extends GutTest
## The game's fight schedule (src/screens/fight/fight_timeline.gd) is the fixture's `best` with
## the owner's picks (plan step 1b: CB2 b, CB3 mild, CB9 aim_lean, every other branch at best's
## pick): on the comparison fight, the same steps on the same frames, the same bursts, falls and
## glows, and every card's pose equal on every frame. And its sound cues sit on the moments they
## belong to.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")

## The fixture's options with exactly the game's picks.
const PICKS: Dictionary = {"CB2": "b", "CB3": "mild", "CB9": "aim_lean"}

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


## [the fixture's timeline, the game's replay] on fight `which`.
func _both(which: String = "") -> Array:
	var combat: Combat = Compare.fight_named(_content, which)
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	base.erase("boards")
	base["slots"] = [[], []]
	var catalog: Dictionary = {}
	ViewAdapter.add_fight_cards(_content, combat.events, catalog)
	var best: RefCounted = Treatments.make("best")
	best.call("configure", PICKS)
	var fixture: FightReplay = best.call(
		"make_replay", base, combat.events, catalog, Compare.DAMAGE
	)
	var game: FightReplay = FightReplay.build(base, combat.events, catalog, Compare.DAMAGE)
	FightScreen.schedule(game)
	return [fixture.get("timeline"), game]


func test_the_game_schedules_the_fixtures_best_with_the_picks() -> void:
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


func test_sound_cues_sit_on_their_moments() -> void:
	var game: FightReplay = _both()[1]
	var plan: FightTimeline = game.plan
	var kinds: Dictionary = {}
	for cue: Dictionary in plan.cues:
		kinds[str(cue["kind"])] = _i(kinds.get(str(cue["kind"]), 0)) + 1
	var hit_frames: Dictionary = {}
	for burst: Dictionary in plan.bursts:
		hit_frames[_i(burst["frame"])] = true
	assert_eq(_i(kinds.get("hit", 0)), hit_frames.size(), "a hit cue on every frame bursts show")
	var fall_frames: Dictionary = {}
	for fall: Dictionary in plan.falls:
		fall_frames[_i(fall["frame"])] = true
	assert_eq(_i(kinds.get("death", 0)), fall_frames.size(), "a death cue as each pass falls")
	assert_gt(_i(kinds.get("trigger", 0)), 0, "triggers sound as their source pulses")
	assert_eq(_i(kinds.get("summon", 0)), 1, "the Hopper's arrival")
	assert_eq(_i(kinds.get("result", 0)), 1, "the result")
	var last: Dictionary = plan.cues.back()
	assert_eq(str(last["kind"]), "result")
	assert_eq(_i(last["frame"]), plan.result_frame, "the result sounds as it shows")
	var six: Dictionary = {}
	for cue: Dictionary in plan.cues:
		if str(cue["kind"]) == "death":
			six[_i(cue["frame"])] = _i(cue["count"])
	assert_true(six.values().has(6), "moment (e)'s six deaths are one cue of six")
	for cue: Dictionary in plan.cues:
		var asked: Array[Dictionary] = SoundCues.for_fight_cue(cue, Sound.table)
		assert_false(asked.is_empty(), "%s asks for a cue" % cue["kind"])


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
