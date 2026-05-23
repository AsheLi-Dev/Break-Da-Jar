extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const WIZARD_TALENT_CATALOG := preload("res://scripts/player/WizardTalentCatalog.gd")
const WIZARD_TALENT_LAYOUT: PackedScene = preload("res://scenes/player/WizardTalentLayout.tscn")
const TALENT_TREE_UI := preload("res://systems/battle/TalentTreeUiController.gd")
const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")
const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")
const HOVERING_FIREBALL_SCRIPT := preload("res://systems/combat/HoveringFireball.gd")

var failures: Array[String] = []
var passed_assertions: int = 0
var player: Player
var scene: FakeBattleScene
var attack_started_count: int = 0
var last_attack_started_info: Dictionary = {}
var saw_zero_hp_changed: bool = false


class FakeBattleScene:
	extends Node2D

	var gold: int = 0

	func add_player_gold(amount: int, _reason: String = "") -> void:
		gold += amount


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("WizardCharacterTest: starting")
	await process_frame

	scene = FakeBattleScene.new()
	root.add_child(scene)
	current_scene = scene

	player = PLAYER_SCENE.instantiate() as Player
	player.setup_character(&"wizard")
	scene.add_child(player)
	await process_frame

	_test_wizard_definition()
	_test_wizard_talent_catalog()
	_test_primary_fireball()
	_test_secondary_laser()
	_test_fire_surge()
	_test_wizard_talent_ui()
	_test_start_talent_poison_chance()
	_test_wizard_fireball_damage_bonus_talent()
	_test_wizard_kill_atk_stack_talent()
	_test_wizard_slide_fireball_radius_buff_talent()
	_test_wizard_fireball_radius_bonus_talent()
	_test_wizard_nearby_damage_lifesteal_talent()
	_test_wizard_swift_flame_extra_gold_talent()
	_test_wizard_kill_move_speed_stack_talent()
	_test_wizard_primary_extra_fireball_talent()
	_test_wizard_fireball_speed_bonus_talent()
	_test_wizard_fireball_hit_heal_talent()
	_test_wizard_start_attack_speed_talent()
	_test_wizard_kill_attack_speed_stack_talent()
	_test_wizard_extra_auto_fire_laser_talent()
	_test_wizard_fire_laser_range_bonus_talent()
	_test_wizard_elite_damage_lifesteal_talent()
	_test_slide_fireball_blast_talent()
	_test_poison_stack_damage_talent()
	_test_nearby_enemy_attack_speed_talent()
	_test_nearby_damage_focus_talent()
	_test_fire_surge_left_click_blast_talent()
	_test_nearby_kill_gold_talent()
	_test_dash_fireball_talent()
	_test_nearby_enemy_move_speed_talent()
	_test_nearby_poison_aura_talent()
	_test_poisoned_kill_gold_talent()
	_test_short_laser_double_damage_talent()
	_test_nearby_enemy_elite_damage_talent()
	_test_more_weaker_enemies_talent()
	_test_fire_essence_burst_talent()
	_test_fireball_max_hp_bonus_damage_talent()
	_test_atk_percent_bonus_talent()
	_test_fireball_radius_per_atk_talent()
	_test_gold_move_speed_bonus_talent()
	_test_fire_surge_radial_fireballs_talent()
	_test_max_hp_primary_echo_talent()
	_test_gold_extra_fireballs_talent()
	_test_poisoned_death_extra_gold_talent()
	_test_rare_item_virtual_gold_talent()
	_test_fire_essence_explosion_scatter_talent()
	_test_guaranteed_legendary_shop_jar_talent()
	_test_lasting_bloom_piercing_fireballs_talent()
	_test_legendary_extra_fireballs_talent()
	_test_warm_ash_wall_bounce_talent()
	_test_pain_bloom_move_speed_fireball_speed_talent()
	_test_random_double_fireballs_talent()
	_test_rebirth_level_to_atk_talent()
	_test_primary_fireball_laser_explosion_talent()
	_test_fire_surge_laser_talent()
	_test_fire_laser_chain_talent()
	_test_quick_kill_max_hp_talent()
	_test_early_round_enemy_gold_talent()
	_test_fireball_split_impact_and_explosion_damage()
	_test_fireball_explodes_on_containers_talent()
	_test_container_break_laser_no_container_damage_talent()
	_test_poisoned_death_fire_laser_talent()
	_test_fire_surge_attack_speed_talent()
	_test_slide_momentum_talent()
	_test_fire_laser_chain_heals_player_talent()
	_test_fire_laser_chain_damage_talent()
	_test_fire_laser_chain_prefers_new_targets_then_repeats()
	_test_slide_fire_laser_talent()
	_test_fire_laser_damages_containers_in_beam()
	_test_fire_laser_ignores_shop_containers()
	_test_hovering_fireball_talent()
	_test_stationary_primary_fireball_radius_charge_talent()
	_test_stationary_primary_fireball_damage_charge_talent()
	_test_stationary_fireball_explosion_talent()
	_test_dash_primary_fireball_stacks_talent()
	_test_fire_laser_hovering_fireball_chain_talent()
	_test_fire_laser_skips_freed_chain_excludes()
	_test_homing_fireball_talent()
	_test_fireball_impact_poison_stun_talent()
	_test_fireball_impact_vulnerable_talent()
	_test_opening_attack_speed_talent()
	_test_attack_chain_lightning_chance_talent()
	_test_chain_lightning_attack_speed_stack_talent()
	_test_fireball_explosion_chain_lightning_talent()
	_test_large_map_more_containers_talent()

	_finish()


func _test_wizard_definition() -> void:
	_assert(player.get("primary_ability") == &"wizard_fireball", "Wizard primary ability is fireball")
	_assert(player.get("secondary_ability") == &"wizard_fire_laser", "Wizard secondary ability is fire laser")
	_assert(player.get("utility_ability") == &"wizard_fire_surge", "Wizard utility ability is fire surge")
	_assert(player.get_talent_node_ids().size() == 82, "Wizard exposes 82 talent nodes")
	var definition := player.get("character_definition") as CharacterDefinition
	_assert(definition.get_active_frame(&"primary", 0) == 7, "Wizard primary active frame is assigned")
	_assert(definition.get_active_frame(&"secondary", 0) == 8, "Wizard secondary active frame is assigned")
	_assert(definition.get_active_frame(&"utility", 0) == 5, "Wizard utility active frame is assigned")
	_assert(definition.textures.get(&"slide_hold") == definition.textures.get(&"slide_start"), "Wizard slide hold freezes slide start sheet")
	for animation_name in [&"idle", &"run", &"attack", &"ability", &"pummel", &"slide_start", &"slide_hold", &"slide_end", &"damage", &"death"]:
		_assert(definition.get_texture(animation_name) != null, "Wizard texture loads: %s" % animation_name)


func _test_wizard_talent_catalog() -> void:
	var ids := WIZARD_TALENT_CATALOG.node_ids()
	_assert(ids.size() == 82, "Wizard catalog has 82 nodes")
	var start_nodes := WIZARD_TALENT_CATALOG.start_nodes()
	_assert(start_nodes.size() == 1 and start_nodes[0] == &"flame_bottom_5", "Wizard catalog has one start node at bottom 5")
	var layout := WIZARD_TALENT_LAYOUT.instantiate() as Node2D
	for id in ids:
		_assert(WIZARD_TALENT_CATALOG.position(id) != Vector2.ZERO, "Wizard node has position: %s" % id)
		var marker := layout.get_node_or_null(String(id)) as Node2D
		_assert(marker != null and WIZARD_TALENT_CATALOG.position(id).is_equal_approx(marker.global_position), "Wizard catalog reads layout marker: %s" % id)
	layout.free()
	for connection in WIZARD_TALENT_CATALOG.connections():
		_assert(ids.has(connection[0]), "Wizard connection from endpoint exists")
		_assert(ids.has(connection[1]), "Wizard connection to endpoint exists")


func _test_primary_fireball() -> void:
	attack_started_count = 0
	last_attack_started_info = {}
	if not player.attack_started.is_connected(_on_attack_started):
		player.attack_started.connect(_on_attack_started)
	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, false, 1.0, 1.0, true, true)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 1, "Wizard primary spawns FireballProjectile")
	var fireball := _find_fireball_with_allow_procs(true)
	_assert(fireball != null, "Wizard primary Fireball allows normal procs")
	_assert(attack_started_count == 1, "Wizard primary Fireball emits attack_started")
	_assert(StringName(last_attack_started_info.get("source", &"")) == &"fireball", "Wizard primary attack_started source is fireball")
	_assert(bool(last_attack_started_info.get("allow_procs", false)), "Wizard primary attack_started allows procs")


func _test_secondary_laser() -> void:
	var before := _count_nodes_with_class("HolyFlameLaser")
	player.set("pending_shockwave_target_position", player.global_position + Vector2.RIGHT * 200.0)
	player.call("_cast_wizard_fire_laser")
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before + 1, "Wizard secondary spawns HolyFlameLaser")
	var laser := _find_node_with_class("HolyFlameLaser") as HolyFlameLaser
	_assert(laser != null and is_equal_approx(laser.length, 500.0), "Wizard secondary laser length is doubled")
	_assert(laser != null and is_equal_approx(laser.width, 84.0), "Wizard secondary laser width is doubled")
	_assert(laser != null and is_equal_approx(laser.chain_range, laser.length), "Wizard secondary laser chain range matches laser length")


func _test_fire_surge() -> void:
	var enemy := Node2D.new()
	enemy.add_to_group("enemy")
	enemy.global_position = player.global_position + Vector2.RIGHT * 180.0
	scene.add_child(enemy)
	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_start_fire_surge")
	await process_frame
	for index in range(20):
		player.call("_update_fire_surge", 0.5)
		await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 5, "Wizard fire surge fires 5 fireballs over 10s")
	_assert(is_equal_approx(float(player.get("blessing_cooldown_remaining")), 10.0), "Wizard fire surge cooldown starts after duration")


func _test_wizard_talent_ui() -> void:
	var ui := TALENT_TREE_UI.new() as TalentTreeUiController
	ui.setup(player)
	scene.add_child(ui)
	var graph := ui.get_node_or_null("TalentTreePanel/Graph")
	_assert(graph != null, "Wizard talent UI creates graph")
	if graph != null:
		_assert(_count_line_children(graph) == WIZARD_TALENT_CATALOG.connections().size(), "Wizard talent UI renders all connections")
		_assert(_count_buttons(graph) == WIZARD_TALENT_CATALOG.node_ids().size(), "Wizard talent UI renders all buttons")
	ui.queue_free()


func _test_start_talent_poison_chance() -> void:
	player.unspent_talent_points = 1
	_assert(player.can_unlock_talent(&"flame_bottom_5"), "Wizard poison start talent is unlockable")
	var stats := player.get_stats()
	var before := stats.poison_chance
	var unlocked := _unlock_talent_for_test(&"flame_bottom_5")
	_assert(unlocked, "Wizard poison start talent unlocks")
	_assert(is_equal_approx(stats.poison_chance, before + 0.1), "Wizard poison start talent grants 10% poison chance")


func _test_wizard_fireball_damage_bonus_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_start_0")
	_assert(unlocked, "Wizard left start Fireball damage talent unlocks")

	_clear_fireballs()
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	var fireball := _find_node_with_class("FireballProjectile") as FireballProjectile
	_assert(fireball != null and is_equal_approx(fireball.damage, player.get_base_attack_damage() * 1.2), "Wizard left start talent grants 20% Fireball damage")
	player.set("talent_wizard_fireball_damage_bonus_enabled", false)
	_clear_fireballs()


func _test_wizard_kill_atk_stack_talent() -> void:
	player.unspent_talent_points = 1
	var stats := player.get_stats()
	var before := stats.atk
	var unlocked := _unlock_talent_for_test(&"flame_left_start_1")
	_assert(unlocked, "Wizard left second kill ATK talent unlocks")
	for _index in range(6):
		player.notify_enemy_killed(DamageProbeEnemy.new())
	var buff: Dictionary = player.get_temporary_buffs().buffs.get(&"wizard_kill_atk_stack", {})
	_assert(int(buff.get("stacks", 0)) == 5, "Wizard left second kill ATK talent caps at 5 stacks")
	_assert(is_equal_approx(stats.atk, before + 10.0), "Wizard left second kill ATK talent grants up to 10 ATK")
	_assert(is_equal_approx(float(buff.get("time_left", 0.0)), 5.0), "Wizard left second kill ATK talent lasts 5s")
	player.get_temporary_buffs().buffs.erase(&"wizard_kill_atk_stack")
	stats.apply_modifier(&"atk", &"add", -10.0)
	player.set("talent_wizard_kill_atk_stack_enabled", false)


func _test_wizard_slide_fireball_radius_buff_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_start_2")
	_assert(unlocked, "Wizard left third slide Fireball radius talent unlocks")

	_clear_fireballs()
	player.call("_apply_slide_finished_talents")
	_assert(is_equal_approx(float(player.get("wizard_slide_fireball_radius_buff_remaining")), 3.0), "Wizard left third talent grants a 3s Fireball radius buff after sliding")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	var fireball := _find_fireball_with_radius(104.0)
	_assert(fireball != null, "Wizard left third talent increases Fireball explosion radius by 30% after sliding")

	_clear_fireballs()
	player.call("_apply_slide_finished_talents")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	fireball = _find_fireball_with_radius(104.0)
	_assert(fireball != null, "Wizard left third talent does not stack from repeated slides")

	_clear_fireballs()
	player.set("talent_wizard_slide_fireball_blast_enabled", true)
	player.set("next_wizard_slide_fireball_ready", true)
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	fireball = _find_fireball_with_radius(128.0)
	_assert(fireball != null, "Wizard left third talent stacks additively with Slide Blast radius")

	_clear_fireballs()
	player.set("talent_wizard_slide_fireball_blast_enabled", false)
	player.set("wizard_slide_fireball_radius_buff_remaining", 3.0)
	player.call("_update_timers", 3.0)
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	fireball = _find_fireball_with_radius(80.0)
	_assert(fireball != null, "Wizard left third talent expires after 3s")
	player.set("talent_wizard_slide_fireball_radius_buff_enabled", false)
	player.set("wizard_slide_fireball_radius_buff_remaining", 0.0)


func _test_wizard_fireball_radius_bonus_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_start_3")
	_assert(unlocked, "Wizard left fourth Fireball radius talent unlocks")

	_clear_fireballs()
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	var fireball := _find_node_with_class("FireballProjectile") as FireballProjectile
	_assert(fireball != null and is_equal_approx(fireball.explosion_radius, 104.0), "Wizard left fourth talent grants 30% Fireball explosion radius")
	player.set("talent_wizard_fireball_radius_bonus_enabled", false)
	_clear_fireballs()


func _test_wizard_nearby_damage_lifesteal_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_start_4")
	_assert(unlocked, "Wizard left fifth nearby damage lifesteal talent unlocks")

	var nearby_enemy := DamageProbeEnemy.new()
	nearby_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(nearby_enemy)

	player.hp = player.max_hp - 50.0
	var before_hp := player.hp
	player.deal_player_damage_to_enemy(nearby_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(player.hp, before_hp + nearby_enemy.last_damage * 0.12), "Wizard left fifth talent heals for 12% of damage dealt to nearby enemies")

	var distant_enemy := DamageProbeEnemy.new()
	distant_enemy.global_position = player.global_position + Vector2.RIGHT * 300.0
	scene.add_child(distant_enemy)

	player.hp = player.max_hp - 50.0
	before_hp = player.hp
	player.deal_player_damage_to_enemy(distant_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(player.hp, before_hp), "Wizard left fifth talent ignores distant enemies")

	player.set("talent_wizard_nearby_damage_lifesteal_enabled", false)
	nearby_enemy.queue_free()
	distant_enemy.queue_free()


func _test_wizard_swift_flame_extra_gold_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_start_0")
	_assert(unlocked, "Wizard Swift Flame talent unlocks")
	_assert(bool(player.get("talent_wizard_swift_flame_extra_gold_enabled")), "Wizard Swift Flame talent enables enemy extra gold drops")


func _test_wizard_kill_move_speed_stack_talent() -> void:
	player.unspent_talent_points = 1
	var stats := player.get_stats()
	var before := stats.movement_speed_bonus
	var unlocked := _unlock_talent_for_test(&"flame_center_start_1")
	_assert(unlocked, "Wizard center second kill movement speed talent unlocks")
	for _index in range(4):
		player.notify_enemy_killed(DamageProbeEnemy.new())
	var buff: Dictionary = player.get_temporary_buffs().buffs.get(&"wizard_kill_move_speed_stack", {})
	_assert(int(buff.get("stacks", 0)) == 3, "Wizard center second kill movement speed talent caps at 3 stacks")
	_assert(is_equal_approx(stats.movement_speed_bonus, before + 0.3), "Wizard center second kill movement speed talent grants up to 30% movement speed")
	_assert(is_equal_approx(float(buff.get("time_left", 0.0)), 3.0), "Wizard center second kill movement speed talent lasts 3s")
	player.get_temporary_buffs().buffs.erase(&"wizard_kill_move_speed_stack")
	stats.apply_modifier(&"movement_speed_bonus", &"add", -0.3)
	player.set("talent_wizard_kill_move_speed_stack_enabled", false)


func _test_wizard_primary_extra_fireball_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_start_2")
	_assert(unlocked, "Wizard center third extra Fireball talent unlocks")

	_clear_fireballs()
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == 2, "Wizard center third talent adds 1 left-click Fireball")
	player.set("talent_wizard_primary_extra_fireball_enabled", false)
	_clear_fireballs()


func _test_wizard_fireball_speed_bonus_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_start_3")
	_assert(unlocked, "Wizard center fourth Fireball speed talent unlocks")

	_clear_fireballs()
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	var fireball := _find_node_with_class("FireballProjectile") as FireballProjectile
	_assert(fireball != null and is_equal_approx(fireball.speed, 728.0), "Wizard center fourth talent grants 40% Fireball speed")
	player.set("talent_wizard_fireball_speed_bonus_enabled", false)
	_clear_fireballs()


func _test_wizard_fireball_hit_heal_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_start_4")
	_assert(unlocked, "Wizard center fifth Fireball hit heal talent unlocks")

	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(enemy)

	player.hp = player.max_hp - 10.0
	var before_hp := player.hp
	player.deal_player_damage_to_enemy(enemy, 100.0, {"source": "fireball", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(player.hp, before_hp + 1.0), "Wizard center fifth talent heals 1 HP when Fireball hits")

	player.hp = player.max_hp - 10.0
	before_hp = player.hp
	player.deal_player_damage_to_enemy(enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(player.hp, before_hp), "Wizard center fifth talent ignores non-Fireball hits")

	player.set("talent_wizard_fireball_hit_heal_enabled", false)
	enemy.queue_free()


func _test_wizard_start_attack_speed_talent() -> void:
	player.unspent_talent_points = 1
	var stats := player.get_stats()
	var before := stats.attack_speed_bonus
	var unlocked := _unlock_talent_for_test(&"flame_right_start_0")
	_assert(unlocked, "Wizard right start attack speed talent unlocks")
	_assert(is_equal_approx(stats.attack_speed_bonus, before + 0.2), "Wizard right start talent grants 20% attack speed")
	stats.apply_modifier(&"attack_speed_bonus", &"add", -0.2)


func _test_wizard_kill_attack_speed_stack_talent() -> void:
	player.unspent_talent_points = 1
	var stats := player.get_stats()
	var before := stats.attack_speed_bonus
	var unlocked := _unlock_talent_for_test(&"flame_right_start_1")
	_assert(unlocked, "Wizard right second kill attack speed talent unlocks")
	for _index in range(4):
		player.notify_enemy_killed(DamageProbeEnemy.new())
	var buff: Dictionary = player.get_temporary_buffs().buffs.get(&"wizard_kill_attack_speed_stack", {})
	_assert(int(buff.get("stacks", 0)) == 3, "Wizard right second kill attack speed talent caps at 3 stacks")
	_assert(is_equal_approx(stats.attack_speed_bonus, before + 0.3), "Wizard right second kill attack speed talent grants up to 30% attack speed")
	_assert(is_equal_approx(float(buff.get("time_left", 0.0)), 5.0), "Wizard right second kill attack speed talent lasts 5s")
	player.get_temporary_buffs().buffs.erase(&"wizard_kill_attack_speed_stack")
	stats.apply_modifier(&"attack_speed_bonus", &"add", -0.3)
	player.set("talent_wizard_kill_attack_speed_stack_enabled", false)


func _test_wizard_extra_auto_fire_laser_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_start_2")
	_assert(unlocked, "Wizard right third extra Fire Laser talent unlocks")

	var enemy := DamageProbeEnemy.new()
	enemy.add_to_group("enemy")
	enemy.global_position = player.global_position + Vector2.DOWN * 160.0
	scene.add_child(enemy)
	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	player.set("pending_shockwave_target_position", player.global_position + Vector2.RIGHT * 200.0)
	player.call("_cast_wizard_fire_laser")
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 2, "Wizard right third talent fires one extra auto-aimed Fire Laser")
	player.set("talent_wizard_extra_auto_fire_laser_enabled", false)
	enemy.queue_free()


func _test_wizard_fire_laser_range_bonus_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_start_3")
	_assert(unlocked, "Wizard right fourth Fire Laser range talent unlocks")

	player.set("pending_shockwave_target_position", player.global_position + Vector2.RIGHT * 200.0)
	player.call("_cast_wizard_fire_laser")
	await process_frame
	var laser := _find_newest_laser()
	_assert(laser != null and is_equal_approx(laser.length, 650.0), "Wizard right fourth talent grants 30% Fire Laser range")
	_assert(laser != null and is_equal_approx(laser.chain_range, 650.0), "Wizard right fourth talent also extends Fire Laser chain range")
	player.set("talent_wizard_fire_laser_range_bonus_enabled", false)


func _test_wizard_elite_damage_lifesteal_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_start_4")
	_assert(unlocked, "Wizard right fifth elite damage lifesteal talent unlocks")

	var elite_enemy := EliteDamageProbeEnemy.new()
	elite_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(elite_enemy)

	player.hp = player.max_hp - 50.0
	var before_hp := player.hp
	player.deal_player_damage_to_enemy(elite_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(player.hp, before_hp + elite_enemy.last_damage * 0.25), "Wizard right fifth talent heals for 25% of damage dealt to elite enemies")

	var normal_enemy := DamageProbeEnemy.new()
	normal_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(normal_enemy)

	player.hp = player.max_hp - 50.0
	before_hp = player.hp
	player.deal_player_damage_to_enemy(normal_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(player.hp, before_hp), "Wizard right fifth talent ignores non-elite enemies")

	player.set("talent_wizard_elite_damage_lifesteal_enabled", false)
	elite_enemy.queue_free()
	normal_enemy.queue_free()


func _test_slide_fireball_blast_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_bottom_4")
	_assert(unlocked, "Wizard slide fireball blast talent unlocks")
	player.call("_apply_slide_finished_talents")
	_assert(bool(player.get("next_wizard_slide_fireball_ready")), "Wizard slide fireball blast arms after slide")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	var fireball := _find_fireball_with_radius(104.0)
	_assert(fireball != null, "Wizard slide fireball blast increases explosion radius by 30%")
	_assert(fireball != null and is_equal_approx(fireball.lifetime, 0.15), "Wizard slide fireball blast reduces travel distance by 90%")
	_assert(not bool(player.get("next_wizard_slide_fireball_ready")), "Wizard slide fireball blast is consumed by left-click fireball")

	_clear_fireballs()
	player.set("talent_wizard_primary_extra_fireball_enabled", true)
	player.call("_apply_slide_finished_talents")
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	await process_frame
	_assert(_count_fireballs_with_radius(104.0) == 2, "Wizard slide fireball blast applies to all Fireballs generated by the next left-click attack")
	for boosted_fireball in _collect_fireballs_with_radius(104.0):
		_assert(is_equal_approx(boosted_fireball.lifetime, 0.15), "Wizard slide fireball blast reduces travel distance for all Fireballs generated by the next left-click attack")
	_assert(not bool(player.get("next_wizard_slide_fireball_ready")), "Wizard slide fireball blast is consumed after the full left-click attack")
	player.set("talent_wizard_primary_extra_fireball_enabled", false)
	_clear_fireballs()


func _test_poison_stack_damage_talent() -> void:
	var enemy := PoisonStackEnemy.new()
	enemy.poison_stacks = 4
	scene.add_child(enemy)
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_bottom_3")
	_assert(unlocked, "Wizard poison stack damage talent unlocks")
	player.deal_player_damage_to_enemy(enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(enemy.last_damage, 120.0), "Wizard poison stack damage grants 5% damage per poison stack")


func _test_nearby_enemy_attack_speed_talent() -> void:
	var nearby_enemy_a := Node2D.new()
	nearby_enemy_a.add_to_group("enemy")
	nearby_enemy_a.global_position = player.global_position + Vector2.RIGHT * 40.0
	scene.add_child(nearby_enemy_a)
	var nearby_enemy_b := Node2D.new()
	nearby_enemy_b.add_to_group("enemy")
	nearby_enemy_b.global_position = player.global_position + Vector2.DOWN * 60.0
	scene.add_child(nearby_enemy_b)

	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_bottom_2")
	_assert(unlocked, "Wizard nearby enemy attack speed talent unlocks")
	player.call("_update_wizard_nearby_enemy_attack_speed")
	var expected_bonus := float(EFFECT_TARGETING.enemies_surrounding(player, player.global_position).size()) * 0.05
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, expected_bonus), "Wizard nearby enemy attack speed grants 5% per nearby enemy")


func _test_nearby_damage_focus_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_0")
	_assert(unlocked, "Wizard nearby damage focus talent unlocks")

	var nearby_enemy := DamageProbeEnemy.new()
	nearby_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(nearby_enemy)
	player.deal_player_damage_to_enemy(nearby_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(nearby_enemy.last_damage, 150.0), "Wizard nearby damage focus grants 50% more damage nearby")

	var distant_enemy := DamageProbeEnemy.new()
	distant_enemy.global_position = player.global_position + Vector2.RIGHT * 300.0
	scene.add_child(distant_enemy)
	player.deal_player_damage_to_enemy(distant_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(distant_enemy.last_damage, 50.0), "Wizard nearby damage focus grants 50% less damage when not nearby")


func _test_fire_surge_left_click_blast_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_1")
	_assert(unlocked, "Wizard fire surge left-click blast talent unlocks")
	player.call("_start_fire_surge")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	var empowered_fireball := _find_fireball_with_radius(120.0)
	_assert(empowered_fireball != null, "Wizard fire surge left-click blast increases explosion radius by 50%")
	_assert(empowered_fireball != null and is_equal_approx(empowered_fireball.lifetime, 0.15), "Wizard fire surge left-click blast reduces travel distance by 90%")

	player.call("_update_fire_surge", 10.0)
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	var normal_fireball := _find_fireball_with_radius(80.0)
	_assert(normal_fireball != null, "Wizard fire surge left-click blast only applies during Fire Surge")


func _test_nearby_kill_gold_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_2")
	_assert(unlocked, "Wizard nearby kill gold talent unlocks")

	scene.gold = 0
	var nearby_enemy := DamageProbeEnemy.new()
	nearby_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	player.notify_enemy_killed(nearby_enemy)
	_assert(scene.gold == 1, "Wizard nearby kill gold grants 1 gold for nearby enemy")

	var distant_enemy := DamageProbeEnemy.new()
	distant_enemy.global_position = player.global_position + Vector2.RIGHT * 300.0
	player.notify_enemy_killed(distant_enemy)
	_assert(scene.gold == 1, "Wizard nearby kill gold ignores distant enemy")


func _test_dash_fireball_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_3")
	_assert(unlocked, "Wizard dash fireball talent unlocks")

	player.set("dash_cooldown_remaining", 0.0)
	player.set("action_animation_remaining", 0.0)
	player.set("facing_direction", Vector2.RIGHT)
	player.call("_try_start_dash")
	await process_frame
	var fireball := _find_fireball_with_radius(160.0)
	_assert(fireball != null, "Wizard dash fires a Fireball with 100% increased explosion radius")
	_assert(fireball != null and is_equal_approx(fireball.lifetime, 0.15), "Wizard dash Fireball has 90% reduced travel distance")


func _test_nearby_enemy_move_speed_talent() -> void:
	var nearby_enemy_a := Node2D.new()
	nearby_enemy_a.add_to_group("enemy")
	nearby_enemy_a.global_position = player.global_position + Vector2.RIGHT * 40.0
	scene.add_child(nearby_enemy_a)
	var nearby_enemy_b := Node2D.new()
	nearby_enemy_b.add_to_group("enemy")
	nearby_enemy_b.global_position = player.global_position + Vector2.DOWN * 60.0
	scene.add_child(nearby_enemy_b)

	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_4")
	_assert(unlocked, "Wizard nearby enemy move speed talent unlocks")
	player.call("_update_wizard_nearby_enemy_move_speed")
	var expected_bonus := float(EFFECT_TARGETING.enemies_surrounding(player, player.global_position).size()) * 0.05
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, expected_bonus), "Wizard nearby enemy move speed grants 5% per nearby enemy")


func _test_nearby_poison_aura_talent() -> void:
	var nearby_enemy := PoisonProbeEnemy.new()
	nearby_enemy.add_to_group("enemy")
	nearby_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(nearby_enemy)
	var distant_enemy := PoisonProbeEnemy.new()
	distant_enemy.add_to_group("enemy")
	distant_enemy.global_position = player.global_position + Vector2.RIGHT * 300.0
	scene.add_child(distant_enemy)

	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_5")
	_assert(unlocked, "Wizard nearby poison aura talent unlocks")
	player.call("_update_wizard_nearby_poison_aura", 4.9)
	_assert(nearby_enemy.poison_stacks == 0, "Wizard nearby poison aura waits 5s before applying poison")
	player.call("_update_wizard_nearby_poison_aura", 0.1)
	_assert(nearby_enemy.poison_stacks == 1, "Wizard nearby poison aura applies 1 Poison stack every 5s")
	_assert(distant_enemy.poison_stacks == 0, "Wizard nearby poison aura ignores distant enemies")


func _test_poisoned_kill_gold_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_6")
	_assert(unlocked, "Wizard poisoned kill gold talent unlocks")

	scene.gold = 0
	var poisoned_enemy := PoisonProbeEnemy.new()
	poisoned_enemy.poison_stacks = 1
	poisoned_enemy.global_position = player.global_position + Vector2.RIGHT * 300.0
	player.notify_enemy_killed(poisoned_enemy)
	_assert(scene.gold == 1, "Wizard poisoned kill gold grants 1 gold for poisoned enemy")

	var clean_enemy := PoisonProbeEnemy.new()
	clean_enemy.global_position = player.global_position + Vector2.RIGHT * 300.0
	player.notify_enemy_killed(clean_enemy)
	_assert(scene.gold == 1, "Wizard poisoned kill gold ignores non-poisoned enemy")


func _test_short_laser_double_damage_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_7")
	_assert(unlocked, "Wizard short laser double damage talent unlocks")

	player.set("pending_shockwave_target_position", player.global_position + Vector2.RIGHT * 200.0)
	player.call("_cast_wizard_fire_laser")
	await process_frame
	var laser := _find_laser_with_length(250.0)
	_assert(laser != null, "Wizard short laser talent reduces right-click range by 50%")
	_assert(laser != null and is_equal_approx(laser.chain_range, 250.0), "Wizard short laser talent also reduces chain range by 50%")
	_assert(laser != null and is_equal_approx(laser.damage, player.get_base_attack_damage() * 3.0), "Wizard short laser talent increases right-click damage by 100%")


func _test_nearby_enemy_elite_damage_talent() -> void:
	var nearby_enemy_a := Node2D.new()
	nearby_enemy_a.add_to_group("enemy")
	nearby_enemy_a.global_position = player.global_position + Vector2.RIGHT * 40.0
	scene.add_child(nearby_enemy_a)
	var nearby_enemy_b := Node2D.new()
	nearby_enemy_b.add_to_group("enemy")
	nearby_enemy_b.global_position = player.global_position + Vector2.DOWN * 60.0
	scene.add_child(nearby_enemy_b)

	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_8")
	_assert(unlocked, "Wizard nearby enemy elite damage talent unlocks")
	player.call("_update_wizard_nearby_enemy_elite_damage")
	var expected_bonus := float(EFFECT_TARGETING.enemies_surrounding(player, player.global_position).size()) * 0.1
	_assert(is_equal_approx(player.get_stats().elite_direct_damage_bonus, expected_bonus), "Wizard nearby enemy elite damage grants 10% per nearby enemy")


func _test_more_weaker_enemies_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_9")
	_assert(unlocked, "Wizard more weaker enemies talent unlocks")
	_assert(is_equal_approx(player.get_enemy_spawn_count_multiplier(), 2.0), "Wizard more weaker enemies doubles enemy count")
	_assert(is_equal_approx(player.get_enemy_max_hp_multiplier(), 0.7), "Wizard more weaker enemies reduces enemy max HP by 30%")


func _test_fire_essence_burst_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_bridge_center_0")
	_assert(unlocked, "Wizard fire essence burst talent unlocks")

	player.set("wizard_fire_essence_charges", 0)
	player.set("wizard_fire_essence_gold_progress", 0)
	player.call("_update_wizard_fire_essence_spawner", 5.0)
	_assert(_count_nodes_with_class("FireEssencePickup") == 0, "Wizard fire essence no longer spawns timed pickups")

	player.call("collect_gold_pickup", 9)
	_assert(int(player.get("wizard_fire_essence_charges")) == 0, "Wizard fire essence waits until 10 picked-up gold")
	_assert(int(player.get("wizard_fire_essence_gold_progress")) == 9, "Wizard fire essence tracks partial picked-up gold")
	player.call("collect_gold_pickup", 1)
	_assert(int(player.get("wizard_fire_essence_charges")) == 1, "Wizard fire essence grants 1 charge per 10 picked-up gold")
	_assert(int(player.get("wizard_fire_essence_gold_progress")) == 0, "Wizard fire essence resets gold progress after granting a charge")
	player.call("add_gold", 10, "Greed Blessing")
	_assert(int(player.get("wizard_fire_essence_charges")) == 1, "Wizard fire essence ignores non-pickup gold gains")
	player.set("wizard_fire_essence_charges", 3)
	player.call("collect_gold_pickup", 20)
	_assert(int(player.get("wizard_fire_essence_charges")) == 4, "Wizard fire essence stores at most 4 charges")
	_assert(int(player.get("wizard_fire_essence_gold_progress")) == 0, "Wizard fire essence drops excess gold progress at the storage cap")
	var before_fireballs := _count_nodes_with_class("FireballProjectile")
	player.set("wizard_fire_essence_charges", 1)
	player.call("_launch_wizard_fire_essence_burst", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before_fireballs + 4, "Wizard fire essence attack fires the original Fireball plus three extra Fireballs")
	var fireball := _find_fireball_with_allow_procs(true)
	_assert(fireball != null, "Wizard fire essence burst Fireballs allow normal procs")


func _test_fireball_max_hp_bonus_damage_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_11")
	_assert(unlocked, "Wizard left eleventh Fireball max HP damage talent unlocks")

	var old_max_hp := player.max_hp
	player.max_hp = 200.0
	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(enemy)

	player.deal_player_damage_to_enemy(enemy, 100.0, {"source": "fireball", "direct": true, "allow_procs": false, "allow_crit": false})
	var nearby_focus_multiplier := 1.5
	var expected_fireball_damage := (100.0 + player.max_hp * 0.1) * player.get_stats().get_damage_multiplier() * nearby_focus_multiplier
	_assert(is_equal_approx(enemy.last_damage, expected_fireball_damage), "Wizard left eleventh talent adds 10% max HP damage to Fireballs")

	player.deal_player_damage_to_enemy(enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	var expected_non_fireball_damage := 100.0 * player.get_stats().get_damage_multiplier() * nearby_focus_multiplier
	_assert(is_equal_approx(enemy.last_damage, expected_non_fireball_damage), "Wizard left eleventh talent does not affect non-Fireball damage")

	player.max_hp = old_max_hp
	player.set("talent_wizard_fireball_max_hp_bonus_damage_enabled", false)
	enemy.queue_free()


func _test_atk_percent_bonus_talent() -> void:
	player.unspent_talent_points = 1
	var old_atk := player.get_stats().atk
	player.get_stats().atk = 50
	var unlocked := _unlock_talent_for_test(&"flame_left_12")
	_assert(unlocked, "Wizard left twelfth ATK percent talent unlocks")
	_assert(player.get_stats().atk == 60, "Wizard left twelfth talent increases ATK by 20%")

	player.call("_remove_talent_stat_effect", &"flame_left_12")
	_assert(player.get_stats().atk == 50, "Wizard left twelfth talent rollback removes the applied ATK bonus")
	player.unlocked_talents.erase(&"flame_left_12")
	player.get_stats().atk = old_atk


func _test_fireball_radius_per_atk_talent() -> void:
	player.unspent_talent_points = 1
	var old_atk := player.get_stats().atk
	player.get_stats().atk = 50
	var unlocked := _unlock_talent_for_test(&"flame_left_13")
	_assert(unlocked, "Wizard left thirteenth Fireball radius per ATK talent unlocks")

	_clear_fireballs()
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	var fireball := _find_node_with_class("FireballProjectile") as FireballProjectile
	_assert(fireball != null and is_equal_approx(fireball.explosion_radius, 208.0), "Wizard left thirteenth talent grants 20% Fireball radius per 10 ATK")

	_clear_fireballs()
	await process_frame
	player.get_stats().atk = 70
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	fireball = _find_node_with_class("FireballProjectile") as FireballProjectile
	_assert(fireball != null and is_equal_approx(fireball.explosion_radius, 249.6), "Wizard left thirteenth talent updates Fireball radius from current ATK")

	player.get_stats().atk = old_atk
	player.set("talent_wizard_fireball_radius_per_atk_enabled", false)
	_clear_fireballs()


func _test_gold_move_speed_bonus_talent() -> void:
	scene.gold = 0
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_0")
	_assert(unlocked, "Wizard After Burn gold movement speed talent unlocks")
	var before_bonus := player.get_stats().movement_speed_bonus
	scene.gold = 9
	player.call("_update_wizard_gold_move_speed_bonus")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, before_bonus), "Wizard After Burn grants no movement speed below 10 gold")

	scene.gold = 10
	player.call("_update_wizard_gold_move_speed_bonus")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, before_bonus + 0.01), "Wizard After Burn grants 1% movement speed per 10 gold")

	scene.gold = 35
	player.call("_update_wizard_gold_move_speed_bonus")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, before_bonus + 0.03), "Wizard After Burn floors current gold to full 10 gold chunks")

	scene.gold = 20
	player.call("_update_wizard_gold_move_speed_bonus")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, before_bonus + 0.02), "Wizard After Burn movement speed drops when gold is spent")

	player.set("talent_wizard_gold_move_speed_bonus_enabled", false)
	player.call("_update_wizard_gold_move_speed_bonus")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, before_bonus), "Wizard After Burn removes its movement speed when disabled")
	scene.gold = 0


func _test_fire_surge_radial_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_1")
	_assert(unlocked, "Wizard fire surge radial Fireballs talent unlocks")

	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_start_fire_surge")
	player.call("_update_fire_surge", 5.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 8, "Wizard Fire Surge radial talent fires 8 Fireballs every 5s")


func _test_max_hp_primary_echo_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_2")
	_assert(unlocked, "Wizard max HP primary echo talent unlocks")

	player.max_hp = 200.0
	player.get_stats().max_hp = 200
	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_schedule_wizard_primary_echoes", player.global_position + Vector2.RIGHT * 200.0, false)
	await create_timer(0.45).timeout
	_assert(_count_nodes_with_class("FireballProjectile") == before + 2, "Wizard max HP primary echo repeats once per 100 max HP")

	player.max_hp = 100.0
	player.get_stats().max_hp = 100
	before = _count_nodes_with_class("FireballProjectile")
	player.call("_schedule_wizard_primary_echoes", player.global_position + Vector2.RIGHT * 200.0, true)
	await create_timer(0.25).timeout
	_assert(_count_nodes_with_class("FireballProjectile") == before + 4, "Wizard max HP primary echo copies Fire Essence four-Fireball attack")


func _test_gold_extra_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_3")
	_assert(unlocked, "Wizard Swift Volley gold extra Fireballs talent unlocks")

	scene.gold = 49
	_assert(player.call("_get_wizard_move_speed_extra_fireball_count") == 0, "Wizard Swift Volley waits for 50 gold before adding a Fireball")
	scene.gold = 50
	_assert(player.call("_get_wizard_move_speed_extra_fireball_count") == 1, "Wizard Swift Volley adds 1 Fireball per 50 gold")
	scene.gold = 100
	_assert(player.call("_get_wizard_move_speed_extra_fireball_count") == 2, "Wizard Swift Volley scales with current gold")

	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 3, "Wizard Swift Volley fires gold-based extra Fireballs without replacing the original")
	scene.gold = 0


func _test_poisoned_death_extra_gold_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_4")
	_assert(unlocked, "Wizard Venom Burst extra gold talent unlocks")
	_assert(bool(player.get("talent_wizard_poisoned_death_extra_gold_enabled")), "Wizard Venom Burst enables poisoned enemy extra gold drops")


func _test_rare_item_virtual_gold_talent() -> void:
	scene.gold = 30
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_5")
	_assert(unlocked, "Wizard Rare Credit virtual gold talent unlocks")

	var before_flat_speed := player.get_stats().bonus_move_speed_flat
	var before_move_bonus := player.get_stats().movement_speed_bonus
	player.add_item(_make_test_item(&"wizard_rare_stride_a", &"rare"))
	player.add_item(_make_test_item(&"wizard_rare_stride_b", &"rare"))
	player.add_item(_make_test_item(&"wizard_common_stride", &"common"))
	_assert(int(player.call("_get_wizard_effective_gold_for_talents")) == 50, "Wizard Rare Credit counts each rare item as 10 extra gold")
	_assert(is_equal_approx(player.get_stats().bonus_move_speed_flat, before_flat_speed), "Wizard Rare Credit does not directly add flat movement speed")

	player.set("talent_wizard_gold_move_speed_bonus_enabled", true)
	player.call("_update_wizard_gold_move_speed_bonus")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, before_move_bonus + 0.05), "Wizard After Burn uses Rare Credit virtual gold")
	_assert(player.call("_get_wizard_move_speed_extra_fireball_count") == 1, "Wizard Swift Volley uses Rare Credit virtual gold")

	player.set("talent_wizard_gold_move_speed_bonus_enabled", false)
	player.call("_update_wizard_gold_move_speed_bonus")
	scene.gold = 0


func _test_fire_essence_explosion_scatter_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_6")
	_assert(unlocked, "Wizard Fire Essence explosion scatter talent unlocks")

	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	var expected_remaining_fireballs := 3 + int(player.call("_get_wizard_move_speed_extra_fireball_count")) + 8
	var scatter_fireball := _find_fireball_with_explode_callback()
	_assert(scatter_fireball != null, "Wizard Fire Essence explosion scatter marks the main Fireball")
	if scatter_fireball != null:
		scatter_fireball.explode()
		await create_timer(0.35).timeout
		_assert(_count_nodes_with_class("FireballProjectile") == before + expected_remaining_fireballs, "Wizard Fire Essence explosion scatter adds 8 Fireballs in a spinning burst after the Fire Essence attack")


func _test_random_double_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_12")
	_assert(unlocked, "Wizard random double Fireballs talent unlocks")

	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 6, "Wizard random double Fireballs talent doubles the Fireball total after legendary extra Fireballs")


func _test_guaranteed_legendary_shop_jar_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_7")
	_assert(unlocked, "Wizard guaranteed legendary shop jar talent unlocks")
	_assert(player.has_guaranteed_legendary_shop_jar(), "Wizard guaranteed legendary shop jar talent marks shops for a forced legendary jar")
	_assert(is_equal_approx(player.get_shop_tier_price_multiplier(2), 2.0), "Wizard guaranteed legendary shop jar talent doubles legendary jar prices")
	_assert(is_equal_approx(player.get_shop_tier_price_multiplier(1), 1.0), "Wizard guaranteed legendary shop jar talent does not change non-legendary jar prices")


func _test_lasting_bloom_piercing_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_8")
	_assert(unlocked, "Wizard Piercing Bloom Fireball talent unlocks")

	var fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	fireball.setup(player, player.global_position, Vector2.RIGHT, 12.0, 80.0)
	scene.add_child(fireball)
	_assert(fireball.pierce_enemies, "Wizard Piercing Bloom makes Fireballs pierce enemies")

	fireball.owner_player = null
	var first_enemy := DamageProbeEnemy.new()
	first_enemy.global_position = fireball.global_position
	first_enemy.add_to_group("enemy")
	scene.add_child(first_enemy)
	var second_enemy := DamageProbeEnemy.new()
	second_enemy.global_position = fireball.global_position + Vector2.RIGHT * 8.0
	second_enemy.add_to_group("enemy")
	scene.add_child(second_enemy)

	fireball.call("_on_body_entered", first_enemy)
	_assert(not fireball.exploded, "Wizard Piercing Bloom Fireballs do not explode when they hit an enemy")
	_assert(is_equal_approx(first_enemy.total_damage, 7.2), "Wizard Piercing Bloom Fireballs still deal impact damage")
	fireball.call("_on_body_entered", first_enemy)
	_assert(is_equal_approx(first_enemy.total_damage, 7.2), "Wizard Piercing Bloom Fireballs do not repeatedly damage the same enemy during one overlap")
	fireball.call("_on_body_entered", second_enemy)
	_assert(not fireball.exploded, "Wizard Piercing Bloom Fireballs keep piercing through additional enemies")
	_assert(is_equal_approx(second_enemy.total_damage, 7.2), "Wizard Piercing Bloom Fireballs deal impact damage to each pierced enemy")

	fireball.explode(true)
	_assert(fireball.exploded, "Wizard Piercing Bloom Fireballs still explode when their flight ends naturally")
	_assert(is_equal_approx(fireball.explosion_radius, 80.0), "Wizard Piercing Bloom no longer doubles natural explosion radius")
	_assert(is_equal_approx(first_enemy.total_damage, 19.2), "Wizard Piercing Bloom natural explosion deals explosion damage after piercing")
	_assert(is_equal_approx(second_enemy.total_damage, 19.2), "Wizard Piercing Bloom natural explosion hits pierced enemies in its radius")
	first_enemy.queue_free()
	second_enemy.queue_free()
	await process_frame


func _test_legendary_extra_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_9")
	_assert(unlocked, "Wizard legendary extra Fireballs talent unlocks")

	player.add_item(_make_test_item(&"wizard_legendary_embers_a", &"legendary"))
	player.add_item(_make_test_item(&"wizard_legendary_embers_b", &"legendary"))
	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 3, "Wizard legendary extra Fireballs adds one Fireball per legendary item")


func _test_warm_ash_wall_bounce_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_10")
	_assert(unlocked, "Wizard Rebound Ash wall bounce talent unlocks")

	var had_legendary_extra_fireballs := bool(player.get("talent_wizard_legendary_extra_fireballs_enabled"))
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)
	player.hp = 10.0
	player.max_hp = 20.0
	var fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	fireball.setup(player, player.global_position, Vector2.RIGHT, 12.0, 80.0)
	scene.add_child(fireball)
	await process_frame
	_assert(fireball.bounce_on_walls, "Wizard Rebound Ash makes Fireballs bounce off walls")
	_assert(is_equal_approx(fireball.lifetime, 3.0), "Wizard Rebound Ash doubles Fireball flight distance")

	var wall := StaticBody2D.new()
	scene.add_child(wall)
	fireball.call("_on_body_entered", wall)
	_assert(not fireball.exploded, "Wizard Rebound Ash Fireballs do not explode when they hit walls")
	_assert(fireball.direction.x < 0.0, "Wizard Rebound Ash Fireballs reflect away from walls")

	fireball.explode(true)
	_assert(is_equal_approx(player.hp, 10.0), "Wizard Rebound Ash no longer heals on natural Fireball explosion")
	wall.queue_free()
	player.set("talent_wizard_legendary_extra_fireballs_enabled", had_legendary_extra_fireballs)
	await process_frame


func _test_pain_bloom_move_speed_fireball_speed_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_center_11")
	_assert(unlocked, "Wizard Kinetic Bloom move speed Fireball speed talent unlocks")

	_clear_fireballs()
	await process_frame

	var stats := player.get_stats()
	var old_move_speed_bonus := stats.movement_speed_bonus
	var had_speed_bonus := bool(player.get("talent_wizard_fireball_speed_bonus_enabled"))
	var had_legendary_extra_fireballs := bool(player.get("talent_wizard_legendary_extra_fireballs_enabled"))
	player.set("talent_wizard_fireball_speed_bonus_enabled", false)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)
	stats.movement_speed_bonus = 0.25

	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	var fireball := _find_node_with_class("FireballProjectile") as FireballProjectile
	_assert(fireball != null and is_equal_approx(fireball.speed, 650.0), "Wizard Kinetic Bloom applies movement speed bonus to Fireball travel speed")
	_assert(fireball != null and is_equal_approx(fireball.lifetime, 3.0), "Wizard Kinetic Bloom coexists with Rebound Ash doubled flight distance")

	stats.movement_speed_bonus = old_move_speed_bonus
	player.set("talent_wizard_fireball_speed_bonus_enabled", had_speed_bonus)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", had_legendary_extra_fireballs)
	player.set("talent_wizard_damage_taken_natural_explode_fireballs_enabled", false)
	_clear_fireballs()
	await process_frame


func _test_rebirth_level_to_atk_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_left_10")
	_assert(unlocked, "Wizard rebirth level to ATK talent unlocks")

	player.level = 6
	player.experience = 7
	player.pending_talent_points = 2
	player.unspent_talent_points = 3
	saw_zero_hp_changed = false
	if not player.hp_changed.is_connected(_on_hp_changed_for_rebirth_test):
		player.hp_changed.connect(_on_hp_changed_for_rebirth_test)
	var before_atk := player.get_stats().atk
	player.take_damage(player.max_hp + 10.0)
	_assert(not player.is_queued_for_deletion(), "Wizard rebirth prevents death queue_free")
	_assert(not saw_zero_hp_changed, "Wizard rebirth prevents broadcasting 0 HP")
	_assert(player.level == 1, "Wizard rebirth resets level")
	_assert(player.experience == 0, "Wizard rebirth resets experience")
	_assert(player.pending_talent_points == 0 and player.unspent_talent_points == 0, "Wizard rebirth resets talent points")
	_assert(player.unlocked_talents.is_empty(), "Wizard rebirth resets unlocked talents")
	_assert(is_equal_approx(player.get_stats().atk, before_atk + 5.0), "Wizard rebirth grants 1 ATK per lost level")
	_assert(roundi(player.hp) == roundi(player.max_hp), "Wizard rebirth restores HP")


func _test_primary_fireball_laser_explosion_talent() -> void:
	player.unspent_talent_points = 2
	_assert(_unlock_talent_for_test(&"flame_bottom_5"), "Wizard right branch laser explosion path unlocks start")
	var unlocked := _unlock_talent_for_test(&"flame_bottom_6")
	_assert(unlocked, "Wizard primary Fireball laser explosion talent unlocks")

	_clear_fireballs()
	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position + Vector2.RIGHT * 160.0
	enemy.add_to_group("enemy")
	scene.add_child(enemy)
	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	var fireball := _find_fireball_with_replacement_callback()
	_assert(fireball != null, "Wizard primary Fireball laser explosion marks left-click Fireballs")
	if fireball != null:
		fireball.explode(false)
		await process_frame
		_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 1, "Wizard primary Fireball explosion spawns a right-click Fire Laser")
		_assert(is_equal_approx(enemy.last_damage, 0.0), "Wizard primary Fireball laser explosion replaces original explosion damage")
	enemy.queue_free()


func _test_fire_surge_laser_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_bottom_7")
	_assert(unlocked, "Wizard Fire Surge laser talent unlocks")

	_clear_fireballs()
	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position + Vector2.RIGHT * 180.0
	enemy.add_to_group("enemy")
	scene.add_child(enemy)
	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	var before_fireballs := _count_nodes_with_class("FireballProjectile")
	player.call("_start_fire_surge")
	player.call("_update_fire_surge", 5.0)
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 3, "Wizard Fire Surge laser talent triggers a Fire Laser every 2s")
	_assert(_count_nodes_with_class("FireballProjectile") == before_fireballs, "Wizard Fire Surge laser talent replaces Fire Surge Fireballs")

	player.set("talent_wizard_fire_surge_radial_fireballs_enabled", true)
	before_lasers = _count_nodes_with_class("HolyFlameLaser")
	before_fireballs = _count_nodes_with_class("FireballProjectile")
	player.call("_start_fire_surge")
	player.call("_update_fire_surge", 5.0)
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 8, "Wizard Fire Surge laser talent combines with radial Fire Surge into eight radial Fire Lasers every 5s")
	_assert(_count_nodes_with_class("FireballProjectile") == before_fireballs, "Wizard radial Fire Surge laser combo replaces radial Fireballs")
	enemy.queue_free()


func _test_fire_laser_chain_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_bottom_8")
	_assert(unlocked, "Wizard Fire Laser chain talent unlocks")

	var first_enemy := DamageProbeEnemy.new()
	first_enemy.global_position = player.global_position + Vector2.RIGHT * 120.0
	first_enemy.add_to_group("enemy")
	scene.add_child(first_enemy)
	var second_enemy := DamageProbeEnemy.new()
	second_enemy.global_position = player.global_position + Vector2.RIGHT * 240.0
	second_enemy.add_to_group("enemy")
	scene.add_child(second_enemy)

	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	player.call("_spawn_wizard_fire_laser", player.global_position, Vector2.RIGHT)
	await process_frame
	var laser := _find_newest_laser()
	_assert(laser != null and laser.chain_remaining == 1, "Wizard Fire Laser chain talent gives new Fire Lasers one chain")
	if laser != null:
		laser.call("_damage_enemy", first_enemy)
		await process_frame
		_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 2, "Wizard Fire Laser chain talent spawns one chained Fire Laser on hit")
		var chained_laser := _find_newest_laser()
		_assert(chained_laser != null and chained_laser.chain_remaining == 0, "Wizard chained Fire Laser does not chain again")
	first_enemy.queue_free()
	second_enemy.queue_free()


func _test_fire_surge_attack_speed_talent() -> void:
	player.set("fire_surge_remaining", 0.0)
	player.call("_update_wizard_fire_surge_attack_speed_bonus")
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_5")
	_assert(unlocked, "Wizard Fire Surge attack speed talent unlocks")

	var before_bonus := player.get_stats().attack_speed_bonus
	player.call("_start_fire_surge")
	player.call("_update_wizard_fire_surge_attack_speed_bonus")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, before_bonus + 0.5), "Wizard Fire Surge attack speed talent grants 50% attack speed during Fire Surge")
	player.set("fire_surge_remaining", 0.0)
	player.call("_update_wizard_fire_surge_attack_speed_bonus")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, before_bonus), "Wizard Fire Surge attack speed talent clears after Fire Surge ends")


func _test_early_round_enemy_gold_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_1")
	_assert(unlocked, "Wizard early round enemy gold talent unlocks")

	player.call("emit_round_started", 2)
	_assert(is_equal_approx(player.get_enemy_gold_reward_multiplier(DamageProbeEnemy.new()), 2.0), "Wizard early round enemy gold talent doubles enemy gold in the first 10s")
	player.set("wizard_early_round_gold_remaining", 0.0)
	_assert(is_equal_approx(player.get_enemy_gold_reward_multiplier(DamageProbeEnemy.new()), 1.0), "Wizard early round enemy gold talent expires after the first 10s")


func _test_fireball_split_impact_and_explosion_damage() -> void:
	_clear_fireballs()
	player.set("talent_wizard_fireball_damage_bonus_enabled", false)
	player.set("talent_wizard_fireball_radius_bonus_enabled", false)
	player.set("talent_wizard_fireball_radius_per_atk_enabled", false)
	player.set("talent_wizard_primary_fireball_laser_explosion_enabled", false)
	player.set("talent_wizard_fireball_max_hp_bonus_damage_enabled", false)
	player.set("talent_wizard_nearby_damage_focus_enabled", false)

	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position
	enemy.add_to_group("enemy")
	scene.add_child(enemy)

	var fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	fireball.setup(null, player.global_position, Vector2.RIGHT, 100.0, 80.0)
	scene.add_child(fireball)
	var expected_explosion_damage := 100.0
	_assert(is_equal_approx(fireball.impact_damage, expected_explosion_damage * 0.6), "Wizard Fireball impact damage is 60% of ATK")
	if fireball != null:
		fireball.call("_on_body_entered", enemy)
	_assert(is_equal_approx(enemy.last_damage, expected_explosion_damage), "Wizard Fireball explosion damage remains 100% of ATK")
	_assert(is_equal_approx(enemy.total_damage, expected_explosion_damage * 1.6), "Wizard Fireball direct hit applies 60% impact damage plus 100% explosion damage")
	enemy.queue_free()
	_clear_fireballs()

	var container := BreakableContainer.new()
	container.max_hp = 100.0
	container.hp = container.max_hp
	container.global_position = player.global_position
	scene.add_child(container)
	player.call("_spawn_wizard_fireball", player.global_position, Vector2.RIGHT)
	var fireballs := _collect_fireball_projectiles(player.get_tree().current_scene)
	fireball = fireballs[fireballs.size() - 1] if not fireballs.is_empty() else null
	_assert(fireball != null and fireball.explode_on_containers, "Wizard Fireball collides with containers by default")
	_assert(fireball != null and fireball.get_collision_mask_value(6), "Wizard Fireball enables jar collision mask by default")
	if fireball != null:
		fireball.call("_on_area_entered", container)
	_assert(fireball != null and fireball.exploded, "Wizard Fireball explodes when hitting a container by default")
	_assert(container.hp < container.max_hp, "Wizard Fireball impact and explosion damage containers by default")
	container.queue_free()


func _test_fireball_explodes_on_containers_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_2")
	_assert(unlocked, "Wizard Fireball container impact talent unlocks")

	_clear_fireballs()
	player.call("_spawn_wizard_fireball", player.global_position, Vector2.RIGHT)
	await process_frame
	var fireball := _find_node_with_class("FireballProjectile") as FireballProjectile
	_assert(fireball != null and fireball.explode_on_containers, "Wizard Fireball container impact talent marks Fireballs")
	_assert(fireball != null and fireball.get_collision_mask_value(6), "Wizard Fireball container impact talent enables jar collision mask")

	var container := BreakableContainer.new()
	scene.add_child(container)
	if fireball != null:
		fireball.call("_on_area_entered", container)
		_assert(fireball.exploded, "Wizard Fireball explodes when entering a container")
	container.queue_free()

	player.set("talent_wizard_primary_fireball_laser_explosion_enabled", true)
	_clear_fireballs()
	for enemy in scene.get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	await process_frame
	var fallback_container := BreakableContainer.new()
	fallback_container.max_hp = 100.0
	fallback_container.global_position = player.global_position
	scene.add_child(fallback_container)
	player.call("_spawn_wizard_fireball", fallback_container.global_position, Vector2.RIGHT)
	await process_frame
	fireball = _find_node_with_class("FireballProjectile") as FireballProjectile
	if fireball != null:
		fireball.call("_on_area_entered", fallback_container)
		await process_frame
		_assert(fallback_container.hp < fallback_container.max_hp, "Wizard Fireball falls back to normal explosion on containers when Laser Burst has no enemy target")
	fallback_container.queue_free()

	var target_enemy := DamageProbeEnemy.new()
	target_enemy.global_position = player.global_position + Vector2.RIGHT * 160.0
	target_enemy.add_to_group("enemy")
	scene.add_child(target_enemy)
	var replacement_container := BreakableContainer.new()
	replacement_container.max_hp = 100.0
	replacement_container.global_position = player.global_position
	scene.add_child(replacement_container)
	var beam_container := BreakableContainer.new()
	beam_container.max_hp = 100.0
	beam_container.global_position = player.global_position + Vector2.RIGHT * 220.0
	scene.add_child(beam_container)
	player.call("_spawn_wizard_fireball", replacement_container.global_position, Vector2.RIGHT)
	await process_frame
	fireball = _find_node_with_class("FireballProjectile") as FireballProjectile
	if fireball != null:
		fireball.call("_on_area_entered", replacement_container)
		await process_frame
		_assert(replacement_container.hp < replacement_container.max_hp, "Wizard Laser Burst Fireball still damages containers with its explosion")
		var replacement_laser := _find_newest_laser()
		if replacement_laser != null:
			replacement_laser.call("_apply_damage")
		_assert(beam_container.hp < beam_container.max_hp, "Wizard Laser Burst replacement laser damages containers inside its beam")
		_assert(is_equal_approx(target_enemy.last_damage, 0.0), "Wizard Laser Burst Fireball still replaces enemy explosion damage")
	beam_container.queue_free()
	replacement_container.queue_free()
	target_enemy.queue_free()


func _test_container_break_laser_no_container_damage_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_3")
	_assert(unlocked, "Wizard container break Fire Laser talent unlocks")

	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position + Vector2.RIGHT * 180.0
	enemy.add_to_group("enemy")
	scene.add_child(enemy)
	var container := BreakableContainer.new()
	container.global_position = player.global_position
	scene.add_child(container)

	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	var triggered: bool = player.call("_try_trigger_wizard_container_break_laser", container, 0.0)
	await process_frame
	_assert(triggered, "Wizard container break Fire Laser talent can trigger from a broken container")
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 1, "Wizard container break Fire Laser talent spawns a Fire Laser")
	var laser := _find_newest_laser()
	_assert(laser != null and not laser.damages_containers, "Wizard container break Fire Laser talent disables Fire Laser container damage")
	_assert(laser != null and not laser.get_collision_mask_value(6), "Wizard container break Fire Laser talent disables Fire Laser jar collision mask")

	container.queue_free()
	enemy.queue_free()


func _test_poisoned_death_fire_laser_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_4")
	_assert(unlocked, "Wizard poisoned death Fire Laser talent unlocks")

	var before := _count_nodes_with_class("HolyFlameLaser")
	var poisoned_enemy := PoisonProbeEnemy.new()
	poisoned_enemy.poison_stacks = 1
	poisoned_enemy.global_position = player.global_position + Vector2.RIGHT * 140.0
	player.notify_enemy_killed(poisoned_enemy)
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before + 1, "Wizard poisoned death Fire Laser triggers from poisoned enemy death")

	before = _count_nodes_with_class("HolyFlameLaser")
	var clean_enemy := PoisonProbeEnemy.new()
	clean_enemy.global_position = player.global_position + Vector2.RIGHT * 140.0
	player.notify_enemy_killed(clean_enemy)
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before, "Wizard poisoned death Fire Laser ignores non-poisoned enemy death")


func _test_quick_kill_max_hp_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_0")
	_assert(unlocked, "Wizard quick kill max HP talent unlocks")

	var before_max_hp := player.max_hp
	var quick_enemy := Node2D.new()
	quick_enemy.set_meta(&"spawn_msec", Time.get_ticks_msec())
	player.notify_enemy_killed(quick_enemy)
	_assert(is_equal_approx(player.max_hp, before_max_hp + 1.0), "Wizard quick kill max HP talent grants 1 max HP for enemies killed before 2s")

	var old_enemy := Node2D.new()
	old_enemy.set_meta(&"spawn_msec", Time.get_ticks_msec() - 2500)
	player.notify_enemy_killed(old_enemy)
	_assert(is_equal_approx(player.max_hp, before_max_hp + 1.0), "Wizard quick kill max HP talent ignores enemies older than 2s")

	player.set("wizard_quick_kill_max_hp_this_round", 19)
	var capped_enemy_a := Node2D.new()
	capped_enemy_a.set_meta(&"spawn_msec", Time.get_ticks_msec())
	player.notify_enemy_killed(capped_enemy_a)
	var capped_value := player.max_hp
	var capped_enemy_b := Node2D.new()
	capped_enemy_b.set_meta(&"spawn_msec", Time.get_ticks_msec())
	player.notify_enemy_killed(capped_enemy_b)
	_assert(is_equal_approx(player.max_hp, capped_value), "Wizard quick kill max HP talent caps at 20 max HP per round")

	player.call("emit_round_started", 3)
	_assert(int(player.get("wizard_quick_kill_max_hp_this_round")) == 0, "Wizard quick kill max HP talent resets round cap each round")


func _test_slide_momentum_talent() -> void:
	player.unspent_talent_points = 1
	if not player.unlocked_talents.has(&"flame_right_2"):
		player.unspent_talent_points += 1
		_assert(_unlock_talent_for_test(&"flame_right_2"), "Wizard slide momentum path unlocks right 2")
	if not player.unlocked_talents.has(&"flame_right_3"):
		player.unspent_talent_points += 1
		_assert(_unlock_talent_for_test(&"flame_right_3"), "Wizard slide momentum path unlocks right 3")
	if not player.unlocked_talents.has(&"flame_right_4"):
		player.unspent_talent_points += 1
		_assert(_unlock_talent_for_test(&"flame_right_4"), "Wizard slide momentum path unlocks right 4")
	if not player.unlocked_talents.has(&"flame_right_5"):
		player.unspent_talent_points += 1
		_assert(_unlock_talent_for_test(&"flame_right_5"), "Wizard slide momentum path unlocks right 5")
	var unlocked := _unlock_talent_for_test(&"flame_right_6")
	_assert(unlocked, "Wizard slide momentum talent unlocks")

	player.get_stats().attack_speed_bonus = 0.0
	player.get_stats().movement_speed_bonus = 0.0
	for _index in range(12):
		player.call("_apply_slide_finished_talents")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, 0.5), "Wizard slide momentum caps attack speed at 50%")
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, 0.5), "Wizard slide momentum caps movement speed at 50%")
	var buffs: TemporaryBuffComponent = player.get_temporary_buffs()
	var attack_buff: Dictionary = buffs.buffs.get(&"wizard_slide_momentum_attack_speed", {})
	var move_buff: Dictionary = buffs.buffs.get(&"wizard_slide_momentum_move_speed", {})
	_assert(is_equal_approx(float(attack_buff.get("time_left", 0.0)), 5.0), "Wizard slide momentum attack speed lasts 5s")
	_assert(is_equal_approx(float(move_buff.get("time_left", 0.0)), 5.0), "Wizard slide momentum movement speed lasts 5s")


func _test_fire_laser_chain_heals_player_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_7")
	_assert(unlocked, "Wizard Fire Laser player chain talent unlocks")

	var source_enemy := DamageProbeEnemy.new()
	source_enemy.global_position = player.global_position + Vector2.RIGHT * 120.0
	source_enemy.add_to_group("enemy")
	scene.add_child(source_enemy)

	player.hp = player.max_hp - 5.0
	var before_hp := player.hp
	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	player.call("spawn_chained_wizard_fire_laser", source_enemy, 0, 700.0, [source_enemy])
	await process_frame
	_assert(is_equal_approx(player.hp, before_hp + 1.0), "Wizard Fire Laser player chain heals 1 HP")
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 1, "Wizard Fire Laser player chain spawns a visual laser")
	var laser := _find_newest_laser()
	_assert(laser != null and not laser.damages_enemies, "Wizard Fire Laser player chain does not damage enemies")
	_assert(laser != null and not laser.get_collision_mask_value(2), "Wizard Fire Laser player chain disables enemy collision mask")
	source_enemy.queue_free()


func _test_fire_laser_chain_damage_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_8")
	_assert(unlocked, "Wizard Fire Laser chain damage talent unlocks")

	var source_enemy := DamageProbeEnemy.new()
	source_enemy.global_position = player.global_position + Vector2.RIGHT * 120.0
	source_enemy.add_to_group("enemy")
	scene.add_child(source_enemy)
	var target_enemy := DamageProbeEnemy.new()
	target_enemy.global_position = player.global_position + Vector2.RIGHT * 240.0
	target_enemy.add_to_group("enemy")
	scene.add_child(target_enemy)

	player.call("spawn_chained_wizard_fire_laser", source_enemy, 0, 700.0, [source_enemy], 1.0)
	await process_frame
	var laser := _find_newest_laser()
	var expected_first_chain_damage: float = player.get_base_attack_damage() * 1.5 * 1.2
	_assert(laser != null and is_equal_approx(laser.damage, expected_first_chain_damage), "Wizard Fire Laser chain damage talent adds 20% damage on first chain")

	player.call("spawn_chained_wizard_fire_laser", source_enemy, 0, 700.0, [source_enemy], 1.2)
	await process_frame
	laser = _find_newest_laser()
	var expected_second_chain_damage: float = player.get_base_attack_damage() * 1.5 * 1.44
	_assert(laser != null and is_equal_approx(laser.damage, expected_second_chain_damage), "Wizard Fire Laser chain damage talent stacks multiplicatively per chain")

	source_enemy.queue_free()
	target_enemy.queue_free()


func _test_fire_laser_chain_prefers_new_targets_then_repeats() -> void:
	var source_enemy := DamageProbeEnemy.new()
	source_enemy.global_position = player.global_position + Vector2.RIGHT * 120.0
	source_enemy.add_to_group("enemy")
	scene.add_child(source_enemy)
	var new_enemy := DamageProbeEnemy.new()
	new_enemy.global_position = player.global_position + Vector2.RIGHT * 220.0
	new_enemy.add_to_group("enemy")
	scene.add_child(new_enemy)
	var old_enemy := DamageProbeEnemy.new()
	old_enemy.global_position = player.global_position + Vector2.RIGHT * 260.0
	old_enemy.add_to_group("enemy")
	scene.add_child(old_enemy)

	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	player.call("spawn_chained_wizard_fire_laser", source_enemy, 0, 700.0, [source_enemy, old_enemy])
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 1, "Wizard Fire Laser chain still targets an unchained enemy first")
	var laser := _find_newest_laser()
	_assert(laser != null and laser.damaged_bodies.has(source_enemy) and laser.damaged_bodies.has(old_enemy), "Wizard Fire Laser chain preserves previous chain history")

	new_enemy.queue_free()
	await process_frame
	before_lasers = _count_nodes_with_class("HolyFlameLaser")
	player.call("spawn_chained_wizard_fire_laser", source_enemy, 0, 700.0, [source_enemy, old_enemy])
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 1, "Wizard Fire Laser chain can repeat old targets when no new enemy is available")

	source_enemy.queue_free()
	old_enemy.queue_free()


func _test_slide_fire_laser_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_9")
	_assert(unlocked, "Wizard slide Fire Laser talent unlocks")

	player.set("dash_direction", Vector2.RIGHT)
	var before_lasers := _count_nodes_with_class("HolyFlameLaser")
	player.call("_apply_slide_finished_talents")
	await process_frame
	_assert(_count_nodes_with_class("HolyFlameLaser") == before_lasers + 1, "Wizard slide Fire Laser talent spawns a Fire Laser after sliding")


func _test_fire_laser_damages_containers_in_beam() -> void:
	var container := BreakableContainer.new()
	container.max_hp = 100.0
	container.global_position = player.global_position + Vector2.RIGHT * 220.0
	scene.add_child(container)

	player.call("_spawn_wizard_fire_laser", player.global_position, Vector2.RIGHT)
	await process_frame
	var laser := _find_newest_laser()
	if laser != null:
		laser.call("_apply_damage")
	_assert(container.hp < container.max_hp, "Wizard Fire Laser damages containers inside its beam")
	container.queue_free()


func _test_fire_laser_ignores_shop_containers() -> void:
	var container := BreakableContainer.new()
	container.max_hp = 100.0
	container.is_shop_container = true
	container.global_position = player.global_position + Vector2.RIGHT * 220.0
	scene.add_child(container)

	player.call("_spawn_wizard_fire_laser", player.global_position, Vector2.RIGHT)
	await process_frame
	var laser := _find_newest_laser()
	if laser != null:
		laser.call("_apply_damage")
	_assert(is_equal_approx(container.hp, container.max_hp), "Wizard Fire Laser does not damage shop containers directly")
	container.queue_free()


func _test_opening_attack_speed_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_10")
	_assert(unlocked, "Wizard opening attack speed talent unlocks")

	player.get_stats().attack_speed_bonus = 0.0
	player.call("emit_round_started", 4)
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, 0.5), "Wizard opening attack speed talent grants 50% attack speed")
	var buffs: TemporaryBuffComponent = player.get_temporary_buffs()
	var buff: Dictionary = buffs.buffs.get(&"wizard_opening_attack_speed", {})
	_assert(is_equal_approx(float(buff.get("time_left", 0.0)), 10.0), "Wizard opening attack speed talent lasts 10s")


func _test_attack_chain_lightning_chance_talent() -> void:
	player.unspent_talent_points = 1
	var before_chance := player.get_stats().chain_lightning_chance
	var unlocked := _unlock_talent_for_test(&"flame_right_11")
	_assert(unlocked, "Wizard right eleventh attack Chain Lightning talent unlocks")
	_assert(is_equal_approx(player.get_stats().chain_lightning_chance, before_chance + 0.5), "Wizard right eleventh talent grants 50% Chain Lightning chance")

	var source_enemy := DamageProbeEnemy.new()
	source_enemy.add_to_group("enemy")
	source_enemy.global_position = player.global_position + Vector2.RIGHT * 500.0
	scene.add_child(source_enemy)
	var chained_enemy := DamageProbeEnemy.new()
	chained_enemy.add_to_group("enemy")
	chained_enemy.global_position = source_enemy.global_position + Vector2.RIGHT * 16.0
	scene.add_child(chained_enemy)

	player.get_stats().chain_lightning_chance = 1.0
	player.deal_player_damage_to_enemy(source_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": true, "allow_crit": false})
	_assert(chained_enemy.last_damage > 0.0, "Wizard right eleventh talent can trigger Chain Lightning from attacks")

	player.get_stats().chain_lightning_chance = before_chance
	source_enemy.queue_free()
	chained_enemy.queue_free()


func _test_chain_lightning_attack_speed_stack_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_12")
	_assert(unlocked, "Wizard right twelfth Chain Lightning attack speed talent unlocks")

	var old_attack_speed := player.get_stats().attack_speed_bonus
	player.get_stats().attack_speed_bonus = 0.0
	player.get_temporary_buffs().call("_remove_buff", &"wizard_chain_lightning_attack_speed_stack")

	var enemies: Array[DamageProbeEnemy] = []
	var origin := Vector2(10000.0, 10000.0)
	for index in range(3):
		var enemy := DamageProbeEnemy.new()
		enemy.add_to_group("enemy")
		enemy.global_position = origin + Vector2.RIGHT * (float(index) * 16.0)
		scene.add_child(enemy)
		enemies.append(enemy)

	player.call("_trigger_holy_strike_chain_lightning", origin)
	var buff: Dictionary = player.get_temporary_buffs().buffs.get(&"wizard_chain_lightning_attack_speed_stack", {})
	_assert(int(buff.get("stacks", 0)) == 3, "Wizard right twelfth talent gains one attack speed stack per Chain Lightning hit")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, 0.06), "Wizard right twelfth talent grants 2% attack speed per stack")
	_assert(is_equal_approx(float(buff.get("time_left", 0.0)), 3.0), "Wizard right twelfth talent stacks last 3s")

	for _index in range(30):
		player.call("_apply_wizard_chain_lightning_attack_speed_stack")
	buff = player.get_temporary_buffs().buffs.get(&"wizard_chain_lightning_attack_speed_stack", {})
	_assert(int(buff.get("stacks", 0)) == 25, "Wizard right twelfth talent caps at 25 stacks")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, 0.5), "Wizard right twelfth talent caps at 50% attack speed")

	player.get_temporary_buffs().call("_remove_buff", &"wizard_chain_lightning_attack_speed_stack")
	player.get_stats().attack_speed_bonus = old_attack_speed
	player.set("talent_wizard_chain_lightning_attack_speed_stack_enabled", false)
	for enemy in enemies:
		enemy.queue_free()


func _test_fireball_explosion_chain_lightning_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"flame_right_13")
	_assert(unlocked, "Wizard right thirteenth Fireball explosion Chain Lightning talent unlocks")

	var fireball := _make_test_fireball(player)
	fireball.global_position = Vector2(12000.0, 12000.0)

	var chain_target := DamageProbeEnemy.new()
	chain_target.add_to_group("enemy")
	chain_target.global_position = fireball.global_position + Vector2.RIGHT * 80.0
	scene.add_child(chain_target)

	fireball.explode()
	_assert(chain_target.last_damage > 0.0, "Wizard right thirteenth talent triggers Chain Lightning when Fireballs explode")

	player.set("talent_wizard_fireball_explosion_chain_lightning_enabled", false)
	chain_target.queue_free()


func _test_large_map_more_containers_talent() -> void:
	player.unspent_talent_points = 1
	var elite_spoils_unlocked := _unlock_talent_for_test(&"spark_4")
	_assert(elite_spoils_unlocked, "Wizard spark fourth elite container talent unlocks")
	_assert(is_equal_approx(player.get_combat_container_count_multiplier(), 2.0), "Wizard spark fourth talent increases combat container count by 100%")
	player.set("talent_wizard_double_containers_elite_break_enabled", false)

	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_5")
	_assert(unlocked, "Wizard right spark map and container talent unlocks")
	_assert(is_equal_approx(player.get_map_size_multiplier(), 1.3), "Wizard right spark talent increases map size by 30%")
	_assert(is_equal_approx(player.get_combat_container_count_multiplier(), 1.3), "Wizard right spark talent increases combat container count by 30%")


func _test_hovering_fireball_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_12")
	_assert(unlocked, "Wizard spark hovering Fireball talent unlocks")

	var target_position := player.global_position + Vector2(180.0, 40.0)
	var enemy := DamageProbeEnemy.new()
	enemy.add_to_group("enemy")
	enemy.global_position = target_position + Vector2.RIGHT * 120.0
	scene.add_child(enemy)

	_clear_fireballs()
	_clear_hovering_fireballs()
	var laser_count := _count_nodes_with_class("HolyFlameLaser")
	player.call("_launch_wizard_primary_attack_pattern", target_position, false)
	await process_frame
	var hovering_fireball := _find_node_with_class("HoveringFireball") as Node2D
	_assert(hovering_fireball != null, "Wizard spark twelfth talent summons a hovering Fireball")
	_assert(hovering_fireball != null and hovering_fireball.global_position.is_equal_approx(target_position), "Wizard spark twelfth talent summons at the mouse position")
	_assert(_count_nodes_with_class("FireballProjectile") == 0, "Wizard spark twelfth talent replaces the left-click projectile Fireball")
	_assert(_count_nodes_with_class("HolyFlameLaser") > laser_count, "Wizard spark twelfth hovering Fireball fires a Fire Laser")

	for _index in range(12):
		player.call("_launch_wizard_primary_attack_pattern", target_position, false)
	await process_frame
	_assert(_count_nodes_with_class("HoveringFireball") == 10, "Wizard spark twelfth talent caps hovering Fireballs at 10")

	_clear_hovering_fireballs()
	await process_frame
	player.call("_launch_wizard_primary_attack_pattern", target_position, true)
	await process_frame
	var fire_essence_hovering_fireballs := _collect_hovering_fireballs()
	_assert(fire_essence_hovering_fireballs.size() == 4, "Wizard spark twelfth talent converts Fire Essence into four hovering Fireballs")
	_assert(_hovering_fireballs_do_not_overlap(fire_essence_hovering_fireballs), "Wizard spark twelfth Fire Essence hovering Fireballs do not overlap")

	_clear_hovering_fireballs()
	await process_frame
	player.max_hp = 200.0
	player.get_stats().max_hp = 200
	player.set("talent_wizard_max_hp_primary_echo_enabled", true)
	player.call("_launch_wizard_primary_attack_pattern", target_position, false)
	await process_frame
	var echo_hovering_fireballs := _collect_hovering_fireballs()
	_assert(echo_hovering_fireballs.size() == 3, "Wizard spark twelfth talent converts Vital Echo into extra hovering Fireballs")
	_assert(_hovering_fireballs_do_not_overlap(echo_hovering_fireballs), "Wizard spark twelfth Vital Echo hovering Fireballs do not overlap")

	_clear_hovering_fireballs()
	await process_frame
	player.call("_launch_wizard_primary_attack_pattern", target_position, true)
	await process_frame
	var fire_essence_echo_hovering_fireballs := _collect_hovering_fireballs()
	_assert(fire_essence_echo_hovering_fireballs.size() == 10, "Wizard spark twelfth Fire Essence and Vital Echo respect the 10 hovering Fireball cap")
	_assert(_hovering_fireballs_do_not_overlap(fire_essence_echo_hovering_fireballs), "Wizard spark twelfth capped Fire Essence Echo hovering Fireballs do not overlap")

	player.max_hp = 100.0
	player.get_stats().max_hp = 100
	player.set("talent_wizard_max_hp_primary_echo_enabled", false)
	_clear_hovering_fireballs()
	player.set("talent_wizard_hovering_fireball_enabled", false)
	enemy.queue_free()


func _test_stationary_primary_fireball_radius_charge_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_9")
	_assert(unlocked, "Wizard spark ninth stationary Fireball charge talent unlocks")

	player.set("talent_wizard_hovering_fireball_enabled", false)
	player.set("talent_wizard_fireball_radius_bonus_enabled", false)
	player.set("talent_wizard_fireball_radius_per_atk_enabled", false)
	player.set("talent_wizard_primary_extra_fireball_enabled", false)
	player.set("talent_wizard_move_speed_extra_fireballs_enabled", false)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)
	player.set("wizard_stationary_primary_fireball_charge_time", 0.0)
	player.set("state", 0)
	player.velocity = Vector2.ZERO

	player.wizard_runtime.update_stationary_primary_fireball_charge(player, 1.0)
	_assert(is_equal_approx(player.wizard_runtime.consume_stationary_primary_fireball_radius_multiplier(), 1.5), "Wizard spark ninth talent gains 10% Fireball radius every 0.2s while stationary")

	player.wizard_runtime.update_stationary_primary_fireball_charge(player, 3.0)
	_assert(is_equal_approx(player.wizard_runtime.consume_stationary_primary_fireball_radius_multiplier(), 2.0), "Wizard spark ninth talent caps Fireball radius charge at 100%")

	player.set("wizard_stationary_primary_fireball_charge_time", 1.0)
	player.velocity = Vector2.RIGHT * 8.0
	player.wizard_runtime.update_stationary_primary_fireball_charge(player, 0.1)
	_assert(is_equal_approx(float(player.get("wizard_stationary_primary_fireball_charge_time")), 0.0), "Wizard spark ninth talent resets charge when moving")
	player.velocity = Vector2.ZERO

	player.set("wizard_stationary_primary_fireball_charge_time", 2.0)
	var before_fireballs := _collect_fireball_projectiles(player.get_tree().current_scene).size()
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	var fireballs := _collect_fireball_projectiles(player.get_tree().current_scene)
	_assert(fireballs.size() == before_fireballs + 1, "Wizard spark ninth test launches one charged left-click Fireball")
	var charged_fireball := fireballs[fireballs.size() - 1] if fireballs.size() > before_fireballs else null
	_assert(charged_fireball != null and is_equal_approx(charged_fireball.explosion_radius, 160.0), "Wizard spark ninth talent applies charged radius to left-click Fireball")
	_assert(is_equal_approx(float(player.get("wizard_stationary_primary_fireball_charge_time")), 0.0), "Wizard spark ninth talent resets charge after left-click attack")
	player.set("talent_wizard_stationary_primary_fireball_radius_charge_enabled", false)


func _test_stationary_primary_fireball_damage_charge_talent() -> void:
	_clear_fireballs()
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_10")
	_assert(unlocked, "Wizard spark tenth stationary Fireball damage charge talent unlocks")

	player.set("talent_wizard_hovering_fireball_enabled", false)
	player.set("talent_wizard_stationary_primary_fireball_radius_charge_enabled", false)
	player.set("talent_wizard_fireball_damage_bonus_enabled", false)
	player.set("talent_wizard_primary_extra_fireball_enabled", false)
	player.set("talent_wizard_move_speed_extra_fireballs_enabled", false)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)
	player.set("wizard_stationary_primary_fireball_charge_time", 0.0)
	player.set("state", 0)
	player.velocity = Vector2.ZERO

	player.wizard_runtime.update_stationary_primary_fireball_charge(player, 1.0)
	_assert(is_equal_approx(player.wizard_runtime.get_stationary_primary_fireball_damage_multiplier(), 1.5), "Wizard spark tenth talent gains 10% Fireball damage every 0.2s while stationary")

	player.set("wizard_stationary_primary_fireball_charge_time", 0.0)
	player.wizard_runtime.update_stationary_primary_fireball_charge(player, 3.0)
	_assert(is_equal_approx(player.wizard_runtime.get_stationary_primary_fireball_damage_multiplier(), 1.5), "Wizard spark tenth talent caps Fireball damage charge at 50%")

	player.set("wizard_stationary_primary_fireball_charge_time", 1.0)
	player.velocity = Vector2.RIGHT * 8.0
	player.wizard_runtime.update_stationary_primary_fireball_charge(player, 0.1)
	_assert(is_equal_approx(float(player.get("wizard_stationary_primary_fireball_charge_time")), 0.0), "Wizard spark tenth talent resets charge when moving")
	player.velocity = Vector2.ZERO

	player.set("wizard_stationary_primary_fireball_charge_time", 1.0)
	var expected_damage := player.wizard_runtime.get_fireball_damage(player) * 1.5
	var before_fireballs := _collect_fireball_projectiles(player.get_tree().current_scene).size()
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	var fireballs := _collect_fireball_projectiles(player.get_tree().current_scene)
	_assert(fireballs.size() == before_fireballs + 1, "Wizard spark tenth test launches one charged left-click Fireball")
	var charged_fireball := fireballs[fireballs.size() - 1] if fireballs.size() > before_fireballs else null
	_assert(charged_fireball != null and is_equal_approx(charged_fireball.damage, expected_damage), "Wizard spark tenth talent applies charged damage to left-click Fireball")
	_assert(charged_fireball != null and is_equal_approx(charged_fireball.explosion_radius, 80.0), "Wizard spark tenth talent does not add radius without spark ninth talent")
	_assert(is_equal_approx(float(player.get("wizard_stationary_primary_fireball_charge_time")), 0.0), "Wizard spark tenth talent resets charge after left-click attack")
	player.set("talent_wizard_stationary_primary_fireball_damage_charge_enabled", false)


func _test_stationary_fireball_explosion_talent() -> void:
	_clear_fireballs()
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_11")
	_assert(unlocked, "Wizard spark eleventh stationary Fireball explosion talent unlocks")

	player.set("talent_wizard_fireball_damage_bonus_enabled", false)
	player.set("talent_wizard_fireball_radius_bonus_enabled", false)
	player.set("talent_wizard_fireball_radius_per_atk_enabled", false)
	player.set("talent_wizard_primary_fireball_laser_explosion_enabled", false)
	player.set("talent_wizard_fireball_max_hp_bonus_damage_enabled", false)
	player.set("talent_wizard_nearby_damage_focus_enabled", false)
	player.set("wizard_stationary_fireball_explosion_timer", 0.0)
	player.set("state", 0)
	player.velocity = Vector2.ZERO

	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position + Vector2.RIGHT * 20.0
	enemy.add_to_group("enemy")
	scene.add_child(enemy)

	player.wizard_runtime.update_stationary_fireball_explosion(player, 1.9)
	_assert(is_equal_approx(enemy.total_damage, 0.0), "Wizard spark eleventh talent waits 2s before triggering a Fireball explosion")
	player.wizard_runtime.update_stationary_fireball_explosion(player, 0.1)
	_assert(enemy.total_damage > 0.0, "Wizard spark eleventh talent triggers a Fireball explosion at the player after 2s stationary")

	enemy.last_damage = 0.0
	enemy.total_damage = 0.0
	player.set("wizard_stationary_fireball_explosion_timer", 1.9)
	player.velocity = Vector2.RIGHT * 8.0
	player.wizard_runtime.update_stationary_fireball_explosion(player, 0.2)
	_assert(is_equal_approx(float(player.get("wizard_stationary_fireball_explosion_timer")), 0.0), "Wizard spark eleventh talent resets its timer when moving")
	_assert(is_equal_approx(enemy.total_damage, 0.0), "Wizard spark eleventh talent does not explode while moving")
	player.velocity = Vector2.ZERO

	enemy.queue_free()
	player.set("talent_wizard_stationary_fireball_explosion_enabled", false)


func _test_dash_primary_fireball_stacks_talent() -> void:
	_clear_fireballs()
	_clear_hovering_fireballs()
	for hovering_fireball in get_nodes_in_group("wizard_hovering_fireball"):
		var hovering_node := hovering_fireball as Node
		if hovering_node != null and is_instance_valid(hovering_node):
			hovering_node.free()

	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_13")
	_assert(unlocked, "Wizard spark thirteenth dash Fireball stack talent unlocks")

	player.set("talent_wizard_primary_extra_fireball_enabled", false)
	player.set("talent_wizard_move_speed_extra_fireballs_enabled", false)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)
	player.set("talent_wizard_max_hp_primary_echo_enabled", false)
	player.set("talent_wizard_random_double_fireballs_enabled", false)
	player.set("talent_wizard_hovering_fireball_enabled", false)
	_assert(not bool(player.get("talent_wizard_hovering_fireball_enabled")), "Wizard spark thirteenth test disables hovering Fireball mode")
	player.set("wizard_dash_primary_fireball_stacks", 0)
	player.set("dash_cooldown_remaining", 0.0)
	player.set("state", 0)
	player.call("_try_start_dash")
	_assert(int(player.get("wizard_dash_primary_fireball_stacks")) == 1, "Wizard spark thirteenth talent gains 1 stack after dashing")
	player.set("state", 0)

	for _index in range(4):
		player.wizard_runtime.add_dash_primary_fireball_stack()
	_assert(int(player.get("wizard_dash_primary_fireball_stacks")) == 3, "Wizard spark thirteenth talent caps at 3 stacks")

	var node_root := player.get_tree().current_scene
	var before_fireballs := _count_fireball_projectiles(node_root)
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	_assert(_count_fireball_projectiles(node_root) == before_fireballs + 4, "Wizard spark thirteenth talent adds stacked left-click Fireballs")
	_assert(int(player.get("wizard_dash_primary_fireball_stacks")) == 0, "Wizard spark thirteenth talent resets stacks after left-click Fireball")

	player.set("wizard_dash_primary_fireball_stacks", 2)
	player.set("talent_wizard_hovering_fireball_enabled", true)
	var before_hovering_fireballs := _count_player_hovering_fireballs()
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	_assert(_count_player_hovering_fireballs() == before_hovering_fireballs + 3, "Wizard spark thirteenth talent adds stacks to hovering left-click Fireballs")
	_assert(int(player.get("wizard_dash_primary_fireball_stacks")) == 0, "Wizard spark thirteenth talent resets stacks after hovering left-click Fireball")
	_clear_hovering_fireballs()
	player.set("talent_wizard_hovering_fireball_enabled", false)
	player.set("talent_wizard_dash_primary_fireball_stacks_enabled", false)


func _test_fire_laser_hovering_fireball_chain_talent() -> void:
	_clear_hovering_fireballs()

	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_14")
	_assert(unlocked, "Wizard spark fourteenth hovering Fireball chain talent unlocks")
	_assert(bool(player.get("talent_wizard_fire_laser_hovering_fireball_chain_enabled")), "Wizard spark fourteenth hovering Fireball chain talent enables its effect")
	player.set("talent_wizard_fire_laser_chain_enabled", false)
	_assert(player.call("_get_wizard_fire_laser_chain_count") == 3, "Wizard spark fourteenth talent adds 3 Fire Laser chains")

	var test_origin := Vector2(20000.0, 20000.0)
	var source_enemy := DamageProbeEnemy.new()
	source_enemy.global_position = test_origin
	scene.add_child(source_enemy)
	source_enemy.add_to_group("enemy")

	var first_hovering_fireball := HOVERING_FIREBALL_SCRIPT.new() as HoveringFireball
	first_hovering_fireball.attack_speed_multiplier = 0.0
	first_hovering_fireball.setup(player, source_enemy.global_position + Vector2.RIGHT * 180.0)
	scene.add_child(first_hovering_fireball)
	first_hovering_fireball.add_to_group("wizard_hovering_fireball")

	var second_hovering_fireball := HOVERING_FIREBALL_SCRIPT.new() as HoveringFireball
	second_hovering_fireball.attack_speed_multiplier = 0.0
	second_hovering_fireball.setup(player, first_hovering_fireball.global_position + Vector2.RIGHT * 120.0)
	scene.add_child(second_hovering_fireball)
	second_hovering_fireball.add_to_group("wizard_hovering_fireball")

	var target_enemy := DamageProbeEnemy.new()
	target_enemy.global_position = source_enemy.global_position + Vector2.RIGHT * 40.0
	scene.add_child(target_enemy)
	target_enemy.add_to_group("enemy")

	var laser_root := player.get_tree().current_scene
	var before_lasers := _collect_lasers(laser_root).size()
	player.wizard_runtime.spawn_fire_laser_chain_from_hit(player, source_enemy, 3, 240.0, [source_enemy], 1.0)
	_assert(_collect_lasers(laser_root).size() == before_lasers + 1, "Wizard spark fourteenth talent chains only to a hovering Fireball, not a nearby enemy")

	var first_chain_laser: HolyFlameLaser = null
	for laser in _collect_lasers(laser_root):
		first_chain_laser = laser
	var expected_first_direction := (first_hovering_fireball.global_position - source_enemy.global_position).normalized()
	_assert(first_chain_laser != null and first_chain_laser.damages_enemies, "Wizard spark fourteenth hovering Fireball chain remains a damaging Fire Laser")
	_assert(first_chain_laser != null and first_chain_laser.chain_remaining == 2, "Wizard spark fourteenth hovering Fireball chain consumes 1 chain")
	_assert(first_chain_laser != null and first_chain_laser.direction.is_equal_approx(expected_first_direction), "Wizard spark fourteenth talent targets the hovering Fireball instead of the enemy")

	if first_chain_laser != null:
		first_chain_laser.call("_damage_enemy", target_enemy)
	_assert(_collect_lasers(laser_root).size() == before_lasers + 2, "Wizard spark fourteenth chained Fire Laser continues to another hovering Fireball after hitting an enemy")
	var second_chain_laser: HolyFlameLaser = null
	for laser in _collect_lasers(laser_root):
		second_chain_laser = laser
	var expected_second_direction := (second_hovering_fireball.global_position - target_enemy.global_position).normalized()
	_assert(second_chain_laser != null and second_chain_laser.chain_remaining == 1, "Wizard spark fourteenth second hovering Fireball chain consumes another chain")
	_assert(second_chain_laser != null and second_chain_laser.direction.is_equal_approx(expected_second_direction), "Wizard spark fourteenth second chain targets another hovering Fireball")

	source_enemy.queue_free()
	target_enemy.queue_free()
	first_hovering_fireball.queue_free()
	second_hovering_fireball.queue_free()
	player.set("talent_wizard_fire_laser_hovering_fireball_chain_enabled", false)


func _test_fire_laser_skips_freed_chain_excludes() -> void:
	var freed_enemy := DamageProbeEnemy.new()
	freed_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	scene.add_child(freed_enemy)
	freed_enemy.add_to_group("enemy")
	freed_enemy.free()

	var laser_root := player.get_tree().current_scene
	var before_lasers := _collect_lasers(laser_root).size()
	player.wizard_runtime.spawn_fire_laser(player, player.global_position, Vector2.RIGHT, 0, [freed_enemy], true, 1.0)
	_assert(_collect_lasers(laser_root).size() == before_lasers + 1, "Wizard Fire Laser ignores freed chain exclude entries")


func _test_homing_fireball_talent() -> void:
	_clear_fireballs()
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_15")
	_assert(unlocked, "Wizard spark fifteenth homing Fireball talent unlocks")

	player.set("talent_wizard_fireball_damage_bonus_enabled", false)
	player.set("talent_wizard_fireball_max_hp_bonus_damage_enabled", false)
	player.set("talent_wizard_nearby_damage_focus_enabled", false)
	player.set("talent_wizard_random_double_fireballs_enabled", false)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)

	var target_enemy := DamageProbeEnemy.new()
	target_enemy.global_position = player.global_position + Vector2(0.0, -200.0)
	target_enemy.add_to_group("enemy")
	scene.add_child(target_enemy)
	var far_enemy := DamageProbeEnemy.new()
	far_enemy.global_position = player.global_position + Vector2.RIGHT * 600.0
	far_enemy.add_to_group("enemy")
	scene.add_child(far_enemy)

	player.call("_spawn_wizard_fireball", player.global_position, Vector2.RIGHT)
	await process_frame
	var fireballs := _collect_fireball_projectiles(player.get_tree().current_scene)
	var fireball := fireballs[fireballs.size() - 1] if not fireballs.is_empty() else null
	var base_damage := player.wizard_runtime.get_fireball_damage(player)
	_assert(fireball != null and fireball.homing_enabled, "Wizard spark fifteenth talent makes Fireballs home")
	_assert(fireball != null and is_equal_approx(fireball.damage, base_damage * 0.6), "Wizard spark fifteenth talent reduces Fireball explosion damage by 40%")
	_assert(fireball != null and is_equal_approx(fireball.impact_damage, base_damage * 0.6), "Wizard spark fifteenth talent keeps Fireball impact damage at 60% ATK")
	if fireball != null:
		fireball.call("_physics_process", 0.1)
		_assert(fireball.direction.y < 0.0, "Wizard spark fifteenth homing Fireball turns toward the nearest enemy")

	target_enemy.queue_free()
	far_enemy.queue_free()
	player.set("talent_wizard_homing_fireballs_enabled", false)


func _test_fireball_impact_poison_stun_talent() -> void:
	_clear_fireballs()
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_16")
	_assert(unlocked, "Wizard spark sixteenth Fireball impact status talent unlocks")

	player.set("talent_wizard_random_double_fireballs_enabled", false)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)

	player.call("_spawn_wizard_fireball", player.global_position, Vector2.RIGHT)
	var fireballs := _collect_fireball_projectiles(player.get_tree().current_scene)
	var fireball := fireballs[fireballs.size() - 1] if not fireballs.is_empty() else null
	_assert(fireball != null and is_equal_approx(fireball.impact_poison_chance, 0.3), "Wizard spark sixteenth talent gives Fireball hits 30% Poison chance")
	_assert(fireball != null and is_equal_approx(fireball.impact_stun_chance, 0.05), "Wizard spark sixteenth talent gives Fireball hits 5% Stun chance")

	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position
	enemy.add_to_group("enemy")
	scene.add_child(enemy)
	if fireball != null:
		fireball.impact_poison_chance = 1.0
		fireball.impact_stun_chance = 1.0
		fireball.call("_on_body_entered", enemy)
	_assert(enemy.poison_stacks == 1, "Wizard spark sixteenth Fireball hit can apply Poison")
	_assert(is_equal_approx(enemy.stun_time_left, 1.0), "Wizard spark sixteenth Fireball hit can apply Stun")

	enemy.queue_free()
	player.set("talent_wizard_fireball_impact_poison_stun_enabled", false)


func _test_fireball_impact_vulnerable_talent() -> void:
	_clear_fireballs()
	player.unspent_talent_points = 1
	var unlocked := _unlock_talent_for_test(&"spark_17")
	_assert(unlocked, "Wizard spark seventeenth Fireball impact Vulnerable talent unlocks")

	player.set("talent_wizard_random_double_fireballs_enabled", false)
	player.set("talent_wizard_legendary_extra_fireballs_enabled", false)

	player.call("_spawn_wizard_fireball", player.global_position, Vector2.RIGHT)
	var fireballs := _collect_fireball_projectiles(player.get_tree().current_scene)
	var fireball := fireballs[fireballs.size() - 1] if not fireballs.is_empty() else null
	_assert(fireball != null and fireball.impact_vulnerable_stacks == 1, "Wizard spark seventeenth talent makes Fireball hits apply 1 Vulnerable stack")

	var enemy := DamageProbeEnemy.new()
	enemy.global_position = player.global_position
	enemy.add_to_group("enemy")
	scene.add_child(enemy)
	if fireball != null:
		fireball.call("_on_body_entered", enemy)
	_assert(enemy.vulnerable_stacks == 1, "Wizard spark seventeenth Fireball hit applies Vulnerable")

	var base_enemy := EnemyBase.new()
	base_enemy.max_hp = 200.0
	scene.add_child(base_enemy)
	base_enemy.apply_vulnerable_stacks(2, player)
	var hp_before := base_enemy.hp
	base_enemy.take_damage(100.0, player, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(hp_before - base_enemy.hp, 110.0), "Vulnerable increases incoming damage by 5% per stack additively")

	enemy.queue_free()
	base_enemy.queue_free()
	player.set("talent_wizard_fireball_impact_vulnerable_enabled", false)


func _count_nodes_with_class(class_name_value: String) -> int:
	return _count_nodes_with_class_recursive(scene, class_name_value)


func _count_fireball_projectiles(node: Node) -> int:
	var count := 0
	var fireball := node as FireballProjectile
	if fireball != null:
		count += 1
	for child in node.get_children():
		count += _count_fireball_projectiles(child)
	return count


func _collect_fireball_projectiles(node: Node) -> Array[FireballProjectile]:
	var result: Array[FireballProjectile] = []
	var fireball := node as FireballProjectile
	if fireball != null:
		result.append(fireball)
	for child in node.get_children():
		result.append_array(_collect_fireball_projectiles(child))
	return result


func _count_player_hovering_fireballs() -> int:
	var count := 0
	for hovering_fireball in get_nodes_in_group("wizard_hovering_fireball"):
		var node := hovering_fireball as Node
		if node != null and is_instance_valid(node) and node.get("owner_player") == player:
			count += 1
	return count


func _find_node_with_class(class_name_value: String) -> Node:
	return _find_node_with_class_recursive(scene, class_name_value)


func _find_node_with_class_recursive(node: Node, class_name_value: String) -> Node:
	if _node_matches_class_name(node, class_name_value):
		return node
	for child in node.get_children():
		var found := _find_node_with_class_recursive(child, class_name_value)
		if found != null:
			return found
	return null


func _find_fireball_with_radius(radius: float) -> FireballProjectile:
	return _find_fireball_with_radius_recursive(scene, radius)


func _count_fireballs_with_radius(radius: float) -> int:
	return _collect_fireballs_with_radius(radius).size()


func _collect_fireballs_with_radius(radius: float) -> Array[FireballProjectile]:
	var result: Array[FireballProjectile] = []
	_collect_fireballs_with_radius_recursive(scene, radius, result)
	return result


func _find_fireball_with_allow_procs(allow_procs: bool) -> FireballProjectile:
	return _find_fireball_with_allow_procs_recursive(scene, allow_procs)


func _find_fireball_with_explode_callback() -> FireballProjectile:
	return _find_fireball_with_explode_callback_recursive(scene)


func _find_fireball_with_replacement_callback() -> FireballProjectile:
	return _find_fireball_with_replacement_callback_recursive(scene)


func _find_fireball_with_replacement_callback_recursive(node: Node) -> FireballProjectile:
	var fireball := node as FireballProjectile
	if fireball != null and fireball.explode_replacement_callback.is_valid():
		return fireball
	for child in node.get_children():
		var found := _find_fireball_with_replacement_callback_recursive(child)
		if found != null:
			return found
	return null


func _find_fireball_with_explode_callback_recursive(node: Node) -> FireballProjectile:
	var fireball := node as FireballProjectile
	if fireball != null and fireball.explode_callback.is_valid():
		return fireball
	for child in node.get_children():
		var found := _find_fireball_with_explode_callback_recursive(child)
		if found != null:
			return found
	return null


func _find_fireball_with_allow_procs_recursive(node: Node, allow_procs: bool) -> FireballProjectile:
	var fireball := node as FireballProjectile
	if fireball != null and fireball.allow_procs == allow_procs:
		return fireball
	for child in node.get_children():
		var found := _find_fireball_with_allow_procs_recursive(child, allow_procs)
		if found != null:
			return found
	return null


func _find_laser_with_length(length: float) -> HolyFlameLaser:
	return _find_laser_with_length_recursive(scene, length)


func _find_newest_laser() -> HolyFlameLaser:
	var newest: HolyFlameLaser = null
	for node in _collect_lasers(scene):
		newest = node
	return newest


func _collect_lasers(node: Node) -> Array[HolyFlameLaser]:
	var result: Array[HolyFlameLaser] = []
	var laser := node as HolyFlameLaser
	if laser != null:
		result.append(laser)
	for child in node.get_children():
		result.append_array(_collect_lasers(child))
	return result


func _find_laser_with_length_recursive(node: Node, length: float) -> HolyFlameLaser:
	var laser := node as HolyFlameLaser
	if laser != null and is_equal_approx(laser.length, length):
		return laser
	for child in node.get_children():
		var found := _find_laser_with_length_recursive(child, length)
		if found != null:
			return found
	return null


func _find_fireball_with_radius_recursive(node: Node, radius: float) -> FireballProjectile:
	var fireball := node as FireballProjectile
	if fireball != null and is_equal_approx(fireball.explosion_radius, radius):
		return fireball
	for child in node.get_children():
		var found := _find_fireball_with_radius_recursive(child, radius)
		if found != null:
			return found
	return null


func _collect_fireballs_with_radius_recursive(node: Node, radius: float, result: Array[FireballProjectile]) -> void:
	var fireball := node as FireballProjectile
	if fireball != null and is_equal_approx(fireball.explosion_radius, radius):
		result.append(fireball)
	for child in node.get_children():
		_collect_fireballs_with_radius_recursive(child, radius, result)


func _count_nodes_with_class_recursive(node: Node, class_name_value: String) -> int:
	var count := 0
	if _node_matches_class_name(node, class_name_value):
		count += 1
	for child in node.get_children():
		count += _count_nodes_with_class_recursive(child, class_name_value)
	return count


func _node_matches_class_name(node: Node, class_name_value: String) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	match class_name_value:
		"FireballProjectile":
			return node is FireballProjectile
		"HolyFlameLaser":
			return node is HolyFlameLaser
		"HoveringFireball":
			return node is HoveringFireball
		"FireEssencePickup":
			return node is FireEssencePickup
	return node.name == class_name_value or node.get_class() == class_name_value or node.is_class(class_name_value)


func _count_line_children(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is Line2D:
			count += 1
	return count


func _count_buttons(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is Button:
			count += 1
	return count


func _unlock_talent_for_test(node_id: StringName) -> bool:
	if player.unlocked_talents.has(node_id):
		return true

	var path := _find_talent_path_for_test(node_id)
	var added_prerequisites: Array[StringName] = []
	for prerequisite_id in path:
		if prerequisite_id == node_id:
			break
		if not player.unlocked_talents.has(prerequisite_id):
			player.unlocked_talents.append(prerequisite_id)
			added_prerequisites.append(prerequisite_id)
	if player.unspent_talent_points <= 0:
		player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(node_id)
	for prerequisite_id in added_prerequisites:
		player.unlocked_talents.erase(prerequisite_id)
	return unlocked


func _find_talent_path_for_test(target_id: StringName) -> Array[StringName]:
	var parents := {}
	var queue: Array[StringName] = []
	for start_id in WIZARD_TALENT_CATALOG.start_nodes():
		parents[start_id] = StringName()
		queue.append(start_id)

	while not queue.is_empty():
		var current_id: StringName = queue.pop_front()
		if current_id == target_id:
			break
		for connection in WIZARD_TALENT_CATALOG.connections():
			var next_id := StringName()
			if connection[0] == current_id:
				next_id = connection[1]
			elif connection[1] == current_id:
				next_id = connection[0]
			else:
				continue
			if parents.has(next_id):
				continue
			parents[next_id] = current_id
			queue.append(next_id)

	if not parents.has(target_id):
		return [target_id]

	var path: Array[StringName] = []
	var cursor := target_id
	while cursor != StringName():
		path.push_front(cursor)
		cursor = parents[cursor]
	return path


func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_assertions += 1
	else:
		failures.append(message)
		push_error("FAIL: %s" % message)


func _on_attack_started(_origin: Vector2, _direction: Vector2, attack_info: Dictionary) -> void:
	attack_started_count += 1
	last_attack_started_info = attack_info


func _on_hp_changed_for_rebirth_test(current_hp: int, _max_hp: int) -> void:
	if current_hp <= 0:
		saw_zero_hp_changed = true


func _make_test_item(item_id: StringName, rarity: StringName) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.id = item_id
	item.display_name = String(item_id)
	item.rarity = rarity
	return item


func _make_test_fireball(owner: Node) -> FireballProjectile:
	var fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	fireball.owner_spawn_modifiers_applied = true
	fireball.setup(owner, player.global_position, Vector2.RIGHT, 12.0, 80.0)
	scene.add_child(fireball)
	return fireball


func _clear_fireballs() -> void:
	_clear_fireballs_recursive(scene)


func _clear_hovering_fireballs() -> void:
	for hovering_fireball in get_nodes_in_group("wizard_hovering_fireball"):
		var node := hovering_fireball as Node
		if node != null:
			node.queue_free()


func _collect_hovering_fireballs() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for hovering_fireball in get_nodes_in_group("wizard_hovering_fireball"):
		var node := hovering_fireball as Node2D
		if node != null:
			result.append(node)
	return result


func _hovering_fireballs_do_not_overlap(hovering_fireballs: Array[Node2D]) -> bool:
	var minimum_distance := 36.0 if hovering_fireballs.size() <= 4 else 24.0
	for first_index in range(hovering_fireballs.size()):
		for second_index in range(first_index + 1, hovering_fireballs.size()):
			if hovering_fireballs[first_index].global_position.distance_to(hovering_fireballs[second_index].global_position) < minimum_distance:
				return false
	return true


func _clear_fireballs_recursive(node: Node) -> void:
	for child in node.get_children():
		var fireball := child as FireballProjectile
		if fireball != null:
			fireball.queue_free()
		else:
			_clear_fireballs_recursive(child)


class PoisonStackEnemy:
	extends Node

	var poison_stacks: int = 0
	var last_damage: float = 0.0

	func take_damage(amount: float, _source: Node = null, _attack_info: Dictionary = {}) -> float:
		last_damage = amount
		return amount

	func get_poison_stacks() -> int:
		return poison_stacks


class DamageProbeEnemy:
	extends Node2D

	var last_damage: float = 0.0
	var total_damage: float = 0.0
	var poison_stacks: int = 0
	var stun_time_left: float = 0.0
	var vulnerable_stacks: int = 0

	func take_damage(amount: float, _source: Node = null, _attack_info: Dictionary = {}) -> float:
		last_damage = amount
		total_damage += amount
		return amount

	func apply_poison_stacks(amount: int, _source_player: Node = null) -> void:
		poison_stacks += amount

	func apply_stun_duration(duration: float, _source_player: Node = null) -> void:
		stun_time_left = maxf(stun_time_left, duration)

	func apply_vulnerable_stacks(amount: int, _source_player: Node = null) -> void:
		vulnerable_stacks += amount


class EliteDamageProbeEnemy:
	extends EnemyBase

	var last_damage: float = 0.0

	func _init() -> void:
		is_elite = true
		max_hp = 1000.0
		hp = max_hp

	func take_damage(amount: float, _source: Node = null, _attack_info: Dictionary = {}) -> float:
		last_damage = amount
		return amount


class PoisonProbeEnemy:
	extends Node2D

	var poison_stacks: int = 0

	func apply_poison_stacks(amount: int, _source_player: Node = null) -> void:
		poison_stacks += amount

	func get_poison_stacks() -> int:
		return poison_stacks


func _finish() -> void:
	if failures.is_empty():
		print("WizardCharacterTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("WizardCharacterTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
