extends ItemEffect
class_name EventEffect

const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")

@export var event_name: StringName
@export var effect_type: StringName
@export var stat_name: StringName
@export var value: float = 0.0
@export var duration: float = 0.0
@export var max_stacks: int = 1
@export var radius: float = 0.0
@export var chance: float = 1.0
@export var damage_scale: float = 1.0
@export var chain_count: int = 0
@export var internal_cooldown: float = 0.0
@export var status_id: StringName
@export var poison_stacks: int = 0
@export var choices: Array[StringName] = []
@export var only_direct_container_breaks: bool = true
@export var lightning_vfx_lifetime: float = 0.12
@export var lightning_vfx_width: float = 7.0
@export var lightning_vfx_color: Color = Color(0.45, 0.85, 1.0, 0.95)
@export var container_proc_delay: float = 0.12
@export var duplicate_projectile_spread_degrees: float = 8.0
@export var dash_fireball_auto_aim_radius: float = 600.0

var owner_player: Node
var cooldown_remaining: float = 0.0
var item_id: StringName
var item_effect_index: int = 0
var item_stack_index: int = 0


func configure_instance(new_item_id: StringName, new_effect_index: int, new_stack_index: int) -> void:
	item_id = new_item_id
	item_effect_index = new_effect_index
	item_stack_index = new_stack_index


func apply_to(player: Node) -> void:
	owner_player = player
	if not player.has_signal(event_name):
		push_warning("Player signal missing: %s" % event_name)
		return

	var callable := Callable(self, "_on_player_event")
	if not player.is_connected(event_name, callable):
		player.connect(event_name, callable)


func _on_player_event(arg1: Variant = null, arg2: Variant = null, arg3: Variant = null) -> void:
	if owner_player == null:
		return
	if cooldown_remaining > 0.0:
		return
	if randf() > chance:
		return

	if internal_cooldown > 0.0:
		cooldown_remaining = internal_cooldown
		_start_cooldown_timer()

	match effect_type:
		&"timed_stat_buff":
			_add_timed_buff()
		&"round_stat_buff":
			_add_round_buff()
		&"apply_poison_near_container":
			_apply_poison_near_position(_extract_position(arg1), 1)
		&"spread_bleeding_on_death":
			_spread_bleeding_on_death(arg1)
		&"chain_lightning":
			_trigger_chain_lightning(_get_effect_origin(arg1), _get_initial_chain_excludes(arg1))
		&"fireball":
			_launch_fireball_from_event(arg1, arg2)
		&"lifesteal":
			_apply_lifesteal(float(arg2))
		&"chain_lightning_on_bleeding_death":
			_chain_lightning_on_bleeding_death(arg1)
		&"poison_transfer_on_death":
			_poison_transfer_on_death(arg1)
		&"fireball_on_dash":
			_fireball_on_dash(arg1)
		&"missing_hp_stat_bonus":
			_update_missing_hp_bonus(int(arg1), int(arg2))
		&"container_break_random_proc":
			_container_break_random_proc(arg1, arg2)


func _start_cooldown_timer() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.create_timer(internal_cooldown).timeout.connect(func() -> void: cooldown_remaining = 0.0)


func _add_timed_buff() -> void:
	var buffs := _get_buffs()
	if buffs != null:
		buffs.add_timed_stat_buff(_get_instance_buff_id(), stat_name, value, duration, max_stacks)


func _add_round_buff() -> void:
	var buffs := _get_buffs()
	if buffs != null:
		buffs.add_round_stat_buff(_get_instance_buff_id(), stat_name, value, max_stacks)


func _apply_lifesteal(damage_dealt: float) -> void:
	if damage_dealt <= 0.0 or not owner_player.has_method("heal"):
		return
	var stats: StatsComponent = owner_player.get_stats()
	if stats == null or stats.lifesteal <= 0.0:
		return
	var heal_amount: float = damage_dealt * stats.lifesteal
	owner_player.heal(heal_amount)
	print("Lifesteal heals %s" % heal_amount)


func _spread_bleeding_on_death(enemy: Variant) -> void:
	if not _enemy_has_status(enemy, &"bleeding"):
		return
	for target in _get_enemies_near(_extract_position(enemy), radius, [enemy]):
		if target.has_method("apply_status_effect"):
			target.apply_status_effect(&"bleeding", owner_player)
	print("Open Wound spread bleeding")


func _chain_lightning_on_bleeding_death(enemy: Variant) -> void:
	if not _enemy_has_status(enemy, &"bleeding"):
		return
	print("Bloodbolt Covenant triggers")
	_trigger_chain_lightning(_extract_position(enemy), [enemy])


func _poison_transfer_on_death(enemy: Variant) -> void:
	var stacks: int = 0
	if enemy != null and enemy.has_method("get_poison_stacks"):
		stacks = enemy.get_poison_stacks()
	if stacks <= 0:
		return

	var nearest := _get_nearest_enemy(_extract_position(enemy), radius, [enemy])
	if nearest != null and nearest.has_method("apply_poison_stacks"):
		nearest.apply_poison_stacks(stacks, owner_player)
		print("Last Venom transfers poison stacks=%d" % stacks)


func _fireball_on_dash(direction_value: Variant) -> void:
	var direction := direction_value as Vector2
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	var start_position: Vector2 = _get_player_position()
	var target := _get_nearest_enemy(start_position, dash_fireball_auto_aim_radius)
	if target != null:
		direction = target.global_position - start_position

	direction = direction.normalized().rotated(deg_to_rad(_get_duplicate_spread_angle()))
	_launch_fireball(start_position, start_position + direction * 240.0)
	print("Blazing Dash launches fireball")


func _update_missing_hp_bonus(current_hp: int, max_hp: int) -> void:
	var missing: int = maxi(0, max_hp - current_hp)
	var bonus: float = floori(float(missing) / 10.0) * value
	var buffs := _get_buffs()
	if buffs != null:
		buffs.set_dynamic_stat_bonus(_get_instance_buff_id(), stat_name, bonus)
		print("Martyr's Fortune updates bonus=%s" % bonus)


func _container_break_random_proc(container: Variant, info_value: Variant) -> void:
	var info: Dictionary = info_value if info_value is Dictionary else {}
	if only_direct_container_breaks and String(info.get("source", "")) != "player_attack":
		return
	if choices.is_empty():
		return

	var origin: Vector2 = _extract_position(container)
	_run_container_break_random_proc_after_delay(origin)


func _run_container_break_random_proc_after_delay(origin: Vector2) -> void:
	if container_proc_delay > 0.0:
		await owner_player.get_tree().create_timer(container_proc_delay).timeout
	if owner_player == null or not is_instance_valid(owner_player):
		return

	var choice: StringName = choices.pick_random()
	var triggered: bool = false
	match choice:
		&"chain_lightning":
			triggered = _trigger_chain_lightning(origin, [])
		&"fireball":
			var nearest := _get_nearest_enemy(origin, radius)
			if nearest != null:
				_launch_fireball(origin, nearest.global_position)
				triggered = true

	if triggered:
		print("Chaos Hatch triggers %s" % choice)
	else:
		print("Chaos Hatch found no target for %s" % choice)


func _apply_poison_near_position(origin: Vector2, stacks: int) -> void:
	for enemy in _get_enemies_near(origin, radius):
		if enemy.has_method("apply_poison_stacks"):
			enemy.apply_poison_stacks(stacks, owner_player)


func _trigger_chain_lightning(origin: Vector2, already_hit: Array = []) -> bool:
	var stats: StatsComponent = owner_player.get_stats()
	if stats == null:
		return false

	var scale: float = stats.chain_lightning_damage_scale_override if stats.chain_lightning_damage_scale_override >= 0.0 else damage_scale
	var damage: float = owner_player.get_base_attack_damage() * stats.get_damage_multiplier() * scale
	var current_position: Vector2 = origin
	var hit: Array = already_hit.duplicate()
	var did_hit: bool = false

	for index in range(chain_count):
		var target := _get_nearest_enemy(current_position, radius, hit)
		if target == null and stats.chain_lightning_can_target_containers and index > 0:
			target = _get_nearest_container(current_position, radius, hit)
		if target == null:
			break

		var previous_position: Vector2 = current_position
		hit.append(target)
		current_position = target.global_position
		_spawn_chain_lightning_vfx(previous_position, current_position)
		did_hit = true
		if target.is_in_group("enemy") and owner_player.has_method("deal_player_damage_to_enemy"):
			owner_player.deal_player_damage_to_enemy(target, damage, {"source": "chain_lightning", "direct": true, "allow_procs": false})
		elif target.has_method("take_damage"):
			target.take_damage(damage, {"source": "chain_lightning", "owner": owner_player})
	if did_hit:
		print("Chain lightning triggers")
	return did_hit


func _spawn_chain_lightning_vfx(start_position: Vector2, end_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var line := Line2D.new()
	line.name = "ChainLightningVFX"
	line.global_position = Vector2.ZERO
	line.width = lightning_vfx_width
	line.default_color = lightning_vfx_color
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.z_index = 200
	line.add_point(start_position)
	line.add_point(_get_lightning_midpoint(start_position, end_position, -10.0))
	line.add_point(_get_lightning_midpoint(start_position, end_position, 10.0))
	line.add_point(end_position)
	owner_player.get_tree().current_scene.add_child(line)

	var core := Line2D.new()
	core.name = "ChainLightningCore"
	core.width = maxf(2.0, lightning_vfx_width * 0.35)
	core.default_color = Color(1.0, 1.0, 1.0, 1.0)
	core.joint_mode = Line2D.LINE_JOINT_SHARP
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	core.z_index = 201
	for point in line.points:
		core.add_point(point)
	line.add_child(core)

	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, lightning_vfx_lifetime)
	tween.finished.connect(line.queue_free)


func _get_lightning_midpoint(start_position: Vector2, end_position: Vector2, side_offset: float) -> Vector2:
	var along: Vector2 = end_position - start_position
	if along.length_squared() <= 0.001:
		return start_position

	var normal: Vector2 = along.normalized().orthogonal()
	var progress: float = 0.35 if side_offset < 0.0 else 0.68
	return start_position.lerp(end_position, progress) + normal * side_offset


func _launch_fireball(start_position: Vector2, target_position: Vector2) -> void:
	var direction: Vector2 = target_position - start_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var stats: StatsComponent = owner_player.get_stats()
	var final_damage: float = owner_player.get_base_attack_damage()
	if stats != null:
		final_damage *= stats.get_damage_multiplier()
	final_damage *= damage_scale

	var fireball := Area2D.new()
	fireball.set_script(FIREBALL_SCRIPT)
	fireball.setup(owner_player, start_position, direction, final_damage, radius)
	fireball.collision_layer = 1 << 2
	fireball.collision_mask = 1 << 1
	owner_player.get_tree().current_scene.add_child(fireball)
	print("Fireball triggers")


func _launch_fireball_from_event(arg1: Variant, arg2: Variant) -> void:
	if event_name == &"attack_started":
		var start_position: Vector2 = _extract_position(arg1)
		var direction := arg2 as Vector2
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT
		_launch_fireball(start_position, start_position + direction.normalized() * 240.0)
		return

	_launch_fireball(_get_player_position(), _extract_position(arg1))


func _get_buffs() -> TemporaryBuffComponent:
	if owner_player != null and owner_player.has_method("get_temporary_buffs"):
		return owner_player.get_temporary_buffs()
	return null


func _get_instance_buff_id() -> StringName:
	return StringName("%s_%s_%d" % [event_name, effect_type, get_instance_id()])


func _get_duplicate_spread_angle() -> float:
	if item_stack_index <= 0:
		return 0.0

	var lane: int = int(ceil(float(item_stack_index) / 2.0))
	var sign_value: float = 1.0 if item_stack_index % 2 == 1 else -1.0
	return duplicate_projectile_spread_degrees * float(lane) * sign_value


func _get_player_position() -> Vector2:
	var node := owner_player as Node2D
	return node.global_position if node != null else Vector2.ZERO


func _extract_position(position_source: Variant) -> Vector2:
	var node := position_source as Node2D
	if node != null:
		return node.global_position
	if position_source is Vector2:
		return position_source
	return _get_player_position()


func _get_effect_origin(arg1: Variant) -> Vector2:
	if event_name == &"attack_started":
		return _extract_position(arg1)
	return _extract_position(arg1)


func _get_initial_chain_excludes(arg1: Variant) -> Array:
	if event_name == &"attack_hit":
		return [arg1]
	return []


func _enemy_has_status(enemy: Variant, id: StringName) -> bool:
	return enemy != null and enemy.has_method("has_status") and enemy.has_status(id)


func _get_enemies_near(origin: Vector2, search_radius: float, exclude: Array = []) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in owner_player.get_tree().get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or exclude.has(enemy) or not is_instance_valid(enemy_2d):
			continue
		if enemy_2d.global_position.distance_to(origin) <= search_radius:
			result.append(enemy_2d)
	return result


func _get_nearest_enemy(origin: Vector2, search_radius: float, exclude: Array = []) -> Node2D:
	var best: Node2D
	var best_distance: float = INF
	for enemy in _get_enemies_near(origin, search_radius, exclude):
		var distance: float = enemy.global_position.distance_to(origin)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _get_nearest_container(origin: Vector2, search_radius: float, exclude: Array = []) -> Node2D:
	var best: Node2D
	var best_distance: float = INF
	for container in owner_player.get_tree().get_nodes_in_group("container"):
		var container_2d := container as Node2D
		if container_2d == null or exclude.has(container) or not is_instance_valid(container_2d):
			continue
		if container_2d is BreakableContainer and container_2d.is_breaking:
			continue
		if container_2d is BreakableContainer and container_2d.is_shop_container:
			continue
		var distance: float = container_2d.global_position.distance_to(origin)
		if distance <= search_radius and distance < best_distance:
			best_distance = distance
			best = container_2d
	return best
