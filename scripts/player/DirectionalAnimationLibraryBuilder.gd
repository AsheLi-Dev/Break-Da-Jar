extends RefCounted
class_name DirectionalAnimationLibraryBuilder


static func build_library(
	animation_player: AnimationPlayer,
	animation_bases: Array[StringName],
	direction_count: int,
	frame_size: Vector2i,
	texture_provider: Callable,
	length_provider: Callable,
	loop_mode_provider: Callable,
	frame_count_provider: Callable,
	frame_column_provider: Callable,
	frame_duration_provider: Callable
) -> void:
	if animation_player.has_animation_library(""):
		animation_player.remove_animation_library("")

	var library := AnimationLibrary.new()
	for animation_base in animation_bases:
		for row in range(direction_count):
			var animation_name: String = "%s_%d" % [String(animation_base), row]
			library.add_animation(
				animation_name,
				_create_direction_animation(
					animation_base,
					row,
					frame_size,
					texture_provider,
					length_provider,
					loop_mode_provider,
					frame_count_provider,
					frame_column_provider,
					frame_duration_provider
				)
			)

	animation_player.add_animation_library("", library)


static func build_state_machine(
	animation_tree: AnimationTree,
	animation_bases: Array[StringName],
	direction_count: int
) -> void:
	var state_machine := AnimationNodeStateMachine.new()
	for animation_base in animation_bases:
		for row in range(direction_count):
			var animation_name: String = "%s_%d" % [String(animation_base), row]
			var animation_node := AnimationNodeAnimation.new()
			animation_node.animation = animation_name
			state_machine.add_node(animation_name, animation_node)

	animation_tree.tree_root = state_machine


static func _create_direction_animation(
	animation_base: StringName,
	row: int,
	frame_size: Vector2i,
	texture_provider: Callable,
	length_provider: Callable,
	loop_mode_provider: Callable,
	frame_count_provider: Callable,
	frame_column_provider: Callable,
	frame_duration_provider: Callable
) -> Animation:
	var animation := Animation.new()
	animation.length = float(length_provider.call(animation_base))
	animation.loop_mode = loop_mode_provider.call(animation_base)

	var texture_track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(texture_track, NodePath("Sprite2D:texture"))
	animation.track_set_interpolation_type(texture_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(texture_track, Animation.UPDATE_DISCRETE)
	animation.track_insert_key(texture_track, 0.0, texture_provider.call(animation_base))

	var region_track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(region_track, NodePath("Sprite2D:region_rect"))
	animation.track_set_interpolation_type(region_track, Animation.INTERPOLATION_NEAREST)
	animation.value_track_set_update_mode(region_track, Animation.UPDATE_DISCRETE)

	var time: float = 0.0
	var frame_count: int = int(frame_count_provider.call(animation_base))
	for frame in range(frame_count):
		var frame_column: int = int(frame_column_provider.call(animation_base, frame))
		var region := Rect2(
			Vector2(frame_column * frame_size.x, row * frame_size.y),
			Vector2(frame_size)
		)
		animation.track_insert_key(region_track, time, region)
		time += float(frame_duration_provider.call(animation_base, frame))

	return animation
