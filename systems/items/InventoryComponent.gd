extends Node
class_name InventoryComponent

const PERMANENT_GROWTH_EFFECT_TYPES: Array[StringName] = [
	&"stat_bonus_every_n_kills_shared",
	&"no_damage_round_permanent_stat",
	&"permanent_stat_elite_kill",
	&"permanent_stat_every_hp_lost_round_cap",
	&"permanent_stat_per_gold_on_round_start",
	&"permanent_stat_player_container_round_cap",
	&"permanent_stat_shop_container_scaled",
	&"permanent_stat_stationary_round_cap",
	&"permanent_stat_attack_kill_crit_state_round_cap",
]

var owner_player: Node
var item_counts: Dictionary = {}
var item_definitions_by_id: Dictionary = {}
var applied_effects: Array[Resource] = []


func setup(player: Node) -> void:
	owner_player = player


func add_item(item: ItemDefinition) -> void:
	if item == null:
		return

	item_counts[item.id] = int(item_counts.get(item.id, 0)) + 1
	item_definitions_by_id[item.id] = item
	print("Player received item: %s x%d" % [item.display_name, item_counts[item.id]])

	for effect_index in range(item.effects.size()):
		var effect: Resource = item.effects[effect_index]
		if effect == null:
			continue

		var effect_instance: Resource = effect.duplicate(true)
		applied_effects.append(effect_instance)
		if effect_instance.has_method("configure_instance"):
			effect_instance.configure_instance(item.id, effect_index, int(item_counts[item.id]) - 1)
		if effect_instance.has_method("apply_to"):
			effect_instance.apply_to(owner_player)

	for applied_effect in applied_effects:
		if applied_effect != null and applied_effect.has_method("on_item_count_changed"):
			applied_effect.on_item_count_changed(item.id)


func get_item_count(item_id: StringName) -> int:
	return int(item_counts.get(item_id, 0))


func get_unique_permanent_growth_item_count() -> int:
	var count := 0
	for item_id in item_counts.keys():
		if int(item_counts.get(item_id, 0)) <= 0:
			continue
		var item := item_definitions_by_id.get(item_id) as ItemDefinition
		if item != null and _is_permanent_growth_item(item):
			count += 1
	return count


func _is_permanent_growth_item(item: ItemDefinition) -> bool:
	for effect in item.effects:
		if effect == null:
			continue
		var effect_type_value: Variant = effect.get("effect_type")
		if effect_type_value != null and PERMANENT_GROWTH_EFFECT_TYPES.has(StringName(effect_type_value)):
			return true
	return false
