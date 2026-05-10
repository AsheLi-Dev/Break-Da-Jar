extends Node2D
class_name FireEssencePickup

@export var collect_radius: float = 300.0
@export var lifetime: float = 5.0
@export var pulse_speed: float = 5.0

var target_player: Node2D
var age: float = 0.0
var collected: bool = false
var body: Polygon2D


func setup(spawn_position: Vector2, new_target_player: Node2D) -> void:
	name = "FireEssencePickup"
	global_position = spawn_position
	target_player = new_target_player


func _ready() -> void:
	z_index = 85
	_ensure_visual()


func _process(delta: float) -> void:
	if collected:
		return

	age += delta
	if age >= lifetime:
		queue_free()
		return

	if body != null:
		var pulse := 1.0 + sin(age * pulse_speed) * 0.12
		body.scale = Vector2.ONE * pulse

	if target_player == null or not is_instance_valid(target_player):
		target_player = get_tree().get_first_node_in_group("player") as Node2D
		if target_player == null:
			return

	if target_player.global_position.distance_to(global_position) <= collect_radius:
		_collect()


func _collect() -> void:
	collected = true
	if target_player != null and is_instance_valid(target_player) and target_player.has_method("collect_fire_essence"):
		target_player.call("collect_fire_essence")
	queue_free()


func _ensure_visual() -> void:
	if body != null:
		return

	body = Polygon2D.new()
	body.name = "FireEssenceVisual"
	body.color = Color(1.0, 0.42, 0.08, 0.92)
	body.polygon = PackedVector2Array([
		Vector2(0.0, -18.0),
		Vector2(12.0, -4.0),
		Vector2(8.0, 12.0),
		Vector2(0.0, 18.0),
		Vector2(-8.0, 12.0),
		Vector2(-12.0, -4.0),
	])
	add_child(body)
