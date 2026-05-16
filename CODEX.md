# Dino Zombie and Jar - Codex Project Notes

这份文档给新的 Codex chat 快速建立上下文用。先读这里，再按任务深入具体文件。

## 项目概览

- Godot 4.6 项目，项目名是 `Dino Zombie and Jar`。
- 主场景：`res://battlescene.tscn`。
- 主逻辑：`res://battlescene.gd`。这是当前最大的中枢脚本，负责战斗回合、地图/相机、敌人生成、容器、商店、掉落、祭坛/词缀、UI 拼装等。
- 自动加载：`ItemDatabase="*res://systems/items/ItemDatabase.gd"`。
- 画面基准：1920x1080，viewport stretch。
- 玩法大意：2D 俯视角战斗/生存原型。玩家在竞技场内移动、攻击、开罐/容器、击杀僵尸，获得金币/经验/物品，回合间进入商店和天赋/祝福选择。

## 目录地图

- `project.godot`：Godot 项目配置、主场景、输入映射、物理层、autoload。
- `battlescene.tscn` / `battlescene.gd`：主战斗场景和当前主要游戏流程。
- `scenes/`：可实例化场景。
  - `scenes/player/Player.tscn`：玩家场景。
  - `scenes/player/WizardTalentLayout.tscn`：法师天赋树布局。
  - `scenes/enemies/*.tscn`：敌人场景，包括 melee、burning、acid、fireman、elite、dark knight。
  - `scenes/containers/*.tscn`：容器阴影/预览场景。
  - `scenes/projectiles/Projectile.tscn`：通用投射物场景。
  - `scenes/summons/*.tscn`：召唤物场景，如 turret、skeleton archer、fire dragon。
  - `scenes/test/*.tscn`：手动/自动测试场景。
- `scripts/`：偏实体和测试的 GDScript。
  - `scripts/player/`：玩家、角色数据库、天赋目录、动画库构建。
  - `scripts/enemies/`：敌人基类和具体敌人实现。
  - `scripts/containers/Container.gd`：可破坏容器。
  - `scripts/projectiles/Projectile.gd`：通用投射物。
  - `scripts/editor/`：天赋布局/预览辅助。
  - `scripts/test/`：Godot headless 测试脚本，目前约 18 个。
- `systems/`：复用系统和组件。
  - `systems/battle/`：商店规则、容器目录、暂停输入、天赋树 UI 控制器。
  - `systems/items/`：物品数据库、物品定义、库存、拾取物、奖励可视化。
  - `systems/items/effects/`：物品效果资源和运行时效果节点。
  - `systems/stats/`：角色属性和临时 buff。
  - `systems/status/`：流血、毒、眩晕等状态组件。
  - `systems/combat/`：火球、酸液、陷阱、激光、治疗、浮字、相机震动等战斗效果。
  - `systems/summons/`：召唤物行为。
  - `systems/audio/SfxPlayer.gd`：音效播放工具。
- `data/items/`：物品 `.tres` 数据资源，目前约 87 个。按普通、稀有、传奇等目录拆分，也有部分根目录物品。
- `assets/`：美术和音频资源。
  - `assets/heroes/`：玩家角色素材。
  - `assets/zombies/`：敌人动画图。
  - `assets/containers/`：罐子、桶、墓碑等容器素材。
  - `assets/items/`：物品图标，包括生成图标和未使用素材。
  - `assets/summons/`：召唤物素材。
  - `assets/vfx/`：火焰、闪电、血等特效素材。
  - `assets/sfx/`：音效和背景音乐。
  - `assets/ui/`：卡牌、面板等 UI 图。
- `docs/`：补充文档，目前有 `docs/item_icon_taxonomy.md`。
- `tools/`：脚本工具。
  - `tools/run_refactor_smoke_tests.ps1`：主要 headless 回归测试入口。
  - `tools/talent_dps_estimator.py`：天赋 DPS 估算工具。
- `.godot/`：Godot 生成缓存目录。不要把它当源码入口；一般不应手动编辑。
- `tmp/`：临时文件目录。

## 核心代码入口

- 玩家：`scripts/player/Player.gd`
  - `class_name Player`
  - 负责移动、攻击、技能/祝福动作、生命/经验/金币、天赋和战斗事件。
- 敌人：`scripts/enemies/EnemyBase.gd`
  - `class_name EnemyBase`
  - 具体敌人在同目录继承它，如 `ZombieMelee.gd`、`AcidZombie.gd`、`EliteBrute.gd`。
- 属性：`systems/stats/StatsComponent.gd`
  - `class_name StatsComponent`
  - 处理基础属性、物品加成、临时 buff 等。
- 状态：`systems/status/StatusEffectComponent.gd`
  - `class_name StatusEffectComponent`
  - 处理 bleeding、poison、stun。
- 物品定义：`systems/items/ItemDefinition.gd`
  - `class_name ItemDefinition`
  - `.tres` 物品资源的 schema：id、名称、描述、类别、稀有度、标签、图标、effects。
- 物品数据库：`systems/items/ItemDatabase.gd`
  - autoload，扫描/加载 `data/items/`。
- 背包：`systems/items/InventoryComponent.gd`
  - `class_name InventoryComponent`
  - 管理物品副本、效果应用和运行时节点。
- 物品效果：
  - `systems/items/effects/ItemEffect.gd`：基础资源。
  - `StatModifierEffect.gd`：属性修改。
  - `EventEffect.gd`：事件触发效果。
  - `PeriodicEffect.gd`：周期效果。
  - `PermanentGrowthEffect.gd`：永久成长。
  - `TriggeredBuffEffect.gd`：触发 buff。
  - `MissingHpSummonEffect.gd`：按损失生命召唤。
  - `ItemRuntimeEffectNode.gd`：战斗中持续监听/执行的运行时效果。
  - `ItemEffectTypes.gd`：效果类型常量。
  - `EffectTargeting.gd`：效果目标选择逻辑。
- 天赋：
  - `scripts/player/PlayerTalentCatalog.gd`：角色天赋目录入口。
  - `scripts/player/WizardTalentCatalog.gd`：法师天赋数据和布局映射。
  - `systems/battle/TalentTreeUiController.gd`：天赋树 UI。
- 商店/容器：
  - `systems/battle/ShopRules.gd`
  - `systems/battle/ContainerCatalog.gd`
  - `scripts/containers/Container.gd`

## 重要文档

- `GODOT_WARNING_STANDARD.md`：Codex 修改完成前的 Godot warning/error 标准。
- `ITEM_STACKING_RULES.md`：物品叠加规则定义。
- `ITEM_EFFECT_CATALOG.md`：已确认和待确认的物品效果叠加行为。
- `item_system_codex_prompt.md`：物品系统相关的大型历史上下文/提示。
- `docs/item_icon_taxonomy.md`：物品图标分类和命名参考。

## 测试和验证

优先运行：

```powershell
.\tools\run_refactor_smoke_tests.ps1
```

如果 Godot 不在 PATH：

```powershell
.\tools\run_refactor_smoke_tests.ps1 -GodotPath "C:\Path\To\godot.exe"
```

这个脚本会：

- 跑 `git diff --check`。
- 检查 `.godot` 是否有工作区变更。
- 用 Godot headless 跑一组 `scripts/test/*Test.gd`。
- 要求没有未允许的 Godot `ERROR:` / `WARNING:`。

常见单测脚本包括：

- `scripts/test/AllScenesLoadTest.gd`
- `scripts/test/ItemDatabaseSchemaTest.gd`
- `scripts/test/TalentCatalogContractTest.gd`
- `scripts/test/EffectTargetingTest.gd`
- `scripts/test/PeriodicEffectTest.gd`
- `scripts/test/EnemyStunStatusTest.gd`
- `scripts/test/AltarAffixTest.gd`
- `scripts/test/RefactorSmokeTest.gd`

## 修改时的注意点

- 仓库可能经常有大量未提交改动。先看 `git status --short`，只改和任务相关的文件。
- 不要手动改 `.godot/` 缓存目录；如果测试导致 `.godot` 变脏，按 `GODOT_WARNING_STANDARD.md` 处理并说明。
- `battlescene.gd` 很大，改动前先定位相关函数/常量，避免顺手重构。
- 新增或移动资源时，必须检查 `preload` 路径、`.tscn` 引用、autoload、测试场景是否还可加载。
- 新增物品时通常要同时检查：
  - `data/items/**/*.tres`
  - `systems/items/effects/ItemEffectTypes.gd`
  - 对应 effect class 或 `ItemRuntimeEffectNode.gd`
  - `ITEM_STACKING_RULES.md` / `ITEM_EFFECT_CATALOG.md`
  - `scripts/test/ItemDatabaseSchemaTest.gd` 或相关效果测试
- 新增敌人/召唤物时通常要同时检查：
  - `scenes/enemies` 或 `scenes/summons`
  - `scripts/enemies` 或 `systems/summons`
  - `battlescene.gd` 中的 preload、生成逻辑、奖励/回合规则
  - `scripts/test/AllScenesLoadTest.gd`
- Godot 脚本里尽量保持现有风格：GDScript、显式类型、`class_name` 只在复用类上使用。
- 对小任务保持外科式修改；不要把大型系统顺手重构。

## 快速定位建议

- 查类名：`rg "^class_name" scripts systems -g "*.gd"`
- 查某个物品 id：`rg "item_id_or_file_name" data systems scripts`
- 查某个效果类型：`rg "effect_type_name" systems data scripts`
- 查场景引用：`rg "res://path/to/resource" . -g "!\\.godot/**"`
- 查测试入口：`rg "PASS|FAIL|extends SceneTree" scripts/test`
