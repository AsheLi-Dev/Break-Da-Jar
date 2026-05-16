extends EnemyBase
class_name ZombieFireman

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const PROJECTILE_SPAWN_FRAME := 7
const ATTACK_HOLD_FRAME := 4
const AIM_RANDOM_SPREAD_DEGREES := 6.0
const ATTACK_HOLD_SQUASH_SHADER_CODE := "shader_type canvas_item;\nuniform vec2 squash_scale = vec2(1.0, 1.0);\nvoid vertex() { VERTEX *= squash_scale; }\n"

const AXE_PROJECTILE_SCRIPT := preload("res://systems/combat/FiremanAxeProjectile.gd")
const ATTACK_TEXTURE: Texture2D = preload("res://assets/zombies/Zombie Fireman/Attack 1.png")
const DIE_TEXTURE: Texture2D = preload("res://assets/zombies/Zombie Fireman/Die (Gore).png")
const IDLE_TEXTURE: Texture2D = preload("res://assets/zombies/Zombie Fireman/Idle 1.png")
const RUN_TEXTURE: Texture2D = preload("res://assets/zombies/Zombie Fireman/Run.png")
const TAKE_DAMAGE_TEXTURE: Texture2D = preload("res://assets/zombies/Zombie Fireman/TakeDamage.png")

@export var ideal_distance: float = 250.0
@export var distance_tolerance: float = 38.0
@export var fire_cooldown: float = 1.65
@export var projectile_speed: float = 380.0
@export var projectile_lifetime: float = 2.1
@export var aim_line_length: float = 310.0
@export var animation_fps: float = 15.0
@export var attack_hold_time: float = 0.18
@export var attack_hold_squash_scale: Vector2 = Vector2(1.025, 0.98)
@export var attack_hold_squash_return_speed: float = 18.0
@export var take_damage_animation_time: float = 0.2

var cooldown_remaining: float = 0.0
var is_aiming: bool = false
var attack_elapsed: float = 0.0
var projectile_fired: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var locked_attack_direction: Vector2 = Vector2.RIGHT
var action_animation_remaining: float = 0.0
var current_animation_name: StringName = &""
var current_attack_hold_squash: Vector2 = Vector2.ONE

var aim_line: Line2D
var sprite: Sprite2D
var attack_hold_squash_material: ShaderMaterial
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state: AnimationNodeStateMachinePlayback


func _ready() -> void:
	super()
	_ensure_ranged_nodes()
	_ensure_animation_nodes()
	_play_fireman_animation(&"idle", true)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_stunned():
		_handle_stunned_physics(delta)
		return

	if _update_knockback(delta):
		_update_attack_hold_squash(delta)
		return

	_find_target()
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

	if not has_valid_target():
		aim_line.visible = false
		stop_moving()
		_update_fireman_animation(delta)
		_update_attack_hold_squash(delta)
		return

	if is_aiming:
		_update_aim(delta)
		_update_fireman_animation(delta)
		_update_attack_hold_squash(delta)
		return

	_face_target(target.global_position)
	_update_spacing(delta)

	if cooldown_remaining <= 0.0:
		_start_aim()

	_update_fireman_animation(delta)
	_update_attack_hold_squash(delta)


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
		return old_hp

	_start_action_animation(&"take_damage", take_damage_animation_time)
	return old_hp - hp


func die() -> void:
	if is_dead:
		return

	release_attack_token()
	is_dead = true
	_notify_player_kill_once()
	_play_death_sfx()
	_hide_hp_bar()
	aim_line.visible = false
	_reset_attack_hold_squash()
	collision_layer = 0
	collision_mask = 0
	_disable_hitbox()
	died.emit(self)
	_start_action_animation(&"die", _get_full_animation_time())
	get_tree().create_timer(_get_full_animation_time()).timeout.connect(queue_free)


func _update_spacing(delta: float) -> void:
	var offset: Vector2 = target.global_position - global_position
	var distance: float = offset.length()

	if distance < ideal_distance - distance_tolerance:
		velocity = -offset.normalized() * move_speed
		move_and_slide()
	elif distance > ideal_distance + distance_tolerance:
		move_toward_position(target.global_position, move_speed, delta)
	else:
		stop_moving()


func _start_aim() -> void:
	if not try_claim_attack_token():
		return

	is_aiming = true
	attack_elapsed = 0.0
	projectile_fired = false
	locked_attack_direction = facing_direction.rotated(deg_to_rad(randf_range(-AIM_RANDOM_SPREAD_DEGREES, AIM_RANDOM_SPREAD_DEGREES))).normalized()
	aim_line.visible = true
	aim_line.set_point_position(1, _get_local_aim_line_end())
	_start_action_animation(&"attack", _get_attack_animation_time())


func _update_aim(delta: float) -> void:
	stop_moving()

	attack_elapsed += delta
	if not projectile_fired and attack_elapsed >= _get_projectile_spawn_time():
		_fire_projectile()
		projectile_fired = true
		aim_line.visible = false

	if attack_elapsed >= _get_attack_animation_time():
		is_aiming = false
		aim_line.visible = false
		cooldown_remaining = fire_cooldown
		_reset_attack_hold_squash()
		release_attack_token()


func _fire_projectile() -> void:
	if is_stunned():
		return

	var direction: Vector2 = locked_attack_direction.normalized()
	var projectile := _spawn_projectile(_get_projectile_spawn_position(), direction)
	projectile.setup(direction, damage, projectile_speed, projectile_lifetime)


func _on_stun_applied() -> void:
	super()
	if is_aiming:
		release_attack_token()
	is_aiming = false
	attack_elapsed = 0.0
	projectile_fired = false
	action_animation_remaining = 0.0
	if aim_line != null:
		aim_line.visible = false
	_reset_attack_hold_squash()


func _handle_stunned_physics(delta: float) -> void:
	_on_stun_applied()
	_update_fireman_animation(delta)
	_update_attack_hold_squash(delta)


func _get_projectile_spawn_position() -> Vector2:
	var gun_point := get_node_or_null("GunPoint") as Marker2D
	if gun_point != null:
		var local_offset: Vector2 = gun_point.position
		if locked_attack_direction.x < 0.0:
			local_offset.x = -local_offset.x
		return global_position + local_offset

	return global_position


func _spawn_projectile(spawn_position: Vector2, direction: Vector2) -> FiremanAxeProjectile:
	var projectile := AXE_PROJECTILE_SCRIPT.new() as FiremanAxeProjectile
	projectile.global_position = spawn_position
	projectile.direction = direction
	projectile.collision_mask = 0
	projectile.set_collision_mask_value(1, true)
	projectile.set_collision_mask_value(7, true)
	get_tree().current_scene.add_child(projectile)
	return projectile


func _disable_hitbox() -> void:
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		return

	hitbox.set_deferred("monitorable", false)
	hitbox.set_deferred("collision_layer", 0)
	hitbox.set_deferred("collision_mask", 0)


func _get_local_aim_line_end() -> Vector2:
	return locked_attack_direction.rotated(-global_rotation) * aim_line_length


func _ensure_ranged_nodes() -> void:
	aim_line = get_node_or_null("AimLine") as Line2D
	if aim_line == null:
		aim_line = Line2D.new()
		aim_line.name = "AimLine"
		add_child(aim_line)

	aim_line.width = 3.0
	aim_line.default_color = Color(1.0, 0.35, 0.08, 0.82)
	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(Vector2(aim_line_length, 0.0))
	aim_line.visible = false


func _face_target(world_position: Vector2) -> void:
	var offset: Vector2 = world_position - global_position
	if offset.length_squared() <= 0.001:
		return

	facing_direction = offset.normalized()
	rotation = facing_direction.angle()
	if sprite != null:
		sprite.rotation = -rotation


func _update_fireman_animation(delta: float) -> void:
	if action_animation_remaining > 0.0:
		action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
		if sprite != null:
			sprite.rotation = -rotation
		return

	var wanted_animation: StringName = &"idle"
	if velocity.length_squared() > 16.0:
		wanted_animation = &"run"

	_play_fireman_animation(wanted_animation)


func _start_action_animation(animation_name: StringName, duration: float) -> void:
	action_animation_remaining = duration
	_play_fireman_animation(animation_name, true)


func _play_fireman_animation(animation_name: StringName, force_restart: bool = false) -> void:
	var direction_row: int = _get_direction_row(facing_direction)
	var tree_animation_name: StringName = StringName("%s_%d" % [String(animation_name), direction_row])
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


func _update_attack_hold_squash(delta: float) -> void:
	if attack_hold_squash_material == null:
		return

	var target_scale := Vector2.ONE
	var hold_time := maxf(attack_hold_time, 0.0)
	if is_aiming and hold_time > 0.0:
		var hold_start := float(ATTACK_HOLD_FRAME) / animation_fps
		var hold_end := hold_start + hold_time
		if attack_elapsed >= hold_start and attack_elapsed <= hold_end:
			var hold_progress := clampf((attack_elapsed - hold_start) / hold_time, 0.0, 1.0)
			target_scale = Vector2.ONE.lerp(attack_hold_squash_scale, smoothstep(0.0, 1.0, hold_progress))

	var blend := 1.0 - exp(-attack_hold_squash_return_speed * delta)
	current_attack_hold_squash = current_attack_hold_squash.lerp(target_scale, blend)
	_set_attack_hold_squash(current_attack_hold_squash)


func _reset_attack_hold_squash() -> void:
	current_attack_hold_squash = Vector2.ONE
	_set_attack_hold_squash(current_attack_hold_squash)


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
	_ensure_attack_hold_squash_material()

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


func _ensure_attack_hold_squash_material() -> void:
	var shader := Shader.new()
	shader.code = ATTACK_HOLD_SQUASH_SHADER_CODE
	attack_hold_squash_material = ShaderMaterial.new()
	attack_hold_squash_material.shader = shader
	sprite.material = attack_hold_squash_material
	_set_attack_hold_squash(Vector2.ONE)


func _set_attack_hold_squash(squash_scale: Vector2) -> void:
	if attack_hold_squash_material != null:
		attack_hold_squash_material.set_shader_parameter("squash_scale", squash_scale)


func _build_animation_library() -> void:
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")

	var library := AnimationLibrary.new()
	var animation_bases: Array[StringName] = [
		&"idle",
		&"run",
		&"attack",
		&"take_damage",
		&"die",
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
		&"take_damage",
		&"die",
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
	animation.length = _get_animation_time(animation_base)
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

	for frame in range(FRAMES_PER_DIRECTION):
		var region := Rect2(
			Vector2(frame * FRAME_SIZE.x, row * FRAME_SIZE.y),
			Vector2(FRAME_SIZE)
		)
		animation.track_insert_key(region_track, _get_frame_start_time(animation_base, frame), region)

	return animation


func _get_animation_texture(animation_name: StringName) -> Texture2D:
	match animation_name:
		&"attack":
			return ATTACK_TEXTURE
		&"take_damage":
			return TAKE_DAMAGE_TEXTURE
		&"die":
			return DIE_TEXTURE
		&"run":
			return RUN_TEXTURE
		_:
			return IDLE_TEXTURE


func _get_animation_loop_mode(animation_name: StringName) -> Animation.LoopMode:
	if animation_name == &"idle" or animation_name == &"run":
		return Animation.LOOP_LINEAR

	return Animation.LOOP_NONE


func _get_full_animation_time() -> float:
	return float(FRAMES_PER_DIRECTION) / animation_fps


func _get_animation_time(animation_name: StringName) -> float:
	if animation_name == &"attack":
		return _get_attack_animation_time()

	return _get_full_animation_time()


func _get_attack_animation_time() -> float:
	return _get_full_animation_time() + maxf(attack_hold_time, 0.0)


func _get_frame_start_time(animation_name: StringName, frame: int) -> float:
	var time := float(frame) / animation_fps
	if animation_name == &"attack" and frame > ATTACK_HOLD_FRAME:
		time += maxf(attack_hold_time, 0.0)

	return time


func _get_projectile_spawn_time() -> float:
	return _get_frame_start_time(&"attack", PROJECTILE_SPAWN_FRAME)


func _get_direction_row(direction: Vector2) -> int:
	if direction.length_squared() <= 0.001:
		return 0

	var angle: float = fposmod(direction.angle(), TAU)
	return int(round(angle / (PI * 0.25))) % DIRECTION_COUNT
