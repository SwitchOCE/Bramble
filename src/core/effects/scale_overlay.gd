class_name ScaleOverlay
extends RefCounted
## A game owns one private configured library. Fights only read that library.


static func library_for(library: UnitLibrary, config: GameConfig) -> UnitLibrary:
	var key: String = _key(config)
	if str(library.get_meta("scale_overlay_key", "")) == key:
		return library
	var source: UnitLibrary = library.get_meta("scale_overlay_source", library)
	var ids: PackedStringArray = selected_levers(config)
	if (
		config.get_bool("card_size_caps")
		and config.get_bool("card_rate_limits")
		and ids.is_empty()
		and not Pass3Rates.overridden(config)
		and not ReferenceQuilboar.allowed(config)
		and not source.has_meta("reference_quilboar")
	):
		return source
	var out := UnitLibrary.new()
	out.set_meta("scale_overlay_source", source)
	out.set_meta("scale_overlay_key", key)
	for unit: Dictionary in source.all_units():
		if ReferenceQuilboar.allowed(config) or not str(unit["id"]).begins_with("qb_"):
			out.register_unit(card_for(unit, config))
	for card: Dictionary in source.all_cards():
		if ReferenceQuilboar.allowed(config) or not str(card["id"]).begins_with("qb_"):
			out.register_card(card_for(card, config))
	for hero: Dictionary in source.all_heroes():
		out.register_hero(card_for(hero, config))
	if not ids.is_empty():
		var levers: UnitLibrary = UnitLibrary.load_dir("res://content/levers")
		for id: String in ids:
			out.register_unit(card_for(levers.get_unit(id), config))
	ReferenceQuilboar.configure(out, config)
	if ReferenceQuilboar.allowed(config):
		out.set_meta("reference_quilboar", true)
	return out


static func selected_levers(config: GameConfig) -> PackedStringArray:
	var ids: PackedStringArray = []
	var known: Array = EffectSchema.data()["lever_cards"]
	for id: String in config.get_strings("scale_levers"):
		if known.has(id) and not ids.has(id):
			ids.append(id)
	return ids


static func _key(config: GameConfig) -> String:
	var values: Array = []
	for key: String in [
		"card_size_caps",
		"card_rate_limits",
		"reference_quilboar",
		"quilboar_ref_preset",
		"scale_levers",
		"scale_engine_percent",
		"scale_engine_flat",
		"scale_engine_self",
		"scale_engine_tribe",
		"scale_answer_percent",
		"scale_economy_cap"
	]:
		values.append(config.get_value(key))
	values.append(Pass3Rates.resolved(config))
	return JSON.stringify(values)


static func card_for(card: Dictionary, config: GameConfig) -> Dictionary:
	var out: Dictionary = card.duplicate(true)
	out.erase(MechanicRegistry.COMPILED_KEY)
	for pair: Array in [
		["card_size_caps", "size_cap_overlay"], ["card_rate_limits", "rate_limit_overlay"]
	]:
		if not config.get_bool(str(pair[0])):
			_strip(out, EffectSchema.section(str(pair[1])), str(pair[0]) == "card_rate_limits")
	ScaleText.rewrite(out, config)
	ScaleLeverText.configure(out, config)
	Pass3Text.configure(out, config)
	return out


static func _strip(value: Variant, overlay: Dictionary, rates: bool) -> void:
	if value is Array:
		var list: Array = value
		for child: Variant in list:
			_strip(child, overlay, rates)
	elif value is Dictionary:
		var entry: Dictionary = value
		if rates and str(entry.get("query", "")) == "buys_per_turn":
			entry["value"] = -1
		if (
			rates
			and str(entry.get("query", "")) == "refresh_cost"
			and str(entry.get("op", "")) == "set"
			and CoreUtil.to_int(entry.get("value", -1)) == 0
		):
			var conditions: Array = entry.get("if", [])
			entry["if"] = conditions.filter(
				func(condition: Dictionary) -> bool:
					return str(condition.get("kind", "")) != "paid_refreshes"
			)
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
			_strip(child, overlay, rates)
