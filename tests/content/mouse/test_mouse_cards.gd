extends GutTest
## The Mice's card data as a screen reads it: each golden copy's text and stats against the
## design's `golden` line, and every term a card's text uses explained from that card (a shown
## keyword's display entry, or a line in its `reminders`). Behaviour of each golden copy is
## tested beside its unit in test_mouse_units.gd.

@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CoreKit := preload("res://tests/core/core_kit.gd")
const Kit := preload("res://tests/content/mouse/mouse_kit.gd")

const DESIGN: String = "res://docs/ideation-track-2/tribes/mouse/units.json"


func test_all_mouse_cards_match_the_design_in_both_forms() -> void:
	var game: GameSession = Kit.session()
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DESIGN))
	var ids: Array[String] = []
	for card: Dictionary in design["units"] + design["tokens"]:
		var id: String = card["id"]
		ids.append(id)
		var unit: Unit = CoreKit.unit(game, id)
		assert_eq(unit.def.tier, int(card["tier"]), id)
		assert_eq(unit.view()["text"], card["text"], id)
		assert_eq(unit.attack(), int(card["attack"]), id)
		assert_eq(unit.health(), int(card["health"]), id)
		var golden: Unit = Kit.golden_unit(game, id)
		assert_eq(golden.view()["text"], card["golden"], id)
		assert_eq(golden.attack(), 2 * int(card["attack"]), id)
		assert_eq(golden.health(), 2 * int(card["health"]), id)
	var shipped: Array[String] = []
	for id: StringName in game.library.ids():
		if game.library.get_card(id).has_tribe("Mouse"):
			shipped.append(String(id))
	shipped.sort()
	ids.sort()
	assert_eq(shipped, ids)
	assert_eq(ids.size(), 20)


func test_every_mouse_term_has_display_text() -> void:
	var game: GameSession = Kit.session()
	for id: StringName in game.library.ids():
		var def: UnitDef = game.library.get_card(id)
		if not def.has_tribe("Mouse"):
			continue
		var unit: Unit = CoreKit.unit(game, String(id))
		var view: Dictionary = unit.view()
		var text: String = view["text"]
		var mechanics: Array = []
		for spec: MechanicSpec in def.mechanics:
			assert_true(game.display.has(spec.id), String(id))
			mechanics.append(spec.id)
		view["mechanics"] = mechanics
		var lines: Array = CardTerms.reminders(view, game.display)
		for term: String in ["Cousin", "Pile on", "Charge", "Guard", "Hand-me-down"]:
			if not text.contains(term):
				continue
			assert_true(
				lines.any(func(line: String) -> bool: return line.begins_with(term)),
				"%s explains %s" % [id, term]
			)
