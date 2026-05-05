extends Node
class_name InventoryComponent

var owner_player: Node
var item_counts: Dictionary = {}
var applied_effects: Array[Resource] = []


func setup(player: Node) -> void:
	owner_player = player


func add_item(item: ItemDefinition) -> void:
	if item == null:
		return

	item_counts[item.id] = int(item_counts.get(item.id, 0)) + 1
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
