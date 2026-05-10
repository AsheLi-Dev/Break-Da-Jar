extends RefCounted
class_name WizardTalentCatalog

const LAYOUT_SCENE: PackedScene = preload("res://scenes/player/WizardTalentLayout.tscn")
const START_IDS: Array[StringName] = [&"flame_bottom_5"]

const POSITIONS := {
	&"flame_bottom_2": Vector2(220, 730),
	&"flame_bottom_3": Vector2(265, 748),
	&"flame_bottom_4": Vector2(310, 758),
	&"flame_bottom_5": Vector2(350, 762),
	&"flame_bottom_6": Vector2(390, 758),
	&"flame_bottom_7": Vector2(430, 748),
	&"flame_bottom_8": Vector2(470, 730),
	&"flame_bridge_center_0": Vector2(346, 598),
	&"flame_left_0": Vector2(205, 560),
	&"flame_left_1": Vector2(175, 510),
	&"flame_left_2": Vector2(150, 455),
	&"flame_left_3": Vector2(125, 400),
	&"flame_left_4": Vector2(112, 345),
	&"flame_left_5": Vector2(125, 288),
	&"flame_left_6": Vector2(155, 235),
	&"flame_left_7": Vector2(190, 190),
	&"flame_left_8": Vector2(225, 150),
	&"flame_left_9": Vector2(255, 112),
	&"flame_left_10": Vector2(285, 80),
	&"flame_center_0": Vector2(330, 565),
	&"flame_center_1": Vector2(315, 508),
	&"flame_center_2": Vector2(300, 452),
	&"flame_center_3": Vector2(292, 395),
	&"flame_center_4": Vector2(305, 338),
	&"flame_center_5": Vector2(330, 282),
	&"flame_center_6": Vector2(360, 226),
	&"flame_center_7": Vector2(385, 176),
	&"flame_center_8": Vector2(398, 126),
	&"flame_center_9": Vector2(392, 82),
	&"flame_center_10": Vector2(370, 48),
	&"flame_center_11": Vector2(345, 82),
	&"flame_center_12": Vector2(332, 126),
	&"flame_right_0": Vector2(515, 560),
	&"flame_right_1": Vector2(545, 510),
	&"flame_right_2": Vector2(570, 455),
	&"flame_right_3": Vector2(595, 400),
	&"flame_right_4": Vector2(608, 345),
	&"flame_right_5": Vector2(595, 288),
	&"flame_right_6": Vector2(565, 235),
	&"flame_right_7": Vector2(530, 190),
	&"flame_right_8": Vector2(495, 150),
	&"flame_right_9": Vector2(465, 112),
	&"flame_right_10": Vector2(435, 80),
	&"spark_0": Vector2(359, 401),
	&"spark_1": Vector2(336, 429),
	&"spark_2": Vector2(390, 435),
	&"spark_3": Vector2(655, 283),
	&"spark_4": Vector2(681, 370),
	&"spark_5": Vector2(623, 335),
	&"spark_6": Vector2(90, 246),
	&"spark_7": Vector2(64, 324),
	&"spark_8": Vector2(41, 286),
}

static var _layout_position_cache: Dictionary = {}


static func node_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in POSITIONS.keys():
		ids.append(id)
	return ids


static func definition(id: StringName) -> Dictionary:
	match id:
		&"flame_bottom_5":
			return {"name": "Venom\nSpark", "description": "Your attacks have 10% chance to apply 1 Poison stack.", "stat": &"poison_chance", "value": 0.1}
		&"flame_bottom_4":
			return {"name": "Slide\nBlast", "description": "After sliding, your next left-click Fireball has 300% increased explosion radius and 90% reduced travel distance.", "effect": &"wizard_slide_fireball_blast"}
		&"flame_bottom_3":
			return {"name": "Toxic\nKindling", "description": "Deal 5% increased damage to enemies for each Poison stack on them.", "effect": &"wizard_poison_stack_damage"}
		&"flame_bottom_2":
			return {"name": "Crowd\nHeat", "description": "Gain 5% attack speed for each nearby enemy.", "effect": &"wizard_nearby_enemy_attack_speed"}
		&"flame_bottom_6":
			return {"name": "Laser\nBurst", "description": "Your left-click Fireball explosion is replaced with a right-click Fire Laser targeting the nearest enemy.", "effect": &"wizard_primary_fireball_laser_explosion"}
		&"flame_bottom_7":
			return {"name": "Surge\nLaser", "description": "Fire Surge now triggers a Fire Laser at the nearest enemy every 2s.", "effect": &"wizard_fire_surge_laser"}
		&"flame_bottom_8":
			return {"name": "Laser\nChain", "description": "Your Fire Lasers chain 1 additional time to a nearby enemy.", "effect": &"wizard_fire_laser_chain"}
		&"flame_left_0":
			return {"name": "Close\nBurn", "description": "Deal 50% more damage to nearby enemies and 50% less damage to enemies that are not nearby.", "effect": &"wizard_nearby_damage_focus"}
		&"flame_left_1":
			return {"name": "Surge\nBlast", "description": "During Fire Surge, your left-click Fireballs have 300% increased explosion radius and 90% reduced travel distance.", "effect": &"wizard_fire_surge_left_click_blast"}
		&"flame_left_2":
			return {"name": "Close\nCoins", "description": "Killing a nearby enemy grants 1 extra gold.", "effect": &"wizard_nearby_kill_gold"}
		&"flame_left_3":
			return {"name": "Dash\nEmber", "description": "Your dash fires a Fireball with 100% increased explosion radius and 90% reduced travel distance.", "effect": &"wizard_dash_fireball"}
		&"flame_left_4":
			return {"name": "Crowd\nDrift", "description": "Gain 5% movement speed for each nearby enemy.", "effect": &"wizard_nearby_enemy_move_speed"}
		&"flame_left_5":
			return {"name": "Venom\nAura", "description": "Nearby enemies gain 1 Poison stack every 5s.", "effect": &"wizard_nearby_poison_aura"}
		&"flame_left_6":
			return {"name": "Venom\nBounty", "description": "Killing a poisoned enemy grants 1 extra gold.", "effect": &"wizard_poisoned_kill_gold"}
		&"flame_left_7":
			return {"name": "Focused\nLaser", "description": "Your right-click attack has 50% reduced range and deals 100% increased damage.", "effect": &"wizard_short_laser_double_damage"}
		&"flame_left_8":
			return {"name": "Elite\nHeat", "description": "Gain 10% increased damage to elite enemies for each nearby enemy.", "effect": &"wizard_nearby_enemy_elite_damage"}
		&"flame_left_9":
			return {"name": "Wild\nHorde", "description": "Enemies are 100% more numerous but have 30% less max HP.", "effect": &"wizard_more_weaker_enemies"}
		&"flame_left_10":
			return {"name": "Phoenix\nDebt", "description": "When you die, revive and reset your level and talents. After reviving, gain 1 ATK for each lost level.", "effect": &"wizard_rebirth_level_to_atk"}
		&"flame_bridge_center_0":
			return {"name": "Fire\nEssence", "description": "Every 5s, a Fire Essence appears within 400px for 5s. Pick it up within 300px to make your next left-click attack fire three extra Fireballs.", "effect": &"wizard_fire_essence_burst"}
		&"flame_center_0":
			return {"name": "After\nBurn", "description": "After killing an enemy, gain 200% movement speed for 0.2s.", "effect": &"wizard_kill_move_speed_burst"}
		&"flame_center_1":
			return {"name": "Surge\nRing", "description": "Fire Surge now fires eight Fireballs in all directions every 5s.", "effect": &"wizard_fire_surge_radial_fireballs"}
		&"flame_center_2":
			return {"name": "Vital\nEcho", "description": "For every 100 max HP you have, your left-click attack repeats once after 0.2s. If it consumed Fire Essence, the repeats use the four-Fireball version.", "effect": &"wizard_max_hp_primary_echo"}
		&"flame_center_3":
			return {"name": "Swift\nVolley", "description": "For every 100 movement speed you have, your left-click attack fires 1 extra Fireball at a 10-degree offset without changing the original Fireball angle.", "effect": &"wizard_move_speed_extra_fireballs"}
		&"flame_center_4":
			return {"name": "Venom\nBurst", "description": "When a poisoned enemy dies, trigger a Fireball from its position.", "effect": &"wizard_poisoned_death_fireball"}
		&"flame_center_5":
			return {"name": "Rare\nStride", "description": "Gain 10 movement speed for each rare item you have.", "effect": &"wizard_rare_item_move_speed"}
		&"flame_center_6":
			return {"name": "Essence\nSpiral", "description": "After picking up Fire Essence, your next left-click Fireball explosion releases eight Fireballs in a spinning burst.", "effect": &"wizard_fire_essence_explosion_scatter"}
		&"flame_center_7":
			return {"name": "Legendary\nMarket", "description": "Your shop always has at least one legendary jar. Legendary jars cost double.", "effect": &"wizard_guaranteed_legendary_shop_jar"}
		&"flame_center_8":
			return {"name": "Lasting\nBloom", "description": "Fireballs have double explosion radius when they explode naturally at the end of their flight.", "effect": &"wizard_natural_fireball_radius"}
		&"flame_center_9":
			return {"name": "Legendary\nEmbers", "description": "For each legendary item you have, every Fireball source fires 1 additional Fireball.", "effect": &"wizard_legendary_extra_fireballs"}
		&"flame_center_10":
			return {"name": "Warm\nAsh", "description": "Recover 1 HP whenever one of your Fireballs explodes naturally at the end of its flight.", "effect": &"wizard_natural_fireball_heal"}
		&"flame_center_11":
			return {"name": "Pain\nBloom", "description": "When you take damage, all of your active Fireballs explode naturally.", "effect": &"wizard_damage_taken_natural_explode_fireballs"}
		&"flame_center_12":
			return {"name": "Wild\nSparks", "description": "All Fireballs from all sources are doubled, but every Fireball launches in a random direction.", "effect": &"wizard_random_double_fireballs"}
		&"flame_right_0":
			return {"name": "Surge\nHaste", "description": "During Fire Surge, gain 50% attack speed.", "effect": &"wizard_fire_surge_attack_speed"}
		&"flame_right_1":
			return {"name": "Rapid\nChain", "description": "Your Fire Lasers gain additional chains equal to your attacks per second, rounded down.", "effect": &"wizard_attack_speed_laser_chain"}
		_:
			return {"name": "+1\nATK", "description": "+1 ATK.", "stat": &"atk", "value": 1.0}


static func display_name(id: StringName) -> String:
	return String(definition(id).get("name", "+1 ATK"))


static func description(id: StringName) -> String:
	return String(definition(id).get("description", "+1 ATK"))


static func position(id: StringName) -> Vector2:
	return _layout_positions().get(id, POSITIONS.get(id, Vector2.ZERO))


static func connections() -> Array:
	var result: Array = []
	_add_path(result, [
		&"flame_bottom_2",
		&"flame_bottom_3",
		&"flame_bottom_4",
		&"flame_bottom_5",
		&"flame_bottom_6",
		&"flame_bottom_7",
		&"flame_bottom_8",
	])
	_add_path(result, _ids("flame_left", 11))
	_add_path(result, _ids("flame_center", 13))
	_add_path(result, _ids("flame_right", 11))
	result.append([&"flame_bottom_2", &"flame_left_0"])
	result.append([&"flame_bottom_5", &"flame_bridge_center_0"])
	result.append([&"flame_bridge_center_0", &"flame_center_0"])
	result.append([&"flame_bottom_8", &"flame_right_0"])
	result.append([&"flame_left_5", &"spark_6"])
	result.append([&"flame_center_2", &"spark_1"])
	result.append([&"flame_right_4", &"spark_5"])
	_add_path(result, [&"spark_0", &"spark_1", &"spark_2"])
	_add_path(result, [&"spark_3", &"spark_4", &"spark_5"])
	_add_path(result, [&"spark_6", &"spark_7", &"spark_8"])
	return result


static func start_nodes() -> Array[StringName]:
	return START_IDS.duplicate()


static func _ids(prefix: String, count: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for index in range(count):
		result.append(StringName("%s_%d" % [prefix, index]))
	return result


static func _add_path(result: Array, ids: Array[StringName]) -> void:
	for index in range(ids.size() - 1):
		result.append([ids[index], ids[index + 1]])


static func _layout_positions() -> Dictionary:
	if not _layout_position_cache.is_empty():
		return _layout_position_cache

	var root := LAYOUT_SCENE.instantiate() as Node2D
	if root == null:
		_layout_position_cache = POSITIONS.duplicate()
		return _layout_position_cache

	var positions := POSITIONS.duplicate()
	for id in POSITIONS.keys():
		var marker := root.get_node_or_null(String(id)) as Node2D
		if marker != null:
			positions[id] = marker.position
	root.free()
	_layout_position_cache = positions
	return _layout_position_cache
