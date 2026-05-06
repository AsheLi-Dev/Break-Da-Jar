# Item Effect Catalog

Use this file to assign stacking rules per effect or per item.

## Already Decided

| Effect / Stat | Items | Rule |
|---|---|---|
| `shop_price_multiplier` | `bargain_stamp` | multiplicative |
| `dodge_chance_multiplier` | `lucky_footwork` | chance_multiplicative |
| `fireball` proc chance | `solar_ember` | chance_multiplicative |
| `chain_lightning` proc chance | `chain_judgment` | chance_multiplicative |
| `chance_heal_on_kill` | `merciful_tally` | chance_multiplicative |
| `fireballs_every_n_kills` | `five_kill_fireburst` | shared 5-kill counter, +2 fireballs per copy |
| `summon_turret_on_level_up` | `level_up_turret_core` | +1 turret per copy |
| `summon_turrets_on_round_start` | `round_start_turret_battery` | +2 turrets per copy |
| `refund_gold_on_shop_container_break` | `shop_refund_charm` | shared trigger limit, +10% refund rate per copy |
| `stat_bonus_every_n_kills_shared` | `bone_graft_totem` | shared kill counter, cap +50 max HP per copy |
| `lose_current_hp_percent_then_heal_over_time` | `blood_renewal_idol` | lose HP once, healing scales by copies |
| `fire_dragons_per_max_hp` | `dragonheart_aerie` | dragon count = floor(max HP / 100) * copies |
| `nearby_enemy_attack_speed` | `surrounded_tempo` | one monitor, special per-copy scaling |
| `stationary_attack_speed` | `stillness_trigger` | one monitor, value stacks, duration does not |

## Needs Your Rule

| Effect / Stat | Items | Current Behavior |
|---|---|---|
| flat stat add: `atk` | `sharpened_relic` | linear add |
| flat stat add: `max_hp` | `vital_charm` | linear add |
| flat stat add: `defense` | `reinforced_plate` | linear add |
| flat stat add: `luck` | `lucky_coin` | linear add |
| flat stat add: `bonus_move_speed_flat` | `light_boots` | linear add |
| percent stat add: `attack_speed_bonus` | `quick_trigger` | linear add |
| percent stat add: `critical_chance` | `hunters_eye` | linear add, clamped to 100% |
| percent stat add: `bleed_chance` | `rusted_fang` | linear add, clamped to 100% |
| percent stat add: `poison_chance` | `toxic_needle` | linear add, clamped to 100% |
| percent stat add: `lifesteal` | `blood_sanctified_blade` | linear add |
| conditional direct damage | `elite_hunter_badge`, `execution_mark`, `opening_strike`, `close_quarters_charm`, `longshot_emblem` | linear stat add, multiplicative during damage calculation |
| `critical_damage_bonus` | `critical_whetstone` | linear add |
| `fireball_poison_stacks` | `plague_comet` | linear add |
| `chain_lightning_damage_scale_override` + container targeting | `storm_greed` | set/unique-like; duplicate behavior not defined |
| `timed_stat_buff` | `adrenaline_shell`, `golden_instinct`, `hunters_step`, `radiant_slide` | each copy has its own buff instance |
| `round_stat_buff` | `crusaders_momentum`, `splinter_fury` | stacks up to `max_stacks`; copies currently separate |
| `periodic_timed_stat_buff` | `battle_pulse` | each copy creates a periodic source |
| `missing_hp_stat_bonus` | `martyrs_fortune`, `bloodied_edge`, `desperate_tempo`, `sanguine_pact` | each copy creates a dynamic bonus |
| `apply_poison_near_container` | `toxic_rupture` | each copy listens and applies effect |
| `spread_bleeding_on_death` | `open_wound` | each copy listens and applies effect |
| `chain_lightning_on_bleeding_death` | `bloodbolt_covenant` | each copy listens and triggers |
| `poison_transfer_on_death` | `last_venom` | each copy listens and transfers |
| `fireball_on_dash` | `blazing_dash` | each copy launches one fireball with spread |
| `container_break_random_proc` | `chaos_hatch` | each copy rolls/triggers separately |
| `heal_over_time_after_damage_taken` | `delayed_mending` | each copy heals independently |
| `gold_every_hp_lost` | `pain_dividend` | each copy tracks HP loss independently |
| `direct_container_break_exp` | `scholar_shard` | each copy gives +1 XP |
| `direct_container_break_gold` | `jar_dividend` | each copy gives +1 gold |
| `queue_extra_rare_shop_jar` | `rare_order_ticket` | each copy queues +1 rare jar once when obtained |
| `next_attack_damage_after_kill` | `revenge_round` | each copy adds +50% to next attack |
