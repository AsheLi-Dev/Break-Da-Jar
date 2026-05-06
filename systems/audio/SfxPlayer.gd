extends RefCounted
class_name SfxPlayer

const THROTTLE_MS := 45

static var last_played_ms: Dictionary = {}


static func play_2d(
	parent: Node,
	stream: AudioStream,
	position: Vector2,
	volume_db: float = 0.0,
	pitch_min: float = 0.94,
	pitch_max: float = 1.08
) -> void:
	if parent == null or stream == null:
		return

	var key := stream.resource_path
	var now := Time.get_ticks_msec()
	var last := int(last_played_ms.get(key, 0))
	if now - last < THROTTLE_MS:
		return
	last_played_ms[key] = now

	var audio := AudioStreamPlayer2D.new()
	audio.stream = stream
	audio.global_position = position
	audio.volume_db = volume_db
	audio.pitch_scale = randf_range(pitch_min, pitch_max)
	parent.add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
