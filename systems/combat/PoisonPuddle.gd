extends Node2D
class_name PoisonPuddle

@export var radius: float = 160.0
@export var duration: float = 10.0
@export var damage_per_second: float = 5.0
@export var slow_multiplier: float = 0.65
@export var slow_refresh_time: float = 0.25

var age: float = 0.0
var damage_tick_remaining: float = 1.0
var visual: Polygon2D


func setup(spawn_position: Vector2, new_radius: float, new_duration: float) -> void:
	global_position = spawn_position
	radius = new_radius
	duration = new_duration


func _ready() -> void:
	_create_visual()


func _process(delta: float) -> void:
	age += delta
	damage_tick_remaining -= delta
	_apply_player_effects(damage_tick_remaining <= 0.0)
	if damage_tick_remaining <= 0.0:
		damage_tick_remaining = 1.0

	if visual != null:
		visual.modulate.a = lerpf(0.42, 0.0, clampf(age / maxf(duration, 0.001), 0.0, 1.0))

	if age >= duration:
		queue_free()


func _apply_player_effects(should_damage: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return

	for player in tree.get_nodes_in_group("player"):
		var player_2d := player as Node2D
		if player_2d == null or player_2d.global_position.distance_to(global_position) > radius:
			continue
		if player.has_method("apply_slow"):
			player.apply_slow(slow_multiplier, slow_refresh_time)
		if should_damage and player.has_method("take_damage"):
			player.take_damage(damage_per_second)


func _create_visual() -> void:
	visual = Polygon2D.new()
	visual.name = "PoisonPuddleVisual"
	visual.color = Color(0.35, 0.95, 0.08, 0.42)
	visual.polygon = _circle_polygon(radius, 40)
	visual.z_index = 12
	add_child(visual)


func _circle_polygon(polygon_radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for index in range(points):
		var angle := TAU * float(index) / float(points)
		var wobble := 1.0 + sin(float(index) * 2.17) * 0.05
		polygon.append(Vector2(cos(angle), sin(angle)) * polygon_radius * wobble)

	return polygon
