extends ItemEffect
class_name PeriodicEffect

const ITEM_RUNTIME_EFFECT_SCRIPT := preload("res://systems/items/effects/ItemRuntimeEffectNode.gd")

const AUTO_HOLY_FLAME_LASER := &"auto_holy_flame_laser"
const NEARBY_ENEMY_ATTACK_SPEED := &"nearby_enemy_attack_speed"
const PERIODIC_AUTO_FIREBALL := &"periodic_auto_fireball"
const PERIODIC_BLOOD_BLADE := &"periodic_blood_blade"
const PERIODIC_BLOOD_CLAW := &"periodic_blood_claw"
const PERIODIC_CHAIN_LIGHTNING := &"periodic_chain_lightning"
const PERIODIC_DAMAGE_SHIELD := &"periodic_damage_shield"
const PERIODIC_EXPLOSIVE_TRAP := &"periodic_explosive_trap"
const PERIODIC_INVINCIBILITY := &"periodic_invincibility"
const PERIODIC_TIMED_STAT_BUFF := &"periodic_timed_stat_buff"
const STATIONARY_ATTACK_SPEED := &"stationary_attack_speed"
const SURROUNDED_STAT_BONUS := &"surrounded_stat_bonus"

@export var mode: StringName
@export var stat_name: StringName
@export var value: float = 0.0
@export var duration: float = 0.0
@export var max_stacks: int = 1
@export var radius: float = 0.0
@export var chance: float = 0.0
@export var damage_scale: float = 0.0
@export var interval: float = 0.0

var owner_player: Node
var item_id: StringName
var item_effect_index: int = 0
var item_stack_index: int = 0
var runtime_node: Node


static func all_modes() -> Array[StringName]:
	return [
		AUTO_HOLY_FLAME_LASER,
		NEARBY_ENEMY_ATTACK_SPEED,
		PERIODIC_AUTO_FIREBALL,
		PERIODIC_BLOOD_BLADE,
		PERIODIC_BLOOD_CLAW,
		PERIODIC_CHAIN_LIGHTNING,
		PERIODIC_DAMAGE_SHIELD,
		PERIODIC_EXPLOSIVE_TRAP,
		PERIODIC_INVINCIBILITY,
		PERIODIC_TIMED_STAT_BUFF,
		STATIONARY_ATTACK_SPEED,
		SURROUNDED_STAT_BONUS,
	]


func configure_instance(new_item_id: StringName, new_effect_index: int, new_stack_index: int) -> void:
	item_id = new_item_id
	item_effect_index = new_effect_index
	item_stack_index = new_stack_index


func apply_to(player: Node) -> void:
	owner_player = player
	if stacking_rule == &"shared_runtime_scaled" and item_stack_index > 0:
		return
	_add_runtime_effect_node()


func on_item_count_changed(changed_item_id: StringName) -> void:
	if changed_item_id != item_id:
		return
	if stacking_rule == &"shared_runtime_scaled" and item_stack_index == 0 and runtime_node == null:
		_add_runtime_effect_node()


func _add_runtime_effect_node() -> void:
	if owner_player == null:
		return

	runtime_node = Node.new()
	runtime_node.name = "ItemRuntimeEffectNode"
	runtime_node.set_script(ITEM_RUNTIME_EFFECT_SCRIPT)
	runtime_node.call(
		"setup",
		owner_player,
		item_id,
		mode,
		stat_name,
		value,
		duration,
		max_stacks,
		radius,
		chance,
		damage_scale,
		interval
	)
	owner_player.add_child(runtime_node)
