extends GutTest
## Phone regressions: birds away keep the shop controls, long sell help fits the detail panel,
## opposing scout columns line up, and slot marks leave the board's captions readable.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const PHONE_CANVAS: Vector2i = Vector2i(2337, 1080)


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _phone() -> SubViewport:
	CardView.window_override = Vector2(1688, 780)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = PHONE_CANVAS
	add_child_autofree(viewport)
	return viewport


func _screen(viewport: SubViewport) -> RecruitScreen:
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var screen: RecruitScreen = RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


func test_birds_away_leave_gold_tier_and_refresh_available_until_a_nest_is_tapped() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var state: Dictionary = screen.port.get_state()
	state["away"] = [{"name": "Old Tern", "turns_left": 3, "nest": 2}]
	screen.render()
	await get_tree().process_frame
	for key: String in ["_gold", "_tier_button", "_refresh_button", "_freeze_button"]:
		var control: Control = screen.get(key)
		assert_true(control.is_visible_in_tree(), key)
	var detail: CardDetail = screen.get("_detail")
	assert_false(detail.visible)
	screen.call("_on_tapped", "board", 2)
	assert_true(detail.visible, "the Nest still opens its full explanation")
	assert_string_contains(str(detail.shown["text"]), "Old Tern comes home in 3 turns")


func test_long_bird_and_belly_help_fit_above_the_actions() -> void:
	var viewport: SubViewport = _phone()
	var detail: CardDetail = CardDetail.new()
	detail.theme = UiTheme.get_theme()
	detail.position = Vector2(1800, 112)
	detail.size = Vector2(442, 747)
	viewport.add_child(detail)
	for hint: String in [
		"Selling this keeps the gold. It comes home in 3 turns.",
		"Tap a slot to play it, or an Ooze to swallow it",
	]:
		detail.clear_actions()
		detail.show_unit(
			{"name": "Mrs Jay", "def_id": "mrs_jay", "kind": "unit", "text": "Fly South."}, hint
		)
		detail.add_action("Sell for good", func() -> void: pass, 1)
		detail.add_action("Into a Belly", func() -> void: pass)
		await get_tree().process_frame
		var help: Label = detail.get("_hint")
		var notes: RichTextLabel = detail.get("_notes")
		assert_eq(help.get_visible_line_count(), help.get_line_count(), hint)
		assert_lte(notes.position.y + notes.size.y, help.position.y, "rules stay above help")
		assert_lte(help.position.y + help.size.y, detail.actions.position.y)
		assert_eq(LayoutCheck.problems(detail, "phone detail"), PackedStringArray())


func test_phone_scout_columns_face_the_matching_own_slots_without_covering_the_shop() -> void:
	var screen: RecruitScreen = _screen(_phone())
	screen.toggle_scout()
	await get_tree().process_frame
	var own: BoardView = screen.get("_board")
	var scout: Control = screen.get("_scout")
	var theirs: BoardView = scout.get("_board")
	for slot: int in BoardView.SLOTS:
		assert_almost_eq(
			own.slot_global_center(slot).x,
			theirs.slot_global_center(slot).x,
			0.1,
			"opposing slot %d" % slot
		)
	var shop: Control = screen.get("_shop_cards")
	assert_false(theirs.get_global_rect().intersects(shop.get_global_rect()))
	assert_false(theirs.get_global_rect().intersects(own.get_global_rect()))
	assert_eq(LayoutCheck.problems(screen, "phone scouting"), PackedStringArray())


func test_nests_keep_their_slot_caption_and_rings_clear_the_keyword_chip() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	raw["away"] = [
		{"name": "Old Tern", "turns_left": 3, "nest": 2},
		{"name": "Mother Goose", "turns_left": 1, "nest": 0},
	]
	screen.render()
	await get_tree().process_frame
	var board: BoardView = screen.get("_board")
	var slot_name: Label = board.slots[2].get("_name_label")
	var note: Panel = board.slots[2].get("_note_box")
	assert_false(slot_name.visible, "the Egg replaces the bare slot name")
	assert_false(note.visible, "no location caption is covered by the Nest caption")
	var chips: Array = board.get("_chips")
	var slot_chip: Label = chips[2]
	assert_true(slot_chip.visible, "the Nest still names its slot")
	assert_eq(slot_chip.text, "F3")
	var marks: Control = board.get("_marks")
	var rings: Array = marks.get("_ring_labels")
	var ring: Label = rings[0]
	var keyword: Control = board.cards[0].get("_chip")
	assert_false(ring.get_global_rect().intersects(keyword.get_global_rect()))
	var nests: Array = marks.get("_nest_labels")
	var nest: Label = nests[0]
	assert_false(nest.get_global_rect().intersects(ring.get_global_rect()))
	assert_false(nest.get_global_rect().intersects(board.cards[0].get_global_rect()))
	raw["next_opponent_last_nests"] = [0, 5]
	screen.toggle_scout()
	await get_tree().process_frame
	assert_eq(LayoutCheck.problems(screen, "Nest and Ring captions"), PackedStringArray())
	screen.toggle_scout()
	screen.call("_on_tapped", "board", 0)
	await get_tree().process_frame
	assert_true(nest.visible, "the Nest keeps its own countdown")
	assert_eq(ring.text, "+2/+2")
	assert_true(
		board.label_rect(0).encloses(ring.get_rect()), "the Ring fits the existing name strip"
	)


func test_selected_bird_keeps_economy_visible_and_shows_every_rule_and_hint_line() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	var units: Array = raw["board"]
	var library: UnitLibrary = UnitLibrary.load_dir()
	var bird: Dictionary = UnitViews.from_def(library.get_unit("mrs_jay"))
	bird["played_round"] = 1
	units[0] = bird
	var ooze: Dictionary = units[1]
	ooze["belly"] = 1
	ooze["held"] = []
	var slot_effects: Array = raw["slot_effects"]
	slot_effects[1] = [{"attack": 2, "health": 2}]
	screen.render()
	screen.call("_on_tapped", "board", 0)
	await get_tree().process_frame
	await get_tree().process_frame
	var detail: CardDetail = screen.get("_detail")
	assert_true(detail.visible, "the bird is selected")
	assert_eq(str(detail.shown["def_id"]), "mrs_jay")
	assert_eq(detail.actions.get_child_count(), 2, "Fly south and Into a Belly both stay available")
	for key: String in [
		"_gold", "_tier_button", "_refresh_button", "_freeze_button", "_end_button"
	]:
		var control: Control = screen.get(key)
		assert_true(control.is_visible_in_tree(), key + " stays visible while reading the bird")
		assert_false(detail.get_global_rect().intersects(control.get_global_rect()), key)
	var notes: RichTextLabel = detail.get("_notes")
	var hint: Label = detail.get("_hint")
	assert_lte(float(notes.get_content_height()), notes.size.y, "the complete Fly South rules fit")
	assert_eq(hint.get_visible_line_count(), hint.get_line_count(), "the complete sell hint fits")
	assert_lte(notes.position.y + notes.size.y, hint.position.y)
	var board: BoardView = screen.get("_board")
	for slot: int in BoardView.SLOTS:
		assert_gte(board.slots[slot].size.x, 122.0, "slot %d remains finger sized" % slot)
		assert_gte(board.slots[slot].size.y, 122.0)
	assert_false(detail.get_global_rect().intersects(board.get_global_rect()))
	var marks: Control = board.get("_marks")
	var rings: Array = marks.get("_ring_labels")
	for slot: int in BoardView.SLOTS:
		var ring: Label = rings[slot]
		if not ring.visible or board.cards[slot] == null:
			continue
		var slip: Control = board.cards[slot].get("_turns")
		if slip != null and slip.visible:
			assert_false(ring.get_global_rect().intersects(slip.get_global_rect()))
	assert_eq(LayoutCheck.problems(screen, "selected phone bird"), PackedStringArray())


func test_scout_slot_labels_clear_every_stat_badge() -> void:
	var screen: RecruitScreen = _screen(_phone())
	screen.toggle_scout()
	await get_tree().process_frame
	var scout: Control = screen.get("_scout")
	var board: BoardView = scout.get("_board")
	var chips: Array = board.get("_chips")
	var own: Control = screen.get("_board")
	for slot: int in BoardView.SLOTS:
		var card: CardView = board.cards[slot]
		if card == null:
			continue
		var chip: Label = chips[slot]
		assert_true(chip.is_visible_in_tree(), "slot %d has a caption" % slot)
		for key: String in ["_attack_badge", "_health_badge"]:
			var badge: Control = card.get(key)
			assert_false(
				chip.get_global_rect().intersects(badge.get_global_rect()), "%d %s" % [slot, key]
			)
		assert_false(chip.get_global_rect().intersects(own.get_global_rect()))


func test_selected_phone_row_tags_and_posset_counters_do_not_overlap() -> void:
	var screen: RecruitScreen = _screen(_phone())
	var raw: Dictionary = screen.port.get_state()
	var units: Array = raw["board"]
	var library: UnitLibrary = UnitLibrary.load_dir()
	var posset: Dictionary = UnitViews.from_def(library.get_unit("mrs_posset"))
	posset["belly"] = 1
	posset["held"] = [UnitViews.from_def(library.get_unit("mrs_sorrel"))]
	units[0] = posset
	var bird: Dictionary = UnitViews.from_def(library.get_unit("mrs_jay"))
	bird["played_round"] = 1
	units[6] = bird
	var effects: Array = raw["slot_effects"]
	effects[0] = [{"attack": 2, "health": 2}]
	screen.render()
	screen.call("_on_tapped", "board", 6)
	await get_tree().process_frame
	await get_tree().process_frame
	var shop: Control = screen.get("_shop_tag")
	var scout: Control = screen.get("_scout_token")
	assert_false(shop.get_global_rect().intersects(scout.get_global_rect()), "SHOP clears Scout")
	var back: Control = screen.get("_back_tag")
	var hero: Control = screen.get("_hero")
	assert_gte(
		back.global_position.x - hero.get_global_rect().end.x,
		20.0,
		"BACK clears the portrait and glyph overhang"
	)
	var board: BoardView = screen.get("_board")
	assert_gt(back.z_index, board.z_index, "BACK draws above the tray in the compact gutter")
	for slot: int in range(BoardView.FRONT, BoardView.SLOTS):
		if board.cards[slot] != null:
			assert_false(
				back.get_global_rect().grow(4.0).intersects(board.cards[slot].get_global_rect()),
				"BACK clears the back-row cards"
			)
	var card: CardView = board.cards[0]
	var belly: Control = card.get("_chip")
	var inside: Control = card.get("_turns")
	assert_true(inside.visible)
	assert_false(
		inside.get_global_rect().intersects(belly.get_global_rect()), "In 1/1 clears Belly"
	)
	assert_true(card.get_global_rect().encloses(inside.get_global_rect()), "In 1/1 stays on Posset")
	for key: String in ["_attack_badge", "_health_badge"]:
		var badge: Control = card.get(key)
		assert_false(inside.get_global_rect().intersects(badge.get_global_rect()), key)
	var marks: Control = board.get("_marks")
	var rings: Array = marks.get("_ring_labels")
	var ring: Label = rings[0]
	assert_true(board.label_rect(0).encloses(ring.get_rect()), "the Ring stays in F1's header")
	assert_eq(LayoutCheck.problems(screen, "selected phone cosmetics"), PackedStringArray())
