extends Node2D

const ITEM_DATABASE_PATH := "/root/ItemDatabase"
const BATTLE_SCENE: PackedScene = preload("res://battlescene.tscn")
const PREVIEW_JAR_OFFSET := Vector2(180.0, 0.0)
const DEBUG_TALENT_POINTS := 999999
const CHARACTER_IDS: Array[StringName] = [&"paladin", &"necromancer", &"wizard"]

var item_ids: Array[StringName] = []
var character_button: OptionButton
var option_button: OptionButton
var status_label: Label
var debug_canvas: CanvasLayer


func _ready() -> void:
	_create_debug_ui()
	_populate_item_dropdown()


func _create_debug_ui() -> void:
	debug_canvas = CanvasLayer.new()
	debug_canvas.name = "ItemTestDebugLayer"
	debug_canvas.layer = 60
	debug_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(debug_canvas)

	var panel := Panel.new()
	panel.name = "ItemDebugUI"
	panel.position = Vector2(24, 116)
	panel.size = Vector2(460, 234)
	debug_canvas.add_child(panel)

	character_button = OptionButton.new()
	character_button.name = "CharacterDropdown"
	character_button.position = Vector2(16, 16)
	character_button.size = Vector2(250, 32)
	panel.add_child(character_button)
	_populate_character_dropdown()

	var apply_character_button := Button.new()
	apply_character_button.name = "ApplyCharacterButton"
	apply_character_button.text = "Apply Character"
	apply_character_button.position = Vector2(278, 16)
	apply_character_button.size = Vector2(150, 32)
	apply_character_button.pressed.connect(_apply_selected_character)
	panel.add_child(apply_character_button)

	option_button = OptionButton.new()
	option_button.name = "ItemDropdown"
	option_button.position = Vector2(16, 62)
	option_button.size = Vector2(428, 32)
	panel.add_child(option_button)

	var give_button := Button.new()
	give_button.name = "GiveItemButton"
	give_button.text = "Give Item"
	give_button.position = Vector2(16, 104)
	give_button.size = Vector2(120, 34)
	give_button.pressed.connect(_give_selected_item)
	panel.add_child(give_button)

	var preview_button := Button.new()
	preview_button.name = "PreviewDropButton"
	preview_button.text = "Preview Drop"
	preview_button.position = Vector2(148, 104)
	preview_button.size = Vector2(130, 34)
	preview_button.pressed.connect(_preview_selected_item_drop)
	panel.add_child(preview_button)

	var talent_tree_button := Button.new()
	talent_tree_button.name = "TalentTreeButton"
	talent_tree_button.text = "Talent Tree"
	talent_tree_button.position = Vector2(290, 104)
	talent_tree_button.size = Vector2(136, 34)
	talent_tree_button.pressed.connect(_open_debug_talent_tree)
	panel.add_child(talent_tree_button)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(16, 150)
	status_label.size = Vector2(428, 66)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status_label)


func _populate_character_dropdown() -> void:
	character_button.clear()
	for character_id in CHARACTER_IDS:
		character_button.add_item(_get_character_display_name(character_id))


func _get_character_display_name(character_id: StringName) -> String:
	match character_id:
		&"paladin":
			return "Paladin"
		&"necromancer":
			return "Necromancer"
		&"wizard":
			return "Wizard"
	return String(character_id)


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


func _apply_selected_character() -> void:
	var character_id := _get_selected_character_id()
	var session := get_node_or_null("/root/GameSession")
	if session != null and session.has_method("set_selected_character"):
		session.set_selected_character(character_id)

	if _clear_battle_scenes():
		await get_tree().process_frame

	var battle_scene := BATTLE_SCENE.instantiate()
	battle_scene.name = "BattleScene"
	add_child(battle_scene)
	move_child(debug_canvas, get_child_count() - 1)
	await get_tree().process_frame
	status_label.text = "Character applied: %s" % _get_character_display_name(character_id)


func _get_selected_character_id() -> StringName:
	var selected_index: int = character_button.selected
	if selected_index < 0 or selected_index >= CHARACTER_IDS.size():
		return CHARACTER_IDS[0]
	return CHARACTER_IDS[selected_index]


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

	var battle_scene := _get_battle_scene()
	if battle_scene == null or not battle_scene.has_method("_spawn_shop_item_reward"):
		status_label.text = "BattleScene preview hook missing."
		return

	var spawn_position := player.global_position + PREVIEW_JAR_OFFSET
	_play_preview_jar_pop(spawn_position, battle_scene)
	battle_scene.call("_spawn_shop_item_reward", item, spawn_position, true)
	status_label.text = "Previewing: %s" % item.display_name


func _open_debug_talent_tree() -> void:
	var battle_scene := _get_battle_scene()
	if battle_scene == null:
		battle_scene = _create_battle_scene()
		await get_tree().process_frame
		if battle_scene == null:
			status_label.text = "BattleScene talent tree hook missing."
			return

	var player := battle_scene.get("player") as Player
	if player == null:
		await get_tree().process_frame
		player = battle_scene.get("player") as Player
	if player == null:
		status_label.text = "Player not found yet."
		return

	if battle_scene.get("talent_tree_ui") == null:
		battle_scene.call("_create_talent_tree_ui")
	var talent_tree_ui := battle_scene.get("talent_tree_ui") as CanvasLayer
	if talent_tree_ui != null:
		talent_tree_ui.process_mode = Node.PROCESS_MODE_ALWAYS

	player.unspent_talent_points = DEBUG_TALENT_POINTS
	player.pending_talent_points = 0
	player.talent_points_changed.emit(player.unspent_talent_points, player.pending_talent_points)
	get_tree().paused = true
	battle_scene.call("_show_talent_tree")
	if talent_tree_ui != null and talent_tree_ui.has_method("refresh"):
		talent_tree_ui.call("refresh")
	status_label.text = "Talent tree opened with unlimited points."


func _get_battle_scene() -> Node:
	var battle_scene := get_node_or_null("BattleScene")
	if battle_scene != null:
		return battle_scene
	return find_child("BattleScene", false, false)


func _clear_battle_scenes() -> bool:
	var removed := false
	for child in get_children():
		var node := child as Node
		if node == null or node == debug_canvas:
			continue
		if node.scene_file_path == "res://battlescene.tscn" or String(node.name).begins_with("BattleScene"):
			remove_child(node)
			node.queue_free()
			removed = true
	return removed


func _create_battle_scene() -> Node:
	_clear_battle_scenes()
	var battle_scene := BATTLE_SCENE.instantiate()
	if battle_scene == null:
		return null
	battle_scene.name = "BattleScene"
	add_child(battle_scene)
	if debug_canvas != null:
		move_child(debug_canvas, get_child_count() - 1)
	return battle_scene


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
