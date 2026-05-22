extends Node
class_name InventoryComponent

const PERMANENT_GROWTH_EFFECT_SCRIPT := preload("res://systems/items/effects/PermanentGrowthEffect.gd")

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


func remove_one_random_item_by_rarity(rarity: StringName) -> ItemDefinition:
	var candidates: Array[ItemDefinition] = []
	for item_id in item_counts.keys():
		if int(item_counts.get(item_id, 0)) <= 0:
			continue
		var item := item_definitions_by_id.get(item_id) as ItemDefinition
		if item != null and item.rarity == rarity:
			candidates.append(item)
	if candidates.is_empty():
		return null

	var item := candidates.pick_random() as ItemDefinition
	var next_count: int = int(item_counts.get(item.id, 0)) - 1
	if next_count > 0:
		item_counts[item.id] = next_count
	else:
		item_counts.erase(item.id)
		item_definitions_by_id.erase(item.id)

	for applied_effect in applied_effects:
		if applied_effect != null and applied_effect.has_method("on_item_count_changed"):
			applied_effect.on_item_count_changed(item.id)
	return item


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
		if effect != null and effect.get_script() == PERMANENT_GROWTH_EFFECT_SCRIPT:
			return true
	return false
