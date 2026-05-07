extends RefCounted
class_name ItemEffectTypes

const APPLY_POISON_NEAR_CONTAINER := &"apply_poison_near_container"
const CHAIN_LIGHTNING := &"chain_lightning"
const CHAIN_LIGHTNING_ON_BLEEDING_DEATH := &"chain_lightning_on_bleeding_death"
const CHANCE_HEAL_ON_KILL := &"chance_heal_on_kill"
const CONTAINER_BREAK_RANDOM_PROC := &"container_break_random_proc"
const DIRECT_CONTAINER_BREAK_EXP := &"direct_container_break_exp"
const DIRECT_CONTAINER_BREAK_GOLD := &"direct_container_break_gold"
const FIRE_DRAGONS_PER_MAX_HP := &"fire_dragons_per_max_hp"
const FIREBALL := &"fireball"
const FIREBALL_ON_DASH := &"fireball_on_dash"
const FIREBALL_SEQUENCE_ON_KILL := &"fireball_sequence_on_kill"
const FIREBALL_SEQUENCE_ON_POISONED_DEATH := &"fireball_sequence_on_poisoned_death"
const FIREBALLS_EVERY_N_KILLS := &"fireballs_every_n_kills"
const FIRST_COPY_STAT_BONUS := &"first_copy_stat_bonus"
const GOLD_EVERY_HP_LOST := &"gold_every_hp_lost"
const HEAL_OVER_TIME_AFTER_DAMAGE_TAKEN := &"heal_over_time_after_damage_taken"
const LIFESTEAL := &"lifesteal"
const LOSE_CURRENT_HP_PERCENT_THEN_HEAL_OVER_TIME := &"lose_current_hp_percent_then_heal_over_time"
const NEXT_ATTACK_DAMAGE_AFTER_KILL := &"next_attack_damage_after_kill"
const POISON_TRANSFER_ON_DEATH := &"poison_transfer_on_death"
const QUEUE_EXTRA_RARE_SHOP_JAR := &"queue_extra_rare_shop_jar"
const REFUND_GOLD_ON_SHOP_CONTAINER_BREAK := &"refund_gold_on_shop_container_break"
const SHOP_PRICE_MULTIPLIER := &"shop_price_multiplier"
const SPREAD_BLEEDING_ON_DEATH := &"spread_bleeding_on_death"
const SUMMON_TURRET_ON_LEVEL_UP := &"summon_turret_on_level_up"
const SUMMON_TURRETS_ON_ROUND_START := &"summon_turrets_on_round_start"


static func all() -> Array[StringName]:
	return [
		APPLY_POISON_NEAR_CONTAINER,
		CHAIN_LIGHTNING,
		CHAIN_LIGHTNING_ON_BLEEDING_DEATH,
		CHANCE_HEAL_ON_KILL,
		CONTAINER_BREAK_RANDOM_PROC,
		DIRECT_CONTAINER_BREAK_EXP,
		DIRECT_CONTAINER_BREAK_GOLD,
		FIRE_DRAGONS_PER_MAX_HP,
		FIREBALL,
		FIREBALL_ON_DASH,
		FIREBALL_SEQUENCE_ON_KILL,
		FIREBALL_SEQUENCE_ON_POISONED_DEATH,
		FIREBALLS_EVERY_N_KILLS,
		FIRST_COPY_STAT_BONUS,
		GOLD_EVERY_HP_LOST,
		HEAL_OVER_TIME_AFTER_DAMAGE_TAKEN,
		LIFESTEAL,
		LOSE_CURRENT_HP_PERCENT_THEN_HEAL_OVER_TIME,
		NEXT_ATTACK_DAMAGE_AFTER_KILL,
		POISON_TRANSFER_ON_DEATH,
		QUEUE_EXTRA_RARE_SHOP_JAR,
		REFUND_GOLD_ON_SHOP_CONTAINER_BREAK,
		SHOP_PRICE_MULTIPLIER,
		SPREAD_BLEEDING_ON_DEATH,
		SUMMON_TURRET_ON_LEVEL_UP,
		SUMMON_TURRETS_ON_ROUND_START,
	]
