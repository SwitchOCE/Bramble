class_name ScaleOverlay
extends RefCounted
## Isolated experiment library; source JSON and shared default definitions stay untouched.


static func library_for(library: UnitLibrary, config: GameConfig) -> UnitLibrary:
	var needs_caps: bool = (
		not config.get_bool("card_size_caps")
		and CoreUtil.to_bool(library.get_meta("card_size_caps", true))
	)
	var needs_levers: bool = (
		config.get_bool("scale_levers")
		and not CoreUtil.to_bool(library.get_meta("scale_levers", false))
	)
	if not needs_caps and not needs_levers:
		return library
	var out := UnitLibrary.new()
	out.set_meta("card_size_caps", config.get_bool("card_size_caps"))
	out.set_meta("scale_levers", config.get_bool("scale_levers"))
	for unit: Dictionary in library.all_units():
		out.register_unit(card_for(unit, config))
	for card: Dictionary in library.all_cards():
		out.register_card(card_for(card, config))
	for hero: Dictionary in library.all_heroes():
		out.register_hero(card_for(hero, config))
	if needs_levers:
		var levers: UnitLibrary = UnitLibrary.load_dir("res://content/levers")
		for unit: Dictionary in levers.all_units():
			out.register_unit(card_for(unit, config))
	return out


static func card_for(card: Dictionary, config: GameConfig) -> Dictionary:
	var out: Dictionary = card.duplicate(true)
	out.erase(MechanicRegistry.COMPILED_KEY)
	if not config.get_bool("card_size_caps"):
		_strip(out)
	return out


static func _strip(value: Variant) -> void:
	if value is Array:
		var list: Array = value
		for child: Variant in list:
			_strip(child)
	elif value is Dictionary:
		var entry: Dictionary = value
		if str(entry.get("query", "")) == "buys_per_turn":
			entry["value"] = -1
		var overlay: Dictionary = EffectSchema.section("size_cap_overlay")
		for key: String in overlay["remove"]:
			entry.erase(key)
		for key: String in overlay["unbounded"]:
			if entry.has(key):
				entry[key] = BoardUnit.STAT_CLAMP
		for key: String in overlay["false"]:
			if entry.has(key):
				entry[key] = false
		var mechanics: Dictionary = overlay["mechanics"]
		var overrides: Dictionary = mechanics.get(str(entry.get("id", "")), {})
		for key: String in overrides:
			var setting: Variant = overrides[key]
			entry[key] = CoreUtil.to_int(setting) if typeof(setting) == TYPE_FLOAT else setting
		entry.erase(MechanicRegistry.COMPILED_KEY)
		for child: Variant in entry.values():
			_strip(child)
