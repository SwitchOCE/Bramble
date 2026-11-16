extends GutTest
## Every term a card's text uses gets its reminder in the hover, and a unit's printed keywords
## with their numbers are its pills (the play-tester's first two findings, 17 Nov).

@warning_ignore_start("unsafe_call_argument")

var _content: GameContent
var _session: GameSession
var _table: Dictionary

## A lone capital N, as in "Order (N)" or "pay N gold", that was never filled.
var _letter_n: RegEx = RegEx.create_from_string("(?<![A-Za-z])N(?![A-Za-z])")
var _bare_id: RegEx = RegEx.create_from_string("^[a-z0-9_]+$")


func before_all() -> void:
	_content = GameContent.load_default()
	_session = _content.new_session(3)
	_table = _content.display_table()


func _card(card_id: String) -> Dictionary:
	return ViewAdapter.card_from_id(_content, _session, card_id)


func _words(card_id: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for pill: Dictionary in CardTerms.all_pills(_card(card_id), _table):
		out.append(str(pill["words"]))
	return out


func _titles(card_id: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for line: String in CardTerms.reminders(_card(card_id), _table):
		out.append(line.get_slice(":", 0))
	return out


func test_numbered_keywords_are_pills() -> void:
	assert_eq(_words("nettle-skirmisher"), PackedStringArray(["Thorns 4", "Root 1"]))
	assert_eq(_words("nettle-sprout"), PackedStringArray(["Thorns 2"]))
	assert_eq(_words("hedge-knight"), PackedStringArray(["Guard", "Fury 1"]))
	assert_eq(_words("brock-cub"), PackedStringArray(["Fury 1", "Grudge"]))
	assert_eq(_words("sett-shield-bearer"), PackedStringArray(["Squire", "Grudge", "Lends"]))
	assert_eq(_words("hedge-layer"), PackedStringArray(["Bury"]))


func test_a_reference_is_not_a_pill() -> void:
	# Hoppers summoned, Tide given, Medals earned: the unit does not have these keywords
	assert_eq(_words("green-recruit"), PackedStringArray())
	assert_eq(_words("prophet-of-the-dust"), PackedStringArray())
	assert_eq(_words("old-campaigner"), PackedStringArray())


func test_more_than_three_pills_end_in_a_count() -> void:
	var card: Dictionary = {
		"text": "Guard. Thorns 2. Seed. Root 1.",
		"keywords": ["taunt", "thorn_seed"],
		"mechanics": ["thorn_thorns", "thorn_root"],
	}
	var words: PackedStringArray = PackedStringArray()
	for pill: Dictionary in CardTerms.pills(card, _table):
		words.append(str(pill["words"]))
	assert_eq(words, PackedStringArray(["Guard", "Thorns 2", "+2"]))


func test_the_reminders_the_play_tester_missed() -> void:
	assert_eq(_titles("nettle-skirmisher").slice(0, 2), PackedStringArray(["Thorns 4", "Root 1"]))
	assert_has(_titles("hedge-layer"), "Bury")
	for title: String in ["Squire", "Grudge", "Lends", "Outnumbered"]:
		assert_has(_titles("sett-shield-bearer"), title)
	for title: String in ["Medal", "Decorated", "Stiff Upper Lip"]:
		assert_has(_titles("old-campaigner"), title)
	for title: String in ["Sortie", "Medal", "Decorated", "Cleave"]:
		assert_has(_titles("flying-ace"), title)
	assert_has(_titles("recruiting-sergeant"), "Private")
	assert_has(_titles("hedgerow-scout"), "Cousin")
	assert_has(_titles("green-recruit"), "Hopper")


func test_a_printed_number_fills_the_reminder() -> void:
	var lines: PackedStringArray = CardTerms.reminders(_card("nettle-skirmisher"), _table)
	assert_eq(lines[0], "Thorns 4: Whenever this is attacked, deal 4 damage to the attacker first.")


func test_a_token_named_in_text_shows_its_stats() -> void:
	var lines: Array = _content.reminders_for(
		"hedgerow-scout", "Whenever this attacks, summon a Cousin."
	)
	assert_true(
		lines.any(func(line: Variant) -> bool: return str(line).begins_with("Cousin: A 2/2"))
	)


## Sword-heir and Marshal of the Red Mist name Fury with no number: the hover says the general
## rule, with no letter N.
func test_a_term_named_with_no_number_reads_as_its_general_rule() -> void:
	for card_id: String in ["sword-heir", "marshal-of-the-red-mist"]:
		var lines: PackedStringArray = CardTerms.reminders(_card(card_id), _table)
		var fury: String = ""
		for line: String in lines:
			if line.begins_with("Fury"):
				fury = line
		assert_eq(
			fury,
			"Fury: Whenever this attacks or is attacked, gain Attack for each unit you're"
			+ " outnumbered by.",
			card_id
		)


## A Fury given on top of the one a card prints shows as one summed number, and a unit with no
## printed Fury that is given some shows it too (the badger worker's finding).
func test_a_given_number_adds_to_the_printed_one() -> void:
	var cub: Dictionary = _card("brock-cub")
	cub["amounts"] = {"badger_fury": 2}
	var words: PackedStringArray = PackedStringArray()
	for pill: Dictionary in CardTerms.all_pills(cub, _table):
		words.append(str(pill["words"]))
	assert_true(words.has("Fury 2"), "Fury 1 printed + 1 given: %s" % ", ".join(words))
	var squire: Dictionary = _card("armsbearer")
	var printed: Array = squire["mechanics"]
	squire["mechanics"] = printed + ["badger_fury"]
	squire["amounts"] = {"badger_fury": 1}
	words = PackedStringArray()
	for pill: Dictionary in CardTerms.all_pills(squire, _table):
		words.append(str(pill["words"]))
	assert_true(words.has("Fury 1"), "given, not printed: %s" % ", ".join(words))
	var shown: Dictionary = CardTerms.amounts(
		{"badger_fury": {"fury": 2}, "pigeon_lance_corporal": {"cost": 1, "amount": 2}}
	)
	assert_eq(shown, {"badger_fury": 2}, "the core's totals; an Order's two numbers are left out")


## Every unit of every tribe: no pill or reminder line is empty or left with a placeholder, and
## the whole list is printed for a reader.
func test_every_card_reads() -> void:
	for card_id: StringName in _content.library.ids():
		var card: Dictionary = _card(String(card_id))
		if card.is_empty():
			continue
		var lines: PackedStringArray = CardTerms.reminders(card, _table)
		var pills: PackedStringArray = _words(String(card_id))
		gut.p("%s | %s | %s" % [card_id, ", ".join(pills), " / ".join(lines)])
		for line: String in lines:
			assert_false(line.contains("{"), "%s: %s" % [card_id, line])
			assert_false(line.ends_with(": "), "%s: %s" % [card_id, line])
			# a keyword the card names with no number of its own reads as its general rule, with
			# no letter N; an Order's cost and any number the card gives are filled
			assert_null(_letter_n.search(line), "no unfilled N: %s: %s" % [card_id, line])
			assert_null(_bare_id.search(line), "no bare id: %s: %s" % [card_id, line])
		for pill: String in pills:
			assert_null(_letter_n.search(pill), "no unfilled N: %s: %s" % [card_id, pill])
