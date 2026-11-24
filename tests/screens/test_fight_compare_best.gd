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
	for branch: String in ["CB1", "CB2", "CB5", "CB6", "CB7", "CB8", "CB9"]:
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


func test_cb9_aim_turns_the_leading_point_to_the_target_on_galaxys_timing() -> void:
	var timeline: RefCounted = _timeline({"CB9": "aim"})
	var attacks: Array = timeline.get("attacks")
	# (b): Prophet of the Dust, theirs, down-right onto Old Brock: its bottom point leads
	var far: Dictionary = attacks[1]
	var key: String = far["attacker"]
	var c: int = far["contact"]
	var aim: float = far["aim_deg"]
	assert_eq(str(far["lead"]), "bottom", "theirs: the bottom point leads")
	assert_lt(aim, -20.0, "down-right turns the bottom point right (anticlockwise)")
	assert_eq(_i(far["aim_full"]), c - Timeline.AIM_FULL_BEFORE, "full at C-12 (least hold)")
	assert_almost_eq(_turn(timeline, key, c - 12), aim, 0.01, "full at C-12")
	assert_almost_eq(_turn(timeline, key, c), aim * Timeline.AIM_AT_CONTACT, 0.01, "90% at C")
	assert_almost_eq(_turn(timeline, key, c + 25), 0.0, 0.01, "straight by C+25")
	var at_ten: float = _turn(timeline, key, c + 10) / (aim * Timeline.AIM_AT_CONTACT)
	assert_between(at_ten, 0.65, 1.0, "65-100% still turned at C+10 (Galaxy)")
	assert_almost_eq(_turn(timeline, key, _i(far["lift"])), 0.0, 0.01, "straight before the lift")
	var first: float = _turn(timeline, key, _i(far["lift"]) + 1)
	assert_true(absf(first) > 0.5, "turns from the lift's first frame")
	# angle: 95% of the path's
	var path: Vector2 = _path(timeline, far)
	var want: float = 0.95 * rad_to_deg(Vector2(0.0, 1.0).angle_to(path))
	assert_almost_eq(aim, want, 0.05, "95% of the path's angle")
	# (a) straight across, yours: the top leads and it does not turn; no lean either
	var straight: Dictionary = attacks[0]
	assert_eq(str(straight["lead"]), "top", "yours: the top point leads")
	assert_almost_eq(
		_turn(timeline, str(straight["attacker"]), _i(straight["contact"])), 0.0, 0.5, "(a)"
	)
	# Old Brock, yours, up-left: the top point turns left (anticlockwise)
	assert_lt(_f(attacks[6]["aim_deg"]), -10.0, "up-left turns the top point left")


func test_cb9_tip_keystones_and_shortens_and_none_keeps_the_proposal() -> void:
	var timeline: RefCounted = _timeline({"CB9": "tip"})
	var all: Array = timeline.get("attacks")
	var far: Dictionary = all[1]
	var key: String = far["attacker"]
	var c: int = far["contact"]
	var at_c: Dictionary = timeline.call("pose", key, c)
	assert_almost_eq(_f(at_c["length"]), 0.75, 0.001, "0.75 of its length at contact")
	assert_almost_eq(_f(at_c["keystone"]), 0.9, 0.001, "leading edge 10% shorter at contact")
	assert_almost_eq(_f(at_c["lead"]), -1.0, 0.001, "the bottom edge leads")
	var held: Dictionary = timeline.call("pose", key, c - 12)
	assert_almost_eq(_f(held["length"]), 1.0, 0.001, "full length in the hold")
	assert_almost_eq(_f(held["keystone"]), 0.9, 0.001, "keystone full in the hold")
	var back: Dictionary = timeline.call("pose", key, c + Timeline.LENGTH_BACK)
	assert_almost_eq(_f(back["length"]), 1.0, 0.001, "length back by C+8")
	var flat: Dictionary = timeline.call("pose", key, c + Timeline.TIP_FADE)
	assert_almost_eq(_f(flat["keystone"]), 1.0, 0.001, "flat by C+10")
	var plain: RefCounted = _timeline({})
	var none: RefCounted = _timeline({"CB9": "none"})
	for n: int in range(_i(far["lift"]), c + 30):
		var a: Dictionary = plain.call("pose", key, n)
		var b: Dictionary = none.call("pose", key, n)
		assert_almost_eq(_f(a["turn"]), _f(b["turn"]), 0.0001, "none is the proposal's lean")
		assert_almost_eq(_f(b["length"]), 1.0, 0.0001, "none: full length")
		assert_almost_eq(_f(b["keystone"]), 1.0, 0.0001, "none: flat")


func test_the_lean_tips_the_leading_point_toward_the_target() -> void:
	var timeline: RefCounted = _timeline({})
	var attacks: Array = timeline.get("attacks")
	# 1: theirs down-right (bottom leads: anticlockwise); 3: theirs down-left (clockwise);
	# 6: yours up-left (top leads: anticlockwise)
	var signs: Array[float] = []
	for k: int in [1, 3, 6]:
		var attack: Dictionary = attacks[k]
		var turn: float = _turn(timeline, str(attack["attacker"]), _i(attack["contact"]) - 12)
		signs.append(signf(turn))
	assert_eq(signs, [-1.0, 1.0, -1.0], "each lean turns the leading point toward the target")


func test_cb2_a_is_shallower_than_b_on_every_attack() -> void:
	var a: Array = _plan({"CB2": "a"})["attacks"]
	var b: Array = _plan({"CB2": "b"})["attacks"]
	for k: int in a.size():
		var shallow: Dictionary = a[k]
		var medium: Dictionary = b[k]
		if _f(shallow["stop_gap_h"]) < 0.0:
			continue
		assert_gt(
			_f(shallow["stop_gap_h"]), _f(medium["stop_gap_h"]), "attack %d: A stops short of B" % k
		)
	for d: float in [1.0, 1.4, 1.8, 2.2, 2.6, 3.2]:
		var gap_a: float = _gap(Timeline.STOPS["a"], d)
		var gap_b: float = _gap(Timeline.STOPS["b"], d)
		assert_gt(gap_a, gap_b, "%.1f h: A stops short of B" % d)


static func _gap(stop: Dictionary, d: float) -> float:
	var share: float = clampf(
		(d - _f(stop["near_d"])) / (_f(stop["far_d"]) - _f(stop["near_d"])), 0.0, 1.0
	)
	return lerpf(_f(stop["near"]), _f(stop["far"]), share)


func test_cb11_strike_curves_speed_up_into_contact() -> void:
	for option: String in ["quad", "mild", "gentle"]:
		var timeline: RefCounted = _timeline({"CB9": "tip", "CB2": "b", "CB3": option})
		var all: Array = timeline.get("attacks")
		var far: Dictionary = all[1]
		var key: String = far["attacker"]
		var steps: Array[float] = []
		var last: Vector2 = _offset(timeline, key, _i(far["launch"]))
		for n: int in range(_i(far["launch"]) + 1, _i(far["contact"])):
			var at: Vector2 = _offset(timeline, key, n)
			steps.append(at.distance_to(last))
			last = at
		for k: int in range(1, steps.size()):
			assert_gt(steps[k], steps[k - 1], "%s: faster every frame into contact" % option)


func test_cb15_turns_its_share_of_the_path_and_the_cap_holds_30_degrees() -> void:
	var shares: Dictionary = {"tip_half": 0.5, "tip_3q": 0.75, "tip_medium": 0.95}
	for option: String in shares:
		var timeline: RefCounted = _timeline({"CB9": option, "CB2": "b", "CB3": "quad"})
		var attacks: Array = timeline.get("attacks")
		for k: int in [1, 3, 6]:
			var attack: Dictionary = attacks[k]
			var path: Vector2 = _path(timeline, attack)
			var lead: float = 1.0 if str(attack["lead"]) == "top" else -1.0
			var want: float = _f(shares[option]) * rad_to_deg(Vector2(0.0, -lead).angle_to(path))
			assert_almost_eq(_f(attack["aim_deg"]), want, 0.05, "%s attack %d" % [option, k])
			var c: int = attack["contact"]
			var at_c: float = _turn(timeline, str(attack["attacker"]), c)
			assert_almost_eq(at_c, want * Timeline.AIM_AT_CONTACT, 0.05, "%s: 90%% at C" % option)
	var capped: Array = _timeline({"CB9": "tip_cap30", "CB2": "b", "CB3": "quad"}).get("attacks")
	var full: Array = _timeline({"CB9": "tip_medium", "CB2": "b", "CB3": "quad"}).get("attacks")
	for k: int in capped.size():
		var got: float = _f(capped[k]["aim_deg"])
		var uncapped: float = _f(full[k]["aim_deg"])
		assert_almost_eq(got, clampf(uncapped, -30.0, 30.0), 0.001, "attack %d: capped at 30" % k)
	# the far corner (-54 at 95 %) and Old Brock (-44) are capped; Sentry's diagonal (26) is not
	assert_almost_eq(_f(capped[1]["aim_deg"]), -30.0, 0.001, "far corner capped")
	assert_almost_eq(_f(capped[6]["aim_deg"]), -30.0, 0.001, "Old Brock capped")
	assert_almost_eq(_f(capped[3]["aim_deg"]), _f(full[3]["aim_deg"]), 0.001, "26 degrees kept")


func test_cb17_tips_by_its_strength_and_none_only_turns() -> void:
	var wants: Dictionary = {
		"aim": [1.0, 1.0],
		"tip_small": [0.965, 0.97],
		"tip_medium": [0.85, 0.94],
		"tip": [0.75, 0.9]
	}
	for option: String in wants:
		var timeline: RefCounted = _timeline({"CB9": option, "CB2": "b", "CB3": "quad"})
		var far: Dictionary = timeline.get("attacks")[1]
		var at_c: Dictionary = timeline.call("pose", str(far["attacker"]), _i(far["contact"]))
		var want: Array = wants[option]
		assert_almost_eq(_f(at_c["length"]), _f(want[0]), 0.001, "%s: length at C" % option)
		assert_almost_eq(_f(at_c["keystone"]), _f(want[1]), 0.001, "%s: keystone at C" % option)
		assert_almost_eq(_f(far["aim_deg"]), -54.33, 0.05, "%s: the same 95 %% turn" % option)


func test_cb17_aim_lean_leans_4_degrees_the_way_it_turns_and_is_gone_by_contact() -> void:
	var lean: RefCounted = _timeline({"CB9": "aim_lean", "CB2": "b", "CB3": "quad"})
	var plain: RefCounted = _timeline({"CB9": "aim", "CB2": "b", "CB3": "quad"})
	var attacks: Array = lean.get("attacks")
	for k: int in [1, 3, 6]:
		var attack: Dictionary = attacks[k]
		var key: String = attack["attacker"]
		var c: int = attack["contact"]
		var aim: float = attack["aim_deg"]
		var extra: float = attack["lean_deg"]
		assert_eq(signf(extra), signf(aim), "attack %d: leans the way it turns" % k)
		assert_between(absf(extra), 1.0, 4.0, "attack %d: up to 4 degrees" % k)
		var held: float = _turn(lean, key, c - 12) - _turn(plain, key, c - 12)
		assert_almost_eq(held, extra, 0.01, "attack %d: the lean on top of the turn" % k)
		assert_almost_eq(
			_turn(lean, key, c), _turn(plain, key, c), 0.01, "attack %d: gone at C" % k
		)
		var at_c: Dictionary = lean.call("pose", key, c)
		assert_almost_eq(_f(at_c["keystone"]), 1.0, 0.001, "no tip")
		assert_almost_eq(_f(at_c["length"]), 1.0, 0.001, "no shortening")
	var straight: Dictionary = attacks[0]
	assert_almost_eq(_f(straight["lean_deg"]), 0.0, 0.01, "straight across: no lean")


func test_fast_plays_the_same_schedule_faster_from_the_fifth_attack() -> void:
	var plain: RefCounted = _timeline({})
	var fast: RefCounted = _timeline({"FAST": "a5"})
	var attacks: Array = fast.get("attacks")
	var from: int = fast.get("fast_from")
	var to: int = fast.get("fast_to")
	var result: int = _i(fast.get("end_frame")) - Timeline.END_HOLD
	assert_eq(from, _i(attacks[4]["lift"]), "from the 5th attack's lift")
	assert_eq(to, result, "to the result")
	var same: Array = plain.get("attacks")
	assert_eq(attacks, same, "the same schedule: only the clock changes")
	assert_eq(_i(plain.get("fast_from")), -1, "no FAST: never faster")
	assert_almost_eq(_f(fast.call("speed_at", from - 1.0)), 1.0, 0.0001, "x1 before")
	assert_almost_eq(_f(fast.call("speed_at", from + 0.5)), 1.5, 0.0001, "x1.5 after")
	assert_almost_eq(_f(fast.call("speed_at", float(result))), 1.0, 0.0001, "the result at x1")
	# the clock lands on the result's frame, after from + (result - from) / 1.5 drawn frames
	var drawn: int = fast.call("drawn_frames_to", result)
	assert_eq(drawn, from + ceili((result - from) / 1.5), "drawn frames to the result")
	assert_eq(_i(plain.call("drawn_frames_to", result)), result, "no FAST: one frame each")
	var t: float = 0.0
	while t < result:
		t = _f(fast.call("advance", t))
	assert_almost_eq(t, float(result), 0.0001, "lands on the result")
	# the card keeper's own tweens (falls) speed up with it
	for value: Variant in fast.get("steps"):
		var step: Dictionary = value
		var frame: int = step["frame"]
		if frame >= from and frame < to:
			assert_gte(_f(step["speed"]), 1.5, "step at %d plays x1.5 or more" % frame)
	# the contact pop holds one drawn frame at the clock's step
	var late: Dictionary = attacks[5]
	var key: String = late["attacker"]
	fast.set("clock_step", 1.5)
	var c: float = _f(late["contact"])
	assert_almost_eq(_f(fast.call("pose", key, c + 1.2)["scale"]), Timeline.POP, 0.001, "pop")
	assert_almost_eq(_f(fast.call("pose", key, c + 1.0)["scale"]), Timeline.POP, 0.001, "pop")
	fast.set("clock_step", 1.0)
	assert_lt(_f(fast.call("pose", key, c + 1.2)["scale"]), Timeline.POP, "x1: one frame")


func test_fast_plays_on_the_fight_screen() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene.call("start", "best", {"FAST": "a5", "GROUP": 3, "R7": "early_x2"})
	var screen: FightScreen = scene.get("screen")
	for i: int in 3:
		await get_tree().process_frame
	assert_true(screen.is_playing(), "still playing")


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


func _timeline(chosen: Dictionary) -> RefCounted:
	var combat: Combat = Compare.fight_named(_content, "")
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	var best: RefCounted = Treatments.make("best")
	best.call("configure", chosen)
	best.call("make_replay", base, combat.events, {}, Compare.DAMAGE)
	var timeline: RefCounted = best.get("timeline")
	return timeline


static func _offset(timeline: RefCounted, key: String, n: int) -> Vector2:
	var pose: Dictionary = timeline.call("pose", key, n)
	var offset: Vector2 = pose["offset"]
	return offset


static func _turn(timeline: RefCounted, key: String, n: int) -> float:
	var pose: Dictionary = timeline.call("pose", key, n)
	return _f(pose["turn"])


## The attack's line: where the attacker stops, from where it stands (along the line to its
## target).
static func _path(timeline: RefCounted, attack: Dictionary) -> Vector2:
	var segments: Dictionary = timeline.get("segments")
	for value: Variant in segments.get(str(attack["attacker"]), []):
		var seg: Dictionary = value
		if str(seg["kind"]) == "attack" and _i(seg["from"]) == _i(attack["lift"]):
			return seg["stop"]
	return Vector2.ZERO


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
		"CB9": Timeline.ROTATIONS,
	}
	var table: Dictionary = tables[branch]
	return table


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
