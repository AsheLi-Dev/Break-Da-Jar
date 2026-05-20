extends Node2D
class_name SkeletonArcher

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const SPRITE_SCALE := Vector2(2.0, 2.0)
const ATTACK_ACTIVE_FRAME := 10
const ATTACK_FPS := 15.0
const IDLE_FPS := 10.0
const RUN_FPS := 12.0
const IDLE_TEXTURE_PATH := "res://assets/summons/5archer/idle.png"
const RUN_TEXTURE_PATH := "res://assets/summons/5archer/run.png"
const ATTACK_TEXTURE_PATH := "res://assets/summons/5archer/attack1.png"
const DIE_TEXTURE_PATH := "res://assets/summons/5archer/die.png"

@export var follow_lerp_speed: float = 8.0
@export var follow_radius: float = 64.0
@export var attack_range: float = 620.0
@export var damage_inherit_multiplier: float = 1.0
@export var damage_growth_per_second: float = 0.0
@export var poison_chance: float = 0.0
@export var attack_speed_inherit_multiplier: float = 0.75
@export var target_group: StringName = &"enemy"

var owner_player: Node2D
var follow_offset: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0
var attacking: bool = false
var attack_elapsed: float = 0.0
var attack_damage_dealt: bool = false
var attack_target: Node2D
var facing_direction: Vector2 = Vector2.RIGHT
var sprite: Sprite2D
var current_texture: Texture2D
var current_frame_index: int = -1
var current_direction_row: int = -1
var idle_texture: Texture2D
var run_texture: Texture2D
var attack_texture: Texture2D
var die_texture: Texture2D
var timed_attack_speed_multiplier: float = 1.0
var timed_attack_speed_remaining: float = 0.0
var die_when_timed_attack_speed_ends: bool = false
var alive_time: float = 0.0
var dying: bool = false
var death_elapsed: float = 0.0


func setup(new_owner: Node2D, new_follow_offset: Vector2) -> void:
	owner_player = new_owner
	follow_offset = new_follow_offset


func _ready() -> void:
	_ensure_nodes()
	idle_texture = _load_texture(IDLE_TEXTURE_PATH)
	run_texture = _load_texture(RUN_TEXTURE_PATH)
	attack_texture = _load_texture(ATTACK_TEXTURE_PATH)
	die_texture = _load_texture(DIE_TEXTURE_PATH)
	_set_animation_texture(idle_texture)
	if owner_player != null and is_instance_valid(owner_player):
		global_position = owner_player.global_position + follow_offset


func _process(delta: float) -> void:
	if dying:
		_update_death(delta)
		return

	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return

	_update_timed_attack_speed(delta)
	alive_time += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if attacking:
		_update_attack(delta)
		return

	var target := _get_nearest_enemy()
	if target != null:
		facing_direction = (target.global_position - global_position).normalized()
		if attack_cooldown <= 0.0:
			_start_attack(target)
		else:
			_play_idle(delta)
		return

	_follow_owner(delta)


func set_follow_offset(new_follow_offset: Vector2) -> void:
	follow_offset = new_follow_offset


func play_death_and_free() -> void:
	if dying:
		return
	dying = true
	attacking = false
	attack_target = null
	if owner_player != null and is_instance_valid(owner_player) and owner_player.has_method("remove_necromancer_skeleton_archer"):
		owner_player.call("remove_necromancer_skeleton_archer", self)
	death_elapsed = 0.0
	_set_animation_texture(die_texture)
	_set_frame(0)


func apply_timed_attack_speed_multiplier(multiplier: float, duration: float, die_on_expire: bool = false) -> void:
	timed_attack_speed_multiplier = maxf(multiplier, 1.0)
	timed_attack_speed_remaining = maxf(duration, timed_attack_speed_remaining)
	die_when_timed_attack_speed_ends = die_when_timed_attack_speed_ends or die_on_expire


func _update_timed_attack_speed(delta: float) -> void:
	if timed_attack_speed_remaining <= 0.0:
		return
	timed_attack_speed_remaining = maxf(0.0, timed_attack_speed_remaining - delta)
	if timed_attack_speed_remaining <= 0.0:
		timed_attack_speed_multiplier = 1.0
		if die_when_timed_attack_speed_ends:
			die_when_timed_attack_speed_ends = false
			play_death_and_free()


func _follow_owner(delta: float) -> void:
	var wanted_position := owner_player.global_position + follow_offset
	var before := global_position
	global_position = global_position.lerp(wanted_position, clampf(follow_lerp_speed * delta, 0.0, 1.0))
	var movement := global_position - before
	if movement.length_squared() > 0.01:
		facing_direction = movement.normalized()
		_play_run(delta)
	else:
		_play_idle(delta)


func _start_attack(target: Node2D) -> void:
	attacking = true
	attack_elapsed = 0.0
	attack_damage_dealt = false
	attack_target = target
	attack_cooldown = _get_attack_interval()
	_set_animation_texture(attack_texture)
	_set_frame(0)


func _update_attack(delta: float) -> void:
	if attack_target != null and is_instance_valid(attack_target):
		facing_direction = (attack_target.global_position - global_position).normalized()

	attack_elapsed += delta
	var frame_index := mini(int(floorf(attack_elapsed * ATTACK_FPS)), FRAMES_PER_DIRECTION - 1)
	_set_frame(frame_index)
	if not attack_damage_dealt and frame_index >= ATTACK_ACTIVE_FRAME:
		attack_damage_dealt = true
		_deal_attack_damage()

	if frame_index >= FRAMES_PER_DIRECTION - 1:
		attacking = false
		attack_target = null


func _update_death(delta: float) -> void:
	death_elapsed += delta
	var frame_index := mini(int(floorf(death_elapsed * ATTACK_FPS)), FRAMES_PER_DIRECTION - 1)
	_set_frame(frame_index)
	if frame_index >= FRAMES_PER_DIRECTION - 1:
		queue_free()


func _deal_attack_damage() -> void:
	var target := attack_target
	if target == null or not is_instance_valid(target):
		target = _get_nearest_enemy()
	if target == null:
		return

	var damage := _get_attack_damage()
	if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
		owner_player.deal_player_damage_to_enemy(target, damage, {"source": "skeleton_archer", "direct": true, "allow_procs": false})
	elif target.has_method("take_damage"):
		target.take_damage(damage)
	_maybe_apply_poison(target)


func _maybe_apply_poison(target: Node) -> void:
	if poison_chance <= 0.0 or randf() >= poison_chance:
		return
	var status_owner: Node = owner_player if owner_player != null and is_instance_valid(owner_player) else null
	if target.has_method("apply_status_effect"):
		target.apply_status_effect(&"poison", status_owner)
	elif target.has_method("apply_poison_stacks"):
		target.apply_poison_stacks(1, status_owner)


func _get_attack_damage() -> float:
	var growth_multiplier := 1.0 + float(floori(alive_time)) * damage_growth_per_second
	if owner_player != null and owner_player.has_method("get_base_attack_damage"):
		return owner_player.get_base_attack_damage() * damage_inherit_multiplier * growth_multiplier
	return 6.0 * growth_multiplier


func _get_attack_interval() -> float:
	var base_interval := 1.0
	if owner_player != null:
		var owner_fire_rate := float(owner_player.get("fire_rate"))
		if owner_fire_rate > 0.0:
			base_interval = 1.0 / owner_fire_rate
		if owner_player.has_method("get_stats"):
			var stats: StatsComponent = owner_player.get_stats()
			if stats != null:
				base_interval = stats.get_attack_interval(base_interval)
	return base_interval / maxf(attack_speed_inherit_multiplier * timed_attack_speed_multiplier, 0.01)


func _get_nearest_enemy() -> Node2D:
	var best: Node2D
	var best_distance := INF
	for enemy in get_tree().get_nodes_in_group(target_group):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or not is_instance_valid(enemy_2d):
			continue
		var distance := enemy_2d.global_position.distance_to(global_position)
		if distance <= attack_range and distance < best_distance:
			best_distance = distance
			best = enemy_2d
	return best


func _play_idle(delta: float) -> void:
	_set_animation_texture(idle_texture)
	_set_frame(int(floorf(Time.get_ticks_msec() / 1000.0 * IDLE_FPS)) % FRAMES_PER_DIRECTION)


func _play_run(delta: float) -> void:
	_set_animation_texture(run_texture)
	_set_frame(int(floorf(Time.get_ticks_msec() / 1000.0 * RUN_FPS)) % FRAMES_PER_DIRECTION)


func _set_animation_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	if current_texture == texture:
		return
	current_texture = texture
	current_frame_index = -1
	current_direction_row = -1
	sprite.texture = texture
	sprite.hframes = FRAMES_PER_DIRECTION
	sprite.vframes = DIRECTION_COUNT


func _set_frame(frame_index: int) -> void:
	var direction_row := _get_direction_row(facing_direction)
	if current_frame_index == frame_index and current_direction_row == direction_row:
		return
	current_frame_index = frame_index
	current_direction_row = direction_row
	sprite.frame_coords = Vector2i(frame_index, direction_row)


func _get_direction_row(direction: Vector2) -> int:
	if direction.length_squared() <= 0.001:
		return 0

	var angle := fposmod(direction.angle(), TAU)
	return int(round(angle / (PI * 0.25))) % DIRECTION_COUNT


func _load_texture(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("Failed to load SkeletonArcher texture: %s" % path)
		return null
	return texture


func _ensure_nodes() -> void:
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.scale = SPRITE_SCALE
