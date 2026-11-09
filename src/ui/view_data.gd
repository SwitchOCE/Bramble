extends RefCounted
## Typed reads from the plain Dictionaries the core and the fixtures hand the UI (SPEC 5 and 6).
## Every warning is an error in this project, so a Variant from Dictionary.get can't be passed
## straight to a typed argument; these return the right type or the default.


static func i(source: Dictionary, key: String, default: int = 0) -> int:
	var value: Variant = source.get(key, default)
	if value is int:
		return value
	if value is float:
		var number: float = value
		return roundi(number)
	return default


static func f(source: Dictionary, key: String, default: float = 0.0) -> float:
	var value: Variant = source.get(key, default)
	if value is float:
		var number: float = value
		return number
	if value is int:
		var integer: int = value
		return float(integer)
	return default


static func s(source: Dictionary, key: String, default: String = "") -> String:
	var value: Variant = source.get(key, default)
	return default if value == null else str(value)


static func b(source: Dictionary, key: String, default: bool = false) -> bool:
	var value: Variant = source.get(key, default)
	if value is bool:
		return value
	return default


static func a(source: Dictionary, key: String) -> Array:
	var value: Variant = source.get(key)
	if value is Array:
		return value
	return []


static func d(source: Dictionary, key: String) -> Dictionary:
	var value: Variant = source.get(key)
	if value is Dictionary:
		return value
	return {}


## An int from an array element (uids in "joiners", "warned", "survivors").
static func at(items: Array, index: int, default: int = -1) -> int:
	if index < 0 or index >= items.size():
		return default
	var value: Variant = items[index]
	if value is int:
		return value
	if value is float:
		var number: float = value
		return roundi(number)
	return default


static func as_int(value: Variant, default: int = -1) -> int:
	if value is int:
		return value
	if value is float:
		var number: float = value
		return roundi(number)
	return default


## The element as a Dictionary, or {} (null board slots, malformed entries).
static func entry(items: Array, index: int) -> Dictionary:
	if index < 0 or index >= items.size():
		return {}
	var value: Variant = items[index]
	if value is Dictionary:
		return value
	return {}
