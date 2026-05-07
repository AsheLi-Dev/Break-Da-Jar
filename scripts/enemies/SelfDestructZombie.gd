extends ZombieMelee
class_name SelfDestructZombie

@export var trigger_distance: float = 100.0
@export var explosion_radius: float = 200.0
@export var explosion_damage: float = 18.0
@export var explosion_windup_time: float = 1.0
@export var speed_multiplier: float = 2.0

var is_exploding: bool = false
var explosion_elapsed: float = 0.0
var explosion_warning: Polygon2D


func setup_self_destruct(new_target: Node2D = null) -> void:
	target = new_target
	move_speed *= speed_multiplier
	attack_range = 0.0
	attack_cooldown = 9999.0
	if sprite != null:
		sprite.modulate = Color(0.55, 1.25, 0.45, 1.0)
	_ensure_explosion_warning()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _update_knockback(delta):
		return

	_find_target()
	if not has_valid_target():
		stop_moving()
		_update_zombie_animation(delta)
		return

	_face_target_for_attack(target.global_position)
	if is_exploding:
		_update_explosion_windup(delta)
		_update_zombie_animation(delta)
		return

	if global_position.distance_to(target.global_position) <= trigger_distance:
		_start_explosion_windup()
		return

	move_toward_position(target.global_position, move_speed, delta)
	_update_zombie_animation(delta)


func _start_explosion_windup() -> void:
	is_exploding = true
	explosion_elapsed = 0.0
	stop_moving()
	_ensure_explosion_warning()
	explosion_warning.visible = true
	explosion_warning.scale = Vector2.ZERO


func _update_explosion_windup(delta: float) -> void:
	stop_moving()
	explosion_elapsed += delta
	var progress := clampf(explosion_elapsed / maxf(explosion_windup_time, 0.001), 0.0, 1.0)
	explosion_warning.scale = Vector2.ONE * progress
	if explosion_elapsed >= explosion_windup_time:
		_explode()


func _explode() -> void:
	if explosion_warning != null:
		explosion_warning.visible = false

	for player in get_tree().get_nodes_in_group("player"):
		var player_2d := player as Node2D
		if player_2d == null or player_2d.global_position.distance_to(global_position) > explosion_radius:
			continue
		if player.has_method("take_damage"):
			player.take_damage(explosion_damage)

	die()


func _ensure_explosion_warning() -> void:
	if explosion_warning != null:
		return

	explosion_warning = get_node_or_null("ExplosionWarning") as Polygon2D
	if explosion_warning == null:
		explosion_warning = Polygon2D.new()
		explosion_warning.name = "ExplosionWarning"
		add_child(explosion_warning)
	explosion_warning.color = Color(0.55, 1.0, 0.05, 0.24)
	explosion_warning.polygon = _circle_polygon(explosion_radius, 48)
	explosion_warning.visible = false
