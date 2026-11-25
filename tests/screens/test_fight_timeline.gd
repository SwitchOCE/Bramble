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
## Every tenth of the 400 saved late fights' logs, by name (test_late_fights_end_true_and_at_rest).
const LATE_FIGHTS: String = "res://tests/screens/fixtures/late_fights.json.gz"

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


static func _base() -> Dictionary:
	var base: Dictionary = GlassScreen.load_state(Compare.BASE_PATH)
	base.erase("boards")
	base["slots"] = [[], []]
	return base


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
