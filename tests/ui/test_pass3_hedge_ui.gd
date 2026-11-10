extends GutTest
## Fixed recruit views: reuse the hand header and reader, keeping marks wordless.
@warning_ignore_start("unsafe_call_argument")

const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const HedgeMarks := preload("res://src/ui/widgets/hedgerow_marks.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _view(id: String, golden: bool = false) -> Dictionary:
	var factor: int = 2 if golden else 1
	return {
		"def_id": id,
		"name": "The Standing Committee" if id == "standing_committee" else "Squire Lollop",
		"tier": 5 if id == "standing_committee" else 6,
		"attack": 50 * factor,
		"health": 70 * factor,
		"golden": golden,
		"tribes": ["Hedgerow folk"],
		"text":
		(
			"End of Turn: Hedgerow folk touching this gain a quarter of the smallest one's stats."
			if id == "standing_committee"
			else (
				"Start of Turn: Hedgerow folk touching this, except your biggest, "
				+ "gain a tenth of its stats."
			)
		),
		"hedgerow_preview": Vector2i(12, 17) * factor,
	}


func test_normal_and_golden_shares_use_the_existing_reader_on_phone_and_desktop() -> void:
	for window: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		CardView.window_override = window
		var viewport := SubViewport.new()
		viewport.size = Vector2i(roundi(1080.0 * window.x / window.y), 1080)
		add_child_autofree(viewport)
		var detail: CardDetail = CardDetail.new()
		detail.theme = UiTheme.get_theme()
		detail.position = Vector2(40, 40)
		detail.size = Vector2(442, 850)
		viewport.add_child(detail)
		var nodes: int = detail.get_child_count()
		for id: String in ["squire_lollop", "standing_committee"]:
			for golden: bool in [false, true]:
				detail.show_unit(_view(id, golden))
				await get_tree().process_frame
				var notes: RichTextLabel = detail.get("_notes")
				var expected: String = "+24/+34" if golden else "+12/+17"
				assert_string_contains(notes.text, expected)
				assert_string_contains(notes.text, "per recipient")
				assert_string_contains(
					notes.text,
					"Start of Turn share" if id == "squire_lollop" else "End of Turn share"
				)
				assert_gte(notes.get_theme_font_size("normal_font_size"), UiTheme.MIN_FONT)
				assert_eq(detail.get_child_count(), nodes, "share adds no text nodes")
				assert_eq(LayoutCheck.problems(detail, "Hedgerow reader"), PackedStringArray())


func test_wake_progress_stays_wordless_and_selection_keeps_the_same_state() -> void:
	for golden: bool in [false, true]:
		for id: String in ["alderman_dozey", "sleeping_partner"]:
			var view: Dictionary = _view(id, golden)
			view.erase("hedgerow_preview")
			view["name"] = "Alderman Dozey" if id == "alderman_dozey" else "The Sleeping Partner"
			view["text"] = "Every 3 turns in this slot: double its stats."
			view["hedgerow_clock"] = true
			view["turns_goal"] = 3
			view["turns_in_slot"] = 2
			view["hedgerow_runt"] = true
			var card: CardView = CardView.new()
			add_child_autofree(card)
			card.show_unit(view, CardView.Mode.BOARD)
			card.set_card_width(189)
			var mark: HedgeMarks = card.get("_hedge_marks")
			assert_eq(mark.period, 3)
			assert_eq(mark.progress, 2)
			assert_true(mark.visible)
			assert_eq(mark.get_child_count(), 0)
			assert_eq(mark.mouse_filter, Control.MOUSE_FILTER_IGNORE)
			assert_string_contains(
				CardDetail.full_text_bbcode(view), "Moving this restarts the wait"
			)
			assert_string_contains(CardDetail.full_text_bbcode(view), "Sleep: 2/3")
			card.selected = true
			assert_eq(mark.progress, 2, "selection keeps the current wake state")
			card.selected = false
			assert_eq(mark.progress, 2)
			card.selected = true
			view["turns_in_slot"] = 0
			card.show_unit(view, CardView.Mode.BOARD)
			assert_eq(mark.progress, 0, "a move reset is visible in existing pips")
			assert_string_contains(CardDetail.full_text_bbcode(view), "Sleep: 0/3")
			card.show_unit({"name": "Plain unit", "tribes": []})
			assert_false(mark.visible)


func test_larder_gold_uses_the_one_tap_reader_without_an_extra_phone_label() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	state["hand"] = []
	state["larder"] = 0
	var screen: RecruitScreen = RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	var zone: Control = screen.get("_hand_zone")
	var nodes: int = zone.get_child_count()
	var count: Label = screen.get("_hand_count")
	assert_false(count.text.contains("g"))
	state["larder"] = 160
	screen.render()
	await get_tree().process_frame
	assert_false(count.visible, "Larder must not add a resting label below full hand capacity")
	assert_string_contains(zone.tooltip_text, "Acorns, Stashes and Great Hoards: 160")
	screen._on_tapped("hand", -1)
	var detail: CardDetail = screen.get("_detail")
	var notes: RichTextLabel = detail.get("_notes")
	assert_true(detail.visible)
	assert_string_contains(notes.get_parsed_text(), "Acorns, Stashes and Great Hoards: 160")
	assert_eq(zone.get_child_count(), nodes, "Larder adds no static labels")
	for label: Label in [count]:
		var font_size: int = label.get_theme_font_size("font_size")
		var width: float = (
			label
			. get_theme_font("font")
			. get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			. x
		)
		assert_gte(font_size, UiTheme.MIN_FONT)
		assert_lte(width, label.size.x, label.text + " fits at phone minimum")


func test_roles_and_hunker_stay_in_the_reader_without_standing_marks() -> void:
	var mark: HedgeMarks = HedgeMarks.new()
	add_child_autofree(mark)
	var view: Dictionary = _view("standing_committee")
	view["hedgerow_runt"] = true
	view["statuses"] = [{"status": "hunker"}]
	mark.show_state(view, true)
	assert_false(mark.visible, "roles and aura status add no standing face marks")
	assert_eq(mark.get_child_count(), 0)
	var detail: CardDetail = CardDetail.new()
	add_child_autofree(detail)
	detail.show_unit(view)
	var notes: RichTextLabel = detail.get("_notes")
	assert_string_contains(notes.text, "The Standing Committee's current smallest unit.")
	assert_string_contains(notes.text.to_lower(), "hunker")
	assert_string_contains(notes.text, "+12/+17 per recipient")
	detail.show_unit({"name": "Plain unit", "tribes": []})
	assert_false(notes.text.contains("current smallest unit"), "the role clears with the view")
	assert_false(notes.text.to_lower().contains("hunker"), "the aura clears with the view")
