extends Area2D
class_name HolyFlameLaser

const LASER_TEXTURE: Texture2D = preload("res://assets/vfx/fire spell/fire laser 256x128.png")
const FRAME_SIZE := Vector2i(256, 128)
const FRAME_COUNT := 8

@export var length: float = 250.0
@export var width: float = 42.0
@export var animation_fps: float = 24.0
@export var damages_enemies: bool = true
@export var damages_containers: bool = true

var owner_player: Node
var damage: float = 12.0
var direction: Vector2 = Vector2.RIGHT
var elapsed: float = 0.0
var damaged_bodies: Array[Node] = []
var damaged_containers: Array[Node] = []
var sprite: AnimatedSprite2D
var attack_source: String = "player_attack"
var allow_procs: bool = true
var chain_remaining: int = 0
var chain_range: float = 700.0
var chain_damage_multiplier: float = 1.0


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
		if damages_enemies and body.is_in_group("enemy"):
			_damage_enemy(body)
		elif damages_containers and body.is_in_group("container"):
			_damage_container(body)
	for area in get_overlapping_areas():
		var enemy := _get_enemy_target(area)
		if damages_enemies and enemy != null:
			_damage_enemy(enemy)
		elif damages_containers and area.is_in_group("container"):
			_damage_container(area)
	if damages_containers:
		_damage_containers_in_beam()


func _get_enemy_target(node: Node) -> Node:
	if node.is_in_group("enemy") and node.has_method("take_damage"):
		return node

	var parent := node.get_parent()
	if parent != null and parent.is_in_group("enemy") and parent.has_method("take_damage"):
		return parent

	return null


func _damage_enemy(enemy: Node) -> void:
	if damaged_bodies.has(enemy) or not enemy.has_method("take_damage"):
		return

	damaged_bodies.append(enemy)
	if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
		owner_player.deal_player_damage_to_enemy(enemy, damage, {"source": attack_source, "direct": true, "allow_procs": allow_procs})
	else:
		enemy.call("take_damage", damage)
	if chain_remaining > 0 and owner_player != null and owner_player.has_method("spawn_chained_wizard_fire_laser"):
		owner_player.call("spawn_chained_wizard_fire_laser", enemy, chain_remaining - 1, chain_range, damaged_bodies.duplicate(), chain_damage_multiplier)


func _damage_container(container: Node) -> void:
	if damaged_containers.has(container) or not container.has_method("take_damage"):
		return
	if container is BreakableContainer and container.is_shop_container:
		return

	damaged_containers.append(container)
	container.take_damage(damage, {"source": attack_source, "owner": owner_player})


func _damage_containers_in_beam() -> void:
	if get_tree() == null:
		return
	for container in get_tree().get_nodes_in_group("container"):
		var container_2d := container as Node2D
		if container_2d == null or not _is_position_in_beam(container_2d.global_position):
			continue
		_damage_container(container)


func _is_position_in_beam(world_position: Vector2) -> bool:
	var local_position := to_local(world_position)
	return (
		local_position.x >= -length * 0.5
		and local_position.x <= length * 0.5
		and absf(local_position.y) <= width * 0.5
	)
