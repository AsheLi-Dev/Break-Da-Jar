extends Camera2D
class_name CameraShake

var shake_timer: float = 0.0
var shake_duration: float = 0.0
var shake_magnitude: float = 0.0


func start_shake(magnitude: float = 6.0, duration: float = 0.14) -> void:
	shake_magnitude = maxf(shake_magnitude, magnitude)
	shake_duration = maxf(shake_duration, duration)
	shake_timer = maxf(shake_timer, duration)


func _process(delta: float) -> void:
	if shake_timer <= 0.0:
		offset = Vector2.ZERO
		shake_duration = 0.0
		shake_magnitude = 0.0
		return

	shake_timer = maxf(0.0, shake_timer - delta)
	var progress := shake_timer / maxf(shake_duration, 0.001)
	var amplitude := shake_magnitude * progress
	offset = Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude))
