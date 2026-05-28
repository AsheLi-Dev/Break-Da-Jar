extends Control

const CHARACTER_DATABASE := preload("res://scripts/player/CharacterDatabase.gd")
const BATTLE_SCENE_PATH := "res://battlescene.tscn"
const CHARACTER_IDS: Array[StringName] = [&"paladin", &"necromancer", &"wizard"]
const CHARACTER_FRAME_SIZE := Vector2i(128, 128)

var selected_character_id: StringName = &"paladin"
var selected_card: Button
var start_button: Button
var cards_by_id: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_select_character(selected_character_id)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.055, 0.065, 0.07)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 180.0
	root.offset_top = 96.0
	root.offset_right = -180.0
	root.offset_bottom = -96.0
	root.add_theme_constant_override("separation", 34)
	add_child(root)

	var title := Label.new()
	title.text = "Dead Vessel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose your character"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	root.add_child(subtitle)

	var card_row := HBoxContainer.new()
	card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 28)
	root.add_child(card_row)

	for character_id in CHARACTER_IDS:
		var card := _create_character_card(character_id)
		cards_by_id[character_id] = card
		card_row.add_child(card)

	start_button = Button.new()
	start_button.text = "Start Game"
	start_button.custom_minimum_size = Vector2(320.0, 64.0)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.add_theme_font_size_override("font_size", 28)
	start_button.pressed.connect(_start_game)
	root.add_child(start_button)


func _create_character_card(character_id: StringName) -> Button:
	var definition := CHARACTER_DATABASE.get_definition(character_id)
	var card := Button.new()
	card.custom_minimum_size = Vector2(360.0, 560.0)
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_ALL
	card.pressed.connect(_select_character.bind(character_id))

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 22.0
	content.offset_top = 22.0
	content.offset_right = -22.0
	content.offset_bottom = -22.0
	content.add_theme_constant_override("separation", 18)
	card.add_child(content)

	var name_label := Label.new()
	name_label.text = definition.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 34)
	content.add_child(name_label)

	var portrait := TextureRect.new()
	portrait.texture = _make_character_portrait_texture(definition)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(240.0, 220.0)
	content.add_child(portrait)

	var stats := Label.new()
	stats.text = "HP %d\nATK %d\nSpeed %d" % [
		int(definition.max_hp),
		int(definition.base_damage),
		int(definition.move_speed),
	]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 24)
	content.add_child(stats)

	var abilities := Label.new()
	abilities.text = _ability_text(character_id)
	abilities.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	abilities.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abilities.size_flags_vertical = Control.SIZE_EXPAND_FILL
	abilities.add_theme_font_size_override("font_size", 20)
	content.add_child(abilities)

	return card


func _make_character_portrait_texture(definition: RefCounted) -> Texture2D:
	var texture: Texture2D = definition.get_texture(&"idle")
	if texture == null:
		return null

	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = Rect2(Vector2.ZERO, Vector2(CHARACTER_FRAME_SIZE))
	return frame


func _ability_text(character_id: StringName) -> String:
	match character_id:
		&"paladin":
			return "Holy Strike\nShockwave\nBlessing"
		&"necromancer":
			return "Soul Beam\nSkeleton Archer\nSoul Surge"
		&"wizard":
			return "Fireball\nFire Laser\nFire Surge"
	return ""


func _select_character(character_id: StringName) -> void:
	selected_character_id = character_id
	for id in cards_by_id.keys():
		var card := cards_by_id[id] as Button
		if card != null:
			card.button_pressed = id == character_id
			card.modulate = Color(1.0, 0.92, 0.62) if id == character_id else Color.WHITE


func _start_game() -> void:
	var session := get_node_or_null("/root/GameSession")
	if session != null and session.has_method("set_selected_character"):
		session.set_selected_character(selected_character_id)
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
