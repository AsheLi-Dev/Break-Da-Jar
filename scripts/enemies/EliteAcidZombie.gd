extends EliteBrute
class_name EliteAcidZombie

const ACID_PROJECTILE_SCRIPT := preload("res://systems/combat/AcidProjectile.gd")
const POISON_PUDDLE_SCRIPT := preload("res://systems/combat/PoisonPuddle.gd")
const SELF_DESTRUCT_SCRIPT := preload("res://scripts/enemies/SelfDestructZombie.gd")
const MELEE_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/ZombieMelee.tscn")

const ACID_THROW_TEXTURE: Texture2D = preload("res://assets/zombies/elite acid zombie/Attack1.png")
const GROUND_SLAM_TEXTURE: Texture2D = preload("res://assets/zombies/elite acid zombie/Attack2.png")
const MUTATE_TEXTURE: Texture2D = preload("res://assets/zombies/elite acid zombie/Taunt.png")
const ACID_DIE_TEXTURE: Texture2D = preload("res://assets/zombies/elite acid zombie/Die.png")
const ACID_IDLE_TEXTURE: Texture2D = preload("res://assets/zombies/elite acid zombie/Idle.png")
const ACID_RUN_TEXTURE: Texture2D = preload("res://assets/zombies/elite acid zombie/Run.png")

const ACID_THROW_ACTIVE_FRAME := 8
const ACID_THROW_HOLD_FRAME := 5
const GROUND_SLAM_ACTIVE_FRAME := 7
const GROUND_SLAM_HOLD_FRAME := 3
const MUTATE_ACTIVE_FRAME := 7
const MUTATE_HOLD_FRAME := 6
const LEGACY_ANIMATION_FPS := 15.0
const LEGACY_ATTACK_HOLD_TIME := 0.18

@export var acid_throw_scale: float = 1.45
@export var acid_throw_speed: float = 430.0
@export var slam_radius: float = 170.0
@export var slam_damage: float = 12.0
@export var slam_projectile_count: int = 8
@export var slam_projectile_scale: float = 0.78
@export var slam_projectile_speed: float = 340.0
@export var poison_puddle_duration: float = 10.0
@export var poison_puddle_radius: float = 170.0
@export var mutate_radius: float = 520.0

var slam_resolved: bool = false
var mutate_resolved: bool = false


func _ready() -> void:
	is_elite = true
	hp_bar_offset_y = -104.0
	melee_radius = slam_radius
	animation_fps = 20.0
	super()


func _start_melee_attack() -> void:
	slam_resolved = false
	super()


func _start_shout_attack() -> void:
	mutate_resolved = false
	super()


func _update_chase(delta: float) -> void:
	if not has_valid_target():
		stop_moving()
		_play_brute_animation(&"idle")
		return

	_face_target(target.global_position)
	var distance: float = global_position.distance_to(target.global_position)

	if cooldown_remaining <= 0.0:
		if distance <= slam_radius:
			_start_melee_attack()
			return
		if _find_mutation_target() != null:
			_start_shout_attack()
			return
		if distance >= ranged_prefer_distance:
			_start_ranged_attack()
			return

	move_toward_position(target.global_position, move_speed, delta)
	_play_brute_animation(&"run")


func _update_melee_attack(delta: float) -> void:
	stop_moving()
	attack_elapsed += delta
	if not slam_resolved and attack_elapsed >= _get_ground_slam_active_time():
		slam_resolved = true
		melee_warning.visible = false
		_do_ground_slam()

	if attack_elapsed >= _get_attack_animation_time(&"melee_attack"):
		melee_warning.visible = false
		_start_recovery()


func _update_shout_attack(delta: float) -> void:
	stop_moving()
	attack_elapsed += delta
	if not mutate_resolved and attack_elapsed >= _get_mutate_active_time():
		mutate_resolved = true
		shout_warning.visible = false
		_mutate_nearby_minion()

	if attack_elapsed >= _get_attack_animation_time(&"shout_attack"):
		shout_warning.visible = false
		_start_recovery()


func _fire_spread_projectiles() -> void:
	if is_stunned():
		return

	var direction := locked_attack_direction.normalized()
	var projectile := _spawn_acid_projectile(_get_projectile_spawn_position(), direction, acid_throw_scale, acid_throw_speed)
	projectile.setup(direction, projectile_damage, acid_throw_speed, projectile_lifetime)


func _do_ground_slam() -> void:
	if is_stunned():
		return

	_spawn_slam_vfx()
	_damage_players_in_radius(slam_radius, slam_damage)
	_spawn_poison_puddle(global_position)
	for index in range(maxi(slam_projectile_count, 1)):
		var angle := TAU * float(index) / float(maxi(slam_projectile_count, 1))
		var direction := Vector2(cos(angle), sin(angle))
		var projectile := _spawn_acid_projectile(global_position, direction, slam_projectile_scale, slam_projectile_speed)
		projectile.setup(direction, projectile_damage, slam_projectile_speed, projectile_lifetime)


func _spawn_acid_projectile(spawn_position: Vector2, direction: Vector2, projectile_scale: float, projectile_speed_value: float) -> AcidProjectile:
	var projectile := ACID_PROJECTILE_SCRIPT.new() as AcidProjectile
	projectile.collision_mask = 0
	projectile.set_collision_mask_value(1, true)
	projectile.set_collision_mask_value(7, true)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_position
	projectile.direction = direction
	projectile.scale = Vector2.ONE * projectile_scale
	projectile.speed = projectile_speed_value
	return projectile


func _spawn_poison_puddle(spawn_position: Vector2) -> void:
	var puddle := POISON_PUDDLE_SCRIPT.new()
	puddle.setup(spawn_position, poison_puddle_radius, poison_puddle_duration)
	get_tree().current_scene.add_child(puddle)


func _mutate_nearby_minion() -> void:
	if is_stunned():
		return

	var minion := _find_mutation_target()
	if minion == null:
		return

	var spawn_position := minion.global_position
	minion.queue_free()
	var suicide := MELEE_ZOMBIE_SCENE.instantiate()
	suicide.set_script(SELF_DESTRUCT_SCRIPT)
	suicide.name = "SelfDestructZombie"
	suicide.global_position = spawn_position
	get_tree().current_scene.add_child(suicide)
	if suicide.has_method("setup_self_destruct"):
		suicide.setup_self_destruct(target)


func _find_mutation_target() -> ZombieMelee:
	var best_target: ZombieMelee
	var best_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == self or not is_instance_valid(enemy):
			continue
		if enemy.get_script() == SELF_DESTRUCT_SCRIPT:
			continue
		var zombie := enemy as ZombieMelee
		if zombie == null or zombie.is_elite:
			continue
		var distance := global_position.distance_to(zombie.global_position)
		if distance <= mutate_radius and distance < best_distance:
			best_distance = distance
			best_target = zombie

	return best_target


func _damage_players_in_radius(radius: float, attack_damage: float) -> void:
	damage_players_in_radius(radius, attack_damage)


func _spawn_slam_vfx() -> void:
	var visual := Polygon2D.new()
	visual.name = "EliteAcidSlamVFX"
	visual.color = Color(0.45, 1.0, 0.08, 0.26)
	visual.polygon = _circle_polygon(slam_radius, 48)
	visual.global_position = global_position
	visual.z_index = 120
	get_tree().current_scene.add_child(visual)
	var tween := visual.create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector2.ONE * 1.15, 0.22)
	tween.tween_property(visual, "modulate:a", 0.0, 0.22)
	tween.finished.connect(Callable(visual, "queue_free"))


func _get_animation_texture(animation_name: StringName) -> Texture2D:
	match animation_name:
		&"melee_attack":
			return GROUND_SLAM_TEXTURE
		&"ranged_attack":
			return ACID_THROW_TEXTURE
		&"shout_attack":
			return MUTATE_TEXTURE
		&"die":
			return ACID_DIE_TEXTURE
		&"run":
			return ACID_RUN_TEXTURE
		_:
			return ACID_IDLE_TEXTURE


func _get_projectile_spawn_time() -> float:
	return _get_frame_start_time(&"ranged_attack", ACID_THROW_ACTIVE_FRAME)


func _get_attack_hold_frame(animation_name: StringName) -> int:
	match animation_name:
		&"ranged_attack":
			return ACID_THROW_HOLD_FRAME
		&"melee_attack":
			return GROUND_SLAM_HOLD_FRAME
		&"shout_attack":
			return MUTATE_HOLD_FRAME

	return -1


func _get_attack_hold_time(animation_name: StringName) -> float:
	match animation_name:
		&"ranged_attack":
			return _get_hold_time_for_preserved_active_frame(ACID_THROW_ACTIVE_FRAME, true)
		&"melee_attack":
			return _get_hold_time_for_preserved_active_frame(GROUND_SLAM_ACTIVE_FRAME, true)
		&"shout_attack":
			return _get_hold_time_for_preserved_active_frame(MUTATE_ACTIVE_FRAME, false)

	return 0.0


func _get_hold_time_for_preserved_active_frame(active_frame: int, had_legacy_hold: bool) -> float:
	var old_time := float(active_frame) / LEGACY_ANIMATION_FPS
	if had_legacy_hold:
		old_time += LEGACY_ATTACK_HOLD_TIME
	var new_time := float(active_frame) / animation_fps
	return maxf(old_time - new_time, 0.0)


func _get_ground_slam_active_time() -> float:
	return _get_frame_start_time(&"melee_attack", GROUND_SLAM_ACTIVE_FRAME)


func _get_mutate_active_time() -> float:
	return _get_frame_start_time(&"shout_attack", MUTATE_ACTIVE_FRAME)
