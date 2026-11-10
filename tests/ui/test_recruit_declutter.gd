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
# The orchestrator restored seven opponent tier numerals, explicitly kept by spec §2.5.
const KEPT_TIER_LIMITS: Dictionary = {"overview": 47, "lobby": 46}
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
	var limit: int = CoreUtil.to_int(KEPT_TIER_LIMITS.get(scenario.get_slice(" ", 0), LIMIT))
	print(
		(
			"declutter recruit label budget: %s = %d/%d %s"
			% [scenario, labels.size(), limit, JSON.stringify(breakdown["counts"])]
		)
	)
	assert_lte(labels.size(), limit, "%s: %s" % [scenario, JSON.stringify(labels)])


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


func test_ring_stacks_leave_the_floor_but_both_occupied_and_empty_slot_readers_keep_exact_values(
) -> void:
	for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
		var port := FixturePort.new()
		port.use_state_file("res://tests/ui/data/recruit_slice.json")
		port.get_state()["slot_effects"] = [
			[{"name": "Ring", "count": 36, "attack": 45, "health": 47}],
			[],
			[{"name": "Ring", "count": 2, "attack": 3, "health": 5}],
			[],
			[],
			[],
			[]
		]
		var before: Dictionary = port.get_state().duplicate(true)
		var screen: RecruitScreen = _screen(pixels, port)
		await wait_process_frames(2)
		var board: BoardView = screen.get("_board")
		var marks: Control = board.get("_marks")
		for label: Label in marks.get("_ring_labels"):
			assert_false(label.is_visible_in_tree(), "stack digits do not remain on the floor")
		var reader: CardDetail = screen.get("_detail")
		screen._on_tapped("board", 0)
		assert_true(reader.visible)
		assert_string_contains(str(reader.shown["text"]), "36 Rings (+45/+47)")
		screen._on_tapped("board", 0)
		screen._on_tapped("board", 2)
		assert_true(reader.visible)
		assert_string_contains(str(reader.shown["text"]), "2 Rings (+3/+5)")
		assert_eq(port.get_state(), before, "reading either Ring stack is a read-only action")
		await wait_process_frames(1)


func test_standard_spell_and_item_prices_leave_the_face_while_changed_prices_remain() -> void:
	for mode: CardView.Mode in [CardView.Mode.SHOP, CardView.Mode.BOARD, CardView.Mode.MINI]:
		for sample: Dictionary in [
			{"kind": "spell", "cost": 1, "visible": false, "number": "1"},
			{"kind": "spell", "cost": 0, "visible": true, "number": "0"},
			{"kind": "spell", "cost": 2, "visible": true, "number": "2"},
			{"kind": "spell", "cost": 5, "visible": true, "number": "5"},
			{"kind": "item", "gold_value": 1, "visible": false, "number": "1"},
			{"kind": "item", "gold_value": 20, "visible": true, "number": "20"},
			{"def_id": "field_vole", "poached": true, "cost": 2, "visible": true, "number": "2"}
		]:
			var tile := CardView.new()
			add_child_autofree(tile)
			tile.show_unit(sample, mode)
			var badge: Control = tile.get("_tier_badge")
			var number: Label = tile.get("_tier_label")
			assert_eq(badge.is_visible_in_tree(), CoreUtil.to_bool(sample["visible"]))
			assert_eq(number.text, str(sample["number"]))
			assert_eq(tile.unit, sample, "hiding a standard-price reminder preserves its value")


func test_one_gold_spell_reader_and_buy_action_retain_the_exact_price() -> void:
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	port.get_state()["shop"] = [
		{"def_id": "ring", "name": "Ring", "kind": "spell", "cost": 1, "text": "A Ring."}
	]
	var before: Dictionary = port.get_state().duplicate(true)
	var screen: RecruitScreen = _screen(Vector2i(1688, 780), port)
	await wait_process_frames(2)
	screen._on_tapped("shop", 0)
	var reader: CardDetail = screen.get("_detail")
	assert_true(reader.visible)
	assert_eq(CoreUtil.to_int(reader.shown["cost"]), 1)
	var reader_price: Label = reader.get("_tier_label")
	assert_true(reader_price.is_visible_in_tree())
	assert_eq(reader_price.text, "1")
	var buy: Button = reader.actions.get_child(0)
	var action_price: Label = buy.get("_cost_label")
	assert_true(action_price.is_visible_in_tree())
	assert_eq(action_price.text, "1")
	assert_eq(port.get_state(), before)


func test_away_tokens_keep_the_complete_forecast_in_one_tap_readers_at_both_sizes() -> void:
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
		assert_true(tray.is_visible_in_tree())
		var away: Array = state["away"]
		assert_eq(tray.tokens.size(), away.size(), "each away Bird retains a reachable token")
		assert_eq(tray.shown, RecruitHeld.sky_card(port.get_state()))
		var rest: Array[Dictionary] = Capture.text_nodes(tray)
		assert_eq(rest.size(), away.size(), "only each Bird's changing countdown stays at rest")
		for index: int in away.size():
			var source: Dictionary = away[index]
			var token_text: Array[Dictionary] = Capture.text_nodes(tray.tokens[index])
			assert_eq(token_text.size(), 1)
			assert_eq(str(token_text[0]["text"]), str(source["turns_left"]))
			assert_eq(str(token_text[0]["category"]), "other")
			tray.tokens[index].tapped.emit("away", index)
			var reader: CardDetail = screen.get("_detail")
			assert_true(reader.visible, "one tap opens the Bird's own complete reader")
			var retained: Dictionary = {}
			for key: String in source:
				if key != "text":
					retained[key] = reader.shown.get(key)
			var original: Dictionary = source.duplicate(true)
			original.erase("text")
			assert_eq(
				retained, original, "every original Bird field survives the reader enrichment"
			)
			var text: String = str(reader.shown["text"])
			assert_string_contains(text, str(source["text"]))
			assert_string_contains(
				text, "Now: %d Attack / %d Health." % [source["attack"], source["health"]]
			)
			assert_string_contains(
				text,
				(
					"Homecoming: %d Attack / %d Health."
					% [source["home_attack"], source["home_health"]]
				)
			)
			assert_string_contains(text, "Home in %d " % source["turns_left"])
			assert_string_contains(text, "Its Nest: front row, %d from the left." % (index + 3))
		assert_eq(port.get_state(), before)
