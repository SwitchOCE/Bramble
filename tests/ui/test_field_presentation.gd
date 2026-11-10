extends GutTest
## Strong-field identities and late-round scouting remain readable in both canvas shapes.

const App := preload("res://src/ui/app.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _viewport(phone: bool) -> SubViewport:
	CardView.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080) if phone else Vector2i(1920, 1080)
	add_child_autofree(viewport)
	return viewport


func test_field_ghost_keeps_its_name_in_combat() -> void:
	var start: Dictionary = {"player_ids": [0, -1]}
	var state: Dictionary = {"standings": [{"player_id": 0, "is_human": true}]}
	assert_eq(
		App.side_names(start, state, "Field ghost"), PackedStringArray(["You", "Field ghost"])
	)
	assert_eq(App.side_names(start, state, "Ghost of Hob")[1], "Ghost of Hob")
	assert_eq(App.side_names(start, state)[1], "A ghost")


func test_watch_again_keeps_the_ghost_fought_before_the_next_pairing() -> void:
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	port.use_combat()
	var combat: Dictionary = port.get_last_combat()
	var events: Array = combat["events"]
	var start: Dictionary = events[0]
	start["player_ids"] = [0, -1]
	var app := App.new()
	add_child_autofree(app)
	app.setup(port)
	app.show_recruit()
	var recruit: RecruitScreen = app.current as RecruitScreen
	recruit.state["next_opponent_id"] = -1
	recruit.state["standings"] = [
		{"player_id": 0, "is_human": true},
		{"player_id": 4, "name": "Hob", "alive": false, "placement": 8},
	]
	app.show_game_combat()
	var first: CombatScreen = app.current as CombatScreen
	var first_log: CombatLog = first.get("_log_text")
	assert_eq(first_log.side_names[1], "Ghost of Hob")
	app.show_recruit()
	app.show_game_combat()
	var replay: CombatScreen = app.current as CombatScreen
	var replay_log: CombatLog = replay.get("_log_text")
	assert_eq(replay_log.side_names[1], "Ghost of Hob", "Watch again retains the previous ghost")


func test_combat_plaque_keeps_rival_identity_in_its_reader_at_both_sizes() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var screen := CombatScreen.new()
		viewport.add_child(screen)
		screen.setup(
			{"events": []},
			PackedStringArray(["You", "Rival 4 · Brother Bracken"]),
			0,
			"Turn 12",
			20
		)
		await get_tree().process_frame
		screen._show_hero(1)
		var reader: Control = screen.get("_reader")
		assert_true(reader.visible)
		var shown: Dictionary = reader.get("shown")
		assert_eq(str(shown.get("name", "")), "Rival 4 · Brother Bracken")
		var plaques: Array = screen.get("_plaques")
		var rival: Button = plaques[1]
		assert_eq(rival.text, "", "the plaque has no resting name")


func test_scout_heading_clears_last_stand_and_the_shop_at_both_sizes() -> void:
	for phone: bool in [false, true]:
		var viewport: SubViewport = _viewport(phone)
		var port := FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		var state: Dictionary = port.get_state()
		for standing: Dictionary in state["standings"]:
			standing["last_stand_enabled"] = true
			standing["last_stand_active"] = true
		var screen := RecruitScreen.new()
		viewport.add_child(screen)
		screen.setup(port)
		screen.toggle_scout()
		await get_tree().process_frame
		await get_tree().process_frame
		var scout: Control = screen.get("_scout")
		var heading: Label = scout.get("_title")
		var lobby: Control = screen.get("_lobby")
		for plaque: Control in lobby.get("plaques"):
			if plaque.has_node("LastStand"):
				var status: Control = plaque.get_node("LastStand")
				assert_lte(status.get_global_rect().end.y, heading.global_position.y)
		var shop: GridContainer = screen.get("_shop_cards")
		var first_offer: Control = shop.get_child(0)
		assert_lte(heading.get_global_rect().end.y + 8.0, first_offer.global_position.y)
