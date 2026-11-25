class_name L1Layout
extends RefCounted
## Hand-kept geometry for the L1 recruit screen, sourced from buy-screen-l1.md.

const PATH: String = "res://assets/glass/l1/layout.json"

static var _entries: Dictionary


static func entries() -> Dictionary:
	if _entries.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		assert(parsed is Dictionary, "%s is not a JSON object" % PATH)
		_entries = parsed
	return _entries


static func _value(key: String) -> Variant:
	assert(entries().has(key), "L1 layout is missing %s" % key)
	var entry: Dictionary = entries()[key]
	assert(str(entry.get("from", "")).begins_with("buy-screen-l1.md §"))
	return entry.get("value")


static func number(key: String) -> float:
	var value: Variant = _value(key)
	assert(value is float, "L1 layout %s must be a number" % key)
	return value


static func colour(key: String) -> Color:
	var value: Variant = _value(key)
	assert(
		value is String and Color.html_is_valid(str(value)), "L1 layout %s must be a colour" % key
	)
	return Color.html(str(value))


static func point(key: String) -> Vector2:
	return Vector2(number(key + ".x"), number(key + ".y"))


static func rect(key: String) -> Rect2:
	return Rect2(point(key), Vector2(number(key + ".w"), number(key + ".h")))


static func centre(key: String, size: Vector2) -> Vector2:
	return rect(key).get_center() - size / 2.0


static func stage_size() -> Vector2:
	return Vector2(number("stage.w"), number("stage.h"))


static func middle() -> Rect2:
	var column: float = number("column.w")
	return Rect2(Vector2(column, 0), stage_size() - Vector2(2.0 * column, 0))


static func shop_opening_x(i: int) -> float:
	var opening: float = number("shop.arch.w")
	var gap: float = number("shop.arch.gap")
	var count: float = number("shop.arch.count")
	var width: float = count * opening + (count - 1.0) * gap
	return (stage_size().x - width) / 2.0 + i * (opening + gap)


static func shop_tint(tier: int) -> Color:
	var key: String = "shop.tint.%d." % clampi(tier, 1, GlassPieces.TIERS)
	return Color(colour(key + "base_colour"), number(key + "strength"))
