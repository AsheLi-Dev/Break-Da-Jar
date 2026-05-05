extends Resource
class_name StatsComponent

signal stat_changed(stat_name: StringName, value: Variant)

@export var atk: int = 0
@export var defense: int = 0
@export var max_hp: int = 100
@export var luck: int = 0
@export var base_move_speed: float = 240.0
@export var bonus_move_speed_flat: float = 0.0
@export var attack_speed_bonus: float = 0.0
@export var movement_speed_bonus: float = 0.0
@export var critical_chance: float = 0.0
@export var bleed_chance: float = 0.0
@export var poison_chance: float = 0.0
@export var lifesteal: float = 0.0
@export var chain_lightning_chance: float = 0.0
@export var fireball_chance: float = 0.0
@export var chain_lightning_damage_scale_override: float = -1.0
@export var chain_lightning_can_target_containers: bool = false
@export var fireball_poison_stacks: int = 0


func apply_modifier(stat_name: StringName, operation: StringName, value: float) -> void:
	match operation:
		&"set":
			_set_stat(stat_name, value)
		&"multiply_add":
			_add_stat(stat_name, _get_numeric_stat(stat_name) * value)
		_:
			_add_stat(stat_name, value)


func add_runtime_modifier(stat_name: StringName, value: float) -> void:
	_add_stat(stat_name, value)


func remove_runtime_modifier(stat_name: StringName, value: float) -> void:
	_add_stat(stat_name, -value)


func get_damage_multiplier() -> float:
	return 1.0 + float(atk) * 0.02


func get_damage_reduction() -> float:
	return float(defense) / float(defense + 100)


func calculate_incoming_damage(raw_damage: float) -> int:
	var final_damage: float = raw_damage * (1.0 - get_damage_reduction())
	return maxi(1, roundi(final_damage))


func get_attack_interval(base_interval: float) -> float:
	return base_interval / maxf(1.0 + attack_speed_bonus, 0.1)


func get_move_speed(base_speed: float) -> float:
	return (base_speed + bonus_move_speed_flat) * maxf(1.0 + movement_speed_bonus, 0.1)


func _add_stat(stat_name: StringName, value: float) -> void:
	match stat_name:
		&"atk":
			atk += int(round(value))
			_emit_change(stat_name, atk)
		&"defense":
			defense += int(round(value))
			_emit_change(stat_name, defense)
		&"max_hp":
			max_hp += int(round(value))
			_emit_change(stat_name, max_hp)
		&"luck":
			luck += int(round(value))
			_emit_change(stat_name, luck)
		&"base_move_speed":
			base_move_speed += value
			_emit_change(stat_name, base_move_speed)
		&"bonus_move_speed_flat":
			bonus_move_speed_flat += value
			_emit_change(stat_name, bonus_move_speed_flat)
		&"attack_speed_bonus":
			attack_speed_bonus += value
			_emit_change(stat_name, attack_speed_bonus)
		&"movement_speed_bonus":
			movement_speed_bonus += value
			_emit_change(stat_name, movement_speed_bonus)
		&"critical_chance":
			critical_chance = clampf(critical_chance + value, 0.0, 1.0)
			_emit_change(stat_name, critical_chance)
		&"bleed_chance":
			bleed_chance = clampf(bleed_chance + value, 0.0, 1.0)
			_emit_change(stat_name, bleed_chance)
		&"poison_chance":
			poison_chance = clampf(poison_chance + value, 0.0, 1.0)
			_emit_change(stat_name, poison_chance)
		&"lifesteal":
			lifesteal = maxf(0.0, lifesteal + value)
			_emit_change(stat_name, lifesteal)
		&"chain_lightning_chance":
			chain_lightning_chance = clampf(chain_lightning_chance + value, 0.0, 1.0)
			_emit_change(stat_name, chain_lightning_chance)
		&"fireball_chance":
			fireball_chance = clampf(fireball_chance + value, 0.0, 1.0)
			_emit_change(stat_name, fireball_chance)
		&"chain_lightning_damage_scale_override":
			chain_lightning_damage_scale_override += value
			_emit_change(stat_name, chain_lightning_damage_scale_override)
		&"chain_lightning_can_target_containers":
			chain_lightning_can_target_containers = value >= 1.0
			_emit_change(stat_name, chain_lightning_can_target_containers)
		&"fireball_poison_stacks":
			fireball_poison_stacks += int(round(value))
			_emit_change(stat_name, fireball_poison_stacks)
		_:
			push_warning("Unknown stat modifier: %s" % stat_name)


func _set_stat(stat_name: StringName, value: float) -> void:
	match stat_name:
		&"chain_lightning_can_target_containers":
			chain_lightning_can_target_containers = value >= 1.0
			_emit_change(stat_name, chain_lightning_can_target_containers)
		&"chain_lightning_damage_scale_override":
			chain_lightning_damage_scale_override = value
			_emit_change(stat_name, chain_lightning_damage_scale_override)
		_:
			var current: float = _get_numeric_stat(stat_name)
			_add_stat(stat_name, value - current)


func _get_numeric_stat(stat_name: StringName) -> float:
	match stat_name:
		&"atk":
			return atk
		&"defense":
			return defense
		&"max_hp":
			return max_hp
		&"luck":
			return luck
		&"base_move_speed":
			return base_move_speed
		&"bonus_move_speed_flat":
			return bonus_move_speed_flat
		&"attack_speed_bonus":
			return attack_speed_bonus
		&"movement_speed_bonus":
			return movement_speed_bonus
		&"critical_chance":
			return critical_chance
		&"bleed_chance":
			return bleed_chance
		&"poison_chance":
			return poison_chance
		&"lifesteal":
			return lifesteal
		&"chain_lightning_chance":
			return chain_lightning_chance
		&"fireball_chance":
			return fireball_chance
		&"chain_lightning_damage_scale_override":
			return chain_lightning_damage_scale_override
		&"fireball_poison_stacks":
			return fireball_poison_stacks
		_:
			return 0.0


func _emit_change(stat_name: StringName, value: Variant) -> void:
	print("Stat changed: %s = %s" % [stat_name, value])
	stat_changed.emit(stat_name, value)
