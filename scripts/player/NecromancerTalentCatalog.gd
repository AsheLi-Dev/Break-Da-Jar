extends RefCounted
class_name NecromancerTalentCatalog

const LAYOUT_SCENE: PackedScene = preload("res://scenes/player/NecromancerTalentLayout.tscn")
const START_IDS: Array[StringName] = [&"tooth_4"]

const POSITIONS := {
	&"skull_top_0": Vector2(178, 176),
	&"skull_top_1": Vector2(210, 112),
	&"skull_top_2": Vector2(265, 70),
	&"skull_top_3": Vector2(327, 52),
	&"skull_top_4": Vector2(390, 52),
	&"skull_top_5": Vector2(452, 70),
	&"skull_top_6": Vector2(507, 112),
	&"skull_top_7": Vector2(542, 176),
	&"left_temple": Vector2(160, 248),
	&"left_cheek_high": Vector2(148, 330),
	&"left_cheek_low": Vector2(162, 430),
	&"left_jaw": Vector2(218, 530),
	&"left_chin": Vector2(255, 660),
	&"right_temple": Vector2(558, 248),
	&"right_cheek_high": Vector2(572, 330),
	&"right_cheek_low": Vector2(558, 430),
	&"right_jaw": Vector2(502, 530),
	&"right_chin": Vector2(465, 660),
	&"chin_center": Vector2(360, 722),
	&"left_eye_0": Vector2(245, 332),
	&"left_eye_1": Vector2(285, 305),
	&"left_eye_2": Vector2(333, 322),
	&"left_eye_3": Vector2(338, 380),
	&"left_eye_4": Vector2(290, 410),
	&"left_eye_5": Vector2(238, 390),
	&"right_eye_0": Vector2(385, 322),
	&"right_eye_1": Vector2(433, 305),
	&"right_eye_2": Vector2(475, 332),
	&"right_eye_3": Vector2(482, 390),
	&"right_eye_4": Vector2(430, 410),
	&"right_eye_5": Vector2(382, 380),
	&"nose_top": Vector2(360, 430),
	&"nose_bridge_high": Vector2(360, 470),
	&"nose_left": Vector2(330, 510),
	&"nose_bottom": Vector2(360, 550),
	&"nose_right": Vector2(390, 510),
	&"nose_bridge_low": Vector2(360, 510),
	&"philtrum": Vector2(361, 604),
	&"tooth_0": Vector2(250, 620),
	&"tooth_1": Vector2(278, 640),
	&"tooth_2": Vector2(306, 650),
	&"tooth_3": Vector2(334, 656),
	&"tooth_4": Vector2(362, 658),
	&"tooth_5": Vector2(390, 656),
	&"tooth_6": Vector2(418, 650),
	&"tooth_7": Vector2(446, 640),
	&"tooth_8": Vector2(474, 620),
	&"mouth_left": Vector2(238, 570),
	&"mouth_right": Vector2(482, 570),
}

static var _layout_position_cache: Dictionary = {}


static func node_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in POSITIONS.keys():
		ids.append(id)
	return ids


static func definition(id: StringName) -> Dictionary:
	match id:
		&"skull_top_1":
			return {"name": "Jar\nBones", "description": "Breaking combat jars has a 10% chance to trigger your right-click Skeleton Archer summon at the jar. Skeleton Archer cap increases by 1.", "effect": &"necromancer_container_break_skeleton_archer"}
		&"skull_top_2":
			return {"name": "Death\nBones", "description": "Killing an enemy has a 10% chance to trigger your right-click Skeleton Archer summon at the enemy. Skeleton Archer cap increases by 2.", "effect": &"necromancer_kill_skeleton_archer"}
		&"tooth_0":
			return {"name": "Bone\nPatience", "description": "Skeleton Archers gain 2% increased damage for each full second they remain alive.", "effect": &"necromancer_skeleton_archer_damage_growth"}
		&"mouth_left":
			return {"name": "Venom\nArrow", "description": "Skeleton Archer attacks have 20% chance to apply Poison.", "effect": &"necromancer_skeleton_archer_poison_chance"}
		&"mouth_right":
			return {"name": "Blood\nSiphon", "description": "Soul Siphon has 20% chance to apply Bleeding.", "effect": &"necromancer_soul_siphon_bleed_chance"}
		&"tooth_4":
			return {"name": "Soul\nSiphon", "description": "Left-click Soul Siphon deals 15% increased damage.", "effect": &"necromancer_soul_siphon_damage_bonus"}
		&"tooth_3":
			return {"name": "Bone\nBow", "description": "Skeleton Archers summoned by right-click deal 15% increased damage.", "effect": &"necromancer_skeleton_archer_damage_bonus"}
		&"tooth_5":
			return {"name": "Quick\nRite", "description": "Gain +15% attack speed.", "stat": &"attack_speed_bonus", "value": 0.15}
		&"nose_bottom":
			return {"name": "Bone\nLesson", "description": "Every 10 enemy kills grants 1 XP.", "effect": &"necromancer_xp_per_10_kills"}
		&"nose_left":
			return {"name": "Bone\nOffering", "description": "Every 20 enemy kills permanently grants +1 ATK.", "effect": &"necromancer_atk_per_20_kills"}
		&"nose_right":
			return {"name": "Bone\nVitality", "description": "Every 10 enemy kills permanently grants +1 maximum HP.", "effect": &"necromancer_max_hp_per_10_kills"}
		&"tooth_2":
			return {"name": "Quick\nDraw", "description": "Skeleton Archers summoned by right-click attack 15% faster.", "effect": &"necromancer_skeleton_archer_attack_speed_bonus"}
		&"tooth_1":
			return {"name": "Slide\nDraw", "description": "After sliding, Skeleton Archers attack 20% faster for 2 seconds.", "effect": &"necromancer_slide_skeleton_archer_attack_speed"}
		&"tooth_6":
			return {"name": "Slide\nSiphon", "description": "After sliding, your next Soul Siphon deals 30% increased damage.", "effect": &"necromancer_slide_soul_siphon_damage_bonus"}
		&"tooth_7":
			return {"name": "Bone\nPlating", "description": "Every 10 enemy kills permanently grants +1 Defense.", "effect": &"necromancer_defense_per_10_kills"}
		&"nose_top":
			return {"name": "Bone\nTithe", "description": "Every 10 enemy kills grants 1 gold.", "effect": &"necromancer_gold_per_10_kills"}
		&"left_eye_3":
			return {"name": "Toxic\nGaze", "description": "Enemies take 5% increased damage for each Poison stack on them.", "effect": &"necromancer_poison_stack_damage"}
		&"left_eye_0":
			return {"name": "Black\nPursuit", "description": "At the start of each combat round, a slow black shadow spawns 600px away and chases you, dealing 100% ATK damage per second to every target it touches, including you. It disappears when the round ends.", "effect": &"necromancer_black_shadow_pursuit"}
		&"left_eye_1":
			return {"name": "Shadow\nDrift", "description": "During each combat round, gain 5% movement speed every second. This resets when the round ends.", "effect": &"necromancer_round_movement_speed_per_second"}
		&"right_eye_5":
			return {"name": "Blood\nChill", "description": "Bleeding enemies move 20% slower.", "effect": &"necromancer_bleeding_move_speed_slow"}
		&"right_eye_2":
			return {"name": "Death\nBurst", "description": "Enemies explode on death, dealing 50% ATK damage to nearby enemies and the player.", "effect": &"necromancer_enemy_death_explosion"}
		&"right_eye_1":
			return {"name": "Blood\nDebt", "description": "Enemy deaths grant +1 ATK. Taking damage removes 2 ATK gained this way.", "effect": &"necromancer_kill_atk_damage_loss"}
		&"left_eye_2":
			return {"name": "Long\nDrift", "description": "Dash distance increases by extending dash duration by 30%.", "effect": &"necromancer_dash_duration_bonus"}
		&"left_eye_4":
			return {"name": "Grave\nHaste", "description": "Attacks that hit enemies grant +5 movement speed for 3 seconds. This can stack without limit.", "effect": &"necromancer_hit_move_speed_stack"}
		&"right_eye_4":
			return {"name": "Patient\nSiphon", "description": "Your next left-click attack gains 10% damage each second, up to 100%. Left-clicking resets this bonus.", "effect": &"necromancer_charged_primary_damage"}
		&"left_jaw":
			return {"name": "Bone\nLegion", "description": "Skeleton Archers last twice as long and your Skeleton Archer cap increases by 1.", "effect": &"necromancer_skeleton_archer_lifetime_and_cap"}
		&"right_jaw":
			return {"name": "Siphon\nCommand", "description": "Soul Siphon grants hit Skeleton Archers +100% attack speed for 2 seconds. They die when it ends.", "effect": &"necromancer_soul_siphon_skeleton_archer_attack_speed"}
		&"left_chin":
			return {"name": "Bone\nTally", "description": "Every 10 enemy kills permanently grants Skeleton Archers +1% damage.", "effect": &"necromancer_skeleton_archer_damage_per_10_kills"}
		&"right_chin":
			return {"name": "Siphon\nTally", "description": "Every 10 enemy kills permanently grants left-click attacks +1% damage.", "effect": &"necromancer_primary_damage_per_10_kills"}
		&"skull_top_3", &"skull_top_4":
			return {"name": "Crown\nof Bone", "description": "Gain +2 ATK.", "stat": &"atk", "value": 2.0}
		&"skull_top_6":
			return {"name": "Bone\nInheritance", "description": "When your Skeleton Archers die, gain +5 ATK until the round ends.", "effect": &"necromancer_skeleton_archer_death_round_atk"}
		&"skull_top_0":
			return {"name": "Marked\nBones", "description": "Skeleton Archers deal 50% increased damage to the enemy most recently damaged by your left-click attack.", "effect": &"necromancer_skeleton_archer_marked_target_damage"}
		&"skull_top_7":
			return {"name": "Bone\nMarked", "description": "You deal 30% increased damage to the enemy most recently damaged by your Skeleton Archers.", "effect": &"necromancer_primary_damage_to_skeleton_marked_target"}
		&"left_temple":
			return {"name": "Marrow\nFeast", "description": "When your Skeleton Archers kill an enemy, heal for 10% of your maximum health.", "effect": &"necromancer_skeleton_archer_kill_heal"}
		&"right_temple":
			return {"name": "Death\nBloom", "description": "When you kill an enemy, recover 5% of your maximum health over 3 seconds.", "effect": &"necromancer_kill_heal_over_time"}
		&"tooth_8":
			return {"name": "Choir\nSiphon", "description": "Soul Siphon deals 10% increased damage for each active Skeleton Archer.", "effect": &"necromancer_soul_siphon_damage_per_skeleton_archer"}
		&"chin_center":
			return {"name": "Death\nMask", "description": "Gain +3 ATK.", "stat": &"atk", "value": 3.0}
		_:
			return {"name": "Bone\nRite", "description": "Gain +1 ATK.", "stat": &"atk", "value": 1.0}


static func display_name(id: StringName) -> String:
	return String(definition(id).get("name", "+1 ATK"))


static func description(id: StringName) -> String:
	return String(definition(id).get("description", "+1 ATK"))


static func position(id: StringName) -> Vector2:
	return _layout_positions().get(id, POSITIONS.get(id, Vector2.ZERO))


static func grid_position(id: StringName) -> Vector2i:
	var position_value: Vector2 = position(id)
	return Vector2i(roundi(position_value.x), roundi(position_value.y))


static func connections() -> Array:
	var result: Array = []
	_add_path(result, [&"skull_top_0", &"skull_top_1", &"skull_top_2", &"skull_top_3", &"skull_top_4", &"skull_top_5", &"skull_top_6", &"skull_top_7"])
	_add_path(result, [&"skull_top_0", &"left_temple", &"left_cheek_high", &"left_cheek_low", &"left_jaw", &"left_chin", &"chin_center", &"right_chin", &"right_jaw", &"right_cheek_low", &"right_cheek_high", &"right_temple", &"skull_top_7"])
	_add_loop(result, [&"left_eye_0", &"left_eye_1", &"left_eye_2", &"left_eye_3", &"left_eye_4", &"left_eye_5"])
	_add_loop(result, [&"right_eye_0", &"right_eye_1", &"right_eye_2", &"right_eye_3", &"right_eye_4", &"right_eye_5"])
	_add_loop(result, [&"nose_top", &"nose_left", &"nose_bottom", &"nose_right"])
	_add_path(result, [&"mouth_left", &"tooth_0", &"tooth_1", &"tooth_2", &"tooth_3", &"tooth_4", &"tooth_5", &"tooth_6", &"tooth_7", &"tooth_8", &"mouth_right"])
	_add_path(result, [&"mouth_left", &"left_jaw"])
	_add_path(result, [&"mouth_right", &"right_jaw"])
	_add_path(result, [&"tooth_4", &"philtrum", &"nose_bottom", &"nose_bridge_low", &"nose_bridge_high", &"nose_top"])
	_add_path(result, [&"left_eye_3", &"nose_top", &"right_eye_5"])
	_add_path(result, [&"tooth_2", &"left_chin"])
	_add_path(result, [&"tooth_6", &"right_chin"])
	return result


static func start_nodes() -> Array[StringName]:
	return START_IDS.duplicate()


static func _add_path(result: Array, ids: Array[StringName]) -> void:
	for index in range(ids.size() - 1):
		result.append([ids[index], ids[index + 1]])


static func _add_loop(result: Array, ids: Array[StringName]) -> void:
	_add_path(result, ids)
	if ids.size() > 2:
		result.append([ids[ids.size() - 1], ids[0]])


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
