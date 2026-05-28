extends SceneTree

const BATTLE_SCENE: PackedScene = preload("res://battlescene.tscn")
const REQUIRED_ITEM_IDS: Array[StringName] = [
	&"auto_fireball",
	&"static_conduit",
	&"blood_claw_sigil",
	&"phase_aegis",
	&"dragonheart_aerie",
	&"round_start_turret_battery",
]

var failures: Array[String] = []
var battle_scene: Node
var player: Player
var item_database: Node


func _initialize() -> void:
	_run.call_deferred()


func _run():
	print("RefactorSmokeTest: starting")
	await process_frame

	item_database = root.get_node_or_null("ItemDatabase")
	_assert(item_database != null, "ItemDatabase autoload exists")

	_spawn_main_scene()
	await process_frame

	_test_main_scene_boot()
	_test_dynamic_play_area_talent()
	_test_dynamic_container_grid_expansion()
	_test_holy_strike_chain_storm_count()
	_test_thin_horde_nearby_damage()
	_test_wizard_container_break_elite_summon()
	_test_wizard_swift_flame_extra_gold_drop()
	_test_wizard_venom_burst_extra_gold_drop()
	_test_pause_toggle()
	await _test_combat_clear_waits_for_scene_enemies()
	_test_shop_phase()
	_test_talent_tree()
	_test_required_items_exist()
	await _test_runtime_items()

	await _finish()


func _spawn_main_scene() -> void:
	battle_scene = BATTLE_SCENE.instantiate()
	_assert(battle_scene != null, "battlescene.tscn instantiates")
	if battle_scene == null:
		return

	root.add_child(battle_scene)
	current_scene = battle_scene


func _test_main_scene_boot() -> void:
	if battle_scene == null:
		return

	player = battle_scene.get("player") as Player
	_assert(player != null, "BattleScene spawns Player")
	_assert(player != null and player.is_in_group("player"), "Player is in player group")
	_assert(battle_scene.process_mode != Node.PROCESS_MODE_ALWAYS, "BattleScene remains pausable")
	_assert(player != null and player.process_mode != Node.PROCESS_MODE_ALWAYS, "Player remains pausable")
	_assert(battle_scene.get("hud_label") != null, "BattleScene creates HUD label")
	_assert(battle_scene.get("camera") != null, "BattleScene creates player camera")

	var containers_value: Variant = battle_scene.get("containers")
	var containers: Array = containers_value if containers_value is Array else []
	_assert(containers.size() > 0, "Combat containers spawn")
	_assert(containers.size() == 20, "Round 1 starts with 50% combat containers")
	_test_container_hitboxes(containers)
	_assert(int(battle_scene.get("phase")) == 0, "Battle starts in combat phase")


func _test_container_hitboxes(containers: Array) -> void:
	var checked_types := {}
	for container in containers:
		if checked_types.has(container.container_type):
			continue
		checked_types[container.container_type] = true
		var collision := container.get_node_or_null("CollisionShape2D") as CollisionShape2D
		_assert(collision != null, "Container has collision shape")
		if collision == null:
			continue
		var circle := collision.shape as CircleShape2D
		_assert(circle != null, "Container hitbox is circular")
		if circle == null:
			continue
		var expected_radius: float = battle_scene.call("_get_container_collision_radius", int(container.container_type))
		var expected_offset: Vector2 = battle_scene.call("_get_container_collision_offset", int(container.container_type))
		_assert(is_equal_approx(circle.radius, expected_radius), "Container hitbox radius matches type")
		_assert(collision.position.is_equal_approx(expected_offset), "Container hitbox offset matches type")


func _test_dynamic_play_area_talent() -> void:
	if battle_scene == null or player == null:
		return
	battle_scene.set("current_round", 1)
	battle_scene.call("_refresh_play_area_from_player", true)
	var initial_rect: Rect2 = battle_scene.call("_get_play_area_rect")
	_assert(initial_rect.size.is_equal_approx(Vector2(1600, 1600)), "BattleScene starts at the round 10 play area size")

	player.set("talent_wizard_large_map_more_containers_enabled", true)
	battle_scene.call("_refresh_play_area_from_player", true)
	var expanded_rect: Rect2 = battle_scene.call("_get_play_area_rect")
	_assert(expanded_rect.size.is_equal_approx(Vector2(2080, 2080)), "Wizard map size talent expands fixed BattleScene play area by 30%")
	_assert(expanded_rect.get_center().is_equal_approx(Vector2(1560, 877.5)), "Wizard map size talent scales fixed BattleScene play area center by 30%")
	_assert(int(battle_scene.call("_get_combat_container_count")) == 26, "Wizard map size talent increases scaled combat container count by 30%")
	_assert(player.movement_bounds.size.is_equal_approx(expanded_rect.size), "Wizard map size talent updates player movement bounds")
	player.set("talent_wizard_large_map_more_containers_enabled", false)
	battle_scene.call("_refresh_play_area_from_player", true)

	battle_scene.set("current_round", 10)
	battle_scene.call("_refresh_play_area_from_player", true)
	var round_ten_rect: Rect2 = battle_scene.call("_get_play_area_rect")
	_assert(round_ten_rect.size.is_equal_approx(initial_rect.size), "Round 10 keeps the fixed BattleScene play area size")
	_assert(player.movement_bounds.size.is_equal_approx(round_ten_rect.size), "Round 10 keeps player movement bounds at the fixed size")

	battle_scene.set("current_round", 6)
	battle_scene.call("_refresh_play_area_from_player", true)
	_assert(int(battle_scene.call("_get_combat_container_count")) == 40, "Round 6 returns to normal combat container count")
	_assert(is_equal_approx(float(battle_scene.call("_get_round_enemy_max_hp_multiplier")), 1.1), "Round 6 adds 10% enemy max HP")
	battle_scene.set("current_round", 7)
	_assert(int(battle_scene.call("_get_combat_container_count")) == 44, "Round 7 adds 10% combat containers")
	battle_scene.set("current_round", 20)
	_assert(int(battle_scene.call("_get_combat_container_count")) == 96, "Round 20 adds 140% combat containers")
	_assert(is_equal_approx(float(battle_scene.call("_get_round_enemy_max_hp_multiplier")), 2.5), "Round 20 adds 150% enemy max HP")
	battle_scene.set("current_round", 5)
	_assert(is_equal_approx(float(battle_scene.call("_get_round_enemy_max_hp_multiplier")), 1.0), "Round 5 has normal enemy max HP")
	var early_rounds_only_roll_jars := true
	for round_index in range(1, 6):
		battle_scene.set("current_round", round_index)
		early_rounds_only_roll_jars = early_rounds_only_roll_jars and int(battle_scene.call("_roll_combat_container_type")) == 0
		early_rounds_only_roll_jars = early_rounds_only_roll_jars and int(battle_scene.call("_roll_small_combat_container_type")) == 0
	_assert(early_rounds_only_roll_jars, "Rounds 1-5 only roll jars")
	battle_scene.set("current_round", 6)
	var round_six_type: int = battle_scene.call("_roll_combat_container_type")
	_assert(round_six_type == 0 or round_six_type == 1, "Rounds 6-10 only roll jars and barrels")
	seed(1)
	var saw_round_six_jar := false
	var saw_round_six_barrel := false
	var round_six_rolled_only_small_containers := true
	for _roll_index in range(40):
		var rolled_type: int = battle_scene.call("_roll_combat_container_type")
		round_six_rolled_only_small_containers = round_six_rolled_only_small_containers and (rolled_type == 0 or rolled_type == 1)
		if rolled_type == 0:
			saw_round_six_jar = true
		elif rolled_type == 1:
			saw_round_six_barrel = true
	_assert(round_six_rolled_only_small_containers, "Rounds 6-10 never roll tombs")
	_assert(saw_round_six_jar and saw_round_six_barrel, "Rounds 6-10 can roll both jars and barrels")
	battle_scene.set("current_round", 1)


func _test_dynamic_container_grid_expansion() -> void:
	if battle_scene == null or player == null:
		return

	var base_bounds: Dictionary = battle_scene.call("_get_dynamic_container_grid_bounds", 20)
	_assert(int(base_bounds.get("min", -1)) == 3 and int(base_bounds.get("max", -1)) == 12, "Dynamic container grid keeps low counts in the original 10x10 area")
	var high_bounds: Dictionary = battle_scene.call("_get_dynamic_container_grid_bounds", 192)
	_assert(int(high_bounds.get("min", -1)) == 0 and int(high_bounds.get("max", -1)) == 15, "Dynamic container grid expands high counts to the hidden 16x16 cap")

	battle_scene.set("current_round", 9)
	player.set("talent_wizard_double_containers_elite_break_enabled", true)
	var target_count: int = battle_scene.call("_get_combat_container_count")
	var placements: Array = battle_scene.call("_roll_combat_container_placements")
	_assert(target_count == 104, "Wizard spark fourth round 9 target container count doubles to 104")
	_assert(placements.size() == target_count, "Dynamic container grid can place doubled round 9 containers without hitting the old 10x10 cap")

	player.set("talent_wizard_large_map_more_containers_enabled", true)
	battle_scene.set("current_round", 20)
	_assert(int(battle_scene.call("_get_combat_container_count")) <= 256, "Dynamic container grid applies a hidden 16x16 container count cap")
	player.set("talent_wizard_large_map_more_containers_enabled", false)
	player.set("talent_wizard_double_containers_elite_break_enabled", false)
	battle_scene.set("current_round", 1)


func _test_holy_strike_chain_storm_count() -> void:
	if battle_scene == null or player == null:
		return

	player.set("talent_holy_strike_chain_lightning_pack_enabled", true)
	var nearby_enemies: Array[Node2D] = []
	for index in range(10):
		var enemy := Node2D.new()
		enemy.add_to_group("enemy")
		enemy.global_position = player.global_position + Vector2.RIGHT.rotated(TAU * float(index) / 10.0) * 80.0
		battle_scene.add_child(enemy)
		nearby_enemies.append(enemy)
	_assert(int(player.call("_get_holy_strike_chain_storm_count")) == 2, "Chain Storm releases one Chain Lightning per 5 nearby enemies")

	for index in range(6):
		nearby_enemies[index].remove_from_group("enemy")
		nearby_enemies[index].queue_free()
	for index in range(6, nearby_enemies.size()):
		nearby_enemies[index].remove_from_group("enemy")
	_assert(int(player.call("_get_holy_strike_chain_storm_count")) == 0, "Chain Storm waits for 5 nearby enemies")
	player.set("talent_holy_strike_chain_lightning_pack_enabled", false)
	for enemy in nearby_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()


func _test_thin_horde_nearby_damage() -> void:
	if battle_scene == null or player == null:
		return

	player.set("talent_holy_strike_more_weaker_enemies_enabled", true)
	_assert(is_equal_approx(player.get_enemy_spawn_count_multiplier(), 1.0), "Thin Horde no longer increases enemy spawn count")
	_assert(is_equal_approx(player.get_enemy_max_hp_multiplier(), 1.0), "Thin Horde no longer reduces enemy max HP")

	var nearby_enemy := EnemyBase.new()
	nearby_enemy.max_hp = 1000.0
	nearby_enemy.hp = 1000.0
	nearby_enemy.global_position = player.global_position + Vector2.RIGHT * 80.0
	battle_scene.add_child(nearby_enemy)
	player.deal_player_damage_to_enemy(nearby_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(nearby_enemy.hp, 880.0), "Thin Horde makes nearby enemies take 20 percent more damage")

	var distant_enemy := EnemyBase.new()
	distant_enemy.max_hp = 1000.0
	distant_enemy.hp = 1000.0
	distant_enemy.global_position = player.global_position + Vector2.RIGHT * 999.0
	battle_scene.add_child(distant_enemy)
	player.deal_player_damage_to_enemy(distant_enemy, 100.0, {"source": "test", "direct": true, "allow_procs": false, "allow_crit": false})
	_assert(is_equal_approx(distant_enemy.hp, 900.0), "Thin Horde does not increase damage to distant enemies")

	player.set("talent_holy_strike_more_weaker_enemies_enabled", false)
	nearby_enemy.queue_free()
	distant_enemy.queue_free()


func _test_wizard_container_break_elite_summon() -> void:
	if battle_scene == null or player == null:
		return

	var container := BreakableContainer.new()
	container.global_position = player.global_position + Vector2(120.0, 0.0)
	battle_scene.add_child(container)
	player.set("talent_wizard_double_containers_elite_break_enabled", true)

	var enemies: Array = battle_scene.get("enemies")
	var before_count := enemies.size()
	var missed: bool = battle_scene.call("_try_trigger_wizard_container_break_elites", container, 0.5)
	_assert(not missed, "Wizard spark fourth elite summon waits for its 1 percent container break roll")
	_assert(enemies.size() == before_count, "Wizard spark fourth missed roll summons no elite enemies")

	var triggered: bool = battle_scene.call("_try_trigger_wizard_container_break_elites", container, 0.0)
	_assert(triggered, "Wizard spark fourth container break roll can summon elite enemies")
	_assert(enemies.size() == before_count + 2, "Wizard spark fourth container break summons 2 elite enemies")
	for index in range(before_count, enemies.size()):
		var enemy := enemies[index] as EnemyBase
		_assert(enemy != null and enemy.is_elite, "Wizard spark fourth summoned enemy is elite")
		if enemy != null:
			enemy.queue_free()
	enemies.resize(before_count)

	player.set("talent_wizard_double_containers_elite_break_enabled", false)
	container.queue_free()


func _test_wizard_swift_flame_extra_gold_drop() -> void:
	if battle_scene == null or player == null:
		return

	var enemy := EnemyBase.new()
	enemy.global_position = player.global_position + Vector2(160.0, 0.0)
	battle_scene.add_child(enemy)

	player.set("talent_wizard_swift_flame_extra_gold_enabled", false)
	var before_pickups := _collect_reward_pickups()
	var disabled: bool = battle_scene.call("_try_drop_wizard_swift_flame_extra_gold", enemy, 0.0)
	_assert(not disabled, "Wizard Swift Flame extra gold waits for its talent")
	_assert(_collect_reward_pickups().size() == before_pickups.size(), "Wizard Swift Flame disabled talent drops no extra gold")

	player.set("talent_wizard_swift_flame_extra_gold_enabled", true)
	var missed: bool = battle_scene.call("_try_drop_wizard_swift_flame_extra_gold", enemy, 0.5)
	_assert(not missed, "Wizard Swift Flame extra gold waits for its 10 percent enemy drop roll")
	_assert(_collect_reward_pickups().size() == before_pickups.size(), "Wizard Swift Flame missed roll drops no extra gold")

	var triggered: bool = battle_scene.call("_try_drop_wizard_swift_flame_extra_gold", enemy, 0.0)
	var after_pickups := _collect_reward_pickups()
	_assert(triggered, "Wizard Swift Flame enemy drop roll can drop extra gold")
	_assert(after_pickups.size() == before_pickups.size() + 1, "Wizard Swift Flame drops one extra pickup")
	var extra_pickup: RewardPickup = after_pickups[after_pickups.size() - 1] as RewardPickup if after_pickups.size() > before_pickups.size() else null
	_assert(extra_pickup != null and extra_pickup.kind == RewardPickup.KIND_GOLD and extra_pickup.amount == 1, "Wizard Swift Flame extra pickup is 1 gold")

	for index in range(before_pickups.size(), after_pickups.size()):
		var pickup := after_pickups[index] as Node
		if pickup != null:
			pickup.queue_free()
	player.set("talent_wizard_swift_flame_extra_gold_enabled", false)
	enemy.queue_free()


func _test_wizard_venom_burst_extra_gold_drop() -> void:
	if battle_scene == null or player == null:
		return

	var enemy := EnemyBase.new()
	enemy.global_position = player.global_position + Vector2(180.0, 0.0)
	battle_scene.add_child(enemy)
	enemy.apply_poison_stacks(1, player)

	player.set("talent_wizard_poisoned_death_extra_gold_enabled", false)
	var before_pickups := _collect_reward_pickups()
	var disabled: bool = battle_scene.call("_try_drop_wizard_poisoned_death_extra_gold", enemy)
	_assert(not disabled, "Wizard Venom Burst extra gold waits for its talent")
	_assert(_collect_reward_pickups().size() == before_pickups.size(), "Wizard Venom Burst disabled talent drops no extra gold")

	player.set("talent_wizard_poisoned_death_extra_gold_enabled", true)
	var clean_enemy := EnemyBase.new()
	clean_enemy.global_position = player.global_position + Vector2(200.0, 0.0)
	battle_scene.add_child(clean_enemy)
	var clean: bool = battle_scene.call("_try_drop_wizard_poisoned_death_extra_gold", clean_enemy)
	_assert(not clean, "Wizard Venom Burst extra gold waits for poisoned enemies")
	_assert(_collect_reward_pickups().size() == before_pickups.size(), "Wizard Venom Burst clean enemy drops no extra gold")

	var triggered: bool = battle_scene.call("_try_drop_wizard_poisoned_death_extra_gold", enemy)
	var after_pickups := _collect_reward_pickups()
	_assert(triggered, "Wizard Venom Burst poisoned enemy can drop extra gold")
	_assert(after_pickups.size() == before_pickups.size() + 1, "Wizard Venom Burst drops one extra pickup")
	var extra_pickup: RewardPickup = after_pickups[after_pickups.size() - 1] as RewardPickup if after_pickups.size() > before_pickups.size() else null
	_assert(extra_pickup != null and extra_pickup.kind == RewardPickup.KIND_GOLD and extra_pickup.amount == 1, "Wizard Venom Burst extra pickup is 1 gold")

	for index in range(before_pickups.size(), after_pickups.size()):
		var pickup := after_pickups[index] as Node
		if pickup != null:
			pickup.queue_free()
	player.set("talent_wizard_poisoned_death_extra_gold_enabled", false)
	enemy.queue_free()
	clean_enemy.queue_free()


func _test_pause_toggle() -> void:
	if battle_scene == null:
		return

	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true

	battle_scene.call("_unhandled_input", event)
	_assert(root.get_tree().paused, "Esc pauses BattleScene")
	var pause_overlay := battle_scene.get("pause_overlay") as Control
	_assert(pause_overlay != null and pause_overlay.visible, "Pause overlay becomes visible")
	var pause_input_controller := battle_scene.get("pause_input_controller") as Node
	_assert(pause_input_controller != null and pause_input_controller.process_mode == Node.PROCESS_MODE_ALWAYS, "Pause input controller keeps receiving Esc")

	pause_input_controller.call("_unhandled_input", event)
	_assert(not root.get_tree().paused, "Esc resumes BattleScene")
	_assert(pause_overlay != null and not pause_overlay.visible, "Pause overlay hides after resume")


func _test_combat_clear_waits_for_scene_enemies() -> void:
	if battle_scene == null:
		return

	var containers: Array = battle_scene.get("containers")
	for container in containers.duplicate():
		if is_instance_valid(container):
			container.queue_free()
	containers.clear()
	var enemies: Array = battle_scene.get("enemies")
	enemies.clear()
	var stray_enemy := Node2D.new()
	stray_enemy.name = "StrayEnemyForClearTest"
	stray_enemy.add_to_group("enemy")
	battle_scene.add_child(stray_enemy)
	battle_scene.call("_check_combat_clear")
	await process_frame
	_assert(int(battle_scene.get("phase")) == 0, "Combat clear waits for enemy nodes still in the scene")

	stray_enemy.queue_free()
	await process_frame
	battle_scene.call("_check_combat_clear")
	await process_frame
	_assert(int(battle_scene.get("phase")) == 1, "Combat clear proceeds after scene enemy nodes are gone")


func _test_shop_phase() -> void:
	if battle_scene == null:
		return

	var original_round := int(battle_scene.get("current_round"))
	_assert(int(battle_scene.call("_get_shop_price", 0, 0)) == 30, "Common brown shop jar base price is 30")
	_assert(int(battle_scene.call("_get_shop_price", 0, 1)) == 100, "Rare brown shop jar base price is 100")
	_assert(int(battle_scene.call("_get_shop_price", 0, 2)) == 300, "Legendary brown shop jar base price is 300")
	_assert(int(battle_scene.call("_get_shop_price", 1, 0)) == 36, "Colored common shop jar costs 20 percent more")
	_assert(int(battle_scene.call("_get_shop_price", 4, 2)) == 360, "White legendary shop jar costs 20 percent more")
	battle_scene.set("current_round", 5)
	_assert(int(battle_scene.call("_apply_shop_round_price_multiplier", 100)) == 140, "Shop jars cost 40 percent more after round 5")
	battle_scene.set("current_round", 10)
	_assert(int(battle_scene.call("_apply_shop_round_price_multiplier", 100)) == 200, "Shop jars cost 100 percent more after round 10")
	battle_scene.set("current_round", 15)
	_assert(int(battle_scene.call("_apply_shop_round_price_multiplier", 100)) == 250, "Shop jars cost 150 percent more after round 15")
	battle_scene.set("current_round", original_round)

	if int(battle_scene.get("phase")) != 1:
		battle_scene.call("_enter_shop_phase")
	var shop_containers_value: Variant = battle_scene.get("shop_containers")
	var shop_data_value: Variant = battle_scene.get("shop_container_data")
	var shop_containers: Array = shop_containers_value if shop_containers_value is Array else []
	var shop_data: Dictionary = shop_data_value if shop_data_value is Dictionary else {}

	_assert(int(battle_scene.get("phase")) == 1, "Entering shop phase updates phase")
	_assert(shop_containers.size() >= 3, "Shop phase spawns shop jars")
	var all_shop_containers_valid := true
	var all_shop_containers_have_price_labels := true
	var all_shop_container_prices_positive := true
	for container in shop_containers:
		if not is_instance_valid(container):
			all_shop_containers_valid = false
			continue
		all_shop_containers_have_price_labels = all_shop_containers_have_price_labels and container.get_node_or_null("ShopLabel") != null
		var data: Dictionary = shop_data.get(container, {})
		all_shop_container_prices_positive = all_shop_container_prices_positive and int(data.get("price", 0)) > 0
	_assert(all_shop_containers_valid, "Shop containers remain valid")
	_assert(all_shop_containers_have_price_labels, "Shop jars have price labels")
	_assert(all_shop_container_prices_positive, "Shop jar prices are positive")

	var first_shop_container := shop_containers[0] as BreakableContainer
	var first_shop_data: Dictionary = shop_data.get(first_shop_container, {})
	var first_shop_price := int(first_shop_data.get("price", 0))
	_assert(battle_scene.call("_get_shop_container_at_position", first_shop_container.global_position) == first_shop_container, "Shop jar can be selected by click position")

	var projectile := Projectile.new()
	projectile.damage = first_shop_container.max_hp
	projectile.target_group = &"enemy"
	battle_scene.call("_on_container_area_entered", projectile, first_shop_container)
	_assert(is_equal_approx(first_shop_container.hp, first_shop_container.max_hp), "Player attacks do not damage shop jars")
	projectile.free()

	battle_scene.set("gold", maxi(first_shop_price - 1, 0))
	var bought_without_gold := bool(battle_scene.call("_try_purchase_shop_container", first_shop_container))
	_assert(not bought_without_gold, "Shop jar purchase fails without enough gold")
	_assert(is_equal_approx(first_shop_container.hp, first_shop_container.max_hp), "Unaffordable shop jar stays intact")

	battle_scene.set("gold", first_shop_price)
	var bought_with_gold := bool(battle_scene.call("_try_purchase_shop_container", first_shop_container))
	_assert(bought_with_gold, "Shop jar purchase succeeds with enough gold")
	_assert(int(battle_scene.get("gold")) == 0, "Shop jar purchase spends its price")
	_assert(first_shop_container.is_breaking, "Purchased shop jar breaks immediately")

	player.set("talent_wizard_guaranteed_legendary_shop_jar_enabled", true)
	battle_scene.call("_spawn_shop_containers")
	shop_containers_value = battle_scene.get("shop_containers")
	shop_data_value = battle_scene.get("shop_container_data")
	shop_containers = shop_containers_value if shop_containers_value is Array else []
	shop_data = shop_data_value if shop_data_value is Dictionary else {}
	var saw_legendary := false
	for container in shop_containers:
		var data: Dictionary = shop_data.get(container, {})
		if int(data.get("tier", -1)) != 2:
			continue
		saw_legendary = true
		var category := int(data.get("category", 0))
		var expected_base_price := int(battle_scene.call("_apply_shop_round_price_multiplier", int(battle_scene.call("_get_shop_price", category, 2))))
		var expected_price := expected_base_price * 2
		_assert(int(data.get("price", 0)) == expected_price, "Wizard legendary shop talent doubles legendary jar price")
		break
	_assert(saw_legendary, "Wizard legendary shop talent guarantees a legendary jar")


func _test_talent_tree() -> void:
	if player == null or battle_scene == null:
		return

	player.unspent_talent_points = 1
	battle_scene.call("_show_talent_tree")
	var talent_tree := battle_scene.get("talent_tree_ui") as Node
	_assert(talent_tree != null, "Talent tree UI controller exists")
	_assert(talent_tree != null and bool(talent_tree.call("is_open")), "Talent tree UI opens")

	var unlock_id: StringName = player.get_talent_node_ids()[0]
	for node_id in player.get_talent_node_ids():
		if player.can_unlock_talent(node_id):
			unlock_id = node_id
			break

	battle_scene.call("_on_talent_button_pressed", unlock_id)
	_assert(player.unlocked_talents.has(unlock_id), "Talent unlock request unlocks talent")
	_assert(player.unspent_talent_points == 0, "Talent unlock consumes one point")


func _test_required_items_exist() -> void:
	if item_database == null:
		return

	for item_id in REQUIRED_ITEM_IDS:
		var item: ItemDefinition = item_database.get_item(item_id)
		_assert(item != null, "Required item exists: %s" % item_id)


func _test_runtime_items():
	if player == null or item_database == null:
		return

	player.setup_character(&"wizard")
	var runtime_item_ids: Array[StringName] = [
		&"auto_fireball",
		&"static_conduit",
		&"blood_claw_sigil",
		&"phase_aegis",
	]
	for item_id in runtime_item_ids:
		_give_item(item_id)

	await process_frame
	_assert(_count_player_runtime_effect_nodes() >= runtime_item_ids.size(), "Runtime item effects attach monitor nodes")

	_give_item(&"dragonheart_aerie")
	await process_frame
	_assert(_count_fire_dragons() >= 1, "Dragonheart Aerie summons a fire dragon")

	_give_item(&"round_start_turret_battery")
	player.emit_round_started(99)
	await process_frame
	_assert(_count_small_turrets() >= 2, "Round Start Turret Battery summons turrets")


func _give_item(item_id: StringName) -> void:
	var item: ItemDefinition = item_database.get_item(item_id)
	if item == null:
		_fail("Cannot give missing item: %s" % item_id)
		return

	player.add_item(item)
	_assert(player.get_item_count(item_id) > 0, "Player receives item: %s" % item_id)


func _count_player_runtime_effect_nodes() -> int:
	var count := 0
	for child in player.get_children():
		if child is ItemRuntimeEffectNode:
			count += 1
	return count


func _count_fire_dragons() -> int:
	if battle_scene == null:
		return 0
	return _count_fire_dragons_recursive(battle_scene)


func _count_fire_dragons_recursive(node: Node) -> int:
	var count := 1 if node is FireDragon else 0
	for child in node.get_children():
		count += _count_fire_dragons_recursive(child)
	return count


func _count_small_turrets() -> int:
	if battle_scene == null:
		return 0
	return _count_small_turrets_recursive(battle_scene)


func _count_small_turrets_recursive(node: Node) -> int:
	var count := 1 if node is SmallTurret else 0
	for child in node.get_children():
		count += _count_small_turrets_recursive(child)
	return count


func _collect_reward_pickups() -> Array[RewardPickup]:
	var result: Array[RewardPickup] = []
	if battle_scene != null:
		_collect_reward_pickups_recursive(battle_scene, result)
	return result


func _collect_reward_pickups_recursive(node: Node, result: Array[RewardPickup]) -> void:
	var pickup := node as RewardPickup
	if pickup != null:
		result.append(pickup)
	for child in node.get_children():
		_collect_reward_pickups_recursive(child, result)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)
	push_error("FAIL: %s" % message)


func _finish() -> void:
	var exit_code := 0
	if failures.is_empty():
		print("RefactorSmokeTest: PASS")
	else:
		exit_code = 1
		print("RefactorSmokeTest: FAIL (%d failures)" % failures.size())
		for failure in failures:
			print("- %s" % failure)

	await _cleanup_scene()
	quit(exit_code)


func _cleanup_scene() -> void:
	root.get_tree().paused = false
	current_scene = null
	player = null
	await create_timer(1.0).timeout
	if battle_scene != null and is_instance_valid(battle_scene):
		if battle_scene.get_parent() != null:
			battle_scene.get_parent().remove_child(battle_scene)
		battle_scene.free()
		await process_frame
		await process_frame
	battle_scene = null
	item_database = null
	for _index in range(12):
		await process_frame
