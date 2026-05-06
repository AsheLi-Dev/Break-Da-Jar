extends Area2D
class_name HolyFlameLaser

const LASER_TEXTURE: Texture2D = preload("res://assets/vfx/fire spell/fire laser 256x128.png")
const FRAME_SIZE := Vector2i(256, 128)
const FRAME_COUNT := 8

@export var length: float = 250.0
@export var width: float = 42.0
@export var animation_fps: float = 24.0

var owner_player: Node
var damage: float = 12.0
var direction: Vector2 = Vector2.RIGHT
var elapsed: float = 0.0
var damaged_bodies: Array[Node] = []
var damaged_containers: Array[Node] = []
var sprite: AnimatedSprite2D
var attack_source: String = "player_attack"
var allow_procs: bool = true


func setup(new_owner_player: Node, origin: Vector2, new_direction: Vector2, new_damage: float, new_attack_source: String = "player_attack", new_allow_procs: bool = true) -> void:
	owner_player = new_owner_player
	direction = new_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	damage = new_damage
	attack_source = new_attack_source
	allow_procs = new_allow_procs
	global_position = origin + direction * (length * 0.5)
	rotation = direction.angle()


func _ready() -> void:
	_ensure_nodes()


func _process(delta: float) -> void:
	elapsed += delta
	var frame_index := mini(int(floor(elapsed * animation_fps)), FRAME_COUNT - 1)
	if frame_index == 1 or frame_index == 2:
		_apply_damage()
	if frame_index >= FRAME_COUNT - 1 and elapsed >= float(FRAME_COUNT) / animation_fps:
		queue_free()


func _ensure_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(length, width)
		collision.shape = shape
		add_child(collision)

	if sprite != null:
		return

	sprite = AnimatedSprite2D.new()
	sprite.name = "LaserSprite"
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _make_sprite_frames()
	sprite.scale = Vector2(length / float(FRAME_SIZE.x), width / float(FRAME_SIZE.y))
	add_child(sprite)
	sprite.play(&"fire")


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var animation_name := &"fire"
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, false)
	frames.set_animation_speed(animation_name, animation_fps)
	for frame in range(FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = LASER_TEXTURE
		atlas.region = Rect2(frame * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(animation_name, atlas)
	return frames


func _apply_damage() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy"):
			_damage_enemy(body)
		elif body.is_in_group("container"):
			_damage_container(body)
	for area in get_overlapping_areas():
		if area.is_in_group("container"):
			_damage_container(area)


func _damage_enemy(enemy: Node) -> void:
	if damaged_bodies.has(enemy) or not enemy.has_method("take_damage"):
		return

	damaged_bodies.append(enemy)
	if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
		owner_player.deal_player_damage_to_enemy(enemy, damage, {"source": attack_source, "direct": true, "allow_procs": allow_procs})
	else:
		enemy.call("take_damage", damage)


func _damage_container(container: Node) -> void:
	if damaged_containers.has(container) or not container.has_method("take_damage"):
		return

	damaged_containers.append(container)
	container.take_damage(damage, {"source": attack_source, "owner": owner_player})
