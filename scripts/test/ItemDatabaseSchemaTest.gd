extends SceneTree

const EFFECT_TYPES := preload("res://systems/items/effects/ItemEffectTypes.gd")
const PERMANENT_GROWTH_EFFECT_SCRIPT := preload("res://systems/items/effects/PermanentGrowthEffect.gd")
const PERIODIC_EFFECT_SCRIPT := preload("res://systems/items/effects/PeriodicEffect.gd")
const TRIGGERED_BUFF_EFFECT_SCRIPT := preload("res://systems/items/effects/TriggeredBuffEffect.gd")

const ITEM_ROOT := "res://data/items"
const VALID_CATEGORIES: Array[StringName] = [
	&"attack",
	&"defense",
	&"utility",
]
const VALID_RARITIES: Array[StringName] = [
	&"common",
	&"rare",
	&"legendary",
]
const VALID_STAT_OPERATIONS: Array[StringName] = [
	&"add",
	&"set",
	&"multiply",
	&"multiply_add",
	&"set_or_add_one",
]
const EVENTLESS_EFFECT_TYPES: Array[StringName] = [
	EFFECT_TYPES.SHOP_PRICE_MULTIPLIER,
	EFFECT_TYPES.QUEUE_EXTRA_RARE_SHOP_JAR,
	EFFECT_TYPES.FIRST_COPY_STAT_BONUS,
]

var failures: Array[String] = []
var passed_assertions: int = 0
var known_effect_types: Dictionary = {}
var item_database: Node
var stats_probe := StatsComponent.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("ItemDatabaseSchemaTest: starting")
	await process_frame

	known_effect_types = _collect_known_effect_types()
	item_database = root.get_node_or_null("ItemDatabase")
	_assert(item_database != null, "ItemDatabase autoload exists")

	var item_paths: Array[String] = []
	_collect_item_paths(ITEM_ROOT, item_paths)
	item_paths.sort()
	_assert(not item_paths.is_empty(), "Item resources exist under %s" % ITEM_ROOT)

	var seen_ids: Dictionary = {}
	for item_path in item_paths:
		_validate_item_resource(item_path, seen_ids)

	if item_database != null:
		var all_items: Array = item_database.get("all_items")
		_assert(all_items.size() == item_paths.size(), "ItemDatabase loaded every item resource")

	_finish()


func _collect_known_effect_types() -> Dictionary:
	var result: Dictionary = {}
	for value in EFFECT_TYPES.all():
		result[value] = true
	return result


func _collect_item_paths(path: String, result: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		_fail("Cannot open item directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue

		var child_path := path.path_join(file_name)
		if dir.current_is_dir():
			_collect_item_paths(child_path, result)
		elif file_name.ends_with(".tres"):
			result.append(child_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _validate_item_resource(item_path: String, seen_ids: Dictionary) -> void:
	_assert(ResourceLoader.exists(item_path), "Item resource path exists: %s" % item_path)
	var item := load(item_path) as ItemDefinition
	_assert(item != null, "Item resource loads as ItemDefinition: %s" % item_path)
	if item == null:
		return

	_assert(item.id != &"", "Item id is set: %s" % item_path)
	_assert(not seen_ids.has(item.id), "Item id is unique: %s" % item.id)
	seen_ids[item.id] = item_path

	_assert(not item.display_name.strip_edges().is_empty(), "Item display name is set: %s" % item.id)
	_assert(not item.description.strip_edges().is_empty(), "Item description is set: %s" % item.id)
	_assert(VALID_CATEGORIES.has(item.category), "Item category is valid: %s" % item.id)
	_assert(VALID_RARITIES.has(item.rarity), "Item rarity is valid: %s" % item.id)
	_assert(not item.effects.is_empty(), "Item has at least one effect: %s" % item.id)

	if item.icon != null and item.icon.resource_path != "":
		_assert(ResourceLoader.exists(item.icon.resource_path), "Item icon path exists: %s" % item.id)

	if item_database != null:
		_assert(item_database.get_item(item.id) != null, "ItemDatabase can resolve item id: %s" % item.id)

	for index in range(item.effects.size()):
		_validate_effect(item, item.effects[index], index)


func _validate_effect(item: ItemDefinition, effect: Resource, index: int) -> void:
	var label := "%s effect[%d]" % [item.id, index]
	_assert(effect != null, "Effect resource is set: %s" % label)
	if effect == null:
		return

	_assert(effect is ItemEffect, "Effect extends ItemEffect: %s" % label)
	_assert(StringName(effect.get("stacking_rule")) != &"", "Effect stacking_rule is set: %s" % label)

	if effect is EventEffect:
		_validate_event_effect(item, effect as EventEffect, label)
	elif effect.get_script() == PERMANENT_GROWTH_EFFECT_SCRIPT:
		_validate_permanent_growth_effect(effect, label)
	elif effect.get_script() == PERIODIC_EFFECT_SCRIPT:
		_validate_periodic_effect(effect, label)
	elif effect.get_script() == TRIGGERED_BUFF_EFFECT_SCRIPT:
		_validate_triggered_buff_effect(effect, label)
	elif effect is StatModifierEffect:
		_validate_stat_modifier_effect(effect as StatModifierEffect, label)


func _validate_event_effect(item: ItemDefinition, effect: EventEffect, label: String) -> void:
	_assert(effect.effect_type != &"", "Event effect_type is set: %s" % label)
	_assert(known_effect_types.has(effect.effect_type), "Event effect_type is defined in ItemEffectTypes: %s -> %s" % [label, effect.effect_type])

	if _requires_event_name(effect.effect_type):
		_assert(effect.event_name != &"", "Event effect_name is set when required: %s" % label)

	if effect.stat_name != &"":
		_assert(_is_known_stat(effect.stat_name), "Event stat_name is known: %s -> %s" % [label, effect.stat_name])

	_assert(effect.max_stacks >= 1, "Event max_stacks is positive: %s" % label)
	_assert(effect.radius >= 0.0, "Event radius is non-negative: %s" % label)
	_assert(effect.duration >= 0.0, "Event duration is non-negative: %s" % label)
	_assert(effect.damage_scale >= 0.0, "Event damage_scale is non-negative: %s" % label)
	_assert(effect.chain_count >= 0, "Event chain_count is non-negative: %s" % label)
	_assert(effect.internal_cooldown >= 0.0, "Event internal_cooldown is non-negative: %s" % label)
	_assert(effect.poison_stacks >= 0, "Event poison_stacks is non-negative: %s" % label)
	_assert(effect.chance >= 0.0 and effect.chance <= 1.0, "Event chance is 0..1: %s" % label)

	for choice in effect.choices:
		if effect.effect_type == EFFECT_TYPES.CONTAINER_BREAK_RANDOM_PROC:
			_assert(known_effect_types.has(choice), "Event choice effect_type exists: %s -> %s" % [label, choice])
		else:
			_assert(item_database == null or item_database.get_item(choice) != null, "Event choice item id exists: %s -> %s" % [label, choice])


func _validate_stat_modifier_effect(effect: StatModifierEffect, label: String) -> void:
	_assert(effect.stat_name != &"", "Stat effect stat_name is set: %s" % label)
	_assert(_is_known_stat(effect.stat_name), "Stat effect stat_name is known: %s -> %s" % [label, effect.stat_name])
	_assert(VALID_STAT_OPERATIONS.has(effect.operation), "Stat effect operation is valid: %s -> %s" % [label, effect.operation])


func _validate_permanent_growth_effect(effect: Resource, label: String) -> void:
	var trigger := StringName(effect.get("trigger"))
	var growth_stat := StringName(effect.get("growth_stat"))
	_assert(trigger != &"", "Permanent growth trigger is set: %s" % label)
	_assert(_is_valid_permanent_growth_trigger(trigger), "Permanent growth trigger is valid: %s -> %s" % [label, trigger])
	_assert(growth_stat != &"", "Permanent growth stat is set: %s" % label)
	_assert(_is_known_stat(growth_stat), "Permanent growth stat is known: %s -> %s" % [label, growth_stat])
	_assert(float(effect.get("growth_value")) > 0.0, "Permanent growth value is positive: %s" % label)
	_assert(float(effect.get("trigger_value")) > 0.0, "Permanent growth trigger value is positive: %s" % label)
	_assert(float(effect.get("round_cap")) >= 0.0, "Permanent growth round cap is non-negative: %s" % label)
	_assert(float(effect.get("stack_round_cap_bonus")) >= 0.0, "Permanent growth stack round cap bonus is non-negative: %s" % label)
	_assert(float(effect.get("stack_growth_bonus")) >= 0.0, "Permanent growth stack growth bonus is non-negative: %s" % label)
	_assert(not (bool(effect.get("requires_critical")) and bool(effect.get("requires_non_critical"))), "Permanent growth crit filters do not conflict: %s" % label)


func _validate_periodic_effect(effect: Resource, label: String) -> void:
	var mode := StringName(effect.get("mode"))
	var stat_name := StringName(effect.get("stat_name"))
	_assert(mode != &"", "Periodic mode is set: %s" % label)
	_assert(PERIODIC_EFFECT_SCRIPT.all_modes().has(mode), "Periodic mode is valid: %s -> %s" % [label, mode])
	if stat_name != &"":
		_assert(_is_known_stat(stat_name), "Periodic stat_name is known: %s -> %s" % [label, stat_name])
	_assert(int(effect.get("max_stacks")) >= 1, "Periodic max_stacks is positive: %s" % label)
	_assert(float(effect.get("radius")) >= 0.0, "Periodic radius is non-negative: %s" % label)
	_assert(float(effect.get("duration")) >= 0.0, "Periodic duration is non-negative: %s" % label)
	_assert(float(effect.get("damage_scale")) >= 0.0, "Periodic damage_scale is non-negative: %s" % label)
	_assert(float(effect.get("interval")) >= 0.0, "Periodic interval is non-negative: %s" % label)
	_assert(float(effect.get("chance")) >= 0.0, "Periodic chance is non-negative: %s" % label)


func _validate_triggered_buff_effect(effect: Resource, label: String) -> void:
	var event_name := StringName(effect.get("event_name"))
	var mode := StringName(effect.get("mode"))
	var stat_name := StringName(effect.get("stat_name"))
	_assert(event_name != &"", "Triggered buff event_name is set: %s" % label)
	_assert(mode != &"", "Triggered buff mode is set: %s" % label)
	_assert(TRIGGERED_BUFF_EFFECT_SCRIPT.all_modes().has(mode), "Triggered buff mode is valid: %s -> %s" % [label, mode])
	_assert(stat_name != &"", "Triggered buff stat_name is set: %s" % label)
	_assert(_is_known_stat(stat_name), "Triggered buff stat_name is known: %s -> %s" % [label, stat_name])
	_assert(int(effect.get("max_stacks")) >= 1, "Triggered buff max_stacks is positive: %s" % label)
	_assert(float(effect.get("duration")) >= 0.0, "Triggered buff duration is non-negative: %s" % label)
	_assert(float(effect.get("missing_hp_step")) > 0.0, "Triggered buff missing_hp_step is positive: %s" % label)
	_assert(float(effect.get("stack_value_bonus")) >= 0.0, "Triggered buff stack_value_bonus is non-negative: %s" % label)


func _requires_event_name(effect_type: StringName) -> bool:
	return not EVENTLESS_EFFECT_TYPES.has(effect_type)


func _is_valid_permanent_growth_trigger(trigger: StringName) -> bool:
	return [
		&"enemy_killed",
		&"container_broken",
		&"damage_taken",
		&"shop_container_broken",
		&"round_started",
		&"round_ended",
		&"stationary",
	].has(trigger)


func _is_known_stat(stat_name: StringName) -> bool:
	return stats_probe.get(String(stat_name)) != null


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
		print("ItemDatabaseSchemaTest: PASS (%d assertions)" % passed_assertions)
		quit(0)
		return

	print("ItemDatabaseSchemaTest: FAIL (%d failures)" % failures.size())
	for failure in failures:
		print("- %s" % failure)
	quit(1)
