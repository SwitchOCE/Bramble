extends GutTest
## Real Ring cohorts drive copied floor state; only temporary dots travel between pockets.

const CK := preload("res://tests/core/combat_kit.gd")
const KIT := preload("res://tests/core/recruit_kit.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const Screen := preload("res://src/ui/screens/combat_screen.gd")
const Lanes := preload("res://src/ui/screens/combat_lanes_view.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RingTravel := preload("res://src/ui/widgets/ring_travel.gd")
const Settings := preload("res://src/ui/settings.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")


func after_each() -> void:
	Settings.reset()


func _fixture(pass3: bool = true) -> Dictionary:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game() if pass3 else GameConfig.defaults(), not pass3)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 27
	var combat: Combat = Combat.create(kit.library, kit.config, rng)
	var row: Array = []
	for slot: int in 7:
		row.append([])
	if pass3:
		row[0] = [
			{"name": "Ring", "count": 3, "ring_size": 2.5, "attack": 8, "health": 8, "moves": 2},
			{"name": "Ring", "count": 2, "ring_size": 2.5, "attack": 5, "health": 5, "moves": 0}
		]
		row[1] = [{"name": "Ring", "count": 1, "ring_size": 2.5, "attack": 3, "health": 3}]
	else:
		row[0] = [{"name": "Ring", "attack": 5, "health": 7}]
		row[1] = [{"name": "Ring", "attack": 2, "health": 3}]
	var original: Array = row.duplicate(true)
	combat.slot_effects = [row, []]
	combat._setup(
		[CK.board({0: CK.u("reel_mistress"), 1: CK.plain(1, 50)}), CK.board({0: CK.plain(0, 1000)})]
	)
	combat._recalc_auras(false)
	CombatMoves.dance_rings(combat, combat.unit_at(0, 0))
	var start: Dictionary = {}
	var dance: Dictionary = {}
	for event: Dictionary in combat.events:
		if str(event["type"]) == "combat_start":
			start = event
		elif str(event["type"]) == "ring_dance":
			dance = event
	return {
		"start": start,
		"dance": dance,
		"original_effects": original,
		"input_effects": row,
		"floor": [RecruitView.slot_marks({"slot_effects": original}), []]
	}


func _screen(fixture: Dictionary) -> Screen:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var screen: Screen = Screen.new()
	screen.manual_playback = true
	screen.auto_return = false
	viewport.add_child(screen)
	var initial_floor: Array = fixture["floor"]
	screen.setup({"events": [], "floor_marks": initial_floor}, ["You", "Them"], 0, "Round 3", 40)
	var start: Dictionary = fixture["start"]
	screen._play_event(start, false)
	return screen


func _advance(screen: Screen, seconds: float) -> void:
	for tick: int in ceili(seconds * 120.0):
		screen.advance_playback(1.0 / 120.0)


func _travel(parent: Node) -> RingTravel:
	for child: Node in parent.get_children():
		if child is RingTravel:
			return child as RingTravel
	return null


func test_both_core_emitters_record_exact_remaining_and_merged_ring_cohorts() -> void:
	for pass3: bool in [false, true]:
		var fixture: Dictionary = _fixture(pass3)
		var event: Dictionary = fixture["dance"]
		assert_false(event.is_empty(), "a real Reel-Mistress produced the event")
		var from: Dictionary = event["from_ring"]
		var to: Dictionary = event["to_ring"]
		assert_eq(CoreUtil.to_int(event["moved_count"]), 2 if pass3 else 1)
		assert_eq(CoreUtil.to_int(from["count"]), 3 if pass3 else 0)
		assert_eq(CoreUtil.to_int(to["count"]), 3 if pass3 else 2)
		assert_eq(CoreUtil.to_int(from["attack"]), 8 if pass3 else 0)
		assert_eq(CoreUtil.to_int(to["attack"]), 8 if pass3 else 7)
		var input_effects: Array = fixture["input_effects"]
		var original_effects: Array = fixture["original_effects"]
		assert_eq(input_effects, original_effects, "combat left recruit floor input intact")


func test_ring_dots_travel_between_actual_pockets_and_land_with_no_labels_at_each_speed() -> void:
	var fixture: Dictionary = _fixture()
	for speed: float in [1.0, 4.0]:
		Settings.reduce_motion = false
		var screen: Screen = _screen(fixture)
		screen.set_speed(speed)
		var before_input: Array = screen.floor_marks.duplicate(true)
		var event: Dictionary = fixture["dance"]
		screen._play_event(event, true)
		var ring: RingTravel = _travel(screen._overlay)
		assert_not_null(ring)
		if ring == null:
			continue
		var board: BoardView = screen.board_for_side(0)
		var transform: Transform2D = (
			screen._overlay.get_global_transform().affine_inverse() * board.get_global_transform()
		)
		var origin: Vector2 = board.slot_position(0)
		var destination: Vector2 = board.slot_position(1)
		assert_eq(ring.from_rect, transform * Rect2(origin, board.pocket).grow(-1.0))
		assert_eq(ring.to_rect, transform * Rect2(destination, board.pocket).grow(-1.0))
		var first: PackedVector2Array = ring.dot_points()
		_advance(screen, 0.15 / speed)
		assert_ne(ring.dot_points(), first, "actual dots leave the source frame")
		assert_eq(Capture.text_nodes(ring).size(), 0, "the travel has no labels")
		assert_lte(CoreUtil.to_float(ring.get_meta("ring_duration")), 0.4)
		_advance(screen, 0.2 / speed)
		await get_tree().process_frame
		assert_false(is_instance_valid(ring), "no moving or standing travel remains")
		var floor_state: Array = Lanes.floor_state(screen)
		var row: Array = floor_state[0]
		var source_mark: Dictionary = row[0]
		var target_mark: Dictionary = row[1]
		assert_eq(CoreUtil.to_int(source_mark["ring_count"]), 3)
		assert_eq(CoreUtil.to_int(target_mark["ring_count"]), 3)
		assert_eq(screen.floor_marks, before_input, "UI updates copied state only")


func test_reduce_motion_flashes_source_then_destination_without_intermediate_travel() -> void:
	Settings.reduce_motion = true
	var fixture: Dictionary = _fixture()
	var screen: Screen = _screen(fixture)
	var event: Dictionary = fixture["dance"]
	screen._play_event(event, true)
	var ring: RingTravel = _travel(screen._overlay)
	assert_not_null(ring)
	if ring == null:
		return
	var source_points: PackedVector2Array = ring.dot_points()
	_advance(screen, 0.1)
	assert_eq(ring.dot_points(), source_points, "source flash stays still")
	_advance(screen, 0.1)
	var destination_points: PackedVector2Array = ring.dot_points()
	assert_ne(destination_points, source_points)
	assert_eq(destination_points[0], ring.to_rect.position, "destination flash has no route")
	_advance(screen, 0.15)
	await get_tree().process_frame
	assert_false(is_instance_valid(ring))


func test_restart_restores_initial_floor_and_skip_finishes_on_recorded_floor_without_motion(
) -> void:
	var fixture: Dictionary = _fixture()
	var screen: Screen = _screen(fixture)
	var start: Dictionary = fixture["start"]
	var event: Dictionary = fixture["dance"]
	screen._play_event(event, true)
	screen.restart()
	var reset_marks: Control = screen.board_for_side(0).get("_marks")
	var reset_row: Array = reset_marks.get("marks")
	var reset_source: Dictionary = reset_row[0]
	assert_eq(
		CoreUtil.to_int(reset_source["ring_count"]),
		5,
		"restart restores the drawn source pile immediately"
	)
	await get_tree().process_frame
	assert_null(_travel(screen._overlay), "restart frees its old movement before replay")
	screen._play_event(start, false)
	var initial_floor: Array = fixture["floor"]
	assert_eq(Lanes.floor_state(screen), initial_floor)
	screen.events = [start, event]
	screen.next_index = 0
	screen.skip_to_end()
	assert_null(_travel(screen._overlay), "skip creates no travelling dots")
	var floor_state: Array = Lanes.floor_state(screen)
	var row: Array = floor_state[0]
	var target: Dictionary = row[1]
	assert_eq(CoreUtil.to_int(target["ring_count"]), 3)
	assert_eq(CoreUtil.to_int(target["slot_attack"]), 8)
	assert_eq(screen.floor_marks, initial_floor)
	await get_tree().process_frame


func test_recruit_exact_count_transfer_uses_travel_while_plain_addition_still_sprouts() -> void:
	var board: BoardView = BoardView.new()
	add_child_autofree(board)
	board.configure("board", 209, true)
	board.set_marks([{"has_ring": true, "ring_count": 2, "ring": "+5/+5"}, {}, {}, {}, {}, {}, {}])
	board.set_marks([{}, {"has_ring": true, "ring_count": 2, "ring": "+5/+5"}, {}, {}, {}, {}, {}])
	var marks: Control = board.get("_marks")
	assert_not_null(_travel(marks))
	var fresh: BoardView = BoardView.new()
	add_child_autofree(fresh)
	fresh.configure("board", 209, true)
	fresh.set_marks([{}, {}, {}, {}, {}, {}, {}])
	fresh.set_marks([{"has_ring": true, "ring_count": 2, "ring": "+5/+5"}, {}, {}, {}, {}, {}, {}])
	var fresh_marks: Control = fresh.get("_marks")
	assert_null(_travel(fresh_marks), "an addition grows in place rather than inventing a source")
	var reveal: Dictionary = fresh_marks.get("_ring_reveal")
	assert_eq(CoreUtil.to_float(reveal[0]), 0.0)
	await get_tree().process_frame
