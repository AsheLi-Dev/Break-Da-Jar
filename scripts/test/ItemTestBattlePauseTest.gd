extends SceneTree

const ITEM_TEST_BATTLE: PackedScene = preload("res://scenes/test/ItemTestBattle.tscn")

var failures: Array[String] = []
var passed_assertions: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("ItemTestBattlePauseTest: starting")
	await process_frame

	var scene := ITEM_TEST_BATTLE.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	var battle_scene := scene.get_node_or_null("BattleScene")
	_assert(battle_scene != null, "ItemTestBattle instantiates BattleScene")
	if battle_scene != null:
		battle_scene.call("_set_paused", true)
	await process_frame

	var panel := scene.get_node_or_null("ItemTestDebugLayer/ItemDebugUI") as Control
	var option_button := scene.get_node_or_null("ItemTestDebugLayer/ItemDebugUI/ItemDropdown") as OptionButton
	var give_button := scene.get_node_or_null("ItemTestDebugLayer/ItemDebugUI/GiveItemButton") as Button
	var talent_tree_button := scene.get_node_or_null("ItemTestDebugLayer/ItemDebugUI/TalentTreeButton") as Button
	var apply_character_button := scene.get_node_or_null("ItemTestDebugLayer/ItemDebugUI/ApplyCharacterButton") as Button
	_assert(panel != null, "Item debug UI is attached to debug layer")
	_assert(panel != null and panel.can_process(), "Item debug panel can process while paused")
	_assert(option_button != null and option_button.can_process(), "Item dropdown can process while paused")
	_assert(give_button != null and give_button.can_process(), "Give item button can process during pause")
	_assert(talent_tree_button != null and talent_tree_button.can_process(), "Talent tree button can process during pause")

	var item_ids: Array = scene.get("item_ids")
	var player := root.get_tree().get_first_node_in_group("player")
	_assert(player != null, "Player exists in ItemTestBattle")
	_assert(not item_ids.is_empty(), "ItemTestBattle item list is populated")
	if give_button != null and player != null and not item_ids.is_empty():
		var item_id: StringName = item_ids[0]
		var before_count := int(player.call("get_item_count", item_id))
		give_button.emit_signal("pressed")
		var after_count := int(player.call("get_item_count", item_id))
		_assert(after_count == before_count + 1, "Give item button grants item while paused")

	if talent_tree_button != null and battle_scene != null and player != null:
		talent_tree_button.emit_signal("pressed")
		var talent_tree := battle_scene.get("talent_tree_ui") as Node
		var talent_player: Object = battle_scene.get("player") as Object
		var talent_point_label: Label = talent_tree.get_node_or_null("TalentTreePanel/TalentPointLabel") as Label if talent_tree != null else null
		_assert(talent_tree != null, "Talent tree button creates or finds TalentTree UI")
		_assert(talent_tree != null and bool(talent_tree.call("is_open")), "Talent tree button opens TalentTree UI")
		_assert(talent_player != null and int(talent_player.get("unspent_talent_points")) == 999999, "Talent tree button grants unlimited talent points to the active BattleScene player")
		_assert(talent_point_label != null and talent_point_label.text.find("999999") >= 0, "Talent tree point label shows unlimited points")

	if talent_tree_button != null and battle_scene != null:
		root.get_tree().paused = false
		battle_scene.queue_free()
		await process_frame
		talent_tree_button.emit_signal("pressed")
		await process_frame
		battle_scene = scene.get_node_or_null("BattleScene")
		var status_label := scene.get_node_or_null("ItemTestDebugLayer/ItemDebugUI/StatusLabel") as Label
		var recreated_player: Object = battle_scene.get("player") as Object if battle_scene != null else null
		_assert(battle_scene != null, "Talent tree button recreates missing BattleScene")
		_assert(status_label != null and status_label.text != "BattleScene talent tree hook missing.", "Talent tree button does not report missing hook when BattleScene was absent")
		_assert(recreated_player != null and int(recreated_player.get("unspent_talent_points")) == 999999, "Talent tree button grants unlimited points after recreating BattleScene")

	if apply_character_button != null:
		apply_character_button.emit_signal("pressed")
		await process_frame
		await process_frame
		var battle_scene_count := 0
		for child in scene.get_children():
			var node := child as Node
			if node != null and (node.scene_file_path == "res://battlescene.tscn" or String(node.name).begins_with("BattleScene")):
				battle_scene_count += 1
		_assert(battle_scene_count == 1, "Apply Character replaces the old BattleScene instead of leaving duplicate characters and containers")
		battle_scene = scene.get_node_or_null("BattleScene")

	if battle_scene != null:
		battle_scene.call("_set_paused", false)
	root.get_tree().paused = false
	current_scene = null
	if scene.get_parent() != null:
		scene.get_parent().remove_child(scene)
	scene.free()
	for _index in range(12):
		await process_frame

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_assertions += 1
	else:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)
	push_error("FAIL: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("ItemTestBattlePauseTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("ItemTestBattlePauseTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
