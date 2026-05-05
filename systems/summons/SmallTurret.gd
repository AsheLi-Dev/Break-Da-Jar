extends Node2D
class_name SmallTurret

const PROJECTILE_SCRIPT := preload("res://scripts/projectiles/Projectile.gd")

@export var duration: float = 10.0
@export var attack_range: float = 220.0
@export var fire_rate: float = 1.0
@export var damage_scale: float = 0.5
@export var projectile_speed: float = 450.0
@export var target_group: StringName = &"enemy"
@export var fallback_damage: float = 5.0

var owner_player: Node
var attack_cooldown: float = 0.0


func setup(new_owner: Node, new_duration: float) -> void:
	owner_player = new_owner
	duration = new_duration


func _ready() -> void:
	_ensure_nodes()
	var timer := get_node_or_null("LifetimeTimer") as Timer
	if timer != null:
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(queue_free)
		timer.start()


func _process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if attack_cooldown > 0.0:
		return

	var target := _get_nearest_enemy()
	if target == null:
		return

	attack_cooldown = 1.0 / maxf(fire_rate, 0.01)
	_fire_at(target)


func _fire_at(target: Node2D) -> void:
	if get_tree().current_scene == null:
		return

	var direction: Vector2 = target.global_position - global_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var projectile := Area2D.new()
	projectile.set_script(PROJECTILE_SCRIPT)
	projectile.global_position = global_position
	projectile.owner_player = owner_player
	projectile.collision_layer = 1 << 2
	projectile.collision_mask = 0
	projectile.set_collision_mask_value(2, true)
	projectile.setup(direction, _get_damage(), projectile_speed, 2.0, target_group)
	get_tree().current_scene.add_child(projectile)


func _get_damage() -> float:
	if owner_player != null and owner_player.has_method("get_base_attack_damage"):
		var damage: float = owner_player.get_base_attack_damage() * damage_scale
		return maxf(damage, 0.0)
	return fallback_damage


func _get_nearest_enemy() -> Node2D:
	var best: Node2D
	var best_distance: float = INF
	for enemy in get_tree().get_nodes_in_group(target_group):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or not is_instance_valid(enemy_2d):
			continue
		var distance: float = enemy_2d.global_position.distance_to(global_position)
		if distance <= attack_range and distance < best_distance:
			best_distance = distance
			best = enemy_2d
	return best


func _ensure_nodes() -> void:
	if get_node_or_null("Sprite2D") == null:
		var sprite := Polygon2D.new()
		sprite.name = "Sprite2D"
		sprite.color = Color(0.9, 0.78, 0.28, 1.0)
		sprite.polygon = PackedVector2Array([
			Vector2(0.0, -14.0),
			Vector2(13.0, 8.0),
			Vector2(0.0, 14.0),
			Vector2(-13.0, 8.0),
		])
		add_child(sprite)

	if get_node_or_null("DetectionArea") == null:
		var area := Area2D.new()
		area.name = "DetectionArea"
		area.monitoring = false
		area.monitorable = false
		add_child(area)

		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = attack_range
		collision.shape = shape
		area.add_child(collision)

	if get_node_or_null("FirePoint") == null:
		var marker := Marker2D.new()
		marker.name = "FirePoint"
		add_child(marker)

	if get_node_or_null("LifetimeTimer") == null:
		var timer := Timer.new()
		timer.name = "LifetimeTimer"
		add_child(timer)
