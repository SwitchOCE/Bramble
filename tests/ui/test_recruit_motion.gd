extends GutTest
## Events change their real recipient's visible beads only on landing, without changing views.

const Motion := preload("res://src/ui/screens/recruit_motion.gd")
const Board := preload("res://src/ui/widgets/board_view.gd")
const Card := preload("res://src/ui/widgets/card_view.gd")
const Settings := preload("res://src/ui/settings.gd")


func after_each() -> void:
	Settings.reset()


func _board(occupied: Array[int]) -> Board:
	var board := Board.new()
	add_child_autofree(board)
	board.configure("board", 209, true)
	for slot: int in occupied:
		var card := Card.new()
		card.show_unit(
			{
				"iid": slot + 10,
				"attack": 2,
				"health": 3,
				"max_health": 3,
				"text": "End of Turn: units touching this gain +1/+1."
			},
			Card.Mode.BOARD
		)
		board.place_card(card, slot)
	return board


func _motion() -> Motion:
	var motion := Motion.new()
	add_child_autofree(motion)
	motion.set_process(false)
	return motion


func test_drag_preview_survives_a_neighbour_freed_mid_lean() -> void:
	var board: Board = _board([0, 1])
	board.show_relations([0], 1)
	var origins: Dictionary = board.get("_lean_origins")
	assert_eq(origins.size(), 1, "drag preview retains its leaning neighbour")
	board.remove_card(0)
	await wait_process_frames(1)
	board.show_relations([1], 0)
	assert_eq(origins.size(), 1, "next drag replaces the freed key with a live neighbour")
	assert_true(origins.has(board.cards[1]))
	assert_engine_error_count(0, "freed lean keys are validated before casting")


func test_clear_cancels_drag_lean_before_board_cards_are_rendered_again() -> void:
	var board: Board = _board([0, 1])
	board.show_relations([0], 1)
	var tween: Tween = board.get("_lean_tween")
	assert_true(tween.is_valid(), "a real drag lean is running")
	board.clear()
	var origins: Dictionary = board.get("_lean_origins")
	assert_true(origins.is_empty(), "rendering drops all previous drag keys")
	assert_false(tween.is_valid(), "rendering kills the previous drag tween")
	await wait_process_frames(1)
	board.place_card(Card.new(), 0)
	board.show_relations([0], 1)
	assert_eq(origins.size(), 1, "the rebuilt board can preview the next drag")
	assert_engine_error_count(0, "rendering during a drag leaves no invalid instances")


func _buff(source: int, target: int, old_a: int = 2) -> Dictionary:
	return {
		"type": "buff",
		"source_slot": source,
		"target_iid": target + 10,
		"attack": 1,
		"health": 1,
		"before_attack": old_a,
		"before_health": 3,
		"after_attack": old_a + 1,
		"after_health": 4,
		"trigger": "end_of_turn"
	}


func test_touching_hops_through_the_contiguous_chain_and_lands_before_stats_roll() -> void:
	var board: Board = _board([0, 4, 1, 2])
	var motion: Motion = _motion()
	motion.play_events(board, [_buff(0, 1), _buff(0, 2)])
	motion.set_process(false)
	assert_eq(motion.tracks.size(), 1, "the gap at B2 stops the Touching effect")
	var route: Array = motion.tracks[0]["route"]
	assert_eq(route, [0, 4, 1], "the mote visits each touching pocket, not a direct chord")
	var label: Label = board.cards[1].get("_attack_label")
	motion.advance(0.05)
	assert_eq(label.text, "2", "the old number stays until the mote lands")
	motion.advance(0.3)
	motion.advance(0.2)
	assert_eq(label.text, "3", "the event's actual final value lands")
	assert_eq(
		CoreUtil.to_int(board.cards[1].unit["attack"]),
		2,
		"animation never rewrites the shared recruit view"
	)
	assert_true(motion.tracks.is_empty(), "no resting route remains")


func test_pass_skips_gaps_and_its_following_buff_is_not_applied_twice() -> void:
	var board: Board = _board([0, 1, 3])
	var motion: Motion = _motion()
	var following_buff: Dictionary = _buff(0, 3)
	following_buff["trigger"] = "pass"
	motion.play_events(
		board,
		[
			{
				"type": "pass",
				"from": 0,
				"to": 3,
				"before_attack": 2,
				"before_health": 3,
				"after_attack": 5,
				"after_health": 6
			},
			following_buff
		]
	)
	motion.set_process(false)
	assert_eq(motion.tracks.size(), 1)
	var pass_route: Array = motion.tracks[0]["route"]
	assert_eq(pass_route, [0, 1, 3], "Pass crosses the gaps that stop Touching")
	motion.finish()
	var label: Label = board.cards[3].get("_attack_label")
	assert_eq(label.text, "5", "skip settles the actual pass result exactly once")


func test_queued_gain_rolls_labels_without_mutating_canonical_stats_or_creating_delta_text(
) -> void:
	var board: Board = _board([0])
	var motion: Motion = _motion()
	motion.roll_gain(board.cards[0], 1, 2)
	motion.set_process(false)
	var label: Label = board.cards[0].get("_attack_label")
	assert_eq(label.text, "1")
	assert_eq(CoreUtil.to_int(board.cards[0].unit["attack"]), 2)
	motion.advance(0.25)
	assert_eq(label.text, "2")
	assert_eq(motion.get_child_count(), 0, "bead motion adds no +X overlay")


func test_all_speeds_finish_inside_sequence_budget_and_reduce_motion_flashes_in_place() -> void:
	for reduced: bool in [false, true]:
		for speed: float in [1.0, 4.0]:
			Settings.reduce_motion = reduced
			Settings.fight_speed = speed
			var board: Board = _board([0, 4, 1, 5, 2, 6, 3])
			var motion: Motion = _motion()
			var events: Array = []
			for source: int in 7:
				events.append(_buff(source, source))
			var span: float = motion.play_events(board, events)
			motion.set_process(false)
			assert_lte(span, 1.5)
			if reduced:
				assert_almost_eq(
					CoreUtil.to_float(motion.tracks[0]["land"]),
					0.15,
					0.001,
					"source flash lasts 150ms"
				)
			motion.advance(1.5)
			assert_true(motion.tracks.is_empty())
			for card: Card in board.cards:
				assert_eq(card.trigger_glyph().scale, Vector2.ONE, "no held glyph emphasis")


func test_carried_pass_before_touching_rebases_visual_order_to_the_actual_final_stats() -> void:
	var board: Board = _board([0, 4, 1, 5, 2, 6, 3])
	var motion: Motion = _motion()
	var touching: Dictionary = _buff(0, 3, 5)
	touching["before_health"] = 6
	touching["after_health"] = 7
	var next_turn: Dictionary = _buff(0, 3, 6)
	next_turn["trigger"] = "start_of_turn"
	(
		motion
		. play_events(
			board,
			[
				{
					"type": "pass",
					"from": 0,
					"to": 3,
					"before_attack": 2,
					"before_health": 3,
					"after_attack": 5,
					"after_health": 6
				},
				touching,
				next_turn,
			]
		)
	)
	motion.set_process(false)
	assert_eq(
		motion.tracks.size(), 2, "the following Start of Turn is not replayed during End of Turn"
	)
	assert_false(
		CoreUtil.to_bool(motion.tracks[0]["pass"]), "Touching is presented before the carried Pass"
	)
	motion.finish()
	var attack_label: Label = board.cards[3].get("_attack_label")
	var health_label: Label = board.cards[3].get("_health_label")
	assert_eq(attack_label.text, "6", "2 + actual Touching 1 + actual carried Pass 3")
	assert_eq(health_label.text, "7", "the final beads match the actual core outcome")
