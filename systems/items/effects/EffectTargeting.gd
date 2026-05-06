extends RefCounted
class_name EffectTargeting

const SURROUNDED_RADIUS := 220.0


static func enemies_near(owner: Node, origin: Vector2, search_radius: float, exclude: Array = []) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if owner == null or owner.get_tree() == null:
		return result

	for enemy in owner.get_tree().get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or exclude.has(enemy) or not is_instance_valid(enemy_2d):
			continue
		if enemy_2d.global_position.distance_to(origin) <= search_radius:
			result.append(enemy_2d)
	return result


static func enemies_surrounding(owner: Node, origin: Vector2, exclude: Array = []) -> Array[Node2D]:
	return enemies_near(owner, origin, SURROUNDED_RADIUS, exclude)


static func nearest_enemy(owner: Node, origin: Vector2, search_radius: float, exclude: Array = []) -> Node2D:
	var best: Node2D
	var best_distance: float = INF
	for enemy in enemies_near(owner, origin, search_radius, exclude):
		var distance: float = enemy.global_position.distance_to(origin)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


static func nearest_container(owner: Node, origin: Vector2, search_radius: float, exclude: Array = []) -> Node2D:
	var best: Node2D
	var best_distance: float = INF
	if owner == null or owner.get_tree() == null:
		return best

	for container in owner.get_tree().get_nodes_in_group("container"):
		var container_2d := container as Node2D
		if container_2d == null or exclude.has(container) or not is_instance_valid(container_2d):
			continue
		if container_2d is BreakableContainer and container_2d.is_breaking:
			continue
		if container_2d is BreakableContainer and container_2d.is_shop_container:
			continue
		var distance := container_2d.global_position.distance_to(origin)
		if distance <= search_radius and distance < best_distance:
			best_distance = distance
			best = container_2d
	return best
