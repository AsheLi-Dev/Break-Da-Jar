extends SceneTree

const PERIODIC_EFFECT_SCRIPT := preload("res://systems/items/effects/PeriodicEffect.gd")

var failures: Array[String] = []
var passed_assertions: int = 0


class TestPlayer:
	extends Node2D

	var item_counts: Dictionary = {}

	func get_item_count(item_id: StringName) -> int:
		return int(item_counts.get(item_id, 0))


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("PeriodicEffectTest: starting")
	await process_frame

	_test_shared_runtime_effect_attaches_once()

	_finish()


func _test_shared_runtime_effect_attaches_once() -> void:
	var player := TestPlayer.new()
	player.item_counts[&"auto_fireball"] = 2
	root.add_child(player)

	var first_effect := PERIODIC_EFFECT_SCRIPT.new()
	first_effect.configure_instance(&"auto_fireball", 0, 0)
	first_effect.stacking_rule = &"shared_runtime_scaled"
	first_effect.mode = &"periodic_auto_fireball"
	first_effect.value = 1.0
	first_effect.radius = 600.0
	first_effect.damage_scale = 0.5
	first_effect.interval = 5.0
	first_effect.apply_to(player)

	var second_effect := PERIODIC_EFFECT_SCRIPT.new()
	second_effect.configure_instance(&"auto_fireball", 0, 1)
	second_effect.stacking_rule = &"shared_runtime_scaled"
	second_effect.mode = &"periodic_auto_fireball"
	second_effect.apply_to(player)

	var runtime_nodes := _get_runtime_nodes(player)
	_assert(runtime_nodes.size() == 1, "Shared periodic effect creates one runtime node")
	if not runtime_nodes.is_empty():
		var node := runtime_nodes[0]
		_assert(StringName(node.get("effect_type")) == &"periodic_auto_fireball", "Runtime node receives mode")
		_assert(is_equal_approx(float(node.get("radius")), 600.0), "Runtime node receives radius")
		_assert(is_equal_approx(float(node.get("internal_cooldown")), 5.0), "Runtime node receives interval")

	player.queue_free()


func _get_runtime_nodes(player: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in player.get_children():
		if child.name == "ItemRuntimeEffectNode":
			result.append(child)
	return result


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
		print("PeriodicEffectTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("PeriodicEffectTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
