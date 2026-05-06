extends SceneTree

const MANDATORY_SCENES: Array[String] = [
	"res://battlescene.tscn",
	"res://scenes/test/ItemTestBattle.tscn",
	"res://scenes/enemies/ZombieMelee.tscn",
	"res://scenes/enemies/AcidZombie.tscn",
	"res://scenes/enemies/EliteBrute.tscn",
	"res://scenes/summons/FireDragon.tscn",
	"res://scenes/summons/SmallTurret.tscn",
	"res://scenes/projectiles/Projectile.tscn",
]

var failures: Array[String] = []
var passed_assertions: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("AllScenesLoadTest: starting")
	await process_frame

	var scene_paths: Array[String] = []
	_collect_scene_paths("res://", scene_paths)
	scene_paths.sort()

	for mandatory_scene in MANDATORY_SCENES:
		_assert(scene_paths.has(mandatory_scene), "Mandatory scene is covered: %s" % mandatory_scene)

	for scene_path in scene_paths:
		await _load_and_enter_scene(scene_path)

	await _drain_frames(8)
	await _finish()


func _collect_scene_paths(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		_fail("Cannot open directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == ".." or file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var child_path := path.path_join(file_name)
		if dir.current_is_dir():
			_collect_scene_paths(child_path, result)
		elif file_name.ends_with(".tscn"):
			result.append(child_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_and_enter_scene(scene_path: String) -> void:
	var scene := load(scene_path) as PackedScene
	_assert(scene != null, "Scene loads: %s" % scene_path)
	if scene == null:
		return

	var instance := scene.instantiate()
	_assert(instance != null, "Scene instantiates: %s" % scene_path)
	if instance == null:
		return

	root.add_child(instance)
	current_scene = instance
	await process_frame
	await _cleanup_instance(instance)


func _cleanup_instance(instance: Variant) -> void:
	current_scene = null
	if is_instance_valid(instance):
		if instance.get_parent() != null:
			instance.get_parent().remove_child(instance)
		instance.queue_free()
	await _drain_frames(8)


func _drain_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		passed_assertions += 1
	else:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)
	push_error("FAIL: %s" % message)


func _finish() -> void:
	if failures.is_empty():
		print("AllScenesLoadTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("AllScenesLoadTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
