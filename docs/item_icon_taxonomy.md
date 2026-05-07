# Item Icon Taxonomy

This document maps item mechanics to icon source folders under `assets/items`.
The goal is to make each item family visually recognizable before the player reads the tooltip.

## Core Rules

- Prefer one primary source folder per item family.
- Use `without shadow` source assets only; shadows should be handled by the game UI if needed.
- Rarity should be expressed by UI frame/background, not by changing the item family's icon source.
- Keep icon choices consistent with mechanics first, then flavor second.
- If a specific item does not fit its family folder, record the exception instead of silently mixing folders.

## Current Mapping

| Item / Effect Family | Primary Sprite Folder | Notes |
| --- | --- | --- |
| Flat attack damage | `assets/items/Sword RPG Icons` | For panel ATK and direct attack damage stat items. |
| Attack speed | `assets/items/Bow and Crossbow Vector Icons` | For panel attack speed. The bow/crossbow silhouette reads as rapid attacks. |
| Critical chance / critical damage | `assets/items/48-dagger-rpg-icons` | Daggers fit precision, crit chance, and crit damage. |
| Attack range / attack area | `assets/items/spear-rpg-game-icons` | Reserved for future range/AOE equipment. |
| Movement speed | `assets/items/trousers-rpg-icon-pack` | For panel movement speed. |
| Defense | `assets/items/cuirass-rpg-icon-pack` | For panel defense and armor-like durability. |
| Max HP / health | `assets/items/belt-game-icons` | For panel max HP and survivability. |
| Economy / chest / container rewards | `assets/items/chest-and-treasure-game-icon-set` | For gold, shop, chest, and container economy effects. |
| Triggered buff effects | `assets/items/Elixir Vector Icons` | For temporary or round buffs, including `TriggeredBuffEffect`. |
| Periodic spellcasting | `assets/items/Magic Book Game Icons` | For automatic or periodic spell effects, including spell-like `PeriodicEffect` items. |
| Summons | `assets/items/Magic Book Game Icons` | For turret, dragon, and future summon items. |
| Permanent growth | `assets/items/sigil-rpg-game-icons` | Tentative. Use for now; revisit after testing in UI. |
| Blood / lifesteal / damage-taken rewards | `assets/items/skull-and-bone-rpg-icons` | For lifesteal, blood cost, healing from damage, and pain reward items. |
| Missing HP scaling | `assets/items/_unused/Demon Loot Vector Icons` | For effects that scale directly from current missing HP. Keep visually distinct from generic blood/lifesteal items. |
| Poison | `assets/items/poison-icons` | Curated folder assembled from selected poison-like icons. |
| Bleeding | `assets/items/bleed-icons` | Curated folder assembled from selected bleeding/weapon wound icons. |

## Tentative / Future Decisions

| Family | Status | Candidate Folder |
| --- | --- | --- |
| Permanent growth | Tentative | `assets/items/sigil-rpg-game-icons` |
| Attack range / attack area | Future system | `assets/items/spear-rpg-game-icons` |
| Poison / alchemy / nature | Assigned for poison, unassigned for broader nature | `assets/items/poison-icons`; broader nature can still use `assets/items/Alchemy Plants Vector Icons` or `assets/items/Mushroom RPG Icon Collection` |
| Jewelry / luck / special utility | Unassigned | `assets/items/rings-and-jewelry-game-icons` |
| Scroll-like one-shot magic | Unassigned | `assets/items/48 Scroll RPG Icons` |
| Magic potions / healing potions | Unassigned | `assets/items/48 Magic Potion RPG Icons`, `assets/items/48 Potion RPG Icons` |
| Bone / curse / undead flavor | Assigned for blood items; broader curse still open | `assets/items/skull-and-bone-rpg-icons` |

## Assignment Workflow

1. Identify the item's dominant mechanical family from its effect script and stat target.
2. Pick the primary folder from the mapping above.
3. Select an icon whose object shape matches the item's flavor.
4. Record the chosen icon path in the item resource.
5. If no icon in the primary folder works, add an exception note before using another folder.

## Current Asset Pool

Main folders in `assets/items` should stay focused on item icons. Less suitable monster, sea, pirate, and creature loot packs are parked under `assets/items/_unused` so they can be restored if a future item needs them.

## Item Assignment Checklist

Use this checklist when assigning item sprites. Leave `sprite:` blank until a final icon is chosen.

### Flat Attack Damage

- `sharpened_relic` - Sharpened Relic
  - effect: `StatModifierEffect`, +2 ATK.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Sword RPG Icons\1.png"

### Attack Speed

- `quick_trigger` - Quick Trigger
  - effect: `StatModifierEffect`, +10% attack speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Bow and Crossbow Vector Icons\1.png"

### Critical Chance / Critical Damage

- `hunters_eye` - Hunter's Eye
  - effect: `StatModifierEffect`, +10% critical chance.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\27.png"
- `critical_whetstone` - Critical Whetstone
  - effect: `StatModifierEffect`, +20% critical damage.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\24.png"

### Movement Speed

- `light_boots` - Light Boots
  - effect: `StatModifierEffect`, +10 movement speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\fairy-loot-game-icons\32.png"

### Defense

- `reinforced_plate` - Reinforced Plate
  - effect: `StatModifierEffect`, +10 DEF.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\cuirass-rpg-icon-pack\4.png"

### Max HP / Health

- `vital_charm` - Vital Charm
  - effect: `StatModifierEffect`, +10 max HP.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\belt-game-icons\15.png"

### Economy / Chest / Container Rewards

- `bargain_stamp` - Shop Key
  - effect: `EventEffect`, shop prices reduced by 10%; copies stack multiplicatively.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\chest-and-treasure-game-icon-set\26.png"
- `jar_dividend` - Jar Dividend
  - effect: `EventEffect`, personally breaking a container grants 1 gold.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\chest-and-treasure-game-icon-set\38.png"
- `pain_dividend` - Pain Dividend
  - effect: `EventEffect`, gain 1 gold for every 10 HP lost.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-loot-rpg-icons\27.png"
- `rare_order_ticket` - Rare Order Ticket
  - effect: `EventEffect`, next shop refresh includes one extra rare jar.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\48-pirate-rpg-icons\30.png"
- `scholar_shard` - Scholar Shard
  - effect: `EventEffect`, personally breaking a container grants 1 XP.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\48 Scroll RPG Icons\2.png"
- `shop_refund_charm` - Shop Refund Charm
  - effect: `EventEffect`, breaking a shop jar refunds 10% of its cost, up to 5 times per run.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\chest-and-treasure-game-icon-set\37.png"

### Triggered Buff Effects

- `adrenaline_shell` - Bamboo Wine
  - effect: `TriggeredBuffEffect`, breaking a container grants temporary attack speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Elixir Vector Icons\12.png"
- `crusaders_momentum` - Crusader's Momentum
  - effect: `TriggeredBuffEffect`, killing an enemy grants round ATK.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Elixir Vector Icons\46.png"
- `golden_instinct` - Golden Instinct
  - effect: `TriggeredBuffEffect`, breaking a container grants temporary Luck.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Elixir Vector Icons\8.png"
- `hunters_step` - Hunter's Step
  - effect: `TriggeredBuffEffect`, killing an enemy grants temporary movement speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\pirate-loot-vector-rpg-icons\48.png"
- `radiant_slide` - Radiant Dash
  - effect: `TriggeredBuffEffect`, dash end grants brief movement speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Elixir Vector Icons\35.png"
- `splinter_fury` - Splinter Fury
  - effect: `TriggeredBuffEffect`, personally breaking a container grants round damage.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Elixir Vector Icons\42.png"

### Periodic Spellcasting / Runtime Effects

- `auto_fireball` - Auto Fireball
  - effect: `PeriodicEffect`, periodically launches a Fireball at the nearest enemy.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Magic Book Game Icons\21.png"
- `battle_pulse` - Battle Pulse
  - effect: `PeriodicEffect`, periodically grants attack speed and movement speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Magic Book Game Icons\31.png"
- `blast_mine` - Blast Mine
  - effect: `PeriodicEffect`, periodically places an explosive trap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Magic Book Game Icons\27.png"
- `mirror_ward` - Mirror Ward
  - effect: `PeriodicEffect`, regenerating damage shield.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Magic Book Game Icons\40.png"
- `phase_aegis` - Phase Aegis
  - effect: `PeriodicEffect`, periodic timed invincibility.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Magic Book Game Icons\4.png"
- `sanctified_lens` - Sanctified Lens
  - effect: `PeriodicEffect`, automatically casts Holy Flame Laser.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Magic Book Game Icons\39.png"
- `static_conduit` - Static Conduit
  - effect: `PeriodicEffect`, periodically triggers Chain Lightning.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Magic Book Game Icons\41.png"

### Permanent Growth

- `blood_price_brand` - Blood Price Brand
  - effect: `PermanentGrowthEffect`, losing HP permanently grants ATK with a round cap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\14.png"
- `bone_graft_totem` - Bone Graft Totem
  - effect: `PermanentGrowthEffect`, enemy kills permanently grant max HP with a round cap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\34.png"
- `crimson_grindstone` - Crimson Grindstone
  - effect: `PermanentGrowthEffect`, critical direct attack kills permanently grant critical damage with a round cap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\41.png"
- `elite_luck_charm` - Elite Luck Charm
  - effect: `PermanentGrowthEffect`, elite kills permanently grant Luck.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\40.png"
- `evergrowth_catalyst` - Evergrowth Catalyst
  - effect: `StatModifierEffect`, increases all permanent growth effects per unique permanent growth item.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Alchemy Plants Vector Icons\36.png"
- `goldroot_totem` - Goldroot Totem
  - effect: `PermanentGrowthEffect`, round-start gold permanently grants max HP with a cap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\45.png"
- `jarheart_seed` - Jarheart Seed
  - effect: `PermanentGrowthEffect`, container breaks permanently grant max HP with a round cap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\8.png"
- `patient_whetstone` - Patient Whetstone
  - effect: `PermanentGrowthEffect`, non-critical direct attack kills permanently grant critical chance with a round cap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\36.png"
- `shopguard_plate` - Shopguard Plate
  - effect: `PermanentGrowthEffect`, shop jar breaks permanently grant defense.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\43.png"
- `stillheart_metronome` - Stillheart Metronome
  - effect: `PermanentGrowthEffect`, standing still permanently grants attack speed with a round cap.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\sigil-rpg-game-icons\3.png"
- `untouched_stride` - Untouched Stride
  - effect: `PermanentGrowthEffect`, no-damage round permanently grants movement speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\fairy-loot-game-icons\27.png"

### Blood / Lifesteal / Damage-Taken Rewards

- `blood_claw_sigil` - Blood Claw Sigil
  - effect: `PeriodicEffect`, periodic Blood Claw damage and healing.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-loot-rpg-icons\13.png"
- `blood_price_brand` - Blood Price Brand
  - effect: `PermanentGrowthEffect`, losing HP permanently grants ATK.
  - sprite:
- `blood_renewal_idol` - Blood Renewal Idol
  - effect: `EventEffect`, round start loses current HP then heals over time.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-rpg-icons\24.png"
- `blood_sanctified_blade` - Blood-Sanctified Blade
  - effect: `StatModifierEffect`, +10% lifesteal.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-loot-rpg-icons\3.png"
- `blood_tide_nail` - Blood Tide Nail
  - effect: `PeriodicEffect`, surrounded enemies grant lifesteal.
  - sprite:
- `bloodbolt_covenant` - Bloodbolt Covenant
  - effect: `EventEffect`, bleeding enemy deaths trigger repeated Chain Lightning.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\39.png"

- `delayed_mending` - Delayed Mending
  - effect: `EventEffect`, taking damage heals a portion over time.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Elixir Vector Icons\4.png"

- `merciful_tally` - Merciful Tally
  - effect: `EventEffect`, enemy kills have a chance to heal HP.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-loot-rpg-icons\5.png"
- `pain_dividend` - Pain Dividend
  - effect: `EventEffect`, HP loss grants gold.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-loot-rpg-icons\27.png"

### Missing HP Scaling

- `bloodied_edge` - Bloodied Edge
  - effect: `TriggeredBuffEffect`, missing HP grants ATK.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\30.png"
- `desperate_tempo` - Desperate Tempo
  - effect: `TriggeredBuffEffect`, missing HP grants attack speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\6.png"
- `martyrs_fortune` - Martyr's Fortune
  - effect: `TriggeredBuffEffect`, missing HP grants Luck.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\47.png"
- `panic_stride` - Martyr Hoof
  - effect: `TriggeredBuffEffect`, missing HP grants movement speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\3.png"
- `sanguine_pact` - Bloodthirst
  - effect: `TriggeredBuffEffect`, missing HP grants lifesteal.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\28.png"
- `scarred_regrowth` - Scarred Regrowth
  - effect: `TriggeredBuffEffect`, missing HP grants HP regen per second.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\Demon Loot Vector Icons\37.png"
- `marrow_bow_choir` - Marrow Bow Choir
  - effect: `MissingHpSummonEffect`, missing HP summons Skeleton Archers.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\skull-and-bone-rpg-icons\6.png"

### Poison

- `five_kill_fireburst` - Plague Fire
  - effect: `EventEffect`, poisoned enemy deaths release fireballs.
  - sprite:
- `last_venom` - Last Venom
  - effect: `EventEffect`, poisoned enemy deaths transfer poison stacks.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\poison-icons\sea_loot_rpg_icons_19.png"
- `plague_comet` - Plague Comet
  - effect: `StatModifierEffect`, Fireball explosions apply poison.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\poison-icons\spider_loot_vector_icons_19.png"
- `toxic_needle` - Toxic Blade
  - effect: `StatModifierEffect`, attacks gain poison chance.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\poison-icons\sea_loot_rpg_icons_16.png"
- `toxic_rupture` - Toxic Rupture
  - effect: `EventEffect`, breaking a container poisons nearby enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\poison-icons\daemon_monster_loot_rpg_icons_18.png"

### Bleeding

- `blood_blade_charm` - Blood Blade Charm
  - effect: `PeriodicEffect`, periodic piercing Blood Blade applies bleeding.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\bleed-icons\Sword_RPG_Icons_46.png"
- `bloodbolt_covenant` - Bloodbolt Covenant
  - effect: `EventEffect`, bleeding enemy deaths trigger Chain Lightning.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\bleed-icons\Demon_Loot_Vector_Icons_2.png"
- `open_wound` - Open Wound
  - effect: `StatModifierEffect`, bleeding deals increased damage.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\bleed-icons\mace_rpg_game_icons_3.png"
- `rusted_fang` - Rusted Fang
  - effect: `StatModifierEffect`, attacks gain bleeding chance.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\bleed-icons\Helmet_RPG_Icons_41.png"
- `scarlet_edge` - Scarlet Edge
  - effect: `StatModifierEffect`, direct damage is increased against bleeding enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\mace-rpg-game-icons\46.png"

### Luck / Dodge / Special Utility

- `crowd_crown` - Crowd Crown
  - effect: `EventEffect`, surrounded effects count additional nearby enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\chest-and-treasure-game-icon-set\46.png"
- `golden_instinct` - Golden Instinct
  - effect: `TriggeredBuffEffect`, breaking a container grants temporary Luck.
  - sprite:
- `lucky_coin` - Lucky Coin
  - effect: `StatModifierEffect`, +1 Luck.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\48-pirate-rpg-icons\44.png"
- `lucky_footwork` - Lucky Footwork
  - effect: `StatModifierEffect`, multiplicative dodge chance.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-loot-rpg-icons\44.png"

- `riot_step` - Riot Step
  - effect: `PeriodicEffect`, surrounded enemies grant dodge layers.
  - sprite:

### Triggered Attack Spells

- `blazing_dash` - Blazing Dash
  - effect: `EventEffect`, dashing launches a Fireball.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\_unused\daemon-monster-loot-rpg-icons\23.png"
- `chain_judgment` - Chain Judgment
  - effect: `EventEffect`, attacks can trigger Chain Lightning.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\rings-and-jewelry-game-icons\43.png"
- `chaos_hatch` - Chaos Hatch
  - effect: `EventEffect`, breaking a container randomly triggers Chain Lightning or Fireball.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\rings-and-jewelry-game-icons\30.png"
- `five_kill_fireburst` - Plague Fire
  - effect: `EventEffect`, poisoned enemy deaths release fireballs.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\rings-and-jewelry-game-icons\37.png"
- `solar_ember` - Solar Ember
  - effect: `EventEffect`, attacks can launch an explosive Fireball.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\rings-and-jewelry-game-icons\10.png"
- `storm_greed` - Storm Greed
  - effect: `StatModifierEffect`, modifies Chain Lightning damage and container chaining.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\rings-and-jewelry-game-icons\34.png"

### Summons

- `dragonheart_aerie` - Dragonheart Aerie
  - effect: `EventEffect`, max HP summons following fire dragons.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\48 Scroll RPG Icons\33.png"
- `level_up_turret_core` - Level-Up Turret Core
  - effect: `EventEffect`, leveling up summons a temporary turret.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\48 Scroll RPG Icons\31.png"
- `round_start_turret_battery` - Round Start Turret Battery
  - effect: `EventEffect`, round start summons temporary turrets.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\48 Scroll RPG Icons\39.png"

### Surrounded / Position-Based Runtime Effects

- `blood_tide_nail` - Blood Tide Cap
  - effect: `PeriodicEffect`, surrounding enemies grant lifesteal.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Helmet RPG Icons\48.png"
- `crisis_pulse` - Crisis Cap
  - effect: `PeriodicEffect`, surrounding enemies grant movement speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Helmet RPG Icons\38.png"
- `iron_ring_ward` - Iron Ward
  - effect: `PeriodicEffect`, surrounding enemies grant defense.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Helmet RPG Icons\31.png"
- `packbreaker_brand` - Packbreaker
  - effect: `PeriodicEffect`, surrounding enemies grant attack damage.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Helmet RPG Icons\43.png"
- `riot_step` - Riot Step
  - effect: `PeriodicEffect`, surrounding enemies grant dodge layers.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Helmet RPG Icons\45.png"
- `stillness_trigger` - Stillness Trigger
  - effect: `PeriodicEffect`, standing still grants attack speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Helmet RPG Icons\28.png"
- `surrounded_tempo` - Surrounded Tempo
  - effect: `PeriodicEffect`, surrounding enemies grant attack speed.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\Helmet RPG Icons\39.png"

### Conditional Direct Damage

- `close_quarters_charm` - Close-Quarter Mace
  - effect: `StatModifierEffect`, increased direct damage to nearby enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\mace-rpg-game-icons\1.png"
- `elite_hunter_badge` - Elite Hunter
  - effect: `StatModifierEffect`, increased direct damage to elite enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\mace-rpg-game-icons\44.png"
- `execution_mark` - Executioner
  - effect: `StatModifierEffect`, increased direct damage to low-HP enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\mace-rpg-game-icons\45.png"
- `longshot_emblem` - Longshot Mace
  - effect: `StatModifierEffect`, increased direct damage to distant enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\mace-rpg-game-icons\15.png"
- `opening_strike` - Opening Strike
  - effect: `StatModifierEffect`, increased direct damage to high-HP enemies.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\mace-rpg-game-icons\32.png"
- `revenge_round` - Slaught
  - effect: `EventEffect`, enemy kills empower the next direct attack.
  - sprite:"C:\Users\2jonl\OneDrive\Documents\dino-zombie-and-jar\assets\items\mace-rpg-game-icons\20.png"
