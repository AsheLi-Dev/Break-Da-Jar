extends SceneTree

var failures: Array[String] = []

const STORM_SHACKLE: ItemDefinition = preload("res://data/items/legendary/storm_shackle.tres")
const SLIDE_SHACKLE: ItemDefinition = preload("res://data/items/legendary/slide_shackle.tres")
const STUNNING_RUPTURE: ItemDefinition = preload("res://data/items/legendary/stunning_rupture.tres")
const CHAIN_LIGHTNING_EFFECT := preload("res://systems/items/effects/EventEffect.gd")


class DamageProbePlayer:
	extends CharacterBody2D

	var damage_taken: float = 0.0

	func _init() -> void:
		add_to_group("player")

	func take_damage(amount: float, _source: Node = null, _attack_info: Dictionary = {}) -> float:
		damage_taken += amount
		return amount


class ChainLightningProbePlayer:
	extends Node2D

	signal container_broken(container: Node, attack_info: Dictionary)

	var stats := StatsComponent.new()
	var inventory := InventoryComponent.new()
	var damage_dealt: float = 0.0

	func _ready() -> void:
		add_child(inventory)
		inventory.setup(self)

	func get_stats() -> StatsComponent:
		return stats

	func get_base_attack_damage() -> float:
		return 10.0

	func get_item_count(item_id: StringName) -> int:
		return inventory.get_item_count(item_id)

	func deal_player_damage_to_enemy(enemy: Node, raw_damage: float, attack_info: Dictionary = {}) -> float:
		damage_dealt += raw_damage
		if enemy.has_method("take_damage"):
			return enemy.take_damage(raw_damage, self, attack_info)
		return raw_damage


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("EnemyStunStatusTest: starting")
	await process_frame

	await _test_status_component_tracks_stun()
	await _test_stuns_are_independent_and_non_stacking()
	await _test_elite_stun_duration_is_halved()
	await _test_stunned_enemy_stops_moving()
	await _test_stun_cancels_melee_damage()
	await _test_stunned_burning_zombie_does_not_contact_damage()
	await _test_holy_retribution_applies_stun()
	await _test_storm_shackle_stacking()
	await _test_chain_lightning_applies_storm_shackle_stun()
	await _test_slide_shackle_stacking()
	await _test_slide_contact_applies_slide_shackle_stun()
	await _test_stunning_rupture_stuns_nearby_enemies()

	_finish()


func _test_status_component_tracks_stun() -> void:
	var enemy := EnemyBase.new()
	root.add_child(enemy)
	await process_frame

	enemy.apply_status_effect(&"stun")
	_assert(enemy.has_status(&"stun"), "Enemy reports active stun status")

	enemy.queue_free()
	await process_frame


func _test_stuns_are_independent_and_non_stacking() -> void:
	var enemy := EnemyBase.new()
	root.add_child(enemy)
	await process_frame

	enemy.apply_stun_duration(0.5)
	enemy.apply_stun_duration(0.2)
	_assert(is_equal_approx(enemy.get_stun_time_left(), 0.5), "Shorter stun does not reduce active longer stun")
	enemy.apply_stun_duration(0.8)
	_assert(is_equal_approx(enemy.get_stun_time_left(), 0.8), "Longer stun replaces active shorter stun")

	enemy.queue_free()
	await process_frame


func _test_elite_stun_duration_is_halved() -> void:
	var normal_enemy := EnemyBase.new()
	var elite_enemy := EnemyBase.new()
	elite_enemy.is_elite = true
	root.add_child(normal_enemy)
	root.add_child(elite_enemy)
	await process_frame

	normal_enemy.apply_stun_duration(1.0)
	elite_enemy.apply_stun_duration(1.0)
	_assert(is_equal_approx(normal_enemy.get_stun_time_left(), 1.0), "Normal enemy receives full stun duration")
	_assert(is_equal_approx(elite_enemy.get_stun_time_left(), 0.5), "Elite enemy receives half stun duration")

	normal_enemy.queue_free()
	elite_enemy.queue_free()
	await process_frame


func _test_stunned_enemy_stops_moving() -> void:
	var enemy := EnemyBase.new()
	var player := DamageProbePlayer.new()
	player.global_position = Vector2(100.0, 0.0)
	root.add_child(player)
	root.add_child(enemy)
	await process_frame

	enemy.apply_status_effect(&"stun")
	enemy._physics_process(0.1)
	_assert(enemy.velocity == Vector2.ZERO, "Stunned base enemy does not move")

	enemy.queue_free()
	player.queue_free()
	await process_frame


func _test_stunned_burning_zombie_does_not_contact_damage() -> void:
	var enemy := BurningZombie.new()
	var player := DamageProbePlayer.new()
	enemy.global_position = Vector2.ZERO
	player.global_position = Vector2(500.0, 0.0)
	root.add_child(player)
	root.add_child(enemy)
	await process_frame

	enemy.target = player
	enemy.apply_status_effect(&"stun")
	player.global_position = Vector2.ZERO
	enemy.call("_try_contact_damage")
	_assert(is_equal_approx(player.damage_taken, 0.0), "Stunned contact-damage enemy cannot deal contact damage")

	enemy.queue_free()
	player.queue_free()
	await process_frame


func _test_stun_cancels_melee_damage() -> void:
	var enemy := ZombieMelee.new()
	var player := DamageProbePlayer.new()
	root.add_child(player)
	root.add_child(enemy)
	await process_frame

	enemy.set("attack_phase", &"active")
	enemy.apply_status_effect(&"stun")
	enemy.call("_try_damage_player", player)
	_assert(is_equal_approx(player.damage_taken, 0.0), "Stunned melee enemy cannot deal active attack damage")
	_assert(StringName(enemy.get("attack_phase")) == &"idle", "Stun cancels active melee attack")

	enemy.queue_free()
	player.queue_free()
	await process_frame


func _test_holy_retribution_applies_stun() -> void:
	var player := Player.new()
	var enemy := EnemyBase.new()
	root.add_child(player)
	root.add_child(enemy)
	enemy.global_position = Vector2(20.0, 0.0)
	await process_frame

	player.call("_perform_scaled_shockwave_attack", Vector2.ZERO, 1.0, 50.0, 0.0)
	_assert(enemy.has_status(&"stun"), "Holy Retribution applies stun to hit enemies")
	_assert(is_equal_approx(enemy.get_stun_time_left(), 1.0), "Holy Retribution stun lasts 1 second")

	player.queue_free()
	enemy.queue_free()
	await process_frame


func _test_storm_shackle_stacking() -> void:
	var player := ChainLightningProbePlayer.new()
	root.add_child(player)
	await process_frame

	player.inventory.add_item(STORM_SHACKLE)
	_assert(is_equal_approx(player.stats.chain_lightning_stun_duration, 0.6), "Storm Shackle first copy grants 0.6s Chain Lightning stun")
	player.inventory.add_item(STORM_SHACKLE)
	_assert(is_equal_approx(player.stats.chain_lightning_stun_duration, 0.9), "Storm Shackle duplicate adds 0.3s Chain Lightning stun")

	player.queue_free()
	await process_frame


func _test_chain_lightning_applies_storm_shackle_stun() -> void:
	var player := ChainLightningProbePlayer.new()
	var enemy := EnemyBase.new()
	root.add_child(player)
	root.add_child(enemy)
	enemy.global_position = Vector2(40.0, 0.0)
	await process_frame

	player.stats.chain_lightning_stun_duration = 0.6
	var effect := CHAIN_LIGHTNING_EFFECT.new()
	effect.owner_player = player
	effect.call("_apply_chain_lightning_stun", enemy, player.stats)
	_assert(enemy.has_status(&"stun"), "Storm Shackle makes Chain Lightning apply stun")

	player.queue_free()
	enemy.queue_free()
	await process_frame


func _test_slide_shackle_stacking() -> void:
	var player := ChainLightningProbePlayer.new()
	root.add_child(player)
	await process_frame

	player.inventory.add_item(SLIDE_SHACKLE)
	_assert(is_equal_approx(player.stats.slide_contact_stun_duration, 0.5), "Slide Shackle first copy grants 0.5s slide contact stun")
	player.inventory.add_item(SLIDE_SHACKLE)
	_assert(is_equal_approx(player.stats.slide_contact_stun_duration, 0.7), "Slide Shackle duplicate adds 0.2s slide contact stun")

	player.queue_free()
	await process_frame


func _test_slide_contact_applies_slide_shackle_stun() -> void:
	var player := Player.new()
	var enemy := EnemyBase.new()
	root.add_child(player)
	root.add_child(enemy)
	enemy.global_position = Vector2(20.0, 0.0)
	await process_frame

	player.stats.slide_contact_stun_duration = 0.5
	player.call("_apply_slide_contact_stun")
	_assert(enemy.has_status(&"stun"), "Slide Shackle makes slide contact apply stun")

	player.queue_free()
	enemy.queue_free()
	await process_frame


func _test_stunning_rupture_stuns_nearby_enemies() -> void:
	var player := ChainLightningProbePlayer.new()
	var near_enemy := EnemyBase.new()
	var far_enemy := EnemyBase.new()
	root.add_child(player)
	root.add_child(near_enemy)
	root.add_child(far_enemy)
	near_enemy.global_position = Vector2(40.0, 0.0)
	far_enemy.global_position = Vector2(500.0, 0.0)
	await process_frame

	player.inventory.add_item(STUNNING_RUPTURE)
	player.inventory.add_item(STUNNING_RUPTURE)
	var effect := STUNNING_RUPTURE.effects[0].duplicate(true)
	effect.configure_instance(&"stunning_rupture", 0, 0)
	effect.owner_player = player
	effect.call("_apply_stun_near_position", Vector2.ZERO)
	_assert(near_enemy.has_status(&"stun"), "Stunning Rupture stuns nearby enemies")
	_assert(is_equal_approx(near_enemy.get_stun_time_left(), 1.5), "Stunning Rupture duplicate adds 0.5s stun")
	_assert(not far_enemy.has_status(&"stun"), "Stunning Rupture ignores enemies outside radius")

	player.queue_free()
	near_enemy.queue_free()
	far_enemy.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	var exit_code := 0
	if failures.is_empty():
		print("EnemyStunStatusTest: PASS")
	else:
		exit_code = 1
		print("EnemyStunStatusTest: FAIL (%d failures)" % failures.size())
		for failure in failures:
			print("- %s" % failure)

	quit(exit_code)
