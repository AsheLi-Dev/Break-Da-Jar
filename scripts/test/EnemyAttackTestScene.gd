extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const MELEE_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/ZombieMelee.tscn")
const ACID_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/AcidZombie.tscn")
const ZOMBIE_FIREMAN_SCENE: PackedScene = preload("res://scenes/enemies/ZombieFireman.tscn")
const ELITE_BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/EliteBrute.tscn")
const ELITE_ACID_ZOMBIE_SCENE: PackedScene = preload("res://scenes/enemies/EliteAcidZombie.tscn")
const UNDEAD_DARK_KNIGHT_SCENE: PackedScene = preload("res://scenes/enemies/UndeadDarkKnight.tscn")

const DUMMY_POSITION := Vector2(520.0, 360.0)

var enemy_options: Array[Dictionary] = [
	{"label": "Zombie Melee", "scene": MELEE_ZOMBIE_SCENE, "attacks": ["Attack"]},
	{"label": "Acid Zombie", "scene": ACID_ZOMBIE_SCENE, "attacks": ["Acid Shot"]},
	{"label": "Zombie Fireman", "scene": ZOMBIE_FIREMAN_SCENE, "attacks": ["Axe Throw"]},
	{"label": "Elite Brute", "scene": ELITE_BRUTE_SCENE, "attacks": ["Melee Slam", "Bone Barrage", "Shout"]},
	{"label": "Elite Acid Zombie", "scene": ELITE_ACID_ZOMBIE_SCENE, "attacks": ["Acid Throw", "Ground Slam", "Mutate Minion"]},
	{"label": "Undead Dark Knight", "scene": UNDEAD_DARK_KNIGHT_SCENE, "attacks": ["Leap Slam"]},
]

var current_enemy: EnemyBase
var dummy_player: Player
var enemy_select: OptionButton
var attack_select: OptionButton
var status_label: Label


func _ready() -> void:
	_create_background()
	_create_dummy_player()
	_create_ui()
	_spawn_selected_enemy()


func _process(_delta: float) -> void:
	if is_instance_valid(dummy_player):
		dummy_player.hp = dummy_player.max_hp


func _create_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.13, 0.15, 0.14)
	background.size = Vector2(1152.0, 648.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var marker := Polygon2D.new()
	marker.name = "DummyMarker"
	marker.color = Color(0.22, 0.32, 0.28, 0.8)
	marker.polygon = PackedVector2Array([
		Vector2(-34.0, -34.0),
		Vector2(34.0, -34.0),
		Vector2(34.0, 34.0),
		Vector2(-34.0, 34.0),
	])
	marker.global_position = DUMMY_POSITION
	add_child(marker)


func _create_dummy_player() -> void:
	dummy_player = PLAYER_SCENE.instantiate() as Player
	dummy_player.name = "InfiniteHealthDummy"
	dummy_player.global_position = DUMMY_POSITION
	dummy_player.max_hp = 999999.0
	dummy_player.hp = dummy_player.max_hp
	dummy_player.move_speed = 0.0
	dummy_player.projectile_damage = 0.0
	add_child(dummy_player)


func _create_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	var panel := PanelContainer.new()
	panel.name = "Controls"
	panel.position = Vector2(24.0, 24.0)
	panel.custom_minimum_size = Vector2(300.0, 180.0)
	ui.add_child(panel)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	panel.add_child(rows)

	var enemy_label := Label.new()
	enemy_label.text = "Enemy"
	rows.add_child(enemy_label)

	enemy_select = OptionButton.new()
	for index in range(enemy_options.size()):
		enemy_select.add_item(String(enemy_options[index]["label"]), index)
	enemy_select.item_selected.connect(_on_enemy_selected)
	rows.add_child(enemy_select)

	var attack_label := Label.new()
	attack_label.text = "Attack"
	rows.add_child(attack_label)

	attack_select = OptionButton.new()
	rows.add_child(attack_select)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	rows.add_child(buttons)

	var release_button := Button.new()
	release_button.text = "Release Attack"
	release_button.pressed.connect(_release_selected_attack)
	buttons.add_child(release_button)

	var reset_button := Button.new()
	reset_button.text = "Reset Enemy"
	reset_button.pressed.connect(_spawn_selected_enemy)
	buttons.add_child(reset_button)

	status_label = Label.new()
	status_label.text = ""
	rows.add_child(status_label)
	_refresh_attack_options()


func _on_enemy_selected(_index: int) -> void:
	_refresh_attack_options()
	_spawn_selected_enemy()


func _refresh_attack_options() -> void:
	attack_select.clear()
	var enemy_data: Dictionary = enemy_options[enemy_select.selected]
	var attacks: Array = enemy_data["attacks"]
	for index in range(attacks.size()):
		attack_select.add_item(String(attacks[index]), index)


func _spawn_selected_enemy() -> void:
	if is_instance_valid(current_enemy):
		current_enemy.queue_free()

	var enemy_data: Dictionary = enemy_options[enemy_select.selected]
	var enemy_scene := enemy_data["scene"] as PackedScene
	current_enemy = enemy_scene.instantiate() as EnemyBase
	current_enemy.name = "AttackTestEnemy"
	current_enemy.global_position = _get_enemy_spawn_position()
	current_enemy.move_speed = 0.0
	current_enemy.attack_cooldown = 9999.0
	current_enemy.target = dummy_player
	add_child(current_enemy)
	_face_enemy_to_dummy()
	status_label.text = "Ready: %s" % enemy_data["label"]


func _release_selected_attack() -> void:
	if not is_instance_valid(current_enemy):
		return

	_reset_enemy_for_attack()
	var attack_name: String = attack_select.get_item_text(attack_select.selected)
	match attack_name:
		"Attack":
			current_enemy.call("_start_attack")
		"Acid Shot":
			current_enemy.call("_start_aim")
		"Axe Throw":
			current_enemy.call("_start_aim")
		"Melee Slam":
			current_enemy.call("_start_melee_attack")
		"Bone Barrage":
			current_enemy.call("_start_ranged_attack")
		"Shout":
			current_enemy.call("_start_shout_attack")
		"Acid Throw":
			current_enemy.call("_start_ranged_attack")
		"Ground Slam":
			current_enemy.call("_start_melee_attack")
		"Mutate Minion":
			_ensure_mutation_minion()
			current_enemy.call("_start_shout_attack")
		"Leap Slam":
			current_enemy.call("_start_leap_slam")

	status_label.text = "Released: %s" % attack_name


func _reset_enemy_for_attack() -> void:
	current_enemy.global_position = _get_enemy_spawn_position()
	current_enemy.velocity = Vector2.ZERO
	current_enemy.target = dummy_player
	_face_enemy_to_dummy()
	current_enemy.set("cooldown_remaining", 9999.0)


func _face_enemy_to_dummy() -> void:
	if current_enemy == null:
		return

	if current_enemy.has_method("_face_target"):
		current_enemy.call("_face_target", DUMMY_POSITION)
	elif current_enemy.has_method("_face_target_for_attack"):
		current_enemy.call("_face_target_for_attack", DUMMY_POSITION)
	elif current_enemy.has_method("face_position"):
		current_enemy.call("face_position", DUMMY_POSITION)


func _get_enemy_spawn_position() -> Vector2:
	var attack_name := ""
	if attack_select != null and attack_select.item_count > 0:
		attack_name = attack_select.get_item_text(attack_select.selected)

	match attack_name:
		"Attack":
			return DUMMY_POSITION + Vector2(96.0, 0.0)
		"Melee Slam":
			return DUMMY_POSITION + Vector2(120.0, 0.0)
		"Shout":
			return DUMMY_POSITION + Vector2(220.0, 0.0)
		"Acid Shot", "Axe Throw", "Bone Barrage", "Acid Throw":
			return DUMMY_POSITION + Vector2(300.0, 0.0)
		"Ground Slam":
			return DUMMY_POSITION + Vector2(145.0, 0.0)
		"Mutate Minion":
			return DUMMY_POSITION + Vector2(260.0, 0.0)
		"Leap Slam":
			return DUMMY_POSITION + Vector2(230.0, 0.0)

	return DUMMY_POSITION + Vector2(180.0, 0.0)


func _ensure_mutation_minion() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy != current_enemy and enemy is ZombieMelee:
			return

	var minion := MELEE_ZOMBIE_SCENE.instantiate() as ZombieMelee
	minion.name = "MutationTarget"
	minion.global_position = DUMMY_POSITION + Vector2(110.0, 120.0)
	minion.target = dummy_player
	add_child(minion)
