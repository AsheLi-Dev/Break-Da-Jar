extends RefCounted

const WORLD_COLLISION_MASK := 1


static func try_damage_player(attacker: Node2D, target_node: Node, damage: float, hit_targets: Variant = null) -> bool:
	if attacker == null or target_node == null:
		return false
	if attacker.has_method("is_stunned") and bool(attacker.call("is_stunned")):
		return false
	var tracks_hits := hit_targets is Array
	if tracks_hits and hit_targets.has(target_node):
		return false

	var player := get_player_target(target_node)
	if player == null:
		return false
	if is_world_between(attacker, attacker.global_position, player.global_position):
		return false

	if tracks_hits:
		hit_targets.append(target_node)
	player.call("take_damage", damage)
	return true


static func damage_overlapping_players(attacker: Node2D, area: Area2D, damage: float, hit_targets: Variant = null) -> int:
	if area == null:
		return 0

	var hit_count := 0
	for body in area.get_overlapping_bodies():
		if try_damage_player(attacker, body, damage, hit_targets):
			hit_count += 1
	return hit_count


static func damage_players_in_radius(attacker: Node2D, radius: float, damage: float) -> int:
	if attacker == null or attacker.get_tree() == null:
		return 0
	if attacker.has_method("is_stunned") and bool(attacker.call("is_stunned")):
		return 0

	var hit_count := 0
	for node in attacker.get_tree().get_nodes_in_group("player"):
		var player := node as Node2D
		if player == null or not player.has_method("take_damage"):
			continue
		if player.global_position.distance_to(attacker.global_position) > radius:
			continue
		if is_world_between(attacker, attacker.global_position, player.global_position):
			continue
		player.call("take_damage", damage)
		hit_count += 1
	return hit_count


static func get_player_target(node: Node) -> Node:
	if node == null:
		return null
	if node.is_in_group("player") and node.has_method("take_damage"):
		return node

	var parent := node.get_parent()
	if parent != null and parent.is_in_group("player") and parent.has_method("take_damage"):
		return parent
	return null


static func is_world_between(query_owner: Node2D, from_position: Vector2, to_position: Vector2) -> bool:
	if query_owner == null or query_owner.get_world_2d() == null:
		return false
	if from_position.distance_squared_to(to_position) <= 1.0:
		return false

	var query := PhysicsRayQueryParameters2D.create(from_position, to_position)
	query.exclude = [query_owner]
	query.collision_mask = WORLD_COLLISION_MASK
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not query_owner.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
