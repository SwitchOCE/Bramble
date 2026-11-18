extends GutTest
## The numbers a printed card draws agree with its own words, plain and golden: its Attack and
## Health badges (golden: doubled), and every numbered pill ("Fury 2"), whose number is the one
## the card's text gives. A card's `amounts` are its mechanics' number parameters, not drawn
## numbers: Field Marshal's golden `extra` is 4 (a Medal's own +2 plus 4 makes the +6/+6 its
## text says), and its mechanic has no pill, so the 4 is never shown.

var _content: GameContent
var _table: Dictionary


func before_all() -> void:
	_content = GameContent.load_default()
	_table = _content.display_table()


func _unit_ids() -> Array[String]:
	var out: Array[String] = []
	for id: StringName in _content.library.ids():
		if not _content.library.get_card(id).is_spell():
			out.append(String(id))
	return out


func test_every_golden_unit_draws_double_its_printed_stats() -> void:
	var stat_max: int = GameConfig.new().stat_max
	for id: String in _unit_ids():
		var plain: Dictionary = ViewAdapter.printed_unit(_content, id)
		var golden: Dictionary = ViewAdapter.printed_unit(_content, id, true)
		var attack: int = plain["attack"]
		var health: int = plain["health"]
		var gold_attack: int = golden["attack"]
		var gold_health: int = golden["health"]
		assert_eq(gold_attack, mini(2 * attack, stat_max), "%s Attack" % id)
		assert_eq(gold_health, mini(2 * health, stat_max), "%s Health" % id)


func test_every_numbered_pill_says_what_the_text_says() -> void:
	var digits: RegEx = RegEx.create_from_string("\\d")
	var checked: int = 0
	for id: String in _unit_ids():
		for golden: bool in [false, true]:
			var card: Dictionary = ViewAdapter.printed_unit(_content, id, golden)
			var text: String = str(card["text"])
			for pill: Dictionary in CardTerms.all_pills(card, _table):
				var words: String = str(pill["words"])
				if digits.search(words) == null:
					continue
				checked += 1
				assert_true(
					text.contains(words),
					(
						"%s%s pill '%s' is in its text: %s"
						% [id, " golden" if golden else "", words, text]
					)
				)
	assert_gt(checked, 0, "some printed cards have numbered pills")


func test_golden_field_marshal_draws_its_text_numbers() -> void:
	var card: Dictionary = ViewAdapter.printed_unit(_content, "field-marshal", true)
	assert_string_contains(str(card["text"]), "worth +6/+6")
	var stats: Array = [card["attack"], card["health"]]
	assert_eq(stats, [18, 30])
	var words: Array = CardTerms.all_pills(card, _table).map(
		func(pill: Dictionary) -> String: return str(pill["words"])
	)
	assert_false(words.any(func(w: String) -> bool: return w.contains("4")), "no 4 is drawn")
	var amounts: Dictionary = card["amounts"]
	var extra: int = amounts.get("pigeon_field_marshal", 0)
	assert_eq(extra, 4, "the Medal bonus on top of +2")
