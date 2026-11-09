extends GutTest
## Count the actual rendered controls: stats, names and action captions all spend the budget.

const GamePort := preload("res://src/ui/adapter/game_port.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const ScoutPanel := preload("res://src/ui/widgets/scout_panel.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")
const LaneStates := preload("res://tests/ui/lane_states.gd")
const Settings := preload("res://src/ui/settings.gd")

const LIMIT: int = 40


func after_each() -> void:
	CardView.window_override = Vector2.ZERO
	Settings.reduce_motion = false
	Settings.fight_speed = 1.0


func _screen(pixels: Vector2i, port: GamePort) -> RecruitScreen:
	CardView.window_override = Vector2(pixels)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(1080.0 * pixels.x / pixels.y), 1080)
	add_child_autofree(viewport)
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


func _assert_budget(screen: RecruitScreen, scenario: String) -> void:
	var labels: Array[Dictionary] = Capture.text_nodes(screen)
	print("declutter recruit label budget: %s = %d/%d" % [scenario, labels.size(), LIMIT])
	assert_lte(labels.size(), LIMIT, "%s: %s" % [scenario, JSON.stringify(labels)])


func test_scripted_recruit_and_scout_keep_all_visible_text_within_forty() -> void:
	for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
		var port := FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		var screen: RecruitScreen = _screen(pixels, port)
		await wait_process_frames(2)
		_assert_budget(screen, "slice recruit %s" % pixels)
		screen.toggle_scout()
		await wait_process_frames(2)
		_assert_budget(screen, "slice scout %s" % pixels)


func test_real_seeded_recruit_uses_the_same_forty_node_budget() -> void:
	for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
		var port := CorePort.new()
		port.setup()
		assert_eq(port.new_game(72), "")
		assert_eq(port.choose(0), "")
		var screen: RecruitScreen = _screen(pixels, port)
		await wait_process_frames(2)
		_assert_budget(screen, "seed72 recruit %s" % pixels)


func test_evidence_recruit_and_scout_states_obey_the_same_budget_at_both_sizes() -> void:
	var states: Dictionary = FixturePort.load_json(
		"res://docs/ideation/evidence/declutter/batch2/states.json"
	)
	for scenario: String in ["overview", "natural-birds", "lobby", "scout"]:
		assert_true(states.has(scenario), "the matching before/after fixture exists")
		if not states.has(scenario):
			continue
		var evidence: Dictionary = states[scenario]
		var state: Dictionary = evidence["state"]
		for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
			var port := FixturePort.new()
			port.set("_state", state.duplicate(true))
			var screen: RecruitScreen = _screen(pixels, port)
			if scenario == "scout":
				screen.toggle_scout()
			await wait_process_frames(2)
			_assert_budget(screen, "%s %s" % [scenario, pixels])


func test_counter_includes_names_numbers_buttons_and_rich_text_and_rejects_forty_one() -> void:
	var holder := Control.new()
	add_child_autofree(holder)
	for index: int in LIMIT:
		var label := Label.new()
		label.text = "2" if index % 2 == 0 else "Brock"
		holder.add_child(label)
	assert_eq(Capture.text_nodes(holder).size(), LIMIT)
	assert_true(Capture.text_nodes(holder).size() <= LIMIT)
	var extra := RichTextLabel.new()
	extra.text = "End turn"
	holder.add_child(extra)
	assert_eq(Capture.text_nodes(holder).size(), LIMIT + 1)
	assert_false(
		Capture.text_nodes(holder).size() <= LIMIT, "the 41st visible node exceeds the gate"
	)
	extra.hide()
	var button := Button.new()
	button.text = "Buy"
	holder.add_child(button)
	assert_eq(Capture.text_nodes(holder).size(), LIMIT + 1, "actions count too")


func test_shop_and_board_faces_leave_rules_in_reader_and_keep_stats() -> void:
	for mode: CardView.Mode in [CardView.Mode.SHOP, CardView.Mode.BOARD, CardView.Mode.MINI]:
		var tile := CardView.new()
		add_child_autofree(tile)
		var view: Dictionary = {
			"def_id": "field_vole",
			"name": "Field Vole",
			"attack": 3,
			"health": 4,
			"text": "End of Turn: gain +1/+1.",
			"keywords": [],
			"tier": 2
		}
		tile.show_unit(view, mode)
		tile.set_card_width(209)
		assert_false(tile.rules_shown)
		assert_eq(tile.chip_shown, "")
		var attack: Label = tile.get("_attack_label")
		var health: Label = tile.get("_health_label")
		assert_true(attack.is_visible_in_tree())
		assert_true(health.is_visible_in_tree())
		assert_eq(attack.text, "3")
		assert_eq(health.text, "4")
		assert_string_contains(CardDetail.full_text_bbcode(view), "End of Turn")


func test_lent_quarry_reach_pulses_its_actual_recipient_then_leaves_no_standing_mark() -> void:
	var own_units: Array = [
		LaneStates.unit("field_vole", 101),
		LaneStates.unit("field_vole", 102),
		null,
		null,
		null,
		null,
		null
	]
	var hunters: Array = [
		LaneStates.unit("young_brock", 1), LaneStates.unit("wick", 2), null, null, null, null, null
	]
	var projection := LaneProjection.new()
	projection.set("_library", LegacyHunters.library())
	var bindings: Dictionary = projection.forecast([own_units, hunters])
	var found_loan: bool = false
	for binding: Dictionary in bindings["quarries"]:
		if binding["from_side"] == 1 and binding["from_slot"] == 1:
			assert_eq(
				CoreUtil.to_int(binding["slot"]),
				0,
				"the borrowed quarry is not across from its hunter"
			)
			found_loan = true
	assert_true(found_loan)
	for speed: float in [1.0, 4.0]:
		Settings.fight_speed = speed
		Settings.reduce_motion = true
		var board := BoardView.new()
		board.configure("board", 209, true)
		add_child_autofree(board)
		var scout := ScoutPanel.new()
		add_child_autofree(scout)
		scout.show_board("Rival", hunters)
		scout.pulse_reach(board, bindings, 1)
		assert_eq(board.slots[0].reach_flash, 1.0)
		assert_eq(board.slots[1].reach_flash, 0.0, "the geometric across slot is not the quarry")
		await get_tree().create_timer(0.45 / speed).timeout
		for slot: Control in board.slots:
			var flash: float = slot.get("reach_flash")
			assert_eq(flash, 0.0, "the cue leaves no standing highlight")
