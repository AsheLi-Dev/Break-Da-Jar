extends Area2D
class_name BloodClawStrike

const BLOOD_CLAW_TEXTURE_PATH := "res://assets/vfx/blood spell/blood claw.png"
const FRAME_SIZE := Vector2(160.0, 144.0)

@export var animation_fps: float = 14.0
@export var elite_heal_weight: float = 5.0

var owner_player: Node
var damage: float = 12.0
var heal_per_hit: float = 2.4
var elapsed: float = 0.0
var damaged_bodies: Array[Node] = []
var blood_claw_texture: Texture2D


func setup(new_owner: Node, target_position: Vector2, target_direction: Vector2, new_damage: float, new_heal_per_hit: float) -> void:
	owner_player = new_owner
	global_position = target_position
	damage = new_damage
	heal_per_hit = new_heal_per_hit
	_apply_orientation(target_direction)


func _ready() -> void:
	_ensure_nodes()


func _process(delta: float) -> void:
	elapsed += delta
	var frame_index := mini(int(floor(elapsed * animation_fps)), _get_frame_count() - 1)
	if frame_index == 1 or frame_index == 2:
		_apply_damage()
	if frame_index >= _get_frame_count() - 1 and elapsed >= float(_get_frame_count()) / animation_fps:
		queue_free()


func _apply_orientation(target_direction: Vector2) -> void:
	if target_direction.length_squared() <= 0.001:
		target_direction = Vector2.RIGHT
	target_direction = target_direction.normalized()

	var should_flip := target_direction.x < 0.0
	var direction_for_rotation := Vector2(absf(target_direction.x), target_direction.y).normalized()
	var angle := clampf(direction_for_rotation.angle(), -PI * 0.5, PI * 0.5)
	rotation = angle
	scale.x = -1.0 if should_flip else 1.0


func _ensure_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = FRAME_SIZE
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("BloodClawSprite") != null:
		return

	var sprite := AnimatedSprite2D.new()
	sprite.name = "BloodClawSprite"
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = _make_sprite_frames()
	sprite.z_index = 140
	add_child(sprite)
	sprite.play(&"strike")


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var animation_name := &"strike"
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, false)
	frames.set_animation_speed(animation_name, animation_fps)
	var texture := _get_blood_claw_texture()
	if texture == null:
		return frames

	for frame_index in range(_get_frame_count()):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(float(frame_index) * FRAME_SIZE.x, 0.0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(animation_name, frame_texture)
	return frames


func _apply_damage() -> void:
	var heal_weight := 0.0
	for body in get_overlapping_bodies():
		heal_weight += _try_damage_enemy(body)
	for area in get_overlapping_areas():
		heal_weight += _try_damage_enemy(_get_enemy_target(area))

	if heal_weight > 0.0 and owner_player != null and is_instance_valid(owner_player) and owner_player.has_method("heal"):
		owner_player.call("heal", heal_per_hit * heal_weight)


func _try_damage_enemy(enemy: Node) -> float:
	if enemy == null or not enemy.is_in_group("enemy") or damaged_bodies.has(enemy):
		return 0.0
	if not enemy.has_method("take_damage"):
		return 0.0

	damaged_bodies.append(enemy)
	if owner_player != null and is_instance_valid(owner_player) and owner_player.has_method("deal_player_damage_to_enemy"):
		owner_player.deal_player_damage_to_enemy(enemy, damage, {"source": "blood_claw", "direct": true, "allow_procs": false})
	else:
		enemy.call("take_damage", damage)
	return elite_heal_weight if _is_elite_enemy(enemy) else 1.0


func _get_enemy_target(node: Node) -> Node:
	if node.is_in_group("enemy") and node.has_method("take_damage"):
		return node

	var parent := node.get_parent()
	if parent != null and parent.is_in_group("enemy") and parent.has_method("take_damage"):
		return parent

	return null


func _is_elite_enemy(enemy: Node) -> bool:
	var enemy_base := enemy as EnemyBase
	if enemy_base != null:
		return enemy_base.is_elite
	return enemy is EliteBrute


func _get_frame_count() -> int:
	var texture := _get_blood_claw_texture()
	if texture == null:
		return 1
	return maxi(int(texture.get_width() / FRAME_SIZE.x), 1)


func _get_blood_claw_texture() -> Texture2D:
	if blood_claw_texture != null:
		return blood_claw_texture

	var image := Image.load_from_file(BLOOD_CLAW_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load blood claw texture: %s" % BLOOD_CLAW_TEXTURE_PATH)
		return null

	blood_claw_texture = ImageTexture.create_from_image(image)
	return blood_claw_texture
