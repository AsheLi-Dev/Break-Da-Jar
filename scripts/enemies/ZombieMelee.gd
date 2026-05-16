extends EnemyBase
class_name ZombieMelee

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const ATTACK_ACTIVE_START_FRAME := 7
const ATTACK_ACTIVE_END_FRAME := 9
const ATTACK_HOLD_SQUASH_SHADER_CODE := "shader_type canvas_item;\nuniform vec2 squash_scale = vec2(1.0, 1.0);\nvoid vertex() { VERTEX *= squash_scale; }\n"
const VISUAL_VARIANT_DIRS: Array[String] = [
	"res://assets/zombies/melee zombie 1",
	"res://assets/zombies/melee zombie 2",
	"res://assets/zombies/melee zombie 3",
	"res://assets/zombies/melee zombie 4",
	"res://assets/zombies/melee zombie 5",
	"res://assets/zombies/melee zombie 6",
]

# Melee attack tuning. Telegraph shows before the hitbox turns on.
@export var attack_range: float = 116.0
@export var cone_angle_degrees: float = 80.0
@export var cone_radius: float = 144.0
@export var warning_color: Color = Color(1.0, 0.25, 0.08, 0.28)
@export var animation_fps: float = 15.0
@export var attack_hold_frame: int = 5
@export var attack_hold_time: float = 0.18
@export var attack_hold_squash_scale: Vector2 = Vector2(1.025, 0.98)
@export var attack_hold_squash_return_speed: float = 18.0
@export var take_damage_animation_time: float = 0.2
@export var post_attack_fatigue_time: float = 0.45
@export var randomize_visual_variant: bool = true
@export_range(0, 5, 1) var visual_variant_index: int = 0

var cooldown_remaining: float = 0.0
var post_attack_fatigue_remaining: float = 0.0
var attack_phase: StringName = &"idle"
var attack_elapsed: float = 0.0
var hit_targets: Array[Node] = []
var facing_direction: Vector2 = Vector2.RIGHT
var action_animation: StringName = &""
var action_animation_remaining: float = 0.0
var current_animation_name: StringName = &""
var animation_textures: Dictionary = {}

var warning_cone: Polygon2D
var attack_area: Area2D
var attack_collision: CollisionPolygon2D
var sprite: Sprite2D
var attack_hold_squash_material: ShaderMaterial
var current_attack_hold_squash: Vector2 = Vector2.ONE
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state: AnimationNodeStateMachinePlayback


func _ready() -> void:
	super()
	_ensure_melee_nodes()
	_ensure_animation_nodes()
	_play_zombie_animation(&"idle", true)


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

	if post_attack_fatigue_remaining > 0.0:
		post_attack_fatigue_remaining = maxf(0.0, post_attack_fatigue_remaining - delta)
		stop_moving()
		_update_zombie_animation(delta)
		_update_attack_hold_squash(delta)
		return

	if attack_phase != &"idle":
		_update_attack(delta)
		_update_zombie_animation(delta)
		_update_attack_hold_squash(delta)
		return

	if not has_valid_target():
		stop_moving()
		_update_zombie_animation(delta)
		_update_attack_hold_squash(delta)
		return

	var distance: float = global_position.distance_to(target.global_position)
	_face_target_for_attack(target.global_position)

	if distance <= attack_range:
		stop_moving()
		if cooldown_remaining <= 0.0:
			_start_attack()
	else:
		move_toward_position(target.global_position, move_speed, delta)

	_update_zombie_animation(delta)
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
	attack_area.monitoring = false
	warning_cone.visible = false
	_reset_attack_hold_squash()
	collision_layer = 0
	collision_mask = 0
	_disable_hitbox()
	died.emit(self)
	_start_action_animation(&"die", _get_full_animation_time())
	get_tree().create_timer(_get_full_animation_time()).timeout.connect(queue_free)


func _start_attack() -> void:
	if not try_claim_attack_token():
		return

	attack_phase = &"startup"
	attack_elapsed = 0.0
	hit_targets.clear()
	# Warning is visible during windup; no damage happens yet.
	warning_cone.visible = true
	attack_area.monitoring = false
	_start_action_animation(&"attack", _get_attack_animation_time())


func _update_attack(delta: float) -> void:
	stop_moving()
	attack_elapsed += delta

	var active_start_time: float = _get_attack_active_start_time()
	var active_end_time: float = _get_attack_active_end_time()
	if attack_phase == &"startup" and attack_elapsed >= active_start_time:
		attack_phase = &"active"
		warning_cone.visible = false
		# Damage only comes from this Area2D while it is active.
		attack_area.monitoring = true
		_damage_overlapping_players()
	elif attack_phase == &"active" and attack_elapsed >= active_end_time:
		attack_area.monitoring = false
		attack_phase = &"recovery"

	if attack_elapsed >= _get_attack_animation_time():
		attack_area.monitoring = false
		warning_cone.visible = false
		attack_phase = &"idle"
		cooldown_remaining = attack_cooldown
		post_attack_fatigue_remaining = post_attack_fatigue_time
		_reset_attack_hold_squash()
		release_attack_token()


func _update_attack_hold_squash(delta: float) -> void:
	if attack_hold_squash_material == null:
		return

	var target_scale := Vector2.ONE
	var hold_time := maxf(attack_hold_time, 0.0)
	if attack_phase != &"idle" and hold_time > 0.0:
		var hold_start := float(attack_hold_frame) / animation_fps
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


func _on_attack_body_entered(body: Node) -> void:
	if attack_phase != &"active":
		return

	_try_damage_player(body)


func _damage_overlapping_players() -> void:
	for body in attack_area.get_overlapping_bodies():
		_try_damage_player(body)


func _try_damage_player(body: Node) -> void:
	if is_stunned():
		return
	if hit_targets.has(body):
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		hit_targets.append(body)
		body.call("take_damage", damage)


func _on_stun_applied() -> void:
	super()
	if attack_phase != &"idle":
		release_attack_token()
	attack_phase = &"idle"
	attack_elapsed = 0.0
	action_animation_remaining = 0.0
	post_attack_fatigue_remaining = 0.0
	if attack_area != null:
		attack_area.monitoring = false
	if warning_cone != null:
		warning_cone.visible = false
	_reset_attack_hold_squash()


func _handle_stunned_physics(delta: float) -> void:
	_on_stun_applied()
	_update_zombie_animation(delta)
	_update_attack_hold_squash(delta)


func _disable_hitbox() -> void:
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		return

	hitbox.set_deferred("monitorable", false)
	hitbox.set_deferred("collision_layer", 0)
	hitbox.set_deferred("collision_mask", 0)


func _ensure_melee_nodes() -> void:
	var cone_polygon: PackedVector2Array = _make_cone_polygon(cone_radius, deg_to_rad(cone_angle_degrees), 12)

	warning_cone = get_node_or_null("AttackWarning") as Polygon2D
	if warning_cone == null:
		warning_cone = Polygon2D.new()
		warning_cone.name = "AttackWarning"
		add_child(warning_cone)
	warning_cone.color = warning_color
	warning_cone.polygon = cone_polygon
	warning_cone.visible = false

	attack_area = get_node_or_null("AttackHitbox") as Area2D
	if attack_area == null:
		attack_area = Area2D.new()
		attack_area.name = "AttackHitbox"
		add_child(attack_area)
	attack_area.monitoring = false
	attack_area.monitorable = false
	attack_area.collision_mask = 0
	attack_area.set_collision_mask_value(7, true)
	if not attack_area.body_entered.is_connected(_on_attack_body_entered):
		attack_area.body_entered.connect(_on_attack_body_entered)

	attack_collision = attack_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if attack_collision == null:
		attack_collision = CollisionPolygon2D.new()
		attack_collision.name = "CollisionPolygon2D"
		attack_area.add_child(attack_collision)
	attack_collision.polygon = cone_polygon


func _face_target_for_attack(world_position: Vector2) -> void:
	var offset: Vector2 = world_position - global_position
	if offset.length_squared() <= 0.001:
		return

	facing_direction = offset.normalized()
	rotation = facing_direction.angle()
	if sprite != null:
		sprite.rotation = -rotation


func _update_zombie_animation(delta: float) -> void:
	if action_animation_remaining > 0.0:
		action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
		if sprite != null:
			sprite.rotation = -rotation
		return

	var wanted_animation: StringName = &"idle"
	if velocity.length_squared() > 16.0:
		wanted_animation = &"run"

	_play_zombie_animation(wanted_animation)


func _start_action_animation(animation_name: StringName, duration: float) -> void:
	action_animation = animation_name
	action_animation_remaining = duration
	_play_zombie_animation(animation_name, true)


func _play_zombie_animation(animation_name: StringName, force_restart: bool = false) -> void:
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
	_load_visual_variant_textures()
	sprite.texture = _get_animation_texture(&"idle")
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
	if animation_textures.has(animation_name):
		return animation_textures[animation_name] as Texture2D

	return animation_textures[&"idle"] as Texture2D


func _load_visual_variant_textures() -> void:
	var variant_index: int = clampi(visual_variant_index, 0, VISUAL_VARIANT_DIRS.size() - 1)
	if randomize_visual_variant:
		variant_index = randi_range(0, VISUAL_VARIANT_DIRS.size() - 1)

	var variant_dir: String = VISUAL_VARIANT_DIRS[variant_index]
	animation_textures = {
		&"idle": load("%s/Idle.png" % variant_dir),
		&"run": load("%s/Run.png" % variant_dir),
		&"attack": load("%s/Attack1.png" % variant_dir),
		&"take_damage": load("%s/TakeDamage.png" % variant_dir),
		&"die": load("%s/Die.png" % variant_dir),
	}


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
	if animation_name == &"attack" and frame > attack_hold_frame:
		time += maxf(attack_hold_time, 0.0)

	return time


func _get_attack_active_start_time() -> float:
	return _get_frame_start_time(&"attack", ATTACK_ACTIVE_START_FRAME)


func _get_attack_active_end_time() -> float:
	return _get_frame_start_time(&"attack", ATTACK_ACTIVE_END_FRAME + 1)


func _get_direction_row(direction: Vector2) -> int:
	if direction.length_squared() <= 0.001:
		return 0

	var angle: float = fposmod(direction.angle(), TAU)
	return int(round(angle / (PI * 0.25))) % DIRECTION_COUNT


func _make_cone_polygon(radius: float, angle: float, steps: int) -> PackedVector2Array:
	var polygon := PackedVector2Array([Vector2.ZERO])
	var start_angle: float = -angle * 0.5
	for index in range(steps + 1):
		var t: float = float(index) / float(steps)
		var current_angle: float = lerpf(start_angle, -start_angle, t)
		polygon.append(Vector2(cos(current_angle), sin(current_angle)) * radius)

	return polygon
