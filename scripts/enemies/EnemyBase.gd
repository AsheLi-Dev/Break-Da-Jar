extends CharacterBody2D
class_name EnemyBase

signal died(enemy: EnemyBase)

# Core stats shared by all enemy types. Tune these per enemy scene.
@export var max_hp: float = 35.0
@export var move_speed: float = 90.0
@export var damage: float = 8.0
@export var attack_cooldown: float = 1.0
@export var knockback_friction: float = 1600.0
@export var is_elite: bool = false

# The enemy automatically tracks the first node in this group.
@export var target_group: StringName = &"player"
@export var debug_color: Color = Color(0.52, 0.56, 0.46)

var hp: float
var target: Node2D
var is_dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var status_effects: StatusEffectComponent
var last_damage_source: Node
var last_attack_info: Dictionary = {}
var kill_notified: bool = false


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	_ensure_status_effects()
	_find_target()
	_ensure_placeholder_visual()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if _update_knockback(delta):
		return

	_find_target()
	_chase_target(delta)


func take_damage(amount: float, source: Node = null, attack_info: Dictionary = {}) -> float:
	if is_dead:
		return 0.0

	last_damage_source = source
	last_attack_info = attack_info
	var old_hp: float = hp
	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		die()
	return old_hp - hp


func die() -> void:
	if is_dead:
		return

	is_dead = true
	_notify_player_kill_once()
	died.emit(self)
	queue_free()


func apply_status_effect(id: StringName, source_player: Node = null) -> void:
	if status_effects != null:
		status_effects.apply_status_effect(id, source_player)


func apply_poison_stacks(amount: int, source_player: Node = null) -> void:
	if status_effects != null:
		status_effects.apply_poison_stacks(amount, source_player)


func get_poison_stacks() -> int:
	return status_effects.get_poison_stacks() if status_effects != null else 0


func has_status(id: StringName) -> bool:
	return status_effects.has_status(id) if status_effects != null else false


func apply_knockback(force: Vector2) -> void:
	# Called by player shockwave or future effects. Movement still uses CharacterBody2D.
	knockback_velocity = force


func has_valid_target() -> bool:
	return target != null and is_instance_valid(target)


func get_target_position() -> Vector2:
	if has_valid_target():
		return target.global_position

	return global_position


func face_position(world_position: Vector2) -> void:
	var offset: Vector2 = world_position - global_position
	if offset.length_squared() > 0.001:
		rotation = offset.angle()


func stop_moving() -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func move_toward_position(world_position: Vector2, speed: float, delta: float) -> void:
	var offset: Vector2 = world_position - global_position
	if offset.length_squared() <= 0.001:
		stop_moving()
		return

	velocity = offset.normalized() * speed
	move_and_slide()


func _chase_target(delta: float) -> void:
	if not has_valid_target():
		stop_moving()
		return

	# Base movement is direct pursuit. Subclasses can override behavior.
	face_position(target.global_position)
	move_toward_position(target.global_position, move_speed, delta)


func _find_target() -> void:
	if has_valid_target():
		return

	target = get_tree().get_first_node_in_group(target_group) as Node2D


func _update_knockback(delta: float) -> bool:
	if knockback_velocity.length_squared() <= 1.0:
		knockback_velocity = Vector2.ZERO
		return false

	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	return true


func _ensure_placeholder_visual() -> void:
	if has_node("DebugBody"):
		return

	var body := Polygon2D.new()
	body.name = "DebugBody"
	body.color = debug_color
	body.polygon = _circle_polygon(18.0, 18)
	add_child(body)

	var forward := Line2D.new()
	forward.name = "DebugForward"
	forward.default_color = Color(0.05, 0.05, 0.05)
	forward.width = 3.0
	forward.add_point(Vector2.ZERO)
	forward.add_point(Vector2(24.0, 0.0))
	add_child(forward)


func _ensure_status_effects() -> void:
	status_effects = get_node_or_null("StatusEffectComponent") as StatusEffectComponent
	if status_effects == null:
		status_effects = StatusEffectComponent.new()
		status_effects.name = "StatusEffectComponent"
		add_child(status_effects)
	status_effects.setup(self)


func _notify_player_kill_once() -> void:
	if kill_notified:
		return
	kill_notified = true
	if last_damage_source != null and last_damage_source.has_method("notify_enemy_killed"):
		last_damage_source.notify_enemy_killed(self)


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in range(points):
		var angle := TAU * float(point) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)

	return polygon
