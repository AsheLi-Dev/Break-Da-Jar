extends CharacterBody2D
class_name Player

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const ATTACK_PROJECTILE_FRAME := 7

const ABILITY_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/ability.png")
const ATTACK_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/attack.png")
const ATTACK_ALT_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/attack_alt.png")
const IDLE_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/idle.png")
const ROLLING_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/rolling.png")
const RUN_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/run.png")

enum State {
	NORMAL,
	DASHING,
	SLIDING,
}

# Movement tuning. Acceleration/friction control top-down feel.
@export var move_speed: float = 240.0
@export var acceleration: float = 1600.0
@export var friction: float = 1900.0

# Health. Enemy attacks should call take_damage(amount).
@export var max_hp: float = 100.0
var hp: float

# Holy bolt tuning. Hold shoot for automatic fire.
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 620.0
@export var projectile_damage: float = 12.0
@export var projectile_lifetime: float = 1.4
@export var fire_rate: float = 1.0
@export var attack_slow_edge_frames: int = 3
@export var attack_edge_animation_fps: float = 15.0
@export var attack_fast_animation_fps: float = 36.0
@export var attack_move_speed_multiplier: float = 0.5

# Holy shockwave tuning. Area2D applies damage and knockback explicitly.
@export var shockwave_damage: float = 18.0
@export var shockwave_radius: float = 118.0
@export var shockwave_knockback: float = 430.0
@export var shockwave_cooldown: float = 6.0
@export var shockwave_visible_time: float = 0.16

# Dash is a short reposition. Slide is the invincible enemy-pass-through followup.
@export var dash_speed: float = 560.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.75
@export var slide_speed: float = 620.0
@export var slide_duration: float = 0.28
@export var slide_cancel_window: float = 0.1
@export var invincible_time: float = 0.3

# Collision mask bit for enemies. Layer numbers are 1-based in the editor.
@export var enemy_collision_layer_number: int = 2
@export var world_collision_layer_number: int = 1
@export var animation_fps: float = 15.0

var state: int = State.NORMAL
var facing_direction: Vector2 = Vector2.RIGHT
var animation_direction: Vector2 = Vector2.RIGHT
var dash_direction: Vector2 = Vector2.RIGHT
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var slide_time_remaining: float = 0.0
var slide_window_remaining: float = 0.0
var invincible_remaining: float = 0.0
var fire_cooldown_remaining: float = 0.0
var shockwave_cooldown_remaining: float = 0.0
var saved_collision_mask: int = 0
var is_invincible: bool = false

var gun_pivot: Node2D
var muzzle: Marker2D
var shockwave_area: Area2D
var shockwave_collision: CollisionShape2D
var shockwave_visual: Polygon2D
var sprite: Sprite2D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state: AnimationNodeStateMachinePlayback
var current_animation: StringName = &"idle"
var current_animation_name: StringName = &""
var action_animation: StringName = &""
var action_animation_remaining: float = 0.0
var action_animation_elapsed: float = 0.0
var pending_attack_projectile: bool = false
var pending_attack_target_position: Vector2 = Vector2.ZERO
var action_direction_locked: bool = false
var action_animation_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	saved_collision_mask = collision_mask
	_ensure_placeholder_nodes()


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_facing()

	match state:
		State.NORMAL:
			_update_normal_movement(delta)
			if Input.is_action_just_pressed("dash"):
				_try_start_dash()
		State.DASHING:
			_update_dash(delta)
		State.SLIDING:
			_update_slide(delta)

	if Input.is_action_just_pressed("slide"):
		_try_start_slide()

	if Input.is_action_pressed("shoot"):
		_try_fire_projectile()

	if Input.is_action_just_pressed("skill"):
		_try_cast_shockwave()

	_update_sprite_animation(delta)


func take_damage(amount: float) -> void:
	if is_invincible:
		return

	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		die()


func die() -> void:
	queue_free()


func _update_timers(delta: float) -> void:
	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
	shockwave_cooldown_remaining = maxf(0.0, shockwave_cooldown_remaining - delta)
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	slide_window_remaining = maxf(0.0, slide_window_remaining - delta)
	invincible_remaining = maxf(0.0, invincible_remaining - delta)
	is_invincible = invincible_remaining > 0.0


func _update_normal_movement(delta: float) -> void:
	var input_direction: Vector2 = _get_move_input()
	var target_speed: float = move_speed
	if _is_attack_movement_slowed():
		target_speed *= attack_move_speed_multiplier

	if input_direction.length_squared() > 0.0:
		velocity = velocity.move_toward(input_direction * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()


func _try_start_dash() -> void:
	if dash_cooldown_remaining > 0.0:
		return
	if not _can_cancel_current_action():
		return

	var input_direction: Vector2 = _get_move_input()
	if input_direction.length_squared() > 0.0:
		dash_direction = input_direction.normalized()
	else:
		dash_direction = facing_direction.normalized()

	_cancel_current_action()
	state = State.DASHING
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	slide_window_remaining = dash_duration + slide_cancel_window
	velocity = dash_direction * dash_speed


func _update_dash(delta: float) -> void:
	dash_time_remaining -= delta
	velocity = dash_direction * dash_speed
	move_and_slide()

	if dash_time_remaining <= 0.0:
		state = State.NORMAL


func _try_start_slide() -> void:
	if state == State.SLIDING or slide_window_remaining <= 0.0:
		return
	if not _can_cancel_current_action():
		return

	if dash_direction.length_squared() <= 0.001:
		dash_direction = facing_direction.normalized()

	_cancel_current_action()
	state = State.SLIDING
	slide_time_remaining = slide_duration
	slide_window_remaining = 0.0
	invincible_remaining = maxf(invincible_remaining, invincible_time)
	is_invincible = true
	velocity = dash_direction * slide_speed
	_play_action_animation(&"rolling", _get_full_animation_time())

	# Slide-through-enemies: temporarily stop colliding with enemy bodies.
	saved_collision_mask = collision_mask
	set_collision_mask_value(enemy_collision_layer_number, false)


func _update_slide(delta: float) -> void:
	slide_time_remaining -= delta
	velocity = dash_direction * slide_speed
	move_and_slide()

	# Optional future upgrade: add a DashHitbox Area2D to damage or knock back enemies along the slide path.
	if slide_time_remaining <= 0.0:
		state = State.NORMAL
		collision_mask = saved_collision_mask


func _try_fire_projectile() -> void:
	if fire_cooldown_remaining > 0.0:
		return

	fire_cooldown_remaining = _get_fire_interval()
	pending_attack_projectile = true
	pending_attack_target_position = get_global_mouse_position()
	_play_action_animation_with_direction(&"attack", _get_action_animation_time(&"attack"), facing_direction)


func _try_cast_shockwave() -> void:
	if shockwave_cooldown_remaining > 0.0:
		return

	shockwave_cooldown_remaining = shockwave_cooldown
	shockwave_visual.visible = true
	_play_action_animation_with_direction(&"ability", shockwave_visible_time, facing_direction)
	get_tree().create_timer(shockwave_visible_time).timeout.connect(_hide_shockwave_visual)

	for body in shockwave_area.get_overlapping_bodies():
		if not body.is_in_group("enemy"):
			continue

		if body.has_method("take_damage"):
			body.call("take_damage", shockwave_damage)

		if body.has_method("apply_knockback"):
			var body_2d: Node2D = body as Node2D
			if body_2d == null:
				continue

			var knockback_direction: Vector2 = (body_2d.global_position - global_position).normalized()
			if knockback_direction.length_squared() <= 0.001:
				knockback_direction = facing_direction
			body.call("apply_knockback", knockback_direction * shockwave_knockback)


func _spawn_projectile(spawn_position: Vector2, direction: Vector2) -> Projectile:
	var projectile: Projectile
	if projectile_scene != null:
		projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		projectile = Projectile.new()

	projectile.global_position = spawn_position
	get_tree().current_scene.add_child(projectile)
	projectile.direction = direction
	return projectile


func _hide_shockwave_visual() -> void:
	if is_instance_valid(shockwave_visual):
		shockwave_visual.visible = false


func _update_facing() -> void:
	var mouse_offset: Vector2 = get_global_mouse_position() - global_position
	if mouse_offset.length_squared() > 0.001:
		facing_direction = mouse_offset.normalized()
	elif _get_move_input().length_squared() > 0.0:
		facing_direction = _get_move_input().normalized()

	gun_pivot.rotation = facing_direction.angle()
	_update_animation_direction()


func _update_animation_direction() -> void:
	if action_direction_locked:
		animation_direction = action_animation_direction
		return

	if _uses_movement_animation_direction():
		var move_direction: Vector2 = _get_move_input()
		if state == State.DASHING or state == State.SLIDING:
			move_direction = dash_direction
		elif velocity.length_squared() > 16.0:
			move_direction = velocity.normalized()

		if move_direction.length_squared() > 0.001:
			animation_direction = move_direction.normalized()
	else:
		animation_direction = facing_direction


func _uses_movement_animation_direction() -> bool:
	return current_animation == &"run" or current_animation == &"rolling"


func _play_action_animation(animation_name: StringName, duration: float) -> void:
	action_direction_locked = false
	action_animation = animation_name
	action_animation_remaining = duration
	action_animation_elapsed = 0.0
	_play_sprite_animation(animation_name, true)


func _play_action_animation_with_direction(animation_name: StringName, duration: float, direction: Vector2) -> void:
	action_direction_locked = true
	action_animation_direction = direction.normalized()
	animation_direction = action_animation_direction
	action_animation = animation_name
	action_animation_remaining = duration
	action_animation_elapsed = 0.0
	_play_sprite_animation(animation_name, true)


func _get_full_animation_time() -> float:
	return float(FRAMES_PER_DIRECTION) / animation_fps


func _get_action_animation_time(animation_name: StringName) -> float:
	if animation_name == &"attack":
		return _get_fire_interval()

	return _get_full_animation_time()


func _update_sprite_animation(delta: float) -> void:
	if action_animation_remaining > 0.0:
		action_animation_elapsed += delta
		action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
		_maybe_spawn_attack_projectile()
		if action_animation_remaining <= 0.0:
			action_direction_locked = false
		return

	var wanted_animation: StringName = _get_locomotion_animation()
	_play_sprite_animation(wanted_animation)


func _get_locomotion_animation() -> StringName:
	if state == State.SLIDING:
		return &"rolling"
	if state == State.DASHING:
		return &"run"
	if velocity.length_squared() > 16.0:
		return &"run"

	return &"idle"


func _is_attack_movement_slowed() -> bool:
	return fire_cooldown_remaining > 0.0


func _play_sprite_animation(animation_name: StringName, force_restart: bool = false) -> void:
	var direction_row: int = _get_direction_row(animation_direction)
	var tree_animation_name: StringName = StringName("%s_%d" % [String(animation_name), direction_row])
	if current_animation_name == tree_animation_name and not force_restart:
		return

	if current_animation == &"attack" and animation_name != &"attack":
		pending_attack_projectile = false

	current_animation = animation_name
	current_animation_name = tree_animation_name
	if animation_state != null:
		if force_restart:
			animation_state.start(String(tree_animation_name), true)
		else:
			animation_state.travel(String(tree_animation_name))
	else:
		animation_player.play(String(tree_animation_name))


func _maybe_spawn_attack_projectile() -> void:
	if not pending_attack_projectile or current_animation != &"attack":
		return

	if action_animation_elapsed < _get_attack_projectile_time():
		return

	pending_attack_projectile = false
	_spawn_holy_bolt_at(pending_attack_target_position)


func _get_attack_projectile_time() -> float:
	var time: float = 0.0
	for frame in range(ATTACK_PROJECTILE_FRAME):
		time += _get_attack_windup_frame_duration(frame)

	return time


func _get_fire_interval() -> float:
	return 1.0 / maxf(fire_rate, 0.01)


func _can_cancel_current_action() -> bool:
	if action_animation_remaining <= 0.0:
		return true
	if action_animation != &"attack":
		return false

	return action_animation_elapsed >= _get_attack_projectile_time()


func _cancel_current_action() -> void:
	if action_animation_remaining <= 0.0:
		return

	action_animation = &""
	action_animation_remaining = 0.0
	action_animation_elapsed = 0.0
	pending_attack_projectile = false
	action_direction_locked = false


func _spawn_holy_bolt_at(target_position: Vector2) -> void:
	var direction: Vector2 = target_position - muzzle.global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()

	var projectile: Projectile = _spawn_projectile(muzzle.global_position, direction)
	projectile.collision_mask = 0
	projectile.set_collision_mask_value(enemy_collision_layer_number, true)
	projectile.set_collision_mask_value(world_collision_layer_number, true)
	projectile.setup(direction, projectile_damage, projectile_speed, projectile_lifetime, &"enemy")


func _get_animation_texture(animation_name: StringName) -> Texture2D:
	match animation_name:
		&"attack":
			return ATTACK_TEXTURE
		&"attack_alt":
			return ATTACK_ALT_TEXTURE
		&"ability":
			return ABILITY_TEXTURE
		&"rolling":
			return ROLLING_TEXTURE
		&"run":
			return RUN_TEXTURE
		_:
			return IDLE_TEXTURE


func _get_direction_row(direction: Vector2) -> int:
	if direction.length_squared() <= 0.001:
		return 0

	var angle: float = fposmod(direction.angle(), TAU)
	return int(round(angle / (PI * 0.25))) % DIRECTION_COUNT


func _get_move_input() -> Vector2:
	var input_direction: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	return input_direction.normalized()


func _ensure_placeholder_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 14.0
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("DebugBody") == null:
		var body: Polygon2D = Polygon2D.new()
		body.name = "DebugBody"
		body.color = Color(0.92, 0.88, 0.52)
		body.polygon = PackedVector2Array([
			Vector2(18.0, 0.0),
			Vector2(7.0, 13.0),
			Vector2(-12.0, 10.0),
			Vector2(-16.0, 0.0),
			Vector2(-12.0, -10.0),
			Vector2(7.0, -13.0),
		])
		add_child(body)
	var debug_body := get_node_or_null("DebugBody") as CanvasItem
	if debug_body != null:
		debug_body.visible = false

	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		move_child(sprite, 1)
	sprite.centered = true
	sprite.region_enabled = true
	sprite.texture = IDLE_TEXTURE
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))

	_ensure_animation_tree()
	_play_sprite_animation(&"idle")

	gun_pivot = get_node_or_null("GunPivot") as Node2D
	if gun_pivot == null:
		gun_pivot = Node2D.new()
		gun_pivot.name = "GunPivot"
		add_child(gun_pivot)

	muzzle = gun_pivot.get_node_or_null("Muzzle") as Marker2D
	if muzzle == null:
		muzzle = Marker2D.new()
		muzzle.name = "Muzzle"
		muzzle.position = Vector2(28.0, 0.0)
		gun_pivot.add_child(muzzle)

	shockwave_area = get_node_or_null("ShockwaveArea") as Area2D
	if shockwave_area == null:
		shockwave_area = Area2D.new()
		shockwave_area.name = "ShockwaveArea"
		add_child(shockwave_area)
	shockwave_area.monitoring = true
	shockwave_area.monitorable = false
	shockwave_area.collision_mask = 0
	shockwave_area.set_collision_mask_value(enemy_collision_layer_number, true)

	shockwave_collision = shockwave_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shockwave_collision == null:
		shockwave_collision = CollisionShape2D.new()
		shockwave_collision.name = "CollisionShape2D"
		shockwave_area.add_child(shockwave_collision)
	var shockwave_shape: CircleShape2D = CircleShape2D.new()
	shockwave_shape.radius = shockwave_radius
	shockwave_collision.shape = shockwave_shape

	shockwave_visual = get_node_or_null("ShockwaveVisual") as Polygon2D
	if shockwave_visual == null:
		shockwave_visual = Polygon2D.new()
		shockwave_visual.name = "ShockwaveVisual"
		add_child(shockwave_visual)
	shockwave_visual.color = Color(1.0, 0.96, 0.42, 0.22)
	shockwave_visual.polygon = _circle_polygon(shockwave_radius, 36)
	shockwave_visual.visible = false


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	for point in range(points):
		var angle: float = TAU * float(point) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)

	return polygon


func _ensure_animation_tree() -> void:
	animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
	animation_player.root_node = NodePath("..")

	animation_tree = get_node_or_null("AnimationTree") as AnimationTree
	if animation_tree == null:
		animation_tree = AnimationTree.new()
		animation_tree.name = "AnimationTree"
		add_child(animation_tree)

	_build_animation_library()
	_build_animation_state_machine()

	animation_tree.set("anim_player", NodePath("../AnimationPlayer"))
	animation_tree.active = true
	animation_state = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback


func _build_animation_library() -> void:
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")

	var library := AnimationLibrary.new()
	var animation_bases: Array[StringName] = [
		&"idle",
		&"run",
		&"attack",
		&"ability",
		&"rolling",
	]

	for animation_base in animation_bases:
		for row in range(DIRECTION_COUNT):
			var animation_name: String = "%s_%d" % [String(animation_base), row]
			library.add_animation(animation_name, _create_direction_animation(animation_base, row))

	animation_player.add_animation_library("", library)


func _build_animation_state_machine() -> void:
	var state_machine := AnimationNodeStateMachine.new()
	var animation_bases: Array[StringName] = [
		&"idle",
		&"run",
		&"attack",
		&"ability",
		&"rolling",
	]

	for animation_base in animation_bases:
		for row in range(DIRECTION_COUNT):
			var animation_name: String = "%s_%d" % [String(animation_base), row]
			var animation_node := AnimationNodeAnimation.new()
			animation_node.animation = animation_name
			state_machine.add_node(animation_name, animation_node)

	animation_tree.tree_root = state_machine


func _create_direction_animation(animation_base: StringName, row: int) -> Animation:
	var animation := Animation.new()
	animation.length = _get_animation_length(animation_base)
	animation.loop_mode = _get_animation_loop_mode(animation_base)

	var texture_track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(texture_track, NodePath("Sprite2D:texture"))
	animation.track_set_interpolation_type(texture_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(texture_track, Animation.UPDATE_DISCRETE)
	animation.track_insert_key(texture_track, 0.0, _get_animation_texture(animation_base))

	var region_track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(region_track, NodePath("Sprite2D:region_rect"))
	animation.track_set_interpolation_type(region_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(region_track, Animation.UPDATE_DISCRETE)

	var time: float = 0.0
	for frame in range(FRAMES_PER_DIRECTION):
		var region := Rect2(
			Vector2(frame * FRAME_SIZE.x, row * FRAME_SIZE.y),
			Vector2(FRAME_SIZE)
		)
		animation.track_insert_key(region_track, time, region)
		time += _get_frame_duration(animation_base, frame)

	return animation


func _get_animation_length(animation_base: StringName) -> float:
	var length: float = 0.0
	for frame in range(FRAMES_PER_DIRECTION):
		length += _get_frame_duration(animation_base, frame)

	return maxf(length, 0.001)


func _get_frame_duration(animation_base: StringName, frame: int) -> float:
	if animation_base == &"attack":
		return _get_attack_frame_duration(frame)

	return 1.0 / animation_fps


func _get_attack_frame_duration(frame: int) -> float:
	if frame < ATTACK_PROJECTILE_FRAME:
		return _get_attack_windup_frame_duration(frame)

	var slow_edge_frames: int = clampi(attack_slow_edge_frames, 0, FRAMES_PER_DIRECTION)
	var slow_recovery_start: int = max(ATTACK_PROJECTILE_FRAME, FRAMES_PER_DIRECTION - slow_edge_frames)
	if frame >= slow_recovery_start:
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	var windup_time: float = _get_attack_projectile_time()
	var slow_recovery_frame_count: int = FRAMES_PER_DIRECTION - slow_recovery_start
	var slow_recovery_time: float = float(slow_recovery_frame_count) / maxf(attack_edge_animation_fps, 0.01)
	var middle_recovery_frame_count: int = slow_recovery_start - ATTACK_PROJECTILE_FRAME
	if middle_recovery_frame_count <= 0:
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	var middle_recovery_time: float = maxf(_get_fire_interval() - windup_time - slow_recovery_time, 0.001)
	return middle_recovery_time / float(middle_recovery_frame_count)


func _get_attack_windup_frame_duration(frame: int) -> float:
	if frame < clampi(attack_slow_edge_frames, 0, ATTACK_PROJECTILE_FRAME):
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	return 1.0 / maxf(attack_fast_animation_fps, 0.01)


func _get_animation_loop_mode(animation_base: StringName) -> int:
	if animation_base == &"idle" or animation_base == &"run":
		return Animation.LOOP_LINEAR

	return Animation.LOOP_NONE
