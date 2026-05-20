extends RefCounted

const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")
const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")
const FIRE_ESSENCE_PICKUP_SCRIPT := preload("res://systems/combat/FireEssencePickup.gd")
const HOLY_FLAME_LASER_SCRIPT := preload("res://systems/combat/HolyFlameLaser.gd")

var enabled_talents: Dictionary = {}
var rebirth_used: bool = false
var applied_nearby_enemy_attack_speed: float = -1.0
var applied_nearby_enemy_move_speed: float = -1.0
var applied_nearby_enemy_elite_damage: float = -1.0
var applied_rare_item_move_speed: int = 0
var next_slide_fireball_ready: bool = false
var slide_fireball_radius_buff_remaining: float = 0.0
var nearby_poison_aura_timer: float = 5.0
var fire_essence_spawn_timer: float = 5.0
var fire_essence_charges: int = 0
var early_round_gold_remaining: float = 0.0
var quick_kill_max_hp_this_round: int = 0


func enable_talent(effect_id: StringName) -> void:
	enabled_talents[effect_id] = true


func has_talent(effect_id: StringName) -> bool:
	return bool(enabled_talents.get(effect_id, false))


func get_compat_property(property: StringName) -> Variant:
	var property_text := String(property)
	if property_text.begins_with("talent_wizard_") and property_text.ends_with("_enabled"):
		return has_talent(_property_to_effect_id(property_text))
	match property:
		&"wizard_rebirth_used":
			return rebirth_used
		&"applied_wizard_nearby_enemy_attack_speed":
			return applied_nearby_enemy_attack_speed
		&"applied_wizard_nearby_enemy_move_speed":
			return applied_nearby_enemy_move_speed
		&"applied_wizard_nearby_enemy_elite_damage":
			return applied_nearby_enemy_elite_damage
		&"applied_wizard_rare_item_move_speed":
			return applied_rare_item_move_speed
		&"next_wizard_slide_fireball_ready":
			return next_slide_fireball_ready
		&"wizard_slide_fireball_radius_buff_remaining":
			return slide_fireball_radius_buff_remaining
		&"wizard_nearby_poison_aura_timer":
			return nearby_poison_aura_timer
		&"wizard_fire_essence_spawn_timer":
			return fire_essence_spawn_timer
		&"wizard_fire_essence_charges":
			return fire_essence_charges
		&"wizard_early_round_gold_remaining":
			return early_round_gold_remaining
		&"wizard_quick_kill_max_hp_this_round":
			return quick_kill_max_hp_this_round
	return null


func set_compat_property(property: StringName, value: Variant) -> bool:
	var property_text := String(property)
	if property_text.begins_with("talent_wizard_") and property_text.ends_with("_enabled"):
		var effect_id := _property_to_effect_id(property_text)
		if bool(value):
			enable_talent(effect_id)
		else:
			enabled_talents.erase(effect_id)
		return true
	match property:
		&"wizard_rebirth_used":
			rebirth_used = bool(value)
		&"applied_wizard_nearby_enemy_attack_speed":
			applied_nearby_enemy_attack_speed = float(value)
		&"applied_wizard_nearby_enemy_move_speed":
			applied_nearby_enemy_move_speed = float(value)
		&"applied_wizard_nearby_enemy_elite_damage":
			applied_nearby_enemy_elite_damage = float(value)
		&"applied_wizard_rare_item_move_speed":
			applied_rare_item_move_speed = int(value)
		&"next_wizard_slide_fireball_ready":
			next_slide_fireball_ready = bool(value)
		&"wizard_slide_fireball_radius_buff_remaining":
			slide_fireball_radius_buff_remaining = float(value)
		&"wizard_nearby_poison_aura_timer":
			nearby_poison_aura_timer = float(value)
		&"wizard_fire_essence_spawn_timer":
			fire_essence_spawn_timer = float(value)
		&"wizard_fire_essence_charges":
			fire_essence_charges = int(value)
		&"wizard_early_round_gold_remaining":
			early_round_gold_remaining = float(value)
		&"wizard_quick_kill_max_hp_this_round":
			quick_kill_max_hp_this_round = int(value)
		_:
			return false
	return true


func reset_state_after_rebirth() -> void:
	enabled_talents.clear()
	next_slide_fireball_ready = false
	slide_fireball_radius_buff_remaining = 0.0
	nearby_poison_aura_timer = 5.0
	fire_essence_spawn_timer = 5.0
	fire_essence_charges = 0
	early_round_gold_remaining = 0.0
	quick_kill_max_hp_this_round = 0
	applied_nearby_enemy_attack_speed = -1.0
	applied_nearby_enemy_move_speed = -1.0
	applied_nearby_enemy_elite_damage = -1.0
	applied_rare_item_move_speed = 0


func _property_to_effect_id(property_text: String) -> StringName:
	return StringName(property_text.trim_prefix("talent_").trim_suffix("_enabled"))


func cast_fire_laser(player) -> void:
	var direction := _direction_to(player, player.pending_shockwave_target_position, player.global_position)
	spawn_fire_laser(player, player.global_position, direction)
	if has_talent(&"wizard_extra_auto_fire_laser"):
		spawn_extra_auto_fire_laser(player)


func spawn_fire_laser(player, start_position: Vector2, direction: Vector2, chain_remaining_override: int = -1, chain_excludes: Array = [], damages_enemies: bool = true, chain_damage_multiplier: float = 1.0) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	var laser := HOLY_FLAME_LASER_SCRIPT.new() as HolyFlameLaser
	laser.length *= 2.0
	laser.width *= 2.0
	if has_talent(&"wizard_fire_laser_range_bonus"):
		laser.length *= 1.3
	var laser_damage_multiplier := 1.5
	if has_talent(&"wizard_short_laser_double_damage"):
		laser.length *= 0.5
		laser_damage_multiplier *= 2.0
	if has_talent(&"wizard_container_break_laser_no_container_damage"):
		laser.damages_containers = false
	laser.damages_enemies = damages_enemies
	laser.setup(player, start_position, direction.normalized(), player.get_base_attack_damage() * laser_damage_multiplier * maxf(chain_damage_multiplier, 0.0), "wizard_fire_laser", true)
	laser.chain_range = laser.length
	laser.chain_damage_multiplier = maxf(chain_damage_multiplier, 0.0)
	laser.chain_remaining = chain_remaining_override if chain_remaining_override >= 0 else get_fire_laser_chain_count(player)
	laser.damaged_bodies.clear()
	for excluded in chain_excludes:
		var excluded_node := excluded as Node
		if excluded_node != null:
			laser.damaged_bodies.append(excluded_node)
	laser.collision_layer = 0
	laser.collision_mask = 0
	if laser.damages_enemies:
		laser.set_collision_mask_value(player.enemy_collision_layer_number, true)
	if laser.damages_containers:
		laser.set_collision_mask_value(player.jar_collision_layer_number, true)
	player.get_tree().current_scene.add_child(laser)


func spawn_extra_auto_fire_laser(player) -> void:
	var target := EFFECT_TARGETING.nearest_enemy(player, player.global_position, 700.0)
	if target == null:
		return
	var direction := _direction_to(player, target.global_position, player.global_position)
	spawn_fire_laser(player, player.global_position, direction)


func spawn_chained_fire_laser(player, source_enemy: Node, remaining_chains: int, chain_range: float, excludes: Array = [], source_chain_damage_multiplier: float = 1.0) -> void:
	var source_2d := source_enemy as Node2D
	if source_2d == null:
		return
	var target := EFFECT_TARGETING.nearest_enemy(player, source_2d.global_position, chain_range, excludes)
	if target == null:
		target = EFFECT_TARGETING.nearest_enemy(player, source_2d.global_position, chain_range, [source_enemy])
	if target == null:
		if has_talent(&"wizard_fire_laser_chain_heals_player") and source_2d.global_position.distance_to(player.global_position) <= chain_range:
			var player_direction := _direction_to(player, player.global_position, source_2d.global_position)
			spawn_fire_laser(player, source_2d.global_position, player_direction, 0, [], false)
			player.heal(1.0)
		return
	var direction := _direction_to(player, target.global_position, source_2d.global_position)
	var chain_damage_multiplier := maxf(source_chain_damage_multiplier, 0.0)
	if has_talent(&"wizard_fire_laser_chain_damage"):
		chain_damage_multiplier *= 1.2
	spawn_fire_laser(player, source_2d.global_position, direction, remaining_chains, excludes, true, chain_damage_multiplier)


func get_fire_laser_chain_count(player) -> int:
	var chain_count := 1 if has_talent(&"wizard_fire_laser_chain") else 0
	if has_talent(&"wizard_attack_speed_laser_chain"):
		chain_count += floori(player.call("_get_current_attacks_per_second"))
	return maxi(chain_count, 0)


func start_fire_surge(player) -> void:
	player.fire_surge_remaining = 10.0
	player.fire_surge_fire_remaining = 0.0
	player.fire_surge_cooldown_pending = true


func update_fire_surge(player, delta: float) -> void:
	if player.fire_surge_remaining <= 0.0:
		return
	if player.utility_ability == &"necromancer_soul_surge":
		player.fire_surge_remaining = maxf(0.0, player.fire_surge_remaining - delta)
		if player.fire_surge_remaining <= 0.0:
			player.fire_surge_cooldown_pending = false
			player.blessing_cooldown_remaining = 10.0
		return
	player.fire_surge_remaining = maxf(0.0, player.fire_surge_remaining - delta)
	player.fire_surge_fire_remaining -= delta
	while player.fire_surge_fire_remaining <= 0.0 and player.fire_surge_remaining > 0.0:
		if has_talent(&"wizard_fire_surge_laser") and has_talent(&"wizard_fire_surge_radial_fireballs"):
			player.fire_surge_fire_remaining += 5.0
			launch_radial_fire_lasers(player)
		elif has_talent(&"wizard_fire_surge_laser"):
			player.fire_surge_fire_remaining += 2.0
			launch_fire_surge_laser(player)
		elif has_talent(&"wizard_fire_surge_radial_fireballs"):
			player.fire_surge_fire_remaining += 5.0
			launch_radial_fireballs(player)
		else:
			player.fire_surge_fire_remaining += 2.0
			var target := EFFECT_TARGETING.nearest_enemy(player, player.global_position, 700.0)
			if target != null:
				launch_fireball(player, target.global_position)
	if player.fire_surge_remaining <= 0.0:
		player.fire_surge_cooldown_pending = false
		player.blessing_cooldown_remaining = 10.0


func launch_fire_surge_laser(player) -> void:
	var target := EFFECT_TARGETING.nearest_enemy(player, player.global_position, 700.0)
	if target == null:
		return
	spawn_fire_laser(player, player.global_position, _direction_to(player, target.global_position, player.global_position))


func launch_radial_fire_lasers(player) -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		spawn_fire_laser(player, player.global_position, Vector2(cos(angle), sin(angle)))


func launch_fireball(player, target_position: Vector2, consume_slide_fireball_bonus: bool = false, radius_multiplier: float = 1.0, lifetime_multiplier: float = 1.0, allow_procs: bool = false, emit_attack_started_event: bool = false, scatter_on_explode: bool = false, force_slide_fireball_bonus: bool = false) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	var direction := _direction_to(player, target_position, player.global_position)
	if emit_attack_started_event:
		player.attack_started.emit(player.global_position, direction, {"source": "fireball", "direct": true, "allow_procs": allow_procs})
	spawn_fireball(player, player.global_position, direction, consume_slide_fireball_bonus, radius_multiplier, lifetime_multiplier, allow_procs, scatter_on_explode, force_slide_fireball_bonus)


func spawn_fireball(player, start_position: Vector2, direction: Vector2, consume_slide_fireball_bonus: bool = false, radius_multiplier: float = 1.0, lifetime_multiplier: float = 1.0, allow_procs: bool = false, scatter_on_explode: bool = false, force_slide_fireball_bonus: bool = false) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	var fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	var explosion_radius := 80.0 * maxf(radius_multiplier, 0.0)
	fireball.lifetime *= maxf(lifetime_multiplier, 0.0)
	var has_slide_fireball_bonus: bool = force_slide_fireball_bonus or (consume_slide_fireball_bonus and next_slide_fireball_ready)
	var has_surge_left_click_bonus: bool = consume_slide_fireball_bonus and has_talent(&"wizard_fire_surge_left_click_blast") and player.fire_surge_remaining > 0.0
	var additive_radius_bonus := 0.0
	if has_slide_fireball_bonus:
		additive_radius_bonus += 0.3
	if has_surge_left_click_bonus:
		additive_radius_bonus += 0.5
	if has_slide_fireball_bonus or has_surge_left_click_bonus:
		fireball.lifetime *= 0.1
	if slide_fireball_radius_buff_remaining > 0.0:
		additive_radius_bonus += 0.3
	explosion_radius *= 1.0 + additive_radius_bonus
	if has_talent(&"wizard_fireball_radius_bonus"):
		explosion_radius *= 1.3
	if has_talent(&"wizard_fireball_radius_per_atk"):
		explosion_radius *= player.call("_get_wizard_fireball_radius_per_atk_multiplier")
	if has_slide_fireball_bonus and not force_slide_fireball_bonus:
		next_slide_fireball_ready = false
	fireball.setup(player, start_position, direction, get_fireball_damage(player), explosion_radius, allow_procs)
	if has_talent(&"wizard_fireball_speed_bonus"):
		fireball.speed *= 1.4
	if has_talent(&"wizard_primary_fireball_laser_explosion"):
		fireball.explode_replacement_callback = Callable(player, "_replace_wizard_primary_fireball_explosion_with_laser")
	if scatter_on_explode:
		fireball.explode_callback = Callable(player, "_launch_wizard_fire_essence_explosion_scatter")
	fireball.collision_layer = 1 << 2
	fireball.collision_mask = 1 << 1
	if has_talent(&"wizard_fireball_explodes_on_containers"):
		fireball.explode_on_containers = true
		fireball.set_collision_mask_value(player.jar_collision_layer_number, true)
	player.get_tree().current_scene.add_child(fireball)


func get_fireball_damage(player) -> float:
	var damage: float = player.get_base_attack_damage()
	if has_talent(&"wizard_fireball_damage_bonus"):
		damage *= 1.2
	return damage


func launch_dash_fireball(player) -> void:
	var direction: Vector2 = player.dash_direction
	if direction.length_squared() <= 0.001:
		direction = player.facing_direction
	launch_fireball(player, player.global_position + direction.normalized() * 200.0, false, 2.0, 0.1)


func launch_primary_attack_pattern(player, target_position: Vector2, use_fire_essence_version: bool, emit_attack_started_event: bool = true) -> void:
	var scatter_on_explode: bool = use_fire_essence_version and has_talent(&"wizard_fire_essence_explosion_scatter")
	var apply_slide_fireball_bonus: bool = next_slide_fireball_ready
	if apply_slide_fireball_bonus:
		next_slide_fireball_ready = false
	launch_fireball(player, target_position, true, 1.0, 1.0, true, emit_attack_started_event, scatter_on_explode, apply_slide_fireball_bonus)
	var offset_index := 0
	if use_fire_essence_version:
		launch_offset_fireballs(player, target_position, 3, offset_index, apply_slide_fireball_bonus)
		offset_index += 3
	if has_talent(&"wizard_primary_extra_fireball"):
		launch_offset_fireballs(player, target_position, 1, offset_index, apply_slide_fireball_bonus)
		offset_index += 1
	launch_offset_fireballs(player, target_position, get_move_speed_extra_fireball_count(player), offset_index, apply_slide_fireball_bonus)


func launch_offset_fireballs(player, target_position: Vector2, count: int, start_index: int = 0, force_slide_fireball_bonus: bool = false) -> void:
	if count <= 0:
		return
	var direction := _direction_to(player, target_position, player.global_position)
	var center_angle := direction.angle()
	for index in range(count):
		var offset_index := start_index + index
		var step := floori(float(offset_index) / 2.0) + 1
		var sign_value := 1.0 if offset_index % 2 == 0 else -1.0
		var angle := center_angle + deg_to_rad(10.0 * float(step) * sign_value)
		launch_fireball(player, player.global_position + Vector2(cos(angle), sin(angle)) * 200.0, true, 1.0, 1.0, true, false, false, force_slide_fireball_bonus)


func launch_fire_essence_explosion_scatter(player, origin: Vector2) -> void:
	for index in range(8):
		var angle := deg_to_rad(24.0) + TAU * float(index) / 8.0
		var delay := 0.04 * float(index)
		if delay <= 0.0:
			spawn_fireball(player, origin, Vector2(cos(angle), sin(angle)), false, 1.0, 1.0, true, false)
		elif player.get_tree() != null:
			player.get_tree().create_timer(delay).timeout.connect(
				Callable(player, "_spawn_wizard_spiral_fireball").bind(origin, Vector2(cos(angle), sin(angle)))
			)


func replace_primary_fireball_explosion_with_laser(player, origin: Vector2) -> bool:
	var target := EFFECT_TARGETING.nearest_enemy(player, origin, 700.0)
	if target == null:
		return false
	spawn_fire_laser(player, origin, _direction_to(player, target.global_position, origin))
	return true


func spawn_fireball_duplicate(player, source_fireball: FireballProjectile, direction: Vector2) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	var duplicate := FIREBALL_SCRIPT.new() as FireballProjectile
	duplicate.owner_spawn_modifiers_applied = true
	duplicate.speed = source_fireball.speed
	duplicate.lifetime = source_fireball.lifetime
	duplicate.target_group = source_fireball.target_group
	duplicate.damages_containers = source_fireball.damages_containers
	duplicate.explode_on_containers = source_fireball.explode_on_containers
	duplicate.explode_replacement_callback = source_fireball.explode_replacement_callback
	duplicate.explode_callback = source_fireball.explode_callback
	duplicate.setup(source_fireball.owner_player, source_fireball.global_position, direction, source_fireball.damage, source_fireball.explosion_radius, source_fireball.allow_procs)
	duplicate.collision_layer = source_fireball.collision_layer
	duplicate.collision_mask = source_fireball.collision_mask
	player.get_tree().current_scene.add_child(duplicate)


func get_random_fireball_direction() -> Vector2:
	return Vector2.RIGHT.rotated(randf_range(0.0, TAU))


func get_legendary_extra_fireball_count(player) -> int:
	if not has_talent(&"wizard_legendary_extra_fireballs"):
		return 0
	return player.call("_get_item_count_by_rarity", &"legendary")


func get_move_speed_extra_fireball_count(player) -> int:
	if not has_talent(&"wizard_move_speed_extra_fireballs"):
		return 0
	var move_speed_value: float = player.move_speed
	if player.stats != null:
		move_speed_value = player.stats.get_move_speed(player.move_speed)
	return maxi(floori(move_speed_value / 100.0), 0)


func launch_radial_fireballs(player) -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		launch_fireball(player, player.global_position + Vector2(cos(angle), sin(angle)) * 200.0)


func schedule_primary_echoes(player, target_position: Vector2, use_fire_essence_version: bool) -> void:
	if not has_talent(&"wizard_max_hp_primary_echo") or player.get_tree() == null:
		return
	var max_hp_value: float = player.max_hp
	if player.stats != null:
		max_hp_value = float(player.stats.max_hp)
	var echo_count := floori(max_hp_value / 100.0)
	for index in range(echo_count):
		player.get_tree().create_timer(0.2 * float(index + 1)).timeout.connect(
			Callable(player, "_launch_wizard_primary_echo").bind(target_position, use_fire_essence_version)
		)


func update_fire_essence_spawner(player, delta: float) -> void:
	if not has_talent(&"wizard_fire_essence_burst"):
		return
	fire_essence_spawn_timer -= delta
	while fire_essence_spawn_timer <= 0.0:
		fire_essence_spawn_timer += 5.0
		spawn_fire_essence(player)


func spawn_fire_essence(player) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	var distance := sqrt(randf()) * 400.0
	var angle := randf_range(0.0, TAU)
	var spawn_position: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	if player.movement_bounds_enabled:
		spawn_position.x = clampf(spawn_position.x, player.movement_bounds.position.x, player.movement_bounds.end.x)
		spawn_position.y = clampf(spawn_position.y, player.movement_bounds.position.y, player.movement_bounds.end.y)
	var essence := FIRE_ESSENCE_PICKUP_SCRIPT.new() as Node2D
	essence.setup(spawn_position, player)
	player.get_tree().current_scene.add_child(essence)


func _direction_to(player, target_position: Vector2, origin: Vector2) -> Vector2:
	var direction: Vector2 = target_position - origin
	if direction.length_squared() <= 0.001:
		direction = player.facing_direction
	else:
		direction = direction.normalized()
	return direction
