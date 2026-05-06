extends Area2D
class_name Projectile

enum BoomerangState {
	OUTBOUND,
	RETURN_DELAY,
	RETURNING,
}

# Projectile tuning. Enemies call setup() before launch.
@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 360.0
@export var damage: float = 8.0
@export var lifetime: float = 2.0
@export var target_group: StringName = &"player"
@export var hit_walls: bool = true
@export var debug_color: Color = Color(1.0, 0.82, 0.16)
@export var boomerang_enabled: bool = false
@export var boomerang_max_distance: float = 520.0
@export var boomerang_return_delay: float = 0.2
@export var boomerang_catch_distance: float = 22.0
@export var boomerang_return_speed: float = -1.0

var age: float = 0.0
var owner_player: Node
var spawn_position: Vector2 = Vector2.ZERO
var boomerang_state: int = BoomerangState.OUTBOUND
var return_delay_remaining: float = 0.0
var outbound_hit_targets: Array[Node] = []
var return_hit_targets: Array[Node] = []
var impact_resolved: bool = false


func _ready() -> void:
	direction = direction.normalized()
	rotation = direction.angle()
	spawn_position = global_position
	_ensure_placeholder_nodes()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func setup(new_direction: Vector2, new_damage: float, new_speed: float = -1.0, new_lifetime: float = -1.0, new_target_group: StringName = &"player") -> void:
	direction = new_direction.normalized()
	damage = new_damage
	target_group = new_target_group
	if new_speed > 0.0:
		speed = new_speed
	if new_lifetime > 0.0:
		lifetime = new_lifetime
	rotation = direction.angle()


func enable_boomerang(new_owner: Node, new_max_distance: float, new_return_delay: float, new_catch_distance: float = 22.0, new_return_speed: float = -1.0) -> void:
	owner_player = new_owner
	boomerang_enabled = true
	boomerang_max_distance = new_max_distance
	boomerang_return_delay = new_return_delay
	boomerang_catch_distance = new_catch_distance
	boomerang_return_speed = new_return_speed
	boomerang_state = BoomerangState.OUTBOUND
	return_delay_remaining = 0.0
	outbound_hit_targets.clear()
	return_hit_targets.clear()
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	if boomerang_enabled and boomerang_state == BoomerangState.RETURNING:
		_update_return_direction()

	position += direction * _get_current_speed() * delta
	age += delta

	if boomerang_enabled:
		_damage_overlapping_targets()
		_update_boomerang_state(delta)

	if age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if impact_resolved:
		return

	if _try_damage_target_node(body):
		if not boomerang_enabled:
			impact_resolved = true
			queue_free()
		return

	if hit_walls and _is_wall_body(body):
		impact_resolved = true
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if impact_resolved:
		return

	if _try_damage_target_node(area):
		if not boomerang_enabled:
			impact_resolved = true
			queue_free()


func _try_damage_target_node(node: Node) -> bool:
	var target := _get_damage_target(node)
	if target == null:
		return false

	if boomerang_enabled:
		return _try_damage_boomerang_target(target)

	_damage_target_body(target)
	return true


func _get_damage_target(node: Node) -> Node:
	if node.is_in_group(target_group) and node.has_method("take_damage"):
		return node

	var parent := node.get_parent()
	if parent != null and parent.is_in_group(target_group) and parent.has_method("take_damage"):
		return parent

	return null


func _try_damage_boomerang_target(target: Node) -> bool:
	var hit_targets: Array[Node] = return_hit_targets
	if boomerang_state != BoomerangState.RETURNING:
		hit_targets = outbound_hit_targets

	if hit_targets.has(target):
		return false

	hit_targets.append(target)
	_damage_target_body(target)
	if boomerang_state == BoomerangState.OUTBOUND:
		_start_return_delay()
	return true


func _damage_target_body(target: Node) -> void:
	var can_use_owner_damage: bool = target_group == &"enemy" and owner_player != null and is_instance_valid(owner_player)
	if can_use_owner_damage:
		can_use_owner_damage = owner_player.has_method("deal_player_damage_to_enemy")

	if can_use_owner_damage:
		owner_player.deal_player_damage_to_enemy(target, damage, {"source": "projectile", "direct": true, "allow_procs": true})
	else:
		target.call("take_damage", damage)


func _damage_overlapping_targets() -> void:
	for body in get_overlapping_bodies():
		_try_damage_target_node(body)
	for area in get_overlapping_areas():
		_try_damage_target_node(area)


func _update_boomerang_state(delta: float) -> void:
	match boomerang_state:
		BoomerangState.OUTBOUND:
			if global_position.distance_to(spawn_position) >= boomerang_max_distance:
				_start_returning()
		BoomerangState.RETURN_DELAY:
			return_delay_remaining -= delta
			if return_delay_remaining <= 0.0:
				_start_returning()
		BoomerangState.RETURNING:
			if _has_reached_owner():
				queue_free()


func _start_return_delay() -> void:
	if boomerang_return_delay <= 0.0:
		_start_returning()
		return

	boomerang_state = BoomerangState.RETURN_DELAY
	return_delay_remaining = boomerang_return_delay


func _start_returning() -> void:
	boomerang_state = BoomerangState.RETURNING
	return_delay_remaining = 0.0
	_update_return_direction()


func _update_return_direction() -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var return_offset: Vector2 = owner_2d.global_position - global_position
	if return_offset.length_squared() <= 0.001:
		return

	direction = return_offset.normalized()
	rotation = direction.angle()


func _has_reached_owner() -> bool:
	if owner_player == null or not is_instance_valid(owner_player):
		return false

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return false

	return global_position.distance_to(owner_2d.global_position) <= boomerang_catch_distance


func _get_current_speed() -> float:
	if boomerang_enabled and boomerang_state == BoomerangState.RETURNING and boomerang_return_speed > 0.0:
		return boomerang_return_speed

	return speed


func _is_wall_body(body: Node) -> bool:
	if body.is_in_group("walls") or body.is_in_group("wall"):
		return true

	return body is StaticBody2D or body is TileMapLayer or body is TileMap


func _ensure_placeholder_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 5.0
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("DebugBody") == null:
		var body := Polygon2D.new()
		body.name = "DebugBody"
		body.color = debug_color
		body.polygon = PackedVector2Array([
			Vector2(10.0, 0.0),
			Vector2(-5.0, -4.0),
			Vector2(-2.0, 0.0),
			Vector2(-5.0, 4.0),
		])
		add_child(body)
