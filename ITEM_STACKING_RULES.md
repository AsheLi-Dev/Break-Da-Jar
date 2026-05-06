# Item Stacking Rules

Item effects default to `stacking_rule = "linear"` unless a resource says otherwise.

## Rules

- `linear`: each copy applies its full effect independently.
- `additive_stat`: explicit linear stat increase, used for readability on stat resources.
- `multiplicative`: each copy multiplies the current value. Example: shop price `0.9 * 0.9`.
- `chance_multiplicative`: chance stacks by multiplying failure rates. Example: 10% dodge per copy is `1 - 0.9^copies`.
- `pickup_once`: effect is applied once when the item copy is obtained.
- `shared_counter_cap_per_copy`: copies share one event counter; extra copies increase the cap/reward capacity, not event counting rate.
- `shared_counter_scaled_effect`: copies share one event counter; the triggered effect scales by copy count.
- `shared_limited_trigger_scaled_by_copies`: copies share one trigger limit; the effect value scales by copy count.
- `shared_trigger_scaled_by_copies`: trigger happens once, but the triggered effect scales by item count.
- `shared_runtime_scaled`: one runtime monitor reads current item count and scales output; extra copies do not create extra monitors.
- `summon_count_by_stat_per_copy`: one monitor controls summons from a stat threshold; item count multiplies summon count.
- `linear_summon_count`: each copy adds another summon on the same event.
- `unique_set`: sets/unlocks a behavior; extra copies do not stack unless the resource explicitly says otherwise.

## Explicit Special Cases

- `bargain_stamp`: `multiplicative`
- `lucky_footwork`: `chance_multiplicative`
- `solar_ember`, `chain_judgment`, `merciful_tally`: `chance_multiplicative`
- `bone_graft_totem`: `shared_counter_cap_per_copy`
- `blood_renewal_idol`: `shared_trigger_scaled_by_copies`
- `crowd_crown`: first copy grants +3 surrounded enemy count; extra copies grant +1.
- `dragonheart_aerie`: `summon_count_by_stat_per_copy`
- `surrounded_tempo`, `iron_ring_ward`, `packbreaker_brand`, `blood_tide_nail`, `crisis_pulse`, `riot_step`: `shared_runtime_scaled`
- `stillness_trigger`: `shared_runtime_scaled`
- `five_kill_fireburst`: `shared_counter_scaled_effect`
- `level_up_turret_core`, `round_start_turret_battery`: `linear_summon_count`
- `shop_refund_charm`: `shared_limited_trigger_scaled_by_copies`
- `rare_order_ticket`: currently each copy queues one extra rare jar when obtained.

## Needs Design Decision

These are mechanically valid today, but their stacking intent should be confirmed:

- Unique mechanics such as `storm_greed`, `last_venom`, `blazing_dash`, `chaos_hatch`: should duplicates be disabled, duplicate effects, or scale parameters?
