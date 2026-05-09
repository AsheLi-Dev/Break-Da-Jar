extends CanvasLayer
class_name TalentTreeUiController

signal talent_requested(node_id: StringName)

const SCREEN_SIZE := Vector2(1920, 1080)
const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const TALENT_HOVER_SFX: AudioStream = preload("res://assets/sfx/Hover_1.wav")

var player: Player
var panel: Panel
var point_label: Label
var buttons: Dictionary = {}


func setup(new_player: Player) -> void:
	player = new_player
	name = "TalentTreeLayer"
	layer = 30
	visible = false
	_build_ui()
	refresh()


func show_tree() -> void:
	visible = true
	refresh()


func hide_tree() -> void:
	visible = false


func is_open() -> bool:
	return visible


func refresh() -> void:
	if point_label == null or not is_instance_valid(player):
		return

	point_label.text = "Unspent Talent Points: %d" % player.unspent_talent_points
	for node_id in buttons.keys():
		var button := buttons[node_id] as Button
		if button == null:
			continue

		var unlocked: bool = player.unlocked_talents.has(node_id)
		var can_unlock: bool = player.can_unlock_talent(node_id)
		button.disabled = unlocked or not can_unlock
		if unlocked:
			button.modulate = Color(1.0, 0.86, 0.32)
		elif can_unlock:
			button.modulate = Color(0.42, 0.92, 0.58)
		else:
			button.modulate = Color(0.44, 0.48, 0.48)


func _build_ui() -> void:
	var blocker := ColorRect.new()
	blocker.name = "Blocker"
	blocker.color = Color(0.0, 0.0, 0.0, 0.58)
	blocker.position = Vector2.ZERO
	blocker.size = SCREEN_SIZE
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)

	panel = Panel.new()
	panel.name = "TalentTreePanel"
	panel.position = Vector2(600, 72)
	panel.size = Vector2(720, 936)
	add_child(panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "Talent Tree"
	title.position = Vector2(32, 22)
	title.size = Vector2(360, 32)
	title.add_theme_font_size_override("font_size", 24)
	panel.add_child(title)

	point_label = Label.new()
	point_label.name = "TalentPointLabel"
	point_label.position = Vector2(32, 58)
	point_label.size = Vector2(360, 28)
	panel.add_child(point_label)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.position = Vector2(588, 24)
	close_button.size = Vector2(96, 34)
	close_button.pressed.connect(hide_tree)
	panel.add_child(close_button)

	var graph := Control.new()
	graph.name = "Graph"
	graph.position = Vector2(0, 96)
	graph.size = Vector2(720, 820)
	graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(graph)

	_add_connection_lines(graph)
	_add_buttons(graph)


func _add_connection_lines(graph: Control) -> void:
	if not is_instance_valid(player):
		return

	for connection in player.get_talent_connections():
		var from_id: StringName = connection[0]
		var to_id: StringName = connection[1]
		var from_position: Vector2 = _get_talent_ui_position(player.get_talent_node_grid_position(from_id))
		var to_position: Vector2 = _get_talent_ui_position(player.get_talent_node_grid_position(to_id))
		var line := ColorRect.new()
		line.name = "TalentConnection"
		line.color = Color(0.42, 0.48, 0.44, 0.85)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if absf(from_position.x - to_position.x) < 0.1:
			line.position = Vector2(from_position.x - 2.0, minf(from_position.y, to_position.y))
			line.size = Vector2(4.0, absf(from_position.y - to_position.y))
		else:
			line.position = Vector2(minf(from_position.x, to_position.x), from_position.y - 2.0)
			line.size = Vector2(absf(from_position.x - to_position.x), 4.0)
		graph.add_child(line)


func _add_buttons(graph: Control) -> void:
	if not is_instance_valid(player):
		return

	buttons.clear()
	for node_id in player.get_talent_node_ids():
		var button := Button.new()
		button.name = String(node_id)
		button.text = player.get_talent_display_name(node_id)
		button.tooltip_text = player.get_talent_description(node_id)
		button.position = _get_talent_ui_position(player.get_talent_node_grid_position(node_id)) - Vector2(24, 24)
		button.size = Vector2(48, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_entered.connect(_play_talent_hover_sfx)
		button.pressed.connect(_on_button_pressed.bind(node_id))
		graph.add_child(button)
		buttons[node_id] = button


func _get_talent_ui_position(coord: Vector2i) -> Vector2:
	var spacing := Vector2(78.0, 86.0)
	var center_x: float = 360.0
	var bottom_y: float = 716.0
	return Vector2(
		center_x + (float(coord.x) - 3.0) * spacing.x,
		bottom_y - float(coord.y) * spacing.y
	)


func _on_button_pressed(node_id: StringName) -> void:
	talent_requested.emit(node_id)


func _play_talent_hover_sfx() -> void:
	if not is_instance_valid(player):
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	SFX_PLAYER.play_2d(parent, TALENT_HOVER_SFX, player.global_position, -6.0, 1.0, 1.0)
