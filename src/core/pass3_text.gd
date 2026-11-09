class_name Pass3Text
extends RefCounted
## Rate overrides change display text alongside the engine. Authored defaults remain untouched.


static func configure(card: Dictionary, config: GameConfig) -> void:
	var id: String = str(card.get("id", ""))
	if not _is_pass3(card) and id != "golden_egg":
		return
	if Pass3Rates.overridden(config):
		card["pass3_rates"] = Pass3Rates.resolved(config)
	for golden: bool in [false, true]:
		var words: String = _bird(id, golden, config)
		if words.is_empty():
			words = _fairy(id, golden, config)
		if words.is_empty():
			words = _fairy_count(id, golden, config)
		if not words.is_empty():
			_set_text(card, golden, words)
	_details(card, config)
	_flight(card, config)


static func _is_pass3(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) in ["pass3_bird", "pass3_fairy"]:
			return true
	return false


static func _changed(config: GameConfig, keys: Array[String]) -> bool:
	var defaults: Dictionary = Pass3Rates.defaults()
	for key: String in keys:
		if Pass3Rates.value(config, key) != defaults.get(key):
			return true
	return false


static func _n(value: float) -> String:
	return str(int(value)) if value == floorf(value) else str(value)


static func _rate(config: GameConfig, key: String, factor: float = 1.0) -> String:
	return _n(Pass3Rates.number(config, key) * factor)


static func _share(config: GameConfig, key: String, factor: float = 1.0) -> String:
	return _rate(config, key, 100.0 * factor) + "%"


static func _amount(count: int) -> String:
	return "a" if count == 1 else str(count)


static func _biggest(count: int, noun: String) -> String:
	return "your biggest " + noun if count == 1 else "your %d biggest %ss" % [count, noun]


static func _start(words: String) -> String:
	return words.substr(0, 1).to_upper() + words.substr(1)


static func _bird(id: String, golden: bool, config: GameConfig) -> String:
	var factor: int = 2 if golden else 1
	match id:
		"mr_redbreast":
			if _changed(config, ["birds_redbreast_share"]):
				return (
					"After a Bird comes home: gain %s of its stats."
					% _share(config, "birds_redbreast_share", factor)
				)
		"cuckoo":
			if _changed(config, ["birds_cuckoo_share"]):
				return (
					"After a Bird comes home: other Birds gain %s of its stats."
					% _share(config, "birds_cuckoo_share", factor)
				)
		"jack_daw":
			if _changed(config, ["birds_jack_daw_share", "birds_jack_daw_permanent"]):
				var permanent: String = (
					"permanently " if Pass3Rates.enabled(config, "birds_jack_daw_permanent") else ""
				)
				return (
					"Start of Combat: your biggest Bird %ssteals %s of the stats of the enemy across."
					% [permanent, _share(config, "birds_jack_daw_share", factor)]
				)
		"mrs_stork":
			if _changed(config, ["birds_stork_gold_step", "birds_stork_recalls"]):
				var count: int = Pass3Rates.integer(config, "birds_stork_recalls") * factor
				return (
					"Every %s gold you spend: %s %s that missed a fight %s home."
					% [
						_rate(config, "birds_stork_gold_step"),
						_amount(count),
						"Bird" if count == 1 else "Birds",
						"comes" if count == 1 else "come"
					]
				)
		"mrs_dunnock":
			if _changed(config, ["birds_dunnock_turns", "birds_dunnock_targets"]):
				var count: int = Pass3Rates.integer(config, "birds_dunnock_targets") * factor
				var turns: int = Pass3Rates.integer(config, "birds_dunnock_turns")
				return (
					"End of Turn: %s away %s home %d %s sooner."
					% [
						_biggest(count, "Bird"),
						"comes" if count == 1 else "come",
						turns,
						"turn" if turns == 1 else "turns"
					]
				)
		"mother_goose":
			if not Pass3Rates.enabled(config, "birds_golden_egg_enabled"):
				return "Fly South."
		"golden_egg":
			if _changed(config, ["birds_golden_egg_multiplier"]):
				return (
					"Multiply a Bird's stats by %s. Once per Bird."
					% _rate(config, "birds_golden_egg_multiplier")
				)
		"tom_tit", "redwing", "great_lump", "gabble_ratchet", "seven_whistlers":
			return _bird_combat(id, golden, config)
	return ""


static func _bird_combat(id: String, golden: bool, config: GameConfig) -> String:
	var factor: int = 2 if golden else 1
	match id:
		"tom_tit":
			if _changed(config, ["birds_tom_tit_reduction", "birds_tom_tit_targets"]):
				var count: int = Pass3Rates.integer(config, "birds_tom_tit_targets") * factor
				return (
					"%s other %s Damage Reduction %s%%."
					% [
						_start(_biggest(count, "Bird")),
						"has" if count == 1 else "have",
						_rate(config, "birds_tom_tit_reduction")
					]
				)
		"redwing":
			if _changed(config, ["birds_redwing_share", "birds_redwing_targets"]):
				return (
					"%s away %s Eggs with %s of their stats."
					% [
						_start(
							_biggest(
								Pass3Rates.integer(config, "birds_redwing_targets") * factor, "Bird"
							)
						),
						(
							"leaves"
							if Pass3Rates.integer(config, "birds_redwing_targets") * factor == 1
							else "leave"
						),
						_share(config, "birds_redwing_share")
					]
				)
		"great_lump":
			if _changed(config, ["birds_lump_multiplier"]):
				return (
					"Cleave. On a Nest, this gains %s times its Bird's stats."
					% _rate(config, "birds_lump_multiplier", factor)
				)
		"gabble_ratchet":
			if _changed(config, ["birds_ratchet_multiplier"]):
				return (
					"When a unit on a Nest dies: its Bird drops in at %s times its stats."
					% _rate(config, "birds_ratchet_multiplier", factor)
				)
		"seven_whistlers":
			if _changed(config, ["birds_whistlers_loss_share", "birds_whistlers_flock_count"]):
				var repeat: String = " twice" if golden else ""
				return (
					(
						"Start of Combat: the enemy across loses %s stats%s. "
						+ "With %s different Birds, every enemy does."
					)
					% [
						_share(config, "birds_whistlers_loss_share"),
						repeat,
						_rate(config, "birds_whistlers_flock_count")
					]
				)
	return ""


static func _fairy(id: String, golden: bool, config: GameConfig) -> String:
	var factor: int = 2 if golden else 1
	match id:
		"cluricaun":
			if _changed(config, ["fairies_ring_growth"]):
				var growth: String = _rate(config, "fairies_ring_growth", factor)
				return (
					"After you Tier up: if every slot has a Ring, your Rings grow +%s/+%s."
					% [growth, growth]
				)
		"cradle_fetch":
			if _changed(config, ["fairies_fetch_share"]):
				return (
					"Start of Combat: become a %scopy of the Fairy behind, Ring and all, with %s stats."
					% ["golden " if golden else "", _share(config, "fairies_fetch_share")]
				)
		"lob_lie_by_the_fire":
			if _changed(config, ["fairies_lob_turns", "fairies_lob_growth"]):
				var growth: String = _rate(config, "fairies_lob_growth", factor)
				return (
					"Shy. When this leaves: your Rings grow +%s/+%s per %s turns it stayed."
					% [growth, growth, _rate(config, "fairies_lob_turns")]
				)
		"silky":
			if _changed(config, ["fairies_silky_growth"]):
				var growth: String = _rate(config, "fairies_silky_growth", factor)
				return "Shy. After a Shy unit leaves: your Rings grow +%s/+%s." % [growth, growth]
		"fairy_monarch":
			if _changed(
				config,
				[
					"fairies_monarch_period",
					"fairies_monarch_multiplier",
					"fairies_golden_monarch_multiplier"
				]
			):
				var key: String = (
					"fairies_golden_monarch_multiplier" if golden else "fairies_monarch_multiplier"
				)
				return (
					"%s: multiply your Ring size by %s."
					% [
						_period(Pass3Rates.integer(config, "fairies_monarch_period")),
						_rate(config, key)
					]
				)
		"reel_mistress":
			if _changed(config, ["fairies_reel_moves"]):
				return (
					"After a unit on a Ring attacks: its Ring moves to your next unit. %s times per Ring."
					% _rate(config, "fairies_reel_moves", factor)
				)
		"queen_of_elfland":
			if _changed(config, ["fairies_queen_period", "fairies_queen_rings"]):
				return (
					"%s: destroy the units behind this. Ring every slot %s times for each."
					% [
						_period(Pass3Rates.integer(config, "fairies_queen_period")),
						_rate(config, "fairies_queen_rings", factor)
					]
				)
	return ""


static func _fairy_count(id: String, golden: bool, config: GameConfig) -> String:
	var factor: int = 2 if golden else 1
	match id:
		"old_moth_annis":
			if _changed(config, ["fairies_annis_sale", "fairies_annis_rings"]):
				var timing: String = (
					"End of Turn and after you sell"
					if Pass3Rates.enabled(config, "fairies_annis_sale")
					else "End of Turn"
				)
				return (
					"%s: Ring the slots behind this %s times."
					% [timing, _rate(config, "fairies_annis_rings", factor)]
				)
		"nan_toadstool":
			if _changed(config, ["fairies_nan_rings"]):
				return (
					"When played or sold: Ring this slot %s times."
					% _rate(config, "fairies_nan_rings", factor)
				)
		"sally_spore":
			if _changed(config, ["fairies_sally_rings"]):
				return (
					"End of Turn: Ring your empty slot nearest this %s times."
					% _rate(config, "fairies_sally_rings", factor)
				)
		"rainbow_chaser":
			if _changed(config, ["fairies_chaser_gold"]):
				return (
					"When sold: get %s gold per slot with a Ring."
					% _rate(config, "fairies_chaser_gold", factor)
				)
		"will_o_the_wisp":
			if _changed(config, ["fairies_wisp_attack", "fairies_wisp_health"]):
				return (
					"Start of Combat: summon a %s/%s Wisp into each empty Ring."
					% [
						_rate(config, "fairies_wisp_attack", factor),
						_rate(config, "fairies_wisp_health", factor)
					]
				)
	return ""


static func _period(turns: int) -> String:
	if turns == 1:
		return "End of Turn"
	var suffix: String = "th"
	if turns % 100 not in [11, 12, 13]:
		match turns % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"
	return "Every %d%s End of Turn" % [turns, suffix]


static func _set_text(card: Dictionary, golden: bool, words: String) -> void:
	var field: String = "golden_text" if golden else "text"
	card[field] = words
	var fragments: Dictionary = card.get("mechanic_text", {})
	for key: String in fragments:
		var fragment: Dictionary = fragments[key]
		if str(fragment.get("id", "")) in ["pass3_bird", "pass3_fairy"]:
			fragment[field] = words.trim_prefix("Shy. ").trim_prefix("Fly South. ")


static func _flight(card: Dictionary, config: GameConfig) -> void:
	var flies: bool = false
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "fly_south":
			flies = true
	if not flies:
		return
	var id: String = str(card.get("id", ""))
	var keys: Array[String] = [
		"birds_homecoming_multiplier", "birds_golden_homecoming_multiplier", "birds_trip_turns"
	]
	if id == "one_swallow":
		keys.append("birds_swallow_trip_turns")
	if id == "old_tern":
		keys.append("birds_golden_tern_trip_turns")
	if not _changed(config, keys):
		return
	for golden: bool in [false, true]:
		var reminder: String = (
			"Sold, flies south for %d turns; returns to hand at %s× permanent stats."
			% [
				_trip(id, golden, config),
				_rate(
					config,
					(
						"birds_golden_homecoming_multiplier"
						if golden
						else "birds_homecoming_multiplier"
					)
				)
			]
		)
		card["golden_details" if golden else "details"] = (
			reminder
			+ " Flying pays no sale gold; played this turn, it sells normally. "
			+ "Early recalls require a missed fight; each trip grows once."
		)
		if not golden:
			var overrides: Dictionary = card.get("keyword_text_overrides", {})
			overrides["Fly South"] = reminder
			card["keyword_text_overrides"] = overrides
			var reminders: Array = card.get("keyword_text", [])
			for entry: Dictionary in reminders:
				if str(entry.get("keyword", "")) == "Fly South":
					entry["text"] = reminder


static func _trip(id: String, golden: bool, config: GameConfig) -> int:
	if id == "one_swallow":
		return Pass3Rates.integer(config, "birds_swallow_trip_turns")
	if golden and id == "old_tern":
		return Pass3Rates.integer(config, "birds_golden_tern_trip_turns")
	return Pass3Rates.integer(config, "birds_trip_turns")


static func _details(card: Dictionary, config: GameConfig) -> void:
	match str(card.get("id", "")):
		"jack_daw":
			if _changed(config, ["birds_jack_daw_permanent"]):
				card["details"] = "Fractions round up. The stolen stats return to their owners after the fight."
		"cradle_fetch":
			if _changed(config, ["fairies_fetch_share"]):
				card["details"] = (
					"Rounds copied stats up and adds this slot's Ring. "
					+ "Copies the biggest Fairy behind; two Fetches never share a target."
				)
				card["golden_details"] = (
					"Becomes golden, including its text. Copies %s of current stats, then adds this slot's Ring."
					% _share(config, "fairies_fetch_share")
				)
		"lob_lie_by_the_fire":
			if _changed(config, ["fairies_lob_growth", "fairies_lob_turns"]):
				var growth: String = _rate(config, "fairies_lob_growth", 2)
				card["golden_details"] = (
					"Shy pays 4 gold. Only thanking counts; each complete %s turns gives +%s/+%s Ring size."
					% [_rate(config, "fairies_lob_turns"), growth, growth]
				)
		"fairy_monarch":
			if _changed(
				config, ["fairies_monarch_multiplier", "fairies_golden_monarch_multiplier"]
			):
				card["details"] = (
					(
						"Midsummer shares one countdown across copies. "
						+ "Extra triggers never advance it or repeat its growth; "
						+ "a golden copy multiplies by %s instead."
					)
					% _rate(config, "fairies_golden_monarch_multiplier")
				)
		"seven_whistlers":
			if _changed(config, ["birds_whistlers_loss_share"]):
				card["details"] = (
					"Counts different Bird card names on your board; Eggs do not count. "
					+ "Each remaining stat rounds up after reduction."
				)
		"old_moth_annis":
			if not Pass3Rates.enabled(config, "fairies_annis_sale"):
				card["details"] = "Rings the slots behind this at End of Turn."
	if _changed(config, ["fairies_initial_ring_size"]):
		var reminders: Array = card.get("keyword_text", [])
		for entry: Dictionary in reminders:
			if str(entry.get("keyword", "")) == "Ring size":
				var size: String = _rate(config, "fairies_initial_ring_size")
				entry["text"] = "What each Ring gives; starts at +%s/+%s." % [size, size]
				var overrides: Dictionary = card.get("keyword_text_overrides", {})
				overrides["Ring size"] = entry["text"]
				card["keyword_text_overrides"] = overrides
