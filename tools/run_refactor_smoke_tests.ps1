param(
    [string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TestScripts = @(
    @{ Script = "res://scripts/test/AllScenesLoadTest.gd"; PassText = "AllScenesLoadTest: PASS" },
    @{ Script = "res://scripts/test/ItemDatabaseSchemaTest.gd"; PassText = "ItemDatabaseSchemaTest: PASS" },
    @{ Script = "res://scripts/test/TalentCatalogContractTest.gd"; PassText = "TalentCatalogContractTest: PASS" },
    @{ Script = "res://scripts/test/NecromancerCharacterTest.gd"; PassText = "NecromancerCharacterTest: PASS" },
    @{ Script = "res://scripts/test/EffectTargetingTest.gd"; PassText = "EffectTargetingTest: PASS" },
    @{ Script = "res://scripts/test/PeriodicEffectTest.gd"; PassText = "PeriodicEffectTest: PASS" },
    @{ Script = "res://scripts/test/EnemyStunStatusTest.gd"; PassText = "EnemyStunStatusTest: PASS" },
    @{ Script = "res://scripts/test/AltarAffixTest.gd"; PassText = "AltarAffixTest: PASS" },
    @{ Script = "res://scripts/test/RefactorSmokeTest.gd"; PassText = "RefactorSmokeTest: PASS" }
)

function Join-ProcessArguments {
    param([string[]]$Arguments)

    return ($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }) -join " "
}

function Invoke-CapturedProcess {
    param(
        [string]$FileName,
        [string[]]$Arguments
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FileName
    $startInfo.Arguments = Join-ProcessArguments -Arguments $Arguments
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result

    return [PSCustomObject]@{
        ExitCode = $process.ExitCode
        Stdout = $stdout
        Stderr = $stderr
        Output = $stdout + $stderr
    }
}

function Resolve-Godot {
    param([string]$ExplicitPath)

    if ($ExplicitPath -ne "") {
        if (-not (Test-Path -LiteralPath $ExplicitPath)) {
            throw "GodotPath does not exist: $ExplicitPath"
        }
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }

    $commandNames = @("godot", "godot4", "godot-console", "godot4-console")
    foreach ($name in $commandNames) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command.Source
        }
    }

    $pathValues = @(
        $env:Path,
        [Environment]::GetEnvironmentVariable("Path", "User"),
        [Environment]::GetEnvironmentVariable("Path", "Machine")
    ) | Where-Object { $_ -ne $null -and $_ -ne "" }

    foreach ($pathValue in $pathValues) {
        foreach ($entry in ($pathValue -split ";")) {
            if ($entry -eq "" -or -not (Test-Path -LiteralPath $entry)) {
                continue
            }

            $match = Get-ChildItem -LiteralPath $entry -Filter "godot*.exe" -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($null -ne $match) {
                return $match.FullName
            }
        }
    }

    $searchRoots = @(
        "$env:ProgramFiles",
        "${env:ProgramFiles(x86)}",
        (Join-Path $env:LOCALAPPDATA "Programs")
    ) | Where-Object { $_ -ne $null -and $_ -ne "" -and (Test-Path -LiteralPath $_) }

    foreach ($root in $searchRoots) {
        $match = Get-ChildItem -LiteralPath $root -Recurse -Filter "godot*.exe" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -ne $match) {
            return $match.FullName
        }
    }

    return ""
}

$ResolvedGodotPath = Resolve-Godot -ExplicitPath $GodotPath
if ($ResolvedGodotPath -eq "") {
    Write-Host "Godot executable not found. Install Godot or run: .\tools\run_refactor_smoke_tests.ps1 -GodotPath 'C:\Path\To\godot.exe'" -ForegroundColor Red
    exit 2
}

Write-Host "Using Godot: $ResolvedGodotPath"
Write-Host "Project: $ProjectRoot"

function Write-ProcessOutput {
    param($Result)

    if ($Result.Stdout -ne "") {
        Write-Host ($Result.Stdout.TrimEnd())
    }
    if ($Result.Stderr -ne "") {
        Write-Host ($Result.Stderr.TrimEnd())
    }
}

function Get-UnallowedGodotDiagnostics {
    param([string]$OutputText)

    $diagnosticPattern = '^\s*(SCRIPT ERROR|SCRIPT WARNING|USER ERROR|USER WARNING|ERROR|WARNING):'
    $allowedPatterns = @(
    )
    $unallowed = @()

    foreach ($line in ($OutputText -split "`r?`n")) {
        if ($line -notmatch $diagnosticPattern) {
            continue
        }

        $isAllowed = $false
        foreach ($allowedPattern in $allowedPatterns) {
            if ($line -match $allowedPattern) {
                $isAllowed = $true
                break
            }
        }

        if (-not $isAllowed) {
            $unallowed += $line
        }
    }

    return $unallowed
}

$GitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $GitCommand) {
    Write-Host "Git executable not found; skipped git diff checks." -ForegroundColor Yellow
} else {
    Write-Host "Running git diff --check"
    $DiffCheck = Invoke-CapturedProcess -FileName $GitCommand.Source -Arguments @("-C", $ProjectRoot, "diff", "--check")
    Write-ProcessOutput -Result $DiffCheck
    if ($DiffCheck.ExitCode -ne 0) {
        exit $DiffCheck.ExitCode
    }

    Write-Host "Checking .godot working-tree changes"
    $GodotStatus = Invoke-CapturedProcess -FileName $GitCommand.Source -Arguments @("-C", $ProjectRoot, "status", "--short", "--", ".godot")
    Write-ProcessOutput -Result $GodotStatus
    if ($GodotStatus.ExitCode -ne 0) {
        exit $GodotStatus.ExitCode
    }
    if ($GodotStatus.Output.Trim() -ne "") {
        Write-Host ".godot has working-tree changes; inspect before continuing." -ForegroundColor Red
        exit 1
    }
}

$LogPath = Join-Path ([System.IO.Path]::GetTempPath()) "dino_zombie_godot_tests.log"
$CombinedOutput = ""

foreach ($test in $TestScripts) {
    Write-Host "Running $($test.Script)"

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $GodotOutputLines = & $ResolvedGodotPath --headless --audio-driver Dummy --path $ProjectRoot --script $test.Script 2>&1 |
        ForEach-Object { $_.ToString() }
    $GodotExitCode = $LASTEXITCODE
    $ErrorActionPreference = $PreviousErrorActionPreference

    $OutputText = $GodotOutputLines -join [Environment]::NewLine
    if ($OutputText -ne "") {
        Write-Host $OutputText
    }
    $CombinedOutput += "===== $($test.Script) =====" + [Environment]::NewLine + $OutputText + [Environment]::NewLine

    if ($GodotExitCode -ne 0) {
        Set-Content -LiteralPath $LogPath -Value $CombinedOutput -NoNewline
        exit $GodotExitCode
    }
    if ($OutputText -match "SCRIPT ERROR|Parse Error|: FAIL") {
        Set-Content -LiteralPath $LogPath -Value $CombinedOutput -NoNewline
        exit 1
    }

    $UnallowedDiagnostics = Get-UnallowedGodotDiagnostics -OutputText $OutputText
    if ($UnallowedDiagnostics.Count -gt 0) {
        Write-Host "Godot emitted unallowlisted diagnostics under GODOT_WARNING_STANDARD.md:" -ForegroundColor Red
        foreach ($diagnostic in $UnallowedDiagnostics) {
            Write-Host $diagnostic -ForegroundColor Red
        }
        Set-Content -LiteralPath $LogPath -Value $CombinedOutput -NoNewline
        exit 1
    }

    if ($OutputText -notmatch [regex]::Escape($test.PassText)) {
        Write-Host "$($test.Script) did not report PASS." -ForegroundColor Red
        Set-Content -LiteralPath $LogPath -Value $CombinedOutput -NoNewline
        exit 1
    }
}

Set-Content -LiteralPath $LogPath -Value $CombinedOutput -NoNewline
exit 0
