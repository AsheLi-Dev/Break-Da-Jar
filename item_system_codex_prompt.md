# Codex Prompt: Implement Data-Driven Stats + Item System in Godot 4

You are a Godot 4.x + GDScript game development assistant.

Implement a **data-driven stats and item system** for my 2D top-down roguelike shooter.

The game currently does **not** have a stats system or item system.

The goal is to add:

1. A reusable player stats system.
2. A reusable item definition system.
3. A data-driven item database.
4. Item pickup / apply logic.
5. Support for attack modifiers such as crit chance, poison, and bleeding.
6. A status effect system on enemies for Poison and Bleeding.
7. Event-driven item effects for container breaks, enemy kills, dash events, chain lightning, fireball, lifesteal, and temporary buffs.

Important design requirement:

> Do **not** hard-code all items in one giant script.  
> Items should be data-driven and easy to add later.

Use Godot 4.x GDScript.

---

## 0. Existing Assumptions

Assume the project already has or will have:

- A `Player.gd` script using `CharacterBody2D`.
- Enemies with a `take_damage(amount)` function.
- Enemies belong to group `"enemy"`.
- Player belongs to group `"player"`.
- Player attacks can call a damage function when hitting enemies.
- Projectiles exist or will exist.

If the exact existing scripts differ, implement the new systems in a modular way and show where to connect them.

---

## 1. Design Goals

The item system should support these item types:

- Flat stat increases, such as `+2 ATK`.
- Percent stat increases, such as `+10% attack speed`.
- Derived combat effects, such as crit chance.
- Attack proc effects, such as:
  - 10% chance to apply Bleeding.
  - 10% chance to apply Poison.
  - 10% chance to trigger chain lightning.
  - 10% chance to launch an explosive fireball.
- Event-triggered effects, such as:
  - On container break temporary attack speed / luck buffs.
  - On enemy kill temporary or round-limited buffs.
  - On dash end temporary movement speed buffs.
- Lifesteal from direct damage.
- Legendary rule-changing effects, such as:
  - Bleeding deaths triggering chain lightning.
  - Chain lightning being able to target containers.
  - Fireballs applying Poison.
  - Poison stacks transferring on death.
  - Dash launching a fireball.
  - Missing HP dynamically granting Luck.
  - Container breaks randomly triggering chain lightning or fireball.

The system should be expandable later to support:

- Rarity.
- Item categories.
- Colored containers / eggs / jars.
- Shop rewards.
- Random item pools.

For now, implement the base system and the 26 initial items: 9 existing common/rare starter items, 10 rare items, plus 7 legendary items listed below.

---

## 2. Core Stats

Create a `StatsComponent.gd` or equivalent Resource / Node script.

The player should have these core stats:

```gdscript
atk: int
defense: int
max_hp: int
luck: int
```

Also include these secondary stats:

```gdscript
attack_speed_bonus: float
movement_speed_bonus: float
critical_chance: float
bleed_chance: float
poison_chance: float
lifesteal: float
chain_lightning_chance: float
fireball_chance: float
chain_lightning_damage_scale_override: float # -1 means use effect's own damage_scale
chain_lightning_can_target_containers: bool
fireball_poison_stacks: int
```

Recommended meaning:

- `atk`: increases direct attack and skill damage.
- `defense`: used for damage reduction.
- `max_hp`: maximum health.
- `luck`: affects future drop rates / rarity later.
- `attack_speed_bonus`: 0.10 means +10% attack speed.
- `movement_speed_bonus`: percent movement speed bonus. 0.50 means +50% movement speed.
- `critical_chance`: 0.10 means +10% crit chance.
- `bleed_chance`: 0.10 means attacks have 10% chance to apply Bleeding.
- `poison_chance`: 0.10 means attacks have 10% chance to apply Poison.
- `lifesteal`: 0.10 means heal for 10% of direct damage dealt.
- `chain_lightning_chance`: 0.10 means attacks have 10% chance to trigger chain lightning.
- `fireball_chance`: 0.10 means attacks have 10% chance to launch a fireball.
- `chain_lightning_damage_scale_override`: -1 means chain lightning uses the effect's configured damage scale. 1.50 means all chain lightning deals 150% ATK damage.
- `chain_lightning_can_target_containers`: if true, chain lightning may target containers as valid chain targets.
- `fireball_poison_stacks`: additional Poison stacks applied by fireball explosions.

For this implementation, use:

```gdscript
base_move_speed: float
bonus_move_speed_flat: float
```

because one of the initial items gives `+10 movement speed` as a flat value.

So include:

```gdscript
bonus_move_speed_flat: float
movement_speed_bonus: float
```

Use both flat and percentage movement speed because the starter item gives flat speed and new rare items give percentage speed.

---

## 3. Recommended Stat Formulas

Implement helper functions:

### Damage Scaling

```gdscript
func get_damage_multiplier() -> float:
    return 1.0 + atk * 0.02
```

This means each ATK gives +2% damage.

Example:

```gdscript
final_damage = base_damage * stats.get_damage_multiplier()
```

### Defense Damage Reduction

Use a soft-cap formula:

```gdscript
func get_damage_reduction() -> float:
    return float(defense) / float(defense + 100)
```

Then incoming damage:

```gdscript
func calculate_incoming_damage(raw_damage: float) -> int:
    var reduction := get_damage_reduction()
    var final_damage := raw_damage * (1.0 - reduction)
    return max(1, roundi(final_damage))
```

### Attack Speed

Use:

```gdscript
func get_attack_interval(base_interval: float) -> float:
    return base_interval / (1.0 + attack_speed_bonus)
```

Clamp if necessary so attack speed cannot become broken later.

### Movement Speed

Use:

```gdscript
func get_move_speed(base_speed: float) -> float:
    return (base_speed + bonus_move_speed_flat) * (1.0 + movement_speed_bonus)
```

Later we may add percent movement speed, but not necessary now.

---

## 4. Data-Driven Item Definition

Create an `ItemDefinition.gd` Resource.

Recommended file:

```text
res://systems/items/ItemDefinition.gd
```

It should be a Resource with exported fields:

```gdscript
extends Resource
class_name ItemDefinition

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: StringName # attack, defense, utility
@export var rarity: StringName # common, rare, legendary
@export var icon: Texture2D
@export var effects: Array[ItemEffect]
```

However, Godot typed exported arrays of custom Resources can sometimes be annoying. If easier, use:

```gdscript
@export var effects: Array[Resource]
```

Each item can have one or more effects.

---

## 5. Item Effects

Create a base Resource:

```text
res://systems/items/effects/ItemEffect.gd
```

```gdscript
extends Resource
class_name ItemEffect

func apply_to(player: Node) -> void:
    pass
```

Then create a concrete stat modifier effect:

```text
res://systems/items/effects/StatModifierEffect.gd
res://systems/items/effects/EventEffect.gd
res://systems/combat/FireballProjectile.gd
```

Fields:

```gdscript
extends ItemEffect
class_name StatModifierEffect

@export var stat_name: StringName
@export var operation: StringName = &"add" # add, multiply_add, set
@export var value: float

func apply_to(player: Node) -> void:
    if not player.has_method("get_stats"):
        push_warning("Player does not expose get_stats().")
        return

    var stats = player.get_stats()
    if stats == null:
        push_warning("Player stats is null.")
        return

    stats.apply_modifier(stat_name, operation, value)
```

StatsComponent should implement:

```gdscript
func apply_modifier(stat_name: StringName, operation: StringName, value: float) -> void:
    match stat_name:
        &"atk":
            atk += int(value)
        &"defense":
            defense += int(value)
        &"max_hp":
            max_hp += int(value)
        &"luck":
            luck += int(value)
        &"attack_speed_bonus":
            attack_speed_bonus += value
        &"bonus_move_speed_flat":
            bonus_move_speed_flat += value
        &"movement_speed_bonus":
            movement_speed_bonus += value
        &"critical_chance":
            critical_chance += value
        &"bleed_chance":
            bleed_chance += value
        &"poison_chance":
            poison_chance += value
        &"lifesteal":
            lifesteal += value
        &"chain_lightning_chance":
            chain_lightning_chance += value
        &"fireball_chance":
            fireball_chance += value
        &"chain_lightning_damage_scale_override":
            chain_lightning_damage_scale_override = value
        &"chain_lightning_can_target_containers":
            chain_lightning_can_target_containers = value >= 1.0
        &"fireball_poison_stacks":
            fireball_poison_stacks += int(value)
        _:
            push_warning("Unknown stat modifier: %s" % stat_name)
```

For now, `operation` can support only `add`, but include the field so it can expand later.


---

## 5B. Temporary Buffs and Event-Driven Item Effects

The new rare items require temporary buffs and event-triggered effects. Keep this data-driven and avoid hard-coding item IDs in `Player.gd`.

### Temporary Buff System

Create:

```text
res://systems/stats/TemporaryBuffComponent.gd
```

Attach it to the player or create it inside the player.

Responsibilities:

- Track temporary stat modifiers.
- Support stacks.
- Support max stacks.
- Support duration refresh.
- Support buffs that expire at the end of the current round.

Suggested API:

```gdscript
extends Node
class_name TemporaryBuffComponent

var owner_player: Node
var buffs: Dictionary = {}

func setup(player: Node) -> void:
    owner_player = player

func add_timed_stat_buff(
    buff_id: StringName,
    stat_name: StringName,
    value_per_stack: float,
    duration: float,
    max_stacks: int,
    refresh_duration: bool = true
) -> void:
    # If buff does not exist, create it with 1 stack.
    # If buff exists, add 1 stack up to max_stacks.
    # Recalculate total applied value.
    # If refresh_duration, reset time_left to duration.
    pass

func add_round_stat_buff(
    buff_id: StringName,
    stat_name: StringName,
    value_per_stack: float,
    max_stacks: int
) -> void:
    # Add stack until max_stacks. Does not expire by time.
    # Cleared when clear_round_buffs() is called.
    pass

func clear_round_buffs() -> void:
    # Remove all round-limited buffs and reverse their stat modifiers.
    pass
```

Implementation note:

- Buffs should apply their current total modifier to `StatsComponent`.
- When stack count changes or buff expires, remove the old modifier and apply the new total.
- It is acceptable in V1 to implement helper methods on `StatsComponent` such as `add_runtime_modifier(stat_name, value)` and `remove_runtime_modifier(stat_name, value)`.
- Do not make these rare item buffs permanent unless specified.

### Player Event Hooks

Create a simple event surface on the player. Items can connect to these signals when acquired.

In `Player.gd` or a dedicated event component, expose signals:

```gdscript
signal attack_hit(enemy: Node, damage_dealt: float, attack_info: Dictionary)
signal enemy_killed(enemy: Node)
signal container_broken(container: Node)
signal dash_started()
signal dash_ended()
signal round_started()
signal round_ended()
signal hp_changed(current_hp: int, max_hp: int)
```

Emit these signals from the relevant systems:

- `attack_hit`: whenever a player direct attack successfully damages an enemy.
- `enemy_killed`: when an enemy dies from player-caused damage or player-owned DoT.
- `container_broken`: when a jar / egg / container is broken by the player or by player-owned damage.
- `dash_started`: when dash / slide begins.
- `dash_ended`: when dash / slide ends.
- `round_ended`: when the current room / combat round ends. Use this to clear round-limited buffs.
- `hp_changed`: when current HP or max HP changes. Use this for dynamic missing-HP stat effects.

If the project does not yet have containers or rounds, implement the signals and helper methods now, then call them from test scripts later.

### Event Item Effect Resource

Create:

```text
res://systems/items/effects/EventEffect.gd
```

Suggested fields:

```gdscript
extends ItemEffect
class_name EventEffect

@export var event_name: StringName # attack_hit, enemy_killed, container_broken, dash_started, dash_ended
@export var effect_type: StringName # timed_stat_buff, round_stat_buff, apply_status_near_container, spread_bleeding_on_death, chain_lightning, fireball, lifesteal
@export var stat_name: StringName
@export var value: float
@export var duration: float
@export var max_stacks: int = 1
@export var radius: float = 0.0
@export var chance: float = 1.0
@export var damage_scale: float = 1.0
@export var chain_count: int = 0
@export var internal_cooldown: float = 0.0
@export var status_id: StringName
@export var poison_stacks: int = 0
@export var choices: Array[StringName] = [] # for random_proc effects, e.g. chain_lightning/fireball
@export var only_direct_container_breaks: bool = true

func apply_to(player: Node) -> void:
    # Connect to the appropriate player signal based on event_name.
    # The connected callback should evaluate chance, internal cooldown, then apply effect_type.
    pass
```

Keep this generic. Do not create one script per individual item unless absolutely necessary.

A small match statement on `effect_type` is acceptable because it maps generic effect types, not individual item IDs.

Required generic effect types for V1:

```text
timed_stat_buff
round_stat_buff
apply_poison_near_container
spread_bleeding_on_death
chain_lightning
fireball
lifesteal
chain_lightning_on_bleeding_death
poison_transfer_on_death
fireball_on_dash
missing_hp_stat_bonus
container_break_random_proc
```

Additional implementation requirements for legendary effects:

- `chain_lightning_on_bleeding_death`: on `enemy_killed`, if the killed enemy had Bleeding active at death, trigger chain lightning from that enemy's position.
- `poison_transfer_on_death`: on `enemy_killed`, if the killed enemy has Poison stacks, transfer its current Poison stack count to the nearest enemy within `radius`; refresh Poison duration on the target.
- `fireball_on_dash`: on `dash_started`, launch a Fireball in the dash direction.
- `missing_hp_stat_bonus`: on `hp_changed`, dynamically apply `floor((max_hp - current_hp) / 10) * value` to `stat_name`; remove/recalculate the previous dynamic bonus whenever HP changes.
- `container_break_random_proc`: on `container_broken`, randomly trigger one proc listed in `choices`, usually `chain_lightning` or `fireball`. To avoid infinite loops, this should only trigger from direct player container breaks, not from containers broken by chain lightning or fireball.

### Direct Damage and Lifesteal

Add a generic direct damage helper if possible:

```gdscript
func deal_player_damage_to_enemy(enemy: Node, raw_damage: float, attack_info: Dictionary = {}) -> float:
    # Apply ATK scaling, crit, direct hit procs, then enemy.take_damage(final_damage).
    # Return actual damage dealt if available, or final_damage as fallback.
```

For V1, lifesteal should only heal from direct damage dealt by player-owned attacks and player-owned proc effects.

Do not lifesteal from:

- Bleeding DoT
- Poison DoT
- Environmental damage
- Container self-damage


---

## 6. Player Integration

Modify or create player support methods:

```gdscript
var stats: StatsComponent

func get_stats() -> StatsComponent:
    return stats
```

If `StatsComponent` is a Resource, initialize it in `_ready()`:

```gdscript
func _ready() -> void:
    if stats == null:
        stats = StatsComponent.new()
    add_to_group("player")
```

If the player already has max HP / current HP, sync them:

- When `max_hp` increases, increase current HP by the same amount if desired.
- Recommended V1 behavior:

```gdscript
func on_max_hp_increased(amount: int) -> void:
    hp += amount
    hp = min(hp, stats.max_hp)
```

If simpler, just update max HP and leave current HP unchanged. But document the choice.

---

## 7. Applying Items

Create an `InventoryComponent.gd`:

```text
res://systems/items/InventoryComponent.gd
```

Responsibilities:

- Store acquired item IDs and counts.
- Apply item effects to player when item is acquired.

Suggested API:

```gdscript
extends Node
class_name InventoryComponent

var owner_player: Node
var item_counts: Dictionary = {}

func setup(player: Node) -> void:
    owner_player = player

func add_item(item: ItemDefinition) -> void:
    if item == null:
        return

    item_counts[item.id] = item_counts.get(item.id, 0) + 1

    for effect in item.effects:
        if effect != null and effect.has_method("apply_to"):
            effect.apply_to(owner_player)
```

Attach this component to Player or instantiate it in Player.

---

## 8. Item Database

Create an `ItemDatabase.gd` autoload or regular Node.

Recommended:

```text
res://systems/items/ItemDatabase.gd
```

It should load all `.tres` item definitions from:

```text
res://data/items/
```

Suggested API:

```gdscript
extends Node
class_name ItemDatabase

var items_by_id: Dictionary = {}
var all_items: Array[ItemDefinition] = []

func _ready() -> void:
    load_items_from_folder("res://data/items/")

func load_items_from_folder(path: String) -> void:
    # Use DirAccess to scan .tres files.
    # Load each resource.
    # If it is ItemDefinition, register it.

func get_item(id: StringName) -> ItemDefinition:
    return items_by_id.get(id)

func get_items_by_category(category: StringName) -> Array[ItemDefinition]:
    # Return items with matching category.

func get_items_by_rarity(rarity: StringName) -> Array[ItemDefinition]:
    # Return items with matching rarity.
```

Register it as an Autoload named `ItemDatabase`, or provide instructions for manually adding it.

Do not hard-code all item effects inside the database. The database should load Resource files.

---

## 9. Initial Common / Starter Item List

Create these 9 starter items as `.tres` Resources under:

```text
res://data/items/
```

Each item should be an `ItemDefinition` with one `StatModifierEffect` unless otherwise noted.

Use placeholder icons if no icons exist.

---

### Item 1: Sharpened Relic

```yaml
id: sharpened_relic
display_name: Sharpened Relic
category: attack
rarity: common
description: +2 ATK.
effects:
  - stat_name: atk
    operation: add
    value: 2
```

---

### Item 2: Reinforced Plate

```yaml
id: reinforced_plate
display_name: Reinforced Plate
category: defense
rarity: common
description: +10 DEF.
effects:
  - stat_name: defense
    operation: add
    value: 10
```

---

### Item 3: Vital Charm

```yaml
id: vital_charm
display_name: Vital Charm
category: defense
rarity: common
description: +10 Max HP.
effects:
  - stat_name: max_hp
    operation: add
    value: 10
```

---

### Item 4: Quick Trigger

```yaml
id: quick_trigger
display_name: Quick Trigger
category: attack
rarity: common
description: +10% Attack Speed.
effects:
  - stat_name: attack_speed_bonus
    operation: add
    value: 0.10
```

---

### Item 5: Lucky Coin

```yaml
id: lucky_coin
display_name: Lucky Coin
category: utility
rarity: common
description: +1 Luck.
effects:
  - stat_name: luck
    operation: add
    value: 1
```

Note: Keep this as +1 Luck for now because the user requested +1 Luck. Later we may tune this to +3 Luck if +1 feels too weak.

---

### Item 6: Light Boots

```yaml
id: light_boots
display_name: Light Boots
category: utility
rarity: common
description: +10 Movement Speed.
effects:
  - stat_name: bonus_move_speed_flat
    operation: add
    value: 10
```

---

### Item 7: Hunter's Eye

```yaml
id: hunters_eye
display_name: Hunter's Eye
category: attack
rarity: rare
description: +10% Critical Chance.
effects:
  - stat_name: critical_chance
    operation: add
    value: 0.10
```

---

### Item 8: Rusted Fang

```yaml
id: rusted_fang
display_name: Rusted Fang
category: attack
rarity: rare
description: Attacks have +10% chance to apply Bleeding.
effects:
  - stat_name: bleed_chance
    operation: add
    value: 0.10
```

Bleeding rules:

```text
Bleeding:
- Max stacks: 1
- Damage: 5% of target max HP per second
- Duration: 3 seconds
- Reapplying Bleeding refreshes duration but does not increase stacks
```

---

### Item 9: Toxic Needle

```yaml
id: toxic_needle
display_name: Toxic Needle
category: attack
rarity: rare
description: Attacks have +10% chance to apply Poison.
effects:
  - stat_name: poison_chance
    operation: add
    value: 0.10
```

Poison rules:

```text
Poison:
- Max stacks: 10
- Damage: 5 flat damage per stack per second
- Duration: 4 seconds
- Reapplying Poison adds 1 stack up to max stacks and refreshes duration
```


---

## 9B. New Rare Item List

Create these 10 additional rare items as `.tres` Resources under:

```text
res://data/items/
```

These should use `EventEffect` and/or `StatModifierEffect` rather than hard-coded item ID checks.

---

### Item 10: Adrenaline Shell

```yaml
id: adrenaline_shell
display_name: Adrenaline Shell
category: attack
rarity: rare
description: Breaking a container grants +5% Attack Speed for 3 seconds. Max 5 stacks.
effects:
  - type: EventEffect
    event_name: container_broken
    effect_type: timed_stat_buff
    stat_name: attack_speed_bonus
    value: 0.05
    duration: 3.0
    max_stacks: 5
```

Behavior:

```text
- Trigger when the player breaks a container.
- Each trigger adds 1 stack, up to 5.
- Each stack gives +5% attack speed.
- Duration: 3 seconds.
- Reapplying refreshes the buff duration.
```

---

### Item 11: Golden Instinct

```yaml
id: golden_instinct
display_name: Golden Instinct
category: utility
rarity: rare
description: Breaking a container grants +2 Luck for 5 seconds. Max 5 stacks.
effects:
  - type: EventEffect
    event_name: container_broken
    effect_type: timed_stat_buff
    stat_name: luck
    value: 2
    duration: 5.0
    max_stacks: 5
```

Behavior:

```text
- Trigger when the player breaks a container.
- Each trigger adds +2 Luck, up to +10 Luck total.
- Duration: 5 seconds.
- Reapplying refreshes the buff duration.
```

---

### Item 12: Crusader's Momentum

```yaml
id: crusaders_momentum
display_name: Crusader's Momentum
category: attack
rarity: rare
description: Killing an enemy grants +1 ATK until the end of the current round. Max +10 ATK.
effects:
  - type: EventEffect
    event_name: enemy_killed
    effect_type: round_stat_buff
    stat_name: atk
    value: 1
    max_stacks: 10
```

Behavior:

```text
- Trigger when the player kills an enemy.
- Gain +1 ATK until round end.
- Max bonus: +10 ATK.
- Clear this bonus when round_ended is emitted.
```

---

### Item 13: Blood-Sanctified Blade

```yaml
id: blood_sanctified_blade
display_name: Blood-Sanctified Blade
category: defense
rarity: rare
description: +10% Lifesteal from direct player damage.
effects:
  - type: StatModifierEffect
    stat_name: lifesteal
    operation: add
    value: 0.10
```

Behavior:

```text
- Heal the player for 10% of direct damage dealt.
- Lifesteal stacks additively if the player gets multiple copies.
- Lifesteal applies to direct attack damage, chain lightning damage, and fireball impact / explosion damage.
- Lifesteal does not apply to Poison or Bleeding DoT.
```

---

### Item 14: Toxic Rupture

```yaml
id: toxic_rupture
display_name: Toxic Rupture
category: utility
rarity: rare
description: Breaking a container applies 1 Poison stack to enemies near that container.
effects:
  - type: EventEffect
    event_name: container_broken
    effect_type: apply_poison_near_container
    radius: 120.0
```

Behavior:

```text
- Trigger when the player breaks a container.
- Find enemies within 120 pixels of the broken container.
- Apply 1 Poison stack to each enemy found.
```

---

### Item 15: Hunter's Step

```yaml
id: hunters_step
display_name: Hunter's Step
category: utility
rarity: rare
description: Killing an enemy grants +50% Movement Speed for 1 second.
effects:
  - type: EventEffect
    event_name: enemy_killed
    effect_type: timed_stat_buff
    stat_name: movement_speed_bonus
    value: 0.50
    duration: 1.0
    max_stacks: 1
```

Implementation note:

```text
- Add `movement_speed_bonus: float` to StatsComponent if it does not exist yet.
- Update movement speed formula to include both flat and percent bonus:
  final_speed = (base_speed + bonus_move_speed_flat) * (1.0 + movement_speed_bonus)
- This buff should not stack. Reapplying refreshes duration.
```

---

### Item 16: Open Wound

```yaml
id: open_wound
display_name: Open Wound
category: attack
rarity: rare
description: When a bleeding enemy dies, nearby enemies gain 1 Bleeding stack.
effects:
  - type: EventEffect
    event_name: enemy_killed
    effect_type: spread_bleeding_on_death
    radius: 120.0
```

Behavior:

```text
- Trigger when the player kills an enemy.
- Check whether the killed enemy had Bleeding active at the moment of death.
- If yes, find enemies within 120 pixels of the killed enemy.
- Apply Bleeding to each nearby enemy.
- Since Bleeding max stacks is 1 in V1, this refreshes Bleeding if already present.
```

Implementation note:

```text
- StatusEffectComponent should expose:
  func has_status(id: StringName) -> bool
- EnemyBase can proxy this as enemy.has_status(&"bleeding").
```

---

### Item 17: Chain Judgment

```yaml
id: chain_judgment
display_name: Chain Judgment
category: attack
rarity: rare
description: Attacks have 10% chance to trigger chain lightning. Chains 3 times and deals 50% ATK damage per hit.
effects:
  - type: EventEffect
    event_name: attack_hit
    effect_type: chain_lightning
    chance: 0.10
    chain_count: 3
    damage_scale: 0.50
    radius: 180.0
    internal_cooldown: 0.15
```

Behavior:

```text
- Trigger only when a player attack hits an enemy.
- Roll 10% chance.
- If successful, chain to up to 3 nearby enemies.
- Each chain hit deals 50% ATK-scaled damage unless a legendary item overrides the chain lightning damage scale.
- Do not hit the same enemy twice in the same chain sequence.
- Use search radius 180 between chain jumps.
- Has 0.15s internal cooldown to avoid excessive triggering at very high attack speeds.
```

Damage formula:

```gdscript
chain_damage = 0.50 * stats.atk * stats.get_damage_multiplier()
```

If this feels too low because `atk` is a stat rather than base damage, use:

```gdscript
chain_damage = base_attack_damage * stats.get_damage_multiplier() * 0.50
```

Document whichever approach is used.

---

### Item 18: Solar Ember

```yaml
id: solar_ember
display_name: Solar Ember
category: attack
rarity: rare
description: Attacks have 10% chance to launch a fireball that explodes on impact for 120% ATK damage.
effects:
  - type: EventEffect
    event_name: attack_hit
    effect_type: fireball
    chance: 0.10
    damage_scale: 1.20
    radius: 80.0
    internal_cooldown: 0.15
```

Behavior:

```text
- Trigger only when a player attack hits an enemy.
- Roll 10% chance.
- If successful, spawn a player-owned fireball projectile.
- Fireball flies toward the hit enemy's position or the player's aim direction.
- On impact, explode in a small AOE radius of 80 pixels.
- Explosion deals 120% ATK-scaled damage.
- Has 0.15s internal cooldown.
```

Create if needed:

```text
res://systems/combat/FireballProjectile.gd
```

The fireball should:

- Use `Area2D`.
- Move in a direction.
- Explode on enemy hit, wall hit, or lifetime expiry.
- Damage enemies in explosion radius.
- Be player-owned so it can trigger lifesteal from direct damage.
- Avoid recursively triggering additional fireballs unless explicitly allowed later. For V1, fireball damage should not trigger `attack_hit` procs.
- If the owner has `stats.fireball_poison_stacks > 0`, fireball explosion should apply that many Poison stacks to enemies hit.

---

### Item 19: Radiant Slide

```yaml
id: radiant_slide
display_name: Radiant Slide
category: utility
rarity: rare
description: After dash ends, gain +50% Movement Speed for 0.2 seconds.
effects:
  - type: EventEffect
    event_name: dash_ended
    effect_type: timed_stat_buff
    stat_name: movement_speed_bonus
    value: 0.50
    duration: 0.2
    max_stacks: 1
```

Behavior:

```text
- Trigger when dash / slide ends.
- Gain +50% movement speed for 0.2 seconds.
- Does not stack. Reapplying refreshes duration.
```

Optional tuning note:

```text
If 0.2 seconds is too hard to feel, tune to 0.3–0.35 seconds later.
```

---

## 9C. New Legendary Item List

Create these 7 additional legendary items as `.tres` Resources under:

```text
res://data/items/
```

These should use `EventEffect` and/or `StatModifierEffect`. They should not be implemented as item-ID special cases in `Player.gd`.

Legendary design rule:

> Legendary items should change how existing systems interact. They may be stronger or riskier than rare items, but they must still be implemented through reusable generic effect types.

---

### Item 20: Bloodbolt Covenant

```yaml
id: bloodbolt_covenant
display_name: Bloodbolt Covenant
category: attack
rarity: legendary
description: When a Bleeding enemy dies, trigger Chain Lightning from its position.
effects:
  - type: EventEffect
    event_name: enemy_killed
    effect_type: chain_lightning_on_bleeding_death
    chain_count: 3
    damage_scale: 0.50
    radius: 180.0
    internal_cooldown: 0.05
```

Behavior:

```text
- Trigger when the player kills an enemy.
- Check whether the killed enemy had Bleeding active at the moment of death.
- If yes, trigger Chain Lightning from the killed enemy's position.
- Use the current global chain lightning damage scale if `chain_lightning_damage_scale_override` is active; otherwise use this effect's `damage_scale`.
- Chain up to 3 targets.
- Do not hit the same enemy twice in the same chain sequence.
```

Implementation note:

```text
- Reuse the same generic chain lightning helper used by Chain Judgment.
- Do not create a separate lightning implementation only for this item.
```

---

### Item 21: Storm Greed

```yaml
id: storm_greed
display_name: Storm Greed
category: attack
rarity: legendary
description: Your Chain Lightning deals 150% ATK damage, but it can chain to containers.
effects:
  - type: StatModifierEffect
    stat_name: chain_lightning_damage_scale_override
    operation: set
    value: 1.50
  - type: StatModifierEffect
    stat_name: chain_lightning_can_target_containers
    operation: set
    value: 1
```

Behavior:

```text
- All player-owned Chain Lightning now deals 150% ATK damage per hit instead of its default 50% ATK damage.
- Chain Lightning may now target containers as valid chain targets.
- Containers hit by Chain Lightning should take damage or break if the existing container system supports that.
- This creates a risk/reward side effect: stronger lightning can accidentally open containers.
```

Targeting rule for V1:

```text
- Chain Lightning should prefer enemy targets first.
- If no valid enemy target is available within chain radius, it may chain to containers.
- To avoid immediate chaos, Chain Lightning can target containers only after it has hit at least one enemy in the current chain sequence.
```

Implementation note:

```text
- The chain lightning helper should check stats.chain_lightning_damage_scale_override.
- If the override is >= 0, use it instead of the EventEffect damage_scale.
- The helper should also check stats.chain_lightning_can_target_containers.
```

---

### Item 22: Plague Comet

```yaml
id: plague_comet
display_name: Plague Comet
category: attack
rarity: legendary
description: Your Fireball explosions apply 2 Poison stacks.
effects:
  - type: StatModifierEffect
    stat_name: fireball_poison_stacks
    operation: add
    value: 2
```

Behavior:

```text
- When a player-owned Fireball explodes, enemies hit by the explosion receive 2 Poison stacks.
- Poison is applied only by the explosion hit, not while the fireball is flying.
- If the player later gains more fireball_poison_stacks, stack the value additively.
```

Implementation note:

```text
- FireballProjectile.gd should read the owner's stats when exploding.
- If stats.fireball_poison_stacks > 0, apply that many Poison stacks to each enemy hit.
```

---

### Item 23: Last Venom

```yaml
id: last_venom
display_name: Last Venom
category: attack
rarity: legendary
description: When a Poisoned enemy dies, the nearest enemy receives its remaining Poison stacks.
effects:
  - type: EventEffect
    event_name: enemy_killed
    effect_type: poison_transfer_on_death
    radius: 240.0
```

Behavior:

```text
- Trigger when the player kills an enemy.
- If the killed enemy has Poison stacks, read its current Poison stack count.
- Find the nearest enemy within 240 pixels.
- Apply the same number of Poison stacks to that target.
- Refresh the target Poison duration to full duration.
- If no enemy is nearby, do nothing.
```

Implementation note:

```text
- StatusEffectComponent should expose:
  func get_poison_stacks() -> int
  func apply_poison_stacks(amount: int) -> void
- Transfer stacks only. Do not try to transfer remaining duration in V1.
```

---

### Item 24: Blazing Slide

```yaml
id: blazing_slide
display_name: Blazing Slide
category: utility
rarity: legendary
description: When you start a dash, launch a Fireball in the dash direction.
effects:
  - type: EventEffect
    event_name: dash_started
    effect_type: fireball_on_dash
    damage_scale: 1.20
    radius: 80.0
```

Behavior:

```text
- Trigger when dash / slide starts.
- Launch one player-owned Fireball in the dash direction.
- The Fireball uses the normal FireballProjectile system.
- Default damage: 120% ATK-scaled damage.
- Default explosion radius: 80 pixels.
- If the player has Plague Comet, this Fireball also applies Poison on explosion.
```

Implementation note:

```text
- Player should provide or pass dash direction when emitting dash_started.
- If current signal has no parameter, either update it to `signal dash_started(direction: Vector2)` or let EventEffect read a `player.last_dash_direction` property.
```

---

### Item 25: Martyr's Fortune

```yaml
id: martyrs_fortune
display_name: Martyr's Fortune
category: utility
rarity: legendary
description: For every 10 missing HP, gain +2 Luck.
effects:
  - type: EventEffect
    event_name: hp_changed
    effect_type: missing_hp_stat_bonus
    stat_name: luck
    value: 2
```

Behavior:

```text
- Dynamically calculate missing HP:
  missing_hp = max_hp - current_hp
- Bonus Luck:
  floor(missing_hp / 10) * 2
- Recalculate whenever HP or max HP changes.
- Healing lowers the bonus.
- Taking damage increases the bonus.
```

Example:

```text
Max HP = 100
Current HP = 55
Missing HP = 45
Bonus Luck = floor(45 / 10) * 2 = +8 Luck
```

Implementation note:

```text
- The temporary/dynamic buff component should track the last applied value for this effect so it can remove the old Luck bonus before applying the new one.
- This is not a timed buff and not a round buff.
```

---

### Item 26: Chaos Hatch

```yaml
id: chaos_hatch
display_name: Chaos Hatch
category: utility
rarity: legendary
description: Breaking a container randomly triggers Chain Lightning or Fireball.
effects:
  - type: EventEffect
    event_name: container_broken
    effect_type: container_break_random_proc
    choices: [chain_lightning, fireball]
    chance: 1.0
    chain_count: 3
    damage_scale: 0.50
    radius: 180.0
    internal_cooldown: 0.05
    only_direct_container_breaks: true
```

Behavior:

```text
- Trigger when the player directly breaks a container.
- Randomly choose one:
  A. Trigger Chain Lightning from the container position.
  B. Launch a Fireball from the container position toward the nearest enemy.
- 50% Chain Lightning / 50% Fireball in V1.
- If no enemy exists, do nothing.
```

Important anti-infinite-loop rule:

```text
- Chaos Hatch should only trigger from direct player container breaks.
- Do not trigger Chaos Hatch from containers broken by Chain Lightning or Fireball.
- Each container can emit container_broken effects only once.
```

Implementation note:

```text
- Container break events should include an `attack_info` or metadata dictionary if possible:
  { "source": "player_attack" | "chain_lightning" | "fireball" }
- If metadata is not available yet, add a simple property or argument so EventEffect can ignore non-direct breaks.
```

---

## 10. Critical Hit Logic

When player attack hits an enemy:

```gdscript
var damage := base_damage * stats.get_damage_multiplier()

if randf() < stats.critical_chance:
    damage *= 2.0

enemy.take_damage(roundi(damage))
```

For V1:

- Crit multiplier = 2.0
- Critical chance is additive.
- Clamp critical chance to a safe maximum, such as 1.0.

---

## 11. Attack Proc Logic

When player attack hits an enemy, after dealing direct damage, emit `attack_hit` and apply simple stat-based procs:

```gdscript
if randf() < stats.bleed_chance:
    if enemy.has_method("apply_status_effect"):
        enemy.apply_status_effect(&"bleeding")

if randf() < stats.poison_chance:
    if enemy.has_method("apply_status_effect"):
        enemy.apply_status_effect(&"poison")
```

Important:

- This should run only when an attack successfully hits an enemy.
- Do not apply status effects on misses.
- If one projectile pierces multiple enemies, each enemy can independently roll proc chances.
- After direct damage is dealt, emit `attack_hit(enemy, damage_dealt, attack_info)`. EventEffect-based items such as Chain Judgment and Solar Ember should listen to this signal.
- Do not let proc damage recursively trigger more attack procs in V1 unless explicitly marked in `attack_info`.

---

## 12. Enemy Status Effect Component

Create:

```text
res://systems/status/StatusEffectComponent.gd
```

Attach it to enemies or create it in enemy base script.

It should support:

```gdscript
func apply_bleeding() -> void
func apply_poison() -> void
func apply_poison_stacks(amount: int) -> void
func get_poison_stacks() -> int
func has_status(id: StringName) -> bool
func apply_status_effect(id: StringName) -> void
func tick(delta: float) -> void
```

Suggested behavior:

### Bleeding

- Max stacks: 1
- Duration: 3 seconds
- Damage: 5% target max HP per second
- Reapply: refresh duration

### Poison

- Max stacks: 10
- Duration: 4 seconds
- Damage: 5 flat damage per stack per second
- Reapply: +1 stack up to 10 and refresh duration
- `apply_poison_stacks(amount)` should add multiple stacks up to 10 and refresh duration once.

Implementation suggestion:

- Store active statuses in variables or a dictionary.
- Apply DoT every 1 second using an accumulator, not every frame.
- Call enemy.take_damage(dot_amount) for DoT damage.

Example fields:

```gdscript
var bleeding_time_left: float = 0.0
var poison_time_left: float = 0.0
var poison_stacks: int = 0
var dot_tick_timer: float = 0.0
```

Example tick:

```gdscript
func _process(delta: float) -> void:
    tick_status_effects(delta)
```

Do not make DoT damage trigger additional on-hit effects to avoid infinite loops.

---

## 13. Enemy Integration

Enemies need:

```gdscript
var max_hp: int
var hp: int
```

Add method:

```gdscript
func apply_status_effect(id: StringName) -> void:
    status_effect_component.apply_status_effect(id)
```

If there is no component architecture yet, implement status logic directly in `EnemyBase.gd` for now, but keep it separated enough to move into a component later.

Preferred:

```text
EnemyBase (CharacterBody2D)
├── StatusEffectComponent (Node)
```

---

## 14. Item Pickup Testing

Create a simple test item pickup scene/script:

```text
res://systems/items/ItemPickup.gd
```

Behavior:

- Export `item_id: StringName`.
- On player entering Area2D, get item from ItemDatabase.
- Add it to player's InventoryComponent.
- Destroy pickup.

Example:

```gdscript
@export var item_id: StringName

func _on_body_entered(body: Node) -> void:
    if not body.is_in_group("player"):
        return

    var item := ItemDatabase.get_item(item_id)
    if item == null:
        push_warning("Unknown item id: %s" % item_id)
        return

    if body.has_method("add_item"):
        body.add_item(item)
    elif body.has_node("InventoryComponent"):
        body.get_node("InventoryComponent").add_item(item)

    queue_free()
```

Add `Player.add_item(item)` as a convenience method:

```gdscript
func add_item(item: ItemDefinition) -> void:
    inventory.add_item(item)
```

---

## 15. Random Item Roll API

Implement basic future-ready API in `ItemDatabase.gd`:

```gdscript
func get_random_item(category: StringName = &"", rarity: StringName = &"") -> ItemDefinition:
    var pool: Array[ItemDefinition] = []
    for item in all_items:
        if category != &"" and item.category != category:
            continue
        if rarity != &"" and item.rarity != rarity:
            continue
        pool.append(item)

    if pool.is_empty():
        return null

    return pool.pick_random()
```

This will support future colored jars / eggs:

- Red container: category `attack`
- Blue container: category `defense`
- Green container: category `utility`
- Common / rare / legendary containers: rarity filter

---

## 16. Folder Structure

Create this folder structure:

```text
res://systems/stats/StatsComponent.gd
res://systems/stats/TemporaryBuffComponent.gd
res://systems/items/ItemDefinition.gd
res://systems/items/InventoryComponent.gd
res://systems/items/ItemDatabase.gd
res://systems/items/ItemPickup.gd
res://systems/items/effects/ItemEffect.gd
res://systems/items/effects/StatModifierEffect.gd
res://systems/items/effects/EventEffect.gd
res://systems/combat/FireballProjectile.gd
res://systems/status/StatusEffectComponent.gd
res://data/items/sharpened_relic.tres
res://data/items/reinforced_plate.tres
res://data/items/vital_charm.tres
res://data/items/quick_trigger.tres
res://data/items/lucky_coin.tres
res://data/items/light_boots.tres
res://data/items/hunters_eye.tres
res://data/items/rusted_fang.tres
res://data/items/toxic_needle.tres
res://data/items/adrenaline_shell.tres
res://data/items/golden_instinct.tres
res://data/items/crusaders_momentum.tres
res://data/items/blood_sanctified_blade.tres
res://data/items/toxic_rupture.tres
res://data/items/hunters_step.tres
res://data/items/open_wound.tres
res://data/items/chain_judgment.tres
res://data/items/solar_ember.tres
res://data/items/radiant_slide.tres
res://data/items/bloodbolt_covenant.tres
res://data/items/storm_greed.tres
res://data/items/plague_comet.tres
res://data/items/last_venom.tres
res://data/items/blazing_slide.tres
res://data/items/martyrs_fortune.tres
res://data/items/chaos_hatch.tres
```

---

## 17. Acceptance Criteria

After implementation:

1. The player has a stats object.
2. The player can receive items.
3. Items are loaded from `.tres` resources in `res://data/items/`.
4. Adding `Sharpened Relic` increases ATK by 2.
5. Adding `Reinforced Plate` increases DEF by 10.
6. Adding `Vital Charm` increases max HP by 10.
7. Adding `Quick Trigger` increases attack speed by 10%.
8. Adding `Lucky Coin` increases Luck by 1.
9. Adding `Light Boots` increases movement speed by 10.
10. Adding `Hunter's Eye` increases crit chance by 10%.
11. Adding `Rusted Fang` gives attacks 10% chance to apply Bleeding.
12. Adding `Toxic Needle` gives attacks 10% chance to apply Poison.
13. Bleeding deals 5% of target max HP per second for 3 seconds, max 1 stack, refreshes duration on reapply.
14. Poison deals 5 flat damage per stack per second for 4 seconds, max 10 stacks, adds stacks and refreshes duration on reapply.
15. `Adrenaline Shell` grants a stacking temporary attack speed buff when breaking containers.
16. `Golden Instinct` grants a stacking temporary Luck buff when breaking containers.
17. `Crusader's Momentum` grants round-limited ATK on enemy kill and clears at round end.
18. `Blood-Sanctified Blade` grants lifesteal from direct player damage only.
19. `Toxic Rupture` applies Poison to enemies near a broken container.
20. `Hunter's Step` grants temporary movement speed on enemy kill.
21. `Open Wound` spreads Bleeding from killed bleeding enemies to nearby enemies.
22. `Chain Judgment` can trigger chain lightning on attack hit.
23. `Solar Ember` can trigger a fireball on attack hit.
24. `Radiant Slide` grants brief movement speed after dash ends.
25. `Bloodbolt Covenant` triggers chain lightning when a bleeding enemy dies.
26. `Storm Greed` makes chain lightning deal 150% ATK damage and allows it to chain to containers using the configured targeting rules.
27. `Plague Comet` makes fireball explosions apply 2 Poison stacks.
28. `Last Venom` transfers Poison stacks from a killed poisoned enemy to the nearest enemy.
29. `Blazing Slide` launches a fireball when dash / slide starts.
30. `Martyr's Fortune` dynamically grants Luck based on missing HP and updates when HP changes.
31. `Chaos Hatch` randomly triggers chain lightning or fireball when a container is directly broken, without infinite recursive container-break loops.
32. No item is hard-coded as a special case in Player.gd.
33. New items can be added later by creating new `.tres` ItemDefinition resources.
---

## 18. Debug Output

Add temporary debug print statements when:

- Item database loads items.
- Player receives an item.
- A stat changes.
- Bleeding is applied.
- Poison is applied.
- Critical hit occurs.
- Temporary buff is added, stacked, refreshed, expired, or cleared at round end.
- Chain lightning triggers.
- Fireball triggers.
- Lifesteal heals the player.
- Legendary effects trigger: bleeding death lightning, poison transfer, dash fireball, missing HP Luck update, and Chaos Hatch.

These can be removed later.

---

## 19. Important Implementation Notes

- Keep all systems modular.
- Avoid putting all item logic in Player.gd.
- Avoid a giant match statement for every individual item ID.
- A small match statement for stat names inside StatsComponent is acceptable.
- Status effects should be reusable by enemies.
- Item data should live in Resource files.
- Use clear comments.
- Prioritize correctness and extensibility over UI polish.
