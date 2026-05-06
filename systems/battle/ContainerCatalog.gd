extends RefCounted
class_name ContainerCatalog

const URN := 0
const BARREL := 1
const TOMB := 2

const URN_MAX_HP := 12.0
const BARREL_MAX_HP := 24.0
const TOMB_MAX_HP := 48.0

const URN_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-main-static-00.png")
const URN_DAMAGED_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-crack-00.png")
const URN_HIT_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-crack-hit-00.png")
const URN_DESTROYED_TEXTURE: Texture2D = preload("res://assets/containers/Urn G/urn-G-static-destroyed-00.png")
const BARREL_TEXTURE: Texture2D = preload("res://assets/containers/Barrel B/barrel-B-main-static-00.png")
const BARREL_HIT_TEXTURE: Texture2D = preload("res://assets/containers/Barrel B/barrel-B-hit-00.png")
const BARREL_DESTROYED_TEXTURE: Texture2D = preload("res://assets/containers/Barrel B/barrel-B-static-destroyed-00.png")
const TOMB_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-main-static-00.png")
const TOMB_DAMAGED_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-crack-1-00.png")
const TOMB_HIT_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-main-hit-00.png")
const TOMB_DESTROYED_TEXTURE: Texture2D = preload("res://assets/containers/Tomb A/tomb-A-static-destroyed-00.png")


static func texture(type: int) -> Texture2D:
	match type:
		BARREL:
			return BARREL_TEXTURE
		TOMB:
			return TOMB_TEXTURE
		_:
			return URN_TEXTURE


static func damaged_texture(type: int) -> Texture2D:
	match type:
		TOMB:
			return TOMB_DAMAGED_TEXTURE
		URN:
			return URN_DAMAGED_TEXTURE
		_:
			return null


static func hit_texture(type: int) -> Texture2D:
	match type:
		BARREL:
			return BARREL_HIT_TEXTURE
		TOMB:
			return TOMB_HIT_TEXTURE
		_:
			return URN_HIT_TEXTURE


static func destroyed_texture(type: int) -> Texture2D:
	match type:
		BARREL:
			return BARREL_DESTROYED_TEXTURE
		TOMB:
			return TOMB_DESTROYED_TEXTURE
		_:
			return URN_DESTROYED_TEXTURE


static func destroy_frames(type: int) -> Array[Texture2D]:
	match type:
		BARREL:
			return [
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-01.png"),
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-02.png"),
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-03.png"),
				preload("res://assets/containers/Barrel B/barrel-B-destr-anim-04.png"),
			]
		TOMB:
			return [
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-01.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-02.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-03.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-04.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-05.png"),
				preload("res://assets/containers/Tomb A/tomb-A-destr-anim-06.png"),
			]
		_:
			return [
				preload("res://assets/containers/Urn G/urn-G-destr-anim-01.png"),
				preload("res://assets/containers/Urn G/urn-G-destr-anim-02.png"),
				preload("res://assets/containers/Urn G/urn-G-destr-anim-03.png"),
				preload("res://assets/containers/Urn G/urn-G-destr-anim-04.png"),
			]


static func max_hp(type: int) -> float:
	match type:
		BARREL:
			return BARREL_MAX_HP
		TOMB:
			return TOMB_MAX_HP
		_:
			return URN_MAX_HP


static func type_name(type: int) -> String:
	match type:
		BARREL:
			return "Barrel"
		TOMB:
			return "Tomb"
		_:
			return "Urn"


static func roll_combat_type() -> int:
	var roll: float = randf()
	if roll < 0.7:
		return URN
	if roll < 0.95:
		return BARREL
	return TOMB


static func roll_small_combat_type() -> int:
	if randf() < 0.7 / 0.95:
		return URN
	return BARREL
