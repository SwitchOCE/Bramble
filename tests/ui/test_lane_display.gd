extends GutTest

const Data := preload("res://src/ui/view_data.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const States := preload("res://tests/ui/lane_states.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const PoachedBadge := preload("res://src/ui/widgets/poached_badge.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")


func test_forecast_reads_mire_spread_chorus_and_reading_order() -> void:
	var own: Array = [
		States.unit("bridge_toad", 1),
		States.unit("prima_donna", 2),
		null,
		null,
		States.unit("wick", 3),
		States.unit("natterjack_chorus", 4),
		null
	]
	var forecast: Dictionary = LaneProjection.new().forecast([own, []])
	var patches: Array = forecast["patches"]
	assert_eq(patches.size(), 4, "F1-F3 and the Chorus neighbour B1; empty enemy slots still bog")
	assert_eq(Data.as_int(patches[0]["from_slot"]), 0, "the first maker keeps F1")
	assert_eq(Data.as_int(patches[3]["slot"]), 4, "a loaned Mire belongs to its borrower")
	assert_eq(Data.as_int(patches[3]["from_slot"]), 4)


func test_own_quarry_beats_brock_and_earlier_lender_beats_laird() -> void:
	var own: Array = [
		States.unit("young_brock", 1),
		States.unit("little_nip", 2),
		States.unit("wick", 3),
		States.unit("laird_of_sett", 4),
		null,
		States.unit("old_brock", 5),
		null
	]
	var enemy: Array = [
		States.unit("field_vole", 101),
		States.unit("mrs_sorrel", 102),
		States.unit("sleeping_partner", 103),
		States.unit("wick", 104),
		null,
		States.unit("mother_goose", 105),
		null
	]
	var marks: Array = LaneProjection.new().forecast([own, enemy])["quarries"]
	var mine: Dictionary = {}
	for mark: Dictionary in marks:
		if Data.as_int(mark["from_side"]) == 0:
			mine[Data.as_int(mark["from_slot"])] = Data.as_int(mark["slot"])
	assert_eq(Data.as_int(mine[1]), 1, "Nip keeps its own quarry")
	assert_eq(Data.as_int(mine[2]), 2, "the Laird reads before Old Brock and loans its own across")


func test_playback_patch_survives_death_and_quarry_follows_movement() -> void:
	var model: CombatModel = CombatModel.new()
	for event: Dictionary in States.fight(true)["events"]:
		model.apply(event)
	var projected: Dictionary = LaneProjection.playback(model)
	assert_eq(Data.a(projected, "patches").size(), 2)
	assert_false(
		Data.b(Data.entry(Data.a(projected, "patches"), 0), "live"),
		"mud stays after its maker dies"
	)
	assert_eq(
		Data.as_int(projected["quarries"][0]["slot"]), 3, "the paw moved from F2 to F4 with Sorrel"
	)
	model.apply({"type": "quarry_lost", "hunter": 2, "quarry": 102})
	assert_eq(
		Data.a(LaneProjection.playback(model), "quarries").size(),
		1,
		"losing the animal clears only that mark"
	)


func test_a_mire_maker_changing_sides_breaks_its_lock_permanently() -> void:
	var model: CombatModel = CombatModel.new()
	var events: Array = Data.a(States.fight(), "events")
	for event: Dictionary in events.slice(0, 4):
		model.apply(event)
	model.apply({"type": "relocate", "uid": 1, "side": 1, "slot": 6})
	model.apply({"type": "relocate", "uid": 1, "side": 0, "slot": 0})
	var patch: Dictionary = Data.entry(Data.a(LaneProjection.playback(model), "patches"), 0)
	assert_false(Data.b(patch, "live"), "the returning maker does not restore a broken lock")
	assert_eq(Data.a(LaneProjection.playback(model), "patches").size(), 2)


func test_fight_screen_keeps_marks_when_skipping_and_clears_them_on_restart() -> void:
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	screen.setup(States.fight(true), PackedStringArray(["You", "Opponent"]), 0, "Round 1")
	screen.skip_to_end()
	assert_eq(Data.a(screen._lanes.bindings, "patches").size(), 2)
	assert_eq(screen._lanes.pack.size(), 2, "the joint exchange brackets leader and joiner")
	screen.restart()
	await wait_process_frames(1)
	assert_true(Data.a(screen._lanes.bindings, "patches").is_empty())
	assert_true(screen._lanes.pack.is_empty())


func test_poach_claim_and_reserved_copy_have_different_feedback() -> void:
	var combat_log: CombatLog = CombatLog.new()
	var model: CombatModel = CombatModel.new()
	model.apply(Data.entry(Data.a(States.fight(), "events"), 0))
	var claim: String = combat_log.describe({"type": "poach", "hunter": 2, "quarry": 102}, model)
	assert_string_contains(claim, "if available")
	assert_string_contains(
		RecruitView.event_note({"type": "poached", "name": "Mrs Sorrel"}), "from your last opponent"
	)
	var view: Dictionary = RecruitView.full_view(
		"shop", {"poached": true, "cost": 2, "text": "Quarry."}, {}
	)
	assert_string_contains(str(view["text"]), "Costs 2 gold")


func test_pack_pounce_and_counter_feedback_names_the_right_action() -> void:
	var model: CombatModel = CombatModel.new()
	model.apply(Data.entry(Data.a(States.fight(), "events"), 0))
	var combat_log: CombatLog = CombatLog.new()
	var pack_line: String = combat_log.describe(
		{"type": "attack", "attacker": 2, "defender": 102, "pack": true, "joiners": [3]}, model
	)
	assert_string_contains(pack_line, "Pack attack")
	assert_string_contains(pack_line, "Wick")
	var pounce: String = combat_log.describe(
		{"type": "immediate_attack", "kind": "pounce", "attacker": 2, "defender": 102}, model
	)
	assert_string_contains(pounce, "pounces on")
	assert_eq(combat_log.last_keyword, "Pounce")
	combat_log.describe(
		{"type": "immediate_attack", "kind": "counter", "attacker": 2, "defender": 102}, model
	)
	assert_eq(combat_log.last_keyword, "", "a Bog counter does not teach Pounce")


func test_phone_scout_projection_uses_the_named_slots_and_keeps_shop_cost_visible() -> void:
	CardView.window_override = Vector2(1688, 780)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(2337, 1080)
	add_child_autofree(viewport)
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	States.recruit(port.get_state())
	var screen: RecruitScreen = RecruitScreen.new()
	viewport.add_child(screen)
	screen.setup(port)
	screen.toggle_scout()
	await wait_process_frames(2)
	var scout_board: BoardView = screen._scout.get("_board")
	for slot: int in 7:
		assert_almost_eq(
			screen._board.slot_global_center(slot).x,
			scout_board.slot_global_center(slot).x,
			1.0,
			"same slot label faces the same column"
		)
	var card: CardView = screen._shop_cards.get_child(0)
	var badge: PoachedBadge = card.get("_poached_badge")
	assert_true(badge.visible)
	assert_eq(badge.cost, 2)
	screen.free()
	CardView.window_override = Vector2.ZERO
