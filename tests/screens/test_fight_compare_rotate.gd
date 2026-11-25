extends GutTest
## The rotation switch of the comparison fight (tests/screens/feel/fight_compare/rotate.gd):
## "options": {"ROTATE": "on"} turns every attacker toward its target, in every treatment, with
## rotate.gd's one set of numbers; off, every treatment is as it was. And the `recommended`
## treatment (recommended.gd): every pick together in one fight. Exploratory; nothing here is the
## game.

const Compare := preload("res://tests/screens/feel/fight_compare/fight_compare.gd")
const Treatments := preload("res://tests/screens/feel/fight_compare/treatments.gd")
const Timeline := preload("res://tests/screens/feel/fight_compare/best_timeline.gd")
const Rotate := preload("res://tests/screens/feel/fight_compare/rotate.gd")
const RotateMotion := preload("res://tests/screens/feel/fight_compare/rotate_motion.gd")
const TodayMotion := preload("res://tests/screens/feel/fight_compare/today_motion.gd")
const PilotMotion := preload("res://tests/screens/feel/fight_compare/pilot_motion.gd")
const HeroDamage := preload("res://tests/screens/feel/fight_compare/pilot_hero_damage.gd")
const Recommended := preload("res://tests/screens/feel/fight_compare/recommended.gd")
const ON: Dictionary = {"ROTATE": "on"}

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_the_set_is_the_default_until_the_owner_picks() -> void:
	assert_almost_eq(_f(Rotate.SET["aim"]), 0.95, 0.0001, "aim at 95 % of the path")
	assert_almost_eq(_f(Rotate.SET["keystone"]), 0.94, 0.0001, "medium lean: keystone 0.94")
	assert_almost_eq(_f(Rotate.SET["length"]), 0.85, 0.0001, "medium lean: length 0.85")
	assert_true(Rotate.on(ON), "on")
	assert_false(Rotate.on({}), "off by default")
	var lean: Dictionary = {"ROTATE": "lean"}
	assert_true(Rotate.on(lean), "lean: on")
	assert_eq(Rotate.set_of(lean), Rotate.SET_LEAN, "lean: the owner's pick of 25 Nov")
	assert_eq(Rotate.set_of(ON), Rotate.SET, "on: the medium tip")
	assert_almost_eq(_f(Rotate.SET_LEAN["aim"]), FightMotion.TURN_AIM, 0.0001, "the game's aim")
	assert_almost_eq(_f(Rotate.SET_LEAN["lean"]), FightMotion.TURN_LEAN, 0.0001, "the game's lean")


func test_the_timing_is_cb9s() -> void:
	# best's wind-up: lift 10, hold 16, strike 8: full at C-12, as best_timeline.gd's aim_ramp
	assert_eq(Rotate.ramp_frames(10, 16, 8), 22.0, "full at C-12")
	assert_eq(Rotate.ramp_frames(4, 0, 8), 4.0, "today's short attack: full as the lift ends")
	var full: Dictionary = Rotate.approach(4.0, 4.0, 4.0, 8.0, 2.0)
	assert_almost_eq(_f(full["share"]), 1.0, 0.0001, "full turn as the strike starts")
	var at_contact: Dictionary = Rotate.approach(12.0, 4.0, 4.0, 8.0, 2.0)
	assert_almost_eq(_f(at_contact["share"]), 0.9, 0.0001, "90 % at contact")
	assert_almost_eq(_f(at_contact["keystone"]), 0.94, 0.0001, "the lean's keystone at contact")
	assert_almost_eq(_f(at_contact["length"]), 0.85, 0.0001, "the lean's length at contact")
	var home: Dictionary = Rotate.leaving(25.0)
	assert_almost_eq(_f(home["share"]), 0.0, 0.0001, "straight 25 f after the return starts")
	assert_almost_eq(_f(home["keystone"]), 1.0, 0.0001, "flat again")
	var still: Dictionary = Rotate.leaving(10.0)
	assert_gt(_f(still["share"]), 0.5, "still turned 10 f into the return (lands turned)")
	var up_right: Dictionary = Rotate.aim_of(Vector2(1.0, -1.0).normalized())
	assert_almost_eq(_f(up_right["turn"]), 0.95 * 45.0, 0.001, "yours, up-right: 95 % of 45 deg")
	assert_eq(_f(up_right["lead"]), 1.0, "the top of yours leads")
	var down_left: Dictionary = Rotate.aim_of(Vector2(-1.0, 1.0).normalized())
	assert_almost_eq(_f(down_left["turn"]), 0.95 * 45.0, 0.001, "theirs, down-left: clockwise")
	assert_eq(_f(down_left["lead"]), -1.0, "the bottom of theirs leads")


func test_off_every_treatment_plays_as_before() -> void:
	var today: RefCounted = Treatments.make("today")
	today.call("configure", {})
	var layer: Control = Control.new()
	add_child_autofree(layer)
	var motion: FightMotion = today.call("make_motion", layer)
	var script: Script = motion.get_script()
	assert_eq(script, TodayMotion, "today off: today's motion (today_motion.gd)")
	var pilot: RefCounted = Treatments.make("pilot")
	pilot.call("configure", {"CB13": "c"})
	var dying: FightMotion = pilot.call("make_motion", layer)
	var dying_on: bool = dying.get("turn_on")
	assert_false(dying_on, "pilot off: no turn")
	var plan: Dictionary = _plan("best", {})
	var claims: Dictionary = plan["claims"]
	var used: Dictionary = claims["rotation"]
	var picked: Dictionary = Timeline.ROTATIONS[Timeline.PICKS["CB9"]]
	assert_eq(used, picked, "best off: CB9's pick")


func test_on_today_and_pilot_turn() -> void:
	var layer: Control = Control.new()
	add_child_autofree(layer)
	var today: RefCounted = Treatments.make("today")
	today.call("configure", ON)
	var motion: FightMotion = today.call("make_motion", layer)
	var script: Script = motion.get_script()
	assert_eq(script, RotateMotion, "today on: today's motion with the turn")
	var on: bool = motion.get("turn_on")
	assert_true(on, "turning")
	for option: String in ["today", "c"]:
		var pilot: RefCounted = Treatments.make("pilot")
		pilot.call("configure", {"CB13": option, "ROTATE": "on"})
		var made: FightMotion = pilot.call("make_motion", layer)
		var turning: bool = made.get("turn_on")
		assert_true(turning, "pilot CB13 %s on: turning" % option)
		assert_true(made is RotateMotion, "pilot CB13 %s: a rotate_motion.gd" % option)


func test_on_today_turns_on_top_of_its_own_attack_and_unwinds() -> void:
	var layer: Control = Control.new()
	add_child_autofree(layer)
	var motion: FightMotion = RotateMotion.new(layer)
	motion.set("turn_on", true)
	var card: Control = Control.new()
	card.size = Vector2(216.0, 250.0)
	layer.add_child(card)
	var home: Vector2 = Vector2(500.0, 600.0)
	card.position = home
	var way: Vector2 = Vector2(1.0, -1.0).normalized()
	var at: Vector2 = home + way * 300.0
	motion.set("_key", "u1")
	motion.call("_attack", card, at, way)
	_step(motion, card, 12)
	var lean: float = TodayMotion.TODAY_WINDUP_TURN * -1.0
	var aim: float = 0.95 * 45.0
	assert_almost_eq(card.position.x, at.x, 0.01, "at contact, as today")
	assert_almost_eq(
		card.rotation_degrees, -lean / 2.0 + aim * 0.9, 0.01, "today's tilt + 90 % turn"
	)
	assert_almost_eq(card.scale.x, TodayMotion.TODAY_LIFT_SCALE, 0.0001, "today's lift scale")
	assert_almost_eq(
		card.scale.y, TodayMotion.TODAY_LIFT_SCALE * 0.85, 0.0001, "shorter along its length"
	)
	assert_almost_eq(_keystone(card), 0.94, 0.0001, "tipped")
	motion.call("_hit", card, home, {"returning": true, "direction": way})
	_step(motion, card, 2 + 11)
	assert_almost_eq(card.position.x, home.x, 0.01, "home after today's 2 + 11 frames")
	assert_gt(card.rotation_degrees, 5.0, "lands still turned")
	_step(motion, card, 14)
	assert_almost_eq(card.rotation_degrees, 0.0, 0.01, "straight 25 f into the return")
	assert_eq(card.scale, Vector2.ONE, "full size")
	assert_null(card.material, "drawn flat again")


func test_lean_is_fight_motions_turn_frame_for_frame() -> void:
	# "ROTATE": "lean" on today's motion (rotate_motion.gd) against FightMotion's attack (its turn
	# numbers are the schedule's; the game plays FightTimeline in a fight since step 1b): the same
	# attack, contact, wait and return, the same pose every 1/60 s
	var layer: Control = Control.new()
	add_child_autofree(layer)
	var fixture: FightMotion = RotateMotion.new(layer)
	fixture.set("turn_on", true)
	fixture.set("turn_set", Rotate.SET_LEAN)
	fixture.set("_key", "u1")
	var game: FightMotion = FightMotion.new(layer)
	game.set("_placing", "u1")
	var home: Vector2 = Vector2(500.0, 600.0)
	for way: Vector2 in [Vector2(1.0, -1.0).normalized(), Vector2(-0.4, 1.0).normalized()]:
		var cards: Array[Control] = []
		for motion: FightMotion in [fixture, game]:
			var card: Control = Control.new()
			card.size = Vector2(216.0, 250.0)
			card.position = home
			layer.add_child(card)
			cards.append(card)
			motion.call("_attack", card, home + way * 300.0, way)
		for frame: int in 12:
			_step(fixture, cards[0], 1)
			_step(game, cards[1], 1)
			_same_pose(cards, "attack frame %d" % (frame + 1))
		assert_gt(absf(cards[1].rotation_degrees), 5.0, "turned at contact")
		for i: int in 2:
			var motion: FightMotion = [fixture, game][i]
			motion.call("_hit", cards[i], home, {"returning": true, "direction": way})
		for frame: int in 30:
			_step(fixture, cards[0], 1)
			_step(game, cards[1], 1)
			_same_pose(cards, "return frame %d" % (frame + 1))
		assert_almost_eq(cards[1].rotation_degrees, 0.0, 0.0001, "straight again")
	var mid: Control = Control.new()
	mid.size = Vector2(216.0, 250.0)
	layer.add_child(mid)
	fixture.call("_attack", mid, home + Vector2(300.0, -300.0), Vector2(1.0, -1.0).normalized())
	_step(fixture, mid, 2)
	var turns: Dictionary = fixture.get("_aims")
	var aimed: Dictionary = turns["u1"]
	assert_gt(_f(aimed["lean_now"]), 1.0, "the lean is there during the lift")
	assert_null(mid.material, "no tip shader")


func _same_pose(cards: Array[Control], moment: String) -> void:
	var a: Control = cards[0]
	var b: Control = cards[1]
	assert_almost_eq(b.rotation_degrees, a.rotation_degrees, 0.001, "rotation, %s" % moment)
	assert_almost_eq(b.position.distance_to(a.position), 0.0, 0.001, "place, %s" % moment)
	assert_almost_eq(b.scale.x, a.scale.x, 0.0001, "scale across, %s" % moment)
	assert_almost_eq(b.scale.y, a.scale.y, 0.0001, "scale along, %s" % moment)


func test_on_best_uses_the_set_for_every_attack() -> void:
	var plan: Dictionary = _plan("best", ON)
	var claims: Dictionary = plan["claims"]
	var used: Dictionary = claims["rotation"]
	assert_eq(used, Rotate.SET, "best on: rotate.gd's set in place of CB9's")
	var timeline: RefCounted = _timeline("best", ON)
	var attacks: Array = plan["attacks"]
	var first: Dictionary = attacks[0]
	var pose: Dictionary = timeline.call("pose", str(first["attacker"]), _i(first["contact"]))
	assert_almost_eq(_f(pose["keystone"]), 0.94, 0.0001, "tipped at contact")
	assert_almost_eq(_f(pose["length"]), 0.85, 0.0001, "shorter at contact")
	var far: Dictionary = attacks[1]
	assert_ne(_f(far["aim_deg"]), 0.0, "a diagonal attack turns")


func test_on_cb12_b_portrait_turns_toward_the_loser() -> void:
	var plain: RefCounted = _damage({})
	var turned: RefCounted = _damage(Rotate.SET)
	var contact: int = HeroDamage.B_CONTACT
	var flat: Dictionary = _striker(plain, contact)
	var aimed: Dictionary = _striker(turned, contact)
	assert_false(flat.has("length"), "off: the striker as the spec has it")
	var way: Vector2 = Vector2(104.0, 994.0) - Vector2(1796.0, 160.0)
	var full: float = 0.95 * rad_to_deg(Vector2.DOWN.angle_to(way.normalized()))
	var turn_off: float = flat["turn"]
	var turn_on: float = aimed["turn"]
	assert_almost_eq(turn_on - turn_off, full * 0.9, 0.01, "90 % of the turn at contact")
	assert_almost_eq(_f(aimed["length"]), 0.85, 0.0001, "shorter along its length")
	assert_eq(_f(aimed["lead"]), -1.0, "their portrait: the bottom leads, down to yours")
	var full_at: Dictionary = _striker(turned, contact - 12)
	var lean_at: float = _striker(plain, contact - 12)["turn"]
	assert_almost_eq(_f(full_at["turn"]) - lean_at, full, 0.01, "full at C-12")
	var home: int = _i(turned.call("home_frame"))
	var back: Dictionary = _striker(turned, home + Rotate.AIM_STRAIGHT)
	assert_almost_eq(_f(back["turn"]), 0.0, 0.01, "straight again after the return")


func test_recommended_plays_every_pick_and_ends_on_the_cores_board() -> void:
	var made: RefCounted = Treatments.make("recommended")
	made.call("configure", {})
	var options: Dictionary = made.get("options")
	for key: String in Recommended.PICKED:
		var got: String = str(options.get(key))
		var want: String = str(Recommended.PICKED[key])
		assert_eq(got, want, "%s at its pick" % key)
	var played: RefCounted = _made("recommended", {})
	var plan: Dictionary = played.call("plan")
	var claims: Dictionary = plan["claims"]
	var used: Dictionary = claims["rotation"]
	assert_eq(used, Rotate.SET, "rotation on")
	assert_eq(_f(claims["curve"]), _f(Timeline.CURVES["mild"]), "CB11 mild: the mild ease-in")
	var stop: Dictionary = claims["stop"]
	var stop_b: Dictionary = Timeline.STOPS["b"]
	assert_eq(stop, stop_b, "CB11 mild's set: stop B")
	# CB14 c's beats push two of CB8 c's staggered deaths a few frames late; nothing else bends
	var notes: Array = plan["notes"]
	assert_lte(notes.size(), 2, "at most two bends")
	for value: Variant in notes:
		var note: String = value
		var found: RegExMatch = (
			RegEx.create_from_string("\\(death\\) shown at (\\d+), not (\\d+)").search(note)
		)
		assert_not_null(found, "only a death shown late: %s" % note)
		if found != null:
			var late: int = found.get_string(1).to_int() - found.get_string(2).to_int()
			assert_between(late, 1, 3, "a few frames late: %s" % note)
	var staggers: Array = plan["staggers"]
	assert_eq(staggers.size(), 1, "CB8 c: the six deaths staggered")
	var buffs: Dictionary = plan["buffs"]
	var gains: Array = buffs["gains"]
	assert_eq(gains.size(), 7, "CB14 c: Old Brock's gain in (d) and six in (e)")
	var solo: Dictionary = played.get("solo")
	for value: Variant in staggers[0]["falls"]:
		var fall: Dictionary = value
		assert_false(solo.has(fall["key"]), "%s falls with the group, not alone" % fall["key"])
	assert_true(solo.has("u8"), "Prophet of the Dust dies alone (CB13 c)")
	var layer: Control = Control.new()
	add_child_autofree(layer)
	var motion: FightMotion = made.call("make_motion", layer)
	assert_true(motion is PilotMotion, "CB13: pilot_motion.gd")
	var death: String = motion.get("option")
	assert_eq(death, "c", "CB13 c: the light goes out")
	var again: RefCounted = Treatments.make("recommended")
	again.call("configure", {"CB8": "a"})
	var mine: Dictionary = again.get("options")
	var stagger: String = mine["CB8"]
	assert_eq(stagger, "a", "a scenario's own option wins")


func test_recommended_plays_on_the_screen() -> void:
	var scene: Control = (
		preload("res://tests/screens/feel/fight_compare/fight_compare.tscn").instantiate()
	)
	add_child_autofree(scene)
	scene.call("start", "recommended", {})
	var screen: FightScreen = scene.get("screen")
	assert_true(screen.is_playing(), "playing")
	assert_true(screen._keeper is PilotMotion, "its deaths drawn by pilot_motion.gd")


func _plan(treatment_name: String, chosen: Dictionary) -> Dictionary:
	var made: RefCounted = _made(treatment_name, chosen)
	var plan: Dictionary = made.call("plan")
	return plan


func _timeline(treatment_name: String, chosen: Dictionary) -> RefCounted:
	var made: RefCounted = _made(treatment_name, chosen)
	var timeline: RefCounted = made.get("timeline")
	return timeline


func _made(treatment_name: String, chosen: Dictionary) -> RefCounted:
	var combat: Combat = Compare.fight_named(_content, "")
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	var made: RefCounted = Treatments.make(treatment_name)
	made.call("configure", chosen)
	made.call("make_replay", base, combat.events, {}, Compare.DAMAGE)
	return made


func _damage(chosen: Dictionary) -> RefCounted:
	var damage: RefCounted = HeroDamage.new("b")
	damage.set("old_health", 30)
	damage.set("base", 7)
	damage.set("total", 7)
	damage.set("winner_at", Vector2(1796.0, 160.0))
	damage.set("loser_at", Vector2(104.0, 994.0))
	damage.set("rotation_set", chosen)
	return damage


static func _striker(damage: RefCounted, f: int) -> Dictionary:
	var pose: Dictionary = damage.call("pose", f)
	return pose["striker"]


## Runs the card's tween on `frames` frames of 1/60 s.
static func _step(motion: FightMotion, card: Control, frames: int) -> void:
	var tweens: Dictionary = motion.get("_tweens")
	for k: int in frames:
		var tween: Tween = tweens.get(card)
		if tween == null or not tween.is_valid():
			return
		tween.custom_step(1.0 / 60.0)


static func _keystone(card: Control) -> float:
	var mat: ShaderMaterial = card.material as ShaderMaterial
	if mat == null:
		return 1.0
	return GlassPieces.as_float(mat.get_shader_parameter("keystone"))


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
