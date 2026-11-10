extends GutTest
## Reader refusals and automatic recruit consequences remain visible without standing hints.

const Screen := preload("res://src/ui/screens/recruit_screen.gd")
const Feedback := preload("res://src/ui/screens/recruit_feedback.gd")
const Detail := preload("res://src/ui/widgets/card_detail.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Board := preload("res://src/ui/widgets/board_view.gd")
const Slot := preload("res://src/ui/widgets/slot_view.gd")
const View := preload("res://src/ui/screens/recruit_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const Settings := preload("res://src/ui/settings.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const Actions := preload("res://tests/ui/shots/declutter_cold_fixture.gd")


func after_each() -> void:
	Settings.reset()
	Card.window_override = Vector2.ZERO


func _screen(port: GamePort, pixels: Vector2i = Vector2i(1688, 780)) -> Screen:
	Card.window_override = Vector2(pixels)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(1080.0 * pixels.x / pixels.y), 1080)
	add_child_autofree(viewport)
	var screen := Screen.new()
	viewport.add_child(screen)
	screen.setup(port)
	return screen


func _fixture() -> FixturePort:
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var raw: Dictionary = port.get_state()
	raw["board"] = [null, null, null, null, null, null, null]
	raw["hand"] = []
	raw["hand_items"] = []
	raw["recruit_log"] = []
	return port


func _unit(def_id: String, iid: int) -> Dictionary:
	return {
		"def_id": def_id,
		"name": def_id.capitalize(),
		"iid": iid,
		"attack": 2,
		"health": 3,
		"tier": 1,
		"tribes": [],
	}


func _kinds(feedback: Feedback) -> PackedStringArray:
	var kinds: PackedStringArray = []
	for track: Dictionary in feedback.tracks:
		kinds.append(Data.s(track, "kind"))
	return kinds


func test_unavailable_spells_show_disabled_reason_and_tapped_card_feedback_at_both_sizes() -> void:
	for pixels: Vector2i in [Vector2i(1688, 780), Vector2i(1920, 1080)]:
		for item: Dictionary in [
			{"def_id": "bread", "kind": "spell", "aim": "back_unit"},
			{"def_id": "golden_egg", "kind": "item", "aim": "unit"},
			{"def_id": "harvest_supper", "kind": "spell", "aim": "none"},
			{"def_id": "fairy_ring", "kind": "spell", "aim": "slot", "ring_add": [1, 1]},
		]:
			var port: FixturePort = _fixture()
			var raw: Dictionary = port.get_state()
			raw["hand_items"] = [item]
			raw["harvest_supper_used"] = true
			raw["pass3_content"] = false
			raw.erase("ring_size")
			var effects: Array = []
			for slot: int in Board.SLOTS:
				effects.append(
					[
						{
							"name": "Ring",
							"attack": BoardUpkeep.RING_CAP,
							"health": BoardUpkeep.RING_CAP
						}
					]
				)
			raw["slot_effects"] = effects
			var screen: Screen = _screen(port, pixels)
			await wait_process_frames(2)
			var before: Dictionary = raw.duplicate(true)
			screen._on_tapped("hand", 0)
			var reader: Detail = screen.get("_detail")
			assert_eq(reader.actions.get_child_count(), 1)
			var action: Button = reader.actions.get_child(0) as Button
			assert_true(action.disabled)
			assert_eq(action.text, View.no_target_note(screen.state, item))
			var hint: Label = reader.get("_hint")
			assert_false(hint.visible, "the reason belongs on the action, with no tutorial hint")
			var feedback: Feedback = screen.get("_feedback")
			assert_has(_kinds(feedback), "refused")
			feedback.set_process(false)
			feedback.advance(0.05)
			assert_eq(raw, before, "a refusal cue cannot mutate a card or spend an item")
			feedback.finish()
			var fan: Control = screen.get("_hand_cards")
			var tile: Card = fan.get_child(0) as Card
			assert_eq(tile.scale, Vector2.ONE)
			assert_eq(tile.modulate, Color.WHITE)
			var board: Board = screen.get("_board")
			for slot: Slot in board.slots:
				assert_eq(
					slot.highlight, Color.TRANSPARENT, "unavailable cards have no false targets"
				)
			screen.get_parent().free()


func test_failure_notices_reach_real_screen_once_and_repeated_render_adds_no_cues() -> void:
	var port: CorePort = Actions.make("play")
	var players: Array[PlayerState] = port.session.get("_players")
	var player: PlayerState = players[0]
	var rules: RecruitRules = port.session.get_rules()
	for slot: int in player.board.size():
		player.board[slot] = RecruitUnit.make(rules.library.get_unit("mr_crumb"), rules.new_iid())
	var screen: Screen = _screen(port)
	await wait_process_frames(2)
	rules.summon_units(player, "mouse", 2, false, 0)
	player.log_event("discover_empty", {"count": 3})
	screen._after_change()
	var toast: Label = screen.get("_toast")
	assert_eq(toast.text.count("No room for Mouse."), 2, "every failed summon is accounted for")
	assert_string_contains(toast.text, "Discover found no eligible cards.")
	var feedback: Feedback = screen.get("_feedback")
	assert_eq(_kinds(feedback).count("no_room"), 2)
	var after: Dictionary = port.get_state().duplicate(true)
	feedback.finish()
	screen._clear_toast()
	screen.render()
	screen._after_change()
	assert_eq(toast.text, "", "the same log entries cannot be toasted twice")
	assert_true(feedback.tracks.is_empty())
	assert_eq(port.get_state(), after)
	var events: Array[Dictionary] = Feedback.new_events(
		{"round": 1, "recruit_log": [{"type": "kiss"}]},
		{"round": 2, "recruit_log": [{"type": "discover_empty"}]}
	)
	assert_eq(events.size(), 1, "a new turn starts reading the new turn's log from zero")
	assert_eq(Data.s(events[0], "type"), "discover_empty")


func test_removed_success_notices_have_cues_and_leave_canonical_state_in_both_motion_modes(
) -> void:
	for reduced: bool in [false, true]:
		Settings.reduce_motion = reduced
		var port: FixturePort = _fixture()
		var raw: Dictionary = port.get_state()
		var frog: Dictionary = _unit("bridge_toad", 10)
		var shy: Dictionary = _unit("silky", 11)
		var expired: Dictionary = _unit("mrs_sorrel", 12)
		expired["poached"] = true
		var second_expired: Dictionary = _unit("mrs_sorrel", 14)
		second_expired["poached"] = true
		raw["board"] = [frog, shy, null, null, null, null, null]
		raw["shop"] = [expired, second_expired]
		raw["shop_spells"] = []
		raw["buys_left"] = 1
		raw["hero"] = {"id": "pipkin", "name": "Pipkin", "kind": "passive"}
		var screen: Screen = _screen(port)
		await wait_process_frames(2)
		var poached: Dictionary = _unit("mr_crumb", 13)
		poached["poached"] = true
		var second_poached: Dictionary = _unit("mr_crumb", 15)
		second_poached["poached"] = true
		raw["shop"] = [poached, second_poached]
		raw["board"] = [frog, null, null, null, null, null, null]
		raw["gold_next_turn"] = 2
		raw["buys_left"] = 0
		raw["recruit_log"] = [
			{"type": "kiss", "iid": 10, "count": 2},
			{"type": "transform", "iid": 10, "name": "Prince Restored"},
			{"type": "poached", "card": "mr_crumb", "name": "Mr Crumb"},
			{"type": "poached", "card": "mr_crumb", "name": "Mr Crumb"},
			{"type": "poach_returned", "name": expired["name"]},
			{"type": "poach_returned", "name": expired["name"]},
			{"type": "walk_out", "name": shy["name"], "slot": 1, "gold": 2},
			{"type": "nest_replaced", "slot": 2, "name": "Mrs Jay"},
		]
		screen._after_change()
		var feedback: Feedback = screen.get("_feedback")
		feedback.set_process(false)
		var kinds: PackedStringArray = _kinds(feedback)
		var poached_targets: Dictionary = {}
		for track: Dictionary in feedback.tracks:
			if Data.s(track, "kind") == "poached":
				var target: Control = track["target"]
				poached_targets[target.get_instance_id()] = true
			if Data.s(track, "kind") == "spent":
				var spent_target: Control = track["node"]
				assert_true(
					spent_target.is_visible_in_tree(), "spent buys animate a visible player anchor"
				)
		assert_eq(poached_targets.size(), 2, "equal-name offers use distinct destination cards")
		assert_eq(kinds.count("poach_returned"), 2, "each expired copy departs once")
		for kind: String in [
			"kiss",
			"heart",
			"transform",
			"poached",
			"poach_returned",
			"walk_out",
			"queued",
			"nest_old",
			"nest_new",
			"spent"
		]:
			assert_has(kinds, kind, "each removed notice gets a real transient consequence")
		var toast: Label = screen.get("_toast")
		assert_eq(toast.text, "", "successful events leave no prose toast")
		var committed: Dictionary = raw.duplicate(true)
		feedback.advance(0.05)
		if reduced:
			var reduced_board: Board = screen.get("_board")
			assert_eq(reduced_board.cards[0].position, reduced_board.card_position(0))
			assert_gt(
				reduced_board.cards[0].modulate.r, 1.0, "reduced motion uses an anchored flash"
			)
		assert_eq(raw, committed)
		feedback.advance(2.0)
		assert_true(feedback.tracks.is_empty())
		for node: Node in feedback.get_children():
			if node is Control:
				assert_false(
					(node as Control).visible, "each picture retires before the rest frame"
				)
		var board: Board = screen.get("_board")
		assert_eq(board.cards[0].scale, Vector2.ONE)
		assert_eq(board.cards[0].modulate, Color.WHITE)
		assert_eq(raw, committed)
		screen.get_parent().free()


func test_one_aimed_spell_thanks_shy_and_immediately_presents_departure() -> void:
	var port: CorePort = Actions.make("play")
	var players: Array[PlayerState] = port.session.get("_players")
	var player: PlayerState = players[0]
	var rules: RecruitRules = port.session.get_rules()
	player.board[1] = RecruitUnit.make(rules.library.get_unit("silky"), rules.new_iid())
	player.items.append(
		HandItem.make(rules.library.get_card("elderflower_cordial"), rules.new_iid())
	)
	var screen: Screen = _screen(port)
	await wait_process_frames(2)
	var hand: Array = Data.a(screen.state, "hand")
	screen._on_tapped("hand", hand.size() - 1)
	screen._on_tapped("board", 1)
	assert_null(player.board[1], "the first aimed press commits Shy's departure")
	assert_true(player.items.is_empty(), "the first press spends the aimed spell")
	assert_eq(player.gold_next_turn, 2)
	var feedback: Feedback = screen.get("_feedback")
	assert_has(_kinds(feedback), "walk_out")
	assert_has(_kinds(feedback), "queued")
	var toast: Label = screen.get("_toast")
	assert_eq(toast.text, "", "one press has no confirmation reminder")


func test_end_turn_completes_once_normally_or_when_skipping_a_pending_feedback_timer() -> void:
	for mode: String in ["normal", "skip", "waiting"]:
		var port: FixturePort = _fixture()
		var screen: Screen = _screen(port)
		await wait_process_frames(2)
		var emitted: Array[int] = [0]
		screen.combat_ready.connect(func() -> void: emitted[0] += 1)
		screen._on_end_turn()
		var committed: Dictionary = port.get_state().duplicate(true)
		var feedback: Feedback = screen.get("_feedback")
		var gold: Control = screen.get("_gold")
		var origin: Vector2 = gold.position
		# Add a real unfinished cue before the motion clock dispatches its completion callback.
		feedback.refuse(gold)
		assert_gt(feedback.duration, 0.0)
		if mode == "waiting":
			await wait_process_frames(2)
			assert_eq(emitted[0], 0, "the ordinary completion is waiting for the unfinished cue")
		if mode != "normal":
			screen._on_end_turn()
			assert_eq(emitted[0], 1, "the skip itself emits completion once")
		await get_tree().create_timer(0.35).timeout
		assert_eq(
			emitted[0], 1, "%s: deferred completion or a resumed timer cannot emit twice" % mode
		)
		assert_true(feedback.tracks.is_empty())
		assert_eq(feedback.duration, 0.0)
		assert_eq(
			gold.position, origin, "normal completion and skip both restore the moving target"
		)
		assert_eq(port.get_state(), committed, "presentation completion cannot commit another turn")
		screen.get_parent().free()
