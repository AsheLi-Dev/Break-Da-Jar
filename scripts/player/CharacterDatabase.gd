extends RefCounted
class_name CharacterDatabase

const CHARACTER_DEFINITION := preload("res://scripts/player/CharacterDefinition.gd")
const PALADIN_TALENT_CATALOG := preload("res://scripts/player/PlayerTalentCatalog.gd")
const NECROMANCER_TALENT_CATALOG := preload("res://scripts/player/NecromancerTalentCatalog.gd")
const WIZARD_TALENT_CATALOG := preload("res://scripts/player/WizardTalentCatalog.gd")


static func get_definition(id: StringName) -> RefCounted:
	match id:
		&"necromancer":
			return _necromancer()
		&"wizard":
			return _wizard()
		_:
			return _paladin()


static func _paladin() -> RefCounted:
	var definition := CHARACTER_DEFINITION.new()
	definition.id = &"paladin"
	definition.display_name = "Paladin"
	definition.talent_catalog = PALADIN_TALENT_CATALOG
	definition.primary_ability = &"paladin_holy_strike"
	definition.secondary_ability = &"paladin_shockwave"
	definition.utility_ability = &"paladin_blessing"
	definition.max_hp = 100.0
	definition.move_speed = 240.0
	definition.base_damage = 12.0
	definition.fire_rate = 1.0
	definition.textures = {
		&"idle": "res://assets/heroes/paladin/idle.png",
		&"run": "res://assets/heroes/paladin/run.png",
		&"attack": "res://assets/heroes/paladin/attack.png",
		&"ability": "res://assets/heroes/paladin/ability.png",
		&"pummel": "res://assets/heroes/paladin/pummel.png",
		&"rolling": "res://assets/heroes/paladin/rolling.png",
		&"slide_start": "res://assets/heroes/paladin/slidestart.png",
		&"slide_hold": "res://assets/heroes/paladin/slidestart.png",
		&"slide_end": "res://assets/heroes/paladin/slideend.png",
		&"damage": "res://assets/heroes/paladin/takedamage.png",
		&"death": "res://assets/heroes/paladin/die.png",
	}
	definition.active_frames = {
		&"primary": 7,
		&"secondary": 9,
		&"utility": 9,
	}
	return definition


static func _necromancer() -> RefCounted:
	var definition := CHARACTER_DEFINITION.new()
	definition.id = &"necromancer"
	definition.display_name = "Necromancer"
	definition.talent_catalog = NECROMANCER_TALENT_CATALOG
	definition.primary_ability = &"necromancer_soul_beam"
	definition.secondary_ability = &"necromancer_skeleton_archer"
	definition.utility_ability = &"necromancer_soul_surge"
	definition.max_hp = 80.0
	definition.move_speed = 240.0
	definition.base_damage = 14.0
	definition.fire_rate = 1.4
	definition.textures = {
		&"idle": "res://assets/heroes/necromancer/idle.png",
		&"run": "res://assets/heroes/necromancer/run.png",
		&"attack": "res://assets/heroes/necromancer/quickshot.png",
		&"ability": "res://assets/heroes/necromancer/castspell.png",
		&"pummel": "res://assets/heroes/necromancer/special1.png",
		&"rolling": "res://assets/heroes/necromancer/rolling.png",
		&"slide_start": "res://assets/heroes/necromancer/slidestart.png",
		&"slide_hold": "res://assets/heroes/necromancer/slidestart.png",
		&"slide_end": "res://assets/heroes/necromancer/slideend.png",
		&"damage": "res://assets/heroes/necromancer/takedamage.png",
		&"death": "res://assets/heroes/necromancer/die.png",
	}
	definition.active_frames = {
		&"primary": 6,
		&"secondary": 7,
		&"utility": 9,
	}
	return definition


static func _wizard() -> RefCounted:
	var definition := CHARACTER_DEFINITION.new()
	definition.id = &"wizard"
	definition.display_name = "Wizard"
	definition.talent_catalog = WIZARD_TALENT_CATALOG
	definition.primary_ability = &"wizard_fireball"
	definition.secondary_ability = &"wizard_fire_laser"
	definition.utility_ability = &"wizard_fire_surge"
	definition.max_hp = 100.0
	definition.move_speed = 240.0
	definition.base_damage = 12.0
	definition.fire_rate = 1.0
	definition.textures = {
		&"idle": "res://assets/heroes/wizard/idle.png",
		&"run": "res://assets/heroes/wizard/run.png",
		&"attack": "res://assets/heroes/wizard/attack1.png",
		&"ability": "res://assets/heroes/wizard/kick.png",
		&"pummel": "res://assets/heroes/wizard/special1.png",
		&"rolling": "res://assets/heroes/wizard/rolling.png",
		&"slide_start": "res://assets/heroes/wizard/slidestart.png",
		&"slide_hold": "res://assets/heroes/wizard/slidestart.png",
		&"slide_end": "res://assets/heroes/wizard/slideend.png",
		&"damage": "res://assets/heroes/wizard/takedamage.png",
		&"death": "res://assets/heroes/wizard/die.png",
	}
	definition.active_frames = {
		&"primary": 7,
		&"secondary": 8,
		&"utility": 5,
	}
	return definition
