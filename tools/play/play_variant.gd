class_name PlayVariant
extends RefCounted
## Blind variants for tools/play: `new --variant X|Y` picks a rates preset through a map the tester
## can't see (the file named by BRAMBLE_VARIANT_MAP). The save seals the preset so the game replays
## without the map, and `<save> reveal` opens the seal. Nothing a tester is shown names the preset.

const MAP_ENV: String = "BRAMBLE_VARIANT_MAP"
const VARIANTS: PackedStringArray = ["X", "Y"]
## The seal is base64, so a glance at the save doesn't give the preset away. It isn't secret:
## a tester who decodes their own save can read it (tools/play/README.md says so).
const SEAL_KEY: String = "variant_seal"
const SEAL_PREFIX: String = "bramble-variant:"


## The map's entry for a variant: {"preset", "field_library", "field_strength"}, or {"error"}.
## An entry is a preset name ("C") or {"preset": "C", "field_library": path, "field_strength": s}.
static func lookup(variant: String) -> Dictionary:
	if not variant in VARIANTS:
		return {"error": "--variant takes X or Y"}
	var path: String = OS.get_environment(MAP_ENV)
	if path == "":
		return {"error": "--variant needs a variant map: set %s to its JSON file" % MAP_ENV}
	if not FileAccess.file_exists(path):
		return {"error": "The variant map named by %s doesn't exist" % MAP_ENV}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {"error": 'The variant map must be a JSON object like {"X": ..., "Y": ...}'}
	var map: Dictionary = parsed
	if not map.has(variant):
		return {"error": "The variant map has no entry for %s" % variant}
	var entry: Variant = map[variant]
	var out: Dictionary = {"field_library": "", "field_strength": "top4"}
	if entry is String:
		out["preset"] = entry
	elif entry is Dictionary:
		var given: Dictionary = entry
		out["preset"] = given.get("preset", "")
		out["field_library"] = str(given.get("field_library", ""))
		out["field_strength"] = str(given.get("field_strength", "top4"))
	if not out.get("preset") is String:
		return {"error": "Variant %s's entry needs a preset name" % variant}
	if str(out["preset"]) == "" or not known_preset(str(out["preset"])):
		return {"error": "Variant %s names a preset that rates.json doesn't have" % variant}
	return out


static func known_preset(name: String) -> bool:
	return name == "" or name in preset_names()


static func preset_names() -> PackedStringArray:
	Pass3Rates.defaults()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Pass3Rates.PATH))
	var out: PackedStringArray = []
	if parsed is Dictionary:
		var data: Dictionary = parsed
		var presets: Variant = data.get("presets", {})
		if presets is Dictionary:
			var named: Dictionary = presets
			for key: Variant in named:
				out.append(str(key))
	return out


## Never names the preset when the game is blind.
static func unknown_preset_message(name: String, variant: String) -> String:
	if variant != "":
		return "Variant %s's preset isn't in rates.json" % variant
	return "Unknown preset: %s (rates.json has %s)" % [name, ", ".join(preset_names())]


static func seal(name: String) -> String:
	return Marshalls.utf8_to_base64(SEAL_PREFIX + name)


## The preset in a seal, or null if it isn't one.
static func unseal(sealed: String) -> Variant:
	var text: String = Marshalls.base64_to_utf8(sealed)
	if not text.begins_with(SEAL_PREFIX):
		return null
	return text.substr(SEAL_PREFIX.length())


static func store_preset(game: PlayGame, saved: Dictionary) -> void:
	if game.variant != "":
		saved["variant"] = game.variant
		saved[SEAL_KEY] = seal(game.preset)
	elif game.preset != "":
		saved["preset"] = game.preset


## Reads a save's preset and variant into the game; "" or why the save can't be used.
static func load_preset(game: PlayGame, data: Dictionary) -> String:
	if data.has("variant") or data.has(SEAL_KEY):
		var opened: Variant = unseal(str(data.get(SEAL_KEY, "")))
		if not str(data.get("variant", "")) in VARIANTS or opened == null:
			return "This save's variant seal is damaged. Start a new game."
		game.variant = str(data["variant"])
		game.preset = str(opened)
		if not known_preset(game.preset):
			return unknown_preset_message(game.preset, game.variant)
		return ""
	if data.has("preset"):
		if not data["preset"] is String or not known_preset(str(data["preset"])):
			return "Unknown preset in save: %s" % str(data["preset"])
		game.preset = str(data["preset"])
	return ""


## For the orchestrator: what a blind save really plays.
static func reveal(game: PlayGame) -> String:
	if game.variant == "":
		return "Not a blind game. Preset: %s" % _shown_preset(game.preset)
	var lines: PackedStringArray = [
		"Variant %s plays preset %s" % [game.variant, _shown_preset(game.preset)]
	]
	if game.field_library_path != "":
		lines.append(
			(
				"Field library: %s (SHA-256 %s, %s)"
				% [game.field_library_path, game.field_library_sha256, game.field_strength]
			)
		)
	return "\n".join(lines)


static func _shown_preset(name: String) -> String:
	return name if name != "" else "%s (rates.json's default)" % Pass3Rates.default_preset()


## The finished-game summary names the field library's source config; a blind game drops it.
static func scrub_game_log(game: PlayGame, summary: Dictionary) -> Dictionary:
	if game.variant == "":
		return summary
	var out: Dictionary = summary.duplicate()
	out.erase("field_source")
	out.erase("field_switches")
	return out
