class_name GameRecordLog
extends RefCounted
## A finished game's record, for the owner to send in: the seed, the settings, the hero and every
## action, written to user://games/<timestamp>-<seed>.json in the action words tools/play saves
## use, so `tools/play/play.sh replay-log <file>` plays it again on the real rules.
##
## The UI keeps the action list. After each port call that succeeds, it appends
## GameRecordLog.words(method, args, state_before), where state_before is port.get_state() taken
## just before the call. When the game ends it calls GameRecordLog.write(port, actions) once.
## tools/play/README.md, "Game logs", has the hook in full.

const FORMAT: String = "bramble-game-log"
const VERSION: int = 1
const DIR: String = "user://games"
## Port methods that take no arguments -> the tools/play word.
const BARE_WORDS: Dictionary = {
	"refresh": "refresh",
	"ask_for_kin": "ask_for_kin",
	"toggle_freeze": "freeze",
	"tier_up": "tier",
	"end_turn": "end",
}


## The tools/play words for one GamePort call. state_before is the state just before the call:
## shop and hand numbers run on through units and then spells, as tools/play numbers them.
## A call tools/play can't replay (the dev panel's) comes back as its own name, and replay refuses
## it by name.
static func words(method: String, args: Array, state_before: Dictionary) -> Array:
	if BARE_WORDS.has(method):
		return [BARE_WORDS[method]]
	match method:
		"buy":
			return ["buy", str(_arg(args, 0))]
		"buy_spell":
			return ["buy", str(_count(state_before, "shop") + _arg(args, 0))]
		"sell":
			return ["sell", _slot(_arg(args, 0))]
		"move":
			return ["move", _slot(_arg(args, 0)), _slot(_arg(args, 1))]
		"play":
			return ["play", str(_arg(args, 0)), _slot(_arg(args, 1))]
		"play_item":
			return _play_item(args, state_before)
		"swallow":
			return ["swallow", _swallowed(args), _slot(_arg(args, 2))]
		"use_power":
			var target: int = _arg(args, 0, -1)
			return ["power"] if target < 0 else ["power", _slot(target)]
		"choose":
			return ["choose", str(_arg(args, 0))]
	var out: Array = [method]
	for value: Variant in args:
		out.append(str(value))
	return out


## Writes the record and returns its path, or "" if it couldn't be written.
## port is the CorePort (get_seed(), get_state() and its config are read); actions is the list
## words() built.
static func write(port: Object, actions: Array, dir: String = DIR) -> String:
	var config: GameConfig = port.get("config")
	var state: Dictionary = port.call("get_state")
	var record: Dictionary = make(CoreUtil.to_int(port.call("get_seed")), config, state, actions)
	DirAccess.make_dir_recursive_absolute(dir)
	var stamp: String = Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	var path: String = dir.path_join("%s-%d.json" % [stamp, CoreUtil.to_int(record["seed"])])
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(record, "\t"))
	return path


## The record itself, without writing it.
static func make(
	game_seed: int, config: GameConfig, state: Dictionary, actions: Array
) -> Dictionary:
	var field_path: String = config.get_string("field_library") if config != null else ""
	var settings: Dictionary = {
		"preset": config.get_string("pass3_preset") if config != null else "",
		"field_library": field_path,
		"field_library_sha256": FileAccess.get_sha256(field_path) if field_path != "" else "",
		"field_strength": str(config.get_value("field_strength")) if config != null else "top4",
		"ask_for_kin": config.get_bool("ask_for_kin") if config != null else false,
	}
	return {
		"format": FORMAT,
		"version": VERSION,
		"seed": game_seed,
		"settings": settings,
		"hero": hero_id(state),
		"placement": state.get("placement"),
		"actions": actions.duplicate(true),
	}


## The chosen hero's id; "" before the pick.
static func hero_id(state: Dictionary) -> String:
	var hero: Variant = state.get("hero")
	if not hero is Dictionary:
		return ""
	var card: Dictionary = hero
	return str(card.get("id", ""))


## A tools/play save for a record: {"error"} if it isn't one. field_override replaces the
## recorded library path (the SHA must still match).
static func to_save(record: Dictionary, field_override: String = "") -> Dictionary:
	if str(record.get("format", "")) != FORMAT:
		return {"error": "Not a Bramble game log."}
	if CoreUtil.to_int(record.get("version", 0)) != VERSION:
		return {"error": "Game log version %s isn't supported." % str(record.get("version"))}
	if not record.get("settings") is Dictionary:
		return {"error": "Game log needs its settings."}
	var settings: Dictionary = record["settings"]
	var save: Dictionary = {"seed": record.get("seed"), "actions": record.get("actions")}
	if str(settings.get("preset", "")) != "":
		save["preset"] = str(settings["preset"])
	if settings.get("ask_for_kin", false) == true:
		save["ask_for_kin"] = true
	var sha: String = str(settings.get("field_library_sha256", ""))
	if sha != "":
		var path: String = field_override
		if path == "":
			path = str(settings.get("field_library", ""))
		save["field_library"] = path
		save["field_library_sha256"] = sha
		save["field_strength"] = str(settings.get("field_strength", "top4"))
	return save


static func _play_item(args: Array, state: Dictionary) -> Array:
	var index: int = _arg(args, 0)
	var target: int = _arg(args, 1, -1)
	var out: Array = ["play", str(_count(state, "hand") + index)]
	if target < 0:
		return out
	var items: Array = state.get("hand_items", [])
	var aims_shop: bool = false
	if index < items.size() and items[index] is Dictionary:
		var item: Dictionary = items[index]
		aims_shop = str(item.get("aim", "")) == HandItem.AIM_SHOP_UNIT
	out.append(str(target) if aims_shop else _slot(target))
	return out


static func _swallowed(args: Array) -> String:
	var source: String = str(args[0]) if args.size() > 0 else ""
	var index: int = _arg(args, 1)
	match source:
		HeldUnits.HAND:
			return "h%d" % index
		HeldUnits.BOARD:
			return _slot(index)
	return str(index)


static func _count(state: Dictionary, key: String) -> int:
	var list: Variant = state.get(key, [])
	if not list is Array:
		return 0
	var items: Array = list
	return items.size()


static func _arg(args: Array, index: int, fallback: int = 0) -> int:
	return CoreUtil.to_int(args[index]) if index < args.size() else fallback


static func _slot(slot: int) -> String:
	var labels: PackedStringArray = BoardGeometry.LABELS
	return labels[slot] if slot >= 0 and slot < labels.size() else str(slot)
