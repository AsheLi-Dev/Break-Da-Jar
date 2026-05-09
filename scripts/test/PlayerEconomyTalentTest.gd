extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")

class FakeBattleScene:
	extends Node2D

	var gold: int = 0

	func add_player_gold(amount: int, _reason: String = "") -> void:
		gold += amount


var failures: Array[String] = []
var passed_assertions: int = 0
var scene: FakeBattleScene
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("PlayerEconomyTalentTest: starting")
	await process_frame

	scene = FakeBattleScene.new()
	root.add_child(scene)
	current_scene = scene

	player = PLAYER_SCENE.instantiate() as Player
	scene.add_child(player)
	await process_frame

	if player != null:
		_test_level_up_gold()
		await _reset_player()
		_test_rich_double_xp()
		await _reset_player()
		_test_elite_kill_common_item()

	_finish()


func _reset_player() -> void:
	if player != null:
		player.queue_free()
	await process_frame
	scene.gold = 0
	player = PLAYER_SCENE.instantiate() as Player
	scene.add_child(player)
	await process_frame


func _test_level_up_gold() -> void:
	player.unspent_talent_points = 4
	_assert(player.unlock_talent(&"talent_4_0"), "Unlock first economy talent")
	_assert(player.unlock_talent(&"talent_4_1"), "Unlock second economy talent")
	_assert(player.unlock_talent(&"talent_4_2"), "Unlock third economy talent")
	_assert(player.unlock_talent(&"talent_4_3"), "Unlock level-up gold talent")

	player.gain_experience(player.get_required_exp_for_next_level())
	_assert(scene.gold == 10, "Level-up gold talent grants 10 gold")


func _test_rich_double_xp() -> void:
	player.unspent_talent_points = 6
	_assert(player.unlock_talent(&"talent_4_0"), "Unlock first economy talent for rich XP")
	_assert(player.unlock_talent(&"talent_4_1"), "Unlock second economy talent for rich XP")
	_assert(player.unlock_talent(&"talent_4_2"), "Unlock third economy talent for rich XP")
	_assert(player.unlock_talent(&"talent_4_3"), "Unlock fourth economy talent for rich XP")
	_assert(player.unlock_talent(&"talent_4_4"), "Unlock bridge talent for rich XP")
	_assert(player.unlock_talent(&"talent_5_4"), "Unlock rich double XP talent")

	scene.gold = 300
	player.gain_experience(4)
	_assert(player.experience == 8, "Rich double XP talent doubles XP at 300 gold")


func _test_elite_kill_common_item() -> void:
	var item_database := root.get_node_or_null("ItemDatabase")
	_assert(item_database != null, "ItemDatabase autoload exists")
	if item_database == null:
		return

	player.unspent_talent_points = 2
	_assert(player.unlock_talent(&"talent_4_0"), "Unlock first economy talent for elite reward")
	_assert(player.unlock_talent(&"talent_4_1"), "Unlock elite common item talent")

	var before_count := _get_total_item_count()
	var enemy := EnemyBase.new()
	enemy.is_elite = true
	player.notify_enemy_killed(enemy)
	enemy.free()

	_assert(_get_total_item_count() == before_count + 1, "Elite kill common item talent grants one item")


func _get_total_item_count() -> int:
	if player == null or player.inventory == null:
		return 0

	var total := 0
	for item_id in player.inventory.item_counts.keys():
		total += int(player.inventory.item_counts.get(item_id, 0))
	return total


func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_assertions += 1
	else:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)
	push_error("FAIL: %s" % message)


func _finish() -> void:
	if player != null:
		player.queue_free()
	if scene != null:
		scene.queue_free()

	if failures.is_empty():
		print("PlayerEconomyTalentTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("PlayerEconomyTalentTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
