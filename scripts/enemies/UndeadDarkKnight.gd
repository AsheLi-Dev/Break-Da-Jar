extends EnemyBase
class_name UndeadDarkKnight

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const LEAP_START_FRAME := 4
const LEAP_END_FRAME := 10
const SLAM_ACTIVE_FRAME := 14
const LEAP_SLAM_HOLD_FRAME := 0
const ATTACK_HOLD_SQUASH_SHADER_CODE := "shader_type canvas_item;\nuniform vec2 squash_scale = vec2(1.0, 1.0);\nvoid vertex() { VERTEX *= squash_scale; }\n"

const IDLE_TEXTURE: Texture2D = preload("res://assets/zombies/undead dark knight/Idle.png")
const RUN_TEXTURE: Texture2D = preload("res://assets/zombies/undead dark knight/Run.png")
const CROUCH_IDLE_TEXTURE: Texture2D = preload("res://assets/zombies/undead dark knight/CrouchIdle.png")
const LEAP_SLAM_TEXTURE: Texture2D = preload("res://assets/zombies/undead dark knight/AttackRun.png")
const DIE_TEXTURE: Texture2D = preload("res://assets/zombies/undead dark knight/Die.png")

enum State {
	IDLE,
	CHASE,
	LEAP_SLAM,
	RECOVERY,
}

@export var leap_min_range: float = 50.0
@export var leap_max_range: float = 200.0
@export var leap_slam_radius: float = 80.0
@export var leap_slam_damage: float = 18.0
@export var leap_slam_hold_time: float = 0.5
@export var leap_slam_hold_squash_scale: Vector2 = Vector2(1.025, 0.97)
@export var leap_slam_hold_squash_return_speed: float = 18.0
@export var recovery_time: float = 0.35
@export var animation_fps: float = 14.0

var state: int = State.IDLE
var state_time: float = 0.0
var attack_elapsed: float = 0.0
var cooldown_remaining: float = 0.0
var slam_resolved: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var locked_attack_direction: Vector2 = Vector2.RIGHT
var leap_start_position: Vector2 = Vector2.ZERO
var leap_target_position: Vector2 = Vector2.ZERO
var leap_target_locked: bool = false
var current_animation_name: StringName = &""
var current_hold_squash: Vector2 = Vector2.ONE
var slam_telegraph_active: bool = false

var sprite: Sprite2D
var hold_squash_material: ShaderMaterial
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state: AnimationNodeStateMachinePlayback
var slam_warning: Polygon2D


func _ready() -> void:
	hp_bar_offset_y = -76.0
	super()
	_ensure_dark_knight_nodes()
	_ensure_animation_nodes()
	_play_dark_knight_animation(&"idle", true)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _update_knockback(delta):
		_update_hold_squash(delta)
		return

	_find_target()
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

	match state:
		State.IDLE:
			_enter_state(State.CHASE)
		State.CHASE:
			_update_chase(delta)
		State.LEAP_SLAM:
			_update_leap_slam(delta)
		State.RECOVERY:
			_update_recovery(delta)

	_update_hold_squash(delta)


func die() -> void:
	if is_dead:
		return

	release_attack_token()
	is_dead = true
	_notify_player_kill_once()
	_play_death_sfx()
	_hide_hp_bar()
	if slam_warning != null:
		slam_warning.visible = false
	_reset_hold_squash()
	collision_layer = 0
	collision_mask = 0
	_disable_hitbox()
	died.emit(self)
	_play_dark_knight_animation(&"die", true)
	get_tree().create_timer(_get_animation_time(&"die")).timeout.connect(queue_free)


func _update_chase(delta: float) -> void:
	if not has_valid_target():
		stop_moving()
		_play_dark_knight_animation(&"idle")
		return

	_face_target(target.global_position)
	var distance := global_position.distance_to(target.global_position)
	if cooldown_remaining <= 0.0 and distance >= leap_min_range and distance <= leap_max_range:
		_start_leap_slam()
		return

	move_toward_position(target.global_position, move_speed, delta)
	_play_dark_knight_animation(&"run")


func _start_leap_slam() -> void:
	if not try_claim_attack_token():
		return

	_enter_state(State.LEAP_SLAM)
	attack_elapsed = 0.0
	slam_resolved = false
	leap_target_locked = false
	_reset_hold_squash()
	locked_attack_direction = facing_direction
	leap_start_position = global_position
	leap_target_position = _get_leap_target_position()
	_update_slam_warning(false)
	stop_moving()
	_play_dark_knight_animation(&"leap_slam", true)


func _update_leap_slam(delta: float) -> void:
	attack_elapsed += delta
	_update_leap_target_lock()
	_update_leap_motion(delta)

	if not slam_resolved and attack_elapsed >= _get_slam_active_time():
		slam_resolved = true
		_do_slam()
	else:
		_update_leap_telegraph()

	if attack_elapsed >= _get_animation_time(&"leap_slam"):
		_start_recovery()


func _update_leap_motion(delta: float) -> void:
	var frame := _get_leap_slam_frame_at_time(attack_elapsed)
	if frame < LEAP_START_FRAME or frame > LEAP_END_FRAME:
		stop_moving()
		return

	var leap_start_time := _get_leap_slam_frame_start_time(LEAP_START_FRAME)
	var leap_end_time := _get_leap_slam_frame_start_time(LEAP_END_FRAME + 1)
	var leap_progress := clampf((attack_elapsed - leap_start_time) / maxf(leap_end_time - leap_start_time, 0.001), 0.0, 1.0)
	var eased_progress := smoothstep(0.0, 1.0, leap_progress)
	var next_position := leap_start_position.lerp(leap_target_position, eased_progress)
	var offset := next_position - global_position
	if offset.length_squared() <= 0.01:
		stop_moving()
		return

	var direction := offset.normalized()
	_face_target(global_position + direction)
	velocity = offset / maxf(delta, 0.001)
	move_and_slide()


func _update_leap_target_lock() -> void:
	if leap_target_locked:
		return

	leap_target_position = _get_leap_target_position()
	var offset := leap_target_position - global_position
	if offset.length_squared() > 0.001:
		locked_attack_direction = offset.normalized()
		_face_target(leap_target_position)

	if attack_elapsed >= _get_leap_slam_hold_end_time():
		leap_target_locked = true


func _get_leap_target_position() -> Vector2:
	var fallback_target := global_position + locked_attack_direction * leap_max_range
	var target_position := target.global_position if has_valid_target() else fallback_target
	var offset := target_position - global_position
	if offset.length_squared() <= 0.001:
		return fallback_target

	var distance := minf(offset.length(), leap_max_range)
	return global_position + offset.normalized() * distance


func _do_slam() -> void:
	if slam_warning != null:
		slam_warning.visible = false
	slam_telegraph_active = false
	_damage_players_in_radius(leap_slam_radius, leap_slam_damage)
	_spawn_slam_vfx()


func _start_recovery() -> void:
	release_attack_token()
	_reset_hold_squash()
	_enter_state(State.RECOVERY)
	state_time = recovery_time
	cooldown_remaining = attack_cooldown
	stop_moving()


func _update_recovery(delta: float) -> void:
	stop_moving()
	state_time -= delta
	if state_time <= 0.0:
		_enter_state(State.CHASE)


func _enter_state(next_state: int) -> void:
	state = next_state
	if slam_warning != null:
		slam_warning.visible = false
	slam_telegraph_active = false


func _update_hold_squash(delta: float) -> void:
	if hold_squash_material == null:
		return

	var target_scale := Vector2.ONE
	if state == State.LEAP_SLAM and leap_slam_hold_time > 0.0:
		var hold_start := _get_leap_slam_frame_start_time(LEAP_SLAM_HOLD_FRAME)
		var hold_end := hold_start + maxf(leap_slam_hold_time, 0.0)
		if attack_elapsed >= hold_start and attack_elapsed <= hold_end:
			var hold_progress := clampf((attack_elapsed - hold_start) / maxf(leap_slam_hold_time, 0.001), 0.0, 1.0)
			target_scale = Vector2.ONE.lerp(leap_slam_hold_squash_scale, smoothstep(0.0, 1.0, hold_progress))

	var blend := 1.0 - exp(-leap_slam_hold_squash_return_speed * delta)
	current_hold_squash = current_hold_squash.lerp(target_scale, blend)
	_set_hold_squash(current_hold_squash)


func _reset_hold_squash() -> void:
	current_hold_squash = Vector2.ONE
	_set_hold_squash(current_hold_squash)


func _set_hold_squash(squash_scale: Vector2) -> void:
	if hold_squash_material != null:
		hold_squash_material.set_shader_parameter("squash_scale", squash_scale)


func _damage_players_in_radius(radius: float, attack_damage: float) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Node2D
		if player == null or not player.has_method("take_damage"):
			continue
		if player.global_position.distance_to(global_position) <= radius:
			player.call("take_damage", attack_damage)


func _update_slam_warning(visible: bool, progress: float = 0.0) -> void:
	if slam_warning == null:
		return
	if not visible:
		slam_warning.visible = false
		slam_telegraph_active = false
		return

	if not slam_telegraph_active:
		slam_telegraph_active = true
		slam_warning.scale = Vector2.ONE * 0.72
	slam_warning.global_position = leap_target_position
	var eased_progress := smoothstep(0.0, 1.0, clampf(progress, 0.0, 1.0))
	slam_warning.scale = Vector2.ONE * lerpf(0.72, 1.0, eased_progress)
	slam_warning.color = Color(1.0, 0.18, 0.0, lerpf(0.08, 0.24, eased_progress))
	slam_warning.visible = true


func _update_leap_telegraph() -> void:
	if state != State.LEAP_SLAM or slam_resolved:
		_update_slam_warning(false)
		return

	var hold_start := _get_leap_slam_frame_start_time(LEAP_SLAM_HOLD_FRAME)
	if attack_elapsed < hold_start:
		_update_slam_warning(false)
		return

	var slam_time := _get_slam_active_time()
	var progress := clampf((attack_elapsed - hold_start) / maxf(slam_time - hold_start, 0.001), 0.0, 1.0)
	_update_slam_warning(true, progress)


func _spawn_slam_vfx() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return

	var effect := Node2D.new()
	effect.name = "UndeadDarkKnightSlamVFX"
	effect.global_position = global_position
	effect.z_index = 120
	parent.add_child(effect)

	for index in range(3):
		var ring := Line2D.new()
		ring.name = "ImpactRing%d" % index
		ring.closed = true
		ring.width = 5.0 - float(index)
		ring.default_color = Color(0.95, 0.72, 0.38, 0.35 - float(index) * 0.08)
		ring.antialiased = true
		var radius := leap_slam_radius * lerpf(0.28, 0.72, float(index) / 2.0)
		for point_index in range(32):
			var angle := TAU * float(point_index) / 32.0
			var wobble := sin(angle * 5.0 + float(index)) * 4.0
			ring.add_point(Vector2(cos(angle), sin(angle)) * (radius + wobble))
		effect.add_child(ring)

	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2.ONE * 1.18, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(effect, "queue_free"))


func _disable_hitbox() -> void:
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		return

	hitbox.set_deferred("monitorable", false)
	hitbox.set_deferred("collision_layer", 0)
	hitbox.set_deferred("collision_mask", 0)


func _ensure_dark_knight_nodes() -> void:
	slam_warning = get_node_or_null("SlamWarning") as Polygon2D
	if slam_warning == null:
		slam_warning = Polygon2D.new()
		slam_warning.name = "SlamWarning"
		add_child(slam_warning)
	slam_warning.top_level = true
	slam_warning.z_index = 90
	slam_warning.color = Color(1.0, 0.18, 0.0, 0.22)
	slam_warning.polygon = _circle_polygon(leap_slam_radius, 40)
	slam_warning.visible = false


func _face_target(world_position: Vector2) -> void:
	var offset := world_position - global_position
	if offset.length_squared() <= 0.001:
		return

	facing_direction = offset.normalized()
	rotation = facing_direction.angle()
	if sprite != null:
		sprite.rotation = -rotation


func _ensure_animation_nodes() -> void:
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
	sprite.rotation = -rotation
	_ensure_hold_squash_material()

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


func _ensure_hold_squash_material() -> void:
	var shader := Shader.new()
	shader.code = ATTACK_HOLD_SQUASH_SHADER_CODE
	hold_squash_material = ShaderMaterial.new()
	hold_squash_material.shader = shader
	sprite.material = hold_squash_material
	_set_hold_squash(Vector2.ONE)


func _build_animation_library() -> void:
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")

	var library := AnimationLibrary.new()
	for animation_base in [&"idle", &"run", &"leap_slam", &"die"]:
		for row in range(DIRECTION_COUNT):
			var animation_name := "%s_%d" % [String(animation_base), row]
			library.add_animation(animation_name, _create_direction_animation(animation_base, row))

	animation_player.add_animation_library("", library)


func _build_animation_state_machine() -> void:
	var state_machine := AnimationNodeStateMachine.new()
	for animation_base in [&"idle", &"run", &"leap_slam", &"die"]:
		for row in range(DIRECTION_COUNT):
			var animation_name := "%s_%d" % [String(animation_base), row]
			var animation_node := AnimationNodeAnimation.new()
			animation_node.animation = animation_name
			state_machine.add_node(animation_name, animation_node)

	animation_tree.tree_root = state_machine


func _create_direction_animation(animation_base: StringName, row: int) -> Animation:
	if animation_base == &"leap_slam":
		return _create_leap_slam_animation(row)

	var animation := Animation.new()
	animation.length = _get_animation_time(animation_base)
	animation.loop_mode = Animation.LOOP_LINEAR if animation_base == &"idle" or animation_base == &"run" else Animation.LOOP_NONE

	var texture_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(texture_track, NodePath("Sprite2D:texture"))
	animation.track_set_interpolation_type(texture_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(texture_track, Animation.UPDATE_DISCRETE)
	animation.track_insert_key(texture_track, 0.0, _get_animation_texture(animation_base))

	var region_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(region_track, NodePath("Sprite2D:region_rect"))
	animation.track_set_interpolation_type(region_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(region_track, Animation.UPDATE_DISCRETE)

	for frame in range(FRAMES_PER_DIRECTION):
		var region := Rect2(
			Vector2(frame * FRAME_SIZE.x, row * FRAME_SIZE.y),
			Vector2(FRAME_SIZE)
		)
		animation.track_insert_key(region_track, _get_frame_start_time(animation_base, frame), region)

	return animation


func _create_leap_slam_animation(row: int) -> Animation:
	var animation := Animation.new()
	animation.length = _get_animation_time(&"leap_slam")
	animation.loop_mode = Animation.LOOP_NONE

	var texture_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(texture_track, NodePath("Sprite2D:texture"))
	animation.track_set_interpolation_type(texture_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(texture_track, Animation.UPDATE_DISCRETE)
	animation.track_insert_key(texture_track, 0.0, CROUCH_IDLE_TEXTURE)
	animation.track_insert_key(texture_track, maxf(leap_slam_hold_time, 0.0), LEAP_SLAM_TEXTURE)

	var region_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(region_track, NodePath("Sprite2D:region_rect"))
	animation.track_set_interpolation_type(region_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(region_track, Animation.UPDATE_DISCRETE)

	var hold_time := maxf(leap_slam_hold_time, 0.0)
	var hold_frame_count := maxi(1, ceili(hold_time * animation_fps))
	for hold_frame in range(hold_frame_count):
		var crouch_frame := hold_frame % FRAMES_PER_DIRECTION
		var crouch_region := Rect2(
			Vector2(crouch_frame * FRAME_SIZE.x, row * FRAME_SIZE.y),
			Vector2(FRAME_SIZE)
		)
		animation.track_insert_key(region_track, float(hold_frame) / animation_fps, crouch_region)

	for frame in range(FRAMES_PER_DIRECTION):
		var region := Rect2(
			Vector2(frame * FRAME_SIZE.x, row * FRAME_SIZE.y),
			Vector2(FRAME_SIZE)
		)
		animation.track_insert_key(region_track, _get_frame_start_time(&"leap_slam", frame), region)
		if frame == LEAP_SLAM_HOLD_FRAME:
			animation.track_insert_key(region_track, hold_time, region)

	return animation


func _get_animation_texture(animation_name: StringName) -> Texture2D:
	match animation_name:
		&"leap_slam":
			return LEAP_SLAM_TEXTURE
		&"die":
			return DIE_TEXTURE
		&"run":
			return RUN_TEXTURE
		_:
			return IDLE_TEXTURE


func _play_dark_knight_animation(animation_name: StringName, force_restart: bool = false) -> void:
	var direction_row := _get_direction_row(facing_direction)
	var tree_animation_name := StringName("%s_%d" % [String(animation_name), direction_row])
	if current_animation_name == tree_animation_name and not force_restart:
		return

	current_animation_name = tree_animation_name
	if sprite != null:
		sprite.rotation = -rotation
	if animation_state != null:
		if force_restart:
			animation_state.start(String(tree_animation_name), true)
		else:
			animation_state.travel(String(tree_animation_name))
	else:
		animation_player.play(String(tree_animation_name))


func _get_slam_active_time() -> float:
	return _get_leap_slam_frame_start_time(SLAM_ACTIVE_FRAME)


func _get_leap_slam_hold_end_time() -> float:
	return _get_leap_slam_frame_start_time(LEAP_SLAM_HOLD_FRAME) + maxf(leap_slam_hold_time, 0.0)


func _get_animation_time(animation_name: StringName) -> float:
	var time := float(FRAMES_PER_DIRECTION) / animation_fps
	if animation_name == &"leap_slam":
		time += maxf(leap_slam_hold_time, 0.0)
	return time


func _get_frame_start_time(animation_name: StringName, frame: int) -> float:
	if animation_name == &"leap_slam":
		return _get_leap_slam_frame_start_time(frame)
	return float(frame) / animation_fps


func _get_leap_slam_frame_start_time(frame: int) -> float:
	var time := float(frame) / animation_fps
	if frame > LEAP_SLAM_HOLD_FRAME:
		time += maxf(leap_slam_hold_time, 0.0)
	return time


func _get_leap_slam_frame_at_time(time: float) -> int:
	for frame in range(FRAMES_PER_DIRECTION - 1, -1, -1):
		if time >= _get_leap_slam_frame_start_time(frame):
			return frame
	return 0


func _get_direction_row(direction: Vector2) -> int:
	if direction.length_squared() <= 0.001:
		return 0

	var angle := fposmod(direction.angle(), TAU)
	return int(round(angle / (PI * 0.25))) % DIRECTION_COUNT
