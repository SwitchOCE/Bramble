extends GutTest
## The `pilot` treatment of the comparison fight (tests/screens/feel/fight_compare/pilot.gd): the
## animation pilot's cheap options for CB12 (damage to the player) and CB13 (a single death). Its
## short loss fights lose as the filming plan says, and each option's schedule keeps its beat
## spec's frames (pilot/player-damage.md and pilot/death.md, section 4). Exploratory; nothing
## here is the game.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const HeroDamage := preload("res://tests/screens/feel/fight_compare/pilot_hero_damage.gd")
const PilotMotion := preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")
const PilotScreen := preload("res://tests/screens/feel/fight_compare/pilot_screen.gd")
const Tokens := preload("res://tests/screens/feel/fight_compare/pilot_tokens.gd")
const SCENE: PackedScene = preload("res://tests/screens/feel/fight_compare/fight_compare.tscn")

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_the_loss_fights_lose_as_planned() -> void:
	var turn: int = _i(GlassScreen.load_state(Compare.BASE_PATH).get("turn", 1))
	var expected: Dictionary = {"lose-small": false, "lose-big": true, "lose-out": false}
	for which: String in expected:
		var fought: Combat = Compare.fight_named(_content, which)
		assert_eq(_i(fought.result["winner"]), 1, "%s: you lose" % which)
		var loss: Array = Compare.loss_of(_content, fought, turn)
		var big: bool = _b(loss[1])
		var wanted: bool = _b(expected[which])
		assert_eq(big, wanted, "%s: big loss" % which)
		assert_eq(_i(loss[0]), turn + 1 + (3 if big else 0), "%s: round + 1 (+3 if big)" % which)


func test_cb12_options_hold_the_old_health_until_the_hit() -> void:
	for option: String in ["b", "c"]:
		var replay: FightReplay = _replay({"CB12": option}, "lose-big")
		var state: Dictionary = _state(replay, 1)
		var before: Dictionary = _state(replay, 2)
		var shown: int = _i(state["health"])
		assert_eq(shown, _i(before["health"]), "%s: the result shows the old Health" % option)
		var moment: Dictionary = state["moment"]
		var result: Dictionary = moment["result"]
		var pilot: Dictionary = result["pilot"]
		assert_true(_b(pilot["big"]), "%s: big" % option)
		assert_eq(_i(pilot["total"]) - _i(pilot["base"]), 3, "%s: the +3 split" % option)
		var new_health: int = _i(pilot["new"])
		assert_eq(new_health, _i(pilot["old"]) - _i(pilot["total"]), "%s: new Health" % option)
	var today: FightReplay = _replay({}, "lose-big")
	var now: int = _i(_state(today, 1)["health"])
	assert_ne(now, _i(_state(today, 2)["health"]), "today: the new Health on the result's frame")


func test_cb12_b_keeps_its_beat_spec() -> void:
	var small: RefCounted = _damage("b", false)
	assert_eq(_ints(small.call("contacts")), [47], "C = R+47")
	assert_eq(_i(small.call("home_frame")), 66, "home at C+19")
	assert_eq(_i(small.call("count_end")), 67, "Health final at R+67")
	var marks: Dictionary = small.call("markers")
	assert_eq(_strings(marks[12]), ["hero_windup"], "lift from R+12")
	assert_eq(_strings(marks[37]), ["hero_launch"], "strike from R+37")
	var lifted: Dictionary = _striker(small, 22)
	var held: Dictionary = _striker(small, 36)
	var lifted_at: Vector2 = lifted["offset"]
	var held_at: Vector2 = held["offset"]
	assert_eq(lifted_at, held_at, "still through the hold")
	assert_almost_eq(_f(lifted["scale"]), HeroDamage.B_LIFT_SCALE, 0.001, "x1.15 at the lift's end")
	var big: RefCounted = _damage("b", true)
	assert_eq(_ints(big.call("contacts")), [47, 62], "C2 = C+15")
	assert_eq(_i(big.call("home_frame")), 81, "home at C2+19")


func test_cb12_c_keeps_its_beat_spec() -> void:
	var small: RefCounted = _damage("c", false)
	assert_eq(_ints(small.call("contacts")), [32], "C = R+32")
	assert_eq(_i(small.call("count_end")), 52, "Health final at R+52")
	assert_eq(_i(small.call("home_frame")), -1, "nothing travels")
	var big: RefCounted = _damage("c", true)
	assert_eq(_ints(big.call("contacts")), [32, 48], "C2 = C+16")


func test_cb12_health_changes_only_after_contact_and_all_ends_at_rest() -> void:
	for option: String in ["b", "c"]:
		for big: bool in [false, true]:
			var damage: RefCounted = _damage(option, big)
			var contact: int = _ints(damage.call("contacts"))[0]
			var label: String = "%s %s" % [option, "big" if big else "small"]
			var widest: float = 0.0
			var early: Array[int] = []
			for f: int in HeroDamage.BUDGET + 1:
				var pose: Dictionary = damage.call("pose", f)
				var stage: Vector2 = pose["stage"]
				widest = maxf(widest, stage.length())
				if f < contact and _i(pose["health"]) != 30:
					early.append(f)
			assert_eq(early, [] as Array[int], "%s: the old Health until C" % label)
			assert_lt(widest, 20.01, "%s: shake at most 20 px (E4)" % label)
			var end: Dictionary = damage.call("pose", HeroDamage.BUDGET)
			var striker: Dictionary = end["striker"]
			var home: Vector2 = striker["offset"]
			var stage_end: Vector2 = end["stage"]
			assert_eq(home, Vector2.ZERO, "%s: striker home (S2)" % label)
			assert_eq(stage_end, Vector2.ZERO, "%s: stage at rest (S2)" % label)
			var burst: Dictionary = end["burst"]
			assert_false(_b(burst["shown"]), "%s: the -N gone by R+150" % label)
			assert_eq(_i(end["health"]), 30 - (10 if big else 7), "%s: the whole loss" % label)


func test_cb13_single_deaths_are_the_lone_ones() -> void:
	var treatment: RefCounted = Treatments.make("pilot")
	treatment.call("configure", {"CB13": "b"})
	var combat: Combat = Compare.fight(_content)
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	treatment.call("make_replay", base, combat.events, {}, Compare.DAMAGE)
	var solo: Dictionary = treatment.get("solo")
	assert_true(solo.has("u8"), "Prophet of the Dust, killed attacking, dies alone")
	assert_true(solo.has("u9"), "the last kill dies alone")
	for six: String in ["u1", "u2", "u5", "u6", "u7", "u11"]:
		assert_false(solo.has(six), "%s dies with five others: CB8's, today's fall" % six)


func test_cb13_options_keep_their_beat_spec() -> void:
	assert_eq(PilotMotion.gone_frame("b"), 21, "B gone at D+21")
	assert_eq(PilotMotion.gone_frame("c"), 23, "C gone at D+23")
	assert_eq(PilotMotion.number_alpha("b", 16), 1.0, "B: the number full to D+16")
	assert_eq(PilotMotion.number_alpha("b", 24), 0.0, "B: gone at D+24")
	assert_eq(PilotMotion.number_alpha("c", 18), 1.0, "C: the number full to D+18")
	assert_eq(PilotMotion.number_alpha("c", 26), 0.0, "C: gone at D+26")


func test_easing_tokens_keep_their_values() -> void:
	# cubic-bezier(0, 0, 0.2, 1) and (0.4, 0, 1, 1), read off by bisection before the tokens used
	# GlassMotion.bezier
	var at: Array[float] = [0.1, 0.25, 0.5, 0.75, 0.9]
	var enter: Array[float] = [0.30385, 0.57757, 0.83925, 0.96422, 0.9946]
	var leave: Array[float] = [0.01837, 0.09863, 0.32481, 0.63009, 0.84375]
	for i: int in at.size():
		assert_almost_eq(Tokens.enter(at[i]), enter[i], 0.0001, "ease.enter at %s" % at[i])
		assert_almost_eq(Tokens.exit(at[i]), leave[i], 0.0001, "ease.exit at %s" % at[i])
	assert_eq(Tokens.enter(0.0), 0.0)
	assert_eq(Tokens.exit(1.0), 1.0)


func test_count_roll_steps_one_at_a_time() -> void:
	var shown: Array[int] = []
	for age: int in 19:
		shown.append(Tokens.roll(36, 29, age, 18))
	assert_eq(shown[0], 36, "starts at the old Health")
	assert_eq(shown[18], 29, "the new on the last frame")
	var jumps: Array[int] = []
	for k: int in range(1, shown.size()):
		if shown[k - 1] - shown[k] > 1:
			jumps.append(k)
	assert_eq(jumps, [] as Array[int], "one step at a time")


func test_the_pilot_scene_plays_its_options() -> void:
	var scene: Control = SCENE.instantiate()
	add_child_autofree(scene)
	scene.call("start", "pilot", {"CB12": "b", "CB13": "c"}, "lose-small")
	var screen: FightScreen = scene.get("screen")
	var script: Script = screen.get_script()
	var motion: Script = screen._keeper.get_script()
	assert_eq(script, PilotScreen, "the pilot's screen")
	assert_eq(motion, PilotMotion, "the pilot's death motion")
	assert_true(screen.is_playing(), "playing")


func _replay(options: Dictionary, which: String) -> FightReplay:
	var treatment: RefCounted = Treatments.make("pilot")
	treatment.call("configure", options)
	var fought: Combat = Compare.fight_named(_content, which)
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	var loss: Array = Compare.loss_of(_content, fought, _i(base.get("turn", 1)))
	return treatment.call("make_replay", base, fought.events, {}, _i(loss[0]))


## The state of the step `back` from the end (1: the result).
static func _state(replay: FightReplay, back: int) -> Dictionary:
	var step: Dictionary = replay.steps[replay.steps.size() - back]
	return step["state"]


func _damage(option: String, big: bool) -> RefCounted:
	var damage: RefCounted = HeroDamage.new(option)
	damage.set("big", big)
	damage.set("old_health", 30)
	damage.set("base", 7)
	damage.set("total", 10 if big else 7)
	damage.set("winner_at", Vector2(1796.0, 160.0))
	damage.set("loser_at", Vector2(104.0, 994.0))
	return damage


static func _striker(damage: RefCounted, f: int) -> Dictionary:
	var pose: Dictionary = damage.call("pose", f)
	return pose["striker"]


static func _ints(value: Variant) -> Array[int]:
	var out: Array[int] = []
	var listed: Array = value
	for item: Variant in listed:
		out.append(_i(item))
	return out


static func _strings(value: Variant) -> Array[String]:
	var out: Array[String] = []
	var listed: Array = value
	for item: Variant in listed:
		out.append(str(item))
	return out


static func _i(value: Variant) -> int:
	return CoreUtil.to_int(value)


static func _f(value: Variant) -> float:
	return GlassPieces.as_float(value)


static func _b(value: Variant) -> bool:
	return GlassPieces.as_bool(value)
