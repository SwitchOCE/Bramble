class_name Pass3Text
extends RefCounted
## Native pass 3 faces are generated from resolved rates. JSON text is a checked copy.

const FIXED_FACES: Dictionary = {
	"belladonna":
	[
		"Start of Combat: give the enemy across Nightshade.",
		"Start of Combat: give the enemy across and the units beside it Nightshade.",
	],
	"changeling":
	[
		"Start of Combat: steal the enemy across until it attacks.",
		"Start of Combat: steal the enemy across until it attacks twice.",
	],
	"hedge_witch":
	[
		"Start of Combat: the enemy across loses Attack equal to this slot's Ring.",
		"Start of Combat: the enemy across loses Attack equal to twice this slot's Ring.",
	],
	"hob_in_the_hearth":
	[
		"Shy. Start of Combat: your biggest Fairy gains Shield.",
		"Shy. Start of Combat: your two biggest Fairies gain Shield.",
	],
	"mag_pye":
	[
		"Start of Combat: your biggest Bird steals the text of the enemy across.",
		"Start of Combat: your biggest Bird steals the text of the enemy across and one next to it.",
	],
	"old_tern":
	[
		"Fly South. When this comes home: so do your Birds that missed a fight.",
		"Fly South. When this comes home: so do your Birds that missed a fight.",
	],
}
const FRACTIONS: Dictionary = {
	2: ["half", "halves"],
	3: ["third", "thirds"],
	4: ["quarter", "quarters"],
	5: ["fifth", "fifths"],
	6: ["sixth", "sixths"],
	7: ["seventh", "sevenths"],
	8: ["eighth", "eighths"],
	9: ["ninth", "ninths"],
	10: ["tenth", "tenths"],
	12: ["twelfth", "twelfths"],
	16: ["sixteenth", "sixteenths"],
	20: ["twentieth", "twentieths"],
}


static func configure(card: Dictionary, config: GameConfig) -> void:
	if Pass3BogText.is_native(card):
		Pass3BogText.configure(card, config)
		return
	if not _is_pass3(card) and str(card.get("id", "")) != "golden_egg":
		return
	card["pass3_rates"] = Pass3Rates.resolved(config)
	for golden: bool in [false, true]:
		if golden and not card.has("golden_text"):
			continue
		var words: String = face(card, config, golden)
		if not words.is_empty():
			_set_text(card, golden, words, config)
	_details(card, config)
	_flight(card, config)


## Pure generation never consults text/golden_text, including at the default rates.
static func face(card: Dictionary, config: GameConfig, golden: bool = false) -> String:
	if Pass3BogText.is_native(card):
		return Pass3BogText.face(card, config, golden)
	var id: String = str(card.get("id", ""))
	if FIXED_FACES.has(id):
		var pair: Array = FIXED_FACES[id]
		return str(pair[1 if golden else 0])
	var words: String = _bird(card, golden, config)
	if words.is_empty():
		words = _bird_combat(id, golden, config)
	if words.is_empty():
		words = _fairy(id, golden, config)
	return words


static func _is_pass3(card: Dictionary) -> bool:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("id", "")) in ["pass3_bird", "pass3_fairy", "pass3_bog"]:
			return true
	return false


static func _n(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)


static func _word(value: int) -> String:
	var words: Array[String] = [
		"zero", "one", "two", "three", "four", "five", "six", "seven", "eight"
	]
	return words[value] if value >= 0 and value < words.size() else str(value)


static func _fraction(value: float) -> String:
	if is_equal_approx(value, 1.0):
		return "all"
	for denominator: int in FRACTIONS:
		var numerator: int = roundi(value * denominator)
		if numerator <= 0 or not is_equal_approx(value, float(numerator) / denominator):
			continue
		var names: Array = FRACTIONS[denominator]
		if numerator > 1:
			return "%s %s" % [_word(numerator), str(names[1])]
		if denominator == 2:
			return "half"
		return ("an " if denominator == 8 else "a ") + str(names[0])
	return _n(value * 100.0) + "%"


static func _stats(value: float, whose: String) -> String:
	if is_equal_approx(value, 2.0):
		return "twice %s stats" % whose
	var share: String = _fraction(value)
	return (
		"%s %s stats" % [share, whose]
		if share in ["half", "all"]
		else "%s of %s stats" % [share, whose]
	)


static func _biggest(count: int, noun: String, other: bool = false) -> String:
	var extra: String = "other " if other else ""
	if count == 1:
		return "your biggest %s%s" % [extra, noun]
	return "your %s biggest %s%ss" % [_word(count), extra, noun]


static func _start(words: String) -> String:
	return words.substr(0, 1).to_upper() + words.substr(1)


static func _repeat(count: int) -> String:
	if count == 1:
		return ""
	return " twice" if count == 2 else " %s times" % _word(count)


static func _multiply(value: float) -> String:
	if is_equal_approx(value, 2.0):
		return "double"
	if is_equal_approx(value, 3.0):
		return "triple"
	return "multiply"


static func _effect_number(card: Dictionary, name: String, key: String) -> int:
	for entry: Dictionary in card.get("mechanics", []):
		if str(entry.get("name", "")) == name:
			for step: Dictionary in MechanicRegistry.steps_of(entry):
				if step.has(key):
					return CoreUtil.to_int(step[key])
	return 0


static func _bird(card: Dictionary, golden: bool, config: GameConfig) -> String:
	var id: String = str(card.get("id", ""))
	var factor: int = 2 if golden else 1
	match id:
		"one_swallow":
			return (
				"Fly South. %s When played: get %d gold."
				% [
					_trip_sentence(id, golden, config),
					_effect_number(card, "swallow_gold", "amount") * factor
				]
			)
		"chiffchaff":
			var gain: int = _effect_number(card, "chiffchaff", "attack") * factor
			return "Fly South. When played: gain +%d/+%d." % [gain, gain]
		"mrs_jay":
			var count: int = _effect_number(card, "jay", "count") * factor
			return (
				"Fly South. When sold: get %s."
				% ("an Acorn" if count == 1 else _word(count) + " Acorns")
			)
		"mr_redbreast", "cuckoo":
			var name: String = "redbreast" if id == "mr_redbreast" else "cuckoo"
			var who: String = "gain" if name == "redbreast" else "other Birds gain"
			return (
				"After a Bird comes home: %s %s."
				% [
					who,
					_stats(Pass3Rates.number(config, "birds_" + name + "_share") * factor, "its")
				]
			)
		"jack_daw":
			var permanent: String = (
				"permanently " if Pass3Rates.enabled(config, "birds_jack_daw_permanent") else ""
			)
			return (
				"Start of Combat: your biggest Bird %ssteals %s of the enemy across."
				% [
					permanent,
					_stats(Pass3Rates.number(config, "birds_jack_daw_share") * factor, "the")
				]
			)
		"mrs_stork":
			var count: int = Pass3Rates.integer(config, "birds_stork_recalls") * factor
			return (
				"Every %d gold you spend: %s %s that missed a fight %s home."
				% [
					Pass3Rates.integer(config, "birds_stork_gold_step"),
					"a" if count == 1 else _word(count),
					"Bird" if count == 1 else "Birds",
					"comes" if count == 1 else "come"
				]
			)
		"mrs_dunnock":
			var count: int = Pass3Rates.integer(config, "birds_dunnock_targets") * factor
			var turns: int = Pass3Rates.integer(config, "birds_dunnock_turns")
			return (
				"End of Turn: %s away %s home %s sooner."
				% [
					_biggest(count, "Bird"),
					"comes" if count == 1 else "come",
					"a turn" if turns == 1 else "%d turns" % turns
				]
			)
		"mother_goose":
			if not Pass3Rates.enabled(config, "birds_golden_egg_enabled"):
				return "Fly South."
			return (
				"Fly South. When played: get %s."
				% ("a Golden Egg" if not golden else "two Golden Eggs")
			)
		"golden_egg":
			var multiplier: float = Pass3Rates.number(config, "birds_golden_egg_multiplier")
			return (
				"%s a Bird's stats%s. Once per Bird."
				% [
					_start(_multiply(multiplier)),
					" by " + _n(multiplier) if _multiply(multiplier) == "multiply" else ""
				]
			)
	return ""


static func _bird_combat(id: String, golden: bool, config: GameConfig) -> String:
	var factor: int = 2 if golden else 1
	match id:
		"tom_tit":
			var count: int = Pass3Rates.integer(config, "birds_tom_tit_targets") * factor
			return (
				"%s %s Damage Reduction %d%%."
				% [
					_start(_biggest(count, "Bird", true)),
					"has" if count == 1 else "have",
					Pass3Rates.integer(config, "birds_tom_tit_reduction")
				]
			)
		"redwing":
			var count: int = Pass3Rates.integer(config, "birds_redwing_targets") * factor
			return (
				"%s away %s Eggs with %s."
				% [
					_start(_biggest(count, "Bird")),
					"leaves" if count == 1 else "leave",
					_stats(Pass3Rates.number(config, "birds_redwing_share"), "their")
				]
			)
		"great_lump":
			var amount: float = Pass3Rates.number(config, "birds_lump_multiplier") * factor
			var times: String = (
				""
				if is_equal_approx(amount, 1.0)
				else "twice " if is_equal_approx(amount, 2.0) else _n(amount) + " times "
			)
			return "Cleave. On a Nest, this has %sits Bird's stats too." % times
		"gabble_ratchet":
			var amount: float = Pass3Rates.number(config, "birds_ratchet_multiplier") * factor
			var extra: String = ""
			if not is_equal_approx(amount, 1.0):
				extra = (
					" with %s stats" % _multiply(amount)
					if _multiply(amount) != "multiply"
					else " with %s times its stats" % _n(amount)
				)
			return "When a unit on a Nest dies: its Bird drops in%s." % extra
		"seven_whistlers":
			var share: float = Pass3Rates.number(config, "birds_whistlers_loss_share")
			var repeat: String = " twice" if golden else ""
			var across: String = (
				"halve the enemy across"
				if is_equal_approx(share, 0.5)
				else "the enemy across loses " + _stats(share, "its")
			)
			var every: String = (
				"halve every enemy"
				if is_equal_approx(share, 0.5)
				else "every enemy loses " + _stats(share, "its")
			)
			return (
				"Start of Combat: %s%s. With %s different Birds, %s%s."
				% [
					across,
					repeat,
					_word(Pass3Rates.integer(config, "birds_whistlers_flock_count")),
					every,
					repeat
				]
			)
	return ""


static func _fairy(id: String, golden: bool, config: GameConfig) -> String:
	var factor: int = 2 if golden else 1
	match id:
		"cluricaun", "silky", "lob_lie_by_the_fire":
			var rate: String = (
				"fairies_ring_growth"
				if id == "cluricaun"
				else "fairies_silky_growth" if id == "silky" else "fairies_lob_growth"
			)
			var growth: String = _n(Pass3Rates.number(config, rate) * factor)
			var prefix: String = (
				"End of Turn: if every slot has a Ring,"
				if id == "cluricaun"
				else "Shy. After a Shy unit leaves:" if id == "silky" else "Shy. When this leaves:"
			)
			var period: String = (
				" per %d turns it stayed" % Pass3Rates.integer(config, "fairies_lob_turns")
				if id == "lob_lie_by_the_fire"
				else ""
			)
			return "%s your Rings grow +%s/+%s%s." % [prefix, growth, growth, period]
		"cradle_fetch":
			var share: float = Pass3Rates.number(config, "fairies_fetch_share")
			var stats: String = (
				"half stats"
				if is_equal_approx(share, 0.5)
				else (
					"full stats"
					if is_equal_approx(share, 1.0)
					else "double stats" if is_equal_approx(share, 2.0) else _stats(share, "its")
				)
			)
			return (
				"Start of Combat: become a %scopy of the Fairy behind, Ring and all, with %s."
				% ["golden " if golden else "", stats]
			)
		"fairy_monarch":
			var amount: float = Pass3Rates.number(
				config,
				"fairies_golden_monarch_multiplier" if golden else "fairies_monarch_multiplier"
			)
			var verb: String = _multiply(amount)
			return (
				"%s: %s your Ring size%s."
				% [
					_period(Pass3Rates.integer(config, "fairies_monarch_period")),
					verb,
					" by " + _n(amount) if verb == "multiply" else ""
				]
			)
		"reel_mistress":
			var moves: int = Pass3Rates.integer(config, "fairies_reel_moves") * factor
			return (
				"After a unit on a Ring attacks: its Ring moves to your next unit. %s per Ring."
				% ("Once" if moves == 1 else _start(_repeat(moves).strip_edges()))
			)
		"queen_of_elfland":
			return (
				"%s: destroy the units behind this. Ring every slot%s for each."
				% [
					_period(Pass3Rates.integer(config, "fairies_queen_period"), "Start of Turn"),
					_repeat(Pass3Rates.integer(config, "fairies_queen_rings") * factor)
				]
			)
		"old_moth_annis":
			var timing: String = (
				"End of Turn and after you sell"
				if Pass3Rates.enabled(config, "fairies_annis_sale")
				else "End of Turn"
			)
			return (
				"%s: Ring the slots behind this%s."
				% [timing, _repeat(Pass3Rates.integer(config, "fairies_annis_rings") * factor)]
			)
		"nan_toadstool":
			return (
				"When played or sold: Ring this slot%s."
				% _repeat(Pass3Rates.integer(config, "fairies_nan_rings") * factor)
			)
		"sally_spore":
			return (
				"End of Turn: Ring your empty slot nearest this%s."
				% _repeat(Pass3Rates.integer(config, "fairies_sally_rings") * factor)
			)
		"rainbow_chaser":
			return (
				"When sold: get %d gold per slot with a Ring."
				% (Pass3Rates.integer(config, "fairies_chaser_gold") * factor)
			)
		"will_o_the_wisp":
			return (
				"Start of Combat: summon a %d/%d Wisp into each empty Ring."
				% [
					Pass3Rates.integer(config, "fairies_wisp_attack") * factor,
					Pass3Rates.integer(config, "fairies_wisp_health") * factor
				]
			)
	return ""


static func _period(turns: int, timing: String = "End of Turn") -> String:
	if turns == 1:
		return timing
	var suffix: String = "th"
	if turns % 100 not in [11, 12, 13]:
		match turns % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"
	return "Every %d%s %s" % [turns, suffix, timing]


static func _set_text(card: Dictionary, golden: bool, words: String, config: GameConfig) -> void:
	var field: String = "golden_text" if golden else "text"
	card[field] = words
	var fragments: Dictionary = card.get("mechanic_text", {})
	for key: String in fragments:
		var fragment: Dictionary = fragments[key]
		if str(fragment.get("id", "")) in ["pass3_bird", "pass3_fairy", "pass3_bog"]:
			var partial: String = words.trim_prefix("Shy. ").trim_prefix("Fly South. ")
			if str(card.get("id", "")) == "one_swallow":
				partial = partial.trim_prefix(_trip_sentence("one_swallow", golden, config) + " ")
			fragment[field] = partial


static func _flight(card: Dictionary, config: GameConfig) -> void:
	var flies: bool = false
	for entry: Dictionary in card.get("mechanics", []):
		flies = flies or str(entry.get("id", "")) == "fly_south"
	if not flies:
		return
	var id: String = str(card.get("id", ""))
	for golden: bool in [false, true]:
		var turns: int = _trip(id, golden, config)
		var multiplier: String = _n(
			Pass3Rates.number(
				config,
				"birds_golden_homecoming_multiplier" if golden else "birds_homecoming_multiplier"
			)
		)
		var reminder: String = (
			"Sold, flies south for %d %s; returns to hand at %s× permanent stats."
			% [turns, "turn" if turns == 1 else "turns", multiplier]
		)
		card["golden_details" if golden else "details"] = (
			reminder
			+ " Flying pays no sale gold; played this turn, it sells normally."
			+ " Early recalls require a missed fight; each trip grows once."
		)
		if not golden:
			var overrides: Dictionary = card.get("keyword_text_overrides", {})
			overrides["Fly South"] = reminder
			card["keyword_text_overrides"] = overrides
			var reminders: Array = card.get("keyword_text", [])
			for entry: Dictionary in reminders:
				if str(entry.get("keyword", "")) == "Fly South":
					entry["text"] = reminder


static func _trip_sentence(id: String, golden: bool, config: GameConfig) -> String:
	var turns: int = _trip(id, golden, config)
	return "Its trips last %d %s." % [turns, "turn" if turns == 1 else "turns"]


static func _trip(id: String, golden: bool, config: GameConfig) -> int:
	if id == "one_swallow":
		return Pass3Rates.integer(config, "birds_swallow_trip_turns")
	if golden and id == "old_tern":
		return Pass3Rates.integer(config, "birds_golden_tern_trip_turns")
	return Pass3Rates.integer(config, "birds_trip_turns")


static func _details(card: Dictionary, config: GameConfig) -> void:
	match str(card.get("id", "")):
		"cluricaun":
			card["details"] = (
				"Empty slots count. Copies grow once at End of Turn, using the strongest copy;"
				+ " a golden copy grows twice as much."
			)
		"jack_daw":
			card["details"] = (
				"Fractions round up. The enemy's loss ends with the fight; your Bird keeps its gain."
				if Pass3Rates.enabled(config, "birds_jack_daw_permanent")
				else "Fractions round up. The stolen stats return to their owners after the fight."
			)
		"cradle_fetch":
			card["details"] = (
				"Rounds copied stats up and adds this slot's Ring."
				+ " Copies the biggest Fairy behind; two Fetches never share a target."
			)
			card["golden_details"] = (
				"Becomes golden, including its text. Copies %s, then adds this slot's Ring."
				% _stats(Pass3Rates.number(config, "fairies_fetch_share"), "the current")
			)
		"lob_lie_by_the_fire":
			var gain: String = _n(Pass3Rates.number(config, "fairies_lob_growth") * 2)
			card["golden_details"] = (
				"Shy pays 4 gold. Only thanking counts; each complete %d turns gives +%s/+%s Ring size."
				% [Pass3Rates.integer(config, "fairies_lob_turns"), gain, gain]
			)
		"fairy_monarch":
			card["details"] = (
				"Midsummer shares one countdown across copies."
				+ (
					" Extra triggers never advance it or repeat its growth; a golden copy %s instead."
					% (
						"triples"
						if is_equal_approx(
							Pass3Rates.number(config, "fairies_golden_monarch_multiplier"), 3.0
						)
						else (
							"multiplies by "
							+ _n(Pass3Rates.number(config, "fairies_golden_monarch_multiplier"))
						)
					)
				)
			)
		"seven_whistlers":
			card["details"] = (
				"Counts different Bird card names on your board; Eggs do not count."
				+ " Each remaining stat rounds up after reduction."
			)
		"old_moth_annis":
			card["details"] = (
				"Any unit sale counts, including Nan, the Chaser and a Bird flying south."
				if Pass3Rates.enabled(config, "fairies_annis_sale")
				else "Rings the slots behind this at End of Turn."
			)
	var size: String = _n(Pass3Rates.number(config, "fairies_initial_ring_size"))
	var overrides: Dictionary = card.get("keyword_text_overrides", {})
	overrides["Ring size"] = "What each Ring gives; starts at +%s/+%s." % [size, size]
	card["keyword_text_overrides"] = overrides
