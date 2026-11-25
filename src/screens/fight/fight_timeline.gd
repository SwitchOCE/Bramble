# gdlint: disable=max-file-lines
class_name FightTimeline
extends RefCounted
## The fight's schedule: from the rules core's log and the board after each event (FightReplay
## views), the frame each change shows, every card's motion, every damage burst, glow and sound
## cue. FightScreen plays it on its game clock. It reads only the log; it decides nothing.
##
## It is the best proposal (docs/workstreams/fight-animation-24-nov/plans/best.md, sections 2 and
## 3) with the owner's picks of 25 Nov ("I want all the recommendations implemented into the
## game"; docs/workstreams/fight-animation-24-nov/PLAN-implement.md, step 1b), ported from the
## fight fixture's best_timeline.gd, which keeps every option and comparison:
##   the wind-up (CB1 best): a 10-frame lift to x1.14, 12 px back, held at least 16 frames;
##   the stop (CB2 b): 0.70 card heights between centres near, 0.50 far, no back-row rule;
##   the strike (CB3 mild, CB11 mild): an ease-in of power 1.6, 7 to 9 frames by distance;
##   a trigger before the hit (CB4 hold): it plays while the attacker is still raised, and the
##   strike runs unbroken after it;
##   a card killed in the exchange falls at contact + 30 (CB5 best); the next attacker lifts at
##   contact + 28, and no earlier than 16 frames before the queue ends (CB6 best);
##   one trigger many times (CB7 best): gaps from 18 frames shrinking x0.75 to a floor of 5, the
##   9th on landing together, the hit card keeping one burst that re-pops with the running total,
##   and rule 7's speed-up (past 120 frames of queue, x1 to x1.5);
##   the turn (CB9 aim_lean): every attacker turns toward its target by FightMotion.TURN_AIM of
##   the path's angle, with the TURN_LEAN in-plane lean the same way, no tip (the owner, 24 Nov:
##   "Every animation, I want to have the rotation included"; 25 Nov: the 4 degree lean), and
##   every jab turns the same way over its few frames;
##   several deaths at once (CB8 c, plan step 3): they fall one after another, 10/7/5/4/4 frames
##   apart within 30 (FightOrder puts the log in that order), each death's own gain beside it;
##   a stat gain (CB14 c; the owner's yes to the stand-in, 25 Nov): each +N is born at its cause
##   (the dead unit's slot, or the giver), flies into the stat and adds up in a tally over it, and
##   the changed disc swells and counts (FightGains draws them; the recruit screen's green gain
##   pill, arc and amber ring stand in for a designed marker);
##   the late-fight speed-ups (CB16; the owner's answer, 25 Nov: both): everything from the 5th
##   attack's lift to the result plays x1.5 (FAST: speed_at, advance), and up to 3 different
##   triggers in a row start together (GROUP: _run_queue).
## Beyond the fixture's `best`, from best.md: Start of Combat plays as a queue after the rest;
## an attacker whose target died before the hit settles back unstruck (8 f); pilers jab 5 f
## apart, the target's burst re-popping with the total.
## Frames are 1/60 s of game time at playback speed 1; frame 0 is the boards at rest. Every
## motion is a function of the frame (pose), so a card node the keeper rebuilds keeps its motion,
## and any frame rate shows the same moments.
##
## Not here yet (later steps of the plan): a single death's look (CB13 c: FightMotion's fall) and
## the winner's portrait striking (CB12 b: after the result in _make_steps). No one has watched
## this move.

## One card height on the 1920 x 1080 stage.
const H: float = 250.0
## CB1: the wind-up's lift (frames), the scale it lifts to, how far it pulls back (px), and the
## least it holds raised before the strike (frames).
const LIFT: int = 10
const LIFT_SCALE: float = 1.14
const PULL_PX: float = 12.0
const HOLD_LEAST: int = 16
## CB2 b: the gap between centres at the stop, in card heights: NEAR up to NEAR_D card heights
## away, FAR from FAR_D, straight between.
const STOP_NEAR: float = 0.70
const STOP_NEAR_D: float = 1.18
const STOP_FAR: float = 0.50
const STOP_FAR_D: float = 3.18
## CB3 mild: the strike's ease-in power (1: constant speed).
const STRIKE_CURVE: float = 1.6
## CB5: a card killed in the exchange falls this many frames after contact.
const EXCHANGE_FALL: int = 30
## CB6: the next attacker lifts this long after contact, and no earlier than LIFT_LEAD before
## the queue ends.
const LIFT_AFTER: int = 28
const LIFT_LEAD: int = 16
## CB7 (rule 5), one trigger many times: the first gap, how each gap after the first shrinks,
## its floor, from which repeat the rest land together, how long the count holds at the end.
const COMBO_FIRST: float = 18.0
const COMBO_SHRINK: float = 0.75
const COMBO_FLOOR: float = 5.0
const COMBO_TOGETHER_FROM: int = 8
const COMBO_END: int = 16
## Rule 7: past SPEEDUP_OVER frames of queue, what starts after its first SPEEDUP_FROM frames
## plays faster, rising to SPEEDUP_TOP over SPEEDUP_RAMP frames.
const SPEEDUP_OVER: int = 120
const SPEEDUP_FROM: int = 60
const SPEEDUP_RAMP: int = 60
const SPEEDUP_TOP: float = 1.5
## CB9 (Galaxy's timing): the turn is full this many frames before contact when the hold is its
## least; it ramps from the lift's first frame. Its amount, what is left at contact and how long
## it takes to unwind are FightMotion's TURN_* (one set for the game).
const AIM_FULL_BEFORE: int = 12

const REST: int = 30
const POP: float = 1.24
const KNOCK_PX: float = 20.0
const KNOCK_IN: int = 3
const KNOCK_SETTLE: int = 11
const KNOCK_TURN: float = 4.0
const BLOCK_SHARE: float = 0.3
const LIGHT_TIME: int = 11
const HIT_LIGHT: Color = Color(1.6, 1.25, 1.1)
const BLOCK_LIGHT: Color = Color(1.1, 1.35, 1.6)
const NUMBERS_AT: int = 2
const AFTER_AT: int = 14
const SCALE_HOME: int = 6
const BEAT_LAND: int = 12
const SELF_LAND: int = 6
const BEAT_GAP: int = 6
const PULSE_IN: int = 6
const PULSE_PX: float = 14.0
const PULSE_SETTLE: int = 10
const JAB_FROM: int = 6
const JAB_TO: int = 10
const JAB_PX: float = 20.0
const JAB_SETTLE: int = 8
const HOLD_PAST: int = 8
## Pile-ons in the hold: each piler jabs this many frames after the one before (best.md).
const PILE_GAP: int = 5
## An attacker whose target died before the hit settles back unstruck over these frames.
const SETTLE: int = 8
const LAUNCH_PAST: int = 4
const EFFECT_KILL: int = 20
const FALL: int = 15
const FALL_LEAST: int = 10
const DROP: int = 12
const DROP_LAND: int = 9
const DROP_PX: float = 37.5
const END_AFTER: int = 24
const END_HOLD: int = 90
## _exchange_at: the attack's target died before the hit.
const UNSTRUCK: int = -2
## Glows that last until the card leaves (an attacker killed before it strikes).
const FOREVER: int = 1 << 20
## The order of a frame's sound cues.
const CUE_ORDER: Array[String] = ["trigger", "hit", "death", "summon", "result"]
## FAST (CB16; Battlegrounds 31.6: "combat animations will now accelerate as the battle rages
## on"): from the lift of attack number FAST_ATTACK (1: the first) to the result, everything plays
## FAST_SPEED times faster. The result's hold plays at x1. A fight with fewer attacks plays at x1
## throughout.
const FAST_ATTACK: int = 5
const FAST_SPEED: float = 1.5
## GROUP (CB16): up to this many single trigger beats in a row start together, at the first one's
## start.
const GROUP_MOST: int = 3
## CB14 c, a stat gain (docs/workstreams/fight-animation-24-nov/buff-look/DESIGN.md, section 2).
## A run of gains: the first gap, how each shrinks, its floor (each gap rounded: 18, 14, 10, 8, 6).
const GAIN_GAP_FIRST: float = 18.0
const GAIN_GAP_SHRINK: float = 0.75
const GAIN_GAP_FLOOR: int = 5
## The +N is born this many frames into a beat with a living cause (a giver, or a gain to
## itself), and flies GAIN_FLY frames (a gain to itself rises GAIN_RISE). A gain caused by a death
## is born at its beat's start, at the dead unit's slot.
const GAIN_BORN_AT: int = 4
const GAIN_FLY: int = 10
const GAIN_RISE: int = 8
## The changed disc: x2.0 at the landing L, held 3 f, back to x1.0 by L+14; digits count over 8 f.
const SWELL: float = 2.0
const SWELL_HOLD: int = 3
const SWELL_BACK: int = 14
const COUNT: int = 8
## The tally over a disc: each gain re-pops it from x1.35 to x1.0 over 6 f with the running total;
## it sinks from the last L+30 (0.1 h down, to x0.4, fading) over 6 f.
const TAG_SETTLE: int = 6
const TAG_REPOP: float = 1.35
const TAG_HOLD: int = 30
const TAG_SINK: int = 6
const SINK_PX: float = 0.1 * H
const SINK_SCALE: float = 0.4
## The tally's centre stands this far above the top of its disc (at rest).
const TAG_ABOVE: float = 38.0
## A flying +N: born at x0.5, x0.9 after 3 f, x1.0 as it lands; a low arc at most 0.15 h high.
const BORN_SCALE: float = 0.5
const BORN_GROWN: float = 0.9
const BORN_FRAMES: int = 3
const ARC_LIFT: float = 0.15 * H
## The disc's flare (the recruit's amber ring) lasts 8 f from L.
const FLARE: int = 8
## The source's light ends this long after its tally is gone.
const LIGHT_PAST: int = 2

## [{state, hold, kind, frame, speed}]: the view state shown from each frame on (kind "lift" as an
## attack starts, "end" for the result, else "show"); speed is the card keeper's for that step.
var steps: Array[Dictionary] = []
## key ("u<uid>") -> [{kind, from, ...}]: every motion of a card, by frame.
var segments: Dictionary = {}
## [{frame, key, side, slot, amount, dealt, blocked, taken, merge}], by frame. amount is what the
## burst shows (a combo's running total), dealt the hit's own damage.
var bursts: Array[Dictionary] = []
## [{key, from, to}]: the attacker's (and a trigger's) glow.
var glows: Array[Dictionary] = []
## Per attack: {attacker, target, lift, launch, contact, release, home, queue_end}, by frame
## (launch and contact -1 when it never strikes).
var attacks: Array[Dictionary] = []
## [{key, frame, frames}]: every fall.
var falls: Array[Dictionary] = []
## [{frame, kind, ...}]: the sound cues, by frame (SoundCues.for_fight_cue reads them): "trigger"
## (a source pulses), "hit" (bursts show: splashes [{side, slot, amount, blocked}]), "death"
## (count units start to fall), "summon" (a unit arrives), "result" (winner, you_side).
var cues: Array[Dictionary] = []
## The result's frame, and the end of its hold.
var result_frame: int = 0
var end_frame: int = 0
## FAST: the schedule's frames from which, and up to which, it plays faster (-1: never).
var fast_from: int = -1
var fast_to: int = -1
## CB14 c, every gain by landing: {key, uid, run, k, start, land, born, fly, cause ({uid, side,
## slot}, or {} for a giver or a gain to itself), source, stats: {attack: [from, to, delta]...}}.
var gains: Array[Dictionary] = []
## Every tally over a disc: {key, source, appear, lands, totals, sink, gone, stats}.
var tallies: Array[Dictionary] = []
## Frames one drawn frame moves (FightScreen sets it): the contact pop shows at least this long,
## so every frame rate draws it once.
var clock_step: float = 1.0

var _events: Array = []
var _views: Array = []
var _reveal: Array[int] = []
var _speeds: Dictionary = {}
var _lifts: Array[Dictionary] = []
var _place: Callable
var _where: Dictionary = {}
var _dead: Dictionary = {}
var _attacker: String = ""
var _commit: bool = true
var _tempo_on: bool = false
## key -> the running total a combo's re-popping burst shows (rule 5), while a combo plays.
var _totals: Dictionary = {}
var _total_on: bool = false
## frame -> {kind -> cue}, gathered as the schedule is made.
var _cue_at: Dictionary = {}
## The attack being grouped: its attacker's uid and its target's.
var _pair: Vector2i = Vector2i(-1, -1)
## The log's index of every death, for its sound cue on the frame it shows.
var _deaths: Array[int] = []
## The latest deaths' units, in the order they fell: [{uid, side, slot}], and how many of them a
## gain has taken as its cause.
var _causes: Array[Dictionary] = []
var _taken: int = 0
## While a staggered group (CB8 c) plays, its gains' rows, shown in one tally per card.
var _grouping: bool = false
var _group_rows: Array[Dictionary] = []


## events: the rules core's log as played (FightReplay.played); views: the view state after each
## event (FightReplay.views); place: (side, slot) -> where a unit stands (FightScreen.unit_xy).
func build(events: Array, views: Array, place: Callable) -> void:
	_events = events
	_views = views
	_place = place
	if events.is_empty():
		return
	_reveal.resize(events.size())
	_reveal.fill(-1)
	_reveal[0] = 0
	_find_places()
	var attack_at: Array[int] = []
	var end_at: int = events.size() - 1
	for i: int in events.size():
		var kind: String = _kind(i)
		if kind == "attack":
			attack_at.append(i)
		elif kind == "combat_end":
			end_at = i
	var first_attack: int = attack_at[0] if not attack_at.is_empty() else end_at
	var last: Dictionary = _start_of_combat(first_attack)
	for k: int in attack_at.size():
		var to: int = attack_at[k + 1] if k + 1 < attack_at.size() else end_at
		last = _attack(attack_at[k], to, last)
	result_frame = _i(last.get("queue_end", REST)) + END_AFTER
	_reveal[end_at] = result_frame
	if attacks.size() >= FAST_ATTACK:
		fast_from = _i(attacks[FAST_ATTACK - 1]["lift"])
		fast_to = result_frame
	var ending: Dictionary = _events[end_at]
	if _kind(end_at) == "combat_end":
		_cue(
			result_frame,
			"result",
			{"winner": _i(ending.get("winner", -1)), "you_side": _you_side()}
		)
	_make_steps(result_frame)
	_make_cues()


## Start of Combat: what the log holds before the first attack plays after the REST as a queue
## (beats, deaths, arrivals; rules 3 to 5), and the first attacker lifts as after any queue (CB6).
## Returns the "last attack" the first one follows, {} when there is nothing to play.
func _start_of_combat(first_attack: int) -> Dictionary:
	var items: Array[Dictionary] = _items(1, first_attack)
	if items.is_empty():
		return {}
	_attacker = ""
	_commit = false
	_tempo_on = false
	var first_pass: int = _run_queue(items, REST, REST, REST)
	_tempo_on = first_pass - REST > SPEEDUP_OVER
	_commit = true
	var queue_end: int = _run_queue(items, REST, REST, REST)
	# CB6 from a moment with no contact: lift LIFT_LEAD before the queue ends, never before REST
	return {"release": REST - LIFT_AFTER, "queue_end": queue_end, "knocked": []}


## How many schedule frames one frame of game time moves at schedule frame t: FAST_SPEED from
## the FAST_ATTACK-th attack's lift to the result, else 1.
func speed_at(t: float) -> float:
	if fast_from >= 0 and t >= fast_from and t < fast_to:
		return FAST_SPEED
	return 1.0


## The schedule's frame `frames` frames of game time after t: x1 up to FAST's start, then
## FAST_SPEED. It stops on the result's own frame, which then plays at x1, as the fixture's clock
## does (best_timeline.gd advance; at 60 frames a second it lands on FAST's start too).
func advance(t: float, frames: float) -> float:
	if fast_from < 0 or t >= fast_to:
		return t + frames
	var left: float = frames
	var at: float = t
	if at < fast_from:
		var plain: float = minf(left, fast_from - at)
		at += plain
		left -= plain
	if left > 0.0:
		at = minf(at + left * FAST_SPEED, float(fast_to))
	return at


## Each card's pose at frame n, as offsets from where it stands: {offset, scale, turn, light}.
func pose(key: String, n: float) -> Dictionary:
	var offset: Vector2 = Vector2.ZERO
	var size: float = 1.0
	var turn: float = 0.0
	var light: Color = Color.WHITE
	var lifted: float = 0.0
	var lift_way: Vector2 = Vector2.ZERO
	for value: Variant in segments.get(key, []):
		var seg: Dictionary = value
		var part: Dictionary = {}
		match str(seg["kind"]):
			"attack":
				part = _attack_pose(seg, n)
			"knock":
				part = _knock_pose(seg, n)
			"summon":
				part = _summon_pose(seg, n)
			"pulse":
				var up: float = _pulse_lift(seg, n)
				if up > lifted:
					lifted = up
					lift_way = seg["lift"]
				part = {"offset": _jab_offset(seg, n), "turn": _jab_turn(seg, n)}
			"light":
				var tint: Color = _light(seg, n)
				light = Color(
					light.r * tint.r, light.g * tint.g, light.b * tint.b, light.a * tint.a
				)
		var moved: Vector2 = part.get("offset", Vector2.ZERO)
		offset += moved
		size *= _f(part.get("scale", 1.0))
		turn += _f(part.get("turn", 0.0))
		if part.has("alpha"):
			light.a *= _f(part["alpha"])
	offset += lift_way * lifted
	return {"offset": offset, "scale": size, "turn": turn, "light": light}


## The keys glowing at frame n.
func glowing(n: float) -> Dictionary:
	var out: Dictionary = {}
	for glow: Dictionary in glows:
		if n >= _i(glow["from"]) and n < _i(glow["to"]):
			out[str(glow["key"])] = true
	return out


# ---- one attack and what it causes ----


func _attack(at: int, to: int, last: Dictionary) -> Dictionary:
	var event: Dictionary = _events[at]
	var uid: int = _i(event.get("uid", -1))
	var target: int = _i(event.get("target_uid", -1))
	_attacker = _key(uid)
	var from_xy: Vector2 = _home(uid)
	var line: Vector2 = _home(target) - from_xy
	var d: float = line.length() / H
	var way: Vector2 = line.normalized()
	var strike: int = 7 if d <= 1.4 else (8 if d <= 2.4 else 9)
	var back: int = 12 if d <= 1.4 else (14 if d <= 2.4 else 16)
	var lift: int = REST if last.is_empty() else _lift_at(last)
	_lifts.append({"frame": lift, "lunge": _lunge(event)})
	var hold0: int = lift + LIFT
	var queue_was: int = _i(last.get("queue_end", 0))
	_pair = Vector2i(uid, target)
	var items: Array[Dictionary] = _items(at + 1, to)
	var hit: int = _exchange_at(items, uid)
	# the defender died before the hit: the exchange is skipped and the attacker settles back
	var settles: bool = hit == UNSTRUCK
	if settles:
		hit = -1
	var before: Array[Dictionary] = []
	var after: Array[Dictionary] = []
	if hit >= 0:
		before.assign(items.slice(0, hit))
		after.assign(items.slice(hit + 1))
	else:
		var cut: int = items.size()
		for j: int in items.size():
			if str(items[j]["kind"]) == "death":
				cut = j
				break
		before.assign(items.slice(0, cut))
		after.assign(items.slice(cut))
	# CB4 hold: what plays before the hit plays while the attacker is raised
	var t: int = maxi(hold0, queue_was)
	var last_land: int = -1
	# pilers jab PILE_GAP apart, the target's burst re-popping with the total (best.md's hold)
	var pile_at: int = -1
	_totals = {}
	for item: Dictionary in before:
		var pile: bool = _is_pile_on(item)
		var chained: bool = pile_at >= 0 and (pile or str(item["kind"]) == "rider")
		var start: int = t
		if chained:
			start = pile_at + PILE_GAP if pile else pile_at
		elif not pile:
			pile_at = -1
		_total_on = pile
		var done: Dictionary = _item(item, start, 1.0)
		_total_on = false
		if pile:
			pile_at = start
		t = maxi(t, _i(done["next"])) if pile or chained else _i(done["next"])
		last_land = maxi(last_land, _i(done["land"]))
	var hold_need: int = HOLD_LEAST
	if last_land >= 0:
		hold_need = maxi(HOLD_LEAST, last_land + HOLD_PAST - hold0)
	var launch: int = maxi(hold0 + hold_need, queue_was + LAUNCH_PAST)
	var contact: int = -1
	var release: int = last_land
	if hit >= 0:
		contact = launch + strike
		release = contact
	else:
		launch = -1
		if settles:
			release = maxi(last_land, hold0)
	var stop: Vector2 = line - way * _stop_gap(d) * H
	# the point facing the target leads: the top edge when the target is above, else the bottom
	var lead: float = -1.0 if way.y > 0.0 else 1.0
	var aim: float = FightMotion.TURN_AIM * rad_to_deg(Vector2(0.0, -lead).angle_to(way))
	# full at C-12 when the hold is its least; it holds through a longer one
	var aim_ramp: int = maxi(1, LIFT + HOLD_LEAST + strike - AIM_FULL_BEFORE)
	# the lean tips the leading point toward the target, the same way as the turn
	var lean: float = FightMotion.TURN_LEAN * way.x * lead
	var seg: Dictionary = {
		"kind": "attack",
		"from": lift,
		"pull": -way * PULL_PX,
		"lean": lean,
		"launch": launch,
		"strike": strike,
		"contact": contact,
		"stop": stop,
		"release": release,
		"back": back,
		"aim": aim,
		"aim_ramp": aim_ramp,
		"settle": -1,
	}
	_add(_attacker, seg)
	# the return moves from C+1 (no frame held at contact) and is home at C + back
	var home_at: int = release + back if hit >= 0 else FOREVER
	var glow: Dictionary = {"key": _attacker, "from": lift, "to": home_at}
	glows.append(glow)
	var knocked: Array[String] = []
	if hit >= 0:
		knocked = _exchange(items[hit], release, way)
	# after the hit: from C+14, and no earlier than the attacker is home (a far return ends later)
	var queue_from: int = release + AFTER_AT
	if hit >= 0:
		queue_from = maxi(queue_from, home_at)
	var queue: Array[Dictionary] = []
	if hit >= 0 and not after.is_empty() and str(after[0]["kind"]) == "death":
		after[0]["exchange_kill"] = true
	queue.append_array(after)
	var kill_land: int = release if hit < 0 else release + NUMBERS_AT
	# rule 7: a first pass, committing nothing, says whether the queue is long enough to speed up
	_commit = false
	_tempo_on = false
	var first_pass: int = _run_queue(queue, queue_from, release, kill_land)
	_tempo_on = first_pass - queue_from > SPEEDUP_OVER
	_commit = true
	var queue_end: int = maxi(
		_run_queue(queue, queue_from, release, kill_land), release + NUMBERS_AT
	)
	if settles:
		# it settles as its target's fall ends (or at once when it was already gone)
		var settle_at: int = maxi(release, hold0 + HOLD_LEAST)
		for fall: Dictionary in falls:
			if str(fall["key"]) == _key(target):
				settle_at = _i(fall["frame"]) + _i(fall["frames"])
		seg["settle"] = settle_at
		home_at = settle_at + SETTLE
		glow["to"] = home_at
		queue_end = maxi(queue_end, home_at)
	(
		attacks
		. append(
			{
				"attacker": _attacker,
				"target": _key(target),
				"lift": lift,
				"launch": launch,
				"contact": contact,
				"release": release,
				"home": home_at if hit >= 0 or settles else -1,
				"queue_end": queue_end,
			}
		)
	)
	return {"release": release, "queue_end": queue_end, "knocked": knocked}


## Which item is the exchange: the first attack damage. An attack whose hits all did nothing (a
## shield on each side, no damage to strike back) has none in the log; its attacker still strikes,
## at the first prevented hit, else straight after what plays before it, unless it dies first.
## -1 when it never strikes (killed by Thorns before the exchange), UNSTRUCK when its target
## died before the hit (best.md: the attacker settles back unstruck).
func _exchange_at(items: Array[Dictionary], uid: int) -> int:
	var cut: int = items.size()
	for j: int in items.size():
		var kind: String = items[j]["kind"]
		if kind == "exchange":
			return j
		if kind == "death" and cut == items.size():
			cut = j
	var target_dead: bool = _dead.has(_pair.y)
	for item: Dictionary in items:
		if str(item["kind"]) == "death":
			for value: Variant in item["events"]:
				var dying: int = _i(_at(_events, _i(value)).get("uid", -1))
				if dying == uid:
					return -1
				target_dead = target_dead or dying == _pair.y
	if target_dead:
		return UNSTRUCK
	for j: int in cut:
		var item: Dictionary = items[j]
		var listed: Array = item["events"]
		if str(item["kind"]) == "rider" and _kind(_i(listed[0])) == "prevented":
			item["kind"] = "exchange"
			return j
	items.insert(cut, {"kind": "exchange", "events": []})
	return cut


## CB6: when the next attacker lifts, from the last attack's C and queue end.
func _lift_at(last: Dictionary) -> int:
	return maxi(_i(last["release"]) + LIFT_AFTER, _i(last["queue_end"]) - LIFT_LEAD)


## CB2 b: the gap between centres at the stop, in card heights.
static func _stop_gap(d: float) -> float:
	var share: float = clampf((d - STOP_NEAR_D) / (STOP_FAR_D - STOP_NEAR_D), 0.0, 1.0)
	return lerpf(STOP_NEAR, STOP_FAR, share)


## The exchange lands at C+2 on every card it damaged; the target is knocked from C. Returns the
## keys knocked.
func _exchange(item: Dictionary, at: int, way: Vector2) -> Array[String]:
	var knocked: Array[String] = []
	_reveal_all(item, at + NUMBERS_AT)
	for value: Variant in item["events"]:
		var i: int = _i(value)
		var event: Dictionary = _events[i]
		var key: String = _key(_i(event.get("uid", -1)))
		var blocked: bool = _kind(i) == "prevented"
		_burst(event, at + NUMBERS_AT, blocked)
		var tint: Color = BLOCK_LIGHT if blocked else HIT_LIGHT
		_add(key, {"kind": "light", "from": at, "colour": tint})
		if key != _attacker and not knocked.has(key):
			knocked.append(key)
			var share: float = BLOCK_SHARE if blocked else 1.0
			_add(
				key,
				{
					"kind": "knock",
					"from": at,
					"way": way * KNOCK_PX * share,
					"turn": KNOCK_TURN * signf(way.y) * share,
				}
			)
	return knocked


## Plays the after-hit queue from `from` (C+14): deaths, beats, combos, arrivals, one at a time.
## Returns the queue's end (last landing, fall end or arrival end).
func _run_queue(queue: Array[Dictionary], from: int, at: int, kill_land: int) -> int:
	var t: int = from
	var queue_end: int = at + NUMBERS_AT
	var killed: int = kill_land
	var j: int = 0
	# GROUP: up to GROUP_MOST single beats in a row start together, at the first one's start
	var group_at: int = -1
	var grouped: int = 0
	while j < queue.size():
		var item: Dictionary = queue[j]
		var tempo: float = _tempo(t - from)
		var kind: String = item["kind"]
		if kind != "beat":
			group_at = -1
		if kind == "stagger":
			# CB8 c: the deaths of one pass fall one after another, each gain beside its death
			var spread: Dictionary = _stagger(item, killed + roundi(EFFECT_KILL / tempo))
			t = maxi(t, _i(spread["next"]))
			queue_end = maxi(queue_end, _i(spread["end"]))
			j += 1
			continue
		if kind == "death":
			var fall: int = killed + roundi(EFFECT_KILL / tempo)
			if item.get("exchange_kill", false):
				fall = at + EXCHANGE_FALL
			var length: int = maxi(FALL_LEAST, roundi(FALL / tempo))
			_fall(item, fall, length)
			t = maxi(t, fall + length)
			queue_end = maxi(queue_end, fall + length)
			j += 1
			continue
		var run: int = _run_length(queue, j)
		var done: Dictionary = {}
		if run >= 3:
			var repeats: Array[Dictionary] = []
			repeats.assign(queue.slice(j, j + run))
			done = _combo(repeats, t, from)
			group_at = -1
			j += run
		else:
			var begin: int = t
			if kind == "beat" and group_at >= 0 and grouped < GROUP_MOST:
				begin = group_at
				grouped += 1
			elif kind == "beat":
				group_at = t
				grouped = 1
			done = _item(item, begin, tempo)
			j += 1
		t = maxi(t, _i(done["next"]))
		queue_end = maxi(queue_end, _i(done["end"]))
		if done.get("damage", false):
			killed = maxi(killed, _i(done["land"]))
	return queue_end


## Rule 7: past SPEEDUP_OVER frames of queue, what starts after its first SPEEDUP_FROM frames
## plays faster, up to SPEEDUP_TOP.
func _tempo(into: int) -> float:
	if not _tempo_on:
		return 1.0
	var share: float = clampf(float(into - SPEEDUP_FROM) / float(SPEEDUP_RAMP), 0.0, 1.0)
	return 1.0 + (SPEEDUP_TOP - 1.0) * share


## Deaths falling from `at` for `length` frames; they are the causes of the gains that follow.
func _fall(item: Dictionary, at: int, length: int) -> void:
	_causes = []
	_taken = 0
	for value: Variant in item["events"]:
		var event: Dictionary = _events[_i(value)]
		(
			_causes
			. append(
				{
					"uid": _i(event.get("uid", -1)),
					"side": _i(event.get("side", 0)),
					"slot": _i(event.get("slot", 0)),
				}
			)
		)
	if not _commit:
		return
	_reveal_all(item, at)
	_speeds[at] = float(FALL) / length
	for value: Variant in item["events"]:
		var event: Dictionary = _events[_i(value)]
		var uid: int = _i(event.get("uid", -1))
		_dead[uid] = true
		_deaths.append(_i(value))
		falls.append({"key": _key(uid), "frame": at, "frames": length})


## CB8 c: a group of deaths at once (FightOrder tagged each with stagger_at), each falling at base
## + its stagger_at for FALL frames (no speed-up), each death's own gain landing beside it, the
## source pulsing before it. Returns {next, end}.
func _stagger(item: Dictionary, base: int) -> Dictionary:
	var listed: Array = item["events"]
	var last: int = _i(listed.back()) + 1
	var fall_end: int = base
	var lands: Array[int] = []
	var k: int = 0
	# the group's gains add up in one tally per card (CB14 c: "adds up")
	_grouping = true
	_group_rows = []
	while k < listed.size():
		var i: int = _i(listed[k])
		var event: Dictionary = _events[i]
		var at: int = base + _i(event["stagger_at"])
		if _kind(i) == "trigger":
			var beat: Dictionary = _beat(i, last)
			var targets: Array = beat["targets"]
			var source: int = _i(beat["source"])
			var to_self: bool = (
				targets.is_empty() or (targets.size() == 1 and _i(targets[0]) == source)
			)
			var done: Dictionary = _item(beat, at - (SELF_LAND if to_self else BEAT_LAND), 1.0)
			lands.append(_i(done["land"]))
			var caused: Array = beat["events"]
			k += caused.size()
			continue
		if _kind(i) == "death":
			_fall({"events": [i]}, at, FALL)
			fall_end = maxi(fall_end, at + FALL)
		elif _commit:
			_reveal[i] = at
		k += 1
	_grouping = false
	if _commit and not _group_rows.is_empty():
		_tally(_group_rows, str(_group_rows[0]["source"]), _i(lands.max()))
	if lands.is_empty():
		return {"next": fall_end, "end": fall_end}
	return {
		"next": maxi(fall_end, _i(lands.max()) + BEAT_GAP),
		"end": maxi(fall_end, _i(lands.max()) + COMBO_END),
	}


## How many beats from j on are the same mechanic with the same effect, back to back.
func _run_length(queue: Array[Dictionary], j: int) -> int:
	var first: Dictionary = queue[j]
	if str(first["kind"]) != "beat":
		return 1
	var n: int = 1
	while j + n < queue.size():
		var next: Dictionary = queue[j + n]
		if (
			str(next["kind"]) != "beat"
			or str(next["mechanic"]) != str(first["mechanic"])
			or str(next["effect"]) != str(first["effect"])
		):
			break
		n += 1
	return n


## Rule 5 (CB7): one trigger many times, each gap shorter than the last; from the 9th the rest land
## together, and a card hit again and again keeps one burst showing the running total.
func _combo(run: Array[Dictionary], start: int, from: int) -> Dictionary:
	if _is_gain(run[0]):
		return _gains(run, start)
	var t: float = float(start)
	var lands: Array[int] = []
	var together_at: int = -1
	var damage: bool = false
	_totals = {}
	_total_on = true
	for k: int in run.size():
		var at: int = roundi(t)
		if k >= COMBO_TOGETHER_FROM:
			if together_at < 0:
				together_at = at
			at = together_at
		var tempo: float = _tempo(at - from)
		var done: Dictionary = _item(run[k], at, tempo)
		lands.append(_i(done["land"]))
		damage = damage or done.get("damage", false)
		t += maxf(COMBO_FLOOR, _combo_gap(k) / tempo)
	_total_on = false
	var last: int = lands.max()
	return {"land": last, "next": last + BEAT_GAP, "end": last + COMBO_END, "damage": damage}


## The gap after the k-th repeat (0 = after the first), before the floor and tempo.
static func _combo_gap(k: int) -> float:
	if k < 1:
		return COMBO_FIRST
	return COMBO_FIRST * pow(COMBO_SHRINK, k)


## One item at `start`: a trigger's beat (pulse, jab, landing), an arrival, or a rider. Returns
## {land, next, end, damage}.
func _item(item: Dictionary, start: int, tempo: float) -> Dictionary:
	if _is_gain(item):
		var one: Array[Dictionary] = [item]
		return _gains(one, start)
	var kind: String = item["kind"]
	if kind == "arrival":
		return _arrive(item, start, tempo)
	if kind != "beat":
		if _commit:
			_reveal_all(item, start)
		return {"land": start, "next": start, "end": start}
	var source: int = _i(item["source"])
	var alive: bool = source >= 0 and _where.has(source) and not _dead.has(source)
	var summons: bool = str(item["effect"]) in ["summon", "reserve", "return"]
	if summons:
		var at: int = start
		if alive:
			_pulse(item, start, start + roundi(BEAT_LAND / tempo))
			at = start + roundi(BEAT_LAND / tempo)
		return _arrive(item, at, tempo)
	var targets: Array = item["targets"]
	var to_self: bool = targets.is_empty() or (targets.size() == 1 and _i(targets[0]) == source)
	var land: int = start + roundi((SELF_LAND if to_self else BEAT_LAND) / tempo)
	if alive:
		_pulse(item, start, land)
	var damage: bool = false
	if _commit:
		_reveal_all(item, land)
		for value: Variant in item["events"]:
			var i: int = _i(value)
			if _kind(i) in ["damage", "destroy", "prevented"]:
				var hurt: Dictionary = _events[i]
				_burst(hurt, land, _kind(i) == "prevented")
				damage = true
	return {"land": land, "next": land + roundi(BEAT_GAP / tempo), "end": land, "damage": damage}


## A unit arriving: it drops in from above its slot with a fade, landing at f9.
func _arrive(item: Dictionary, at: int, tempo: float) -> Dictionary:
	var land: int = at + roundi(DROP_LAND / tempo)
	if _commit:
		_reveal_all(item, at)
		var arrived: bool = false
		for value: Variant in item["events"]:
			var i: int = _i(value)
			if _kind(i) in ["summon", "reserve", "return"]:
				var event: Dictionary = _events[i]
				_add(_key(_i(event.get("uid", -1))), {"kind": "summon", "from": at, "tempo": tempo})
				arrived = true
		if arrived:
			_cue(at, "summon", {})
	return {
		"land": land,
		"next": land + roundi(BEAT_GAP / tempo),
		"end": at + roundi(DROP / tempo),
		"damage": false
	}


## The source's pulse (a lift and glow), and its jab toward the target when the effect lands on
## another card (STAND-IN for a drawn link between them).
func _pulse(item: Dictionary, start: int, land: int) -> void:
	if not _commit:
		return
	var source: int = _i(item["source"])
	var key: String = _key(source)
	var where: Array = _where[source]
	var up: Vector2 = Vector2.UP if _i(where[0]) == _you_side() else Vector2.DOWN
	var jab: Vector2 = Vector2.ZERO
	var toward: Vector2 = Vector2.ZERO
	var count: int = 0
	for value: Variant in item["targets"]:
		var target: int = _i(value)
		if target != source and _where.has(target):
			toward += _home(target)
			count += 1
	var aim: float = 0.0
	var lean: float = 0.0
	if count > 0:
		var way: Vector2 = (toward / count - _home(source)).normalized()
		jab = way * JAB_PX
		# the jab turns as a strike does (CB9 aim_lean), over the jab's few frames
		var lead: float = -1.0 if way.y > 0.0 else 1.0
		aim = FightMotion.TURN_AIM * rad_to_deg(Vector2(0.0, -lead).angle_to(way))
		aim = clampf(aim, -FightMotion.JAB_TURN_CAP, FightMotion.JAB_TURN_CAP)
		lean = FightMotion.TURN_LEAN * way.x * lead
	_add(
		key,
		{
			"kind": "pulse",
			"from": start,
			"land": land,
			"lift": up * PULSE_PX,
			"jab": jab,
			"aim": aim,
			"lean": lean,
		}
	)
	glows.append({"key": key, "from": start, "to": land + BEAT_GAP})
	_cue(start, "trigger", {})


# ---- stat gains (CB14 c) ----


static func _is_gain(item: Dictionary) -> bool:
	return str(item.get("kind", "")) == "beat" and str(item.get("effect", "")) == "buff"


## The gap after the k-th gain of a run (0: after the first), rounded per gap.
static func gain_gap(k: int) -> int:
	return maxi(GAIN_GAP_FLOOR, roundi(GAIN_GAP_FIRST * pow(GAIN_GAP_SHRINK, k)))


## The k-th gain's beat start, frames after the run's first.
static func gain_start(k: int) -> int:
	var at: int = 0
	for j: int in k:
		at += gain_gap(j)
	return at


## A run of gain beats (one or more) by DESIGN.md's beats (C), from `start`, without rule 7's
## speed-up. Each +N is born at its cause and flies into its disc; a gain to itself rises from the
## card. Returns {land, next, end, damage}.
func _gains(run: Array[Dictionary], start: int) -> Dictionary:
	var source: int = _i(run[0]["source"])
	var alive: bool = source >= 0 and _where.has(source) and not _dead.has(source)
	var lands: Array[int] = []
	var all_self: bool = true
	var rows: Array[Dictionary] = []
	for k: int in run.size():
		var item: Dictionary = run[k]
		var targets: Array = item["targets"]
		var to_self: bool = targets.is_empty() or (targets.size() == 1 and _i(targets[0]) == source)
		all_self = all_self and to_self
		var s: int = start + gain_start(k)
		var cause: Dictionary = _cause_of(item)
		var born: int = s + GAIN_BORN_AT
		var fly: int = GAIN_RISE if to_self else GAIN_FLY
		if not cause.is_empty():
			born = s
			fly = GAIN_FLY
		var land: int = born + fly
		if alive and not to_self:
			# the +N's flight replaces the jab; the giver still pulses
			_add(
				_key(source),
				{
					"kind": "pulse",
					"from": s,
					"land": land,
					"lift": _up(source) * PULSE_PX,
					"jab": Vector2.ZERO,
				}
			)
			_cue(s, "trigger", {})
		lands.append(land)
		if _commit:
			_reveal_all(item, land)
			# each row joins `gains` at once: the next gain's count carries on from it
			var made: Array[Dictionary] = _gain_rows(item, k, s, land, born, fly, cause)
			gains.append_array(made)
			rows.append_array(made)
	var last: int = lands.max()
	# the queue goes on once the discs settle: a tally's tail runs under what plays next
	# (DESIGN.md: "The next beat starts at f20, under the tag's tail")
	var settle: int = last + SWELL_BACK
	var light_to: int = last + TAG_HOLD + TAG_SINK + LIGHT_PAST
	if alive and all_self:
		# a gain to itself: the source lights once and stays lit through the run
		_add(
			_key(source),
			{
				"kind": "pulse",
				"from": start,
				"land": last,
				"lift": _up(source) * PULSE_PX,
				"jab": Vector2.ZERO,
			}
		)
		_cue(start, "trigger", {})
	if alive and _commit:
		glows.append({"key": _key(source), "from": start, "to": light_to})
	if _commit and _grouping:
		_group_rows.append_array(rows)
	elif _commit:
		_tally(rows, _key(source), last)
	return {"land": last, "next": last + BEAT_GAP, "end": settle, "damage": false}


## A gain's cause: the death it is for when FightOrder named one (a staggered group's beat:
## `stagger_cause`), else the latest death item's next unit on the gain's source's side (the k-th
## gain after a group of deaths at once is that side's k-th death), else {} (a giver, a gain to
## itself with no death behind it).
func _cause_of(item: Dictionary) -> Dictionary:
	var listed: Array = item["events"]
	var trigger: Dictionary = _at(_events, _i(listed[0]))
	if trigger.has("stagger_cause"):
		var dead: int = _i(trigger["stagger_cause"])
		for value: Variant in _events:
			var event: Dictionary = value
			if _kind_of(event) == "death" and _i(event.get("uid", -1)) == dead:
				return {
					"uid": dead,
					"side": _i(event.get("side", 0)),
					"slot": _i(event.get("slot", 0)),
				}
	var source: int = _i(item["source"])
	if not _where.has(source):
		return {}
	var side: int = _i(_where[source][0])
	var seen: int = 0
	for cause: Dictionary in _causes:
		if _i(cause["side"]) != side or _i(cause["uid"]) == source:
			continue
		if seen == _taken:
			_taken += 1
			return cause
		seen += 1
	return {}


## One row per changed unit in a gain beat: what each stat counts from and to.
func _gain_rows(
	item: Dictionary, k: int, s: int, land: int, born: int, fly: int, cause: Dictionary
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for value: Variant in item["events"]:
		var i: int = _i(value)
		if _kind(i) != "buff":
			continue
		var event: Dictionary = _events[i]
		var uid: int = _i(event.get("uid", -1))
		var after: Vector2i = Vector2i(_i(event.get("attack", 0)), _i(event.get("health", 0)))
		var before: Vector2i = _shown_before(i, uid, after)
		var key: String = _key(uid)
		var stats: Dictionary = {}
		var delta: Vector2i = after - before
		for stat: String in ["attack", "health"]:
			var d: int = delta.x if stat == "attack" else delta.y
			if d == 0:
				continue
			var was: int = before.x if stat == "attack" else before.y
			var now: int = after.x if stat == "attack" else after.y
			stats[stat] = [_count_from(key, stat, land, was), now, d]
		if stats.is_empty():
			continue
		(
			out
			. append(
				{
					"key": key,
					"uid": uid,
					"k": k,
					"start": s,
					"land": land,
					"born": born,
					"fly": fly,
					"cause": cause,
					"source": _key(_i(item["source"])),
					"stats": stats,
				}
			)
		)
	return out


## A unit's Attack and Health just before log event i, from the log itself: the start boards (or
## its summon), then every buff (its new numbers) and damage (the Health left) on it.
func _shown_before(i: int, uid: int, fallback: Vector2i) -> Vector2i:
	var stats: Vector2i = Vector2i(-1, -1)
	var start: Dictionary = _events[0]
	for row: Variant in start.get("boards", []):
		var units: Array = row
		for unit: Variant in units:
			if not unit is Dictionary:
				continue
			var held: Dictionary = unit
			if _i(held.get("uid", -1)) == uid:
				stats = Vector2i(_i(held.get("attack", 0)), _i(held.get("health", 0)))
	for j: int in range(1, i):
		var event: Dictionary = _events[j]
		if _i(event.get("uid", -1)) != uid:
			continue
		match _kind(j):
			"buff", "summon":
				stats = Vector2i(_i(event.get("attack", stats.x)), _i(event.get("health", stats.y)))
			"damage":
				stats.y = _i(event.get("health", stats.y))
	return fallback if stats.x < 0 else stats


## Where a stat's count starts at `land`: what the last gain on it shows then while it is still
## counting (its count carries on), else the number before this gain.
func _count_from(key: String, stat: String, land: int, was: int) -> int:
	for j: int in range(gains.size() - 1, -1, -1):
		var gain: Dictionary = gains[j]
		var stats: Dictionary = gain["stats"]
		if str(gain["key"]) != key or not stats.has(stat) or _i(gain["land"]) > land:
			continue
		var age: int = land - _i(gain["land"])
		if age >= COUNT:
			return was
		var counted: Array = stats[stat]
		return roll(_i(counted[0]), _i(counted[1]), age, COUNT)
	return was


## One tally per changed card and run of gains (or staggered group: _stagger), showing the
## running total of each stat changed; the last is the whole change.
func _tally(rows: Array[Dictionary], source: String, last: int) -> void:
	var keys: Array[String] = []
	for row: Dictionary in rows:
		if not keys.has(str(row["key"])):
			keys.append(str(row["key"]))
	for key: String in keys:
		var lands: Array[int] = []
		var totals: Array = []
		var sum: Dictionary = {"attack": 0, "health": 0}
		var changed: Dictionary = {}
		for row: Dictionary in rows:
			if str(row["key"]) != key:
				continue
			var stats: Dictionary = row["stats"]
			for stat: String in stats:
				var counted: Array = stats[stat]
				sum[stat] = _i(sum[stat]) + _i(counted[2])
				changed[stat] = true
			lands.append(_i(row["land"]))
			totals.append(sum.duplicate())
		(
			tallies
			. append(
				{
					"key": key,
					"source": source,
					"appear": lands[0],
					"lands": lands,
					"totals": totals,
					"sink": last + TAG_HOLD,
					"gone": last + TAG_HOLD + TAG_SINK,
					"stats": changed.keys(),
				}
			)
		)


func _up(uid: int) -> Vector2:
	var where: Array = _where[uid]
	return Vector2.UP if _i(where[0]) == _you_side() else Vector2.DOWN


## count.roll: the number shown `age` frames into a count from `from` to `to`, one step at a time,
## the steps spread evenly over `frames` frames (the last step lands on the last frame).
static func roll(from: int, to: int, age: float, frames: int) -> int:
	if age < 0.0:
		return from
	var count: int = absi(to - from)
	if count == 0 or age >= frames:
		return to
	var done: int = 0
	for i: int in range(1, count + 1):
		if age >= roundi(float(i) * frames / count):
			done = i
	return from + done * signi(to - from)


# ---- what a gain shows at a frame (FightGains draws it) ----


## A changed disc at frame n: {scale, value, to} while it swells or counts, else {}.
func disc_at(key: String, stat: String, n: float) -> Dictionary:
	for j: int in range(gains.size() - 1, -1, -1):
		var gain: Dictionary = gains[j]
		var stats: Dictionary = gain["stats"]
		if str(gain["key"]) != key or not stats.has(stat) or _i(gain["land"]) > n:
			continue
		var age: float = n - _i(gain["land"])
		if age >= SWELL_BACK:
			return {}
		var size: float = SWELL
		if age >= SWELL_HOLD:
			var p: float = (age - SWELL_HOLD) / (SWELL_BACK - SWELL_HOLD)
			size = lerpf(SWELL, 1.0, _enter(p))
		var counted: Array = stats[stat]
		return {
			"scale": size,
			"value": roll(_i(counted[0]), _i(counted[1]), age, COUNT),
			"to": _i(counted[1]),
		}
	return {}


## The keys with a gain landing, swelling or counting at frame n.
func swelling(n: float) -> Array[String]:
	var out: Array[String] = []
	for gain: Dictionary in gains:
		var age: float = n - _i(gain["land"])
		if age >= 0.0 and age < SWELL_BACK and not out.has(str(gain["key"])):
			out.append(str(gain["key"]))
	return out


## Every tally at frame n: [{key, tally, stat, text, scale, alpha, drop}] (tally: its index).
func tags_at(n: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for index: int in tallies.size():
		var tally: Dictionary = tallies[index]
		if n < _i(tally["appear"]) or n >= _i(tally["gone"]):
			continue
		var lands: Array = tally["lands"]
		var totals: Array = tally["totals"]
		var k: int = 0
		for j: int in lands.size():
			if _i(lands[j]) <= n:
				k = j
		var size: float = 1.0
		var age: float = n - _i(lands[k])
		if age < TAG_SETTLE:
			size = lerpf(TAG_REPOP, 1.0, _enter(age / TAG_SETTLE))
		var alpha: float = 1.0
		var drop: float = 0.0
		var sink: int = _i(tally["sink"])
		if n >= sink:
			var p: float = _exit((n - sink) / TAG_SINK)
			drop = SINK_PX * p
			size *= lerpf(1.0, SINK_SCALE, p)
			alpha = 1.0 - p
		var total: Dictionary = totals[k]
		for stat: Variant in tally["stats"]:
			(
				out
				. append(
					{
						"key": tally["key"],
						"tally": index,
						"stat": str(stat),
						"text": "+%d" % _i(total[stat]),
						"scale": size,
						"alpha": alpha,
						"drop": drop,
					}
				)
			)
	return out


## Every +N in flight at frame n: [{gain, key, stat, text, cause, source, mix, scale, alpha}]. mix
## is the share of the way travelled (the recruit's arrive curve: off gently, in at speed).
func flights_at(n: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for j: int in gains.size():
		var gain: Dictionary = gains[j]
		var born: int = _i(gain["born"])
		if born < 0 or n < born or n >= _i(gain["land"]):
			continue
		var age: float = n - born
		var mix: float = RecruitTurnStart._arrive(age / _i(gain["fly"]))
		var size: float = lerpf(BORN_GROWN, 1.0, mix)
		if age < BORN_FRAMES:
			size = lerpf(BORN_SCALE, BORN_GROWN, _enter(age / BORN_FRAMES))
		var stats: Dictionary = gain["stats"]
		for stat: String in stats:
			var counted: Array = stats[stat]
			(
				out
				. append(
					{
						"gain": j,
						"key": gain["key"],
						"stat": stat,
						"text": "+%d" % _i(counted[2]),
						"cause": gain["cause"],
						"source": gain["source"],
						"mix": mix,
						"scale": size,
						"alpha": minf(1.0, (age + 1.0) / BORN_FRAMES),
					}
				)
			)
	return out


## Every disc flaring at frame n: [{gain, key, stat, age}].
func flares_at(n: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for j: int in gains.size():
		var gain: Dictionary = gains[j]
		var age: float = n - _i(gain["land"])
		if age < 0.0 or age >= FLARE:
			continue
		var stats: Dictionary = gain["stats"]
		for stat: String in stats:
			out.append({"gain": j, "key": gain["key"], "stat": stat, "age": age})
	return out


## ease.enter: decelerate, cubic-bezier(0, 0, 0.2, 1).
static func _enter(p: float) -> float:
	return GlassMotion.bezier(Vector4(0.0, 0.0, 0.2, 1.0), p)


## ease.exit: accelerate, cubic-bezier(0.4, 0, 1, 1).
static func _exit(p: float) -> float:
	return GlassMotion.bezier(Vector4(0.4, 0.0, 1.0, 1.0), p)


# ---- grouping the log ----


## The events from `from` up to `to` as items: the exchange, death passes, beats (a trigger and
## what it does), arrivals, riders.
func _items(from: int, to: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var i: int = from
	while i < to:
		var kind: String = _kind(i)
		var listed: Array = [i]
		var item: Dictionary = {"kind": "rider", "events": listed}
		var j: int = i + 1
		if _at(_events, i).has("stagger_at"):
			# CB8 c: a group of deaths with their own gains, played by _stagger()
			item["kind"] = "stagger"
			while j < to and _at(_events, j).has("stagger_at"):
				listed.append(j)
				j += 1
		elif _opens_exchange(i):
			item["kind"] = "exchange"
			while j < to and _exchange_part(j):
				listed.append(j)
				j += 1
		elif kind == "death":
			item["kind"] = "death"
			while j < to and _kind(j) == "death":
				listed.append(j)
				j += 1
		elif kind == "trigger":
			item = _beat(i, to)
			var caused: Array = item["events"]
			j = i + caused.size()
		elif kind in ["summon", "reserve", "return"]:
			item["kind"] = "arrival"
		elif kind == "pass":
			i = j
			continue
		out.append(item)
		i = j
	return out


## Where an attack's exchange starts: its first attack damage, or its attacker's own hit on its
## target blocked (a shield: the core logs that as prevented, before the strike back).
func _opens_exchange(i: int) -> bool:
	var event: Dictionary = _events[i]
	if _kind(i) == "damage":
		return event.get("from_attack", false)
	return (
		_kind(i) == "prevented"
		and _i(event.get("source_uid", -1)) == _pair.x
		and _i(event.get("uid", -1)) == _pair.y
	)


func _exchange_part(i: int) -> bool:
	var event: Dictionary = _events[i]
	if _kind(i) == "prevented":
		return true
	return _kind(i) == "damage" and event.get("from_attack", false)


## A pile-on's beat: a trigger whose effect is a `hit` on the attack's target.
func _is_pile_on(item: Dictionary) -> bool:
	if str(item["kind"]) != "beat":
		return false
	for value: Variant in item["events"]:
		if _kind(_i(value)) == "hit":
			return true
	return false


## A trigger and the events it causes (up to the next trigger, death, attack or exchange).
func _beat(at: int, to: int) -> Dictionary:
	var trigger: Dictionary = _events[at]
	var source: int = _i(trigger.get("uid", -1))
	var events: Array = [at]
	var targets: Array = []
	var effect: String = ""
	var j: int = at + 1
	while j < to:
		var kind: String = _kind(j)
		var event: Dictionary = _events[j]
		# a hit the effect's target blocked stays with its beat (its 0 shows on the landing)
		if kind in ["trigger", "death", "attack", "combat_end"] or _opens_exchange(j):
			break
		if effect == "":
			effect = kind
		var uid: int = _i(event.get("uid", -1))
		if uid >= 0 and not targets.has(uid):
			targets.append(uid)
		events.append(j)
		j += 1
	return {
		"kind": "beat",
		"events": events,
		"source": source,
		"mechanic": str(trigger.get("mechanic", "")),
		"effect": effect,
		"targets": targets,
	}


# ---- the steps and cues ----


## The view state at each frame something shows: the board after the longest run of the log
## whose changes have all shown, with the attack under way (moment.lunge, as the view contract
## has it; the screen poses the cards from the schedule) and, from its frame, the result.
func _make_steps(result: int) -> void:
	var shown: int = 0
	for i: int in _events.size():
		if _reveal[i] < 0:
			_reveal[i] = shown
		elif _reveal[i] < shown:
			# a change scheduled before one that must show first: it waits, so the board stays true
			_reveal[i] = shown
		shown = _reveal[i]
	var frames: Dictionary = {}
	for value: int in _reveal:
		frames[value] = true
	for lift: Dictionary in _lifts:
		frames[_i(lift["frame"])] = true
	var order: Array = frames.keys()
	order.sort()
	var lift_at: Dictionary = {}
	for lift: Dictionary in _lifts:
		lift_at[_i(lift["frame"])] = lift["lunge"]
	var upto: int = 0
	var lunge: Dictionary = {}
	for value: Variant in order:
		var frame: int = _i(value)
		while upto + 1 < _events.size() and _reveal[upto + 1] <= frame:
			upto += 1
		var kind: String = "show"
		if lift_at.has(frame):
			lunge = lift_at[frame]
			kind = "lift"
		var snap: Dictionary = _views[upto]
		var view: Dictionary = snap.duplicate(true)
		var was: Dictionary = view.get("moment", {})
		var moment: Dictionary = {}
		if was.has("result") and frame >= result:
			# the result's hold (CB12 b, plan step 4, adds the winner's portrait striking here)
			moment["result"] = was["result"]
			kind = "end"
		elif not lunge.is_empty():
			moment["lunge"] = lunge.duplicate()
		view["moment"] = moment
		var speed: float = _f(_speeds.get(frame, 1.0)) * speed_at(frame)
		steps.append({"state": view, "hold": 0.0, "kind": kind, "frame": frame, "speed": speed})
	for k: int in steps.size():
		var step: Dictionary = steps[k]
		var next: int = _i(steps[k + 1]["frame"]) if k + 1 < steps.size() else result + END_HOLD
		step["hold"] = (next - _i(step["frame"])) / 60.0
	end_frame = result + END_HOLD


## A cue at a frame: one of each kind per frame (a death cue counts every fall starting then).
func _cue(frame: int, kind: String, fields: Dictionary) -> void:
	if not _commit:
		return
	if not _cue_at.has(frame):
		_cue_at[frame] = {}
	var cue: Dictionary = fields.duplicate()
	cue["frame"] = frame
	cue["kind"] = kind
	_cue_at[frame][kind] = cue


## The cue of a kind at a frame so far, or `none`.
func _cue_of(frame: int, kind: String, none: Dictionary) -> Dictionary:
	if not _cue_at.has(frame):
		return none
	var at: Dictionary = _cue_at[frame]
	var cue: Dictionary = at.get(kind, none)
	return cue


## The cues by frame, each frame's in CUE_ORDER: a frame's bursts make its hit cue, and the units
## that start to fall on a frame (as the steps show them) its death cue. Each cue keeps the speed
## the fight plays at on its frame (FAST), so a cue's own staggers speed up with the fight.
func _make_cues() -> void:
	for i: int in _deaths:
		var shown: int = _reveal[i]
		var fell: Dictionary = _cue_of(shown, "death", {"count": 0})
		_cue(shown, "death", {"count": _i(fell["count"]) + 1})
	for burst: Dictionary in bursts:
		var frame: int = burst["frame"]
		var was: Dictionary = _cue_of(frame, "hit", {"splashes": []})
		var splashes: Array = was["splashes"]
		var amount: int = _i(burst["dealt"])
		(
			splashes
			. append(
				{
					"side": burst["side"],
					"slot": burst["slot"],
					"amount": amount,
					"blocked": burst["blocked"],
				}
			)
		)
		_cue(frame, "hit", {"splashes": splashes})
	var frames: Array = _cue_at.keys()
	frames.sort()
	for frame: Variant in frames:
		var at: Dictionary = _cue_at[frame]
		for kind: String in CUE_ORDER:
			if at.has(kind):
				var cue: Dictionary = at[kind]
				cue["speed"] = speed_at(_i(frame))
				cues.append(cue)


# ---- poses ----


## The attacker's motion, plus the turn (_aim_turn), which outlasts it: the card lands home still
## turned and straightens there.
func _attack_pose(seg: Dictionary, n: float) -> Dictionary:
	var part: Dictionary = _move_pose(seg, n)
	var aim: float = _aim_turn(seg, n)
	if is_zero_approx(aim):
		return part
	var out: Dictionary = part.duplicate()
	out["turn"] = _f(part.get("turn", 0.0)) + aim
	return out


## The turn at frame n (degrees): it ramps from the lift's first frame (sine out: it starts at
## once and eases in), full at aim_ramp, eases back to TURN_AT_CONTACT over the strike, holds
## there to the release, and unwinds from the return's start over TURN_UNWIND (smootherstep).
func _aim_turn(seg: Dictionary, n: float) -> float:
	var aim: float = _f(seg.get("aim", 0.0))
	var start: int = seg["from"]
	if n <= start or is_zero_approx(aim):
		return 0.0
	var ramp: float = sin(PI / 2.0 * minf(1.0, float(n - start) / _i(seg["aim_ramp"])))
	var share: float = ramp
	var launch: int = seg["launch"]
	var contact: int = seg["contact"]
	var release: int = seg["release"]
	var straight: int = unwind_frames()
	if launch < 0:
		share = ramp * (1.0 - _settled(seg, n))
	elif n > launch:
		if n < contact:
			var u: float = float(n - launch) / _i(seg["strike"])
			share = ramp * lerpf(1.0, FightMotion.TURN_AT_CONTACT, u)
		elif n <= release:
			share = FightMotion.TURN_AT_CONTACT
		else:
			var j: float = n - release
			if j >= straight:
				return 0.0
			share = FightMotion.TURN_AT_CONTACT * (1.0 - _smoother(minf(1.0, float(j) / straight)))
	return aim * share


## Frames from the return's start until the turn is gone (FightMotion.TURN_UNWIND).
static func unwind_frames() -> int:
	return roundi(FightMotion.TURN_UNWIND * 60.0)


func _move_pose(seg: Dictionary, n: float) -> Dictionary:
	var start: int = seg["from"]
	if n <= start:
		return {}
	var launch: int = seg["launch"]
	if launch < 0 or n <= launch:
		var pose_now: Dictionary = _windup_pose(seg, n - start)
		var down: float = _settled(seg, n)
		if down >= 1.0:
			return {}
		if down > 0.0:
			var offset: Vector2 = pose_now["offset"]
			pose_now["offset"] = offset * (1.0 - down)
			pose_now["scale"] = lerpf(_f(pose_now["scale"]), 1.0, down)
			pose_now["turn"] = _f(pose_now["turn"]) * (1.0 - down)
		return pose_now
	var contact: int = seg["contact"]
	var stop: Vector2 = seg["stop"]
	if n < contact:
		var u: float = float(n - launch) / _i(seg["strike"])
		var pull: Vector2 = seg["pull"]
		var along: float = pow(u, STRIKE_CURVE)
		return {
			"offset": pull.lerp(stop, along), "scale": LIFT_SCALE, "turn": _f(seg["lean"]) * (1 - u)
		}
	# the pop holds one frame, or one drawn frame when a drawn frame is longer
	if n < contact + clock_step:
		return {"offset": stop, "scale": POP}
	return _return_pose(seg, n)


## How far an unstruck attacker has settled back at frame n: 0 raised, 1 home.
func _settled(seg: Dictionary, n: float) -> float:
	var settle: int = _i(seg.get("settle", -1))
	if settle < 0 or n <= settle:
		return 0.0
	return _cubic_out(minf(1.0, (n - settle) / SETTLE))


func _windup_pose(seg: Dictionary, k: float) -> Dictionary:
	var e: float = _quad_out(minf(1.0, float(k) / LIFT))
	var pull: Vector2 = seg["pull"]
	return {
		"offset": pull * e,
		"scale": lerpf(1.0, LIFT_SCALE, e),
		"turn": _f(seg["lean"]) * e,
	}


func _return_pose(seg: Dictionary, n: float) -> Dictionary:
	var release: int = seg["release"]
	var stop: Vector2 = seg["stop"]
	if n <= release:
		return {"offset": stop, "scale": LIFT_SCALE}
	var v: float = float(n - release) / _i(seg["back"])
	if v >= 1.0:
		return {}
	var e: float = 1.0 - pow(1.0 - v, 4.0)
	var shrink: float = clampf(float(n - release) / SCALE_HOME, 0.0, 1.0)
	return {"offset": stop.lerp(Vector2.ZERO, e), "scale": lerpf(LIFT_SCALE, 1.0, shrink)}


func _knock_pose(seg: Dictionary, n: float) -> Dictionary:
	var k: float = n - _i(seg["from"])
	if k <= 0 or k >= KNOCK_IN + KNOCK_SETTLE:
		return {}
	var a: float = float(k) / KNOCK_IN
	if k > KNOCK_IN:
		a = 1.0 - _cubic_out(float(k - KNOCK_IN) / KNOCK_SETTLE)
	var way: Vector2 = seg["way"]
	return {"offset": way * a, "turn": _f(seg["turn"]) * a}


func _summon_pose(seg: Dictionary, n: float) -> Dictionary:
	var tempo: float = seg["tempo"]
	var k: float = (n - _i(seg["from"])) * tempo
	if k >= DROP:
		return {}
	var fall: float = clampf(k / DROP_LAND, 0.0, 1.0)
	return {
		"offset": Vector2.UP * DROP_PX * (1.0 - fall * fall),
		"alpha": clampf(k / DROP, 0.0, 1.0),
	}


func _pulse_lift(seg: Dictionary, n: float) -> float:
	var start: int = seg["from"]
	var land: int = seg["land"]
	if n <= start:
		return 0.0
	if n <= land:
		return _quad_out(minf(1.0, float(n - start) / PULSE_IN))
	return 1.0 - _cubic_out(minf(1.0, float(n - land) / PULSE_SETTLE))


func _jab_offset(seg: Dictionary, n: float) -> Vector2:
	var jab: Vector2 = seg["jab"]
	var k: float = n - _i(seg["from"])
	var land: int = seg["land"]
	if jab == Vector2.ZERO or k <= JAB_FROM:
		return Vector2.ZERO
	if n <= land:
		return jab * _quad_out(minf(1.0, float(k - JAB_FROM) / (JAB_TO - JAB_FROM)))
	return jab * (1.0 - _cubic_out(minf(1.0, float(n - land) / JAB_SETTLE)))


## A jab's turn (degrees), the strike's shape on the jab's frames: it ramps in with the pulse
## (sine out, full at JAB_FROM) with the lean, eases to TURN_AT_CONTACT as the jab lands while
## the lean goes, and unwinds as the jab comes back (JAB_SETTLE, smootherstep).
func _jab_turn(seg: Dictionary, n: float) -> float:
	var aim: float = _f(seg.get("aim", 0.0))
	var lean: float = _f(seg.get("lean", 0.0))
	var k: float = n - _i(seg["from"])
	var land: float = _i(seg["land"]) - _i(seg["from"])
	if k <= 0.0 or (is_zero_approx(aim) and is_zero_approx(lean)):
		return 0.0
	if k <= land:
		var ramp: float = sin(PI / 2.0 * minf(1.0, k / JAB_FROM))
		var u: float = clampf((k - JAB_FROM) / maxf(1.0, land - JAB_FROM), 0.0, 1.0)
		return aim * ramp * lerpf(1.0, FightMotion.TURN_AT_CONTACT, u) + lean * ramp * (1.0 - u)
	var back: float = minf(1.0, (k - land) / JAB_SETTLE)
	return aim * FightMotion.TURN_AT_CONTACT * (1.0 - _smoother(back))


## A card's jab turn at frame n, summed over its pulses (what `best` has not got).
func jab_turn(key: String, n: float) -> float:
	var out: float = 0.0
	for value: Variant in segments.get(key, []):
		var seg: Dictionary = value
		if str(seg["kind"]) == "pulse":
			out += _jab_turn(seg, n)
	return out


func _light(seg: Dictionary, n: float) -> Color:
	var k: float = n - _i(seg["from"])
	if k < 0 or k >= LIGHT_TIME:
		return Color.WHITE
	var tint: Color = seg["colour"]
	return tint.lerp(Color.WHITE, float(k) / LIGHT_TIME)


# ---- small helpers ----


func _add(key: String, seg: Dictionary) -> void:
	if not _commit:
		return
	if not segments.has(key):
		segments[key] = []
	var list: Array = segments[key]
	list.append(seg)


func _reveal_all(item: Dictionary, at: int) -> void:
	if not _commit:
		return
	for value: Variant in item["events"]:
		var i: int = _i(value)
		if _kind(i) in ["attack", "trigger", "pass"]:
			continue
		_reveal[i] = at


func _burst(event: Dictionary, at: int, blocked: bool) -> void:
	if not _commit:
		return
	var uid: int = _i(event.get("uid", -1))
	var key: String = _key(uid)
	var where: Array = _where.get(uid, [0, 0])
	var dealt: int = _i(event.get("amount", 0)) if _kind_of(event) == "damage" else 0
	var amount: int = dealt
	# rule 5: a card hit again and again in a combo keeps one burst, re-popping with the total
	var merge: bool = _total_on and not blocked
	if merge:
		amount += _i(_totals.get(key, 0))
		_totals[key] = amount
	(
		bursts
		. append(
			{
				"frame": at,
				"key": key,
				"side": _i(event.get("side", where[0])),
				"slot": _i(event.get("slot", where[1])),
				"amount": amount,
				"dealt": dealt,
				"blocked": blocked,
				"taken": key == _attacker,
				"merge": merge,
			}
		)
	)


static func _lunge(event: Dictionary) -> Dictionary:
	return {
		"side": _i(event.get("side", 0)),
		"slot": _i(event.get("slot", 0)),
		"target_side": _i(event.get("target_side", 0)),
		"target_slot": _i(event.get("target_slot", 0)),
	}


## Where each unit stands: from the start boards, then the first event naming it.
func _find_places() -> void:
	var start: Dictionary = _events[0]
	var boards: Array = start.get("boards", [])
	for side: int in boards.size():
		var row: Array = boards[side]
		for value: Variant in row:
			if value is Dictionary:
				var unit: Dictionary = value
				_where[_i(unit["uid"])] = [side, _i(unit["slot"])]
	for value: Variant in _events:
		var event: Dictionary = value
		var uid: int = _i(event.get("uid", -1))
		if uid >= 0 and not _where.has(uid) and event.has("side") and event.has("slot"):
			_where[uid] = [_i(event["side"]), _i(event["slot"])]


func _home(uid: int) -> Vector2:
	var where: Array = _where.get(uid, [0, 0])
	var at: Variant = _place.call(_i(where[0]), _i(where[1]))
	var out: Vector2 = at
	return out


## Which side is yours (a pulse lifts toward the opponent).
func _you_side() -> int:
	if _views.is_empty():
		return 0
	var first: Dictionary = _views[0]
	return _i(first.get("you_side", 0))


func _kind(i: int) -> String:
	var event: Dictionary = _events[i]
	return _kind_of(event)


static func _at(events: Array, k: int) -> Dictionary:
	var event: Dictionary = events[k]
	return event


static func _kind_of(event: Dictionary) -> String:
	return str(event.get("type", ""))


static func _key(uid: int) -> String:
	return "u%d" % uid


static func _quad_out(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)


static func _cubic_out(u: float) -> float:
	return 1.0 - pow(1.0 - u, 3.0)


static func _smoother(u: float) -> float:
	return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
