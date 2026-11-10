extends GutTest

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const LobbyStrip := preload("res://src/ui/widgets/lobby_strip.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const Guide := preload("res://src/ui/screens/how_to_play.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_finished_fight_keeps_details_in_log_and_returns_at_both_sizes() -> void:
	for phone: bool in [false, true]:
		CardView.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(2337, 1080) if phone else Vector2i(1920, 1080)
		add_child_autofree(viewport)
		var screen := CombatScreen.new()
		viewport.add_child(screen)
		screen.manual_playback = true
		var completed: Array[bool] = []
		screen.finished.connect(func() -> void: completed.append(true))
		screen.setup(
			{
				"events":
				[{"type": "combat_end", "winner": 1, "damage": 13, "last_stand_sides": [0]}]
			},
			PackedStringArray(["You", "Hob Mumblecrust"]),
			0,
			"Round 8"
		)
		screen.skip_to_end()
		assert_true(screen.model.finished)
		assert_false(screen._log.visible, "the log is off the fight screen")
		assert_string_contains(screen._log.all_text(), "Last Stand: You left on 1 Health.")
		screen.open_log()
		await get_tree().process_frame
		var page: Control = screen.get_children().back()
		assert_true(page.visible, "Log opens a separate page")
		assert_eq(page.size, screen.size, "the log uses the full page")
		assert_eq(LayoutCheck.problems(page, "fight log", false), PackedStringArray())
		screen.advance_playback(0.11)
		assert_eq(completed.size(), 1, "the fight returns without a Continue button")
		screen.advance_playback(1.0)
		assert_eq(completed.size(), 1, "return emits once")


## The guide teaches the charge; ending exceptions stay in linked reminders and the log.
func test_guide_teaches_hero_damage_and_leaves_engine_rulings_to_the_log() -> void:
	var words: String = ""
	for page: Dictionary in Guide.PAGES:
		words += str(page["text"])
	assert_string_contains(words, "40 Health")
	assert_string_contains(words, "base damage, plus 1 per")
	assert_string_contains(words, "enemy starting survivor")
	for ruling: String in ["Last Blow", "toll", "2+ Health", "ready/used/locked"]:
		assert_false(words.contains(ruling), ruling)


func test_combat_log_names_saved_heroes_in_wins_and_ties() -> void:
	var combat_log := CombatLog.new()
	combat_log.side_names = PackedStringArray(["You", "Hob"])
	for winner: int in [1, -1]:
		var event: Dictionary = {
			"type": "combat_end", "winner": winner, "damage": 6, "last_stand_sides": [0, 1]
		}
		var line: String = combat_log.describe(event, CombatModel.new())
		assert_string_contains(line, "Last Stand: You left on 1 Health.")
		assert_string_contains(line, "Last Stand: Hob left on 1 Health.")
		assert_string_contains(line, "Tie." if winner < 0 else "Winner: Hob")


func test_result_arithmetic_mentions_cap_only_when_it_exists() -> void:
	var rules: Dictionary = {"damage_base": 6, "round_toll": 2, "damage_uncapped": 8}
	for cap: int in [0, 12]:
		rules["damage_cap"] = cap
		var note: String = CombatLog.rules_note(rules, PackedStringArray(["You", "Hob"]))
		assert_eq(note.contains("before cap"), cap > 0)
		assert_string_contains(note, "6 + 2 toll = 8")


func test_wasp_health_loss_and_death_use_card_words_and_are_not_named_nightshade() -> void:
	var combat_log := CombatLog.new()
	var model := CombatModel.new()
	var line: String = combat_log.describe(
		{"type": "health_loss", "target": 1, "cause": "parasite", "amount": 2, "health_after": 0},
		model
	)
	assert_string_contains(line, "loses 2 Health to Ichneumon Wasp's delayed kill: 0 Health left")
	assert_false(line.contains("Nightshade"))
	assert_string_contains(
		combat_log.describe({"type": "death", "uid": 1}, model),
		"dies to Ichneumon Wasp's delayed kill"
	)
	assert_string_contains(
		combat_log.describe(
			{"type": "health_loss", "target": 1, "amount": 2, "health_after": 2}, model
		),
		"Nightshade"
	)


func test_lobby_last_stand_states_fit_without_shortening_names() -> void:
	var names: PackedStringArray = [
		"You",
		"Hob Mumblecrust",
		"Dame Hoolet",
		"Pipkin",
		"Little King Wren",
		"Old Mother Mousewife",
		"Jill Down-the-Tree",
		"Brother Bracken"
	]
	for phone: bool in [false, true]:
		for alive: int in [8, 5, 4, 3]:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(2337 if phone else 1920, 1080)
			add_child_autofree(viewport)
			var strip := LobbyStrip.new()
			strip.position = Vector2(20, 17)
			strip.size = Vector2(2283 if phone else 1866, LobbyStrip.HEIGHT)
			viewport.add_child(strip)
			var standings: Array = []
			for index: int in 8:
				standings.append(
					{
						"player_id": index,
						"name": names[index],
						"health": 40,
						"alive": index < alive,
						"last_stand_enabled": true,
						"last_stand_used": index == 1,
						"last_stand_active": alive <= 4
					}
				)
			strip.show_standings(standings, 1)
			await get_tree().process_frame
			await get_tree().process_frame
			assert_eq(LayoutCheck.problems(strip, "lobby marker"), PackedStringArray())
			for index: int in strip.plaques.size():
				var plaque: LobbyPlaque = strip.plaques[index]
				assert_gte(
					plaque.size.x + 0.1,
					plaque.wanted_width(),
					"name and status keep their full width"
				)
				var first: Label = plaque.get("_name")
				var rest: Label = plaque.get("_surname")
				assert_eq(
					(first.text.trim_prefix("Next: ") + " " + rest.text).strip_edges(),
					names[index],
					"full hero name"
				)
				var expected: bool = alive <= 4 and index < alive
				assert_eq(plaque.has_node("LastStand"), expected)
				if expected:
					var marker: Label = plaque.get_node("LastStand")
					assert_eq(marker.text, "Last Stand: " + ("used" if index == 1 else "ready"))
					assert_gte(
						marker.get_theme_font_size("font_size"),
						UiTheme.MIN_FONT if phone else LobbyStrip.DESKTOP_NAME
					)
					assert_lte(marker.get_minimum_size().x, marker.size.x)
				assert_lte(plaque.position.x + plaque.size.x, strip.size.x + 0.1)
			assert_gte((strip.plaques[1] as LobbyPlaque).tap.size.y, 140.0)


func test_disabled_out_and_ghost_plaques_do_not_offer_last_stand() -> void:
	for standing: Dictionary in [
		{"last_stand_enabled": false, "last_stand_active": true},
		{"last_stand_enabled": true, "last_stand_active": true, "alive": false},
	]:
		var plaque := LobbyPlaque.new(standing, false)
		add_child_autofree(plaque)
		assert_false(plaque.has_node("LastStand"))
	var ghost := LobbyPlaque.new(
		{"last_stand_enabled": true, "last_stand_active": true}, true, true
	)
	add_child_autofree(ghost)
	assert_false(ghost.has_node("LastStand"))


func test_hero_damage_guide_fits_above_page_number_at_both_sizes() -> void:
	for width: int in [1920, 2337]:
		var guide := Guide.new()
		guide.theme = UiTheme.get_theme()
		guide.set_anchors_preset(Control.PRESET_TOP_LEFT)
		guide.size = Vector2(width, 1080)
		add_child_autofree(guide)
		guide.page = 9
		guide._layout()
		guide._show_page()
		await get_tree().process_frame
		guide._layout()
		await get_tree().process_frame
		var body: Label = guide.get("_text")
		var count: Label = guide.get("_count")
		assert_lte(body.get_minimum_size().y, body.size.y)
		assert_lte(body.position.y + body.size.y, count.position.y)
		assert_gte(body.get_theme_font_size("font_size"), 38)


func test_late_status_band_clears_tools_and_all_tribe_bonuses() -> void:
	for phone: bool in [false, true]:
		CardView.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(2337 if phone else 1920, 1080)
		add_child_autofree(viewport)
		var port := FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		var state: Dictionary = port.get_state()
		var standings: Array = state["standings"]
		for index: int in standings.size():
			var standing: Dictionary = standings[index]
			standing["alive"] = index < 4
			standing["last_stand_enabled"] = true
			standing["last_stand_active"] = true
		state["lobby_tribes"] = ["Hedgerow folk", "Fairies", "Oozes", "Birds", "Hunters"]
		state["tribe_bonuses"] = {
			"Hedgerow folk": 3, "Fairies": 3, "Oozes": 3, "Birds": 3, "Hunters": 3
		}
		var screen := RecruitScreen.new()
		viewport.add_child(screen)
		screen.setup(port)
		for reading: bool in [false, true]:
			if reading:
				screen.call("_on_tapped", "board", 0)
			await get_tree().process_frame
			await get_tree().process_frame
			var lobby: LobbyStrip = screen.get("_lobby")
			var tools: Control = screen.get("_menu_token")
			var bonuses: Control = screen.get("_tribes")
			var board: Control = screen.get("_board")
			assert_gt(bonuses.z_index, board.z_index, "bonuses draw above the board header")
			for chip: Control in bonuses.get("chips"):
				assert_true(
					bonuses.get_global_rect().encloses(chip.get_global_rect()),
					"all five bonuses stay inside the header"
				)
			for plaque: Control in lobby.plaques:
				if plaque.has_node("LastStand"):
					var marker: Label = plaque.get_node("LastStand")
					assert_false(
						marker.get_global_rect().intersects(tools.get_global_rect()),
						"settings cannot obscure Last Stand"
					)
					assert_false(
						marker.get_global_rect().intersects(bonuses.get_global_rect()),
						"tribe bonuses cannot obscure Last Stand"
					)
			assert_eq(LayoutCheck.problems(screen, "late lobby with bonuses"), PackedStringArray())
