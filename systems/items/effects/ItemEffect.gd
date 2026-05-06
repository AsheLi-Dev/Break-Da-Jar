extends Resource
class_name ItemEffect

@export var stacking_rule: StringName = &"linear"
@export_multiline var stacking_notes: String = ""


func apply_to(_player: Node) -> void:
	pass
