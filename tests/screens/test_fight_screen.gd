extends GutTest
## The fight screen draws fight.html's moments from view states, and FightReplay turns the rules
## core's fight log into steps that end on the core's own result.

@warning_ignore_start("unsafe_call_argument", "unsafe_cast")

const CoreKit := preload("res://tests/core/core_kit.gd")
const StandIn := preload("res://tests/screens/fight_stand_in.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")
const START: String = "res://tests/screens/fixtures/fight_start.json"
const MID: String = "res://tests/screens/fixtures/fight_mid.json"

var _screen: FightScreen


func _make(state: Dictionary) -> FightScreen:
	_screen = SCREEN.instantiate()
	_screen.state = state
	add_child_autofree(_screen)
	return _screen


func _stage() -> Control:
	return _screen.get_node("Frame/Stage") as Control


func _count(prefix: String) -> int:
	var n: int = 0
	for child: Node in _stage().get_children():
		if String(child.name).begins_with(prefix):
			n += 1
	return n


func test_start_shows_both_boards_whole() -> void:
	_make(RecruitScreen.load_state(START))
	assert_eq(_count("Unit_0_"), 6, "your six units")
	assert_eq(_count("Unit_1_"), 7, "their seven")
	assert_not_null(_stage().get_node_or_null("Slot_0_5"), "your Ring slot")
	assert_eq(_count("Hit_"), 0)
	var stag: GlassCard = _stage().get_node("Unit_0_0")
	assert_false(stag.hurt)


func test_mid_lunges_splashes_and_reddens() -> void:
	var state: Dictionary = RecruitScreen.load_state(MID)
	_make(state)
	assert_eq(_count("Unit_0_"), 5, "your Hare has died: its slot is empty")
	assert_eq(_count("Unit_1_"), 6)
	assert_eq(_count("Hit_"), 2)
	var badger: GlassCard = _stage().get_node("Unit_0_1")
	var moment: Dictionary = state["moment"]
	assert_eq(badger.position, _screen.lunge_xy(moment["lunge"]), "the Badger lunges")
	assert_true(badger.hurt, "7 of 12 Health is red")
	assert_true((_stage().get_node("Unit_1_1") as GlassCard).hurt)


func test_lunge_rises_towards_the_target() -> void:
	_make(RecruitScreen.load_state(MID))
	var lunge: Dictionary = {"side": 0, "slot": 1, "target_side": 1, "target_slot": 1}
	assert_lt(_screen.lunge_xy(lunge).y, _screen.unit_xy(0, 1).y)
	var theirs: Dictionary = {"side": 1, "slot": 1, "target_side": 0, "target_slot": 1}
	assert_gt(_screen.lunge_xy(theirs).y, _screen.unit_xy(1, 1).y, "theirs mirrors it down")


func test_each_recorded_fight_replays_to_the_cores_result() -> void:
	for spec: Array in StandIn.FIGHTS:
		var game: GameSession = CoreKit.session(7)
		var spec_a: Dictionary = spec[0]
		var spec_b: Dictionary = spec[1]
		var combat: Combat = CoreKit.fight(
			game, CoreKit.board(game, spec_a), CoreKit.board(game, spec_b), 11
		)
		var replay: FightReplay = FightReplay.build({}, combat.events, StandIn.catalog(game), 7)
		for side: int in 2:
			var core: Array[Dictionary] = []
			for unit: CombatUnit in combat.units(side):
				(
					core
					. append(
						{
							"slot": unit.slot,
							"uid": unit.uid,
							"attack": unit.attack(),
							"health": unit.health(),
						}
					)
				)
			core.sort_custom(
				func(a: Dictionary, b: Dictionary) -> bool: return a["slot"] < b["slot"]
			)
			assert_eq(replay.summary(side), core, "side %d of %s" % [side, spec])
		var last: Dictionary = replay.steps[replay.steps.size() - 1]
		var view: Dictionary = last["state"]
		var moment: Dictionary = view["moment"]
		assert_eq(moment["result"]["winner"], combat.result["winner"])


func test_unknown_and_future_events_do_not_fail() -> void:
	var start: Dictionary = {
		"type": "combat_start",
		"first": 0,
		"boards":
		[
			[
				{
					"uid": 0,
					"id": "x",
					"side": 0,
					"slot": 2,
					"attack": 2,
					"health": 3,
					"golden": false,
					"keywords": []
				}
			],
			[]
		],
	}
	var events: Array = [
		start,
		{
			"type": "medal_gained",
			"side": 0,
			"slot": 2,
			"uid": 0,
			"counters": [{"label": "Medals", "value": 2}]
		},
		{"type": "aura", "uid": 0, "attack": 5},
		{"type": "something_new"},
		{"type": "damage", "uid": 99, "amount": 1, "health": 0},
		{"type": "death", "uid": 99},
		{},
		"not an event",
	]
	var replay: FightReplay = FightReplay.build({}, events, {})
	var row: Array = replay.boards[0]
	var unit: Dictionary = row[2]
	assert_eq(unit["attack"], 5, "an event carrying attack resyncs it")
	assert_eq((unit["counters"] as Array).size(), 1, "counters come through")
	_make(replay.steps[replay.steps.size() - 1]["state"])
	assert_eq(_count("Unit_0_2"), 1)
	var card: GlassCard = _stage().get_node("Unit_0_2")
	assert_not_null(card.get_node_or_null("Pill"), "a counter shows as a pill")


func test_playback_skips_to_the_result() -> void:
	var game: GameSession = CoreKit.session(7)
	var spec: Array = StandIn.FIGHTS[2]
	var spec_a: Dictionary = spec[0]
	var spec_b: Dictionary = spec[1]
	var combat: Combat = CoreKit.fight(
		game, CoreKit.board(game, spec_a), CoreKit.board(game, spec_b), 11
	)
	var replay: FightReplay = FightReplay.build(
		RecruitScreen.load_state(START), combat.events, StandIn.catalog(game), 7
	)
	_make(replay.steps[0]["state"])
	watch_signals(_screen)
	_screen.play(replay)
	assert_true(_screen.is_playing())
	_screen.skip()
	_screen._process(10.0)
	assert_signal_emitted(_screen, "playback_finished")
	assert_false(_screen.is_playing())
	assert_not_null(_stage().get_node_or_null("Result"))
	assert_not_null(_stage().get_node_or_null("ResultHit"), "the loser's damage")
