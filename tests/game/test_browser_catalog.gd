extends GutTest
## Exhaustive content-backed filter checks: totals are derived from the shipped library,
## including tokens, and excluding the hidden system spell. No count lives in the UI.

var _content: GameContent
var _catalog: BrowserCatalog


func before_all() -> void:
	_content = GameContent.load_default()
	_catalog = BrowserCatalog.new(_content)


func test_every_printed_unit_and_shop_spell_occurs_once() -> void:
	var units: Array[String] = []
	var spells: Array[String] = []
	for id: StringName in _content.library.ids():
		var def: UnitDef = _content.library.get_card(id)
		if def.is_spell():
			if def.offered:
				spells.append(String(id))
		else:
			units.append(String(id))
	assert_eq(_catalog.matching().size(), units.size())
	assert_eq(_catalog.matching(true).size(), spells.size())
	var seen: Array[String] = []
	for card: Dictionary in _catalog.cards:
		var id: String = card["id"]
		assert_false(seen.has(id), "one copy of %s" % id)
		seen.append(id)
		assert_true((spells if card["spell"] else units).has(id))
		assert_false(str(card["text"]).contains("{"), "resolved rules text for %s" % id)
	assert_false(seen.has("triple_reward"))
	print("browser content: %d units, %d spells" % [units.size(), spells.size()])


func test_all_tribe_and_tier_combinations_match_content() -> void:
	var folders: PackedStringArray = _content.tribe_ids()
	folders.append("")
	for tribe: String in folders:
		for tier: int in range(7):
			var expected: Array[String] = []
			for id: StringName in _content.library.ids():
				var def: UnitDef = _content.library.get_card(id)
				if def.is_spell():
					continue
				if tribe != "" and _content.folder_of(String(id)) != tribe:
					continue
				if tier > 0 and def.tier != tier:
					continue
				expected.append(String(id))
			var actual: Array[Dictionary] = _catalog.matching(false, tribe, tier)
			assert_eq(actual.size(), expected.size(), "%s tier %d count" % [tribe, tier])
			for card: Dictionary in actual:
				assert_true(expected.has(str(card["id"])))


func test_spell_tiers_work_and_ignore_tribes() -> void:
	for tier: int in range(7):
		var expected: int = 0
		for id: StringName in _content.library.ids():
			var def: UnitDef = _content.library.get_card(id)
			if def.is_spell() and def.offered and (tier == 0 or def.tier == tier):
				expected += 1
		assert_eq(_catalog.matching(true, "mouse", tier).size(), expected)


func test_search_matches_names_and_resolved_rules_case_insensitively() -> void:
	assert_eq(_catalog.matching(false, "", 0, "  HEDGE KNIGHT  ").size(), 1)
	assert_eq(_catalog.matching(false, "mouse", 5, "Master of Engines").size(), 1)
	assert_eq(_catalog.matching(false, "badger", 5, "Master of Engines").size(), 0)
	assert_gt(_catalog.matching(false, "", 0, "Start of fight").size(), 0)
	assert_eq(_catalog.matching(false, "", 0, "no-such-card").size(), 0)
	assert_eq(_catalog.matching(true, "", 0, "seek").size(), 1)


func test_tokens_come_last_and_every_group_has_deterministic_order() -> void:
	var saw_token: bool = false
	var previous: Dictionary = {}
	for card: Dictionary in _catalog.matching():
		if card["token"]:
			saw_token = true
		elif saw_token:
			fail_test("a non-token follows a token")
		if not previous.is_empty():
			assert_true(BrowserCatalog._before(previous, card), "stable tier/tribe/name order")
		previous = card
	assert_true(saw_token, "tokens are browsable too")
