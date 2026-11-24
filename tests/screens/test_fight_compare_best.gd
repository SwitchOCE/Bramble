extends GutTest
## The `best` treatment of the comparison fight (tests/screens/feel/fight_compare/best.gd): its
## schedule keeps best.md's numbers for a plain attack, and every contested branch's option
## builds a whole fight that ends on the core's board. Exploratory; nothing here is the game.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const Timeline := preload("res://tests/screens/feel/fight_compare/best_timeline.gd")
const SCENE: PackedScene = preload("res://tests/screens/feel/fight_compare/fight_compare.tscn")

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_a_plain_attack_keeps_the_proposals_numbers() -> void:
	var plan: Dictionary = _plan({})
	var attacks: Array = plan["attacks"]
	var first: Dictionary = attacks[0]
	assert_eq(_i(first["lift"]), Timeline.REST, "lifts after the 30 f rest")
	assert_eq(_i(first["lift_frames"]), 10, "10 f lift")
	assert_eq(_i(first["hold_frames"]), 16, "16 f hold")
	assert_eq(_i(first["strike_frames"]), 7, "7 f strike straight across")
	assert_eq(_i(first["contact"]), Timeline.REST + 33, "contact 33 f after the lift starts")
	assert_almost_eq(_f(first["stop_gap_h"]), 0.62, 0.001, "today's near stop")
	assert_eq(_i(first["next_lift"]), _i(first["contact"]) + 28, "next lifts at C+28")
	assert_eq(_i(first["home"]), _i(first["contact"]) + 12, "returns from C+1, home at C+12")
	assert_eq(_i(first["queue_from"]), _i(first["contact"]) + 14, "after the hit from C+14")
	var far: Dictionary = attacks[1]
	assert_eq(_i(far["queue_from"]), _i(far["home"]), "a far return: after the hit once it is home")
	var thorns_kill: Dictionary = attacks[4]
	var no_strike: bool = thorns_kill["no_strike"]
	assert_true(no_strike, "(d) Thorns kills the attacker: no strike")


func test_every_option_plays_the_whole_fight() -> void:
	var sets: Array[Dictionary] = [{}]
	for branch: String in ["CB1", "CB2", "CB5", "CB6", "CB7", "CB8"]:
		var table: Dictionary = _table(branch)
		for option: String in table:
			sets.append({branch: option})
	for option: String in Timeline.CURVES:
		sets.append({"CB3": option})
	for option: String in Timeline.BEFORE_MODES:
		sets.append({"CB4": option})
	for chosen: Dictionary in sets:
		var plan: Dictionary = _plan(chosen)
		var attacks: Array = plan["attacks"]
		var notes: Array = plan["notes"]
		assert_eq(attacks.size(), 7, "%s: seven attacks" % str(chosen))
		assert_eq(notes, [], "%s: every change shows in the log's order" % str(chosen))


func test_only_best_combos_speed_up() -> void:
	var sped: Array[bool] = []
	for option: String in ["best", "bg"]:
		var attacks: Array = _plan({"CB7": option})["attacks"]
		var chain: Dictionary = attacks[5]
		var on: bool = chain["speedup"]
		sped.append(on)
	assert_eq(sped, [true, false], "rule 7 speeds up (e)'s chain for best only")


func test_after_keeps_the_numbers_true() -> void:
	var combat: Combat = Compare.fight(_content)
	var played: Array = Timeline.reorder(combat.events, {"CB4": "after"})
	var healths: Array[int] = []
	var attacks: int = 0
	for value: Variant in played:
		var event: Dictionary = value
		if str(event.get("type", "")) == "attack":
			attacks += 1
		if attacks == 3 and str(event.get("type", "")) == "damage" and _i(event["uid"]) == 2:
			healths.append(_i(event["health"]))
	assert_eq(healths, [3, 1], "(c): the exchange takes Health 5 to 3, then Thorns 3 to 1")


func test_cb7_fight_lands_ten_hits_as_a_combo() -> void:
	var plan: Dictionary = _plan({"CB7": "best_no7"}, "cb7")
	var combos: Array = plan["combos"]
	assert_eq(combos.size(), 1, "one combo")
	var combo: Dictionary = combos[0]
	var lands: Array = combo["lands"]
	assert_eq(lands.size(), 10, "ten Gleaner hits")
	var ninth: int = _i(lands[8])
	var tenth: int = _i(lands[9])
	assert_eq(ninth, tenth, "from the 9th, the rest land together")


func test_cb8_staggers_the_six_deaths_in_order_with_their_gaps() -> void:
	var together: Array = _plan({})["attacks"][5]["falls"]
	var first: int = _i(together[1]["frame"])
	var want: Dictionary = {
		"b": [0, 4, 8, 12, 16, 20],
		"c": [0, 10, 17, 22, 26, 30],
		"d": [0, 12, 24, 36, 48, 60],
	}
	for option: String in want:
		var plan: Dictionary = _plan({"CB8": option})
		var staggers: Array = plan["staggers"]
		assert_eq(staggers.size(), 1, "%s: one group of deaths at once" % option)
		var group: Dictionary = staggers[0]
		var keys: Array = []
		var starts: Array = []
		for value: Variant in group["falls"]:
			var fall: Dictionary = value
			keys.append(fall["key"])
			starts.append(_i(fall["frame"]) - first)
		# rulebook 9.7.3: the attacker's side has no deaths here; yours in reading order F1-F3, B1-B3
		assert_eq(keys, ["u1", "u2", "u11", "u5", "u6", "u7"], "%s: reading order" % option)
		var wanted: Array = want[option]
		assert_eq(starts, wanted, "%s: fall starts after the first" % option)
		var lands: Array = []
		for value: Variant in group["lands"]:
			lands.append(_i(value) - first)
		var after: Array = []
		for start: Variant in want[option]:
			after.append(_i(start) + Timeline.STAGGER_LAND)
		assert_eq(lands, after, "%s: each gain as its own fall ends" % option)
	for value: Variant in together.slice(1):
		var fall: Dictionary = value
		assert_eq(_i(fall["frame"]), first, "a: all six fall together")


func test_cb8_caps_the_spread_whatever_the_count() -> void:
	var b: Array[int] = Timeline.stagger_starts(10, Timeline.STAGGERS["b"])
	var c: Array[int] = Timeline.stagger_starts(10, Timeline.STAGGERS["c"])
	var d: Array[int] = Timeline.stagger_starts(10, Timeline.STAGGERS["d"])
	assert_eq(_i(b.back()), 24, "b: 10 deaths within 24 f")
	assert_eq(_i(c.back()), 30, "c: 10 deaths within 30 f")
	assert_eq(_i(d.back()), 108, "d: no cap")
	assert_eq(Timeline.stagger_starts(2, Timeline.STAGGERS["c"]), [0, 10], "c: two deaths 10 apart")


func test_cb8_changes_only_the_order_shown() -> void:
	var events: Array = Compare.fight(_content).events
	var played: Array = Timeline.reorder(events, {"CB8": "c"})
	assert_eq(played.size(), events.size(), "the same events")
	assert_eq(_last_buff(played, 4), _last_buff(events, 4), "Old Brock ends as the log says")
	# a log with u2 dying before u1: shown in reading order, each gain staying with its own death
	var swapped: Array = events.duplicate()
	var at: int = -1
	for i: int in swapped.size():
		if str(swapped[i]["type"]) == "death" and _i(swapped[i]["uid"]) == 1:
			at = i
	var one: Dictionary = swapped[at]
	swapped[at] = swapped[at + 1]
	swapped[at + 1] = one
	var shown: Array = Timeline.reorder(swapped, {"CB8": "c"})
	var order: Array = []
	var gains: Array = []
	for value: Variant in shown:
		var event: Dictionary = value
		if event.has("stagger_at") and str(event["type"]) == "death":
			order.append(_i(event["uid"]))
		if event.has("stagger_at") and str(event["type"]) == "buff":
			gains.append([_i(event["attack"]), _i(event["health"])])
	assert_eq(order, [1, 2, 11, 5, 6, 7], "reading order, whatever the log's")
	# Old Brock is 10/9 before the gains. The swapped log's first gain (+2/+5) is u2's, its second
	# (+3/+5) u1's: u1's shows first, then u2's, recounted
	var first_gain: Array = gains[0]
	var second_gain: Array = gains[1]
	var last_gain: Array = gains.back()
	assert_eq(first_gain, [13, 14], "u1's gain first: 10/9 + 3/5")
	assert_eq(second_gain, [15, 19], "then u2's: + 2/5")
	assert_eq(last_gain, _last_buff(events, 4), "the last as the log's")


func test_best_plays_on_the_fight_screen() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene.call("start", "best", {"CB7": "best_xn"})
	var screen: FightScreen = scene.get("screen")
	assert_true(screen.is_playing(), "playing")
	for i: int in 3:
		await get_tree().process_frame
	assert_true(screen.is_playing(), "still playing")


func _plan(chosen: Dictionary, which: String = "") -> Dictionary:
	var combat: Combat = Compare.fight_named(_content, which)
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	var best: RefCounted = Treatments.make("best")
	best.call("configure", chosen)
	var replay: FightReplay = best.call("make_replay", base, combat.events, {}, Compare.DAMAGE)
	assert_gt(replay.steps.size(), 10, "steps")
	var plan: Dictionary = best.call("plan")
	return plan


static func _last_buff(events: Array, uid: int) -> Array:
	var out: Array = []
	for value: Variant in events:
		var event: Dictionary = value
		if str(event.get("type", "")) == "buff" and _i(event["uid"]) == uid:
			out = [_i(event["attack"]), _i(event["health"])]
	return out


static func _table(branch: String) -> Dictionary:
	var tables: Dictionary = {
		"CB1": Timeline.WINDUPS,
		"CB2": Timeline.STOPS,
		"CB5": Timeline.FALLS,
		"CB6": Timeline.LIFTS,
		"CB7": Timeline.COMBOS,
		"CB8": Timeline.STAGGERS,
	}
	var table: Dictionary = tables[branch]
	return table


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
