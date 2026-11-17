class_name CoreUtil
extends RefCounted
## Small typed conversions. int()/bool() on a Variant is an unsafe call under the project's
## warnings-as-errors, and JSON numbers arrive as floats. Taken from the first run's core.


static func to_int(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			var whole: int = value
			return whole
		TYPE_FLOAT:
			var number: float = value
			return roundi(number)
		TYPE_BOOL:
			var flag: bool = value
			return 1 if flag else 0
	return 0


static func to_bool(value: Variant) -> bool:
	if typeof(value) == TYPE_BOOL:
		var flag: bool = value
		return flag
	return to_int(value) != 0


static func to_text(value: Variant) -> String:
	if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
		return str(value)
	return ""


static func to_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		var list: Array = value
		return list
	return []


static func to_dict(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		var map: Dictionary = value
		return map
	return {}


## Integer division rounded up, for positive divisors.
static func ceil_div(numerator: int, divisor: int) -> int:
	@warning_ignore("integer_division")
	return (numerator + divisor - 1) / divisor
