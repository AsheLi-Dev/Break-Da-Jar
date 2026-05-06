extends RefCounted
class_name PlayerTalentCatalog


static func node_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for coord in coords():
		ids.append(node_id(coord))
	return ids


static func definition(id: StringName) -> Dictionary:
	match id:
		&"talent_2_0":
			return {
				"name": "+10%\nDMG",
				"description": "+10% attack damage.",
				"stat": &"attack_damage_bonus",
				"value": 0.1,
			}
		&"talent_2_1":
			return {
				"name": "Slide\nAS",
				"description": "Gain +20% attack speed for 3s after sliding.",
				"effect": &"slide_attack_speed",
			}
		&"talent_2_2":
			return {
				"name": "+10%\nCRIT",
				"description": "+10% crit chance.",
				"stat": &"critical_chance",
				"value": 0.1,
			}
		&"talent_2_3":
			return {
				"name": "Fire\n10%",
				"description": "Attacks have 10% chance to trigger Fireball.",
				"stat": &"fireball_chance",
				"value": 0.1,
			}
		&"talent_2_4":
			return {
				"name": "Slide\nHit",
				"description": "Next attack after sliding deals +50% damage.",
				"effect": &"next_slide_attack",
			}
		&"talent_3_0":
			return {
				"name": "+10%\nHP",
				"description": "+10% max HP.",
				"stat": &"max_hp",
				"operation": &"multiply_add",
				"value": 0.1,
			}
		&"talent_3_1":
			return {
				"name": "Slide\nDR",
				"description": "Gain 20% damage reduction for 2s after sliding.",
				"effect": &"slide_damage_reduction",
			}
		&"talent_3_2":
			return {
				"name": "+10\nDEF",
				"description": "+10 Defense.",
				"stat": &"defense",
				"value": 10.0,
			}
		&"talent_3_3":
			return {
				"name": "ATK\nHP",
				"description": "Gain max HP equal to your ATK.",
				"effect": &"max_hp_from_atk",
			}
		&"talent_3_4":
			return {
				"name": "Kill\nHeal",
				"description": "Heal 5 HP after killing an enemy.",
				"effect": &"heal_on_kill",
			}
		_:
			return {
				"name": "+1\nATK",
				"description": "+1 ATK.",
				"stat": &"atk",
				"value": 1.0,
			}


static func grid_position(id: StringName) -> Vector2i:
	for coord in coords():
		if node_id(coord) == id:
			return coord
	return Vector2i.ZERO


static func display_name(id: StringName) -> String:
	return String(definition(id).get("name", "+1 ATK"))


static func description(id: StringName) -> String:
	return String(definition(id).get("description", "+1 ATK"))


static func connections() -> Array:
	var result: Array = []
	for coord in coords():
		var from_id: StringName = node_id(coord)
		for neighbor in neighbor_coords(coord):
			if is_coord_valid(neighbor):
				var to_id: StringName = node_id(neighbor)
				if String(from_id) < String(to_id):
					result.append([from_id, to_id])
	return result


static func neighbor_coords(coord: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	neighbors.append(coord + Vector2i(0, -1))
	neighbors.append(coord + Vector2i(0, 1))
	if coord.y == 0 or coord.y >= 4:
		neighbors.append(coord + Vector2i(-1, 0))
		neighbors.append(coord + Vector2i(1, 0))
	return neighbors


static func coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(5):
		result.append(Vector2i(2, y))
		result.append(Vector2i(3, y))
	for y in range(4, 8):
		for x in range(6):
			var coord := Vector2i(x, y)
			if not result.has(coord):
				result.append(coord)
	return result


static func node_id(coord: Vector2i) -> StringName:
	return StringName("talent_%d_%d" % [coord.x, coord.y])


static func is_coord_valid(coord: Vector2i) -> bool:
	if coord.y >= 4 and coord.y <= 7:
		return coord.x >= 0 and coord.x <= 5
	if coord.y >= 0 and coord.y <= 3:
		return coord.x == 2 or coord.x == 3
	return false


static func is_start_coord(coord: Vector2i) -> bool:
	return coord.y == 0 and (coord.x == 2 or coord.x == 3)
