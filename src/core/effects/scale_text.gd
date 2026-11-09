class_name ScaleText
extends RefCounted
## Display-only patches for the limits actually changed by each schema overlay.

static var _patterns: Dictionary = {}


static func rewrite(card: Dictionary, config: GameConfig) -> void:
	_patch_tree(card, config)
	var authored: Dictionary = card.get("overlay_text", {})
	var size_text: Dictionary = authored.get("size", {})
	var rate_text: Dictionary = authored.get("rate", {})
	var both_text: Dictionary = authored.get("both", {})
	if not config.get_bool("card_size_caps"):
		_apply(card, size_text)
	if not config.get_bool("card_rate_limits"):
		_apply(card, rate_text)
	if not config.get_bool("card_size_caps") and not config.get_bool("card_rate_limits"):
		_apply(card, both_text)


static func _apply(card: Dictionary, fragments: Dictionary) -> void:
	for key: String in fragments:
		card[key] = fragments[key]


static func _patch_tree(value: Variant, config: GameConfig) -> void:
	if value is Dictionary:
		var entry: Dictionary = value
		for key: String in entry.keys():
			if key in ["keyword_text", "source", "overlay_text"]:
				continue
			if key in ["text", "golden_text", "details", "golden_details"] and entry[key] is String:
				entry[key] = _text(str(entry[key]), config)
			else:
				_patch_tree(entry[key], config)
	elif value is Array:
		var list: Array = value
		for child: Variant in list:
			_patch_tree(child, config)


static func _text(words: String, config: GameConfig) -> String:
	for pair: Array in [
		["card_size_caps", "size_cap_overlay"], ["card_rate_limits", "rate_limit_overlay"]
	]:
		if config.get_bool(str(pair[0])):
			continue
		var rules: Array = EffectSchema.section(str(pair[1])).get("text_rules", [])
		for rule: Dictionary in rules:
			var pattern: String = str(rule["pattern"])
			if not _patterns.has(pattern):
				_patterns[pattern] = RegEx.create_from_string(pattern)
			var regex: RegEx = _patterns[pattern]
			words = regex.sub(words, str(rule.get("replacement", "")), true)
	return words.strip_edges()
