extends SceneTree

const BATTLE_SCENE: PackedScene = preload("res://battlescene.tscn")
const ELITE_BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/EliteBrute.tscn")

var failures: Array[String] = []
var battle_scene: Node
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("AltarAffixTest: starting")
	await process_frame

	_spawn_main_scene()
	await process_frame

	_test_elite_affix_application()
	_test_altar_accepts_next_round_challenge()
	_test_altar_offer_changes_each_round()
	_test_upgrade_altar_consumes_common_for_rare()
	_test_gamble_altar_spends_gold()
	_test_blessing_altar_buys_blessing()
	_test_level_altar_buys_level()
	_test_healing_altar_restores_half_max_hp()
	_test_map_affix_modifiers()
	_test_altar_blessings()

	await _finish()


func _spawn_main_scene() -> void:
	battle_scene = BATTLE_SCENE.instantiate()
	_assert(battle_scene != null, "battlescene.tscn instantiates")
	if battle_scene == null:
		return
	root.add_child(battle_scene)
	current_scene = battle_scene
	player = battle_scene.get("player") as Player
	_assert(player != null, "BattleScene spawns Player")


func _test_elite_affix_application() -> void:
	if battle_scene == null:
		return

	var enemy_count_before: int = (battle_scene.get("enemies") as Array).size()
	battle_scene.call("_spawn_enemy", Vector2(960.0, 540.0), ELITE_BRUTE_SCENE)
	var enemies: Array = battle_scene.get("enemies")
	_assert(enemies.size() == enemy_count_before + 1, "Elite enemy spawn is tracked")
	var enemy := enemies[enemies.size() - 1] as EnemyBase
	_assert(enemy != null and enemy.is_elite, "Spawned test enemy is elite")
	_assert(enemy != null and enemy.elite_affix_id != &"", "Elite enemy receives an affix")
	_assert(enemy != null and enemy.elite_affix_label != null and enemy.elite_affix_label.visible, "Elite affix label is visible")


func _test_altar_accepts_next_round_challenge() -> void:
	if battle_scene == null:
		return

	battle_scene.call("_enter_shop_phase")
	var altar := battle_scene.get("altar_node") as Node2D
	_assert(altar != null and is_instance_valid(altar), "Shop phase spawns an altar")
	var offer: Dictionary = battle_scene.call("_roll_challenge_altar_offer")
	offer["type"] = 0
	battle_scene.set("altar_offer", offer)
	battle_scene.set("altar_accepted", false)
	var accepted := bool(battle_scene.call("_try_accept_altar_at_position", altar.global_position))
	_assert(accepted, "Clicking altar accepts the offer")
	_assert(not (battle_scene.get("pending_map_affix") as Dictionary).is_empty(), "Accepted altar stores pending map affix")
	_assert(not (battle_scene.get("pending_altar_blessing") as Dictionary).is_empty(), "Accepted altar stores pending blessing")
	_assert(not bool(battle_scene.call("_try_accept_altar_at_position", altar.global_position)), "Accepted altar cannot be accepted twice")


func _test_altar_offer_changes_each_round() -> void:
	if battle_scene == null:
		return

	battle_scene.set("last_altar_map_affix_id", &"")
	battle_scene.set("last_altar_blessing_id", &"")
	var first_offer: Dictionary = battle_scene.call("_roll_challenge_altar_offer")
	var first_map_id: StringName = first_offer.get("map_affix", {}).get("id", &"")
	var first_blessing_id: StringName = first_offer.get("blessing", {}).get("id", &"")
	var second_offer: Dictionary = battle_scene.call("_roll_challenge_altar_offer")
	var second_map_id: StringName = second_offer.get("map_affix", {}).get("id", &"")
	var second_blessing_id: StringName = second_offer.get("blessing", {}).get("id", &"")
	_assert(first_map_id != second_map_id, "Altar map modifier does not repeat immediately")
	_assert(first_blessing_id != second_blessing_id, "Altar blessing reward does not repeat immediately")


func _test_upgrade_altar_consumes_common_for_rare() -> void:
	if battle_scene == null or player == null:
		return

	var common_item := _get_random_item(&"common")
	_assert(common_item != null, "Test database has common items")
	if common_item == null:
		return
	player.add_item(common_item)
	var common_before := _get_inventory_rarity_count(&"common")
	var rare_before := _get_inventory_rarity_count(&"rare")
	battle_scene.call("_enter_shop_phase")
	var altar := battle_scene.get("altar_node") as Node2D
	battle_scene.set("altar_offer", {"type": 1, "gold_cost": 8})
	battle_scene.set("altar_accepted", false)
	battle_scene.set("gold", 8)
	var accepted := bool(battle_scene.call("_try_accept_altar_at_position", altar.global_position))
	_assert(accepted, "Upgrade altar accepts common item and gold")
	_assert(int(battle_scene.get("gold")) == 0, "Upgrade altar spends gold")
	_assert(_get_inventory_rarity_count(&"common") == common_before - 1, "Upgrade altar consumes one common item")
	_assert(_get_inventory_rarity_count(&"rare") == rare_before + 1, "Upgrade altar grants one rare item")


func _test_gamble_altar_spends_gold() -> void:
	if battle_scene == null:
		return

	battle_scene.call("_enter_shop_phase")
	var altar := battle_scene.get("altar_node") as Node2D
	battle_scene.set("altar_offer", {"type": 2, "gold_cost": 10})
	battle_scene.set("altar_accepted", false)
	battle_scene.set("gold", 10)
	var accepted := bool(battle_scene.call("_try_accept_altar_at_position", altar.global_position))
	var remaining_gold := int(battle_scene.get("gold"))
	_assert(accepted, "Gamble altar accepts gold")
	_assert(remaining_gold == 0 or remaining_gold == 20, "Gamble altar either loses cost or pays double cost")


func _test_blessing_altar_buys_blessing() -> void:
	if battle_scene == null or player == null:
		return

	battle_scene.call("_enter_shop_phase")
	var altar := battle_scene.get("altar_node") as Node2D
	battle_scene.set("altar_offer", {
		"type": 3,
		"gold_cost": 20,
		"blessing": {"id": &"move_speed", "name": "Wind Blessing", "description": "Move speed +20%."},
	})
	battle_scene.set("altar_accepted", false)
	battle_scene.set("gold", 20)
	var blessing_count_before := player.get_altar_blessing_count()
	var accepted := bool(battle_scene.call("_try_accept_altar_at_position", altar.global_position))
	_assert(accepted, "Blessing altar accepts gold")
	_assert(int(battle_scene.get("gold")) == 0, "Blessing altar spends gold")
	_assert(player.get_altar_blessing_count() == blessing_count_before + 1, "Blessing altar grants a blessing immediately")


func _test_level_altar_buys_level() -> void:
	if battle_scene == null or player == null:
		return

	battle_scene.call("_enter_shop_phase")
	var altar := battle_scene.get("altar_node") as Node2D
	battle_scene.set("altar_offer", {"type": 4, "gold_cost": 25})
	battle_scene.set("altar_accepted", false)
	battle_scene.set("gold", 25)
	var level_before := player.level
	var accepted := bool(battle_scene.call("_try_accept_altar_at_position", altar.global_position))
	_assert(accepted, "Level altar accepts gold")
	_assert(int(battle_scene.get("gold")) == 0, "Level altar spends gold")
	_assert(player.level == level_before + 1, "Level altar grants one level")


func _test_healing_altar_restores_half_max_hp() -> void:
	if battle_scene == null or player == null:
		return

	battle_scene.call("_enter_shop_phase")
	var altar := battle_scene.get("altar_node") as Node2D
	battle_scene.set("altar_offer", {"type": 5, "gold_cost": 12})
	battle_scene.set("altar_accepted", false)
	battle_scene.set("gold", 12)
	player.hp = 10.0
	player.max_hp = 100.0
	var accepted := bool(battle_scene.call("_try_accept_altar_at_position", altar.global_position))
	_assert(accepted, "Healing altar accepts gold")
	_assert(int(battle_scene.get("gold")) == 0, "Healing altar spends gold")
	_assert(is_equal_approx(player.hp, 60.0), "Healing altar restores 50% max HP")


func _test_map_affix_modifiers() -> void:
	if battle_scene == null:
		return

	battle_scene.set("active_map_affix", {"id": &"enemy_count", "name": "Swarming Horde", "spawn_multiplier": 1.3})
	_assert(int(battle_scene.call("_get_modified_enemy_spawn_count", 10)) == 13, "Enemy count map affix increases spawns by 30%")
	battle_scene.set("active_map_affix", {"id": &"enemy_health", "name": "Thick Horde", "health_multiplier": 1.2})
	battle_scene.set("current_round", 1)
	_assert(is_equal_approx(float(battle_scene.call("_get_round_enemy_max_hp_multiplier")), 1.2), "Enemy health map affix increases health by 20%")
	var enemy := EnemyBase.new()
	enemy.max_hp = 10.0
	enemy.move_speed = 100.0
	enemy.is_elite = false
	battle_scene.add_child(enemy)
	battle_scene.set("active_map_affix", {"id": &"enemy_speed", "name": "Ravenous Pace", "move_speed_multiplier": 1.3})
	battle_scene.call("_apply_current_map_affix_to_enemy", enemy)
	_assert(is_equal_approx(enemy.map_move_speed_multiplier, 1.3), "Enemy speed map affix applies to spawned enemies")
	enemy.queue_free()
	battle_scene.set("active_map_affix", {})


func _test_altar_blessings() -> void:
	if player == null or battle_scene == null:
		return

	var old_move_speed_bonus := player.stats.movement_speed_bonus
	player.add_altar_blessing(&"move_speed")
	_assert(player.has_altar_blessing(&"move_speed"), "Player records altar blessing")
	_assert(is_equal_approx(player.stats.movement_speed_bonus, old_move_speed_bonus + 0.2), "Move speed blessing applies stats")

	battle_scene.set("gold", 0)
	player.add_altar_blessing(&"kill_gold")
	for _index in range(10):
		var killed_enemy := Node2D.new()
		player.notify_enemy_killed(killed_enemy)
		killed_enemy.free()
	_assert(int(battle_scene.get("gold")) == 1, "Kill gold blessing grants gold every 10 kills")

	var old_item_count := player.get_altar_blessing_count()
	player.add_altar_blessing(&"round_common_item")
	_assert(player.get_altar_blessing_count() == old_item_count + 1, "Round common item blessing stacks as a blessing")
	battle_scene.call("_update_character_card")
	var blessings_label := battle_scene.get("character_card_blessings_label") as Label
	_assert(blessings_label != null and blessings_label.text.contains("Wind Blessing"), "Character card lists altar blessings")


func _get_random_item(rarity: StringName) -> ItemDefinition:
	var database := root.get_node_or_null("ItemDatabase")
	if database == null or not database.has_method("get_random_item"):
		return null
	return database.get_random_item(&"", rarity) as ItemDefinition


func _get_inventory_rarity_count(rarity: StringName) -> int:
	if player == null or player.inventory == null:
		return 0

	var total := 0
	for item_id in player.inventory.item_counts.keys():
		var item := player.inventory.item_definitions_by_id.get(item_id) as ItemDefinition
		if item != null and item.rarity == rarity:
			total += int(player.inventory.item_counts.get(item_id, 0))
	return total


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
		print("AltarAffixTest: PASS")
	else:
		exit_code = 1
		print("AltarAffixTest: FAIL (%d failures)" % failures.size())
		for failure in failures:
			print("- %s" % failure)

	await _cleanup_scene()
	quit(exit_code)


func _cleanup_scene() -> void:
	root.get_tree().paused = false
	current_scene = null
	player = null
	_cleanup_audio_players()
	if battle_scene != null and is_instance_valid(battle_scene):
		if battle_scene.get_parent() != null:
			battle_scene.get_parent().remove_child(battle_scene)
		battle_scene.free()
	battle_scene = null
	for _index in range(12):
		await process_frame


func _cleanup_audio_players() -> void:
	for child in root.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
			child.queue_free()
