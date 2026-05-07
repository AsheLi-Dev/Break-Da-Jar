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

	var panel := scene.get_node_or_null("BattleScene/HUD/PauseOverlay/ItemDebugUI") as Control
	var option_button := scene.get_node_or_null("BattleScene/HUD/PauseOverlay/ItemDebugUI/ItemDropdown") as OptionButton
	var give_button := scene.get_node_or_null("BattleScene/HUD/PauseOverlay/ItemDebugUI/GiveItemButton") as Button
	_assert(panel != null, "Item debug UI is attached to pause overlay")
	_assert(panel != null and panel.can_process(), "Item debug panel can process while paused")
	_assert(option_button != null and option_button.can_process(), "Item dropdown can process while paused")
	_assert(give_button != null and give_button.can_process(), "Give item button can process during pause")

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

	if battle_scene != null:
		battle_scene.call("_set_paused", false)
	current_scene = null
	scene.queue_free()
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
