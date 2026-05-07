extends ItemEffect
class_name EventEffect

const EFFECT_TARGETING := preload("res://systems/items/effects/EffectTargeting.gd")
const EFFECT_TYPES := preload("res://systems/items/effects/ItemEffectTypes.gd")
const FIREBALL_SCRIPT := preload("res://systems/combat/FireballProjectile.gd")
const FIRE_DRAGON_SCENE := preload("res://scenes/summons/FireDragon.tscn")
const HEALING_OVER_TIME_SCRIPT := preload("res://systems/combat/HealingOverTimeEffect.gd")
const LIGHTNING_CHAIN_TEXTURE_PATH := "res://assets/vfx/lightning spell/lightning chain 256x256.png"
const LIGHTNING_CHAIN_FRAME_SIZE := Vector2(256.0, 256.0)
const LIGHTNING_CHAIN_SFX_PATH := "res://assets/sfx/dragon-studio-lightning-spell-386163.mp3"
const SFX_PLAYER := preload("res://systems/audio/SfxPlayer.gd")
const SMALL_TURRET_SCENE := preload("res://scenes/summons/SmallTurret.tscn")

@export var event_name: StringName
@export var effect_type: StringName
@export var stat_name: StringName
@export var value: float = 0.0
@export var duration: float = 0.0
@export var max_stacks: int = 1
@export var radius: float = 0.0
@export var chance: float = 1.0
@export var damage_scale: float = 1.0
@export var chain_count: int = 0
@export var internal_cooldown: float = 0.0
@export var status_id: StringName
@export var poison_stacks: int = 0
@export var choices: Array[StringName] = []
@export var only_direct_container_breaks: bool = true
@export var lightning_vfx_lifetime: float = 0.12
@export var lightning_vfx_width: float = 7.0
@export var lightning_vfx_color: Color = Color(0.45, 0.85, 1.0, 0.95)
@export var lightning_vfx_animation_fps: float = 20.0
@export var lightning_vfx_height_scale: float = 2.0
@export var lightning_sfx_volume_db: float = -2.0
@export var container_proc_delay: float = 0.12
@export var duplicate_projectile_spread_degrees: float = 8.0
@export var dash_fireball_auto_aim_radius: float = 600.0

var owner_player: Node
var cooldown_remaining: float = 0.0
var item_id: StringName
var item_effect_index: int = 0
var item_stack_index: int = 0
var runtime_trigger_count: int = 0
var kill_counter: int = 0
var fireburst_deferred: bool = false
var fire_dragons: Array[Node] = []
var accumulated_hp_loss: float = 0.0
var lightning_chain_texture: Texture2D
var lightning_chain_sfx: AudioStream


func configure_instance(new_item_id: StringName, new_effect_index: int, new_stack_index: int) -> void:
	item_id = new_item_id
	item_effect_index = new_effect_index
	item_stack_index = new_stack_index


func apply_to(player: Node) -> void:
	owner_player = player
	if _is_pickup_effect():
		_apply_pickup_effect()
		return
	if _uses_shared_stack_listener() and item_stack_index > 0:
		return
	if not player.has_signal(event_name):
		push_warning("Player signal missing: %s" % event_name)
		return

	var callable := Callable(self, "_on_player_event")
	if not player.is_connected(event_name, callable):
		player.connect(event_name, callable)
	if effect_type == &"fire_dragons_per_max_hp":
		_sync_fire_dragons(_get_owner_max_hp())


func on_item_count_changed(changed_item_id: StringName) -> void:
	if changed_item_id != item_id:
		return
	if effect_type == &"fire_dragons_per_max_hp" and item_stack_index == 0:
		_sync_fire_dragons(_get_owner_max_hp())


func _on_player_event(arg1: Variant = null, arg2: Variant = null, arg3: Variant = null) -> void:
	if owner_player == null:
		return
	if cooldown_remaining > 0.0:
		return
	if randf() > _get_effective_chance():
		return

	if internal_cooldown > 0.0:
		cooldown_remaining = internal_cooldown
		_start_cooldown_timer()

	match effect_type:
		&"apply_poison_near_container":
			_apply_poison_near_position(_extract_position(arg1), 1)
		&"spread_bleeding_on_death":
			_spread_bleeding_on_death(arg1)
		&"chain_lightning":
			_trigger_chain_lightning(_get_effect_origin(arg1), _get_initial_chain_excludes(arg1))
		&"fireball":
			_launch_fireball_from_event(arg1, arg2)
		&"lifesteal":
			_apply_lifesteal(float(arg2))
		&"chain_lightning_on_bleeding_death":
			_chain_lightning_on_bleeding_death(arg1)
		&"poison_transfer_on_death":
			_poison_transfer_on_death(arg1)
		&"fireball_on_dash":
			_fireball_on_dash(arg1)
		&"container_break_random_proc":
			_container_break_random_proc(arg1, arg2)
		&"refund_gold_on_shop_container_break":
			_refund_gold_on_shop_container_break(arg2)
		&"summon_turret_on_level_up":
			_summon_turrets(1)
		&"heal_over_time_after_damage_taken":
			_heal_over_time_after_damage_taken(float(arg1))
		&"fireballs_every_n_kills":
			_fireballs_every_n_kills()
		&"fireball_sequence_on_kill":
			_fireball_sequence_on_kill()
		&"fireball_sequence_on_poisoned_death":
			_fireball_sequence_on_poisoned_death(arg1)
		&"summon_turrets_on_round_start":
			_summon_turrets(maxi(chain_count, 1))
		&"lose_current_hp_percent_then_heal_over_time":
			_lose_current_hp_percent_then_heal_over_time()
		&"fire_dragons_per_max_hp":
			_sync_fire_dragons(int(arg2))
		&"gold_every_hp_lost":
			_gold_every_hp_lost(float(arg1))
		&"direct_container_break_exp":
			_direct_container_break_exp(arg2)
		&"direct_container_break_gold":
			_direct_container_break_gold(arg2)
		&"chance_heal_on_kill":
			_chance_heal_on_kill()
		&"shop_price_multiplier":
			_apply_shop_price_multiplier()
		&"queue_extra_rare_shop_jar":
			_queue_extra_rare_shop_jar()
		&"next_attack_damage_after_kill":
			_next_attack_damage_after_kill()


func _start_cooldown_timer() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.create_timer(internal_cooldown).timeout.connect(_clear_cooldown)


func _clear_cooldown() -> void:
	cooldown_remaining = 0.0


func _is_pickup_effect() -> bool:
	if stacking_rule == &"pickup_once":
		return true
	if effect_type == EFFECT_TYPES.SHOP_PRICE_MULTIPLIER:
		return true
	if effect_type == EFFECT_TYPES.QUEUE_EXTRA_RARE_SHOP_JAR:
		return true
	return effect_type == EFFECT_TYPES.FIRST_COPY_STAT_BONUS


func _apply_pickup_effect() -> void:
	match effect_type:
		&"shop_price_multiplier":
			_apply_shop_price_multiplier()
		&"queue_extra_rare_shop_jar":
			_queue_extra_rare_shop_jar()
		&"first_copy_stat_bonus":
			_apply_first_copy_stat_bonus()


func _apply_first_copy_stat_bonus() -> void:
	if owner_player == null or not owner_player.has_method("get_stats"):
		return

	var stats: StatsComponent = owner_player.get_stats()
	if stats == null:
		return

	var bonus: float = value if item_stack_index == 0 else damage_scale
	stats.apply_modifier(stat_name, &"add", bonus)


func _apply_lifesteal(damage_dealt: float) -> void:
	if damage_dealt <= 0.0 or not owner_player.has_method("heal"):
		return
	var stats: StatsComponent = owner_player.get_stats()
	if stats == null or stats.lifesteal <= 0.0:
		return
	var heal_amount: float = damage_dealt * stats.lifesteal
	owner_player.heal(heal_amount)
	print("Lifesteal heals %s" % heal_amount)


func _spread_bleeding_on_death(enemy: Variant) -> void:
	if not _enemy_has_status(enemy, &"bleeding"):
		return
	for target in _get_enemies_near(_extract_position(enemy), radius, [enemy]):
		if target.has_method("apply_status_effect"):
			target.apply_status_effect(&"bleeding", owner_player)
	print("Open Wound spread bleeding")


func _chain_lightning_on_bleeding_death(enemy: Variant) -> void:
	if not _enemy_has_status(enemy, &"bleeding"):
		return

	var origin := _extract_position(enemy)
	var trigger_count := 1
	if stacking_rule == &"shared_sequence_scaled":
		trigger_count = maxi(max_stacks, 1) + maxi(_get_item_count() - 1, 0)

	for index in range(trigger_count):
		if index > 0:
			await owner_player.get_tree().create_timer(maxf(chance, 0.0)).timeout
		if owner_player == null or not is_instance_valid(owner_player):
			return

		var excludes := []
		if enemy is Object and is_instance_valid(enemy):
			excludes.append(enemy)
		if _trigger_chain_lightning(origin, excludes):
			print("Bloodbolt Covenant triggers")


func _poison_transfer_on_death(enemy: Variant) -> void:
	var stacks: int = 0
	if enemy != null and enemy.has_method("get_poison_stacks"):
		stacks = enemy.get_poison_stacks()
	if stacks <= 0:
		return

	var origin := _extract_position(enemy)
	var exclude := [enemy]
	var transfer_count := maxi(max_stacks, 1)
	if stacking_rule == &"shared_poison_transfer_scaled":
		transfer_count += maxi(_get_item_count() - 1, 0)

	var did_transfer := false
	for index in range(transfer_count):
		var target := _get_nearest_enemy(origin, radius, exclude)
		if target == null:
			break

		exclude.append(target)
		if target.has_method("apply_poison_stacks"):
			target.apply_poison_stacks(stacks, owner_player)
			did_transfer = true

	if did_transfer:
		print("Last Venom transfers poison stacks=%d targets=%d" % [stacks, exclude.size() - 1])


func _fireball_on_dash(direction_value: Variant) -> void:
	var direction := direction_value as Vector2
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT

	var start_position: Vector2 = _get_player_position()
	var target := _get_nearest_enemy(start_position, dash_fireball_auto_aim_radius)
	if target != null:
		direction = target.global_position - start_position

	direction = direction.normalized().rotated(deg_to_rad(_get_duplicate_spread_angle()))
	_launch_fireball(start_position, start_position + direction * 240.0)
	print("Blazing Dash launches fireball")


func _container_break_random_proc(container: Variant, info_value: Variant) -> void:
	var info: Dictionary = info_value if info_value is Dictionary else {}
	if only_direct_container_breaks and String(info.get("source", "")) != "player_attack":
		return
	if choices.is_empty():
		return

	var origin: Vector2 = _extract_position(container)
	_run_container_break_random_proc_after_delay(origin)


func _run_container_break_random_proc_after_delay(origin: Vector2) -> void:
	if container_proc_delay > 0.0:
		await owner_player.get_tree().create_timer(container_proc_delay).timeout
	if owner_player == null or not is_instance_valid(owner_player):
		return

	var choice: StringName = choices.pick_random()
	var triggered: bool = false
	match choice:
		&"chain_lightning":
			triggered = _trigger_chain_lightning(origin, [])
		&"fireball":
			var nearest := _get_nearest_enemy(origin, radius)
			if nearest != null:
				_launch_fireball(origin, nearest.global_position)
				triggered = true

	if triggered:
		print("Chaos Hatch triggers %s" % choice)
	else:
		print("Chaos Hatch found no target for %s" % choice)


func _is_direct_player_container_break(info: Dictionary) -> bool:
	return String(info.get("source", "")) == "player_attack"


func _direct_container_break_exp(info_value: Variant) -> void:
	var info: Dictionary = info_value if info_value is Dictionary else {}
	if not _is_direct_player_container_break(info) or owner_player == null or not owner_player.has_method("gain_experience"):
		return
	owner_player.gain_experience(int(value))


func _direct_container_break_gold(info_value: Variant) -> void:
	var info: Dictionary = info_value if info_value is Dictionary else {}
	if not _is_direct_player_container_break(info) or owner_player == null or not owner_player.has_method("add_gold"):
		return
	owner_player.add_gold(int(value), "Jar Dividend")


func _chance_heal_on_kill() -> void:
	if owner_player != null and owner_player.has_method("heal"):
		owner_player.heal(value)


func _next_attack_damage_after_kill() -> void:
	if owner_player != null and owner_player.has_method("add_next_attack_damage_bonus"):
		owner_player.add_next_attack_damage_bonus(value)


func _apply_shop_price_multiplier() -> void:
	if owner_player != null and owner_player.has_method("add_shop_price_multiplier"):
		owner_player.add_shop_price_multiplier(value)


func _queue_extra_rare_shop_jar() -> void:
	if owner_player != null and owner_player.has_method("queue_extra_rare_shop_jar"):
		owner_player.queue_extra_rare_shop_jar(maxi(int(value), 1))


func _refund_gold_on_shop_container_break(gold_cost_value: Variant) -> void:
	if max_stacks > 0 and runtime_trigger_count >= max_stacks:
		return
	var gold_cost: int = int(gold_cost_value)
	if gold_cost <= 0 or owner_player == null or not owner_player.has_method("add_gold"):
		return

	var refund_rate: float = value
	if stacking_rule == &"shared_limited_trigger_scaled_by_copies":
		refund_rate *= float(_get_item_count())
	var refund: int = floori(float(gold_cost) * refund_rate)
	if refund <= 0:
		refund = 1
	runtime_trigger_count += 1
	owner_player.add_gold(refund, "Shop Refund Charm")


func _heal_over_time_after_damage_taken(final_damage_taken: float) -> void:
	if final_damage_taken <= 0.0 or owner_player == null:
		return
	var total_heal: float = final_damage_taken * value
	if total_heal <= 0.0:
		return

	var effect := Node.new()
	effect.name = "HealingOverTimeEffect"
	effect.set_script(HEALING_OVER_TIME_SCRIPT)
	effect.call("setup", owner_player, total_heal, duration)
	owner_player.add_child(effect)


func _gold_every_hp_lost(final_damage_taken: float) -> void:
	if final_damage_taken <= 0.0 or owner_player == null or not owner_player.has_method("add_gold"):
		return

	var hp_per_gold: float = maxf(value, 0.001)
	accumulated_hp_loss += final_damage_taken
	var gold_to_add: int = int(floorf(accumulated_hp_loss / hp_per_gold))
	if gold_to_add <= 0:
		return

	accumulated_hp_loss -= float(gold_to_add) * hp_per_gold
	owner_player.add_gold(gold_to_add, "Pain Dividend")


func _lose_current_hp_percent_then_heal_over_time() -> void:
	if owner_player == null or not owner_player.has_method("lose_hp"):
		return
	var current_hp: float = float(owner_player.get("hp"))
	var hp_loss: float = current_hp * value
	if hp_loss <= 0.0:
		return

	var actual_loss: float = float(owner_player.lose_hp(hp_loss))
	if actual_loss <= 0.0:
		return

	var total_heal: float = actual_loss * damage_scale * float(_get_item_count())
	var effect := Node.new()
	effect.name = "HealingOverTimeEffect"
	effect.set_script(HEALING_OVER_TIME_SCRIPT)
	effect.call("setup", owner_player, total_heal, duration)
	owner_player.add_child(effect)


func _uses_shared_stack_listener() -> bool:
	if stacking_rule == &"chance_multiplicative":
		return true
	if stacking_rule == &"shared_counter_cap_per_copy":
		return true
	if stacking_rule == &"shared_counter_scaled_effect":
		return true
	if stacking_rule == &"shared_sequence_scaled":
		return true
	if stacking_rule == &"shared_limited_trigger_scaled_by_copies":
		return true
	if stacking_rule == &"shared_trigger_scaled_by_copies":
		return true
	if stacking_rule == &"shared_poison_transfer_scaled":
		return true
	if stacking_rule == &"summon_count_by_stat_per_copy":
		return true
	if effect_type == EFFECT_TYPES.LOSE_CURRENT_HP_PERCENT_THEN_HEAL_OVER_TIME:
		return true
	return effect_type == EFFECT_TYPES.FIRE_DRAGONS_PER_MAX_HP


func _get_item_count() -> int:
	if owner_player != null and owner_player.has_method("get_item_count"):
		return maxi(int(owner_player.get_item_count(item_id)), 1)
	return 1


func _get_effective_chance() -> float:
	if stacking_rule == &"chance_multiplicative":
		return 1.0 - pow(1.0 - clampf(chance, 0.0, 1.0), float(_get_item_count()))
	return chance


func _fireballs_every_n_kills() -> void:
	var threshold: int = maxi(max_stacks, 1)
	kill_counter += 1
	if kill_counter < threshold or fireburst_deferred:
		return

	fireburst_deferred = true
	call_deferred("_release_pending_fireburst")


func _release_pending_fireburst() -> void:
	fireburst_deferred = false
	var threshold: int = maxi(max_stacks, 1)
	while kill_counter >= threshold:
		kill_counter -= threshold
		var fireball_count: int = maxi(chain_count, 1)
		if stacking_rule == &"shared_counter_scaled_effect":
			fireball_count *= _get_item_count()
		if not _release_fireballs_from_player(fireball_count):
			break


func _release_fireballs_from_player(count: int) -> bool:
	var origin: Vector2 = _get_player_position()
	var targets: Array[Node2D] = _get_enemies_near(origin, radius)
	if targets.is_empty():
		return false

	var fallback_target: Node2D = targets[0]
	for index in range(count):
		var target: Node2D = _pop_nearest_target(targets, origin)
		if target == null:
			target = fallback_target
		if target == null or not is_instance_valid(target):
			continue
		var target_position: Vector2 = target.global_position
		if targets.is_empty() and count > 1:
			target_position = origin + (target.global_position - origin).rotated(deg_to_rad(_get_spread_angle(index, count)))
		_launch_fireball(origin, target_position)
	return true


func _fireball_sequence_on_kill() -> void:
	if fireburst_deferred:
		return

	fireburst_deferred = true
	call_deferred("_release_fireball_sequence")


func _fireball_sequence_on_poisoned_death(enemy: Variant) -> void:
	if not _enemy_has_status(enemy, &"poison"):
		return
	_fireball_sequence_on_kill()


func _release_fireball_sequence() -> void:
	var fireball_count := maxi(chain_count, 1)
	if stacking_rule == &"shared_sequence_scaled":
		fireball_count += maxi(_get_item_count() - 1, 0)

	for index in range(fireball_count):
		if index > 0:
			await owner_player.get_tree().create_timer(maxf(chance, 0.0)).timeout
		if owner_player == null or not is_instance_valid(owner_player):
			fireburst_deferred = false
			return
		if not _release_fireballs_from_player(1):
			break

	fireburst_deferred = false


func _pop_nearest_target(targets: Array[Node2D], origin: Vector2) -> Node2D:
	var best_index: int = -1
	var best_distance: float = INF
	for index in range(targets.size()):
		var target: Node2D = targets[index]
		if target == null or not is_instance_valid(target):
			continue
		var distance: float = target.global_position.distance_squared_to(origin)
		if distance < best_distance:
			best_distance = distance
			best_index = index
	if best_index < 0:
		return null
	var best: Node2D = targets[best_index]
	targets.remove_at(best_index)
	return best


func _sync_fire_dragons(max_hp: int) -> void:
	_cleanup_fire_dragons()
	var hp_per_dragon: int = maxi(max_stacks, 1)
	var wanted_count: int = int(floori(float(maxi(max_hp, 0)) / float(hp_per_dragon))) * _get_item_count()
	while fire_dragons.size() < wanted_count:
		_add_fire_dragon(fire_dragons.size(), wanted_count)
	while fire_dragons.size() > wanted_count:
		var dragon: Node = fire_dragons.pop_back()
		if is_instance_valid(dragon):
			dragon.queue_free()
	_update_fire_dragon_offsets()


func _add_fire_dragon(index: int, total_count: int) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var player_2d := owner_player as Node2D
	if player_2d == null:
		return

	var dragon := FIRE_DRAGON_SCENE.instantiate()
	if dragon == null:
		return
	var follow_radius: float = radius if radius > 0.0 else 56.0
	var follow_offset: Vector2 = _get_fire_dragon_offset(index, total_count, follow_radius)
	dragon.call("setup", player_2d, follow_offset, damage_scale, dash_fireball_auto_aim_radius, value)
	dragon.global_position = player_2d.global_position + follow_offset
	owner_player.get_tree().current_scene.add_child(dragon)
	fire_dragons.append(dragon)


func _update_fire_dragon_offsets() -> void:
	var total_count: int = fire_dragons.size()
	var follow_radius: float = radius if radius > 0.0 else 56.0
	for index in range(total_count):
		var dragon := fire_dragons[index]
		if is_instance_valid(dragon):
			dragon.call("set_follow_offset", _get_fire_dragon_offset(index, total_count, follow_radius))


func _get_fire_dragon_offset(index: int, total_count: int, follow_radius: float) -> Vector2:
	if total_count <= 1:
		return Vector2(42.0, -34.0)
	var angle: float = -PI * 0.5 + TAU * float(index) / float(total_count)
	return Vector2.RIGHT.rotated(angle) * follow_radius


func _cleanup_fire_dragons() -> void:
	for index in range(fire_dragons.size() - 1, -1, -1):
		if not is_instance_valid(fire_dragons[index]):
			fire_dragons.remove_at(index)


func _get_owner_max_hp() -> int:
	if owner_player == null:
		return 0
	if owner_player.has_method("get_stats"):
		var stats: StatsComponent = owner_player.get_stats()
		if stats != null:
			return stats.max_hp
	return int(owner_player.get("max_hp"))


func _get_spread_angle(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	return (float(index) - float(count - 1) * 0.5) * duplicate_projectile_spread_degrees


func _summon_turrets(count: int) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return

	var origin: Vector2 = _get_player_position()
	var spawn_radius: float = radius if radius > 0.0 else 28.0
	for index in range(count):
		var turret := SMALL_TURRET_SCENE.instantiate()
		if turret == null:
			continue
		turret.call("setup", owner_player, duration)
		turret.set("damage_scale", damage_scale)
		turret.global_position = origin + _get_spawn_offset(index, count, spawn_radius)
		owner_player.get_tree().current_scene.add_child(turret)


func _get_spawn_offset(index: int, count: int, spawn_radius: float) -> Vector2:
	if count <= 1:
		return Vector2.ZERO
	var angle: float = TAU * float(index) / float(count)
	return Vector2.RIGHT.rotated(angle) * spawn_radius


func _apply_poison_near_position(origin: Vector2, stacks: int) -> void:
	for enemy in _get_enemies_near(origin, radius):
		if enemy.has_method("apply_poison_stacks"):
			enemy.apply_poison_stacks(stacks, owner_player)


func _trigger_chain_lightning(origin: Vector2, already_hit: Array = []) -> bool:
	var stats: StatsComponent = owner_player.get_stats()
	if stats == null:
		return false

	var scale: float = stats.chain_lightning_damage_scale_override if stats.chain_lightning_damage_scale_override >= 0.0 else damage_scale
	var damage: float = owner_player.get_base_attack_damage() * stats.get_damage_multiplier() * scale
	var current_position: Vector2 = origin
	var hit: Array = already_hit.duplicate()
	var did_hit: bool = false

	for index in range(chain_count):
		var target := _get_nearest_enemy(current_position, radius, hit)
		if target == null and stats.chain_lightning_can_target_containers and index > 0:
			target = _get_nearest_container(current_position, radius, hit)
		if target == null:
			break

		var previous_position: Vector2 = current_position
		hit.append(target)
		current_position = target.global_position
		_spawn_chain_lightning_vfx(previous_position, current_position)
		did_hit = true
		if target.is_in_group("enemy") and owner_player.has_method("deal_player_damage_to_enemy"):
			owner_player.deal_player_damage_to_enemy(target, damage, {"source": "chain_lightning", "direct": true, "allow_procs": false})
		elif target.has_method("take_damage"):
			target.take_damage(damage, {"source": "chain_lightning", "owner": owner_player})
	if did_hit:
		_play_chain_lightning_sfx(origin)
		print("Chain lightning triggers")
	return did_hit


func _spawn_chain_lightning_vfx(start_position: Vector2, end_position: Vector2) -> void:
	if owner_player == null or owner_player.get_tree().current_scene == null:
		return
	var distance: float = start_position.distance_to(end_position)
	if distance <= 0.001:
		return
	var lightning_texture: Texture2D = _get_lightning_chain_texture()
	if lightning_texture == null:
		return

	var sprite_frames := SpriteFrames.new()
	var animation_name := &"default"
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, lightning_vfx_animation_fps)

	var frame_count: int = int(lightning_texture.get_height() / LIGHTNING_CHAIN_FRAME_SIZE.y)
	for frame_index in range(frame_count):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = lightning_texture
		frame_texture.region = Rect2(
			0.0,
			float(frame_index) * LIGHTNING_CHAIN_FRAME_SIZE.y,
			LIGHTNING_CHAIN_FRAME_SIZE.x,
			LIGHTNING_CHAIN_FRAME_SIZE.y
		)
		sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.name = "ChainLightningVFX"
	effect.sprite_frames = sprite_frames
	effect.rotation = (end_position - start_position).angle()
	effect.scale = Vector2(distance / LIGHTNING_CHAIN_FRAME_SIZE.x, lightning_vfx_height_scale)
	effect.z_index = 200
	effect.modulate.a = lightning_vfx_color.a
	owner_player.get_tree().current_scene.add_child(effect)
	effect.global_position = start_position.lerp(end_position, 0.5)
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
	var stream: AudioStream = _get_lightning_chain_sfx()
	if stream == null:
		return
	SFX_PLAYER.play_2d(owner_player.get_tree().current_scene, stream, position, lightning_sfx_volume_db, 0.98, 1.04)


func _get_lightning_chain_sfx() -> AudioStream:
	if lightning_chain_sfx != null:
		return lightning_chain_sfx

	var stream := load(LIGHTNING_CHAIN_SFX_PATH) as AudioStream
	if stream == null and FileAccess.file_exists(LIGHTNING_CHAIN_SFX_PATH):
		stream = AudioStreamMP3.load_from_file(LIGHTNING_CHAIN_SFX_PATH)
	if stream == null:
		push_warning("Failed to load chain lightning SFX: %s" % LIGHTNING_CHAIN_SFX_PATH)
		return null

	lightning_chain_sfx = stream
	return lightning_chain_sfx


func _launch_fireball(start_position: Vector2, target_position: Vector2) -> void:
	var direction: Vector2 = target_position - start_position
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var stats: StatsComponent = owner_player.get_stats()
	var final_damage: float = owner_player.get_base_attack_damage()
	if stats != null:
		final_damage *= stats.get_damage_multiplier()
	final_damage *= damage_scale

	var fireball := Area2D.new()
	fireball.set_script(FIREBALL_SCRIPT)
	fireball.setup(owner_player, start_position, direction, final_damage, radius)
	fireball.collision_layer = 1 << 2
	fireball.collision_mask = 1 << 1
	owner_player.get_tree().current_scene.add_child(fireball)
	print("Fireball triggers")


func _launch_fireball_from_event(arg1: Variant, arg2: Variant) -> void:
	if event_name == &"attack_started":
		var start_position: Vector2 = _extract_position(arg1)
		var direction := arg2 as Vector2
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT
		_launch_fireball(start_position, start_position + direction.normalized() * 240.0)
		return

	_launch_fireball(_get_player_position(), _extract_position(arg1))


func _get_buffs() -> TemporaryBuffComponent:
	if owner_player != null and owner_player.has_method("get_temporary_buffs"):
		return owner_player.get_temporary_buffs()
	return null


func _get_instance_buff_id() -> StringName:
	return StringName("%s_%s_%d" % [event_name, effect_type, get_instance_id()])


func _get_duplicate_spread_angle() -> float:
	if item_stack_index <= 0:
		return 0.0

	var lane: int = int(ceil(float(item_stack_index) / 2.0))
	var sign_value: float = 1.0 if item_stack_index % 2 == 1 else -1.0
	return duplicate_projectile_spread_degrees * float(lane) * sign_value


func _get_player_position() -> Vector2:
	var node := owner_player as Node2D
	return node.global_position if node != null else Vector2.ZERO


func _extract_position(position_source: Variant) -> Vector2:
	if position_source is Vector2:
		return position_source
	if not position_source is Object:
		return _get_player_position()

	var node := position_source as Node2D
	if node != null:
		return node.global_position
	return _get_player_position()


func _get_effect_origin(arg1: Variant) -> Vector2:
	if event_name == &"attack_started":
		return _extract_position(arg1)
	return _extract_position(arg1)


func _get_initial_chain_excludes(arg1: Variant) -> Array:
	if event_name == &"attack_hit":
		return [arg1]
	return []


func _enemy_has_status(enemy: Variant, id: StringName) -> bool:
	return enemy != null and enemy.has_method("has_status") and enemy.has_status(id)


func _get_enemies_near(origin: Vector2, search_radius: float, exclude: Array = []) -> Array[Node2D]:
	return EFFECT_TARGETING.enemies_near(owner_player, origin, search_radius, exclude)


func _get_nearest_enemy(origin: Vector2, search_radius: float, exclude: Array = []) -> Node2D:
	return EFFECT_TARGETING.nearest_enemy(owner_player, origin, search_radius, exclude)


func _get_nearest_container(origin: Vector2, search_radius: float, exclude: Array = []) -> Node2D:
	return EFFECT_TARGETING.nearest_container(owner_player, origin, search_radius, exclude)
