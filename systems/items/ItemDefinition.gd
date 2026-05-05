extends Resource
class_name ItemDefinition

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: StringName = &"utility"
@export var rarity: StringName = &"common"
@export var tags: Array[StringName] = []
@export var icon: Texture2D
@export var effects: Array[Resource] = []
