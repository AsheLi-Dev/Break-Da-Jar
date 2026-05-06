extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const TALENT_CATALOG := preload("res://scripts/player/PlayerTalentCatalog.gd")

var failures: Array[String] = []
var passed_assertions: int = 0
var player: Player


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("TalentCatalogContractTest: starting")
	await process_frame

	player = PLAYER_SCENE.instantiate() as Player
	_assert(player != null, "Player scene instantiates for facade checks")
	if player != null:
		_test_catalog_contract()
		_test_player_facade()
		_test_unlock_contract()
		player.free()
		player = null

	_finish()


func _test_catalog_contract() -> void:
	var ids: Array[StringName] = TALENT_CATALOG.node_ids()
	_assert(not ids.is_empty(), "Talent catalog exposes node ids")

	var seen_ids: Dictionary = {}
	for id in ids:
		_assert(not seen_ids.has(id), "Talent id is unique: %s" % id)
		seen_ids[id] = true

		var definition: Dictionary = TALENT_CATALOG.definition(id)
		var coord: Vector2i = TALENT_CATALOG.grid_position(id)
		_assert(not definition.is_empty(), "Talent definition exists: %s" % id)
		_assert(TALENT_CATALOG.is_coord_valid(coord), "Talent grid position is valid: %s" % id)
		_assert(TALENT_CATALOG.node_id(coord) == id, "Talent id round-trips through grid position: %s" % id)
		_assert(not TALENT_CATALOG.display_name(id).strip_edges().is_empty(), "Talent display name is set: %s" % id)
		_assert(not TALENT_CATALOG.description(id).strip_edges().is_empty(), "Talent description is set: %s" % id)
		_assert(definition.has("stat") or definition.has("effect"), "Talent has stat or effect payload: %s" % id)

	_assert(TALENT_CATALOG.is_start_coord(Vector2i(2, 0)), "Left start talent coordinate is recognized")
	_assert(TALENT_CATALOG.is_start_coord(Vector2i(3, 0)), "Right start talent coordinate is recognized")

	for connection in TALENT_CATALOG.connections():
		_assert(connection is Array and connection.size() == 2, "Talent connection has two endpoints")
		if not (connection is Array and connection.size() == 2):
			continue

		var from_id: StringName = connection[0]
		var to_id: StringName = connection[1]
		_assert(seen_ids.has(from_id), "Talent connection from endpoint exists: %s" % from_id)
		_assert(seen_ids.has(to_id), "Talent connection to endpoint exists: %s" % to_id)

		var from_coord: Vector2i = TALENT_CATALOG.grid_position(from_id)
		var to_coord: Vector2i = TALENT_CATALOG.grid_position(to_id)
		_assert(TALENT_CATALOG.neighbor_coords(from_coord).has(to_coord), "Talent connection endpoints are neighbors: %s -> %s" % [from_id, to_id])


func _test_player_facade() -> void:
	var ids: Array[StringName] = TALENT_CATALOG.node_ids()
	_assert(player.get_talent_node_ids() == ids, "Player facade returns catalog node ids")
	_assert(player.get_talent_connections() == TALENT_CATALOG.connections(), "Player facade returns catalog connections")

	for id in ids:
		_assert(player.get_talent_node_grid_position(id) == TALENT_CATALOG.grid_position(id), "Player facade grid position matches catalog: %s" % id)
		_assert(player.get_talent_display_name(id) == TALENT_CATALOG.display_name(id), "Player facade display name matches catalog: %s" % id)
		_assert(player.get_talent_description(id) == TALENT_CATALOG.description(id), "Player facade description matches catalog: %s" % id)


func _test_unlock_contract() -> void:
	player.unlocked_talents.clear()
	player.unspent_talent_points = 1

	_assert(player.can_unlock_talent(&"talent_2_0"), "Start talent can unlock with one point")
	_assert(not player.can_unlock_talent(&"talent_2_1"), "Non-start talent cannot unlock without unlocked neighbor")

	player.unlocked_talents.append(&"talent_2_0")
	_assert(player.can_unlock_talent(&"talent_2_1"), "Adjacent talent can unlock after neighbor is unlocked")

	player.unlocked_talents.clear()
	player.unspent_talent_points = 0
	_assert(not player.can_unlock_talent(&"talent_2_0"), "Talent cannot unlock without points")


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
		print("TalentCatalogContractTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("TalentCatalogContractTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
