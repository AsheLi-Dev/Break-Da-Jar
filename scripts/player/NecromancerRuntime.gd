extends RefCounted
class_name NecromancerRuntime

const HOLY_FLAME_LASER_SCRIPT := preload("res://systems/combat/HolyFlameLaser.gd")
const NECROMANCER_SHADOW_SCRIPT := preload("res://systems/combat/NecromancerShadow.gd")
const SKELETON_ARCHER_SCENE: PackedScene = preload("res://scenes/summons/SkeletonArcher.tscn")
const HEALING_OVER_TIME_SCRIPT := preload("res://systems/combat/HealingOverTimeEffect.gd")
const DEATH_EXPLOSION_TEXTURE: Texture2D = preload("res://assets/vfx/dark spell/dark_explosion.png")

const SOUL_SIPHON_BEAM_TEXTURE_PATH := "res://assets/vfx/dark spell/soul_siphon_beam.png"
const SOUL_SIPHON_BEAM_FRAME_SIZE := Vector2i(265, 81)
const SOUL_SIPHON_BEAM_FRAME_COUNT := 7
const SOUL_SIPHON_LIGHTNING_OVERLAY_TEXTURE_PATH := "res://assets/vfx/dark spell/soul_siphon_lightning_overlay.png"
const SOUL_SIPHON_LIGHTNING_OVERLAY_FRAME_SIZE := Vector2i(256, 128)
const SOUL_SIPHON_LIGHTNING_OVERLAY_FRAME_COUNT := 6
const DEATH_EXPLOSION_FRAME_SIZE := Vector2i(144, 144)
const DEATH_EXPLOSION_ANIMATION_FPS := 20.0
const MAX_SKELETON_ARCHERS := 3
const SKELETON_ARCHER_LIFETIME := 10.0
const SLIDE_SKELETON_ARCHER_ATTACK_SPEED_MULTIPLIER := 1.2
const SLIDE_SKELETON_ARCHER_ATTACK_SPEED_DURATION := 2.0
const SOUL_SIPHON_SKELETON_ARCHER_ATTACK_SPEED_MULTIPLIER := 2.0
const SOUL_SIPHON_SKELETON_ARCHER_ATTACK_SPEED_DURATION := 2.0
const DEATH_EXPLOSION_RADIUS := 150.0
const DEATH_EXPLOSION_DAMAGE_MULTIPLIER := 0.5
const ROUND_MOVE_SPEED_BONUS_PER_SECOND := 0.05

var enabled_talents: Dictionary = {}
var xp_kill_counter: int = 0
var gold_kill_counter: int = 0
var defense_kill_counter: int = 0
var atk_kill_counter: int = 0
var max_hp_kill_counter: int = 0
var skeleton_archer_damage_kill_counter: int = 0
var skeleton_archer_damage_kill_stacks: int = 0
var primary_damage_kill_counter: int = 0
var primary_damage_kill_stacks: int = 0
var kill_atk_damage_loss_bonus: int = 0
var next_slide_soul_siphon_ready: bool = false
var slide_skeleton_archer_attack_speed_remaining: float = 0.0
var skeleton_archers: Array[Node] = []
var black_shadow: Node2D
var round_movement_speed_active: bool = false
var round_movement_speed_timer: float = 0.0
var hit_move_speed_buff_counter: int = 0
var charged_primary_damage_timer: float = 0.0
var recently_primary_damaged_enemy: Node
var recently_skeleton_damaged_enemy: Node


func enable_talent(effect_id: StringName) -> void:
	enabled_talents[effect_id] = true


func has_talent(effect_id: StringName) -> bool:
	return bool(enabled_talents.get(effect_id, false))


func apply_talent_effect(effect_id: StringName, _player) -> bool:
	if not String(effect_id).begins_with("necromancer_"):
		return false
	enable_talent(effect_id)
	return true


func get_compat_property(property: StringName) -> Variant:
	match property:
		&"necromancer_xp_kill_counter":
			return xp_kill_counter
		&"necromancer_gold_kill_counter":
			return gold_kill_counter
		&"necromancer_defense_kill_counter":
			return defense_kill_counter
		&"necromancer_atk_kill_counter":
			return atk_kill_counter
		&"necromancer_max_hp_kill_counter":
			return max_hp_kill_counter
		&"necromancer_skeleton_archer_damage_kill_counter":
			return skeleton_archer_damage_kill_counter
		&"necromancer_skeleton_archer_damage_kill_stacks":
			return skeleton_archer_damage_kill_stacks
		&"necromancer_primary_damage_kill_counter":
			return primary_damage_kill_counter
		&"necromancer_primary_damage_kill_stacks":
			return primary_damage_kill_stacks
		&"necromancer_kill_atk_damage_loss_bonus":
			return kill_atk_damage_loss_bonus
		&"next_necromancer_slide_soul_siphon_ready":
			return next_slide_soul_siphon_ready
		&"necromancer_slide_skeleton_archer_attack_speed_remaining":
			return slide_skeleton_archer_attack_speed_remaining
		&"necromancer_skeleton_archers":
			return skeleton_archers
		&"necromancer_black_shadow":
			return black_shadow
	return null


func set_compat_property(property: StringName, value: Variant) -> bool:
	match property:
		&"necromancer_xp_kill_counter":
			xp_kill_counter = int(value)
		&"necromancer_gold_kill_counter":
			gold_kill_counter = int(value)
		&"necromancer_defense_kill_counter":
			defense_kill_counter = int(value)
		&"necromancer_atk_kill_counter":
			atk_kill_counter = int(value)
		&"necromancer_max_hp_kill_counter":
			max_hp_kill_counter = int(value)
		&"necromancer_skeleton_archer_damage_kill_counter":
			skeleton_archer_damage_kill_counter = int(value)
		&"necromancer_skeleton_archer_damage_kill_stacks":
			skeleton_archer_damage_kill_stacks = int(value)
		&"necromancer_primary_damage_kill_counter":
			primary_damage_kill_counter = int(value)
		&"necromancer_primary_damage_kill_stacks":
			primary_damage_kill_stacks = int(value)
		&"necromancer_kill_atk_damage_loss_bonus":
			kill_atk_damage_loss_bonus = int(value)
		&"next_necromancer_slide_soul_siphon_ready":
			next_slide_soul_siphon_ready = bool(value)
		&"necromancer_slide_skeleton_archer_attack_speed_remaining":
			slide_skeleton_archer_attack_speed_remaining = float(value)
		&"necromancer_skeleton_archers":
			skeleton_archers.clear()
			for archer in value:
				if archer is Node:
					skeleton_archers.append(archer)
		&"necromancer_black_shadow":
			black_shadow = value
		_:
			return false
	return true


func launch_soul_orb(player, target_position: Vector2) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	var direction := _direction_to(player, target_position)
	var projectile = player.call("_make_player_projectile")
	if projectile == null:
		return
	var damage: float = player.get_base_attack_damage()
	if player.utility_ability == &"necromancer_soul_surge" and player.fire_surge_remaining > 0.0:
		damage *= 1.25
	damage *= get_primary_damage_kill_multiplier()
	damage *= consume_charged_primary_damage_multiplier()
	projectile.global_position = player.global_position + direction * 28.0
	projectile.owner_player = player
	projectile.debug_color = Color(0.52, 0.16, 0.92)
	projectile.setup(direction, damage, 560.0, 1.0, &"enemy")
	projectile.collision_layer = 1 << 2
	projectile.collision_mask = 1 << 1
	player.attack_started.emit(player.global_position, direction, {"source": "necromancer_soul_orb", "direct": true, "allow_procs": true})
	player.get_tree().current_scene.add_child(projectile)


func cast_soul_beam(player) -> void:
	spawn_soul_beam(player, player.global_position, _direction_to(player, player.pending_shockwave_target_position))


func fire_soul_beam(player, target_position: Vector2) -> void:
	spawn_soul_beam(player, player.global_position, _direction_to(player, target_position), true)


func spawn_soul_beam(player, start_position: Vector2, direction: Vector2, consume_primary_charge: bool = false) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	var laser := HOLY_FLAME_LASER_SCRIPT.new() as HolyFlameLaser
	laser.length = 300.0
	laser.width = 52.0
	laser.animation_fps = 24.0
	laser.beam_texture = player.call("_load_texture_compat", SOUL_SIPHON_BEAM_TEXTURE_PATH)
	laser.beam_frame_size = SOUL_SIPHON_BEAM_FRAME_SIZE
	laser.beam_frame_count = SOUL_SIPHON_BEAM_FRAME_COUNT
	laser.overlay_beam_texture = player.call("_load_texture_compat", SOUL_SIPHON_LIGHTNING_OVERLAY_TEXTURE_PATH)
	laser.overlay_beam_frame_size = SOUL_SIPHON_LIGHTNING_OVERLAY_FRAME_SIZE
	laser.overlay_beam_frame_count = SOUL_SIPHON_LIGHTNING_OVERLAY_FRAME_COUNT
	laser.modulate = Color(1.0, 1.0, 1.0, 0.95)
	var damage: float = player.get_base_attack_damage() * 1.35
	if has_talent(&"necromancer_soul_siphon_damage_bonus"):
		damage *= 1.15
	if has_talent(&"necromancer_soul_siphon_damage_per_skeleton_archer"):
		cleanup_skeleton_archers(false)
		damage *= 1.0 + 0.1 * float(skeleton_archers.size())
	if next_slide_soul_siphon_ready:
		damage *= 1.3
		next_slide_soul_siphon_ready = false
	if player.utility_ability == &"necromancer_soul_surge" and player.fire_surge_remaining > 0.0:
		damage *= 1.25
	damage *= get_primary_damage_kill_multiplier()
	if consume_primary_charge:
		damage *= consume_charged_primary_damage_multiplier()
	laser.setup(player, start_position, direction.normalized(), damage, "necromancer_soul_beam", true)
	laser.collision_layer = 0
	laser.collision_mask = 0
	laser.set_collision_mask_value(player.enemy_collision_layer_number, true)
	laser.set_collision_mask_value(player.jar_collision_layer_number, true)
	player.get_tree().current_scene.add_child(laser)


func summon_skeleton_archer(player) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	cleanup_skeleton_archers(false)
	if skeleton_archers.size() >= get_skeleton_archer_cap():
		return
	var summon_position: Vector2 = player.pending_shockwave_target_position
	var archer := SKELETON_ARCHER_SCENE.instantiate() as Node2D
	if archer == null:
		return
	var follow_offset: Vector2 = summon_position - player.global_position
	if archer.has_method("setup"):
		archer.call("setup", player, follow_offset)
	if has_talent(&"necromancer_skeleton_archer_damage_bonus"):
		archer.damage_inherit_multiplier *= 1.15
	archer.damage_inherit_multiplier *= get_skeleton_archer_damage_kill_multiplier()
	if has_talent(&"necromancer_skeleton_archer_damage_growth"):
		archer.damage_growth_per_second = 0.02
	if has_talent(&"necromancer_skeleton_archer_poison_chance"):
		archer.poison_chance = 0.2
	if has_talent(&"necromancer_skeleton_archer_attack_speed_bonus"):
		archer.attack_speed_inherit_multiplier *= 1.15
	if slide_skeleton_archer_attack_speed_remaining > 0.0 and archer.has_method("apply_timed_attack_speed_multiplier"):
		archer.call("apply_timed_attack_speed_multiplier", SLIDE_SKELETON_ARCHER_ATTACK_SPEED_MULTIPLIER, slide_skeleton_archer_attack_speed_remaining)
	archer.global_position = summon_position
	player.get_tree().current_scene.add_child(archer)
	skeleton_archers.append(archer)
	var lifetime_timer := Timer.new()
	lifetime_timer.name = "LifetimeTimer"
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = get_skeleton_archer_lifetime()
	archer.add_child(lifetime_timer)
	lifetime_timer.timeout.connect(expire_skeleton_archer.bind(archer.get_instance_id(), player))
	lifetime_timer.start()


func get_skeleton_archer_cap() -> int:
	var cap := MAX_SKELETON_ARCHERS
	if has_talent(&"necromancer_skeleton_archer_lifetime_and_cap"):
		cap += 1
	if has_talent(&"necromancer_container_break_skeleton_archer"):
		cap += 1
	if has_talent(&"necromancer_kill_skeleton_archer"):
		cap += 2
	return cap


func get_skeleton_archer_lifetime() -> float:
	if has_talent(&"necromancer_skeleton_archer_lifetime_and_cap"):
		return SKELETON_ARCHER_LIFETIME * 2.0
	return SKELETON_ARCHER_LIFETIME


func spawn_black_shadow(player) -> void:
	if player.get_tree() == null or player.get_tree().current_scene == null:
		return
	cleanup_black_shadow()
	var shadow := NECROMANCER_SHADOW_SCRIPT.new() as Node2D
	var spawn_direction := Vector2.RIGHT.rotated(randf() * TAU)
	var spawn_position: Vector2 = player.global_position + spawn_direction * 600.0
	if shadow.has_method("setup"):
		shadow.call("setup", player, spawn_position)
	else:
		shadow.global_position = spawn_position
	black_shadow = shadow
	player.get_tree().current_scene.add_child(shadow)


func cleanup_black_shadow() -> void:
	if is_instance_valid(black_shadow):
		black_shadow.queue_free()
	black_shadow = null


func trigger_enemy_death_explosion(player, enemy: Node) -> void:
	var enemy_2d := enemy as Node2D
	if enemy_2d == null or player.get_tree() == null:
		return
	var origin := enemy_2d.global_position
	var damage: float = player.get_base_attack_damage() * DEATH_EXPLOSION_DAMAGE_MULTIPLIER
	if damage <= 0.0:
		return
	spawn_death_explosion_visual(player, origin)
	if player.global_position.distance_to(origin) <= DEATH_EXPLOSION_RADIUS:
		player.take_damage(damage)
	for target in player.get_tree().get_nodes_in_group("enemy"):
		if target == enemy:
			continue
		var target_2d := target as Node2D
		if target_2d == null or not is_instance_valid(target_2d):
			continue
		if target.get("is_dead") == true:
			continue
		if target_2d.global_position.distance_to(origin) > DEATH_EXPLOSION_RADIUS:
			continue
		if target.has_method("take_damage"):
			player.deal_player_damage_to_enemy(target, damage, {"source": "necromancer_death_explosion", "direct": false, "allow_procs": false})


func spawn_death_explosion_visual(player, origin: Vector2) -> void:
	var parent = player.get_tree().current_scene
	if parent == null:
		parent = player.get_parent()
	if parent == null:
		return
	var visual := Node2D.new()
	visual.name = "NecromancerDeathExplosion"
	visual.global_position = origin
	parent.add_child(visual)

	var sprite := AnimatedSprite2D.new()
	sprite.name = "DarkExplosion"
	sprite.sprite_frames = _make_death_explosion_frames()
	sprite.z_index = 180
	sprite.scale = Vector2.ONE * (DEATH_EXPLOSION_RADIUS * 2.0 / float(DEATH_EXPLOSION_FRAME_SIZE.x))
	visual.add_child(sprite)
	sprite.play(&"explode")
	sprite.animation_finished.connect(Callable(visual, "queue_free"))


func _make_death_explosion_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var animation_name := &"explode"
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, false)
	frames.set_animation_speed(animation_name, DEATH_EXPLOSION_ANIMATION_FPS)

	var texture := DEATH_EXPLOSION_TEXTURE
	if texture == null:
		return frames

	var columns := maxi(int(texture.get_width() / DEATH_EXPLOSION_FRAME_SIZE.x), 1)
	var rows := maxi(int(texture.get_height() / DEATH_EXPLOSION_FRAME_SIZE.y), 1)
	for row in range(rows):
		for column in range(columns):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(
				float(column * DEATH_EXPLOSION_FRAME_SIZE.x),
				float(row * DEATH_EXPLOSION_FRAME_SIZE.y),
				float(DEATH_EXPLOSION_FRAME_SIZE.x),
				float(DEATH_EXPLOSION_FRAME_SIZE.y)
			)
			frames.add_frame(animation_name, frame)
	return frames


func apply_kill_atk_gain(player) -> void:
	if player.stats == null:
		return
	kill_atk_damage_loss_bonus += 1
	player.stats.apply_modifier(&"atk", &"add", 1.0)


func apply_kill_atk_damage_loss(player) -> void:
	if not has_talent(&"necromancer_kill_atk_damage_loss") or player.stats == null:
		return
	var loss := mini(2, kill_atk_damage_loss_bonus)
	if loss <= 0:
		return
	kill_atk_damage_loss_bonus -= loss
	player.stats.apply_modifier(&"atk", &"add", -float(loss))


func cleanup_skeleton_archers(free_valid: bool) -> void:
	for index in range(skeleton_archers.size() - 1, -1, -1):
		var archer := skeleton_archers[index]
		if not is_instance_valid(archer):
			skeleton_archers.remove_at(index)
		elif free_valid:
			archer.queue_free()
			skeleton_archers.remove_at(index)


func remove_skeleton_archer(archer: Node, player = null) -> void:
	var index := skeleton_archers.find(archer)
	if index >= 0:
		skeleton_archers.remove_at(index)
		_apply_skeleton_archer_death_atk(player)


func expire_skeleton_archer(archer_id: int, player = null) -> void:
	var archer := instance_from_id(archer_id) as Node
	var index := skeleton_archers.find(archer)
	if index >= 0:
		skeleton_archers.remove_at(index)
		_apply_skeleton_archer_death_atk(player)
	if is_instance_valid(archer):
		if archer.has_method("play_death_and_free"):
			archer.call("play_death_and_free")
		else:
			archer.queue_free()
	cleanup_skeleton_archers(false)


func _apply_skeleton_archer_death_atk(player) -> void:
	if not has_talent(&"necromancer_skeleton_archer_death_round_atk"):
		return
	if player == null or player.temporary_buffs == null:
		return
	player.temporary_buffs.add_round_stat_buff(&"necromancer_skeleton_archer_death_round_atk", &"atk", 5.0, 999999)


func apply_slide_skeleton_archer_attack_speed() -> void:
	slide_skeleton_archer_attack_speed_remaining = SLIDE_SKELETON_ARCHER_ATTACK_SPEED_DURATION
	cleanup_skeleton_archers(false)
	for archer in skeleton_archers:
		if is_instance_valid(archer) and archer.has_method("apply_timed_attack_speed_multiplier"):
			archer.call("apply_timed_attack_speed_multiplier", SLIDE_SKELETON_ARCHER_ATTACK_SPEED_MULTIPLIER, SLIDE_SKELETON_ARCHER_ATTACK_SPEED_DURATION)


func update_slide_skeleton_archer_attack_speed(delta: float) -> void:
	if slide_skeleton_archer_attack_speed_remaining <= 0.0:
		return
	slide_skeleton_archer_attack_speed_remaining = maxf(0.0, slide_skeleton_archer_attack_speed_remaining - delta)


func update_round_movement_speed(player, delta: float) -> void:
	if not has_talent(&"necromancer_round_movement_speed_per_second") or not round_movement_speed_active:
		return
	if player.temporary_buffs == null:
		return
	round_movement_speed_timer += delta
	while round_movement_speed_timer >= 1.0:
		round_movement_speed_timer -= 1.0
		player.temporary_buffs.add_round_stat_buff(
			&"necromancer_round_movement_speed_per_second",
			&"movement_speed_bonus",
			ROUND_MOVE_SPEED_BONUS_PER_SECOND,
			999999
		)


func update_charged_primary_damage(delta: float) -> void:
	if not has_talent(&"necromancer_charged_primary_damage"):
		charged_primary_damage_timer = 0.0
		return
	charged_primary_damage_timer = minf(charged_primary_damage_timer + delta, 10.0)


func get_dash_duration_multiplier() -> float:
	return 1.3 if has_talent(&"necromancer_dash_duration_bonus") else 1.0


func consume_charged_primary_damage_multiplier() -> float:
	if not has_talent(&"necromancer_charged_primary_damage"):
		return 1.0
	var multiplier := 1.0 + minf(floorf(charged_primary_damage_timer) * 0.1, 1.0)
	charged_primary_damage_timer = 0.0
	return multiplier


func apply_laser_allied_effects(laser: HolyFlameLaser) -> void:
	if not has_talent(&"necromancer_soul_siphon_skeleton_archer_attack_speed"):
		return
	if laser == null or laser.attack_source != "necromancer_soul_beam":
		return
	cleanup_skeleton_archers(false)
	for archer in skeleton_archers:
		if not is_instance_valid(archer) or bool(archer.get("dying")):
			continue
		if not bool(laser.call("_is_position_in_beam", archer.global_position)):
			continue
		if archer.has_method("apply_timed_attack_speed_multiplier"):
			archer.call(
				"apply_timed_attack_speed_multiplier",
				SOUL_SIPHON_SKELETON_ARCHER_ATTACK_SPEED_MULTIPLIER,
				SOUL_SIPHON_SKELETON_ARCHER_ATTACK_SPEED_DURATION,
				true
			)


func handle_enemy_killed(player, enemy: Node) -> void:
	if has_talent(&"necromancer_skeleton_archer_kill_heal") and _was_killed_by_skeleton_archer(enemy):
		player.heal(player.max_hp * 0.1)
	if has_talent(&"necromancer_kill_heal_over_time"):
		_start_kill_heal_over_time(player)
	if has_talent(&"necromancer_kill_atk_damage_loss"):
		apply_kill_atk_gain(player)
	if has_talent(&"necromancer_enemy_death_explosion"):
		trigger_enemy_death_explosion(player, enemy)
	handle_enemy_kill_skeleton_archer(player, enemy)
	if has_talent(&"necromancer_xp_per_10_kills"):
		xp_kill_counter += 1
		while xp_kill_counter >= 10:
			xp_kill_counter -= 10
			player.gain_experience(1)
	if has_talent(&"necromancer_gold_per_10_kills"):
		gold_kill_counter += 1
		while gold_kill_counter >= 10:
			gold_kill_counter -= 10
			player.add_gold(1, "Bone Tithe")
	if has_talent(&"necromancer_defense_per_10_kills") and player.stats != null:
		defense_kill_counter += 1
		while defense_kill_counter >= 10:
			defense_kill_counter -= 10
			player.stats.apply_modifier(&"defense", &"add", 1.0)
	if has_talent(&"necromancer_atk_per_20_kills") and player.stats != null:
		atk_kill_counter += 1
		while atk_kill_counter >= 20:
			atk_kill_counter -= 20
			player.stats.apply_modifier(&"atk", &"add", 1.0)
	if has_talent(&"necromancer_max_hp_per_10_kills") and player.stats != null:
		max_hp_kill_counter += 1
		while max_hp_kill_counter >= 10:
			max_hp_kill_counter -= 10
			player.stats.apply_modifier(&"max_hp", &"add", 1.0)
	if has_talent(&"necromancer_skeleton_archer_damage_per_10_kills"):
		skeleton_archer_damage_kill_counter += 1
		while skeleton_archer_damage_kill_counter >= 10:
			skeleton_archer_damage_kill_counter -= 10
			_add_skeleton_archer_damage_kill_stack()
	if has_talent(&"necromancer_primary_damage_per_10_kills"):
		primary_damage_kill_counter += 1
		while primary_damage_kill_counter >= 10:
			primary_damage_kill_counter -= 10
			primary_damage_kill_stacks += 1


func handle_container_broken(player, container: Node, attack_info: Dictionary, chance_roll: float = -1.0) -> bool:
	if not has_talent(&"necromancer_container_break_skeleton_archer"):
		return false
	if container == null or not container is Node2D:
		return false
	if container is BreakableContainer and container.is_shop_container:
		return false
	if attack_info.has("owner") and attack_info.get("owner") != player:
		return false

	var roll: float = chance_roll if chance_roll >= 0.0 else randf()
	if roll >= 0.1:
		return false

	var previous_target: Vector2 = player.pending_shockwave_target_position
	player.pending_shockwave_target_position = (container as Node2D).global_position
	summon_skeleton_archer(player)
	player.pending_shockwave_target_position = previous_target
	return true


func handle_enemy_kill_skeleton_archer(player, enemy: Node, chance_roll: float = -1.0) -> bool:
	if not has_talent(&"necromancer_kill_skeleton_archer"):
		return false
	if enemy == null or not enemy is Node2D:
		return false

	var roll: float = chance_roll if chance_roll >= 0.0 else randf()
	if roll >= 0.1:
		return false

	var previous_target: Vector2 = player.pending_shockwave_target_position
	player.pending_shockwave_target_position = (enemy as Node2D).global_position
	summon_skeleton_archer(player)
	player.pending_shockwave_target_position = previous_target
	return true


func _start_kill_heal_over_time(player) -> void:
	var effect := HEALING_OVER_TIME_SCRIPT.new() as HealingOverTimeEffect
	effect.setup(player, player.max_hp * 0.05, 3.0)
	if player.get_tree() != null and player.get_tree().current_scene != null:
		player.get_tree().current_scene.add_child(effect)
	else:
		player.add_child(effect)


func _was_killed_by_skeleton_archer(enemy: Node) -> bool:
	if enemy == null:
		return false
	var attack_info: Variant = enemy.get("last_attack_info") if enemy is Object else null
	if not attack_info is Dictionary:
		return false
	return String(attack_info.get("source", "")) == "skeleton_archer"


func _add_skeleton_archer_damage_kill_stack() -> void:
	var previous_multiplier := get_skeleton_archer_damage_kill_multiplier()
	skeleton_archer_damage_kill_stacks += 1
	var next_multiplier := get_skeleton_archer_damage_kill_multiplier()
	var active_archer_ratio := next_multiplier / maxf(previous_multiplier, 0.001)
	cleanup_skeleton_archers(false)
	for archer in skeleton_archers:
		if is_instance_valid(archer):
			archer.damage_inherit_multiplier *= active_archer_ratio


func get_skeleton_archer_damage_kill_multiplier() -> float:
	return 1.0 + float(skeleton_archer_damage_kill_stacks) * 0.01


func get_primary_damage_kill_multiplier() -> float:
	return 1.0 + float(primary_damage_kill_stacks) * 0.01


func handle_attack_hit(player, enemy: Node, _attack_info: Dictionary) -> void:
	if _is_necromancer_left_click_attack(_attack_info):
		recently_primary_damaged_enemy = enemy
	if String(_attack_info.get("source", "")) == "skeleton_archer":
		recently_skeleton_damaged_enemy = enemy
	if not has_talent(&"necromancer_hit_move_speed_stack") or player.temporary_buffs == null:
		return
	if not bool(_attack_info.get("direct", true)):
		return

	hit_move_speed_buff_counter += 1
	var buff_id := StringName("necromancer_hit_move_speed_%s" % hit_move_speed_buff_counter)
	player.temporary_buffs.add_timed_stat_buff(buff_id, &"bonus_move_speed_flat", 5.0, 3.0, 1)


func get_skeleton_archer_target_damage_multiplier(target: Node) -> float:
	if not has_talent(&"necromancer_skeleton_archer_marked_target_damage"):
		return 1.0
	if target == null or not is_instance_valid(target):
		return 1.0
	if recently_primary_damaged_enemy == null or not is_instance_valid(recently_primary_damaged_enemy):
		return 1.0
	return 1.5 if target == recently_primary_damaged_enemy else 1.0


func get_player_damage_to_skeleton_marked_target_multiplier(target: Node, attack_info: Dictionary) -> float:
	if not has_talent(&"necromancer_primary_damage_to_skeleton_marked_target"):
		return 1.0
	if String(attack_info.get("source", "")) == "skeleton_archer":
		return 1.0
	if target == null or not is_instance_valid(target):
		return 1.0
	if recently_skeleton_damaged_enemy == null or not is_instance_valid(recently_skeleton_damaged_enemy):
		return 1.0
	return 1.3 if target == recently_skeleton_damaged_enemy else 1.0


func _is_necromancer_left_click_attack(attack_info: Dictionary) -> bool:
	if not bool(attack_info.get("direct", true)):
		return false
	var source := String(attack_info.get("source", ""))
	return source == "necromancer_soul_beam" or source == "necromancer_soul_orb"


func on_round_started(player) -> void:
	if has_talent(&"necromancer_black_shadow_pursuit"):
		spawn_black_shadow(player)
	if has_talent(&"necromancer_round_movement_speed_per_second"):
		round_movement_speed_active = true
		round_movement_speed_timer = 0.0


func on_round_ended() -> void:
	cleanup_black_shadow()
	round_movement_speed_active = false
	round_movement_speed_timer = 0.0


func on_slide_finished() -> void:
	if has_talent(&"necromancer_slide_soul_siphon_damage_bonus"):
		next_slide_soul_siphon_ready = true
	if has_talent(&"necromancer_slide_skeleton_archer_attack_speed"):
		apply_slide_skeleton_archer_attack_speed()


func get_soul_siphon_bleed_chance(attack_info: Dictionary = {}) -> float:
	if not has_talent(&"necromancer_soul_siphon_bleed_chance"):
		return 0.0
	if String(attack_info.get("source", "")) != "necromancer_soul_beam":
		return 0.0
	return 0.2


func get_bleeding_move_speed_multiplier() -> float:
	if has_talent(&"necromancer_bleeding_move_speed_slow"):
		return 0.8
	return 1.0


func get_poison_stack_damage_multiplier(player, enemy: Node, attack_info: Dictionary) -> float:
	if not has_talent(&"necromancer_poison_stack_damage"):
		return 1.0
	var poison_stacks: int = player.call("_get_enemy_poison_stacks", enemy)
	if poison_stacks <= 0:
		return 1.0
	attack_info["necromancer_poison_stack_damage_bonus"] = poison_stacks
	return 1.0 + 0.05 * float(poison_stacks)


func start_soul_surge(player) -> void:
	if player.fire_surge_remaining > 0.0 or player.fire_surge_cooldown_pending:
		return
	player.fire_surge_remaining = 6.0
	player.fire_surge_fire_remaining = 0.0
	player.fire_surge_cooldown_pending = true
	if player.temporary_buffs != null:
		player.temporary_buffs.add_timed_stat_buff(&"necromancer_soul_surge_attack_speed", &"attack_speed_bonus", 0.35, player.fire_surge_remaining, 1)
		player.temporary_buffs.add_timed_stat_buff(&"necromancer_soul_surge_move_speed", &"movement_speed_bonus", 0.2, player.fire_surge_remaining, 1)


func _direction_to(player, target_position: Vector2) -> Vector2:
	var direction: Vector2 = target_position - player.global_position
	if direction.length_squared() <= 0.001:
		direction = player.facing_direction
	else:
		direction = direction.normalized()
	return direction
