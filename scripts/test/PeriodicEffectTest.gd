extends SceneTree

const PERIODIC_EFFECT_SCRIPT := preload("res://systems/items/effects/PeriodicEffect.gd")

var failures: Array[String] = []
var passed_assertions: int = 0


class TestPlayer:
	extends Node2D

	var item_counts: Dictionary = {}
	var retribution_casts: int = 0
	var last_retribution_position: Vector2 = Vector2.ZERO
	var last_damage_multiplier: float = 0.0
	var last_area_multiplier: float = 0.0

	func get_item_count(item_id: StringName) -> int:
		return int(item_counts.get(item_id, 0))

	func trigger_periodic_holy_retribution(target_position: Vector2, damage_multiplier: float, area_multiplier: float) -> void:
		retribution_casts += 1
		last_retribution_position = target_position
		last_damage_multiplier = damage_multiplier
		last_area_multiplier = area_multiplier


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("PeriodicEffectTest: starting")
	await process_frame

	_test_shared_runtime_effect_attaches_once()
	_test_periodic_holy_retribution_targets_nearest_enemy()

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


func _test_periodic_holy_retribution_targets_nearest_enemy() -> void:
	var player := TestPlayer.new()
	player.item_counts[&"judgment_bell"] = 2
	var far_enemy := Node2D.new()
	var near_enemy := Node2D.new()
	far_enemy.add_to_group("enemy")
	near_enemy.add_to_group("enemy")
	far_enemy.global_position = Vector2(300.0, 0.0)
	near_enemy.global_position = Vector2(40.0, 0.0)
	root.add_child(player)
	root.add_child(far_enemy)
	root.add_child(near_enemy)

	var effect := PERIODIC_EFFECT_SCRIPT.new()
	effect.configure_instance(&"judgment_bell", 0, 0)
	effect.stacking_rule = &"shared_runtime_scaled"
	effect.mode = &"periodic_holy_retribution"
	effect.value = 1.0
	effect.radius = 99999.0
	effect.damage_scale = 0.5
	effect.interval = 5.0
	effect.apply_to(player)

	var runtime_nodes := _get_runtime_nodes(player)
	_assert(runtime_nodes.size() == 1, "Holy Retribution item creates one runtime node")
	if not runtime_nodes.is_empty():
		var node := runtime_nodes[0]
		node.set("periodic_remaining", 0.0)
		node.call("_process", 0.1)
		_assert(player.retribution_casts == 1, "Holy Retribution periodic effect casts once when ready")
		_assert(player.last_retribution_position.is_equal_approx(near_enemy.global_position), "Holy Retribution targets nearest enemy")
		_assert(is_equal_approx(player.last_damage_multiplier, 1.5), "Holy Retribution duplicate adds 50% damage")
		_assert(is_equal_approx(player.last_area_multiplier, 1.5), "Holy Retribution duplicate adds 50% area")

	player.queue_free()
	far_enemy.queue_free()
	near_enemy.queue_free()


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
