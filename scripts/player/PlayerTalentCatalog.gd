extends RefCounted
class_name PlayerTalentCatalog


static func node_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for coord in coords():
		ids.append(node_id(coord))
	return ids


static func definition(id: StringName) -> Dictionary:
	match id:
		&"talent_0_4":
			return {
				"name": "Heal\nOrb",
				"description": "A healing orb appears on the map at the start of each combat round.",
				"effect": &"round_healing_orb",
			}
		&"talent_0_5":
			return {
				"name": "Last\nLight",
				"description": "At round end, if your health is below 50%, restore 30% of maximum health.",
				"effect": &"low_hp_round_end_heal",
			}
		&"talent_1_7":
			return {
				"name": "Spoiled\nGuard",
				"description": "Gain +5 Defense for each item you have.",
				"effect": &"defense_per_item",
			}
		&"talent_3_7":
			return {
				"name": "Vital\nSpoils",
				"description": "Gain +3 maximum health for each common item you have.",
				"effect": &"max_hp_per_common_item",
			}
		&"talent_5_7":
			return {
				"name": "Hearty\nLoot",
				"description": "Item-based maximum health bonuses are increased by 30%.",
				"effect": &"item_max_hp_bonus_multiplier",
			}
		&"talent_6_6":
			return {
				"name": "Slide\nGuard",
				"description": "After sliding, gain +50% Defense for 2 seconds.",
				"effect": &"slide_defense_bonus",
			}
		&"talent_6_7":
			return {
				"name": "Blood\nVow",
				"description": "When you lose health, gain 20% lifesteal for 2 seconds.",
				"effect": &"damage_taken_lifesteal",
			}
		&"talent_-1_4":
			return {
				"name": "Cull\nCoin",
				"description": "Killing a normal enemy has a 10% chance to grant 1 gold.",
				"effect": &"normal_kill_gold_chance",
			}
		&"talent_-1_5":
			return {
				"name": "Cull\nStudy",
				"description": "Normal enemies drop 20% more XP.",
				"effect": &"normal_enemy_xp_bonus",
			}
		&"talent_-1_6":
			return {
				"name": "Cull\nSpoils",
				"description": "Every 25 normal enemy kills grants a random common item.",
				"effect": &"normal_kill_common_item_counter",
			}
		&"talent_-1_7":
			return {
				"name": "Cull\nGreed",
				"description": "Normal enemy gold drops are doubled.",
				"effect": &"normal_enemy_gold_double",
			}
		&"talent_0_7":
			return {
				"name": "Zombie\nSigil",
				"description": "Every 10 enemy kills grants a Zombie Inscription. Each inscription counts as one nearby enemy.",
				"effect": &"holy_strike_zombie_inscriptions",
			}
		&"talent_0_6":
			return {
				"name": "Elite\nStorm",
				"description": "Each enemy kill grants +1% damage to elite enemies for the rest of the round.",
				"effect": &"holy_strike_elite_damage_per_kill",
			}
		&"talent_1_6":
			return {
				"name": "Thin\nHorde",
				"description": "Nearby enemies take 20% increased damage.",
				"effect": &"holy_strike_more_weaker_enemies",
			}
		&"talent_1_5":
			return {
				"name": "Crowd\nTempo",
				"description": "Gain +5% attack speed for each nearby enemy.",
				"effect": &"holy_strike_nearby_enemy_attack_speed",
			}
		&"talent_2_5":
			return {
				"name": "Chain\nStorm",
				"description": "When you attack, release one extra Chain Lightning for every 5 nearby enemies.",
				"effect": &"holy_strike_chain_lightning_pack",
			}
		&"talent_2_4":
			return {
				"name": "Vital\nReach",
				"description": "Holy Strike gains 2% increased range for every 10 maximum health you have.",
				"effect": &"holy_strike_max_hp_range",
			}
		&"talent_2_7":
			return {
				"name": "Swift\nFaith",
				"description": "Gain 1% increased attack speed for every 10 movement speed you have.",
				"effect": &"holy_strike_move_speed_attack_speed",
			}
		&"talent_2_6":
			return {
				"name": "Lucky\nCrits",
				"description": "When Holy Strike crits, your other Holy Strike proc chances roll twice and use the better result.",
				"effect": &"holy_strike_lucky_critical_procs",
			}
		&"talent_3_6":
			return {
				"name": "Eight\nBurst",
				"description": "Critical hits with Holy Strike have a 50% chance to trigger an eight-fireball burst.",
				"effect": &"holy_strike_crit_fireball_burst",
			}
		&"talent_3_5":
			return {
				"name": "Focused\nZeal",
				"description": "Holy Strike has 80% reduced attack angle and 100% increased attack speed.",
				"effect": &"holy_strike_focused_zeal",
			}
		&"talent_4_5":
			return {
				"name": "Long\nFlame",
				"description": "Holy Strike gains 50% increased range, but deals 20% less direct damage.",
				"effect": &"holy_strike_long_range",
			}
		&"talent_4_4":
			return {
				"name": "Zeal\nStep",
				"description": "Holy Strike grants +5 movement speed for 3 seconds when you hit an enemy. Stacks without limit.",
				"effect": &"holy_strike_movement_stack",
			}
		&"talent_4_7":
			return {
				"name": "Still\nAegis",
				"description": "After 5 seconds without taking damage, you count as stationary and have 30% reduced movement speed.",
				"effect": &"holy_strike_undamaged_stationary",
			}
		&"talent_4_6":
			return {
				"name": "Double\nTombs",
				"description": "Tomb count is increased by 100%.",
				"effect": &"holy_strike_double_tombs",
			}
		&"talent_5_6":
			return {
				"name": "Rooted\nMight",
				"description": "While stationary, gain +1 ATK per second. Moving removes all stacks.",
				"effect": &"holy_strike_stationary_atk",
			}
		&"talent_5_5":
			return {
				"name": "Elite\nSmite",
				"description": "Holy Strike deals 50% more damage to elites, but 30% less damage to normal enemies.",
				"effect": &"holy_strike_elite_smite",
			}
		&"talent_6_5":
			return {
				"name": "Certain\nCrit",
				"description": "After standing still for 2 seconds, your next Holy Strike is guaranteed to crit.",
				"effect": &"holy_strike_stationary_crit",
			}
		&"talent_6_4":
			return {
				"name": "Heavy\nSmite",
				"description": "Holy Strike deals 50% more damage, but you have 30% reduced attack speed.",
				"effect": &"holy_strike_heavy_smite",
			}
		&"talent_7_4":
			return {
				"name": "Elite\nBounty",
				"description": "Killing an elite enemy grants 10 gold.",
				"effect": &"elite_kill_gold",
			}
		&"talent_7_5":
			return {
				"name": "Elite\nStudy",
				"description": "Elite enemies drop 50% more XP.",
				"effect": &"elite_enemy_xp_bonus",
			}
		&"talent_7_6":
			return {
				"name": "Elite\nSpoils",
				"description": "Killing an elite enemy grants a random common item.",
				"effect": &"elite_kill_common_item",
			}
		&"talent_7_7":
			return {
				"name": "Elite\nRelic",
				"description": "Killing an elite enemy grants a random rare item.",
				"effect": &"elite_kill_rare_item",
			}
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
		&"talent_1_4":
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
		&"talent_4_0":
			return {
				"name": "Kill\nGold",
				"description": "Killing an enemy has 10% chance to gain 1 gold.",
				"effect": &"kill_gold_chance",
			}
		&"talent_4_1":
			return {
				"name": "Elite\nItem",
				"description": "Killing an elite enemy grants a random common item.",
				"effect": &"elite_kill_common_item",
			}
		&"talent_4_2":
			return {
				"name": "Jar\nGold",
				"description": "Breaking a container has 10% chance to gain 1 gold.",
				"effect": &"container_gold_chance",
			}
		&"talent_4_3":
			return {
				"name": "Level\nGold",
				"description": "Gain 10 gold when you level up.",
				"effect": &"level_up_gold",
			}
		&"talent_5_4":
			return {
				"name": "Rich\nXP",
				"description": "Gain double XP while you have 300+ gold.",
				"effect": &"rich_double_xp",
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


static func position(id: StringName) -> Vector2:
	var coord := grid_position(id)
	var spacing := Vector2(62.0, 82.0)
	var center_x := 360.0
	var bottom_y := 716.0
	return Vector2(
		center_x + (float(coord.x) - 3.0) * spacing.x,
		bottom_y - float(coord.y) * spacing.y
	)


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
				if _is_blocked_connection(from_id, to_id):
					continue
				if String(from_id) < String(to_id):
					result.append([from_id, to_id])
	return result


static func _is_blocked_connection(from_id: StringName, to_id: StringName) -> bool:
	var blocked_connections: Array[Array] = [
		[&"talent_0_7", &"talent_1_7"],
		[&"talent_2_7", &"talent_3_7"],
		[&"talent_4_7", &"talent_5_7"],
		[&"talent_-1_4", &"talent_-1_5"],
		[&"talent_-1_6", &"talent_-1_7"],
		[&"talent_-2_7", &"talent_-1_7"],
		[&"talent_7_4", &"talent_7_5"],
		[&"talent_6_7", &"talent_7_7"],
		[&"talent_7_6", &"talent_7_7"],
	]
	for connection in blocked_connections:
		if (connection[0] == from_id and connection[1] == to_id) or (connection[0] == to_id and connection[1] == from_id):
			return true
	return false


static func neighbor_coords(coord: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	if coord.y < 4:
		neighbors.append(coord + Vector2i(0, -1))
		neighbors.append(coord + Vector2i(0, 1))
	elif coord.y == 4 and coord.x >= 2 and coord.x <= 4:
		neighbors.append(coord + Vector2i(0, -1))
	if coord.y >= 4 and (coord.x == -1 or coord.x == 7):
		neighbors.append(coord + Vector2i(0, -1))
		neighbors.append(coord + Vector2i(0, 1))
	if coord.y >= 4 and (coord.x == -2 or coord.x == 8):
		neighbors.append(coord + Vector2i(0, -1))
		neighbors.append(coord + Vector2i(0, 1))
	if coord.y == 0 or coord.y == 4 or coord.y == 7 or coord.y == 8:
		neighbors.append(coord + Vector2i(-1, 0))
		neighbors.append(coord + Vector2i(1, 0))
	match coord:
		Vector2i(-1, 5):
			neighbors.append(Vector2i(0, 5))
		Vector2i(0, 5):
			neighbors.append(Vector2i(-1, 5))
			neighbors.append(Vector2i(0, 4))
		Vector2i(0, 4):
			neighbors.append(Vector2i(0, 5))
		Vector2i(-1, 6):
			neighbors.append(Vector2i(-2, 6))
		Vector2i(0, 7):
			neighbors.append(Vector2i(0, 6))
		Vector2i(1, 7):
			neighbors.append(Vector2i(1, 8))
		Vector2i(0, 6):
			neighbors.append(Vector2i(0, 7))
			neighbors.append(Vector2i(1, 6))
		Vector2i(1, 6):
			neighbors.append(Vector2i(0, 6))
			neighbors.append(Vector2i(1, 5))
		Vector2i(1, 5):
			neighbors.append(Vector2i(1, 6))
			neighbors.append(Vector2i(2, 5))
		Vector2i(2, 5):
			neighbors.append(Vector2i(1, 5))
			neighbors.append(Vector2i(2, 4))
		Vector2i(2, 4):
			neighbors.append(Vector2i(2, 5))
		Vector2i(2, 7):
			neighbors.append(Vector2i(2, 6))
		Vector2i(3, 7):
			neighbors.append(Vector2i(3, 8))
		Vector2i(2, 6):
			neighbors.append(Vector2i(2, 7))
			neighbors.append(Vector2i(3, 6))
		Vector2i(3, 6):
			neighbors.append(Vector2i(2, 6))
			neighbors.append(Vector2i(3, 5))
		Vector2i(3, 5):
			neighbors.append(Vector2i(3, 6))
			neighbors.append(Vector2i(4, 5))
		Vector2i(4, 5):
			neighbors.append(Vector2i(3, 5))
			neighbors.append(Vector2i(4, 4))
		Vector2i(4, 4):
			neighbors.append(Vector2i(4, 5))
		Vector2i(4, 7):
			neighbors.append(Vector2i(4, 6))
		Vector2i(5, 7):
			neighbors.append(Vector2i(5, 8))
		Vector2i(4, 6):
			neighbors.append(Vector2i(4, 7))
			neighbors.append(Vector2i(5, 6))
		Vector2i(5, 6):
			neighbors.append(Vector2i(4, 6))
			neighbors.append(Vector2i(5, 5))
		Vector2i(5, 5):
			neighbors.append(Vector2i(5, 6))
			neighbors.append(Vector2i(6, 5))
		Vector2i(6, 5):
			neighbors.append(Vector2i(5, 5))
			neighbors.append(Vector2i(6, 4))
		Vector2i(6, 4):
			neighbors.append(Vector2i(6, 5))
		Vector2i(6, 7):
			neighbors.append(Vector2i(6, 6))
		Vector2i(6, 6):
			neighbors.append(Vector2i(6, 7))
			neighbors.append(Vector2i(7, 6))
		Vector2i(7, 6):
			neighbors.append(Vector2i(6, 6))
		Vector2i(7, 5):
			neighbors.append(Vector2i(8, 5))
	return neighbors


static func coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(5):
		result.append(Vector2i(2, y))
		result.append(Vector2i(3, y))
		result.append(Vector2i(4, y))
	for y in range(4, 8):
		for x in range(-1, 8):
			var coord := Vector2i(x, y)
			if not result.has(coord):
				result.append(coord)
	for y in range(4, 9):
		for x in range(-2, 9):
			var coord := Vector2i(x, y)
			if not result.has(coord):
				result.append(coord)
	return result


static func node_id(coord: Vector2i) -> StringName:
	return StringName("talent_%d_%d" % [coord.x, coord.y])


static func is_coord_valid(coord: Vector2i) -> bool:
	if coord.y >= 4 and coord.y <= 8:
		return coord.x >= -2 and coord.x <= 8
	if coord.y >= 0 and coord.y <= 3:
		return coord.x >= 2 and coord.x <= 4
	return false


static func is_start_coord(coord: Vector2i) -> bool:
	return coord.y == 0 and coord.x >= 2 and coord.x <= 4
