extends GutTest
## Audit the entire displayed catalogue against its effective overlay parameters.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")

const TEXT_FIELDS: Array[String] = ["text", "golden_text", "details", "golden_details"]
const SIZE_KEYS: Array[String] = [
	"permanent_buff_cap",
	"most",
	"golden_most",
	"per_max",
	"max_steps",
	"takes_max",
	"gold_max",
	"homecomings_max"
]
const RATE_KEYS: Array[String] = [
	"once", "once_per_enemy", "limit", "lifetime", "attack_limit", "gold_limit", "uses_per_turn"
]
## These uses are displayed by the hero-power control, rather than printed in card prose.
const UNPRINTED_RATE_USES: Array[String] = [
	"jill_down_the_tree", "hob_mumblecrust", "sample_painter"
]

## Independent links bind each printed limit to its effective rule parameter.
## Columns: card, parameter path, text layer, semantic format, limited-clause regex,
## optional golden-only flag. New changed parameters must acquire a link.
const PARAMETER_TEXT: Array = [
	["dame_farthing", "/power/effects/0/do/per_max", "details", "gold_cap", "up to"],
	["brother_bracken", "/power/effects/0/do/per_max", "text", "stats", "up to"],
	["honorary_treasurer", "/mechanics/0/max_steps", "text", "stats", "up to"],
	["madame_ermeline", "/mechanics/0/takes_max", "details", "takes", "counts up to"],
	["madame_ermeline", "/mechanics/0/gold_max", "details", "ermeline_gold", "up to \\d+ gold"],
	["charcoal_burner", "/mechanics/0/do/0/most", "text", "burn", "burn up to"],
	["alderman_dozey", "/mechanics/1/do/most", "text", "stats", "up to"],
	["alderman_dozey", "/permanent_buff_cap", "details", "permanent_stats", "cap at"],
	["bridge_toad", "/permanent_buff_cap", "text", "stats", "up to"],
	["hedge_witch", "/mechanics/0/most", "text", "tier", "up to", false],
	["hedge_witch", "/mechanics/0/golden_most", "text", "tier", "up to", true],
	["seven_whistlers", "/mechanics/0/homecomings_max", "details", "negative_stats", "up to"],
	["money_spider", "/mechanics/1/do/per_max", "text", "money", "or \\d+ if", true],
	["pipkin", "/power/rules/1/buy_limit", "text", "buy", "buy only"],
	[
		"old_mother_mousewife",
		"/power/effects/0/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	[
		"toll_bard",
		"/mechanics/1/attack_limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	["toll_bard", "/mechanics/1/gold_limit", "text", "first_time", "the first time"],
	[
		"signor_ranocchio",
		"/mechanics/1/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	[
		"cricket_busker",
		"/mechanics/0/limit",
		"text",
		"turn",
		"times a turn|once a turn|twice a turn"
	],
	[
		"wee_wobbly",
		"/mechanics/1/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	["mrs_clover", "/mechanics/0/limit", "text", "turn", "times a turn|once a turn|twice a turn"],
	["stone_soup", "/mechanics/1/limit", "text", "turn", "times a turn|once a turn|twice a turn"],
	["alderman_dozey", "/mechanics/1/once", "text", "dozey_once", "after 3 turns in this slot:"],
	[
		"bubble_and_squeak",
		"/mechanics/1/splits",
		"text",
		"bubble",
		"times a fight|once a fight|twice a fight"
	],
	[
		"tiddy_mun",
		"/mechanics/0/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	[
		"peat_king",
		"/mechanics/1/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	["dishwater_nell", "/mechanics/0/limit", "details", "first_nell", "only your first nell pays"],
	[
		"beadle_warrenby",
		"/mechanics/0/limit",
		"text",
		"turn",
		"times a turn|once a turn|twice a turn"
	],
	[
		"sexton_beetle",
		"/mechanics/0/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	["prima_donna", "/mechanics/1/once_per_enemy", "text", "once_enemy", "once per enemy"],
	[
		"his_highness",
		"/mechanics/1/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	[
		"peat_cutter",
		"/mechanics/1/limit",
		"text",
		"fight",
		"times a fight|once a fight|twice a fight"
	],
	["peat_cutter", "/mechanics/1/lifetime", "text", "lifetime", "times in all"],
	["old_mother_mast", "/mechanics/0/limit", "text", "first_buy", "first unit buy each turn"],
	["old_mother_mast", "/mechanics/1/limit", "text", "first_buy", "first unit buy each turn"],
	["reel_mistress", "/mechanics/0/repeat", "text", "repeat", "each ring moves once a fight"],
	["pennywort_snail", "/mechanics/0/turns", "text", "turns", "up to \\d+ turns"],
	["sleeping_partner", "/mechanics/0/lifetime", "text", "lifetime", "times in all"],
]


func _config(sizes: bool, rates: bool) -> GameConfig:
	var config := GameConfig.defaults()
	config.set_value("card_size_caps", sizes)
	config.set_value("card_rate_limits", rates)
	return config


func _cards() -> Array[Dictionary]:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var cards: Array[Dictionary] = library.all_units()
	cards.append_array(library.all_cards())
	cards.append_array(library.all_heroes())
	cards.append_array(UnitLibrary.load_dir("res://content/levers").all_units())
	return cards


func _display(value: Variant) -> String:
	var words: PackedStringArray = []
	if value is Dictionary:
		var entry: Dictionary = value
		for key: String in entry:
			if key in ["overlay_text", "source", "keyword_text"]:
				continue
			if key in TEXT_FIELDS:
				words.append(str(entry[key]))
			else:
				words.append(_display(entry[key]))
	elif value is Array:
		var entries: Array = value
		for entry: Variant in entries:
			words.append(_display(entry))
	return " ".join(words).strip_edges()


## Record only rule parameters, never authored text metadata. Defaults are included
## for mechanics whose caps are supplied by their implementation rather than JSON.
func _limits(value: Variant, path: String = "") -> Dictionary:
	var out: Dictionary = {}
	if value is Dictionary:
		var entry: Dictionary = value
		for key: String in entry:
			if key in ["overlay_text", "source", "keyword_text", "mechanic_text"] + TEXT_FIELDS:
				continue
			var next: String = path + "/" + key
			if key in SIZE_KEYS + RATE_KEYS:
				out[next] = entry[key]
			out.merge(_limits(entry[key], next))
		var id: String = str(entry.get("id", ""))
		for pair: Array in [
			["whistlers", "homecomings_max", 3],
			["savings", "turns", 3],
			["stone_soup", "limit", 1],
			["nell", "limit", 1],
			["kiss", "limit", 1],
			["bubble", "splits", 1],
			["reel_mistress", "repeat", false]
		]:
			if path.begins_with("/mechanics/") and id == str(pair[0]):
				out[path + "/" + str(pair[1])] = entry.get(str(pair[1]), pair[2])
		if str(entry.get("query", "")) == "buys_per_turn":
			out[path + "/buy_limit"] = entry["value"]
	elif value is Array:
		var entries: Array = value
		for index: int in entries.size():
			out.merge(_limits(entries[index], path + "/" + str(index)))
	return out


func test_every_card_all_overlay_combinations_has_text_for_changed_rule_parameters() -> void:
	var checked: int = 0
	for raw: Dictionary in _cards():
		var before: Dictionary = _limits(raw)
		for sizes: bool in [false, true]:
			for rates: bool in [false, true]:
				var config: GameConfig = _config(sizes, rates)
				var card: Dictionary = ScaleOverlay.card_for(raw, config)
				var after: Dictionary = _limits(card)
				var label: String = "%s size=%s rate=%s" % [raw["id"], sizes, rates]
				var changed: bool = false
				for path: String in before:
					if (
						typeof(before[path]) == typeof(after.get(path))
						and before[path] == after.get(path)
					):
						continue
					if path.ends_with("/uses_per_turn") and str(raw["id"]) in UNPRINTED_RATE_USES:
						assert_eq(after[path], BoardUnit.STAT_CLAMP, label)
						continue
					changed = true
					assert_true(
						_has_link(str(raw["id"]), path), label + ": uncovered parameter " + path
					)
				_assert_parameter_text(card, after, label)
				_assert_runtime_text(card, config, label)
				if changed:
					assert_ne(
						_display(card), _display(raw), label + ": changed rules need changed prose"
					)
				if sizes and rates and not str(raw["id"]).begins_with("scale_"):
					assert_eq(
						_display(card), _display(raw), label + ": defaults retain authored prose"
					)
				_assert_no_disabled_claims(card, sizes, rates, label)
				checked += 1
	assert_eq(
		checked, 812, "203 units, spells, heroes and opt-in levers each audited in four modes"
	)


func _has_link(id: String, path: String) -> bool:
	for link: Array in PARAMETER_TEXT:
		if str(link[0]) == id and str(link[1]) == path:
			return true
	return false


func _assert_parameter_text(card: Dictionary, limits: Dictionary, label: String) -> void:
	for link: Array in PARAMETER_TEXT:
		if str(link[0]) != str(card["id"]):
			continue
		var value: Variant = limits.get(str(link[1]))
		var bounded: bool = false
		match typeof(value):
			TYPE_BOOL:
				bounded = bool(value)
			TYPE_INT, TYPE_FLOAT:
				var numeric: int = CoreUtil.to_int(value)
				bounded = numeric != BoardUnit.STAT_CLAMP and numeric != -1
			TYPE_STRING:
				bounded = not str(value).is_empty()
		if str(link[3]) == "repeat":
			bounded = not bool(value)
		for golden: bool in [false, true]:
			if link.size() > 5 and golden != bool(link[5]):
				continue
			var field: String = str(link[2])
			if golden and card.has("golden_" + field):
				field = "golden_" + field
			elif golden:
				continue
			var words: String = str(card.get(field, "")).to_lower()
			if bounded:
				var expected: String = _expected_clause(str(link[3]), value, golden)
				assert_string_contains(words, expected, label + " " + field + " " + str(link[1]))
			else:
				var regex := RegEx.create_from_string(str(link[4]))
				assert_null(regex.search(words), label + " " + field + ": stale " + str(link[1]))


## These limits live in runtime providers rather than authored mechanic parameters.
## Exercise the provider so prose cannot silently retain a disabled hardcoded rule.
func _assert_runtime_text(card: Dictionary, config: GameConfig, label: String) -> void:
	match str(card["id"]):
		"market_stall":
			_assert_stall_text(card, config, label)
		"harvest_supper":
			_assert_harvest_text(card, config, label)
		"figgy_duff":
			for golden: bool in [false, true]:
				var words: String = str(card["golden_text" if golden else "text"]).to_lower()
				var skips_next: bool = not _figgy_can_pair(config, golden, 1)
				assert_eq(words.contains("once every other turn"), skips_next, label)
				assert_eq(_figgy_can_pair(config, golden, 0), not skips_next, label)
				assert_true(_figgy_can_pair(config, golden, 2), label + ": two-turn cooldown")
		"prince_restored":
			_assert_prince_text(card, config, label)
		"sample_thrifty":
			var kit := KIT.new()
			kit.setup(config)
			HeroRules.assign(kit.player, card)
			kit.player.paid_refreshes = 0
			assert_eq(kit.rules.refresh_cost(kit.player), 0, label)
			kit.player.paid_refreshes = 3
			var limited: bool = kit.rules.refresh_cost(kit.player) > 0
			var words: String = str(card["text"]).to_lower()
			assert_eq(words.contains("first refresh each turn is free"), limited, label)
			assert_eq(words.contains("your refreshes are free"), not limited, label)
			assert_string_contains(words, "tier up costs 1 more", label)


func _assert_stall_text(card: Dictionary, config: GameConfig, label: String) -> void:
	var kit := KIT.new()
	kit.setup(config)
	kit.player.market_stalls = MarketStalls.LIMIT
	var words: String = str(card["details"]).to_lower()
	assert_eq(
		words.contains("at most %d stalls" % MarketStalls.LIMIT),
		MarketStalls.limit_reached(kit.player),
		label + ": lifetime purchase limit"
	)
	kit.player.market_stalls = MarketStalls.UNIT_CAP
	var bounded: bool = MarketStalls.unit_bonus(kit.rules, kit.player) < kit.player.market_stalls
	assert_eq(words.contains("up to %d" % MarketStalls.UNIT_CAP), bounded, label + ": shop ceiling")
	assert_eq(words.contains("each stall adds a unit offer"), not bounded, label)
	HeroRules.assign(kit.player, kit.rules.library.get_hero("pipkin"))
	var extra_spells: int = MarketStalls.spell_bonus(kit.rules, kit.player)
	assert_eq(words.contains("pipkin gets spells instead"), extra_spells > 0, label)


func _assert_harvest_text(card: Dictionary, config: GameConfig, label: String) -> void:
	var kit := KIT.new()
	kit.setup(config)
	kit.library = kit.rules.library
	var chosen: RecruitUnit = kit.put("field_vole", 0)
	var item := HandItem.make(card, 99)
	kit.player.round_number = 3
	kit.player.harvest_supper_round = 3
	var rate_problem: String = TribeBonus.cast_problem(kit.player, item, 0)
	var words: String = str(card["text"]).to_lower()
	assert_eq(words.contains("once a turn"), rate_problem.contains("once a turn"), label)
	kit.player.harvest_supper_round = -1
	for tribe: String in chosen.tribes():
		kit.player.tribe_bonuses[tribe] = TribeBonus.CAP
	var size_problem: String = TribeBonus.cast_problem(kit.player, item, 0)
	assert_eq(
		words.contains("up to +%d/+%d" % [TribeBonus.CAP, TribeBonus.CAP]),
		not size_problem.is_empty(),
		label
	)
	TribeBonus.grant(kit.player, chosen, 1)
	for tribe: String in chosen.tribes():
		var total: int = CoreUtil.to_int(kit.player.tribe_bonuses[tribe])
		assert_eq(
			total, TribeBonus.CAP if not size_problem.is_empty() else TribeBonus.CAP + 1, label
		)


func _figgy_can_pair(config: GameConfig, golden: bool, elapsed: int) -> bool:
	var kit := KIT.new()
	kit.setup(config)
	kit.library = kit.rules.library
	var figgy: RecruitUnit = kit.put("figgy_duff", 0, golden)
	figgy.counters["figgy_round"] = 5
	kit.player.round_number = 5 + elapsed
	var inner: RecruitUnit = kit.put("field_vole")
	inner.origin = RecruitUnit.ORIGIN_BOUGHT
	kit.player.hand.erase(inner)
	figgy.held.append(inner)
	var twin: RecruitUnit = kit.put("field_vole", 1)
	twin.origin = RecruitUnit.ORIGIN_BOUGHT
	return HeldUnits.figgy_pair(kit.rules, kit.player)


func _assert_prince_text(card: Dictionary, config: GameConfig, label: String) -> void:
	for golden: bool in [false, true]:
		var kit := KIT.new()
		kit.setup(config)
		kit.library = kit.rules.library
		var prince: RecruitUnit = kit.put("prince_restored", 0, golden)
		var discount: int = prince.mechanic_number("spell_discount", "gold")
		var item := HandItem.make(kit.library.get_card("market_stall"), 99)
		kit.player.spells_bought_turn = 0
		assert_eq(BogFolk.spell_cost(kit.player, item), item.cost() - discount, label)
		kit.player.spells_bought_turn = 1
		var limited: bool = BogFolk.spell_cost(kit.player, item) == item.cost()
		var words: String = str(card["golden_text" if golden else "text"]).to_lower()
		assert_eq(words.contains("first spell each turn"), limited, label)
		assert_string_contains(
			words, "costs %d less" % discount if limited else "cost %d less" % discount, label
		)


# gdlint: disable=max-returns
func _expected_clause(kind: String, value: Variant, golden: bool) -> String:
	var n: int = CoreUtil.to_int(value)
	var factor: int = 2 if golden else 1
	match kind:
		"stats":
			return "up to +%d/+%d" % [n * factor, n * factor]
		"negative_stats":
			return "up to -%d/-%d" % [n * factor, n * factor]
		"permanent_stats":
			return "cap at +%d/+%d" % [n * factor, n * factor]
		"tier":
			return "up to your tier + 2" if str(value) == "tier_plus_2" else "up to your tier."
		"takes":
			return "counts up to %d takes" % n
		"gold_cap":
			return "up to %d gold a turn" % n
		"ermeline_gold":
			return "up to %d gold" % (n + (1 if golden else 0))
		"burn":
			return "burn up to %d of your gold" % (n * factor)
		"turn", "fight", "bubble":
			if kind == "bubble":
				n *= factor
			var frequency: String = "once" if n == 1 else ("twice" if n == 2 else "%d times" % n)
			return "%s a %s" % [frequency, "turn" if kind == "turn" else "fight"]
		"turns":
			return "up to %d turns" % n
		"lifetime":
			return "%s times in all" % ("three" if n == 3 else str(n))
		"dozey_once":
			return "after 3 turns in this slot:"
		"money":
			return "or %d if" % (1 + n)
		"buy":
			return "buy only %d units a turn" % n
		"first_time":
			return "the first time"
		"first_nell":
			return "only your first nell pays"
		"first_buy":
			return "first unit buy each turn"
		"repeat":
			return "each ring moves once a fight"
		"once_enemy":
			return "once per enemy"
	return "UNHANDLED CONTRACT " + kind


func _assert_no_disabled_claims(card: Dictionary, sizes: bool, rates: bool, label: String) -> void:
	var words: String = _display(card)
	if not sizes:
		var caps := RegEx.create_from_string(
			"(?i)\\b(?:cap|capped|ceiling)\\b|up to (?!\\d+ turns)"
		)
		assert_null(caps.search(words), label + ": disabled size clauses")
	if not rates:
		var limits := RegEx.create_from_string(
			(
				"(?i)(?:once|twice|\\d+ times|three times) (?:a (?:turn|fight)|per enemy|in all)"
				+ "|up to \\d+ turns|first unit buy|first spell each turn|first Refresh each turn"
				+ "|buy only \\d+ units a turn"
			)
		)
		assert_null(limits.search(words), label + ": disabled rate clauses")


func test_dozey_repeat_timing_and_numeric_caps_match_effective_rule_in_all_modes() -> void:
	var raw: Dictionary = UnitLibrary.load_dir().get_unit("alderman_dozey")
	for sizes: bool in [false, true]:
		for rates: bool in [false, true]:
			var card: Dictionary = ScaleOverlay.card_for(raw, _config(sizes, rates))
			var wake: Dictionary = card["mechanics"][1]
			var growth: Dictionary = wake["do"]
			assert_eq(wake["once"], rates)
			for golden: bool in [false, true]:
				var words: String = card["golden_text" if golden else "text"]
				var factor: int = 2 if golden else 1
				var turns: int = wake["if"][0]["at_least"]
				assert_string_contains(
					words, "after %d turns" % turns if not rates else "After %d turns" % turns
				)
				assert_eq(words.contains("End of Turn:"), not bool(wake["once"]))
				assert_eq(wake["trigger"], "end_of_turn")
				assert_eq(growth["factor"], 2)
				assert_eq(words.contains("double its stats"), growth["factor"] == 2)
				assert_eq(words.contains("up to"), growth.has("most"))
				if growth.has("most"):
					var cap: int = CoreUtil.to_int(growth["most"]) * factor
					assert_string_contains(words, "up to +%d/+%d" % [cap, cap])
				assert_eq(card.has("permanent_buff_cap"), sizes)
				if sizes:
					var cap: int = CoreUtil.to_int(card["permanent_buff_cap"]) * factor
					assert_string_contains(
						card["golden_details" if golden else "details"], "+%d/+%d" % [cap, cap]
					)


func test_pipkin_and_money_spider_words_match_their_effective_numbers_in_all_modes() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	for sizes: bool in [false, true]:
		for rates: bool in [false, true]:
			var config: GameConfig = _config(sizes, rates)
			var pipkin: Dictionary = ScaleOverlay.card_for(library.get_hero("pipkin"), config)
			var rules: Array = pipkin["power"]["rules"]
			assert_string_contains(
				pipkin["text"], "%d more cards" % CoreUtil.to_int(rules[0]["value"])
			)
			var limit: int = CoreUtil.to_int(rules[1]["value"])
			assert_eq(str(pipkin["text"]).contains("buy only"), limit >= 0)
			if limit >= 0:
				assert_string_contains(pipkin["text"], "buy only %d units a turn" % limit)
			var spider: Dictionary = ScaleOverlay.card_for(library.get_unit("money_spider"), config)
			var base: Dictionary = spider["mechanics"][0]["do"]
			var extra: Dictionary = spider["mechanics"][1]["do"]
			assert_eq(base["golden_static"], true)
			assert_eq(extra["golden_static"], true)
			assert_eq(str(spider["golden_text"]).contains("or 2 if"), extra.has("per_max"))
			assert_string_contains(spider["text"], "get %d gold" % CoreUtil.to_int(base["amount"]))
			assert_string_contains(
				spider["golden_text"], "get %d gold" % CoreUtil.to_int(base["amount"])
			)
			if extra.has("per_max"):
				assert_string_contains(
					spider["golden_text"],
					"carried over %d or more" % CoreUtil.to_int(extra["per_div"])
				)
			else:
				assert_string_contains(
					spider["golden_text"],
					(
						"plus %d for every %d you carried over"
						% [CoreUtil.to_int(extra["amount"]), CoreUtil.to_int(extra["per_div"])]
					)
				)


func test_empty_engine_tribe_names_every_friendly_unit_and_shows_the_dials() -> void:
	var config := GameConfig.defaults()
	config.set_value("scale_engine_tribe", "")
	config.set_value("scale_engine_percent", 17)
	var raw: Dictionary = UnitLibrary.load_dir("res://content/levers").get_unit("scale_engine")
	var card: Dictionary = ScaleOverlay.card_for(raw, config)
	assert_eq(card["text"], "End of Turn: give your units +17% stats permanently.")
	assert_eq(card["golden_text"], "End of Turn: give your units +34% stats permanently.")
	config.set_value("scale_engine_flat", 9)
	card = ScaleOverlay.card_for(raw, config)
	assert_eq(card["text"], "End of Turn: give your units +9/+9 permanently.")
	assert_eq(card["golden_text"], "End of Turn: give your units +18/+18 permanently.")
