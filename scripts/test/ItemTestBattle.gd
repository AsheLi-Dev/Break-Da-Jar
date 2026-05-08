extends Node2D

const ITEM_DATABASE_PATH := "/root/ItemDatabase"
const PREVIEW_JAR_OFFSET := Vector2(180.0, 0.0)

var item_ids: Array[StringName] = []
var option_button: OptionButton
var status_label: Label


func _ready() -> void:
	_create_debug_ui()
	_populate_item_dropdown()


func _create_debug_ui() -> void:
	var parent := _get_debug_ui_parent()

	var panel := Panel.new()
	panel.name = "ItemDebugUI"
	panel.position = Vector2(24, 116)
	panel.size = Vector2(460, 144)
	parent.add_child(panel)

	option_button = OptionButton.new()
	option_button.name = "ItemDropdown"
	option_button.position = Vector2(16, 16)
	option_button.size = Vector2(428, 32)
	panel.add_child(option_button)

	var give_button := Button.new()
	give_button.name = "GiveItemButton"
	give_button.text = "Give Item"
	give_button.position = Vector2(16, 58)
	give_button.size = Vector2(120, 34)
	give_button.pressed.connect(_give_selected_item)
	panel.add_child(give_button)

	var preview_button := Button.new()
	preview_button.name = "PreviewDropButton"
	preview_button.text = "Preview Drop"
	preview_button.position = Vector2(148, 58)
	preview_button.size = Vector2(130, 34)
	preview_button.pressed.connect(_preview_selected_item_drop)
	panel.add_child(preview_button)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(16, 100)
	status_label.size = Vector2(428, 34)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status_label)


func _get_debug_ui_parent() -> Node:
	var battle_scene := get_node_or_null("BattleScene")
	if battle_scene != null:
		var pause_overlay := battle_scene.get("pause_overlay") as Control
		if pause_overlay != null:
			return pause_overlay
	return self


func _populate_item_dropdown() -> void:
	option_button.clear()
	item_ids.clear()

	var database := get_node_or_null(ITEM_DATABASE_PATH)
	if database == null:
		status_label.text = "ItemDatabase autoload not found."
		return

	var sorted_items: Array = []
	for item in database.all_items:
		if item == null:
			continue
		sorted_items.append(item)
	sorted_items.sort_custom(_compare_items_alphabetically)

	for item in sorted_items:
		var label := "%s [%s]" % [item.display_name, item.rarity]
		option_button.add_item(label)
		item_ids.append(item.id)

	status_label.text = "Loaded %d items." % item_ids.size()


func _compare_items_alphabetically(left: ItemDefinition, right: ItemDefinition) -> bool:
	return left.display_name.nocasecmp_to(right.display_name) < 0


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
	var battle_scene := get_node_or_null("BattleScene")
	if battle_scene != null and battle_scene.has_method("_update_hud"):
		battle_scene.call("_update_hud")
	status_label.text = "Gave: %s" % item.display_name


func _preview_selected_item_drop() -> void:
	var item := _get_selected_item()
	if item == null:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		status_label.text = "Player not found yet."
		return

	var battle_scene := get_node_or_null("BattleScene")
	if battle_scene == null or not battle_scene.has_method("_spawn_shop_item_reward"):
		status_label.text = "BattleScene preview hook missing."
		return

	var spawn_position := player.global_position + PREVIEW_JAR_OFFSET
	_play_preview_jar_pop(spawn_position, battle_scene)
	battle_scene.call("_spawn_shop_item_reward", item, spawn_position, true)
	status_label.text = "Previewing: %s" % item.display_name


func _get_selected_item() -> ItemDefinition:
	if item_ids.is_empty():
		return null

	var database := get_node_or_null(ITEM_DATABASE_PATH)
	if database == null:
		status_label.text = "ItemDatabase autoload not found."
		return null

	var selected_index: int = option_button.selected
	if selected_index < 0 or selected_index >= item_ids.size():
		return null

	var item_id: StringName = item_ids[selected_index]
	var item: ItemDefinition = database.get_item(item_id)
	if item == null:
		status_label.text = "Unknown item: %s" % item_id
	return item


func _play_preview_jar_pop(spawn_position: Vector2, battle_scene: Node) -> void:
	var jar := Sprite2D.new()
	jar.name = "PreviewShopJar"
	jar.process_mode = Node.PROCESS_MODE_ALWAYS
	jar.global_position = spawn_position
	jar.z_index = 90
	if battle_scene.has_method("_get_container_texture"):
		jar.texture = battle_scene.call("_get_container_texture", 0)
	battle_scene.add_child(jar)

	var tween := jar.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(jar, "scale", Vector2(1.18, 1.18), 0.08)
	tween.tween_callback(_set_preview_jar_destroyed_texture.bind(jar, battle_scene))
	tween.tween_property(jar, "modulate:a", 0.0, 0.18)
	tween.finished.connect(Callable(jar, "queue_free"))


func _set_preview_jar_destroyed_texture(jar: Sprite2D, battle_scene: Node) -> void:
	if not is_instance_valid(jar):
		return
	if battle_scene.has_method("_get_container_destroyed_texture"):
		jar.texture = battle_scene.call("_get_container_destroyed_texture", 0)
