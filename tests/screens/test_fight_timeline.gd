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
## Every tenth of the 400 saved late fights' logs, by name (test_late_fights_end_true_and_at_rest).
const LATE_FIGHTS: String = "res://tests/screens/fixtures/late_fights.json.gz"

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
	var jabbed: float = 0.0
	for key: Variant in segments:
		for n: int in plan.end_frame + 1:
			# the jabs turn in the game (step 1b's review: "every animation"); best's jabs do not
			var jab: float = plan.jab_turn(str(key), float(n))
			jabbed = maxf(jabbed, absf(jab))
			var mine: Dictionary = plan.pose(str(key), float(n)).duplicate()
			mine["turn"] = _f(mine["turn"]) - jab
			var pose: Dictionary = fixture.call("pose", str(key), float(n))
			if not _same(mine, pose):
				differ += 1
				if differ <= 5:
					fail_test("%s at frame %d: %s against %s" % [key, n, mine, pose])
	assert_eq(differ, 0, "every pose on every frame, but for the jabs' turn")
	assert_gt(jabbed, 5.0, "the Thorns and Locust jabs turn toward their targets")
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


## CB14 c ("each +N flies from the dead card into the stat and adds up") on moment (e): each of
## Old Brock's six gains flies from the death it is for, never from Brock, and the one tally over
## him counts up, each total the sum of the gains landed so far, the last his whole change.
func test_staggered_gains_fly_from_their_deaths_and_add_up() -> void:
	var game: FightReplay = _both()[1]
	var plan: FightTimeline = game.plan
	var meant: Dictionary = {}
	var first: Vector2i = Vector2i(-1, -1)
	var last: Vector2i = Vector2i.ZERO
	for value: Variant in game.played:
		var event: Dictionary = value
		if event.has("stagger_cause") and str(event["type"]) == "trigger":
			meant[_i(event["stagger_cause"])] = true
		if event.has("stagger_cause") and str(event["type"]) == "buff":
			last = Vector2i(_i(event["attack"]), _i(event["health"]))
	assert_eq(meant.size(), 6, "six beats, each for its own death")
	# moment (e)'s first fall (the fourth death of the fight)
	var fell: Array[int] = []
	for fall: Dictionary in plan.falls:
		fell.append(_i(fall["frame"]))
	fell.sort()
	var base: int = fell[3]
	var brock: String = ""
	var rows: Array[Dictionary] = []
	for gain: Dictionary in plan.gains:
		if str(gain["source"]) == str(gain["key"]) and _i(gain["land"]) > base:
			rows.append(gain)
			brock = str(gain["key"])
	assert_eq(rows.size(), 6, "Old Brock's six gains")
	var causes: Array[int] = []
	for gain: Dictionary in rows:
		var cause: Dictionary = gain["cause"]
		assert_false(cause.is_empty(), "gain %d flies from a death, not from Brock" % _i(gain["k"]))
		assert_ne(_key_of(cause), brock, "never from Brock himself")
		causes.append(_i(cause.get("uid", -1)))
		if first.x < 0:
			var stats: Dictionary = gain["stats"]
			var attack: Array = stats.get("attack", [0, 0, 0])
			var health: Array = stats.get("health", [0, 0, 0])
			first = Vector2i(_i(attack[1]) - _i(attack[2]), _i(health[1]) - _i(health[2]))
	causes.sort()
	var wanted: Array = meant.keys()
	wanted.sort()
	assert_eq(str(causes), str(wanted), "each from its own death, all six different")
	var groups: Array[Dictionary] = []
	for tally: Dictionary in plan.tallies:
		var lands: Array = tally["lands"]
		if str(tally["key"]) == brock and _i(lands[0]) > base:
			groups.append(tally)
	assert_eq(groups.size(), 1, "one tally over Brock for the whole group")
	var tally: Dictionary = groups[0]
	var totals: Array = tally["totals"]
	assert_eq(totals.size(), 6, "it re-pops with each gain")
	var sum: Vector2i = Vector2i.ZERO
	for k: int in rows.size():
		var stats: Dictionary = rows[k]["stats"]
		var attack: Array = stats.get("attack", [0, 0, 0])
		var health: Array = stats.get("health", [0, 0, 0])
		sum += Vector2i(_i(attack[2]), _i(health[2]))
		var shown: Dictionary = totals[k]
		assert_eq(
			Vector2i(_i(shown["attack"]), _i(shown["health"])), sum, "total %d: the sum so far" % k
		)
	assert_eq(sum, last - first, "the last total is Brock's whole change")


static func _key_of(cause: Dictionary) -> String:
	return "u%d" % _i(cause.get("uid", -1))


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
		var before: Dictionary = _uid_set(plan.steps[k - 1])
		var now: Dictionary = _uid_set(plan.steps[k])
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
		# within a drawn frame's share at 144 fps (FAST's start and end fall between its frames);
		# past the result the clock has stopped on the result's frame (advance), so at 30 fps it
		# can trail by up to one drawn frame's FAST share (3 schedule frames)
		var slack: float = 0.001 if due <= plan.fast_to else 3.0
		assert_almost_eq(slow_clocks[k], due, slack, "at %d/6 s at 30 fps: game time, FAST" % k)
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


static func _uid_set(step: Dictionary) -> Dictionary:
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


## 40 of the 400 saved late fights (every tenth of /data/fight-anim-work/fight-length/fights, the
## league's final bots; docs/workstreams/fight-animation-24-nov/research/fight-length.md): each
## schedule ends on the board the whole log leaves (the core's survivors), with every card at
## rest, and nothing but the first board shows at frame 0.
func test_late_fights_end_true_and_at_rest() -> void:
	var packed: PackedByteArray = FileAccess.get_file_as_bytes(LATE_FIGHTS)
	var text: String = (
		packed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
	)
	var fights: Dictionary = JSON.parse_string(text)
	assert_eq(fights.size(), 40, "40 saved fights")
	var unstruck: int = 0
	var opened: int = 0
	for fight_name: Variant in fights:
		var events: Array = fights[fight_name]
		var catalog: Dictionary = {}
		ViewAdapter.add_fight_cards(_content, events, catalog)
		var game: FightReplay = FightReplay.build(_base(), events, catalog, Compare.DAMAGE)
		var first: Dictionary = game.views[0]
		var whole: Dictionary = game.views.back()
		FightScreen.schedule(game)
		var plan: FightTimeline = game.plan
		var last: Dictionary = game.steps.back()
		var shown: Dictionary = last["state"]
		assert_eq(
			JSON.stringify(shown["boards"]),
			JSON.stringify(whole["boards"]),
			"%s ends on the log's board" % fight_name
		)
		var ending: Dictionary = events.back()
		assert_eq(str(ending["type"]), "combat_end")
		var survivors: Array = ending["survivors"]
		for side: int in 2:
			var core: Array = []
			for uid: Variant in survivors[side]:
				core.append(_i(uid))
			core.sort()
			assert_eq(
				_uids(shown, side), core, "%s side %d: the core's survivors" % [fight_name, side]
			)
		for key: Variant in plan.segments:
			var pose: Dictionary = plan.pose(str(key), float(plan.end_frame))
			assert_true(_at_rest(pose), "%s: %s at rest at the end (%s)" % [fight_name, key, pose])
			for value: Variant in plan.segments[key]:
				var seg: Dictionary = value
				if str(seg["kind"]) == "pulse":
					assert_true(
						absf(_f(seg.get("aim", 0.0))) <= FightMotion.JAB_TURN_CAP + 0.001,
						"%s: %s jab turn within the cap" % [fight_name, key]
					)
		var zero: Dictionary = game.steps[0]
		var zero_view: Dictionary = zero["state"]
		assert_eq(_i(zero["frame"]), 0)
		assert_eq(
			JSON.stringify(zero_view["boards"]),
			JSON.stringify(first["boards"]),
			"%s: frame 0 is the first board" % fight_name
		)
		assert_gt(_i(game.steps[1]["frame"]), 0, "%s: nothing else at frame 0" % fight_name)
		for burst: Dictionary in plan.bursts:
			assert_gt(_i(burst["frame"]), 0, "%s: no burst at frame 0" % fight_name)
		for attack: Dictionary in plan.attacks:
			if _i(attack["contact"]) < 0 and _i(attack["home"]) >= 0:
				unstruck += 1
		for k: int in range(1, events.size()):
			var event: Dictionary = events[k]
			if str(event["type"]) == "attack":
				break
			opened += 1
	assert_gt(unstruck, 0, "the sample has attackers whose target died before the hit")
	assert_gt(opened, 0, "and Start of Combat effects")


## Rule C: a hit an effect makes that a shield blocks stays with its beat: its 0 shows as the
## beat lands, not as an exchange of its own.
func test_a_blocked_effect_hit_stays_with_its_beat() -> void:
	var events: Array = _three_units()
	(
		events
		. append_array(
			[
				_attack(1, 0, 0, 2, 1, 0),
				_damage(2, 1, 0, 2, 3, 1, true),
				_damage(1, 0, 0, 2, 1, 2, true),
				{"type": "trigger", "side": 0, "slot": 1, "uid": 3, "mechanic": "test_sling"},
				{
					"type": "prevented",
					"side": 1,
					"slot": 0,
					"uid": 2,
					"amount": 1,
					"reason": "absorbed",
					"source_uid": 3,
				},
				{"type": "combat_end", "winner": -1},
			]
		)
	)
	var plan: FightTimeline = _schedule(events)
	assert_eq(plan.attacks.size(), 1, "one attack")
	assert_eq(plan.bursts.size(), 3, "the exchange's two, and the blocked one")
	var attack: Dictionary = plan.attacks[0]
	var blocked: Dictionary = plan.bursts[2]
	assert_true(_b(blocked["blocked"]), "the shield's 0")
	assert_eq(str(blocked["key"]), "u2")
	var pulse: Dictionary = {}
	for seg: Dictionary in plan.segments["u3"]:
		if str(seg["kind"]) == "pulse":
			pulse = seg
	assert_false(pulse.is_empty(), "the slinger pulses")
	assert_eq(_i(blocked["frame"]), _i(pulse["land"]), "its 0 shows as the beat lands")
	assert_gt(
		_i(blocked["frame"]), _i(attack["contact"]) + FightTimeline.NUMBERS_AT, "after the hit"
	)
	var u1: Array = plan.segments["u1"]
	assert_eq(u1.filter(func(seg: Dictionary) -> bool: return seg["kind"] == "attack").size(), 1)


## best.md: a defender killed before the hit (here by a pile-on) skips the exchange; the attacker
## settles back unstruck over 8 f as the defender's fall ends, never striking.
func test_an_attacker_whose_target_died_first_settles_back_unstruck() -> void:
	var events: Array = _three_units()
	(
		events
		. append_array(
			[
				_attack(3, 0, 1, 2, 1, 0),
				{"type": "trigger", "side": 0, "slot": 0, "uid": 1, "mechanic": "mouse_pile_on"},
				{"type": "hit", "side": 0, "slot": 0, "uid": 1, "target_uid": 2},
				_damage(2, 1, 0, 6, -3, 1, false),
				{"type": "death", "side": 1, "slot": 0, "uid": 2},
				{"type": "combat_end", "winner": 0},
			]
		)
	)
	var plan: FightTimeline = _schedule(events)
	var attack: Dictionary = plan.attacks[0]
	assert_eq(_i(attack["contact"]), -1, "it never strikes")
	assert_eq(plan.bursts.size(), 1, "only the pile-on's hit")
	var fall: Dictionary = plan.falls[0]
	var settle: int = _i(fall["frame"]) + _i(fall["frames"])
	assert_eq(_i(attack["home"]), settle + FightTimeline.SETTLE, "home 8 f after the fall ends")
	var raised: Dictionary = plan.pose("u3", float(settle))
	assert_gt(_f(raised["scale"]), 1.05, "still raised as the fall ends")
	assert_gt(absf(_f(raised["turn"])), 1.0, "and turned toward its target")
	assert_true(
		_at_rest(plan.pose("u3", float(settle + FightTimeline.SETTLE))), "home and straight"
	)


## best.md's hold: pilers jab 5 f apart, the target's burst re-popping with the total; each jab
## turns toward its target.
func test_pilers_jab_five_frames_apart_and_turn() -> void:
	var events: Array = _three_units()
	var fourth: Dictionary = {"uid": 4, "id": "d", "side": 0, "slot": 2, "attack": 2, "health": 3}
	var start: Dictionary = events[0]
	var boards: Array = start["boards"]
	var yours: Array = boards[0]
	yours.append(fourth)
	(
		events
		. append_array(
			[
				_attack(1, 0, 0, 2, 1, 0),
				{"type": "trigger", "side": 0, "slot": 1, "uid": 3, "mechanic": "mouse_pile_on"},
				{"type": "hit", "side": 0, "slot": 1, "uid": 3, "target_uid": 2},
				_damage(2, 1, 0, 1, 4, 3, false),
				{"type": "uses", "side": 0, "slot": 2, "uid": 4, "key": "mouse_pile_on", "left": 0},
				{"type": "trigger", "side": 0, "slot": 2, "uid": 4, "mechanic": "mouse_pile_on"},
				{"type": "hit", "side": 0, "slot": 2, "uid": 4, "target_uid": 2},
				_damage(2, 1, 0, 1, 3, 4, false),
				_damage(2, 1, 0, 2, 1, 1, true),
				_damage(1, 0, 0, 2, 1, 2, true),
				{"type": "combat_end", "winner": -1},
			]
		)
	)
	var plan: FightTimeline = _schedule(events)
	var first: Dictionary = plan.bursts[0]
	var second: Dictionary = plan.bursts[1]
	assert_eq(_i(second["frame"]) - _i(first["frame"]), FightTimeline.PILE_GAP, "5 f apart")
	assert_true(_b(second["merge"]), "the second re-pops")
	assert_eq(_i(second["amount"]), 2, "with the total")
	# the second piler stands off its target's line (the first is straight below it)
	assert_gt(absf(plan.jab_turn("u4", _f(second["frame"]))), 5.0, "the piler turns as it lands")
	assert_eq(plan.jab_turn("u4", float(plan.end_frame)), 0.0, "and straightens")
	assert_gt(_i(plan.attacks[0]["contact"]), _i(second["frame"]), "then the attacker strikes")


## best.md's fight frame: Start of Combat plays after the 30 f rest as beats; a unit it kills
## falls on screen, and the first attacker waits for it.
func test_start_of_combat_plays_after_the_rest() -> void:
	var events: Array = _three_units()
	(
		events
		. append_array(
			[
				{
					"type": "trigger",
					"side": 1,
					"slot": 0,
					"uid": 2,
					"mechanic": "start_combat_damage"
				},
				_damage(3, 0, 1, 3, 0, 2, false),
				{"type": "death", "side": 0, "slot": 1, "uid": 3},
				_attack(1, 0, 0, 2, 1, 0),
				_damage(2, 1, 0, 2, 1, 1, true),
				_damage(1, 0, 0, 2, 1, 2, true),
				{"type": "combat_end", "winner": -1},
			]
		)
	)
	var plan: FightTimeline = _schedule(events)
	assert_gt(_i(plan.steps[1]["frame"]), 0, "nothing but the first board at frame 0")
	var hit: Dictionary = plan.bursts[0]
	assert_eq(str(hit["key"]), "u3")
	assert_eq(
		_i(hit["frame"]), FightTimeline.REST + FightTimeline.BEAT_LAND, "a beat after the rest"
	)
	var fall: Dictionary = plan.falls[0]
	assert_eq(str(fall["key"]), "u3", "the killed unit falls on screen")
	assert_gt(_i(plan.attacks[0]["launch"]), _i(fall["frame"]) + _i(fall["frames"]), "then attacks")
	var trigger: Dictionary = plan.cues[0]
	assert_eq(str(trigger["kind"]), "trigger")
	assert_eq(_i(trigger["frame"]), FightTimeline.REST, "its sound with its pulse")


func _three_units() -> Array:
	var a: Dictionary = {"uid": 1, "id": "a", "side": 0, "slot": 0, "attack": 2, "health": 3}
	var c: Dictionary = {"uid": 3, "id": "c", "side": 0, "slot": 1, "attack": 1, "health": 3}
	var b: Dictionary = {"uid": 2, "id": "b", "side": 1, "slot": 0, "attack": 2, "health": 5}
	return [{"type": "combat_start", "boards": [[a, c], [b]]}]


static func _attack(
	uid: int, side: int, slot: int, target: int, target_side: int, target_slot: int
) -> Dictionary:
	var event: Dictionary = {"type": "attack", "uid": uid, "side": side, "slot": slot}
	event.merge({"target_uid": target, "target_side": target_side, "target_slot": target_slot})
	return event


static func _damage(
	uid: int, side: int, slot: int, amount: int, health: int, source: int, from_attack: bool
) -> Dictionary:
	var event: Dictionary = {"type": "damage", "uid": uid, "side": side, "slot": slot}
	event.merge(
		{"amount": amount, "health": health, "source_uid": source, "from_attack": from_attack}
	)
	return event


func _schedule(events: Array) -> FightTimeline:
	var replay: FightReplay = FightReplay.build({}, events, {})
	FightScreen.schedule(replay)
	return replay.plan


static func _uids(view: Dictionary, side: int) -> Array:
	var out: Array = []
	var boards: Array = view["boards"]
	var row: Array = boards[side]
	for value: Variant in row:
		if value is Dictionary:
			var unit: Dictionary = value
			out.append(_i(unit["uid"]))
	out.sort()
	return out


static func _at_rest(pose: Dictionary) -> bool:
	var offset: Vector2 = pose["offset"]
	return (
		offset.is_zero_approx()
		and is_equal_approx(_f(pose["scale"]), 1.0)
		and is_zero_approx(_f(pose["turn"]))
	)


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


static func _b(v: Variant) -> bool:
	return v == true


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
