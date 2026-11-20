extends GutTest
## The Badger folder loads clean through ContentSet: every designed unit, its numbers as
## placeholders that fill back to the designed text, and a display entry with the glossary's
## name and reminder for every keyword, golden texts, and every card's reminders.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const BadgerKit := preload("res://tests/content/badger/badger_kit.gd")
const DESIGN: String = "res://docs/ideation-track-2/tribes/badger/units.json"

## The design's `golden` line for each unit, as the golden copy's text reads it.
const GOLDEN_TEXT: Dictionary = {
	"brock-cub": "Fury 2.\nGrudge gives +2 Health, and +2/+2 more for each.",
	"hedge-knight": "Guard.\nFury 2.",
	"sett-shield-bearer":
	(
		"Squire.\nGrudge gives +2 Health, and +2/+2 more for each.\nLends its Health to the units"
		+ " in front of it."
	),
	"armsbearer":
	(
		"Squire.\nGrudge gives +2 Health, and +2/+2 more for each.\nLends its Attack to the units"
		+ " in front of it."
	),
	"relic-seeker":
	"Squire.\nAfter each fight, gain 2 gold, or 4 if you were outnumbered by 3 or more.",
	"gate-warden": "Guard.\nWhenever this is attacked, gain +2/+6 permanently.",
	"grudge-keeper":
	(
		"Fury 2.\nYour Knights have Grudge. The Grudge it gives is +2 Health, and +2/+2 more for"
		+ " each."
	),
	"hedge-lancer": "Fury 2.\nStart of fight: This attacks immediately and takes no damage.",
	"sword-heir":
	(
		"Squire.\nAfter a unit in front of this dies, gain double its Attack and Health,"
		+ " and its Fury, this fight."
	),
	"herald-of-the-charge":
	"Squire.\nStart of fight: The units in front of this attack immediately.",
	"greatsword-bearer": "Squire.\nThe units in front of this have Overrun.",
	"sett-sexton":
	(
		"Squire.\nAfter a unit in front of this gains Attack from Fury, it gains +4 Attack"
		+ " permanently (2 a fight each)."
	),
	"master-at-arms": "Recruit: Give a unit +2 Fury.",
	"ironhide-berserker": "Fury 6.\nOverrun.",
	"dame-of-the-old-sett": "Your Knights have +4 Fury and Overrun.",
	"tourney-champion":
	"Fury 2.\nStart of fight: This attacks the enemy with the most Attack and takes no damage.",
	"the-oakfeller":
	"Fury 6.\nOverrun.\nAfter this attacks and kills a unit, it attacks once more.",
	"old-brock": "After a friendly unit dies, gain double its Attack and Health this fight.",
	"marshal-of-the-red-mist": "Your units' Fury is tripled.",
}


func _design() -> Dictionary:
	var file := FileAccess.open(DESIGN, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var root: Dictionary = parsed
	return root


func test_the_badger_folder_loads_with_no_errors() -> void:
	var made: ContentSet = CoreKit.content(["badger"], false)
	assert_eq(made.errors, PackedStringArray())
	assert_true(made.folders.has("badger"))


func test_every_designed_unit_is_a_card_with_its_name_tier_stats_types_and_text() -> void:
	var game: GameSession = BadgerKit.session()
	var units: Array = _design()["units"]
	assert_eq(units.size(), 19)
	for value: Variant in units:
		var design: Dictionary = value
		var card_id := StringName(str(design["id"]))
		assert_true(game.library.has(card_id), "%s is a card" % card_id)
		if not game.library.has(card_id):
			continue
		var card: UnitDef = game.library.get_card(card_id)
		assert_eq(card.name, design["name"])
		assert_eq(card.tier, CoreUtil.to_int(design["tier"]))
		assert_eq(card.attack, CoreUtil.to_int(design["attack"]))
		assert_eq(card.health, CoreUtil.to_int(design["health"]))
		assert_true(card.has_tribe("Badger"))
		for word: String in str(design["type"]).split(" "):
			assert_true(card.types.has(word), "%s's type line has %s" % [card_id, word])
		assert_true(card.can_be_drawn(), "%s can appear in shops" % card_id)
		var unit: Unit = CoreKit.unit(game, String(card_id))
		# C15 (7.2.3) supersedes the ideation design's play timing.
		var text: String = (
			"Recruit: Give a unit +1 Fury." if card_id == &"master-at-arms" else str(design["text"])
		)
		assert_eq(str(unit.view()["text"]).replace("\n", " "), text, "%s text fills back" % card_id)


func test_every_keyword_shows_the_glossary_name_and_reminder() -> void:
	var made: ContentSet = CoreKit.content(["badger"], false)
	var glossary: Dictionary = _design()["keywords"]
	var expect: Dictionary = {
		"badger_fury": ["Fury", "Fury N"],
		"badger_grudge": ["Grudge", "Grudge"],
		"badger_squire": ["Squire", "Squire"],
		"badger_lend_attack": ["Lends", "Lends"],
		"badger_lend_health": ["Lends", "Lends"],
		"badger_overrun": ["Overrun", "Overrun"],
		"badger_outnumbered": ["Outnumbered", "Outnumbered"],
	}
	for key: String in expect:
		var entry: Dictionary = made.display[key]
		var pair: Array = expect[key]
		assert_eq(entry["name"], pair[0], key)
		assert_eq(entry["reminder"], glossary[pair[1]], key)
		assert_false(entry["hidden"], key)
	assert_eq(made.display["taunt"]["reminder"], glossary["Guard"], "Guard is the shared taunt")
	for helper: String in [
		"badger_relic",
		"badger_grudge_pay",
		"badger_grudge_keeper",
		"badger_gate_warden",
		"badger_lance",
		"badger_tourney",
		"badger_sword_heir",
		"badger_herald",
		"badger_greatsword",
		"badger_sexton",
		"badger_arms_master",
		"badger_dame",
		"badger_oakfeller",
		"badger_old_brock",
		"badger_marshal"
	]:
		assert_true(made.display[helper]["hidden"], "%s is a hidden helper" % helper)


func test_every_player_has_the_badger_standing_rules() -> void:
	var game: GameSession = BadgerKit.session()
	for player: PlayerState in game.players:
		assert_true(player.has_standing(&"badger_grudge_pay"))
		assert_eq(player.standing.size(), 1, "Grudge's payment is the only standing rule")


func test_every_golden_copy_reads_as_the_designs_golden_line() -> void:
	var game: GameSession = BadgerKit.session()
	assert_eq(GOLDEN_TEXT.size(), 19)
	for card_id: String in GOLDEN_TEXT:
		var golden: Unit = CoreKit.unit(game, card_id, true)
		assert_eq(golden.view()["text"], GOLDEN_TEXT[card_id], card_id)
		var plain: Unit = CoreKit.unit(game, card_id)
		assert_eq(
			[golden.attack(), golden.health()], [plain.attack() * 2, plain.health() * 2], card_id
		)


func test_every_card_reaches_a_reminder_for_every_term_its_design_explains() -> void:
	var made: ContentSet = CoreKit.content(["badger"], false)
	var glossary: Dictionary = _design()["keywords"]
	for value: Variant in _design()["units"]:
		var design: Dictionary = value
		var card: UnitDef = made.library.get_card(StringName(str(design["id"])))
		var reached: PackedStringArray = []
		for line: String in card.reminders:
			if made.display.has(line):
				var entry: Dictionary = made.display[line]
				assert_false(entry["hidden"], "%s: %s is shown" % [card.id, line])
				assert_ne(str(entry["reminder"]), "", "%s: %s has a reminder" % [card.id, line])
				reached.append(str(entry["name"]))
			else:
				assert_false(
					line.begins_with("badger_"), "%s: %s is a display id" % [card.id, line]
				)
				reached.append(line)
		for line: Variant in design["reminders"]:
			var said: String = str(line)
			var term: String = said.get_slice(":", 0).get_slice(" ", 0)
			if glossary.has(term) or glossary.has(term + " N"):
				assert_true(reached.has(term), "%s reaches %s" % [card.id, term])
			else:
				assert_true(reached.has(said), "%s says %s" % [card.id, said])


func test_every_printed_keyword_is_a_shown_display_entry_and_helpers_are_hidden() -> void:
	var made: ContentSet = CoreKit.content(["badger"], false)
	var shown: Dictionary = {
		"taunt": "Guard",
		"badger_fury": "Fury",
		"badger_grudge": "Grudge",
		"badger_squire": "Squire",
		"badger_lend_attack": "Lends",
		"badger_lend_health": "Lends",
		"badger_overrun": "Overrun",
	}
	for card_id: StringName in made.library.ids():
		var card: UnitDef = made.library.get_card(card_id)
		if not card.has_tribe("Badger"):
			continue
		var ids: Array[String] = []
		for keyword: StringName in card.keywords:
			ids.append(String(keyword))
		for spec: MechanicSpec in card.mechanics:
			ids.append(String(spec.id))
		for id: String in ids:
			var entry: Dictionary = made.display[id]
			if shown.has(id):
				assert_false(entry["hidden"], "%s: %s" % [card.id, id])
				assert_true(card.text.contains(shown[id]), "%s prints %s" % [card.id, shown[id]])
			else:
				assert_true(entry["hidden"], "%s: %s is a helper" % [card.id, id])
