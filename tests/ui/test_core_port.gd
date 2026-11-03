extends GutTest
## The UI driven by the real rules core through CorePort: several rounds of buy, play and end
## turn, every fight replayed by the combat model, a bot-only game to the end, sandbox fights on
## real boards, the unbuilt badge and the dev panel.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const DevPanel := preload("res://src/ui/widgets/dev_panel.gd")
const Data := preload("res://src/ui/view_data.gd")

const ROUNDS: int = 6


func _port(config: GameConfig = null) -> CorePort:
	var port: CorePort = CorePort.new()
	port.setup(config)
	return port


func _first_empty_slot(state: Dictionary) -> int:
	var board: Array = Data.a(state, "board")
	for slot: int in board.size():
		if board[slot] == null:
			return slot
	return -1


func test_several_rounds_of_buy_play_end_turn() -> void:
	var port: CorePort = _port()
	assert_eq(port.new_game(11), "")
	for i: int in ROUNDS:
		var state: Dictionary = port.get_state()
		assert_eq(Data.i(state, "round"), i + 1, "round %d" % (i + 1))
		if Data.i(state, "gold") >= 3 and not Data.a(state, "shop").is_empty():
			assert_eq(port.buy(0), "", "buy in round %d" % (i + 1))
			var slot: int = _first_empty_slot(port.get_state())
			if slot >= 0:
				var hand: Array = Data.a(port.get_state(), "hand")
				assert_eq(port.play(hand.size() - 1, slot), "", "play in round %d" % (i + 1))
		assert_eq(port.end_turn(), "", "end turn %d" % (i + 1))
		var combat: Dictionary = port.get_last_combat()
		var events: Array = Data.a(combat, "events")
		assert_gt(events.size(), 1, "round %d has a fight" % (i + 1))
		var model: CombatModel = CombatModel.new()
		for entry: Variant in events:
			var event: Dictionary = entry
			model.apply(event)
		assert_true(model.finished, "round %d fight replays to combat_end" % (i + 1))
		if port.get_state().get("placement") != null:
			break


func test_refused_actions_come_back_as_reasons() -> void:
	var port: CorePort = _port()
	port.new_game(3)
	assert_ne(port.sell(0), "", "nothing to sell on an empty board")
	assert_ne(port.play(0, 0), "", "nothing in hand to play")


func test_app_flow_on_the_core() -> void:
	var app: App = App.new()
	add_child_autofree(app)
	app.setup(_port())
	app.start_game()
	assert_true(app.current is RecruitScreen)
	(app.current as RecruitScreen).call("_on_end_turn")
	assert_true(app.current is CombatScreen, "end turn shows the core's fight")
	var combat: CombatScreen = app.current as CombatScreen
	combat.skip_to_end()
	assert_true(combat.is_showing_result())
	combat.finished.emit()
	assert_true(app.current is RecruitScreen, "back to recruit for round 2")
	var round_two: int = Data.i(app.port.get_state(), "round")
	assert_eq(round_two, 2)


func test_bot_only_game_reaches_game_over_screen() -> void:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("human_bot", "balanced")
	var app: App = App.new()
	add_child_autofree(app)
	app.setup(_port(config))
	app.start_game()
	var turns: int = 0
	while app.current is RecruitScreen and turns < 60:
		(app.current as RecruitScreen).call("_on_end_turn")
		if app.current is CombatScreen:
			(app.current as CombatScreen).finished.emit()
		turns += 1
	assert_true(app.current is GameOverScreen, "game over once the human is out (%d turns)" % turns)
	assert_true(app.human_is_out())


func test_sandbox_fights_real_boards() -> void:
	var port: CorePort = _port()
	var own: Array = [
		null, {"def_id": "hoglet_mother", "golden": false}, null, null, null, null, null
	]
	var enemy: Array = [
		null, {"def_id": "stoat_captain", "golden": true}, null, null, null, null, null
	]
	var result: Dictionary = port.sandbox_fight([own, enemy], 5)
	assert_false(result.has("error"), "fight runs: %s" % Data.s(result, "error"))
	var events: Array = Data.a(result, "events")
	var first: Dictionary = Data.entry(events, 0)
	assert_eq(Data.s(first, "type"), "combat_start")
	var bad: Array = [{"def_id": "no_such_unit"}, null, null, null, null, null, null]
	assert_true(port.sandbox_fight([bad, enemy], 5).has("error"), "unknown unit refused")


func test_unbuilt_units_get_a_badge() -> void:
	var port: CorePort = _port()
	CardView.set_unbuilt(port.unbuilt_units())
	for id: String in port.unbuilt_units():
		assert_true(CardView.is_unbuilt({"def_id": id}), "%s flagged" % id)
	assert_false(CardView.is_unbuilt({"def_id": "dewdrop_ooze"}), "plain units are built")
	CardView.set_unbuilt(PackedStringArray())


func test_dev_panel_shows_the_reason_strings() -> void:
	var port: CorePort = _port()
	port.new_game(9)
	var panel: DevPanel = DevPanel.new()
	add_child_autofree(panel)
	panel.setup(port)
	panel.call("_on_add_gold")
	var result: Label = panel.get("_result")
	assert_string_starts_with(result.text, "Add gold: ")
	var seed_label: Label = panel.get("_seed_label")
	assert_eq(seed_label.text, "Seed: 9")
