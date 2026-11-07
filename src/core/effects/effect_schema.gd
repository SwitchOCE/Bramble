class_name EffectSchema
extends RefCounted
## content/schema/effects.json: the one list of triggers, selectors, conditions, effects and
## mechanic parameters. The content checker and the docs test read the same file.

const PATH: String = "res://content/schema/effects.json"
const NUMBER: String = "number"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
			_resolve_acorn_reminder()
		else:
			push_error("EffectSchema: can't read %s" % PATH)
	return _data


static func section(name: String) -> Dictionary:
	var value: Dictionary = data().get(name, {})
	return value


## The parameter kinds of a built mechanic id, or {}.
static func mechanic_params(mechanic_id: String) -> Dictionary:
	var value: Dictionary = section("mechanics").get(mechanic_id, {})
	return value


## Whose event this trigger listens to by default: "self", "other" or "any".
static func default_subject(trigger: String) -> String:
	var entry: Dictionary = section("triggers").get(trigger, {})
	return str(entry.get("subject", "any"))


## An effect entry's parameter kinds.
static func effect_params(effect: String) -> Dictionary:
	var entry: Dictionary = section("effects").get(effect, {})
	var params: Dictionary = entry.get("params", {})
	return params


## A step of a data effect with its number parameters doubled (7.3.5).
static func doubled_step(step: Dictionary) -> Dictionary:
	var out: Dictionary = step.duplicate(true)
	var kinds: Dictionary = effect_params(str(step.get("effect", "")))
	for key: Variant in kinds:
		if (
			str(kinds[key]) == NUMBER
			and out.has(key)
			and not CoreUtil.to_bool(step.get("golden_static", false))
		):
			out[key] = CoreUtil.to_int(out[key]) * 2
	return out


## Resolve printed item values once, without recursively loading the unit library.
static func _resolve_acorn_reminder() -> void:
	var values: Dictionary = {}
	for card_id: String in ["acorn", "stash", "great_hoard"]:
		var path: String = "res://content/spells/%s.json" % card_id
		var card: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		values[card_id] = CoreUtil.to_int(card["gold_value"])
	var words: Dictionary = _data["keywords"]
	words["Acorn"] = str(words["Acorn"]).format(values)
