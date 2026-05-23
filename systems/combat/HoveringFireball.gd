extends Node2D
class_name HoveringFireball

const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")
const SPINNING_FIREBALL_TEXTURE: Texture2D = preload("res://assets/vfx/fire spell/Spinning Fireball.png")
const FRAME_SIZE := Vector2i(64, 64)
const IDLE_FRAME_COUNT := 8
const DISAPPEAR_FRAME_COUNT := 5

@export var lifetime: float = 2.0
@export var attack_speed_multiplier: float = 0.5
@export var target_range: float = 700.0
@export var animation_fps: float = 16.0
@export var visual_scale: float = 1.0
@export var jitter_radius: float = 4.0
@export var jitter_frequency: float = 18.0
@export var jitter_snap_interval: float = 0.07
@export var squash_amount: float = 0.035
@export var wobble_rotation: float = 0.035

var owner_player: Node
var age: float = 0.0
var attack_timer: float = 0.0
var is_disappearing: bool = false
var sprite: AnimatedSprite2D
var jitter_phase: float = 0.0
var jitter_snap_timer: float = 0.0
var jitter_target_offset: Vector2 = Vector2.ZERO
var jitter_current_offset: Vector2 = Vector2.ZERO


func setup(new_owner: Node, spawn_position: Vector2) -> void:
	owner_player = new_owner
	global_position = spawn_position


func _ready() -> void:
	add_to_group("wizard_hovering_fireball")
	jitter_phase = randf() * TAU
	jitter_snap_timer = randf_range(0.0, jitter_snap_interval)
	jitter_target_offset = _random_jitter_offset()
	_ensure_nodes()


func _exit_tree() -> void:
	owner_player = null


func _process(delta: float) -> void:
	_update_unstable_visual(delta)
	if is_disappearing:
		return

	age += delta
	if age >= lifetime:
		_start_disappear()
		return

	var attacks_per_second := _get_attacks_per_second()
	if attacks_per_second <= 0.0:
		return

	attack_timer -= delta
	while attack_timer <= 0.0:
		attack_timer += 1.0 / attacks_per_second
		_fire_at_nearest_enemy()


func _get_attacks_per_second() -> float:
	if owner_player == null or not is_instance_valid(owner_player):
		return 0.0
	if not owner_player.has_method("_get_current_attacks_per_second"):
		return 0.0
	return maxf(float(owner_player.call("_get_current_attacks_per_second")) * attack_speed_multiplier, 0.0)


func _fire_at_nearest_enemy() -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return
	if owner_player.get_tree() == null or owner_player.get_tree().current_scene == null:
		return
	var target := EFFECT_TARGETING.nearest_enemy(owner_player, global_position, target_range)
	if target == null:
		return
	if not owner_player.has_method("_spawn_wizard_fire_laser"):
		return
	var target_2d := target as Node2D
	if target_2d == null:
		return
	var direction := target_2d.global_position - global_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	owner_player.call("_spawn_wizard_fire_laser", global_position, direction.normalized())


func _update_unstable_visual(delta: float) -> void:
	if sprite == null:
		return

	jitter_snap_timer -= delta
	if jitter_snap_timer <= 0.0:
		jitter_snap_timer += jitter_snap_interval
		jitter_target_offset = _random_jitter_offset()

	var pulse_time := age * jitter_frequency + jitter_phase
	var elastic_offset := Vector2(
		sin(pulse_time * 1.13) + sin(pulse_time * 2.37) * 0.35,
		cos(pulse_time * 1.41) + sin(pulse_time * 2.09) * 0.28
	) * jitter_radius * 0.42
	jitter_current_offset = jitter_current_offset.lerp(jitter_target_offset + elastic_offset, clampf(delta * 18.0, 0.0, 1.0))
	sprite.position = jitter_current_offset

	var stretch := sin(pulse_time * 1.7) * squash_amount + sin(pulse_time * 3.4) * squash_amount * 0.35
	var tug := clampf(jitter_current_offset.length() / maxf(jitter_radius, 1.0), 0.0, 1.0) * squash_amount * 0.25
	sprite.scale = Vector2(
		visual_scale * (1.0 + stretch + tug),
		visual_scale * (1.0 - stretch * 0.45 - tug * 0.2)
	)
	sprite.rotation = sin(pulse_time * 1.9) * wobble_rotation + jitter_current_offset.x * 0.003


func _random_jitter_offset() -> Vector2:
	return Vector2.RIGHT.rotated(randf() * TAU) * randf_range(jitter_radius * 0.25, jitter_radius)


func _ensure_nodes() -> void:
	if sprite != null:
		return

	sprite = AnimatedSprite2D.new()
	sprite.name = "SpinningFireball"
	sprite.sprite_frames = _make_sprite_frames()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * visual_scale
	sprite.z_index = 120
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)
	sprite.play(&"idle")


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", animation_fps)
	frames.add_animation(&"disappear")
	frames.set_animation_loop(&"disappear", false)
	frames.set_animation_speed(&"disappear", animation_fps)

	for index in range(IDLE_FRAME_COUNT):
		frames.add_frame(&"idle", _make_frame_texture(index))
	for index in range(DISAPPEAR_FRAME_COUNT):
		frames.add_frame(&"disappear", _make_frame_texture(IDLE_FRAME_COUNT + index))
	return frames


func _make_frame_texture(frame_index: int) -> AtlasTexture:
	var columns := maxi(int(SPINNING_FIREBALL_TEXTURE.get_width() / FRAME_SIZE.x), 1)
	var column := frame_index % columns
	var row := frame_index / columns
	var frame := AtlasTexture.new()
	frame.atlas = SPINNING_FIREBALL_TEXTURE
	frame.region = Rect2(
		float(column * FRAME_SIZE.x),
		float(row * FRAME_SIZE.y),
		float(FRAME_SIZE.x),
		float(FRAME_SIZE.y)
	)
	return frame


func _start_disappear() -> void:
	is_disappearing = true
	if sprite == null:
		queue_free()
		return
	sprite.play(&"disappear")


func _on_animation_finished() -> void:
	if is_disappearing:
		queue_free()
