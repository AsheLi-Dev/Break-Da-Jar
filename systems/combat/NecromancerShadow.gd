extends Node2D
class_name NecromancerShadow

@export var move_speed: float = 72.0
@export var damage_radius: float = 46.0
@export var visual_radius: float = 54.0

var owner_player: Node2D


func setup(new_owner_player: Node2D, spawn_position: Vector2) -> void:
	owner_player = new_owner_player
	global_position = spawn_position


func _process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return

	var to_player := owner_player.global_position - global_position
	if to_player.length_squared() > 1.0:
		global_position += to_player.normalized() * move_speed * delta
	_apply_damage(delta)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, visual_radius, Color(0.02, 0.0, 0.04, 0.38))
	draw_circle(Vector2.ZERO, visual_radius * 0.62, Color(0.0, 0.0, 0.0, 0.58))
	draw_circle(Vector2.ZERO + Vector2(-visual_radius * 0.18, -visual_radius * 0.12), visual_radius * 0.32, Color(0.18, 0.02, 0.28, 0.34))


func _apply_damage(delta: float) -> void:
	var damage := _get_damage_per_second() * delta
	if damage <= 0.0:
		return
	if owner_player.global_position.distance_to(global_position) <= damage_radius and owner_player.has_method("take_damage"):
		owner_player.call("take_damage", damage)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_damage_target(enemy, damage, {"source": "necromancer_shadow", "direct": false, "allow_procs": false})
	for container in get_tree().get_nodes_in_group("container"):
		_damage_container(container, damage)


func _damage_target(target: Node, damage: float, attack_info: Dictionary) -> void:
	var target_2d := target as Node2D
	if target_2d == null or not is_instance_valid(target_2d):
		return
	if target_2d.global_position.distance_to(global_position) > damage_radius:
		return
	if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
		owner_player.call("deal_player_damage_to_enemy", target, damage, attack_info)
	elif target.has_method("take_damage"):
		target.call("take_damage", damage)


func _damage_container(container: Node, damage: float) -> void:
	var container_2d := container as Node2D
	if container_2d == null or not is_instance_valid(container_2d):
		return
	if container_2d.global_position.distance_to(global_position) > damage_radius:
		return
	if container.has_method("take_damage"):
		container.call("take_damage", damage, {"source": "necromancer_shadow", "owner": owner_player})


func _get_damage_per_second() -> float:
	if owner_player == null or not is_instance_valid(owner_player):
		return 0.0
	if owner_player.has_method("get_base_attack_damage"):
		return float(owner_player.call("get_base_attack_damage"))
	return 0.0
