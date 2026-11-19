extends GutTest
## The fight screen draws fight.html's moments from view states, and FightReplay turns the rules
## core's fight log into steps that end on the core's own result.

@warning_ignore_start("unsafe_call_argument", "unsafe_cast")

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")

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
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
	return _screen


func _stage() -> Control:
	return _screen.get_node("Frame/Stage") as Control


## Children of the stage's three layers (Back, Cards, Front) whose names start with prefix.
func _count(prefix: String) -> int:
	var n: int = 0
	for layer: Node in _stage().get_children():
		for child: Node in layer.get_children():
			if String(child.name).begins_with(prefix) and not child.is_queued_for_deletion():
				n += 1
	return n


func _find(node_name: String) -> Node:
	for layer: Node in _stage().get_children():
		var found: Node = layer.get_node_or_null(node_name)
		if found != null:
			return found
	return null


func test_start_shows_both_boards_whole() -> void:
	_make(GlassScreen.load_state(START))
	assert_eq(_count("Unit_0_"), 6, "your six units")
	assert_eq(_count("Unit_1_"), 7, "their seven")
	assert_not_null(_find("Slot_0_5"), "your Ring slot")
	assert_eq(_count("Hit_"), 0)
	var stag: GlassCard = _find("Unit_0_0")
	assert_false(stag.hurt)


func test_mid_lunges_splashes_and_reddens() -> void:
	var state: Dictionary = GlassScreen.load_state(MID)
	_make(state)
	assert_eq(_count("Unit_0_"), 5, "your Hare has died: its slot is empty")
	assert_eq(_count("Unit_1_"), 6)
	assert_eq(_count("Hit_"), 2)
	var badger: GlassCard = _find("Unit_0_1")
	var moment: Dictionary = state["moment"]
	assert_eq(badger.position, _screen.lunge_xy(moment["lunge"]), "the Badger lunges")
	assert_true(badger.hurt, "7 of 12 Health is red")
	assert_true((_find("Unit_1_1") as GlassCard).hurt)


func test_lunge_rises_towards_the_target() -> void:
	_make(GlassScreen.load_state(MID))
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
			"type": "mark_gained",
			"side": 0,
			"slot": 2,
			"uid": 0,
			"counters": [{"id": "mark", "value": 2}]
		},
		{"type": "aura", "uid": 0, "attack": 5},
		{"type": "something_new"},
		{"type": "damage", "uid": 99, "amount": 1, "health": 0},
		{"type": "death", "uid": 99},
		{},
		"not an event",
	]
	var base: Dictionary = {"display": {"mark": {"name": "marks", "reminder": ""}}}
	var replay: FightReplay = FightReplay.build(base, events, {})
	var row: Array = replay.boards[0]
	var unit: Dictionary = row[2]
	assert_eq(unit["attack"], 5, "an event carrying attack resyncs it")
	assert_eq((unit["counters"] as Array).size(), 1, "counters come through")
	_make(replay.steps[replay.steps.size() - 1]["state"])
	assert_eq(_count("Unit_0_2"), 1)
	var card: GlassCard = _find("Unit_0_2")
	assert_not_null(card.get_node_or_null("Pill_0"), "a counter shows as a pill")


func test_playback_skips_to_the_result() -> void:
	var game: GameSession = CoreKit.session(7)
	var spec: Array = StandIn.FIGHTS[2]
	var spec_a: Dictionary = spec[0]
	var spec_b: Dictionary = spec[1]
	var combat: Combat = CoreKit.fight(
		game, CoreKit.board(game, spec_a), CoreKit.board(game, spec_b), 11
	)
	var replay: FightReplay = FightReplay.build(
		GlassScreen.load_state(START), combat.events, StandIn.catalog(game), 7
	)
	_make(replay.steps[0]["state"])
	watch_signals(_screen)
	_screen.play(replay)
	assert_true(_screen.is_playing())
	_screen.skip()
	_screen._process(10.0)
	assert_signal_emitted(_screen, "playback_finished")
	assert_false(_screen.is_playing())
	assert_not_null(_find("Result"))
	assert_not_null(_find("ResultHit"), "the loser's damage")


func test_the_hover_detail_lasts_through_playback_steps() -> void:
	var state: Dictionary = GlassScreen.load_state(START)
	_make(state)
	var card: Control = _find("Unit_0_0")
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	var frame: Control = _screen.get_node("Frame")
	motion.position = frame.position + card.position + card.size / 2.0
	_screen._gui_input(motion)
	assert_true((_find("Tip") as Control).visible)
	var next: Dictionary = state.duplicate(true)
	var boards: Array = next["boards"]
	var mine: Array = boards[0]
	var stag: Dictionary = mine[0]
	stag["health"] = 3
	_screen.show_state(next)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	assert_true((_find("Tip") as Control).visible, "still showing after the step")
	assert_same(_find("Unit_0_0"), _screen.node_for("board", 0), "drawn on the kept card")


# ---- the replay's moments (items 8 to 13) ----


func _two_units() -> Array:
	var a: Dictionary = {"uid": 1, "id": "a", "side": 0, "slot": 0, "attack": 2, "health": 3}
	var b: Dictionary = {"uid": 2, "id": "b", "side": 1, "slot": 0, "attack": 2, "health": 3}
	return [{"type": "combat_start", "boards": [[a], [b]]}]


func _moments(replay: FightReplay) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for step: Dictionary in replay.steps:
		var view: Dictionary = step["state"]
		out.append(view["moment"])
	return out


func test_one_attack_keeps_its_lunge_through_triggers_and_destroy() -> void:
	var events: Array = _two_units()
	(
		events
		. append_array(
			[
				{
					"type": "attack",
					"side": 0,
					"slot": 0,
					"uid": 1,
					"target_side": 1,
					"target_slot": 0
				},
				{"type": "damage", "uid": 2, "amount": 2, "health": 1, "source_uid": 1},
				{"type": "trigger", "side": 0, "slot": 0, "uid": 1, "mechanic": "venomous"},
				{"type": "destroy", "uid": 2, "source_uid": 1},
				{"type": "death", "side": 1, "slot": 0, "uid": 2},
			]
		)
	)
	var moments: Array[Dictionary] = _moments(FightReplay.build({}, events, {}))
	# start, lunge, hit, trigger, destroy, death
	assert_eq(moments.size(), 6)
	for k: int in range(1, 5):
		assert_true(moments[k].has("lunge"), "step %d still lunging" % k)
	assert_eq(moments[3]["trigger"], {"side": 0, "slot": 0}, "the venomous unit glows")
	assert_eq(moments[4]["splashes"], [{"side": 1, "slot": 0, "amount": 0}], "destroy drawn")
	assert_false(moments[5].has("lunge"), "home once the dead are gone")


func test_a_new_lunge_starts_from_rest_and_unchanging_events_make_no_step() -> void:
	var events: Array = _two_units()
	var hit: Dictionary = {"type": "attack", "side": 0, "slot": 0, "uid": 1}
	hit.merge({"target_side": 1, "target_slot": 0})
	var back: Dictionary = {"type": "attack", "side": 1, "slot": 0, "uid": 2}
	back.merge({"target_side": 0, "target_slot": 0})
	events.append_array([hit, {"type": "pass", "side": 0}, {"type": "gold", "side": 0}, back])
	var moments: Array[Dictionary] = _moments(FightReplay.build({}, events, {}))
	# start, lunge, home, lunge: the pass and gold change nothing shown
	assert_eq(moments.size(), 4)
	assert_false(moments[2].has("lunge"))


func test_simultaneous_stats_share_a_step() -> void:
	var events: Array = _two_units()
	(
		events
		. append_array(
			[
				{
					"type": "stats",
					"uid": 1,
					"id": "a",
					"side": 0,
					"slot": 0,
					"attack": 4,
					"health": 3
				},
				{
					"type": "stats",
					"uid": 2,
					"id": "b",
					"side": 1,
					"slot": 0,
					"attack": 4,
					"health": 3
				},
			]
		)
	)
	var replay: FightReplay = FightReplay.build({}, events, {})
	assert_eq(replay.steps.size(), 2, "start, then both changes at once")


func test_a_reborn_unit_comes_back_in_its_slot() -> void:
	var events: Array = _two_units()
	(
		events
		. append_array(
			[
				{"type": "death", "side": 0, "slot": 0, "uid": 1},
				{"type": "return", "side": 0, "slot": 0, "uid": 9, "from_uid": 1, "health": 1},
			]
		)
	)
	var replay: FightReplay = FightReplay.build({}, events, {})
	assert_eq(replay.summary(0), [{"slot": 0, "uid": 9, "attack": 2, "health": 1}])


func test_the_result_takes_the_damage_off_the_losers_health() -> void:
	var base: Dictionary = GlassScreen.load_state(START)
	var events: Array = _two_units()
	events.append({"type": "combat_end", "winner": 1})
	var replay: FightReplay = FightReplay.build(base, events, {}, 5)
	var view: Dictionary = replay.steps[replay.steps.size() - 1]["state"]
	assert_eq(GlassPieces.as_int(view["health"]), GlassPieces.as_int(base["health"]) - 5)
	var players: Array = view["players"]
	for value: Variant in players:
		var player: Dictionary = value
		if GlassPieces.as_bool(player.get("you", false)):
			assert_eq(GlassPieces.as_int(player["health"]), GlassPieces.as_int(base["health"]) - 5)
	_make(view)
	var badge: Control = _find("HeroHealth")
	assert_not_null(badge)


func test_only_the_visible_screen_takes_keys() -> void:
	var recruit: RecruitScreen = (
		preload("res://src/screens/recruit/recruit_screen.tscn").instantiate()
	)
	recruit.state = GlassScreen.load_state("res://tests/screens/fixtures/recruit_mockup.json")
	add_child_autofree(recruit)
	assert_eq(SlotChecks.check(recruit), PackedStringArray(), "initial slot rows")
	_make(GlassScreen.load_state(START))
	_screen.visible = false
	var tab: InputEventKey = InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	_screen._unhandled_key_input(tab)
	recruit._unhandled_key_input(tab)
	assert_false(_screen.show_leaderboard, "the hidden fight screen ignores Tab")
	assert_true(recruit.show_leaderboard, "the recruit screen showing takes it")


func test_a_second_skip_does_nothing() -> void:
	var events: Array = _two_units()
	events.append({"type": "combat_end", "winner": 0})
	var replay: FightReplay = FightReplay.build(GlassScreen.load_state(START), events, {}, 3)
	_make(replay.steps[0]["state"])
	watch_signals(_screen)
	_screen.play(replay)
	_screen.skip()
	_screen._process(1.0)
	_screen.skip()
	_screen._process(1.0)
	assert_signal_emitted(
		_screen, "playback_finished", "the result's hold ran out despite the skip"
	)


func test_your_heap_chip_follows_the_fight() -> void:
	var base: Dictionary = {
		"you_side": 1,
		"counters": [{"id": "compost", "value": 2, "entries": []}],
		"boards": [[], []],
	}
	var events: Array = [
		{"type": "combat_start", "boards": [[], []]},
		{"type": "heap_add", "side": 0, "heap": "compost", "id": "pip", "size": 9},
		{"type": "heap_add", "side": 1, "heap": "compost", "id": "pip", "size": 3},
		{"type": "combat_end", "winner": -1},
	]
	var replay: FightReplay = FightReplay.build(base, events, {"pip": {"name": "Pip", "tier": 1}})
	var last: Dictionary = replay.steps[replay.steps.size() - 1]["state"]
	var chip: Dictionary = (last["counters"] as Array)[0]
	assert_eq(int(chip["value"]), 3, "your side's add, not theirs")
	var entries: Array = chip["entries"]
	assert_eq(entries.size(), 1)
	assert_eq(str((entries[0] as Dictionary)["name"]), "Pip")


func test_a_new_fight_starts_from_whole_cards() -> void:
	var events: Array = _two_units()
	events.append({"type": "combat_end", "winner": 0})
	var replay: FightReplay = FightReplay.build(GlassScreen.load_state(START), events, {}, 3)
	_make(replay.steps[0]["state"])
	_screen.play(replay)
	var cards: int = _screen._keeper.layer.get_child_count()
	_screen.skip()
	_screen._process(10.0)
	_screen.play(replay)
	assert_eq(
		_screen._keeper.layer.get_child_count(), cards, "no card of the last fight is left over"
	)
	for node: Node in _screen._keeper.layer.get_children():
		var card: Control = node as Control
		assert_eq(card.modulate.a, 1.0, "%s shows whole" % card.name)


func test_uses_left_show_like_counters_and_follow_the_fight() -> void:
	var events: Array = _two_units()
	var start: Dictionary = events[0]
	var boards: Array = start["boards"]
	var mine: Array = boards[0]
	var first: Dictionary = mine[0]
	first["uses"] = {"privates_left": 3}
	events.append(
		{"type": "uses", "side": 0, "slot": 0, "uid": 1, "key": "privates_left", "left": 2}
	)
	events.append({"type": "combat_end", "winner": 0})
	var replay: FightReplay = FightReplay.build(GlassScreen.load_state(START), events, {}, 3)
	var values: Array[int] = []
	for step: Dictionary in replay.steps:
		var view: Dictionary = step["state"]
		var sides: Array = view["boards"]
		var row: Array = sides[0]
		var unit: Dictionary = row[0] if not row.is_empty() and row[0] is Dictionary else {}
		for counter: Variant in unit.get("counters", []):
			var held: Dictionary = counter
			if str(held["id"]) == "privates_left":
				var value: int = held["value"]
				if values.is_empty() or values[-1] != value:
					values.append(value)
	assert_eq(values, [3, 2] as Array[int])


# ---- what a player sees of a blocked hit, a slot doubling and a mechanic given mid-fight ----


func test_a_blocked_hit_splashes_a_zero() -> void:
	var events: Array = _two_units()
	events.append(
		{"type": "prevented", "side": 1, "slot": 0, "uid": 2, "amount": 2, "reason": "absorbed"}
	)
	var replay: FightReplay = FightReplay.build(GlassScreen.load_state(START), events, {})
	var last: Dictionary = replay.steps[replay.steps.size() - 1]["state"]
	var moment: Dictionary = last["moment"]
	assert_eq(moment["splashes"], [{"side": 1, "slot": 0, "amount": 0, "blocked": true}])
	_make(last)
	var hit: Node = _find("Hit_0")
	var words: Array[String] = []
	for text: Node in hit.find_children("*", "GlassText", true, false):
		words.append((text as GlassText).words)
	assert_eq(words, ["0"] as Array[String], "a 0 on the burst")


func test_a_slot_attack_multiplier_doubles_its_displayed_bonus() -> void:
	var events: Array = _two_units()
	events.append({"type": "slot_percent", "side": 0, "percent": 200, "source_uid": 1})
	var base: Dictionary = GlassScreen.load_state(START)
	var slots: Array = base["slots"]
	var mine: Array = slots[0]
	mine[0] = {"attack": 2, "health": 1, "keywords": [], "label": ""}
	var replay: FightReplay = FightReplay.build(base, events, {})
	var last: Dictionary = replay.steps[replay.steps.size() - 1]["state"]
	_make(last)
	var row: Array = (last["slots"] as Array)[0]
	assert_eq(str(_screen.slot_info(row[0])["buff"]), "+4/+1", "Attack doubled, Health not")


func test_a_mechanic_given_mid_fight_adds_to_the_units_number() -> void:
	var events: Array = _two_units()
	var start: Dictionary = events[0]
	var boards: Array = start["boards"]
	var mine: Array = boards[0]
	var first: Dictionary = mine[0]
	first["totals"] = {"badger_fury": {"fury": 1}}
	(
		events
		. append(
			{
				"type": "effect",
				"side": 0,
				"slot": 0,
				"uid": 1,
				"mechanic": "badger_fury",
				"params": {"fury": 2},
				"permanent": false,
			}
		)
	)
	var replay: FightReplay = FightReplay.build({}, events, {})
	var row: Array = replay.boards[0]
	var unit: Dictionary = row[0]
	assert_eq(unit["amounts"], {"badger_fury": 3}, "1 of its own and 2 given")
	assert_true((unit["mechanics"] as Array).has("badger_fury"))
