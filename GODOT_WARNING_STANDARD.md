# Godot Warning Standard

This project is in prototype phase, so the standard is practical rather than perfect: warnings may exist only when they are known, documented, and not hiding broken gameplay.

## Blocking Diagnostics

Fix these before considering a Codex change complete:

- `SCRIPT ERROR`, `Parse Error`, or any script load failure.
- `ERROR:` during headless smoke tests.
- `WARNING:` during headless smoke tests, unless explicitly allowlisted.
- Missing resources, invalid `preload` paths, broken scene instantiation, or missing autoloads.
- Any warning that appears after adding or moving scripts, scenes, resources, item ids, talent ids, or effect types.
- Any warning that repeats every frame or every trigger.

## Prototype Allowlist Rule

A warning may be temporarily allowed only when all of these are true:

- The game flow still works in the smoke test or manual check.
- The warning has a clear known cause.
- The warning is not from parsing, script loading, resource loading, item effect dispatch, scene instantiation, or signal connection.
- The warning is added to the test runner allowlist with a short reason in code or removed before the task closes.

The default allowlist is empty. New Codex work should aim to leave Godot headless output warning-free.

## Codex Closeout Checklist

Before closing a code change, run:

```powershell
.\tools\run_refactor_smoke_tests.ps1
```

The script runs the headless Godot test suite and must pass with:

- `git diff --check` clean.
- no `.godot` working-tree changes.
- each `scripts/test/*Test.gd` runner entry reporting `PASS`.
- no unallowlisted Godot `ERROR:` or `WARNING:` lines.

Headless tests run with Godot's dummy audio driver. Audio playback quality is checked manually in the editor; headless warning checks should not depend on the local Windows audio backend.

If a warning is intentionally deferred, mention it in the final answer with the exact warning text, the reason it is safe for now, and the condition for removing it.
