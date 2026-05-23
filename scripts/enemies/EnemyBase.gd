extends CharacterBody2D
class_name EnemyBase

const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const ELITE_AFFIX_ACID_PROJECTILE_SCRIPT := preload("res://systems/combat/AcidProjectile.gd")
const ELITE_AFFIX_POISON_PUDDLE_SCRIPT := preload("res://systems/combat/PoisonPuddle.gd")
const UNDEAD_DEATH_SFX_A: AudioStream = preload("res://assets/sfx/undead_death_bone_break_a.mp3")
const UNDEAD_DEATH_SFX_B: AudioStream = preload("res://assets/sfx/undead_death_bone_break_b.mp3")

signal died(enemy: EnemyBase)

# Core stats shared by all enemy types. Tune these per enemy scene.
@export var max_hp: float = 35.0
@export var move_speed: float = 90.0
@export var damage: float = 8.0
@export var attack_cooldown: float = 1.0
@export var knockback_friction: float = 1600.0
@export var is_elite: bool = false
@export var hp_bar_offset_y: float = -72.0

# The enemy automatically tracks the first node in this group.
@export var target_group: StringName = &"player"
@export var debug_color: Color = Color(0.52, 0.56, 0.46)

var hp: float
var target: Node2D
var is_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var status_effects: StatusEffectComponent
var last_damage_source: Node
var last_attack_info: Dictionary = {}
var kill_notified: bool = false
var hp_bar_root: Node2D
var hp_bar_fill: Polygon2D
var base_move_speed: float = 0.0
var round_enrage_multiplier: float = 1.0
var enrage_visual_base_modulates: Dictionary = {}
var elite_affix_id: StringName = &""
var elite_affix_label: Label
var incoming_damage_multiplier: float = 1.0
var extra_damage_multiplier: float = 1.0
var dodge_chance: float = 0.0
var map_move_speed_multiplier: float = 1.0
var elite_affix_data: Dictionary = {}
var elite_affix_timers: Dictionary = {}
var temporary_move_speed_multipliers: Dictionary = {}


func _ready() -> void:
	base_move_speed = move_speed
	hp = max_hp
	add_to_group("enemy")
	_ensure_status_effects()
	_find_target()
	_ensure_placeholder_visual()
	_ensure_hp_bar()
	_update_hp_bar()


func _process(delta: float) -> void:
	if not is_dead:
		_update_temporary_move_speed_multipliers()
		_update_elite_affix_runtime(delta)
		_update_hp_bar_position()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_stunned():
		_handle_stunned_physics(delta)
		return

	if _update_knockback(delta):
		return

	_find_target()
	_chase_target(delta)


func take_damage(amount: float, source: Node = null, attack_info: Dictionary = {}) -> float:
	if is_dead:
		return 0.0

	last_damage_source = source
	last_attack_info = attack_info
	amount = _apply_incoming_damage_modifiers(amount)
	if amount <= 0.0:
		return 0.0
	var old_hp: float = hp
	hp = maxf(0.0, hp - amount)
	_update_hp_bar()
	if hp <= 0.0:
		die()
	return old_hp - hp


func die() -> void:
	if is_dead:
		return

	release_attack_token()
	is_dead = true
	_notify_player_kill_once()
	_play_death_sfx()
	_hide_hp_bar()
	died.emit(self)
	queue_free()


func apply_status_effect(id: StringName, source_player: Node = null) -> void:
	if status_effects != null:
		status_effects.apply_status_effect(id, source_player)
	if id == &"stun" and is_stunned():
		_on_stun_applied()


func apply_stun_duration(duration: float, source_player: Node = null) -> void:
	if status_effects != null:
		status_effects.apply_stun_duration(_get_effective_stun_duration(duration), source_player)
	if is_stunned():
		_on_stun_applied()


func apply_poison_stacks(amount: int, source_player: Node = null) -> void:
	if status_effects != null:
		status_effects.apply_poison_stacks(amount, source_player)


func apply_vulnerable_stacks(amount: int, source_player: Node = null) -> void:
	if status_effects != null:
		status_effects.apply_vulnerable_stacks(amount, source_player)


func get_poison_stacks() -> int:
	return status_effects.get_poison_stacks() if status_effects != null else 0


func get_vulnerable_stacks() -> int:
	return status_effects.get_vulnerable_stacks() if status_effects != null else 0


func get_stun_time_left() -> float:
	return status_effects.get_stun_time_left() if status_effects != null else 0.0


func has_status(id: StringName) -> bool:
	return status_effects.has_status(id) if status_effects != null else false


func is_stunned() -> bool:
	return has_status(&"stun")


func apply_knockback(force: Vector2) -> void:
	# Called by player shockwave or future effects. Movement still uses CharacterBody2D.
	knockback_velocity = force


func has_valid_target() -> bool:
	return target != null and is_instance_valid(target)


func get_target_position() -> Vector2:
	if has_valid_target():
		return target.global_position

	return global_position


func face_position(world_position: Vector2) -> void:
	var offset: Vector2 = world_position - global_position
	if offset.length_squared() > 0.001:
		rotation = offset.angle()


func stop_moving() -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func move_toward_position(world_position: Vector2, speed: float, delta: float) -> void:
	var offset: Vector2 = world_position - global_position
	if offset.length_squared() <= 0.001:
		stop_moving()
		return

	velocity = offset.normalized() * speed
	move_and_slide()


func set_round_enrage_multiplier(multiplier: float) -> void:
	if base_move_speed <= 0.0:
		base_move_speed = move_speed

	round_enrage_multiplier = maxf(1.0, multiplier)
	_recalculate_move_speed()
	_update_enrage_visuals()


func set_map_move_speed_multiplier(multiplier: float) -> void:
	map_move_speed_multiplier = maxf(multiplier, 0.01)
	_recalculate_move_speed()


func apply_temporary_move_speed_multiplier(source_id: StringName, multiplier: float, duration: float) -> void:
	if source_id == &"" or duration <= 0.0:
		return

	temporary_move_speed_multipliers[source_id] = {
		"multiplier": maxf(multiplier, 0.01),
		"expire_msec": Time.get_ticks_msec() + int(duration * 1000.0),
	}
	_recalculate_move_speed()


func set_elite_affix(affix_id: StringName, display_name: String, data: Dictionary = {}) -> void:
	if affix_id == &"":
		return

	elite_affix_id = affix_id
	elite_affix_data = data.duplicate(true)
	elite_affix_timers.clear()
	_ensure_elite_affix_label()
	if elite_affix_label != null:
		elite_affix_label.text = display_name
		elite_affix_label.visible = true


func try_claim_attack_token() -> bool:
	var coordinator := get_tree().current_scene
	if coordinator == null or not coordinator.has_method("request_enemy_attack_token"):
		return true

	return bool(coordinator.call("request_enemy_attack_token", self))


func release_attack_token() -> void:
	var coordinator := get_tree().current_scene
	if coordinator != null and coordinator.has_method("release_enemy_attack_token"):
		coordinator.call("release_enemy_attack_token", self)


func _on_stun_applied() -> void:
	knockback_velocity = Vector2.ZERO
	stop_moving()
	release_attack_token()


func _handle_stunned_physics(_delta: float) -> void:
	_on_stun_applied()


func _get_effective_stun_duration(duration: float) -> float:
	return duration * 0.5 if is_elite else duration


func _chase_target(delta: float) -> void:
	if not has_valid_target():
		stop_moving()
		return

	# Base movement is direct pursuit. Subclasses can override behavior.
	face_position(target.global_position)
	move_toward_position(target.global_position, move_speed, delta)


func _find_target() -> void:
	if has_valid_target():
		return

	target = get_tree().get_first_node_in_group(target_group) as Node2D


func _update_knockback(delta: float) -> bool:
	if knockback_velocity.length_squared() <= 1.0:
		knockback_velocity = Vector2.ZERO
		return false

	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	return true


func _ensure_placeholder_visual() -> void:
	if has_node("DebugBody"):
		return

	var body := Polygon2D.new()
	body.name = "DebugBody"
	body.color = debug_color
	body.polygon = _circle_polygon(18.0, 18)
	add_child(body)

	var forward := Line2D.new()
	forward.name = "DebugForward"
	forward.default_color = Color(0.05, 0.05, 0.05)
	forward.width = 3.0
	forward.add_point(Vector2.ZERO)
	forward.add_point(Vector2(24.0, 0.0))
	add_child(forward)


func _ensure_status_effects() -> void:
	status_effects = get_node_or_null("StatusEffectComponent") as StatusEffectComponent
	if status_effects == null:
		status_effects = StatusEffectComponent.new()
		status_effects.name = "StatusEffectComponent"
		add_child(status_effects)
	status_effects.setup(self)


func _ensure_hp_bar() -> void:
	hp_bar_root = get_node_or_null("HpBar") as Node2D
	if hp_bar_root == null:
		hp_bar_root = Node2D.new()
		hp_bar_root.name = "HpBar"
		hp_bar_root.top_level = true
		hp_bar_root.z_index = 50
		add_child(hp_bar_root)

	var background := hp_bar_root.get_node_or_null("Background") as Polygon2D
	if background == null:
		background = Polygon2D.new()
		background.name = "Background"
		background.color = Color(0.08, 0.08, 0.08, 0.78)
		background.polygon = PackedVector2Array([
			Vector2(-24.0, -3.0),
			Vector2(24.0, -3.0),
			Vector2(24.0, 3.0),
			Vector2(-24.0, 3.0),
		])
		hp_bar_root.add_child(background)

	hp_bar_fill = hp_bar_root.get_node_or_null("Fill") as Polygon2D
	if hp_bar_fill == null:
		hp_bar_fill = Polygon2D.new()
		hp_bar_fill.name = "Fill"
		hp_bar_fill.color = Color(0.86, 0.12, 0.12, 0.95)
		hp_bar_root.add_child(hp_bar_fill)

	_update_hp_bar_position()


func _update_hp_bar() -> void:
	if hp_bar_fill == null:
		return

	var ratio := clampf(hp / maxf(max_hp, 0.001), 0.0, 1.0)
	var left := -23.0
	var right := lerpf(left, 23.0, ratio)
	hp_bar_fill.polygon = PackedVector2Array([
		Vector2(left, -2.0),
		Vector2(right, -2.0),
		Vector2(right, 2.0),
		Vector2(left, 2.0),
	])


func _update_hp_bar_position() -> void:
	if hp_bar_root == null:
		return

	hp_bar_root.global_position = global_position + Vector2(0.0, hp_bar_offset_y)
	hp_bar_root.global_rotation = 0.0


func _hide_hp_bar() -> void:
	if hp_bar_root != null:
		hp_bar_root.visible = false


func _apply_incoming_damage_modifiers(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	if dodge_chance > 0.0 and randf() < clampf(dodge_chance, 0.0, 0.95):
		return 0.0

	var multiplier := incoming_damage_multiplier
	multiplier *= 1.0 + 0.05 * float(get_vulnerable_stacks())
	if elite_affix_id == &"distant_hide":
		multiplier *= _get_distant_hide_damage_multiplier()
	return amount * maxf(multiplier, 0.0)


func _get_distant_hide_damage_multiplier() -> float:
	var distance := 0.0
	if has_valid_target():
		distance = global_position.distance_to(target.global_position)
	else:
		var player := get_tree().get_first_node_in_group(target_group) as Node2D
		if player != null:
			distance = global_position.distance_to(player.global_position)

	var start_distance := float(elite_affix_data.get("start_distance", 260.0))
	var full_distance := float(elite_affix_data.get("full_distance", 720.0))
	var max_reduction := float(elite_affix_data.get("max_reduction", 0.6))
	var progress := clampf((distance - start_distance) / maxf(full_distance - start_distance, 1.0), 0.0, 1.0)
	return 1.0 - max_reduction * progress


func _update_temporary_move_speed_multipliers() -> void:
	if temporary_move_speed_multipliers.is_empty():
		return

	var now := Time.get_ticks_msec()
	var changed := false
	for source_id in temporary_move_speed_multipliers.keys():
		var data: Dictionary = temporary_move_speed_multipliers.get(source_id, {})
		if int(data.get("expire_msec", 0)) <= now:
			temporary_move_speed_multipliers.erase(source_id)
			changed = true
	if changed:
		_recalculate_move_speed()


func _recalculate_move_speed() -> void:
	if base_move_speed <= 0.0:
		base_move_speed = move_speed

	var speed_up_multiplier := 1.0
	var slow_multiplier := 1.0
	for data in temporary_move_speed_multipliers.values():
		if data is Dictionary:
			var multiplier := float(data.get("multiplier", 1.0))
			if multiplier >= 1.0:
				speed_up_multiplier = maxf(speed_up_multiplier, multiplier)
			else:
				slow_multiplier *= maxf(multiplier, 0.01)
	var temporary_multiplier := speed_up_multiplier * slow_multiplier
	move_speed = base_move_speed * round_enrage_multiplier * map_move_speed_multiplier * temporary_multiplier


func _update_elite_affix_runtime(delta: float) -> void:
	if elite_affix_id == &"" or is_dead:
		return

	match elite_affix_id:
		&"poison_trail":
			_update_poison_trail_affix(delta)
		&"speed_aura":
			_update_speed_aura_affix(delta)
		&"slow_regen":
			_update_slow_regen_affix(delta)
		&"acid_volley":
			_update_acid_volley_affix(delta)


func _update_poison_trail_affix(delta: float) -> void:
	if velocity.length_squared() <= 64.0:
		return
	var timer := maxf(float(elite_affix_timers.get("poison_trail", 0.0)) - delta, 0.0)
	if timer > 0.0:
		elite_affix_timers["poison_trail"] = timer
		return

	elite_affix_timers["poison_trail"] = float(elite_affix_data.get("interval", 1.0))
	_spawn_elite_affix_poison_puddle(global_position, float(elite_affix_data.get("radius", 80.0)), float(elite_affix_data.get("duration", 5.0)))


func _update_speed_aura_affix(delta: float) -> void:
	var timer := maxf(float(elite_affix_timers.get("speed_aura", 0.0)) - delta, 0.0)
	if timer > 0.0:
		elite_affix_timers["speed_aura"] = timer
		return

	elite_affix_timers["speed_aura"] = float(elite_affix_data.get("interval", 0.5))
	var radius := float(elite_affix_data.get("radius", 260.0))
	var multiplier := float(elite_affix_data.get("multiplier", 1.3))
	var duration := float(elite_affix_data.get("duration", 0.8))
	var source_id := StringName("elite_speed_aura_%d" % get_instance_id())
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as EnemyBase
		if enemy == null or enemy == self or enemy.is_dead or enemy.is_elite:
			continue
		if enemy.global_position.distance_to(global_position) <= radius:
			enemy.apply_temporary_move_speed_multiplier(source_id, multiplier, duration)


func _update_slow_regen_affix(delta: float) -> void:
	if hp >= max_hp:
		return
	hp = minf(max_hp, hp + float(elite_affix_data.get("regen_per_second", 2.0)) * delta)
	_update_hp_bar()


func _update_acid_volley_affix(delta: float) -> void:
	var timer := maxf(float(elite_affix_timers.get("acid_volley", float(elite_affix_data.get("cooldown", 2.6)))) - delta, 0.0)
	if timer > 0.0:
		elite_affix_timers["acid_volley"] = timer
		return

	elite_affix_timers["acid_volley"] = float(elite_affix_data.get("cooldown", 2.6))
	if not has_valid_target():
		return

	var direction := target.global_position - global_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	direction = direction.rotated(deg_to_rad(randf_range(-18.0, 18.0)))
	var projectile := ELITE_AFFIX_ACID_PROJECTILE_SCRIPT.new() as AcidProjectile
	projectile.collision_mask = 0
	projectile.set_collision_mask_value(1, true)
	projectile.set_collision_mask_value(7, true)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.setup(direction, damage * float(elite_affix_data.get("damage_multiplier", 0.8)), float(elite_affix_data.get("speed", 330.0)), float(elite_affix_data.get("lifetime", 2.1)))


func _spawn_elite_affix_poison_puddle(spawn_position: Vector2, puddle_radius: float, puddle_duration: float) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var puddle := ELITE_AFFIX_POISON_PUDDLE_SCRIPT.new() as PoisonPuddle
	puddle.setup(spawn_position, puddle_radius, puddle_duration)
	get_tree().current_scene.add_child(puddle)


func _ensure_elite_affix_label() -> void:
	_ensure_hp_bar()
	if hp_bar_root == null:
		return

	elite_affix_label = hp_bar_root.get_node_or_null("EliteAffixLabel") as Label
	if elite_affix_label != null:
		return

	elite_affix_label = Label.new()
	elite_affix_label.name = "EliteAffixLabel"
	elite_affix_label.position = Vector2(-72.0, -28.0)
	elite_affix_label.size = Vector2(144.0, 24.0)
	elite_affix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_affix_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.35))
	elite_affix_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	elite_affix_label.add_theme_constant_override("shadow_offset_x", 1)
	elite_affix_label.add_theme_constant_override("shadow_offset_y", 1)
	elite_affix_label.add_theme_font_size_override("font_size", 15)
	elite_affix_label.visible = false
	hp_bar_root.add_child(elite_affix_label)


func _update_enrage_visuals() -> void:
	var progress := clampf((round_enrage_multiplier - 1.0) / 0.5, 0.0, 1.0)
	var visuals := _get_enrage_visuals()
	for visual in visuals:
		if not is_instance_valid(visual):
			continue
		if not enrage_visual_base_modulates.has(visual):
			enrage_visual_base_modulates[visual] = visual.modulate
		var base_color: Color = enrage_visual_base_modulates[visual]
		var target_color := Color(maxf(base_color.r, 1.35), base_color.g * 0.45, base_color.b * 0.45, base_color.a)
		visual.modulate = base_color.lerp(target_color, progress)


func _get_enrage_visuals() -> Array[CanvasItem]:
	var visuals: Array[CanvasItem] = []
	var sprite := get_node_or_null("Sprite2D") as CanvasItem
	if sprite != null:
		visuals.append(sprite)
	else:
		var debug_body := get_node_or_null("DebugBody") as CanvasItem
		if debug_body != null:
			visuals.append(debug_body)
	return visuals


func _play_death_sfx() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var stream := UNDEAD_DEATH_SFX_A if randf() < 0.5 else UNDEAD_DEATH_SFX_B
	SFX_PLAYER.play_2d(parent, stream, global_position, -2.0, 0.88, 1.1)


func _notify_player_kill_once() -> void:
	if kill_notified:
		return
	kill_notified = true
	if last_damage_source != null and last_damage_source.has_method("notify_enemy_killed"):
		last_damage_source.notify_enemy_killed(self)


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in range(points):
		var angle := TAU * float(point) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)

	return polygon
