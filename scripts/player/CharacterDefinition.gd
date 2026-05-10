extends RefCounted
class_name CharacterDefinition

var id: StringName
var display_name: String
var talent_catalog: GDScript
var primary_ability: StringName = &"paladin_holy_strike"
var secondary_ability: StringName = &"paladin_shockwave"
var utility_ability: StringName = &"paladin_blessing"
var max_hp: float = 100.0
var move_speed: float = 240.0
var base_damage: float = 12.0
var fire_rate: float = 1.0
var textures: Dictionary = {}
var active_frames: Dictionary = {}


func get_texture(animation_name: StringName) -> Texture2D:
	var path: String = String(textures.get(animation_name, ""))
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D

	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func get_active_frame(action_name: StringName, fallback: int) -> int:
	return int(active_frames.get(action_name, fallback))
