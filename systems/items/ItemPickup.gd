extends Area2D
class_name ItemPickup

@export var item_id: StringName


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if not Engine.has_singleton("ItemDatabase") and get_node_or_null("/root/ItemDatabase") == null:
		push_warning("ItemDatabase autoload is missing.")
		return

	var database := get_node_or_null("/root/ItemDatabase")
	var item: ItemDefinition = database.get_item(item_id) if database != null else null
	if item == null:
		push_warning("Unknown item id: %s" % item_id)
		return

	if body.has_method("add_item"):
		body.add_item(item)
	elif body.has_node("InventoryComponent"):
		body.get_node("InventoryComponent").add_item(item)

	queue_free()
