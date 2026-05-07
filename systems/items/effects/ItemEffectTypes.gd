extends RefCounted
class_name ItemEffectTypes

const APPLY_POISON_NEAR_CONTAINER := &"apply_poison_near_container"
const AUTO_HOLY_FLAME_LASER := &"auto_holy_flame_laser"
const CHAIN_LIGHTNING := &"chain_lightning"
const CHAIN_LIGHTNING_ON_BLEEDING_DEATH := &"chain_lightning_on_bleeding_death"
const CHANCE_HEAL_ON_KILL := &"chance_heal_on_kill"
const CONTAINER_BREAK_RANDOM_PROC := &"container_break_random_proc"
const DIRECT_CONTAINER_BREAK_EXP := &"direct_container_break_exp"
const DIRECT_CONTAINER_BREAK_GOLD := &"direct_container_break_gold"
const DIRECT_CONTAINER_BREAK_ROUND_DAMAGE := &"direct_container_break_round_damage"
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
const MISSING_HP_STAT_BONUS := &"missing_hp_stat_bonus"
const NEARBY_ENEMY_ATTACK_SPEED := &"nearby_enemy_attack_speed"
const NEXT_ATTACK_DAMAGE_AFTER_KILL := &"next_attack_damage_after_kill"
const NO_DAMAGE_ROUND_PERMANENT_STAT := &"no_damage_round_permanent_stat"
const PERMANENT_STAT_ELITE_KILL := &"permanent_stat_elite_kill"
const PERMANENT_STAT_EVERY_HP_LOST_ROUND_CAP := &"permanent_stat_every_hp_lost_round_cap"
const PERMANENT_STAT_PER_GOLD_ON_ROUND_START := &"permanent_stat_per_gold_on_round_start"
const PERMANENT_STAT_PLAYER_CONTAINER_ROUND_CAP := &"permanent_stat_player_container_round_cap"
const PERMANENT_STAT_SHOP_CONTAINER_SCALED := &"permanent_stat_shop_container_scaled"
const PERMANENT_STAT_STATIONARY_ROUND_CAP := &"permanent_stat_stationary_round_cap"
const PERMANENT_STAT_ATTACK_KILL_CRIT_STATE_ROUND_CAP := &"permanent_stat_attack_kill_crit_state_round_cap"
const PERIODIC_AUTO_FIREBALL := &"periodic_auto_fireball"
const PERIODIC_BLOOD_BLADE := &"periodic_blood_blade"
const PERIODIC_BLOOD_CLAW := &"periodic_blood_claw"
const PERIODIC_CHAIN_LIGHTNING := &"periodic_chain_lightning"
const PERIODIC_DAMAGE_SHIELD := &"periodic_damage_shield"
const PERIODIC_EXPLOSIVE_TRAP := &"periodic_explosive_trap"
const PERIODIC_INVINCIBILITY := &"periodic_invincibility"
const PERIODIC_TIMED_STAT_BUFF := &"periodic_timed_stat_buff"
const POISON_TRANSFER_ON_DEATH := &"poison_transfer_on_death"
const QUEUE_EXTRA_RARE_SHOP_JAR := &"queue_extra_rare_shop_jar"
const REFUND_GOLD_ON_SHOP_CONTAINER_BREAK := &"refund_gold_on_shop_container_break"
const ROUND_STAT_BUFF := &"round_stat_buff"
const SHOP_PRICE_MULTIPLIER := &"shop_price_multiplier"
const SPREAD_BLEEDING_ON_DEATH := &"spread_bleeding_on_death"
const STAT_BONUS_EVERY_N_KILLS_SHARED := &"stat_bonus_every_n_kills_shared"
const STATIONARY_ATTACK_SPEED := &"stationary_attack_speed"
const SURROUNDED_STAT_BONUS := &"surrounded_stat_bonus"
const SUMMON_TURRET_ON_LEVEL_UP := &"summon_turret_on_level_up"
const SUMMON_TURRETS_ON_ROUND_START := &"summon_turrets_on_round_start"
const TIMED_STAT_BUFF := &"timed_stat_buff"


static func all() -> Array[StringName]:
	return [
		APPLY_POISON_NEAR_CONTAINER,
		AUTO_HOLY_FLAME_LASER,
		CHAIN_LIGHTNING,
		CHAIN_LIGHTNING_ON_BLEEDING_DEATH,
		CHANCE_HEAL_ON_KILL,
		CONTAINER_BREAK_RANDOM_PROC,
		DIRECT_CONTAINER_BREAK_EXP,
		DIRECT_CONTAINER_BREAK_GOLD,
		DIRECT_CONTAINER_BREAK_ROUND_DAMAGE,
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
		MISSING_HP_STAT_BONUS,
		NEARBY_ENEMY_ATTACK_SPEED,
		NEXT_ATTACK_DAMAGE_AFTER_KILL,
		NO_DAMAGE_ROUND_PERMANENT_STAT,
		PERMANENT_STAT_ELITE_KILL,
		PERMANENT_STAT_EVERY_HP_LOST_ROUND_CAP,
		PERMANENT_STAT_PER_GOLD_ON_ROUND_START,
		PERMANENT_STAT_PLAYER_CONTAINER_ROUND_CAP,
		PERMANENT_STAT_SHOP_CONTAINER_SCALED,
		PERMANENT_STAT_STATIONARY_ROUND_CAP,
		PERMANENT_STAT_ATTACK_KILL_CRIT_STATE_ROUND_CAP,
		PERIODIC_AUTO_FIREBALL,
		PERIODIC_BLOOD_BLADE,
		PERIODIC_BLOOD_CLAW,
		PERIODIC_CHAIN_LIGHTNING,
		PERIODIC_DAMAGE_SHIELD,
		PERIODIC_EXPLOSIVE_TRAP,
		PERIODIC_INVINCIBILITY,
		PERIODIC_TIMED_STAT_BUFF,
		POISON_TRANSFER_ON_DEATH,
		QUEUE_EXTRA_RARE_SHOP_JAR,
		REFUND_GOLD_ON_SHOP_CONTAINER_BREAK,
		ROUND_STAT_BUFF,
		SHOP_PRICE_MULTIPLIER,
		SPREAD_BLEEDING_ON_DEATH,
		STAT_BONUS_EVERY_N_KILLS_SHARED,
		STATIONARY_ATTACK_SPEED,
		SURROUNDED_STAT_BONUS,
		SUMMON_TURRET_ON_LEVEL_UP,
		SUMMON_TURRETS_ON_ROUND_START,
		TIMED_STAT_BUFF,
	]


static func is_periodic_runtime(effect_type: StringName) -> bool:
	return [
		PERIODIC_AUTO_FIREBALL,
		PERIODIC_CHAIN_LIGHTNING,
		PERIODIC_BLOOD_CLAW,
		PERIODIC_BLOOD_BLADE,
		PERIODIC_EXPLOSIVE_TRAP,
		PERIODIC_INVINCIBILITY,
		PERIODIC_DAMAGE_SHIELD,
	].has(effect_type)


static func is_runtime_monitor(effect_type: StringName) -> bool:
	return [
		NEARBY_ENEMY_ATTACK_SPEED,
		STATIONARY_ATTACK_SPEED,
		PERMANENT_STAT_STATIONARY_ROUND_CAP,
		SURROUNDED_STAT_BONUS,
		AUTO_HOLY_FLAME_LASER,
		PERIODIC_TIMED_STAT_BUFF,
	].has(effect_type) or is_periodic_runtime(effect_type)
