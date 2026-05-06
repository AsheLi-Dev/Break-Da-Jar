extends Camera2D
class_name CameraShake

var shake_timer: float = 0.0
var shake_duration: float = 0.0
var shake_magnitude: float = 0.0
var base_zoom: Vector2 = Vector2.ONE
var zoom_timer: float = 0.0
var zoom_duration: float = 0.0
var zoom_factor: float = 1.0


func _ready() -> void:
	base_zoom = zoom


func start_shake(magnitude: float = 6.0, duration: float = 0.14) -> void:
	shake_magnitude = maxf(shake_magnitude, magnitude)
	shake_duration = maxf(shake_duration, duration)
	shake_timer = maxf(shake_timer, duration)


func start_zoom_in(factor: float = 1.12, duration: float = 0.16) -> void:
	zoom_factor = maxf(zoom_factor, factor)
	zoom_duration = maxf(zoom_duration, duration)
	zoom_timer = maxf(zoom_timer, duration)


func _process(delta: float) -> void:
	_update_zoom(delta)
	if shake_timer <= 0.0:
		offset = Vector2.ZERO
		shake_duration = 0.0
		shake_magnitude = 0.0
		return

	shake_timer = maxf(0.0, shake_timer - delta)
	var progress := shake_timer / maxf(shake_duration, 0.001)
	var amplitude := shake_magnitude * progress
	offset = Vector2(randf_range(-amplitude, amplitude), randf_range(-amplitude, amplitude))


func _update_zoom(delta: float) -> void:
	if zoom_timer <= 0.0:
		zoom = base_zoom
		zoom_duration = 0.0
		zoom_factor = 1.0
		return

	var adjusted_delta := delta / maxf(Engine.time_scale, 0.001)
	zoom_timer = maxf(0.0, zoom_timer - adjusted_delta)
	var progress := zoom_timer / maxf(zoom_duration, 0.001)
	var current_factor := lerpf(1.0, zoom_factor, progress)
	zoom = base_zoom * current_factor
