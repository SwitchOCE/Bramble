class_name Pass3OozeText
extends RefCounted
## Ooze faces, borrowed fragments and rate parameters share one resolved source.


static func is_native(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) == "pass3_ooze":
			return true
	return false


static func configure(card: Dictionary, config: GameConfig) -> void:
	if not is_native(card):
		return
	card["pass3_rates"] = Pass3Rates.resolved(config)
	card.erase(MechanicRegistry.COMPILED_KEY)
	_parameters(card, config)
	for golden: bool in [false, true]:
		card["golden_text" if golden else "text"] = face(card, config, golden)
		card["golden_details" if golden else "details"] = details(card, config, golden)
	var fragments: Dictionary = {}
	var entries: Array = card.get("mechanics", [])
	var lendable: Array[int] = []
	for index: int in entries.size():
		var entry: Dictionary = entries[index]
		if RecruitUnit._can_lend(entry):
			lendable.append(index)
	if not lendable.is_empty() and lendable.size() != entries.size():
		for index: int in lendable:
			var entry: Dictionary = entries[index]
			var fragment: Dictionary = {"id": str(entry["id"])}
			for golden: bool in [false, true]:
				var words: String = face(card, config, golden)
				var belly: int = _belly(card, config) * (2 if golden else 1)
				words = words.trim_prefix("Belly %d. " % belly)
				words = words.trim_prefix("Digest. ").trim_prefix("Cleave. ")
				fragment["golden_text" if golden else "text"] = words
			fragments[str(index)] = fragment
	card["mechanic_text"] = fragments


static func _parameters(card: Dictionary, config: GameConfig) -> void:
	var id: String = str(card["id"])
	for entry: Dictionary in card["mechanics"]:
		match str(entry["id"]):
			"belly":
				entry["size"] = _belly(card, config)
			"belly_discount":
				entry["gold"] = Pass3Rates.integer(config, "oozes_dollop_discount")
			"bubble":
				entry["splits"] = Pass3Rates.integer(config, "oozes_bubble_splits")
			"wobbly":
				entry["drip"] = Pass3Rates.integer(config, "oozes_wobbly_drip")
			"pie":
				entry["per_unit"] = Pass3Rates.integer(config, "oozes_pie_gold")
			"syllabub":
				entry["times"] = Pass3Rates.integer(config, "oozes_syllabub_fires")
			"pass3_ooze":
				match id:
					"mrs_posset":
						entry["loss_share"] = Pass3Rates.number(config, "oozes_posset_loss_share")
					"stone_soup":
						entry["share"] = Pass3Rates.number(config, "oozes_soup_share")
						entry["golden_reads"] = Pass3Rates.integer(
							config, "oozes_golden_soup_reads"
						)
					"dishwater_nell":
						entry["count"] = Pass3Rates.integer(config, "oozes_nell_meals")
					"moss_ooze":
						entry["reduction"] = Pass3Rates.integer(
							config, "oozes_moss_golden_reduction"
						)
					"aunt_aspic":
						entry["bonus"] = Pass3Rates.number(config, "oozes_aspic_bonus")
						entry["golden_multiplier"] = Pass3Rates.number(
							config, "oozes_golden_aspic_multiplier"
						)
					"frumenty":
						entry["meals"] = Pass3Rates.integer(config, "oozes_frumenty_meals")
					"elder_ooze":
						entry["share"] = Pass3Rates.number(config, "oozes_elder_share")
						entry["golden_multiplier"] = Pass3Rates.number(
							config, "oozes_golden_elder_multiplier"
						)
					"hasty_pudding":
						entry["share"] = Pass3Rates.number(config, "oozes_hasty_share")
						entry["count"] = Pass3Rates.integer(config, "oozes_hasty_swallows")
						entry["after"] = Pass3Rates.integer(config, "oozes_hasty_release_deaths")
					"granny_stir_up":
						entry["attack_multiplier"] = Pass3Rates.number(
							config, "oozes_granny_attack_multiplier"
						)
					"cut_and_come_again":
						entry["share"] = Pass3Rates.number(config, "oozes_slice_share")
						entry["count"] = Pass3Rates.integer(config, "oozes_slice_count")


static func _belly(card: Dictionary, config: GameConfig) -> int:
	var id: String = str(card.get("id", ""))
	if id == "little_dollop":
		return Pass3Rates.integer(config, "oozes_dollop_belly")
	if id == "bubble_and_squeak":
		return Pass3Rates.integer(config, "oozes_bubble_belly")
	if id == "sixpenny_pie":
		return 2
	if id == "hasty_pudding":
		return Pass3Rates.integer(config, "oozes_hasty_swallows")
	if id in ["mrs_posset", "wee_wobbly", "frumenty", "figgy_duff"]:
		return 1
	return 0


static func face(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	var id: String = str(card.get("id", ""))
	var factor: int = 2 if golden else 1
	var belly: String = "Belly %d. " % (_belly(card, config) * factor)
	match id:
		"little_dollop":
			return (
				belly
				+ (
					"Digest. Buying into this costs %d gold less."
					% (Pass3Rates.integer(config, "oozes_dollop_discount") * factor)
				)
			)
		"mrs_posset":
			return (
				belly
				+ (
					"When this dies: %s %s %s."
					% [
						"its killer and the units beside it" if golden else "its killer",
						"lose" if golden else "loses",
						Pass3Text._stats(
							Pass3Rates.number(config, "oozes_posset_loss_share"),
							"their" if golden else "its"
						)
					]
				)
			)
		"wee_wobbly":
			var drip: int = Pass3Rates.integer(config, "oozes_wobbly_drip") * factor
			return (
				belly
				+ (
					"After this survives a hit: what's inside comes out, or a %d/%d Drip."
					% [drip, drip]
				)
			)
		"stone_soup":
			var reads: int = Pass3Rates.integer(config, "oozes_golden_soup_reads") if golden else 1
			var noun: String = (
				"your biggest Ooze's" if reads == 1 else "your %s biggest Oozes'" % _word(reads)
			)
			return (
				"Shop units gain %s."
				% Pass3Text._stats(Pass3Rates.number(config, "oozes_soup_share"), noun)
			)
		"dishwater_nell":
			var meals: int = Pass3Rates.integer(config, "oozes_nell_meals") * factor
			if meals == 1:
				return "Start of Turn: the biggest Ooze next to this eats your shop's lowest-tier unit."
			return (
				"Start of Turn: the %s biggest Oozes next to this eat your shop's %s lowest-tier units."
				% [_word(meals), _word(meals)]
			)
		"moss_ooze":
			return (
				"When a unit comes out of your Oozes: it gains Shield%s."
				% (
					(
						" and Damage Reduction %d%%"
						% Pass3Rates.integer(config, "oozes_moss_golden_reduction")
					)
					if golden
					else ""
				)
			)
		"aunt_aspic":
			if golden:
				var multiple: float = Pass3Rates.number(config, "oozes_golden_aspic_multiplier")
				var words: String = (
					"double"
					if is_equal_approx(multiple, 2.0)
					else "%s times as many" % _n(multiple)
				)
				return "Oozes in front of this gain %s stats from eating non-Oozes." % words
			return (
				"Oozes in front of this gain %s%% more from eating non-Oozes."
				% _n(Pass3Rates.number(config, "oozes_aspic_bonus") * 100.0)
			)
		"bubble_and_squeak":
			var count: int = Pass3Rates.integer(config, "oozes_bubble_splits") * factor
			return (
				belly
				+ "Digest. After this survives a hit: split in two. %s a fight." % _count(count)
			)
		"sixpenny_pie":
			return (
				belly
				+ (
					"When this dies: get %d gold per unit that comes out."
					% Pass3Rates.integer(config, "oozes_pie_gold")
				)
			)
		"frumenty":
			var count: int = Pass3Rates.integer(config, "oozes_frumenty_meals") * factor
			return (
				belly
				+ (
					"Digest. This has the text of its last %s."
					% ("meal" if count == 1 else _word(count) + " meals")
				)
			)
		"figgy_duff":
			return belly + "What's inside goes golden when you buy another copy."
		"mr_syllabub":
			var count: int = Pass3Rates.integer(config, "oozes_syllabub_fires") * factor
			return (
				"When a unit comes out of your Oozes: its Start of Combat fires%s."
				% ("" if count == 1 else " twice" if count == 2 else " %s times" % _word(count))
			)
		"elder_ooze":
			var share: float = Pass3Rates.number(config, "oozes_elder_share")
			if golden:
				share *= Pass3Rates.number(config, "oozes_golden_elder_multiplier")
			return (
				"After your biggest Ooze eats a non-Ooze: your other Oozes gain %s."
				% Pass3Text._stats(share, "its")
			)
		"hasty_pudding":
			var count: int = Pass3Rates.integer(config, "oozes_hasty_swallows") * factor
			var who: String = (
				"the biggest enemy" if count == 1 else "the %s biggest enemies" % _word(count)
			)
			return (
				belly
				+ (
					"Start of Combat: if empty, swallow %s. Your biggest Ooze permanently gains %s."
					% [
						who,
						(
							Pass3Text._fraction(Pass3Rates.number(config, "oozes_hasty_share"))
							+ " of "
							+ ("it" if count == 1 else "each")
						)
					]
				)
			)
		"granny_stir_up":
			var multiple: float = (
				Pass3Rates.number(config, "oozes_granny_attack_multiplier") * factor
			)
			var amount: String = (
				"their Attack"
				if is_equal_approx(multiple, 1.0)
				else (
					"twice their Attack"
					if is_equal_approx(multiple, 2.0)
					else "%s times their Attack" % _n(multiple)
				)
			)
			return "Cleave. Start of Combat: touching Oozes go inside. Gain %s." % amount
		"cut_and_come_again":
			var count: int = Pass3Rates.integer(config, "oozes_slice_count") * factor
			return (
				"Start of Turn: get %s with %s."
				% [
					"a Slice" if count == 1 else _word(count) + " Slices",
					Pass3Text._stats(
						Pass3Rates.number(config, "oozes_slice_share"), "your biggest Ooze's"
					)
				]
			)
	return ""


static func details(card: Dictionary, config: GameConfig, _golden: bool = false) -> String:
	var words: String = ""
	match str(card.get("id", "")):
		"little_dollop", "aunt_aspic", "elder_ooze":
			words = (
				"Eating destroys the meal, returns its pool copies and grants its own "
				+ "base plus permanent stats; no tribe bonus, Rings or auras. No sale "
				+ "gold."
			)
			if str(card["id"]) == "aunt_aspic":
				words += " Only the strongest Aspic serving an eater counts. Eating Oozes earns no bonus."
			if str(card["id"]) == "elder_ooze":
				words += (
					" Only other Oozes on your board gain; not units in hand or Bellies. The "
					+ "meal's stats are read before Aspic."
				)
		"mrs_posset":
			words = (
				"The killer is the unit whose attack or effect dealt the killing "
				+ "damage. Losses round down; Attack stays at least 0 and Health at least "
				+ "1. Lasts this fight."
			)
		"wee_wobbly":
			words = (
				"Only hits that deal damage count. If there is no room, contents stay "
				+ "inside. Empty Bellies create Drips."
			)
		"stone_soup":
			words = (
				"Shown live and kept when bought. Only your best Stone Soup counts. "
				+ (
					"Shares round down. Golden reads the sum of your %s biggest Oozes."
					% _word(Pass3Rates.integer(config, "oozes_golden_soup_reads"))
				)
			)
		"dishwater_nell":
			words = (
				"After Digest, eats only unfrozen shop units. Next to means beside, in "
				+ "front or behind. The bigger Ooze eats first, one meal each. Soup "
				+ "updates between meals."
			)
		"moss_ooze":
			words = (
				"Your own units only, in fights. Granny's family counts; returned enemy "
				+ "prisoners do not. Shield does not stack."
			)
		"bubble_and_squeak":
			words = (
				"Digest eats its contents at Start of Turn. Only hits that deal damage "
				+ "count; Shield stopping the whole hit cannot split. The nearest empty "
				+ "slot receives half its current stats and an empty Belly. Halves never "
				+ "split."
			)
		"sixpenny_pie":
			words = (
				"Gold arrives next turn. Only units that actually find room to come out "
				+ "count. Golden keeps the same gold per unit; its larger Belly can pay "
				+ "more."
			)
		"frumenty":
			words = (
				"Digest eats its contents at Start of Turn. Keeps the most recent meals "
				+ "permanently. Cannot borrow Belly, Digest, Fly South, Shy, on-play, "
				+ "on-sell or homecoming text. Borrowed text reads from its own slot."
			)
		"figgy_duff":
			words = (
				"Both copies must be bought. The golden goes to your hand, keeps all "
				+ "copies' buffs and gives a Triple Reward when played."
			)
		"mr_syllabub":
			words = (
				"Fights only. Friendly units emerging from your Oozes replay their "
				+ "Start of Combat text, using their current slot. Extra triggers cannot "
				+ "repeat a doubling or move a countdown."
			)
		"hasty_pudding":
			words = (
				"Swallows after other opening buffs; sees through Bellies and swallows "
				+ "the container. Each gain reads the swallowed enemy's own base plus "
				+ "permanent stats, excluding fight-only buffs, and goes to your biggest "
				+ "Ooze's recruit copy."
			)
			words += (
				(
					" Prisoners return when this dies, after %d friendly deaths,"
					+ " or when their side has nobody else."
				)
				% Pass3Rates.integer(config, "oozes_hasty_release_deaths")
			)
		"granny_stir_up":
			words = (
				"Touching means an unbroken zigzag run through this slot. Gathers after "
				+ "your other Start of Combat effects, including Hasty. The family "
				+ "returns whole to its own slots when Granny dies."
			)
		"cut_and_come_again":
			words = "Created Slices have no tribe or text. Shares round down. A full hand loses the Slice."
	return words


static func _word(value: int) -> String:
	return Pass3Text._word(value)


static func _n(value: float) -> String:
	return Pass3Text._n(value)


static func _count(value: int) -> String:
	return "Once" if value == 1 else "Twice" if value == 2 else "%s times" % _word(value)
