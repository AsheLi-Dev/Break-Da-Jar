extends CharacterBody2D
class_name Player

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const ATTACK_PROJECTILE_FRAME := 7
const SHOCKWAVE_HIT_FRAME := 9
const SHOCKWAVE_EFFECT_DAMAGE_FRAME := 4
const SHOCKWAVE_EFFECT_FPS := 10.0
const SHOCKWAVE_WINDUP_LUNGE_DISTANCE := 72.0
const SHOCKWAVE_HIT_OFFSET := 60.0
const SLIDE_END_FPS := 30.0
const MELEE_TELEGRAPH_RADIUS_SCALE := 0.9

const ABILITY_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/ability.png")
const ATTACK_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/attack.png")
const ATTACK_ALT_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/attack_alt.png")
const DIRECTIONAL_ANIMATION_LIBRARY_BUILDER := preload("res://scripts/player/DirectionalAnimationLibraryBuilder.gd")
const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")
const FLOATING_TEXT_SCRIPT := preload("res://systems/combat/FloatingText.gd")
const HOLY_SPELL_FRAME_SIZE := Vector2i(128, 64)
const HOLY_SPELL_TEXTURE: Texture2D = preload("res://assets/vfx/holy spell/HolyNova_spritesheet.png")
const HOLY_SLASH_FRAME_SIZE := Vector2i(64, 64)
const HOLY_SLASH_TEXTURE: Texture2D = preload("res://assets/vfx/holy spell/HolySlash_A_spritesheet.png")
const HOLY_SLASH_FPS := 24.0
const IDLE_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/idle.png")
const LEVEL_UP_EFFECT_TEXTURE: Texture2D = preload("res://assets/vfx/Level Up Effect/Level Up Effect Spritesheet.png")
const ROLLING_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/rolling.png")
const SLIDE_END_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/slideend.png")
const SLIDE_SFX_PATH := "res://assets/sfx/slide.mp3"
const SLIDE_START_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/slidestart.png")
const RUN_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/run.png")
const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const ENEMY_HURT_SFX: AudioStream = preload("res://assets/sfx/enemy_hurt.wav")
const TALENT_CATALOG := preload("res://scripts/player/PlayerTalentCatalog.gd")

signal attack_hit(enemy: Node, damage_dealt: float, attack_info: Dictionary)
signal attack_started(origin: Vector2, direction: Vector2, attack_info: Dictionary)
signal enemy_killed(enemy: Node)
signal container_broken(container: Node, attack_info: Dictionary)
signal shop_container_broken(container: Node, gold_cost: int)
signal dash_started(direction: Vector2)
signal dash_ended(direction: Vector2)
signal round_started(round_index: int)
signal round_ended()
signal damage_taken(final_damage_taken: float)
signal hp_changed(current_hp: int, max_hp: int)
signal player_leveled_up(new_level: int)
signal experience_changed(current_exp: int, required_exp: int, level: int)
signal talent_points_changed(unspent_points: int, pending_points: int)
signal talent_unlocked(node_id: StringName)

enum State {
	NORMAL,
	DASHING,
	SLIDING,
}

# Movement tuning. Acceleration/friction control top-down feel.
@export var move_speed: float = 240.0
@export var acceleration: float = 1600.0
@export var friction: float = 1900.0

# Health. Enemy attacks should call take_damage(amount).
@export var max_hp: float = 100.0
var hp: float

# Holy boomerang tuning. Hold shoot for automatic fire.
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 620.0
@export var projectile_damage: float = 12.0
@export var projectile_lifetime: float = 3.0
@export var projectile_max_distance: float = 520.0
@export var projectile_return_delay: float = 0.2
@export var projectile_catch_distance: float = 22.0
@export var fire_rate: float = 1.0
@export var attack_slow_edge_frames: int = 3
@export var attack_edge_animation_fps: float = 15.0
@export var attack_fast_animation_fps: float = 36.0
@export var attack_move_speed_multiplier: float = 0.5
@export var melee_attack_radius: float = 200.0
@export var melee_telegraph_color: Color = Color(1.0, 0.9, 0.28, 0.22)

# Holy shockwave tuning. Area2D applies damage and knockback explicitly.
@export var shockwave_damage: float = 18.0
@export var shockwave_radius: float = 118.0
@export var shockwave_knockback: float = 430.0
@export var shockwave_cooldown: float = 6.0
@export var shockwave_visible_time: float = 0.16

# Dash is a short reposition. Slide is the invincible enemy-pass-through followup.
@export var dash_speed: float = 560.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.75
@export var dash_smear_count: int = 5
@export var dash_smear_lifetime: float = 0.14
@export var dash_smear_spacing: float = 12.0
@export var dash_smear_color: Color = Color(1.0, 1.0, 1.0, 0.35)
@export var dash_forward_smear_enabled: bool = true
@export var dash_forward_smear_delay_ratio: float = 0.7
@export var dash_forward_smear_distance: float = 14.0
@export var dash_forward_smear_lifetime: float = 0.08
@export var dash_forward_smear_alpha: float = 0.18
@export var slide_speed: float = 480.0
@export var slide_duration: float = 0.5
@export var slide_cancel_window: float = 0.3
@export var slide_sfx_volume_db: float = -4.0
@export var invincible_time: float = 0.3

# Collision mask bit for enemies. Layer numbers are 1-based in the editor.
@export var enemy_collision_layer_number: int = 2
@export var world_collision_layer_number: int = 1
@export var jar_collision_layer_number: int = 6
@export var animation_fps: float = 15.0
@export var movement_bounds_enabled: bool = false
@export var movement_bounds: Rect2 = Rect2()
@export var hurt_slow_time_scale: float = 0.35
@export var hurt_slow_duration: float = 0.2
@export var hurt_zoom_factor: float = 1.14
@export var hurt_zoom_duration: float = 0.18
@export var hurt_flash_color: Color = Color(1.0, 0.05, 0.02, 0.28)
@export var hurt_flash_duration: float = 0.16
@export var hurt_feedback_cooldown: float = 1.0

var slow_multiplier: float = 1.0
var slow_remaining: float = 0.0
var stats: StatsComponent
var inventory: InventoryComponent
var temporary_buffs: TemporaryBuffComponent
var level: int = 1
var experience: int = 0
var pending_talent_points: int = 0
var unspent_talent_points: int = 0
var unlocked_talents: Array[StringName] = []
var talent_slide_attack_speed_enabled: bool = false
var talent_next_attack_after_slide_enabled: bool = false
var talent_slide_damage_reduction_enabled: bool = false
var talent_max_hp_from_atk_enabled: bool = false
var talent_heal_on_kill_enabled: bool = false
var applied_max_hp_from_atk: int = 0
var next_attack_after_slide_ready: bool = false
var next_attack_damage_bonus: float = 0.0
var shop_price_multiplier: float = 1.0
var extra_rare_shop_jars_pending: int = 0
var damage_shield_active: bool = false
var state: int = State.NORMAL
var facing_direction: Vector2 = Vector2.RIGHT
var animation_direction: Vector2 = Vector2.RIGHT
var dash_direction: Vector2 = Vector2.RIGHT
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var slide_time_remaining: float = 0.0
var slide_window_remaining: float = 0.0
var invincible_remaining: float = 0.0
var fire_cooldown_remaining: float = 0.0
var shockwave_cooldown_remaining: float = 0.0
var saved_collision_mask: int = 0
var is_invincible: bool = false

var gun_pivot: Node2D
var muzzle: Marker2D
var melee_telegraph_visual: Polygon2D
var melee_attack_root: Node2D
var melee_hitbox_area: Area2D
var melee_hitbox_polygon: CollisionPolygon2D
var melee_effect_damage_preview: Sprite2D
var shockwave_attack_root: Node2D
var shockwave_area: Area2D
var shockwave_collision: CollisionShape2D
var shockwave_preview_frame: Sprite2D
var shockwave_effect_damage_preview: Sprite2D
var shockwave_visual: Polygon2D
var sprite: Sprite2D
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var animation_state: AnimationNodeStateMachinePlayback
var current_animation: StringName = &"idle"
var current_animation_name: StringName = &""
var current_animation_elapsed: float = 0.0
var action_animation: StringName = &""
var action_animation_remaining: float = 0.0
var action_animation_elapsed: float = 0.0
var pending_attack_projectile: bool = false
var pending_attack_target_position: Vector2 = Vector2.ZERO
var pending_shockwave_target_position: Vector2 = Vector2.ZERO
var slide_sfx: AudioStream
var action_direction_locked: bool = false
var action_animation_direction: Vector2 = Vector2.RIGHT
var hurt_slow_restore_token: int = 0
var hurt_slow_original_time_scale: float = 1.0
var hurt_slow_active: bool = false
var hurt_feedback_cooldown_remaining: float = 0.0


func _ready() -> void:
	add_to_group("player")
	_ensure_stats_and_items()
	hp = max_hp
	saved_collision_mask = collision_mask
	_ensure_placeholder_nodes()
	hp_changed.emit(roundi(hp), roundi(max_hp))


func _exit_tree() -> void:
	_force_restore_hurt_slow_motion()


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_facing()

	match state:
		State.NORMAL:
			_update_normal_movement(delta)
			if Input.is_action_just_pressed("dash"):
				_try_start_dash()
		State.DASHING:
			_update_dash(delta)
		State.SLIDING:
			_update_slide(delta)

	if Input.is_action_just_pressed("slide"):
		_try_start_slide()

	if Input.is_action_pressed("shoot"):
		_try_fire_projectile()

	if Input.is_action_just_pressed("skill"):
		_try_cast_shockwave()

	_update_sprite_animation(delta)


func take_damage(amount: float) -> void:
	if damage_shield_active:
		damage_shield_active = false
		return
	if is_invincible:
		return
	if stats != null and randf() < 1.0 - stats.dodge_chance_multiplier:
		return

	var final_damage: float = amount
	if stats != null:
		final_damage = float(stats.calculate_incoming_damage(amount))
	if final_damage <= 0.0:
		return
	hp = maxf(0.0, hp - final_damage)
	hp_changed.emit(roundi(hp), roundi(max_hp))
	damage_taken.emit(final_damage)
	_play_hurt_impact_feedback()
	if hp <= 0.0:
		die()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(roundi(hp), roundi(max_hp))


func lose_hp(amount: float) -> float:
	if amount <= 0.0:
		return 0.0

	var old_hp: float = hp
	hp = maxf(0.0, hp - amount)
	hp_changed.emit(roundi(hp), roundi(max_hp))
	if hp <= 0.0:
		die()
	return old_hp - hp


func get_stats() -> StatsComponent:
	return stats


func get_temporary_buffs() -> TemporaryBuffComponent:
	return temporary_buffs


func get_base_attack_damage() -> float:
	return projectile_damage


func grant_timed_invincibility(duration: float) -> void:
	if duration <= 0.0:
		return

	invincible_remaining = maxf(invincible_remaining, duration)
	is_invincible = true


func grant_damage_shield() -> void:
	damage_shield_active = true


func has_damage_shield() -> bool:
	return damage_shield_active


func gain_experience(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount
	while experience >= _get_required_exp_for_next_level():
		experience -= _get_required_exp_for_next_level()
		_level_up()

	experience_changed.emit(experience, _get_required_exp_for_next_level(), level)


func settle_round_level_rewards() -> void:
	if pending_talent_points <= 0:
		return

	unspent_talent_points += pending_talent_points
	pending_talent_points = 0
	talent_points_changed.emit(unspent_talent_points, pending_talent_points)


func get_required_exp_for_next_level() -> int:
	return _get_required_exp_for_next_level()


func get_talent_node_ids() -> Array[StringName]:
	return TALENT_CATALOG.node_ids()


func get_talent_node_grid_position(node_id: StringName) -> Vector2i:
	return TALENT_CATALOG.grid_position(node_id)


func get_talent_display_name(node_id: StringName) -> String:
	var definition: Dictionary = _get_talent_definition(node_id)
	return String(definition.get("name", "+1 ATK"))


func get_talent_description(node_id: StringName) -> String:
	var definition: Dictionary = _get_talent_definition(node_id)
	return String(definition.get("description", "+1 ATK"))


func get_talent_connections() -> Array:
	return TALENT_CATALOG.connections()


func can_unlock_talent(node_id: StringName) -> bool:
	if unspent_talent_points <= 0:
		return false
	if unlocked_talents.has(node_id):
		return false

	var coord: Vector2i = get_talent_node_grid_position(node_id)
	if not _is_talent_coord_valid(coord):
		return false
	if _is_talent_start_coord(coord):
		return true

	for neighbor in _get_talent_neighbor_coords(coord):
		if unlocked_talents.has(_get_talent_node_id(neighbor)):
			return true

	return false


func unlock_talent(node_id: StringName) -> bool:
	if not can_unlock_talent(node_id):
		return false

	unspent_talent_points -= 1
	unlocked_talents.append(node_id)
	_apply_talent_effect(node_id)
	talent_unlocked.emit(node_id)
	talent_points_changed.emit(unspent_talent_points, pending_talent_points)
	return true


func add_item(item: ItemDefinition) -> void:
	if inventory != null:
		inventory.add_item(item)


func get_item_count(item_id: StringName) -> int:
	return inventory.get_item_count(item_id) if inventory != null else 0


func add_shop_price_multiplier(multiplier: float) -> void:
	shop_price_multiplier *= maxf(multiplier, 0.01)
	if get_tree().current_scene != null and get_tree().current_scene.has_method("refresh_shop_container_prices"):
		get_tree().current_scene.refresh_shop_container_prices()


func get_shop_price_multiplier() -> float:
	return shop_price_multiplier


func queue_extra_rare_shop_jar(amount: int = 1) -> void:
	extra_rare_shop_jars_pending += maxi(amount, 0)


func consume_extra_rare_shop_jars() -> int:
	var amount: int = extra_rare_shop_jars_pending
	extra_rare_shop_jars_pending = 0
	return amount


func add_next_attack_damage_bonus(bonus: float) -> void:
	next_attack_damage_bonus += maxf(bonus, 0.0)


func deal_player_damage_to_enemy(enemy: Node, raw_damage: float, attack_info: Dictionary = {}) -> float:
	if enemy == null or not enemy.has_method("take_damage"):
		return 0.0

	var final_damage: float = raw_damage
	if stats != null:
		if _should_consume_next_slide_attack(attack_info):
			final_damage *= 1.5
			next_attack_after_slide_ready = false
			attack_info["talent_slide_attack_bonus"] = true
		if bool(attack_info.get("direct", true)) and next_attack_damage_bonus > 0.0:
			final_damage *= 1.0 + next_attack_damage_bonus
			attack_info["next_attack_damage_bonus"] = next_attack_damage_bonus
			next_attack_damage_bonus = 0.0
		final_damage *= stats.get_damage_multiplier()
		if bool(attack_info.get("direct", true)):
			final_damage *= _get_conditional_direct_damage_multiplier(enemy)
		if bool(attack_info.get("allow_crit", true)) and randf() < stats.critical_chance:
			final_damage *= 2.0 + stats.critical_damage_bonus
			attack_info["critical"] = true
			print("Critical hit")

	var damage_dealt: float = enemy.take_damage(final_damage, self, attack_info)
	if damage_dealt <= 0.0:
		damage_dealt = final_damage

	_play_enemy_hit_feedback(enemy, damage_dealt, attack_info)

	if bool(attack_info.get("direct", true)):
		_apply_attack_status_procs(enemy)
		if stats != null and stats.lifesteal > 0.0:
			var heal_amount: float = damage_dealt * stats.lifesteal
			heal(heal_amount)
			print("Lifesteal heals %s" % heal_amount)

	if bool(attack_info.get("allow_procs", true)):
		_try_trigger_talent_fireball(enemy)
		attack_hit.emit(enemy, damage_dealt, attack_info)

	return damage_dealt


func _play_enemy_hit_feedback(enemy: Node, damage_dealt: float, attack_info: Dictionary) -> void:
	var enemy_2d := enemy as Node2D
	if enemy_2d == null:
		return

	var is_critical := bool(attack_info.get("critical", false))
	_spawn_damage_popup(enemy_2d.global_position + Vector2(0.0, -42.0), roundi(damage_dealt), is_critical)
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	SFX_PLAYER.play_2d(parent, ENEMY_HURT_SFX, enemy_2d.global_position, -3.0, 0.94, 1.12)
	if is_critical:
		_start_camera_shake(4.0, 0.1)

	if bool(attack_info.get("direct", true)) and String(attack_info.get("source", "")) != "shockwave":
		if enemy.has_method("apply_knockback"):
			var knockback_direction := (enemy_2d.global_position - global_position).normalized()
			if knockback_direction.length_squared() <= 0.001:
				knockback_direction = facing_direction
			enemy.call("apply_knockback", knockback_direction * 125.0)


func _spawn_damage_popup(spawn_position: Vector2, amount: int, is_critical: bool) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return

	var popup := FLOATING_TEXT_SCRIPT.new() as FloatingText
	var color := Color(1.0, 0.88, 0.24) if is_critical else Color(0.95, 0.97, 1.0)
	var scale_value := 1.2 if is_critical else 1.0
	popup.setup(str(amount), spawn_position, color, scale_value)
	parent.add_child(popup)


func _start_camera_shake(magnitude: float, duration: float) -> void:
	var current_camera := get_viewport().get_camera_2d()
	if current_camera != null and current_camera.has_method("start_shake"):
		current_camera.call("start_shake", magnitude, duration)


func _play_hurt_impact_feedback() -> void:
	if hurt_feedback_cooldown_remaining > 0.0:
		return

	hurt_feedback_cooldown_remaining = hurt_feedback_cooldown
	_start_camera_shake(6.0, hurt_zoom_duration)
	var current_camera := get_viewport().get_camera_2d()
	if current_camera != null and current_camera.has_method("start_zoom_in"):
		current_camera.call("start_zoom_in", hurt_zoom_factor, hurt_zoom_duration)
	_flash_hurt_screen()
	_start_hurt_slow_motion()


func _start_hurt_slow_motion() -> void:
	hurt_slow_restore_token += 1
	var restore_token := hurt_slow_restore_token
	if not hurt_slow_active:
		hurt_slow_original_time_scale = Engine.time_scale
	hurt_slow_active = true
	Engine.time_scale = minf(Engine.time_scale, hurt_slow_time_scale)
	var tree := get_tree()
	if tree == null:
		return
	tree.create_timer(hurt_slow_duration, true, false, true).timeout.connect(_restore_hurt_slow_motion.bind(restore_token))


func _restore_hurt_slow_motion(restore_token: int) -> void:
	if restore_token != hurt_slow_restore_token:
		return
	_force_restore_hurt_slow_motion()


func _force_restore_hurt_slow_motion() -> void:
	if not hurt_slow_active:
		return

	Engine.time_scale = hurt_slow_original_time_scale
	hurt_slow_active = false


func _flash_hurt_screen() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return

	var layer := CanvasLayer.new()
	layer.name = "HurtFlash"
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.current_scene.add_child(layer)

	var rect := ColorRect.new()
	rect.color = hurt_flash_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)

	var tween := layer.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ignore_time_scale(true)
	tween.tween_property(rect, "color:a", 0.0, hurt_flash_duration)
	tween.finished.connect(Callable(layer, "queue_free"))


func notify_enemy_killed(enemy: Node) -> void:
	if talent_heal_on_kill_enabled:
		heal(5.0)
	enemy_killed.emit(enemy)


func add_gold(amount: int, reason: String = "") -> void:
	if amount <= 0 or get_tree().current_scene == null:
		return
	if get_tree().current_scene.has_method("add_player_gold"):
		get_tree().current_scene.add_player_gold(amount, reason)


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = minf(slow_multiplier, clampf(multiplier, 0.05, 1.0))
	slow_remaining = maxf(slow_remaining, duration)


func die() -> void:
	_force_restore_hurt_slow_motion()
	queue_free()


func _update_timers(delta: float) -> void:
	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
	shockwave_cooldown_remaining = maxf(0.0, shockwave_cooldown_remaining - delta)
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - delta)
	hurt_feedback_cooldown_remaining = maxf(0.0, hurt_feedback_cooldown_remaining - delta)
	slide_window_remaining = maxf(0.0, slide_window_remaining - delta)
	invincible_remaining = maxf(0.0, invincible_remaining - delta)
	slow_remaining = maxf(0.0, slow_remaining - delta)
	if slow_remaining <= 0.0:
		slow_multiplier = 1.0
	is_invincible = invincible_remaining > 0.0


func _update_normal_movement(delta: float) -> void:
	if _is_shockwave_windup_active():
		var lunge_speed := SHOCKWAVE_WINDUP_LUNGE_DISTANCE / maxf(_get_shockwave_hit_time(), 0.001)
		velocity = action_animation_direction * lunge_speed
		move_and_slide()
		_clamp_to_movement_bounds()
		return

	var input_direction: Vector2 = _get_move_input()
	var target_speed: float = move_speed * slow_multiplier
	if stats != null:
		target_speed = stats.get_move_speed(move_speed) * slow_multiplier
	if _is_attack_movement_slowed():
		target_speed *= attack_move_speed_multiplier

	if input_direction.length_squared() > 0.0:
		velocity = velocity.move_toward(input_direction * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_clamp_to_movement_bounds()


func _try_start_dash() -> void:
	if dash_cooldown_remaining > 0.0:
		return
	if not _can_cancel_current_action():
		return

	var input_direction: Vector2 = _get_move_input()
	if input_direction.length_squared() > 0.0:
		dash_direction = input_direction.normalized()
	else:
		dash_direction = facing_direction.normalized()

	_cancel_current_action()
	state = State.DASHING
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	slide_window_remaining = dash_duration + slide_cancel_window
	velocity = dash_direction * dash_speed
	dash_started.emit(dash_direction)
	_spawn_dash_smear()
	_schedule_forward_dash_smear()


func _update_dash(delta: float) -> void:
	dash_time_remaining -= delta
	velocity = dash_direction * dash_speed
	move_and_slide()
	_clamp_to_movement_bounds()

	if dash_time_remaining <= 0.0:
		state = State.NORMAL
		dash_ended.emit(dash_direction)


func _try_start_slide() -> void:
	if state == State.SLIDING or slide_window_remaining <= 0.0:
		return
	if not _can_cancel_current_action():
		return

	if dash_direction.length_squared() <= 0.001:
		dash_direction = facing_direction.normalized()

	_cancel_current_action()
	state = State.SLIDING
	slide_time_remaining = slide_duration
	slide_window_remaining = 0.0
	invincible_remaining = maxf(invincible_remaining, invincible_time)
	is_invincible = true
	velocity = dash_direction * slide_speed
	_play_slide_sfx()

	# Slide-through-enemies: temporarily stop colliding with enemy bodies.
	saved_collision_mask = collision_mask
	set_collision_mask_value(enemy_collision_layer_number, false)


func _update_slide(delta: float) -> void:
	slide_time_remaining -= delta
	var progress: float = _get_slide_progress()
	var current_slide_speed: float = lerpf(slide_speed, move_speed, progress)
	velocity = dash_direction * current_slide_speed
	move_and_slide()
	_clamp_to_movement_bounds()

	# Optional future upgrade: add a DashHitbox Area2D to damage or knock back enemies along the slide path.
	if slide_time_remaining <= 0.0:
		_finish_slide(true)


func _get_slide_progress() -> float:
	return clampf(1.0 - slide_time_remaining / maxf(slide_duration, 0.001), 0.0, 1.0)


func _is_slide_attack_cancel_window() -> bool:
	return state == State.SLIDING and _get_slide_progress() >= 0.5


func _can_start_attack_now() -> bool:
	if state == State.SLIDING:
		return _is_slide_attack_cancel_window()
	return _can_cancel_current_action()


func _interrupt_slide_for_attack() -> void:
	if state == State.SLIDING:
		_finish_slide(false)


func _finish_slide(play_recovery: bool) -> void:
	if state != State.SLIDING:
		return

	state = State.NORMAL
	slide_time_remaining = 0.0
	collision_mask = saved_collision_mask
	_apply_slide_finished_talents()
	dash_ended.emit(dash_direction)
	if play_recovery:
		_play_action_animation_with_direction(&"slide_end", float(FRAMES_PER_DIRECTION) / SLIDE_END_FPS, dash_direction)


func _try_fire_projectile() -> void:
	if fire_cooldown_remaining > 0.0:
		return
	if not _can_start_attack_now():
		return
	_interrupt_slide_for_attack()

	fire_cooldown_remaining = _get_fire_interval()
	pending_attack_projectile = true
	pending_attack_target_position = get_global_mouse_position()
	_play_action_animation_with_direction(&"attack", _get_action_animation_time(&"attack"), facing_direction)
	_show_melee_telegraph(facing_direction)
	_queue_holy_slash_effect(facing_direction)


func _try_cast_shockwave() -> void:
	if shockwave_cooldown_remaining > 0.0:
		return
	if not _can_start_attack_now():
		return
	_interrupt_slide_for_attack()

	shockwave_cooldown_remaining = shockwave_cooldown
	pending_shockwave_target_position = get_global_mouse_position()
	_play_action_animation_with_direction(&"ability", _get_action_animation_time(&"ability"), facing_direction)
	get_tree().create_timer(_get_shockwave_hit_time()).timeout.connect(_start_shockwave_effect)


func _start_shockwave_effect() -> void:
	var shockwave_center := _get_shockwave_center()
	shockwave_visual.visible = true
	shockwave_visual.global_position = shockwave_center
	_play_holy_spell_effect(shockwave_center)
	_start_camera_shake(5.0, 0.12)
	get_tree().create_timer(shockwave_visible_time).timeout.connect(_hide_shockwave_visual)
	get_tree().create_timer(_get_shockwave_effect_damage_time()).timeout.connect(_perform_shockwave_attack.bind(shockwave_center))


func _perform_shockwave_attack(shockwave_center: Vector2) -> void:
	var active_radius := _get_shockwave_radius()

	for body in get_tree().get_nodes_in_group("enemy"):
		if not body.is_in_group("enemy"):
			continue
		var body_2d: Node2D = body as Node2D
		if body_2d == null or body_2d.global_position.distance_to(shockwave_center) > active_radius:
			continue

		if body.has_method("take_damage"):
			deal_player_damage_to_enemy(body, shockwave_damage, {"source": "shockwave", "direct": true, "allow_procs": true})

		if body.has_method("apply_knockback"):
			var knockback_direction: Vector2 = (body_2d.global_position - shockwave_center).normalized()
			if knockback_direction.length_squared() <= 0.001:
				knockback_direction = facing_direction
			body.call("apply_knockback", knockback_direction * shockwave_knockback)

	for container in get_tree().get_nodes_in_group("container"):
		var container_2d := container as Node2D
		if container_2d == null or container_2d.global_position.distance_to(shockwave_center) > active_radius:
			continue
		if container is BreakableContainer and container.is_shop_container:
			continue
		if container.has_method("take_damage"):
			container.take_damage(shockwave_damage, {"source": "player_attack", "owner": self})


func _get_shockwave_center() -> Vector2:
	var local_offset := Vector2.ZERO
	if shockwave_attack_root != null:
		local_offset = shockwave_attack_root.position
		if shockwave_area != null:
			local_offset += shockwave_area.position
		if shockwave_collision != null:
			local_offset += shockwave_collision.position

	return pending_shockwave_target_position + local_offset


func _get_shockwave_direction_angle() -> float:
	return 0.0


func _get_direction_angle(direction: Vector2) -> float:
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	if direction.length_squared() <= 0.001:
		return 0.0

	return direction.angle()


func _get_shockwave_radius() -> float:
	if shockwave_collision != null:
		var circle_shape := shockwave_collision.shape as CircleShape2D
		if circle_shape != null:
			return circle_shape.radius * maxf(absf(shockwave_collision.scale.x), absf(shockwave_collision.scale.y))

	return shockwave_radius


func _get_shockwave_hit_time() -> float:
	return float(SHOCKWAVE_HIT_FRAME - 1) / animation_fps


func _get_shockwave_effect_damage_time() -> float:
	return float(SHOCKWAVE_EFFECT_DAMAGE_FRAME - 1) / SHOCKWAVE_EFFECT_FPS


func _is_shockwave_windup_active() -> bool:
	return action_animation == &"ability" and action_animation_elapsed < _get_shockwave_hit_time()


func _spawn_projectile(spawn_position: Vector2, direction: Vector2) -> Projectile:
	var projectile: Projectile
	if projectile_scene != null:
		projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		projectile = Projectile.new()

	projectile.global_position = spawn_position
	get_tree().current_scene.add_child(projectile)
	projectile.direction = direction
	return projectile


func _spawn_dash_smear() -> void:
	if sprite == null or sprite.texture == null:
		return

	var count: int = maxi(dash_smear_count, 0)
	for index in range(count):
		var ghost := Sprite2D.new()
		ghost.name = "DashSmear"
		ghost.texture = sprite.texture
		ghost.centered = sprite.centered
		ghost.region_enabled = sprite.region_enabled
		ghost.region_rect = sprite.region_rect
		ghost.global_position = global_position - dash_direction.normalized() * dash_smear_spacing * float(index + 1)
		ghost.global_rotation = sprite.global_rotation
		ghost.global_scale = sprite.global_scale
		ghost.modulate = Color(
			dash_smear_color.r,
			dash_smear_color.g,
			dash_smear_color.b,
			dash_smear_color.a * (1.0 - float(index) / float(maxi(count, 1)))
		)
		ghost.z_index = sprite.z_index - 1
		get_tree().current_scene.add_child(ghost)

		var tween := ghost.create_tween()
		tween.tween_property(ghost, "modulate:a", 0.0, dash_smear_lifetime)
		tween.finished.connect(ghost.queue_free)


func _schedule_forward_dash_smear() -> void:
	if not dash_forward_smear_enabled:
		return

	var delay: float = dash_duration * clampf(dash_forward_smear_delay_ratio, 0.0, 1.0)
	get_tree().create_timer(delay).timeout.connect(_spawn_forward_dash_smear)


func _spawn_forward_dash_smear() -> void:
	if state != State.DASHING:
		return
	if sprite == null or sprite.texture == null:
		return

	var ghost := Sprite2D.new()
	ghost.name = "DashForwardSmear"
	ghost.texture = sprite.texture
	ghost.centered = sprite.centered
	ghost.region_enabled = sprite.region_enabled
	ghost.region_rect = sprite.region_rect
	ghost.global_position = global_position + dash_direction.normalized() * dash_forward_smear_distance
	ghost.global_rotation = sprite.global_rotation
	ghost.global_scale = sprite.global_scale
	ghost.modulate = Color(
		dash_smear_color.r,
		dash_smear_color.g,
		dash_smear_color.b,
		dash_forward_smear_alpha
	)
	ghost.z_index = sprite.z_index - 1
	get_tree().current_scene.add_child(ghost)

	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, dash_forward_smear_lifetime)
	tween.finished.connect(ghost.queue_free)


func _hide_shockwave_visual() -> void:
	if is_instance_valid(shockwave_visual):
		shockwave_visual.visible = false
		shockwave_visual.position = Vector2.ZERO


func _update_facing() -> void:
	var mouse_offset: Vector2 = get_global_mouse_position() - global_position
	if mouse_offset.length_squared() > 0.001:
		facing_direction = mouse_offset.normalized()
	elif _get_move_input().length_squared() > 0.0:
		facing_direction = _get_move_input().normalized()

	gun_pivot.rotation = facing_direction.angle()
	_update_animation_direction()


func _update_animation_direction() -> void:
	if action_direction_locked:
		animation_direction = action_animation_direction
		return

	if _uses_movement_animation_direction():
		var move_direction: Vector2 = _get_move_input()
		if state == State.DASHING or state == State.SLIDING:
			move_direction = dash_direction
		elif velocity.length_squared() > 16.0:
			move_direction = velocity.normalized()

		if move_direction.length_squared() > 0.001:
			animation_direction = move_direction.normalized()
	else:
		animation_direction = facing_direction


func _uses_movement_animation_direction() -> bool:
	return current_animation == &"run" or current_animation == &"rolling" or current_animation == &"slide_start" or current_animation == &"slide_hold" or current_animation == &"slide_end"


func _play_action_animation(animation_name: StringName, duration: float) -> void:
	action_direction_locked = false
	action_animation = animation_name
	action_animation_remaining = duration
	action_animation_elapsed = 0.0
	_play_sprite_animation(animation_name, true)


func _play_action_animation_with_direction(animation_name: StringName, duration: float, direction: Vector2) -> void:
	action_direction_locked = true
	action_animation_direction = direction.normalized()
	animation_direction = action_animation_direction
	action_animation = animation_name
	action_animation_remaining = duration
	action_animation_elapsed = 0.0
	_play_sprite_animation(animation_name, true)


func _get_full_animation_time() -> float:
	return float(FRAMES_PER_DIRECTION) / animation_fps


func _get_action_animation_time(animation_name: StringName) -> float:
	if animation_name == &"attack":
		return _get_fire_interval()

	return _get_full_animation_time()


func _update_sprite_animation(delta: float) -> void:
	if action_animation_remaining > 0.0:
		action_animation_elapsed += delta
		action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
		_maybe_spawn_attack_projectile()
		if action_animation_remaining <= 0.0:
			action_direction_locked = false
		return

	var wanted_animation: StringName = _get_locomotion_animation()
	_play_sprite_animation(wanted_animation)
	current_animation_elapsed += delta


func _get_locomotion_animation() -> StringName:
	if state == State.SLIDING:
		return &"slide_start" if _get_slide_progress() < 0.5 else &"slide_hold"
	if state == State.DASHING:
		if velocity.length_squared() > 16.0:
			return &"run"
		return &"idle"
	if velocity.length_squared() > 16.0:
		return &"run"

	return &"idle"


func _is_attack_movement_slowed() -> bool:
	return fire_cooldown_remaining > 0.0


func _play_sprite_animation(animation_name: StringName, force_restart: bool = false) -> void:
	var direction_row: int = _get_direction_row(animation_direction)
	var tree_animation_name: StringName = StringName("%s_%d" % [String(animation_name), direction_row])
	if current_animation_name == tree_animation_name and not force_restart:
		return

	if current_animation == &"attack" and animation_name != &"attack":
		pending_attack_projectile = false
		_hide_melee_telegraph()

	current_animation = animation_name
	current_animation_name = tree_animation_name
	current_animation_elapsed = 0.0
	if animation_state != null:
		if force_restart:
			animation_state.start(String(tree_animation_name), true)
		else:
			animation_state.travel(String(tree_animation_name))
	else:
		animation_player.play(String(tree_animation_name))


func _maybe_spawn_attack_projectile() -> void:
	if not pending_attack_projectile or current_animation != &"attack":
		return

	if action_animation_elapsed < _get_attack_projectile_time():
		return

	pending_attack_projectile = false
	_hide_melee_telegraph()
	_perform_melee_attack_at(pending_attack_target_position)


func _get_attack_projectile_time() -> float:
	var time: float = 0.0
	for frame in range(ATTACK_PROJECTILE_FRAME):
		time += _get_attack_windup_frame_duration(frame)

	return time


func _get_fire_interval() -> float:
	var base_interval: float = 1.0 / maxf(fire_rate, 0.01)
	if stats != null:
		return stats.get_attack_interval(base_interval)
	return base_interval


func _can_cancel_current_action() -> bool:
	if action_animation_remaining <= 0.0:
		return true
	if action_animation == &"slide_end":
		return true
	if action_animation != &"attack":
		return false

	return action_animation_elapsed >= _get_attack_projectile_time()


func _cancel_current_action() -> void:
	if action_animation_remaining <= 0.0:
		return

	action_animation = &""
	action_animation_remaining = 0.0
	action_animation_elapsed = 0.0
	pending_attack_projectile = false
	action_direction_locked = false
	_hide_melee_telegraph()


func _spawn_holy_bolt_at(target_position: Vector2) -> void:
	var direction: Vector2 = target_position - muzzle.global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()

	var projectile: Projectile = _spawn_projectile(muzzle.global_position, direction)
	projectile.owner_player = self
	projectile.collision_mask = 0
	projectile.set_collision_mask_value(enemy_collision_layer_number, true)
	projectile.set_collision_mask_value(world_collision_layer_number, true)
	projectile.set_collision_mask_value(jar_collision_layer_number, true)
	projectile.setup(direction, projectile_damage, projectile_speed, projectile_lifetime, &"enemy")
	projectile.enable_boomerang(self, projectile_max_distance, projectile_return_delay, projectile_catch_distance)
	attack_started.emit(muzzle.global_position, direction, {"source": "projectile", "direct": true})


func _perform_melee_attack_at(target_position: Vector2) -> void:
	var direction: Vector2 = target_position - global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()

	var attack_info := {"source": "player_attack", "direct": true, "allow_procs": true}
	attack_started.emit(global_position, direction, attack_info)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or not _is_target_in_melee_hitbox(enemy_2d.global_position, direction):
			continue
		if enemy.has_method("take_damage"):
			deal_player_damage_to_enemy(enemy, projectile_damage, attack_info.duplicate())

	for container in get_tree().get_nodes_in_group("container"):
		var container_2d := container as Node2D
		if container_2d == null or not _is_target_in_melee_hitbox(container_2d.global_position, direction):
			continue
		if container.has_method("take_damage"):
			container.take_damage(projectile_damage, {"source": "player_attack", "owner": self})


func _is_target_in_melee_hitbox(target_position: Vector2, direction: Vector2) -> bool:
	if melee_hitbox_polygon == null:
		return _is_target_in_melee_arc(target_position, direction, melee_attack_radius)

	var local_offset := Vector2.ZERO
	if melee_attack_root != null:
		local_offset += melee_attack_root.position
	if melee_hitbox_area != null:
		local_offset += melee_hitbox_area.position
	local_offset += melee_hitbox_polygon.position

	var angle := _get_direction_angle(direction)
	var local_target := target_position - (global_position + local_offset.rotated(angle))
	local_target = local_target.rotated(-angle)
	local_target = Vector2(
		local_target.x / maxf(absf(melee_hitbox_polygon.scale.x), 0.001),
		local_target.y / maxf(absf(melee_hitbox_polygon.scale.y), 0.001)
	)
	return _is_point_in_polygon(local_target, melee_hitbox_polygon.polygon)


func _is_target_in_melee_arc(target_position: Vector2, direction: Vector2, radius: float) -> bool:
	var offset := target_position - global_position
	if offset.length_squared() > radius * radius:
		return false
	if offset.length_squared() <= 0.001:
		return true
	return direction.dot(offset.normalized()) >= 0.0


func _is_point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3:
		return false

	var inside := false
	var previous_index := polygon.size() - 1
	for index in range(polygon.size()):
		var current := polygon[index]
		var previous := polygon[previous_index]
		var intersects := (current.y > point.y) != (previous.y > point.y)
		if intersects:
			var crossing_x := (previous.x - current.x) * (point.y - current.y) / (previous.y - current.y) + current.x
			if point.x < crossing_x:
				inside = not inside
		previous_index = index

	return inside


func _show_melee_telegraph(direction: Vector2) -> void:
	if melee_telegraph_visual == null:
		return
	if direction.length_squared() <= 0.001:
		direction = facing_direction

	melee_telegraph_visual.polygon = _semicircle_polygon(_get_melee_telegraph_radius(), 24)
	melee_telegraph_visual.rotation = direction.angle()
	melee_telegraph_visual.color = melee_telegraph_color
	melee_telegraph_visual.visible = true


func _get_melee_telegraph_radius() -> float:
	return melee_attack_radius * MELEE_TELEGRAPH_RADIUS_SCALE


func _hide_melee_telegraph() -> void:
	if melee_telegraph_visual != null:
		melee_telegraph_visual.visible = false


func emit_container_broken(container: Node, attack_info: Dictionary = {}) -> void:
	container_broken.emit(container, attack_info)


func emit_shop_container_broken(container: Node, gold_cost: int) -> void:
	shop_container_broken.emit(container, gold_cost)


func emit_round_started(round_index: int = 0) -> void:
	round_started.emit(round_index)


func emit_round_ended() -> void:
	round_ended.emit()
	if temporary_buffs != null:
		temporary_buffs.clear_round_buffs()


func _get_required_exp_for_next_level() -> int:
	return 10 + (level - 1) * 5


func _level_up() -> void:
	level += 1
	pending_talent_points += 1
	_play_level_up_effect()
	talent_points_changed.emit(unspent_talent_points, pending_talent_points)
	player_leveled_up.emit(level)


func _play_level_up_effect() -> void:
	_play_spritesheet_effect(
		LEVEL_UP_EFFECT_TEXTURE,
		&"level_up",
		global_position + Vector2(0.0, -96.0),
		10.0,
		Vector2(3.0, 3.0)
	)


func _play_holy_spell_effect(spawn_position: Vector2) -> void:
	var effect_position := spawn_position
	var effect_scale := Vector2.ONE * (_get_shockwave_radius() * 2.0 / float(HOLY_SPELL_FRAME_SIZE.x))
	if shockwave_effect_damage_preview != null:
		effect_position += shockwave_effect_damage_preview.position.rotated(_get_shockwave_direction_angle())
		effect_scale = shockwave_effect_damage_preview.scale
	_play_spritesheet_effect(HOLY_SPELL_TEXTURE, &"holy_spell", effect_position, SHOCKWAVE_EFFECT_FPS, effect_scale, HOLY_SPELL_FRAME_SIZE)


func _queue_holy_slash_effect(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	direction = direction.normalized()

	var delay := maxf(_get_attack_projectile_time() - 1.0 / HOLY_SLASH_FPS, 0.0)
	get_tree().create_timer(delay).timeout.connect(_play_holy_slash_effect.bind(global_position, direction))


func _play_holy_slash_effect(spawn_position: Vector2, direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	direction = direction.normalized()

	var effect_position := spawn_position + direction * (melee_attack_radius * 0.5)
	var effect_scale := Vector2.ONE * (melee_attack_radius * 2.0 / float(HOLY_SLASH_FRAME_SIZE.x))
	if melee_effect_damage_preview != null:
		var local_offset := Vector2.ZERO
		if melee_attack_root != null:
			local_offset += melee_attack_root.position
		local_offset += melee_effect_damage_preview.position
		effect_position = spawn_position + local_offset.rotated(direction.angle())
		effect_scale = melee_effect_damage_preview.scale
	_play_spritesheet_effect(
		HOLY_SLASH_TEXTURE,
		&"holy_slash",
		effect_position,
		HOLY_SLASH_FPS,
		effect_scale,
		HOLY_SLASH_FRAME_SIZE,
		direction.angle()
	)


func _play_spritesheet_effect(
	effect_texture: Texture2D,
	animation_name: StringName,
	spawn_position: Vector2,
	fps: float,
	effect_scale: Vector2 = Vector2.ONE,
	frame_size: Vector2i = FRAME_SIZE,
	effect_rotation: float = 0.0
) -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, fps)

	var frame_count := int(effect_texture.get_width() / frame_size.x)
	for frame_index in range(frame_count):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = effect_texture
		frame_texture.region = Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
		sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = sprite_frames
	effect.animation = animation_name
	effect.centered = true
	effect.scale = effect_scale
	effect.rotation = effect_rotation
	effect.z_index = 20
	get_parent().add_child(effect)
	effect.global_position = spawn_position
	effect.animation_finished.connect(effect.queue_free)
	effect.play()


func _get_talent_definition(node_id: StringName) -> Dictionary:
	return TALENT_CATALOG.definition(node_id)


func _apply_talent_effect(node_id: StringName) -> void:
	var definition: Dictionary = _get_talent_definition(node_id)
	var effect: StringName = StringName(definition.get("effect", &""))
	match effect:
		&"slide_attack_speed":
			talent_slide_attack_speed_enabled = true
		&"next_slide_attack":
			talent_next_attack_after_slide_enabled = true
		&"slide_damage_reduction":
			talent_slide_damage_reduction_enabled = true
		&"max_hp_from_atk":
			talent_max_hp_from_atk_enabled = true
			_update_max_hp_from_atk_talent()
		&"heal_on_kill":
			talent_heal_on_kill_enabled = true
		_:
			if stats != null:
				stats.apply_modifier(
					StringName(definition.get("stat", &"atk")),
					StringName(definition.get("operation", &"add")),
					float(definition.get("value", 1.0))
				)


func _apply_slide_finished_talents() -> void:
	if talent_slide_attack_speed_enabled and temporary_buffs != null:
		temporary_buffs.add_timed_stat_buff(&"talent_slide_attack_speed", &"attack_speed_bonus", 0.2, 3.0, 1)
	if talent_slide_damage_reduction_enabled and temporary_buffs != null:
		temporary_buffs.add_timed_stat_buff(&"talent_slide_damage_reduction", &"damage_reduction_bonus", 0.2, 2.0, 1)
	if talent_next_attack_after_slide_enabled:
		next_attack_after_slide_ready = true


func _update_max_hp_from_atk_talent() -> void:
	if not talent_max_hp_from_atk_enabled or stats == null:
		return

	var wanted_bonus: int = maxi(stats.atk, 0)
	var delta: int = wanted_bonus - applied_max_hp_from_atk
	if delta == 0:
		return

	applied_max_hp_from_atk = wanted_bonus
	stats.apply_modifier(&"max_hp", &"add", float(delta))


func _should_consume_next_slide_attack(attack_info: Dictionary) -> bool:
	if not next_attack_after_slide_ready:
		return false
	if not bool(attack_info.get("direct", true)):
		return false
	return StringName(attack_info.get("source", &"")) == &"projectile"


func _get_conditional_direct_damage_multiplier(enemy: Node) -> float:
	if stats == null:
		return 1.0

	var multiplier: float = 1.0
	if stats.elite_direct_damage_bonus > 0.0 and _is_elite_enemy(enemy):
		multiplier *= 1.0 + stats.elite_direct_damage_bonus

	var hp_fraction: float = _get_enemy_hp_fraction(enemy)
	if stats.high_hp_direct_damage_bonus > 0.0 and hp_fraction > 0.75:
		multiplier *= 1.0 + stats.high_hp_direct_damage_bonus
	if stats.low_hp_direct_damage_bonus > 0.0 and hp_fraction < 0.25:
		multiplier *= 1.0 + stats.low_hp_direct_damage_bonus
	var distance: float = _get_distance_to_enemy(enemy)
	if stats.nearby_direct_damage_bonus > 0.0 and distance <= 180.0:
		multiplier *= 1.0 + stats.nearby_direct_damage_bonus
	if stats.distant_direct_damage_bonus > 0.0 and distance >= 360.0:
		multiplier *= 1.0 + stats.distant_direct_damage_bonus
	if stats.bleeding_direct_damage_bonus > 0.0 and _enemy_has_status(enemy, &"bleeding"):
		multiplier *= 1.0 + stats.bleeding_direct_damage_bonus
	return multiplier


func _is_elite_enemy(enemy: Node) -> bool:
	if enemy == null:
		return false
	var enemy_base := enemy as EnemyBase
	if enemy_base != null:
		return enemy_base.is_elite
	return enemy is EliteBrute


func _get_enemy_hp_fraction(enemy: Node) -> float:
	if enemy == null:
		return 1.0
	var enemy_base := enemy as EnemyBase
	if enemy_base == null:
		return 1.0
	if enemy_base.max_hp <= 0.0:
		return 1.0
	return clampf(enemy_base.hp / enemy_base.max_hp, 0.0, 1.0)


func _get_distance_to_enemy(enemy: Node) -> float:
	var enemy_2d := enemy as Node2D
	if enemy_2d == null:
		return 0.0
	return global_position.distance_to(enemy_2d.global_position)


func _enemy_has_status(enemy: Node, status_id: StringName) -> bool:
	return enemy != null and enemy.has_method("has_status") and enemy.has_status(status_id)


func _try_trigger_talent_fireball(enemy: Node) -> void:
	if stats == null or stats.fireball_chance <= 0.0:
		return
	if randf() >= stats.fireball_chance:
		return

	var enemy_2d := enemy as Node2D
	if enemy_2d == null:
		return

	_launch_talent_fireball(global_position, enemy_2d.global_position)


func _launch_talent_fireball(start_position: Vector2, target_position: Vector2) -> void:
	if get_tree().current_scene == null:
		return

	var direction: Vector2 = target_position - start_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()

	var final_damage: float = projectile_damage
	if stats != null:
		final_damage *= stats.get_damage_multiplier()
	final_damage *= 1.2

	var fireball := Area2D.new()
	fireball.set_script(FIREBALL_SCRIPT)
	fireball.setup(self, start_position, direction, final_damage, 80.0)
	fireball.collision_layer = 1 << 2
	fireball.collision_mask = 1 << 1
	get_tree().current_scene.add_child(fireball)


func _get_talent_coords() -> Array[Vector2i]:
	return TALENT_CATALOG.coords()


func _get_talent_node_id(coord: Vector2i) -> StringName:
	return TALENT_CATALOG.node_id(coord)


func _is_talent_coord_valid(coord: Vector2i) -> bool:
	return TALENT_CATALOG.is_coord_valid(coord)


func _is_talent_start_coord(coord: Vector2i) -> bool:
	return TALENT_CATALOG.is_start_coord(coord)


func _get_talent_neighbor_coords(coord: Vector2i) -> Array[Vector2i]:
	return TALENT_CATALOG.neighbor_coords(coord)


func _get_animation_texture(animation_name: StringName) -> Texture2D:
	match animation_name:
		&"attack":
			return ATTACK_TEXTURE
		&"attack_alt":
			return ATTACK_ALT_TEXTURE
		&"ability":
			return ABILITY_TEXTURE
		&"rolling":
			return ROLLING_TEXTURE
		&"slide_start":
			return SLIDE_START_TEXTURE
		&"slide_hold":
			return SLIDE_START_TEXTURE
		&"slide_end":
			return SLIDE_END_TEXTURE
		&"run":
			return RUN_TEXTURE
		_:
			return IDLE_TEXTURE


func _play_slide_sfx() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return

	var stream: AudioStream = _get_slide_sfx()
	if stream == null:
		return
	SFX_PLAYER.play_2d(parent, stream, global_position, slide_sfx_volume_db, 1.8, 3.2)


func _get_slide_sfx() -> AudioStream:
	if slide_sfx != null:
		return slide_sfx

	var stream := load(SLIDE_SFX_PATH) as AudioStream
	if stream == null and FileAccess.file_exists(SLIDE_SFX_PATH):
		stream = AudioStreamMP3.load_from_file(SLIDE_SFX_PATH)
	if stream == null:
		push_warning("Failed to load slide SFX: %s" % SLIDE_SFX_PATH)
		return null

	slide_sfx = stream
	return slide_sfx


func _get_direction_row(direction: Vector2) -> int:
	if direction.length_squared() <= 0.001:
		return 0

	var angle: float = fposmod(direction.angle(), TAU)
	return int(round(angle / (PI * 0.25))) % DIRECTION_COUNT


func _get_move_input() -> Vector2:
	var input_direction: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	return input_direction.normalized()


func _ensure_placeholder_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 14.0
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("DebugBody") == null:
		var body: Polygon2D = Polygon2D.new()
		body.name = "DebugBody"
		body.color = Color(0.92, 0.88, 0.52)
		body.polygon = PackedVector2Array([
			Vector2(18.0, 0.0),
			Vector2(7.0, 13.0),
			Vector2(-12.0, 10.0),
			Vector2(-16.0, 0.0),
			Vector2(-12.0, -10.0),
			Vector2(7.0, -13.0),
		])
		add_child(body)
	var debug_body := get_node_or_null("DebugBody") as CanvasItem
	if debug_body != null:
		debug_body.visible = false

	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		move_child(sprite, 1)
	sprite.centered = true
	sprite.region_enabled = true
	sprite.texture = IDLE_TEXTURE
	sprite.region_rect = Rect2(Vector2.ZERO, Vector2(FRAME_SIZE))

	_ensure_animation_tree()
	_play_sprite_animation(&"idle")

	gun_pivot = get_node_or_null("GunPivot") as Node2D
	if gun_pivot == null:
		gun_pivot = Node2D.new()
		gun_pivot.name = "GunPivot"
		add_child(gun_pivot)

	muzzle = gun_pivot.get_node_or_null("Muzzle") as Marker2D
	if muzzle == null:
		muzzle = Marker2D.new()
		muzzle.name = "Muzzle"
		muzzle.position = Vector2(28.0, 0.0)
		gun_pivot.add_child(muzzle)

	melee_attack_root = get_node_or_null("MeleeAttack") as Node2D
	if melee_attack_root == null:
		melee_attack_root = Node2D.new()
		melee_attack_root.name = "MeleeAttack"
		add_child(melee_attack_root)

	melee_hitbox_area = melee_attack_root.get_node_or_null("HitboxArea") as Area2D
	if melee_hitbox_area == null:
		melee_hitbox_area = Area2D.new()
		melee_hitbox_area.name = "HitboxArea"
		melee_attack_root.add_child(melee_hitbox_area)
	melee_hitbox_area.monitoring = false
	melee_hitbox_area.monitorable = false
	melee_hitbox_area.collision_mask = 0
	melee_hitbox_area.set_collision_mask_value(enemy_collision_layer_number, true)
	melee_hitbox_area.set_collision_mask_value(jar_collision_layer_number, true)

	melee_hitbox_polygon = melee_hitbox_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if melee_hitbox_polygon == null:
		melee_hitbox_polygon = CollisionPolygon2D.new()
		melee_hitbox_polygon.name = "CollisionPolygon2D"
		melee_hitbox_area.add_child(melee_hitbox_polygon)
	if melee_hitbox_polygon.polygon.is_empty():
		melee_hitbox_polygon.polygon = _semicircle_polygon(melee_attack_radius, 24)

	melee_effect_damage_preview = melee_attack_root.get_node_or_null("EffectDamagePreview") as Sprite2D
	if melee_effect_damage_preview == null:
		melee_effect_damage_preview = Sprite2D.new()
		melee_effect_damage_preview.name = "EffectDamagePreview"
		melee_effect_damage_preview.position = Vector2(melee_attack_radius * 0.5, 0.0)
		melee_effect_damage_preview.scale = Vector2.ONE * (melee_attack_radius * 2.0 / float(HOLY_SLASH_FRAME_SIZE.x))
		melee_attack_root.add_child(melee_effect_damage_preview)
	melee_effect_damage_preview.texture = HOLY_SLASH_TEXTURE
	melee_effect_damage_preview.centered = true
	melee_effect_damage_preview.region_enabled = true
	melee_effect_damage_preview.region_rect = _get_holy_slash_damage_preview_region()
	melee_effect_damage_preview.modulate = Color(1.0, 0.95, 0.55, 0.42)
	melee_effect_damage_preview.visible = false

	shockwave_attack_root = get_node_or_null("ShockwaveAttack") as Node2D
	if shockwave_attack_root == null:
		shockwave_attack_root = Node2D.new()
		shockwave_attack_root.name = "ShockwaveAttack"
		add_child(shockwave_attack_root)

	shockwave_area = shockwave_attack_root.get_node_or_null("HitboxArea") as Area2D
	if shockwave_area == null:
		shockwave_area = Area2D.new()
		shockwave_area.name = "HitboxArea"
		shockwave_attack_root.add_child(shockwave_area)
	shockwave_area.monitoring = false
	shockwave_area.monitorable = false
	shockwave_area.collision_mask = 0
	shockwave_area.set_collision_mask_value(enemy_collision_layer_number, true)

	shockwave_collision = shockwave_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shockwave_collision == null:
		shockwave_collision = CollisionShape2D.new()
		shockwave_collision.name = "CollisionShape2D"
		shockwave_area.add_child(shockwave_collision)
	var shockwave_shape: CircleShape2D = CircleShape2D.new()
	shockwave_shape.radius = shockwave_radius
	if shockwave_collision.shape == null:
		shockwave_collision.shape = shockwave_shape

	shockwave_preview_frame = shockwave_attack_root.get_node_or_null("PreviewFrame") as Sprite2D
	if shockwave_preview_frame == null:
		shockwave_preview_frame = Sprite2D.new()
		shockwave_preview_frame.name = "PreviewFrame"
		shockwave_attack_root.add_child(shockwave_preview_frame)
	shockwave_preview_frame.texture = ABILITY_TEXTURE
	shockwave_preview_frame.centered = true
	shockwave_preview_frame.region_enabled = true
	shockwave_preview_frame.region_rect = _get_shockwave_preview_region()
	shockwave_preview_frame.modulate = Color(1.0, 1.0, 1.0, 0.45)
	shockwave_preview_frame.visible = false

	shockwave_effect_damage_preview = shockwave_attack_root.get_node_or_null("EffectDamagePreview") as Sprite2D
	if shockwave_effect_damage_preview == null:
		shockwave_effect_damage_preview = Sprite2D.new()
		shockwave_effect_damage_preview.name = "EffectDamagePreview"
		shockwave_attack_root.add_child(shockwave_effect_damage_preview)
	shockwave_effect_damage_preview.texture = HOLY_SPELL_TEXTURE
	shockwave_effect_damage_preview.centered = true
	shockwave_effect_damage_preview.region_enabled = true
	shockwave_effect_damage_preview.region_rect = _get_shockwave_effect_damage_preview_region()
	shockwave_effect_damage_preview.modulate = Color(0.6, 0.9, 1.0, 0.42)
	shockwave_effect_damage_preview.visible = false

	shockwave_visual = get_node_or_null("ShockwaveVisual") as Polygon2D
	if shockwave_visual == null:
		shockwave_visual = Polygon2D.new()
		shockwave_visual.name = "ShockwaveVisual"
		add_child(shockwave_visual)
	shockwave_visual.color = Color(1.0, 0.96, 0.42, 0.22)
	shockwave_visual.polygon = _circle_polygon(_get_shockwave_radius(), 36)
	shockwave_visual.visible = false

	melee_telegraph_visual = get_node_or_null("MeleeTelegraphVisual") as Polygon2D
	if melee_telegraph_visual == null:
		melee_telegraph_visual = Polygon2D.new()
		melee_telegraph_visual.name = "MeleeTelegraphVisual"
		add_child(melee_telegraph_visual)
		move_child(melee_telegraph_visual, 0)
	melee_telegraph_visual.color = melee_telegraph_color
	melee_telegraph_visual.polygon = _semicircle_polygon(_get_melee_telegraph_radius(), 24)
	melee_telegraph_visual.visible = false


func _get_shockwave_preview_region() -> Rect2:
	var frame_index := clampi(SHOCKWAVE_HIT_FRAME - 1, 0, FRAMES_PER_DIRECTION - 1)
	return Rect2(Vector2(frame_index * FRAME_SIZE.x, 0.0), Vector2(FRAME_SIZE))


func _get_shockwave_effect_damage_preview_region() -> Rect2:
	var frame_count := maxi(int(HOLY_SPELL_TEXTURE.get_width() / HOLY_SPELL_FRAME_SIZE.x), 1)
	var frame_index := clampi(SHOCKWAVE_EFFECT_DAMAGE_FRAME - 1, 0, frame_count - 1)
	return Rect2(Vector2(frame_index * HOLY_SPELL_FRAME_SIZE.x, 0.0), Vector2(HOLY_SPELL_FRAME_SIZE))


func _get_holy_slash_damage_preview_region() -> Rect2:
	var frame_count := maxi(int(HOLY_SLASH_TEXTURE.get_width() / HOLY_SLASH_FRAME_SIZE.x), 1)
	var frame_index := clampi(1, 0, frame_count - 1)
	return Rect2(Vector2(frame_index * HOLY_SLASH_FRAME_SIZE.x, 0.0), Vector2(HOLY_SLASH_FRAME_SIZE))


func _ensure_stats_and_items() -> void:
	if stats == null:
		stats = StatsComponent.new()
	stats.max_hp = roundi(max_hp)
	stats.base_move_speed = move_speed
	if not stats.stat_changed.is_connected(_on_stat_changed):
		stats.stat_changed.connect(_on_stat_changed)

	inventory = get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory == null:
		inventory = InventoryComponent.new()
		inventory.name = "InventoryComponent"
		add_child(inventory)
	inventory.setup(self)

	temporary_buffs = get_node_or_null("TemporaryBuffComponent") as TemporaryBuffComponent
	if temporary_buffs == null:
		temporary_buffs = TemporaryBuffComponent.new()
		temporary_buffs.name = "TemporaryBuffComponent"
		add_child(temporary_buffs)
	temporary_buffs.setup(self)


func _on_stat_changed(stat_name: StringName, _value: Variant) -> void:
	if stat_name == &"max_hp" and stats != null:
		var old_max_hp: float = max_hp
		max_hp = float(stats.max_hp)
		if max_hp > old_max_hp:
			hp += max_hp - old_max_hp
		hp = minf(hp, max_hp)
		hp_changed.emit(roundi(hp), roundi(max_hp))
	elif stat_name == &"atk":
		_update_max_hp_from_atk_talent()


func _apply_attack_status_procs(enemy: Node) -> void:
	if stats == null or enemy == null:
		return
	if randf() < stats.bleed_chance and enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect(&"bleeding", self)
	if randf() < stats.poison_chance and enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect(&"poison", self)


func _clamp_to_movement_bounds() -> void:
	if not movement_bounds_enabled:
		return

	global_position = Vector2(
		clampf(global_position.x, movement_bounds.position.x, movement_bounds.end.x),
		clampf(global_position.y, movement_bounds.position.y, movement_bounds.end.y)
	)


func _circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	for point in range(points):
		var angle: float = TAU * float(point) / float(points)
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)

	return polygon


func _semicircle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	polygon.append(Vector2.ZERO)
	for point in range(points + 1):
		var angle: float = -PI * 0.5 + PI * float(point) / float(maxi(points, 1))
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)

	return polygon


func _ensure_animation_tree() -> void:
	animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
	animation_player.root_node = NodePath("..")

	animation_tree = get_node_or_null("AnimationTree") as AnimationTree
	if animation_tree == null:
		animation_tree = AnimationTree.new()
		animation_tree.name = "AnimationTree"
		add_child(animation_tree)

	_build_animation_library()
	_build_animation_state_machine()

	animation_tree.set("anim_player", NodePath("../AnimationPlayer"))
	animation_tree.active = true
	animation_state = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback


func _build_animation_library() -> void:
	DIRECTIONAL_ANIMATION_LIBRARY_BUILDER.build_library(
		animation_player,
		_get_animation_bases(),
		DIRECTION_COUNT,
		FRAME_SIZE,
		Callable(self, "_get_animation_texture"),
		Callable(self, "_get_animation_length"),
		Callable(self, "_get_animation_loop_mode"),
		Callable(self, "_get_animation_frame_count"),
		Callable(self, "_get_animation_frame_column"),
		Callable(self, "_get_frame_duration")
	)


func _build_animation_state_machine() -> void:
	DIRECTIONAL_ANIMATION_LIBRARY_BUILDER.build_state_machine(
		animation_tree,
		_get_animation_bases(),
		DIRECTION_COUNT
	)


func _get_animation_bases() -> Array[StringName]:
	return [
		&"idle",
		&"run",
		&"attack",
		&"ability",
		&"rolling",
		&"slide_start",
		&"slide_hold",
		&"slide_end",
	]


func _get_animation_length(animation_base: StringName) -> float:
	var length: float = 0.0
	for frame in range(FRAMES_PER_DIRECTION):
		length += _get_frame_duration(animation_base, frame)

	return maxf(length, 0.001)


func _get_frame_duration(animation_base: StringName, frame: int) -> float:
	if animation_base == &"attack":
		return _get_attack_frame_duration(frame)
	if animation_base == &"rolling":
		return dash_duration / float(FRAMES_PER_DIRECTION)
	if animation_base == &"slide_start" or animation_base == &"slide_hold":
		return slide_duration * 0.5 / float(FRAMES_PER_DIRECTION)
	if animation_base == &"slide_end":
		return 1.0 / SLIDE_END_FPS

	return 1.0 / animation_fps


func _get_attack_frame_duration(frame: int) -> float:
	if frame < ATTACK_PROJECTILE_FRAME:
		return _get_attack_windup_frame_duration(frame)

	var slow_edge_frames: int = clampi(attack_slow_edge_frames, 0, FRAMES_PER_DIRECTION)
	var slow_recovery_start: int = max(ATTACK_PROJECTILE_FRAME, FRAMES_PER_DIRECTION - slow_edge_frames)
	if frame >= slow_recovery_start:
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	var windup_time: float = _get_attack_projectile_time()
	var slow_recovery_frame_count: int = FRAMES_PER_DIRECTION - slow_recovery_start
	var slow_recovery_time: float = float(slow_recovery_frame_count) / maxf(attack_edge_animation_fps, 0.01)
	var middle_recovery_frame_count: int = slow_recovery_start - ATTACK_PROJECTILE_FRAME
	if middle_recovery_frame_count <= 0:
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	var middle_recovery_time: float = maxf(_get_fire_interval() - windup_time - slow_recovery_time, 0.001)
	return middle_recovery_time / float(middle_recovery_frame_count)


func _get_attack_windup_frame_duration(frame: int) -> float:
	if frame < clampi(attack_slow_edge_frames, 0, ATTACK_PROJECTILE_FRAME):
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	return 1.0 / maxf(attack_fast_animation_fps, 0.01)


func _get_animation_loop_mode(animation_base: StringName) -> Animation.LoopMode:
	if animation_base == &"idle" or animation_base == &"run":
		return Animation.LOOP_LINEAR

	return Animation.LOOP_NONE


func _get_animation_frame_count(animation_base: StringName) -> int:
	if animation_base == &"slide_hold":
		return 1
	return FRAMES_PER_DIRECTION


func _get_animation_frame_column(animation_base: StringName, frame: int) -> int:
	if animation_base == &"slide_hold":
		return FRAMES_PER_DIRECTION - 1
	return frame
