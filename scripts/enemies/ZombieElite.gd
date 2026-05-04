extends EnemyBase
class_name ZombieElite

# Simple state machine. Only one attack can run at a time.
enum State {
	IDLE,
	CHASE,
	WINDUP_CHARGE,
	CHARGING,
	WINDUP_STOMP,
	RECOVERY,
}

# Skill selection distances. Far favors charge; close favors stomp.
@export var charge_prefer_distance: float = 260.0
@export var stomp_prefer_distance: float = 150.0

# Charge attack: warning, locked direction, active hitbox, recovery.
@export var charge_windup: float = 0.55
@export var charge_speed: float = 520.0
@export var charge_duration: float = 0.42
@export var charge_damage: float = 14.0
@export var charge_hitbox_radius: float = 28.0

# Stomp attack: circular warning, Area2D damage, then 8 projectiles.
@export var stomp_windup: float = 0.65
@export var stomp_radius: float = 105.0
@export var stomp_damage: float = 12.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 330.0
@export var projectile_lifetime: float = 2.0
@export var recovery_time: float = 0.35

var state: int = State.IDLE
var state_time: float = 0.0
var charge_direction: Vector2 = Vector2.ZERO
var cooldown_remaining: float = 0.0
var hit_targets: Array[Node] = []

var charge_warning: Line2D
var charge_hitbox: Area2D
var charge_collision: CollisionShape2D
var stomp_warning: Polygon2D
var stomp_hitbox: Area2D
var stomp_collision: CollisionShape2D


func _ready() -> void:
	super()
	_ensure_elite_nodes()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _update_knockback(delta):
		return

	_find_target()
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

	match state:
		State.IDLE:
			_enter_state(State.CHASE)
		State.CHASE:
			_update_chase(delta)
		State.WINDUP_CHARGE:
			_update_charge_windup(delta)
		State.CHARGING:
			_update_charging(delta)
		State.WINDUP_STOMP:
			_update_stomp_windup(delta)
		State.RECOVERY:
			_update_recovery(delta)


func _update_chase(delta: float) -> void:
	if not has_valid_target():
		stop_moving()
		return

	face_position(target.global_position)
	var distance: float = global_position.distance_to(target.global_position)

	if cooldown_remaining <= 0.0:
		if distance >= charge_prefer_distance:
			_start_charge()
			return
		if distance <= stomp_prefer_distance:
			_start_stomp()
			return

	move_toward_position(target.global_position, move_speed, delta)


func _start_charge() -> void:
	if not has_valid_target():
		return

	_enter_state(State.WINDUP_CHARGE)
	state_time = charge_windup
	charge_direction = (target.global_position - global_position).normalized()
	face_position(target.global_position)
	charge_warning.visible = true
	charge_warning.set_point_position(1, charge_direction * 240.0)
	hit_targets.clear()


func _update_charge_windup(delta: float) -> void:
	stop_moving()
	state_time -= delta
	if state_time <= 0.0:
		_enter_state(State.CHARGING)
		state_time = charge_duration
		charge_warning.visible = false
		charge_hitbox.monitoring = true
		_damage_overlapping_players(charge_hitbox, charge_damage)


func _update_charging(delta: float) -> void:
	velocity = charge_direction * charge_speed
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	state_time -= delta
	if collision != null or state_time <= 0.0:
		charge_hitbox.monitoring = false
		_start_recovery()


func _start_stomp() -> void:
	_enter_state(State.WINDUP_STOMP)
	state_time = stomp_windup
	stomp_warning.visible = true
	hit_targets.clear()
	stop_moving()


func _update_stomp_windup(delta: float) -> void:
	stop_moving()
	if has_valid_target():
		face_position(target.global_position)

	state_time -= delta
	if state_time <= 0.0:
		stomp_warning.visible = false
		stomp_hitbox.monitoring = true
		_damage_overlapping_players(stomp_hitbox, stomp_damage)
		_fire_radial_projectiles()
		stomp_hitbox.monitoring = false
		_start_recovery()


func _start_recovery() -> void:
	_enter_state(State.RECOVERY)
	state_time = recovery_time
	cooldown_remaining = attack_cooldown
	stop_moving()


func _update_recovery(delta: float) -> void:
	stop_moving()
	state_time -= delta
	if state_time <= 0.0:
		_enter_state(State.CHASE)


func _enter_state(next_state: int) -> void:
	state = next_state
	charge_warning.visible = false
	stomp_warning.visible = false
	charge_hitbox.monitoring = false
	stomp_hitbox.monitoring = false


func _on_attack_body_entered(body: Node) -> void:
	if state == State.CHARGING:
		_try_damage_player(body, charge_damage)
	elif state == State.WINDUP_STOMP:
		_try_damage_player(body, stomp_damage)


func _damage_overlapping_players(area: Area2D, attack_damage: float) -> void:
	for body in area.get_overlapping_bodies():
		_try_damage_player(body, attack_damage)


func _try_damage_player(body: Node, attack_damage: float) -> void:
	if hit_targets.has(body):
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		hit_targets.append(body)
		body.call("take_damage", attack_damage)


func _fire_radial_projectiles() -> void:
	for index in range(8):
		var angle: float = TAU * float(index) / 8.0
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var projectile: Projectile = _spawn_projectile(global_position, direction)
		projectile.setup(direction, damage, projectile_speed, projectile_lifetime)


func _spawn_projectile(spawn_position: Vector2, direction: Vector2) -> Projectile:
	var projectile: Projectile
	if projectile_scene != null:
		projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		projectile = Projectile.new()

	projectile.global_position = spawn_position
	get_tree().current_scene.add_child(projectile)
	projectile.direction = direction
	return projectile


func _ensure_elite_nodes() -> void:
	charge_warning = get_node_or_null("ChargeWarning") as Line2D
	if charge_warning == null:
		charge_warning = Line2D.new()
		charge_warning.name = "ChargeWarning"
		add_child(charge_warning)
	charge_warning.width = 8.0
	charge_warning.default_color = Color(1.0, 0.1, 0.0, 0.55)
	charge_warning.clear_points()
	charge_warning.add_point(Vector2.ZERO)
	charge_warning.add_point(Vector2(240.0, 0.0))
	charge_warning.visible = false

	charge_hitbox = _get_or_create_area("ChargeHitbox", charge_hitbox_radius)
	charge_collision = charge_hitbox.get_node("CollisionShape2D") as CollisionShape2D

	stomp_warning = get_node_or_null("StompWarning") as Polygon2D
	if stomp_warning == null:
		stomp_warning = Polygon2D.new()
		stomp_warning.name = "StompWarning"
		add_child(stomp_warning)
	stomp_warning.color = Color(1.0, 0.15, 0.0, 0.22)
	stomp_warning.polygon = _circle_polygon(stomp_radius, 32)
	stomp_warning.visible = false

	stomp_hitbox = _get_or_create_area("StompHitbox", stomp_radius)
	stomp_collision = stomp_hitbox.get_node("CollisionShape2D") as CollisionShape2D

	if not charge_hitbox.body_entered.is_connected(_on_attack_body_entered):
		charge_hitbox.body_entered.connect(_on_attack_body_entered)
	if not stomp_hitbox.body_entered.is_connected(_on_attack_body_entered):
		stomp_hitbox.body_entered.connect(_on_attack_body_entered)


func _get_or_create_area(area_name: StringName, radius: float) -> Area2D:
	var area := get_node_or_null(String(area_name)) as Area2D
	if area == null:
		area = Area2D.new()
		area.name = area_name
		add_child(area)

	area.monitoring = false
	area.monitorable = false

	var collision := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		area.add_child(collision)

	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	return area
