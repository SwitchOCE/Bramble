extends GutTest
## Count the actual rendered controls: stats, names and action captions all spend the budget.

const GamePort := preload("res://src/ui/adapter/game_port.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const AwayTray := preload("res://src/ui/widgets/away_tray.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const ScoutPanel := preload("res://src/ui/widgets/scout_panel.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")
const LaneStates := preload("res://tests/ui/lane_states.gd")
const Settings := preload("res://src/ui/settings.gd")

const LIMIT: int = 40
var _breakdown_records: Array[Dictionary] = []


func after_each() -> void:
	CardView.window_override = Vector2.ZERO
	Settings.reduce_motion = false
	Settings.fight_speed = 1.0


func after_all() -> void:
	var output: String = OS.get_environment("BRAMBLE_BUDGET_BREAKDOWN")
	if output.is_empty():
		output = "res://build/declutter/b2-tests/budget-breakdown-run.json"
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	assert_not_null(file, "classified evidence is writable")
	if file != null:
		file.store_string(
			JSON.stringify({"schema": 1, "captures": _breakdown_records}, "\t", true, true)
		)
		file.close()


func _record_breakdown(
	screen: RecruitScreen, scenario: String, reader_open: bool = false
) -> Dictionary:
	var breakdown: Dictionary = Capture.label_breakdown(screen)
	breakdown["scenario"] = scenario.get_slice(" (", 0)
	breakdown["pixels"] = screen.get_meta("evidence_pixels")
	breakdown["reader_open"] = reader_open
	breakdown["state_sha256"] = (
		JSON.stringify(screen.port.get_state(), "", true, true).sha256_text()
	)
	_breakdown_records.append(breakdown)
	return breakdown


func _screen(pixels: Vector2i, port: GamePort) -> RecruitScreen:
	CardView.window_override = Vector2(pixels)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(1080.0 * pixels.x / pixels.y), 1080)
	add_child_autofree(viewport)
	var screen := RecruitScreen.new()
	viewport.add_child(screen)
	screen.set_meta("evidence_pixels", [pixels.x, pixels.y])
	screen.setup(port)
	return screen


func _assert_budget(screen: RecruitScreen, scenario: String) -> void:
	var breakdown: Dictionary = _record_breakdown(screen, scenario)
	var labels: Array[Dictionary] = breakdown["visible_text_nodes"]
	print(
		(
			"declutter recruit label budget: %s = %d/%d %s"
			% [scenario, labels.size(), LIMIT, JSON.stringify(breakdown["counts"])]
		)
	)
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
	for scenario: String in [
		"overview", "natural-birds", "lobby", "scout", "reader-reel_mistress-golden"
	]:
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
			elif scenario == "reader-reel_mistress-golden":
				var hand: Array = port.get_state()["hand"]
				for index: int in hand.size():
					var card: Dictionary = hand[index]
					if str(card.get("def_id", "")) == "reel_mistress":
						screen._on_tapped("hand", index)
			await wait_process_frames(2)
			if scenario == "reader-reel_mistress-golden":
				var reader: CardDetail = screen.get("_detail")
				assert_true(reader.visible, "reader-open evidence includes every reader label")
				_record_breakdown(screen, scenario, true)
			else:
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


func test_scout_focus_clears_selected_reader_and_pending_hover_without_changing_state() -> void:
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var screen: RecruitScreen = _screen(Vector2i(1688, 780), port)
	await wait_process_frames(2)
	screen._on_tapped("shop", 0)
	var reader: CardDetail = screen.get("_detail")
	assert_true(reader.visible, "the selected shop card starts in its reader")
	var hover_card: Dictionary = screen.state["shop"][1]
	screen.set("_hover_view", hover_card.duplicate(true))
	screen.set("_hover_zone", "shop")
	screen.set("_hover_index", 1)
	var hover: Timer = screen.get("_hover_timer")
	var leave: Timer = screen.get("_leave_timer")
	hover.start(10.0)
	leave.start(10.0)
	var before: Dictionary = port.get_state().duplicate(true)
	screen.toggle_scout()
	await wait_process_frames(2)
	assert_false(reader.visible, "focus closes a selected shop reader")
	var selection: Dictionary = screen.get("_selected")
	var hovering: Dictionary = screen.get("_hover_view")
	assert_true(selection.is_empty())
	assert_true(hovering.is_empty())
	assert_true(hover.is_stopped(), "a queued hover cannot reopen the collapsed shop")
	assert_true(leave.is_stopped())
	var own: BoardView = screen.get("_board")
	var scout: ScoutPanel = screen.get("_scout")
	assert_true(own.is_visible_in_tree())
	assert_true(scout.is_visible_in_tree())
	var shop: Control = screen.get("_shop_cards")
	assert_false(shop.is_visible_in_tree())
	assert_eq(port.get_state(), before)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	screen._unhandled_key_input(escape)
	await wait_process_frames(2)
	assert_false(scout.visible, "Escape closes scout focus")
	var pause_menu: Node = screen.get("_pause")
	assert_null(pause_menu, "closing focus does not also open pause")
	assert_eq(port.get_state(), before, "both focus transitions leave every recruit value intact")


func test_modified_refresh_prices_remain_visible_while_the_standard_price_uses_its_tooltip(
) -> void:
	for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
		var port := FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		var screen: RecruitScreen = _screen(pixels, port)
		for cost: int in [1, 0, 2]:
			port.get_state()["refresh_cost"] = cost
			var before: Dictionary = port.get_state().duplicate(true)
			screen.render()
			await wait_process_frames(1)
			var refresh: Control = screen.get("_refresh_button")
			var pill: Control = refresh.get("_cost_pill")
			var label: Label = refresh.get("_cost_label")
			assert_eq(pill.is_visible_in_tree(), cost != 1)
			assert_string_contains(refresh.tooltip_text, "%d gold" % cost)
			if cost != 1:
				assert_true(label.is_visible_in_tree())
				assert_eq(label.text, str(cost), "a changed refresh price is decision state")
			assert_eq(port.get_state(), before, "rendering the price never changes recruit state")


func test_away_heading_cut_retains_the_complete_reader_forecast_at_both_sizes() -> void:
	var evidence: Dictionary = FixturePort.load_json(
		"res://docs/ideation/evidence/declutter/batch2/states.json"
	)
	var overview: Dictionary = evidence["overview"]
	var state: Dictionary = overview["state"]
	for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
		var port := FixturePort.new()
		port.set("_state", state.duplicate(true))
		var before: Dictionary = port.get_state().duplicate(true)
		var screen: RecruitScreen = _screen(pixels, port)
		await wait_process_frames(2)
		var tray: AwayTray = screen.get("_away_tray")
		var heading: Label = tray.get("_heading")
		var forecast: RichTextLabel = tray.get("_notes")
		var reader: Dictionary = RecruitHeld.sky_card(port.get_state())
		assert_true(tray.is_visible_in_tree())
		assert_false(heading.is_visible_in_tree())
		assert_false(forecast.get_parsed_text().is_empty())
		assert_eq(
			forecast.get_parsed_text(),
			str(reader["text"]),
			"the complete changing Bird state survives the heading cut"
		)
		assert_eq(port.get_state(), before)
