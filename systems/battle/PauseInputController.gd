extends Node
class_name PauseInputController

signal resume_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if not get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel"):
			resume_requested.emit()
			get_viewport().set_input_as_handled()
