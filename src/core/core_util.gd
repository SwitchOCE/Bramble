class_name CoreUtil
extends RefCounted
## Small typed conversions. int()/bool() on a Variant is an unsafe call under the project's
## warnings-as-errors, and JSON numbers arrive as floats.


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


## `value`, or null when `value` is `empty` (for the nullable fields of the state format).
static func int_or_null(value: int, empty: int) -> Variant:
	if value == empty:
		return null
	return value


static func string_or_null(value: String) -> Variant:
	if value == "":
		return null
	return value
