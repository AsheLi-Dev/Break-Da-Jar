extends Node2D
class_name FloatingText

@export var duration: float = 0.55
@export var rise_speed: float = 48.0
@export var text_color: Color = Color.WHITE
@export var outline_color: Color = Color(0.04, 0.05, 0.08, 0.95)
@export var text_scale: float = 1.0

var age: float = 0.0
var label: Label


func setup(text: String, spawn_position: Vector2, color: Color = Color.WHITE, scale_value: float = 1.0) -> void:
	global_position = spawn_position
	text_color = color
	text_scale = scale_value
	_ensure_label()
	label.text = text
	label.add_theme_color_override("font_color", text_color)


func _ready() -> void:
	z_index = 120
	_ensure_label()


func _process(delta: float) -> void:
	age += delta
	position.y -= rise_speed * delta
	var progress := clampf(age / maxf(duration, 0.001), 0.0, 1.0)
	modulate.a = 1.0 - progress
	if age >= duration:
		queue_free()


func _ensure_label() -> void:
	if label != null:
		return

	label = Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-40.0, -12.0)
	label.size = Vector2(80.0, 24.0)
	label.scale = Vector2(text_scale, text_scale)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
