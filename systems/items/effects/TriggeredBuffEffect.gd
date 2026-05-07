extends ItemEffect
class_name TriggeredBuffEffect

const MODE_TIMED_STAT_BUFF := &"timed_stat_buff"
const MODE_ROUND_STAT_BUFF := &"round_stat_buff"
const MODE_MISSING_HP_STAT_BONUS := &"missing_hp_stat_bonus"

@export var event_name: StringName
@export var mode: StringName
@export var stat_name: StringName
@export var value: float = 0.0
@export var duration: float = 0.0
@export var max_stacks: int = 1
@export var missing_hp_step: float = 10.0
@export var stack_value_bonus: float = 0.0
@export var requires_direct_player_container_break: bool = false

var owner_player: Node
var item_id: StringName
var item_effect_index: int = 0
var item_stack_index: int = 0


static func all_modes() -> Array[StringName]:
	return [
		MODE_TIMED_STAT_BUFF,
		MODE_ROUND_STAT_BUFF,
		MODE_MISSING_HP_STAT_BONUS,
	]


func configure_instance(new_item_id: StringName, new_effect_index: int, new_stack_index: int) -> void:
	item_id = new_item_id
	item_effect_index = new_effect_index
	item_stack_index = new_stack_index


func apply_to(player: Node) -> void:
	owner_player = player
	if _uses_shared_listener() and item_stack_index > 0:
		return
	if not player.has_signal(event_name):
		push_warning("Player signal missing: %s" % event_name)
		return

	var callable := Callable(self, "_on_player_event")
	if not player.is_connected(event_name, callable):
		player.connect(event_name, callable)


func _on_player_event(arg1: Variant = null, arg2: Variant = null, _arg3: Variant = null) -> void:
	if owner_player == null:
		return

	match mode:
		MODE_TIMED_STAT_BUFF:
			_add_timed_buff()
		MODE_ROUND_STAT_BUFF:
			if _passes_direct_container_filter(arg2):
				_add_round_buff()
		MODE_MISSING_HP_STAT_BONUS:
			_update_missing_hp_bonus(int(arg1), int(arg2))


func _add_timed_buff() -> void:
	var buffs := _get_buffs()
	if buffs != null:
		buffs.add_timed_stat_buff(_get_instance_buff_id(), stat_name, value, duration, max_stacks)


func _add_round_buff() -> void:
	var buffs := _get_buffs()
	if buffs != null:
		buffs.add_round_stat_buff(_get_instance_buff_id(), stat_name, value, max_stacks)


func _update_missing_hp_bonus(current_hp: int, max_hp: int) -> void:
	var missing: int = maxi(0, max_hp - current_hp)
	var step := maxf(missing_hp_step, 0.001)
	var value_per_step := value + stack_value_bonus * float(maxi(_get_item_count() - 1, 0))
	var bonus: float = floorf(float(missing) / step) * value_per_step
	var buffs := _get_buffs()
	if buffs != null:
		buffs.set_dynamic_stat_bonus(_get_instance_buff_id(), stat_name, bonus)


func _passes_direct_container_filter(info_value: Variant) -> bool:
	if not requires_direct_player_container_break:
		return true
	var info: Dictionary = info_value if info_value is Dictionary else {}
	return String(info.get("source", "")) == "player_attack"


func _uses_shared_listener() -> bool:
	return stacking_rule == &"shared_missing_hp_scaled"


func _get_buffs() -> TemporaryBuffComponent:
	if owner_player != null and owner_player.has_method("get_temporary_buffs"):
		return owner_player.get_temporary_buffs()
	return null


func _get_instance_buff_id() -> StringName:
	return StringName("%s_%s_%d" % [event_name, mode, get_instance_id()])


func _get_item_count() -> int:
	if owner_player != null and owner_player.has_method("get_item_count"):
		return maxi(int(owner_player.get_item_count(item_id)), 1)
	return 1
