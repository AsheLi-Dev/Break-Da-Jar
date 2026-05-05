extends Node
class_name TemporaryBuffComponent

var owner_player: Node
var buffs: Dictionary = {}
var dynamic_bonuses: Dictionary = {}


func setup(player: Node) -> void:
	owner_player = player


func _process(delta: float) -> void:
	for buff_id in buffs.keys().duplicate():
		var buff: Dictionary = buffs[buff_id]
		if bool(buff.get("round", false)):
			continue

		buff["time_left"] = float(buff.get("time_left", 0.0)) - delta
		if float(buff["time_left"]) <= 0.0:
			_remove_buff(buff_id)
		else:
			buffs[buff_id] = buff


func add_timed_stat_buff(buff_id: StringName, stat_name: StringName, value_per_stack: float, duration: float, max_stacks: int, refresh_duration: bool = true) -> void:
	var buff: Dictionary = buffs.get(buff_id, {})
	var old_value: float = float(buff.get("applied_value", 0.0))
	var stacks: int = mini(int(buff.get("stacks", 0)) + 1, maxi(max_stacks, 1))
	if old_value != 0.0:
		_apply_stat(stat_name, -old_value)

	var new_value: float = value_per_stack * float(stacks)
	_apply_stat(stat_name, new_value)
	buff = {
		"stat_name": stat_name,
		"value_per_stack": value_per_stack,
		"stacks": stacks,
		"max_stacks": max_stacks,
		"applied_value": new_value,
		"time_left": duration if refresh_duration else float(buff.get("time_left", duration)),
		"round": false,
	}
	buffs[buff_id] = buff
	print("Timed buff added/refreshed: %s stacks=%d" % [buff_id, stacks])


func add_round_stat_buff(buff_id: StringName, stat_name: StringName, value_per_stack: float, max_stacks: int) -> void:
	var buff: Dictionary = buffs.get(buff_id, {})
	var old_value: float = float(buff.get("applied_value", 0.0))
	var stacks: int = mini(int(buff.get("stacks", 0)) + 1, maxi(max_stacks, 1))
	if old_value != 0.0:
		_apply_stat(stat_name, -old_value)

	var new_value: float = value_per_stack * float(stacks)
	_apply_stat(stat_name, new_value)
	buffs[buff_id] = {
		"stat_name": stat_name,
		"value_per_stack": value_per_stack,
		"stacks": stacks,
		"max_stacks": max_stacks,
		"applied_value": new_value,
		"round": true,
	}
	print("Round buff added: %s stacks=%d" % [buff_id, stacks])


func set_dynamic_stat_bonus(bonus_id: StringName, stat_name: StringName, value: float) -> void:
	var old: Dictionary = dynamic_bonuses.get(bonus_id, {})
	if not old.is_empty():
		_apply_stat(StringName(old["stat_name"]), -float(old["value"]))

	if value != 0.0:
		_apply_stat(stat_name, value)
		dynamic_bonuses[bonus_id] = {"stat_name": stat_name, "value": value}
	else:
		dynamic_bonuses.erase(bonus_id)

	print("Dynamic bonus updated: %s value=%s" % [bonus_id, value])


func clear_round_buffs() -> void:
	for buff_id in buffs.keys().duplicate():
		var buff: Dictionary = buffs[buff_id]
		if bool(buff.get("round", false)):
			_remove_buff(buff_id)
	print("Round buffs cleared")


func _remove_buff(buff_id: StringName) -> void:
	var buff: Dictionary = buffs.get(buff_id, {})
	if buff.is_empty():
		return

	_apply_stat(StringName(buff["stat_name"]), -float(buff.get("applied_value", 0.0)))
	buffs.erase(buff_id)
	print("Buff expired/removed: %s" % buff_id)


func _apply_stat(stat_name: StringName, value: float) -> void:
	if owner_player == null or not owner_player.has_method("get_stats"):
		return
	var stats: StatsComponent = owner_player.get_stats()
	if stats != null:
		stats.add_runtime_modifier(stat_name, value)
