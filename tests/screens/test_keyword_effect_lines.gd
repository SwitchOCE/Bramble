extends GutTest
## Explicit display-text boundaries separate independent effects; punctuation stays within groups.


func test_two_effects_get_two_lines_even_when_both_fit() -> void:
	var rules: KeywordText = KeywordText.make("Gain 1 gold.\nDraw a card.", {}, 1500.0)
	add_child_autofree(rules)
	assert_eq(KeywordText.effect_lines("Gain 1 gold.\nDraw a card."), "Gain 1 gold.\nDraw a card.")
	assert_eq(rules.size.y, KeywordStyle.LINE_H * 2.0)
	var draw: GlassText = _word(rules, "Draw")
	assert_not_null(draw)
	assert_eq(draw.position.x, 0.0)
	assert_gte(draw.position.y, KeywordStyle.LINE_H)


func test_comma_inside_one_effect_stays_on_one_line() -> void:
	var words: String = "After this kills, gain 1 gold."
	var rules: KeywordText = KeywordText.make(words, {}, 1500.0)
	add_child_autofree(rules)
	assert_eq(KeywordText.effect_lines(words), words)
	assert_eq(rules.size.y, KeywordStyle.LINE_H)


func test_abbreviations_initials_and_decimal_numbers_stay_in_the_effect() -> void:
	var words: String = "Give Dr. Mouse 1.5 Attack, e.g. Fury. Gain 2 gold."
	assert_eq(KeywordText.effect_lines(words), words)
	assert_eq(
		KeywordText.effect_lines("Help A. Mouse and U.S. Pigeons."),
		"Help A. Mouse and U.S. Pigeons."
	)


func test_explanatory_sentences_stay_in_the_same_effect_group() -> void:
	var words: String = "Gain 1 gold. Gain 2 if this survived."
	var rules: KeywordText = KeywordText.make(words, {}, 3000.0)
	add_child_autofree(rules)
	assert_eq(KeywordText.effect_lines(words), words)
	assert_eq(_rendered_words(rules), words)
	assert_eq(rules.size.y, KeywordStyle.LINE_H)
	assert_eq(KeywordText.effect_lines("First.\r\nSecond."), "First.\nSecond.")


func test_explicit_newlines_work_with_inline_keyword_marks() -> void:
	var table: Dictionary = GameContent.load_default().display_table()
	var rules: KeywordText = KeywordText.make("Guard.\nFury 1.", table, 1500.0)
	add_child_autofree(rules)
	assert_eq(rules.marks.size(), 2)
	assert_eq(rules.marks[0].position.x, 0.0)
	assert_eq(rules.marks[1].position.x, 0.0)
	assert_eq(rules.marks[1].position.y - rules.marks[0].position.y, KeywordStyle.LINE_H)


func test_plain_rules_wrapper_respects_effect_and_existing_line_breaks() -> void:
	assert_eq(
		GlassParts.wrap_words(KeywordText.effect_lines("Gain 1 gold.\nDraw a card."), 1500.0),
		PackedStringArray(["Gain 1 gold.", "Draw a card."])
	)
	assert_eq(
		GlassParts.wrap_words("First.\n\nSecond.", 1500.0),
		PackedStringArray(["First.", "", "Second."])
	)
	assert_eq(GlassParts.wrap_words("", 1500.0), PackedStringArray())


func test_grenadier_keeps_stats_plain_and_has_two_effect_lines() -> void:
	var content: GameContent = GameContent.load_default()
	var card: UnitDef = content.library.get_card(&"grenadier-guard")
	var unit: Unit = Unit.create(card, 1, false, content.registry, 9999)
	var words: String = str(unit.view()["text"])
	var expected: String = (
		"0: Make a slot your Guard post.\n"
		+ "At the end of your turn, give your Guard post 3 Renown."
	)
	var rules: KeywordText = KeywordText.make(words, content.display_table(), 3000.0)
	add_child_autofree(rules)
	assert_eq(_rendered_words(rules), expected)
	assert_eq(rules.size.y, KeywordStyle.LINE_H * 2.0)
	assert_eq(rules.marks.size(), 4)
	assert_eq(rules.marks[0].words, "0", "the Active's cost, drawn as a gold coin")
	assert_true(rules.marks[0].coin)
	assert_eq(rules.marks[0].number, "0")
	for index: int in [1, 2]:
		assert_eq(rules.marks[index].words, "Guard post")
		assert_eq(rules.marks[index].number, "")
	assert_eq(rules.marks[3].words, "Renown")


## An Active's cost at the start of an effect line is a gold coin holding the number, whose hover
## says what the cost buys; a number later in a line stays words.
func test_a_leading_cost_is_a_gold_coin_with_its_reminder() -> void:
	var table: Dictionary = GameContent.load_default().display_table()
	var rules: KeywordText = KeywordText.make(
		"0: Make a slot your Guard post.\n2: Gain 2: nothing.", table, 3000.0
	)
	add_child_autofree(rules)
	var coins: Array[KeywordMark] = []
	for mark: KeywordMark in rules.marks:
		if mark.coin:
			coins.append(mark)
	assert_eq(coins.size(), 2, "one coin for each line's leading cost, none mid-line")
	assert_eq(str(coins[0].term["reminder"]), "Use this once a turn.")
	assert_eq(str(coins[1].term["reminder"]), "Once a turn, pay 2 gold to use this.")
	var coin: GoldCoin = coins[0].get_node("PriceCoin")
	assert_eq(coin.amount, 0)
	assert_eq(_rendered_words(rules), "0: Make a slot your Guard post.\n2: Gain 2: nothing.")
	var option: GlassBox = GlassParts.option_text(
		"Lance Corporal", "1: Give the slots in front of this 1 Renown."
	)
	add_child_autofree(option)
	var drawn: GoldCoin = option.find_child("PriceCoin", true, false)
	assert_not_null(drawn, "plain text draws the coin too (a Discover option)")
	assert_eq(drawn.amount, 1)


func test_stat_values_never_become_keyword_counts() -> void:
	var table: Dictionary = GameContent.load_default().display_table()
	for stats: String in ["+2/+4", "+1 Attack", "+1 Health", "+X/+X", "+12/+34"]:
		for keyword: String in ["Guard post", "Fury"]:
			var words: String = "Give your " + keyword + " " + stats + "."
			var rules: KeywordText = KeywordText.make(words, table, 3000.0)
			add_child_autofree(rules)
			assert_eq(_rendered_words(rules), words)
			assert_eq(rules.marks.size(), 1)
			assert_eq(rules.marks[0].words, keyword)
			assert_eq(rules.marks[0].number, "")
			var found: Dictionary = CardTerms.find(words, keyword, false, false)
			assert_eq(str(found.get("number", "")), "")
			assert_eq(str(found.get("words", "")), keyword)


func test_every_card_keeps_stat_continuations_outside_numbered_marks() -> void:
	var content: GameContent = GameContent.load_default()
	var table: Dictionary = content.display_table()
	var stat: RegEx = RegEx.create_from_string("(?i)^\\s*(?:/|Attack\\b|Health\\b)")
	var checked: int = 0
	for card_id: StringName in content.library.ids():
		var card: UnitDef = content.library.get_card(card_id)
		for golden: bool in [false, true]:
			var unit: Unit = Unit.create(card, 1, golden, content.registry, 9999)
			var words: String = str(unit.view()["text"])
			var rules: KeywordText = KeywordText.make(words, table, 3000.0)
			assert_eq(_rendered_words(rules), KeywordText.effect_lines(words), str(card_id))
			for mark: KeywordMark in rules.marks:
				if mark.number == "":
					continue
				var following: String = ""
				for index: int in range(mark.get_index() + 1, rules.get_child_count()):
					var part: Control = rules.get_child(index)
					if part is KeywordMark:
						break
					following += (part as GlassText).words
				assert_null(stat.search(following), "%s: %s%s" % [card_id, mark.words, following])
				checked += 1
			rules.free()
	assert_gt(checked, 20, "traversal checked actual numbered marks")


func test_punctuation_stays_attached_when_the_keyword_wraps() -> void:
	var table: Dictionary = GameContent.load_default().display_table()
	var measure: KeywordMark = KeywordMark.make({"name": "Fury", "words": "Fury 1"})
	var rules: KeywordText = KeywordText.make("Gain Fury 1.", table, measure.size.x + 1.0)
	measure.free()
	add_child_autofree(rules)
	var mark: KeywordMark = rules.marks[0]
	var punctuation: GlassText = _word(rules, ".")
	assert_not_null(punctuation)
	assert_eq(punctuation.position.x, mark.position.x + mark.size.x - KeywordText.PUNCTUATION_INSET)
	assert_almost_eq(
		punctuation.position.y + punctuation.size.y / 2.0, mark.position.y + mark.size.y / 2.0, 0.01
	)


func test_campaigner_survival_addendum_stays_with_its_base_effect() -> void:
	var content: GameContent = GameContent.load_default()
	_assert_groups(
		content,
		"old-campaigner",
		false,
		["At the start of your turn, give this slot 1 Renown, or 2 if this survived last fight."]
	)
	_assert_groups(
		content,
		"old-campaigner",
		true,
		["At the start of your turn, give this slot 2 Renown, or 4 if this survived last fight."]
	)


func test_grudge_keeper_explanation_stays_with_the_granted_effect() -> void:
	var content: GameContent = GameContent.load_default()
	_assert_groups(content, "grudge-keeper", false, ["Fury 1.", "Your Knights have Grudge 1."])
	_assert_groups(content, "grudge-keeper", true, ["Fury 2.", "Your Knights have Grudge 2."])


func test_seed_addendum_stays_joined_and_crab_apple_death_summon_is_separate() -> void:
	var content: GameContent = GameContent.load_default()
	for card_id: String in ["pip", "bramble-runner"]:
		_assert_groups(content, card_id, false, ["Seed."])
		_assert_groups(content, card_id, true, ["Seed. It adds 2 copies to your Compost."])
	_assert_groups(content, "crab-apple", false, ["Seed.", "When this dies, summon a Pip."])
	_assert_groups(
		content,
		"crab-apple",
		true,
		["Seed. It adds 2 copies to your Compost.", "When this dies, summon a golden Pip."]
	)


func test_independent_keyword_and_triggered_effects_have_authored_boundaries() -> void:
	var content: GameContent = GameContent.load_default()
	for golden: bool in [false, true]:
		var factor: int = 2 if golden else 1
		_assert_groups(content, "hedge-knight", golden, ["Guard.", "Fury %d." % factor])
		_assert_groups(
			content,
			"grenadier-guard",
			golden,
			[
				"0: Make a slot your Guard post.",
				"At the end of your turn, give your Guard post %d Renown." % (3 * factor)
			]
		)
		_assert_groups(
			content,
			"shrew-cutpurse",
			golden,
			["Pile on %d." % factor, "After this piles on, gain 2 gold."]
		)
		_assert_groups(
			content,
			"flying-ace",
			golden,
			[
				"Cleave.",
				"Charge %d: After this kills, give this slot %d Renown." % [2 * factor, factor]
			]
		)


func test_return_buff_and_global_modifier_are_separate_even_when_they_reference_a_keyword() -> void:
	var content: GameContent = GameContent.load_default()
	for golden: bool in [false, true]:
		var sapling_gain: int = 2 if golden else 1
		_assert_groups(
			content,
			"blackthorn-sapling",
			golden,
			[
				"Root 1.",
				"After this returns, gain +%d/+%d permanently." % [sapling_gain, sapling_gain]
			]
		)
		_assert_groups(
			content,
			"dame-bodkin",
			golden,
			[
				"Pile on %d." % (4 if golden else 2),
				"Your Mice's pile-on hits deal %s damage." % ("triple" if golden else "double")
			]
		)


func test_multisentence_keyword_reminders_stay_in_the_same_group() -> void:
	var table: Dictionary = GameContent.load_default().display_table()
	var checked: int = 0
	for entry: Dictionary in CardTerms.shown_entries(table):
		var reminder: String = str(entry["reminder"])
		if not reminder.contains(". "):
			continue
		var rules: KeywordText = KeywordText.make(reminder, table, 10000.0)
		assert_eq(_rendered_words(rules), reminder, str(entry["name"]))
		assert_eq(rules.size.y, KeywordStyle.LINE_H, str(entry["name"]))
		rules.free()
		checked += 1
	assert_gt(checked, 3, "actual multi-sentence keyword reminders were checked")


func test_numbered_border_marks_remain_detectable_after_authored_newlines() -> void:
	var table: Dictionary = GameContent.load_default().display_table()
	var pills: Array[Dictionary] = CardTerms.all_pills(
		{
			"text": "Guard.\nFury 2.\nThorns 4.",
			"keywords": ["taunt"],
			"mechanics": ["badger_fury", "thorn_thorns"]
		},
		table
	)
	assert_eq(pills.size(), 3)
	assert_eq(str(pills[0]["words"]), "Guard")
	assert_eq(str(pills[1]["words"]), "Fury 2")
	assert_eq(str(pills[2]["words"]), "Thorns 4")
	assert_string_contains(str(pills[1]["reminder"]), "+2 Attack")
	assert_string_contains(str(pills[2]["reminder"]), "4 damage")


func _assert_groups(
	content: GameContent, card_id: String, golden: bool, groups: Array[String]
) -> void:
	var card: UnitDef = content.library.get_card(StringName(card_id))
	var unit: Unit = Unit.create(card, 1, golden, content.registry, 9999)
	var words: String = str(unit.view()["text"])
	var rules: KeywordText = KeywordText.make(words, content.display_table(), 10000.0)
	var context: String = card_id + (" golden" if golden else " normal")
	assert_eq(words, "\n".join(groups), context)
	assert_eq(_rendered_words(rules), words, context)
	assert_eq(rules.size.y, KeywordStyle.LINE_H * groups.size(), context)
	rules.free()


func _rendered_words(rules: KeywordText) -> String:
	var said: String = ""
	for part: Node in rules.get_children():
		said += (part as KeywordMark).words if part is KeywordMark else (part as GlassText).words
	return said


func _word(rules: KeywordText, words: String) -> GlassText:
	for child: Node in rules.get_children():
		if child is GlassText and (child as GlassText).words == words:
			return child as GlassText
	return null
