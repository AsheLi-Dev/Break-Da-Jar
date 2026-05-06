extends SceneTree

const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")

var failures: Array[String] = []
var passed_assertions: int = 0
var test_root: Node2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("EffectTargetingTest: starting")
	await process_frame

	test_root = Node2D.new()
	test_root.name = "EffectTargetingTestRoot"
	root.add_child(test_root)
	current_scene = test_root
	await process_frame

	_test_empty_queries()
	await _test_enemy_queries()
	await _test_container_queries()
	await _cleanup_root()

	_finish()


func _test_empty_queries() -> void:
	_assert(EFFECT_TARGETING.enemies_near(test_root, Vector2.ZERO, 100.0).is_empty(), "Empty enemy range query returns empty")
	_assert(EFFECT_TARGETING.nearest_enemy(test_root, Vector2.ZERO, 100.0) == null, "Empty nearest enemy query returns null")
	_assert(EFFECT_TARGETING.nearest_container(test_root, Vector2.ZERO, 100.0) == null, "Empty nearest container query returns null")
	_assert(EFFECT_TARGETING.enemies_near(null, Vector2.ZERO, 100.0).is_empty(), "Null owner enemy range query is safe")
	_assert(EFFECT_TARGETING.nearest_enemy(null, Vector2.ZERO, 100.0) == null, "Null owner nearest enemy query is safe")
	_assert(EFFECT_TARGETING.nearest_container(null, Vector2.ZERO, 100.0) == null, "Null owner nearest container query is safe")


func _test_enemy_queries() -> void:
	var far_enemy := _make_group_node("FarEnemy", "enemy", Vector2(220, 0))
	var mid_enemy := _make_group_node("MidEnemy", "enemy", Vector2(100, 0))
	var close_enemy := _make_group_node("CloseEnemy", "enemy", Vector2(40, 0))
	await process_frame

	_assert(EFFECT_TARGETING.nearest_enemy(test_root, Vector2.ZERO, 150.0) == close_enemy, "Nearest enemy returns closest in range")
	_assert(EFFECT_TARGETING.enemies_near(test_root, Vector2.ZERO, 150.0).size() == 2, "Enemy range query excludes out-of-range enemies")
	_assert(EFFECT_TARGETING.nearest_enemy(test_root, Vector2.ZERO, 150.0, [close_enemy]) == mid_enemy, "Nearest enemy respects exclude list")
	_assert(EFFECT_TARGETING.nearest_enemy(test_root, Vector2.ZERO, 20.0) == null, "Nearest enemy returns null when all enemies are out of range")

	far_enemy.queue_free()
	mid_enemy.queue_free()
	close_enemy.queue_free()
	await process_frame
	await process_frame


func _test_container_queries() -> void:
	var far_container := _make_group_node("FarContainer", "container", Vector2(260, 0))
	var close_container := _make_group_node("CloseContainer", "container", Vector2(70, 0))
	await process_frame

	_assert(EFFECT_TARGETING.nearest_container(test_root, Vector2.ZERO, 200.0) == close_container, "Nearest container returns closest in range")
	_assert(EFFECT_TARGETING.nearest_container(test_root, Vector2.ZERO, 300.0, [close_container]) == far_container, "Nearest container respects exclude list")
	_assert(EFFECT_TARGETING.nearest_container(test_root, Vector2.ZERO, 40.0) == null, "Nearest container returns null when all containers are out of range")

	far_container.queue_free()
	close_container.queue_free()
	await process_frame
	await process_frame


func _make_group_node(node_name: String, group_name: String, node_position: Vector2) -> Node2D:
	var node := Node2D.new()
	node.name = node_name
	node.global_position = node_position
	node.add_to_group(group_name)
	test_root.add_child(node)
	return node


func _cleanup_root() -> void:
	current_scene = null
	if test_root != null and is_instance_valid(test_root):
		root.remove_child(test_root)
		test_root.queue_free()
		await process_frame
		await process_frame
	test_root = null


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
		print("EffectTargetingTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("EffectTargetingTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
