extends Projectile
class_name AcidProjectile

@export var core_color: Color = Color(0.72, 1.0, 0.18, 0.95)
@export var rim_color: Color = Color(0.16, 0.62, 0.12, 0.85)
@export var trail_color: Color = Color(0.48, 1.0, 0.08, 0.78)
@export var trail_spawn_interval: float = 0.018
@export var trail_lifetime: float = 0.34
@export var splash_lifetime: float = 0.22

var visual_root: Node2D
var acid_sprite: AnimatedSprite2D
var wobble_time: float = 0.0
var trail_spawn_timer: float = 0.0


func _process(delta: float) -> void:
	wobble_time += delta
	_update_acid_trail(delta)
	if acid_sprite == null:
		return

	acid_sprite.position.y = roundf(sin(wobble_time * 13.0))


func _on_body_entered(body: Node) -> void:
	if _try_damage_target_body(body):
		_spawn_acid_splash()
		if not boomerang_enabled:
			queue_free()
		return

	if hit_walls and _is_wall_body(body):
		_spawn_acid_splash()
		queue_free()


func _ensure_placeholder_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 5.0
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("AcidVisual") != null:
		return

	visual_root = Node2D.new()
	visual_root.name = "AcidVisual"
	add_child(visual_root)

	acid_sprite = AnimatedSprite2D.new()
	acid_sprite.name = "AcidSprite"
	acid_sprite.centered = true
	acid_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	acid_sprite.sprite_frames = _make_acid_sprite_frames()
	acid_sprite.scale = Vector2(1.25, 1.25)
	visual_root.add_child(acid_sprite)
	acid_sprite.play(&"fly")


func _make_pixel(pixel_name: String, center: Vector2, size: Vector2, color: Color) -> Polygon2D:
	var pixel := Polygon2D.new()
	pixel.name = pixel_name
	pixel.color = color
	var half_size: Vector2 = size * 0.5
	pixel.polygon = PackedVector2Array([
		center + Vector2(-half_size.x, -half_size.y),
		center + Vector2(half_size.x, -half_size.y),
		center + Vector2(half_size.x, half_size.y),
		center + Vector2(-half_size.x, half_size.y),
	])
	return pixel


func _make_acid_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var animation_name := &"fly"
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, 10.0)
	for frame in range(4):
		frames.add_frame(animation_name, _make_acid_texture(frame))
	return frames


func _make_acid_texture(frame: int) -> Texture2D:
	var width := 24
	var height := 18
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var center := Vector2(11.5, 8.5)
	var radius_x := 8.0
	var radius_y := 4.8
	for y in range(height):
		for x in range(width):
			var local := Vector2(float(x), float(y)) - center
			var ellipse: float = (local.x * local.x) / (radius_x * radius_x) + (local.y * local.y) / (radius_y * radius_y)
			if ellipse > 1.0:
				continue

			var color := core_color
			if ellipse > 0.72:
				color = rim_color
			elif local.x < -3.0 and local.y < -2.0:
				color = Color(0.94, 1.0, 0.5, 0.95)
			image.set_pixel(x, y, color)

	_draw_acid_bubbles(image, frame)
	return ImageTexture.create_from_image(image)


func _draw_acid_bubbles(image: Image, frame: int) -> void:
	_set_pixel_safe(image, 8, 5 + frame % 2, Color(0.98, 1.0, 0.72, 0.95))
	_set_pixel_safe(image, 9, 5 + frame % 2, Color(0.98, 1.0, 0.72, 0.75))
	_set_pixel_safe(image, 15, 10 - frame % 2, Color(0.98, 1.0, 0.72, 0.72))
	_set_pixel_safe(image, 16, 10 - frame % 2, Color(0.98, 1.0, 0.72, 0.55))


func _update_acid_trail(delta: float) -> void:
	trail_spawn_timer -= delta
	if trail_spawn_timer > 0.0:
		return

	trail_spawn_timer = trail_spawn_interval
	for index in range(3):
		_spawn_acid_trail_pixel(index)


func _spawn_acid_trail_pixel(index: int) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var travel_direction := direction.normalized()
	if travel_direction.length_squared() <= 0.001:
		travel_direction = Vector2.RIGHT.rotated(rotation)

	var tangent := Vector2(-travel_direction.y, travel_direction.x)
	var size := randf_range(5.0, 8.0)
	var trail_pixel := _make_pixel("AcidTrailPixel", Vector2.ZERO, Vector2(size, size), trail_color)
	trail_pixel.z_index = -1
	get_tree().current_scene.add_child(trail_pixel)
	trail_pixel.global_position = global_position - travel_direction * randf_range(10.0 + index * 4.0, 18.0 + index * 7.0) + tangent * randf_range(-7.0, 7.0)

	var tween := trail_pixel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail_pixel, "scale", Vector2(0.25, 0.25), trail_lifetime)
	tween.tween_property(trail_pixel, "modulate:a", 0.0, trail_lifetime)
	tween.finished.connect(Callable(trail_pixel, "queue_free"))


func _set_pixel_safe(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, color)


func _spawn_acid_splash() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return

	var splash := Node2D.new()
	splash.name = "AcidSplashVFX"
	get_tree().current_scene.add_child(splash)
	splash.global_position = global_position

	splash.add_child(_make_pixel("PuddleA", Vector2.ZERO, Vector2(24.0, 8.0), Color(0.46, 0.9, 0.1, 0.38)))
	splash.add_child(_make_pixel("PuddleB", Vector2(-7.0, 3.0), Vector2(10.0, 5.0), Color(0.72, 1.0, 0.18, 0.32)))
	splash.add_child(_make_pixel("PuddleC", Vector2(8.0, -2.0), Vector2(8.0, 4.0), Color(0.18, 0.58, 0.1, 0.36)))

	for index in range(4):
		var size := randf_range(2.0, 4.0)
		var drop := _make_pixel("Drop%d" % index, Vector2.ZERO, Vector2(size, size), Color(0.75, 1.0, 0.22, 0.7))
		drop.position = Vector2(roundf(randf_range(-18.0, 18.0)), roundf(randf_range(-10.0, 10.0)))
		splash.add_child(drop)

	var tween := splash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(splash, "scale", Vector2(1.25, 1.25), splash_lifetime)
	tween.tween_property(splash, "modulate:a", 0.0, splash_lifetime)
	tween.finished.connect(Callable(splash, "queue_free"))
