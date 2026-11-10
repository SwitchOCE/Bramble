extends GutTest
## Production action callbacks present actual state without delaying or changing core actions.

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
