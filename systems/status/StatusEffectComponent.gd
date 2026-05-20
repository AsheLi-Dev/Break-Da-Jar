extends Node
class_name StatusEffectComponent

@export var bleeding_duration: float = 3.0
@export var bleeding_max_hp_damage_per_second: float = 0.05
@export var poison_duration: float = 4.0
@export var poison_damage_per_stack: float = 5.0
@export var poison_max_stacks: int = 10
@export var stun_duration: float = 1.0

var owner_enemy: EnemyBase
var status_owner_player: Node
var bleeding_time_left: float = 0.0
var poison_time_left: float = 0.0
var poison_stacks: int = 0
var stun_time_left: float = 0.0
var dot_tick_timer: float = 0.0


func setup(enemy: EnemyBase) -> void:
	owner_enemy = enemy


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if owner_enemy == null or owner_enemy.is_dead:
		return

	bleeding_time_left = maxf(0.0, bleeding_time_left - delta)
	poison_time_left = maxf(0.0, poison_time_left - delta)
	stun_time_left = maxf(0.0, stun_time_left - delta)
	if poison_time_left <= 0.0:
		poison_stacks = 0

	dot_tick_timer += delta
	while dot_tick_timer >= 1.0:
		dot_tick_timer -= 1.0
		_apply_dot_tick()


func apply_status_effect(id: StringName, source_player: Node = null) -> void:
	match id:
		&"bleeding":
			apply_bleeding(source_player)
		&"poison":
			apply_poison(source_player)
		&"stun":
			apply_stun(source_player)


func apply_bleeding(source_player: Node = null) -> void:
	bleeding_time_left = bleeding_duration
	if source_player != null and is_instance_valid(source_player):
		status_owner_player = source_player
		_apply_bleeding_move_speed_slow(source_player)


func apply_poison(source_player: Node = null) -> void:
	apply_poison_stacks(1, source_player)


func apply_poison_stacks(amount: int, source_player: Node = null) -> void:
	poison_stacks = clampi(poison_stacks + amount, 0, poison_max_stacks)
	poison_time_left = poison_duration
	if source_player != null and is_instance_valid(source_player):
		status_owner_player = source_player


func apply_stun(source_player: Node = null) -> void:
	apply_stun_duration(stun_duration, source_player)


func apply_stun_duration(duration: float, source_player: Node = null) -> void:
	stun_time_left = maxf(stun_time_left, duration)
	if source_player != null and is_instance_valid(source_player):
		status_owner_player = source_player


func get_poison_stacks() -> int:
	return poison_stacks


func get_stun_time_left() -> float:
	return stun_time_left


func has_status(id: StringName) -> bool:
	match id:
		&"bleeding":
			return bleeding_time_left > 0.0
		&"poison":
			return poison_time_left > 0.0 and poison_stacks > 0
		&"stun":
			return stun_time_left > 0.0
		_:
			return false


func _apply_dot_tick() -> void:
	var damage_source := _get_valid_status_owner()
	if bleeding_time_left > 0.0:
		var bleed_damage: float = maxf(1.0, owner_enemy.max_hp * bleeding_max_hp_damage_per_second)
		bleed_damage *= _get_bleeding_damage_multiplier(damage_source)
		owner_enemy.take_damage(bleed_damage, damage_source, {"source": "bleeding", "direct": false})

	if owner_enemy == null or owner_enemy.is_dead:
		return

	if poison_time_left > 0.0 and poison_stacks > 0:
		var poison_damage: float = poison_damage_per_stack * float(poison_stacks)
		owner_enemy.take_damage(poison_damage, damage_source, {"source": "poison", "direct": false})


func _get_valid_status_owner() -> Node:
	if status_owner_player != null and is_instance_valid(status_owner_player):
		return status_owner_player

	status_owner_player = null
	return null


func _get_bleeding_damage_multiplier(source: Node) -> float:
	if source == null or not source.has_method("get_stats"):
		return 1.0

	var stats: StatsComponent = source.get_stats()
	if stats == null:
		return 1.0
	return maxf(1.0 + stats.bleeding_damage_bonus, 0.0)


func _apply_bleeding_move_speed_slow(source: Node) -> void:
	if owner_enemy == null or not source.has_method("get_bleeding_move_speed_multiplier"):
		return
	var multiplier := float(source.call("get_bleeding_move_speed_multiplier"))
	if multiplier >= 1.0:
		return
	owner_enemy.apply_temporary_move_speed_multiplier(&"bleeding_move_speed_slow", multiplier, bleeding_duration)
