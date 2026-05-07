extends ItemEffect
class_name PermanentGrowthEffect

const TRIGGER_ENEMY_KILLED := &"enemy_killed"
const TRIGGER_CONTAINER_BROKEN := &"container_broken"
const TRIGGER_DAMAGE_TAKEN := &"damage_taken"
const TRIGGER_SHOP_CONTAINER_BROKEN := &"shop_container_broken"
const TRIGGER_ROUND_STARTED := &"round_started"
const TRIGGER_ROUND_ENDED := &"round_ended"
const TRIGGER_STATIONARY := &"stationary"

@export var trigger: StringName
@export var growth_stat: StringName
@export var growth_value: float = 0.0
@export var trigger_value: float = 1.0
@export var round_cap: float = 0.0
@export var stack_round_cap_bonus: float = 0.0
@export var stack_growth_bonus: float = 0.0
@export var requires_direct_player_attack: bool = false
@export var requires_critical: bool = false
@export var requires_non_critical: bool = false
@export var requires_elite: bool = false
@export var requires_no_damage_round: bool = false
@export var use_current_gold: bool = false

var owner_player: Node
var item_id: StringName
var item_effect_index: int = 0
var item_stack_index: int = 0
var trigger_progress: float = 0.0
var round_growth: float = 0.0
var took_damage_this_round: bool = false
var runtime_node: Node


class StationaryRuntimeNode:
	extends Node

	var effect: PermanentGrowthEffect
	var last_position: Vector2 = Vector2.ZERO

	func setup(new_effect: PermanentGrowthEffect, owner: Node) -> void:
		effect = new_effect
		var owner_2d := owner as Node2D
		if owner_2d != null:
			last_position = owner_2d.global_position

	func _process(delta: float) -> void:
		if effect == null or effect.owner_player == null or not is_instance_valid(effect.owner_player):
			queue_free()
			return

		var owner_2d := effect.owner_player as Node2D
		if owner_2d == null:
			return

		var moved := owner_2d.global_position.distance_squared_to(last_position) > 1.0
		last_position = owner_2d.global_position
		if moved:
			effect.trigger_progress = 0.0
			return

		effect.trigger_progress += delta
		effect._consume_threshold_progress()


func configure_instance(new_item_id: StringName, new_effect_index: int, new_stack_index: int) -> void:
	item_id = new_item_id
	item_effect_index = new_effect_index
	item_stack_index = new_stack_index


func apply_to(player: Node) -> void:
	owner_player = player
	if _uses_shared_listener() and item_stack_index > 0:
		return

	if _uses_round_state():
		_connect_signal(&"round_started", Callable(self, "_on_round_started"))

	if trigger == TRIGGER_STATIONARY:
		_add_stationary_runtime_node()
		return

	if requires_no_damage_round:
		_connect_signal(&"damage_taken", Callable(self, "_on_damage_taken_for_no_damage_round"))

	_connect_signal(_get_signal_name(), Callable(self, "_on_triggered"))


func on_item_count_changed(changed_item_id: StringName) -> void:
	if changed_item_id != item_id:
		return
	if trigger == TRIGGER_STATIONARY and item_stack_index == 0 and runtime_node == null:
		_add_stationary_runtime_node()


func _on_round_started(_round_index: int = 0) -> void:
	trigger_progress = 0.0
	round_growth = 0.0
	took_damage_this_round = false


func _on_damage_taken_for_no_damage_round(final_damage_taken: float) -> void:
	if final_damage_taken > 0.0:
		took_damage_this_round = true


func _on_triggered(arg1: Variant = null, arg2: Variant = null, _arg3: Variant = null) -> void:
	if requires_no_damage_round:
		if took_damage_this_round:
			return
		_apply_growth(growth_value)
		return

	match trigger:
		TRIGGER_ENEMY_KILLED:
			_on_enemy_killed(arg1)
		TRIGGER_CONTAINER_BROKEN:
			_on_container_broken(arg2)
		TRIGGER_DAMAGE_TAKEN:
			_on_damage_taken(float(arg1))
		TRIGGER_SHOP_CONTAINER_BROKEN:
			_apply_growth(_get_scaled_growth_value())
		TRIGGER_ROUND_STARTED:
			_on_round_started_growth()


func _on_enemy_killed(enemy: Variant) -> void:
	if requires_elite and not _is_elite_enemy(enemy):
		return

	if requires_direct_player_attack or requires_critical or requires_non_critical:
		var attack_info := _get_enemy_last_attack_info(enemy)
		if requires_direct_player_attack and not _is_direct_player_attack(attack_info):
			return
		var was_critical := bool(attack_info.get("critical", false))
		if requires_critical and not was_critical:
			return
		if requires_non_critical and was_critical:
			return

	_apply_growth(growth_value)


func _on_container_broken(info_value: Variant) -> void:
	var info: Dictionary = info_value if info_value is Dictionary else {}
	if requires_direct_player_attack and not _is_direct_player_attack(info):
		return
	_apply_growth(growth_value)


func _on_damage_taken(final_damage_taken: float) -> void:
	if final_damage_taken <= 0.0:
		return
	trigger_progress += final_damage_taken
	_consume_threshold_progress()


func _on_round_started_growth() -> void:
	if not use_current_gold:
		_apply_growth(growth_value)
		return

	var scene := owner_player.get_tree().current_scene if owner_player != null else null
	if scene == null:
		return

	var gold := int(scene.get("gold"))
	var threshold := maxf(trigger_value, 0.001)
	var trigger_count := floorf(float(gold) / threshold)
	_apply_growth(growth_value * trigger_count)


func _consume_threshold_progress() -> void:
	var threshold := maxf(trigger_value, 0.001)
	while trigger_progress >= threshold:
		var before := round_growth
		_apply_growth(growth_value)
		if is_equal_approx(before, round_growth) and _get_round_cap() > 0.0:
			trigger_progress = threshold
			return
		trigger_progress -= threshold


func _apply_growth(base_amount: float) -> void:
	var amount := _apply_round_cap(base_amount)
	if amount <= 0.0:
		return

	amount = _get_permanent_growth_amount(amount)
	if amount <= 0.0:
		return

	var stats := _get_stats()
	if stats != null:
		stats.apply_modifier(growth_stat, &"add", amount)


func _apply_round_cap(amount: float) -> float:
	var cap := _get_round_cap()
	if cap <= 0.0:
		return amount
	if round_growth >= cap:
		return 0.0

	var capped_amount := minf(amount, cap - round_growth)
	round_growth += capped_amount
	return capped_amount


func _get_round_cap() -> float:
	if round_cap <= 0.0:
		return 0.0
	return round_cap + stack_round_cap_bonus * float(maxi(_get_item_count() - 1, 0))


func _get_scaled_growth_value() -> float:
	return growth_value + stack_growth_bonus * float(maxi(_get_item_count() - 1, 0))


func _get_permanent_growth_amount(amount: float) -> float:
	var stats := _get_stats()
	if stats == null or stats.permanent_growth_bonus_per_unique <= 0.0:
		return amount

	var unique_count := 0
	if owner_player.has_method("get_unique_permanent_growth_item_count"):
		unique_count = int(owner_player.get_unique_permanent_growth_item_count())
	if unique_count <= 0:
		return amount

	var multiplier := 1.0 + stats.permanent_growth_bonus_per_unique * float(unique_count)
	if absf(amount) < 1.0:
		return floorf(amount * multiplier * 100.0) / 100.0
	return floorf(amount * multiplier)


func _add_stationary_runtime_node() -> void:
	if owner_player == null:
		return
	runtime_node = StationaryRuntimeNode.new()
	runtime_node.name = "PermanentGrowthRuntimeNode"
	runtime_node.setup(self, owner_player)
	owner_player.add_child(runtime_node)


func _connect_signal(signal_name: StringName, callable: Callable) -> void:
	if owner_player == null:
		return
	if not owner_player.has_signal(signal_name):
		push_warning("Player signal missing: %s" % signal_name)
		return
	if not owner_player.is_connected(signal_name, callable):
		owner_player.connect(signal_name, callable)


func _get_signal_name() -> StringName:
	if requires_no_damage_round:
		return TRIGGER_ROUND_ENDED
	return trigger


func _uses_round_state() -> bool:
	return round_cap > 0.0 or trigger == TRIGGER_DAMAGE_TAKEN or trigger == TRIGGER_STATIONARY or requires_no_damage_round


func _uses_shared_listener() -> bool:
	return round_cap > 0.0 or stack_growth_bonus != 0.0 or trigger == TRIGGER_ROUND_STARTED or trigger == TRIGGER_STATIONARY


func _is_direct_player_attack(info: Dictionary) -> bool:
	return bool(info.get("direct", false)) and String(info.get("source", "")) == "player_attack"


func _is_elite_enemy(enemy: Variant) -> bool:
	var enemy_base := enemy as EnemyBase
	if enemy_base != null:
		return enemy_base.is_elite
	return enemy is EliteBrute


func _get_enemy_last_attack_info(enemy: Variant) -> Dictionary:
	if enemy == null:
		return {}
	var value: Variant = enemy.get("last_attack_info") if enemy is Object else null
	return value if value is Dictionary else {}


func _get_stats() -> StatsComponent:
	if owner_player != null and owner_player.has_method("get_stats"):
		return owner_player.get_stats()
	return null


func _get_item_count() -> int:
	if owner_player != null and owner_player.has_method("get_item_count"):
		return maxi(int(owner_player.get_item_count(item_id)), 1)
	return 1
