extends Node2D

const SCREEN_SIZE = Vector2(1152, 648)
const PLAYER_POSITION = Vector2(120, 330)
const PLAYER_MAX_HEALTH = 100.0
const PLAYER_SPEED = 230.0
const PLAYER_MIN_POSITION = Vector2(45, 95)
const PLAYER_MAX_POSITION = Vector2(1105, 455)

const PROJECTILE_SPEED = 720.0
const PROJECTILE_LIFETIME = 1.35
const PROJECTILE_DAMAGE = 18.0
const PROJECTILE_FIRE_INTERVAL = 0.28
const PROJECTILE_RADIUS = 6.0
const PROJECTILE_JAR_HIT_RADIUS = 34.0
const PROJECTILE_ZOMBIE_HIT_RADIUS = 26.0

const JAR_COUNT = 25
const JAR_HIT_SIZE = Vector2(52, 64)

const ZOMBIE_MAX_HEALTH = 35.0
const ZOMBIE_SPEED = 92.0
const ZOMBIE_ATTACK_RANGE = 46.0
const ZOMBIE_ATTACK_DAMAGE = 8.0
const ZOMBIE_ATTACK_INTERVAL = 0.95

const ZOMBIE_COLOR = Color(0.52, 0.56, 0.46)
const JAR_COLOR = Color(0.72, 0.46, 0.24)
const PLAYER_COLOR = Color(0.22, 0.43, 0.80)

var jars: Array[Node2D] = []
var zombies: Array = []
var projectiles: Array = []

var player_health = PLAYER_MAX_HEALTH
var game_over = false
var fire_cooldown = 0.0
var is_firing = false

var player_node: Node2D
var hud_label: Label
var status_panel: Panel
var status_label: Label
var player_health_fill: ColorRect


func _ready() -> void:
	randomize()
	_setup_scene()
	_spawn_jars()
	_update_hud()


func _process(delta: float) -> void:
	if game_over:
		return

	_update_player_movement(delta)
	_update_player_fire(delta)
	_update_projectiles(delta)
	_update_zombies(delta)
	_update_hud()
	_check_victory()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R and game_over:
			get_tree().reload_current_scene()
			return

	if game_over:
		is_firing = false
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_firing = event.pressed


func _setup_scene() -> void:
	_create_background()
	_create_player_base()
	_create_hud()
	_set_control_mouse_filters(self)


func _create_background() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.73, 0.86, 0.93)
	sky.size = SCREEN_SIZE
	sky.z_index = -100
	add_child(sky)

	var ground := ColorRect.new()
	ground.color = Color(0.31, 0.48, 0.29)
	ground.position = Vector2(0, 470)
	ground.size = Vector2(SCREEN_SIZE.x, SCREEN_SIZE.y - ground.position.y)
	ground.z_index = -90
	add_child(ground)

	var lane := ColorRect.new()
	lane.color = Color(0.52, 0.62, 0.42)
	lane.position = Vector2(0, 255)
	lane.size = Vector2(SCREEN_SIZE.x, 210)
	lane.z_index = -80
	add_child(lane)


func _create_player_base() -> void:
	player_node = Node2D.new()
	player_node.name = "PlayerBase"
	player_node.position = PLAYER_POSITION
	player_node.z_index = 10
	add_child(player_node)

	var body := ColorRect.new()
	body.color = PLAYER_COLOR
	body.position = Vector2(-38, -64)
	body.size = Vector2(76, 128)
	player_node.add_child(body)

	var top := ColorRect.new()
	top.color = Color(0.14, 0.27, 0.52)
	top.position = Vector2(-48, -76)
	top.size = Vector2(96, 20)
	player_node.add_child(top)

	var label := Label.new()
	label.text = "PLAYER"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-48, -14)
	label.size = Vector2(96, 28)
	player_node.add_child(label)

	var health_bg := ColorRect.new()
	health_bg.color = Color(0.08, 0.10, 0.10)
	health_bg.position = Vector2(-48, 76)
	health_bg.size = Vector2(96, 10)
	player_node.add_child(health_bg)

	player_health_fill = ColorRect.new()
	player_health_fill.color = Color(0.22, 0.86, 0.31)
	player_health_fill.position = Vector2(-46, 78)
	player_health_fill.size = Vector2(92, 6)
	player_node.add_child(player_health_fill)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)

	var hud_bg := ColorRect.new()
	hud_bg.color = Color(0.04, 0.06, 0.07, 0.72)
	hud_bg.position = Vector2(18, 16)
	hud_bg.size = Vector2(370, 42)
	canvas.add_child(hud_bg)

	hud_label = Label.new()
	hud_label.position = Vector2(30, 22)
	hud_label.size = Vector2(350, 30)
	canvas.add_child(hud_label)

	status_panel = Panel.new()
	status_panel.visible = false
	status_panel.position = Vector2(356, 240)
	status_panel.size = Vector2(440, 150)
	canvas.add_child(status_panel)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.position = Vector2(16, 12)
	status_label.size = Vector2(408, 126)
	status_panel.add_child(status_label)


func _spawn_jars() -> void:
	var start := Vector2(470, 95)
	var spacing := Vector2(105, 82)
	var columns := 5

	for index in range(JAR_COUNT):
		var row := int(index / columns)
		var column := index % columns
		var jar_position := start + Vector2(column * spacing.x, row * spacing.y)
		jars.append(_create_jar(jar_position, index + 1))


func _create_jar(jar_position: Vector2, jar_number: int) -> Node2D:
	var jar := Node2D.new()
	jar.name = "Jar%d" % jar_number
	jar.position = jar_position
	jar.z_index = 5
	add_child(jar)

	var body := Polygon2D.new()
	body.color = JAR_COLOR
	body.polygon = PackedVector2Array([
		Vector2(-24, -20),
		Vector2(-16, -32),
		Vector2(16, -32),
		Vector2(24, -20),
		Vector2(20, 28),
		Vector2(-20, 28),
	])
	jar.add_child(body)

	var lid := ColorRect.new()
	lid.color = Color(0.41, 0.24, 0.13)
	lid.position = Vector2(-18, -42)
	lid.size = Vector2(36, 10)
	jar.add_child(lid)

	var shine := ColorRect.new()
	shine.color = Color(0.95, 0.78, 0.44, 0.7)
	shine.position = Vector2(-14, -14)
	shine.size = Vector2(7, 24)
	jar.add_child(shine)

	var label := Label.new()
	label.text = "JAR"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-24, -4)
	label.size = Vector2(48, 24)
	jar.add_child(label)

	_set_control_mouse_filters(jar)
	return jar


func _break_jar(jar: Node2D) -> void:
	if not jars.has(jar):
		return

	var spawn_position: Vector2 = jar.position
	jars.erase(jar)
	jar.queue_free()

	_spawn_zombie(spawn_position)

	_update_hud()
	_check_victory()


func _update_player_movement(delta: float) -> void:
	var movement: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		movement.y += 1.0

	if movement.length() <= 0.0:
		return

	player_node.position += movement.normalized() * PLAYER_SPEED * delta
	player_node.position = Vector2(
		clampf(player_node.position.x, PLAYER_MIN_POSITION.x, PLAYER_MAX_POSITION.x),
		clampf(player_node.position.y, PLAYER_MIN_POSITION.y, PLAYER_MAX_POSITION.y)
	)


func _update_player_fire(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_firing or fire_cooldown > 0.0:
		return

	_fire_projectile(get_global_mouse_position())
	fire_cooldown = PROJECTILE_FIRE_INTERVAL


func _fire_projectile(mouse_position: Vector2) -> void:
	var projectile_start: Vector2 = player_node.position
	var aim_offset: Vector2 = mouse_position - projectile_start
	if aim_offset.length() <= 0.001:
		return

	var direction: Vector2 = aim_offset.normalized()
	var projectile_node: Node2D = _create_projectile(projectile_start, direction)
	projectiles.append({
		"node": projectile_node,
		"direction": direction,
		"age": 0.0,
	})


func _create_projectile(projectile_position: Vector2, direction: Vector2) -> Node2D:
	var projectile: Node2D = Node2D.new()
	projectile.name = "Projectile"
	projectile.position = projectile_position
	projectile.rotation = direction.angle()
	projectile.z_index = 60
	add_child(projectile)

	var body: Polygon2D = Polygon2D.new()
	body.color = Color(1.0, 0.92, 0.26)
	body.polygon = PackedVector2Array([
		Vector2(PROJECTILE_RADIUS * 2.0, 0),
		Vector2(-PROJECTILE_RADIUS, -PROJECTILE_RADIUS * 0.8),
		Vector2(-3, 0),
		Vector2(-PROJECTILE_RADIUS, PROJECTILE_RADIUS * 0.8),
	])
	projectile.add_child(body)

	return projectile


func _update_projectiles(delta: float) -> void:
	for projectile_value in projectiles.duplicate():
		var projectile: Dictionary = projectile_value
		if not _is_projectile_valid(projectile):
			projectiles.erase(projectile)
			continue

		var projectile_node: Node2D = projectile["node"]
		var direction: Vector2 = projectile["direction"]
		var previous_position: Vector2 = projectile_node.position
		var move_distance: float = PROJECTILE_SPEED * delta
		var next_position: Vector2 = previous_position + direction * move_distance

		projectile_node.position = next_position
		projectile["age"] = float(projectile["age"]) + delta

		if _try_projectile_hit(projectile, previous_position, next_position):
			continue

		if float(projectile["age"]) >= PROJECTILE_LIFETIME:
			_remove_projectile(projectile)


func _try_projectile_hit(projectile: Dictionary, segment_start: Vector2, segment_end: Vector2) -> bool:
	var nearest_progress: float = INF
	var hit_jar: Node2D = null
	var hit_zombie: Dictionary = {}

	for jar_value in jars:
		var jar: Node2D = jar_value
		if not is_instance_valid(jar):
			continue

		var progress: float = _projectile_progress_to_point(jar.position, segment_start, segment_end, PROJECTILE_JAR_HIT_RADIUS)
		if progress < nearest_progress:
			nearest_progress = progress
			hit_jar = jar
			hit_zombie = {}

	for zombie_value in zombies:
		var zombie: Dictionary = zombie_value
		if not _is_actor_alive(zombie):
			continue

		var zombie_node: Node2D = zombie["node"]
		var progress: float = _projectile_progress_to_point(zombie_node.position, segment_start, segment_end, PROJECTILE_ZOMBIE_HIT_RADIUS)
		if progress < nearest_progress:
			nearest_progress = progress
			hit_jar = null
			hit_zombie = zombie

	if hit_jar != null:
		_break_jar(hit_jar)
		_remove_projectile(projectile)
		return true
	elif not hit_zombie.is_empty():
		_damage_actor(hit_zombie, PROJECTILE_DAMAGE)
		_remove_projectile(projectile)
		return true

	return false


func _projectile_progress_to_point(point: Vector2, segment_start: Vector2, segment_end: Vector2, radius: float) -> float:
	var segment: Vector2 = segment_end - segment_start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return INF

	var progress: float = clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest_point: Vector2 = segment_start + segment * progress
	if point.distance_to(closest_point) > radius:
		return INF

	return progress


func _is_projectile_valid(projectile: Dictionary) -> bool:
	if projectile.is_empty() or not projectile.has("node"):
		return false

	var projectile_node: Node2D = projectile["node"]
	return is_instance_valid(projectile_node)


func _remove_projectile(projectile: Dictionary) -> void:
	projectiles.erase(projectile)
	if not projectile.has("node"):
		return

	var projectile_node: Node2D = projectile["node"]
	if is_instance_valid(projectile_node):
		projectile_node.queue_free()


func _spawn_zombie(spawn_position: Vector2) -> void:
	var zombie: Dictionary = _create_actor("Zombie", spawn_position, ZOMBIE_COLOR, "Z", ZOMBIE_MAX_HEALTH)
	zombies.append(zombie)


func _create_actor(actor_name: String, spawn_position: Vector2, color: Color, marker: String, max_health: float) -> Dictionary:
	var actor_node := Node2D.new()
	actor_node.name = actor_name
	actor_node.position = spawn_position
	actor_node.z_index = 20
	add_child(actor_node)

	var body := Polygon2D.new()
	body.color = color
	body.polygon = _circle_polygon(24, 18)
	actor_node.add_child(body)

	var shadow := Polygon2D.new()
	shadow.color = Color(0.02, 0.02, 0.02, 0.20)
	shadow.position = Vector2(3, 5)
	shadow.polygon = _circle_polygon(24, 18)
	shadow.z_index = -1
	actor_node.add_child(shadow)

	var label := Label.new()
	label.text = marker
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-14, -16)
	label.size = Vector2(28, 28)
	actor_node.add_child(label)

	var health_bg := ColorRect.new()
	health_bg.color = Color(0.08, 0.10, 0.10)
	health_bg.position = Vector2(-24, -36)
	health_bg.size = Vector2(48, 7)
	actor_node.add_child(health_bg)

	var health_fill := ColorRect.new()
	health_fill.color = Color(0.20, 0.86, 0.30)
	health_fill.position = Vector2(-22, -34)
	health_fill.size = Vector2(44, 3)
	actor_node.add_child(health_fill)

	_set_control_mouse_filters(actor_node)
	return {
		"node": actor_node,
		"hp": max_health,
		"max_hp": max_health,
		"health_fill": health_fill,
		"attack_timer": 0.0,
	}


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in range(points):
		var angle := TAU * float(point) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon


func _set_control_mouse_filters(root: Node) -> void:
	if root is Control:
		var control: Control = root
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in root.get_children():
		_set_control_mouse_filters(child)


func _update_zombies(delta: float) -> void:
	for zombie_value in zombies.duplicate():
		var zombie: Dictionary = zombie_value
		if not _is_actor_alive(zombie):
			continue

		_update_zombie_against_player(zombie, delta)


func _update_zombie_against_player(zombie: Dictionary, delta: float) -> void:
	var zombie_node: Node2D = zombie["node"]
	var player_position: Vector2 = player_node.position
	var distance: float = zombie_node.position.distance_to(player_position)
	if distance > ZOMBIE_ATTACK_RANGE:
		zombie["attack_timer"] = 0.0
		_move_actor_toward(zombie, player_position, ZOMBIE_SPEED, delta)
	else:
		zombie["attack_timer"] = float(zombie["attack_timer"]) - delta
		if float(zombie["attack_timer"]) <= 0.0:
			_damage_player(ZOMBIE_ATTACK_DAMAGE)
			zombie["attack_timer"] = ZOMBIE_ATTACK_INTERVAL


func _move_actor_toward(actor: Dictionary, target_position: Vector2, speed: float, delta: float) -> void:
	var node: Node2D = actor["node"]
	var offset: Vector2 = target_position - node.position
	if offset.length() <= 0.001:
		return

	var step: float = minf(offset.length(), speed * delta)
	node.position += offset.normalized() * step


func _damage_actor(actor: Dictionary, damage: float) -> void:
	if not _is_actor_alive(actor):
		return

	actor["hp"] = maxf(0.0, float(actor["hp"]) - damage)
	_update_actor_health(actor)

	if float(actor["hp"]) <= 0.0:
		_kill_zombie(actor)


func _damage_player(damage: float) -> void:
	if game_over:
		return

	player_health = maxf(0.0, player_health - damage)
	_update_player_health()

	if player_health <= 0.0:
		_lose_game()


func _kill_zombie(zombie: Dictionary) -> void:
	zombies.erase(zombie)
	if is_instance_valid(zombie["node"]):
		zombie["node"].queue_free()
	_check_victory()


func _is_actor_alive(actor: Dictionary) -> bool:
	if actor.is_empty() or not actor.has("node"):
		return false

	return is_instance_valid(actor["node"]) and float(actor["hp"]) > 0.0


func _update_actor_health(actor: Dictionary) -> void:
	if not actor.has("health_fill") or not is_instance_valid(actor["health_fill"]):
		return

	var max_health: float = float(actor["max_hp"])
	var health_ratio: float = clampf(float(actor["hp"]) / max_health, 0.0, 1.0)
	var health_fill: ColorRect = actor["health_fill"]
	health_fill.size = Vector2(44.0 * health_ratio, health_fill.size.y)


func _update_player_health() -> void:
	var health_ratio: float = clampf(player_health / PLAYER_MAX_HEALTH, 0.0, 1.0)
	player_health_fill.size = Vector2(92.0 * health_ratio, player_health_fill.size.y)


func _update_hud() -> void:
	if hud_label == null:
		return

	hud_label.text = "HP: %d/%d   Jars: %d   Zombies: %d" % [
		int(ceil(player_health)),
		int(PLAYER_MAX_HEALTH),
		jars.size(),
		zombies.size(),
	]


func _check_victory() -> void:
	if game_over:
		return

	if jars.is_empty() and zombies.is_empty():
		_win_game()


func _win_game() -> void:
	game_over = true
	status_panel.visible = true
	status_label.text = "Victory!\nAll jars are broken and every zombie is down.\nPress R to restart."


func _lose_game() -> void:
	game_over = true
	status_panel.visible = true
	status_label.text = "Defeat!\nThe zombies destroyed the player.\nPress R to restart."
