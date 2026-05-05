extends Node2D
class_name FireDragon

const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")

@export var follow_lerp_speed: float = 12.0
@export var attack_range: float = 620.0
@export var fire_rate: float = 0.65
@export var damage_scale: float = 1.0
@export var explosion_radius: float = 80.0
@export var projectile_speed: float = 520.0
@export var target_group: StringName = &"enemy"

var owner_player: Node2D
var follow_offset: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0


func setup(new_owner: Node2D, new_offset: Vector2, new_damage_scale: float, new_attack_range: float, new_fire_rate: float) -> void:
	owner_player = new_owner
	follow_offset = new_offset
	damage_scale = new_damage_scale
	attack_range = new_attack_range
	fire_rate = new_fire_rate


func _ready() -> void:
	_ensure_nodes()
	if owner_player != null and is_instance_valid(owner_player):
		global_position = owner_player.global_position + follow_offset


func _process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return

	var target_position: Vector2 = owner_player.global_position + follow_offset
	global_position = global_position.lerp(target_position, clampf(follow_lerp_speed * delta, 0.0, 1.0))

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if attack_cooldown > 0.0:
		return

	var target := _get_nearest_enemy()
	if target == null:
		return

	attack_cooldown = 1.0 / maxf(fire_rate, 0.01)
	_launch_fireball(target.global_position)


func set_follow_offset(new_offset: Vector2) -> void:
	follow_offset = new_offset


func _launch_fireball(target_position: Vector2) -> void:
	if get_tree().current_scene == null:
		return

	var direction: Vector2 = target_position - global_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var damage: float = _get_fireball_damage()
	var fireball := Area2D.new()
	fireball.set_script(FIREBALL_SCRIPT)
	fireball.setup(owner_player, global_position, direction, damage, explosion_radius)
	fireball.set("speed", projectile_speed)
	fireball.collision_layer = 1 << 2
	fireball.collision_mask = 1 << 1
	get_tree().current_scene.add_child(fireball)


func _get_fireball_damage() -> float:
	if owner_player != null and owner_player.has_method("get_base_attack_damage"):
		var damage: float = owner_player.get_base_attack_damage()
		if owner_player.has_method("get_stats"):
			var stats: StatsComponent = owner_player.get_stats()
			if stats != null:
				damage *= stats.get_damage_multiplier()
		return damage * damage_scale
	return 8.0 * damage_scale


func _get_nearest_enemy() -> Node2D:
	var best: Node2D
	var best_distance: float = INF
	for enemy in get_tree().get_nodes_in_group(target_group):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or not is_instance_valid(enemy_2d):
			continue
		var distance: float = enemy_2d.global_position.distance_to(global_position)
		if distance <= attack_range and distance < best_distance:
			best_distance = distance
			best = enemy_2d
	return best


func _ensure_nodes() -> void:
	if get_node_or_null("Body") == null:
		var body := Polygon2D.new()
		body.name = "Body"
		body.color = Color(1.0, 0.26, 0.08, 1.0)
		body.polygon = PackedVector2Array([
			Vector2(18.0, 0.0),
			Vector2(2.0, -10.0),
			Vector2(-14.0, -6.0),
			Vector2(-8.0, 0.0),
			Vector2(-14.0, 6.0),
			Vector2(2.0, 10.0),
		])
		add_child(body)

	if get_node_or_null("WingLeft") == null:
		var wing_left := Polygon2D.new()
		wing_left.name = "WingLeft"
		wing_left.color = Color(0.7, 0.1, 0.06, 0.9)
		wing_left.polygon = PackedVector2Array([
			Vector2(-4.0, -5.0),
			Vector2(-24.0, -20.0),
			Vector2(-16.0, -2.0),
		])
		add_child(wing_left)

	if get_node_or_null("WingRight") == null:
		var wing_right := Polygon2D.new()
		wing_right.name = "WingRight"
		wing_right.color = Color(0.7, 0.1, 0.06, 0.9)
		wing_right.polygon = PackedVector2Array([
			Vector2(-4.0, 5.0),
			Vector2(-24.0, 20.0),
			Vector2(-16.0, 2.0),
		])
		add_child(wing_right)
