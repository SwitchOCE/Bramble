extends GutTest
## Strong-field identities and late-round scouting remain readable in both canvas shapes.

const App := preload("res://src/ui/app.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
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


func test_combat_plaque_keeps_the_rival_number_at_both_sizes() -> void:
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
		var label: Label = screen.get("_fight_name")
		assert_true(label.text.begins_with("Rival 4"), label.text)
		assert_false(label.text.ends_with("·"), "a trimmed hero leaves no dangling separator")
		var font: Font = label.get_theme_font("font")
		var text_size: Vector2 = font.get_string_size(
			label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")
		)
		assert_lte(text_size.x, label.size.x, "the seat number fits without clipping")


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
