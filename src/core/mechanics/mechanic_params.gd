class_name MechanicParams
extends RefCounted
## Typed mechanic parameters, their kinds declared once by the mechanic (Mechanic.param_kinds)
## and checked when the library loads. NUMBER defaults to doubling on a golden. THRESHOLD
## keeps its value, and TEXT is an id. Card data can override golden NUMBER and TEXT values.

enum Kind { NUMBER, THRESHOLD, TEXT }

var golden: bool = false
var _ints: Dictionary = {}
var _texts: Dictionary = {}
var _kinds: Dictionary = {}
## NUMBER parameters with their own golden value (card data "golden"), in place of double.
var _golden_ints: Dictionary = {}
var _golden_texts: Dictionary = {}


## Builds params from raw data against declared kinds. Returns null and fills `errors` on a
## missing required parameter, unknown parameter or wrong type. A "golden" entry gives a
## NUMBER or TEXT its own golden value ({"amount": 4, "golden": {"amount": 6}}).
static func parse(
	raw: Dictionary,
	kinds: Dictionary,
	where: String,
	errors: PackedStringArray,
	optional: PackedStringArray = []
) -> MechanicParams:
	var params := MechanicParams.new()
	var ok: bool = true
	if raw.has("golden"):
		if not raw["golden"] is Dictionary:
			errors.append("%s: golden must be an object" % where)
			return null
		raw = raw.duplicate()
		var overrides: Dictionary = raw["golden"]
		raw.erase("golden")
		ok = params._parse_golden(overrides, raw, kinds, where, errors)
	for key: Variant in raw:
		if not kinds.has(str(key)):
			errors.append("%s: unknown parameter '%s'" % [where, key])
			ok = false
	for key: Variant in kinds:
		var param: String = str(key)
		var kind: int = CoreUtil.to_int(kinds[key])
		params._kinds[param] = kind
		if not raw.has(param):
			if not optional.has(param):
				errors.append("%s: missing parameter '%s'" % [where, param])
				ok = false
			continue
		var value: Variant = raw[param]
		if kind == Kind.TEXT:
			if typeof(value) != TYPE_STRING:
				errors.append("%s: '%s' must be text" % [where, param])
				ok = false
			params._texts[param] = CoreUtil.to_text(value)
		else:
			if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
				errors.append("%s: '%s' must be a number" % [where, param])
				ok = false
			params._ints[param] = CoreUtil.to_int(value)
	return params if ok else null


func _parse_golden(
	overrides: Dictionary,
	raw: Dictionary,
	kinds: Dictionary,
	where: String,
	errors: PackedStringArray
) -> bool:
	var ok: bool = true
	for key: String in overrides:
		var kind: int = CoreUtil.to_int(kinds.get(key, -1))
		var value: Variant = overrides[key]
		var problem: String = ""
		if not raw.has(key) or (kind != Kind.NUMBER and kind != Kind.TEXT):
			problem = "must override a NUMBER or TEXT with a base value"
		elif kind == Kind.TEXT:
			if value is String:
				_golden_texts[key] = value
			else:
				problem = "must be text"
		elif value is int or value is float:
			_golden_ints[key] = CoreUtil.to_int(value)
		else:
			problem = "must be a number"
		if problem != "":
			errors.append("%s: golden '%s' %s" % [where, key, problem])
			ok = false
	return ok


## The same values, as a golden copy reads them (7.3.5).
func with_golden(is_golden: bool) -> MechanicParams:
	var copy := MechanicParams.new()
	copy.golden = is_golden
	copy._ints = _ints
	copy._texts = _texts
	copy._kinds = _kinds
	copy._golden_ints = _golden_ints
	copy._golden_texts = _golden_texts
	return copy


## A NUMBER (doubled when golden) or a THRESHOLD (never doubled).
func num(param: StringName, fallback: int = 0) -> int:
	if not _ints.has(String(param)):
		return fallback
	var value: int = CoreUtil.to_int(_ints[String(param)])
	if golden and CoreUtil.to_int(_kinds.get(String(param), -1)) == Kind.NUMBER:
		if _golden_ints.has(String(param)):
			return CoreUtil.to_int(_golden_ints[String(param)])
		return value * 2
	return value


func text(param: StringName) -> String:
	if golden and _golden_texts.has(String(param)):
		return CoreUtil.to_text(_golden_texts[String(param)])
	return CoreUtil.to_text(_texts.get(String(param), ""))


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _ints:
		out[key] = num(StringName(str(key)))
	for key: Variant in _texts:
		out[key] = text(StringName(str(key)))
	return out
