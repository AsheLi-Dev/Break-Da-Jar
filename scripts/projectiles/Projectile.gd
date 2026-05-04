extends Area2D
class_name Projectile

# Projectile tuning. Enemies call setup() before launch.
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 360.0
@export var damage: float = 8.0
@export var lifetime: float = 2.0
@export var target_group: StringName = &"player"
@export var hit_walls: bool = true
@export var debug_color: Color = Color(1.0, 0.82, 0.16)

var age: float = 0.0


func _ready() -> void:
	direction = direction.normalized()
	rotation = direction.angle()
	_ensure_placeholder_nodes()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2, new_damage: float, new_speed: float = -1.0, new_lifetime: float = -1.0, new_target_group: StringName = &"player") -> void:
	direction = new_direction.normalized()
	damage = new_damage
	target_group = new_target_group
	if new_speed > 0.0:
		speed = new_speed
	if new_lifetime > 0.0:
		lifetime = new_lifetime
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	# Projectile damage is explicit: movement plus Area2D body_entered.
	position += direction * speed * delta
	age += delta
	if age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) and body.has_method("take_damage"):
		body.call("take_damage", damage)
		queue_free()
		return

	if hit_walls and _is_wall_body(body):
		queue_free()


func _is_wall_body(body: Node) -> bool:
	if body.is_in_group("walls") or body.is_in_group("wall"):
		return true

	return body is StaticBody2D or body is TileMapLayer or body is TileMap


func _ensure_placeholder_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 5.0
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("DebugBody") == null:
		var body := Polygon2D.new()
		body.name = "DebugBody"
		body.color = debug_color
		body.polygon = PackedVector2Array([
			Vector2(10.0, 0.0),
			Vector2(-5.0, -4.0),
			Vector2(-2.0, 0.0),
			Vector2(-5.0, 4.0),
		])
		add_child(body)
