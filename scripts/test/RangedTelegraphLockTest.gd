extends SceneTree

const ACID_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/AcidZombie.tscn")
const ZOMBIE_FIREMAN_SCENE: PackedScene = preload("res://scenes/enemies/ZombieFireman.tscn")
const ELITE_BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/EliteBrute.tscn")

var failures: Array[String] = []
var passed_assertions: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("RangedTelegraphLockTest: starting")
	await process_frame

	await _test_aim_line_stays_locked(ACID_ZOMBIE_SCENE, "AimLine", "_start_aim", "_face_target", "Acid Zombie")
	await _test_aim_line_stays_locked(ZOMBIE_FIREMAN_SCENE, "AimLine", "_start_aim", "_face_target", "Zombie Fireman")
	await _test_aim_line_starts_in_locked_world_direction(ELITE_BRUTE_SCENE, "RangedWarning", "_start_ranged_attack", "_face_target", "Elite Brute")

	await _finish()


func _test_aim_line_stays_locked(
	scene: PackedScene,
	line_name: String,
	start_method: String,
	face_method: String,
	label: String
) -> void:
	var target := _make_target(Vector2(180.0, 0.0))
	var enemy := _make_enemy(scene, Vector2.ZERO, target)
	enemy.call(face_method, target.global_position)
	enemy.call(start_method)

	var locked_direction := Vector2(enemy.get("locked_attack_direction")).normalized()
	target.global_position = Vector2(0.0, 180.0)
	enemy.call("_physics_process", 0.1)

	var line := enemy.get_node(line_name) as Line2D
	var line_direction := _get_world_line_direction(line)
	_assert(line_direction.dot(locked_direction) > 0.999, "%s telegraph keeps the locked world direction while target moves" % label)

	_cleanup(enemy, target)
	await process_frame


func _test_aim_line_starts_in_locked_world_direction(
	scene: PackedScene,
	line_name: String,
	start_method: String,
	face_method: String,
	label: String
) -> void:
	var target := _make_target(Vector2(0.0, 180.0))
	var enemy := _make_enemy(scene, Vector2.ZERO, target)
	enemy.call(face_method, target.global_position)
	enemy.call(start_method)

	var locked_direction := Vector2(enemy.get("locked_attack_direction")).normalized()
	var line := enemy.get_node(line_name) as Line2D
	var line_direction := _get_world_line_direction(line)
	_assert(line_direction.dot(locked_direction) > 0.999, "%s telegraph starts in the locked world direction" % label)

	_cleanup(enemy, target)
	await process_frame


func _make_target(position: Vector2) -> Node2D:
	var target := Node2D.new()
	target.name = "TelegraphLockTarget"
	target.global_position = position
	target.add_to_group("player")
	root.add_child(target)
	return target


func _make_enemy(scene: PackedScene, position: Vector2, target: Node2D) -> EnemyBase:
	var enemy := scene.instantiate() as EnemyBase
	enemy.global_position = position
	enemy.move_speed = 0.0
	enemy.attack_cooldown = 9999.0
	enemy.target = target
	root.add_child(enemy)
	return enemy


func _get_world_line_direction(line: Line2D) -> Vector2:
	var start := line.to_global(line.get_point_position(0))
	var end := line.to_global(line.get_point_position(1))
	return (end - start).normalized()


func _cleanup(enemy: Node, target: Node) -> void:
	if is_instance_valid(enemy):
		enemy.queue_free()
	if is_instance_valid(target):
		target.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_assertions += 1
	else:
		failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("RangedTelegraphLockTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("RangedTelegraphLockTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
