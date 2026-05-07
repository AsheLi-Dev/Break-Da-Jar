extends SceneTree

const MISSING_HP_SUMMON_EFFECT_SCRIPT := preload("res://systems/items/effects/MissingHpSummonEffect.gd")
const SKELETON_ARCHER_SCRIPT := preload("res://systems/summons/SkeletonArcher.gd")
const SKELETON_ARCHER_SCENE: PackedScene = preload("res://scenes/summons/SkeletonArcher.tscn")

var failures: Array[String] = []
var passed_assertions: int = 0


class TestPlayer:
	extends Node2D

	signal hp_changed(current_hp: int, max_hp: int)

	var hp: float = 100.0
	var max_hp: float = 100.0
	var fire_rate: float = 100.0
	var item_counts: Dictionary = {}
	var stats := StatsComponent.new()
	var dealt_damage: float = 0.0

	func get_item_count(item_id: StringName) -> int:
		return int(item_counts.get(item_id, 0))

	func get_base_attack_damage() -> float:
		return 20.0

	func get_stats() -> StatsComponent:
		return stats

	func deal_player_damage_to_enemy(enemy: Node, raw_damage: float, attack_info: Dictionary = {}) -> float:
		dealt_damage += raw_damage
		if enemy.has_method("take_damage"):
			return enemy.take_damage(raw_damage, self, attack_info)
		return raw_damage


class TestEnemy:
	extends Node2D

	var damage_taken: float = 0.0

	func _ready() -> void:
		add_to_group("enemy")

	func take_damage(amount: float, _source: Node = null, _attack_info: Dictionary = {}) -> float:
		damage_taken += amount
		return amount


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("MissingHpSummonEffectTest: starting")
	await process_frame

	await _test_missing_hp_syncs_summon_count()
	await _test_stack_reduces_missing_hp_requirement()
	await _test_skeleton_archer_deals_instant_damage()
	await _test_skeleton_archer_uses_player_scale_and_eight_directions()

	_finish()


func _test_missing_hp_syncs_summon_count() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var player := TestPlayer.new()
	player.item_counts[&"marrow_bow_choir"] = 1
	scene.add_child(player)

	var effect := MISSING_HP_SUMMON_EFFECT_SCRIPT.new()
	effect.configure_instance(&"marrow_bow_choir", 0, 0)
	effect.summon_scene = SKELETON_ARCHER_SCENE
	effect.missing_hp_per_summon = 50.0
	effect.apply_to(player)

	player.hp = 40.0
	player.emit_signal(&"hp_changed", 40, 100)
	await process_frame
	_assert(_count_skeleton_archers(scene) == 1, "Missing HP summons one Skeleton Archer at 60 missing HP")

	player.hp = 100.0
	player.emit_signal(&"hp_changed", 100, 100)
	await process_frame
	await process_frame
	_assert(_count_skeleton_archers(scene) == 0, "Missing HP removes Skeleton Archers after healing")

	scene.queue_free()
	await process_frame
	current_scene = null


func _test_stack_reduces_missing_hp_requirement() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var player := TestPlayer.new()
	player.item_counts[&"marrow_bow_choir"] = 5
	scene.add_child(player)

	var effect := MISSING_HP_SUMMON_EFFECT_SCRIPT.new()
	effect.configure_instance(&"marrow_bow_choir", 0, 0)
	effect.summon_scene = SKELETON_ARCHER_SCENE
	effect.missing_hp_per_summon = 50.0
	effect.stack_missing_hp_reduction = 10.0
	effect.minimum_missing_hp_per_summon = 10.0
	effect.apply_to(player)

	player.hp = 70.0
	player.emit_signal(&"hp_changed", 70, 100)
	await process_frame
	_assert(_count_skeleton_archers(scene) == 3, "Five copies reduce Skeleton Archer requirement to 10 missing HP")

	player.item_counts[&"marrow_bow_choir"] = 6
	effect.on_item_count_changed(&"marrow_bow_choir")
	await process_frame
	_assert(_count_skeleton_archers(scene) == 3, "Skeleton Archer requirement is capped at minimum 10 missing HP")

	scene.queue_free()
	await process_frame
	current_scene = null


func _test_skeleton_archer_deals_instant_damage() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var player := TestPlayer.new()
	scene.add_child(player)
	var enemy := TestEnemy.new()
	enemy.global_position = Vector2(80.0, 0.0)
	scene.add_child(enemy)

	var archer := SKELETON_ARCHER_SCENE.instantiate()
	scene.add_child(archer)
	archer.call("setup", player, Vector2.ZERO)
	archer.global_position = Vector2.ZERO

	for _index in range(20):
		archer.call("_process", 0.1)
		await process_frame

	_assert(enemy.damage_taken > 0.0, "Skeleton Archer deals damage during attack active frame")
	_assert(is_equal_approx(float(archer.call("_get_attack_damage")), 20.0), "Skeleton Archer inherits full player attack damage")
	_assert(is_equal_approx(float(archer.call("_get_attack_interval")), 1.0 / 75.0), "Skeleton Archer inherits 75 percent player attack speed")

	scene.queue_free()
	await process_frame
	current_scene = null


func _test_skeleton_archer_uses_player_scale_and_eight_directions() -> void:
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene

	var player := TestPlayer.new()
	scene.add_child(player)

	var archer := SKELETON_ARCHER_SCENE.instantiate()
	scene.add_child(archer)
	archer.call("setup", player, Vector2.ZERO)
	await process_frame

	var sprite := archer.get_node_or_null("Sprite2D") as Sprite2D
	_assert(sprite != null and sprite.scale == Vector2(2.0, 2.0), "Skeleton Archer uses player sprite scale")

	var directions: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2(1.0, 1.0),
		Vector2.DOWN,
		Vector2(-1.0, 1.0),
		Vector2.LEFT,
		Vector2(-1.0, -1.0),
		Vector2.UP,
		Vector2(1.0, -1.0),
	]
	for index in range(directions.size()):
		var direction := directions[index].normalized()
		_assert(int(archer.call("_get_direction_row", direction)) == index, "Skeleton Archer direction row %d matches player mapping" % index)

	archer.set("facing_direction", Vector2.RIGHT)
	archer.call("_set_frame", 0)
	_assert(sprite.frame_coords == Vector2i(0, 0), "Skeleton Archer faces right on row 0")
	archer.set("facing_direction", Vector2.UP)
	archer.call("_set_frame", 0)
	_assert(sprite.frame_coords == Vector2i(0, 6), "Skeleton Archer updates direction row even when frame is unchanged")

	scene.queue_free()
	await process_frame
	current_scene = null


func _count_skeleton_archers(node: Node) -> int:
	var count := 1 if node.get_script() == SKELETON_ARCHER_SCRIPT else 0
	for child in node.get_children():
		count += _count_skeleton_archers(child)
	return count


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
		print("MissingHpSummonEffectTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("MissingHpSummonEffectTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
