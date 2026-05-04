extends EnemyBase
class_name ZombieRanged

# Spacing controls: ranged zombies try to hover near ideal_distance.
@export var ideal_distance: float = 230.0
@export var distance_tolerance: float = 35.0

# Fire controls. Aim line is shown during aim_time before firing.
@export var fire_cooldown: float = 1.35
@export var aim_time: float = 0.35
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 360.0
@export var projectile_lifetime: float = 2.2
@export var aim_line_length: float = 280.0

var cooldown_remaining: float = 0.0
var is_aiming: bool = false
var aim_remaining: float = 0.0

var aim_line: Line2D


func _ready() -> void:
	super()
	_ensure_ranged_nodes()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _update_knockback(delta):
		return

	_find_target()
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

	if not has_valid_target():
		aim_line.visible = false
		stop_moving()
		return

	face_position(target.global_position)

	if is_aiming:
		_update_aim(delta)
		return

	_update_spacing(delta)

	if cooldown_remaining <= 0.0:
		_start_aim()


func _update_spacing(delta: float) -> void:
	var offset: Vector2 = target.global_position - global_position
	var distance: float = offset.length()

	if distance < ideal_distance - distance_tolerance:
		velocity = -offset.normalized() * move_speed
		move_and_slide()
	elif distance > ideal_distance + distance_tolerance:
		move_toward_position(target.global_position, move_speed, delta)
	else:
		stop_moving()


func _start_aim() -> void:
	is_aiming = true
	aim_remaining = aim_time
	aim_line.visible = true


func _update_aim(delta: float) -> void:
	stop_moving()
	if has_valid_target():
		face_position(target.global_position)
		# Keep the aim warning pointed at the current player position.
		var direction: Vector2 = (target.global_position - global_position).normalized()
		aim_line.set_point_position(1, direction * aim_line_length)

	aim_remaining -= delta
	if aim_remaining <= 0.0:
		_fire_projectile()
		is_aiming = false
		aim_line.visible = false
		cooldown_remaining = fire_cooldown


func _fire_projectile() -> void:
	if not has_valid_target():
		return

	var direction: Vector2 = (target.global_position - global_position).normalized()
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


func _ensure_ranged_nodes() -> void:
	aim_line = get_node_or_null("AimLine") as Line2D
	if aim_line == null:
		aim_line = Line2D.new()
		aim_line.name = "AimLine"
		add_child(aim_line)

	aim_line.width = 3.0
	aim_line.default_color = Color(1.0, 0.1, 0.1, 0.8)
	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(Vector2(aim_line_length, 0.0))
	aim_line.visible = false
