extends Node2D
class_name ShopItemRewardVisual

@export var hover_duration: float = 0.45
@export var fly_speed: float = 900.0
@export var collect_distance: float = 22.0
@export var icon_size: float = 48.0

var item: ItemDefinition
var target_player: Node2D
var collect_callback: Callable
var age: float = 0.0
var flying: bool = false
var collected: bool = false
var hover_offset: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var icon_sprite: Sprite2D
var shadow: Polygon2D


func setup(new_item: ItemDefinition, spawn_position: Vector2, new_target_player: Node2D, new_collect_callback: Callable) -> void:
	item = new_item
	global_position = spawn_position
	target_player = new_target_player
	collect_callback = new_collect_callback
	hover_offset = Vector2(randf_range(-14.0, 14.0), -44.0)
	velocity = Vector2(randf_range(-35.0, 35.0), -80.0)


func _ready() -> void:
	z_index = 120
	_ensure_visual()


func _process(delta: float) -> void:
	if collected:
		return

	age += delta
	if not flying:
		_update_hover(delta)
		if age >= hover_duration:
			flying = true
		return

	if target_player == null or not is_instance_valid(target_player):
		queue_free()
		return

	var offset := target_player.global_position - global_position
	if offset.length() <= collect_distance:
		_collect()
		return

	var desired_velocity := offset.normalized() * fly_speed
	velocity = velocity.move_toward(desired_velocity, fly_speed * delta * 5.0)
	global_position += velocity * delta


func _update_hover(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)
	global_position += velocity * delta
	if icon_sprite != null:
		var bob := sin(age * TAU * 2.0) * 4.0
		icon_sprite.position = hover_offset + Vector2(0.0, bob)
	if shadow != null:
		shadow.scale = Vector2(0.75, 0.75)


func _collect() -> void:
	collected = true
	if collect_callback.is_valid():
		collect_callback.call(item)
	queue_free()


func _ensure_visual() -> void:
	shadow = Polygon2D.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.02, 0.025, 0.03, 0.32)
	shadow.polygon = PackedVector2Array([
		Vector2(-12.0, -4.0),
		Vector2(12.0, -4.0),
		Vector2(12.0, 4.0),
		Vector2(-12.0, 4.0),
	])
	add_child(shadow)

	icon_sprite = Sprite2D.new()
	icon_sprite.name = "Icon"
	icon_sprite.texture = item.icon if item != null else null
	icon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_sprite.position = hover_offset
	if icon_sprite.texture != null:
		var texture_size := icon_sprite.texture.get_size()
		var largest_side := maxf(texture_size.x, texture_size.y)
		if largest_side > 0.0:
			var scale_value := icon_size / largest_side
			icon_sprite.scale = Vector2(scale_value, scale_value)
	add_child(icon_sprite)
