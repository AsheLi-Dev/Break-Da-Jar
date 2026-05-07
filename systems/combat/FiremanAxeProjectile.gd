extends Projectile
class_name FiremanAxeProjectile

const AXE_TEXTURE: Texture2D = preload("res://assets/vfx/barbarian-spinning-axe.png")
const FRAME_SIZE := Vector2i(256, 256)
const FRAME_COUNT := 15

@export var animation_fps: float = 24.0
@export var visual_scale: Vector2 = Vector2(0.3515625, 0.3515625)
@export var collision_radius: float = 15.0

var has_reversed: bool = false
var animation_elapsed: float = 0.0
var sprite: Sprite2D


func _physics_process(delta: float) -> void:
	animation_elapsed += delta
	if not has_reversed and age >= lifetime * 0.5:
		has_reversed = true
		direction = -direction
		rotation = direction.angle()

	position += direction * speed * delta
	age += delta
	_update_animation_frame()

	if age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _try_damage_fireman_target(body):
		return

	if hit_walls and _is_wall_body(body):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	_try_damage_fireman_target(area)


func _try_damage_fireman_target(node: Node) -> bool:
	var target := _get_damage_target(node)
	if target == null:
		return false

	var hit_targets: Array[Node] = return_hit_targets if has_reversed else outbound_hit_targets
	if hit_targets.has(target):
		return false

	hit_targets.append(target)
	_damage_target_body(target)
	return true


func _ensure_placeholder_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = collision_radius
		collision.shape = shape
		add_child(collision)

	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	sprite.centered = true
	sprite.texture = AXE_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))
	sprite.scale = visual_scale
	sprite.z_index = 120


func _update_animation_frame() -> void:
	if sprite == null:
		return

	var frame := int(floor(animation_elapsed * animation_fps)) % FRAME_COUNT
	sprite.region_rect = Rect2(
		Vector2(float(frame * FRAME_SIZE.x), 0.0),
		Vector2(FRAME_SIZE)
	)
