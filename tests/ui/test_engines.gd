extends GutTest

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const LobbyStrip := preload("res://src/ui/widgets/lobby_strip.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Guide := preload("res://src/ui/screens/how_to_play.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_engine_result_lines_fit_desktop_and_phone_without_smaller_type() -> void:
	for phone: bool in [false, true]:
		CardView.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
		var screen := CombatScreen.new()
		add_child_autofree(screen)
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.size = Vector2(2337, 1080) if phone else Vector2(1920, 1080)
		screen._layout()
		screen.model.winner = 1
		screen.model.damage = 18
		screen.model.damage_uncapped = 18
		screen._log_text.side_names = PackedStringArray(["You", "Hob Mumblecrust"])
		screen.model.result_rules = {
			"winner": 1,
			"last_blow": true,
			"last_blow_kind": "effect",
			"damage_base": 6,
			"round_toll": 12,
			"damage_uncapped": 18,
			"alive": 4,
			"damage_cap": 0,
			"last_stand_sides": [0]
		}
		screen._show_result()
		await get_tree().process_frame
		var text: Label = screen._result_text
		for words: String in [
			"Last Blow", "6 + 12 toll = 18", "Cap lifted: 4 left", "Last Stand", "1 Health"
		]:
			assert_string_contains(text.text, words)
		assert_false(text.text.contains("before cap"))
		assert_lte(text.get_minimum_size().y, text.size.y, "all result lines fit")
		assert_gte(text.get_theme_font_size("font_size"), 36)


func test_guide_names_every_adopted_engine() -> void:
	var words: String = ""
	for page: Dictionary in Guide.PAGES:
		words += str(page["text"])
	for rule: String in [
		"Last Blow",
		"Start of Combat",
		"four",
		"Last Stand",
		"2+ Health",
		"four or fewer living heroes",
		"ready/used/locked",
		"Ghosts",
		"tier 3, Harvest Supper"
	]:
		assert_string_contains(words, rule)


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


func test_parasite_health_loss_and_death_are_not_named_nightshade() -> void:
	var combat_log := CombatLog.new()
	var model := CombatModel.new()
	var line: String = combat_log.describe(
		{"type": "health_loss", "target": 1, "cause": "parasite", "amount": 2, "health_after": 0},
		model
	)
	assert_string_contains(line, "loses 2 Health to a parasite: 0 Health left")
	assert_false(line.contains("Nightshade"))
	assert_string_contains(
		combat_log.describe({"type": "death", "uid": 1}, model), "dies to a parasite"
	)
	assert_string_contains(
		combat_log.describe(
			{"type": "health_loss", "target": 1, "amount": 2, "health_after": 2}, model
		),
		"Nightshade"
	)


func test_lobby_last_stand_states_fit_all_eight_plaques_at_existing_type_sizes() -> void:
	for phone: bool in [false, true]:
		var strip := LobbyStrip.new()
		strip.size = Vector2(2283 if phone else 1866, LobbyStrip.HEIGHT)
		add_child_autofree(strip)
		var standings: Array = []
		for index: int in 8:
			standings.append(
				{
					"player_id": index,
					"name": "Hob Mumblecrust",
					"health": 40,
					"alive": true,
					"last_stand_enabled": true,
					"last_stand_used": index == 1,
					"last_stand_active": index == 0
				}
			)
		strip.show_standings(standings, 1)
		await get_tree().process_frame
		for index: int in strip.plaques.size():
			var plaque: LobbyPlaque = strip.plaques[index]
			var marker: Label = plaque.get_node("LastStand")
			assert_eq(
				marker.text,
				"Last Stand: " + ("ready" if index == 0 else "used" if index == 1 else "locked")
			)
			assert_gte(
				marker.get_theme_font_size("font_size"),
				UiTheme.MIN_FONT if phone else LobbyStrip.DESKTOP_NAME
			)
			assert_lte(marker.get_minimum_size().x, marker.size.x, "full status fits its plaque")
			assert_lte(marker.position.y + marker.size.y, plaque.size.y)
			assert_lte(plaque.position.x + plaque.size.x, strip.size.x + 0.1)
		assert_gte((strip.plaques[1] as LobbyPlaque).tap.size.y, 140.0, "scout tap stays generous")


func test_disabled_out_and_ghost_plaques_do_not_offer_last_stand() -> void:
	for standing: Dictionary in [
		{"last_stand_enabled": false},
		{"last_stand_enabled": true, "alive": false},
	]:
		var plaque := LobbyPlaque.new(standing, false)
		add_child_autofree(plaque)
		assert_false(plaque.has_node("LastStand"))
	var ghost := LobbyPlaque.new({"last_stand_enabled": true}, true, true)
	add_child_autofree(ghost)
	assert_false(ghost.has_node("LastStand"))


func test_last_stand_guide_fits_above_page_number_at_both_sizes() -> void:
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
