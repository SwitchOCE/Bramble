extends GutTest

const Guide := preload("res://src/ui/screens/how_to_play.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const ReminderSlip := preload("res://src/ui/widgets/reminder_slip.gd")


func test_core_loop_precedes_card_keywords_and_covers_the_economy() -> void:
	var words: String = ""
	for index: int in 5:
		words += str(Guide.PAGES[index]["text"]).to_lower()
	for needed: String in [
		"3 gold",
		"4, 5",
		"10",
		"carries over",
		"tier up",
		"refresh",
		"freeze",
		"sell",
		"hero",
		"spells",
		"permanent",
		"golden",
		"discover"
	]:
		assert_true(needed in words, needed)
	assert_lte(Guide.PAGES.size(), 14, "core loop, tribe and travel examples, positioning and tips")


## docs/ideation/wording-guide.md rule 8: a guide page is at most 40 words.
func test_every_guide_page_is_forty_words_or_fewer() -> void:
	for page: Dictionary in Guide.PAGES:
		var words: PackedStringArray = str(page["text"]).replace("\n", " ").split(" ", false)
		assert_lte(words.size(), 40, str(page["title"]))


func test_guide_pages_fit_the_phone_canvas() -> void:
	var guide: Guide = Guide.new()
	guide.set_anchors_preset(Control.PRESET_TOP_LEFT)
	guide.size = Vector2(2337, 1080)
	add_child_autofree(guide)
	guide._layout()
	for index: int in Guide.PAGES.size():
		guide.page = index
		guide._show_page()
		await get_tree().process_frame
		var body: Label = guide.get("_text")
		assert_lte(body.get_minimum_size().y, body.size.y, "page %d body" % index)
		var demo: Control = guide.get("_demo")
		for child: Node in demo.get_children():
			if child is Control:
				assert_lte(
					(child as Control).position.y + (child as Control).size.y,
					demo.size.y + 1,
					"page %d example" % index
				)


func test_toll_result_and_hint_show_cap_limited_damage() -> void:
	var screen := preload("res://src/ui/screens/combat_screen.gd").new()
	add_child_autofree(screen)
	var log_text := preload("res://src/ui/screens/combat_log.gd").new()
	for added: int in [0, 2, 7]:
		var event: Dictionary = {
			"type": "combat_end",
			"winner": 1,
			"damage": 12,
			"damage_uncapped": 19 - added,
			"round_toll": 7,
			"round_toll_added": added
		}
		screen.model.apply(event)
		screen._show_result()
		var expected: String = "Round toll added %d" % added
		assert_true(expected in screen._result_text.text, "visible result: " + expected)
		assert_true(expected in log_text._end(event), "combat log: " + expected)
		assert_eq("limited by cap" in screen._result_text.text, added < 7)
	var note: String = RecruitView.fight_note({"round_toll": 7, "damage_cap": 12})
	assert_true("Toll 7" in note)
	assert_true("cap 12" in note)
	var damage_pages: Array[Dictionary] = []
	for page: Dictionary in Guide.PAGES:
		if str(page["title"]) == "Stay standing to win":
			damage_pages.append(page)
	assert_eq(damage_pages.size(), 1, "find the damage page even with tribe pages after it")
	if damage_pages.is_empty():
		return
	var words: String = str(damage_pages[0]["text"])
	assert_true("base damage, plus 1 per" in words)
	assert_true("enemy starting survivor" in words)


func test_damage_page_terms_open_their_reminders() -> void:
	for page: Dictionary in Guide.PAGES:
		if str(page["title"]) != "Stay standing to win":
			continue
		var terms: Array = page.get("terms", [])
		assert_eq(terms.size(), 4, "the damage rules are links, not paragraphs")
		for term: Variant in terms:
			var said: String = ReminderSlip.reminder_bbcode(str(term))
			assert_false(said.is_empty(), "%s opens a reminder" % term)
			assert_true(said.split(" ").size() <= 24, "%s stays one short sentence" % term)


func test_default_damage_hint_shows_base_and_starting_survivors() -> void:
	var note: String = RecruitView.fight_note(
		{"damage_mode": "v05", "base_damage": 7, "round_toll": 0, "damage_cap": 0}
	)
	assert_eq(note, "7 + starting survivors")
