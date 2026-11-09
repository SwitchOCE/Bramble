extends GutTest
@warning_ignore_start("unsafe_call_argument")

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CardRulings := preload("res://src/ui/card_rulings.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const AwayTray := preload("res://src/ui/widgets/away_tray.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_all_wave1_cards_keep_readable_phone_rules_or_a_tap_target() -> void:
	CardView.window_override = Vector2(1688, 780)
	var holder := Control.new()
	holder.size = Vector2(1920, 1080)
	holder.theme = UiTheme.get_theme()
	add_child_autofree(holder)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var count: int = 0
	for definition: Dictionary in library.pool_units("slice"):
		var tribes: Array = definition["tribes"]
		if not tribes.has("Birds") and not tribes.has("Fairies"):
			continue
		count += 1
		for golden: bool in [false, true]:
			var card := CardView.new()
			card.position = Vector2(200, 200)
			card.show_unit(UnitViews.from_def(definition, golden), CardView.Mode.SHOP)
			card.set_card_width(CardView.SHOP_WIDTH)
			holder.add_child(card)
			await get_tree().process_frame
			assert_true(
				card.rules_shown or not card.chip_shown.is_empty(),
				"%s keeps an ability on its tile" % definition["name"]
			)
			var rules: Label = card.get("_rules")
			if card.rules_shown:
				assert_gte(rules.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
			assert_eq(LayoutCheck.problems(card, str(definition["name"])), PackedStringArray())
			card.queue_free()
	assert_eq(count, 32, "exactly sixteen cards of each wave1 tribe are in the pool")


func test_lump_drag_reads_the_full_away_bird_and_the_configured_share() -> void:
	var lump: Dictionary = {
		"def_id": "great_lump",
		"attack": 50,
		"health": 65,
		"pass3_content": true,
		"nest_multiplier": 1.0,
		"stat_layers": {"aura_attack": 45, "aura_health": 57},
	}
	var target: Dictionary = {
		"nest": true,
		"bird_attack": 101,
		"bird_health": 125,
		"slot_attack": 3,
		"slot_health": 3,
	}
	var preview: Dictionary = RecruitHeld.lump_preview(lump, target)
	assert_eq(preview["attack"], 109)
	assert_eq(preview["health"], 136)
	lump["nest_multiplier"] = 2.0
	preview = RecruitHeld.lump_preview(lump, target)
	assert_eq(preview["attack"], 210, "golden borrowing doubles the full body")
	assert_eq(preview["health"], 261)
	assert_eq(lump["attack"], 50, "a forecast does not mutate live state")


func test_ring_count_zero_one_egg_and_homecoming_preview_are_visible() -> void:
	var away: Dictionary = {
		"name": "Chiffchaff",
		"nest": 0,
		"turns_left": 1,
		"attack": 78,
		"health": 94,
		"home_attack": 156,
		"home_health": 188,
		"pass3_content": true,
	}
	var state: Dictionary = {
		"slot_effects": [[{"name": "Ring", "count": 12, "attack": 72, "health": 72}]],
		"away": [away],
	}
	var marks: Array = RecruitView.slot_marks(state)
	assert_eq(marks[0]["ring"], "+72/+72 · 12")
	assert_eq(marks[0]["egg_attack"], 72, "Ring stats apply to a 0/1 Egg")
	assert_eq(marks[0]["egg_health"], 73)
	assert_string_contains(str(RecruitHeld.sky_card(state)["text"]), "78/94 → 156/188")
	assert_eq(RecruitView.turns_word({"stork_count": 4, "stork_goal": 6}), "4/6")
	assert_string_contains(CardDetail.state_bbcode({"egged": true}), "Golden Egg used")
	var fetch: Dictionary = {
		"def_id": "cradle_fetch",
		"combat_start_overlay": true,
		"copied_name": "Nan Toadstool",
		"details": "Starts as Nan at 50% stats, plus this slot's Ring."
	}
	assert_string_contains(CardDetail.state_bbcode(fetch), "Combat-start stats")
	assert_string_contains(CardRulings.for_view(fetch), str(fetch["details"]))
	assert_string_contains(CardRulings.for_view(fetch), "two Fetches never share a target")


func test_ring_spell_preview_uses_owner_size_without_a_cap_and_eggs_filter_targets() -> void:
	var state: Dictionary = {
		"pass3_content": true,
		"ring_size": 1.25,
		"slot_effects": [[{"name": "Ring", "count": 33, "attack": 42, "health": 42}]],
	}
	var spell: Dictionary = {"ring_add": [2, 2], "aim": "any_slot"}
	assert_eq(RecruitView.ring_preview(state, spell, 0), "+2/+2", "ceil(35*1.25)-ceil(33*1.25)")
	assert_eq(
		RecruitView.ring_preview(state, spell, 1), "+3/+3", "an empty slot rounds only the total"
	)
	assert_true(RecruitView.item_lands(spell, {}, 0, state), "large Rings remain legal targets")
	var egg: Dictionary = {"def_id": "golden_egg", "aim": "unit"}
	assert_false(RecruitView.item_lands(egg, {"tribes": ["Fairies"]}, 0, state))
	assert_false(RecruitView.item_lands(egg, {"tribes": ["Birds"], "egged": true}, 0, state))
	assert_true(RecruitView.item_lands(egg, {"tribes": ["Birds"]}, 0, state))


func test_ring_size_and_midsummer_fit_beside_supper_at_the_phone_minimum() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	state["ring_size"] = 1.25
	state["midsummer_left"] = 2
	state["lobby_tribes"] = ["Birds", "Fairies", "Hunters", "Bog folk", "Oozes"]
	state["tribe_bonuses"] = {"Fairies": 3, "Birds": 2}
	state["slot_effects"] = [[{"name": "Ring", "count": 12, "attack": 15, "health": 15}]]
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	await wait_process_frames(2)
	var chips: Control = screen.get("_tribes")
	var size_label: Label = chips.get_node("RingSize/Engine")
	var summer_label: Label = chips.get_node("Midsummer/Engine")
	assert_eq(size_label.text, "Ring size 1.25")
	assert_eq(summer_label.text, "Midsummer 2")
	assert_gte(size_label.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
	assert_eq(LayoutCheck.problems(screen, "Fairy engine phone"), PackedStringArray())


func test_fetch_copy_displays_the_current_silenced_text_and_keeps_its_body() -> void:
	var model := CombatModel.new()
	model.apply(
		{
			"type": "combat_start",
			"boards":
			[
				[
					{
						"uid": 1,
						"text": "Cleave.",
						"keywords": ["Cleave"],
						"attack": 100,
						"health": 100
					}
				],
				[{"uid": 2, "text": "Start of Combat: steal text.", "keywords": []}]
			]
		}
	)
	model.apply({"type": "text_taken", "uid": 2, "from": 1})
	model.apply(
		{
			"type": "summon",
			"side": 0,
			"slot": 1,
			"copied": 1,
			"unit":
			{"uid": 3, "text": "Cleave.", "keywords": ["Cleave"], "attack": 50, "health": 50}
		}
	)
	assert_eq(model.unit(3)["text"], "", "copying the Fairy does not restore its stolen text")
	assert_eq(model.unit(3)["keywords"], [])
	assert_eq(model.unit(3)["attack"], 50, "event-supplied stats remain authoritative")
	assert_eq(model.unit(1)["text"], "")
	assert_string_contains(str(model.unit(2)["text"]), "Cleave")


func _away_screen(window: Vector2, hand_count: int = 1) -> RecruitScreen:
	CardView.window_override = window
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(window.x * 1080.0 / window.y), 1080)
	add_child_autofree(viewport)
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	state["away"] = [
		{
			"name": "One Swallow",
			"nest": 2,
			"turns_left": 1,
			"attack": 78,
			"health": 94,
			"home_attack": 156,
			"home_health": 188,
			"pass3_content": true,
		},
		{
			"name": "Mrs Jay",
			"nest": -1,
			"turns_left": 2,
			"attack": 7,
			"health": 10,
			"home_attack": 14,
			"home_health": 20,
			"pass3_content": true,
		},
	]
	var hand: Array = []
	var card: Dictionary = UnitViews.from_def(UnitLibrary.load_dir().get_unit("chiffchaff"))
	for index: int in hand_count:
		var copy: Dictionary = card.duplicate(true)
		copy["iid"] = 1000 + index
		hand.append(copy)
	state["hand"] = hand
	state["hand_items"] = []
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


func test_away_tray_shows_now_and_landing_without_covering_recruit_actions() -> void:
	for window: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		var screen: RecruitScreen = _away_screen(window)
		await wait_process_frames(3)
		var tray: AwayTray = screen.get("_away_tray")
		var notes: RichTextLabel = tray.get("_notes")
		assert_true(tray.is_visible_in_tree())
		assert_string_contains(notes.text, "Now → landing")
		assert_string_contains(notes.text, "One Swallow · home in 1 turn\n78/94 → 156/188 · F3")
		assert_string_contains(notes.text, "Mrs Jay · home in 2 turns\n7/10 → 14/20")
		assert_gte(notes.get_theme_font_size("normal_font_size"), UiTheme.MIN_FONT)
		var hand_zone: Control = screen.get("_hand_zone")
		assert_false(tray.get_global_rect().intersects(hand_zone.get_global_rect()))
		for key: String in [
			"_gold", "_tier_button", "_refresh_button", "_freeze_button", "_end_button"
		]:
			var action: Control = screen.get(key)
			assert_true(action.is_visible_in_tree(), key + " stays usable")
			assert_false(tray.get_global_rect().intersects(action.get_global_rect()), key)
		screen._on_tapped("board", 0)
		await wait_process_frames(2)
		assert_true(tray.is_visible_in_tree(), "unit reader does not replace the away tray")
		screen._on_tapped("table", -1)
		await wait_process_frames(2)
		assert_true(tray.is_visible_in_tree(), "clearing selection restores normal recruiting")
		assert_eq(LayoutCheck.problems(screen, "away forecast"), PackedStringArray())


func test_many_away_birds_scroll_with_a_full_hand_and_clear_when_they_land() -> void:
	var screen: RecruitScreen = _away_screen(Vector2(1688, 780), 7)
	var state: Dictionary = screen.port.get_state()
	var away: Array = state["away"]
	for index: int in 10:
		(
			away
			. append(
				{
					"name": "Long travelling Mother Goose %d" % index,
					"nest": -1,
					"turns_left": 2,
					"attack": 100000,
					"health": 200000,
					"home_attack": 200000,
					"home_health": 400000,
				}
			)
		)
	state["doorstep"] = [{"name": "Old Tern"}]
	screen.render()
	await wait_process_frames(3)
	var tray: AwayTray = screen.get("_away_tray")
	var notes: RichTextLabel = tray.get("_notes")
	assert_string_contains(notes.text, "Long travelling Mother Goose 9")
	assert_string_contains(notes.text, "100k/200k → 200k/400k")
	assert_string_contains(notes.text, "Old Tern: on the doorstep")
	var scroll: VScrollBar = notes.get_v_scroll_bar()
	assert_gt(scroll.max_value, scroll.page, "all Birds remain available through scrolling")
	var hand: GridContainer = screen.get("_hand_cards")
	assert_eq(hand.get_child_count(), 4, "three hand tiles plus the full-hand picker")
	assert_true(hand.get_child(3) is Button)
	assert_eq(LayoutCheck.problems(screen, "full hand and sky"), PackedStringArray())
	state["away"] = []
	state["doorstep"] = []
	screen.render()
	await wait_process_frames(2)
	assert_false(tray.visible, "an empty sky returns the space to the hand")
	assert_eq(hand.get_child_count(), 6)


func test_crowded_pc_shop_keeps_long_names_on_whole_word_lines() -> void:
	var screen: RecruitScreen = _away_screen(Vector2(1920, 1080))
	var state: Dictionary = screen.port.get_state()
	var library: UnitLibrary = UnitLibrary.load_dir()
	var shop: Array = []
	for id: String in [
		"madame_ermeline", "his_highness", "grey_agnes", "madame_ermeline", "jenny_greenteeth"
	]:
		shop.append(UnitViews.from_def(library.get_unit(id)))
	state["shop"] = shop
	state["shop_spells"] = [
		{"name": "Rainy Day", "kind": "spell", "text": "", "cost": 1},
		{"name": "A Leg Up", "kind": "spell", "text": "", "cost": 1},
	]
	screen.render()
	await wait_process_frames(3)
	var offers: GridContainer = screen.get("_shop_cards")
	for index: int in [1, 4]:
		var card: CardView = offers.get_child(index)
		var label: Label = card.get("_name_label")
		assert_eq(label.text, shop[index]["name"])
		assert_lte(
			label.get_line_count(), 3 if index == 1 else 2, "no split word or comma-only line"
		)
		assert_gte(label.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
	assert_eq(LayoutCheck.problems(screen, "crowded PC shop"), PackedStringArray())


func test_end_turn_subtitle_clears_the_leaf_rim_with_and_without_phone_reader() -> void:
	var screen: RecruitScreen = _away_screen(Vector2(1688, 780))
	for reader: bool in [false, true]:
		if reader:
			screen._on_tapped("board", 0)
		await wait_process_frames(3)
		var button: Control = screen.get("_end_button")
		var subtitle: Label = button.get("_sub")
		var title: Label = button.get("_label")
		assert_true(subtitle.is_visible_in_tree())
		assert_gte(subtitle.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
		assert_gte(title.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
		assert_lte(
			subtitle.get_global_rect().end.y,
			button.get_global_rect().end.y - button.size.y * 0.04,
			"the second line stays clear of the lower leaf rim"
		)
