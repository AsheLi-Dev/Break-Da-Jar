extends CharacterBody2D
class_name Player

const FRAME_SIZE := Vector2i(128, 128)
const FRAMES_PER_DIRECTION := 15
const DIRECTION_COUNT := 8
const ATTACK_PROJECTILE_FRAME := 7
const BLESSING_ACTIVE_FRAME := 9
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
const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")
const FLOATING_TEXT_SCRIPT := preload("res://systems/combat/FloatingText.gd")
const HOLY_SPELL_FRAME_SIZE := Vector2i(128, 64)
const HOLY_SPELL_TEXTURE: Texture2D = preload("res://assets/vfx/holy spell/HolyNova_spritesheet.png")
const HOLY_SLASH_FRAME_SIZE := Vector2i(64, 64)
const HOLY_SLASH_TEXTURE: Texture2D = preload("res://assets/vfx/holy spell/HolySlash_A_spritesheet.png")
const HOLY_SLASH_FPS := 24.0
const IDLE_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/idle.png")
const LEVEL_UP_EFFECT_TEXTURE: Texture2D = preload("res://assets/vfx/Level Up Effect/Level Up Effect Spritesheet.png")
const PUMMEL_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/pummel.png")
const ROLLING_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/rolling.png")
const SLIDE_END_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/slideend.png")
const SLIDE_SFX_PATH := "res://assets/sfx/slide.mp3"
const SLIDE_START_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/slidestart.png")
const RUN_TEXTURE: Texture2D = preload("res://assets/heroes/paladin/run.png")
const SWORD_OF_JUSTICE_FRAME_SIZE := Vector2i(64, 128)
const SWORD_OF_JUSTICE_TEXTURE: Texture2D = preload("res://assets/vfx/holy spell/SwordOfJustice_spritesheet.png")
const HOLY_SHIELD_FRAME_SIZE := Vector2i(64, 64)
const HOLY_SHIELD_TEXTURE: Texture2D = preload("res://assets/vfx/holy spell/HolyShield_spritesheet.png")
const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const ENEMY_HURT_SFX: AudioStream = preload("res://assets/sfx/enemy_hurt.wav")
const TALENT_CATALOG := preload("res://scripts/player/PlayerTalentCatalog.gd")
const CHARACTER_DATABASE := preload("res://scripts/player/CharacterDatabase.gd")
const HOLY_FLAME_LASER_SCRIPT := preload("res://systems/combat/HolyFlameLaser.gd")
const FIRE_ESSENCE_PICKUP_SCRIPT := preload("res://systems/combat/FireEssencePickup.gd")
const LIGHTNING_CHAIN_TEXTURE_PATH := "res://assets/vfx/lightning spell/lightning chain 256x256.png"
const LIGHTNING_CHAIN_FRAME_SIZE := Vector2(256.0, 256.0)
const LIGHTNING_CHAIN_SFX: AudioStream = preload("res://assets/sfx/dragon-studio-lightning-spell-386163.mp3")

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
@export var attack_move_speed_multiplier: float = 0.3
@export var attack_min_recovery_duration: float = 0.08
@export var attack_max_animation_speed_scale: float = 2.2
@export var melee_attack_radius: float = 200.0
@export var melee_telegraph_color: Color = Color(1.0, 0.9, 0.28, 0.22)

# Holy shockwave tuning. Area2D applies damage and knockback explicitly.
@export var shockwave_damage: float = 18.0
@export var shockwave_radius: float = 118.0
@export var shockwave_knockback: float = 430.0
@export var shockwave_cooldown: float = 6.0
@export var shockwave_visible_time: float = 0.16
@export var blessing_cooldown: float = 10.0
@export var blessing_duration: float = 5.0
@export var blessing_attack_speed_bonus: float = 0.3
@export var blessing_move_speed_bonus: float = 0.3
@export var blessing_effect_fps: float = 12.0

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
var character_definition: RefCounted
var talent_catalog: GDScript = TALENT_CATALOG
var primary_ability: StringName = &"paladin_holy_strike"
var secondary_ability: StringName = &"paladin_shockwave"
var utility_ability: StringName = &"paladin_blessing"
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
var talent_kill_gold_chance_enabled: bool = false
var talent_elite_kill_common_item_enabled: bool = false
var talent_container_gold_chance_enabled: bool = false
var talent_level_up_gold_enabled: bool = false
var talent_rich_double_xp_enabled: bool = false
var talent_normal_kill_gold_chance_enabled: bool = false
var talent_normal_enemy_xp_bonus_enabled: bool = false
var talent_normal_kill_common_item_counter_enabled: bool = false
var talent_normal_enemy_gold_double_enabled: bool = false
var talent_elite_kill_gold_enabled: bool = false
var talent_elite_enemy_xp_bonus_enabled: bool = false
var talent_elite_kill_rare_item_enabled: bool = false
var talent_round_healing_orb_enabled: bool = false
var talent_low_hp_round_end_heal_enabled: bool = false
var talent_defense_per_item_enabled: bool = false
var talent_max_hp_per_common_item_enabled: bool = false
var talent_item_max_hp_bonus_multiplier_enabled: bool = false
var talent_slide_defense_bonus_enabled: bool = false
var talent_damage_taken_lifesteal_enabled: bool = false
var talent_holy_strike_movement_stack_enabled: bool = false
var talent_holy_strike_long_range_enabled: bool = false
var talent_holy_strike_focused_zeal_enabled: bool = false
var talent_holy_strike_crit_fireball_burst_enabled: bool = false
var talent_holy_strike_lucky_critical_procs_enabled: bool = false
var talent_holy_strike_move_speed_attack_speed_enabled: bool = false
var talent_holy_strike_max_hp_range_enabled: bool = false
var talent_holy_strike_chain_lightning_pack_enabled: bool = false
var talent_holy_strike_nearby_enemy_attack_speed_enabled: bool = false
var talent_holy_strike_more_weaker_enemies_enabled: bool = false
var talent_holy_strike_elite_damage_per_kill_enabled: bool = false
var talent_holy_strike_zombie_inscriptions_enabled: bool = false
var talent_holy_strike_heavy_smite_enabled: bool = false
var talent_holy_strike_stationary_crit_enabled: bool = false
var talent_holy_strike_elite_smite_enabled: bool = false
var talent_holy_strike_stationary_atk_enabled: bool = false
var talent_holy_strike_double_tombs_enabled: bool = false
var talent_holy_strike_undamaged_stationary_enabled: bool = false
var talent_wizard_slide_fireball_blast_enabled: bool = false
var talent_wizard_poison_stack_damage_enabled: bool = false
var talent_wizard_nearby_enemy_attack_speed_enabled: bool = false
var talent_wizard_nearby_damage_focus_enabled: bool = false
var talent_wizard_fire_surge_left_click_blast_enabled: bool = false
var talent_wizard_nearby_kill_gold_enabled: bool = false
var talent_wizard_dash_fireball_enabled: bool = false
var talent_wizard_nearby_enemy_move_speed_enabled: bool = false
var talent_wizard_nearby_poison_aura_enabled: bool = false
var talent_wizard_poisoned_kill_gold_enabled: bool = false
var talent_wizard_short_laser_double_damage_enabled: bool = false
var talent_wizard_nearby_enemy_elite_damage_enabled: bool = false
var talent_wizard_more_weaker_enemies_enabled: bool = false
var talent_wizard_rebirth_level_to_atk_enabled: bool = false
var talent_wizard_primary_fireball_laser_explosion_enabled: bool = false
var talent_wizard_fire_surge_laser_enabled: bool = false
var talent_wizard_fire_laser_chain_enabled: bool = false
var talent_wizard_fire_surge_attack_speed_enabled: bool = false
var talent_wizard_attack_speed_laser_chain_enabled: bool = false
var talent_wizard_fire_essence_burst_enabled: bool = false
var talent_wizard_kill_move_speed_burst_enabled: bool = false
var talent_wizard_fire_surge_radial_fireballs_enabled: bool = false
var talent_wizard_max_hp_primary_echo_enabled: bool = false
var talent_wizard_move_speed_extra_fireballs_enabled: bool = false
var talent_wizard_poisoned_death_fireball_enabled: bool = false
var talent_wizard_rare_item_move_speed_enabled: bool = false
var talent_wizard_fire_essence_explosion_scatter_enabled: bool = false
var talent_wizard_random_double_fireballs_enabled: bool = false
var talent_wizard_guaranteed_legendary_shop_jar_enabled: bool = false
var talent_wizard_natural_fireball_radius_enabled: bool = false
var talent_wizard_legendary_extra_fireballs_enabled: bool = false
var talent_wizard_natural_fireball_heal_enabled: bool = false
var talent_wizard_damage_taken_natural_explode_fireballs_enabled: bool = false
var wizard_rebirth_used: bool = false
var applied_max_hp_from_atk: int = 0
var applied_holy_strike_move_speed_attack_speed: float = -1.0
var applied_holy_strike_nearby_enemy_attack_speed: float = -1.0
var applied_wizard_nearby_enemy_attack_speed: float = -1.0
var applied_wizard_nearby_enemy_move_speed: float = -1.0
var applied_wizard_nearby_enemy_elite_damage: float = -1.0
var holy_strike_zombie_inscription_kills: int = 0
var holy_strike_stationary_time: float = 0.0
var holy_strike_undamaged_time: float = 0.0
var holy_strike_stationary_atk_timer: float = 0.0
var holy_strike_stationary_atk_stacks: int = 0
var applied_holy_strike_undamaged_move_speed: float = 0.0
var normal_kill_common_item_counter: int = 0
var applied_item_defense_bonus: int = 0
var applied_item_max_hp_bonus: int = 0
var applied_wizard_rare_item_move_speed: int = 0
var next_attack_after_slide_ready: bool = false
var next_wizard_slide_fireball_ready: bool = false
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
var blessing_cooldown_remaining: float = 0.0
var blessing_shield_remaining: float = 0.0
var saved_collision_mask: int = 0
var is_invincible: bool = false
var blessing_next_is_attack: bool = true
var pending_blessing: bool = false
var pending_blessing_is_attack: bool = true
var blessing_damage_shield_active: bool = false
var blessing_shield_heals_on_block: bool = false
var fire_surge_remaining: float = 0.0
var fire_surge_fire_remaining: float = 0.0
var fire_surge_cooldown_pending: bool = false
var wizard_nearby_poison_aura_timer: float = 5.0
var wizard_fire_essence_spawn_timer: float = 5.0
var wizard_fire_essence_charges: int = 0

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
	if character_definition == null:
		setup_character(&"paladin")
	add_to_group("player")
	_ensure_stats_and_items()
	hp = max_hp
	saved_collision_mask = collision_mask
	_ensure_placeholder_nodes()
	hp_changed.emit(roundi(hp), roundi(max_hp))


func setup_character(character_id: StringName) -> void:
	character_definition = CHARACTER_DATABASE.get_definition(character_id)
	talent_catalog = character_definition.talent_catalog
	primary_ability = character_definition.primary_ability
	secondary_ability = character_definition.secondary_ability
	utility_ability = character_definition.utility_ability
	max_hp = character_definition.max_hp
	move_speed = character_definition.move_speed
	projectile_damage = character_definition.base_damage
	fire_rate = character_definition.fire_rate
	if stats != null:
		stats.max_hp = roundi(max_hp)
		stats.base_move_speed = move_speed
	if sprite != null:
		sprite.texture = _get_animation_texture(&"idle")
	if animation_player != null:
		_build_animation_library()
		_build_animation_state_machine()


func _exit_tree() -> void:
	_force_restore_hurt_slow_motion()


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_holy_strike_stationary_talents(delta)
	_update_holy_strike_dynamic_talents()
	_update_holy_strike_nearby_enemy_attack_speed()
	_update_wizard_nearby_enemy_attack_speed()
	_update_wizard_nearby_enemy_move_speed()
	_update_wizard_nearby_enemy_elite_damage()
	_update_wizard_fire_surge_attack_speed_bonus()
	_update_wizard_nearby_poison_aura(delta)
	_update_wizard_fire_essence_spawner(delta)
	_update_hp_regen(delta)
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

	if Input.is_action_just_pressed("blessing"):
		_try_cast_blessing()

	_update_sprite_animation(delta)


func take_damage(amount: float) -> void:
	if damage_shield_active:
		var blocked_damage: float = amount
		if stats != null:
			blocked_damage = float(stats.calculate_incoming_damage(amount))
		damage_shield_active = false
		if blessing_damage_shield_active:
			blessing_damage_shield_active = false
			blessing_shield_remaining = 0.0
		if blessing_shield_heals_on_block:
			blessing_shield_heals_on_block = false
			heal(blocked_damage)
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
	if hp - final_damage <= 0.0 and _try_wizard_rebirth():
		damage_taken.emit(final_damage)
		return
	hp = maxf(0.0, hp - final_damage)
	holy_strike_undamaged_time = 0.0
	hp_changed.emit(roundi(hp), roundi(max_hp))
	damage_taken.emit(final_damage)
	_trigger_wizard_damage_taken_fireball_natural_explosions()
	if talent_damage_taken_lifesteal_enabled and temporary_buffs != null:
		temporary_buffs.add_timed_stat_buff(&"damage_taken_lifesteal", &"lifesteal", 0.2, 2.0, 1)
	_play_hurt_impact_feedback()
	if hp <= 0.0:
		die()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	hp = minf(max_hp, hp + amount)
	hp_changed.emit(roundi(hp), roundi(max_hp))


func _update_hp_regen(delta: float) -> void:
	if stats == null or stats.hp_regen_per_second <= 0.0 or hp >= max_hp:
		return

	var old_rounded_hp := roundi(hp)
	hp = minf(max_hp, hp + stats.hp_regen_per_second * delta)
	var new_rounded_hp := roundi(hp)
	if new_rounded_hp != old_rounded_hp:
		hp_changed.emit(new_rounded_hp, roundi(max_hp))


func lose_hp(amount: float) -> float:
	if amount <= 0.0:
		return 0.0

	var old_hp: float = hp
	if hp - amount <= 0.0 and _try_wizard_rebirth():
		return old_hp
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


func collect_fire_essence() -> void:
	if talent_wizard_fire_essence_burst_enabled:
		wizard_fire_essence_charges += 1


func apply_fireball_projectile_talent_modifiers(fireball: FireballProjectile) -> void:
	if fireball == null or fireball.owner_spawn_modifiers_applied:
		return

	fireball.owner_spawn_modifiers_applied = true
	var total_fireballs := 1 + _get_wizard_legendary_extra_fireball_count()
	if talent_wizard_random_double_fireballs_enabled:
		total_fireballs *= 2
	if total_fireballs <= 1:
		return

	var randomize_directions := talent_wizard_random_double_fireballs_enabled
	if randomize_directions:
		var first_direction := _get_random_fireball_direction()
		fireball.direction = first_direction
		fireball.rotation = first_direction.angle()
	for _index in range(total_fireballs - 1):
		var duplicate_direction := _get_random_fireball_direction() if randomize_directions else fireball.direction
		_spawn_fireball_duplicate(fireball, duplicate_direction)


func get_fireball_natural_explosion_radius_multiplier() -> float:
	return 2.0 if talent_wizard_natural_fireball_radius_enabled else 1.0


func on_fireball_natural_explosion(_fireball: FireballProjectile) -> void:
	if talent_wizard_natural_fireball_heal_enabled:
		heal(1.0)


func _trigger_wizard_damage_taken_fireball_natural_explosions() -> void:
	if not talent_wizard_damage_taken_natural_explode_fireballs_enabled or get_tree() == null:
		return

	for node in get_tree().get_nodes_in_group("fireball_projectile"):
		var fireball := node as FireballProjectile
		if fireball == null or fireball.owner_player != self or fireball.exploded:
			continue
		fireball.explode(true)


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

	if talent_rich_double_xp_enabled and _get_current_gold() >= 300:
		amount *= 2
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
	return talent_catalog.node_ids()


func get_talent_node_grid_position(node_id: StringName) -> Vector2i:
	if talent_catalog.has_method("grid_position"):
		return talent_catalog.grid_position(node_id)
	return Vector2i.ZERO


func get_talent_node_position(node_id: StringName) -> Vector2:
	if talent_catalog.has_method("position"):
		return talent_catalog.position(node_id)
	return _get_talent_ui_position_from_grid(get_talent_node_grid_position(node_id))


func get_talent_display_name(node_id: StringName) -> String:
	var definition: Dictionary = _get_talent_definition(node_id)
	return String(definition.get("name", "+1 ATK"))


func get_talent_description(node_id: StringName) -> String:
	var definition: Dictionary = _get_talent_definition(node_id)
	return String(definition.get("description", "+1 ATK"))


func get_talent_connections() -> Array:
	return talent_catalog.connections()


func can_unlock_talent(node_id: StringName) -> bool:
	if unspent_talent_points <= 0:
		return false
	if unlocked_talents.has(node_id):
		return false

	if not get_talent_node_ids().has(node_id):
		return false
	if _is_talent_start_node(node_id):
		return true
	for connection in get_talent_connections():
		if connection.size() != 2:
			continue
		if connection[0] == node_id and unlocked_talents.has(connection[1]):
			return true
		if connection[1] == node_id and unlocked_talents.has(connection[0]):
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
		_update_item_talent_bonuses()


func get_item_count(item_id: StringName) -> int:
	return inventory.get_item_count(item_id) if inventory != null else 0


func get_unique_permanent_growth_item_count() -> int:
	return inventory.get_unique_permanent_growth_item_count() if inventory != null else 0


func add_shop_price_multiplier(multiplier: float) -> void:
	shop_price_multiplier *= maxf(multiplier, 0.01)
	if get_tree().current_scene != null and get_tree().current_scene.has_method("refresh_shop_container_prices"):
		get_tree().current_scene.refresh_shop_container_prices()


func get_shop_price_multiplier() -> float:
	return shop_price_multiplier


func has_guaranteed_legendary_shop_jar() -> bool:
	return talent_wizard_guaranteed_legendary_shop_jar_enabled


func get_shop_tier_price_multiplier(tier: int) -> float:
	return 2.0 if talent_wizard_guaranteed_legendary_shop_jar_enabled and tier == 2 else 1.0


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
		if _is_holy_strike_attack(attack_info) and talent_holy_strike_heavy_smite_enabled:
			final_damage *= 1.5
			attack_info["holy_strike_heavy_smite"] = true
		if _is_holy_strike_attack(attack_info) and talent_holy_strike_long_range_enabled:
			final_damage *= 0.8
			attack_info["holy_strike_long_range_damage_penalty"] = true
		if bool(attack_info.get("direct", true)) and next_attack_damage_bonus > 0.0:
			final_damage *= 1.0 + next_attack_damage_bonus
			attack_info["next_attack_damage_bonus"] = next_attack_damage_bonus
			next_attack_damage_bonus = 0.0
		final_damage *= stats.get_damage_multiplier()
		if bool(attack_info.get("direct", true)):
			final_damage *= _get_conditional_direct_damage_multiplier(enemy)
		if talent_wizard_poison_stack_damage_enabled:
			var poison_stacks := _get_enemy_poison_stacks(enemy)
			if poison_stacks > 0:
				final_damage *= 1.0 + 0.05 * float(poison_stacks)
				attack_info["wizard_poison_stack_damage_bonus"] = poison_stacks
		if talent_wizard_nearby_damage_focus_enabled:
			if _is_enemy_nearby(enemy):
				final_damage *= 1.5
				attack_info["wizard_nearby_damage_focus"] = "nearby"
			else:
				final_damage *= 0.5
				attack_info["wizard_nearby_damage_focus"] = "distant"
		if _is_holy_strike_attack(attack_info) and talent_holy_strike_elite_smite_enabled:
			if _is_elite_enemy(enemy):
				final_damage *= 1.5
			else:
				final_damage *= 0.7
			attack_info["holy_strike_elite_smite"] = true
		if bool(attack_info.get("allow_crit", true)) and _roll_attack_crit(attack_info):
			final_damage *= 2.0 + stats.critical_damage_bonus
			attack_info["critical"] = true

	var damage_dealt: float = enemy.take_damage(final_damage, self, attack_info)
	if damage_dealt <= 0.0:
		damage_dealt = final_damage

	_play_enemy_hit_feedback(enemy, damage_dealt, attack_info)

	if bool(attack_info.get("direct", true)):
		_apply_attack_status_procs(enemy, attack_info)
		if stats != null and stats.lifesteal > 0.0:
			var heal_amount: float = damage_dealt * stats.lifesteal
			heal(heal_amount)

	if bool(attack_info.get("allow_procs", true)):
		_apply_holy_strike_on_hit_talents(enemy, attack_info)
		_try_trigger_talent_fireball(enemy, attack_info)
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
	var is_elite := _is_elite_enemy(enemy)
	if talent_heal_on_kill_enabled:
		heal(5.0)
	if talent_kill_gold_chance_enabled and randf() < 0.1:
		add_gold(1)
	if talent_normal_kill_gold_chance_enabled and not is_elite and randf() < 0.1:
		add_gold(1)
	if talent_normal_kill_common_item_counter_enabled and not is_elite:
		normal_kill_common_item_counter += 1
		while normal_kill_common_item_counter >= 25:
			normal_kill_common_item_counter -= 25
			_grant_random_common_item()
	if talent_elite_kill_gold_enabled and is_elite:
		add_gold(10)
	if talent_elite_kill_common_item_enabled and is_elite:
		_grant_random_common_item()
	if talent_elite_kill_rare_item_enabled and is_elite:
		_grant_random_item(&"rare")
	if talent_wizard_nearby_kill_gold_enabled and _is_enemy_nearby(enemy):
		add_gold(1)
	if talent_wizard_poisoned_kill_gold_enabled and _is_enemy_poisoned(enemy):
		add_gold(1)
	if talent_wizard_poisoned_death_fireball_enabled and _is_enemy_poisoned(enemy):
		_trigger_wizard_poisoned_death_fireball(enemy)
	if talent_wizard_kill_move_speed_burst_enabled and temporary_buffs != null:
		temporary_buffs.add_timed_stat_buff(&"wizard_kill_move_speed_burst", &"movement_speed_bonus", 2.0, 0.2, 1)
	if talent_holy_strike_elite_damage_per_kill_enabled and temporary_buffs != null:
		temporary_buffs.add_round_stat_buff(&"holy_strike_elite_damage_per_kill", &"elite_direct_damage_bonus", 0.01, 999999)
	if talent_holy_strike_zombie_inscriptions_enabled and stats != null:
		holy_strike_zombie_inscription_kills += 1
		while holy_strike_zombie_inscription_kills >= 10:
			holy_strike_zombie_inscription_kills -= 10
			stats.apply_modifier(&"surrounded_enemy_count_bonus", &"add", 1.0)
	enemy_killed.emit(enemy)


func add_gold(amount: int, reason: String = "") -> void:
	if amount <= 0 or get_tree().current_scene == null:
		return
	if get_tree().current_scene.has_method("add_player_gold"):
		get_tree().current_scene.add_player_gold(amount, reason)


func _get_current_gold() -> int:
	if get_tree().current_scene == null:
		return 0
	return int(get_tree().current_scene.get("gold"))


func get_enemy_spawn_count_multiplier() -> float:
	if talent_wizard_more_weaker_enemies_enabled:
		return 2.0
	return 1.5 if talent_holy_strike_more_weaker_enemies_enabled else 1.0


func get_enemy_max_hp_multiplier() -> float:
	if talent_wizard_more_weaker_enemies_enabled:
		return 0.7
	return 0.8 if talent_holy_strike_more_weaker_enemies_enabled else 1.0


func get_tomb_container_count_multiplier() -> float:
	return 2.0 if talent_holy_strike_double_tombs_enabled else 1.0


func get_enemy_gold_reward_multiplier(enemy: Node) -> float:
	if not _is_elite_enemy(enemy) and talent_normal_enemy_gold_double_enabled:
		return 2.0
	return 1.0


func get_enemy_experience_reward_multiplier(enemy: Node) -> float:
	if _is_elite_enemy(enemy) and talent_elite_enemy_xp_bonus_enabled:
		return 1.5
	if not _is_elite_enemy(enemy) and talent_normal_enemy_xp_bonus_enabled:
		return 1.2
	return 1.0


func should_spawn_round_healing_orb() -> bool:
	return talent_round_healing_orb_enabled


func _try_wizard_rebirth() -> bool:
	if not talent_wizard_rebirth_level_to_atk_enabled or wizard_rebirth_used:
		return false

	wizard_rebirth_used = true
	var lost_levels: int = maxi(level - 1, 0)
	_reset_level_and_talents_after_wizard_rebirth()
	if stats != null and lost_levels > 0:
		stats.apply_modifier(&"atk", &"add", float(lost_levels))
	hp = max_hp
	is_invincible = false
	invincible_remaining = 0.0
	hp_changed.emit(roundi(hp), roundi(max_hp))
	experience_changed.emit(experience, _get_required_exp_for_next_level(), level)
	talent_points_changed.emit(unspent_talent_points, pending_talent_points)
	return true


func _reset_level_and_talents_after_wizard_rebirth() -> void:
	for node_id in unlocked_talents.duplicate():
		_remove_talent_stat_effect(node_id)
	unlocked_talents.clear()
	level = 1
	experience = 0
	pending_talent_points = 0
	unspent_talent_points = 0
	_reset_wizard_talent_state_after_rebirth()


func _remove_talent_stat_effect(node_id: StringName) -> void:
	if stats == null:
		return
	var definition := _get_talent_definition(node_id)
	if not definition.has("stat"):
		return
	var operation := StringName(definition.get("operation", &"add"))
	if operation != &"add":
		return
	stats.apply_modifier(
		StringName(definition.get("stat", &"atk")),
		&"add",
		-float(definition.get("value", 1.0))
	)


func _reset_wizard_talent_state_after_rebirth() -> void:
	talent_wizard_slide_fireball_blast_enabled = false
	talent_wizard_poison_stack_damage_enabled = false
	talent_wizard_nearby_enemy_attack_speed_enabled = false
	talent_wizard_nearby_damage_focus_enabled = false
	talent_wizard_fire_surge_left_click_blast_enabled = false
	talent_wizard_nearby_kill_gold_enabled = false
	talent_wizard_dash_fireball_enabled = false
	talent_wizard_nearby_enemy_move_speed_enabled = false
	talent_wizard_nearby_poison_aura_enabled = false
	talent_wizard_poisoned_kill_gold_enabled = false
	talent_wizard_short_laser_double_damage_enabled = false
	talent_wizard_nearby_enemy_elite_damage_enabled = false
	talent_wizard_more_weaker_enemies_enabled = false
	talent_wizard_rebirth_level_to_atk_enabled = false
	talent_wizard_primary_fireball_laser_explosion_enabled = false
	talent_wizard_fire_surge_laser_enabled = false
	talent_wizard_fire_laser_chain_enabled = false
	talent_wizard_fire_surge_attack_speed_enabled = false
	talent_wizard_attack_speed_laser_chain_enabled = false
	talent_wizard_fire_essence_burst_enabled = false
	talent_wizard_kill_move_speed_burst_enabled = false
	talent_wizard_fire_surge_radial_fireballs_enabled = false
	talent_wizard_max_hp_primary_echo_enabled = false
	talent_wizard_move_speed_extra_fireballs_enabled = false
	talent_wizard_poisoned_death_fireball_enabled = false
	talent_wizard_rare_item_move_speed_enabled = false
	talent_wizard_fire_essence_explosion_scatter_enabled = false
	talent_wizard_random_double_fireballs_enabled = false
	talent_wizard_guaranteed_legendary_shop_jar_enabled = false
	talent_wizard_natural_fireball_radius_enabled = false
	talent_wizard_legendary_extra_fireballs_enabled = false
	talent_wizard_natural_fireball_heal_enabled = false
	talent_wizard_damage_taken_natural_explode_fireballs_enabled = false
	if stats != null and applied_wizard_rare_item_move_speed != 0:
		stats.apply_modifier(&"bonus_move_speed_flat", &"add", -float(applied_wizard_rare_item_move_speed))
		applied_wizard_rare_item_move_speed = 0
	next_wizard_slide_fireball_ready = false
	wizard_nearby_poison_aura_timer = 5.0
	wizard_fire_essence_spawn_timer = 5.0
	wizard_fire_essence_charges = 0
	_clear_wizard_dynamic_talent_bonuses()


func _clear_wizard_dynamic_talent_bonuses() -> void:
	if temporary_buffs == null:
		return
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_nearby_enemy_attack_speed", &"attack_speed_bonus", 0.0)
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_nearby_enemy_move_speed", &"movement_speed_bonus", 0.0)
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_nearby_enemy_elite_damage", &"elite_direct_damage_bonus", 0.0)
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_fire_surge_attack_speed", &"attack_speed_bonus", 0.0)
	applied_wizard_nearby_enemy_attack_speed = -1.0
	applied_wizard_nearby_enemy_move_speed = -1.0
	applied_wizard_nearby_enemy_elite_damage = -1.0


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = minf(slow_multiplier, clampf(multiplier, 0.05, 1.0))
	slow_remaining = maxf(slow_remaining, duration)


func die() -> void:
	_force_restore_hurt_slow_motion()
	if _try_wizard_rebirth():
		return
	queue_free()


func _update_timers(delta: float) -> void:
	fire_cooldown_remaining = maxf(0.0, fire_cooldown_remaining - delta)
	shockwave_cooldown_remaining = maxf(0.0, shockwave_cooldown_remaining - delta)
	if not fire_surge_cooldown_pending:
		blessing_cooldown_remaining = maxf(0.0, blessing_cooldown_remaining - delta)
	_update_fire_surge(delta)
	blessing_shield_remaining = maxf(0.0, blessing_shield_remaining - delta)
	if blessing_damage_shield_active and blessing_shield_remaining <= 0.0:
		blessing_damage_shield_active = false
		blessing_shield_heals_on_block = false
		damage_shield_active = false
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
	if talent_wizard_dash_fireball_enabled:
		_launch_wizard_dash_fireball()
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
	if primary_ability == &"paladin_holy_strike":
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
	if secondary_ability == &"wizard_fire_laser":
		get_tree().create_timer(_get_shockwave_hit_time()).timeout.connect(_cast_wizard_fire_laser)
	else:
		get_tree().create_timer(_get_shockwave_hit_time()).timeout.connect(_start_shockwave_effect)


func _try_cast_blessing() -> void:
	if blessing_cooldown_remaining > 0.0:
		return
	if fire_surge_remaining > 0.0 or fire_surge_cooldown_pending:
		return
	if not _can_start_attack_now():
		return
	_interrupt_slide_for_attack()

	if utility_ability == &"paladin_blessing":
		blessing_cooldown_remaining = blessing_cooldown
	pending_blessing = true
	pending_blessing_is_attack = blessing_next_is_attack
	if utility_ability == &"paladin_blessing":
		blessing_next_is_attack = not blessing_next_is_attack
	_play_action_animation_with_direction(&"pummel", _get_action_animation_time(&"pummel"), facing_direction)


func _maybe_apply_blessing() -> void:
	if not pending_blessing or current_animation != &"pummel":
		return
	if action_animation_elapsed < _get_blessing_active_time():
		return

	pending_blessing = false
	if utility_ability == &"wizard_fire_surge":
		_start_fire_surge()
		return
	if pending_blessing_is_attack:
		_apply_attack_blessing()
	else:
		_apply_defense_blessing()


func _apply_attack_blessing() -> void:
	if temporary_buffs != null:
		temporary_buffs.add_timed_stat_buff(&"attack_blessing_attack_speed", &"attack_speed_bonus", blessing_attack_speed_bonus, blessing_duration, 1)
		temporary_buffs.add_timed_stat_buff(&"attack_blessing_move_speed", &"movement_speed_bonus", blessing_move_speed_bonus, blessing_duration, 1)
	_play_blessing_effect(SWORD_OF_JUSTICE_TEXTURE, &"sword_of_justice", SWORD_OF_JUSTICE_FRAME_SIZE)


func _apply_defense_blessing() -> void:
	damage_shield_active = true
	blessing_damage_shield_active = true
	blessing_shield_heals_on_block = true
	blessing_shield_remaining = blessing_duration
	_play_blessing_effect(HOLY_SHIELD_TEXTURE, &"holy_shield", HOLY_SHIELD_FRAME_SIZE)


func _start_shockwave_effect() -> void:
	var shockwave_center := _get_shockwave_center()
	shockwave_visual.visible = true
	shockwave_visual.global_position = shockwave_center
	_play_holy_spell_effect(shockwave_center)
	_start_camera_shake(5.0, 0.12)
	get_tree().create_timer(shockwave_visible_time).timeout.connect(_hide_shockwave_visual)
	get_tree().create_timer(_get_shockwave_effect_damage_time()).timeout.connect(_perform_shockwave_attack.bind(shockwave_center))


func _cast_wizard_fire_laser() -> void:
	var target_position := pending_shockwave_target_position
	var direction := target_position - global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()

	_spawn_wizard_fire_laser(global_position, direction)


func _spawn_wizard_fire_laser(start_position: Vector2, direction: Vector2, chain_remaining_override: int = -1) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var laser := HOLY_FLAME_LASER_SCRIPT.new() as HolyFlameLaser
	laser.length *= 2.0
	laser.width *= 2.0
	var laser_damage_multiplier := 1.5
	if talent_wizard_short_laser_double_damage_enabled:
		laser.length *= 0.5
		laser_damage_multiplier *= 2.0
	laser.setup(self, start_position, direction.normalized(), get_base_attack_damage() * laser_damage_multiplier, "wizard_fire_laser", true)
	laser.chain_remaining = chain_remaining_override if chain_remaining_override >= 0 else _get_wizard_fire_laser_chain_count()
	laser.collision_layer = 0
	laser.collision_mask = 0
	laser.set_collision_mask_value(enemy_collision_layer_number, true)
	laser.set_collision_mask_value(jar_collision_layer_number, true)
	get_tree().current_scene.add_child(laser)


func spawn_chained_wizard_fire_laser(source_enemy: Node, remaining_chains: int, chain_range: float, excludes: Array = []) -> void:
	var source_2d := source_enemy as Node2D
	if source_2d == null:
		return
	var target := EFFECT_TARGETING.nearest_enemy(self, source_2d.global_position, chain_range, excludes)
	if target == null:
		return
	var direction := target.global_position - source_2d.global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()
	_spawn_wizard_fire_laser(source_2d.global_position, direction, remaining_chains)


func _get_wizard_fire_laser_chain_count() -> int:
	var chain_count := 1 if talent_wizard_fire_laser_chain_enabled else 0
	if talent_wizard_attack_speed_laser_chain_enabled:
		chain_count += floori(_get_current_attacks_per_second())
	return maxi(chain_count, 0)


func _get_current_attacks_per_second() -> float:
	var attack_speed_bonus := stats.attack_speed_bonus if stats != null else 0.0
	return fire_rate * maxf(1.0 + attack_speed_bonus, 0.1)


func _start_fire_surge() -> void:
	fire_surge_remaining = 10.0
	fire_surge_fire_remaining = 0.0
	fire_surge_cooldown_pending = true


func _update_fire_surge(delta: float) -> void:
	if fire_surge_remaining <= 0.0:
		return

	fire_surge_remaining = maxf(0.0, fire_surge_remaining - delta)
	fire_surge_fire_remaining -= delta
	while fire_surge_fire_remaining <= 0.0 and fire_surge_remaining > 0.0:
		if talent_wizard_fire_surge_laser_enabled and talent_wizard_fire_surge_radial_fireballs_enabled:
			fire_surge_fire_remaining += 5.0
			_launch_wizard_radial_fire_lasers()
		elif talent_wizard_fire_surge_laser_enabled:
			fire_surge_fire_remaining += 2.0
			_launch_fire_surge_laser()
		elif talent_wizard_fire_surge_radial_fireballs_enabled:
			fire_surge_fire_remaining += 5.0
			_launch_wizard_radial_fireballs()
		else:
			fire_surge_fire_remaining += 2.0
			var target := EFFECT_TARGETING.nearest_enemy(self, global_position, 700.0)
			if target != null:
				_launch_wizard_fireball(target.global_position)

	if fire_surge_remaining <= 0.0:
		fire_surge_cooldown_pending = false
		blessing_cooldown_remaining = 10.0


func _launch_fire_surge_laser() -> void:
	var target := EFFECT_TARGETING.nearest_enemy(self, global_position, 700.0)
	if target == null:
		return
	var direction := target.global_position - global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()
	_spawn_wizard_fire_laser(global_position, direction)


func _launch_wizard_radial_fire_lasers() -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		_spawn_wizard_fire_laser(global_position, Vector2(cos(angle), sin(angle)))


func _launch_wizard_fireball(target_position: Vector2, consume_slide_fireball_bonus: bool = false, radius_multiplier: float = 1.0, lifetime_multiplier: float = 1.0, allow_procs: bool = false, emit_attack_started_event: bool = false, scatter_on_explode: bool = false) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var direction := target_position - global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()
	if emit_attack_started_event:
		attack_started.emit(global_position, direction, {"source": "fireball", "direct": true, "allow_procs": allow_procs})

	_spawn_wizard_fireball(global_position, direction, consume_slide_fireball_bonus, radius_multiplier, lifetime_multiplier, allow_procs, scatter_on_explode)


func _spawn_wizard_fireball(start_position: Vector2, direction: Vector2, consume_slide_fireball_bonus: bool = false, radius_multiplier: float = 1.0, lifetime_multiplier: float = 1.0, allow_procs: bool = false, scatter_on_explode: bool = false) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var fireball := FIREBALL_SCRIPT.new() as FireballProjectile
	var explosion_radius := 80.0 * maxf(radius_multiplier, 0.0)
	fireball.lifetime *= maxf(lifetime_multiplier, 0.0)
	var has_slide_fireball_bonus := consume_slide_fireball_bonus and next_wizard_slide_fireball_ready
	var has_surge_left_click_bonus := consume_slide_fireball_bonus and talent_wizard_fire_surge_left_click_blast_enabled and fire_surge_remaining > 0.0
	if has_slide_fireball_bonus or has_surge_left_click_bonus:
		explosion_radius *= 4.0
		fireball.lifetime *= 0.1
	if has_slide_fireball_bonus:
		next_wizard_slide_fireball_ready = false
	fireball.setup(self, start_position, direction, get_base_attack_damage(), explosion_radius, allow_procs)
	if talent_wizard_primary_fireball_laser_explosion_enabled:
		fireball.explode_replacement_callback = Callable(self, "_replace_wizard_primary_fireball_explosion_with_laser")
	if scatter_on_explode:
		fireball.explode_callback = Callable(self, "_launch_wizard_fire_essence_explosion_scatter")
	fireball.collision_layer = 1 << 2
	fireball.collision_mask = 1 << 1
	get_tree().current_scene.add_child(fireball)


func _launch_wizard_dash_fireball() -> void:
	var direction := dash_direction
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	_launch_wizard_fireball(global_position + direction.normalized() * 200.0, false, 2.0, 0.1)


func _launch_wizard_primary_attack_pattern(target_position: Vector2, use_fire_essence_version: bool, emit_attack_started_event: bool = true) -> void:
	var scatter_on_explode := use_fire_essence_version and talent_wizard_fire_essence_explosion_scatter_enabled
	_launch_wizard_fireball(target_position, true, 1.0, 1.0, true, emit_attack_started_event, scatter_on_explode)
	var offset_index := 0
	if use_fire_essence_version:
		_launch_wizard_offset_fireballs(target_position, 3, offset_index)
		offset_index += 3
	_launch_wizard_offset_fireballs(target_position, _get_wizard_move_speed_extra_fireball_count(), offset_index)


func _launch_wizard_fire_essence_burst(target_position: Vector2) -> void:
	_launch_wizard_primary_attack_pattern(target_position, true)


func _launch_wizard_offset_fireballs(target_position: Vector2, count: int, start_index: int = 0) -> void:
	if count <= 0:
		return
	var direction := target_position - global_position
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()

	var center_angle := direction.angle()
	for index in range(count):
		var offset_index := start_index + index
		var step := floori(float(offset_index) / 2.0) + 1
		var sign_value := 1.0 if offset_index % 2 == 0 else -1.0
		var angle := center_angle + deg_to_rad(10.0 * float(step) * sign_value)
		_launch_wizard_fireball(global_position + Vector2(cos(angle), sin(angle)) * 200.0, true, 1.0, 1.0, true)


func _launch_wizard_fire_essence_explosion_scatter(origin: Vector2) -> void:
	for index in range(8):
		var angle := deg_to_rad(24.0) + TAU * float(index) / 8.0
		var delay := 0.04 * float(index)
		if delay <= 0.0:
			_spawn_wizard_fireball(origin, Vector2(cos(angle), sin(angle)), false, 1.0, 1.0, true, false)
		elif get_tree() != null:
			get_tree().create_timer(delay).timeout.connect(
				_spawn_wizard_spiral_fireball.bind(origin, Vector2(cos(angle), sin(angle)))
			)


func _spawn_wizard_spiral_fireball(origin: Vector2, direction: Vector2) -> void:
	if not is_inside_tree():
		return
	_spawn_wizard_fireball(origin, direction, false, 1.0, 1.0, true, false)


func _replace_wizard_primary_fireball_explosion_with_laser(origin: Vector2, _is_natural: bool) -> bool:
	var target := EFFECT_TARGETING.nearest_enemy(self, origin, 700.0)
	if target == null:
		return true
	var direction := target.global_position - origin
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	else:
		direction = direction.normalized()
	_spawn_wizard_fire_laser(origin, direction)
	return true


func _spawn_fireball_duplicate(source_fireball: FireballProjectile, direction: Vector2) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var duplicate := FIREBALL_SCRIPT.new() as FireballProjectile
	duplicate.owner_spawn_modifiers_applied = true
	duplicate.speed = source_fireball.speed
	duplicate.lifetime = source_fireball.lifetime
	duplicate.target_group = source_fireball.target_group
	duplicate.damages_containers = source_fireball.damages_containers
	duplicate.explode_replacement_callback = source_fireball.explode_replacement_callback
	duplicate.explode_callback = source_fireball.explode_callback
	duplicate.setup(source_fireball.owner_player, source_fireball.global_position, direction, source_fireball.damage, source_fireball.explosion_radius, source_fireball.allow_procs)
	duplicate.collision_layer = source_fireball.collision_layer
	duplicate.collision_mask = source_fireball.collision_mask
	get_tree().current_scene.add_child(duplicate)


func _get_random_fireball_direction() -> Vector2:
	return Vector2.RIGHT.rotated(randf_range(0.0, TAU))


func _get_wizard_legendary_extra_fireball_count() -> int:
	if not talent_wizard_legendary_extra_fireballs_enabled:
		return 0
	return _get_item_count_by_rarity(&"legendary")


func _get_wizard_move_speed_extra_fireball_count() -> int:
	if not talent_wizard_move_speed_extra_fireballs_enabled:
		return 0
	var move_speed_value := move_speed
	if stats != null:
		move_speed_value = stats.get_move_speed(move_speed)
	return maxi(floori(move_speed_value / 100.0), 0)


func _launch_wizard_radial_fireballs() -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		_launch_wizard_fireball(global_position + Vector2(cos(angle), sin(angle)) * 200.0)


func _schedule_wizard_primary_echoes(target_position: Vector2, use_fire_essence_version: bool) -> void:
	if not talent_wizard_max_hp_primary_echo_enabled or get_tree() == null:
		return

	var max_hp_value := max_hp
	if stats != null:
		max_hp_value = float(stats.max_hp)
	var echo_count := floori(max_hp_value / 100.0)
	for index in range(echo_count):
		get_tree().create_timer(0.2 * float(index + 1)).timeout.connect(
			_launch_wizard_primary_echo.bind(target_position, use_fire_essence_version)
		)


func _launch_wizard_primary_echo(target_position: Vector2, use_fire_essence_version: bool) -> void:
	if not is_inside_tree():
		return
	_launch_wizard_primary_attack_pattern(target_position, use_fire_essence_version)


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
	return float(_get_ability_active_frame(&"secondary", SHOCKWAVE_HIT_FRAME) - 1) / animation_fps


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
		return _get_attack_action_time()

	return _get_full_animation_time()


func _get_blessing_active_time() -> float:
	return float(_get_ability_active_frame(&"utility", BLESSING_ACTIVE_FRAME) - 1) / animation_fps


func _update_sprite_animation(delta: float) -> void:
	if action_animation_remaining > 0.0:
		action_animation_elapsed += delta
		action_animation_remaining = maxf(0.0, action_animation_remaining - delta)
		_maybe_spawn_attack_projectile()
		_maybe_apply_blessing()
		if action_animation_remaining <= 0.0:
			action_direction_locked = false
			_set_animation_speed_scale(1.0)
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
	_set_animation_speed_scale(_get_animation_speed_scale(animation_name))
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
	if primary_ability == &"wizard_fireball":
		var used_fire_essence := wizard_fire_essence_charges > 0
		if wizard_fire_essence_charges > 0:
			wizard_fire_essence_charges -= 1
		_launch_wizard_primary_attack_pattern(pending_attack_target_position, used_fire_essence)
		_schedule_wizard_primary_echoes(pending_attack_target_position, used_fire_essence)
	else:
		_perform_melee_attack_at(pending_attack_target_position)


func _get_attack_projectile_time() -> float:
	return _get_attack_base_windup_time() / _get_attack_speed_multiplier()


func _get_attack_base_windup_time() -> float:
	var time: float = 0.0
	for frame in range(_get_ability_active_frame(&"primary", ATTACK_PROJECTILE_FRAME)):
		time += _get_attack_windup_frame_duration(frame)

	return time


func _get_ability_active_frame(action_name: StringName, fallback: int) -> int:
	if character_definition != null and character_definition.has_method("get_active_frame"):
		return clampi(character_definition.get_active_frame(action_name, fallback), 1, FRAMES_PER_DIRECTION)
	return fallback


func _get_attack_action_time() -> float:
	var hit_time: float = _get_attack_projectile_time()
	var recovery_time: float = maxf(attack_min_recovery_duration, _get_fire_interval() - hit_time)
	return hit_time + recovery_time


func _get_attack_cancel_time() -> float:
	return _get_attack_projectile_time() + attack_min_recovery_duration


func _get_base_fire_interval() -> float:
	return 1.0 / maxf(fire_rate, 0.01)


func _get_fire_interval() -> float:
	var base_interval: float = _get_base_fire_interval()
	if stats != null:
		return stats.get_attack_interval(base_interval)
	return base_interval


func _get_holy_strike_radius() -> float:
	var radius := melee_attack_radius
	if talent_holy_strike_max_hp_range_enabled and stats != null:
		radius *= 1.0 + 0.02 * floorf(float(stats.max_hp) / 10.0)
	if talent_holy_strike_long_range_enabled:
		radius *= 1.5
	return radius


func _get_holy_strike_angle() -> float:
	if talent_holy_strike_focused_zeal_enabled:
		return PI * 0.2
	return PI


func _get_attack_speed_multiplier() -> float:
	return maxf(_get_base_fire_interval() / maxf(_get_fire_interval(), 0.001), 0.01)


func _get_attack_animation_speed_scale() -> float:
	return clampf(_get_base_fire_interval() / maxf(_get_attack_action_time(), 0.001), 1.0, attack_max_animation_speed_scale)


func _get_animation_speed_scale(animation_name: StringName) -> float:
	if animation_name == &"attack":
		return _get_attack_animation_speed_scale()
	return 1.0


func _set_animation_speed_scale(speed_scale: float) -> void:
	if animation_player != null:
		animation_player.speed_scale = speed_scale


func _can_cancel_current_action() -> bool:
	if action_animation_remaining <= 0.0:
		return true
	if action_animation == &"slide_end":
		return true
	if action_animation != &"attack":
		return false

	return action_animation_elapsed >= _get_attack_cancel_time()


func _cancel_current_action() -> void:
	if action_animation_remaining <= 0.0:
		return

	action_animation = &""
	action_animation_remaining = 0.0
	action_animation_elapsed = 0.0
	pending_attack_projectile = false
	pending_blessing = false
	action_direction_locked = false
	_set_animation_speed_scale(1.0)
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

	var enemies_hit: int = 0
	var last_enemy_hit_position := global_position
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or not _is_target_in_melee_hitbox(enemy_2d.global_position, direction):
			continue
		if enemy.has_method("take_damage"):
			deal_player_damage_to_enemy(enemy, projectile_damage, attack_info.duplicate())
			enemies_hit += 1
			last_enemy_hit_position = enemy_2d.global_position

	if talent_holy_strike_chain_lightning_pack_enabled and enemies_hit >= 5:
		_trigger_holy_strike_chain_lightning(last_enemy_hit_position)

	for container in get_tree().get_nodes_in_group("container"):
		var container_2d := container as Node2D
		if container_2d == null or not _is_target_in_melee_hitbox(container_2d.global_position, direction):
			continue
		if container.has_method("take_damage"):
			container.take_damage(projectile_damage, {"source": "player_attack", "owner": self})


func _is_target_in_melee_hitbox(target_position: Vector2, direction: Vector2) -> bool:
	if talent_holy_strike_long_range_enabled or talent_holy_strike_focused_zeal_enabled:
		return _is_target_in_melee_arc(target_position, direction, _get_holy_strike_radius(), _get_holy_strike_angle())
	if melee_hitbox_polygon == null:
		return _is_target_in_melee_arc(target_position, direction, _get_holy_strike_radius(), _get_holy_strike_angle())

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


func _is_target_in_melee_arc(target_position: Vector2, direction: Vector2, radius: float, angle: float = PI) -> bool:
	var offset := target_position - global_position
	if offset.length_squared() > radius * radius:
		return false
	if offset.length_squared() <= 0.001:
		return true
	return direction.dot(offset.normalized()) >= cos(angle * 0.5)


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

	_sync_holy_strike_preview()
	melee_telegraph_visual.polygon = _arc_polygon(_get_melee_telegraph_radius(), _get_holy_strike_angle(), 24)
	melee_telegraph_visual.rotation = direction.angle()
	melee_telegraph_visual.color = melee_telegraph_color
	melee_telegraph_visual.visible = true


func _get_melee_telegraph_radius() -> float:
	return _get_holy_strike_radius() * MELEE_TELEGRAPH_RADIUS_SCALE


func _hide_melee_telegraph() -> void:
	if melee_telegraph_visual != null:
		melee_telegraph_visual.visible = false


func _sync_holy_strike_preview() -> void:
	if melee_hitbox_polygon != null:
		melee_hitbox_polygon.polygon = _arc_polygon(_get_holy_strike_radius(), _get_holy_strike_angle(), 24)
	if melee_effect_damage_preview != null:
		var holy_strike_radius := _get_holy_strike_radius()
		melee_effect_damage_preview.position = Vector2(holy_strike_radius * 0.5, 0.0)
		melee_effect_damage_preview.scale = Vector2.ONE * (holy_strike_radius * 2.0 / float(HOLY_SLASH_FRAME_SIZE.x))


func emit_container_broken(container: Node, attack_info: Dictionary = {}) -> void:
	if talent_container_gold_chance_enabled and randf() < 0.1:
		add_gold(1)
	container_broken.emit(container, attack_info)


func emit_shop_container_broken(container: Node, gold_cost: int) -> void:
	shop_container_broken.emit(container, gold_cost)


func emit_round_started(round_index: int = 0) -> void:
	round_started.emit(round_index)


func emit_round_ended() -> void:
	if talent_low_hp_round_end_heal_enabled and max_hp > 0.0 and hp / max_hp < 0.5:
		heal(max_hp * 0.3)
	round_ended.emit()
	if temporary_buffs != null:
		temporary_buffs.clear_round_buffs()


func _get_required_exp_for_next_level() -> int:
	return 10 + (level - 1) * 5


func _level_up() -> void:
	level += 1
	pending_talent_points += 1
	if talent_level_up_gold_enabled:
		add_gold(10)
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
	get_tree().create_timer(delay).timeout.connect(_play_holy_slash_effect.bind(direction))


func _play_holy_slash_effect(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		direction = facing_direction
	direction = direction.normalized()

	_sync_holy_strike_preview()
	var holy_strike_radius := _get_holy_strike_radius()
	var effect_position := direction * (holy_strike_radius * 0.5)
	var effect_scale := Vector2.ONE * (holy_strike_radius * 2.0 / float(HOLY_SLASH_FRAME_SIZE.x))
	if melee_effect_damage_preview != null:
		var local_offset := Vector2.ZERO
		if melee_attack_root != null:
			local_offset += melee_attack_root.position
		local_offset += melee_effect_damage_preview.position
		effect_position = local_offset.rotated(direction.angle())
		effect_scale = melee_effect_damage_preview.scale
	_play_spritesheet_effect(
		HOLY_SLASH_TEXTURE,
		&"holy_slash",
		effect_position,
		HOLY_SLASH_FPS,
		effect_scale,
		HOLY_SLASH_FRAME_SIZE,
		direction.angle(),
		self
	)


func _play_blessing_effect(effect_texture: Texture2D, animation_name: StringName, frame_size: Vector2i) -> void:
	_play_spritesheet_effect(
		effect_texture,
		animation_name,
		global_position,
		blessing_effect_fps,
		Vector2.ONE,
		frame_size
	)


func _play_spritesheet_effect(
	effect_texture: Texture2D,
	animation_name: StringName,
	spawn_position: Vector2,
	fps: float,
	effect_scale: Vector2 = Vector2.ONE,
	frame_size: Vector2i = FRAME_SIZE,
	effect_rotation: float = 0.0,
	effect_parent: Node2D = null
) -> void:
	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, fps)

	var frame_columns := int(effect_texture.get_width() / frame_size.x)
	var frame_rows := int(effect_texture.get_height() / frame_size.y)
	for row_index in range(frame_rows):
		for column_index in range(frame_columns):
			var frame_texture := AtlasTexture.new()
			frame_texture.atlas = effect_texture
			frame_texture.region = Rect2(column_index * frame_size.x, row_index * frame_size.y, frame_size.x, frame_size.y)
			sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = sprite_frames
	effect.animation = animation_name
	effect.centered = true
	effect.scale = effect_scale
	effect.rotation = effect_rotation
	effect.z_index = 20
	if effect_parent != null:
		effect_parent.add_child(effect)
		effect.position = spawn_position
	else:
		get_parent().add_child(effect)
		effect.global_position = spawn_position
	effect.animation_finished.connect(effect.queue_free)
	effect.play()


func _get_talent_definition(node_id: StringName) -> Dictionary:
	return talent_catalog.definition(node_id)


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
		&"kill_gold_chance":
			talent_kill_gold_chance_enabled = true
		&"elite_kill_common_item":
			talent_elite_kill_common_item_enabled = true
		&"container_gold_chance":
			talent_container_gold_chance_enabled = true
		&"level_up_gold":
			talent_level_up_gold_enabled = true
		&"rich_double_xp":
			talent_rich_double_xp_enabled = true
		&"normal_kill_gold_chance":
			talent_normal_kill_gold_chance_enabled = true
		&"normal_enemy_xp_bonus":
			talent_normal_enemy_xp_bonus_enabled = true
		&"normal_kill_common_item_counter":
			talent_normal_kill_common_item_counter_enabled = true
		&"normal_enemy_gold_double":
			talent_normal_enemy_gold_double_enabled = true
		&"elite_kill_gold":
			talent_elite_kill_gold_enabled = true
		&"elite_enemy_xp_bonus":
			talent_elite_enemy_xp_bonus_enabled = true
		&"elite_kill_rare_item":
			talent_elite_kill_rare_item_enabled = true
		&"round_healing_orb":
			talent_round_healing_orb_enabled = true
		&"low_hp_round_end_heal":
			talent_low_hp_round_end_heal_enabled = true
		&"defense_per_item":
			talent_defense_per_item_enabled = true
			_update_item_talent_bonuses()
		&"max_hp_per_common_item":
			talent_max_hp_per_common_item_enabled = true
			_update_item_talent_bonuses()
		&"item_max_hp_bonus_multiplier":
			talent_item_max_hp_bonus_multiplier_enabled = true
			_update_item_talent_bonuses()
		&"slide_defense_bonus":
			talent_slide_defense_bonus_enabled = true
		&"damage_taken_lifesteal":
			talent_damage_taken_lifesteal_enabled = true
		&"holy_strike_movement_stack":
			talent_holy_strike_movement_stack_enabled = true
		&"holy_strike_long_range":
			talent_holy_strike_long_range_enabled = true
		&"holy_strike_focused_zeal":
			talent_holy_strike_focused_zeal_enabled = true
			if stats != null:
				stats.apply_modifier(&"attack_speed_bonus", &"add", 1.0)
		&"holy_strike_crit_fireball_burst":
			talent_holy_strike_crit_fireball_burst_enabled = true
		&"holy_strike_lucky_critical_procs":
			talent_holy_strike_lucky_critical_procs_enabled = true
		&"holy_strike_move_speed_attack_speed":
			talent_holy_strike_move_speed_attack_speed_enabled = true
			_update_holy_strike_dynamic_talents()
		&"holy_strike_max_hp_range":
			talent_holy_strike_max_hp_range_enabled = true
		&"holy_strike_chain_lightning_pack":
			talent_holy_strike_chain_lightning_pack_enabled = true
		&"holy_strike_nearby_enemy_attack_speed":
			talent_holy_strike_nearby_enemy_attack_speed_enabled = true
			_update_holy_strike_nearby_enemy_attack_speed()
		&"holy_strike_more_weaker_enemies":
			talent_holy_strike_more_weaker_enemies_enabled = true
		&"holy_strike_elite_damage_per_kill":
			talent_holy_strike_elite_damage_per_kill_enabled = true
		&"holy_strike_zombie_inscriptions":
			talent_holy_strike_zombie_inscriptions_enabled = true
		&"holy_strike_heavy_smite":
			talent_holy_strike_heavy_smite_enabled = true
			if stats != null:
				stats.apply_modifier(&"attack_speed_bonus", &"add", -0.3)
		&"holy_strike_stationary_crit":
			talent_holy_strike_stationary_crit_enabled = true
		&"holy_strike_elite_smite":
			talent_holy_strike_elite_smite_enabled = true
		&"holy_strike_stationary_atk":
			talent_holy_strike_stationary_atk_enabled = true
		&"holy_strike_double_tombs":
			talent_holy_strike_double_tombs_enabled = true
		&"holy_strike_undamaged_stationary":
			talent_holy_strike_undamaged_stationary_enabled = true
		&"wizard_slide_fireball_blast":
			talent_wizard_slide_fireball_blast_enabled = true
		&"wizard_poison_stack_damage":
			talent_wizard_poison_stack_damage_enabled = true
		&"wizard_nearby_enemy_attack_speed":
			talent_wizard_nearby_enemy_attack_speed_enabled = true
			_update_wizard_nearby_enemy_attack_speed()
		&"wizard_nearby_damage_focus":
			talent_wizard_nearby_damage_focus_enabled = true
		&"wizard_fire_surge_left_click_blast":
			talent_wizard_fire_surge_left_click_blast_enabled = true
		&"wizard_nearby_kill_gold":
			talent_wizard_nearby_kill_gold_enabled = true
		&"wizard_dash_fireball":
			talent_wizard_dash_fireball_enabled = true
		&"wizard_nearby_enemy_move_speed":
			talent_wizard_nearby_enemy_move_speed_enabled = true
			_update_wizard_nearby_enemy_move_speed()
		&"wizard_nearby_poison_aura":
			talent_wizard_nearby_poison_aura_enabled = true
			wizard_nearby_poison_aura_timer = 5.0
		&"wizard_poisoned_kill_gold":
			talent_wizard_poisoned_kill_gold_enabled = true
		&"wizard_short_laser_double_damage":
			talent_wizard_short_laser_double_damage_enabled = true
		&"wizard_nearby_enemy_elite_damage":
			talent_wizard_nearby_enemy_elite_damage_enabled = true
			_update_wizard_nearby_enemy_elite_damage()
		&"wizard_more_weaker_enemies":
			talent_wizard_more_weaker_enemies_enabled = true
		&"wizard_rebirth_level_to_atk":
			talent_wizard_rebirth_level_to_atk_enabled = true
		&"wizard_primary_fireball_laser_explosion":
			talent_wizard_primary_fireball_laser_explosion_enabled = true
		&"wizard_fire_surge_laser":
			talent_wizard_fire_surge_laser_enabled = true
		&"wizard_fire_laser_chain":
			talent_wizard_fire_laser_chain_enabled = true
		&"wizard_fire_surge_attack_speed":
			talent_wizard_fire_surge_attack_speed_enabled = true
			_update_wizard_fire_surge_attack_speed_bonus()
		&"wizard_attack_speed_laser_chain":
			talent_wizard_attack_speed_laser_chain_enabled = true
		&"wizard_fire_essence_burst":
			talent_wizard_fire_essence_burst_enabled = true
			wizard_fire_essence_spawn_timer = 5.0
		&"wizard_kill_move_speed_burst":
			talent_wizard_kill_move_speed_burst_enabled = true
		&"wizard_fire_surge_radial_fireballs":
			talent_wizard_fire_surge_radial_fireballs_enabled = true
		&"wizard_max_hp_primary_echo":
			talent_wizard_max_hp_primary_echo_enabled = true
		&"wizard_move_speed_extra_fireballs":
			talent_wizard_move_speed_extra_fireballs_enabled = true
		&"wizard_poisoned_death_fireball":
			talent_wizard_poisoned_death_fireball_enabled = true
		&"wizard_rare_item_move_speed":
			talent_wizard_rare_item_move_speed_enabled = true
			_update_item_talent_bonuses()
		&"wizard_fire_essence_explosion_scatter":
			talent_wizard_fire_essence_explosion_scatter_enabled = true
		&"wizard_random_double_fireballs":
			talent_wizard_random_double_fireballs_enabled = true
		&"wizard_guaranteed_legendary_shop_jar":
			talent_wizard_guaranteed_legendary_shop_jar_enabled = true
		&"wizard_natural_fireball_radius":
			talent_wizard_natural_fireball_radius_enabled = true
		&"wizard_legendary_extra_fireballs":
			talent_wizard_legendary_extra_fireballs_enabled = true
		&"wizard_natural_fireball_heal":
			talent_wizard_natural_fireball_heal_enabled = true
		&"wizard_damage_taken_natural_explode_fireballs":
			talent_wizard_damage_taken_natural_explode_fireballs_enabled = true
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
	if talent_slide_defense_bonus_enabled and temporary_buffs != null and stats != null:
		temporary_buffs.add_timed_stat_buff(&"talent_slide_defense_bonus", &"defense", float(stats.defense) * 0.5, 2.0, 1)
	if talent_next_attack_after_slide_enabled:
		next_attack_after_slide_ready = true
	if talent_wizard_slide_fireball_blast_enabled:
		next_wizard_slide_fireball_ready = true


func _update_max_hp_from_atk_talent() -> void:
	if not talent_max_hp_from_atk_enabled or stats == null:
		return

	var wanted_bonus: int = maxi(stats.atk, 0)
	var delta: int = wanted_bonus - applied_max_hp_from_atk
	if delta == 0:
		return

	applied_max_hp_from_atk = wanted_bonus
	stats.apply_modifier(&"max_hp", &"add", float(delta))


func _update_item_talent_bonuses() -> void:
	if stats == null or inventory == null:
		return

	var total_item_count := _get_total_item_count()
	var wanted_defense := total_item_count * 5 if talent_defense_per_item_enabled else 0
	var defense_delta := wanted_defense - applied_item_defense_bonus
	if defense_delta != 0:
		applied_item_defense_bonus = wanted_defense
		stats.apply_modifier(&"defense", &"add", float(defense_delta))

	var common_item_count := _get_item_count_by_rarity(&"common")
	var base_max_hp_bonus := common_item_count * 3 if talent_max_hp_per_common_item_enabled else 0
	var multiplier := 1.3 if talent_item_max_hp_bonus_multiplier_enabled else 1.0
	var wanted_max_hp := int(round(float(base_max_hp_bonus) * multiplier))
	var max_hp_delta := wanted_max_hp - applied_item_max_hp_bonus
	if max_hp_delta != 0:
		applied_item_max_hp_bonus = wanted_max_hp
		stats.apply_modifier(&"max_hp", &"add", float(max_hp_delta))

	var rare_item_count := _get_item_count_by_rarity(&"rare")
	var wanted_rare_move_speed := rare_item_count * 10 if talent_wizard_rare_item_move_speed_enabled else 0
	var rare_move_speed_delta := wanted_rare_move_speed - applied_wizard_rare_item_move_speed
	if rare_move_speed_delta != 0:
		applied_wizard_rare_item_move_speed = wanted_rare_move_speed
		stats.apply_modifier(&"bonus_move_speed_flat", &"add", float(rare_move_speed_delta))


func _get_total_item_count() -> int:
	if inventory == null:
		return 0

	var total := 0
	for item_id in inventory.item_counts.keys():
		total += int(inventory.item_counts.get(item_id, 0))
	return total


func _get_item_count_by_rarity(rarity: StringName) -> int:
	if inventory == null:
		return 0

	var total := 0
	for item_id in inventory.item_counts.keys():
		var item := inventory.item_definitions_by_id.get(item_id) as ItemDefinition
		if item != null and item.rarity == rarity:
			total += int(inventory.item_counts.get(item_id, 0))
	return total


func _update_holy_strike_dynamic_talents() -> void:
	if not talent_holy_strike_move_speed_attack_speed_enabled or temporary_buffs == null or stats == null:
		return

	var move_speed_value: float = stats.get_move_speed(move_speed)
	var attack_speed_bonus: float = floorf(move_speed_value / 10.0) * 0.01
	if is_equal_approx(attack_speed_bonus, applied_holy_strike_move_speed_attack_speed):
		return
	applied_holy_strike_move_speed_attack_speed = attack_speed_bonus
	temporary_buffs.set_dynamic_stat_bonus(&"holy_strike_move_speed_attack_speed", &"attack_speed_bonus", attack_speed_bonus)


func _update_holy_strike_nearby_enemy_attack_speed() -> void:
	if not talent_holy_strike_nearby_enemy_attack_speed_enabled or temporary_buffs == null or stats == null:
		return

	var nearby_enemy_count := EFFECT_TARGETING.enemies_surrounding(self, global_position).size()
	nearby_enemy_count += maxi(stats.surrounded_enemy_count_bonus, 0)
	var attack_speed_bonus := float(nearby_enemy_count) * 0.05
	if is_equal_approx(attack_speed_bonus, applied_holy_strike_nearby_enemy_attack_speed):
		return
	applied_holy_strike_nearby_enemy_attack_speed = attack_speed_bonus
	temporary_buffs.set_dynamic_stat_bonus(&"holy_strike_nearby_enemy_attack_speed", &"attack_speed_bonus", attack_speed_bonus)


func _update_wizard_nearby_enemy_attack_speed() -> void:
	if not talent_wizard_nearby_enemy_attack_speed_enabled or temporary_buffs == null or stats == null:
		return

	var nearby_enemy_count := EFFECT_TARGETING.enemies_surrounding(self, global_position).size()
	var attack_speed_bonus := float(nearby_enemy_count) * 0.05
	if is_equal_approx(attack_speed_bonus, applied_wizard_nearby_enemy_attack_speed):
		return
	applied_wizard_nearby_enemy_attack_speed = attack_speed_bonus
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_nearby_enemy_attack_speed", &"attack_speed_bonus", attack_speed_bonus)


func _update_wizard_nearby_enemy_move_speed() -> void:
	if not talent_wizard_nearby_enemy_move_speed_enabled or temporary_buffs == null or stats == null:
		return

	var nearby_enemy_count := EFFECT_TARGETING.enemies_surrounding(self, global_position).size()
	var move_speed_bonus := float(nearby_enemy_count) * 0.05
	if is_equal_approx(move_speed_bonus, applied_wizard_nearby_enemy_move_speed):
		return
	applied_wizard_nearby_enemy_move_speed = move_speed_bonus
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_nearby_enemy_move_speed", &"movement_speed_bonus", move_speed_bonus)


func _update_wizard_nearby_enemy_elite_damage() -> void:
	if not talent_wizard_nearby_enemy_elite_damage_enabled or temporary_buffs == null or stats == null:
		return

	var nearby_enemy_count := EFFECT_TARGETING.enemies_surrounding(self, global_position).size()
	var elite_damage_bonus := float(nearby_enemy_count) * 0.1
	if is_equal_approx(elite_damage_bonus, applied_wizard_nearby_enemy_elite_damage):
		return
	applied_wizard_nearby_enemy_elite_damage = elite_damage_bonus
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_nearby_enemy_elite_damage", &"elite_direct_damage_bonus", elite_damage_bonus)


func _update_wizard_fire_surge_attack_speed_bonus() -> void:
	if temporary_buffs == null:
		return
	var wanted_bonus := 0.5 if talent_wizard_fire_surge_attack_speed_enabled and fire_surge_remaining > 0.0 else 0.0
	temporary_buffs.set_dynamic_stat_bonus(&"wizard_fire_surge_attack_speed", &"attack_speed_bonus", wanted_bonus)


func _update_wizard_nearby_poison_aura(delta: float) -> void:
	if not talent_wizard_nearby_poison_aura_enabled:
		return

	wizard_nearby_poison_aura_timer -= delta
	while wizard_nearby_poison_aura_timer <= 0.0:
		wizard_nearby_poison_aura_timer += 5.0
		for enemy in EFFECT_TARGETING.enemies_surrounding(self, global_position):
			if enemy.has_method("apply_poison_stacks"):
				enemy.apply_poison_stacks(1, self)


func _update_wizard_fire_essence_spawner(delta: float) -> void:
	if not talent_wizard_fire_essence_burst_enabled:
		return

	wizard_fire_essence_spawn_timer -= delta
	while wizard_fire_essence_spawn_timer <= 0.0:
		wizard_fire_essence_spawn_timer += 5.0
		_spawn_wizard_fire_essence()


func _spawn_wizard_fire_essence() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var distance := sqrt(randf()) * 400.0
	var angle := randf_range(0.0, TAU)
	var spawn_position := global_position + Vector2(cos(angle), sin(angle)) * distance
	if movement_bounds_enabled:
		spawn_position.x = clampf(spawn_position.x, movement_bounds.position.x, movement_bounds.end.x)
		spawn_position.y = clampf(spawn_position.y, movement_bounds.position.y, movement_bounds.end.y)

	var essence := FIRE_ESSENCE_PICKUP_SCRIPT.new() as Node2D
	essence.setup(spawn_position, self)
	get_tree().current_scene.add_child(essence)


func _update_holy_strike_stationary_talents(delta: float) -> void:
	holy_strike_undamaged_time += delta
	var effective_stationary := _is_holy_strike_effectively_stationary()
	if effective_stationary:
		holy_strike_stationary_time += delta
	else:
		holy_strike_stationary_time = 0.0

	_update_holy_strike_stationary_atk(delta, effective_stationary)
	_update_holy_strike_undamaged_move_speed()


func _update_holy_strike_stationary_atk(delta: float, effective_stationary: bool) -> void:
	if not talent_holy_strike_stationary_atk_enabled or stats == null:
		return

	if not effective_stationary:
		if holy_strike_stationary_atk_stacks > 0:
			stats.apply_modifier(&"atk", &"add", -float(holy_strike_stationary_atk_stacks))
			holy_strike_stationary_atk_stacks = 0
		holy_strike_stationary_atk_timer = 0.0
		return

	holy_strike_stationary_atk_timer += delta
	while holy_strike_stationary_atk_timer >= 1.0:
		holy_strike_stationary_atk_timer -= 1.0
		holy_strike_stationary_atk_stacks += 1
		stats.apply_modifier(&"atk", &"add", 1.0)


func _update_holy_strike_undamaged_move_speed() -> void:
	if not talent_holy_strike_undamaged_stationary_enabled or temporary_buffs == null:
		return

	var wanted_bonus := -0.3 if holy_strike_undamaged_time >= 5.0 else 0.0
	if is_equal_approx(wanted_bonus, applied_holy_strike_undamaged_move_speed):
		return
	applied_holy_strike_undamaged_move_speed = wanted_bonus
	temporary_buffs.set_dynamic_stat_bonus(&"holy_strike_undamaged_stationary_move_speed", &"movement_speed_bonus", wanted_bonus)


func _is_holy_strike_effectively_stationary() -> bool:
	if talent_holy_strike_undamaged_stationary_enabled and holy_strike_undamaged_time >= 5.0:
		return true
	if state == State.DASHING or state == State.SLIDING:
		return false
	if _get_move_input().length_squared() > 0.001:
		return false
	return velocity.length_squared() <= 16.0


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


func _grant_random_common_item() -> void:
	_grant_random_item(&"common")


func _grant_random_item(rarity: StringName) -> void:
	var database := get_node_or_null("/root/ItemDatabase")
	if database == null or not database.has_method("get_random_item"):
		return

	var item := database.get_random_item(&"", rarity) as ItemDefinition
	if item == null and rarity != &"common":
		item = database.get_random_item(&"", &"common") as ItemDefinition
	if item != null:
		add_item(item)


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


func _is_enemy_nearby(enemy: Node) -> bool:
	var enemy_2d := enemy as Node2D
	return enemy_2d != null and _get_distance_to_enemy(enemy_2d) <= EFFECT_TARGETING.SURROUNDED_RADIUS


func _enemy_has_status(enemy: Node, status_id: StringName) -> bool:
	return enemy != null and enemy.has_method("has_status") and enemy.has_status(status_id)


func _get_enemy_poison_stacks(enemy: Node) -> int:
	if enemy != null and enemy.has_method("get_poison_stacks"):
		return maxi(int(enemy.get_poison_stacks()), 0)
	return 0


func _is_enemy_poisoned(enemy: Node) -> bool:
	return _enemy_has_status(enemy, &"poison") or _get_enemy_poison_stacks(enemy) > 0


func _trigger_wizard_poisoned_death_fireball(enemy: Node) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var enemy_2d := enemy as Node2D
	var origin := enemy_2d.global_position if enemy_2d != null else global_position
	var target := EFFECT_TARGETING.nearest_enemy(self, origin, 700.0, [enemy])
	if target != null:
		_launch_talent_fireball(origin, target.global_position)
	else:
		_launch_talent_fireball(origin, origin + facing_direction)


func _try_trigger_talent_fireball(enemy: Node, attack_info: Dictionary = {}) -> void:
	if stats == null or stats.fireball_chance <= 0.0:
		return
	if not _roll_holy_strike_proc(stats.fireball_chance, attack_info):
		return

	var enemy_2d := enemy as Node2D
	if enemy_2d == null:
		return

	_launch_talent_fireball(global_position, enemy_2d.global_position)


func _apply_holy_strike_on_hit_talents(enemy: Node, attack_info: Dictionary) -> void:
	if not _is_holy_strike_attack(attack_info):
		return

	if talent_holy_strike_movement_stack_enabled and temporary_buffs != null:
		temporary_buffs.add_timed_stat_buff(&"holy_strike_movement_stack", &"bonus_move_speed_flat", 5.0, 3.0, 999999)

	if talent_holy_strike_crit_fireball_burst_enabled and bool(attack_info.get("critical", false)):
		if _roll_holy_strike_proc(0.5, attack_info):
			var enemy_2d := enemy as Node2D
			if enemy_2d != null:
				_launch_holy_strike_fireball_burst(enemy_2d.global_position)


func _roll_holy_strike_proc(chance: float, attack_info: Dictionary) -> bool:
	var clamped_chance := clampf(chance, 0.0, 1.0)
	if clamped_chance <= 0.0:
		return false
	if clamped_chance >= 1.0:
		return true
	if _should_roll_holy_strike_proc_lucky(attack_info):
		return randf() < clamped_chance or randf() < clamped_chance
	return randf() < clamped_chance


func _roll_attack_crit(attack_info: Dictionary) -> bool:
	if stats == null:
		return false
	if (
		_is_holy_strike_attack(attack_info)
		and talent_holy_strike_stationary_crit_enabled
		and holy_strike_stationary_time >= 2.0
	):
		holy_strike_stationary_time = 0.0
		return true
	return randf() < stats.critical_chance


func _should_roll_holy_strike_proc_lucky(attack_info: Dictionary) -> bool:
	return (
		talent_holy_strike_lucky_critical_procs_enabled
		and _is_holy_strike_attack(attack_info)
		and bool(attack_info.get("critical", false))
	)


func _is_holy_strike_attack(attack_info: Dictionary) -> bool:
	return StringName(attack_info.get("source", &"")) == &"player_attack"


func _launch_holy_strike_fireball_burst(origin: Vector2) -> void:
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		_launch_talent_fireball(origin, origin + Vector2(cos(angle), sin(angle)))


func _trigger_holy_strike_chain_lightning(origin: Vector2) -> void:
	if get_tree().current_scene == null:
		return

	var damage := get_base_attack_damage() * 0.8
	var current_position := origin
	var hit: Array = []
	var did_hit := false
	for _index in range(5):
		var target := EFFECT_TARGETING.nearest_enemy(self, current_position, 420.0, hit)
		if target == null:
			break

		var previous_position := current_position
		hit.append(target)
		current_position = target.global_position
		_spawn_holy_strike_chain_lightning_vfx(previous_position, current_position)
		deal_player_damage_to_enemy(target, damage, {"source": "holy_strike_chain_lightning", "direct": true, "allow_procs": false})
		did_hit = true

	if did_hit:
		SFX_PLAYER.play_2d(get_tree().current_scene, LIGHTNING_CHAIN_SFX, origin, -4.0, 0.96, 1.04)


func _spawn_holy_strike_chain_lightning_vfx(start_position: Vector2, end_position: Vector2) -> void:
	var texture := load(LIGHTNING_CHAIN_TEXTURE_PATH) as Texture2D
	if texture == null or get_tree().current_scene == null:
		return

	var offset := end_position - start_position
	var length := offset.length()
	if length <= 0.001:
		return

	var sprite_frames := SpriteFrames.new()
	var animation_name := &"chain"
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, 20.0)

	var frame_count := int(texture.get_height() / LIGHTNING_CHAIN_FRAME_SIZE.y)
	for frame_index in range(frame_count):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(0.0, float(frame_index) * LIGHTNING_CHAIN_FRAME_SIZE.y, LIGHTNING_CHAIN_FRAME_SIZE.x, LIGHTNING_CHAIN_FRAME_SIZE.y)
		sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.name = "HolyStrikeChainLightningVFX"
	effect.sprite_frames = sprite_frames
	effect.centered = true
	effect.rotation = offset.angle()
	effect.scale = Vector2(length / LIGHTNING_CHAIN_FRAME_SIZE.x, 1.0)
	effect.z_index = 140
	get_tree().current_scene.add_child(effect)
	effect.global_position = (start_position + end_position) * 0.5
	effect.play(animation_name)
	effect.animation_finished.connect(effect.queue_free)


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
	if talent_catalog.has_method("coords"):
		return talent_catalog.coords()
	return []


func _get_talent_node_id(coord: Vector2i) -> StringName:
	if talent_catalog.has_method("node_id"):
		return talent_catalog.node_id(coord)
	return &""


func _is_talent_coord_valid(coord: Vector2i) -> bool:
	return talent_catalog.has_method("is_coord_valid") and talent_catalog.is_coord_valid(coord)


func _is_talent_start_coord(coord: Vector2i) -> bool:
	return talent_catalog.has_method("is_start_coord") and talent_catalog.is_start_coord(coord)


func _get_talent_neighbor_coords(coord: Vector2i) -> Array[Vector2i]:
	if talent_catalog.has_method("neighbor_coords"):
		return talent_catalog.neighbor_coords(coord)
	return []


func _is_talent_start_node(node_id: StringName) -> bool:
	if talent_catalog.has_method("start_nodes"):
		return talent_catalog.start_nodes().has(node_id)
	return _is_talent_start_coord(get_talent_node_grid_position(node_id))


func _get_talent_ui_position_from_grid(coord: Vector2i) -> Vector2:
	var spacing := Vector2(78.0, 86.0)
	var center_x: float = 360.0
	var bottom_y: float = 716.0
	return Vector2(
		center_x + (float(coord.x) - 3.0) * spacing.x,
		bottom_y - float(coord.y) * spacing.y
	)


func _get_animation_texture(animation_name: StringName) -> Texture2D:
	if character_definition != null:
		var texture: Texture2D = character_definition.get_texture(animation_name)
		if texture != null:
			return texture
	match animation_name:
		&"attack":
			return ATTACK_TEXTURE
		&"attack_alt":
			return ATTACK_ALT_TEXTURE
		&"ability":
			return ABILITY_TEXTURE
		&"pummel":
			return PUMMEL_TEXTURE
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


func _apply_attack_status_procs(enemy: Node, attack_info: Dictionary = {}) -> void:
	if stats == null or enemy == null:
		return
	if _roll_holy_strike_proc(stats.bleed_chance, attack_info) and enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect(&"bleeding", self)
	if _roll_holy_strike_proc(stats.poison_chance, attack_info) and enemy.has_method("apply_status_effect"):
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
	return _arc_polygon(radius, PI, points)


func _arc_polygon(radius: float, angle: float, points: int) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	polygon.append(Vector2.ZERO)
	for point in range(points + 1):
		var point_angle: float = -angle * 0.5 + angle * float(point) / float(maxi(points, 1))
		polygon.append(Vector2(cos(point_angle), sin(point_angle)) * radius)

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
		&"pummel",
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
	var primary_active_frame := _get_ability_active_frame(&"primary", ATTACK_PROJECTILE_FRAME)
	if frame < primary_active_frame:
		return _get_attack_windup_frame_duration(frame)

	var slow_edge_frames: int = clampi(attack_slow_edge_frames, 0, FRAMES_PER_DIRECTION)
	var slow_recovery_start: int = max(primary_active_frame, FRAMES_PER_DIRECTION - slow_edge_frames)
	if frame >= slow_recovery_start:
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	var windup_time: float = _get_attack_base_windup_time()
	var slow_recovery_frame_count: int = FRAMES_PER_DIRECTION - slow_recovery_start
	var slow_recovery_time: float = float(slow_recovery_frame_count) / maxf(attack_edge_animation_fps, 0.01)
	var middle_recovery_frame_count: int = slow_recovery_start - primary_active_frame
	if middle_recovery_frame_count <= 0:
		return 1.0 / maxf(attack_edge_animation_fps, 0.01)

	var middle_recovery_time: float = maxf(_get_base_fire_interval() - windup_time - slow_recovery_time, 0.001)
	return middle_recovery_time / float(middle_recovery_frame_count)


func _get_attack_windup_frame_duration(frame: int) -> float:
	var primary_active_frame := _get_ability_active_frame(&"primary", ATTACK_PROJECTILE_FRAME)
	if frame < clampi(attack_slow_edge_frames, 0, primary_active_frame):
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
