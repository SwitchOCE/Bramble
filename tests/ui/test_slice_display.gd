extends GutTest
## What the first slice's cards need on the recruit screen: scouting, Rings and bands, where a Pass
## lands, Acorns combining, and slot strips that never trail off.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func _slice_screen() -> RecruitScreen:
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	return screen


func test_scouting_shows_the_last_board_by_slot_from_the_next_plaque() -> void:
	var screen: RecruitScreen = _slice_screen()
	var scout: Control = screen.get("_scout")
	assert_false(scout.visible, "closed until asked for")
	var lobby: Control = screen.get("_lobby")
	lobby.emit_signal("next_tapped")
	assert_true(scout.visible, "one tap on the next opponent's plaque")
	var shown: int = scout.get("unit_count")
	assert_eq(shown, 4)
	var board: Control = scout.get("_board")
	var cards: Array = board.get("cards")
	assert_true(cards[2] != null, "F3 stands in F3")
	assert_true(cards[1] == null, "the gap at F2 stays a gap")
	screen.call("_on_tapped", "scout", 2)
	var detail: Control = screen.get("_detail")
	assert_true(detail.visible, "a tap on their unit opens its full text")
	var shown_card: Dictionary = detail.get("shown")
	var theirs: Array = screen.state["next_opponent_last_board"]
	var third: Dictionary = theirs[2]
	assert_eq(str(shown_card["name"]), str(third["name"]))


func test_scouting_shows_their_rings_and_their_hero_a_tap_away() -> void:
	var screen: RecruitScreen = _slice_screen()
	var raw: Dictionary = screen.port.get_state()
	raw["next_opponent_last_slot_effects"] = [[], [{"attack": 2, "health": 1}], [], [], [], [], []]
	raw["next_opponent_hero"] = {"name": "Dame Test", "text": "Her power."}
	screen.toggle_scout()
	screen.call("_on_tapped", "scout", 1)
	var detail: Control = screen.get("_detail")
	var on_slot: Dictionary = detail.get("shown")
	assert_string_contains(str(on_slot["text"]), "Ring +2/+1")
	screen.call("_show_opponent")
	var hero_card: Dictionary = detail.get("shown")
	assert_string_contains(str(hero_card["text"]), "Her power.")


func test_scouting_says_so_when_they_have_not_fought() -> void:
	var screen: RecruitScreen = _slice_screen()
	screen.port.get_state()["next_opponent_last_board"] = []
	screen.toggle_scout()
	var scout: Control = screen.get("_scout")
	var shown: int = scout.get("unit_count")
	assert_eq(shown, 0)
	var empty: Label = scout.get("_empty")
	assert_true(empty.visible)


func test_pass_lands_on_the_last_touching_unit_and_a_gap_stops_it() -> void:
	var crumb: Dictionary = {"text": "When played and when sold: Pass right +1/+1."}
	var unit: Dictionary = {"text": ""}
	var board: Array = [crumb, unit, null, null, unit, null, null]
	assert_eq(RecruitView.pass_preview(board, crumb, 0, 0), 1, "F1, B1, F2, then the gap at B2")
	assert_eq(
		RecruitView.pass_preview(board, crumb, 0, -1), 1, "sold: starts from the slot it left"
	)
	var gap: Array = [crumb, null, null, null, null, null, null]
	assert_eq(RecruitView.pass_preview(gap, crumb, 0, 0), -1, "nobody touching: nobody gets it")
	assert_eq(RecruitView.pass_preview(board, unit, 1, 1), -1, "no Pass on the card")


func test_rings_and_bands_read_from_slot_effects_on_empty_slots_too() -> void:
	var marks: Array = RecruitView.slot_marks(_slice_screen().state)
	assert_eq(Data.s(Data.entry(marks, 2), "ring"), "+1/+1", "a Ring on empty F3")
	assert_eq(Data.b(Data.entry(marks, 0), "band"), true, "F1 has a band")
	assert_eq(Data.s(Data.entry(marks, 3), "ring"), "", "bare F4")
	assert_string_contains(RecruitView.slot_note(Data.entry(marks, 2), 2), "F3: Ring +1/+1")


func test_acorns_combining_is_announced() -> void:
	var acorn: Dictionary = {"def_id": "acorn", "name": "Acorn", "combines_into": "stash"}
	var stash: Dictionary = {"def_id": "stash", "name": "Stash", "combines_into": "great_hoard"}
	var hoard: Dictionary = {"def_id": "great_hoard", "name": "Great Hoard"}
	var before: Dictionary = {"hand": [acorn, acorn]}
	var after: Dictionary = {"hand": [stash]}
	assert_eq(RecruitView.combine_note(before, after), "Three Acorns made a Stash.")
	assert_eq(RecruitView.combine_note(after, after), "")
	assert_eq(
		RecruitView.combine_note({"hand": [stash, stash]}, {"hand": [hoard]}),
		"Three Stashes made a Great Hoard."
	)


func test_a_band_is_the_bands_field_not_a_name() -> void:
	var state: Dictionary = {
		"slot_effects":
		[[{"name": "Rainbow band", "attack": 1, "health": 1}], [], [], [], [], [], []],
		"bands": [false, true, false, false, false, false, false],
	}
	var marks: Array = RecruitView.slot_marks(state)
	assert_false(Data.b(Data.entry(marks, 0), "band"), "a Ring by any name stays a Ring")
	assert_true(Data.b(Data.entry(marks, 0), "has_ring"))
	assert_true(Data.b(Data.entry(marks, 1), "band"))
	assert_false(Data.b(Data.entry(marks, 1), "has_ring"))


func test_a_turn_slip_counts_to_the_goal_or_a_timer() -> void:
	assert_eq(RecruitView.turns_word({"turns_goal": 3, "turns_in_slot": 2}), "2/3")
	assert_eq(RecruitView.turns_word({"turns_goal": 0, "turns_in_slot": 2}), "")
	assert_eq(RecruitView.turns_word({"timers": [{"left": 2}]}), "2 left")


func test_an_acorn_lands_on_a_unit_that_eats_it_and_aims_keep_to_their_row() -> void:
	var acorn: Dictionary = {"aim": "none", "gold_value": 1}
	var eater: Dictionary = {"eats_items": true, "name": "Alderman"}
	var plain: Dictionary = {"name": "Vole"}
	assert_true(RecruitView.item_lands(acorn, eater, 1))
	assert_false(RecruitView.item_lands(acorn, plain, 1))
	assert_false(RecruitView.item_lands(acorn, {}, 1))
	assert_true(RecruitView.item_lands({"aim": "front_unit"}, plain, 0))
	assert_false(RecruitView.item_lands({"aim": "front_unit"}, plain, 5))
	assert_true(RecruitView.item_lands({"aim": "back_unit"}, plain, 5))
	assert_true(RecruitView.item_lands({"aim": "any_slot"}, {}, 2))
	assert_false(RecruitView.item_lands({"aim": "shop_unit"}, plain, 2))


func test_a_slot_strip_shows_the_whole_name_or_its_last_word_never_an_ellipsis() -> void:
	var words: Label = UiTheme.head("", UiTheme.FONT_SMALL)
	add_child_autofree(words)
	words.size = Vector2(151, 44)
	assert_eq(BoardView.fit_name("Marsh Frog", words), "Marsh Frog")
	assert_eq(BoardView.fit_name("Honorary Treasurer Of Parishes Far", words), "Far")
	assert_eq(
		BoardView.fit_name("Will-o'-the-Wisp Grand-Duchess-Of-The-Far-Marshes", words), "Marshes"
	)


func test_the_toast_stands_clear_of_the_shop() -> void:
	var screen: RecruitScreen = _slice_screen()
	screen.show_toast("Three Acorns made a Stash.")
	var toast: Label = screen.get("_toast")
	assert_true(toast.position.y + toast.size.y <= RecruitScreen.SHOP_TOP - 20.0)
