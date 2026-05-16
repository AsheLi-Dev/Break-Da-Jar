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
	player.set("talent_wizard_large_map_more_containers_enabled", true)
	battle_scene.call("_refresh_play_area_from_player", true)
	var expanded_rect: Rect2 = battle_scene.call("_get_play_area_rect")
	_assert(expanded_rect.size.is_equal_approx(Vector2(1664, 1664)), "Wizard map size talent expands BattleScene play area by 30%")
	_assert(expanded_rect.get_center().is_equal_approx(Vector2(1248, 702)), "Wizard map size talent scales BattleScene play area center by 30%")
	_assert(int(battle_scene.call("_get_combat_container_count")) == 26, "Wizard map size talent increases scaled combat container count by 30%")
	_assert(player.movement_bounds.size.is_equal_approx(expanded_rect.size), "Wizard map size talent updates player movement bounds")
	player.set("talent_wizard_large_map_more_containers_enabled", false)
	battle_scene.call("_refresh_play_area_from_player", true)

	battle_scene.set("current_round", 10)
	battle_scene.call("_refresh_play_area_from_player", true)
	var round_ten_rect: Rect2 = battle_scene.call("_get_play_area_rect")
	_assert(round_ten_rect.size.is_equal_approx(Vector2(1472, 1472)), "Round 10 expands BattleScene play area by 15%")
	_assert(player.movement_bounds.size.is_equal_approx(round_ten_rect.size), "Round 10 updates player movement bounds")

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
	for round_index in range(1, 6):
		battle_scene.set("current_round", round_index)
		for _roll_index in range(10):
			_assert(int(battle_scene.call("_roll_combat_container_type")) == 0, "Rounds 1-5 only roll jars")
			_assert(int(battle_scene.call("_roll_small_combat_container_type")) == 0, "Rounds 1-5 fallback rolls only jars")
	battle_scene.set("current_round", 6)
	var round_six_type: int = battle_scene.call("_roll_combat_container_type")
	_assert(round_six_type == 0 or round_six_type == 1, "Rounds 6-10 only roll jars and barrels")
	seed(1)
	var saw_round_six_jar := false
	var saw_round_six_barrel := false
	for _roll_index in range(100):
		var rolled_type: int = battle_scene.call("_roll_combat_container_type")
		_assert(rolled_type == 0 or rolled_type == 1, "Rounds 6-10 never roll tombs")
		if rolled_type == 0:
			saw_round_six_jar = true
		elif rolled_type == 1:
			saw_round_six_barrel = true
	_assert(saw_round_six_jar and saw_round_six_barrel, "Rounds 6-10 can roll both jars and barrels")
	battle_scene.set("current_round", 1)


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

	if int(battle_scene.get("phase")) != 1:
		battle_scene.call("_enter_shop_phase")
	var shop_containers_value: Variant = battle_scene.get("shop_containers")
	var shop_data_value: Variant = battle_scene.get("shop_container_data")
	var shop_containers: Array = shop_containers_value if shop_containers_value is Array else []
	var shop_data: Dictionary = shop_data_value if shop_data_value is Dictionary else {}

	_assert(int(battle_scene.get("phase")) == 1, "Entering shop phase updates phase")
	_assert(shop_containers.size() >= 3, "Shop phase spawns shop jars")
	for container in shop_containers:
		if not is_instance_valid(container):
			_fail("Shop container remains valid")
			continue
		_assert(container.get_node_or_null("ShopLabel") != null, "Shop jar has price label")
		var data: Dictionary = shop_data.get(container, {})
		_assert(int(data.get("price", 0)) > 0, "Shop jar has positive price")

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
		var expected_price := int(battle_scene.call("_get_shop_price", category, 2)) * 2
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
	if battle_scene != null and is_instance_valid(battle_scene):
		if battle_scene.get_parent() != null:
			battle_scene.get_parent().remove_child(battle_scene)
		battle_scene.free()
		await process_frame
		await process_frame
	battle_scene = null
	item_database = null
	await create_timer(0.1).timeout
	await process_frame
