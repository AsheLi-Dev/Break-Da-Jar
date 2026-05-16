extends Node

const PLAYER_SCRIPT := preload("res://scripts/player/Player.gd")
const TALENT_TREE_UI := preload("res://systems/battle/TalentTreeUiController.gd")

@export var preview_talent_points: int = 99

var player: Player
var talent_tree_ui: TalentTreeUiController


func _ready() -> void:
	player = PLAYER_SCRIPT.new() as Player
	player.name = "PreviewWizardPlayer"
	player.setup_character(&"wizard")
	player.unspent_talent_points = preview_talent_points
	player.visible = false
	add_child(player)

	talent_tree_ui = TALENT_TREE_UI.new() as TalentTreeUiController
	add_child(talent_tree_ui)
	talent_tree_ui.setup(player)
	talent_tree_ui.talent_requested.connect(_on_talent_requested)
	talent_tree_ui.show_tree()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _on_talent_requested(node_id: StringName) -> void:
	if player.unlock_talent(node_id):
		talent_tree_ui.refresh()
