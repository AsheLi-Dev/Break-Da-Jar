extends Node

const DEFAULT_CHARACTER_ID := &"necromancer"

var selected_character_id: StringName = DEFAULT_CHARACTER_ID


func set_selected_character(character_id: StringName) -> void:
	selected_character_id = character_id


func get_selected_character() -> StringName:
	return selected_character_id
