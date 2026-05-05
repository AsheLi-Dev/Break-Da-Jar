extends ItemEffect
class_name StatModifierEffect

@export var stat_name: StringName
@export var operation: StringName = &"add"
@export var value: float = 0.0


func apply_to(player: Node) -> void:
	if not player.has_method("get_stats"):
		push_warning("Player does not expose get_stats().")
		return

	var stats: StatsComponent = player.get_stats()
	if stats == null:
		push_warning("Player stats is null.")
		return

	stats.apply_modifier(stat_name, operation, value)
