extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const NECROMANCER_TALENT_CATALOG := preload("res://scripts/player/NecromancerTalentCatalog.gd")
const NECROMANCER_SHADOW_SCRIPT := preload("res://systems/combat/NecromancerShadow.gd")

var failures: Array[String] = []
var passed_assertions: int = 0
var scene_root: GoldProbeScene
var player: Player


class GoldProbeScene:
	extends Node2D

	var gold: int = 0
	var gold_reasons: Array[String] = []

	func add_player_gold(amount: int, reason: String = "") -> void:
		gold += amount
		gold_reasons.append(reason)


class PoisonProbeEnemy:
	extends Node2D

	var poison_stacks: int = 0
	var bleeding_stacks: int = 0
	var last_damage: float = 0.0
	var last_attack_info: Dictionary = {}

	func take_damage(amount: float, _source: Node = null, _attack_info: Dictionary = {}) -> float:
		last_damage = amount
		last_attack_info = _attack_info
		return amount

	func apply_status_effect(id: StringName, _source_player: Node = null) -> void:
		if id == &"poison":
			poison_stacks += 1
		elif id == &"bleeding":
			bleeding_stacks += 1

	func get_poison_stacks() -> int:
		return poison_stacks


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("NecromancerCharacterTest: starting")
	await process_frame

	scene_root = GoldProbeScene.new()
	root.add_child(scene_root)
	current_scene = scene_root

	player = PLAYER_SCENE.instantiate() as Player
	_assert(player != null, "Player scene instantiates")
	if player != null:
		player.setup_character(&"necromancer")
		scene_root.add_child(player)
		await process_frame
		_test_definition()
		_test_textures()
		await _test_talent_catalog()
		await _test_primary_beam()
		await _test_secondary_skeleton_archer()
		_test_soul_surge()

	_cleanup()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	_finish()


func _test_definition() -> void:
	_assert(player.character_definition.id == &"necromancer", "Necromancer definition is selected")
	_assert(player.character_definition.display_name == "Necromancer", "Necromancer display name is set")
	_assert(player.primary_ability == &"necromancer_soul_beam", "Necromancer primary ability is Soul Beam")
	_assert(player.secondary_ability == &"necromancer_skeleton_archer", "Necromancer secondary ability is Skeleton Archer")
	_assert(player.utility_ability == &"necromancer_soul_surge", "Necromancer utility ability is Soul Surge")
	_assert(player.talent_catalog == NECROMANCER_TALENT_CATALOG, "Necromancer uses its skull talent catalog")
	_assert(is_equal_approx(player.max_hp, 80.0), "Necromancer max HP matches source role")
	_assert(is_equal_approx(player.projectile_damage, 14.0), "Necromancer base damage matches source role")
	_assert(is_equal_approx(player.fire_rate, 1.4), "Necromancer attack cadence matches source role")


func _test_textures() -> void:
	for animation_name in [&"idle", &"run", &"attack", &"ability", &"pummel", &"rolling", &"slide_start", &"slide_end", &"damage", &"death"]:
		var texture: Texture2D = player.character_definition.get_texture(animation_name)
		_assert(texture != null, "Necromancer texture loads: %s" % animation_name)


func _test_talent_catalog() -> void:
	player.unspent_talent_points = 1
	var ids := player.get_talent_node_ids()
	_assert(ids.has(&"tooth_4"), "Necromancer skull talent tree has a center tooth start node")
	_assert(ids.has(&"philtrum"), "Necromancer skull talent tree has a node between tooth 4 and nose bottom")
	_assert(ids.has(&"nose_bridge_low") and ids.has(&"nose_bridge_high"), "Necromancer skull talent tree has two nodes between nose bottom and nose top")
	_assert(ids.has(&"left_eye_0") and ids.has(&"right_eye_0"), "Necromancer skull talent tree has eye sockets")
	_assert(ids.has(&"nose_top") and ids.has(&"chin_center"), "Necromancer skull talent tree has nose and chin nodes")
	_assert(player.can_unlock_talent(&"tooth_4"), "Necromancer skull tree starts from the center tooth")
	_assert(not player.can_unlock_talent(&"nose_top"), "Necromancer skull tree locks inner skull nodes until connected")
	_assert(player.get_talent_display_name(&"tooth_4") == "Soul\nSiphon", "Necromancer tooth 4 names the Soul Siphon talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_4").get("effect") == &"necromancer_soul_siphon_damage_bonus", "Necromancer tooth 4 grants Soul Siphon damage")
	_assert(player.get_talent_display_name(&"tooth_3") == "Bone\nBow", "Necromancer tooth 3 names the Skeleton Archer damage talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_3").get("effect") == &"necromancer_skeleton_archer_damage_bonus", "Necromancer tooth 3 grants Skeleton Archer damage")
	_assert(player.get_talent_display_name(&"tooth_2") == "Quick\nDraw", "Necromancer tooth 2 names the Skeleton Archer attack speed talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_2").get("effect") == &"necromancer_skeleton_archer_attack_speed_bonus", "Necromancer tooth 2 grants Skeleton Archer attack speed")
	_assert(player.get_talent_display_name(&"tooth_1") == "Slide\nDraw", "Necromancer tooth 1 names the slide Skeleton Archer attack speed talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_1").get("effect") == &"necromancer_slide_skeleton_archer_attack_speed", "Necromancer tooth 1 grants slide Skeleton Archer attack speed")
	_assert(player.get_talent_display_name(&"tooth_0") == "Bone\nPatience", "Necromancer tooth 0 names the Skeleton Archer damage growth talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_0").get("effect") == &"necromancer_skeleton_archer_damage_growth", "Necromancer tooth 0 grants Skeleton Archer damage growth")
	_assert(player.get_talent_display_name(&"mouth_left") == "Venom\nArrow", "Necromancer mouth left names the Skeleton Archer poison talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"mouth_left").get("effect") == &"necromancer_skeleton_archer_poison_chance", "Necromancer mouth left grants Skeleton Archer poison chance")
	_assert(player.get_talent_display_name(&"left_jaw") == "Bone\nLegion", "Necromancer left jaw names the Skeleton Archer lifetime and cap talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"left_jaw").get("effect") == &"necromancer_skeleton_archer_lifetime_and_cap", "Necromancer left jaw grants Skeleton Archer lifetime and cap")
	_assert(player.get_talent_display_name(&"right_jaw") == "Siphon\nCommand", "Necromancer right jaw names the Soul Siphon Skeleton Archer attack speed talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"right_jaw").get("effect") == &"necromancer_soul_siphon_skeleton_archer_attack_speed", "Necromancer right jaw grants Skeleton Archer attack speed when hit by Soul Siphon")
	_assert(player.get_talent_display_name(&"skull_top_1") == "Jar\nBones", "Necromancer skull top 1 names the container Skeleton Archer talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"skull_top_1").get("effect") == &"necromancer_container_break_skeleton_archer", "Necromancer skull top 1 summons Skeleton Archers from broken containers")
	_assert(player.get_talent_display_name(&"skull_top_2") == "Death\nBones", "Necromancer skull top 2 names the kill Skeleton Archer talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"skull_top_2").get("effect") == &"necromancer_kill_skeleton_archer", "Necromancer skull top 2 summons Skeleton Archers from kills")
	_assert(player.get_talent_display_name(&"left_chin") == "Bone\nTally", "Necromancer left chin names the Skeleton Archer kill damage talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"left_chin").get("effect") == &"necromancer_skeleton_archer_damage_per_10_kills", "Necromancer left chin grants Skeleton Archer damage every 10 kills")
	_assert(player.get_talent_display_name(&"skull_top_0") == "Marked\nBones", "Necromancer skull top 0 names the marked Skeleton Archer damage talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"skull_top_0").get("effect") == &"necromancer_skeleton_archer_marked_target_damage", "Necromancer skull top 0 grants Skeleton Archer damage to recently left-clicked enemies")
	_assert(player.get_talent_display_name(&"left_temple") == "Marrow\nFeast", "Necromancer left temple names the Skeleton Archer kill heal talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"left_temple").get("effect") == &"necromancer_skeleton_archer_kill_heal", "Necromancer left temple heals when Skeleton Archers kill enemies")
	_assert(player.get_talent_display_name(&"right_temple") == "Death\nBloom", "Necromancer right temple names the kill heal-over-time talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"right_temple").get("effect") == &"necromancer_kill_heal_over_time", "Necromancer right temple heals over time after enemy kills")
	_assert(player.get_talent_display_name(&"skull_top_6") == "Bone\nInheritance", "Necromancer skull top 6 names the Skeleton Archer death ATK talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"skull_top_6").get("effect") == &"necromancer_skeleton_archer_death_round_atk", "Necromancer skull top 6 grants round ATK when Skeleton Archers die")
	_assert(player.get_talent_display_name(&"skull_top_7") == "Bone\nMarked", "Necromancer skull top 7 names the player damage to Skeleton Archer marked target talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"skull_top_7").get("effect") == &"necromancer_primary_damage_to_skeleton_marked_target", "Necromancer skull top 7 grants player damage to enemies recently damaged by Skeleton Archers")
	_assert(player.get_talent_display_name(&"right_chin") == "Siphon\nTally", "Necromancer right chin names the left-click kill damage talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"right_chin").get("effect") == &"necromancer_primary_damage_per_10_kills", "Necromancer right chin grants left-click damage every 10 kills")
	_assert(player.get_talent_display_name(&"mouth_right") == "Blood\nSiphon", "Necromancer mouth right names the Soul Siphon bleeding talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"mouth_right").get("effect") == &"necromancer_soul_siphon_bleed_chance", "Necromancer mouth right grants Soul Siphon bleeding chance")
	_assert(player.get_talent_display_name(&"tooth_5") == "Quick\nRite", "Necromancer tooth 5 names the attack speed talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_5").get("stat") == &"attack_speed_bonus", "Necromancer tooth 5 grants attack speed")
	_assert(is_equal_approx(float(NECROMANCER_TALENT_CATALOG.definition(&"tooth_5").get("value")), 0.15), "Necromancer tooth 5 grants 15 percent attack speed")
	_assert(player.get_talent_display_name(&"tooth_6") == "Slide\nSiphon", "Necromancer tooth 6 names the slide Soul Siphon talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_6").get("effect") == &"necromancer_slide_soul_siphon_damage_bonus", "Necromancer tooth 6 grants slide Soul Siphon damage")
	_assert(player.get_talent_display_name(&"tooth_7") == "Bone\nPlating", "Necromancer tooth 7 names the kill defense talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_7").get("effect") == &"necromancer_defense_per_10_kills", "Necromancer tooth 7 grants defense every 10 kills")
	_assert(player.get_talent_display_name(&"tooth_8") == "Choir\nSiphon", "Necromancer tooth 8 names the Skeleton Archer Soul Siphon talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"tooth_8").get("effect") == &"necromancer_soul_siphon_damage_per_skeleton_archer", "Necromancer tooth 8 grants Soul Siphon damage per Skeleton Archer")
	_assert(player.get_talent_display_name(&"nose_bottom") == "Bone\nLesson", "Necromancer nose bottom names the kill XP talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"nose_bottom").get("effect") == &"necromancer_xp_per_10_kills", "Necromancer nose bottom grants XP every 10 kills")
	_assert(player.get_talent_display_name(&"nose_left") == "Bone\nOffering", "Necromancer nose left names the kill ATK talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"nose_left").get("effect") == &"necromancer_atk_per_20_kills", "Necromancer nose left grants ATK every 20 kills")
	_assert(player.get_talent_display_name(&"nose_right") == "Bone\nVitality", "Necromancer nose right names the kill max HP talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"nose_right").get("effect") == &"necromancer_max_hp_per_10_kills", "Necromancer nose right grants max HP every 10 kills")
	_assert(player.get_talent_display_name(&"nose_top") == "Bone\nTithe", "Necromancer nose top names the kill gold talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"nose_top").get("effect") == &"necromancer_gold_per_10_kills", "Necromancer nose top grants gold every 10 kills")
	_assert(player.get_talent_display_name(&"left_eye_3") == "Toxic\nGaze", "Necromancer left eye 3 names the Poison stack damage talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"left_eye_3").get("effect") == &"necromancer_poison_stack_damage", "Necromancer left eye 3 grants damage per Poison stack")
	_assert(player.get_talent_display_name(&"left_eye_0") == "Black\nPursuit", "Necromancer left eye 0 names the Black Pursuit talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"left_eye_0").get("effect") == &"necromancer_black_shadow_pursuit", "Necromancer left eye 0 grants the chasing black shadow")
	_assert(player.get_talent_display_name(&"left_eye_1") == "Shadow\nDrift", "Necromancer left eye 1 names the round movement speed talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"left_eye_1").get("effect") == &"necromancer_round_movement_speed_per_second", "Necromancer left eye 1 grants movement speed each second during combat rounds")
	_assert(player.get_talent_display_name(&"left_eye_2") == "Long\nDrift", "Necromancer left eye 2 names the dash duration talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"left_eye_2").get("effect") == &"necromancer_dash_duration_bonus", "Necromancer left eye 2 grants increased dash duration")
	_assert(player.get_talent_display_name(&"right_eye_1") == "Blood\nDebt", "Necromancer right eye 1 names the kill ATK damage loss talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"right_eye_1").get("effect") == &"necromancer_kill_atk_damage_loss", "Necromancer right eye 1 grants kill ATK that is lost when damaged")
	_assert(player.get_talent_display_name(&"right_eye_2") == "Death\nBurst", "Necromancer right eye 2 names the enemy death explosion talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"right_eye_2").get("effect") == &"necromancer_enemy_death_explosion", "Necromancer right eye 2 grants enemy death explosions")
	_assert(player.get_talent_display_name(&"right_eye_4") == "Patient\nSiphon", "Necromancer right eye 4 names the charged left-click damage talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"right_eye_4").get("effect") == &"necromancer_charged_primary_damage", "Necromancer right eye 4 grants charged left-click damage")
	_assert(player.get_talent_display_name(&"right_eye_5") == "Blood\nChill", "Necromancer right eye 5 names the Bleeding slow talent")
	_assert(NECROMANCER_TALENT_CATALOG.definition(&"right_eye_5").get("effect") == &"necromancer_bleeding_move_speed_slow", "Necromancer right eye 5 slows Bleeding enemies")
	_assert(player.get_talent_display_name(&"philtrum") == "Bone\nRite", "Necromancer philtrum uses the default Bone Rite placeholder talent")
	_assert(player.get_talent_display_name(&"nose_bridge_low") == "Bone\nRite", "Necromancer low nose bridge uses the default Bone Rite placeholder talent")
	_assert(player.get_talent_display_name(&"nose_bridge_high") == "Bone\nRite", "Necromancer high nose bridge uses the default Bone Rite placeholder talent")
	player.unlocked_talents.append(&"tooth_4")
	var base_attack_speed_bonus := player.get_stats().attack_speed_bonus
	_assert(player.unlock_talent(&"tooth_5"), "Necromancer tooth 5 unlocks from tooth 4")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, base_attack_speed_bonus + 0.15), "Necromancer tooth 5 applies 15 percent attack speed")
	player.unspent_talent_points = 1
	player.experience = 0
	_assert(player.unlock_talent(&"philtrum"), "Necromancer philtrum unlocks from tooth 4")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"nose_bottom"), "Necromancer nose bottom unlocks from philtrum")
	for index in range(9):
		_notify_dummy_kill()
	_assert(player.experience == 0, "Necromancer nose bottom waits for 10 kills before granting XP")
	_assert(int(player.get("necromancer_xp_kill_counter")) == 9, "Necromancer nose bottom tracks partial kill progress")
	_notify_dummy_kill()
	_assert(player.experience == 1, "Necromancer nose bottom grants 1 XP every 10 kills")
	_assert(int(player.get("necromancer_xp_kill_counter")) == 0, "Necromancer nose bottom resets kill counter after granting XP")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"nose_left"), "Necromancer nose left unlocks from nose bottom")
	var base_atk := player.get_stats().atk
	for index in range(19):
		_notify_dummy_kill()
	_assert(player.get_stats().atk == base_atk, "Necromancer nose left waits for 20 kills before granting ATK")
	_assert(int(player.get("necromancer_atk_kill_counter")) == 19, "Necromancer nose left tracks partial kill progress")
	_notify_dummy_kill()
	_assert(player.get_stats().atk == base_atk + 1, "Necromancer nose left grants 1 ATK every 20 kills")
	_assert(int(player.get("necromancer_atk_kill_counter")) == 0, "Necromancer nose left resets kill counter after granting ATK")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"nose_right"), "Necromancer nose right unlocks from nose bottom")
	var base_max_hp := player.get_stats().max_hp
	for index in range(9):
		_notify_dummy_kill()
	_assert(player.get_stats().max_hp == base_max_hp, "Necromancer nose right waits for 10 kills before granting max HP")
	_assert(int(player.get("necromancer_max_hp_kill_counter")) == 9, "Necromancer nose right tracks partial kill progress")
	_notify_dummy_kill()
	_assert(player.get_stats().max_hp == base_max_hp + 1, "Necromancer nose right grants 1 max HP every 10 kills")
	_assert(roundi(player.max_hp) == base_max_hp + 1, "Necromancer nose right syncs Player max HP")
	_assert(int(player.get("necromancer_max_hp_kill_counter")) == 0, "Necromancer nose right resets kill counter after granting max HP")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"nose_bridge_low"), "Necromancer low nose bridge unlocks from nose bottom")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"nose_bridge_high"), "Necromancer high nose bridge unlocks from low nose bridge")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"nose_top"), "Necromancer nose top unlocks from high nose bridge")
	for index in range(9):
		_notify_dummy_kill()
	_assert(scene_root.gold == 0, "Necromancer nose top waits for 10 kills before granting gold")
	_assert(int(player.get("necromancer_gold_kill_counter")) == 9, "Necromancer nose top tracks partial kill progress")
	_notify_dummy_kill()
	_assert(scene_root.gold == 1, "Necromancer nose top grants 1 gold every 10 kills")
	_assert(int(player.get("necromancer_gold_kill_counter")) == 0, "Necromancer nose top resets kill counter after granting gold")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"left_eye_3"), "Necromancer left eye 3 unlocks from nose top")
	var poison_damage_enemy := PoisonProbeEnemy.new()
	poison_damage_enemy.poison_stacks = 4
	player.deal_player_damage_to_enemy(poison_damage_enemy, 100.0, {"source": "necromancer_test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(poison_damage_enemy.last_damage, 100.0 * player.get_stats().get_damage_multiplier() * 1.2), "Necromancer left eye 3 increases damage by 5 percent per Poison stack")
	poison_damage_enemy.free()
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"left_eye_4"), "Necromancer left eye 4 unlocks from left eye 3")
	var base_hit_move_speed := player.get_stats().bonus_move_speed_flat
	var hit_move_speed_enemy := PoisonProbeEnemy.new()
	player.deal_player_damage_to_enemy(hit_move_speed_enemy, 100.0, {"source": "necromancer_test", "direct": true, "allow_procs": false, "allow_crit": false})
	player.deal_player_damage_to_enemy(hit_move_speed_enemy, 100.0, {"source": "necromancer_test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(player.get_stats().bonus_move_speed_flat, base_hit_move_speed + 10.0), "Necromancer left eye 4 grants 5 move speed per enemy hit and stacks")
	player.temporary_buffs.call("_process", 3.1)
	_assert(is_equal_approx(player.get_stats().bonus_move_speed_flat, base_hit_move_speed), "Necromancer left eye 4 hit move speed stacks expire after 3 seconds")
	hit_move_speed_enemy.free()
	player.unspent_talent_points = 1
	var base_dash_duration := float(player.call("_get_effective_dash_duration"))
	_assert(player.unlock_talent(&"left_eye_2"), "Necromancer left eye 2 unlocks from the eye loop")
	_assert(is_equal_approx(float(player.call("_get_effective_dash_duration")), base_dash_duration * 1.3), "Necromancer left eye 2 extends dash duration by 30 percent")
	player.unspent_talent_points = 1
	var base_movement_speed_bonus := player.get_stats().movement_speed_bonus
	_assert(player.unlock_talent(&"left_eye_1"), "Necromancer left eye 1 unlocks from the eye loop")
	player.call("emit_round_started", 98)
	player.call("_update_necromancer_round_movement_speed", 2.1)
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, base_movement_speed_bonus + 0.1), "Necromancer left eye 1 grants 5 percent movement speed each second during the round")
	player.call("emit_round_ended")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, base_movement_speed_bonus), "Necromancer left eye 1 movement speed resets after the round ends")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"left_eye_0"), "Necromancer left eye 0 unlocks from the eye loop")
	_assert(player.get("necromancer_black_shadow") == null, "Necromancer left eye 0 does not spawn a black shadow during shop or between rounds")
	player.call("emit_round_started", 99)
	var shadow := player.get("necromancer_black_shadow") as Node2D
	_assert(shadow != null and is_instance_valid(shadow), "Necromancer left eye 0 spawns a chasing black shadow when a combat round starts")
	_assert(shadow != null and is_equal_approx(shadow.global_position.distance_to(player.global_position), 600.0), "Necromancer black shadow starts 600px from the player")
	var shadow_start_position := shadow.global_position
	shadow.call("_process", 0.5)
	_assert(shadow.global_position.distance_to(player.global_position) < shadow_start_position.distance_to(player.global_position), "Necromancer black shadow slowly chases the player")
	shadow.global_position = player.global_position
	var shadow_enemy := PoisonProbeEnemy.new()
	shadow_enemy.add_to_group("enemy")
	shadow_enemy.global_position = player.global_position
	scene_root.add_child(shadow_enemy)
	var hp_before_shadow := player.hp
	shadow.call("_process", 1.0)
	_assert(player.hp < hp_before_shadow, "Necromancer black shadow damages the player it touches")
	_assert(shadow_enemy.last_damage > 0.0, "Necromancer black shadow damages enemies it touches")
	shadow_enemy.free()
	player.call("_force_restore_hurt_slow_motion")
	player.set("hp", player.max_hp)
	player.call("emit_round_ended")
	_assert(player.get("necromancer_black_shadow") == null, "Necromancer black shadow disappears when the combat round ends")
	await process_frame
	_assert(_count_necromancer_shadows() == 0, "Necromancer black shadow is not present during the shop phase")
	player.unlocked_talents.append(&"right_eye_0")
	player.unspent_talent_points = 1
	var base_right_eye_atk := player.get_stats().atk
	_assert(player.unlock_talent(&"right_eye_1"), "Necromancer right eye 1 unlocks from the eye loop")
	var right_eye_kill_a := Node2D.new()
	var right_eye_kill_b := Node2D.new()
	var right_eye_kill_c := Node2D.new()
	player.notify_enemy_killed(right_eye_kill_a)
	player.notify_enemy_killed(right_eye_kill_b)
	player.notify_enemy_killed(right_eye_kill_c)
	right_eye_kill_a.free()
	right_eye_kill_b.free()
	right_eye_kill_c.free()
	_assert(player.get_stats().atk == base_right_eye_atk + 3, "Necromancer right eye 1 grants 1 ATK per enemy death")
	_assert(int(player.get("necromancer_kill_atk_damage_loss_bonus")) == 3, "Necromancer right eye 1 tracks ATK gained from enemy deaths")
	player.take_damage(1.0)
	_assert(player.get_stats().atk == base_right_eye_atk + 1, "Necromancer right eye 1 removes 2 gained ATK when the player takes damage")
	_assert(int(player.get("necromancer_kill_atk_damage_loss_bonus")) == 1, "Necromancer right eye 1 tracks remaining gained ATK after damage")
	player.take_damage(1.0)
	_assert(player.get_stats().atk == base_right_eye_atk, "Necromancer right eye 1 cannot remove more ATK than it granted")
	_assert(int(player.get("necromancer_kill_atk_damage_loss_bonus")) == 0, "Necromancer right eye 1 clears gained ATK after enough damage")
	player.call("_force_restore_hurt_slow_motion")
	player.set("hp", player.max_hp)
	player.unlocked_talents.append(&"right_eye_3")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"right_eye_4"), "Necromancer right eye 4 unlocks from the eye loop")
	player.call("_update_necromancer_charged_primary_damage", 5.2)
	_assert(is_equal_approx(player.necromancer_runtime.consume_charged_primary_damage_multiplier(), 1.5), "Necromancer right eye 4 gains 10 percent left-click damage each full second")
	_assert(is_equal_approx(player.necromancer_runtime.consume_charged_primary_damage_multiplier(), 1.0), "Necromancer right eye 4 resets after the left-click damage bonus is consumed")
	player.call("_update_necromancer_charged_primary_damage", 15.0)
	_assert(is_equal_approx(player.necromancer_runtime.consume_charged_primary_damage_multiplier(), 2.0), "Necromancer right eye 4 caps left-click damage bonus at 100 percent")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"right_eye_2"), "Necromancer right eye 2 unlocks from the eye loop")
	var killed_enemy := Node2D.new()
	killed_enemy.global_position = player.global_position
	scene_root.add_child(killed_enemy)
	var explosion_enemy := PoisonProbeEnemy.new()
	explosion_enemy.add_to_group("enemy")
	explosion_enemy.global_position = player.global_position + Vector2(60.0, 0.0)
	scene_root.add_child(explosion_enemy)
	var hp_before_explosion := player.hp
	player.notify_enemy_killed(killed_enemy)
	_assert(player.hp < hp_before_explosion, "Necromancer right eye 2 enemy death explosion damages the player")
	_assert(explosion_enemy.last_damage > 0.0, "Necromancer right eye 2 enemy death explosion damages nearby enemies")
	killed_enemy.free()
	explosion_enemy.free()
	player.call("_force_restore_hurt_slow_motion")
	player.set("hp", player.max_hp)
	_free_necromancer_death_explosions()
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"right_eye_5"), "Necromancer right eye 5 unlocks from nose top")
	_assert(is_equal_approx(player.get_bleeding_move_speed_multiplier(), 0.8), "Necromancer right eye 5 exposes a 20 percent Bleeding move speed slow")
	var slowed_enemy := EnemyBase.new()
	slowed_enemy.move_speed = 100.0
	scene_root.add_child(slowed_enemy)
	await process_frame
	slowed_enemy.apply_status_effect(&"bleeding", player)
	_assert(is_equal_approx(slowed_enemy.move_speed, 80.0), "Necromancer right eye 5 slows Bleeding enemies by 20 percent")
	slowed_enemy.free()
	player.unlocked_talents.append(&"tooth_6")
	player.unspent_talent_points = 1
	var base_defense := player.get_stats().defense
	_assert(player.unlock_talent(&"tooth_7"), "Necromancer tooth 7 unlocks from tooth 6")
	for index in range(9):
		_notify_dummy_kill()
	_assert(player.get_stats().defense == base_defense, "Necromancer tooth 7 waits for 10 kills before granting Defense")
	_assert(int(player.get("necromancer_defense_kill_counter")) == 9, "Necromancer tooth 7 tracks partial kill progress")
	_notify_dummy_kill()
	_assert(player.get_stats().defense == base_defense + 1, "Necromancer tooth 7 grants 1 Defense every 10 kills")
	_assert(int(player.get("necromancer_defense_kill_counter")) == 0, "Necromancer tooth 7 resets kill counter after granting Defense")
	player.unlocked_talents.erase(&"tooth_4")
	player.unlocked_talents.erase(&"tooth_5")
	player.unlocked_talents.erase(&"tooth_6")
	player.unlocked_talents.erase(&"tooth_7")
	player.unlocked_talents.erase(&"philtrum")
	player.unlocked_talents.erase(&"nose_bottom")
	player.unlocked_talents.erase(&"nose_bridge_low")
	player.unlocked_talents.erase(&"nose_bridge_high")
	player.unlocked_talents.erase(&"nose_left")
	player.unlocked_talents.erase(&"nose_right")
	player.unlocked_talents.erase(&"nose_top")
	player.unlocked_talents.erase(&"left_eye_0")
	player.unlocked_talents.erase(&"left_eye_1")
	player.unlocked_talents.erase(&"left_eye_2")
	player.unlocked_talents.erase(&"left_eye_3")
	player.unlocked_talents.erase(&"right_eye_0")
	player.unlocked_talents.erase(&"right_eye_1")
	player.unlocked_talents.erase(&"right_eye_2")
	player.unlocked_talents.erase(&"right_eye_5")
	player.unspent_talent_points = 1
	_assert(player.get_talent_node_position(&"skull_top_3").y < player.get_talent_node_position(&"left_eye_0").y, "Necromancer skull tree places crown above eyes")
	_assert(player.get_talent_node_position(&"left_eye_0").x < player.get_talent_node_position(&"right_eye_0").x, "Necromancer skull tree places eyes left and right")
	_assert(player.get_talent_connections().has([&"tooth_4", &"philtrum"]), "Necromancer skull tree connects tooth 4 into the philtrum")
	_assert(player.get_talent_connections().has([&"philtrum", &"nose_bottom"]), "Necromancer skull tree connects the philtrum into the nose")
	_assert(player.get_talent_connections().has([&"nose_bottom", &"nose_bridge_low"]), "Necromancer skull tree connects nose bottom into the low bridge")
	_assert(player.get_talent_connections().has([&"nose_bridge_low", &"nose_bridge_high"]), "Necromancer skull tree connects the two nose bridge nodes")
	_assert(player.get_talent_connections().has([&"nose_bridge_high", &"nose_top"]), "Necromancer skull tree connects the high bridge into nose top")
	_assert(not player.get_talent_connections().has([&"nose_bottom", &"nose_top"]), "Necromancer skull tree no longer connects nose bottom directly to nose top")
	_assert(not player.get_talent_connections().has([&"tooth_4", &"nose_bottom"]), "Necromancer skull tree no longer connects tooth 4 directly into the nose")


func _test_primary_beam() -> void:
	var before_count := _count_lasers()
	player.call("_spawn_necromancer_soul_beam", player.global_position, Vector2.RIGHT)
	_assert(_count_lasers() == before_count + 1, "Necromancer primary spawns a soul beam")
	var beam := _find_last_laser()
	_assert(beam != null and is_equal_approx(beam.damage, player.get_base_attack_damage() * 1.35), "Necromancer Soul Siphon uses base beam damage before talents")
	_assert(beam != null and beam.beam_texture != null, "Necromancer primary uses Soul Siphon beam VFX")
	_assert(beam != null and beam.beam_frame_size == Vector2i(265, 81), "Necromancer Soul Siphon beam uses source frame size")
	_assert(beam != null and beam.beam_frame_count == 7, "Necromancer Soul Siphon beam uses source frame count")
	_assert(beam != null and beam.overlay_beam_texture != null, "Necromancer primary uses Soul Siphon lightning overlay")
	_assert(beam != null and beam.overlay_beam_frame_size == Vector2i(256, 128), "Necromancer Soul Siphon lightning overlay uses source frame size")
	_assert(beam != null and beam.overlay_beam_frame_count == 6, "Necromancer Soul Siphon lightning overlay uses source frame count")
	_assert(player.unlock_talent(&"tooth_4"), "Necromancer tooth 4 unlocks")
	player.call("_spawn_necromancer_soul_beam", player.global_position, Vector2.RIGHT)
	beam = _find_last_laser()
	_assert(beam != null and is_equal_approx(beam.damage, player.get_base_attack_damage() * 1.35 * 1.15), "Necromancer tooth 4 increases Soul Siphon damage by 15%")
	if not player.unlocked_talents.has(&"tooth_5"):
		player.unlocked_talents.append(&"tooth_5")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"tooth_6"), "Necromancer tooth 6 unlocks from tooth 5")
	player.call("_apply_slide_finished_talents")
	_assert(bool(player.get("next_necromancer_slide_soul_siphon_ready")), "Necromancer tooth 6 readies the next Soul Siphon after sliding")
	player.call("_spawn_necromancer_soul_beam", player.global_position, Vector2.RIGHT)
	beam = _find_last_laser()
	_assert(beam != null and is_equal_approx(beam.damage, player.get_base_attack_damage() * 1.35 * 1.15 * 1.3), "Necromancer tooth 6 increases the next Soul Siphon damage by 30%")
	_assert(not bool(player.get("next_necromancer_slide_soul_siphon_ready")), "Necromancer tooth 6 consumes the slide Soul Siphon bonus")
	player.call("_spawn_necromancer_soul_beam", player.global_position, Vector2.RIGHT)
	beam = _find_last_laser()
	_assert(beam != null and is_equal_approx(beam.damage, player.get_base_attack_damage() * 1.35 * 1.15), "Necromancer tooth 6 only affects one Soul Siphon")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"tooth_7"), "Necromancer tooth 7 unlocks from tooth 6 before tooth 8")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"tooth_8"), "Necromancer tooth 8 unlocks from tooth 7")
	for index in range(2):
		player.set("pending_shockwave_target_position", player.global_position + Vector2(100.0 + 24.0 * index, -40.0))
		player.call("_summon_necromancer_skeleton_archer")
	player.call("_spawn_necromancer_soul_beam", player.global_position, Vector2.RIGHT)
	beam = _find_last_laser()
	_assert(beam != null and is_equal_approx(beam.damage, player.get_base_attack_damage() * 1.35 * 1.15 * 1.2), "Necromancer tooth 8 increases Soul Siphon damage by 10 percent per active Skeleton Archer")
	_free_skeleton_archers()
	await process_frame
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"mouth_right"), "Necromancer mouth right unlocks from tooth 8")
	_assert(is_equal_approx(float(player.call("_get_necromancer_soul_siphon_bleed_chance", {"source": "necromancer_soul_beam"})), 0.2), "Necromancer mouth right gives Soul Siphon 20 percent bleed chance")
	_assert(is_equal_approx(float(player.call("_get_necromancer_soul_siphon_bleed_chance", {"source": "skeleton_archer"})), 0.0), "Necromancer mouth right does not affect non-Soul Siphon attacks")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"right_jaw"), "Necromancer right jaw unlocks from mouth right")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(120.0, 0.0))
	player.call("_summon_necromancer_skeleton_archer")
	var archer := _find_last_skeleton_archer()
	_assert(archer != null and is_equal_approx(archer.timed_attack_speed_multiplier, 1.0), "Necromancer right jaw Skeleton Archer starts without the Soul Siphon buff")
	player.call("_spawn_necromancer_soul_beam", player.global_position, Vector2.RIGHT)
	beam = _find_last_laser()
	if beam != null:
		beam.call("_apply_damage")
	_assert(archer != null and is_equal_approx(archer.timed_attack_speed_multiplier, 2.0), "Necromancer right jaw doubles hit Skeleton Archer attack speed")
	_assert(archer != null and archer.timed_attack_speed_remaining > 1.9, "Necromancer right jaw Skeleton Archer attack speed buff lasts 2 seconds")
	if archer != null:
		archer.call("_process", 2.1)
		_assert(bool(archer.get("dying")), "Necromancer right jaw kills the hit Skeleton Archer when the Soul Siphon buff ends")
		_assert(not player.get("necromancer_skeleton_archers").has(archer), "Necromancer right jaw removes dying Skeleton Archers from active tracking")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"right_chin"), "Necromancer right chin unlocks from tooth 6")
	for index in range(10):
		_notify_dummy_kill()
	_assert(int(player.get("necromancer_primary_damage_kill_stacks")) == 1, "Necromancer right chin grants one left-click damage stack every 10 kills")
	_assert(int(player.get("necromancer_primary_damage_kill_counter")) == 0, "Necromancer right chin resets kill counter after granting damage")
	player.call("_spawn_necromancer_soul_beam", player.global_position, Vector2.RIGHT)
	beam = _find_last_laser()
	_assert(beam != null and is_equal_approx(beam.damage, player.get_base_attack_damage() * 1.35 * 1.15 * 1.01), "Necromancer right chin permanently increases left-click damage by 1 percent per stack")
	player.unlocked_talents.append(&"skull_top_7")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"right_temple"), "Necromancer right temple unlocks from skull top 7")
	player.necromancer_runtime.enabled_talents.erase(&"necromancer_enemy_death_explosion")
	player.hp = player.max_hp * 0.5
	var hp_before_kill_hot := player.hp
	var hot_kill_enemy := PoisonProbeEnemy.new()
	player.notify_enemy_killed(hot_kill_enemy)
	var kill_hot := _find_healing_over_time_effect()
	_assert(kill_hot != null, "Necromancer right temple starts a heal-over-time effect when you kill an enemy")
	if kill_hot != null:
		kill_hot.call("_process", 1.5)
		_assert(is_equal_approx(player.hp, hp_before_kill_hot + player.max_hp * 0.025), "Necromancer right temple heals half of its 5 percent max HP total after 1.5 seconds")
		kill_hot.call("_process", 1.5)
		_assert(is_equal_approx(player.hp, hp_before_kill_hot + player.max_hp * 0.05), "Necromancer right temple heals 5 percent max HP over 3 seconds")
	hot_kill_enemy.free()
	_free_skeleton_archers()
	await process_frame
	player.necromancer_runtime.enable_talent(&"necromancer_skeleton_archer_death_round_atk")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(180.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	var base_death_atk := player.get_stats().atk
	if archer != null:
		archer.call("play_death_and_free")
	_assert(player.get_stats().atk == base_death_atk + 5, "Necromancer skull top 6 grants 5 ATK when a Skeleton Archer dies")
	player.call("emit_round_ended")
	_assert(player.get_stats().atk == base_death_atk, "Necromancer skull top 6 ATK resets when the round ends")
	_free_lasers()
	_free_skeleton_archers()
	await process_frame


func _test_secondary_skeleton_archer() -> void:
	for index in range(4):
		player.set("pending_shockwave_target_position", player.global_position + Vector2(80.0 + 24.0 * index, -40.0))
		player.call("_summon_necromancer_skeleton_archer")
	_assert(_count_skeleton_archers() == 3, "Necromancer secondary summons Skeleton Archers up to a cap of three")
	var archer := _find_last_skeleton_archer()
	_assert(archer != null, "Necromancer secondary reuses Skeleton Archer summon")
	_assert(archer != null and archer.get("owner_player") == player, "Necromancer Skeleton Archer follows the player")
	_assert(archer != null and is_equal_approx(archer.damage_inherit_multiplier, 1.0), "Necromancer Skeleton Archer uses base damage before talents")
	_assert(archer != null and is_equal_approx(archer.attack_speed_inherit_multiplier, 0.75), "Necromancer Skeleton Archer uses base attack speed before talents")
	_assert(archer != null and archer.global_position.distance_to(player.global_position + Vector2(128.0, -40.0)) < 0.1, "Necromancer Skeleton Archer spawns at the mouse target")
	await create_timer(10.1).timeout
	_assert(_count_skeleton_archers() == 3, "Necromancer Skeleton Archers remain briefly to play death animation")
	_assert(archer != null and bool(archer.get("dying")), "Necromancer Skeleton Archers play death animation when lifetime expires")
	_assert(player.get("necromancer_skeleton_archers").is_empty(), "Necromancer Skeleton Archer tracking clears expired summons")
	await create_timer(1.1).timeout
	_assert(_count_skeleton_archers() == 0, "Necromancer Skeleton Archers free after death animation")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"tooth_3"), "Necromancer tooth 3 unlocks after tooth 4")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(90.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	_assert(archer != null and is_equal_approx(archer.damage_inherit_multiplier, 1.15), "Necromancer tooth 3 increases Skeleton Archer damage by 15%")
	player.set("necromancer_skeleton_archers", [])
	if is_instance_valid(archer):
		archer.free()
	player.necromancer_runtime.enable_talent(&"necromancer_skeleton_archer_marked_target_damage")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(95.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	var marked_enemy := PoisonProbeEnemy.new()
	var unmarked_enemy := PoisonProbeEnemy.new()
	scene_root.add_child(marked_enemy)
	scene_root.add_child(unmarked_enemy)
	player.deal_player_damage_to_enemy(marked_enemy, 10.0, {"source": "necromancer_soul_beam", "direct": true, "allow_procs": false, "allow_crit": false})
	if archer != null:
		archer.set("attack_target", unmarked_enemy)
		archer.call("_deal_attack_damage")
		archer.set("attack_target", marked_enemy)
		archer.call("_deal_attack_damage")
		var marked_damage := marked_enemy.last_damage
		_assert(is_equal_approx(marked_damage, unmarked_enemy.last_damage * 1.5), "Necromancer skull top 0 makes Skeleton Archers deal 50 percent more damage to the enemy most recently damaged by left-click")
	player.necromancer_runtime.enable_talent(&"necromancer_primary_damage_to_skeleton_marked_target")
	player.deal_player_damage_to_enemy(marked_enemy, 100.0, {"source": "necromancer_soul_beam", "direct": true, "allow_procs": false, "allow_crit": false})
	player.deal_player_damage_to_enemy(unmarked_enemy, 100.0, {"source": "necromancer_soul_beam", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(marked_enemy.last_damage, unmarked_enemy.last_damage * 1.3), "Necromancer skull top 7 makes you deal 30 percent more damage to enemies most recently damaged by Skeleton Archers")
	marked_enemy.free()
	unmarked_enemy.free()
	player.set("necromancer_skeleton_archers", [])
	if is_instance_valid(archer):
		archer.free()
	player.unlocked_talents.append(&"tooth_4")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"tooth_2"), "Necromancer tooth 2 unlocks from tooth 3")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(110.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	_assert(archer != null and is_equal_approx(archer.attack_speed_inherit_multiplier, 0.75 * 1.15), "Necromancer tooth 2 increases Skeleton Archer attack speed by 15%")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"left_chin"), "Necromancer left chin unlocks from tooth 2")
	var base_archer_damage_multiplier := float(archer.damage_inherit_multiplier)
	for index in range(9):
		_notify_dummy_kill()
	_assert(int(player.get("necromancer_skeleton_archer_damage_kill_counter")) == 9, "Necromancer left chin tracks partial kill progress")
	_assert(int(player.get("necromancer_skeleton_archer_damage_kill_stacks")) == 0, "Necromancer left chin waits for 10 kills before granting damage")
	_notify_dummy_kill()
	_assert(int(player.get("necromancer_skeleton_archer_damage_kill_counter")) == 0, "Necromancer left chin resets kill counter after granting damage")
	_assert(int(player.get("necromancer_skeleton_archer_damage_kill_stacks")) == 1, "Necromancer left chin grants one Skeleton Archer damage stack every 10 kills")
	_assert(archer != null and is_equal_approx(archer.damage_inherit_multiplier, base_archer_damage_multiplier * 1.01), "Necromancer left chin updates active Skeleton Archer damage")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(120.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	_assert(archer != null and is_equal_approx(archer.damage_inherit_multiplier, base_archer_damage_multiplier * 1.01), "Necromancer left chin applies permanent damage to newly summoned Skeleton Archers")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"tooth_1"), "Necromancer tooth 1 unlocks from tooth 2")
	player.call("_apply_slide_finished_talents")
	_assert(is_equal_approx(float(player.get("necromancer_slide_skeleton_archer_attack_speed_remaining")), 2.0), "Necromancer tooth 1 starts a 2s Skeleton Archer slide buff")
	_assert(archer != null and is_equal_approx(archer.timed_attack_speed_multiplier, 1.2), "Necromancer tooth 1 gives active Skeleton Archers 20 percent attack speed")
	_assert(archer != null and archer.timed_attack_speed_remaining > 1.9, "Necromancer tooth 1 applies a 2s timed Skeleton Archer buff")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(130.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	_assert(archer != null and is_equal_approx(archer.timed_attack_speed_multiplier, 1.2), "Necromancer tooth 1 gives newly summoned Skeleton Archers the remaining slide buff")
	if archer != null:
		archer.call("_process", 2.1)
		_assert(is_equal_approx(archer.timed_attack_speed_multiplier, 1.0), "Necromancer tooth 1 Skeleton Archer buff expires")
		_assert(not bool(archer.get("dying")), "Necromancer tooth 1 Skeleton Archer buff does not kill the archer")
	_free_skeleton_archers()
	await process_frame
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"tooth_0"), "Necromancer tooth 0 unlocks from tooth 1")
	player.set("pending_shockwave_target_position", player.global_position + Vector2(150.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	_assert(archer != null and is_equal_approx(archer.damage_growth_per_second, 0.02), "Necromancer tooth 0 gives Skeleton Archers 2 percent damage growth per second")
	if archer != null:
		var base_damage := float(archer.call("_get_attack_damage"))
		archer.call("_process", 1.1)
		_assert(is_equal_approx(float(archer.call("_get_attack_damage")), base_damage * 1.02), "Necromancer tooth 0 increases Skeleton Archer damage after 1 second alive")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"mouth_left"), "Necromancer mouth left unlocks from tooth 0")
	_free_skeleton_archers()
	await process_frame
	player.set("pending_shockwave_target_position", player.global_position + Vector2(170.0, -40.0))
	player.call("_summon_necromancer_skeleton_archer")
	archer = _find_last_skeleton_archer()
	_assert(archer != null and is_equal_approx(archer.poison_chance, 0.2), "Necromancer mouth left gives Skeleton Archers 20 percent poison chance")
	if archer != null:
		var poison_probe := PoisonProbeEnemy.new()
		scene_root.add_child(poison_probe)
		archer.poison_chance = 1.0
		archer.set("attack_target", poison_probe)
		archer.call("_deal_attack_damage")
		_assert(poison_probe.poison_stacks == 1, "Necromancer mouth left Skeleton Archer attacks can apply poison")
		poison_probe.free()
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"left_jaw"), "Necromancer left jaw unlocks from mouth left")
	_assert(int(player.call("_get_necromancer_skeleton_archer_cap")) == 4, "Necromancer left jaw increases Skeleton Archer cap by 1")
	_assert(is_equal_approx(float(player.call("_get_necromancer_skeleton_archer_lifetime")), 20.0), "Necromancer left jaw doubles Skeleton Archer lifetime")
	player.necromancer_runtime.enable_talent(&"necromancer_container_break_skeleton_archer")
	_assert(int(player.call("_get_necromancer_skeleton_archer_cap")) == 5, "Necromancer skull top 1 increases Skeleton Archer cap by 1")
	var broken_container := BreakableContainer.new()
	broken_container.global_position = player.global_position + Vector2(210.0, -40.0)
	scene_root.add_child(broken_container)
	_assert(not bool(player.call("_try_trigger_necromancer_container_break_skeleton_archer", broken_container, {"source": "player_attack", "owner": player}, 0.5)), "Necromancer skull top 1 waits for its 10 percent container break roll")
	var archer_count_before_container := _count_skeleton_archers()
	_assert(bool(player.call("_try_trigger_necromancer_container_break_skeleton_archer", broken_container, {"source": "player_attack", "owner": player}, 0.0)), "Necromancer skull top 1 can trigger right-click summon when a container breaks")
	_assert(_count_skeleton_archers() == archer_count_before_container + 1, "Necromancer skull top 1 summons one Skeleton Archer from a broken container")
	var container_archer := _find_last_skeleton_archer()
	_assert(container_archer != null and container_archer.global_position.distance_to(broken_container.global_position) < 0.1, "Necromancer skull top 1 summons the Skeleton Archer at the broken container position")
	broken_container.free()
	_free_skeleton_archers()
	player.necromancer_runtime.enabled_talents.erase(&"necromancer_container_break_skeleton_archer")
	await process_frame
	player.necromancer_runtime.enable_talent(&"necromancer_kill_skeleton_archer")
	_assert(int(player.call("_get_necromancer_skeleton_archer_cap")) == 6, "Necromancer skull top 2 increases Skeleton Archer cap by 2")
	var killed_enemy := PoisonProbeEnemy.new()
	killed_enemy.global_position = player.global_position + Vector2(235.0, 35.0)
	scene_root.add_child(killed_enemy)
	_assert(not bool(player.call("_try_trigger_necromancer_kill_skeleton_archer", killed_enemy, 0.5)), "Necromancer skull top 2 waits for its 10 percent kill roll")
	var archer_count_before_kill := _count_skeleton_archers()
	_assert(bool(player.call("_try_trigger_necromancer_kill_skeleton_archer", killed_enemy, 0.0)), "Necromancer skull top 2 can trigger right-click summon when you kill an enemy")
	_assert(_count_skeleton_archers() == archer_count_before_kill + 1, "Necromancer skull top 2 summons one Skeleton Archer from a kill")
	var kill_archer := _find_last_skeleton_archer()
	_assert(kill_archer != null and kill_archer.global_position.distance_to(killed_enemy.global_position) < 0.1, "Necromancer skull top 2 summons the Skeleton Archer at the killed enemy position")
	killed_enemy.free()
	_free_skeleton_archers()
	player.necromancer_runtime.enabled_talents.erase(&"necromancer_kill_skeleton_archer")
	await process_frame
	player.unlocked_talents.append(&"skull_top_0")
	player.unspent_talent_points = 1
	_assert(player.unlock_talent(&"left_temple"), "Necromancer left temple unlocks from skull top 0")
	player.set("necromancer_xp_kill_counter", 0)
	player.set("necromancer_gold_kill_counter", 0)
	player.set("necromancer_defense_kill_counter", 0)
	player.set("necromancer_atk_kill_counter", 0)
	player.set("necromancer_max_hp_kill_counter", 0)
	player.set("necromancer_skeleton_archer_damage_kill_counter", 0)
	player.set("necromancer_primary_damage_kill_counter", 0)
	player.necromancer_runtime.enabled_talents.erase(&"necromancer_enemy_death_explosion")
	player.hp = player.max_hp * 0.5
	var hp_before_archer_kill := player.hp
	var archer_kill_enemy := PoisonProbeEnemy.new()
	archer_kill_enemy.last_attack_info = {"source": "skeleton_archer", "direct": true}
	player.notify_enemy_killed(archer_kill_enemy)
	_assert(is_equal_approx(player.hp, hp_before_archer_kill + player.max_hp * 0.1), "Necromancer left temple heals 10 percent max HP when a Skeleton Archer kills an enemy")
	var hp_before_non_archer_kill := player.hp
	var non_archer_kill_enemy := PoisonProbeEnemy.new()
	non_archer_kill_enemy.last_attack_info = {"source": "necromancer_soul_beam", "direct": true}
	player.notify_enemy_killed(non_archer_kill_enemy)
	_assert(is_equal_approx(player.hp, hp_before_non_archer_kill), "Necromancer left temple does not heal from non-Skeleton Archer kills")
	archer_kill_enemy.free()
	non_archer_kill_enemy.free()
	_free_skeleton_archers()
	await process_frame
	for index in range(5):
		player.set("pending_shockwave_target_position", player.global_position + Vector2(190.0 + 24.0 * index, -40.0))
		player.call("_summon_necromancer_skeleton_archer")
	_assert(_count_skeleton_archers() == 4, "Necromancer left jaw allows four active Skeleton Archers")
	_free_skeleton_archers()
	await process_frame


func _test_soul_surge() -> void:
	player.call("_start_necromancer_soul_surge")
	_assert(player.fire_surge_remaining > 0.0, "Necromancer Soul Surge starts a timed state")
	_assert(player.fire_surge_cooldown_pending, "Necromancer Soul Surge blocks recast until finished")
	var buffs := player.get_temporary_buffs()
	_assert(buffs != null and buffs.buffs.has(&"necromancer_soul_surge_attack_speed"), "Soul Surge grants attack speed buff")
	_assert(buffs != null and buffs.buffs.has(&"necromancer_soul_surge_move_speed"), "Soul Surge grants movement speed buff")


func _count_projectiles() -> int:
	var count := 0
	for child in scene_root.get_children():
		if child is Projectile:
			count += 1
	return count


func _count_lasers() -> int:
	var count := 0
	for child in scene_root.get_children():
		if child is HolyFlameLaser:
			count += 1
	return count


func _count_skeleton_archers() -> int:
	var count := 0
	for child in scene_root.get_children():
		if child is SkeletonArcher:
			count += 1
	return count


func _find_last_laser() -> HolyFlameLaser:
	var result: HolyFlameLaser = null
	for child in scene_root.get_children():
		if child is HolyFlameLaser:
			result = child
	return result


func _find_last_skeleton_archer() -> SkeletonArcher:
	var result: SkeletonArcher = null
	for child in scene_root.get_children():
		if child is SkeletonArcher:
			result = child
	return result


func _find_healing_over_time_effect() -> HealingOverTimeEffect:
	for child in scene_root.get_children():
		if child is HealingOverTimeEffect:
			return child
	return null


func _free_skeleton_archers() -> void:
	player.set("necromancer_skeleton_archers", [])
	for child in scene_root.get_children():
		if child is SkeletonArcher:
			child.free()


func _free_lasers() -> void:
	for child in scene_root.get_children():
		if child is HolyFlameLaser:
			child.free()


func _free_necromancer_shadows() -> void:
	player.set("necromancer_black_shadow", null)
	for child in scene_root.get_children():
		if child.get_script() == NECROMANCER_SHADOW_SCRIPT:
			child.free()


func _free_necromancer_death_explosions() -> void:
	for child in scene_root.get_children():
		if child.name == "NecromancerDeathExplosion":
			child.free()


func _count_necromancer_shadows() -> int:
	var count := 0
	for child in scene_root.get_children():
		if child.get_script() == NECROMANCER_SHADOW_SCRIPT:
			count += 1
	return count


func _notify_dummy_kill() -> void:
	var enemy := Node.new()
	player.notify_enemy_killed(enemy)
	enemy.free()


func _cleanup() -> void:
	if is_instance_valid(scene_root):
		_free_skeleton_archers()
		_free_lasers()
		_free_necromancer_shadows()
		_free_necromancer_death_explosions()
	current_scene = null
	if is_instance_valid(scene_root):
		root.remove_child(scene_root)
		scene_root.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_assertions += 1
	else:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)
	push_error("FAIL: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("NecromancerCharacterTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("NecromancerCharacterTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
