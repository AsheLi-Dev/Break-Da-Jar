extends Node2D

const SCREEN_SIZE := Vector2(1920, 1080)
const PLAY_AREA_SIZE := Vector2(1280, 1280)
const PLAY_AREA_CENTER := Vector2(960, 540)
const PLAY_AREA_RECT := Rect2(PLAY_AREA_CENTER - PLAY_AREA_SIZE * 0.5, PLAY_AREA_SIZE)
const ROUND_10_MAP_SIZE_MULTIPLIER := 1.15
const ROUND_10_MAP_EXPAND_SHAKE_MAGNITUDE := 12.0
const ROUND_10_MAP_EXPAND_SHAKE_DURATION := 0.22
const ROUND_10_MAP_EXPAND_DELAY := 0.18
const ROUND_10_MAP_EXPAND_ZOOM_FACTOR := 1.08
const CAMERA_VISIBLE_SIZE := Vector2(1152, 648)
const CAMERA_ZOOM := Vector2(SCREEN_SIZE.x / CAMERA_VISIBLE_SIZE.x, SCREEN_SIZE.y / CAMERA_VISIBLE_SIZE.y)
const PLAYER_POSITION := PLAY_AREA_CENTER + Vector2(-500, 0)
const ARENA_TILE_SIZE := Vector2i(32, 32)
const ARENA_TILE_SCALE := 2.0
const ARENA_GRID_SIZE := Vector2i(20, 20)
const ARENA_TILE_SOURCE_ID := 0
const CHARACTER_SPRITE_SCALE := Vector2(2.0, 2.0)
const MAX_ROUNDS := 20
const ROUND_CONTAINER_AUTO_BREAK_TIME := 30.0
const RANDOM_CONTAINER_BREAK_MIN_TIME := 2.0
const RANDOM_CONTAINER_BREAK_MAX_TIME := 3.0
const ROUND_ENRAGE_SPEED_GAIN_PER_SECOND := 0.05
const ROUND_ENRAGE_MAX_SPEED_BONUS := 1.0
const PLAYER_CONTAINER_GOLD_DROP_CHANCE := 0.5
const PLAYER_CONTAINER_GOLD_DROP_MIN := 1
const PLAYER_CONTAINER_GOLD_DROP_MAX := 3

const CONTAINER_COUNT := 40
const GRID_SIZE := 16
const CONTAINER_GRID_MIN_INDEX := 3
const CONTAINER_GRID_MAX_INDEX := 12

const SHOP_CONTAINER_COUNT := 6
const SHOP_CONTAINER_COLUMNS := 3
const SHOP_CONTAINER_START := PLAY_AREA_CENTER + Vector2(-280, 40)
const SHOP_CONTAINER_SPACING := Vector2(280, 240)
const SHOP_CONTAINER_MAX_HP := 12.0
const CHARACTER_CARD_WIDTH := 282.0
const CHARACTER_CARD_POSITION := Vector2(1608.0, 24.0)
const CHARACTER_CARD_TOP_HEIGHT := 150.0
const CHARACTER_CARD_ICON_SIZE := 34.0
const ITEM_DETAIL_CARD_WIDTH := 282.0
const ITEM_DETAIL_CARD_POSITION := Vector2(1304.0, 24.0)
const ITEM_DETAIL_CARD_ICON_SIZE := 104.0
const ITEM_DETAIL_TEXT_BOX_MARGIN := Vector2(28.0, 18.0)
const CONTAINER_HITBOX_PREVIEW_ROOT := NodePath("ContainerHitboxPreviews")
const ALTAR_CLICK_RADIUS := 64.0
const ALTAR_POSITION := PLAY_AREA_CENTER + Vector2(0.0, -210.0)
const MAP_POISON_PUDDLE_INTERVAL := 4.0
const MAP_POISON_PUDDLE_INITIAL_COUNT := 5

const MELEE_ZOMBIE_GOLD := 3
const ACID_ZOMBIE_GOLD := 4
const ELITE_BRUTE_GOLD := 12
const MAX_MELEE_ENEMY_ATTACK_TOKENS := 2
const MAX_RANGED_ENEMY_ATTACK_TOKENS := 3
const MAX_ELITE_ENEMY_ATTACK_TOKENS := 2

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const DEFAULT_CHARACTER_ID := &"necromancer"
const MELEE_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/ZombieMelee.tscn")
const BURNING_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/BurningZombie.tscn")
const ACID_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/AcidZombie.tscn")
const ZOMBIE_FIREMAN_SCENE: PackedScene = preload("res://scenes/enemies/ZombieFireman.tscn")
const ELITE_BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/EliteBrute.tscn")
const UNDEAD_DARK_KNIGHT_SCENE: PackedScene = preload("res://scenes/enemies/UndeadDarkKnight.tscn")
const CAMERA_SHAKE_SCRIPT := preload("res://systems/combat/CameraShake.gd")
const CONTAINER_CATALOG := preload("res://systems/battle/ContainerCatalog.gd")
const REWARD_PICKUP_SCRIPT := preload("res://systems/items/RewardPickup.gd")
const SHOP_ITEM_REWARD_VISUAL_SCRIPT := preload("res://systems/items/ShopItemRewardVisual.gd")
const POISON_PUDDLE_SCRIPT := preload("res://systems/combat/PoisonPuddle.gd")
const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const SHOP_RULES := preload("res://systems/battle/ShopRules.gd")
const TALENT_TREE_UI_CONTROLLER := preload("res://systems/battle/TalentTreeUiController.gd")
const PAUSE_INPUT_CONTROLLER := preload("res://systems/battle/PauseInputController.gd")
const BATTLE_BGM: AudioStream = preload("res://assets/sfx/junipersona-to-the-death-159171.mp3")
const SHOP_INSUFFICIENT_GOLD_SFX: AudioStream = preload("res://assets/sfx/Error_1.wav")
const TALENT_UNLOCK_SFX: AudioStream = preload("res://assets/sfx/Confirm_7.wav")
const ARENA_TEXTURE: Texture2D = preload("res://assets/map/arena tiles.png")
const CHARACTER_CARD_TEXTURE: Texture2D = preload("res://assets/ui/Gold Blue Card.png")
const COMMON_ITEM_CARD_TEXTURE: Texture2D = preload("res://assets/ui/Green Card.png")
const RARE_ITEM_CARD_TEXTURE: Texture2D = preload("res://assets/ui/Golden Card.png")
const LEGENDARY_ITEM_CARD_TEXTURE: Texture2D = preload("res://assets/ui/Gold Red Card.png")
const ITEM_DETAIL_TEXT_BOX_TEXTURE: Texture2D = preload("res://assets/ui/Passive Box.png")
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

const ELITE_AFFIXES: Array[Dictionary] = [
	{"id": &"swift", "name": "Swift", "description": "+35% movement speed.", "move_speed_multiplier": 1.35},
	{"id": &"poison_trail", "name": "Venom Trail", "description": "Leaves poison puddles while moving.", "interval": 1.0, "radius": 80.0, "duration": 5.0},
	{"id": &"speed_aura", "name": "Haste Aura", "description": "Nearby normal enemies move faster.", "radius": 260.0, "multiplier": 1.3, "duration": 0.8, "interval": 0.5},
	{"id": &"slow_regen", "name": "Regrowth", "description": "Regenerates health over time.", "regen_per_second": 2.0},
	{"id": &"distant_hide", "name": "Distant Hide", "description": "Takes less damage when far away.", "start_distance": 260.0, "full_distance": 720.0, "max_reduction": 0.6},
	{"id": &"acid_volley", "name": "Acid Spitter", "description": "Randomly fires acid projectiles.", "cooldown": 2.6, "speed": 330.0, "lifetime": 2.1, "damage_multiplier": 0.8},
]

const MAP_AFFIXES: Array[Dictionary] = [
	{"id": &"poison_puddles", "name": "Toxic Ground", "description": "Poison puddles appear around the arena."},
	{"id": &"elite_damage", "name": "Elite Fury", "description": "Elite enemies deal +30% damage.", "elite_damage_multiplier": 1.3},
	{"id": &"normal_damage", "name": "Minion Fury", "description": "Normal enemies deal +20% damage.", "normal_damage_multiplier": 1.2},
	{"id": &"enemy_health", "name": "Thick Horde", "description": "Enemies have +20% health.", "health_multiplier": 1.2},
	{"id": &"enemy_speed", "name": "Ravenous Pace", "description": "Enemies move +30% faster.", "move_speed_multiplier": 1.3},
	{"id": &"enemy_count", "name": "Swarming Horde", "description": "Enemies spawn +30% more often.", "spawn_multiplier": 1.3},
	{"id": &"enemy_dodge", "name": "Shifting Horde", "description": "Enemies gain 10% dodge.", "dodge_chance": 0.1},
]

const ALTAR_BLESSINGS: Array[Dictionary] = [
	{"id": &"move_speed", "name": "Wind Blessing", "description": "Move speed +20%."},
	{"id": &"attack_speed", "name": "Tempo Blessing", "description": "Attack speed +20%."},
	{"id": &"fireball_proc", "name": "Ember Blessing", "description": "Attacks have +20% fireball chance."},
	{"id": &"chain_lightning_proc", "name": "Storm Blessing", "description": "Attacks have +20% chain lightning chance."},
	{"id": &"round_common_item", "name": "Spoils Blessing", "description": "Gain a random common item each round end."},
	{"id": &"kill_gold", "name": "Greed Blessing", "description": "Every 10 kills grants +1 gold."},
	{"id": &"kill_xp", "name": "Scholar Blessing", "description": "Every 10 kills grants +1 XP."},
]

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
var round_enrage_active: bool = false
var round_enrage_elapsed: float = 0.0
var shop_transition_pending: bool = false
var round_10_map_expansion_effect_played: bool = false
var altar_node: Node2D
var altar_offer: Dictionary = {}
var altar_accepted: bool = false
var last_altar_map_affix_id: StringName = &""
var last_altar_blessing_id: StringName = &""
var pending_map_affix: Dictionary = {}
var pending_altar_blessing: Dictionary = {}
var pending_altar_reward_round: int = 0
var active_map_affix: Dictionary = {}
var active_map_affix_round: int = 0
var map_poison_puddle_timer: float = 0.0

var player: Player
var camera: Camera2D
var hud_label: Label
var status_panel: Panel
var status_label: Label
var character_card: Control
var character_card_stats_label: Label
var character_card_items_grid: GridContainer
var character_card_blessings_label: Label
var character_card_items_signature: String = ""
var item_detail_card: Control
var item_detail_card_background: TextureRect
var item_detail_card_icon: TextureRect
var item_detail_card_text_box: TextureRect
var item_detail_card_name_label: Label
var item_detail_card_description_label: Label
var pause_overlay: Control
var pause_input_controller: Node
var talent_tree_ui: CanvasLayer
var bgm_player: AudioStreamPlayer
var applied_map_size_multiplier: float = 1.0


func _ready() -> void:
	randomize()
	y_sort_enabled = true
	_hide_container_hitbox_previews()
	_create_background()
	_spawn_player()
	_create_camera()
	_start_bgm()
	_create_hud()
	_create_pause_input_controller()
	_start_combat_round()


func _exit_tree() -> void:
	get_tree().paused = false
	_stop_bgm()


func _process(delta: float) -> void:
	if game_over or get_tree().paused:
		return

	_update_round_timer(delta)
	_update_random_container_break_timer(delta)
	_update_active_map_affix(delta)
	_cleanup_enemy_list()
	_update_round_enrage(delta)
	_update_hud()
	_check_defeat()
	_check_combat_clear()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _try_accept_altar_at_position(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
			return
		if _try_purchase_clicked_shop_container(get_global_mouse_position()):
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel"):
			_set_paused(not get_tree().paused)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_R and game_over:
			get_tree().paused = false
			get_tree().reload_current_scene()
			return
		if Input.is_action_just_pressed("shop_next_round") and phase == Phase.SHOP:
			if _is_talent_tree_open():
				return
			_advance_from_shop()


func _create_background() -> void:
	var play_area_rect := _get_play_area_rect()
	var blocked_area := ColorRect.new()
	blocked_area.name = "BlockedArea"
	blocked_area.color = Color(0.045, 0.052, 0.05)
	blocked_area.position = play_area_rect.position - Vector2(900, 900)
	blocked_area.size = play_area_rect.size + Vector2(1800, 1800)
	blocked_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocked_area.z_index = -120
	add_child(blocked_area)

	_create_arena_tile_map()
	_create_arena_edge_decorations()
	_create_arena_walls()


func _create_arena_tile_map() -> void:
	var play_area_rect := _get_play_area_rect()
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
	arena.position = play_area_rect.position
	arena.scale = Vector2(ARENA_TILE_SCALE, ARENA_TILE_SCALE)
	arena.z_index = -100
	add_child(arena)

	_fill_arena_tiles(arena)


func _fill_arena_tiles(arena: TileMapLayer) -> void:
	var arena_grid_size := _get_arena_grid_size()
	var max_x := arena_grid_size.x - 1
	var max_y := arena_grid_size.y - 1

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
	var play_area_rect := _get_play_area_rect()
	var decorations := Node2D.new()
	decorations.name = "ArenaEdgeDecorations"
	decorations.z_index = -90
	add_child(decorations)

	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[0], play_area_rect.position + Vector2(245, 150), -0.18, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[3], play_area_rect.position + Vector2(620, 130), 0.12, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[1], Vector2(play_area_rect.end.x - 210, play_area_rect.position.y + 155), 0.2, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[2], Vector2(play_area_rect.position.x + 150, play_area_rect.position.y + 420), 0.3, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[0], Vector2(play_area_rect.end.x - 145, play_area_rect.position.y + 540), -0.22, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[3], Vector2(play_area_rect.position.x + 140, play_area_rect.end.y - 430), -0.08, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[2], Vector2(play_area_rect.end.x - 155, play_area_rect.end.y - 320), 0.16, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[1], Vector2(play_area_rect.position.x + 330, play_area_rect.end.y - 150), -0.25, 2.0, false)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[2], Vector2(play_area_rect.position.x + 820, play_area_rect.end.y - 140), 0.18, 2.0, true)
	_add_arena_edge_decoration(decorations, SKULL_DECOR_TEXTURES[0], Vector2(play_area_rect.end.x - 390, play_area_rect.end.y - 150), 0.08, 2.0, true)


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
	var play_area_center := _get_play_area_center()
	var play_area_size := _get_play_area_size()
	var play_area_rect := _get_play_area_rect()
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
		play_area_rect.position + Vector2(play_area_size.x * 0.5, wall_thickness * 0.5),
		Vector2(play_area_size.x, wall_thickness)
	)
	_add_arena_wall(
		walls,
		"BottomWall",
		Vector2(play_area_center.x, play_area_rect.end.y - wall_thickness * 0.5),
		Vector2(play_area_size.x, wall_thickness)
	)
	_add_arena_wall(
		walls,
		"LeftWall",
		play_area_rect.position + Vector2(wall_thickness * 0.5, play_area_size.y * 0.5),
		Vector2(wall_thickness, play_area_size.y)
	)
	_add_arena_wall(
		walls,
		"RightWall",
		Vector2(play_area_rect.end.x - wall_thickness * 0.5, play_area_center.y),
		Vector2(wall_thickness, play_area_size.y)
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
	player.setup_character(DEFAULT_CHARACTER_ID)
	player.name = "Player"
	player.global_position = _get_player_position()
	player.set_collision_layer_value(1, false)
	player.set_collision_layer_value(7, true)
	player.collision_mask = 0
	player.set_collision_mask_value(1, true)
	_scale_actor_body(player)
	player.movement_bounds_enabled = true
	player.movement_bounds = _get_play_area_rect()
	player.hp_changed.connect(_on_player_hp_changed)
	player.experience_changed.connect(_on_player_progress_changed)
	player.talent_points_changed.connect(_on_player_talent_points_changed)
	player.talent_unlocked.connect(_on_player_talent_unlocked)
	add_child(player)


func _create_camera() -> void:
	var play_area_rect := _get_play_area_rect()
	camera = Camera2D.new()
	camera.set_script(CAMERA_SHAKE_SCRIPT)
	camera.name = "PlayerCamera"
	camera.zoom = CAMERA_ZOOM
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = int(play_area_rect.position.x)
	camera.limit_top = int(play_area_rect.position.y)
	camera.limit_right = int(play_area_rect.end.x)
	camera.limit_bottom = int(play_area_rect.end.y)
	player.add_child(camera)
	camera.make_current()


func _get_map_size_multiplier() -> float:
	var multiplier := _get_round_map_size_multiplier()
	if is_instance_valid(player) and player.has_method("get_map_size_multiplier"):
		multiplier *= float(player.get_map_size_multiplier())
	return multiplier


func _get_round_map_size_multiplier() -> float:
	return ROUND_10_MAP_SIZE_MULTIPLIER if current_round >= 10 else 1.0


func _should_play_round_10_map_expansion_effect() -> bool:
	return current_round == 10 and not round_10_map_expansion_effect_played


func _play_round_10_map_expansion_effect() -> void:
	round_10_map_expansion_effect_played = true
	if is_instance_valid(camera) and camera.has_method("start_shake"):
		camera.call("start_shake", ROUND_10_MAP_EXPAND_SHAKE_MAGNITUDE, ROUND_10_MAP_EXPAND_SHAKE_DURATION)
	await get_tree().create_timer(ROUND_10_MAP_EXPAND_DELAY).timeout
	if is_instance_valid(camera) and camera.has_method("start_zoom_in"):
		camera.call("start_zoom_in", ROUND_10_MAP_EXPAND_ZOOM_FACTOR, 0.12)


func _get_play_area_size() -> Vector2:
	return PLAY_AREA_SIZE * _get_map_size_multiplier()


func _get_play_area_center() -> Vector2:
	return PLAY_AREA_CENTER * _get_map_size_multiplier()


func _get_play_area_rect() -> Rect2:
	var play_area_size := _get_play_area_size()
	return Rect2(_get_play_area_center() - play_area_size * 0.5, play_area_size)


func _get_player_position() -> Vector2:
	return _get_play_area_center() + (PLAYER_POSITION - PLAY_AREA_CENTER)


func _get_arena_grid_size() -> Vector2i:
	var play_area_size := _get_play_area_size()
	var tile_world_size := float(ARENA_TILE_SIZE.x) * ARENA_TILE_SCALE
	return Vector2i(
		maxi(ARENA_GRID_SIZE.x, ceili(play_area_size.x / tile_world_size)),
		maxi(ARENA_GRID_SIZE.y, ceili(play_area_size.y / tile_world_size))
	)


func _get_combat_container_count() -> int:
	var multiplier := 1.0
	if is_instance_valid(player) and player.has_method("get_combat_container_count_multiplier"):
		multiplier = float(player.get_combat_container_count_multiplier())
	return maxi(1, roundi(float(CONTAINER_COUNT) * _get_round_container_count_multiplier() * multiplier))


func _get_round_container_count_multiplier() -> float:
	if current_round <= 6:
		return 0.4 + 0.1 * float(current_round)
	return 1.0 + 0.1 * float(current_round - 6)


func _refresh_play_area_from_player(force: bool = false) -> void:
	var next_multiplier := _get_map_size_multiplier()
	if not force and is_equal_approx(next_multiplier, applied_map_size_multiplier):
		return
	applied_map_size_multiplier = next_multiplier
	for node_name in [&"BlockedArea", &"ArenaTiles", &"ArenaEdgeDecorations", &"ArenaWalls"]:
		var existing := get_node_or_null(NodePath(String(node_name)))
		if existing != null:
			remove_child(existing)
			existing.queue_free()
	_create_background()
	if is_instance_valid(player):
		player.movement_bounds = _get_play_area_rect()
	if is_instance_valid(camera):
		var play_area_rect := _get_play_area_rect()
		camera.limit_left = int(play_area_rect.position.x)
		camera.limit_top = int(play_area_rect.position.y)
		camera.limit_right = int(play_area_rect.end.x)
		camera.limit_bottom = int(play_area_rect.end.y)


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
	round_enrage_active = false
	round_enrage_elapsed = 0.0
	shop_transition_pending = false
	_clear_altar_offer()
	_activate_pending_map_affix()
	hud_message = "Round %d started." % current_round
	status_panel.visible = false
	_clear_shop_containers()
	if _should_play_round_10_map_expansion_effect():
		await _play_round_10_map_expansion_effect()
	_refresh_play_area_from_player()
	_spawn_containers()
	if is_instance_valid(player):
		player.emit_round_started(current_round)
		_maybe_spawn_round_healing_orb()
	_apply_starting_map_affix_effects()
	_update_hud()


func _maybe_spawn_round_healing_orb() -> void:
	if not is_instance_valid(player) or not player.has_method("should_spawn_round_healing_orb"):
		return
	if not bool(player.should_spawn_round_healing_orb()):
		return

	var play_area_size := _get_play_area_size()
	var play_area_rect := _get_play_area_rect()
	var spawn_position := play_area_rect.position + Vector2(
		randf_range(play_area_size.x * 0.2, play_area_size.x * 0.8),
		randf_range(play_area_size.y * 0.2, play_area_size.y * 0.8)
	)
	_spawn_reward_pickup(RewardPickup.KIND_HEAL, maxi(1, roundi(player.max_hp * 0.25)), spawn_position)


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
	var grid_cell_size: Vector2 = _get_play_area_size() / float(GRID_SIZE)
	for _index in range(_get_combat_container_count()):
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
		if container_type == ContainerType.TOMB:
			var extra_tomb_count := _get_extra_tomb_container_count()
			for _extra_index in range(extra_tomb_count):
				var extra_placement := _roll_container_placement(ContainerType.TOMB, grid_cell_size, occupied_cells)
				if extra_placement.is_empty():
					break
				placements.append({
					"position": extra_placement["position"],
					"type": ContainerType.TOMB,
				})
	return placements


func _get_extra_tomb_container_count() -> int:
	var multiplier := 1.0
	if is_instance_valid(player) and player.has_method("get_tomb_container_count_multiplier"):
		multiplier = float(player.get_tomb_container_count_multiplier())
	return maxi(0, int(floorf(multiplier - 1.0)))


func _roll_container_placement(container_type: int, grid_cell_size: Vector2, occupied_cells: Dictionary) -> Dictionary:
	var play_area_rect := _get_play_area_rect()
	if container_type == ContainerType.TOMB:
		var top_left_cell := _pick_free_tomb_cell(occupied_cells)
		if top_left_cell == Vector2i(-1, -1):
			return {}

		for row_offset in range(2):
			for column_offset in range(2):
				occupied_cells[top_left_cell + Vector2i(column_offset, row_offset)] = true
		return {
			"position": play_area_rect.position + (Vector2(top_left_cell) + Vector2(1.0, 1.0)) * grid_cell_size,
		}

	var cell := _pick_free_single_cell(occupied_cells)
	if cell == Vector2i(-1, -1):
		return {}

	occupied_cells[cell] = true
	var position: Vector2 = play_area_rect.position + (Vector2(cell) + Vector2(0.5, 0.5)) * grid_cell_size
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
	if current_round <= 5:
		return ContainerType.URN
	if current_round <= 10:
		return ContainerType.URN if randf() < 0.8 else ContainerType.BARREL
	return CONTAINER_CATALOG.roll_combat_type()


func _roll_small_combat_container_type() -> int:
	if current_round <= 5:
		return ContainerType.URN
	if current_round <= 10:
		return ContainerType.URN if randf() < 0.8 else ContainerType.BARREL
	return CONTAINER_CATALOG.roll_small_combat_type()


func _create_combat_container(container_position: Vector2, container_number: int, container_type: int) -> BreakableContainer:
	var container := _create_base_container(container_position, "%s%d" % [_get_container_type_name(container_type), container_number], container_type)
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
	base_price = _apply_shop_tier_price_multiplier(base_price, tier)
	var price: int = _apply_shop_price_discount(base_price)
	var container := _create_base_container(container_position, "ShopJar%d" % index, ContainerType.URN)
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


func _create_base_container(container_position: Vector2, container_name: String, container_type: int) -> BreakableContainer:
	var container := BreakableContainer.new()
	container.name = container_name
	container.global_position = container_position
	container.collision_layer = 1 << 5
	container.collision_mask = 1 << 2
	container.monitoring = true
	container.monitorable = true

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.position = _get_container_collision_offset(container_type)
	collision.scale = _get_container_collision_scale(container_type)
	collision.shape = _get_container_collision_shape(container_type)
	container.add_child(collision)
	return container


func _hide_container_hitbox_previews() -> void:
	var preview_root := get_node_or_null(CONTAINER_HITBOX_PREVIEW_ROOT) as Node2D
	if preview_root != null:
		preview_root.visible = false


func _get_container_collision_shape(container_type: int) -> Shape2D:
	var template := _get_container_hitbox_template(container_type)
	if template != null and template.shape != null:
		return template.shape.duplicate() as Shape2D

	var shape := CircleShape2D.new()
	shape.radius = _get_exported_container_collision_radius(container_type)
	return shape


func _get_container_collision_radius(container_type: int) -> float:
	var template := _get_container_hitbox_template(container_type)
	if template != null and template.shape is CircleShape2D:
		return (template.shape as CircleShape2D).radius
	return _get_exported_container_collision_radius(container_type)


func _get_exported_container_collision_radius(container_type: int) -> float:
	match container_type:
		ContainerType.BARREL:
			return 32.0
		ContainerType.TOMB:
			return 64.0
		_:
			return 28.0


func _get_container_collision_offset(container_type: int) -> Vector2:
	var template := _get_container_hitbox_template(container_type)
	if template != null:
		return template.position
	return _get_exported_container_collision_offset(container_type)


func _get_exported_container_collision_offset(container_type: int) -> Vector2:
	match container_type:
		ContainerType.BARREL:
			return Vector2(0.0, 16.0)
		ContainerType.TOMB:
			return Vector2(0.0, 20.0)
		_:
			return Vector2(0.0, 12.0)


func _get_container_collision_scale(container_type: int) -> Vector2:
	var template := _get_container_hitbox_template(container_type)
	if template != null:
		return template.scale
	return Vector2.ONE


func _get_container_hitbox_template(container_type: int) -> CollisionShape2D:
	var preview_root := get_node_or_null(CONTAINER_HITBOX_PREVIEW_ROOT)
	if preview_root == null:
		return null

	var preview_name := "Urn"
	match container_type:
		ContainerType.BARREL:
			preview_name = "Barrel"
		ContainerType.TOMB:
			preview_name = "Tomb"

	return preview_root.get_node_or_null("%s/CollisionShape2D" % preview_name) as CollisionShape2D


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

	if container.is_shop_container:
		return

	projectile.queue_free()
	var owner_player: Node = projectile.owner_player
	var attack_info: Dictionary = {"source": "player_attack", "owner": owner_player}
	container.take_damage(projectile.damage, attack_info)


func _try_purchase_clicked_shop_container(click_position: Vector2) -> bool:
	if phase != Phase.SHOP or game_over or _is_talent_tree_open():
		return false
	var container := _get_shop_container_at_position(click_position)
	if container == null:
		return false
	return _try_purchase_shop_container(container)


func _get_shop_container_at_position(world_position: Vector2) -> BreakableContainer:
	for container in shop_containers:
		if not is_instance_valid(container) or container.is_breaking:
			continue
		if _is_position_inside_container(container, world_position):
			return container
	return null


func _is_position_inside_container(container: BreakableContainer, world_position: Vector2) -> bool:
	var collision := container.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or collision.shape == null:
		return false

	var local_position := collision.to_local(world_position)
	if collision.shape is CircleShape2D:
		return local_position.length() <= (collision.shape as CircleShape2D).radius
	if collision.shape is RectangleShape2D:
		var size := (collision.shape as RectangleShape2D).size
		return absf(local_position.x) <= size.x * 0.5 and absf(local_position.y) <= size.y * 0.5

	return false


func _try_purchase_shop_container(container: BreakableContainer) -> bool:
	if not is_instance_valid(container) or container.is_breaking:
		return false
	var data: Dictionary = shop_container_data.get(container, {})
	var price: int = int(data.get("price", 0))
	if gold < price:
		_play_shop_insufficient_gold_sfx(container.global_position)
		hud_message = "Not enough gold. Need %d." % price
		_update_hud()
		return false

	gold -= price
	hud_message = "Spent %d gold." % price
	container.take_damage(container.hp, {"source": "shop_purchase", "owner": player})
	return true


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
		_spawn_shop_item_reward(item, container.global_position)
		hud_message = "Bought %s." % item.display_name
	else:
		hud_message = "The shop jar was empty."
	shop_container_data.erase(container)
	_update_hud()


func _spawn_shop_item_reward(item: ItemDefinition, spawn_position: Vector2, always_process: bool = false) -> void:
	if item == null or not is_instance_valid(player):
		return

	var reward_visual := SHOP_ITEM_REWARD_VISUAL_SCRIPT.new()
	if always_process:
		reward_visual.process_mode = Node.PROCESS_MODE_ALWAYS
	reward_visual.setup(item, spawn_position, player, Callable(self, "_collect_shop_item_reward"))
	add_child(reward_visual)


func _collect_shop_item_reward(item: ItemDefinition) -> void:
	if item == null or not is_instance_valid(player):
		return

	player.add_item(item)
	hud_message = "Received %s." % item.display_name
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
		var base_price: int = _apply_shop_tier_price_multiplier(_get_shop_price(category, tier), tier)
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
			var count := _get_modified_enemy_spawn_count(1)
			for index in range(count):
				_spawn_enemy(_get_spawn_offset_position(spawn_position, index, count), _pick_basic_zombie_scene(0.7))
		ContainerType.BARREL:
			var count: int = _get_modified_enemy_spawn_count(randi_range(2, 3))
			for index in range(count):
				_spawn_enemy(_get_spawn_offset_position(spawn_position, index, count), _pick_basic_zombie_scene(0.5))
		ContainerType.TOMB:
			if randf() < 0.2:
				var count := _get_modified_enemy_spawn_count(1)
				for index in range(count):
					_spawn_enemy(_get_spawn_offset_position(spawn_position, index, count), _pick_elite_enemy_scene())
			else:
				var count := _get_modified_enemy_spawn_count(5)
				for index in range(count):
					_spawn_enemy(_get_spawn_offset_position(spawn_position, index, count), _pick_basic_zombie_scene(0.5))


func _get_modified_enemy_spawn_count(base_count: int) -> int:
	var multiplier := 1.0
	if is_instance_valid(player) and player.has_method("get_enemy_spawn_count_multiplier"):
		multiplier = float(player.get_enemy_spawn_count_multiplier())
	multiplier *= _get_active_map_affix_value(&"spawn_multiplier", 1.0)
	return maxi(1, int(ceilf(float(base_count) * multiplier)))


func _pick_basic_zombie_scene(melee_chance: float) -> PackedScene:
	if randf() < 0.18:
		return BURNING_ZOMBIE_SCENE

	if randf() < melee_chance:
		if current_round >= 5 and randf() < 0.35:
			return UNDEAD_DARK_KNIGHT_SCENE
		return MELEE_ZOMBIE_SCENE

	if current_round < 3:
		return MELEE_ZOMBIE_SCENE

	if current_round < 7:
		return ACID_ZOMBIE_SCENE

	if randf() < 0.5:
		return ZOMBIE_FIREMAN_SCENE

	return ACID_ZOMBIE_SCENE


func _pick_elite_enemy_scene() -> PackedScene:
	return ELITE_BRUTE_SCENE


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
	enemy.set_meta(&"spawn_msec", Time.get_ticks_msec())
	enemy.max_hp *= _get_round_enemy_max_hp_multiplier()
	enemy.hp = enemy.max_hp
	if is_instance_valid(player) and player.has_method("get_enemy_max_hp_multiplier"):
		var hp_multiplier := float(player.get_enemy_max_hp_multiplier())
		enemy.max_hp *= hp_multiplier
		enemy.hp = enemy.max_hp
	enemy.died.connect(_on_enemy_died)
	enemies.append(enemy)
	enemy_gold_rewards[enemy] = _get_enemy_gold_reward(enemy)
	add_child(enemy)
	_scale_actor_body(enemy)
	_apply_current_round_enrage_to_enemy(enemy)
	_apply_current_map_affix_to_enemy(enemy)
	_apply_elite_affix(enemy)


func _get_enemy_gold_reward(enemy: EnemyBase) -> int:
	if enemy is EliteBrute:
		return ELITE_BRUTE_GOLD
	if enemy is AcidZombie or enemy is ZombieFireman:
		return ACID_ZOMBIE_GOLD
	return MELEE_ZOMBIE_GOLD


func _get_round_enemy_max_hp_multiplier() -> float:
	var altar_multiplier := _get_active_map_affix_value(&"health_multiplier", 1.0)
	if current_round < 6:
		return altar_multiplier
	return (1.0 + 0.1 * float(current_round - 5)) * altar_multiplier


func _on_enemy_died(enemy: EnemyBase) -> void:
	enemies.erase(enemy)
	release_enemy_attack_token(enemy)
	var base_reward: int = int(enemy_gold_rewards.get(enemy, MELEE_ZOMBIE_GOLD))
	enemy_gold_rewards.erase(enemy)
	var gold_reward := _get_modified_enemy_gold_reward(enemy, base_reward)
	var experience_reward := _get_modified_enemy_experience_reward(enemy, base_reward)
	_spawn_reward_pickup(RewardPickup.KIND_GOLD, gold_reward, enemy.global_position + Vector2(-10.0, 0.0))
	_spawn_reward_pickup(RewardPickup.KIND_EXPERIENCE, experience_reward, enemy.global_position + Vector2(10.0, 0.0))
	hud_message = "Dropped %d gold and %d EXP." % [gold_reward, experience_reward]
	_update_hud()
	_check_combat_clear()


func _get_modified_enemy_gold_reward(enemy: EnemyBase, base_reward: int) -> int:
	var multiplier := 1.0
	if is_instance_valid(player) and player.has_method("get_enemy_gold_reward_multiplier"):
		multiplier = float(player.get_enemy_gold_reward_multiplier(enemy))
	return maxi(0, int(round(float(base_reward) * multiplier)))


func _get_modified_enemy_experience_reward(enemy: EnemyBase, base_reward: int) -> int:
	var multiplier := 1.0
	if is_instance_valid(player) and player.has_method("get_enemy_experience_reward_multiplier"):
		multiplier = float(player.get_enemy_experience_reward_multiplier(enemy))
	return maxi(0, int(round(float(base_reward) * multiplier)))


func _spawn_reward_pickup(kind: StringName, amount: int, spawn_position: Vector2) -> void:
	if amount <= 0 or not is_instance_valid(player):
		return

	var pickup := REWARD_PICKUP_SCRIPT.new() as RewardPickup
	pickup.setup(kind, amount, spawn_position, player)
	add_child(pickup)


func _roll_elite_affix() -> Dictionary:
	return ELITE_AFFIXES.pick_random().duplicate(true)


func _apply_elite_affix(enemy: EnemyBase) -> void:
	if enemy == null or not enemy.is_elite:
		return

	var affix := _roll_elite_affix()
	var affix_id: StringName = affix.get("id", &"")
	if affix_id == &"":
		return

	if affix_id == &"swift":
		enemy.base_move_speed *= float(affix.get("move_speed_multiplier", 1.35))
		enemy.set_map_move_speed_multiplier(enemy.map_move_speed_multiplier)
	enemy.set_elite_affix(affix_id, String(affix.get("name", "Elite")), affix)


func _roll_altar_offer() -> Dictionary:
	var map_affix: Dictionary = _pick_different_entry(MAP_AFFIXES, last_altar_map_affix_id)
	var blessing: Dictionary = _pick_different_entry(ALTAR_BLESSINGS, last_altar_blessing_id)
	last_altar_map_affix_id = StringName(map_affix.get("id", &""))
	last_altar_blessing_id = StringName(blessing.get("id", &""))
	return {
		"map_affix": map_affix,
		"blessing": blessing,
	}


func _pick_different_entry(entries: Array[Dictionary], previous_id: StringName) -> Dictionary:
	if entries.is_empty():
		return {}

	var candidates: Array[Dictionary] = []
	for entry in entries:
		if entries.size() > 1 and StringName(entry.get("id", &"")) == previous_id:
			continue
		candidates.append(entry)
	if candidates.is_empty():
		candidates = entries.duplicate()
	return candidates.pick_random().duplicate(true)


func _spawn_altar_offer() -> void:
	_clear_altar_offer()
	if phase != Phase.SHOP or game_over:
		return

	altar_offer = _roll_altar_offer()
	altar_accepted = false
	altar_node = Node2D.new()
	altar_node.name = "ChallengeAltar"
	altar_node.global_position = _get_altar_position()
	add_child(altar_node)

	var base := Polygon2D.new()
	base.name = "AltarBase"
	base.color = Color(0.34, 0.18, 0.48, 0.95)
	base.polygon = PackedVector2Array([
		Vector2(0.0, -42.0),
		Vector2(36.0, -12.0),
		Vector2(24.0, 38.0),
		Vector2(-24.0, 38.0),
		Vector2(-36.0, -12.0),
	])
	altar_node.add_child(base)

	var core := Polygon2D.new()
	core.name = "AltarCore"
	core.color = Color(0.72, 1.0, 0.28, 0.9)
	core.polygon = _circle_polygon(14.0, 16)
	core.position = Vector2(0.0, -8.0)
	altar_node.add_child(core)

	var label := Label.new()
	label.name = "AltarLabel"
	label.position = Vector2(-180.0, 52.0)
	label.size = Vector2(360.0, 92.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.66))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 17)
	label.text = _get_altar_offer_text(false)
	altar_node.add_child(label)


func _clear_altar_offer() -> void:
	if altar_node != null and is_instance_valid(altar_node):
		altar_node.queue_free()
	altar_node = null
	altar_offer.clear()
	altar_accepted = false


func _try_accept_altar_at_position(world_position: Vector2) -> bool:
	if phase != Phase.SHOP or altar_accepted or altar_node == null or not is_instance_valid(altar_node):
		return false
	if world_position.distance_to(altar_node.global_position) > ALTAR_CLICK_RADIUS:
		return false

	var map_affix: Dictionary = altar_offer.get("map_affix", {})
	var blessing: Dictionary = altar_offer.get("blessing", {})
	if map_affix.is_empty() or blessing.is_empty():
		return false

	altar_accepted = true
	pending_map_affix = map_affix.duplicate(true)
	pending_altar_blessing = blessing.duplicate(true)
	pending_altar_reward_round = current_round + 1
	var label := altar_node.get_node_or_null("AltarLabel") as Label
	if label != null:
		label.text = _get_altar_offer_text(true)
	hud_message = "Altar accepted. Next round: %s." % String(map_affix.get("name", "Challenge"))
	_update_hud()
	return true


func _activate_pending_map_affix() -> void:
	active_map_affix.clear()
	active_map_affix_round = 0
	map_poison_puddle_timer = 0.0
	if pending_map_affix.is_empty():
		return

	active_map_affix = pending_map_affix.duplicate(true)
	active_map_affix_round = current_round
	pending_map_affix.clear()
	map_poison_puddle_timer = MAP_POISON_PUDDLE_INTERVAL


func _complete_active_altar_challenge() -> void:
	if active_map_affix.is_empty() or active_map_affix_round != current_round:
		active_map_affix.clear()
		active_map_affix_round = 0
		return

	active_map_affix.clear()
	active_map_affix_round = 0
	if pending_altar_reward_round == current_round and not pending_altar_blessing.is_empty():
		_grant_altar_blessing(StringName(pending_altar_blessing.get("id", &"")))
		hud_message = "Blessing received: %s." % String(pending_altar_blessing.get("name", "Blessing"))
	pending_altar_blessing.clear()
	pending_altar_reward_round = 0


func _grant_altar_blessing(blessing_id: StringName) -> void:
	if blessing_id == &"" or not is_instance_valid(player):
		return
	if player.has_method("add_altar_blessing"):
		player.add_altar_blessing(blessing_id)


func _apply_starting_map_affix_effects() -> void:
	if StringName(active_map_affix.get("id", &"")) != &"poison_puddles":
		return
	for _index in range(MAP_POISON_PUDDLE_INITIAL_COUNT):
		_spawn_map_poison_puddle()


func _update_active_map_affix(delta: float) -> void:
	if phase != Phase.COMBAT or active_map_affix.is_empty():
		return
	if StringName(active_map_affix.get("id", &"")) != &"poison_puddles":
		return

	map_poison_puddle_timer = maxf(map_poison_puddle_timer - delta, 0.0)
	if map_poison_puddle_timer > 0.0:
		return

	map_poison_puddle_timer = MAP_POISON_PUDDLE_INTERVAL
	_spawn_map_poison_puddle()


func _spawn_map_poison_puddle() -> void:
	var play_area_rect := _get_play_area_rect()
	var margin := 120.0
	var spawn_position := Vector2(
		randf_range(play_area_rect.position.x + margin, play_area_rect.end.x - margin),
		randf_range(play_area_rect.position.y + margin, play_area_rect.end.y - margin)
	)
	var puddle := POISON_PUDDLE_SCRIPT.new() as PoisonPuddle
	puddle.setup(spawn_position, 110.0, 8.0)
	add_child(puddle)


func _apply_current_map_affix_to_enemy(enemy: EnemyBase) -> void:
	if enemy == null or active_map_affix.is_empty():
		return

	var move_multiplier := _get_active_map_affix_value(&"move_speed_multiplier", 1.0)
	if move_multiplier != 1.0:
		enemy.set_map_move_speed_multiplier(move_multiplier)

	var dodge := _get_active_map_affix_value(&"dodge_chance", 0.0)
	if dodge > 0.0:
		enemy.dodge_chance = maxf(enemy.dodge_chance, dodge)

	var damage_multiplier := 1.0
	if enemy.is_elite:
		damage_multiplier = _get_active_map_affix_value(&"elite_damage_multiplier", 1.0)
	else:
		damage_multiplier = _get_active_map_affix_value(&"normal_damage_multiplier", 1.0)
	if damage_multiplier != 1.0:
		_multiply_enemy_damage(enemy, damage_multiplier)


func _multiply_enemy_damage(enemy: EnemyBase, multiplier: float) -> void:
	for property_name in [&"damage", &"melee_damage", &"shout_damage", &"projectile_damage", &"contact_damage", &"explosion_damage"]:
		if not _object_has_property(enemy, property_name):
			continue
		var value: Variant = enemy.get(property_name)
		if value is int or value is float:
			enemy.set(property_name, float(value) * multiplier)


func _object_has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _get_active_map_affix_value(key: StringName, default_value: float) -> float:
	if active_map_affix.is_empty():
		return default_value
	if not active_map_affix.has(key):
		return default_value
	return float(active_map_affix.get(key, default_value))


func _get_altar_offer_text(accepted: bool) -> String:
	var map_affix: Dictionary = altar_offer.get("map_affix", {})
	var blessing: Dictionary = altar_offer.get("blessing", {})
	var prefix := "Accepted" if accepted else "Click altar"
	return "%s\nMap: %s\nReward: %s" % [
		prefix,
		String(map_affix.get("description", "")),
		String(blessing.get("description", "")),
	]


func _get_altar_position() -> Vector2:
	var play_area_rect := _get_play_area_rect()
	return Vector2(
		clampf(ALTAR_POSITION.x, play_area_rect.position.x + 120.0, play_area_rect.end.x - 120.0),
		clampf(ALTAR_POSITION.y, play_area_rect.position.y + 120.0, play_area_rect.end.y - 120.0)
	)


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in range(points):
		var angle := TAU * float(point) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon


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
	if enemy is AcidZombie or enemy is ZombieFireman:
		return ranged_enemy_attack_tokens

	return melee_enemy_attack_tokens


func _get_enemy_attack_token_limit(enemy: EnemyBase) -> int:
	var multiplier := 2 if round_enrage_active else 1
	if enemy is EliteBrute:
		return MAX_ELITE_ENEMY_ATTACK_TOKENS * multiplier
	if enemy is AcidZombie or enemy is ZombieFireman:
		return MAX_RANGED_ENEMY_ATTACK_TOKENS * multiplier

	return MAX_MELEE_ENEMY_ATTACK_TOKENS * multiplier


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
	hud_message = "Shop phase. Click jars to buy items, or press Enter for next round."
	if is_instance_valid(player):
		player.emit_round_ended()
		player.settle_round_level_rewards()
	_complete_active_altar_challenge()
	_spawn_shop_containers()
	_spawn_altar_offer()
	_maybe_show_talent_tree()
	_update_hud()


func _spawn_shop_containers() -> void:
	_clear_shop_containers()
	for index in range(SHOP_CONTAINER_COUNT):
		var position: Vector2 = _get_shop_container_position(index)
		var forced_tier := ShopTier.LEGENDARY if index == 0 and _should_force_legendary_shop_jar() else -1
		var container := _create_shop_container(position, index + 1, -1, forced_tier)
		shop_containers.append(container)
		add_child(container)
	var extra_rare_count: int = player.consume_extra_rare_shop_jars() if is_instance_valid(player) else 0
	for extra_index in range(extra_rare_count):
		var index: int = SHOP_CONTAINER_COUNT + extra_index
		var position: Vector2 = _get_shop_container_position(index)
		var container := _create_shop_container(position, index + 1, ShopCategory.BROWN, ShopTier.RARE)
		shop_containers.append(container)
		add_child(container)


func _should_force_legendary_shop_jar() -> bool:
	return is_instance_valid(player) and player.has_method("has_guaranteed_legendary_shop_jar") and bool(player.has_guaranteed_legendary_shop_jar())


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

	_create_character_card(canvas)
	_create_item_detail_card(canvas)
	_create_pause_overlay(canvas)
	_create_talent_tree_ui()


func _create_character_card(canvas: CanvasLayer) -> void:
	var texture_size := CHARACTER_CARD_TEXTURE.get_size()
	var card_height := CHARACTER_CARD_WIDTH * texture_size.y / texture_size.x
	var card_size := Vector2(CHARACTER_CARD_WIDTH, card_height)

	character_card = Control.new()
	character_card.name = "CharacterCard"
	character_card.position = CHARACTER_CARD_POSITION
	character_card.size = card_size
	character_card.mouse_filter = Control.MOUSE_FILTER_PASS
	canvas.add_child(character_card)

	var background := TextureRect.new()
	background.name = "Background"
	background.texture = CHARACTER_CARD_TEXTURE
	background.position = Vector2.ZERO
	background.size = card_size
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_card.add_child(background)

	character_card_stats_label = Label.new()
	character_card_stats_label.name = "Stats"
	character_card_stats_label.position = Vector2(26, 28)
	character_card_stats_label.size = Vector2(card_size.x - 52, CHARACTER_CARD_TOP_HEIGHT - 34)
	character_card_stats_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.62))
	character_card_stats_label.add_theme_font_size_override("font_size", 17)
	character_card_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_card.add_child(character_card_stats_label)

	var separator := ColorRect.new()
	separator.name = "Separator"
	separator.color = Color(0.72, 0.58, 0.32, 0.72)
	separator.position = Vector2(24, CHARACTER_CARD_TOP_HEIGHT)
	separator.size = Vector2(card_size.x - 48, 2)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_card.add_child(separator)

	var equipment_label := Label.new()
	equipment_label.name = "EquipmentLabel"
	equipment_label.text = "Equipment"
	equipment_label.position = Vector2(26, CHARACTER_CARD_TOP_HEIGHT + 12)
	equipment_label.size = Vector2(card_size.x - 52, 24)
	equipment_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.62))
	equipment_label.add_theme_font_size_override("font_size", 15)
	equipment_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_card.add_child(equipment_label)

	var scroll := ScrollContainer.new()
	scroll.name = "EquipmentScroll"
	scroll.position = Vector2(24, CHARACTER_CARD_TOP_HEIGHT + 42)
	scroll.size = Vector2(card_size.x - 48, card_size.y - CHARACTER_CARD_TOP_HEIGHT - 70)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	character_card.add_child(scroll)

	var scroll_content := VBoxContainer.new()
	scroll_content.name = "EquipmentContent"
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_theme_constant_override("separation", 10)
	scroll.add_child(scroll_content)

	character_card_items_grid = GridContainer.new()
	character_card_items_grid.name = "EquipmentGrid"
	character_card_items_grid.columns = 5
	character_card_items_grid.add_theme_constant_override("h_separation", 7)
	character_card_items_grid.add_theme_constant_override("v_separation", 7)
	character_card_items_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll_content.add_child(character_card_items_grid)

	var blessings_title := Label.new()
	blessings_title.name = "BlessingsLabel"
	blessings_title.text = "Blessings"
	blessings_title.add_theme_color_override("font_color", Color(0.88, 0.82, 0.62))
	blessings_title.add_theme_font_size_override("font_size", 15)
	blessings_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_content.add_child(blessings_title)

	character_card_blessings_label = Label.new()
	character_card_blessings_label.name = "Blessings"
	character_card_blessings_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_card_blessings_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_card_blessings_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.6))
	character_card_blessings_label.add_theme_font_size_override("font_size", 13)
	character_card_blessings_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_content.add_child(character_card_blessings_label)


func _create_item_detail_card(canvas: CanvasLayer) -> void:
	var texture_size := COMMON_ITEM_CARD_TEXTURE.get_size()
	var card_height := ITEM_DETAIL_CARD_WIDTH * texture_size.y / texture_size.x
	var card_size := Vector2(ITEM_DETAIL_CARD_WIDTH, card_height)

	item_detail_card = Control.new()
	item_detail_card.name = "ItemDetailCard"
	item_detail_card.visible = false
	item_detail_card.position = ITEM_DETAIL_CARD_POSITION
	item_detail_card.size = card_size
	item_detail_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(item_detail_card)

	item_detail_card_background = TextureRect.new()
	item_detail_card_background.name = "Background"
	item_detail_card_background.position = Vector2.ZERO
	item_detail_card_background.size = card_size
	item_detail_card_background.stretch_mode = TextureRect.STRETCH_SCALE
	item_detail_card_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_detail_card.add_child(item_detail_card_background)

	item_detail_card_icon = TextureRect.new()
	item_detail_card_icon.name = "Icon"
	item_detail_card_icon.position = (card_size - Vector2(ITEM_DETAIL_CARD_ICON_SIZE, ITEM_DETAIL_CARD_ICON_SIZE)) * 0.5
	item_detail_card_icon.size = Vector2(ITEM_DETAIL_CARD_ICON_SIZE, ITEM_DETAIL_CARD_ICON_SIZE)
	item_detail_card_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_detail_card_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_detail_card_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item_detail_card_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_detail_card.add_child(item_detail_card_icon)

	var text_box_top := card_size.y * 0.63
	var text_box_position := Vector2(ITEM_DETAIL_TEXT_BOX_MARGIN.x, text_box_top)
	var text_box_size := Vector2(
		card_size.x - ITEM_DETAIL_TEXT_BOX_MARGIN.x * 2.0,
		card_size.y - text_box_top - ITEM_DETAIL_TEXT_BOX_MARGIN.y
	)

	item_detail_card_text_box = TextureRect.new()
	item_detail_card_text_box.name = "TextBox"
	item_detail_card_text_box.texture = ITEM_DETAIL_TEXT_BOX_TEXTURE
	item_detail_card_text_box.position = text_box_position
	item_detail_card_text_box.size = text_box_size
	item_detail_card_text_box.stretch_mode = TextureRect.STRETCH_SCALE
	item_detail_card_text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_detail_card.add_child(item_detail_card_text_box)

	item_detail_card_name_label = Label.new()
	item_detail_card_name_label.name = "Name"
	item_detail_card_name_label.position = text_box_position + Vector2(16, 13)
	item_detail_card_name_label.size = Vector2(text_box_size.x - 32, 30)
	item_detail_card_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_detail_card_name_label.add_theme_font_size_override("font_size", 18)
	item_detail_card_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_detail_card.add_child(item_detail_card_name_label)

	item_detail_card_description_label = Label.new()
	item_detail_card_description_label.name = "Description"
	item_detail_card_description_label.position = text_box_position + Vector2(18, 46)
	item_detail_card_description_label.size = Vector2(text_box_size.x - 36, text_box_size.y - 58)
	item_detail_card_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_detail_card_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	item_detail_card_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_detail_card_description_label.add_theme_font_size_override("font_size", 14)
	item_detail_card_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_detail_card.add_child(item_detail_card_description_label)


func _create_pause_overlay(canvas: CanvasLayer) -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(pause_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.58)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(shade)

	var panel := Panel.new()
	panel.position = Vector2(720, 390)
	panel.size = Vector2(480, 260)
	pause_overlay.add_child(panel)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(24, 42)
	title.size = Vector2(432, 70)
	title.add_theme_font_size_override("font_size", 42)
	panel.add_child(title)

	var hint := Label.new()
	hint.text = "Press Esc to resume"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.position = Vector2(24, 132)
	hint.size = Vector2(432, 70)
	hint.add_theme_font_size_override("font_size", 24)
	panel.add_child(hint)


func _create_pause_input_controller() -> void:
	pause_input_controller = PAUSE_INPUT_CONTROLLER.new() as Node
	pause_input_controller.name = "PauseInputController"
	pause_input_controller.resume_requested.connect(_on_pause_resume_requested)
	add_child(pause_input_controller)


func _on_pause_resume_requested() -> void:
	_set_paused(false)


func _set_paused(paused: bool) -> void:
	if game_over and paused:
		return
	get_tree().paused = paused
	if pause_overlay != null:
		pause_overlay.visible = paused


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


func _on_player_hp_changed(_current_hp: int, _max_hp: int) -> void:
	_update_hud()


func _on_player_progress_changed(_current_exp: int, _required_exp: int, _level: int) -> void:
	_update_hud()


func _on_player_talent_points_changed(_unspent_points: int, _pending_points: int) -> void:
	_update_talent_tree_ui()
	_update_hud()


func _on_player_talent_unlocked(_node_id: StringName) -> void:
	_refresh_play_area_from_player()
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

	var map_label := "None"
	if not active_map_affix.is_empty():
		map_label = String(active_map_affix.get("name", "Challenge"))
	var blessing_count := 0
	if is_instance_valid(player) and player.has_method("get_altar_blessing_count"):
		blessing_count = int(player.get_altar_blessing_count())

	hud_label.text = "Round: %d/%d   Phase: %s   Gold: %d   HP: %d   Lv: %d   EXP: %d/%d   Talent: %d   Map: %s   Blessings: %d   %s: %d   Zombies: %d%s" % [
		current_round,
		MAX_ROUNDS,
		phase_label,
		gold,
		hp,
		level,
		experience,
		required_experience,
		unspent_talents,
		map_label,
		blessing_count,
		objective_label,
		objective_count,
		enemies.size(),
		prompt,
	]
	_update_character_card()


func _update_character_card() -> void:
	if character_card_stats_label == null or character_card_items_grid == null:
		return

	var hp := 0
	var max_hp := 0
	var level := 1
	var experience := 0
	var required_experience := 10
	var atk := 0
	var defense := 0
	if is_instance_valid(player):
		hp = int(ceil(player.hp))
		max_hp = int(ceil(player.max_hp))
		level = player.level
		experience = player.experience
		required_experience = player.get_required_exp_for_next_level()
		if player.stats != null:
			atk = player.stats.atk
			defense = player.stats.defense

	character_card_stats_label.text = "HP       %d/%d\nLevel    %d\nEXP      %d/%d\nATK      %d\nDEF      %d" % [
		hp,
		max_hp,
		level,
		experience,
		required_experience,
		atk,
		defense,
	]
	_rebuild_character_card_items()


func _rebuild_character_card_items() -> void:
	var signature := _get_character_card_items_signature()
	if signature == character_card_items_signature:
		return

	character_card_items_signature = signature
	_hide_item_detail_card()
	for child in character_card_items_grid.get_children():
		child.queue_free()

	if not is_instance_valid(player) or player.inventory == null:
		_update_character_card_blessings()
		return

	var item_ids: Array = player.inventory.item_definitions_by_id.keys()
	item_ids.sort()
	for item_id in item_ids:
		var count := player.inventory.get_item_count(item_id)
		if count <= 0:
			continue
		var item := player.inventory.item_definitions_by_id.get(item_id) as ItemDefinition
		if item == null:
			continue
		character_card_items_grid.add_child(_create_character_card_item_icon(item, count))
	_update_character_card_blessings()


func _create_character_card_item_icon(item: ItemDefinition, count: int) -> Control:
	var cell := Control.new()
	cell.custom_minimum_size = Vector2(CHARACTER_CARD_ICON_SIZE, CHARACTER_CARD_ICON_SIZE)
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.mouse_entered.connect(_show_item_detail_card.bind(item))
	cell.mouse_exited.connect(_hide_item_detail_card)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2.ZERO
	icon.size = Vector2(CHARACTER_CARD_ICON_SIZE, CHARACTER_CARD_ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)

	if count > 1:
		var count_label := Label.new()
		count_label.text = str(count)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.position = Vector2(0, CHARACTER_CARD_ICON_SIZE - 15)
		count_label.size = Vector2(CHARACTER_CARD_ICON_SIZE, 15)
		count_label.add_theme_color_override("font_color", Color(0.98, 0.9, 0.62))
		count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.01))
		count_label.add_theme_constant_override("outline_size", 3)
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(count_label)

	return cell


func _get_character_card_items_signature() -> String:
	if not is_instance_valid(player):
		return ""

	var parts: Array[String] = []
	if player.inventory != null:
		var item_ids: Array = player.inventory.item_definitions_by_id.keys()
		item_ids.sort()
		for item_id in item_ids:
			var count := player.inventory.get_item_count(item_id)
			if count > 0:
				parts.append("item:%s:%d" % [String(item_id), count])
	var blessing_ids: Array = player.altar_blessings.keys()
	blessing_ids.sort()
	for blessing_id in blessing_ids:
		var count := int(player.altar_blessings.get(blessing_id, 0))
		if count > 0:
			parts.append("blessing:%s:%d" % [String(blessing_id), count])
	return "|".join(parts)


func _update_character_card_blessings() -> void:
	if character_card_blessings_label == null:
		return
	if not is_instance_valid(player) or player.altar_blessings.is_empty():
		character_card_blessings_label.text = "None"
		return

	var lines: Array[String] = []
	var blessing_ids: Array = player.altar_blessings.keys()
	blessing_ids.sort()
	for blessing_id in blessing_ids:
		var count := int(player.altar_blessings.get(blessing_id, 0))
		if count <= 0:
			continue
		var display_name := _get_altar_blessing_display_name(StringName(blessing_id))
		if count > 1:
			display_name += " x%d" % count
		lines.append(display_name)
	character_card_blessings_label.text = "None" if lines.is_empty() else "\n".join(lines)


func _get_altar_blessing_display_name(blessing_id: StringName) -> String:
	for blessing in ALTAR_BLESSINGS:
		if StringName(blessing.get("id", &"")) == blessing_id:
			return String(blessing.get("name", String(blessing_id)))
	return String(blessing_id)


func _show_item_detail_card(item: ItemDefinition) -> void:
	if item == null or item_detail_card == null:
		return

	var rarity := String(item.rarity)
	item_detail_card_background.texture = _get_item_detail_card_texture(rarity)
	item_detail_card_icon.texture = item.icon
	item_detail_card_name_label.text = item.display_name
	item_detail_card_description_label.text = item.description
	_apply_item_detail_card_text_colors(rarity)
	item_detail_card.visible = true


func _hide_item_detail_card() -> void:
	if item_detail_card != null:
		item_detail_card.visible = false


func _get_item_detail_card_texture(rarity: String) -> Texture2D:
	match rarity:
		"legendary":
			return LEGENDARY_ITEM_CARD_TEXTURE
		"rare":
			return RARE_ITEM_CARD_TEXTURE
		_:
			return COMMON_ITEM_CARD_TEXTURE


func _apply_item_detail_card_text_colors(_rarity: String) -> void:
	var text_color := Color(0.0, 0.0, 0.0)

	item_detail_card_name_label.add_theme_color_override("font_color", text_color)
	item_detail_card_name_label.add_theme_constant_override("outline_size", 0)
	item_detail_card_description_label.add_theme_color_override("font_color", text_color)
	item_detail_card_description_label.add_theme_constant_override("outline_size", 0)


func _check_defeat() -> void:
	if not is_instance_valid(player):
		_lose_game()


func _check_combat_clear() -> void:
	if phase != Phase.COMBAT or game_over or shop_transition_pending:
		return

	if containers.is_empty() and enemies.is_empty() and not _has_enemy_nodes_in_scene():
		shop_transition_pending = true
		call_deferred("_enter_shop_phase")


func _has_enemy_nodes_in_scene() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			return true
	return false


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


func _update_round_enrage(delta: float) -> void:
	if phase != Phase.COMBAT:
		return
	if not auto_break_triggered or not containers.is_empty() or enemies.is_empty():
		return

	if not round_enrage_active:
		round_enrage_active = true
		round_enrage_elapsed = 0.0
		hud_message = "Surviving zombies are enraging."

	round_enrage_elapsed += delta
	var speed_multiplier := _get_round_enrage_speed_multiplier()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.set_round_enrage_multiplier(speed_multiplier)


func _get_round_enrage_speed_multiplier() -> float:
	var speed_bonus := minf(
		round_enrage_elapsed * ROUND_ENRAGE_SPEED_GAIN_PER_SECOND,
		ROUND_ENRAGE_MAX_SPEED_BONUS
	)
	return 1.0 + speed_bonus


func _apply_current_round_enrage_to_enemy(enemy: EnemyBase) -> void:
	if not is_instance_valid(enemy):
		return
	var speed_multiplier := _get_round_enrage_speed_multiplier() if round_enrage_active else 1.0
	enemy.set_round_enrage_multiplier(speed_multiplier)


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


func _apply_shop_tier_price_multiplier(base_price: int, tier: int) -> int:
	var multiplier := 1.0
	if is_instance_valid(player) and player.has_method("get_shop_tier_price_multiplier"):
		multiplier = float(player.get_shop_tier_price_multiplier(tier))
	return maxi(1, int(round(float(base_price) * multiplier)))


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
