extends GutTest
## The `buffs` treatment of the comparison fight (tests/screens/feel/fight_compare/buffs.gd): CB14,
## how a stat gain shows (docs/workstreams/fight-animation-24-nov/buff-look/DESIGN.md, section 2).
## Old Brock's six gains in moment (e) keep DESIGN.md's beats in every option, the numbers counted
## stay true, and "none" is the best proposal unchanged. Exploratory; nothing here is the game.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const Timeline := preload("res://tests/screens/feel/fight_compare/buff_timeline.gd")

## Old Brock's six gains in moment (e): what each dead friend gives, and the dead slots in order.
const GAINS: Array[Vector2i] = [
	Vector2i(2, 5), Vector2i(3, 5), Vector2i(2, 2), Vector2i(2, 5), Vector2i(3, 5), Vector2i(2, 2)
]
const DEAD_SLOTS: Array[int] = [0, 1, 2, 4, 5, 6]
## DESIGN.md: beats 18, 14, 10, 8, 6 f apart (x0.75, rounded, floor 5).
const STARTS: Array[int] = [0, 18, 32, 42, 50, 56]

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_beats_start_as_design_says() -> void:
	var got: Array[int] = []
	for k: int in 6:
		got.append(Timeline.start_of(k))
	assert_eq(got, STARTS)


func test_a_and_b_land_six_frames_into_each_beat() -> void:
	for option: String in ["a", "b"]:
		var timeline: RefCounted = _timeline(option)
		var run: Dictionary = _brock_run(timeline)
		var start: int = _i(run["start"])
		assert_eq(start, _fall_end(timeline), "%s: the first beat at the falls' end (F)" % option)
		var lands: Array[int] = []
		for land: Variant in run["lands"]:
			lands.append(_i(land) - start)
		assert_eq(lands, [6, 24, 38, 48, 56, 62], "%s: L at F+6, 24, 38, 48, 56, 62" % option)
	for option: String in ["a", "b"]:
		var run: Dictionary = _brock_run(_timeline(option))
		var end: int = _i(run["end"]) - _i(run["start"])
		assert_eq(end, 76, "%s: settled by F+76; a tally's tail does not hold the queue" % option)


func test_c_carries_each_gain_from_its_dead_friends_slot() -> void:
	var timeline: RefCounted = _timeline("c")
	var run: Dictionary = _brock_run(timeline)
	var start: int = _i(run["start"])
	var born: Array[int] = []
	var landed: Array[int] = []
	var slots: Array[int] = []
	for gain: Dictionary in _brock_gains(timeline):
		born.append(_i(gain["born"]) - start)
		landed.append(_i(gain["land"]) - start)
		var cause: Dictionary = gain["cause"]
		slots.append(_i(cause.get("slot", -1)))
	assert_eq(born, STARTS, "pairs rise at F+0, 18, 32, 42, 50, 56")
	assert_eq(landed, [10, 28, 42, 52, 60, 66], "and land 10 f later")
	assert_eq(slots, DEAD_SLOTS, "each from the slot of the friend whose death gave it")


func test_the_counts_add_up_to_the_log() -> void:
	for option: String in ["a", "b", "c"]:
		var timeline: RefCounted = _timeline(option)
		var gains: Array[Dictionary] = _brock_gains(timeline)
		assert_eq(gains.size(), 6, "%s: six gains" % option)
		var deltas: Array[Vector2i] = []
		for gain: Dictionary in gains:
			deltas.append(Vector2i(_stat(gain, "attack", 2), _stat(gain, "health", 2)))
		assert_eq(deltas, GAINS, "%s: each gain is its dead friend's stats" % option)
		var from: Array[int] = [_stat(gains[0], "attack", 0), _stat(gains[0], "health", 0)]
		var to: Array[int] = [_stat(gains[5], "attack", 1), _stat(gains[5], "health", 1)]
		assert_eq(from, [10, 9], "%s: from 10/9" % option)
		assert_eq(to, [24, 33], "%s: to 24/33" % option)


func test_only_the_changed_disc_swells_and_counts() -> void:
	var timeline: RefCounted = _timeline("a")
	var first: Dictionary = _brock_gains(timeline)[0]
	var land: int = _i(first["land"])
	var key: String = first["key"]
	assert_true(_disc(timeline, key, "attack", land - 1).is_empty(), "at rest before L")
	var at_l: Dictionary = timeline.call("disc_at", key, "attack", land)
	assert_almost_eq(_f(at_l["scale"]), 2.0, 0.001, "x2.0 at L")
	assert_eq(_i(at_l["value"]), 10, "counting from the old number")
	var counted: Dictionary = timeline.call("disc_at", key, "health", land + 8)
	assert_eq(_i(counted["value"]), 14, "counted to the new number by L+8")
	assert_true(_disc(timeline, key, "attack", land + 14).is_empty(), "back at rest by L+14")
	assert_true(_disc(timeline, "u1", "attack", land).is_empty(), "no other card's disc")


func test_b_tally_runs_the_total_and_sinks() -> void:
	var timeline: RefCounted = _timeline("b")
	var gains: Array[Dictionary] = _brock_gains(timeline)
	var first: int = _i(gains[0]["land"])
	var last: int = _i(gains[5]["land"])
	var key: String = gains[0]["key"]
	assert_eq(_texts(timeline, key, first - 3), [], "no tag before L-2")
	assert_eq(_texts(timeline, key, first - 2), ["+2", "+5"], "the first gain's tag at L-2")
	assert_eq(_texts(timeline, key, last), ["+14", "+24"], "the running total at the last gain")
	assert_eq(_texts(timeline, key, last + 35), ["+14", "+24"], "sinking until L+36")
	assert_eq(_texts(timeline, key, last + 36), [], "gone at L+36")


func test_none_is_the_best_proposal() -> void:
	var best: RefCounted = _replay_timeline("best", {})
	var none: RefCounted = _replay_timeline("buffs", {"CB14": "none"})
	assert_eq(JSON.stringify(none.get("steps")), JSON.stringify(best.get("steps")))


func _timeline(option: String) -> RefCounted:
	return _replay_timeline("buffs", {"CB14": option})


func _replay_timeline(treatment_name: String, options: Dictionary) -> RefCounted:
	var combat: Combat = Compare.fight(_content)
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	base.erase("boards")
	base["slots"] = [[], []]
	var treatment: RefCounted = Treatments.make(treatment_name)
	treatment.call("configure", options)
	var replay: FightReplay = treatment.call("make_replay", base, combat.events, {}, Compare.DAMAGE)
	return replay.get("timeline")


## Moment (e)'s run of six gains on Old Brock.
func _brock_run(timeline: RefCounted) -> Dictionary:
	for value: Variant in timeline.get("runs"):
		var run: Dictionary = value
		var lands: Array = run["lands"]
		if lands.size() == 6:
			return run
	return {}


func _brock_gains(timeline: RefCounted) -> Array[Dictionary]:
	var run: int = _i(_brock_run(timeline).get("run", -1))
	var out: Array[Dictionary] = []
	for value: Variant in timeline.get("gains"):
		var gain: Dictionary = value
		if _i(gain["run"]) == run:
			out.append(gain)
	return out


## When moment (e)'s six falls end (attack 5's last fall).
func _fall_end(timeline: RefCounted) -> int:
	var attacks: Array = timeline.get("attacks")
	var attack: Dictionary = attacks[5]
	var falls: Array = attack["falls"]
	var fall: Dictionary = falls.back()
	return _i(fall["frame"]) + _i(fall["frames"])


func _disc(timeline: RefCounted, key: String, stat: String, n: int) -> Dictionary:
	var shown: Dictionary = timeline.call("disc_at", key, stat, n)
	return shown


func _texts(timeline: RefCounted, key: String, n: int) -> Array[String]:
	var out: Array[String] = []
	for value: Variant in timeline.call("tags_at", n):
		var tag: Dictionary = value
		if str(tag["key"]) == key:
			out.append(str(tag["text"]))
	return out


## A gain's [from, to, delta] for one stat, the part asked for.
static func _stat(gain: Dictionary, stat: String, part: int) -> int:
	var stats: Dictionary = gain["stats"]
	var counted: Array = stats[stat]
	return _i(counted[part])


static func _i(value: Variant) -> int:
	return CoreUtil.to_int(value)


static func _f(value: Variant) -> float:
	return GlassPieces.as_float(value)
