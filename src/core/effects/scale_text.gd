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
	_scaling_details(card, config)


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


static func _scaling_details(card: Dictionary, config: GameConfig) -> void:
	if config.get_bool("pass3_content"):
		for mechanic: Dictionary in card.get("mechanics", []):
			if str(mechanic.get("trigger", "")) == "on_take":
				_append_ruling(
					card, "Permanent gains from Takes arrive at your next Start of Turn."
				)
				break
		if str(card.get("id", "")) == "bridge_toad":
			_append_ruling(card, "Permanent gains from bites arrive at your next Start of Turn.")
	if str(card.get("id", "")) == "harvest_supper" and config.get_bool("pass3_content"):
		card["text"] = "Pick a unit. Your units of its tribe, now and later, gain +1/+1. Once a turn."
	var raw_step: Variant = card.get("do", {})
	var step: Dictionary = raw_step if raw_step is Dictionary else {}
	if (
		config.get_bool("pass3_content")
		and str(step.get("effect", "")) == "slot_effect"
		and str(step.get("name", "")) == BoardUpkeep.RING
	):
		card["text"] = (
			"Ring a slot %d times." % CoreUtil.to_int(step.get("count", step.get("attack", 0)))
		)
	if not config.get_bool("scale_hero_spell_stats"):
		return
	if str(card.get("kind", "")) != "spell" and not card.has("power"):
		return
	var rate: int = maxi(0, config.get_int("scale_hero_spell_percent"))
	if rate == 0:
		return
	if not _has_scaled_effect(card, config):
		return
	for field: String in ["text", "golden_text"]:
		if card.has(field):
			card[field] = _scaled_pairs(str(card[field]), rate)
	var words: String = (
		(
			"Each positive printed stat point grants %d%% of the recipient's corresponding stat, "
			+ "with the printed gain as a minimum. Effects without a recipient use "
			+ "your board's average stats. Fractional gains round down."
		)
		% rate
	)
	if str(card.get("id", "")) == "harvest_supper":
		var cap: String = (
			", up to +3/+3"
			if config.get_bool("card_size_caps") and not config.get_bool("pass3_content")
			else ""
		)
		card["text"] = (
			(
				"Pick a unit. Your units of its tribe, now and later, gain %d%% of your board's "
				+ "lower average stat as +Attack/+Health (minimum +1/+1)%s. Once a turn."
			)
			% [rate, cap]
		)
		if not config.get_bool("pass3_content") and not config.get_bool("card_rate_limits"):
			card["text"] = str(card["text"]).replace(" Once a turn.", "")
		words = (
			(
				"The tribe bonus gains %d%% of the lower of your board's average Attack and Health, "
				+ "with +1/+1 as a minimum."
			)
			% rate
		)
	if str(step.get("effect", "")) == "wait_in_slot":
		words += " The gain is fixed when cast."
	card["details"] = (str(card.get("details", "")) + " " + words).strip_edges()


static func _has_scaled_effect(value: Variant, config: GameConfig) -> bool:
	if value is Dictionary:
		var entry: Dictionary = value
		if (
			config.get_bool("pass3_content")
			and str(entry.get("effect", "")) == "slot_effect"
			and str(entry.get("name", "")) == BoardUpkeep.RING
		):
			return false
		if (
			str(entry.get("effect", ""))
			in ["buff", "kin_buff", "slot_effect", "tribe_bonus", "wait_in_slot"]
		):
			return true
		for child: Variant in entry.values():
			if _has_scaled_effect(child, config):
				return true
	elif value is Array:
		for child: Variant in value:
			if _has_scaled_effect(child, config):
				return true
	return false


static func _scaled_pairs(words: String, rate: int) -> String:
	var regex := RegEx.create_from_string("\\+(\\d+)/\\+(\\d+)")
	var matches: Array[RegExMatch] = regex.search_all(words)
	matches.reverse()
	for found: RegExMatch in matches:
		var attack: int = found.get_string(1).to_int() * rate
		var health: int = found.get_string(2).to_int() * rate
		var pair: String = "+%d%%/+%d%% (minimum %s)" % [attack, health, found.get_string()]
		words = words.substr(0, found.get_start()) + pair + words.substr(found.get_end())
	return words


static func _append_ruling(card: Dictionary, words: String) -> void:
	var normal: String = str(card.get("details", ""))
	var golden: String = str(card.get("golden_details", normal))
	card["details"] = (normal + " " + words).strip_edges()
	card["golden_details"] = (golden + " " + words).strip_edges()
