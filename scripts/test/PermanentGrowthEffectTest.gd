extends SceneTree

const PERMANENT_GROWTH_EFFECT := preload("res://systems/items/effects/PermanentGrowthEffect.gd")

class FakePlayer:
	extends Node2D

	signal enemy_killed(enemy: Node)
	signal container_broken(container: Node, attack_info: Dictionary)
	signal damage_taken(final_damage_taken: float)
	signal round_started(round_index: int)
	signal round_ended()

	var stats := StatsComponent.new()
	var item_counts: Dictionary = {}
	var unique_permanent_growth_item_count: int = 0

	func get_stats() -> StatsComponent:
		return stats

	func get_item_count(item_id: StringName) -> int:
		return int(item_counts.get(item_id, 0))

	func get_unique_permanent_growth_item_count() -> int:
		return unique_permanent_growth_item_count


class FakeEnemy:
	extends Node

	var last_attack_info: Dictionary = {}


var failures: Array[String] = []
var passed_assertions: int = 0
var player: FakePlayer


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("PermanentGrowthEffectTest: starting")
	await process_frame

	_test_no_damage_round_growth()
	_test_container_round_cap_and_stack_cap()
	_test_critical_state_kill_growth()
	_test_evergrowth_multiplier()

	_finish()


func _reset_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = FakePlayer.new()
	root.add_child(player)


func _make_growth_effect(
	trigger: StringName,
	stat_name: StringName,
	growth_value: float,
	item_id: StringName = &"test_item"
):
	var effect: Resource = PERMANENT_GROWTH_EFFECT.new()
	effect.set("trigger", trigger)
	effect.set("growth_stat", stat_name)
	effect.set("growth_value", growth_value)
	effect.call("configure_instance", item_id, 0, 0)
	player.item_counts[item_id] = int(player.item_counts.get(item_id, 1))
	effect.call("apply_to", player)
	return effect


func _test_no_damage_round_growth() -> void:
	_reset_player()
	var effect: Resource = _make_growth_effect(&"round_ended", &"bonus_move_speed_flat", 10.0, &"untouched_stride")
	effect.set("requires_no_damage_round", true)
	effect.call("apply_to", player)

	player.round_started.emit(1)
	player.round_ended.emit()
	_assert(is_equal_approx(player.stats.bonus_move_speed_flat, 10.0), "No-damage round grants move speed")

	player.round_started.emit(2)
	player.damage_taken.emit(1.0)
	player.round_ended.emit()
	_assert(is_equal_approx(player.stats.bonus_move_speed_flat, 10.0), "Damaged round does not grant move speed")


func _test_container_round_cap_and_stack_cap() -> void:
	_reset_player()
	player.item_counts[&"jarheart_seed"] = 2
	var effect: Resource = _make_growth_effect(&"container_broken", &"max_hp", 1.0, &"jarheart_seed")
	effect.set("round_cap", 10.0)
	effect.set("stack_round_cap_bonus", 5.0)
	effect.set("requires_direct_player_attack", true)
	effect.call("apply_to", player)

	player.round_started.emit(1)
	for index in range(20):
		var container := Node.new()
		player.container_broken.emit(container, {"source": "player_attack", "direct": true})
		container.free()
	_assert(player.stats.max_hp == 115, "Container growth respects stacked round cap")


func _test_critical_state_kill_growth() -> void:
	_reset_player()
	var noncrit: Resource = _make_growth_effect(&"enemy_killed", &"critical_chance", 0.01, &"patient_whetstone")
	noncrit.set("round_cap", 0.05)
	noncrit.set("stack_round_cap_bonus", 0.03)
	noncrit.set("requires_direct_player_attack", true)
	noncrit.set("requires_non_critical", true)
	noncrit.call("apply_to", player)

	var crit: Resource = _make_growth_effect(&"enemy_killed", &"critical_damage_bonus", 0.02, &"crimson_grindstone")
	crit.set("round_cap", 0.1)
	crit.set("stack_round_cap_bonus", 0.05)
	crit.set("requires_direct_player_attack", true)
	crit.set("requires_critical", true)
	crit.call("apply_to", player)

	var normal_enemy := FakeEnemy.new()
	normal_enemy.last_attack_info = {"source": "player_attack", "direct": true}
	player.enemy_killed.emit(normal_enemy)
	normal_enemy.free()

	var crit_enemy := FakeEnemy.new()
	crit_enemy.last_attack_info = {"source": "player_attack", "direct": true, "critical": true}
	player.enemy_killed.emit(crit_enemy)
	crit_enemy.free()

	_assert(is_equal_approx(player.stats.critical_chance, 0.01), "Non-critical kill grants crit chance only")
	_assert(is_equal_approx(player.stats.critical_damage_bonus, 0.02), "Critical kill grants crit damage only")


func _test_evergrowth_multiplier() -> void:
	_reset_player()
	player.unique_permanent_growth_item_count = 2
	player.stats.permanent_growth_bonus_per_unique = 0.5

	var elite: Resource = _make_growth_effect(&"enemy_killed", &"luck", 1.0, &"elite_luck_charm")
	elite.set("requires_elite", true)
	elite.call("apply_to", player)

	var enemy := EnemyBase.new()
	enemy.is_elite = true
	player.enemy_killed.emit(enemy)
	enemy.free()
	_assert(player.stats.luck == 2, "Evergrowth multiplies integer growth and floors")

	var noncrit: Resource = _make_growth_effect(&"enemy_killed", &"critical_chance", 0.01, &"patient_whetstone")
	noncrit.set("requires_direct_player_attack", true)
	noncrit.set("requires_non_critical", true)
	noncrit.call("apply_to", player)

	var normal_enemy := FakeEnemy.new()
	normal_enemy.last_attack_info = {"source": "player_attack", "direct": true}
	player.enemy_killed.emit(normal_enemy)
	normal_enemy.free()
	_assert(is_equal_approx(player.stats.critical_chance, 0.02), "Evergrowth multiplies percent growth by percentage points")


func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_assertions += 1
	else:
		failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	if failures.is_empty():
		print("PermanentGrowthEffectTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("PermanentGrowthEffectTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
