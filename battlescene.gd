extends Node2D

const SCREEN_SIZE := Vector2(1920, 1080)
const PLAY_AREA_SIZE := Vector2(1500, 1500)
const PLAY_AREA_CENTER := Vector2(960, 540)
const PLAY_AREA_RECT := Rect2(PLAY_AREA_CENTER - PLAY_AREA_SIZE * 0.5, PLAY_AREA_SIZE)
const CAMERA_VISIBLE_SIZE := Vector2(1600, 900)
const CAMERA_ZOOM := Vector2(SCREEN_SIZE.x / CAMERA_VISIBLE_SIZE.x, SCREEN_SIZE.y / CAMERA_VISIBLE_SIZE.y)
const PLAYER_POSITION := PLAY_AREA_CENTER + Vector2(-500, 0)
const MAX_ROUNDS := 10
const ROUND_CONTAINER_AUTO_BREAK_TIME := 30.0

const CONTAINER_COUNT := 40
const GRID_SIZE := 15
const CONTAINER_GRID_MIN_INDEX := 3
const CONTAINER_GRID_MAX_INDEX := 10
const CONTAINER_CLUSTER_RADIUS_CELLS := 4.5
const CONTAINER_EDGE_FALLOFF := 2.2
const CONTAINER_COLLISION_RADIUS := 18.0
const URN_MAX_HP := 12.0
const BARREL_MAX_HP := 24.0
const TOMB_MAX_HP := 48.0

const SHOP_CONTAINER_COUNT := 3
const SHOP_CONTAINER_START := PLAY_AREA_CENTER + Vector2(-150, 120)
const SHOP_CONTAINER_SPACING := Vector2(150, 0)
const SHOP_CONTAINER_MAX_HP := 12.0

const MELEE_ZOMBIE_GOLD := 3
const ACID_ZOMBIE_GOLD := 4
const ELITE_BRUTE_GOLD := 12

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const MELEE_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/ZombieMelee.tscn")
const ACID_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/AcidZombie.tscn")
const ELITE_BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/EliteBrute.tscn")
const URN_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-main-static-00.png")
const URN_DAMAGED_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-crack-00.png")
const URN_HIT_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-crack-hit-00.png")
const URN_DESTROYED_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-static-destroyed-00.png")
const BARREL_TEXTURE: Texture2D = preload("res://assets/containers/Barrel B/barrel-B-main-static-00.png")
const BARREL_HIT_TEXTURE: Texture2D = preload("res://assets/containers/Barrel B/barrel-B-hit-00.png")
const BARREL_DESTROYED_TEXTURE: Texture2D = preload("res://assets/containers/Barrel B/barrel-B-static-destroyed-00.png")
const TOMB_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-main-static-00.png")
const TOMB_DAMAGED_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-crack-1-00.png")
const TOMB_HIT_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-main-hit-00.png")
const TOMB_DESTROYED_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-static-destroyed-00.png")

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
var enemy_gold_rewards: Dictionary = {}
var phase: int = Phase.COMBAT
var current_round: int = 1
var gold: int = 0
var game_over: bool = false
var hud_message: String = ""
var round_time_remaining: float = 0.0
var auto_break_triggered: bool = false
var shop_transition_pending: bool = false

var player: Player
var camera: Camera2D
var hud_label: Label
var status_panel: Panel
var status_label: Label
var talent_tree_layer: CanvasLayer
var talent_tree_panel: Panel
var talent_point_label: Label
var talent_buttons: Dictionary = {}


func _ready() -> void:
	randomize()
	_create_background()
	_spawn_player()
	_create_camera()
	_create_hud()
	_start_combat_round()


func _process(delta: float) -> void:
	if game_over:
		return

	_update_round_timer(delta)
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

	var background := ColorRect.new()
	background.name = "PlayableArea"
	background.color = Color(0.16, 0.2, 0.18)
	background.position = PLAY_AREA_RECT.position
	background.size = PLAY_AREA_RECT.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -100
	add_child(background)

	var border := Line2D.new()
	border.name = "PlayableAreaBorder"
	border.default_color = Color(0.36, 0.44, 0.38)
	border.width = 4.0
	border.z_index = -90
	border.add_point(PLAY_AREA_RECT.position)
	border.add_point(Vector2(PLAY_AREA_RECT.end.x, PLAY_AREA_RECT.position.y))
	border.add_point(PLAY_AREA_RECT.end)
	border.add_point(Vector2(PLAY_AREA_RECT.position.x, PLAY_AREA_RECT.end.y))
	border.add_point(PLAY_AREA_RECT.position)
	add_child(border)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.name = "Player"
	player.global_position = PLAYER_POSITION
	player.movement_bounds_enabled = true
	player.movement_bounds = PLAY_AREA_RECT
	player.experience_changed.connect(_on_player_progress_changed)
	player.talent_points_changed.connect(_on_player_talent_points_changed)
	player.talent_unlocked.connect(_on_player_talent_unlocked)
	add_child(player)


func _create_camera() -> void:
	camera = Camera2D.new()
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


func _start_combat_round() -> void:
	phase = Phase.COMBAT
	round_time_remaining = ROUND_CONTAINER_AUTO_BREAK_TIME
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
	var positions: Array[Vector2] = _roll_combat_container_positions()
	for index in range(CONTAINER_COUNT):
		var container_position: Vector2 = positions[index]
		var container_type: int = _roll_combat_container_type()
		var container := _create_combat_container(container_position, index + 1, container_type)
		containers.append(container)
		add_child(container)


func _roll_combat_container_positions() -> Array[Vector2]:
	var candidates: Array[Dictionary] = []
	var grid_cell_size: Vector2 = PLAY_AREA_SIZE / float(GRID_SIZE)
	var center_cell: Vector2 = Vector2(
		(float(CONTAINER_GRID_MIN_INDEX) + float(CONTAINER_GRID_MAX_INDEX) + 1.0) * 0.5,
		(float(CONTAINER_GRID_MIN_INDEX) + float(CONTAINER_GRID_MAX_INDEX) + 1.0) * 0.5
	)
	for row in range(CONTAINER_GRID_MIN_INDEX, CONTAINER_GRID_MAX_INDEX + 1):
		for column in range(CONTAINER_GRID_MIN_INDEX, CONTAINER_GRID_MAX_INDEX + 1):
			var cell_center := Vector2(column + 0.5, row + 0.5)
			var normalized_distance: float = cell_center.distance_to(center_cell) / CONTAINER_CLUSTER_RADIUS_CELLS
			var circular_bias: float = maxf(0.0, 1.0 - pow(normalized_distance, CONTAINER_EDGE_FALLOFF))
			var noise_bias: float = randf_range(0.65, 1.45)
			var weight: float = (0.03 + circular_bias * circular_bias) * noise_bias
			var position: Vector2 = PLAY_AREA_RECT.position + cell_center * grid_cell_size
			position += Vector2(
				randf_range(-grid_cell_size.x * 0.38, grid_cell_size.x * 0.38),
				randf_range(-grid_cell_size.y * 0.38, grid_cell_size.y * 0.38)
			)
			candidates.append({
				"position": position,
				"weight": weight,
			})

	var positions: Array[Vector2] = []
	for _index in range(CONTAINER_COUNT):
		if candidates.is_empty():
			break
		var candidate_index: int = _pick_weighted_candidate_index(candidates)
		positions.append(candidates[candidate_index]["position"])
		candidates.remove_at(candidate_index)
	return positions


func _pick_weighted_candidate_index(candidates: Array[Dictionary]) -> int:
	var total_weight: float = 0.0
	for candidate in candidates:
		total_weight += float(candidate["weight"])

	var roll: float = randf() * total_weight
	var running_weight: float = 0.0
	for index in range(candidates.size()):
		running_weight += float(candidates[index]["weight"])
		if roll <= running_weight:
			return index

	return candidates.size() - 1


func _roll_combat_container_type() -> int:
	var roll: float = randf()
	if roll < 0.7:
		return ContainerType.URN
	if roll < 0.95:
		return ContainerType.BARREL
	return ContainerType.TOMB


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
	container.static_texture = URN_TEXTURE
	container.damaged_texture = URN_DAMAGED_TEXTURE
	container.hit_texture = URN_HIT_TEXTURE
	container.destroyed_texture = URN_DESTROYED_TEXTURE
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
	container.z_index = 5

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := CircleShape2D.new()
	shape.radius = CONTAINER_COLLISION_RADIUS
	collision.shape = shape
	container.add_child(collision)
	return container


func _add_container_sprite(container: BreakableContainer, modulate_color: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = container.static_texture
	sprite.centered = true
	sprite.modulate = modulate_color
	container.add_child(sprite)


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


func _on_container_break_finished(_container: BreakableContainer, container_type: int, spawn_position: Vector2) -> void:
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


func _get_enemy_gold_reward(enemy: EnemyBase) -> int:
	if enemy is EliteBrute:
		return ELITE_BRUTE_GOLD
	if enemy is AcidZombie:
		return ACID_ZOMBIE_GOLD
	return MELEE_ZOMBIE_GOLD


func _on_enemy_died(enemy: EnemyBase) -> void:
	enemies.erase(enemy)
	var reward: int = int(enemy_gold_rewards.get(enemy, MELEE_ZOMBIE_GOLD))
	enemy_gold_rewards.erase(enemy)
	gold += reward
	if is_instance_valid(player):
		player.gain_experience(reward)
	hud_message = "+%d gold, +%d EXP" % [reward, reward]
	_update_hud()
	_check_combat_clear()


func _enter_shop_phase() -> void:
	if phase != Phase.COMBAT or game_over:
		return

	shop_transition_pending = false
	phase = Phase.SHOP
	round_time_remaining = 0.0
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
		var position: Vector2 = SHOP_CONTAINER_START + SHOP_CONTAINER_SPACING * float(index)
		var container := _create_shop_container(position, index + 1)
		shop_containers.append(container)
		add_child(container)
	var extra_rare_count: int = player.consume_extra_rare_shop_jars() if is_instance_valid(player) else 0
	for extra_index in range(extra_rare_count):
		var index: int = SHOP_CONTAINER_COUNT + extra_index
		var position: Vector2 = SHOP_CONTAINER_START + SHOP_CONTAINER_SPACING * float(index)
		var container := _create_shop_container(position, index + 1, ShopCategory.BROWN, ShopTier.RARE)
		shop_containers.append(container)
		add_child(container)


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
	talent_tree_layer = CanvasLayer.new()
	talent_tree_layer.name = "TalentTreeLayer"
	talent_tree_layer.layer = 30
	talent_tree_layer.visible = false
	add_child(talent_tree_layer)

	var blocker := ColorRect.new()
	blocker.name = "Blocker"
	blocker.color = Color(0.0, 0.0, 0.0, 0.58)
	blocker.position = Vector2.ZERO
	blocker.size = SCREEN_SIZE
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	talent_tree_layer.add_child(blocker)

	talent_tree_panel = Panel.new()
	talent_tree_panel.name = "TalentTreePanel"
	talent_tree_panel.position = Vector2(600, 72)
	talent_tree_panel.size = Vector2(720, 936)
	talent_tree_layer.add_child(talent_tree_panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "Talent Tree"
	title.position = Vector2(32, 22)
	title.size = Vector2(360, 32)
	title.add_theme_font_size_override("font_size", 24)
	talent_tree_panel.add_child(title)

	talent_point_label = Label.new()
	talent_point_label.name = "TalentPointLabel"
	talent_point_label.position = Vector2(32, 58)
	talent_point_label.size = Vector2(360, 28)
	talent_tree_panel.add_child(talent_point_label)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.position = Vector2(588, 24)
	close_button.size = Vector2(96, 34)
	close_button.pressed.connect(_hide_talent_tree)
	talent_tree_panel.add_child(close_button)

	var graph := Control.new()
	graph.name = "Graph"
	graph.position = Vector2(0, 96)
	graph.size = Vector2(720, 820)
	graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	talent_tree_panel.add_child(graph)

	_add_talent_connection_lines(graph)
	_add_talent_buttons(graph)
	_update_talent_tree_ui()


func _add_talent_connection_lines(graph: Control) -> void:
	if not is_instance_valid(player):
		return

	for connection in player.get_talent_connections():
		var from_id: StringName = connection[0]
		var to_id: StringName = connection[1]
		var from_position: Vector2 = _get_talent_ui_position(player.get_talent_node_grid_position(from_id))
		var to_position: Vector2 = _get_talent_ui_position(player.get_talent_node_grid_position(to_id))
		var line := ColorRect.new()
		line.name = "TalentConnection"
		line.color = Color(0.42, 0.48, 0.44, 0.85)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if absf(from_position.x - to_position.x) < 0.1:
			line.position = Vector2(from_position.x - 2.0, minf(from_position.y, to_position.y))
			line.size = Vector2(4.0, absf(from_position.y - to_position.y))
		else:
			line.position = Vector2(minf(from_position.x, to_position.x), from_position.y - 2.0)
			line.size = Vector2(absf(from_position.x - to_position.x), 4.0)
		graph.add_child(line)


func _add_talent_buttons(graph: Control) -> void:
	if not is_instance_valid(player):
		return

	talent_buttons.clear()
	for node_id in player.get_talent_node_ids():
		var button := Button.new()
		button.name = String(node_id)
		button.text = player.get_talent_display_name(node_id)
		button.tooltip_text = player.get_talent_description(node_id)
		button.position = _get_talent_ui_position(player.get_talent_node_grid_position(node_id)) - Vector2(24, 24)
		button.size = Vector2(48, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_talent_button_pressed.bind(node_id))
		graph.add_child(button)
		talent_buttons[node_id] = button


func _get_talent_ui_position(coord: Vector2i) -> Vector2:
	var spacing := Vector2(78.0, 86.0)
	var center_x: float = 360.0
	var bottom_y: float = 716.0
	return Vector2(
		center_x + (float(coord.x) - 2.5) * spacing.x,
		bottom_y - float(coord.y) * spacing.y
	)


func _on_talent_button_pressed(node_id: StringName) -> void:
	if not is_instance_valid(player):
		return

	if player.unlock_talent(node_id):
		hud_message = "Unlocked +1 ATK."
	_update_talent_tree_ui()
	_update_hud()


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
	if talent_tree_layer == null:
		return
	talent_tree_layer.visible = true
	_update_talent_tree_ui()


func _hide_talent_tree() -> void:
	if talent_tree_layer == null:
		return
	talent_tree_layer.visible = false


func _is_talent_tree_open() -> bool:
	return talent_tree_layer != null and talent_tree_layer.visible


func _update_talent_tree_ui() -> void:
	if talent_point_label == null or not is_instance_valid(player):
		return

	talent_point_label.text = "Unspent Talent Points: %d" % player.unspent_talent_points
	for node_id in talent_buttons.keys():
		var button := talent_buttons[node_id] as Button
		if button == null:
			continue

		var unlocked: bool = player.unlocked_talents.has(node_id)
		var can_unlock: bool = player.can_unlock_talent(node_id)
		button.disabled = unlocked or not can_unlock
		if unlocked:
			button.modulate = Color(1.0, 0.86, 0.32)
		elif can_unlock:
			button.modulate = Color(0.42, 0.92, 0.58)
		else:
			button.modulate = Color(0.44, 0.48, 0.48)


func _cleanup_enemy_list() -> void:
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			enemy_gold_rewards.erase(enemy)


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


func _auto_break_remaining_containers() -> void:
	auto_break_triggered = true
	hud_message = "Time is up. Remaining containers broke open."
	for container in containers.duplicate():
		if is_instance_valid(container) and not container.is_breaking:
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


func _clear_shop_containers() -> void:
	for container in shop_containers:
		if is_instance_valid(container):
			container.queue_free()
	shop_containers.clear()
	shop_container_data.clear()


func _roll_shop_category() -> int:
	if randf() < 0.7:
		return ShopCategory.BROWN

	var categories: Array[int] = [
		ShopCategory.ATTACK,
		ShopCategory.DEFENSE,
		ShopCategory.UTILITY,
	]
	return categories.pick_random()


func _roll_shop_tier() -> int:
	var roll: float = randf()
	if roll < 0.89:
		return ShopTier.COMMON
	if roll < 0.99:
		return ShopTier.RARE
	return ShopTier.LEGENDARY


func _roll_item_rarity_for_tier(tier: int) -> StringName:
	var roll: float = randf()
	match tier:
		ShopTier.RARE:
			return &"rare" if roll < 0.95 else &"legendary"
		ShopTier.LEGENDARY:
			return &"legendary"
		_:
			if roll < 0.89:
				return &"common"
			if roll < 0.99:
				return &"rare"
			return &"legendary"


func _roll_shop_item(category: int, rarity: StringName) -> ItemDefinition:
	var database := get_node_or_null("/root/ItemDatabase")
	if database == null:
		return null

	var category_filter: StringName = _get_shop_category_filter(category)
	var item: ItemDefinition = database.get_random_item(category_filter, rarity)
	if item != null:
		return item

	item = database.get_random_item(&"", rarity)
	if item != null:
		return item

	return database.get_random_item()


func _get_shop_price(category: int, tier: int) -> int:
	var is_brown: bool = category == ShopCategory.BROWN
	match tier:
		ShopTier.RARE:
			return 30 if is_brown else 36
		ShopTier.LEGENDARY:
			return 75 if is_brown else 90
		_:
			return 12 if is_brown else 15


func _get_discounted_shop_price(category: int, tier: int) -> int:
	return _apply_shop_price_discount(_get_shop_price(category, tier))


func _apply_shop_price_discount(base_price: int) -> int:
	var price: int = base_price
	if is_instance_valid(player):
		price = maxi(1, floori(float(price) * player.get_shop_price_multiplier()))
	return price


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
	match category:
		ShopCategory.ATTACK:
			return &"attack"
		ShopCategory.DEFENSE:
			return &"defense"
		ShopCategory.UTILITY:
			return &"utility"
		_:
			return &""


func _get_shop_category_color(category: int) -> Color:
	match category:
		ShopCategory.ATTACK:
			return Color(1.0, 0.38, 0.32)
		ShopCategory.DEFENSE:
			return Color(0.38, 1.0, 0.48)
		ShopCategory.UTILITY:
			return Color(0.42, 0.68, 1.0)
		_:
			return Color(0.74, 0.52, 0.34)


func _get_shop_category_label(category: int) -> String:
	match category:
		ShopCategory.ATTACK:
			return "Red"
		ShopCategory.DEFENSE:
			return "Green"
		ShopCategory.UTILITY:
			return "Blue"
		_:
			return "Brown"


func _get_shop_tier_label(tier: int) -> String:
	match tier:
		ShopTier.RARE:
			return "Rare"
		ShopTier.LEGENDARY:
			return "Legend"
		_:
			return "Common"


func _get_container_texture(container_type: int) -> Texture2D:
	match container_type:
		ContainerType.BARREL:
			return BARREL_TEXTURE
		ContainerType.TOMB:
			return TOMB_TEXTURE
		_:
			return URN_TEXTURE


func _get_container_damaged_texture(container_type: int) -> Texture2D:
	match container_type:
		ContainerType.TOMB:
			return TOMB_DAMAGED_TEXTURE
		ContainerType.URN:
			return URN_DAMAGED_TEXTURE
		_:
			return null


func _get_container_hit_texture(container_type: int) -> Texture2D:
	match container_type:
		ContainerType.BARREL:
			return BARREL_HIT_TEXTURE
		ContainerType.TOMB:
			return TOMB_HIT_TEXTURE
		_:
			return URN_HIT_TEXTURE


func _get_container_destroyed_texture(container_type: int) -> Texture2D:
	match container_type:
		ContainerType.BARREL:
			return BARREL_DESTROYED_TEXTURE
		ContainerType.TOMB:
			return TOMB_DESTROYED_TEXTURE
		_:
			return URN_DESTROYED_TEXTURE


func _get_container_destroy_frames(container_type: int) -> Array[Texture2D]:
	match container_type:
		ContainerType.BARREL:
			return [
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-01.png"),
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-02.png"),
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-03.png"),
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-04.png"),
			]
		ContainerType.TOMB:
			return [
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-01.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-02.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-03.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-04.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-05.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-06.png"),
			]
		_:
			return [
				preload("res://assets/containers/Urn G/urn-G-destr-anim-01.png"),
				preload("res://assets/containers/Urn G/urn-G-destr-anim-02.png"),
				preload("res://assets/containers/Urn G/urn-G-destr-anim-03.png"),
				preload("res://assets/containers/Urn G/urn-G-destr-anim-04.png"),
			]


func _get_container_max_hp(container_type: int) -> float:
	match container_type:
		ContainerType.BARREL:
			return BARREL_MAX_HP
		ContainerType.TOMB:
			return TOMB_MAX_HP
		_:
			return URN_MAX_HP


func _get_container_type_name(container_type: int) -> String:
	match container_type:
		ContainerType.BARREL:
			return "Barrel"
		ContainerType.TOMB:
			return "Tomb"
		_:
			return "Urn"
