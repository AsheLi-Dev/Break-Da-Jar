extends Area2D
class_name BreakableContainer

const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const CRATE_BREAK_SFX: AudioStream = preload("res://assets/sfx/crate_break.mp3")
const JAR_BREAK_SFX: AudioStream = preload("res://assets/sfx/jar_break.mp3")
const TOMB_BREAK_SFX: AudioStream = preload("res://assets/sfx/tomb_break.mp3")

signal break_finished(container: BreakableContainer, container_type: int, spawn_position: Vector2)
signal broken(container: BreakableContainer, attack_info: Dictionary)

@export var container_type: int = 0
@export var static_texture: Texture2D
@export var damaged_texture: Texture2D
@export var hit_texture: Texture2D
@export var destroyed_texture: Texture2D
@export var destroy_frames: Array[Texture2D] = []
@export var hit_flash_time: float = 0.08
@export var destroy_frame_time: float = 0.08
@export var max_hp: float = 24.0
@export var is_shop_container: bool = false

var is_breaking: bool = false
var hp: float
var sprite: Sprite2D
var last_attack_info: Dictionary = {}


func _ready() -> void:
	hp = max_hp
	add_to_group("container")
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	sprite.centered = true
	sprite.texture = static_texture


func take_damage(amount: float, attack_info: Dictionary = {}) -> float:
	if is_breaking:
		return 0.0

	last_attack_info = attack_info
	var old_hp: float = hp
	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		break_open()
	else:
		hit()
	return old_hp - hp


func hit() -> void:
	if is_breaking:
		return

	if hit_texture == null:
		return

	sprite.texture = hit_texture
	await get_tree().create_timer(hit_flash_time).timeout
	if not is_breaking and is_instance_valid(sprite):
		sprite.texture = _get_current_static_texture()


func break_open() -> void:
	if is_breaking:
		return

	is_breaking = true
	_play_break_sfx()
	broken.emit(self, last_attack_info)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.set_deferred("disabled", true)

	var release_frame_index: int = mini(1, max(destroy_frames.size() - 1, 0))
	for index in range(destroy_frames.size()):
		var frame: Texture2D = destroy_frames[index]
		if frame != null:
			sprite.texture = frame
		if index == release_frame_index:
			break_finished.emit(self, container_type, global_position)
		await get_tree().create_timer(destroy_frame_time).timeout

	if destroyed_texture != null:
		sprite.texture = destroyed_texture

	queue_free()


func _get_current_static_texture() -> Texture2D:
	if max_hp > 0.0 and hp / max_hp <= 0.5 and damaged_texture != null:
		return damaged_texture

	return static_texture


func _play_break_sfx() -> void:
	var stream := JAR_BREAK_SFX
	if container_type == 1:
		stream = CRATE_BREAK_SFX
	elif container_type == 2:
		stream = TOMB_BREAK_SFX

	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	SFX_PLAYER.play_2d(parent, stream, global_position, -2.0, 0.94, 1.08)
