extends Area2D
class_name BloodBladeProjectile

const IDLE_TEXTURE_PATH := "res://assets/vfx/blood spell/blood blade/Effect 6 Idle.png"
const END_TEXTURE_PATH := "res://assets/vfx/blood spell/blood blade/Effect 6 End.png"
const FRAME_SIZE := Vector2(196.0, 196.0)
const HITBOX_SIZE := Vector2(35.0, 78.0)
const VISUAL_SCALE := Vector2(0.5, 0.5)

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 400.0
@export var damage: float = 6.0
@export var lifetime: float = 0.5
@export var animation_fps: float = 30.0

var owner_player: Node
var age: float = 0.0
var ending: bool = false
var hit_bodies: Array[Node] = []
var idle_texture: Texture2D
var end_texture: Texture2D


func setup(new_owner: Node, start_position: Vector2, new_direction: Vector2, new_damage: float, new_speed: float, new_lifetime: float) -> void:
	owner_player = new_owner
	global_position = start_position
	direction = new_direction.normalized() if new_direction.length_squared() > 0.001 else Vector2.RIGHT
	damage = new_damage
	speed = new_speed
	lifetime = new_lifetime
	rotation = direction.angle()


func _ready() -> void:
	set_collision_mask_value(1, true)
	_ensure_nodes()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if ending:
		return

	position += direction * speed * delta
	age += delta
	if age >= lifetime:
		_start_end_animation()


func _on_body_entered(body: Node) -> void:
	if _is_wall_body(body):
		_start_end_animation()
		return
	_try_damage_enemy(body)


func _on_area_entered(area: Area2D) -> void:
	_try_damage_enemy(_get_enemy_target(area))


func _try_damage_enemy(enemy: Node) -> void:
	if ending or enemy == null or not enemy.is_in_group("enemy") or hit_bodies.has(enemy):
		return
	if not enemy.has_method("take_damage"):
		return

	hit_bodies.append(enemy)
	if owner_player != null and is_instance_valid(owner_player) and owner_player.has_method("deal_player_damage_to_enemy"):
		owner_player.deal_player_damage_to_enemy(enemy, damage, {"source": "blood_blade", "direct": true, "allow_procs": false})
	else:
		enemy.call("take_damage", damage)
	if enemy.has_method("apply_status_effect"):
		var status_owner: Node = owner_player if owner_player != null and is_instance_valid(owner_player) else null
		enemy.apply_status_effect(&"bleeding", status_owner)


func _get_enemy_target(node: Node) -> Node:
	if node.is_in_group("enemy") and node.has_method("take_damage"):
		return node

	var parent := node.get_parent()
	if parent != null and parent.is_in_group("enemy") and parent.has_method("take_damage"):
		return parent

	return null


func _is_wall_body(body: Node) -> bool:
	if body == null:
		return false
	return body is StaticBody2D or body is TileMap or body is TileMapLayer or body.is_in_group("wall") or body.is_in_group("walls")


func _ensure_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = HITBOX_SIZE
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("BloodBladeSprite") != null:
		return

	var sprite := AnimatedSprite2D.new()
	sprite.name = "BloodBladeSprite"
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _make_sprite_frames()
	sprite.scale = VISUAL_SCALE
	sprite.z_index = 125
	add_child(sprite)
	sprite.play(&"idle")


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_animation_frames(frames, &"idle", _get_idle_texture(), true)
	_add_animation_frames(frames, &"end", _get_end_texture(), false)
	return frames


func _add_animation_frames(frames: SpriteFrames, animation_name: StringName, texture: Texture2D, loop: bool) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, loop)
	frames.set_animation_speed(animation_name, animation_fps)
	if texture == null:
		return

	var frame_count := maxi(int(texture.get_width() / FRAME_SIZE.x), 1)
	for frame_index in range(frame_count):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(float(frame_index) * FRAME_SIZE.x, 0.0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(animation_name, frame_texture)


func _start_end_animation() -> void:
	if ending:
		return

	ending = true
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.set_deferred("disabled", true)

	var sprite := get_node_or_null("BloodBladeSprite") as AnimatedSprite2D
	if sprite == null:
		queue_free()
		return
	sprite.play(&"end")
	sprite.animation_finished.connect(Callable(self, "queue_free"), CONNECT_ONE_SHOT)


func _get_idle_texture() -> Texture2D:
	if idle_texture != null:
		return idle_texture

	var image := Image.load_from_file(IDLE_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load blood blade idle texture: %s" % IDLE_TEXTURE_PATH)
		return null

	idle_texture = ImageTexture.create_from_image(image)
	return idle_texture


func _get_end_texture() -> Texture2D:
	if end_texture != null:
		return end_texture

	var image := Image.load_from_file(END_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load blood blade end texture: %s" % END_TEXTURE_PATH)
		return null

	end_texture = ImageTexture.create_from_image(image)
	return end_texture
