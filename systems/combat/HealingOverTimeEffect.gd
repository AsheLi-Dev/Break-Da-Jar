extends Node
class_name HealingOverTimeEffect

var owner_player: Node
var total_heal: float = 0.0
var duration: float = 2.0
var elapsed: float = 0.0
var healed: float = 0.0


func setup(new_owner: Node, new_total_heal: float, new_duration: float) -> void:
	owner_player = new_owner
	total_heal = maxf(new_total_heal, 0.0)
	duration = maxf(new_duration, 0.001)


func _process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player) or not owner_player.has_method("heal"):
		queue_free()
		return

	elapsed = minf(elapsed + delta, duration)
	var target_healed: float = total_heal * (elapsed / duration)
	var tick_heal: float = target_healed - healed
	healed = target_healed
	if tick_heal > 0.0:
		owner_player.heal(tick_heal)
	if elapsed >= duration:
		queue_free()
