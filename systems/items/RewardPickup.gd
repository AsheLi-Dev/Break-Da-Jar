extends Node2D
class_name RewardPickup

const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const GOLD_PICKUP_SFX: AudioStream = preload("res://assets/sfx/gold_pickup.mp3")
const XP_PICKUP_SFX: AudioStream = preload("res://assets/sfx/xp_pickup.mp3")

const KIND_GOLD := &"gold"
const KIND_EXPERIENCE := &"experience"
const KIND_HEAL := &"heal"

@export var kind: StringName = KIND_GOLD
@export var amount: int = 1
@export var fly_speed: float = 650.0
@export var collect_distance: float = 18.0
@export var collect_delay: float = 0.35
@export var magnet_delay: float = 0.45
@export var gravity: float = 720.0
@export var bounce_restitution: float = 0.42
@export var ground_drag: float = 9.0

var target_player: Player
var velocity: Vector2 = Vector2.ZERO
var height: float = 0.0
var vertical_velocity: float = 0.0
var age: float = 0.0
var collected: bool = false
var body: Polygon2D
var label: Label
var shadow: Polygon2D


func setup(new_kind: StringName, new_amount: int, spawn_position: Vector2, new_target_player: Player) -> void:
	kind = new_kind
	amount = new_amount
	global_position = spawn_position
	target_player = new_target_player
	var burst_direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	velocity = burst_direction * randf_range(140.0, 240.0)
	height = randf_range(12.0, 24.0)
	vertical_velocity = randf_range(170.0, 260.0)


func _ready() -> void:
	z_index = 80
	_ensure_visual()


func _process(delta: float) -> void:
	if collected:
		return

	age += delta
	_update_bounce(delta)
	_update_visual_height()

	if target_player == null or not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Player
		if target_player == null:
			return

	var offset: Vector2 = target_player.global_position - global_position
	if age >= collect_delay and offset.length() <= collect_distance:
		_collect()
		return

	if age >= magnet_delay:
		var distance := maxf(offset.length(), 1.0)
		var magnet_strength := clampf(1.0 - distance / 700.0, 0.0, 1.0)
		velocity = velocity.move_toward(offset.normalized() * fly_speed, fly_speed * magnet_strength * delta * 3.5)

	global_position += velocity * delta


func _collect() -> void:
	collected = true
	if target_player == null or not is_instance_valid(target_player):
		queue_free()
		return

	if kind == KIND_EXPERIENCE:
		target_player.gain_experience(amount)
		_play_pickup_sfx(XP_PICKUP_SFX, -2.0, 0.88, 1.18)
	elif kind == KIND_GOLD:
		target_player.add_gold(amount)
		_play_pickup_sfx(GOLD_PICKUP_SFX, -4.0, 0.92, 1.16)
	elif kind == KIND_HEAL:
		target_player.heal(amount)
		_play_pickup_sfx(XP_PICKUP_SFX, -3.0, 1.08, 1.28)

	queue_free()


func _update_bounce(delta: float) -> void:
	if height > 0.0 or vertical_velocity > 0.0:
		height += vertical_velocity * delta
		vertical_velocity -= gravity * delta
		if height <= 0.0:
			height = 0.0
			if absf(vertical_velocity) > 48.0:
				vertical_velocity = absf(vertical_velocity) * bounce_restitution
			else:
				vertical_velocity = 0.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ground_drag * 60.0 * delta)


func _update_visual_height() -> void:
	var visual_position := Vector2(0.0, -height)
	if body != null:
		body.position = visual_position
	if label != null:
		label.position = visual_position + Vector2(-10.0, -28.0)
	if shadow != null:
		var shadow_scale := clampf(1.0 - height * 0.01, 0.45, 1.0)
		shadow.scale = Vector2(shadow_scale, shadow_scale)


func _play_pickup_sfx(stream: AudioStream, volume_db: float, pitch_min: float, pitch_max: float) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	SFX_PLAYER.play_2d(parent, stream, global_position, volume_db, pitch_min, pitch_max)


func _ensure_visual() -> void:
	shadow = Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.02, 0.025, 0.03, 0.28)
	shadow.polygon = PackedVector2Array([
		Vector2(-8.0, -3.0),
		Vector2(8.0, -3.0),
		Vector2(8.0, 3.0),
		Vector2(-8.0, 3.0),
	])
	add_child(shadow)

	body = Polygon2D.new()
	body.name = "Body"
	if kind == KIND_GOLD:
		body.color = Color(1.0, 0.78, 0.18, 1.0)
	elif kind == KIND_HEAL:
		body.color = Color(0.34, 1.0, 0.56, 1.0)
	else:
		body.color = Color(0.24, 0.72, 1.0, 1.0)
	body.polygon = PackedVector2Array([
		Vector2(0.0, -8.0),
		Vector2(7.0, 0.0),
		Vector2(0.0, 8.0),
		Vector2(-7.0, 0.0),
	])
	add_child(body)

	label = Label.new()
	label.name = "Label"
	if kind == KIND_GOLD:
		label.text = "$"
	elif kind == KIND_HEAL:
		label.text = "+"
	else:
		label.text = "XP"
	label.position = Vector2(-10.0, -28.0)
	label.add_theme_color_override("font_color", body.color)
	add_child(label)
	_update_visual_height()
