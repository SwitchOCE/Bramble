extends GutTest
## Effect boundaries are renderer rules; content stays unchanged.


func test_two_effects_get_two_lines_even_when_both_fit() -> void:
	var rules: KeywordText = KeywordText.make("Gain 1 gold. Draw a card.", {}, 1500.0)
	add_child_autofree(rules)
	assert_eq(KeywordText.effect_lines("Gain 1 gold. Draw a card."), "Gain 1 gold.\nDraw a card.")
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
	assert_eq(
		KeywordText.effect_lines(words), "Give Dr. Mouse 1.5 Attack, e.g. Fury.\nGain 2 gold."
	)
	assert_eq(
		KeywordText.effect_lines("Help A. Mouse and U.S. Pigeons."),
		"Help A. Mouse and U.S. Pigeons."
	)


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
		GlassParts.wrap_words(KeywordText.effect_lines("Gain 1 gold. Draw a card."), 1500.0),
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
		"Order (1): Make a slot your Guard post.\n"
		+ "At the end of your turn, give your Guard post +2/+4."
	)
	var rules: KeywordText = KeywordText.make(words, content.display_table(), 3000.0)
	add_child_autofree(rules)
	assert_eq(_rendered_words(rules), expected)
	assert_eq(rules.size.y, KeywordStyle.LINE_H * 2.0)
	assert_eq(rules.marks.size(), 3)
	assert_eq(rules.marks[0].words, "Order (1)")
	assert_eq(rules.marks[0].number, "1")
	for index: int in [1, 2]:
		assert_eq(rules.marks[index].words, "Guard post")
		assert_eq(rules.marks[index].number, "")
	assert_not_null(_word(rules, "+2/+4."))


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
