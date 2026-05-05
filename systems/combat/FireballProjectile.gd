extends Area2D
class_name FireballProjectile

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 520.0
@export var damage: float = 12.0
@export var lifetime: float = 1.5
@export var explosion_radius: float = 80.0
@export var target_group: StringName = &"enemy"
@export var damages_containers: bool = true
@export var debug_color: Color = Color(1.0, 0.35, 0.08)

var owner_player: Node
var age: float = 0.0
var exploded: bool = false


func setup(new_owner: Node, new_position: Vector2, new_direction: Vector2, new_damage: float, new_radius: float) -> void:
	owner_player = new_owner
	global_position = new_position
	direction = new_direction.normalized()
	damage = new_damage
	explosion_radius = new_radius
	rotation = direction.angle()


func _ready() -> void:
	_ensure_nodes()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	age += delta
	if age >= lifetime:
		explode()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) or _is_wall_body(body):
		explode()


func explode() -> void:
	if exploded:
		return

	exploded = true
	print("Fireball explodes")
	var poison_stacks: int = 0
	if owner_player != null and owner_player.has_method("get_stats"):
		var stats: StatsComponent = owner_player.get_stats()
		if stats != null:
			poison_stacks = stats.fireball_poison_stacks

	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or enemy_2d.global_position.distance_to(global_position) > explosion_radius:
			continue
		if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
			owner_player.deal_player_damage_to_enemy(enemy, damage, {"source": "fireball", "direct": true, "allow_procs": false})
		elif enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		if poison_stacks > 0 and enemy.has_method("apply_poison_stacks"):
			enemy.apply_poison_stacks(poison_stacks, owner_player)

	if damages_containers:
		for container in get_tree().get_nodes_in_group("container"):
			var container_2d := container as Node2D
			if container_2d == null or container_2d.global_position.distance_to(global_position) > explosion_radius:
				continue
			if container is BreakableContainer and container.is_shop_container:
				continue
			if container.has_method("take_damage"):
				container.take_damage(damage, {"source": "fireball", "owner": owner_player})

	queue_free()


func _is_wall_body(body: Node) -> bool:
	return body is StaticBody2D or body is TileMap or body is TileMapLayer or body.is_in_group("wall") or body.is_in_group("walls")


func _ensure_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 8.0
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("DebugBody") == null:
		var body := Polygon2D.new()
		body.name = "DebugBody"
		body.color = debug_color
		body.polygon = PackedVector2Array([
			Vector2(14.0, 0.0),
			Vector2(-8.0, -8.0),
			Vector2(-4.0, 0.0),
			Vector2(-8.0, 8.0),
		])
		add_child(body)
