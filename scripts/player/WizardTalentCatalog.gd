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
	&"flame_left_start_0": Vector2(335, 610),
	&"flame_left_start_1": Vector2(305, 592),
	&"flame_left_start_2": Vector2(275, 574),
	&"flame_left_start_3": Vector2(245, 556),
	&"flame_left_start_4": Vector2(215, 538),
	&"flame_center_start_0": Vector2(359, 600),
	&"flame_center_start_1": Vector2(356, 570),
	&"flame_center_start_2": Vector2(353, 540),
	&"flame_center_start_3": Vector2(350, 510),
	&"flame_center_start_4": Vector2(347, 480),
	&"flame_right_start_0": Vector2(389, 610),
	&"flame_right_start_1": Vector2(421, 592),
	&"flame_right_start_2": Vector2(453, 574),
	&"flame_right_start_3": Vector2(485, 556),
	&"flame_right_start_4": Vector2(517, 538),
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
	&"flame_left_11": Vector2(305, 138),
	&"flame_left_12": Vector2(325, 196),
	&"flame_left_13": Vector2(345, 254),
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
	&"flame_right_11": Vector2(415, 138),
	&"flame_right_12": Vector2(395, 196),
	&"flame_right_13": Vector2(375, 254),
	&"spark_0": Vector2(385, 72),
	&"spark_1": Vector2(352, 94),
	&"spark_2": Vector2(390, 128),
	&"spark_3": Vector2(655, 283),
	&"spark_4": Vector2(681, 370),
	&"spark_5": Vector2(623, 335),
	&"spark_6": Vector2(90, 246),
	&"spark_7": Vector2(64, 324),
	&"spark_8": Vector2(41, 286),
	&"spark_9": Vector2(126, 438),
	&"spark_10": Vector2(88, 405),
	&"spark_11": Vector2(139, 388),
	&"spark_12": Vector2(594, 438),
	&"spark_13": Vector2(632, 405),
	&"spark_14": Vector2(581, 388),
	&"spark_15": Vector2(330, 360),
	&"spark_16": Vector2(358, 398),
	&"spark_17": Vector2(318, 424),
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
		&"flame_left_start_0":
			return {"name": "Fireball\nForce", "description": "Your Fireballs deal 20% increased damage.", "effect": &"wizard_fireball_damage_bonus"}
		&"flame_left_start_1":
			return {"name": "Culling\nFlame", "description": "After killing an enemy, gain 2 ATK for 5s, up to 10 ATK.", "effect": &"wizard_kill_atk_stack"}
		&"flame_left_start_2":
			return {"name": "Slide\nBloom", "description": "After sliding, your Fireball explosion radius is increased by 30% for 3s. Does not stack. This bonus is additive with Slide Blast and Surge Blast.", "effect": &"wizard_slide_fireball_radius_buff"}
		&"flame_left_start_3":
			return {"name": "Wide\nBlast", "description": "Your Fireballs have 30% increased explosion radius.", "effect": &"wizard_fireball_radius_bonus"}
		&"flame_left_start_4":
			return {"name": "Close\nDrain", "description": "Damage dealt to nearby enemies heals you for 12% of the damage dealt.", "effect": &"wizard_nearby_damage_lifesteal"}
		&"flame_center_start_0":
			return {"name": "Swift\nFlame", "description": "Enemies have a 10% chance to drop 1 extra gold.", "effect": &"wizard_swift_flame_extra_gold"}
		&"flame_center_start_1":
			return {"name": "Burning\nStride", "description": "After killing an enemy, gain 10% movement speed for 3s, up to 30%.", "effect": &"wizard_kill_move_speed_stack"}
		&"flame_center_start_2":
			return {"name": "Extra\nSpark", "description": "Your left-click attack fires 1 additional Fireball.", "effect": &"wizard_primary_extra_fireball"}
		&"flame_center_start_3":
			return {"name": "Fast\nSparks", "description": "Your Fireballs have 40% increased travel speed.", "effect": &"wizard_fireball_speed_bonus"}
		&"flame_center_start_4":
			return {"name": "Siphon\nSpark", "description": "Fireball hits restore 1 HP.", "effect": &"wizard_fireball_hit_heal"}
		&"flame_right_start_0":
			return {"name": "Quick\nCast", "description": "Gain 20% attack speed.", "stat": &"attack_speed_bonus", "value": 0.2}
		&"flame_right_start_1":
			return {"name": "Kindled\nCast", "description": "After killing an enemy, gain 10% attack speed for 5s, up to 30%.", "effect": &"wizard_kill_attack_speed_stack"}
		&"flame_right_start_2":
			return {"name": "Twin\nRay", "description": "Your right-click attack fires an additional Fire Laser at the nearest enemy.", "effect": &"wizard_extra_auto_fire_laser"}
		&"flame_right_start_3":
			return {"name": "Long\nRay", "description": "Your Fire Lasers have 30% increased range.", "effect": &"wizard_fire_laser_range_bonus"}
		&"flame_right_start_4":
			return {"name": "Elite\nDrain", "description": "Damage dealt to elite enemies heals you for 25% of the damage dealt.", "effect": &"wizard_elite_damage_lifesteal"}
		&"flame_bottom_4":
			return {"name": "Slide\nBlast", "description": "After sliding, your next left-click Fireball has 30% increased explosion radius and 90% reduced travel distance.", "effect": &"wizard_slide_fireball_blast"}
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
			return {"name": "Close\nBurn", "description": "Deal 20% increased damage to nearby enemies.", "effect": &"wizard_nearby_damage_focus"}
		&"flame_left_1":
			return {"name": "Surge\nBlast", "description": "During Fire Surge, your left-click Fireballs have 50% increased explosion radius and 90% reduced travel distance.", "effect": &"wizard_fire_surge_left_click_blast"}
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
		&"flame_left_11":
			return {"name": "Vital\nFire", "description": "Your Fireballs deal bonus damage equal to 10% of your maximum HP.", "effect": &"wizard_fireball_max_hp_bonus_damage"}
		&"flame_left_12":
			return {"name": "Arcane\nMight", "description": "Increase your ATK by 20%.", "stat": &"atk", "operation": &"multiply_add", "value": 0.2}
		&"flame_left_13":
			return {"name": "Might\nBloom", "description": "For every 10 ATK you have, your Fireball explosion radius increases by 20%.", "effect": &"wizard_fireball_radius_per_atk"}
		&"flame_bridge_center_0":
			return {"name": "Fire\nEssence", "description": "Picking up 10 gold grants 1 Fire Essence, up to 4 stored. Your next left-click attack consumes 1 Fire Essence to fire three extra Fireballs.", "effect": &"wizard_fire_essence_burst"}
		&"flame_center_0":
			return {"name": "After\nBurn", "description": "Gain 1% movement speed for every 10 gold you have.", "effect": &"wizard_gold_move_speed_bonus"}
		&"flame_center_1":
			return {"name": "Surge\nRing", "description": "Fire Surge now fires eight Fireballs in all directions every 5s.", "effect": &"wizard_fire_surge_radial_fireballs"}
		&"flame_center_2":
			return {"name": "Vital\nEcho", "description": "For every 100 max HP you have, your left-click attack repeats once after 0.2s. If it consumed Fire Essence, the repeats use the four-Fireball version.", "effect": &"wizard_max_hp_primary_echo"}
		&"flame_center_3":
			return {"name": "Swift\nVolley", "description": "For every 50 gold you have, your left-click attack fires 1 extra Fireball at a 10-degree offset without changing the original Fireball angle.", "effect": &"wizard_move_speed_extra_fireballs"}
		&"flame_center_4":
			return {"name": "Venom\nBurst", "description": "Poisoned enemies drop 1 extra gold when they die.", "effect": &"wizard_poisoned_death_extra_gold"}
		&"flame_center_5":
			return {"name": "Rare\nCredit", "description": "Each rare item you have makes you count as having 10 extra gold.", "effect": &"wizard_rare_item_move_speed"}
		&"flame_center_6":
			return {"name": "Essence\nSpiral", "description": "After consuming Fire Essence, your next left-click Fireball explosion releases eight Fireballs in a spinning burst.", "effect": &"wizard_fire_essence_explosion_scatter"}
		&"flame_center_7":
			return {"name": "Legendary\nMarket", "description": "Your shop always has at least one legendary jar. Legendary jars cost double.", "effect": &"wizard_guaranteed_legendary_shop_jar"}
		&"flame_center_8":
			return {"name": "Piercing\nBloom", "description": "Your Fireballs pierce enemies indefinitely, dealing impact damage on hit without exploding. They only explode when their flight ends naturally.", "effect": &"wizard_natural_fireball_radius"}
		&"flame_center_9":
			return {"name": "Legendary\nEmbers", "description": "For each legendary item you have, every Fireball source fires 1 additional Fireball.", "effect": &"wizard_legendary_extra_fireballs"}
		&"flame_center_10":
			return {"name": "Rebound\nAsh", "description": "Your Fireballs bounce when they hit walls, and their flight distance is doubled.", "effect": &"wizard_natural_fireball_heal"}
		&"flame_center_11":
			return {"name": "Kinetic\nBloom", "description": "Your movement speed bonus also applies to your Fireball travel speed.", "effect": &"wizard_damage_taken_natural_explode_fireballs"}
		&"flame_center_12":
			return {"name": "Wild\nSparks", "description": "All Fireballs from all sources are doubled, but every Fireball launches in a random direction.", "effect": &"wizard_random_double_fireballs"}
		&"flame_right_0":
			return {"name": "Quick\nVitality", "description": "Killing an enemy that has lived for less than 2s grants 1 max HP, up to 20 per round.", "effect": &"wizard_quick_kill_max_hp"}
		&"flame_right_1":
			return {"name": "Opening\nBounty", "description": "For the first 10s of each round, enemies drop double gold.", "effect": &"wizard_early_round_enemy_gold"}
		&"flame_right_2":
			return {"name": "Jar\nBurst", "description": "Your Fireballs explode when they hit containers.", "effect": &"wizard_fireball_explodes_on_containers"}
		&"flame_right_3":
			return {"name": "Jar\nFlare", "description": "Breaking a container has 10% chance to trigger a Fire Laser. Your Fire Lasers no longer break containers.", "effect": &"wizard_container_break_laser_no_container_damage"}
		&"flame_right_4":
			return {"name": "Venom\nRay", "description": "When a poisoned enemy dies, trigger a Fire Laser from its position.", "effect": &"wizard_poisoned_death_fire_laser"}
		&"flame_right_5":
			return {"name": "Surge\nHaste", "description": "During Fire Surge, gain 50% attack speed.", "effect": &"wizard_fire_surge_attack_speed"}
		&"flame_right_6":
			return {"name": "Slide\nMomentum", "description": "After sliding, gain 5% attack speed and movement speed for 5s, stacking up to 50%.", "effect": &"wizard_slide_momentum"}
		&"flame_right_7":
			return {"name": "Living\nCircuit", "description": "Your Fire Lasers can chain to you, healing 1 HP without dealing damage.", "effect": &"wizard_fire_laser_chain_heals_player"}
		&"flame_right_8":
			return {"name": "Arc\nFocus", "description": "Your Fire Lasers deal 20% more damage for each chain.", "effect": &"wizard_fire_laser_chain_damage"}
		&"flame_right_9":
			return {"name": "Slide\nRay", "description": "After sliding, trigger a Fire Laser in your slide direction.", "effect": &"wizard_slide_fire_laser"}
		&"flame_right_10":
			return {"name": "Opening\nSurge", "description": "Gain 50% attack speed for the first 10s of each round.", "effect": &"wizard_opening_attack_speed"}
		&"flame_right_11":
			return {"name": "Storm\nCast", "description": "Your attacks have 50% chance to trigger Chain Lightning.", "stat": &"chain_lightning_chance", "value": 0.5}
		&"flame_right_12":
			return {"name": "Storm\nTempo", "description": "Each enemy hit by Chain Lightning grants 2% attack speed for 3s, up to 50%.", "effect": &"wizard_chain_lightning_attack_speed_stack"}
		&"flame_right_13":
			return {"name": "Storm\nBloom", "description": "Fireball explosions trigger Chain Lightning.", "effect": &"wizard_fireball_explosion_chain_lightning"}
		&"spark_4":
			return {"name": "Elite\nSpoils", "description": "Combat container count is increased by 100%. When a container breaks, it has a 1% chance to summon 2 elite enemies.", "effect": &"wizard_double_containers_elite_break"}
		&"spark_5":
			return {"name": "Wide\nSpoils", "description": "Map size and combat container count are increased by 30%.", "effect": &"wizard_large_map_more_containers"}
		&"spark_6":
			return {"name": "Surge\nBloom", "description": "Fireballs fired by Fire Surge have 90% reduced range and 30% increased explosion radius.", "effect": &"wizard_fire_surge_short_fireballs"}
		&"spark_7":
			return {"name": "Close\nSpark", "description": "Deal 50% increased damage to nearby enemies and 50% reduced damage to enemies that are not nearby.", "effect": &"wizard_spark_nearby_damage_focus"}
		&"spark_8":
			return {"name": "Focused\nRay", "description": "Your Fire Lasers have 80% reduced range and deal 500% increased damage.", "effect": &"wizard_short_laser_massive_damage"}
		&"spark_1":
			return {"name": "Critical\nVolley", "description": "Your left-click critical hits no longer deal extra damage. When your left-click attack crits, fire 1 additional Fireball for every 50% critical damage bonus you have.", "effect": &"wizard_primary_crit_extra_fireballs"}
		&"spark_9":
			return {"name": "Still\nCharge", "description": "Stand still to charge your left-click Fireballs, gaining 10% explosion radius every 0.2s, up to 100%. Moving or casting the left-click attack resets the charge.", "effect": &"wizard_stationary_primary_fireball_radius_charge"}
		&"spark_10":
			return {"name": "Still\nForce", "description": "Stand still to charge your next left-click Fireballs, gaining 10% Fireball damage every 0.2s, up to 50%. Moving or casting the left-click attack resets the charge.", "effect": &"wizard_stationary_primary_fireball_damage_charge"}
		&"spark_11":
			return {"name": "Still\nBurst", "description": "While standing still, trigger a Fireball explosion at your position every 2s.", "effect": &"wizard_stationary_fireball_explosion"}
		&"spark_12":
			return {"name": "Hovering\nSpark", "description": "Your left-click Fireball summons hovering Fireballs around the mouse position instead. Fire Essence and Vital Echo add more hovering Fireballs. They fire Fire Lasers at the nearest enemy at 50% attack speed, last 2s, and are capped at 10.", "effect": &"wizard_hovering_fireball"}
		&"spark_13":
			return {"name": "Dash\nVolley", "description": "After dashing, your next left-click attack fires 1 additional Fireball, stacking up to 3 times. Casting the left-click attack resets the stacks.", "effect": &"wizard_dash_primary_fireball_stacks"}
		&"spark_14":
			return {"name": "Relay\nSpark", "description": "Your Fire Lasers gain 3 chains and can only chain to your hovering Fireballs.", "effect": &"wizard_fire_laser_hovering_fireball_chain"}
		&"spark_15":
			return {"name": "Gold\nSpark", "description": "Your Fireball explosions no longer deal damage, but have a 10% chance to spawn 1 gold.", "effect": &"wizard_fireball_explosion_gold"}
		&"spark_16":
			return {"name": "Toxic\nSpark", "description": "When your Fireballs hit enemies, they have a 30% chance to Poison and a 5% chance to Stun.", "effect": &"wizard_fireball_impact_poison_stun"}
		&"spark_17":
			return {"name": "Brittle\nSpark", "description": "When your Fireballs hit enemies, they apply Vulnerable. Each Vulnerable stack makes the unit take 5% increased damage, stacking additively.", "effect": &"wizard_fireball_impact_vulnerable"}
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
	_add_path(result, [&"flame_bottom_2", &"flame_bottom_3", &"flame_bottom_4"])
	_add_path(result, [&"flame_bottom_6", &"flame_bottom_7", &"flame_bottom_8"])
	_add_path(result, _ids("flame_left", 14))
	_add_path(result, _ids("flame_center", 13))
	_add_path(result, _ids("flame_right", 14))
	_add_path(result, _branch_ids(&"flame_bottom_5", "flame_left_start", 5, &"flame_bottom_4"))
	_add_path(result, _branch_ids(&"flame_bottom_5", "flame_center_start", 5, &"flame_bridge_center_0"))
	_add_path(result, _branch_ids(&"flame_bottom_5", "flame_right_start", 5, &"flame_bottom_6"))
	result.append([&"flame_bottom_2", &"flame_left_0"])
	result.append([&"flame_bridge_center_0", &"flame_center_0"])
	result.append([&"flame_bottom_8", &"flame_right_0"])
	result.append([&"flame_left_5", &"spark_6"])
	result.append([&"flame_center_5", &"spark_1"])
	result.append([&"flame_center_0", &"spark_15"])
	result.append([&"flame_right_4", &"spark_5"])
	result.append([&"flame_bottom_3", &"spark_9"])
	result.append([&"flame_bottom_8", &"spark_12"])
	_add_path(result, [&"spark_0", &"spark_1", &"spark_2"])
	_add_path(result, [&"spark_3", &"spark_4", &"spark_5"])
	_add_path(result, [&"spark_6", &"spark_7", &"spark_8"])
	_add_path(result, [&"spark_9", &"spark_10", &"spark_11"])
	_add_path(result, [&"spark_12", &"spark_13", &"spark_14"])
	_add_path(result, [&"spark_15", &"spark_16", &"spark_17"])
	return result


static func incompatible_nodes() -> Array:
	return [
		[&"spark_15", &"flame_bottom_6"],
		[&"spark_0", &"spark_2"],
	]


static func start_nodes() -> Array[StringName]:
	return START_IDS.duplicate()


static func _ids(prefix: String, count: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for index in range(count):
		result.append(StringName("%s_%d" % [prefix, index]))
	return result


static func _branch_ids(start_id: StringName, prefix: String, count: int, end_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = [start_id]
	result.append_array(_ids(prefix, count))
	result.append(end_id)
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
			positions[id] = marker.global_position
	root.free()
	_layout_position_cache = positions
	return _layout_position_cache
