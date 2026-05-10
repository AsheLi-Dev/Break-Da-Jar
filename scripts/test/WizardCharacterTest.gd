extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const WIZARD_TALENT_CATALOG := preload("res://scripts/player/WizardTalentCatalog.gd")
const WIZARD_TALENT_LAYOUT: PackedScene = preload("res://scenes/player/WizardTalentLayout.tscn")
const TALENT_TREE_UI := preload("res://systems/battle/TalentTreeUiController.gd")
const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")
const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")

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
	_test_kill_move_speed_burst_talent()
	_test_fire_surge_radial_fireballs_talent()
	_test_max_hp_primary_echo_talent()
	_test_move_speed_extra_fireballs_talent()
	_test_poisoned_death_fireball_talent()
	_test_rare_item_move_speed_talent()
	_test_fire_essence_explosion_scatter_talent()
	_test_guaranteed_legendary_shop_jar_talent()
	_test_natural_fireball_radius_talent()
	_test_legendary_extra_fireballs_talent()
	_test_natural_fireball_heal_talent()
	_test_damage_taken_natural_explode_fireballs_talent()
	_test_random_double_fireballs_talent()
	_test_rebirth_level_to_atk_talent()
	_test_primary_fireball_laser_explosion_talent()
	_test_fire_surge_laser_talent()
	_test_fire_laser_chain_talent()
	_test_fire_surge_attack_speed_talent()
	_test_attack_speed_laser_chain_talent()

	_finish()


func _test_wizard_definition() -> void:
	_assert(player.get("primary_ability") == &"wizard_fireball", "Wizard primary ability is fireball")
	_assert(player.get("secondary_ability") == &"wizard_fire_laser", "Wizard secondary ability is fire laser")
	_assert(player.get("utility_ability") == &"wizard_fire_surge", "Wizard utility ability is fire surge")
	_assert(player.get_talent_node_ids().size() == 52, "Wizard exposes 52 talent nodes")
	var definition := player.get("character_definition") as CharacterDefinition
	_assert(definition.get_active_frame(&"primary", 0) == 7, "Wizard primary active frame is assigned")
	_assert(definition.get_active_frame(&"secondary", 0) == 8, "Wizard secondary active frame is assigned")
	_assert(definition.get_active_frame(&"utility", 0) == 5, "Wizard utility active frame is assigned")
	_assert(definition.textures.get(&"slide_hold") == definition.textures.get(&"slide_start"), "Wizard slide hold freezes slide start sheet")
	for animation_name in [&"idle", &"run", &"attack", &"ability", &"pummel", &"slide_start", &"slide_hold", &"slide_end", &"damage", &"death"]:
		_assert(definition.get_texture(animation_name) != null, "Wizard texture loads: %s" % animation_name)


func _test_wizard_talent_catalog() -> void:
	var ids := WIZARD_TALENT_CATALOG.node_ids()
	_assert(ids.size() == 52, "Wizard catalog has 52 nodes")
	var start_nodes := WIZARD_TALENT_CATALOG.start_nodes()
	_assert(start_nodes.size() == 1 and start_nodes[0] == &"flame_bottom_5", "Wizard catalog has one start node at bottom 5")
	var layout := WIZARD_TALENT_LAYOUT.instantiate() as Node2D
	for id in ids:
		_assert(WIZARD_TALENT_CATALOG.position(id) != Vector2.ZERO, "Wizard node has position: %s" % id)
		var marker := layout.get_node_or_null(String(id)) as Node2D
		_assert(marker != null and WIZARD_TALENT_CATALOG.position(id).is_equal_approx(marker.position), "Wizard catalog reads layout marker: %s" % id)
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
	var unlocked := player.unlock_talent(&"flame_bottom_5")
	_assert(unlocked, "Wizard poison start talent unlocks")
	_assert(is_equal_approx(stats.poison_chance, before + 0.1), "Wizard poison start talent grants 10% poison chance")


func _test_slide_fireball_blast_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_bottom_4")
	_assert(unlocked, "Wizard slide fireball blast talent unlocks")
	player.call("_apply_slide_finished_talents")
	_assert(bool(player.get("next_wizard_slide_fireball_ready")), "Wizard slide fireball blast arms after slide")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	var fireball := _find_fireball_with_radius(320.0)
	_assert(fireball != null, "Wizard slide fireball blast increases explosion radius by 300%")
	_assert(fireball != null and is_equal_approx(fireball.lifetime, 0.15), "Wizard slide fireball blast reduces travel distance by 90%")
	_assert(not bool(player.get("next_wizard_slide_fireball_ready")), "Wizard slide fireball blast is consumed by left-click fireball")


func _test_poison_stack_damage_talent() -> void:
	var enemy := PoisonStackEnemy.new()
	enemy.poison_stacks = 4
	scene.add_child(enemy)
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_bottom_3")
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
	var unlocked := player.unlock_talent(&"flame_bottom_2")
	_assert(unlocked, "Wizard nearby enemy attack speed talent unlocks")
	player.call("_update_wizard_nearby_enemy_attack_speed")
	var expected_bonus := float(EFFECT_TARGETING.enemies_surrounding(player, player.global_position).size()) * 0.05
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, expected_bonus), "Wizard nearby enemy attack speed grants 5% per nearby enemy")


func _test_nearby_damage_focus_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_left_0")
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
	var unlocked := player.unlock_talent(&"flame_left_1")
	_assert(unlocked, "Wizard fire surge left-click blast talent unlocks")
	player.call("_start_fire_surge")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	var empowered_fireball := _find_fireball_with_radius(320.0)
	_assert(empowered_fireball != null, "Wizard fire surge left-click blast increases explosion radius by 300%")
	_assert(empowered_fireball != null and is_equal_approx(empowered_fireball.lifetime, 0.15), "Wizard fire surge left-click blast reduces travel distance by 90%")

	player.call("_update_fire_surge", 10.0)
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0, true)
	await process_frame
	var normal_fireball := _find_fireball_with_radius(80.0)
	_assert(normal_fireball != null, "Wizard fire surge left-click blast only applies during Fire Surge")


func _test_nearby_kill_gold_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_left_2")
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
	var unlocked := player.unlock_talent(&"flame_left_3")
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
	var unlocked := player.unlock_talent(&"flame_left_4")
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
	var unlocked := player.unlock_talent(&"flame_left_5")
	_assert(unlocked, "Wizard nearby poison aura talent unlocks")
	player.call("_update_wizard_nearby_poison_aura", 4.9)
	_assert(nearby_enemy.poison_stacks == 0, "Wizard nearby poison aura waits 5s before applying poison")
	player.call("_update_wizard_nearby_poison_aura", 0.1)
	_assert(nearby_enemy.poison_stacks == 1, "Wizard nearby poison aura applies 1 Poison stack every 5s")
	_assert(distant_enemy.poison_stacks == 0, "Wizard nearby poison aura ignores distant enemies")


func _test_poisoned_kill_gold_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_left_6")
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
	var unlocked := player.unlock_talent(&"flame_left_7")
	_assert(unlocked, "Wizard short laser double damage talent unlocks")

	player.set("pending_shockwave_target_position", player.global_position + Vector2.RIGHT * 200.0)
	player.call("_cast_wizard_fire_laser")
	await process_frame
	var laser := _find_laser_with_length(250.0)
	_assert(laser != null, "Wizard short laser talent reduces right-click range by 50%")
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
	var unlocked := player.unlock_talent(&"flame_left_8")
	_assert(unlocked, "Wizard nearby enemy elite damage talent unlocks")
	player.call("_update_wizard_nearby_enemy_elite_damage")
	var expected_bonus := float(EFFECT_TARGETING.enemies_surrounding(player, player.global_position).size()) * 0.1
	_assert(is_equal_approx(player.get_stats().elite_direct_damage_bonus, expected_bonus), "Wizard nearby enemy elite damage grants 10% per nearby enemy")


func _test_more_weaker_enemies_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_left_9")
	_assert(unlocked, "Wizard more weaker enemies talent unlocks")
	_assert(is_equal_approx(player.get_enemy_spawn_count_multiplier(), 2.0), "Wizard more weaker enemies doubles enemy count")
	_assert(is_equal_approx(player.get_enemy_max_hp_multiplier(), 0.7), "Wizard more weaker enemies reduces enemy max HP by 30%")


func _test_fire_essence_burst_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_bridge_center_0")
	_assert(unlocked, "Wizard fire essence burst talent unlocks")

	var before_essences := _count_nodes_with_class("FireEssencePickup")
	player.call("_update_wizard_fire_essence_spawner", 5.0)
	_assert(_count_nodes_with_class("FireEssencePickup") == before_essences + 1, "Wizard fire essence spawns every 5s")

	player.call("collect_fire_essence")
	_assert(int(player.get("wizard_fire_essence_charges")) > 0, "Wizard fire essence pickup grants a burst charge")
	var before_fireballs := _count_nodes_with_class("FireballProjectile")
	player.set("wizard_fire_essence_charges", 1)
	player.call("_launch_wizard_fire_essence_burst", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before_fireballs + 4, "Wizard fire essence attack fires the original Fireball plus three extra Fireballs")
	var fireball := _find_fireball_with_allow_procs(true)
	_assert(fireball != null, "Wizard fire essence burst Fireballs allow normal procs")


func _test_kill_move_speed_burst_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_0")
	_assert(unlocked, "Wizard kill move speed burst talent unlocks")

	var before_bonus := player.get_stats().movement_speed_bonus
	player.notify_enemy_killed(DamageProbeEnemy.new())
	var buff: Dictionary = player.get_temporary_buffs().buffs.get(&"wizard_kill_move_speed_burst", {})
	_assert(is_equal_approx(player.get_stats().movement_speed_bonus, before_bonus + 2.0), "Wizard kill move speed burst grants 200% movement speed")
	_assert(is_equal_approx(float(buff.get("time_left", 0.0)), 0.2), "Wizard kill move speed burst lasts 0.2s")
	_assert(int(buff.get("stacks", 0)) == 1, "Wizard kill move speed burst does not stack")


func _test_fire_surge_radial_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_1")
	_assert(unlocked, "Wizard fire surge radial Fireballs talent unlocks")

	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_start_fire_surge")
	player.call("_update_fire_surge", 5.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 8, "Wizard Fire Surge radial talent fires 8 Fireballs every 5s")


func _test_max_hp_primary_echo_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_2")
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


func _test_move_speed_extra_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_3")
	_assert(unlocked, "Wizard move speed extra Fireballs talent unlocks")

	player.move_speed = 200.0
	player.get_stats().base_move_speed = 200.0
	player.get_stats().movement_speed_bonus = 0.0
	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_primary_attack_pattern", player.global_position + Vector2.RIGHT * 200.0, false)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 3, "Wizard move speed extra Fireballs grants one extra Fireball per 100 movement speed without replacing the original")


func _test_poisoned_death_fireball_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_4")
	_assert(unlocked, "Wizard poisoned death Fireball talent unlocks")

	var before := _count_nodes_with_class("FireballProjectile")
	var poisoned_enemy := PoisonProbeEnemy.new()
	poisoned_enemy.poison_stacks = 1
	poisoned_enemy.global_position = player.global_position + Vector2.RIGHT * 140.0
	player.notify_enemy_killed(poisoned_enemy)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 1, "Wizard poisoned death Fireball triggers from poisoned enemy death")

	before = _count_nodes_with_class("FireballProjectile")
	var clean_enemy := PoisonProbeEnemy.new()
	clean_enemy.global_position = player.global_position + Vector2.RIGHT * 140.0
	player.notify_enemy_killed(clean_enemy)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before, "Wizard poisoned death Fireball ignores non-poisoned enemy death")


func _test_rare_item_move_speed_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_5")
	_assert(unlocked, "Wizard rare item move speed talent unlocks")

	var before_bonus := player.get_stats().bonus_move_speed_flat
	player.add_item(_make_test_item(&"wizard_rare_stride_a", &"rare"))
	player.add_item(_make_test_item(&"wizard_rare_stride_b", &"rare"))
	player.add_item(_make_test_item(&"wizard_common_stride", &"common"))
	_assert(is_equal_approx(player.get_stats().bonus_move_speed_flat, before_bonus + 20.0), "Wizard rare item move speed grants 10 move speed per rare item only")


func _test_fire_essence_explosion_scatter_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_6")
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
	var unlocked := player.unlock_talent(&"flame_center_12")
	_assert(unlocked, "Wizard random double Fireballs talent unlocks")

	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 6, "Wizard random double Fireballs talent doubles the Fireball total after legendary extra Fireballs")


func _test_guaranteed_legendary_shop_jar_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_7")
	_assert(unlocked, "Wizard guaranteed legendary shop jar talent unlocks")
	_assert(player.has_guaranteed_legendary_shop_jar(), "Wizard guaranteed legendary shop jar talent marks shops for a forced legendary jar")
	_assert(is_equal_approx(player.get_shop_tier_price_multiplier(2), 2.0), "Wizard guaranteed legendary shop jar talent doubles legendary jar prices")
	_assert(is_equal_approx(player.get_shop_tier_price_multiplier(1), 1.0), "Wizard guaranteed legendary shop jar talent does not change non-legendary jar prices")


func _test_natural_fireball_radius_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_8")
	_assert(unlocked, "Wizard natural Fireball radius talent unlocks")

	var natural_fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	natural_fireball.owner_spawn_modifiers_applied = true
	natural_fireball.setup(player, player.global_position, Vector2.RIGHT, 12.0, 80.0)
	scene.add_child(natural_fireball)
	natural_fireball.explode(true)
	_assert(is_equal_approx(natural_fireball.explosion_radius, 160.0), "Wizard natural Fireball radius talent doubles radius on natural explosion")

	var impact_fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	impact_fireball.owner_spawn_modifiers_applied = true
	impact_fireball.setup(player, player.global_position, Vector2.RIGHT, 12.0, 80.0)
	scene.add_child(impact_fireball)
	impact_fireball.explode(false)
	_assert(is_equal_approx(impact_fireball.explosion_radius, 80.0), "Wizard natural Fireball radius talent does not affect impact explosions")
	await process_frame


func _test_legendary_extra_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_9")
	_assert(unlocked, "Wizard legendary extra Fireballs talent unlocks")

	player.add_item(_make_test_item(&"wizard_legendary_embers_a", &"legendary"))
	player.add_item(_make_test_item(&"wizard_legendary_embers_b", &"legendary"))
	var before := _count_nodes_with_class("FireballProjectile")
	player.call("_launch_wizard_fireball", player.global_position + Vector2.RIGHT * 200.0)
	await process_frame
	_assert(_count_nodes_with_class("FireballProjectile") == before + 3, "Wizard legendary extra Fireballs adds one Fireball per legendary item")


func _test_natural_fireball_heal_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_10")
	_assert(unlocked, "Wizard natural Fireball heal talent unlocks")

	player.hp = 10.0
	player.max_hp = 20.0
	var natural_fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	natural_fireball.owner_spawn_modifiers_applied = true
	natural_fireball.setup(player, player.global_position, Vector2.RIGHT, 12.0, 80.0)
	scene.add_child(natural_fireball)
	natural_fireball.explode(true)
	_assert(is_equal_approx(player.hp, 11.0), "Wizard natural Fireball heal restores 1 HP on natural explosion")

	var impact_fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	impact_fireball.owner_spawn_modifiers_applied = true
	impact_fireball.setup(player, player.global_position, Vector2.RIGHT, 12.0, 80.0)
	scene.add_child(impact_fireball)
	impact_fireball.explode(false)
	_assert(is_equal_approx(player.hp, 11.0), "Wizard natural Fireball heal ignores impact explosions")
	await process_frame


func _test_damage_taken_natural_explode_fireballs_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_center_11")
	_assert(unlocked, "Wizard damage taken natural explode Fireballs talent unlocks")

	_clear_fireballs()
	await process_frame
	player.hp = 10.0
	player.max_hp = 20.0
	player.get_stats().dodge_chance_multiplier = 1.0
	player.get_stats().defense = 0
	player.get_stats().damage_reduction_bonus = 0.0
	var first_fireball := _make_test_fireball(player)
	var second_fireball := _make_test_fireball(player)
	var other_owner := Node2D.new()
	scene.add_child(other_owner)
	var other_fireball := _make_test_fireball(other_owner)

	player.take_damage(4.0)
	_assert(first_fireball.exploded and second_fireball.exploded, "Wizard damage taken talent naturally explodes player-owned Fireballs")
	_assert(not other_fireball.exploded, "Wizard damage taken talent ignores Fireballs not owned by the player")
	_assert(is_equal_approx(player.hp, 8.0), "Wizard damage taken natural explosions trigger natural Fireball heal")
	await process_frame


func _test_rebirth_level_to_atk_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_left_10")
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
	_assert(player.unlock_talent(&"flame_bottom_5"), "Wizard right branch laser explosion path unlocks start")
	var unlocked := player.unlock_talent(&"flame_bottom_6")
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
	var unlocked := player.unlock_talent(&"flame_bottom_7")
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
	var unlocked := player.unlock_talent(&"flame_bottom_8")
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
	var unlocked := player.unlock_talent(&"flame_right_0")
	_assert(unlocked, "Wizard Fire Surge attack speed talent unlocks")

	var before_bonus := player.get_stats().attack_speed_bonus
	player.call("_start_fire_surge")
	player.call("_update_wizard_fire_surge_attack_speed_bonus")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, before_bonus + 0.5), "Wizard Fire Surge attack speed talent grants 50% attack speed during Fire Surge")
	player.set("fire_surge_remaining", 0.0)
	player.call("_update_wizard_fire_surge_attack_speed_bonus")
	_assert(is_equal_approx(player.get_stats().attack_speed_bonus, before_bonus), "Wizard Fire Surge attack speed talent clears after Fire Surge ends")


func _test_attack_speed_laser_chain_talent() -> void:
	player.unspent_talent_points = 1
	var unlocked := player.unlock_talent(&"flame_right_1")
	_assert(unlocked, "Wizard attack speed Fire Laser chain talent unlocks")

	player.fire_rate = 1.0
	player.get_stats().attack_speed_bonus = 0.0
	player.call("_spawn_wizard_fire_laser", player.global_position, Vector2.RIGHT)
	await process_frame
	var laser := _find_newest_laser()
	_assert(laser != null and laser.chain_remaining == 2, "Wizard attack speed Fire Laser chain talent adds floor(attacks per second) chains")

	player.get_stats().attack_speed_bonus = 1.0
	player.call("_spawn_wizard_fire_laser", player.global_position, Vector2.RIGHT)
	await process_frame
	laser = _find_newest_laser()
	_assert(laser != null and laser.chain_remaining == 3, "Wizard attack speed Fire Laser chain talent scales with attack speed rounded down")


func _count_nodes_with_class(class_name_value: String) -> int:
	return _count_nodes_with_class_recursive(scene, class_name_value)


func _find_node_with_class(class_name_value: String) -> Node:
	return _find_node_with_class_recursive(scene, class_name_value)


func _find_node_with_class_recursive(node: Node, class_name_value: String) -> Node:
	if node.name == class_name_value or node.get_class() == class_name_value or node.is_class(class_name_value):
		return node
	for child in node.get_children():
		var found := _find_node_with_class_recursive(child, class_name_value)
		if found != null:
			return found
	return null


func _find_fireball_with_radius(radius: float) -> FireballProjectile:
	return _find_fireball_with_radius_recursive(scene, radius)


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


func _count_nodes_with_class_recursive(node: Node, class_name_value: String) -> int:
	var count := 0
	if node.name == class_name_value or node.get_class() == class_name_value or node.is_class(class_name_value):
		count += 1
	for child in node.get_children():
		count += _count_nodes_with_class_recursive(child, class_name_value)
	return count


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
