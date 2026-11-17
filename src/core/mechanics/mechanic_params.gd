class_name MechanicParams
extends RefCounted
## Typed mechanic parameters, their kinds declared once by the mechanic (Mechanic.param_kinds)
## and checked when the library loads (prototype lesson 3). 7.3.5: a golden unit doubles every
## NUMBER; THRESHOLD values (counters, "after 3 deaths") keep their value; TEXT is an id.

enum Kind { NUMBER, THRESHOLD, TEXT }

var golden: bool = false
var _ints: Dictionary = {}
var _texts: Dictionary = {}
var _kinds: Dictionary = {}
## NUMBER parameters with their own golden value (card data "golden"), in place of double.
var _golden_ints: Dictionary = {}


## Builds params from raw data against declared kinds. Returns null and fills `errors` on a
## missing or unknown parameter or a wrong type. An optional "golden" entry gives a NUMBER its
## own golden value where it is not double ({"amount": 4, "golden": {"amount": 6}}).
static func parse(
	raw: Dictionary, kinds: Dictionary, where: String, errors: PackedStringArray
) -> MechanicParams:
	var params := MechanicParams.new()
	var ok: bool = true
	if raw.has("golden"):
		raw = raw.duplicate()
		var overrides: Dictionary = CoreUtil.to_dict(raw["golden"])
		raw.erase("golden")
		for key: Variant in overrides:
			var value: Variant = overrides[key]
			var known: bool = kinds.has(str(key))
			if not known or CoreUtil.to_int(kinds[str(key)]) != Kind.NUMBER:
				errors.append("%s: golden '%s' is not a NUMBER parameter" % [where, key])
				ok = false
			elif typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
				errors.append("%s: golden '%s' must be a number" % [where, key])
				ok = false
			else:
				params._golden_ints[str(key)] = CoreUtil.to_int(value)
	for key: Variant in raw:
		if not kinds.has(str(key)):
			errors.append("%s: unknown parameter '%s'" % [where, key])
			ok = false
	for key: Variant in kinds:
		var param: String = str(key)
		var kind: int = CoreUtil.to_int(kinds[key])
		params._kinds[param] = kind
		if not raw.has(param):
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


## The same values, as a golden copy reads them (7.3.5).
func with_golden(is_golden: bool) -> MechanicParams:
	var copy := MechanicParams.new()
	copy.golden = is_golden
	copy._ints = _ints
	copy._texts = _texts
	copy._kinds = _kinds
	copy._golden_ints = _golden_ints
	return copy


## A NUMBER (doubled when golden) or a THRESHOLD (never doubled).
func num(param: StringName) -> int:
	var value: int = CoreUtil.to_int(_ints.get(String(param), 0))
	if golden and CoreUtil.to_int(_kinds.get(String(param), -1)) == Kind.NUMBER:
		if _golden_ints.has(String(param)):
			return CoreUtil.to_int(_golden_ints[String(param)])
		return value * 2
	return value


func text(param: StringName) -> String:
	return CoreUtil.to_text(_texts.get(String(param), ""))


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in _ints:
		out[key] = num(StringName(str(key)))
	for key: Variant in _texts:
		out[key] = _texts[key]
	return out
