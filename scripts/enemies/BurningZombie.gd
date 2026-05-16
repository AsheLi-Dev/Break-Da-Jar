extends EnemyBase
class_name BurningZombie

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8

const IDLE_TEXTURE: Texture2D = preload("res://assets/zombies/Burning Zombie/Idle.png")
const RUN_TEXTURE: Texture2D = preload("res://assets/zombies/Burning Zombie/Run.png")
const TAKE_DAMAGE_TEXTURE: Texture2D = preload("res://assets/zombies/Burning Zombie/TakeDamage.png")
const DIE_TEXTURE: Texture2D = preload("res://assets/zombies/Burning Zombie/Die.png")
const FIRE_TEXTURE: Texture2D = preload("res://assets/vfx/Flickering Fire.png")
const FIRE_FRAME_SIZE := Vector2i(64, 64)

@export var contact_damage: float = 4.0
@export var contact_damage_interval: float = 0.45
@export_range(8.0, 96.0, 1.0, "or_greater") var contact_radius: float = 35.0
@export var animation_fps: float = 15.0
@export var take_damage_animation_time: float = 0.16
@export var fire_animation_fps: float = 18.0

var contact_damage_remaining: float = 0.0
var facing_direction: Vector2 = Vector2.RIGHT
var action_animation_remaining: float = 0.0
var current_animation_name: StringName = &""
var flame_time: float = 0.0
var fire_frame_elapsed: float = 0.0

var sprite: Sprite2D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state: AnimationNodeStateMachinePlayback
var contact_damage_shape: CollisionShape2D
var flame_sprite: Sprite2D


func _ready() -> void:
	super()
	_ensure_burning_nodes()
	_ensure_animation_nodes()
	_play_burning_animation(&"idle", true)


func _process(delta: float) -> void:
	super(delta)
	if is_dead:
		return

	_update_flame_visuals(delta)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_stunned():
		_handle_stunned_physics(delta)
		return

	if _update_knockback(delta):
		_update_burning_animation(delta)
		return

	_find_target()
	contact_damage_remaining = maxf(0.0, contact_damage_remaining - delta)

	if not has_valid_target():
		stop_moving()
		_update_burning_animation(delta)
		return

	_face_target(target.global_position)
	move_toward_position(target.global_position, move_speed, delta)
	_try_contact_damage()
	_update_burning_animation(delta)


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

	is_dead = true
	_notify_player_kill_once()
	_play_death_sfx()
	_hide_hp_bar()
	_disable_hitbox()
	if flame_sprite != null:
		flame_sprite.visible = false
	collision_layer = 0
	collision_mask = 0
	died.emit(self)
	_start_action_animation(&"die", _get_animation_time(&"die"))
	get_tree().create_timer(_get_animation_time(&"die")).timeout.connect(queue_free)


func _try_contact_damage() -> void:
	if is_stunned():
		return
	if contact_damage_remaining > 0.0 or target == null:
		return
	if not _is_target_inside_contact_damage_shape():
		return
	if target.has_method("take_damage"):
		target.call("take_damage", contact_damage)
		contact_damage_remaining = contact_damage_interval


func _handle_stunned_physics(delta: float) -> void:
	_on_stun_applied()
	action_animation_remaining = 0.0
	_update_burning_animation(delta)


func _face_target(world_position: Vector2) -> void:
	var offset: Vector2 = world_position - global_position
	if offset.length_squared() <= 0.001:
		return

	facing_direction = offset.normalized()
	rotation = facing_direction.angle()
	if sprite != null:
		sprite.rotation = -rotation
	if flame_sprite != null:
		flame_sprite.rotation = -rotation


func _update_burning_animation(delta: float) -> void:
	if action_animation_remaining > 0.0:
		action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
		if sprite != null:
			sprite.rotation = -rotation
		if flame_sprite != null:
			flame_sprite.rotation = -rotation
		return

	var wanted_animation: StringName = &"idle"
	if velocity.length_squared() > 16.0:
		wanted_animation = &"run"

	_play_burning_animation(wanted_animation)


func _start_action_animation(animation_name: StringName, duration: float) -> void:
	action_animation_remaining = duration
	_play_burning_animation(animation_name, true)


func _play_burning_animation(animation_name: StringName, force_restart: bool = false) -> void:
	var direction_row: int = _get_direction_row(facing_direction)
	var tree_animation_name: StringName = StringName("%s_%d" % [String(animation_name), direction_row])
	if current_animation_name == tree_animation_name and not force_restart:
		return

	current_animation_name = tree_animation_name
	if sprite != null:
		sprite.rotation = -rotation
	if flame_sprite != null:
		flame_sprite.rotation = -rotation
	if animation_state != null:
		if force_restart:
			animation_state.start(String(tree_animation_name), true)
		else:
			animation_state.travel(String(tree_animation_name))
	else:
		animation_player.play(String(tree_animation_name))


func _ensure_burning_nodes() -> void:
	_ensure_contact_damage_area()

	flame_sprite = get_node_or_null("FlameSprite") as Sprite2D
	if flame_sprite == null:
		flame_sprite = Sprite2D.new()
		flame_sprite.name = "FlameSprite"
		add_child(flame_sprite)
	flame_sprite.texture = FIRE_TEXTURE
	flame_sprite.centered = true
	flame_sprite.region_enabled = false
	flame_sprite.hframes = maxi(int(FIRE_TEXTURE.get_width() / FIRE_FRAME_SIZE.x), 1)
	flame_sprite.vframes = maxi(int(FIRE_TEXTURE.get_height() / FIRE_FRAME_SIZE.y), 1)
	flame_sprite.frame = 0
	flame_sprite.position = Vector2(0.0, -22.0)
	flame_sprite.scale = Vector2.ONE * 1.25
	flame_sprite.modulate = Color(1.0, 0.82, 0.58, 0.88)
	flame_sprite.z_index = 5


func _ensure_contact_damage_area() -> void:
	var area := get_node_or_null("ContactDamageArea") as Area2D
	if area == null:
		area = Area2D.new()
		area.name = "ContactDamageArea"
		add_child(area)
	area.monitoring = false
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 0

	contact_damage_shape = area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if contact_damage_shape == null:
		contact_damage_shape = CollisionShape2D.new()
		contact_damage_shape.name = "CollisionShape2D"
		area.add_child(contact_damage_shape)
	if contact_damage_shape.shape == null:
		var circle := CircleShape2D.new()
		circle.radius = contact_radius
		contact_damage_shape.shape = circle


func _is_target_inside_contact_damage_shape() -> bool:
	if target == null:
		return false
	if contact_damage_shape != null and contact_damage_shape.shape is CircleShape2D:
		var circle := contact_damage_shape.shape as CircleShape2D
		var local_target_position := contact_damage_shape.global_transform.affine_inverse() * target.global_position
		return local_target_position.length() <= circle.radius

	return global_position.distance_to(target.global_position) <= contact_radius


func _update_flame_visuals(delta: float) -> void:
	flame_time += delta
	if flame_sprite == null:
		return

	fire_frame_elapsed += delta
	var frame_time := 1.0 / maxf(fire_animation_fps, 0.001)
	while fire_frame_elapsed >= frame_time:
		fire_frame_elapsed -= frame_time
		flame_sprite.frame = (flame_sprite.frame + 1) % maxi(flame_sprite.hframes * flame_sprite.vframes, 1)

	var sway := sin(flame_time * 8.0) * 2.0
	var pulse := 0.5 + 0.5 * sin(flame_time * 10.0)
	flame_sprite.position = Vector2(sway, -22.0)
	flame_sprite.scale = Vector2.ONE * lerpf(1.16, 1.32, pulse)


func _ensure_animation_nodes() -> void:
	var debug_body := get_node_or_null("DebugBody") as CanvasItem
	if debug_body != null:
		debug_body.visible = false
	var debug_forward := get_node_or_null("DebugForward") as CanvasItem
	if debug_forward != null:
		debug_forward.visible = false

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
	sprite.modulate = Color(1.3, 0.82, 0.56, 1.0)
	sprite.rotation = -rotation

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
	for animation_base in [&"idle", &"run", &"take_damage", &"die"]:
		for row in range(DIRECTION_COUNT):
			var animation_name: String = "%s_%d" % [String(animation_base), row]
			library.add_animation(animation_name, _create_direction_animation(animation_base, row))

	animation_player.add_animation_library("", library)


func _build_animation_state_machine() -> void:
	var state_machine := AnimationNodeStateMachine.new()
	for animation_base in [&"idle", &"run", &"take_damage", &"die"]:
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
		animation.track_insert_key(region_track, float(frame) / animation_fps, region)

	return animation


func _get_animation_texture(animation_name: StringName) -> Texture2D:
	match animation_name:
		&"run":
			return RUN_TEXTURE
		&"take_damage":
			return TAKE_DAMAGE_TEXTURE
		&"die":
			return DIE_TEXTURE
		_:
			return IDLE_TEXTURE


func _get_animation_loop_mode(animation_name: StringName) -> Animation.LoopMode:
	if animation_name == &"idle" or animation_name == &"run":
		return Animation.LOOP_LINEAR

	return Animation.LOOP_NONE


func _get_animation_time(_animation_name: StringName) -> float:
	return float(FRAMES_PER_DIRECTION) / animation_fps


func _get_direction_row(direction: Vector2) -> int:
	if direction.length_squared() <= 0.001:
		return 0

	var angle: float = fposmod(direction.angle(), TAU)
	return int(round(angle / (PI * 0.25))) % DIRECTION_COUNT


func _disable_hitbox() -> void:
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		return

	hitbox.set_deferred("monitorable", false)
	hitbox.set_deferred("collision_layer", 0)
	hitbox.set_deferred("collision_mask", 0)
