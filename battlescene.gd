extends Node2D

const SCREEN_SIZE := Vector2(1920, 1080)
const PLAY_AREA_SIZE := Vector2(1536, 1536)
const PLAY_AREA_CENTER := Vector2(960, 540)
const PLAY_AREA_RECT := Rect2(PLAY_AREA_CENTER - PLAY_AREA_SIZE * 0.5, PLAY_AREA_SIZE)
const CAMERA_VISIBLE_SIZE := Vector2(1600, 900)
const CAMERA_ZOOM := Vector2(SCREEN_SIZE.x / CAMERA_VISIBLE_SIZE.x, SCREEN_SIZE.y / CAMERA_VISIBLE_SIZE.y)
const PLAYER_POSITION := PLAY_AREA_CENTER + Vector2(-500, 0)
const ARENA_TILE_SIZE := Vector2i(32, 32)
const ARENA_TILE_SCALE := 2.0
const ARENA_GRID_SIZE := Vector2i(24, 24)
const ARENA_TILE_SOURCE_ID := 0
const CHARACTER_SPRITE_SCALE := Vector2(2.0, 2.0)
const MAX_ROUNDS := 10
const ROUND_CONTAINER_AUTO_BREAK_TIME := 30.0
const RANDOM_CONTAINER_BREAK_MIN_TIME := 2.0
const RANDOM_CONTAINER_BREAK_MAX_TIME := 3.0
const PLAYER_CONTAINER_GOLD_DROP_CHANCE := 0.5
const PLAYER_CONTAINER_GOLD_DROP_MIN := 1
const PLAYER_CONTAINER_GOLD_DROP_MAX := 3

const CONTAINER_COUNT := 40
const GRID_SIZE := 16
const CONTAINER_GRID_MIN_INDEX := 3
const CONTAINER_GRID_MAX_INDEX := 12
const CONTAINER_COLLISION_RADIUS := 18.0

const SHOP_CONTAINER_COUNT := 6
const SHOP_CONTAINER_COLUMNS := 3
const SHOP_CONTAINER_START := PLAY_AREA_CENTER + Vector2(-280, 40)
const SHOP_CONTAINER_SPACING := Vector2(280, 240)
const SHOP_CONTAINER_MAX_HP := 12.0

const MELEE_ZOMBIE_GOLD := 3
const ACID_ZOMBIE_GOLD := 4
const ELITE_BRUTE_GOLD := 12
const MAX_MELEE_ENEMY_ATTACK_TOKENS := 2
const MAX_RANGED_ENEMY_ATTACK_TOKENS := 1
const MAX_ELITE_ENEMY_ATTACK_TOKENS := 1

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const MELEE_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/ZombieMelee.tscn")
const ACID_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/AcidZombie.tscn")
const ELITE_BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/EliteBrute.tscn")
const CAMERA_SHAKE_SCRIPT := preload("res://systems/combat/CameraShake.gd")
const CONTAINER_CATALOG := preload("res://systems/battle/ContainerCatalog.gd")
const REWARD_PICKUP_SCRIPT := preload("res://systems/items/RewardPickup.gd")
const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const SHOP_RULES := preload("res://systems/battle/ShopRules.gd")
const TALENT_TREE_UI_CONTROLLER := preload("res://systems/battle/TalentTreeUiController.gd")
const BATTLE_BGM: AudioStream = preload("res://assets/sfx/junipersona-to-the-death-159171.mp3")
const SHOP_INSUFFICIENT_GOLD_SFX: AudioStream = preload("res://assets/sfx/Error_1.wav")
const TALENT_UNLOCK_SFX: AudioStream = preload("res://assets/sfx/Confirm_7.wav")
const ARENA_TEXTURE: Texture2D = preload("res://assets/map/arena tiles.png")
const URN_SHADOW_SCENE: PackedScene = preload("res://scenes/containers/UrnShadow.tscn")
const BARREL_SHADOW_SCENE: PackedScene = preload("res://scenes/containers/BarrelShadow.tscn")
const SKULL_DECOR_TEXTURES: Array[Texture2D] = [
	preload("res://assets/map/skull1.png"),
	preload("res://assets/map/skull2.png"),
	preload("res://assets/map/small skull1.png"),
	preload("res://assets/map/small skull2.png"),
]

enum Phase {
	COMBAT,
	SHOP,
	VICTORY,
	DEFEAT,
}

enum ContainerType {
	URN,
	BARREL,
	TOMB,
}

enum ShopCategory {
	BROWN,
	ATTACK,
	DEFENSE,
	UTILITY,
}

enum ShopTier {
	COMMON,
	RARE,
	LEGENDARY,
}

var containers: Array[BreakableContainer] = []
var shop_containers: Array[BreakableContainer] = []
var enemies: Array[EnemyBase] = []
var shop_container_data: Dictionary = {}
var no_spawn_container_breaks: Dictionary = {}
var enemy_gold_rewards: Dictionary = {}
var melee_enemy_attack_tokens: Dictionary = {}
var ranged_enemy_attack_tokens: Dictionary = {}
var elite_enemy_attack_tokens: Dictionary = {}
var phase: int = Phase.COMBAT
var current_round: int = 1
var gold: int = 0
var game_over: bool = false
var hud_message: String = ""
var round_time_remaining: float = 0.0
var random_container_break_time_remaining: float = 0.0
var auto_break_triggered: bool = false
var shop_transition_pending: bool = false

var player: Player
var camera: Camera2D
var hud_label: Label
var status_panel: Panel
var status_label: Label
var talent_tree_ui: CanvasLayer
var bgm_player: AudioStreamPlayer


func _ready() -> void:
	randomize()
	y_sort_enabled = true
	_create_background()
	_spawn_player()
	_create_camera()
	_start_bgm()
	_create_hud()
	_start_combat_round()


func _exit_tree() -> void:
	_stop_bgm()


func _process(delta: float) -> void:
	if game_over:
		return

	_update_round_timer(delta)
	_update_random_container_break_timer(delta)
	_cleanup_enemy_list()
	_update_hud()
	_check_defeat()
	_check_combat_clear()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
			return
		if Input.is_action_just_pressed("shop_next_round") and phase == Phase.SHOP:
			if _is_talent_tree_open():
				return
			_advance_from_shop()


func _create_background() -> void:
	var blocked_area := ColorRect.new()
	blocked_area.name = "BlockedArea"
	blocked_area.color = Color(0.045, 0.052, 0.05)
	blocked_area.position = PLAY_AREA_RECT.position - Vector2(900, 900)
	blocked_area.size = PLAY_AREA_RECT.size + Vector2(1800, 1800)
	blocked_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocked_area.z_index = -120
	add_child(blocked_area)

	_create_arena_tile_map()
	_create_arena_edge_decorations()
	_create_arena_walls()


func _create_arena_tile_map() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = ARENA_TILE_SIZE

	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = ARENA_TEXTURE
	atlas_source.texture_region_size = ARENA_TILE_SIZE
	for y in range(10):
		for x in range(10):
			atlas_source.create_tile(Vector2i(x, y))
	tile_set.add_source(atlas_source, ARENA_TILE_SOURCE_ID)

	var arena := TileMapLayer.new()
	arena.name = "ArenaTiles"
	arena.tile_set = tile_set
	arena.position = PLAY_AREA_RECT.position
	arena.scale = Vector2(ARENA_TILE_SCALE, ARENA_TILE_SCALE)
	arena.z_index = -100
	add_child(arena)

	_fill_arena_tiles(arena)


func _fill_arena_tiles(arena: TileMapLayer) -> void:
	var max_x := ARENA_GRID_SIZE.x - 1
	var max_y := ARENA_GRID_SIZE.y - 1

	for y in range(2, max_y - 1):
		for x in range(2, max_x - 1):
			arena.set_cell(Vector2i(x, y), ARENA_TILE_SOURCE_ID, Vector2i(randi_range(3, 6), randi_range(3, 6)))

	for x in range(2, max_x - 1):
		var top_variant_x := randi_range(3, 6)
		var bottom_variant_x := randi_range(3, 6)
		arena.set_cell(Vector2i(x, 0), ARENA_TILE_SOURCE_ID, Vector2i(top_variant_x, 0))
		arena.set_cell(Vector2i(x, 1), ARENA_TILE_SOURCE_ID, Vector2i(top_variant_x, 1))
		arena.set_cell(Vector2i(x, max_y - 1), ARENA_TILE_SOURCE_ID, Vector2i(bottom_variant_x, 8))
		arena.set_cell(Vector2i(x, max_y), ARENA_TILE_SOURCE_ID, Vector2i(bottom_variant_x, 9))

	for y in range(2, max_y - 1):
		var left_variant_y := randi_range(3, 6)
		var right_variant_y := randi_range(3, 6)
		arena.set_cell(Vector2i(0, y), ARENA_TILE_SOURCE_ID, Vector2i(0, left_variant_y))
		arena.set_cell(Vector2i(1, y), ARENA_TILE_SOURCE_ID, Vector2i(1, left_variant_y))
		arena.set_cell(Vector2i(max_x - 1, y), ARENA_TILE_SOURCE_ID, Vector2i(8, right_variant_y))
		arena.set_cell(Vector2i(max_x, y), ARENA_TILE_SOURCE_ID, Vector2i(9, right_variant_y))

	for y in range(2):
		for x in range(2):
			arena.set_cell(Vector2i(x, y), ARENA_TILE_SOURCE_ID, Vector2i(x, y))
			arena.set_cell(Vector2i(max_x - 1 + x, y), ARENA_TILE_SOURCE_ID, Vector2i(8 + x, y))
			arena.set_cell(Vector2i(x, max_y - 1 + y), ARENA_TILE_SOURCE_ID, Vector2i(x, 8 + y))
			arena.set_cell(Vector2i(max_x - 1 + x, max_y - 1 + y), ARENA_TILE_SOURCE_ID, Vector2i(8 + x, 8 + y))


func _create_arena_edge_decorations() -> void:
	var decorations := Node2D.new()
	decorations.name = "ArenaEdgeDecorations"
	decorations.z_index = -90
	add_child(decorations)

	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[0], PLAY_AREA_RECT.position + Vector2(245, 150), -0.18, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[3], PLAY_AREA_RECT.position + Vector2(620, 130), 0.12, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[1], Vector2(PLAY_AREA_RECT.end.x - 210, PLAY_AREA_RECT.position.y + 155), 0.2, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[2], Vector2(PLAY_AREA_RECT.position.x + 150, PLAY_AREA_RECT.position.y + 420), 0.3, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[0], Vector2(PLAY_AREA_RECT.end.x - 145, PLAY_AREA_RECT.position.y + 540), -0.22, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[3], Vector2(PLAY_AREA_RECT.position.x + 140, PLAY_AREA_RECT.end.y - 430), -0.08, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[2], Vector2(PLAY_AREA_RECT.end.x - 155, PLAY_AREA_RECT.end.y - 320), 0.16, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[1], Vector2(PLAY_AREA_RECT.position.x + 330, PLAY_AREA_RECT.end.y - 150), -0.25, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[2], Vector2(PLAY_AREA_RECT.position.x + 820, PLAY_AREA_RECT.end.y - 140), 0.18, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[0], Vector2(PLAY_AREA_RECT.end.x - 390, PLAY_AREA_RECT.end.y - 150), 0.08, 2.0, true)


func _add_arena_edge_decoration(
	parent: Node2D,
	texture: Texture2D,
	decoration_position: Vector2,
	decoration_rotation: float,
	decoration_scale: float,
	flip_h: bool
) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.global_position = decoration_position
	sprite.rotation = decoration_rotation
	sprite.scale = Vector2(decoration_scale, decoration_scale)
	sprite.flip_h = flip_h
	parent.add_child(sprite)


func _create_arena_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "ArenaWalls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	walls.add_to_group("walls")
	add_child(walls)

	var wall_thickness := float(ARENA_TILE_SIZE.x) * ARENA_TILE_SCALE * 2.0
	_add_arena_wall(
		walls,
		"TopWall",
		PLAY_AREA_RECT.position + Vector2(PLAY_AREA_SIZE.x * 0.5, wall_thickness * 0.5),
		Vector2(PLAY_AREA_SIZE.x, wall_thickness)
	)
	_add_arena_wall(
		walls,
		"BottomWall",
		Vector2(PLAY_AREA_CENTER.x, PLAY_AREA_RECT.end.y - wall_thickness * 0.5),
		Vector2(PLAY_AREA_SIZE.x, wall_thickness)
	)
	_add_arena_wall(
		walls,
		"LeftWall",
		PLAY_AREA_RECT.position + Vector2(wall_thickness * 0.5, PLAY_AREA_SIZE.y * 0.5),
		Vector2(wall_thickness, PLAY_AREA_SIZE.y)
	)
	_add_arena_wall(
		walls,
		"RightWall",
		Vector2(PLAY_AREA_RECT.end.x - wall_thickness * 0.5, PLAY_AREA_CENTER.y),
		Vector2(wall_thickness, PLAY_AREA_SIZE.y)
	)


func _add_arena_wall(parent: StaticBody2D, wall_name: String, wall_position: Vector2, wall_size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = wall_size

	var collision := CollisionShape2D.new()
	collision.name = wall_name
	collision.global_position = wall_position
	collision.shape = shape
	parent.add_child(collision)


func _scale_actor_body(actor: Node2D) -> void:
	var sprite := actor.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.scale = CHARACTER_SPRITE_SCALE

	var body_collision := actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.scale = CHARACTER_SPRITE_SCALE


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.name = "Player"
	player.global_position = PLAYER_POSITION
	player.set_collision_layer_value(1, false)
	player.set_collision_layer_value(7, true)
	player.collision_mask = 0
	player.set_collision_mask_value(1, true)
	_scale_actor_body(player)
	player.movement_bounds_enabled = true
	player.movement_bounds = PLAY_AREA_RECT
	player.experience_changed.connect(_on_player_progress_changed)
	player.talent_points_changed.connect(_on_player_talent_points_changed)
	player.talent_unlocked.connect(_on_player_talent_unlocked)
	add_child(player)


func _create_camera() -> void:
	camera = Camera2D.new()
	camera.set_script(CAMERA_SHAKE_SCRIPT)
	camera.name = "PlayerCamera"
	camera.zoom = CAMERA_ZOOM
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = int(PLAY_AREA_RECT.position.x)
	camera.limit_top = int(PLAY_AREA_RECT.position.y)
	camera.limit_right = int(PLAY_AREA_RECT.end.x)
	camera.limit_bottom = int(PLAY_AREA_RECT.end.y)
	player.add_child(camera)
	camera.make_current()


func _start_bgm() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BattleBgm"
	bgm_player.stream = BATTLE_BGM
	bgm_player.volume_db = -18.0
	add_child(bgm_player)
	bgm_player.finished.connect(bgm_player.play)
	bgm_player.play()


func _stop_bgm() -> void:
	if bgm_player == null or not is_instance_valid(bgm_player):
		return
	var replay_callable := Callable(bgm_player, "play")
	if bgm_player.finished.is_connected(replay_callable):
		bgm_player.finished.disconnect(replay_callable)
	bgm_player.stop()
	bgm_player.stream = null


func _start_combat_round() -> void:
	phase = Phase.COMBAT
	round_time_remaining = ROUND_CONTAINER_AUTO_BREAK_TIME
	_reset_random_container_break_timer()
	auto_break_triggered = false
	shop_transition_pending = false
	hud_message = "Round %d started." % current_round
	status_panel.visible = false
	_clear_shop_containers()
	_spawn_containers()
	if is_instance_valid(player):
		player.emit_round_started(current_round)
	_update_hud()


func _spawn_containers() -> void:
	_clear_combat_containers()
	var placements: Array[Dictionary] = _roll_combat_container_placements()
	for index in range(placements.size()):
		var placement: Dictionary = placements[index]
		var container_position: Vector2 = placement["position"]
		var container_type: int = int(placement["type"])
		var container := _create_combat_container(container_position, index + 1, container_type)
		containers.append(container)
		add_child(container)


func _roll_combat_container_placements() -> Array[Dictionary]:
	var occupied_cells: Dictionary = {}
	var placements: Array[Dictionary] = []
	var grid_cell_size: Vector2 = PLAY_AREA_SIZE / float(GRID_SIZE)
	for _index in range(CONTAINER_COUNT):
		var container_type: int = _roll_combat_container_type()
		var placement := _roll_container_placement(container_type, grid_cell_size, occupied_cells)
		if placement.is_empty() and container_type == ContainerType.TOMB:
			container_type = _roll_small_combat_container_type()
			placement = _roll_container_placement(container_type, grid_cell_size, occupied_cells)
		if placement.is_empty():
			break
		placements.append({
			"position": placement["position"],
			"type": container_type,
		})
	return placements


func _roll_container_placement(container_type: int, grid_cell_size: Vector2, occupied_cells: Dictionary) -> Dictionary:
	if container_type == ContainerType.TOMB:
		var top_left_cell := _pick_free_tomb_cell(occupied_cells)
		if top_left_cell == Vector2i(-1, -1):
			return {}

		for row_offset in range(2):
			for column_offset in range(2):
				occupied_cells[top_left_cell + Vector2i(column_offset, row_offset)] = true
		return {
			"position": PLAY_AREA_RECT.position + (Vector2(top_left_cell) + Vector2(1.0, 1.0)) * grid_cell_size,
		}

	var cell := _pick_free_single_cell(occupied_cells)
	if cell == Vector2i(-1, -1):
		return {}

	occupied_cells[cell] = true
	var position: Vector2 = PLAY_AREA_RECT.position + (Vector2(cell) + Vector2(0.5, 0.5)) * grid_cell_size
	position += Vector2(
		randf_range(-grid_cell_size.x * 0.38, grid_cell_size.x * 0.38),
		randf_range(-grid_cell_size.y * 0.38, grid_cell_size.y * 0.38)
	)
	return {
		"position": position,
	}


func _pick_free_tomb_cell(occupied_cells: Dictionary) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for row in range(CONTAINER_GRID_MIN_INDEX, CONTAINER_GRID_MAX_INDEX):
		for column in range(CONTAINER_GRID_MIN_INDEX, CONTAINER_GRID_MAX_INDEX):
			var cell := Vector2i(column, row)
			if _is_tomb_cell_free(cell, occupied_cells):
				candidates.append(cell)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[randi_range(0, candidates.size() - 1)]


func _is_tomb_cell_free(top_left_cell: Vector2i, occupied_cells: Dictionary) -> bool:
	for row_offset in range(2):
		for column_offset in range(2):
			if occupied_cells.has(top_left_cell + Vector2i(column_offset, row_offset)):
				return false
	return true


func _pick_free_single_cell(occupied_cells: Dictionary) -> Vector2i:
	var candidates: Array[Vector2i] = []
	for row in range(CONTAINER_GRID_MIN_INDEX, CONTAINER_GRID_MAX_INDEX + 1):
		for column in range(CONTAINER_GRID_MIN_INDEX, CONTAINER_GRID_MAX_INDEX + 1):
			var cell := Vector2i(column, row)
			if not occupied_cells.has(cell):
				candidates.append(cell)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[randi_range(0, candidates.size() - 1)]


func _roll_combat_container_type() -> int:
	return CONTAINER_CATALOG.roll_combat_type()


func _roll_small_combat_container_type() -> int:
	return CONTAINER_CATALOG.roll_small_combat_type()


func _create_combat_container(container_position: Vector2, container_number: int, container_type: int) -> BreakableContainer:
	var container := _create_base_container(container_position, "%s%d" % [_get_container_type_name(container_type), container_number])
	container.container_type = container_type
	container.static_texture = _get_container_texture(container_type)
	container.damaged_texture = _get_container_damaged_texture(container_type)
	container.hit_texture = _get_container_hit_texture(container_type)
	container.destroyed_texture = _get_container_destroyed_texture(container_type)
	container.destroy_frames = _get_container_destroy_frames(container_type)
	container.max_hp = _get_container_max_hp(container_type)
	container.area_entered.connect(_on_container_area_entered.bind(container))
	container.broken.connect(_on_container_broken)
	container.break_finished.connect(_on_container_break_finished)
	_add_container_sprite(container, Color.WHITE)
	return container


func _create_shop_container(container_position: Vector2, index: int, forced_category: int = -1, forced_tier: int = -1) -> BreakableContainer:
	var category: int = forced_category if forced_category >= 0 else _roll_shop_category()
	var tier: int = forced_tier if forced_tier >= 0 else _roll_shop_tier()
	var base_price: int = _get_shop_price(category, tier)
	var price: int = _apply_shop_price_discount(base_price)
	var container := _create_base_container(container_position, "ShopJar%d" % index)
	container.is_shop_container = true
	container.container_type = ContainerType.URN
	container.static_texture = _get_container_texture(ContainerType.URN)
	container.damaged_texture = _get_container_damaged_texture(ContainerType.URN)
	container.hit_texture = _get_container_hit_texture(ContainerType.URN)
	container.destroyed_texture = _get_container_destroyed_texture(ContainerType.URN)
	container.destroy_frames = _get_container_destroy_frames(ContainerType.URN)
	container.max_hp = SHOP_CONTAINER_MAX_HP
	container.area_entered.connect(_on_container_area_entered.bind(container))
	container.broken.connect(_on_shop_container_broken)
	_add_container_sprite(container, _get_shop_category_color(category))
	_add_shop_label(container, category, tier, price)
	shop_container_data[container] = {
		"category": category,
		"tier": tier,
		"base_price": base_price,
		"price": price,
	}
	return container


func _create_base_container(container_position: Vector2, container_name: String) -> BreakableContainer:
	var container := BreakableContainer.new()
	container.name = container_name
	container.global_position = container_position
	container.collision_layer = 1 << 5
	container.collision_mask = 1 << 2
	container.monitoring = true
	container.monitorable = true

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = CONTAINER_COLLISION_RADIUS * CHARACTER_SPRITE_SCALE.x
	collision.shape = shape
	container.add_child(collision)
	return container


func _add_container_sprite(container: BreakableContainer, modulate_color: Color) -> void:
	_add_container_shadow(container)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = container.static_texture
	sprite.centered = true
	sprite.scale = CHARACTER_SPRITE_SCALE
	sprite.modulate = modulate_color
	container.add_child(sprite)


func _add_container_shadow(container: BreakableContainer) -> void:
	if container.container_type == ContainerType.TOMB:
		return

	var shadow_scene := URN_SHADOW_SCENE
	match container.container_type:
		ContainerType.BARREL:
			shadow_scene = BARREL_SHADOW_SCENE

	var shadow := shadow_scene.instantiate() as Node2D
	if shadow == null:
		return

	shadow.name = "Shadow"
	container.add_child(shadow)


func _add_shop_label(container: BreakableContainer, category: int, tier: int, price: int) -> void:
	var label := Label.new()
	label.name = "ShopLabel"
	label.text = "%s %s\n%dg" % [
		_get_shop_category_label(category),
		_get_shop_tier_label(tier),
		price,
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-65, 42)
	label.size = Vector2(130, 44)
	container.add_child(label)


func _on_container_area_entered(area: Area2D, container: BreakableContainer) -> void:
	if game_over or not is_instance_valid(container):
		return
	if container.is_breaking:
		return
	if not area is Projectile:
		return

	var projectile := area as Projectile
	if projectile.target_group != &"enemy":
		return

	projectile.queue_free()
	if container.is_shop_container:
		_try_damage_shop_container(container, projectile.damage)
		return

	var owner_player: Node = projectile.owner_player
	var attack_info: Dictionary = {"source": "player_attack", "owner": owner_player}
	container.take_damage(projectile.damage, attack_info)


func _try_damage_shop_container(container: BreakableContainer, damage: float) -> void:
	var data: Dictionary = shop_container_data.get(container, {})
	var price: int = int(data.get("price", 0))
	if container.hp - damage <= 0.0 and gold < price:
		_play_shop_insufficient_gold_sfx(container.global_position)
		hud_message = "Not enough gold. Need %d." % price
		_update_hud()
		return

	if container.hp - damage <= 0.0:
		gold -= price
		hud_message = "Spent %d gold." % price
	container.take_damage(damage, {"source": "shop_purchase", "owner": player})


func _mark_container_broken(container: BreakableContainer) -> void:
	if not containers.has(container):
		return

	containers.erase(container)
	_update_hud()
	_check_combat_clear()


func _on_container_broken(container: BreakableContainer, attack_info: Dictionary) -> void:
	_mark_container_broken(container)
	_try_drop_player_container_gold(container, attack_info)
	var owner: Node = attack_info.get("owner")
	if owner != null and owner.has_method("emit_container_broken"):
		owner.emit_container_broken(container, attack_info)


func _on_shop_container_broken(container: BreakableContainer, _attack_info: Dictionary) -> void:
	if shop_containers.has(container):
		shop_containers.erase(container)

	var data: Dictionary = shop_container_data.get(container, {})
	var price: int = int(data.get("price", 0))
	if is_instance_valid(player):
		player.emit_shop_container_broken(container, price)
	var category: int = int(data.get("category", ShopCategory.BROWN))
	var tier: int = int(data.get("tier", ShopTier.COMMON))
	var rarity: StringName = _roll_item_rarity_for_tier(tier)
	var item := _roll_shop_item(category, rarity)
	if item != null and is_instance_valid(player):
		player.add_item(item)
		hud_message = "Received %s." % item.display_name
	else:
		hud_message = "The shop jar was empty."
	shop_container_data.erase(container)
	_update_hud()


func add_player_gold(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	gold += amount
	if reason != "":
		hud_message = "%s refunded %d gold." % [reason, amount]
	else:
		hud_message = "Gained %d gold." % amount
	_update_hud()


func _try_drop_player_container_gold(container: BreakableContainer, attack_info: Dictionary) -> void:
	if attack_info.get("source") != "player_attack":
		return
	if randf() >= PLAYER_CONTAINER_GOLD_DROP_CHANCE:
		return

	no_spawn_container_breaks[container] = true
	var gold_amount: int = randi_range(PLAYER_CONTAINER_GOLD_DROP_MIN, PLAYER_CONTAINER_GOLD_DROP_MAX)
	_spawn_reward_pickup(RewardPickup.KIND_GOLD, gold_amount, container.global_position)
	hud_message = "Container dropped %d gold." % gold_amount
	_update_hud()


func refresh_shop_container_prices() -> void:
	for container in shop_containers:
		if not is_instance_valid(container):
			continue
		var data: Dictionary = shop_container_data.get(container, {})
		if data.is_empty():
			continue
		var category: int = int(data.get("category", ShopCategory.BROWN))
		var tier: int = int(data.get("tier", ShopTier.COMMON))
		var base_price: int = int(data.get("base_price", _get_shop_price(category, tier)))
		var price: int = _apply_shop_price_discount(base_price)
		data["base_price"] = base_price
		data["price"] = price
		shop_container_data[container] = data
		_update_shop_label(container, category, tier, price)
	_update_hud()


func _on_container_break_finished(container: BreakableContainer, container_type: int, spawn_position: Vector2) -> void:
	if no_spawn_container_breaks.has(container):
		no_spawn_container_breaks.erase(container)
		_update_hud()
		_check_combat_clear()
		return

	_release_container_enemies(spawn_position, container_type)
	_update_hud()
	_check_combat_clear()


func _release_container_enemies(spawn_position: Vector2, container_type: int) -> void:
	match container_type:
		ContainerType.URN:
			_spawn_enemy(spawn_position, _pick_basic_zombie_scene(0.7))
		ContainerType.BARREL:
			var count: int = randi_range(2, 3)
			for index in range(count):
				_spawn_enemy(_get_spawn_offset_position(spawn_position, index, count), _pick_basic_zombie_scene(0.5))
		ContainerType.TOMB:
			if randf() < 0.2:
				_spawn_enemy(spawn_position, ELITE_BRUTE_SCENE)
			else:
				for index in range(5):
					_spawn_enemy(_get_spawn_offset_position(spawn_position, index, 5), _pick_basic_zombie_scene(0.5))


func _pick_basic_zombie_scene(melee_chance: float) -> PackedScene:
	if randf() < melee_chance:
		return MELEE_ZOMBIE_SCENE

	return ACID_ZOMBIE_SCENE


func _get_spawn_offset_position(center: Vector2, index: int, count: int) -> Vector2:
	if count <= 1:
		return center

	var angle: float = TAU * float(index) / float(count)
	return center + Vector2(cos(angle), sin(angle)) * 34.0


func _spawn_enemy(spawn_position: Vector2, enemy_scene: PackedScene) -> void:
	var enemy := enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		return

	enemy.global_position = spawn_position
	enemy.died.connect(_on_enemy_died)
	enemies.append(enemy)
	enemy_gold_rewards[enemy] = _get_enemy_gold_reward(enemy)
	add_child(enemy)
	_scale_actor_body(enemy)


func _get_enemy_gold_reward(enemy: EnemyBase) -> int:
	if enemy is EliteBrute:
		return ELITE_BRUTE_GOLD
	if enemy is AcidZombie:
		return ACID_ZOMBIE_GOLD
	return MELEE_ZOMBIE_GOLD


func _on_enemy_died(enemy: EnemyBase) -> void:
	enemies.erase(enemy)
	release_enemy_attack_token(enemy)
	var reward: int = int(enemy_gold_rewards.get(enemy, MELEE_ZOMBIE_GOLD))
	enemy_gold_rewards.erase(enemy)
	_spawn_reward_pickup(RewardPickup.KIND_GOLD, reward, enemy.global_position + Vector2(-10.0, 0.0))
	_spawn_reward_pickup(RewardPickup.KIND_EXPERIENCE, reward, enemy.global_position + Vector2(10.0, 0.0))
	hud_message = "Dropped %d gold and %d EXP." % [reward, reward]
	_update_hud()
	_check_combat_clear()


func _spawn_reward_pickup(kind: StringName, amount: int, spawn_position: Vector2) -> void:
	if amount <= 0 or not is_instance_valid(player):
		return

	var pickup := REWARD_PICKUP_SCRIPT.new() as RewardPickup
	pickup.setup(kind, amount, spawn_position, player)
	add_child(pickup)


func request_enemy_attack_token(enemy: EnemyBase) -> bool:
	var token_pool: Dictionary = _get_enemy_attack_token_pool(enemy)
	if token_pool.has(enemy):
		return true

	if _get_valid_enemy_attack_token_count(token_pool) >= _get_enemy_attack_token_limit(enemy):
		return false

	token_pool[enemy] = true
	return true


func release_enemy_attack_token(enemy: EnemyBase) -> void:
	melee_enemy_attack_tokens.erase(enemy)
	ranged_enemy_attack_tokens.erase(enemy)
	elite_enemy_attack_tokens.erase(enemy)


func _get_enemy_attack_token_pool(enemy: EnemyBase) -> Dictionary:
	if enemy is EliteBrute:
		return elite_enemy_attack_tokens
	if enemy is AcidZombie:
		return ranged_enemy_attack_tokens

	return melee_enemy_attack_tokens


func _get_enemy_attack_token_limit(enemy: EnemyBase) -> int:
	if enemy is EliteBrute:
		return MAX_ELITE_ENEMY_ATTACK_TOKENS
	if enemy is AcidZombie:
		return MAX_RANGED_ENEMY_ATTACK_TOKENS

	return MAX_MELEE_ENEMY_ATTACK_TOKENS


func _get_valid_enemy_attack_token_count(token_pool: Dictionary) -> int:
	for enemy in token_pool.keys():
		if not is_instance_valid(enemy):
			token_pool.erase(enemy)

	return token_pool.size()


func _enter_shop_phase() -> void:
	if phase != Phase.COMBAT or game_over:
		return

	shop_transition_pending = false
	phase = Phase.SHOP
	round_time_remaining = 0.0
	random_container_break_time_remaining = 0.0
	hud_message = "Shop phase. Shoot jars to buy items, or press Enter for next round."
	if is_instance_valid(player):
		player.emit_round_ended()
		player.settle_round_level_rewards()
	_spawn_shop_containers()
	_maybe_show_talent_tree()
	_update_hud()


func _spawn_shop_containers() -> void:
	_clear_shop_containers()
	for index in range(SHOP_CONTAINER_COUNT):
		var position: Vector2 = _get_shop_container_position(index)
		var container := _create_shop_container(position, index + 1)
		shop_containers.append(container)
		add_child(container)
	var extra_rare_count: int = player.consume_extra_rare_shop_jars() if is_instance_valid(player) else 0
	for extra_index in range(extra_rare_count):
		var index: int = SHOP_CONTAINER_COUNT + extra_index
		var position: Vector2 = _get_shop_container_position(index)
		var container := _create_shop_container(position, index + 1, ShopCategory.BROWN, ShopTier.RARE)
		shop_containers.append(container)
		add_child(container)


func _get_shop_container_position(index: int) -> Vector2:
	var column: int = index % SHOP_CONTAINER_COLUMNS
	var row: int = floori(float(index) / float(SHOP_CONTAINER_COLUMNS))
	return SHOP_CONTAINER_START + Vector2(
		SHOP_CONTAINER_SPACING.x * float(column),
		SHOP_CONTAINER_SPACING.y * float(row)
	)


func _advance_from_shop() -> void:
	if _is_talent_tree_open():
		return
	if current_round >= MAX_ROUNDS:
		_win_game()
		return

	current_round += 1
	_start_combat_round()


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var hud_bg := ColorRect.new()
	hud_bg.color = Color(0.04, 0.06, 0.07, 0.72)
	hud_bg.position = Vector2(24, 24)
	hud_bg.size = Vector2(1060, 78)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud_bg)

	hud_label = Label.new()
	hud_label.position = Vector2(36, 30)
	hud_label.size = Vector2(1030, 66)
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(hud_label)

	status_panel = Panel.new()
	status_panel.visible = false
	status_panel.position = Vector2(690, 390)
	status_panel.size = Vector2(540, 220)
	canvas.add_child(status_panel)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.position = Vector2(24, 20)
	status_label.size = Vector2(492, 180)
	status_panel.add_child(status_label)

	_create_talent_tree_ui()


func _create_talent_tree_ui() -> void:
	if not is_instance_valid(player):
		return

	talent_tree_ui = TALENT_TREE_UI_CONTROLLER.new() as CanvasLayer
	talent_tree_ui.setup(player)
	talent_tree_ui.talent_requested.connect(_on_talent_button_pressed)
	add_child(talent_tree_ui)


func _on_talent_button_pressed(node_id: StringName) -> void:
	if not is_instance_valid(player):
		return

	if player.unlock_talent(node_id):
		_play_talent_unlock_sfx()
		hud_message = "Unlocked +1 ATK."
	_update_talent_tree_ui()
	_update_hud()


func _play_talent_unlock_sfx() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	SFX_PLAYER.play_2d(parent, TALENT_UNLOCK_SFX, player.global_position, -2.0, 1.0, 1.0)


func _play_shop_insufficient_gold_sfx(sound_position: Vector2) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	SFX_PLAYER.play_2d(parent, SHOP_INSUFFICIENT_GOLD_SFX, sound_position, -2.0, 1.0, 1.0)


func _on_player_progress_changed(_current_exp: int, _required_exp: int, _level: int) -> void:
	_update_hud()


func _on_player_talent_points_changed(_unspent_points: int, _pending_points: int) -> void:
	_update_talent_tree_ui()
	_update_hud()


func _on_player_talent_unlocked(_node_id: StringName) -> void:
	_update_talent_tree_ui()


func _maybe_show_talent_tree() -> void:
	if is_instance_valid(player) and player.unspent_talent_points > 0:
		_show_talent_tree()


func _show_talent_tree() -> void:
	if talent_tree_ui == null:
		return
	talent_tree_ui.show_tree()


func _hide_talent_tree() -> void:
	if talent_tree_ui == null:
		return
	talent_tree_ui.hide_tree()


func _is_talent_tree_open() -> bool:
	return talent_tree_ui != null and talent_tree_ui.is_open()


func _update_talent_tree_ui() -> void:
	if talent_tree_ui != null:
		talent_tree_ui.refresh()


func _cleanup_enemy_list() -> void:
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			enemy_gold_rewards.erase(enemy)
			release_enemy_attack_token(enemy)


func _update_hud() -> void:
	if hud_label == null:
		return

	var hp: int = 0
	var level: int = 1
	var experience: int = 0
	var required_experience: int = 10
	var unspent_talents: int = 0
	if is_instance_valid(player):
		hp = int(ceil(player.hp))
		level = player.level
		experience = player.experience
		required_experience = player.get_required_exp_for_next_level()
		unspent_talents = player.unspent_talent_points

	var phase_label: String = "Combat" if phase == Phase.COMBAT else "Shop"
	var objective_count: int = containers.size() if phase == Phase.COMBAT else shop_containers.size()
	var objective_label: String = "Containers" if phase == Phase.COMBAT else "Shop Jars"
	var prompt: String = "\n%s" % hud_message if hud_message != "" else ""
	if phase == Phase.SHOP:
		prompt = "\n%s" % ("Press Enter for next round. " + hud_message)
	elif phase == Phase.COMBAT:
		prompt = "\nTimer: %ds until remaining containers break. %s" % [
			ceili(round_time_remaining),
			hud_message,
		]

	hud_label.text = "Round: %d/%d   Phase: %s   Gold: %d   HP: %d   Lv: %d   EXP: %d/%d   Talent: %d   %s: %d   Zombies: %d%s" % [
		current_round,
		MAX_ROUNDS,
		phase_label,
		gold,
		hp,
		level,
		experience,
		required_experience,
		unspent_talents,
		objective_label,
		objective_count,
		enemies.size(),
		prompt,
	]


func _check_defeat() -> void:
	if not is_instance_valid(player):
		_lose_game()


func _check_combat_clear() -> void:
	if phase != Phase.COMBAT or game_over or shop_transition_pending:
		return

	if containers.is_empty() and enemies.is_empty():
		shop_transition_pending = true
		call_deferred("_enter_shop_phase")


func _update_round_timer(delta: float) -> void:
	if phase != Phase.COMBAT or auto_break_triggered:
		return
	if containers.is_empty():
		return

	round_time_remaining = maxf(0.0, round_time_remaining - delta)
	if round_time_remaining <= 0.0:
		_auto_break_remaining_containers()


func _update_random_container_break_timer(delta: float) -> void:
	if phase != Phase.COMBAT or auto_break_triggered:
		return
	if containers.is_empty():
		return

	random_container_break_time_remaining -= delta
	if random_container_break_time_remaining <= 0.0:
		_break_random_container()
		_reset_random_container_break_timer()


func _reset_random_container_break_timer() -> void:
	random_container_break_time_remaining = randf_range(
		RANDOM_CONTAINER_BREAK_MIN_TIME,
		RANDOM_CONTAINER_BREAK_MAX_TIME
	)


func _break_random_container() -> void:
	var available_containers: Array[BreakableContainer] = []
	for container in containers:
		if is_instance_valid(container) and not container.is_breaking:
			available_containers.append(container)
	if available_containers.is_empty():
		return

	var container := available_containers.pick_random() as BreakableContainer
	container.last_attack_info = {"source": "random_container_timer"}
	container.break_open()


func _auto_break_remaining_containers() -> void:
	auto_break_triggered = true
	hud_message = "Time is up. Remaining containers broke open."
	for container in containers.duplicate():
		if is_instance_valid(container) and not container.is_breaking:
			no_spawn_container_breaks[container] = true
			container.last_attack_info = {"source": "round_timer"}
			container.break_open()
	_update_hud()


func _win_game() -> void:
	game_over = true
	phase = Phase.VICTORY
	_clear_shop_containers()
	status_panel.visible = true
	status_label.text = "Victory!\nYou cleared all 10 rounds.\nPress R to restart."
	_update_hud()


func _lose_game() -> void:
	game_over = true
	phase = Phase.DEFEAT
	status_panel.visible = true
	status_label.text = "Defeat!\nThe zombies killed the player.\nPress R to restart."


func _clear_combat_containers() -> void:
	for container in containers:
		if is_instance_valid(container):
			container.queue_free()
	containers.clear()
	no_spawn_container_breaks.clear()


func _clear_shop_containers() -> void:
	for container in shop_containers:
		if is_instance_valid(container):
			container.queue_free()
	shop_containers.clear()
	shop_container_data.clear()


func _roll_shop_category() -> int:
	return SHOP_RULES.roll_category()


func _roll_shop_tier() -> int:
	return SHOP_RULES.roll_tier()


func _roll_item_rarity_for_tier(tier: int) -> StringName:
	return SHOP_RULES.rarity_for_tier(tier)


func _roll_shop_item(category: int, rarity: StringName) -> ItemDefinition:
	var database := get_node_or_null("/root/ItemDatabase")
	return SHOP_RULES.roll_item(database, category, rarity)


func _get_shop_price(category: int, tier: int) -> int:
	return SHOP_RULES.price(category, tier)


func _get_discounted_shop_price(category: int, tier: int) -> int:
	var multiplier: float = player.get_shop_price_multiplier() if is_instance_valid(player) else 1.0
	return SHOP_RULES.discounted_price(category, tier, multiplier)


func _apply_shop_price_discount(base_price: int) -> int:
	var multiplier: float = player.get_shop_price_multiplier() if is_instance_valid(player) else 1.0
	return SHOP_RULES.discounted_base_price(base_price, multiplier)


func _update_shop_label(container: BreakableContainer, category: int, tier: int, price: int) -> void:
	var label := container.get_node_or_null("ShopLabel") as Label
	if label == null:
		return
	label.text = "%s %s\n%dg" % [
		_get_shop_category_label(category),
		_get_shop_tier_label(tier),
		price,
	]


func _get_shop_category_filter(category: int) -> StringName:
	return SHOP_RULES.category_filter(category)


func _get_shop_category_color(category: int) -> Color:
	return SHOP_RULES.category_color(category)


func _get_shop_category_label(category: int) -> String:
	return SHOP_RULES.category_label(category)


func _get_shop_tier_label(tier: int) -> String:
	return SHOP_RULES.tier_label(tier)


func _get_container_texture(container_type: int) -> Texture2D:
	return CONTAINER_CATALOG.texture(container_type)


func _get_container_damaged_texture(container_type: int) -> Texture2D:
	return CONTAINER_CATALOG.damaged_texture(container_type)


func _get_container_hit_texture(container_type: int) -> Texture2D:
	return CONTAINER_CATALOG.hit_texture(container_type)


func _get_container_destroyed_texture(container_type: int) -> Texture2D:
	return CONTAINER_CATALOG.destroyed_texture(container_type)


func _get_container_destroy_frames(container_type: int) -> Array[Texture2D]:
	return CONTAINER_CATALOG.destroy_frames(container_type)


func _get_container_max_hp(container_type: int) -> float:
	return CONTAINER_CATALOG.max_hp(container_type)


func _get_container_type_name(container_type: int) -> String:
	return CONTAINER_CATALOG.type_name(container_type)
