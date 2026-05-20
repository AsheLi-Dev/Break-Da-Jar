@tool
extends Node2D

@export var graph_size: Vector2 = Vector2(720.0, 820.0)
@export var node_radius: float = 12.0
@export var node_color: Color = Color(0.78, 0.82, 0.88, 0.9)
@export var start_node_color: Color = Color(0.85, 0.12, 0.75, 0.95)
@export var graph_color: Color = Color(0.08, 0.08, 0.1, 0.5)
@export var connection_color: Color = Color(0.62, 0.22, 0.78, 0.7)
@export var connection_width: float = 4.0
@export var mirror_left_and_right: bool = true
@export var mirror_center_x: float = 360.0

const NECROMANCER_TALENT_CATALOG := preload("res://scripts/player/NecromancerTalentCatalog.gd")
const START_NODE_NAMES := {
	"tooth_4": true,
}

const MIRROR_PAIRS := [
	["skull_top_0", "skull_top_7"],
	["skull_top_1", "skull_top_6"],
	["skull_top_2", "skull_top_5"],
	["skull_top_3", "skull_top_4"],
	["left_temple", "right_temple"],
	["left_cheek_high", "right_cheek_high"],
	["left_cheek_low", "right_cheek_low"],
	["left_jaw", "right_jaw"],
	["left_chin", "right_chin"],
	["left_eye_0", "right_eye_2"],
	["left_eye_1", "right_eye_1"],
	["left_eye_2", "right_eye_0"],
	["left_eye_3", "right_eye_5"],
	["left_eye_4", "right_eye_4"],
	["left_eye_5", "right_eye_3"],
	["nose_left", "nose_right"],
	["tooth_0", "tooth_8"],
	["tooth_1", "tooth_7"],
	["tooth_2", "tooth_6"],
	["tooth_3", "tooth_5"],
	["mouth_left", "mouth_right"],
]

var _last_positions: Dictionary = {}
var _syncing_mirror := false


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_mirrored_nodes()
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, graph_size), graph_color, false, 2.0)
	for connection in NECROMANCER_TALENT_CATALOG.connections():
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
		draw_circle(marker.position, node_radius, _get_marker_color(marker))


func _sync_mirrored_nodes() -> void:
	if _syncing_mirror or not mirror_left_and_right:
		_remember_positions()
		return

	_syncing_mirror = true
	for pair in MIRROR_PAIRS:
		_sync_mirrored_pair(String(pair[0]), String(pair[1]))
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
	return NECROMANCER_TALENT_CATALOG.node_ids().has(StringName(marker.name))


func _get_marker_color(marker: Node2D) -> Color:
	if START_NODE_NAMES.has(String(marker.name)):
		return start_node_color
	return node_color
