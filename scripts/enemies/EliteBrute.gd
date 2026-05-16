extends EnemyBase
class_name EliteBrute

const FRAME_SIZE := Vector2i(192, 192)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const PROJECTILE_SPAWN_FRAME := 5
const MELEE_ACTIVE_START_FRAME := 7
const MELEE_ACTIVE_END_FRAME := 9
const SHOUT_ACTIVE_START_FRAME := 5
const SHOUT_ACTIVE_END_FRAME := 9
const ATTACK_HOLD_SQUASH_SHADER_CODE := "shader_type canvas_item;\nuniform vec2 squash_scale = vec2(1.0, 1.0);\nvoid vertex() { VERTEX *= squash_scale; }\n"

const RANGED_ATTACK_TEXTURE: Texture2D = preload("res://assets/zombies/elite brute zombie/Attack2.png")
const MELEE_ATTACK_TEXTURE: Texture2D = preload("res://assets/zombies/elite brute zombie/Attack3.png")
const SHOUT_TEXTURE: Texture2D = preload("res://assets/zombies/elite brute zombie/Taunt.png")
const DIE_TEXTURE: Texture2D = preload("res://assets/zombies/elite brute zombie/Die.png")
const IDLE_TEXTURE: Texture2D = preload("res://assets/zombies/elite brute zombie/Idle.png")
const RUN_TEXTURE: Texture2D = preload("res://assets/zombies/elite brute zombie/Run.png")

enum State {
	IDLE,
	CHASE,
	MELEE_ATTACK,
	RANGED_ATTACK,
	SHOUT_ATTACK,
	RECOVERY,
}

# Close range uses Attack3. Mid/far range uses Attack2 projectile burst.
@export var melee_prefer_distance: float = 145.0
@export var ranged_prefer_distance: float = 260.0
@export var melee_radius: float = 105.0
@export var melee_damage: float = 14.0
@export var shout_range: float = 275.0
@export var shout_angle_degrees: float = 105.0
@export var shout_damage: float = 5.0
@export var shout_slow_multiplier: float = 0.7
@export var shout_slow_duration: float = 2.0
@export var shout_air_wave_lifetime: float = 0.32
@export var shout_air_wave_color: Color = Color(0.78, 0.96, 1.0, 0.18)
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 550.0
@export var projectile_lifetime: float = 2.0
@export var projectile_damage: float = 10.0
@export var projectile_spread_degrees: float = 15.0
@export var recovery_time: float = 0.35
@export var animation_fps: float = 15.0
@export var melee_attack_hold_frame: int = 2
@export var ranged_attack_hold_frame: int = 2
@export var shout_attack_hold_frame: int = 3
@export var attack_hold_time: float = 0.18
@export var attack_hold_squash_scale: Vector2 = Vector2(1.04, 0.95)
@export var attack_hold_squash_return_speed: float = 18.0

var state: int = State.IDLE
var state_time: float = 0.0
var attack_elapsed: float = 0.0
var cooldown_remaining: float = 0.0
var projectile_fired: bool = false
var shout_air_wave_spawned: bool = false
var hit_targets: Array[Node] = []
var facing_direction: Vector2 = Vector2.RIGHT
var locked_attack_direction: Vector2 = Vector2.RIGHT
var current_animation_name: StringName = &""

var melee_warning: Polygon2D
var melee_hitbox: Area2D
var melee_collision: CollisionShape2D
var shout_warning: Polygon2D
var shout_hitbox: Area2D
var shout_collision: CollisionPolygon2D
var ranged_warning: Line2D
var sprite: Sprite2D
var attack_hold_squash_material: ShaderMaterial
var current_attack_hold_squash: Vector2 = Vector2.ONE
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state: AnimationNodeStateMachinePlayback


func _ready() -> void:
	is_elite = true
	hp_bar_offset_y = -104.0
	super()
	_ensure_elite_nodes()
	_ensure_animation_nodes()
	_play_brute_animation(&"idle", true)


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

	match state:
		State.IDLE:
			_enter_state(State.CHASE)
		State.CHASE:
			_update_chase(delta)
		State.MELEE_ATTACK:
			_update_melee_attack(delta)
		State.RANGED_ATTACK:
			_update_ranged_attack(delta)
		State.SHOUT_ATTACK:
			_update_shout_attack(delta)
		State.RECOVERY:
			_update_recovery(delta)

	_update_attack_hold_squash(delta)


func die() -> void:
	if is_dead:
		return

	release_attack_token()
	is_dead = true
	_notify_player_kill_once()
	_play_death_sfx()
	_hide_hp_bar()
	melee_warning.visible = false
	shout_warning.visible = false
	ranged_warning.visible = false
	melee_hitbox.monitoring = false
	shout_hitbox.monitoring = false
	_reset_attack_hold_squash()
	collision_layer = 0
	collision_mask = 0
	_disable_hitbox()
	died.emit(self)
	_play_brute_animation(&"die", true)
	get_tree().create_timer(_get_full_animation_time()).timeout.connect(queue_free)


func _update_chase(delta: float) -> void:
	if not has_valid_target():
		stop_moving()
		_play_brute_animation(&"idle")
		return

	_face_target(target.global_position)
	var distance: float = global_position.distance_to(target.global_position)

	if cooldown_remaining <= 0.0:
		if distance <= melee_prefer_distance:
			_start_melee_attack()
			return
		if distance <= shout_range:
			_start_shout_attack()
			return
		if distance >= ranged_prefer_distance:
			_start_ranged_attack()
			return

	move_toward_position(target.global_position, move_speed, delta)
	_play_brute_animation(&"run")


func _start_melee_attack() -> void:
	if not try_claim_attack_token():
		return

	_enter_state(State.MELEE_ATTACK)
	attack_elapsed = 0.0
	hit_targets.clear()
	locked_attack_direction = facing_direction
	melee_warning.visible = true
	melee_hitbox.monitoring = false
	stop_moving()
	_play_brute_animation(&"melee_attack", true)


func _update_melee_attack(delta: float) -> void:
	stop_moving()

	attack_elapsed += delta
	var active_start_time: float = _get_melee_active_start_time()
	var active_end_time: float = _get_melee_active_end_time()

	if attack_elapsed >= active_start_time and attack_elapsed < active_end_time:
		if not melee_hitbox.monitoring:
			melee_warning.visible = false
			melee_hitbox.monitoring = true
			_damage_overlapping_players(melee_hitbox, melee_damage)
	elif melee_hitbox.monitoring:
		melee_hitbox.monitoring = false

	if attack_elapsed >= _get_attack_animation_time(&"melee_attack"):
		melee_warning.visible = false
		melee_hitbox.monitoring = false
		_start_recovery()


func _start_ranged_attack() -> void:
	if not try_claim_attack_token():
		return

	_enter_state(State.RANGED_ATTACK)
	attack_elapsed = 0.0
	projectile_fired = false
	locked_attack_direction = facing_direction
	ranged_warning.visible = true
	ranged_warning.set_point_position(1, _get_local_ranged_warning_end())
	stop_moving()
	_play_brute_animation(&"ranged_attack", true)


func _update_ranged_attack(delta: float) -> void:
	stop_moving()

	attack_elapsed += delta
	if not projectile_fired and attack_elapsed >= _get_projectile_spawn_time():
		projectile_fired = true
		ranged_warning.visible = false
		_fire_spread_projectiles()

	if attack_elapsed >= _get_attack_animation_time(&"ranged_attack"):
		ranged_warning.visible = false
		_start_recovery()


func _start_shout_attack() -> void:
	if not try_claim_attack_token():
		return

	_enter_state(State.SHOUT_ATTACK)
	attack_elapsed = 0.0
	hit_targets.clear()
	shout_air_wave_spawned = false
	locked_attack_direction = facing_direction
	shout_warning.visible = true
	shout_hitbox.monitoring = false
	stop_moving()
	_play_brute_animation(&"shout_attack", true)


func _update_shout_attack(delta: float) -> void:
	stop_moving()

	attack_elapsed += delta
	var active_start_time: float = _get_shout_active_start_time()
	var active_end_time: float = _get_shout_active_end_time()

	if attack_elapsed >= active_start_time and attack_elapsed < active_end_time:
		if not shout_hitbox.monitoring:
			shout_warning.visible = false
			shout_hitbox.monitoring = true
			if not shout_air_wave_spawned:
				shout_air_wave_spawned = true
				_spawn_shout_air_wave_vfx()
			_damage_overlapping_players(shout_hitbox, shout_damage)
	elif shout_hitbox.monitoring:
		shout_hitbox.monitoring = false

	if attack_elapsed >= _get_attack_animation_time(&"shout_attack"):
		shout_warning.visible = false
		shout_hitbox.monitoring = false
		_start_recovery()


func _start_recovery() -> void:
	release_attack_token()
	_reset_attack_hold_squash()
	_enter_state(State.RECOVERY)
	state_time = recovery_time
	cooldown_remaining = attack_cooldown
	stop_moving()


func _update_recovery(delta: float) -> void:
	stop_moving()
	state_time -= delta
	if state_time <= 0.0:
		_enter_state(State.CHASE)


func _update_attack_hold_squash(delta: float) -> void:
	if attack_hold_squash_material == null:
		return

	var target_scale := Vector2.ONE
	var attack_animation := _get_current_attack_animation_name()
	if attack_animation != &"":
		var hold_time := _get_attack_hold_time(attack_animation)
		if hold_time > 0.0:
			var hold_start := float(_get_attack_hold_frame(attack_animation)) / animation_fps
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


func _get_current_attack_animation_name() -> StringName:
	match state:
		State.MELEE_ATTACK:
			return &"melee_attack"
		State.RANGED_ATTACK:
			return &"ranged_attack"
		State.SHOUT_ATTACK:
			return &"shout_attack"

	return &""


func _enter_state(next_state: int) -> void:
	state = next_state
	melee_warning.visible = false
	shout_warning.visible = false
	ranged_warning.visible = false
	melee_hitbox.monitoring = false
	shout_hitbox.monitoring = false


func _on_melee_body_entered(body: Node) -> void:
	if state != State.MELEE_ATTACK or not melee_hitbox.monitoring:
		return

	_try_damage_player(body, melee_damage)


func _on_shout_body_entered(body: Node) -> void:
	if state != State.SHOUT_ATTACK or not shout_hitbox.monitoring:
		return

	_try_damage_player(body, shout_damage)


func _damage_overlapping_players(area: Area2D, attack_damage: float) -> void:
	for body in area.get_overlapping_bodies():
		_try_damage_player(body, attack_damage)


func _try_damage_player(body: Node, attack_damage: float) -> void:
	if is_stunned():
		return
	if hit_targets.has(body):
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		hit_targets.append(body)
		body.call("take_damage", attack_damage)
		if state == State.SHOUT_ATTACK and body.has_method("apply_slow"):
			body.call("apply_slow", shout_slow_multiplier, shout_slow_duration)


func _on_stun_applied() -> void:
	super()
	match state:
		State.MELEE_ATTACK, State.RANGED_ATTACK, State.SHOUT_ATTACK:
			release_attack_token()
	state = State.CHASE
	state_time = 0.0
	attack_elapsed = 0.0
	projectile_fired = false
	shout_air_wave_spawned = false
	if melee_warning != null:
		melee_warning.visible = false
	if shout_warning != null:
		shout_warning.visible = false
	if ranged_warning != null:
		ranged_warning.visible = false
	if melee_hitbox != null:
		melee_hitbox.monitoring = false
	if shout_hitbox != null:
		shout_hitbox.monitoring = false
	_reset_attack_hold_squash()


func _handle_stunned_physics(delta: float) -> void:
	_on_stun_applied()
	_play_brute_animation(&"idle")
	_update_attack_hold_squash(delta)


func _disable_hitbox() -> void:
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox == null:
		return

	hitbox.set_deferred("monitorable", false)
	hitbox.set_deferred("collision_layer", 0)
	hitbox.set_deferred("collision_mask", 0)


func _fire_spread_projectiles() -> void:
	if is_stunned():
		return

	var base_angle: float = locked_attack_direction.angle()
	for angle_offset_degrees in [-projectile_spread_degrees, 0.0, projectile_spread_degrees]:
		var angle: float = base_angle + deg_to_rad(float(angle_offset_degrees))
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var projectile: Projectile = _spawn_projectile(_get_projectile_spawn_position(), direction)
		if projectile.has_method("use_bone_spike_visual"):
			projectile.use_bone_spike_visual()
		projectile.setup(direction, projectile_damage, projectile_speed, projectile_lifetime)


func _get_projectile_spawn_position() -> Vector2:
	var gun_point := get_node_or_null("GunPoint") as Marker2D
	if gun_point != null:
		var local_offset: Vector2 = gun_point.position
		if locked_attack_direction.x < 0.0:
			local_offset.x = -local_offset.x
		return global_position + local_offset

	return global_position


func _spawn_projectile(spawn_position: Vector2, direction: Vector2) -> Projectile:
	var projectile: Projectile
	if projectile_scene != null:
		projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		projectile = Projectile.new()

	projectile.collision_mask = 0
	projectile.set_collision_mask_value(1, true)
	projectile.set_collision_mask_value(7, true)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_position
	projectile.direction = direction
	return projectile


func _get_local_ranged_warning_end() -> Vector2:
	return locked_attack_direction.rotated(-global_rotation) * ranged_prefer_distance


func _spawn_shout_air_wave_vfx() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var effect := Node2D.new()
	effect.name = "EliteBruteShoutAirWaveVFX"
	effect.global_position = global_position
	effect.global_rotation = locked_attack_direction.angle()
	effect.z_index = 125
	get_tree().current_scene.add_child(effect)

	var angle: float = deg_to_rad(shout_angle_degrees)
	var base_radii: Array[float] = [
		shout_range * 0.34,
		shout_range * 0.54,
		shout_range * 0.75,
		shout_range * 0.92,
	]
	for index in range(base_radii.size()):
		var line := Line2D.new()
		line.name = "AirRipple%d" % index
		line.width = lerpf(14.0, 5.0, float(index) / float(maxi(base_radii.size() - 1, 1)))
		line.default_color = Color(
			shout_air_wave_color.r,
			shout_air_wave_color.g,
			shout_air_wave_color.b,
			shout_air_wave_color.a * lerpf(1.0, 0.42, float(index) / float(maxi(base_radii.size() - 1, 1)))
		)
		line.antialiased = true
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		for point_index in range(13):
			var t: float = float(point_index) / 12.0
			var point_angle: float = lerpf(-angle * 0.5, angle * 0.5, t)
			var ripple: float = sin(t * TAU * 2.0 + float(index) * 1.7) * 5.0
			var radius: float = base_radii[index] + ripple + randf_range(-4.0, 4.0)
			line.add_point(Vector2(cos(point_angle), sin(point_angle)) * radius)
		effect.add_child(line)

	effect.scale = Vector2.ONE * 0.58
	var tween := effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2.ONE * 1.08, shout_air_wave_lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "modulate:a", 0.0, shout_air_wave_lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(Callable(effect, "queue_free"))


func _ensure_elite_nodes() -> void:
	melee_warning = get_node_or_null("MeleeWarning") as Polygon2D
	if melee_warning == null:
		melee_warning = Polygon2D.new()
		melee_warning.name = "MeleeWarning"
		add_child(melee_warning)
	melee_warning.color = Color(1.0, 0.15, 0.0, 0.22)
	melee_warning.polygon = _circle_polygon(melee_radius, 32)
	melee_warning.visible = false

	melee_hitbox = _get_or_create_area("MeleeHitbox", melee_radius)
	melee_collision = melee_hitbox.get_node("CollisionShape2D") as CollisionShape2D
	if not melee_hitbox.body_entered.is_connected(_on_melee_body_entered):
		melee_hitbox.body_entered.connect(_on_melee_body_entered)

	var shout_polygon: PackedVector2Array = _make_cone_polygon(shout_range, deg_to_rad(shout_angle_degrees), 18)
	shout_warning = get_node_or_null("ShoutWarning") as Polygon2D
	if shout_warning == null:
		shout_warning = Polygon2D.new()
		shout_warning.name = "ShoutWarning"
		add_child(shout_warning)
	shout_warning.color = Color(0.45, 0.9, 1.0, 0.22)
	shout_warning.polygon = shout_polygon
	shout_warning.visible = false

	shout_hitbox = get_node_or_null("ShoutHitbox") as Area2D
	if shout_hitbox == null:
		shout_hitbox = Area2D.new()
		shout_hitbox.name = "ShoutHitbox"
		add_child(shout_hitbox)
	shout_hitbox.monitoring = false
	shout_hitbox.monitorable = false
	shout_hitbox.collision_mask = 0
	shout_hitbox.set_collision_mask_value(7, true)
	if not shout_hitbox.body_entered.is_connected(_on_shout_body_entered):
		shout_hitbox.body_entered.connect(_on_shout_body_entered)

	shout_collision = shout_hitbox.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if shout_collision == null:
		shout_collision = CollisionPolygon2D.new()
		shout_collision.name = "CollisionPolygon2D"
		shout_hitbox.add_child(shout_collision)
	shout_collision.polygon = shout_polygon

	ranged_warning = get_node_or_null("RangedWarning") as Line2D
	if ranged_warning == null:
		ranged_warning = Line2D.new()
		ranged_warning.name = "RangedWarning"
		add_child(ranged_warning)
	ranged_warning.width = 8.0
	ranged_warning.default_color = Color(0.5, 1.0, 0.1, 0.55)
	ranged_warning.clear_points()
	ranged_warning.add_point(Vector2.ZERO)
	ranged_warning.add_point(Vector2(ranged_prefer_distance, 0.0))
	ranged_warning.visible = false


func _get_or_create_area(area_name: StringName, radius: float) -> Area2D:
	var area := get_node_or_null(String(area_name)) as Area2D
	if area == null:
		area = Area2D.new()
		area.name = area_name
		add_child(area)

	area.monitoring = false
	area.monitorable = false
	area.collision_mask = 0
	area.set_collision_mask_value(7, true)

	var collision := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		area.add_child(collision)

	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	return area


func _face_target(world_position: Vector2) -> void:
	var offset: Vector2 = world_position - global_position
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
		&"melee_attack",
		&"ranged_attack",
		&"shout_attack",
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
		&"melee_attack",
		&"ranged_attack",
		&"shout_attack",
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
	animation.length = _get_attack_animation_time(animation_base)
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
		&"melee_attack":
			return MELEE_ATTACK_TEXTURE
		&"ranged_attack":
			return RANGED_ATTACK_TEXTURE
		&"shout_attack":
			return SHOUT_TEXTURE
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


func _play_brute_animation(animation_name: StringName, force_restart: bool = false) -> void:
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


func _get_full_animation_time() -> float:
	return float(FRAMES_PER_DIRECTION) / animation_fps


func _get_attack_animation_time(animation_name: StringName) -> float:
	return _get_full_animation_time() + _get_attack_hold_time(animation_name)


func _get_attack_hold_time(animation_name: StringName) -> float:
	if animation_name == &"melee_attack" or animation_name == &"ranged_attack" or animation_name == &"shout_attack":
		return maxf(attack_hold_time, 0.0)

	return 0.0


func _get_attack_hold_frame(animation_name: StringName) -> int:
	match animation_name:
		&"melee_attack":
			return melee_attack_hold_frame
		&"ranged_attack":
			return ranged_attack_hold_frame
		&"shout_attack":
			return shout_attack_hold_frame

	return -1


func _get_frame_start_time(animation_name: StringName, frame: int) -> float:
	var time := float(frame) / animation_fps
	if frame > _get_attack_hold_frame(animation_name):
		time += _get_attack_hold_time(animation_name)

	return time


func _get_projectile_spawn_time() -> float:
	return _get_frame_start_time(&"ranged_attack", PROJECTILE_SPAWN_FRAME)


func _get_melee_active_start_time() -> float:
	return _get_frame_start_time(&"melee_attack", MELEE_ACTIVE_START_FRAME)


func _get_melee_active_end_time() -> float:
	return _get_frame_start_time(&"melee_attack", MELEE_ACTIVE_END_FRAME + 1)


func _get_shout_active_start_time() -> float:
	return _get_frame_start_time(&"shout_attack", SHOUT_ACTIVE_START_FRAME)


func _get_shout_active_end_time() -> float:
	return _get_frame_start_time(&"shout_attack", SHOUT_ACTIVE_END_FRAME + 1)


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
