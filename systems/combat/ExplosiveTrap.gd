extends Node2D
class_name ExplosiveTrap

@export var trigger_radius: float = 200.0
@export var explosion_radius: float = 200.0
@export var damage: float = 12.0
@export var check_interval: float = 0.1
@export var telegraph_color: Color = Color(1.0, 0.55, 0.12, 0.16)
@export var explosion_color: Color = Color(1.0, 0.32, 0.05, 0.32)
@export var explosion_lifetime: float = 0.18

var owner_player: Node
var check_remaining: float = 0.0


func setup(new_owner: Node, spawn_position: Vector2, new_damage: float, new_trigger_radius: float, new_explosion_radius: float) -> void:
	owner_player = new_owner
	global_position = spawn_position
	damage = new_damage
	trigger_radius = new_trigger_radius
	explosion_radius = new_explosion_radius


func _ready() -> void:
	_add_telegraph()


func _process(delta: float) -> void:
	check_remaining -= delta
	if check_remaining > 0.0:
		return

	check_remaining = check_interval
	if _has_enemy_in_trigger_radius():
		_explode()


func _has_enemy_in_trigger_radius() -> bool:
	var tree := get_tree()
	if tree == null:
		return false

	for enemy in tree.get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d != null and enemy_2d.global_position.distance_to(global_position) <= trigger_radius:
			return true
	return false


func _explode() -> void:
	_spawn_explosion_visual()
	var tree := get_tree()
	if tree == null:
		queue_free()
		return

	for enemy in tree.get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or enemy_2d.global_position.distance_to(global_position) > explosion_radius:
			continue
		if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
			owner_player.deal_player_damage_to_enemy(enemy, damage, {"source": "explosive_trap", "direct": true, "allow_procs": false})
		elif enemy.has_method("take_damage"):
			enemy.take_damage(damage)

	queue_free()


func _add_telegraph() -> void:
	var visual := Polygon2D.new()
	visual.name = "TrapTelegraph"
	visual.color = telegraph_color
	visual.polygon = _circle_polygon(trigger_radius, 48)
	visual.z_index = 20
	add_child(visual)


func _spawn_explosion_visual() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var visual := Polygon2D.new()
	visual.name = "TrapExplosionVFX"
	visual.color = explosion_color
	visual.polygon = _circle_polygon(explosion_radius, 48)
	visual.global_position = global_position
	visual.z_index = 130
	get_tree().current_scene.add_child(visual)

	var tween := visual.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, explosion_lifetime)
	tween.finished.connect(Callable(visual, "queue_free"))


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	for point in range(points):
		var angle := TAU * float(point) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon
