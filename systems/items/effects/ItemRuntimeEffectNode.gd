extends Node
class_name ItemRuntimeEffectNode

var owner_player: Node
var item_id: StringName
var effect_type: StringName
var stat_name: StringName
var value: float = 0.0
var duration: float = 0.0
var max_stacks: int = 1
var radius: float = 0.0
var damage_scale: float = 0.0
var internal_cooldown: float = 0.0

var applied_bonus: float = 0.0
var stationary_time: float = 0.0
var linger_remaining: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var periodic_remaining: float = 0.0


func setup(
	new_owner: Node,
	new_item_id: StringName,
	new_effect_type: StringName,
	new_stat_name: StringName,
	new_value: float,
	new_duration: float,
	new_max_stacks: int,
	new_radius: float,
	new_damage_scale: float,
	new_internal_cooldown: float
) -> void:
	owner_player = new_owner
	item_id = new_item_id
	effect_type = new_effect_type
	stat_name = new_stat_name
	value = new_value
	duration = new_duration
	max_stacks = new_max_stacks
	radius = new_radius
	damage_scale = new_damage_scale
	internal_cooldown = new_internal_cooldown
	periodic_remaining = internal_cooldown

	var owner_2d := owner_player as Node2D
	if owner_2d != null:
		last_position = owner_2d.global_position


func _process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return

	match effect_type:
		&"nearby_enemy_attack_speed":
			_update_nearby_enemy_attack_speed()
		&"stationary_attack_speed":
			_update_stationary_attack_speed(delta)
		&"periodic_timed_stat_buff":
			_update_periodic_timed_stat_buff(delta)


func _update_nearby_enemy_attack_speed() -> void:
	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var enemies_nearby: int = 0
	for enemy in owner_player.get_tree().get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d != null and is_instance_valid(enemy_2d) and enemy_2d.global_position.distance_to(owner_2d.global_position) <= radius:
			enemies_nearby += 1

	var item_count: int = _get_item_count()
	var per_enemy_bonus: float = value + damage_scale * float(maxi(item_count - 1, 0))
	var cap: float = duration * float(item_count)
	_set_dynamic_bonus(minf(float(enemies_nearby) * per_enemy_bonus, cap))


func _update_stationary_attack_speed(delta: float) -> void:
	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var moved: bool = owner_2d.global_position.distance_squared_to(last_position) > 1.0
	last_position = owner_2d.global_position
	if moved:
		if stationary_time >= duration:
			linger_remaining = radius
		stationary_time = 0.0
	else:
		stationary_time += delta

	linger_remaining = maxf(0.0, linger_remaining - delta)
	var active: bool = stationary_time >= duration or linger_remaining > 0.0
	var wanted_bonus: float = 0.0
	if active:
		wanted_bonus = value * float(_get_item_count())
	_set_dynamic_bonus(wanted_bonus)


func _update_periodic_timed_stat_buff(delta: float) -> void:
	if internal_cooldown <= 0.0:
		return

	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	periodic_remaining += internal_cooldown
	var buffs: TemporaryBuffComponent = null
	if owner_player.has_method("get_temporary_buffs"):
		buffs = owner_player.get_temporary_buffs()
	if buffs != null:
		buffs.add_timed_stat_buff(StringName("%s_%s_%s" % [item_id, stat_name, get_instance_id()]), stat_name, value, duration, max_stacks)


func _set_dynamic_bonus(wanted_bonus: float) -> void:
	if is_equal_approx(wanted_bonus, applied_bonus):
		return

	var buffs: TemporaryBuffComponent = null
	if owner_player.has_method("get_temporary_buffs"):
		buffs = owner_player.get_temporary_buffs()
	if buffs != null:
		buffs.set_dynamic_stat_bonus(StringName("%s_%s_%s" % [item_id, effect_type, stat_name]), stat_name, wanted_bonus)
	applied_bonus = wanted_bonus


func _get_item_count() -> int:
	if owner_player != null and owner_player.has_method("get_item_count"):
		return maxi(int(owner_player.get_item_count(item_id)), 1)
	return 1
