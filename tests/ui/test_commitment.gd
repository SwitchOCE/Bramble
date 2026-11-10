extends GutTest
## The grant explains its rule, the permanent bonus remains visible, and aiming follows tribes.

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const TribeBonuses := preload("res://src/ui/widgets/tribe_bonuses.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const Guide := preload("res://src/ui/screens/how_to_play.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_harvest_explains_where_its_bonus_applies_and_its_bounds() -> void:
	var library: UnitLibrary = TestLibraries.current()
	var spell: Dictionary = HandItem.make(library.get_card("harvest_supper"), 1).view()
	var full: String = CardDetail.full_text_bbcode(spell)
	for expected: String in ["+3/+3", "Once a turn"]:
		assert_string_contains(full, expected)
	# Who misses out is a ruling, one hover or tap on "Details" away, not on the card.
	assert_string_contains(full, "[url=kw:Details]")
	assert_false(full.contains("Offered from tier 3"), "offer exceptions live in Details")
	assert_string_contains(CardDetail.reminder_for("Details", spell), "Offered from tier 3")
	assert_false(full.contains("summoned"), "not on the card")
	assert_string_contains(CardDetail.reminder_for("Details", spell), "summoned")
	var bonus: String = CardDetail.full_text_bbcode({"tribe_bonuses": {"Oozes": 2}})
	assert_string_contains(bonus, "[url=kw:Tribe bonus]")
	assert_string_contains(
		CardDetail.reminder_for("Tribe bonus", spell), KeywordRules.TRIBE_BONUS_TEXT
	)
	var unit: String = RegEx.create_from_string("\\[[^\\]]*\\]").sub(
		CardDetail.full_text_bbcode({"tribe_bonuses": {"Oozes": 2, "Fairies": 1}}), "", true
	)
	assert_string_contains(unit, "Oozes tribe bonus: +2/+2")
	assert_string_contains(unit, "Fairies tribe bonus: +1/+1")
	assert_string_contains(unit, "in its stats")


func test_harvest_highlights_only_units_with_a_tribe() -> void:
	var item: Dictionary = {"aim": "tribe_unit"}
	var spent: String = RecruitView.no_target_note(
		{"harvest_supper_used": true}, {"def_id": "harvest_supper", "aim": "tribe_unit"}
	)
	assert_string_contains(spent, "already cast this turn")
	assert_false(RecruitView.item_lands(item, {}, 0))
	assert_false(RecruitView.item_lands(item, {"tribes": []}, 0))
	assert_true(RecruitView.item_lands(item, {"tribes": ["Birds"]}, 4))
	assert_string_contains(
		RecruitView.no_target_note({"board": [{"tribes": []}]}, item), "with a tribe"
	)


func test_tribe_portraits_show_bonus_on_phone() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	state["lobby_tribes"] = ["Hedgerow folk", "Fairies", "Oozes", "Birds", "Hunters"]
	state["tribe_bonuses"] = {"Fairies": 3, "Birds": 1}
	var screen: RecruitScreen = RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	await get_tree().process_frame
	var icons: TribeBonuses = screen.get("_tribes")
	assert_eq(icons.chips.size(), 2, "only tribes with an earned bonus")
	assert_eq(icons.tribes, ["Fairies", "Birds"])
	var caption: Label = icons.get_node("Caption") as Label
	assert_eq(caption.text, "Tribe bonus")
	assert_false(caption.is_visible_in_tree(), "earned portraits need no resting caption")
	var fairy: Control = icons.chips[0]
	assert_eq((fairy.get_node("Bonus") as Label).text, "+3/+3")
	assert_string_contains(fairy.tooltip_text, "Fairies")
	assert_lte(icons.position.y + icons.size.y, 134.0, "icons finish above the shop badges")
	assert_eq(LayoutCheck.problems(icons, "tribe icons"), PackedStringArray())
	state["tribe_bonuses"] = {"Fairies": 0}
	screen.render()
	await get_tree().process_frame
	assert_eq(icons.chips.size(), 0, "zero and missing bonuses are absent")
	assert_false(icons.is_visible_in_tree(), "no empty caption before the first bonus")
	state["tribe_bonuses"] = {
		"Hedgerow folk": 3, "Fairies": 3, "Oozes": 3, "Birds": 3, "Hunters": 3
	}
	screen.render()
	await get_tree().process_frame
	assert_eq(icons.chips.size(), 5)
	assert_eq(LayoutCheck.problems(icons, "all earned tribe bonuses"), PackedStringArray())


func test_bird_flying_cost_and_egg_stats_are_clear_before_the_action() -> void:
	var bird: Dictionary = {"fly_south": 2, "played_round": 1, "sell_value": 1}
	assert_eq(RecruitHeld.sell_gold(bird, 3), 0)
	assert_string_contains(RecruitHeld.sell_note(bird, 3), "no sale gold")
	assert_eq(RecruitHeld.sell_gold(bird, 1), 1)
	var marks: Array = RecruitHeld.with_nests(
		RecruitView.slot_marks({}),
		[{"nest": 0, "name": "Mrs Jay", "def_id": "mrs_jay", "attack": 7, "health": 9}]
	)
	assert_string_contains(RecruitHeld.nest_note(_mark(marks)), "4/5 Egg")
	assert_string_contains(
		RecruitHeld.nest_note({"nest": true, "nest_left": -1}), "half the Bird's"
	)
	marks = RecruitHeld.with_nests(
		RecruitView.slot_marks({}),
		[{"nest": 0, "name": "Mother Goose", "def_id": "mother_goose", "attack": 7, "health": 9}]
	)
	assert_string_contains(RecruitHeld.nest_note(_mark(marks)), "4/5 Egg")


## Card-specific rules (Harvest Supper, Hiring Fair, Moss Ooze, the cost of a flight) are on the
## cards themselves; the guide names the ideas.
func test_guide_teaches_commitment_bellies_and_travel() -> void:
	var words: String = ""
	for page: Dictionary in Guide.PAGES:
		words += str(page["text"])
	for expected: String in ["five tribes", "Tribe bonuses", "Belly", "Fly South", "Egg"]:
		assert_string_contains(words, expected)


func _mark(marks: Array) -> Dictionary:
	var mark: Dictionary = marks[0]
	return mark
