class_name Pass3HunterText
extends RefCounted
## Native Hunter faces and borrowed fragments are generated from the resolved paper rates.


static func is_native(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "pass3_hunter":
			return true
	return false


static func configure(card: Dictionary, config: GameConfig) -> void:
	if not is_native(card):
		return
	card["pass3_rates"] = Pass3Rates.resolved(config)
	for golden: bool in [false, true]:
		card["golden_text" if golden else "text"] = face(card, config, golden)
		card["golden_details" if golden else "details"] = details(card, config, golden)
	card["configured_rulings"] = {
		"details": card["details"], "golden_details": card["golden_details"]
	}
	var fragments: Dictionary = {}
	var entries: Array = card.get("mechanics", [])
	for index: int in entries.size():
		var entry: Dictionary = entries[index]
		if str(entry.get("id", "")) != "pass3_hunter":
			continue
		var fragment: Dictionary = {"id": "pass3_hunter"}
		for golden: bool in [false, true]:
			var words: String = face(card, config, golden)
			for prefix: String in ["Quarry, wherever it stands. ", "Quarry. ", "Pack. "]:
				words = words.trim_prefix(prefix)
			fragment["golden_text" if golden else "text"] = words
		fragments[str(index)] = fragment
	card["mechanic_text"] = fragments
	var overrides: Dictionary = card.get("keyword_text_overrides", {})
	overrides["Take"] = "Its quarry dies while this is on the board."
	overrides["Pelt"] = (
		"A 0-gold spell: give a Hunter %s permanently."
		% _portion(Pass3Rates.number(config, "hunters_pelt_share"), "the prey's stats")
	)
	card["keyword_text_overrides"] = overrides


static func face(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	var id: String = str(card.get("id", ""))
	match id:
		"little_nip", "old_lutra":
			var ability: String = "nip" if id == "little_nip" else "lutra"
			return (
				"%s Take: gain %s permanently."
				% [
					"Quarry." if id == "little_nip" else "Quarry, wherever it stands.",
					_portion(_share(config, ability, golden), "the quarry's stats"),
				]
			)
		"wick":
			return (
				"Pack. After this joins a kill: gain %s permanently."
				% _portion(_share(config, "wick", golden), "the target's stats")
			)
		"young_brock":
			return (
				"When a Hunter %s this is sold: gain %s permanently."
				% [
					"next to" if golden else "beside",
					_portion(Pass3Rates.number(config, "hunters_young_brock_share"), "its stats"),
				]
			)
		"sable":
			return (
				"Quarry. Start of Combat: gain %s. Take: gain %s permanently."
				% [
					_portion(_golden_rate(config, "sable_strike", golden), "its quarry's Attack"),
					_portion(_share(config, "sable", golden), "the quarry's stats"),
				]
			)
		"toll_bard":
			return (
				"Quarry. After its quarry attacks: get %d gold next turn. %s a fight."
				% [
					int(_golden_rate(config, "lane_bard_gold", golden)),
					_start(_times(Pass3Rates.integer(config, "hunters_lane_bard_triggers"))),
				]
			)
		"mistress_russet":
			var copies: int = Pass3Rates.integer(config, "hunters_russet_copies")
			return (
				"Quarry. Take: your next shop has %s, with %s."
				% [
					"a copy" if copies == 1 else "%d copies" % copies,
					_portion(_golden_rate(config, "russet_buff_share", golden), "its buffs"),
				]
			)
		"brother_wolf":
			return "Pack. Units beside this attack first; this joins both."
		"lodger":
			return (
				"After a Take beside this: gain %s permanently."
				% _portion(_share(config, "lodger", golden), "the quarry's stats")
			)
		"madame_ermeline":
			var count: int = int(_golden_rate(config, "ermeline_pelts", golden))
			return (
				"After each fight: get %s of your biggest quarry."
				% ("a Pelt" if count == 1 else _word(count) + " Pelts")
			)
		"old_brock":
			return "Hunters next to this hunt the enemy across from this, wherever it stands."
		"grey_agnes":
			return (
				"Pack. Your pack leaders take %s."
				% _portion(_golden_rate(config, "agnes_hit_back", golden), "the hit back")
			)
		"grizel":
			return (
				"Pack. After your pack kills: its attackers gain %s permanently."
				% _portion(_share(config, "grizel", golden), "the target's stats")
			)
		"mountain_glutton":
			return (
				"Pack. After each Take: gain %s permanently."
				% _portion(_share(config, "glutton", golden), "the quarry's stats")
			)
		"laird_of_sett":
			return (
				"Your 'Take:' text triggers %s."
				% _times(_golden_rate(config, "laird_multiplier", golden))
			)
		"old_isegrim":
			return (
				"Start of Combat: this and Hunters %s it hunt the biggest enemy, wherever it stands."
				% ("next to" if golden else "beside")
			)
	return ""


static func details(card: Dictionary, config: GameConfig, _golden: bool = false) -> String:
	var id: String = str(card.get("id", ""))
	var words: String = ""
	match id:
		"young_brock":
			words = (
				"Reads the sold Hunter's current stats without its tribe bonus;"
				+ " golden widens reach, not the share."
			)
		"sable":
			words = (
				"The opening Attack gain lasts only this fight and reads the quarry's bell Attack."
				+ " A late-lent quarry still enables the strike. Printed and borrowed copies use the"
				+ " strongest strike once per dispatch; a separate Start of Combat replay can add it again."
			)
		"toll_bard":
			words = "The quarry can attack anyone; each completed attack can pay."
		"mistress_russet":
			words = (
				"Copies only permanent buffs onto a pool-backed, non-golden copy at your tier or lower."
				+ " It costs the normal price; unbought copies expire at End of Turn."
			)
		"brother_wolf":
			words = (
				"Joins each neighbour once a cycle."
				+ " Does not lead while one can attack; joins never cleave."
			)
		"lodger":
			words = "Only a Take made by a unit beside this counts; the Laird does not repeat this reward."
		"madame_ermeline":
			words = (
				(
					"Biggest means the most Attack plus Health among enemies your units marked"
					+ " at the bell, killed or not."
				)
				+ (
					" Each Pelt gives %s permanently to a Hunter; a full hand delays it on the doorstep."
					% _portion(
						Pass3Rates.number(config, "hunters_pelt_share"), "the prey's bell stats"
					)
				)
			)
		"old_brock":
			words = "Only Hunters without their own quarry take the lent hunt; golden does not widen it."
		"grey_agnes":
			words = "Only the counter-hit of an attack led by your pack is reduced; copies do not stack."
		"mountain_glutton":
			words = "Each actual Take feeds this once; the Laird does not repeat this reward."
		"laird_of_sett":
			words = (
				"Only 'Take:' payoffs repeat; 'After each Take' listeners fire once."
				+ " Copies use the strongest multiplier."
			)
		"old_isegrim":
			words = (
				"Biggest means Attack plus Health, including units inside Bellies; ties use reading order."
				+ " Hunters with their own quarry keep it."
			)
			var cut: float = Pass3Rates.number(config, "hunters_isegrim_health_cut")
			if cut > 0.0:
				words += " Its quarry loses %s at the opening." % _portion(cut, "its Health")
	if id in ["little_nip", "wick", "sable", "lodger", "old_lutra", "grizel", "mountain_glutton"]:
		words += (
			" Shares read bell stats, rounded down, at least +%d/+%d."
			% [
				Pass3Rates.integer(config, "hunters_take_floor"),
				Pass3Rates.integer(config, "hunters_take_floor"),
			]
		)
		words += (
			" Gains arrive at your next Start of Turn, even if this died making the Take."
			if Pass3Rates.enabled(config, "hunters_trophies_after_fight")
			else " Gains apply during the fight."
		)
	return words.strip_edges()


static func _share(config: GameConfig, ability: String, golden: bool) -> float:
	return (
		Pass3Rates.number(config, "hunters_" + ability + "_share")
		* (Pass3Rates.number(config, "hunters_golden_take_multiplier") if golden else 1.0)
	)


static func _golden_rate(config: GameConfig, key: String, golden: bool) -> float:
	return Pass3Rates.number(config, "hunters_" + ("golden_" if golden else "") + key)


static func _portion(value: float, noun: String) -> String:
	if is_equal_approx(value, 1.0):
		return noun
	if is_equal_approx(value, 2.0):
		return "twice " + noun
	for pair: Array in [
		[2, "half", "halves"],
		[3, "third", "thirds"],
		[4, "quarter", "quarters"],
		[6, "sixth", "sixths"],
		[8, "eighth", "eighths"],
		[12, "twelfth", "twelfths"]
	]:
		var denominator: int = CoreUtil.to_int(pair[0])
		var numerator: int = roundi(value * denominator)
		if numerator <= 0 or not is_equal_approx(value, float(numerator) / denominator):
			continue
		if numerator == 1:
			return ("half " if denominator == 2 else "a " + str(pair[1]) + " of ") + noun
		return "%s %s of %s" % [_word(numerator), str(pair[2]), noun]
	return _n(value * 100.0) + "% of " + noun


static func _times(value: float) -> String:
	if is_equal_approx(value, 1.0):
		return "once"
	if is_equal_approx(value, 2.0):
		return "twice"
	return _n(value) + " times"


static func _word(value: int) -> String:
	var words: Array[String] = [
		"zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"
	]
	return words[value] if value >= 0 and value < words.size() else str(value)


static func _n(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)


static func _start(words: String) -> String:
	return words.substr(0, 1).to_upper() + words.substr(1)
