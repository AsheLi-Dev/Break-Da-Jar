extends SceneTree

const TRIGGERED_BUFF_EFFECT_SCRIPT := preload("res://systems/items/effects/TriggeredBuffEffect.gd")

var failures: Array[String] = []
var passed_assertions: int = 0


class TestPlayer:
	extends Node

	signal container_broken(container: Variant, info: Dictionary)
	signal hp_changed(current_hp: int, max_hp: int)

	var item_counts: Dictionary = {}
	var temporary_buffs := TemporaryBuffComponent.new()

	func _ready() -> void:
		add_child(temporary_buffs)
		temporary_buffs.setup(self)

	func get_temporary_buffs() -> TemporaryBuffComponent:
		return temporary_buffs

	func get_item_count(item_id: StringName) -> int:
		return int(item_counts.get(item_id, 0))


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("TriggeredBuffEffectTest: starting")
	await process_frame

	_test_timed_buff_on_signal()
	_test_direct_container_round_buff_filter()
	_test_shared_missing_hp_scaling()

	_finish()


func _test_timed_buff_on_signal() -> void:
	var player := _add_player()
	var effect := TRIGGERED_BUFF_EFFECT_SCRIPT.new()
	effect.configure_instance(&"adrenaline_shell", 0, 0)
	effect.event_name = &"container_broken"
	effect.mode = &"timed_stat_buff"
	effect.stat_name = &"attack_speed_bonus"
	effect.value = 0.05
	effect.duration = 3.0
	effect.max_stacks = 5
	effect.apply_to(player)

	player.emit_signal(&"container_broken", null, {})

	_assert(player.temporary_buffs.buffs.size() == 1, "Timed triggered buff adds one buff")
	var buff: Dictionary = player.temporary_buffs.buffs.values()[0]
	_assert(StringName(buff.get("stat_name")) == &"attack_speed_bonus", "Timed triggered buff stores stat")
	_assert(is_equal_approx(float(buff.get("time_left")), 3.0), "Timed triggered buff stores duration")
	player.queue_free()


func _test_direct_container_round_buff_filter() -> void:
	var player := _add_player()
	var effect := TRIGGERED_BUFF_EFFECT_SCRIPT.new()
	effect.configure_instance(&"splinter_fury", 0, 0)
	effect.event_name = &"container_broken"
	effect.mode = &"round_stat_buff"
	effect.stat_name = &"attack_damage_bonus"
	effect.value = 0.05
	effect.max_stacks = 99
	effect.requires_direct_player_container_break = true
	effect.apply_to(player)

	player.emit_signal(&"container_broken", null, {"source": "explosion"})
	_assert(player.temporary_buffs.buffs.is_empty(), "Direct container filter ignores indirect breaks")

	player.emit_signal(&"container_broken", null, {"source": "player_attack"})
	_assert(player.temporary_buffs.buffs.size() == 1, "Direct container filter accepts player breaks")
	player.queue_free()


func _test_shared_missing_hp_scaling() -> void:
	var player := _add_player()
	player.item_counts[&"martyrs_fortune"] = 2

	var first_effect := TRIGGERED_BUFF_EFFECT_SCRIPT.new()
	first_effect.configure_instance(&"martyrs_fortune", 0, 0)
	first_effect.stacking_rule = &"shared_missing_hp_scaled"
	first_effect.event_name = &"hp_changed"
	first_effect.mode = &"missing_hp_stat_bonus"
	first_effect.stat_name = &"luck"
	first_effect.value = 8.0
	first_effect.stack_value_bonus = 2.0
	first_effect.apply_to(player)

	var second_effect := TRIGGERED_BUFF_EFFECT_SCRIPT.new()
	second_effect.configure_instance(&"martyrs_fortune", 0, 1)
	second_effect.stacking_rule = &"shared_missing_hp_scaled"
	second_effect.event_name = &"hp_changed"
	second_effect.mode = &"missing_hp_stat_bonus"
	second_effect.stat_name = &"luck"
	second_effect.value = 8.0
	second_effect.stack_value_bonus = 2.0
	second_effect.apply_to(player)

	player.emit_signal(&"hp_changed", 70, 100)

	_assert(player.temporary_buffs.dynamic_bonuses.size() == 1, "Shared missing HP buff uses one listener")
	var bonus: Dictionary = player.temporary_buffs.dynamic_bonuses.values()[0]
	_assert(is_equal_approx(float(bonus.get("value")), 30.0), "Shared missing HP buff scales by copy count")
	player.queue_free()


func _add_player() -> TestPlayer:
	var player := TestPlayer.new()
	root.add_child(player)
	return player


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
		print("TriggeredBuffEffectTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("TriggeredBuffEffectTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
