extends GutTest
## The Badger folder loads clean through ContentSet: every designed unit, its numbers as
## placeholders that fill back to the designed text, and a display entry with the glossary's
## name and reminder for every keyword.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const BadgerKit := preload("res://tests/content/badger/badger_kit.gd")
const DESIGN: String = "res://docs/ideation-track-2/tribes/badger/units.json"


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
		assert_true(card.in_pool(), "%s is in the shop pool" % card_id)
		var unit: Unit = CoreKit.unit(game, String(card_id))
		assert_eq(unit.view()["text"], design["text"], "%s text fills back" % card_id)


func test_golden_text_doubles_the_numbers() -> void:
	var game: GameSession = BadgerKit.session()
	var cub: Unit = CoreKit.unit(game, "brock-cub", true)
	assert_eq(cub.view()["text"], "Fury 2. Grudge.")
	var warden: Unit = CoreKit.unit(game, "gate-warden", true)
	assert_eq(
		warden.view()["text"], "Guard. Whenever this is attacked, gain +4/+4 permanently."
	)
	var seeker: Unit = CoreKit.unit(game, "relic-seeker", true)
	assert_eq(
		seeker.view()["text"],
		"Squire. After each fight, gain 2 gold for every 2 units you were outnumbered by."
	)


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
		"badger_fury_fight": ["Fury", "Fury N"],
	}
	for key: String in expect:
		var entry: Dictionary = made.display[key]
		var pair: Array = expect[key]
		assert_eq(entry["name"], pair[0], key)
		assert_eq(entry["reminder"], glossary[pair[1]], key)
		assert_false(entry["hidden"], key)
	assert_eq(made.display["taunt"]["reminder"], glossary["Guard"], "Guard is the shared taunt")
	assert_true(made.display["badger_rage"]["hidden"], "helpers are hidden")


func test_every_player_has_the_badger_standing_rules() -> void:
	var game: GameSession = BadgerKit.session()
	for player: PlayerState in game.players:
		assert_true(player.has_standing(&"badger_fury_given"))
		assert_true(player.has_standing(&"badger_grudge_pay"))
