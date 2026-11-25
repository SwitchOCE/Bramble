extends GutTest
## The game's fight schedule (src/screens/fight/fight_timeline.gd) is the fixture's `recommended`
## with the owner's picks and both late-fight speed-ups, minus CB13 c (plan steps 1b, 3 to 5:
## CB2 b, CB3 mild, CB9 aim_lean, CB8 c, CB14 c, FAST a5, GROUP 3; the single death is a later
## step): on the comparison fight, the same steps on the same frames, the same bursts, falls,
## glows, gains and tallies, and every card's pose equal on every frame. Its sound cues sit on the
## moments they belong to, and FAST speeds them up with the fight. The same fight on the screen at
## 30 and 144 frames a second shows the same things at the same seconds.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")

## The fixture's options with exactly the game's picks (recommended's own: CB2 b, CB3 mild, CB8 c,
## CB14 c), the game's turn (CB9 aim_lean, which overrides the rotation switch's set), no CB13,
## and the two speed-ups.
const PICKS: Dictionary = {
	"ROTATE": "off", "CB9": "aim_lean", "CB13": "none", "FAST": "a5", "GROUP": 3
}
## The gain fields both schedules keep.
const GAIN_FIELDS: Array[String] = ["key", "k", "start", "land", "born", "fly", "cause", "stats"]

var _content: GameContent
var _screen: FightScreen


func before_all() -> void:
	_content = GameContent.load_default()


## [the fixture's timeline, the game's replay] on fight `which`.
func _both(which: String = "") -> Array:
	var combat: Combat = Compare.fight_named(_content, which)
	var base: Dictionary = _base()
	var catalog: Dictionary = {}
	ViewAdapter.add_fight_cards(_content, combat.events, catalog)
	var recommended: RefCounted = Treatments.make("recommended")
	recommended.call("configure", PICKS)
	var fixture: FightReplay = recommended.call(
		"make_replay", base, combat.events, catalog, Compare.DAMAGE
	)
	var game: FightReplay = FightReplay.build(_base(), combat.events, catalog, Compare.DAMAGE)
	FightScreen.schedule(game)
	return [fixture.get("timeline"), game]


static func _base() -> Dictionary:
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	base.erase("boards")
	base["slots"] = [[], []]
	return base


func test_the_game_schedules_the_fixtures_recommended_with_the_picks() -> void:
	var both: Array = _both()
	var fixture: RefCounted = both[0]
	var game: FightReplay = both[1]
	var plan: FightTimeline = game.plan
	var theirs: Array = fixture.get("steps")
	assert_eq(game.steps.size(), theirs.size(), "as many steps")
	for k: int in theirs.size():
		var mine: Dictionary = game.steps[k]
		var step: Dictionary = theirs[k]
		assert_eq(_i(mine["frame"]), _i(step["frame"]), "step %d's frame" % k)
		assert_eq(str(mine["kind"]), str(step["kind"]), "step %d's kind" % k)
		assert_almost_eq(_f(mine["speed"]), _f(step["speed"]), 0.0001, "step %d's speed" % k)
		var a: Dictionary = mine["state"]
		var b: Dictionary = step["state"]
		assert_eq(JSON.stringify(a["boards"]), JSON.stringify(b["boards"]), "step %d's boards" % k)
	assert_eq(plan.end_frame, _i(fixture.get("end_frame")), "the same end")
	assert_eq(plan.fast_from, _i(fixture.get("fast_from")), "FAST from the same frame")
	assert_eq(plan.fast_to, _i(fixture.get("fast_to")), "FAST to the result")
	var bursts: Array = fixture.get("bursts")
	assert_eq(plan.bursts.size(), bursts.size(), "as many bursts")
	for k: int in bursts.size():
		var mine: Dictionary = plan.bursts[k]
		var burst: Dictionary = bursts[k]
		for field: String in [
			"frame", "key", "side", "slot", "amount", "blocked", "taken", "merge"
		]:
			assert_eq(str(mine[field]), str(burst[field]), "burst %d's %s" % [k, field])
	assert_eq(JSON.stringify(plan.glows), JSON.stringify(fixture.get("glows")), "the glows")
	assert_eq(JSON.stringify(plan.falls), JSON.stringify(fixture.get("_falls")), "the falls")
	var gains: Array = fixture.get("gains")
	assert_eq(plan.gains.size(), gains.size(), "as many gains")
	for k: int in gains.size():
		for field: String in GAIN_FIELDS:
			assert_eq(
				JSON.stringify(plan.gains[k][field]),
				JSON.stringify(gains[k][field]),
				"gain %d's %s" % [k, field]
			)
	var tallies: Array = fixture.get("tallies")
	assert_eq(plan.tallies.size(), tallies.size(), "as many tallies")
	for k: int in tallies.size():
		for field: String in ["key", "appear", "lands", "totals", "sink", "gone"]:
			assert_eq(
				JSON.stringify(plan.tallies[k][field]),
				JSON.stringify(tallies[k][field]),
				"tally %d's %s" % [k, field]
			)
	var segments: Dictionary = fixture.get("segments")
	assert_eq(plan.segments.keys(), segments.keys(), "the same cards move")
	var differ: int = 0
	for key: Variant in segments:
		for n: int in plan.end_frame + 1:
			var mine: Dictionary = plan.pose(str(key), float(n))
			var pose: Dictionary = fixture.call("pose", str(key), float(n))
			if not _same(mine, pose):
				differ += 1
				if differ <= 5:
					fail_test("%s at frame %d: %s against %s" % [key, n, mine, pose])
	assert_eq(differ, 0, "every pose on every frame")
	# what each gain shows, frame by frame (the fixture's buff screen draws the same queries)
	differ = 0
	for n: int in plan.end_frame + 1:
		var a: String = JSON.stringify([plan.tags_at(n), plan.flights_at(n), plan.flares_at(n)])
		var b: String = JSON.stringify(
			[
				fixture.call("tags_at", n),
				fixture.call("flights_at", n),
				fixture.call("flares_at", n)
			]
		)
		var discs_a: String = JSON.stringify(plan.disc_at("u4", "health", n))
		var discs_b: String = JSON.stringify(fixture.call("disc_at", "u4", "health", n))
		if _strip(a) != _strip(b) or discs_a != discs_b:
			differ += 1
	assert_eq(differ, 0, "the gains' pieces on every frame")


func test_deaths_at_once_fall_one_after_another() -> void:
	assert_eq(str(FightOrder.starts_of(6)), str([0, 10, 17, 22, 26, 30]), "10/7/5/4/4")
	assert_eq(_i(FightOrder.starts_of(9).back()), FightOrder.CAP, "capped at 30")
	var game: FightReplay = _both()[1]
	# moment (e): six of yours at once, from one frame, each its own fall
	var frames: Dictionary = {}
	for fall: Dictionary in game.plan.falls:
		frames[_i(fall["frame"])] = _i(frames.get(_i(fall["frame"]), 0)) + 1
	assert_false(frames.values().has(6), "no six at once any more")
	var six: Array[int] = []
	for fall: Dictionary in game.plan.falls:
		six.append(_i(fall["frame"]))
	six.sort()
	var base: int = six[3]
	assert_eq(
		[six[3] - base, six[4] - base, six[5] - base, six[6] - base, six[7] - base, six[8] - base],
		[0, 10, 17, 22, 26, 30],
		"moment (e)'s falls start 10, 7, 5, 4, 4 frames apart"
	)
	# each of Old Brock's gains lands after a death of moment (e), 19 f after it starts (15 to
	# the empty slot, plus the flight's landing past CB8's mark, as in the recommended film)
	var lands: Array[int] = []
	for gain: Dictionary in game.plan.gains:
		if _i(gain["land"]) > base:
			lands.append(_i(gain["land"]))
	assert_eq(lands.size(), 6, "one gain per death")
	assert_eq(lands[0], base + FightOrder.LAND + 4, "the first lands as its fall ends, and 4")


func test_fast_plays_from_the_fifth_attack_to_the_result() -> void:
	var plan: FightTimeline = _both()[1].plan
	var fifth: Dictionary = plan.attacks[FightTimeline.FAST_ATTACK - 1]
	assert_eq(plan.fast_from, _i(fifth["lift"]), "from the fifth attack's lift")
	assert_eq(plan.fast_to, plan.result_frame, "to the result")
	assert_eq(plan.speed_at(plan.fast_from - 1.0), 1.0, "x1 before")
	assert_eq(plan.speed_at(float(plan.fast_from)), FightTimeline.FAST_SPEED, "x1.5 from it")
	assert_eq(plan.speed_at(float(plan.result_frame)), 1.0, "the result's hold at x1")
	assert_eq(plan.advance(plan.fast_from - 1.0, 1.0), float(plan.fast_from), "lands on its start")
	assert_eq(plan.advance(float(plan.fast_from), 1.0), plan.fast_from + 1.5, "1.5 a frame")
	assert_eq(plan.advance(plan.fast_to - 0.5, 1.0), float(plan.fast_to), "stops on the result")
	assert_eq(plan.advance(plan.fast_from - 1.0, 2.0), plan.fast_from + 1.5, "split at its start")
	# the keeper's own tweens (a fall, numbers rolling) follow it too
	for step: Dictionary in plan.steps:
		var frame: int = _i(step["frame"])
		if frame >= plan.fast_from and frame < plan.fast_to:
			assert_almost_eq(_f(step["speed"]), FightTimeline.FAST_SPEED, 0.0001, "step speed")
	# a fight with fewer attacks plays at x1 throughout
	var short: FightTimeline = FightTimeline.new()
	assert_eq(short.fast_from, -1)
	assert_eq(short.advance(10.0, 1.0), 11.0)


func test_sound_cues_sit_on_their_moments_and_speed_up_with_fast() -> void:
	var game: FightReplay = _both()[1]
	var plan: FightTimeline = game.plan
	var kinds: Dictionary = {}
	for cue: Dictionary in plan.cues:
		kinds[str(cue["kind"])] = _i(kinds.get(str(cue["kind"]), 0)) + 1
	var hit_frames: Dictionary = {}
	for burst: Dictionary in plan.bursts:
		hit_frames[_i(burst["frame"])] = true
	assert_eq(_i(kinds.get("hit", 0)), hit_frames.size(), "a hit cue on every frame bursts show")
	# a death sounds as the steps show it fall: as its unit leaves the board
	var gone_at: Dictionary = {}
	for k: int in range(1, plan.steps.size()):
		var before: Dictionary = _uids(plan.steps[k - 1])
		var now: Dictionary = _uids(plan.steps[k])
		for uid: Variant in before:
			if not now.has(uid):
				gone_at[_i(plan.steps[k]["frame"])] = (
					_i(gone_at.get(_i(plan.steps[k]["frame"]), 0)) + 1
				)
	var deaths: Dictionary = {}
	for cue: Dictionary in plan.cues:
		if str(cue["kind"]) == "death":
			deaths[_i(cue["frame"])] = _i(cue["count"])
	assert_eq(deaths, gone_at, "each death cue on the frame its units leave, with their count")
	assert_false(deaths.values().has(6), "moment (e)'s six deaths are six cues, not one")
	assert_gt(_i(kinds.get("trigger", 0)), 0, "triggers sound as their source pulses")
	assert_eq(_i(kinds.get("summon", 0)), 1, "the Hopper's arrival")
	assert_eq(_i(kinds.get("result", 0)), 1, "the result")
	var last: Dictionary = plan.cues.back()
	assert_eq(str(last["kind"]), "result")
	assert_eq(_i(last["frame"]), plan.result_frame, "the result sounds as it shows")
	for cue: Dictionary in plan.cues:
		var expect: float = plan.speed_at(_i(cue["frame"]))
		assert_eq(
			_f(cue["speed"]), expect, "%s at %s: the fight's speed" % [cue["kind"], cue["frame"]]
		)
		var asked: Array[Dictionary] = SoundCues.for_fight_cue(cue, Sound.table)
		assert_false(asked.is_empty(), "%s asks for a cue" % cue["kind"])
	# FAST shortens a cue's own staggers (seven hit at once: the cleave's staggered takes)
	var cleave: Dictionary = {}
	for cue: Dictionary in plan.cues:
		var splashes: Array = cue.get("splashes", [])
		if str(cue["kind"]) == "hit" and splashes.size() >= 3:
			cleave = cue
	assert_eq(_f(cleave["speed"]), FightTimeline.FAST_SPEED, "moment (e)'s cleave is under FAST")
	var fast: Array[Dictionary] = SoundCues.for_fight_cue(cleave, Sound.table)
	var plain_cue: Dictionary = cleave.duplicate()
	plain_cue["speed"] = 1.0
	var plain: Array[Dictionary] = SoundCues.for_fight_cue(plain_cue, Sound.table)
	assert_eq(fast.size(), plain.size())
	for k: int in plain.size():
		assert_almost_eq(
			_f(fast[k]["delay_s"]),
			_f(plain[k]["delay_s"]) / FightTimeline.FAST_SPEED,
			0.0001,
			"take %d's stagger" % k
		)


func test_the_board_at_the_end_is_the_cores() -> void:
	var combat: Combat = Compare.fight(_content)
	var game: FightReplay = _both()[1]
	var last: Dictionary = game.steps.back()
	assert_eq(str(last["kind"]), "end")
	var shown_state: Dictionary = last["state"]
	var boards: Array = shown_state["boards"]
	for side: int in 2:
		var shown: Array = []
		var row: Array = boards[side]
		for value: Variant in row:
			if value is Dictionary:
				var unit: Dictionary = value
				shown.append(
					[_i(unit["slot"]), _i(unit["uid"]), _i(unit["attack"]), _i(unit["health"])]
				)
		var core: Array = []
		for unit: CombatUnit in combat.units(side):
			core.append([unit.slot, unit.uid, unit.attack(), unit.health()])
		core.sort()
		shown.sort()
		assert_eq(shown, core, "side %d's last board is the core's" % side)
	assert_eq(
		JSON.stringify(game.summary(0)), JSON.stringify(_core_board(combat, 0)), "the replay's"
	)


## What the screen shows every 1/6 s of game time on the comparison fight at `fps`: the schedule
## clock, Old Brock's drawn numbers and the gain pieces drawn; and the seconds the result shows.
func _run_at(fps: int) -> Dictionary:
	var game: FightReplay = _both()[1]
	_screen = SCREEN.instantiate()
	add_child_autofree(_screen)
	_screen.set_process(false)
	_screen.play(game)
	var clocks: Array[float] = []
	var brock: Array[Vector2i] = []
	var pieces: Array[int] = []
	var result: Array[float] = [-1.0]
	var elapsed: Array[float] = [0.0]
	_screen.result_shown.connect(func() -> void: result[0] = elapsed[0])
	var per_sixth: int = roundi(fps / 6.0)
	for k: int in 80:
		clocks.append(_screen._clock)
		var card: GlassCard = _screen._kept_node("u4") as GlassCard
		brock.append(Vector2i(card.attack, card.health) if card != null else Vector2i(-1, -1))
		pieces.append(_screen._gains.drawn.size() if _screen._gains != null else 0)
		for frame: int in per_sixth:
			_screen._process(1.0 / fps)
			elapsed[0] += 1.0 / fps
	return {"clocks": clocks, "brock": brock, "pieces": pieces, "result": result[0]}


func test_the_same_fight_at_30_and_144_frames_a_second() -> void:
	var slow: Dictionary = _run_at(30)
	var plan: FightTimeline = _screen._schedule
	var fast: Dictionary = _run_at(144)
	var slow_clocks: Array[float] = slow["clocks"]
	var fast_clocks: Array[float] = fast["clocks"]
	var slow_brock: Array[Vector2i] = slow["brock"]
	var fast_brock: Array[Vector2i] = fast["brock"]
	var slow_pieces: Array[int] = slow["pieces"]
	var fast_pieces: Array[int] = fast["pieces"]
	for k: int in slow_clocks.size():
		var due: float = _expected_frame(plan, k / 6.0)
		if due >= plan.end_frame:
			# the fight is over: its clock stops
			break
		# within a drawn frame's share at 144 fps (FAST's start and end fall between its frames)
		assert_almost_eq(slow_clocks[k], due, 0.001, "at %d/6 s at 30 fps: game time, FAST" % k)
		assert_almost_eq(fast_clocks[k], due, 0.7, "at %d/6 s at 144 fps" % k)
	var differ: int = 0
	for k: int in slow_brock.size():
		if fast_brock[k] != slow_brock[k] or (fast_pieces[k] > 0) != (slow_pieces[k] > 0):
			differ += 1
	# a 1/6 s sample can fall on a count's step at one rate and just past it at the other
	assert_lte(differ, 3, "Old Brock's numbers and the gains drawn at the same seconds")
	var shown: bool = false
	for count: int in slow_pieces:
		shown = shown or count > 0
	assert_true(shown, "the gains' pieces were drawn")
	var expect: float = (
		plan.fast_from / 60.0 + (plan.fast_to - plan.fast_from) / (60.0 * FightTimeline.FAST_SPEED)
	)
	assert_almost_eq(_f(slow["result"]), expect, 1.0 / 30.0 + 0.001, "the result at 30 fps")
	assert_almost_eq(_f(fast["result"]), expect, 1.0 / 30.0 + 0.001, "the result at 144 fps")


func test_skip_leaves_no_gain_piece_and_the_cores_numbers() -> void:
	var game: FightReplay = _both()[1]
	_screen = SCREEN.instantiate()
	add_child_autofree(_screen)
	_screen.set_process(false)
	_screen.play(game)
	var plan: FightTimeline = _screen._schedule
	var mid: float = _f(plan.gains[2]["land"]) + 2.0
	while _screen._clock < mid:
		_screen._process(1.0 / 60.0)
	assert_gt(_screen._gains.drawn.size(), 0, "pieces drawn mid-gain")
	_screen.skip()
	assert_eq(_screen._gains.drawn.size(), 0, "nothing drawn after a skip")
	var left: int = 0
	for node: Node in _screen._front.find_children("Gain*", "", true, false):
		if not node.is_queued_for_deletion():
			left += 1
	assert_eq(left, 0, "no piece left")
	_screen._process(1.0 / 60.0)
	assert_eq(_screen._gains.drawn.size(), 0, "nor on the next frame")
	var card: GlassCard = _screen._kept_node("u4") as GlassCard
	var end: Dictionary = {}
	for unit: Dictionary in game.summary(0):
		if _i(unit["uid"]) == 4:
			end = unit
	assert_eq(Vector2i(card.attack, card.health), Vector2i(_i(end["attack"]), _i(end["health"])))


## The schedule frame the clock should be at after `seconds` of game time.
static func _expected_frame(plan: FightTimeline, seconds: float) -> float:
	var frames: float = seconds * 60.0
	if frames <= plan.fast_from:
		return frames
	var sped: float = plan.fast_from + (frames - plan.fast_from) * FightTimeline.FAST_SPEED
	if sped <= plan.fast_to:
		return sped
	var left: float = frames - plan.fast_from - (plan.fast_to - plan.fast_from) / 1.5
	return plan.fast_to + left


static func _core_board(combat: Combat, side: int) -> Array:
	var out: Array = []
	for unit: CombatUnit in combat.units(side):
		out.append(
			{"slot": unit.slot, "uid": unit.uid, "attack": unit.attack(), "health": unit.health()}
		)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["slot"] < b["slot"])
	return out


static func _uids(step: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var state: Dictionary = step["state"]
	var boards: Array = state.get("boards", [])
	for row: Variant in boards:
		var units: Array = row
		for value: Variant in units:
			if value is Dictionary:
				var unit: Dictionary = value
				out[_i(unit.get("uid", -1))] = true
	return out


## The fixture names a tally by its run, the game by its index: both dropped.
static func _strip(text: String) -> String:
	var out: String = text
	for name_of: String in ['"run"', '"tally"']:
		var regex: RegEx = RegEx.create_from_string(name_of + ":\\d+,?")
		out = regex.sub(out, "", true)
	return out


static func _same(mine: Dictionary, pose: Dictionary) -> bool:
	var a: Vector2 = mine["offset"]
	var b: Vector2 = pose["offset"]
	var la: Color = mine["light"]
	var lb: Color = pose["light"]
	return (
		a.is_equal_approx(b)
		and is_equal_approx(_f(mine["scale"]), _f(pose["scale"]))
		and is_equal_approx(_f(mine["turn"]), _f(pose["turn"]))
		and la.is_equal_approx(lb)
	)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
