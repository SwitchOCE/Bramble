extends GutTest
## Production action callbacks present actual state without delaying or changing core actions.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Detail := preload("res://src/ui/widgets/card_detail.gd")
const Fixture := preload("res://tests/ui/shots/declutter_cold_fixture.gd")
const Screen := preload("res://src/ui/screens/recruit_screen.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Settings := preload("res://src/ui/settings.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const CASES: PackedStringArray = ["buy", "sell", "play", "triple", "tier-up", "ooze", "bird"]


func after_each() -> void:
	Settings.reset()
	Card.window_override = Vector2.ZERO


func _cards_restored(node: Node) -> void:
	if node is Card:
		var card: Card = node as Card
		if card.zone in ["shop", "hand", "board"]:
			assert_almost_eq(card.modulate.a, 1.0, 0.001, "finish restores every canonical card")
			var attack_label: Label = card.get("_attack_label")
			var health_label: Label = card.get("_health_label")
			assert_eq(attack_label.text.to_int(), CoreUtil.to_int(card.unit.get("attack", 0)))
			assert_eq(health_label.text.to_int(), CoreUtil.to_int(card.unit.get("health", 0)))
	for child: Node in node.get_children():
		_cards_restored(child)


func _canonical_change(kind: String, before: Dictionary, after: Dictionary) -> void:
	var old_shop: Array = before["shop"]
	var shop: Array = after["shop"]
	var old_hand: Array = before["hand"]
	var hand: Array = after["hand"]
	var board: Array = after["board"]
	var away: Array = after["away"]
	var old_gold: int = CoreUtil.to_int(before["gold"])
	var gold: int = CoreUtil.to_int(after["gold"])
	var old_tier: int = CoreUtil.to_int(before["tier"])
	var tier: int = CoreUtil.to_int(after["tier"])
	var cost: int = CoreUtil.to_int(before["tier_up_cost"])
	match kind:
		"buy":
			assert_eq(shop.size(), old_shop.size() - 1)
			assert_eq(hand.size(), old_hand.size() + 1)
		"sell":
			assert_true(board[1] == null)
			assert_gt(gold, old_gold)
		"play":
			var placed: Dictionary = board[1]
			var previous: Dictionary = old_hand[0]
			assert_eq(CoreUtil.to_int(placed["iid"]), CoreUtil.to_int(previous["iid"]))
		"triple":
			assert_eq(hand.size(), 1)
			assert_true(CoreUtil.to_bool(after["hand"][0]["golden"]))
			assert_true(board[1] == null)
		"tier-up":
			assert_eq(tier, old_tier + 1)
			assert_eq(gold, old_gold - cost)
		"ooze":
			var eater: Dictionary = board[1]
			var held: Array = eater["held"]
			assert_eq(held.size(), 1)
			assert_eq(shop.size(), old_shop.size() - 1)
		"bird":
			assert_eq(away.size(), 1)
			assert_true(board[1] == null)
			assert_eq(gold, old_gold, "Fly South is not paid sale gold")


func _check_actions(reduced: bool) -> void:
	Settings.reduce_motion = reduced
	Settings.fight_speed = 1.0
	Card.window_override = Vector2(1688, 780)
	for kind: String in CASES:
		var port: CorePort = Fixture.make(kind)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(2337, 1080)
		add_child_autofree(viewport)
		var screen := Screen.new()
		viewport.add_child(screen)
		screen.setup(port)
		await wait_process_frames(2)
		var before: Dictionary = port.get_state().duplicate(true)
		Fixture.perform(screen, kind)
		var after: Dictionary = port.get_state().duplicate(true)
		_canonical_change(kind, before, after)
		var motion: Control = screen.get("_action_motion")
		motion.set_process(false)
		var duration: float = CoreUtil.to_float(motion.get("duration"))
		assert_gt(duration, 0.0, "%s starts a real presentation cue" % kind)
		assert_lte(duration, 1.5)
		var tracks: Array = motion.get("tracks")
		assert_gt(tracks.size(), 0, "%s has an actual visible action track" % kind)
		motion.call("advance", duration * 0.45)
		assert_eq(
			port.get_state(), after, "presentation never delays or changes the committed core state"
		)
		if kind == "triple":
			var destination: Control = tracks[0]["target"]
			assert_eq(
				destination.modulate.a, 0.0, "golden stays hidden until every incoming copy retires"
			)
		if kind == "buy" and not reduced:
			var purchase: Dictionary = tracks[0]
			var travelling: Control = purchase["node"]
			var own_board: Control = screen.get("_board")
			var residents: Array = own_board.get("cards")
			for resident: Control in residents:
				if resident != null:
					assert_false(
						travelling.get_global_rect().intersects(resident.get_global_rect()),
						"purchase uses the gutter, clear of occupied board portraits"
					)
		if kind == "tier-up":
			var button: Control = screen.get("_tier_button")
			var price: Label = button.get("_cost_label")
			assert_eq(price.text, str(before["tier_up_cost"]), "old price remains during payment")
		if kind in ["ooze", "bird"]:
			var travel: Dictionary = tracks[0]
			assert_true(CoreUtil.to_bool(travel.get("dissolve")))
			var endpoint: Rect2 = travel["to"]
			if kind == "ooze":
				assert_lte(endpoint.size.x, 16.0, "purchase shrinks into the Belly glyph")
			var pulses: Array = motion.get("_pulses")
			assert_gt(pulses.size(), 0, "arrival has a count pulse")
			var first_pulse: Dictionary = pulses[0]
			var count: Control = first_pulse["target"]
			assert_eq(count.modulate.a, 0.0, "count waits until incoming overlay has retired")
			var current: float = CoreUtil.to_float(motion.get("elapsed"))
			var near_arrival: float = CoreUtil.to_float(travel["seconds"]) - 0.0001
			motion.call("advance", maxf(0.0, near_arrival - current))
			var picture: Control = travel["node"]
			var expected: Vector2 = motion.get_global_transform() * endpoint.get_center()
			assert_lt(
				picture.get_global_rect().get_center().distance_to(expected),
				1.0,
				"scaled picture reaches the actual glyph/portrait, not the neighbouring space"
			)
			assert_gte(
				CoreUtil.to_float(first_pulse["start"]), CoreUtil.to_float(travel["seconds"])
			)
		motion.call("advance", duration)
		for overlay: Node in motion.get_children():
			if overlay is Control:
				var picture: Control = overlay as Control
				assert_false(picture.visible, "natural ending retires every overlay before rest")
		assert_false(CoreUtil.to_bool(motion.get("active")))
		var settled_tracks: Array = motion.get("tracks")
		assert_true(settled_tracks.is_empty())
		await wait_process_frames(1)
		var gold: Control = screen.get("_gold")
		var value: Label = gold.get("_value")
		assert_eq(value.text, str(after["gold"]), "skip/finish shows the exact committed gold")
		var tier: Label = screen.get("_tier_label")
		assert_eq(tier.text, str(after["tier"]))
		_cards_restored(screen)
		assert_eq(port.get_state(), after, "finish has no hidden model state")
		viewport.free()


func test_real_actions_normal_motion_finish_at_canonical_state() -> void:
	await _check_actions(false)


func test_real_actions_reduced_motion_finish_at_canonical_state() -> void:
	await _check_actions(true)


func test_freed_animation_targets_and_overlays_can_advance_and_finish() -> void:
	var ActionScript := preload("res://src/ui/screens/recruit_action_motion.gd")
	for freed: String in ["target", "node", "pulse"]:
		var motion: Control = ActionScript.new()
		add_child_autofree(motion)
		var ghost := Control.new()
		var target := Control.new()
		var pulse := Control.new()
		motion.add_child(ghost)
		motion.add_child(target)
		motion.add_child(pulse)
		motion.set("active", true)
		motion.set("duration", 1.0)
		var tracks: Array = motion.get("tracks")
		(
			tracks
			. append(
				{
					"node": ghost,
					"target": target,
					"from": Rect2(0, 0, 20, 20),
					"to": Rect2(20, 20, 20, 20),
					"start": 0.0,
					"seconds": 0.5,
				}
			)
		)
		var targets: Array = motion.get("_targets")
		targets.append(target)
		motion.call("_pulse", pulse, 0.0)
		if freed == "target":
			target.free()
		elif freed == "node":
			ghost.free()
		else:
			pulse.free()
		motion.call("advance", 0.1)
		assert_almost_eq(CoreUtil.to_float(motion.get("elapsed")), 0.1, 0.001)
		motion.call("finish")
		assert_false(CoreUtil.to_bool(motion.get("active")), freed + " finishes without errors")
		assert_true(tracks.is_empty(), freed + " clears tracks after a target disappears")


func test_feedback_and_end_of_turn_motion_survive_freed_nodes() -> void:
	var FeedbackScript := preload("res://src/ui/screens/recruit_feedback.gd")
	var MotionScript := preload("res://src/ui/screens/recruit_motion.gd")
	var feedback: Control = FeedbackScript.new()
	add_child_autofree(feedback)
	var node := Control.new()
	var target := Control.new()
	feedback.add_child(node)
	feedback.add_child(target)
	var track: Dictionary = feedback.call("_cue", "poached", node, 0.4)
	track["target"] = target
	track["to"] = Vector2(20, 20)
	target.free()
	feedback.call("advance", 0.1)
	node.free()
	feedback.call("advance", 0.1)
	feedback.call("finish")
	var tracks: Array = feedback.get("tracks")
	assert_true(tracks.is_empty(), "freed feedback nodes are retired")
	var motion: Control = MotionScript.new()
	add_child_autofree(motion)
	var glyph := Control.new()
	motion.add_child(glyph)
	var sources: Dictionary = motion.get("_sources")
	sources[0] = {"glyph": glyph, "start": 0.0}
	glyph.free()
	motion.call("advance", 0.1)
	motion.call("finish")
	assert_true(sources.is_empty(), "freed end-of-turn glyphs are retired")


func test_reader_overlays_without_reflow_at_both_sizes() -> void:
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1688, 780)]:
		Card.window_override = Vector2(window)
		var viewport := SubViewport.new()
		viewport.size = window if window.x == 1920 else Vector2i(2337, 1080)
		add_child_autofree(viewport)
		var screen := Screen.new()
		viewport.add_child(screen)
		screen.setup(Fixture.make("play"))
		await wait_process_frames(2)
		var controls: Array[Control] = []
		for key: String in [
			"_board",
			"_shop_cards",
			"_hand_zone",
			"_gold",
			"_tier_button",
			"_refresh_button",
			"_freeze_button",
			"_end_button"
		]:
			controls.append(screen.get(key))
		var rectangles: Array[Rect2] = []
		for control: Control in controls:
			rectangles.append(control.get_global_rect())
		for zone: String in ["hand", "shop", "board"]:
			screen.call("_on_tapped", zone, 0)
			await wait_process_frames(2)
			var reader: Control = screen.get("_detail")
			assert_true(reader.visible)
			for i: int in controls.size():
				assert_eq(
					controls[i].get_global_rect(),
					rectangles[i],
					"reader leaves every control in place"
				)
			var row: Control = screen._board
			if zone == "shop":
				row = screen._shop_cards
			elif zone == "hand":
				row = screen._hand_zone
			assert_false(
				reader.get_global_rect().intersects(row.get_global_rect()),
				"the inspected row stays exposed"
			)
			for protected_row: Control in [
				screen._shop_cards, screen._board, screen._bar_contents, screen._lobby
			]:
				assert_false(
					reader.get_global_rect().intersects(protected_row.get_global_rect()),
					"merchant targets, board, rail and bottom bar stay exposed"
				)
			if zone == "hand":
				assert_false(
					reader.get_global_rect().intersects(screen._board.get_global_rect()),
					"hand play destinations stay exposed"
				)
			screen.call("_on_tapped", "table", -1)
		await wait_process_frames(1)
		viewport.free()


func test_direct_purchase_and_swap_have_tracks_for_the_actual_units() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var screen := Screen.new()
	viewport.add_child(screen)
	screen.setup(Fixture.make("buy"))
	await wait_process_frames(2)
	screen._drop({"zone": "shop", "index": 0}, "board", 1)
	var motion: Control = screen.get("_action_motion")
	motion.set_process(false)
	var tracks: Array = motion.get("tracks")
	assert_false(tracks.is_empty(), "direct shop-to-board has visible travel")
	var landing: Control = tracks[0]["target"]
	assert_eq(landing, screen._card_at("board", 1))
	var card_before_end: Control = screen._card_at("board", 1)
	screen.notification(Control.NOTIFICATION_DRAG_END)
	assert_eq(
		screen._card_at("board", 1), card_before_end, "drag-end does not rebuild the landing card"
	)
	screen._drop({"zone": "board", "index": 0}, "board", 1)
	motion.set_process(false)
	tracks = motion.get("tracks")
	assert_eq(tracks.size(), 2, "both actual swap participants travel")
	var first_target: Control = tracks[0]["target"]
	var second_target: Control = tracks[1]["target"]
	assert_ne(first_target, second_target)
	motion.call("finish")
	_cards_restored(screen)
	await wait_process_frames(1)


func test_reader_protects_each_whole_row_in_a_stacked_arrangement() -> void:
	var stage := Control.new()
	stage.size = Vector2(1920, 1080)
	add_child_autofree(stage)
	var rows: Dictionary = {}
	var rectangles: Dictionary = {
		"shop": Rect2(535, 28, 980, 245),
		"board": Rect2(510, 302, 1030, 450),
		"hand": Rect2(230, 760, 1600, 174),
		"gold": Rect2(120, 940, 200, 100),
		"end": Rect2(1480, 940, 350, 100),
	}
	for key: String in rectangles:
		var row := Control.new()
		var rect: Rect2 = rectangles[key]
		row.position = rect.position
		row.size = rect.size
		stage.add_child(row)
		rows[key] = row
	var reader := Detail.new()
	stage.add_child(reader)
	var gold: Control = rows["gold"]
	var end: Control = rows["end"]
	reader.attach_recruit_overlay(
		stage, gold, end, {"shop": rows["shop"], "board": rows["board"], "hand": rows["hand"]}
	)
	for zone: String in ["shop", "board", "hand"]:
		reader.read_zone = zone
		reader.show_unit(
			{"name": "Hedge Witch", "def_id": "hedge_witch", "text": "Start of Combat."}
		)
		reader.add_action("Buy", func() -> void: pass, 3)
		await wait_process_frames(1)
		var row: Control = rows[zone]
		assert_false(
			reader.get_global_rect().intersects(row.get_global_rect()),
			zone + " stays completely exposed"
		)
		if zone == "hand":
			var board: Control = rows["board"]
			assert_false(
				reader.get_global_rect().intersects(board.get_global_rect()),
				"hand inspection also leaves play destinations clear"
			)
		reader.show_empty()
	reader.read_zone = "hand"
	reader.show_unit({"name": "Shake the Tree", "kind": "spell", "aim": "shop_unit"})
	await wait_process_frames(1)
	for zone: String in ["hand", "shop"]:
		var row: Control = rows[zone]
		assert_false(
			reader.get_global_rect().intersects(row.get_global_rect()),
			"a shop-targeted spell leaves its source and targets exposed"
		)
	await wait_process_frames(1)


func test_reader_name_fitting_does_not_step_below_the_existing_minimum() -> void:
	var reader := Detail.new()
	add_child_autofree(reader)
	reader.place_overlay(Rect2(150, 20, 354, 648))
	reader.show_unit({"name": "The Standing Committee"})
	var name_label: Label = reader.get("_name_label")
	assert_gte(name_label.get_theme_font_size("font_size"), UiTheme.FONT_SMALL)


func test_explicit_reader_survives_hover_exit_until_another_tap() -> void:
	var screen := Screen.new()
	add_child_autofree(screen)
	screen.setup(Fixture.make("scout"))
	await wait_process_frames(2)
	screen.toggle_scout()
	screen.call("_read_external", {"name": "Ghost", "text": "Ghost opponent"})
	screen.call("_on_hovered", "board", 0, false)
	screen.call("_show_hover")
	screen.call("_on_leave_check")
	var reader: Detail = screen.get("_detail")
	assert_true(reader.visible)
	assert_eq(str(reader.shown["name"]), "Ghost")
	assert_false(reader.get_global_rect().intersects(screen._scout.get_global_rect()))
	screen.call("_show_lobby_hero", {"is_human": true, "name": "Hidden lobby hover"})
	assert_eq(str(reader.shown["name"]), "Ghost", "hidden lobby events cannot replace scouting")
	screen.call("_on_hovered", "board", 2, true)
	screen.call("_show_hover")
	assert_ne(str(reader.shown["name"]), "Ghost", "a fresh card hover can read another unit")
	screen.call("_on_tapped", "table", -1)
	assert_false(reader.visible)
	await wait_process_frames(1)


func test_reader_backing_follows_rules_actions_and_keyword_content() -> void:
	var reader := Detail.new()
	add_child_autofree(reader)
	reader.place_overlay(Rect2(150, 20, 430, 680))
	reader.show_unit({"name": "Short card", "text": "Four short lines.\nSecond.\nThird.\nFourth."})
	await wait_process_frames(2)
	var short_height: float = reader.size.y
	var notes: RichTextLabel = reader.get("_notes")
	assert_almost_eq(notes.size.y, float(notes.get_content_height()), 1.0)
	reader.add_action("Buy", func() -> void: pass, 3)
	await wait_process_frames(2)
	assert_gt(reader.size.y, short_height, "actions have room without a standing empty backing")
	reader.show_unit({"name": "Long card", "text": "A longer line of card rules.\n".repeat(20)})
	await wait_process_frames(2)
	assert_eq(reader.size.y, 680.0, "long rules use the available band and scroll")
	assert_gt(float(notes.get_content_height()), notes.size.y)
