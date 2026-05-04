extends EnemyBase
class_name ZombieMelee

# Melee attack tuning. Telegraph shows before the hitbox turns on.
@export var attack_range: float = 58.0
@export var telegraph_time: float = 0.45
@export var hitbox_time: float = 0.12
@export var cone_angle_degrees: float = 80.0
@export var cone_radius: float = 72.0
@export var warning_color: Color = Color(1.0, 0.25, 0.08, 0.28)

var cooldown_remaining: float = 0.0
var attack_phase: StringName = &"idle"
var phase_time: float = 0.0
var hit_targets: Array[Node] = []

var warning_cone: Polygon2D
var attack_area: Area2D
var attack_collision: CollisionPolygon2D


func _ready() -> void:
	super()
	_ensure_melee_nodes()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _update_knockback(delta):
		return

	_find_target()
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

	if attack_phase != &"idle":
		_update_attack(delta)
		return

	if not has_valid_target():
		stop_moving()
		return

	var distance: float = global_position.distance_to(target.global_position)
	face_position(target.global_position)

	if distance <= attack_range:
		stop_moving()
		if cooldown_remaining <= 0.0:
			_start_attack()
	else:
		move_toward_position(target.global_position, move_speed, delta)


func _start_attack() -> void:
	attack_phase = &"telegraph"
	phase_time = telegraph_time
	hit_targets.clear()
	# Warning is visible during windup; no damage happens yet.
	warning_cone.visible = true
	attack_area.monitoring = false


func _update_attack(delta: float) -> void:
	if has_valid_target():
		face_position(target.global_position)

	stop_moving()
	phase_time -= delta

	if attack_phase == &"telegraph" and phase_time <= 0.0:
		attack_phase = &"active"
		phase_time = hitbox_time
		warning_cone.visible = false
		# Damage only comes from this Area2D while it is active.
		attack_area.monitoring = true
		_damage_overlapping_players()
	elif attack_phase == &"active" and phase_time <= 0.0:
		attack_area.monitoring = false
		attack_phase = &"idle"
		cooldown_remaining = attack_cooldown


func _on_attack_body_entered(body: Node) -> void:
	if attack_phase != &"active":
		return

	_try_damage_player(body)


func _damage_overlapping_players() -> void:
	for body in attack_area.get_overlapping_bodies():
		_try_damage_player(body)


func _try_damage_player(body: Node) -> void:
	if hit_targets.has(body):
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		hit_targets.append(body)
		body.call("take_damage", damage)


func _ensure_melee_nodes() -> void:
	var cone_polygon: PackedVector2Array = _make_cone_polygon(cone_radius, deg_to_rad(cone_angle_degrees), 12)

	warning_cone = get_node_or_null("AttackWarning") as Polygon2D
	if warning_cone == null:
		warning_cone = Polygon2D.new()
		warning_cone.name = "AttackWarning"
		add_child(warning_cone)
	warning_cone.color = warning_color
	warning_cone.polygon = cone_polygon
	warning_cone.visible = false

	attack_area = get_node_or_null("AttackHitbox") as Area2D
	if attack_area == null:
		attack_area = Area2D.new()
		attack_area.name = "AttackHitbox"
		add_child(attack_area)
	attack_area.monitoring = false
	attack_area.monitorable = false
	if not attack_area.body_entered.is_connected(_on_attack_body_entered):
		attack_area.body_entered.connect(_on_attack_body_entered)

	attack_collision = attack_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if attack_collision == null:
		attack_collision = CollisionPolygon2D.new()
		attack_collision.name = "CollisionPolygon2D"
		attack_area.add_child(attack_collision)
	attack_collision.polygon = cone_polygon


func _make_cone_polygon(radius: float, angle: float, steps: int) -> PackedVector2Array:
	var polygon := PackedVector2Array([Vector2.ZERO])
	var start_angle: float = -angle * 0.5
	for index in range(steps + 1):
		var t: float = float(index) / float(steps)
		var current_angle: float = lerpf(start_angle, -start_angle, t)
		polygon.append(Vector2(cos(current_angle), sin(current_angle)) * radius)

	return polygon
