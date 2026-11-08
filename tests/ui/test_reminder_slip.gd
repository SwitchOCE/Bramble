extends GutTest
## Reminder text (what a keyword means) stays off the card. It opens on hover (PC) or tap (phone),
## italic, smaller than the rules and on its own slip (owner, 8 Nov 2026).

const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const ReminderSlip := preload("res://src/ui/widgets/reminder_slip.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")

const PC: Vector2 = Vector2(1920, 1080)
const PHONE: Vector2 = Vector2(1688, 780)


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _plain(bbcode: String) -> String:
	return RegEx.create_from_string("\\[[^\\]]*\\]").sub(bbcode, "", true)


func _detail(window: Vector2, def_id: String) -> CardDetail:
	CardView.window_override = window
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(roundi(1080.0 * window.x / window.y), 1080)
	add_child_autofree(viewport)
	var detail: CardDetail = CardDetail.new()
	viewport.add_child(detail)
	detail.position = Vector2(40, 40)
	detail.size = Vector2(620, 1000)
	detail.show_unit(UnitViews.from_def(UnitLibrary.load_dir().get_unit(def_id)))
	return detail


func test_no_card_text_carries_a_keyword_reminder() -> void:
	for def: Dictionary in UnitLibrary.load_dir().all_units():
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(def, golden)
			var full: String = _plain(CardDetail.full_text_bbcode(view))
			for word: String in KeywordRules.named_on(view):
				var reminder: String = KeywordRules.text(word)
				assert_false(full.contains(reminder), "%s shows %s's reminder" % [def["id"], word])


func test_each_keyword_in_the_rules_is_a_link() -> void:
	var view: Dictionary = UnitViews.from_def(UnitLibrary.load_dir().get_unit("belladonna"))
	var full: String = CardDetail.full_text_bbcode(view)
	assert_string_contains(full, "[url=kw:Nightshade]")
	assert_eq(full.count("[url=kw:Nightshade]"), 1, "the first mention only")
	assert_string_contains(_plain(full), Data.s(view, "text"), "the rules read as printed")


func test_hover_shows_the_reminder_on_pc_and_leaving_hides_it() -> void:
	var detail: CardDetail = _detail(PC, "belladonna")
	var notes: RichTextLabel = detail.get("_notes")
	assert_false(detail.reminder.visible, "nothing until asked")
	notes.meta_hover_started.emit("kw:Nightshade")
	assert_true(detail.reminder.visible)
	assert_eq(detail.reminder.keyword, "Nightshade")
	var text: RichTextLabel = detail.reminder.get("_text")
	assert_string_contains(text.get_parsed_text(), KeywordRules.text("Nightshade"))
	notes.meta_hover_ended.emit("kw:Nightshade")
	assert_false(detail.reminder.visible, "PC: leaving the word hides it")


func test_tap_opens_it_on_a_phone_and_a_second_tap_closes_it() -> void:
	var detail: CardDetail = _detail(PHONE, "belladonna")
	var notes: RichTextLabel = detail.get("_notes")
	# A touch arrives as hover then click in the same frame.
	notes.meta_hover_started.emit("kw:Nightshade")
	notes.meta_clicked.emit("kw:Nightshade")
	assert_true(detail.reminder.visible, "the tap opens it")
	notes.meta_hover_ended.emit("kw:Nightshade")
	assert_true(detail.reminder.visible, "touch has no hover to end")
	await wait_process_frames(3)
	notes.meta_clicked.emit("kw:Nightshade")
	assert_false(detail.reminder.visible, "a second tap closes it")


func test_reminder_is_italic_smaller_and_set_apart_at_both_sizes() -> void:
	for window: Vector2 in [PC, PHONE]:
		var detail: CardDetail = _detail(window, "belladonna")
		var notes: RichTextLabel = detail.get("_notes")
		notes.meta_hover_started.emit("kw:Nightshade")
		var text: RichTextLabel = detail.reminder.get("_text")
		var rules_size: int = notes.get_theme_font_size("normal_font_size")
		var reminder_size: int = text.get_theme_font_size("normal_font_size")
		assert_lt(reminder_size, rules_size, "smaller than the rules at %s" % window)
		assert_gte(reminder_size, LayoutCheck.DESKTOP_RULES_FONT)
		if window == PHONE:
			assert_eq(reminder_size, UiTheme.MIN_FONT, "never under the phone minimum")
		assert_eq(text.get_theme_font("normal_font"), UiTheme.italic_font(), "italic")
		assert_eq(
			text.get_theme_color("default_color"), UiTheme.REMINDER, "muted, unlike rules ink"
		)
		var slip: Rect2 = detail.reminder.get_rect()
		var rules: Rect2 = notes.get_rect()
		assert_lte(rules.end.y, slip.position.y, "under the rules, never over them")
		assert_eq(LayoutCheck.problems(detail, "reminder %s" % window), PackedStringArray())


func test_a_new_card_closes_the_last_ones_reminder() -> void:
	var detail: CardDetail = _detail(PC, "belladonna")
	var notes: RichTextLabel = detail.get("_notes")
	notes.meta_clicked.emit("kw:Nightshade")
	assert_true(detail.reminder.visible)
	detail.show_unit(UnitViews.from_def(UnitLibrary.load_dir().get_unit("mr_crumb")))
	assert_false(detail.reminder.visible)


func test_a_reminder_brings_the_terms_it_uses() -> void:
	var words: String = ReminderSlip.reminder_bbcode("Pounce")
	assert_string_contains(words, "[b]Pounce:[/b]")
	assert_string_contains(words, "[b]Next to:[/b]")
	assert_string_contains(words, "[b]Cycle:[/b]")


func test_statuses_golden_and_created_name_their_word_and_keep_the_meaning_a_tap_away() -> void:
	var view: Dictionary = {
		"def_id": "common_toad",
		"golden": true,
		"origin": "created",
		"statuses": [{"status": "nightshade", "data": {}}],
	}
	var state: String = CardDetail.state_bbcode(view)
	for word: String in ["Golden", "Created", "Nightshade"]:
		assert_string_contains(state, "[url=kw:%s]" % word)
	assert_false(_plain(state).contains("first loses half"), "the meaning is not on the card")
	assert_string_contains(CardDetail.reminder_for("Golden", view), "Double stats")
	assert_string_contains(CardDetail.reminder_for("Created", view), "not bought")
