extends Area2D
class_name FireballProjectile

const FIREBALL_TEXTURE_PATH := "res://assets/vfx/fire spell/Fireball(throw).png"
const FIREBALL_FRAME_SIZE := Vector2(100.0, 100.0)
const FIREBALL_COLUMNS := 6
const FIREBALL_ROWS := 5
const FIREBALL_EXPLOSION_TEXTURE_PATH := "res://assets/vfx/fire spell/fire explosion.png"
const FIREBALL_EXPLOSION_FRAME_SIZE := Vector2(64.0, 64.0)

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 520.0
@export var damage: float = 12.0
@export var lifetime: float = 1.5
@export var explosion_radius: float = 80.0
@export var target_group: StringName = &"enemy"
@export var damages_containers: bool = true
@export var debug_color: Color = Color(1.0, 0.35, 0.08)
@export var fireball_animation_fps: float = 24.0
@export var fireball_visual_scale: float = 1.0
@export var explosion_animation_fps: float = 18.0
@export var explosion_visual_radius_scale: float = 0.85

var owner_player: Node
var age: float = 0.0
var exploded: bool = false
var fireball_texture: Texture2D
var explosion_texture: Texture2D


func setup(new_owner: Node, new_position: Vector2, new_direction: Vector2, new_damage: float, new_radius: float) -> void:
	owner_player = new_owner
	global_position = new_position
	direction = new_direction.normalized()
	damage = new_damage
	explosion_radius = new_radius
	rotation = direction.angle()


func _ready() -> void:
	_ensure_nodes()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	age += delta
	if age >= lifetime:
		explode()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) or _is_wall_body(body):
		explode()


func explode() -> void:
	if exploded:
		return

	exploded = true
	print("Fireball explodes")
	_spawn_explosion_vfx()
	var poison_stacks: int = 0
	if owner_player != null and owner_player.has_method("get_stats"):
		var stats: StatsComponent = owner_player.get_stats()
		if stats != null:
			poison_stacks = stats.fireball_poison_stacks

	for enemy in get_tree().get_nodes_in_group("enemy"):
		var enemy_2d := enemy as Node2D
		if enemy_2d == null or enemy_2d.global_position.distance_to(global_position) > explosion_radius:
			continue
		if owner_player != null and owner_player.has_method("deal_player_damage_to_enemy"):
			owner_player.deal_player_damage_to_enemy(enemy, damage, {"source": "fireball", "direct": true, "allow_procs": false})
		elif enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		if poison_stacks > 0 and enemy.has_method("apply_poison_stacks"):
			enemy.apply_poison_stacks(poison_stacks, owner_player)

	if damages_containers:
		for container in get_tree().get_nodes_in_group("container"):
			var container_2d := container as Node2D
			if container_2d == null or container_2d.global_position.distance_to(global_position) > explosion_radius:
				continue
			if container is BreakableContainer and container.is_shop_container:
				continue
			if container.has_method("take_damage"):
				container.take_damage(damage, {"source": "fireball", "owner": owner_player})

	queue_free()


func _is_wall_body(body: Node) -> bool:
	return body is StaticBody2D or body is TileMap or body is TileMapLayer or body.is_in_group("wall") or body.is_in_group("walls")


func _ensure_nodes() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 8.0
		collision.shape = shape
		add_child(collision)

	if get_node_or_null("FireballVFX") == null and _add_fireball_vfx():
		var debug_body := get_node_or_null("DebugBody")
		if debug_body != null:
			debug_body.queue_free()
		return

	if get_node_or_null("DebugBody") == null:
		var body := Polygon2D.new()
		body.name = "DebugBody"
		body.color = debug_color
		body.polygon = PackedVector2Array([
			Vector2(14.0, 0.0),
			Vector2(-8.0, -8.0),
			Vector2(-4.0, 0.0),
			Vector2(-8.0, 8.0),
		])
		add_child(body)


func _add_fireball_vfx() -> bool:
	var texture: Texture2D = _get_fireball_texture()
	if texture == null:
		return false

	var sprite_frames := SpriteFrames.new()
	var animation_name := &"fly"
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, fireball_animation_fps)

	for row in range(FIREBALL_ROWS):
		for column in range(FIREBALL_COLUMNS):
			var frame_texture := AtlasTexture.new()
			frame_texture.atlas = texture
			frame_texture.region = Rect2(
				float(column) * FIREBALL_FRAME_SIZE.x,
				float(row) * FIREBALL_FRAME_SIZE.y,
				FIREBALL_FRAME_SIZE.x,
				FIREBALL_FRAME_SIZE.y
			)
			sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.name = "FireballVFX"
	effect.sprite_frames = sprite_frames
	effect.scale = Vector2.ONE * fireball_visual_scale
	effect.z_index = 120
	add_child(effect)
	effect.play(animation_name)
	return true


func _get_fireball_texture() -> Texture2D:
	if fireball_texture != null:
		return fireball_texture

	var image := Image.load_from_file(FIREBALL_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load fireball texture: %s" % FIREBALL_TEXTURE_PATH)
		return null

	fireball_texture = ImageTexture.create_from_image(image)
	return fireball_texture


func _spawn_explosion_vfx() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var texture: Texture2D = _get_explosion_texture()
	if texture == null:
		return

	var sprite_frames := SpriteFrames.new()
	var animation_name := &"explode"
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, false)
	sprite_frames.set_animation_speed(animation_name, explosion_animation_fps)

	var frame_count: int = int(texture.get_width() / FIREBALL_EXPLOSION_FRAME_SIZE.x)
	for frame_index in range(frame_count):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = texture
		frame_texture.region = Rect2(
			float(frame_index) * FIREBALL_EXPLOSION_FRAME_SIZE.x,
			0.0,
			FIREBALL_EXPLOSION_FRAME_SIZE.x,
			FIREBALL_EXPLOSION_FRAME_SIZE.y
		)
		sprite_frames.add_frame(animation_name, frame_texture)

	var effect := AnimatedSprite2D.new()
	effect.name = "FireballExplosionVFX"
	effect.sprite_frames = sprite_frames
	var diameter: float = explosion_radius * 2.0 * explosion_visual_radius_scale
	effect.scale = Vector2.ONE * (diameter / FIREBALL_EXPLOSION_FRAME_SIZE.x)
	effect.z_index = 130
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position
	effect.play(animation_name)
	effect.animation_finished.connect(Callable(effect, "queue_free"))


func _get_explosion_texture() -> Texture2D:
	if explosion_texture != null:
		return explosion_texture

	var image := Image.load_from_file(FIREBALL_EXPLOSION_TEXTURE_PATH)
	if image == null or image.is_empty():
		push_warning("Failed to load fireball explosion texture: %s" % FIREBALL_EXPLOSION_TEXTURE_PATH)
		return null

	explosion_texture = ImageTexture.create_from_image(image)
	return explosion_texture
