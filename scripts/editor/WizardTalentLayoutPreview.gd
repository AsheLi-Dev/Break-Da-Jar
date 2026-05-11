@tool
extends Node2D

@export var graph_size: Vector2 = Vector2(720.0, 820.0)
@export var node_radius: float = 12.0
@export var node_color: Color = Color(1.0, 0.35, 0.08, 0.85)
@export var spark_node_color: Color = Color(1.0, 0.7, 0.18, 0.85)
@export var start_node_color: Color = Color(1.0, 0.45, 0.08, 0.95)
@export var graph_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var connection_color: Color = Color(1.0, 0.48, 0.12, 0.65)
@export var connection_width: float = 4.0
@export var mirror_left_and_right: bool = true
@export var mirror_center_x: float = 360.0

const WIZARD_TALENT_CATALOG := preload("res://scripts/player/WizardTalentCatalog.gd")

const START_NODE_NAMES := {
	"flame_bottom_5": true,
}

var _last_positions: Dictionary = {}
var _syncing_mirror := false


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_mirrored_nodes()
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, graph_size), graph_color, false, 2.0)
	for connection in WIZARD_TALENT_CATALOG.connections():
		if connection.size() != 2:
			continue
		var from_marker := get_node_or_null(String(connection[0])) as Node2D
		var to_marker := get_node_or_null(String(connection[1])) as Node2D
		if from_marker == null or to_marker == null:
			continue
		draw_line(from_marker.position, to_marker.position, connection_color, connection_width, true)

	for child in get_children():
		var marker := child as Node2D
		if marker == null or not _is_layout_marker(marker):
			continue
		var color := _get_marker_color(marker)
		draw_circle(marker.position, node_radius, color)


func _sync_mirrored_nodes() -> void:
	if _syncing_mirror or not mirror_left_and_right:
		_remember_positions()
		return

	_syncing_mirror = true
	for index in range(3):
		_sync_mirrored_pair("flame_bottom_%d" % (index + 2), "flame_bottom_%d" % (8 - index))
	for index in range(14):
		_sync_mirrored_pair("flame_left_%d" % index, "flame_right_%d" % index)
	for index in range(5):
		_sync_mirrored_pair("flame_left_start_%d" % index, "flame_right_start_%d" % index)

	_remember_positions()
	_syncing_mirror = false


func _sync_mirrored_pair(left_name: String, right_name: String) -> void:
	var left := get_node_or_null(left_name) as Node2D
	var right := get_node_or_null(right_name) as Node2D
	if left == null or right == null:
		return

	var left_key := String(left.name)
	var right_key := String(right.name)
	var left_changed := _last_positions.has(left_key) and not left.position.is_equal_approx(_last_positions[left_key])
	var right_changed := _last_positions.has(right_key) and not right.position.is_equal_approx(_last_positions[right_key])

	if left_changed and not right_changed:
		right.position = _mirror_position(left.position)
	elif right_changed and not left_changed:
		left.position = _mirror_position(right.position)
	elif left_changed and right_changed:
		right.position = _mirror_position(left.position)


func _mirror_position(position: Vector2) -> Vector2:
	return Vector2(mirror_center_x * 2.0 - position.x, position.y)


func _remember_positions() -> void:
	for child in get_children():
		var marker := child as Node2D
		if marker == null or not _is_layout_marker(marker):
			continue
		_last_positions[String(marker.name)] = marker.position


func _is_layout_marker(marker: Node2D) -> bool:
	var marker_name := String(marker.name)
	return marker_name.begins_with("flame_") or marker_name.begins_with("spark_")


func _get_marker_color(marker: Node2D) -> Color:
	var marker_name := String(marker.name)
	if START_NODE_NAMES.has(marker_name):
		return start_node_color
	if marker_name.begins_with("spark_"):
		return spark_node_color
	return node_color
