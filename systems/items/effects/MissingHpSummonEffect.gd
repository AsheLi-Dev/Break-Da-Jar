extends ItemEffect
class_name MissingHpSummonEffect

@export var summon_scene: PackedScene
@export var missing_hp_per_summon: float = 50.0
@export var stack_missing_hp_reduction: float = 0.0
@export var minimum_missing_hp_per_summon: float = 10.0
@export var summon_spacing: float = 42.0
@export var follow_radius: float = 72.0

var owner_player: Node
var item_id: StringName
var item_effect_index: int = 0
var item_stack_index: int = 0
var summons: Array[Node] = []


func configure_instance(new_item_id: StringName, new_effect_index: int, new_stack_index: int) -> void:
	item_id = new_item_id
	item_effect_index = new_effect_index
	item_stack_index = new_stack_index


func apply_to(player: Node) -> void:
	owner_player = player
	if item_stack_index > 0:
		return
	if not player.has_signal(&"hp_changed"):
		push_warning("Player signal missing: hp_changed")
		return

	var callable := Callable(self, "_on_hp_changed")
	if not player.is_connected(&"hp_changed", callable):
		player.connect(&"hp_changed", callable)
	_on_hp_changed(int(player.get("hp")), int(player.get("max_hp")))


func on_item_count_changed(changed_item_id: StringName) -> void:
	if changed_item_id != item_id or item_stack_index > 0 or owner_player == null:
		return
	_on_hp_changed(int(owner_player.get("hp")), int(owner_player.get("max_hp")))


func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	_cleanup_summons()
	var missing_hp := maxi(max_hp - current_hp, 0)
	var per_summon := _get_missing_hp_per_summon()
	var wanted_count := int(floorf(float(missing_hp) / per_summon))
	_sync_summons(wanted_count)


func _sync_summons(wanted_count: int) -> void:
	while summons.size() < wanted_count:
		_add_summon(summons.size(), wanted_count)
	while summons.size() > wanted_count:
		var summon: Node = summons.pop_back()
		if is_instance_valid(summon):
			summon.queue_free()
	_update_offsets()


func _add_summon(index: int, total_count: int) -> void:
	if summon_scene == null or owner_player == null or owner_player.get_tree().current_scene == null:
		return
	var owner_2d := owner_player as Node2D
	if owner_2d == null:
		return

	var summon := summon_scene.instantiate() as Node2D
	if summon == null:
		return
	var offset := _get_offset(index, total_count)
	if summon.has_method("setup"):
		summon.call("setup", owner_2d, offset)
	summon.global_position = owner_2d.global_position + offset
	owner_player.get_tree().current_scene.add_child(summon)
	summons.append(summon)


func _update_offsets() -> void:
	var total_count := summons.size()
	for index in range(total_count):
		var summon: Node = summons[index]
		if is_instance_valid(summon) and summon.has_method("set_follow_offset"):
			summon.call("set_follow_offset", _get_offset(index, total_count))


func _get_offset(index: int, total_count: int) -> Vector2:
	if total_count <= 1:
		return Vector2(-follow_radius, -24.0)
	var angle := -PI * 0.5 + TAU * float(index) / float(total_count)
	return Vector2.RIGHT.rotated(angle) * (follow_radius + summon_spacing * floorf(float(index) / 8.0))


func _cleanup_summons() -> void:
	for index in range(summons.size() - 1, -1, -1):
		if not is_instance_valid(summons[index]):
			summons.remove_at(index)


func _get_item_count() -> int:
	if owner_player != null and owner_player.has_method("get_item_count"):
		return maxi(int(owner_player.get_item_count(item_id)), 1)
	return 1


func _get_missing_hp_per_summon() -> float:
	var reduction := stack_missing_hp_reduction * float(maxi(_get_item_count() - 1, 0))
	return maxf(minimum_missing_hp_per_summon, missing_hp_per_summon - reduction)
