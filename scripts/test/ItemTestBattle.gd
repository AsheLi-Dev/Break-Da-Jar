extends Node2D

const ITEM_DATABASE_PATH := "/root/ItemDatabase"

var item_ids: Array[StringName] = []
var option_button: OptionButton
var status_label: Label


func _ready() -> void:
	_create_debug_ui()
	_populate_item_dropdown()


func _create_debug_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ItemDebugUI"
	canvas.layer = 20
	add_child(canvas)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(24, 76)
	panel.size = Vector2(420, 126)
	canvas.add_child(panel)

	option_button = OptionButton.new()
	option_button.name = "ItemDropdown"
	option_button.position = Vector2(16, 16)
	option_button.size = Vector2(388, 32)
	panel.add_child(option_button)

	var give_button := Button.new()
	give_button.name = "GiveItemButton"
	give_button.text = "Give Item"
	give_button.position = Vector2(16, 58)
	give_button.size = Vector2(120, 34)
	give_button.pressed.connect(_give_selected_item)
	panel.add_child(give_button)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(150, 58)
	status_label.size = Vector2(254, 48)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status_label)


func _populate_item_dropdown() -> void:
	option_button.clear()
	item_ids.clear()

	var database := get_node_or_null(ITEM_DATABASE_PATH)
	if database == null:
		status_label.text = "ItemDatabase autoload not found."
		return

	for item in database.all_items:
		if item == null:
			continue
		var label := "%s [%s]" % [item.display_name, item.rarity]
		option_button.add_item(label)
		item_ids.append(item.id)

	status_label.text = "Loaded %d items." % item_ids.size()


func _give_selected_item() -> void:
	if item_ids.is_empty():
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("add_item"):
		status_label.text = "Player not found yet."
		return

	var database := get_node_or_null(ITEM_DATABASE_PATH)
	if database == null:
		status_label.text = "ItemDatabase autoload not found."
		return

	var selected_index: int = option_button.selected
	if selected_index < 0 or selected_index >= item_ids.size():
		return

	var item_id: StringName = item_ids[selected_index]
	var item: ItemDefinition = database.get_item(item_id)
	if item == null:
		status_label.text = "Unknown item: %s" % item_id
		return

	player.add_item(item)
	status_label.text = "Gave: %s" % item.display_name
