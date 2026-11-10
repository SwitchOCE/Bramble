extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardRulings := preload("res://src/ui/card_rulings.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const Settings := preload("res://src/ui/settings.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const SettingsScreen := preload("res://src/ui/screens/settings_screen.gd")
const KIT := preload("res://tests/core/recruit_kit.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO
	Settings.reset()


func test_pass_preview_crosses_gaps_skips_source_and_handles_sale() -> void:
	var crumb: Dictionary = {"text": "When played or sold: Pass +1/+1."}
	var board: Array = [null, {"name": "Other"}, null, crumb, null, null, null]
	assert_eq(RecruitView.pass_end(board), 3)
	assert_eq(RecruitView.pass_preview(board, crumb, 3, 3), 1)
	assert_eq(RecruitView.pass_preview(board, crumb, 3, -1), 1)
	assert_eq(RecruitView.pass_preview(board, crumb, 3, 6), 1)
	assert_eq(RecruitView.pass_preview(board, crumb, 3, 1), 3, "swap leaves Other at F4")
	board[1] = null
	assert_eq(RecruitView.pass_preview(board, crumb, 3, 3), -1)
	assert_eq(RecruitView.geometry_note(crumb, 3, board), "")
	assert_false(RecruitView.geometry_note(crumb, 3, board).contains("Pass order"))


func test_pass_recipient_is_state_without_a_permanent_mark_or_selection_preview() -> void:
	var board := BoardView.new()
	board.configure("board", 180, true, true)
	add_child_autofree(board)
	var units: Array = [{"name": "First"}, null, null, null, null, null, {"name": "Last"}]
	board.set_marks(RecruitView.slot_marks({"board": units}))
	var marks: Control = board.get("_marks")
	var label: Label = marks.get("_pass_label")
	assert_false(label.visible)
	assert_eq(RecruitView.pass_end(units), 6)
	board.set_pass_landing(0)
	assert_false(label.visible, "selection cannot restore a standing Pass pointer")
	board.set_pass_landing(-2)
	assert_false(label.visible)


func test_pass_rules_remain_in_the_reader_without_geometry_instructions() -> void:
	var library: UnitLibrary = LegacyWave1.with_hedgerow(TestLibraries.current())
	for golden: bool in [false, true]:
		for id: String in ["dr_urchin", "mr_crumb", "mr_pym", "beadle_warrenby"]:
			var source := RecruitUnit.make(library.get_unit(id), 2, golden)
			assert_eq(RecruitView.geometry_note(source.view(), 0), "")
			assert_false(str(source.view()["text"]).is_empty(), id)


func test_golden_shy_cards_print_the_payment_once_and_keep_their_other_rulings() -> void:
	var library := TestLibraries.current()
	for id: String in ["hob_in_the_hearth", "lob_lie_by_the_fire", "silky"]:
		var unit := RecruitUnit.make(library.get_unit(id), 1, true)
		var face: String = unit.view()["text"]
		var rulings: String = CardRulings.for_view(unit.view())
		assert_eq((face + rulings).count("Shy pays 4 gold"), 1, id)
		if id == "lob_lie_by_the_fire":
			assert_string_contains(CardDetail.notes_bbcode(unit.view()), "each complete 2 turns")
			assert_false(CardDetail.notes_bbcode(unit.view()).contains("starts at +1/+1"))
		elif id == "silky":
			assert_string_contains(CardDetail.notes_bbcode(unit.view()), "once per departure")


func test_nest_display_uses_live_tom_tit_redwing_tribe_and_slot_stats() -> void:
	var kit := KIT.new()
	kit.setup(GameConfig.full_game(), true)
	kit.player.round_number = 6
	var bird := RecruitUnit.make(kit.library.get_unit("mrs_jay"), 99)
	bird.add_permanent(4, 6)
	kit.player.away.append({"unit": bird, "nest": 0, "due": 8})
	kit.player.tribe_bonuses["Birds"] = 1
	kit.put("tom_tit", 4)
	kit.rules.board_changed(kit.player)
	var effects: Array = [[{"attack": 1, "health": 2}], [], [], [], [], [], []]
	var marks: Array = RecruitView.slot_marks(
		{"away": HeldUnits.away_views(kit.player), "slot_effects": effects}
	)
	var mark: Dictionary = marks[0]
	assert_eq(mark["egg_attack"], 5, "half 8 Attack, then the slot Ring")
	assert_eq(mark["egg_health"], 12, "Tom Tit keeps full 10 Health, then the slot Ring")
	kit.put("redwing", 1)
	kit.rules.board_changed(kit.player)
	marks = RecruitView.slot_marks(
		{"away": HeldUnits.away_views(kit.player), "slot_effects": effects}
	)
	mark = marks[0]
	assert_eq(mark["egg_attack"], 9, "Redwing supplies full Attack without stacking Tit")
	assert_eq(mark["egg_health"], 12)
	var board := BoardView.new()
	board.configure("board", 180, true, true)
	add_child_autofree(board)
	board.set_marks(marks)
	var overlay: Control = board.get("_marks")
	var labels: Array = overlay.get("_nest_labels")
	var caption: Label = labels[0]
	assert_false(caption.visible, "homecoming countdown stays on the away token")
	var detail: Dictionary = RecruitHeld.egg_card(mark)
	assert_eq(detail["attack"], 9)
	assert_eq(detail["health"], 12)
	assert_string_contains(detail["text"], "2 turns")


func test_spoils_log_and_income_name_the_payment() -> void:
	var screen := CombatScreen.new()
	add_child_autofree(screen)
	screen.bottom_side = 0
	screen._play_event({"type": "early_spoils", "side": 0, "amount": 1}, false)
	screen._play_event({"type": "combat_end", "winner": 0, "damage": 1}, false)
	assert_string_contains(screen._log.all_text(), "+1 gold next turn (Spoils)")
	assert_false(screen._log.visible, "Spoils details stay in Log")
	assert_string_contains(
		RecruitView.income_note(
			{"next_turn_income": 4, "gold_next_turn": 1, "early_spoils_next_turn": 1}
		),
		"+1 Spoils queued"
	)
	assert_string_contains(
		RecruitView.income_note({"next_turn_income": 5, "early_spoils_income": 1}),
		"+1 Spoils received"
	)


func test_kin_controls_only_appear_for_the_enabled_game_and_fit_on_phone() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	var kin: Button = screen.get("_kin_button")
	assert_false(kin.visible)
	port.get_state()["ask_for_kin_enabled"] = true
	port.get_state()["can_ask_for_kin"] = false
	screen.render()
	assert_true(kin.visible)
	assert_true(kin.disabled)
	port.get_state()["can_ask_for_kin"] = true
	screen.render()
	assert_false(kin.disabled)
	await get_tree().process_frame
	for key: String in ["_tier_button", "_refresh_button", "_freeze_button", "_kin_button"]:
		var control: Control = screen.get(key)
		assert_gte(control.size.y, 122.0, key)
	screen.call("_on_tapped", "board", 0)
	await get_tree().process_frame
	assert_true(kin.visible, "the floating reader leaves the enabled Kin action available")
	for key: String in ["_tier_button", "_refresh_button", "_freeze_button"]:
		var control: Control = screen.get(key)
		assert_true(control.visible, key)
		assert_gte(control.size.y, 122.0, key)
	screen.call("_on_tapped", "table", -1)
	assert_true(kin.visible, "closing the reader restores the enabled Kin action")
	assert_false(kin.disabled)


func test_kin_setting_defaults_off_and_persists_explicit_choice() -> void:
	var old_path: String = Settings.path
	Settings.path = "user://pass2-settings-test.cfg"
	Settings.reset()
	assert_false(Settings.ask_for_kin)
	var screen := SettingsScreen.new()
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(1920, 1080)
	add_child_autofree(screen)
	screen.call("_on_kin", true)
	Settings.reset()
	assert_false(Settings.ask_for_kin)
	Settings.load_saved()
	assert_true(Settings.ask_for_kin)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.path = old_path
