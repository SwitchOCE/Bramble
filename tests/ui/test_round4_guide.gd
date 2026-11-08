extends GutTest

const Guide := preload("res://src/ui/screens/how_to_play.gd")


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
	var note: String = preload("res://src/ui/screens/recruit_view.gd").fight_note(
		{"round_toll": 7, "damage_cap": 12}
	)
	assert_true("up to 7" in note)
	assert_true("cap 12" in note)
	var toll_pages: Array[Dictionary] = []
	for page: Dictionary in Guide.PAGES:
		if str(page["title"]) == "Stay standing to win":
			toll_pages.append(page)
	assert_eq(toll_pages.size(), 1, "find the toll page even with tribe pages after it")
	if toll_pages.is_empty():
		return
	var words: String = str(toll_pages[0]["text"])
	assert_true("at four" in words)
	assert_true("Last Stand" in words)
