extends Node
class_name ItemRuntimeEffectNode

const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")
const EXPLOSIVE_TRAP_SCRIPT := preload("res://systems/combat/ExplosiveTrap.gd")
const BLOOD_CLAW_SCRIPT := preload("res://systems/combat/BloodClawStrike.gd")
const BLOOD_BLADE_SCRIPT := preload("res://systems/combat/BloodBladeProjectile.gd")
const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")
const HOLY_FLAME_LASER_SCRIPT := preload("res://systems/combat/HolyFlameLaser.gd")
const LIGHTNING_CHAIN_TEXTURE_PATH := "res://assets/vfx/lightning spell/lightning chain 256x256.png"
const LIGHTNING_CHAIN_FRAME_SIZE := Vector2(256.0, 256.0)
const LIGHTNING_CHAIN_SFX_PATH := "res://assets/sfx/dragon-studio-lightning-spell-386163.mp3"
const PHOENIX_TEXTURE_PATH := "res://assets/vfx/fire spell/phoenix.png"
const PHOENIX_FRAME_SIZE := Vector2(256.0, 128.0)
const BATTLE_PULSE_TEXTURE_PATH := "res://assets/vfx/blood spell/blood face.png"
const BATTLE_PULSE_FRAME_SIZE := Vector2(64.0, 64.0)
const BATTLE_PULSE_VFX_DEDUPE_MS := 250
const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")

var owner_player: Node
var item_id: StringName
var effect_type: StringName
var stat_name: StringName
var value: float = 0.0
var duration: float = 0.0
var max_stacks: int = 1
var radius: float = 0.0
var chance: float = 0.0
var damage_scale: float = 0.0
var internal_cooldown: float = 0.0

var applied_bonus: float = 0.0
var stationary_time: float = 0.0
var linger_remaining: float = 0.0
var permanent_round_triggers: int = 0
var last_position: Vector2 = Vector2.ZERO
var periodic_remaining: float = 0.0
var active_trap: Node
var damage_shield_waiting_for_break: bool = false
var lightning_chain_texture: Texture2D
var lightning_chain_sfx: AudioStream
var phoenix_texture: Texture2D
var battle_pulse_texture: Texture2D


func setup(
	new_owner: Node,
	new_item_id: StringName,
	new_effect_type: StringName,
	new_stat_name: StringName,
	new_value: float,
	new_duration: float,
	new_max_stacks: int,
	new_radius: float,
	new_chance: float,
	new_damage_scale: float,
	new_internal_cooldown: float
) -> void:
	owner_player = new_owner
	item_id = new_item_id
	effect_type = new_effect_type
	stat_name = new_stat_name
	value = new_value
	duration = new_duration
	max_stacks = new_max_stacks
	radius = new_radius
	chance = new_chance
	damage_scale = new_damage_scale
	internal_cooldown = new_internal_cooldown
	periodic_remaining = internal_cooldown

	var owner_2d := owner_player as Node2D
	if owner_2d != null:
		last_position = owner_2d.global_position
	if effect_type == &"permanent_stat_stationary_round_cap":
		_connect_round_started()


func _process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return

	match effect_type:
		&"nearby_enemy_attack_speed":
			_update_surrounded_stat_bonus()
		&"surrounded_stat_bonus":
			_update_surrounded_stat_bonus()
		&"stationary_attack_speed":
			_update_stationary_attack_speed(delta)
		&"permanent_stat_stationary_round_cap":
			_update_permanent_stationary_stat(delta)
		&"periodic_timed_stat_buff":
			_update_periodic_timed_stat_buff(delta)
		&"auto_holy_flame_laser":
			_update_auto_holy_flame_laser(delta)
		&"periodic_auto_fireball":
			_update_periodic_auto_fireball(delta)
		&"periodic_chain_lightning":
			_update_periodic_chain_lightning(delta)
		&"periodic_blood_claw":
			_update_periodic_blood_claw(delta)
		&"periodic_blood_blade":
			_update_periodic_blood_blade(delta)
		&"periodic_explosive_trap":
			_update_periodic_explosive_trap(delta)
		&"periodic_invincibility":
			_update_periodic_invincibility(delta)
		&"periodic_damage_shield":
			_update_periodic_damage_shield(delta)


func _update_surrounded_stat_bonus() -> void:
	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var surrounding_enemy_count: int = EFFECT_TARGETING.enemies_surrounding(owner_player, owner_2d.global_position).size()
	surrounding_enemy_count += _get_surrounded_enemy_count_bonus()

	var item_count: int = _get_item_count()
	if stat_name == &"dodge_chance_multiplier" and value < 0.0:
		var dodge_chance_per_layer: float = absf(value) + damage_scale * float(maxi(item_count - 1, 0))
		var max_layers: int = maxi(int(round(duration)) + maxi(item_count - 1, 0) * maxi(max_stacks, 0), 0)
		var layers: int = mini(surrounding_enemy_count, max_layers)
		_set_dynamic_bonus(pow(1.0 - dodge_chance_per_layer, float(layers)) - 1.0)
		return

	var per_enemy_bonus: float = value + damage_scale * float(maxi(item_count - 1, 0))
	var cap: float = duration * (1.0 + 0.5 * float(maxi(item_count - 1, 0)))
	var wanted_bonus: float = float(surrounding_enemy_count) * per_enemy_bonus
	if wanted_bonus >= 0.0:
		wanted_bonus = minf(wanted_bonus, cap)
	else:
		wanted_bonus = maxf(wanted_bonus, -cap)
	_set_dynamic_bonus(wanted_bonus)


func _update_stationary_attack_speed(delta: float) -> void:
	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var moved: bool = owner_2d.global_position.distance_squared_to(last_position) > 1.0
	last_position = owner_2d.global_position
	if moved:
		if stationary_time >= duration:
			linger_remaining = radius
		stationary_time = 0.0
	else:
		stationary_time += delta

	linger_remaining = maxf(0.0, linger_remaining - delta)
	var active: bool = stationary_time >= duration or linger_remaining > 0.0
	var wanted_bonus: float = 0.0
	if active:
		wanted_bonus = value * float(_get_item_count())
	_set_dynamic_bonus(wanted_bonus)


func _update_permanent_stationary_stat(delta: float) -> void:
	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var moved: bool = owner_2d.global_position.distance_squared_to(last_position) > 1.0
	last_position = owner_2d.global_position
	if moved:
		stationary_time = 0.0
		return

	stationary_time += delta
	while stationary_time >= duration and permanent_round_triggers < _get_permanent_round_cap():
		stationary_time -= duration
		permanent_round_triggers += 1
		_apply_permanent_stat(value)


func _connect_round_started() -> void:
	if owner_player == null or not owner_player.has_signal(&"round_started"):
		return
	var callable := Callable(self, "_on_round_started")
	if not owner_player.is_connected(&"round_started", callable):
		owner_player.connect(&"round_started", callable)


func _on_round_started(_round_index: int = 0) -> void:
	permanent_round_triggers = 0
	stationary_time = 0.0


func _get_permanent_round_cap() -> int:
	return maxi(max_stacks + maxi(_get_item_count() - 1, 0) * int(round(damage_scale)), 1)


func _apply_permanent_stat(amount: float) -> void:
	if owner_player == null or not owner_player.has_method("get_stats"):
		return

	var stats: StatsComponent = owner_player.get_stats()
	if stats != null:
		stats.apply_modifier(stat_name, &"add", _get_permanent_growth_amount(amount))


func _get_permanent_growth_amount(amount: float) -> float:
	if owner_player == null or not owner_player.has_method("get_stats"):
		return amount
	var stats := owner_player.get_stats() as StatsComponent
	if stats == null or stats.permanent_growth_bonus_per_unique <= 0.0:
		return amount
	var unique_count := 0
	if owner_player.has_method("get_unique_permanent_growth_item_count"):
		unique_count = int(owner_player.get_unique_permanent_growth_item_count())
	if unique_count <= 0:
		return amount

	var multiplier := 1.0 + stats.permanent_growth_bonus_per_unique * float(unique_count)
	if absf(amount) < 1.0:
		return floorf(amount * multiplier * 100.0) / 100.0
	return floorf(amount * multiplier)


func _update_periodic_timed_stat_buff(delta: float) -> void:
	if internal_cooldown <= 0.0:
		return

	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	periodic_remaining += internal_cooldown
	var buffs: TemporaryBuffComponent = null
	if owner_player.has_method("get_temporary_buffs"):
		buffs = owner_player.get_temporary_buffs()
	if buffs != null:
		buffs.add_timed_stat_buff(StringName("%s_%s_%s" % [item_id, stat_name, get_instance_id()]), stat_name, value, duration, max_stacks)
		if item_id == &"battle_pulse" and stat_name == &"attack_speed_bonus":
			var owner_2d := owner_player as Node2D
			if owner_2d != null and _claim_battle_pulse_vfx_spawn():
				_spawn_battle_pulse_vfx(owner_2d.global_position)


func _update_auto_holy_flame_laser(delta: float) -> void:
	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var target := _get_nearest_enemy(owner_2d.global_position, radius)
	if target == null:
		return

	_launch_holy_flame_laser(owner_2d.global_position, target.global_position)
	periodic_remaining = internal_cooldown


func _launch_holy_flame_laser(start_position: Vector2, target_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var direction := target_position - start_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var base_damage: float = owner_player.get_base_attack_damage() if owner_player.has_method("get_base_attack_damage") else 0.0
	var damage_multiplier: float = value + damage_scale * float(maxi(_get_item_count() - 1, 0))
	var laser := HOLY_FLAME_LASER_SCRIPT.new() as HolyFlameLaser
	laser.setup(owner_player, start_position, direction, base_damage * damage_multiplier, "holy_flame_laser", true)
	laser.collision_layer = 0
	laser.collision_mask = 0
	laser.set_collision_mask_value(2, true)
	laser.set_collision_mask_value(6, true)
	owner_player.get_tree().current_scene.add_child(laser)


func _update_periodic_auto_fireball(delta: float) -> void:
	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var target := _get_nearest_enemy(owner_2d.global_position, radius)
	if target == null:
		return

	_launch_auto_fireball(owner_2d.global_position, target.global_position, value + damage_scale * float(maxi(_get_item_count() - 1, 0)))
	periodic_remaining = internal_cooldown


func _update_periodic_chain_lightning(delta: float) -> void:
	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return
	if _get_nearest_enemy(owner_2d.global_position, radius) == null:
		return

	_trigger_auto_chain_lightning(owner_2d.global_position, value + damage_scale * float(maxi(_get_item_count() - 1, 0)))
	periodic_remaining = internal_cooldown


func _update_periodic_blood_claw(delta: float) -> void:
	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var target := _get_nearest_enemy(owner_2d.global_position, radius)
	if target == null:
		return

	_launch_blood_claw(owner_2d.global_position, target.global_position)
	periodic_remaining = internal_cooldown


func _update_periodic_blood_blade(delta: float) -> void:
	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return
	if _get_nearest_enemy(owner_2d.global_position, radius) == null:
		return

	_release_blood_blade_sequence()
	periodic_remaining = internal_cooldown


func _update_periodic_explosive_trap(delta: float) -> void:
	if is_instance_valid(active_trap):
		return

	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	_place_explosive_trap(owner_2d.global_position, value + damage_scale * float(maxi(_get_item_count() - 1, 0)))
	periodic_remaining = internal_cooldown


func _update_periodic_invincibility(delta: float) -> void:
	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	if owner_player.has_method("grant_timed_invincibility"):
		var invincibility_duration := minf(value + damage_scale * float(maxi(_get_item_count() - 1, 0)), duration)
		owner_player.call("grant_timed_invincibility", invincibility_duration)
		var owner_2d := owner_player as Node2D
		if owner_2d != null:
			_spawn_phoenix_vfx(owner_2d.global_position)
	periodic_remaining = internal_cooldown


func _update_periodic_damage_shield(delta: float) -> void:
	if owner_player.has_method("has_damage_shield") and owner_player.has_method("grant_damage_shield"):
		if bool(owner_player.call("has_damage_shield")):
			damage_shield_waiting_for_break = true
			return
		if damage_shield_waiting_for_break:
			damage_shield_waiting_for_break = false
			periodic_remaining = _get_damage_shield_cooldown()

	periodic_remaining -= delta
	if periodic_remaining > 0.0:
		return

	if owner_player.has_method("grant_damage_shield"):
		owner_player.call("grant_damage_shield")
		damage_shield_waiting_for_break = true


func _launch_auto_fireball(start_position: Vector2, target_position: Vector2, damage_multiplier: float) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var direction := target_position - start_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var fireball := Area2D.new()
	fireball.set_script(FIREBALL_SCRIPT)
	fireball.setup(owner_player, start_position, direction, _get_base_attack_damage() * damage_multiplier, 80.0)
	fireball.collision_layer = 1 << 2
	fireball.collision_mask = 1 << 1
	owner_player.get_tree().current_scene.add_child(fireball)


func _trigger_auto_chain_lightning(origin: Vector2, damage_multiplier: float) -> void:
	var damage := _get_base_attack_damage() * damage_multiplier
	var current_position := origin
	var hit: Array = []
	var did_hit := false
	var chain_total := maxi(max_stacks, 1)

	for index in range(chain_total):
		var target := _get_nearest_enemy(current_position, radius, hit)
		if target == null:
			break

		var previous_position := current_position
		hit.append(target)
		current_position = target.global_position
		_spawn_chain_lightning_vfx(previous_position, current_position)
		did_hit = true
		if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
			owner_player.deal_player_damage_to_enemy(target, damage, {"source": "periodic_chain_lightning", "direct": true, "allow_procs": false})
		elif target.has_method("take_damage"):
			target.take_damage(damage)

	if did_hit:
		_play_chain_lightning_sfx(origin)


func _launch_blood_claw(start_position: Vector2, target_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var item_count: int = _get_item_count()
	var damage_multiplier := value + damage_scale * float(maxi(item_count - 1, 0))
	var heal_multiplier := duration + chance * float(maxi(item_count - 1, 0))
	var claw := BLOOD_CLAW_SCRIPT.new() as BloodClawStrike
	claw.setup(owner_player, target_position, target_position - start_position, _get_base_attack_damage() * damage_multiplier, _get_base_attack_damage() * heal_multiplier)
	claw.collision_layer = 0
	claw.collision_mask = 0
	claw.set_collision_mask_value(2, true)
	owner_player.get_tree().current_scene.add_child(claw)


func _release_blood_blade_sequence() -> void:
	var blade_count := maxi(_get_item_count(), 1)
	for index in range(blade_count):
		if index > 0:
			await owner_player.get_tree().create_timer(chance).timeout
		if owner_player == null or not is_instance_valid(owner_player):
			return
		var owner_2d := owner_player as Node2D
		if owner_2d == null:
			return
		var target := _get_nearest_enemy(owner_2d.global_position, radius)
		if target == null:
			continue
		_launch_blood_blade(owner_2d.global_position, target.global_position)


func _launch_blood_blade(start_position: Vector2, target_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var direction := target_position - start_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var blade := BLOOD_BLADE_SCRIPT.new() as BloodBladeProjectile
	blade.setup(owner_player, start_position, direction, _get_base_attack_damage() * value, damage_scale, duration)
	blade.collision_layer = 0
	blade.collision_mask = 0
	blade.set_collision_mask_value(2, true)
	owner_player.get_tree().current_scene.add_child(blade)


func _place_explosive_trap(spawn_position: Vector2, damage_multiplier: float) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var trap := EXPLOSIVE_TRAP_SCRIPT.new() as ExplosiveTrap
	trap.setup(owner_player, spawn_position, _get_base_attack_damage() * damage_multiplier, radius, radius)
	owner_player.get_tree().current_scene.add_child(trap)
	active_trap = trap


func _get_damage_shield_cooldown() -> float:
	var stacks := maxi(_get_item_count(), 1)
	return 8.0 + 12.0 / (1.0 + 0.35 * float(stacks - 1))


func _get_base_attack_damage() -> float:
	if owner_player != null and owner_player.has_method("get_base_attack_damage"):
		return owner_player.get_base_attack_damage()
	return 0.0


func _get_nearest_enemy(origin: Vector2, search_radius: float, exclude: Array = []) -> Node2D:
	return EFFECT_TARGETING.nearest_enemy(owner_player, origin, search_radius, exclude)


func _spawn_chain_lightning_vfx(start_position: Vector2, end_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return
	var texture := _get_lightning_chain_texture()
	if texture == null:
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
	effect.name = "PeriodicChainLightningVFX"
	effect.sprite_frames = sprite_frames
	effect.centered = true
	effect.rotation = offset.angle()
	effect.scale = Vector2(length / LIGHTNING_CHAIN_FRAME_SIZE.x, 1.0)
	effect.z_index = 140
	owner_player.get_tree().current_scene.add_child(effect)
	effect.global_position = (start_position + end_position) * 0.5
	effect.play(animation_name)
	effect.animation_finished.connect(Callable(effect, "queue_free"))


func _get_lightning_chain_texture() -> Texture2D:
	if lightning_chain_texture != null:
		return lightning_chain_texture

	var image := Image.load_from_file(LIGHTNING_CHAIN_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load chain lightning texture: %s" % LIGHTNING_CHAIN_TEXTURE_PATH)
		return null

	lightning_chain_texture = ImageTexture.create_from_image(image)
	return lightning_chain_texture


func _play_chain_lightning_sfx(position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return
	var stream := _get_lightning_chain_sfx()
	if stream != null:
		SFX_PLAYER.play_2d(owner_player.get_tree().current_scene, stream, position, -2.0, 0.95, 1.08)


func _get_lightning_chain_sfx() -> AudioStream:
	if lightning_chain_sfx != null:
		return lightning_chain_sfx

	var stream := AudioStreamMP3.load_from_file(LIGHTNING_CHAIN_SFX_PATH)
	if stream == null:
		push_warning("Failed to load chain lightning sfx: %s" % LIGHTNING_CHAIN_SFX_PATH)
		return null

	lightning_chain_sfx = stream
	return lightning_chain_sfx


func _spawn_phoenix_vfx(spawn_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return
	var texture := _get_phoenix_texture()
	if texture == null:
		return

	var sprite_frames := SpriteFrames.new()
	var animation_name := &"rise"
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, 12.0)

	var frame_count := int(texture.get_width() / PHOENIX_FRAME_SIZE.x)
	for frame_index in range(frame_count):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(float(frame_index) * PHOENIX_FRAME_SIZE.x, 0.0, PHOENIX_FRAME_SIZE.x, PHOENIX_FRAME_SIZE.y)
		sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.name = "PhaseAegisPhoenixVFX"
	effect.sprite_frames = sprite_frames
	effect.centered = true
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.z_index = 135
	owner_player.get_tree().current_scene.add_child(effect)
	effect.global_position = spawn_position
	effect.play(animation_name)
	effect.animation_finished.connect(Callable(effect, "queue_free"))


func _get_phoenix_texture() -> Texture2D:
	if phoenix_texture != null:
		return phoenix_texture

	var image := Image.load_from_file(PHOENIX_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load phoenix texture: %s" % PHOENIX_TEXTURE_PATH)
		return null

	phoenix_texture = ImageTexture.create_from_image(image)
	return phoenix_texture


func _spawn_battle_pulse_vfx(spawn_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return
	var texture := _get_battle_pulse_texture()
	if texture == null:
		return

	var sprite_frames := SpriteFrames.new()
	var animation_name := &"pulse"
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, 14.0)

	var frame_count := int(texture.get_width() / BATTLE_PULSE_FRAME_SIZE.x)
	for frame_index in range(frame_count):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(float(frame_index) * BATTLE_PULSE_FRAME_SIZE.x, 0.0, BATTLE_PULSE_FRAME_SIZE.x, BATTLE_PULSE_FRAME_SIZE.y)
		sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.name = "BattlePulseVFX"
	effect.sprite_frames = sprite_frames
	effect.centered = true
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.z_index = 135
	owner_player.get_tree().current_scene.add_child(effect)
	effect.global_position = spawn_position
	effect.play(animation_name)
	effect.animation_finished.connect(Callable(effect, "queue_free"))


func _claim_battle_pulse_vfx_spawn() -> bool:
	if owner_player == null:
		return false

	var now := Time.get_ticks_msec()
	var meta_key := &"last_battle_pulse_vfx_msec"
	var last_spawn := int(owner_player.get_meta(meta_key, -BATTLE_PULSE_VFX_DEDUPE_MS))
	if now - last_spawn < BATTLE_PULSE_VFX_DEDUPE_MS:
		return false

	owner_player.set_meta(meta_key, now)
	return true


func _get_battle_pulse_texture() -> Texture2D:
	if battle_pulse_texture != null:
		return battle_pulse_texture

	var image := Image.load_from_file(BATTLE_PULSE_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load battle pulse texture: %s" % BATTLE_PULSE_TEXTURE_PATH)
		return null

	battle_pulse_texture = ImageTexture.create_from_image(image)
	return battle_pulse_texture


func _set_dynamic_bonus(wanted_bonus: float) -> void:
	if is_equal_approx(wanted_bonus, applied_bonus):
		return

	var buffs: TemporaryBuffComponent = null
	if owner_player.has_method("get_temporary_buffs"):
		buffs = owner_player.get_temporary_buffs()
	if buffs != null:
		buffs.set_dynamic_stat_bonus(StringName("%s_%s_%s" % [item_id, effect_type, stat_name]), stat_name, wanted_bonus)
	applied_bonus = wanted_bonus


func _get_item_count() -> int:
	if owner_player != null and owner_player.has_method("get_item_count"):
		return maxi(int(owner_player.get_item_count(item_id)), 1)
	return 1


func _get_surrounded_enemy_count_bonus() -> int:
	if owner_player == null or not owner_player.has_method("get_stats"):
		return 0

	var stats: StatsComponent = owner_player.get_stats()
	if stats == null:
		return 0
	return maxi(stats.surrounded_enemy_count_bonus, 0)
