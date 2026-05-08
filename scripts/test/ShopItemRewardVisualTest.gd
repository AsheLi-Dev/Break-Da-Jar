extends SceneTree

const SHOP_ITEM_REWARD_VISUAL_SCRIPT := preload("res://systems/items/ShopItemRewardVisual.gd")

var failures: Array[String] = []
var passed_assertions: int = 0
var collected_item: ItemDefinition


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("ShopItemRewardVisualTest: starting")
	await process_frame

	var item := ItemDefinition.new()
	item.id = &"test_shop_item"
	item.display_name = "Test Shop Item"

	var target := Node2D.new()
	target.global_position = Vector2.ZERO
	root.add_child(target)

	var visual := SHOP_ITEM_REWARD_VISUAL_SCRIPT.new()
	visual.hover_duration = 0.05
	visual.fly_speed = 1200.0
	visual.setup(item, Vector2.ZERO, target, Callable(self, "_on_item_collected"))
	root.add_child(visual)

	await process_frame
	_assert(collected_item == null, "Shop item reward is not collected immediately")

	await create_timer(0.2).timeout
	_assert(collected_item == item, "Shop item reward collects after hover and fly")
	_assert(not is_instance_valid(visual), "Shop item reward visual frees itself after collection")

	target.queue_free()
	await process_frame
	_finish()


func _on_item_collected(item: ItemDefinition) -> void:
	collected_item = item


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
		print("ShopItemRewardVisualTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("ShopItemRewardVisualTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
