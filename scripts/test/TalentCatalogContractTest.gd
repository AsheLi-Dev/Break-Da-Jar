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
	_assert(TALENT_CATALOG.is_start_coord(Vector2i(4, 0)), "Center start talent coordinate is recognized")
	_assert(TALENT_CATALOG.is_coord_valid(Vector2i(4, 3)), "Talent handle includes third column")
	_assert(TALENT_CATALOG.is_coord_valid(Vector2i(-2, 4)), "Talent hammer head includes expanded left edge column")
	_assert(TALENT_CATALOG.is_coord_valid(Vector2i(8, 7)), "Talent hammer head includes expanded right edge column")
	_assert(TALENT_CATALOG.is_coord_valid(Vector2i(3, 8)), "Talent hammer head includes expanded top row")
	_assert(not TALENT_CATALOG.is_coord_valid(Vector2i(1, 3)), "Talent handle rejects outside left column")
	_assert(not TALENT_CATALOG.is_coord_valid(Vector2i(5, 3)), "Talent handle rejects outside right column")
	_assert(not TALENT_CATALOG.is_coord_valid(Vector2i(-3, 4)), "Talent hammer head rejects outside expanded left column")
	_assert(not TALENT_CATALOG.is_coord_valid(Vector2i(9, 7)), "Talent hammer head rejects outside expanded right column")
	_assert(not TALENT_CATALOG.is_coord_valid(Vector2i(3, 9)), "Talent hammer head rejects above expanded top row")

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

	var connections := TALENT_CATALOG.connections()
	_assert(connections.has([&"talent_1_7", &"talent_1_8"]), "Spoiled Guard connects upward")
	_assert(connections.has([&"talent_3_7", &"talent_3_8"]), "Vital Spoils connects upward")
	_assert(connections.has([&"talent_5_7", &"talent_5_8"]), "Hearty Loot connects upward")
	_assert(not connections.has([&"talent_0_7", &"talent_1_7"]), "Zombie Sigil no longer connects to Spoiled Guard")
	_assert(not connections.has([&"talent_2_7", &"talent_3_7"]), "Swift Faith no longer connects to Vital Spoils")
	_assert(not connections.has([&"talent_4_7", &"talent_5_7"]), "Still Aegis no longer connects to Hearty Loot")
	_assert(not connections.has([&"talent_-1_4", &"talent_-1_5"]), "Cull Coin no longer connects to Cull Study")
	_assert(not connections.has([&"talent_-1_6", &"talent_-1_7"]), "Cull Spoils no longer connects to Cull Greed")
	_assert(connections.has([&"talent_-1_6", &"talent_-2_6"]), "Cull Spoils connects left")
	_assert(not connections.has([&"talent_-2_7", &"talent_-1_7"]), "Cull Greed no longer connects left")
	_assert(not connections.has([&"talent_7_4", &"talent_7_5"]), "Elite Study no longer connects downward")
	_assert(connections.has([&"talent_7_5", &"talent_8_5"]), "Elite Study connects right")
	_assert(not connections.has([&"talent_6_7", &"talent_7_7"]), "Blood Vow no longer connects to Elite Relic")
	_assert(not connections.has([&"talent_7_6", &"talent_7_7"]), "Elite Spoils no longer connects to Elite Relic")


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
