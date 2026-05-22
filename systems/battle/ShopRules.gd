extends RefCounted
class_name ShopRules

const BROWN := 0
const ATTACK := 1
const DEFENSE := 2
const UTILITY := 3
const WHITE := 4

const COMMON := 0
const RARE := 1
const LEGENDARY := 2


static func roll_category() -> int:
	if randf() < 0.7:
		return BROWN

	var categories: Array[int] = [
		ATTACK,
		DEFENSE,
		UTILITY,
		WHITE,
	]
	return categories.pick_random()


static func roll_tier() -> int:
	var roll: float = randf()
	if roll < 0.89:
		return COMMON
	if roll < 0.99:
		return RARE
	return LEGENDARY


static func rarity_for_tier(tier: int) -> StringName:
	var roll: float = randf()
	match tier:
		RARE:
			return &"rare" if roll < 0.95 else &"legendary"
		LEGENDARY:
			return &"legendary"
		_:
			if roll < 0.89:
				return &"common"
			if roll < 0.99:
				return &"rare"
			return &"legendary"


static func category_filter(category: int) -> StringName:
	match category:
		ATTACK:
			return &"attack"
		DEFENSE:
			return &"defense"
		UTILITY:
			return &"utility"
		_:
			return &""


static func category_color(category: int) -> Color:
	match category:
		ATTACK:
			return Color(1.0, 0.38, 0.32)
		DEFENSE:
			return Color(0.38, 1.0, 0.48)
		UTILITY:
			return Color(0.42, 0.68, 1.0)
		WHITE:
			return Color(1.0, 1.0, 1.0, 0.52)
		_:
			return Color(0.74, 0.52, 0.34)


static func category_label(category: int) -> String:
	match category:
		ATTACK:
			return "Red"
		DEFENSE:
			return "Green"
		UTILITY:
			return "Blue"
		WHITE:
			return "White"
		_:
			return "Brown"


static func tier_label(tier: int) -> String:
	match tier:
		RARE:
			return "Rare"
		LEGENDARY:
			return "Legend"
		_:
			return "Common"


static func price(category: int, tier: int) -> int:
	var is_brown: bool = category == BROWN or category == WHITE
	match tier:
		RARE:
			return 30 if is_brown else 36
		LEGENDARY:
			return 75 if is_brown else 90
		_:
			return 12 if is_brown else 15


static func discounted_price(category: int, tier: int, multiplier: float) -> int:
	return maxi(1, floori(float(price(category, tier)) * multiplier))


static func discounted_base_price(base_price: int, multiplier: float) -> int:
	return maxi(1, floori(float(base_price) * multiplier))


static func roll_item(database: Node, category: int, rarity: StringName) -> ItemDefinition:
	if database == null:
		return null

	var filter: StringName = category_filter(category)
	var item: ItemDefinition = database.get_random_item(filter, rarity)
	if item != null:
		return item

	item = database.get_random_item(&"", rarity)
	if item != null:
		return item

	return database.get_random_item()
