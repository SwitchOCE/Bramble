class_name Pass3BogText
extends RefCounted
## Bog faces and rulings come from the same resolved dials as their abilities.


static func is_native(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "pass3_bog":
			return true
		if str(card.get("id", "")) == "peatling" and CoreUtil.to_bool(entry.get("pass3", false)):
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
		if str(entry.get("id", "")) != "pass3_bog":
			continue
		var fragment: Dictionary = {"id": "pass3_bog"}
		for golden: bool in [false, true]:
			var words: String = _face(card, config, golden)
			if str(entry.get("ability", "")) == "soak":
				words = "Soak."
			else:
				for prefix: String in ["Mire. ", "Snap. ", "Bitter. ", "Soak. "]:
					words = words.trim_prefix(prefix)
			fragment["golden_text" if golden else "text"] = words
		fragments[str(index)] = fragment
	card["mechanic_text"] = fragments
	var overrides: Dictionary = card.get("keyword_text_overrides", {})
	overrides["Bitter"] = bitter_reminder(config)
	overrides["Soak"] = soak_reminder(config)
	overrides["Sink"] = "After a Mired enemy dies."
	overrides["Toll"] = "The Attack your Bitter took in your last fight."
	overrides["kiss"] = "Your frogs share kisses; each fight with a Sink adds to the count."
	card["keyword_text_overrides"] = overrides


static func face(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	var words: String = _face(card, config, golden)
	if _capstone_gain(card, config):
		words = "When played: gain the Toll. " + words
	return words


static func _face(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	var factor: int = 2 if golden else 1
	var id: String = str(card.get("id", ""))
	match id:
		"bridge_toad":
			return "Mire. Soak."
		"warty_nan":
			return (
				"Bitter. Start of Turn: your smallest Bog folk gains %s."
				% _share(_rate(config, "nan_share", golden), "the Toll")
			)
		"young_pretender":
			return (
				"Snap. After this kills a Mired enemy: get %d gold next turn."
				% (Pass3Rates.integer(config, "bog_pretender_gold") * factor)
			)
		"madame_bufo":
			return (
				"Mire. Bitter. If its Mired enemy kills this, halve its Attack%s."
				% _repeat(Pass3Rates.integer(config, "bog_bufo_halvings") * factor)
			)
		"vaulting_hopkin":
			return (
				"Snap. In the back row: attacks first, using %s."
				% _share(
					Pass3Rates.number(config, "bog_hopkin_share") * factor,
					"the highest Attack in front"
				)
			)
		"peat_cutter":
			return (
				"Mire. Sink: get %d gold next turn. Once a fight."
				% (Pass3Rates.integer(config, "bog_cutter_gold") * factor)
			)
		"gideon":
			return (
				"Mire. Soak. After its Mired enemy attacks this: hit it back%s."
				% _repeat(Pass3Rates.integer(config, "bog_gideon_hitbacks") * factor)
			)
		"natterjack_chorus":
			var count: int = Pass3Rates.integer(config, "bog_chorus_lends")
			return (
				"Your Bog folk beside this have Mire and Soak."
				if count >= 2
				else "Your first %d Bog folk beside this have Mire and Soak." % count
			)
		"spitfire_sal":
			return (
				"Start of Combat: deal %s, split among Mired enemies."
				% _share(Pass3Rates.number(config, "bog_sal_toll_multiplier") * factor, "the Toll")
			)
		"tiddy_mun":
			return (
				"Start of Turn: the units beside this split %s."
				% _share(_rate(config, "tiddy_share", golden), "the Toll")
			)
		"his_highness", "prince_restored":
			var multiplier: float = _rate(config, "frog_multiplier", golden)
			var verb: String = (
				"double"
				if is_equal_approx(multiplier, 2.0)
				else (
					"triple"
					if is_equal_approx(multiplier, 3.0)
					else "multiply by " + _n(multiplier)
				)
			)
			var suffix: String = (
				" First time: become %s Prince." % ("a golden" if golden else "the")
				if id == "his_highness"
				else ""
			)
			return (
				"%s Every %s kiss: %s the units beside this.%s"
				% [
					"Snap." if id == "his_highness" else "Mire. Soak.",
					_ordinal(Pass3Rates.integer(config, "bog_kiss_period")),
					verb,
					suffix,
				]
			)
		"signor_ranocchio":
			return (
				"Snap. After this attacks a Mired enemy: gain %s as +Attack/+Health permanently."
				% _share(_rate(config, "ranocchio_share", golden), "its Attack")
			)
		"prima_donna":
			var patches: int = Pass3Rates.integer(config, "bog_prima_donna_patches")
			return (
				"Mire the slot across and the slots beside it. Soak."
				if patches == 3
				else "Mire up to %d slots across and beside it. Soak." % patches
			)
		"jenny_greenteeth":
			var pulls: int = Pass3Rates.integer(config, "bog_jenny_pulls")
			return (
				"Mire. Soak. Start of Combat: pull the biggest enemy in the row across to face this."
				if pulls == 1
				else (
					"Mire. Soak. Start of Combat: pull the row's biggest enemy across%s."
					% _repeat(pulls)
				)
			)
		"peat_king":
			return (
				"Mire. Soak. Sink: it rises for you as a Peatling. %s a fight."
				% _count(Pass3Rates.integer(config, "bog_king_peatlings") * factor)
			)
		"lantern_man":
			var count: int = Pass3Rates.integer(config, "bog_lantern_lures") * factor
			return (
				"Mire %s, wherever %s. Soak."
				% [
					"the biggest enemy" if count == 1 else "the %d biggest enemies" % count,
					"it stands" if count == 1 else "they stand",
				]
			)
		"peatling":
			return "Bitter."
	return ""


static func details(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	var id: String = str(card.get("id", ""))
	var words: String = ""
	match id:
		"warty_nan":
			words = (
				"Gives the Toll share as +Attack/+Health permanently, rounded down;"
				+ " ties use reading order."
			)
		"madame_bufo":
			words = "Only the enemy on this unit's patch can trigger the halving."
		"vaulting_hopkin":
			words = (
				"For its first attack only; uses its own Attack if higher."
				+ " In front means the two front slots before it."
			)
		"gideon":
			words = "The hit back deals this unit's Attack without retaliation."
		"natterjack_chorus":
			words = "Only Bog folk in the same row receive the lend; own and lent Soak do not stack."
		"spitfire_sal":
			words = "Uses last fight's Toll after patches are laid; damage splits evenly, rounded down."
		"tiddy_mun":
			words = (
				"Splits its share as permanent +Attack/+Health among occupied units"
				+ " beside this in the same row; the share and each split round down."
			)
		"his_highness", "prince_restored":
			words = (
				(
					"Frogs share kisses; gain %d per fight with a Sink while a frog is out."
					% Pass3Rates.integer(config, "bog_kisses_per_fight")
				)
				+ " Growth uses base plus permanent stats, never fight-only buffs."
				+ (
					" A unit grows at most %d time(s) a turn; the strongest frog applies."
					% Pass3Rates.integer(config, "bog_frog_doubles_per_turn")
				)
			)
			if id == "his_highness":
				words += " The Prince keeps this unit's buffs and slot."
		"signor_ranocchio":
			words = (
				"Fractions round down. Gains even if retaliation kills this;"
				+ " pays at your next Start of Turn."
			)
		"jenny_greenteeth":
			words = "Pulls before patches; skips the Lantern's target. Slot effects stay in their slots."
		"peat_king":
			words = (
				(
					"Peatlings rise in the nearest empty slot with %s and only Bitter;"
					+ " copied stats round down and last this fight."
				)
				% _share(
					Pass3Rates.number(config, "bog_peatling_stat_share"),
					"the enemy's starting stats"
				)
			)
		"lantern_man":
			words = (
				"Lays its patches first; biggest means Attack plus Health,"
				+ " including units inside Bellies."
			)
		"peatling":
			words = "A combat-only copy of a sunk enemy, with only Bitter."
	if _capstone_gain(card, config):
		words += (
			" When played: permanently gain +Attack/+Health equal to the Toll;"
			+ " golden gains the same amount."
		)
	if _has_soak(card) or id == "natterjack_chorus":
		var keep: String = _n(_rate(config, "soak_keep", golden))
		var enemies: String = (
			"its own Mired enemies"
			if Pass3Rates.enabled(config, "bog_soak_mired_only")
			else "any enemies"
		)
		words += (
			(
				" Soak keeps +%s/+%s per Attack Bitter took from %s,"
				+ " at your next Start of Turn, even if this died. Each bite's gain rounds down."
			)
			% [keep, keep, enemies]
		)
	if _has_soak(card) or id in ["warty_nan", "madame_bufo", "peatling", "natterjack_chorus"]:
		words += (
			" Bitter fractions round %s; the biter keeps at least 1 Attack."
			% ("up" if Pass3Rates.enabled(config, "bog_bitter_round_up") else "down")
		)
	return words.strip_edges()


static func bitter_reminder(config: GameConfig) -> String:
	return (
		"Before an enemy hits this, it loses %s."
		% _share(Pass3Rates.number(config, "bog_bitter_share"), "its Attack")
	)


static func soak_reminder(config: GameConfig) -> String:
	var keep: String = _n(Pass3Rates.number(config, "bog_soak_keep"))
	var golden_keep: String = _n(Pass3Rates.number(config, "bog_golden_soak_keep"))
	var enemies: String = (
		"its Mired enemies" if Pass3Rates.enabled(config, "bog_soak_mired_only") else "any enemy"
	)
	return (
		"Bitter. Next Start of Turn: keep +%s/+%s per Attack taken from %s; golden +%s/+%s."
		% [keep, keep, enemies, golden_keep, golden_keep]
	)


static func _has_soak(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "pass3_bog" and str(entry.get("ability", "")) == "soak":
			return true
	return false


static func _rate(config: GameConfig, name: String, golden: bool) -> float:
	return Pass3Rates.number(config, "bog_" + ("golden_" if golden else "") + name)


static func _n(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)


static func _share(value: float, noun: String) -> String:
	if is_equal_approx(value, 1.0):
		return noun
	if is_equal_approx(value, 0.5):
		return "half " + noun
	for pair: Array in [
		[0.25, "a quarter"],
		[0.75, "three quarters"],
		[1.0 / 3.0, "a third"],
		[2.0 / 3.0, "two thirds"]
	]:
		if is_equal_approx(value, CoreUtil.to_float(pair[0])):
			return str(pair[1]) + " of " + noun
	if is_equal_approx(value, 2.0):
		return "twice " + noun
	return _n(value * 100.0) + "% of " + noun


static func _repeat(count: int) -> String:
	return "" if count == 1 else " twice" if count == 2 else " %d times" % count


static func _count(count: int) -> String:
	return "Once" if count == 1 else "Twice" if count == 2 else "%d times" % count


static func _ordinal(count: int) -> String:
	if count == 3:
		return "third"
	if count == 4:
		return "fourth"
	if count == 2:
		return "second"
	return str(count) + ("st" if count % 10 == 1 and count % 100 != 11 else "th")


static func _capstone_gain(card: Dictionary, config: GameConfig) -> bool:
	return (
		str(card.get("id", "")) in ["prima_donna", "jenny_greenteeth", "peat_king", "lantern_man"]
		and Pass3Rates.enabled(config, "bog_capstone_gain_toll")
	)
