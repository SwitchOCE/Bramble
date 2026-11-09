extends GutTest
## Pass 3 Bog reuses tribe chips, frog counters and the selected card's scout reader.
@warning_ignore_start("unsafe_call_argument")

const TribeBonuses := preload("res://src/ui/widgets/tribe_bonuses.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const CombatLanesView := preload("res://src/ui/screens/combat_lanes_view.gd")
const FightLog := preload("res://tools/play/play_fight_log.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _frog(uid: int = 1) -> Dictionary:
	return {
		"uid": uid,
		"def_id": "his_highness",
		"name": "His Highness",
		"attack": 3,
		"health": 5,
		"text": "Mire. Soak.",
		"keywords": ["Mire", "Soak"],
		"tribes": ["Bog folk"],
		"bog_kiss_period": 3,
		"counters": {"kisses": 4}
	}


func test_toll_occupies_existing_bog_icon_and_keeps_numeric_label_readable() -> void:
	for window: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		CardView.window_override = window
		var chips: TribeBonuses = TribeBonuses.new()
		chips.theme = UiTheme.get_theme()
		chips.size = Vector2(900, 40)
		add_child_autofree(chips)
		chips.show_bonuses(["Bog folk"], {})
		chips.show_engine({"lobby_tribes": ["Bog folk"], "bog_toll": 1234567})
		assert_eq(chips.chips.size(), 1, "the existing tribe portrait carries Toll")
		var chip: Control = chips.chips[0]
		var label: Label = chip.get_node("Bonus") as Label
		assert_true(label.text.ends_with("m"))
		assert_gte(label.get_theme_font_size("font_size"), 31)
		assert_true(chip.get_rect().encloses(Rect2(label.position, label.size)))
		assert_eq(chips.bonuses, {}, "Toll does not become a fake tribe stat bonus")
		assert_string_contains(chip.tooltip_text, "1,234,567")


func test_all_frogs_show_the_shared_counter_and_configured_period() -> void:
	for uid: int in [1, 2]:
		var card: CardView = CardView.new()
		add_child_autofree(card)
		var view: Dictionary = _frog(uid)
		view["bog_kiss_period"] = 5
		card.show_unit(view, CardView.Mode.BOARD)
		card.set_card_width(210)
		assert_string_contains(card.chip_shown, "Kiss 4/5")
		assert_string_contains(CardDetail.full_text_bbcode(view), "Shared kisses: 4 (4/5)")
		CombatLanesView.sync_bog_state(card, {"kisses": 5, "bog_kiss_period": 5})
		assert_string_contains(card.chip_shown, "Kiss 0/5")


func test_selected_scout_reader_uses_supplied_per_bite_gain_without_own_power_math() -> void:
	for window: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		CardView.window_override = window
		var viewport: SubViewport = SubViewport.new()
		viewport.size = Vector2i(2337, 1080) if window.x == 1688 else Vector2i(1920, 1080)
		add_child_autofree(viewport)
		var port: FixturePort = FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		var state: Dictionary = port.get_state()
		var view: Dictionary = _frog()
		view["attack"] = 999999
		view["bog_soak_keep"] = 1.0
		view["soak_preview"] = [
			{"slot": 0, "name": "Boar", "attack": 5, "drink": 2},
			{"slot": 1, "name": "Empty-Handed Vole", "attack": 1, "drink": 0}
		]
		state["board"] = [view, null, null, null, null, null, null]
		state["lobby_tribes"] = ["Bog folk"]
		state["bog_toll"] = 7
		state["next_opponent_last_board"] = [
			{"def_id": "field_vole", "name": "Boar", "attack": 5, "health": 6}
		]
		var screen: RecruitScreen = RecruitScreen.new()
		viewport.add_child(screen)
		screen.setup(port)
		screen.call("_on_tapped", "board", 0)
		var detail: CardDetail = screen.get("_detail")
		assert_false(CardDetail.full_text_bbcode(detail.shown).contains("per bite"))
		screen.toggle_scout()
		await wait_process_frames(2)
		var text: String = CardDetail.full_text_bbcode(detail.shown)
		assert_string_contains(text, "Across Boar: +2/+2 per bite")
		assert_string_contains(text, "Across Empty-Handed Vole: +0/+0 per bite")
		assert_eq(LayoutCheck.problems(detail, "Bog scout reader"), PackedStringArray())
		screen.toggle_scout()
		assert_false(CardDetail.full_text_bbcode(detail.shown).contains("per bite"))


func test_toll_and_kiss_events_replay_and_both_logs_use_human_state() -> void:
	var model: CombatModel = CombatModel.new()
	model.apply({"type": "combat_start", "boards": [[_frog()], []]})
	var event: Dictionary = {"type": "bog_toll", "side": 0, "total": 7, "amount": 2, "source": 911}
	var log_text: CombatLog = CombatLog.new()
	log_text.side_names = PackedStringArray(["You", "Opponent"])
	for line: String in [log_text.describe(event, model, false), FightLog.event_line(event, {}, 0)]:
		assert_string_contains(line, "Your Bog Toll: 7")
		assert_false(line.contains("911"))
	model.apply(event)
	assert_eq(model.bog_toll[0], 7)
	assert_eq(CombatLanesView.bog_summary(model, 0), "\nBog Toll: 7")
	model.apply({"type": "kiss", "target": 1, "side": 0, "count": 5, "period": 5})
	assert_eq(model.unit(1)["kisses"], 5)
	assert_eq(model.unit(1)["bog_kiss_period"], 5)


func test_new_bog_actions_use_named_human_lines_in_both_logs() -> void:
	var source: Dictionary = _frog(71)
	source["name"] = "Jenny Greenteeth"
	var target: Dictionary = _frog(89)
	target["name"] = "Boar"
	var model: CombatModel = CombatModel.new()
	model.apply({"type": "combat_start", "boards": [[source], [target]]})
	var logger: CombatLog = CombatLog.new()
	for kind: String in ["bog_pull", "bog_bind", "bog_hit_back"]:
		var event: Dictionary = {"type": kind, "source": 71, "target": 89, "ability": "lantern"}
		for line: String in [
			logger.describe(event, model, false),
			FightLog.event_line(event, {71: "Jenny Greenteeth", 89: "Boar"}, 0)
		]:
			assert_string_contains(line, "Jenny Greenteeth")
			assert_false(line.contains("bog_"))
			assert_false(line.contains("71"))
			assert_false(line.contains("89"))
			assert_false(line.contains("lantern"))
			if kind == "bog_bind":
				assert_string_contains(line, "emerge")
			else:
				assert_string_contains(line, "Boar")
