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
@export var visual_style: StringName = &"default"
@export var bone_afterimage_interval: float = 0.04
@export var bone_afterimage_lifetime: float = 0.12
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
var bone_afterimage_remaining: float = 0.0


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


func use_bone_spike_visual() -> void:
	visual_style = &"bone_spike"
	_apply_visual_style()


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

	_update_bone_afterimage(delta)
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

	_apply_visual_style()


func _apply_visual_style() -> void:
	if visual_style != &"bone_spike":
		return

	var body := get_node_or_null("DebugBody") as Polygon2D
	if body != null:
		body.scale = Vector2(0.72, 0.58)
		body.color = Color(0.82, 0.79, 0.69, 1.0)
		body.polygon = PackedVector2Array([
			Vector2(24.0, -0.3),
			Vector2(13.0, -1.8),
			Vector2(4.0, -2.9),
			Vector2(-4.0, -2.1),
			Vector2(-11.0, -3.7),
			Vector2(-18.0, -1.1),
			Vector2(-13.0, 0.4),
			Vector2(-20.0, 1.8),
			Vector2(-9.0, 2.9),
			Vector2(2.0, 1.7),
			Vector2(12.0, 2.4),
		])

	var trail := get_node_or_null("Trail") as Line2D
	if trail != null:
		trail.visible = false

	if get_node_or_null("BoneCracks") == null:
		var cracks := Line2D.new()
		cracks.name = "BoneCracks"
		cracks.scale = Vector2(0.72, 0.58)
		cracks.width = 0.8
		cracks.default_color = Color(0.30, 0.28, 0.24, 0.72)
		cracks.add_point(Vector2(9.0, -0.9))
		cracks.add_point(Vector2(5.0, 1.0))
		cracks.add_point(Vector2(-1.0, -0.7))
		cracks.add_point(Vector2(-6.0, 1.6))
		cracks.add_point(Vector2(-13.0, -0.2))
		add_child(cracks)

	if get_node_or_null("BoneShard") == null:
		var shard := Polygon2D.new()
		shard.name = "BoneShard"
		shard.scale = Vector2(0.72, 0.58)
		shard.color = Color(0.70, 0.67, 0.58, 0.95)
		shard.polygon = PackedVector2Array([
			Vector2(-6.0, -4.4),
			Vector2(-1.0, -3.0),
			Vector2(-4.2, -1.7),
		])
		add_child(shard)

	if get_node_or_null("AirCutTrail") == null:
		var air_cut := Line2D.new()
		air_cut.name = "AirCutTrail"
		air_cut.width = 0.9
		air_cut.default_color = Color(0.86, 0.92, 0.95, 0.14)
		air_cut.antialiased = true
		air_cut.add_point(Vector2(-10.0, -1.9))
		air_cut.add_point(Vector2(-24.0, -3.1))
		add_child(air_cut)

	if get_node_or_null("AirCutTrailLower") == null:
		var air_cut_lower := Line2D.new()
		air_cut_lower.name = "AirCutTrailLower"
		air_cut_lower.width = 0.7
		air_cut_lower.default_color = Color(0.86, 0.92, 0.95, 0.10)
		air_cut_lower.antialiased = true
		air_cut_lower.add_point(Vector2(-9.0, 1.7))
		air_cut_lower.add_point(Vector2(-21.0, 2.5))
		add_child(air_cut_lower)


func _update_bone_afterimage(delta: float) -> void:
	if visual_style != &"bone_spike":
		return

	bone_afterimage_remaining -= delta
	if bone_afterimage_remaining > 0.0:
		return

	bone_afterimage_remaining = bone_afterimage_interval
	_spawn_bone_afterimage()


func _spawn_bone_afterimage() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var afterimage := Polygon2D.new()
	afterimage.name = "BoneSpikeAfterimage"
	afterimage.global_position = global_position - direction.normalized() * 8.0
	afterimage.global_rotation = rotation + randf_range(-0.05, 0.05)
	afterimage.scale = Vector2(0.55, 0.42)
	afterimage.color = Color(0.76, 0.78, 0.73, 0.42)
	afterimage.polygon = PackedVector2Array([
		Vector2(24.0, -0.3),
		Vector2(13.0, -1.8),
		Vector2(4.0, -2.9),
		Vector2(-4.0, -2.1),
		Vector2(-11.0, -3.7),
		Vector2(-18.0, -1.1),
		Vector2(-13.0, 0.4),
		Vector2(-20.0, 1.8),
		Vector2(-9.0, 2.9),
		Vector2(2.0, 1.7),
		Vector2(12.0, 2.4),
	])
	afterimage.z_index = 118
	get_tree().current_scene.add_child(afterimage)

	var tween := afterimage.create_tween()
	tween.set_parallel(true)
	tween.tween_property(afterimage, "modulate:a", 0.0, bone_afterimage_lifetime)
	tween.tween_property(afterimage, "scale", Vector2(0.42, 0.32), bone_afterimage_lifetime)
	tween.finished.connect(Callable(afterimage, "queue_free"))
