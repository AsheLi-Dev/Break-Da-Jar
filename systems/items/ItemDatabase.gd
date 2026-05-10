extends Node

var items_by_id: Dictionary = {}
var all_items: Array[ItemDefinition] = []


func _ready() -> void:
	load_items_from_folder("res://data/items/")


func load_items_from_folder(path: String) -> void:
	items_by_id.clear()
	all_items.clear()
	_load_items_recursive(path)


func _load_items_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("Item folder not found: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
		var item_path := path.path_join(file_name)
		if dir.current_is_dir():
			_load_items_recursive(item_path)
		elif file_name.ends_with(".tres"):
			var item := load(item_path) as ItemDefinition
			if item != null:
				items_by_id[item.id] = item
				all_items.append(item)
		file_name = dir.get_next()
	dir.list_dir_end()


func get_item(id: StringName) -> ItemDefinition:
	return items_by_id.get(id)


func get_items_by_category(category: StringName) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for item in all_items:
		if item.category == category:
			result.append(item)
	return result


func get_items_by_rarity(rarity: StringName) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for item in all_items:
		if item.rarity == rarity:
			result.append(item)
	return result


func get_random_item(category: StringName = &"", rarity: StringName = &"") -> ItemDefinition:
	var pool: Array[ItemDefinition] = []
	for item in all_items:
		if category != &"" and item.category != category:
			continue
		if rarity != &"" and item.rarity != rarity:
			continue
		pool.append(item)

	if pool.is_empty():
		return null
	return pool.pick_random()
