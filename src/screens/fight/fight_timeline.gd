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
##   "Every animation, I want to have the rotation included"; 25 Nov: the 4 degree lean).
## Frames are 1/60 s of game time at playback speed 1; frame 0 is the boards at rest. Every
## motion is a function of the frame (pose), so a card node the keeper rebuilds keeps its motion,
## and any frame rate shows the same moments.
##
## Not here yet (later steps of the plan): several deaths one after another (CB8 c, step 3:
## _run_queue's "death" item), a single death's look (CB13 c: FightMotion's fall), stat gains
## flying to their stat (CB14 c: _item's buff beats), the winner's portrait striking (CB12 b:
## after the result in _make_steps), and the late-fight speed-ups (FAST: speed_at; GROUP:
## _run_queue's beats). Start of Combat effects show at frame 0, as in the fixture (best.md
## wants them as beats after the rest). No one has watched this move.

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
const LAUNCH_PAST: int = 4
const EFFECT_KILL: int = 20
const FALL: int = 15
const FALL_LEAST: int = 10
const DROP: int = 12
const DROP_LAND: int = 9
const DROP_PX: float = 37.5
const END_AFTER: int = 24
const END_HOLD: int = 90
## Glows that last until the card leaves (an attacker killed before it strikes).
const FOREVER: int = 1 << 20
## The order of a frame's sound cues.
const CUE_ORDER: Array[String] = ["trigger", "hit", "death", "summon", "result"]

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
	# Start of Combat effects show at frame 0, so their trigger sounds there, once
	var first_attack: int = attack_at[0] if not attack_at.is_empty() else end_at
	for i: int in first_attack:
		if _kind(i) == "trigger":
			_cue(0, "trigger", {})
			break
	var last: Dictionary = {}
	for k: int in attack_at.size():
		var to: int = attack_at[k + 1] if k + 1 < attack_at.size() else end_at
		last = _attack(attack_at[k], to, last)
	result_frame = _i(last.get("queue_end", REST)) + END_AFTER
	_reveal[end_at] = result_frame
	var ending: Dictionary = _events[end_at]
	if _kind(end_at) == "combat_end":
		_cue(
			result_frame,
			"result",
			{"winner": _i(ending.get("winner", -1)), "you_side": _you_side()}
		)
	_make_steps(result_frame)
	_make_cues()


## How many schedule frames one frame of game time moves at schedule frame t: 1 throughout. The
## late-fight speed-up (FAST, plan step 5) goes here.
func speed_at(_t: float) -> float:
	return 1.0


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
				part = {"offset": _jab_offset(seg, n)}
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
	var uid: int = _i(event.get("uid", _uid_at(at, "side", "slot")))
	var target: int = _i(event.get("target_uid", _uid_at(at, "target_side", "target_slot")))
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
	for item: Dictionary in before:
		var done: Dictionary = _item(item, t, 1.0)
		t = _i(done["next"])
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
	var stop: Vector2 = line - way * _stop_gap(d) * H
	# the point facing the target leads: the top edge when the target is above, else the bottom
	var lead: float = -1.0 if way.y > 0.0 else 1.0
	var aim: float = FightMotion.TURN_AIM * rad_to_deg(Vector2(0.0, -lead).angle_to(way))
	# full at C-12 when the hold is its least; it holds through a longer one
	var aim_ramp: int = maxi(1, LIFT + HOLD_LEAST + strike - AIM_FULL_BEFORE)
	# the lean tips the leading point toward the target, the same way as the turn
	var lean: float = FightMotion.TURN_LEAN * way.x * lead
	_add(
		_attacker,
		{
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
		}
	)
	# the return moves from C+1 (no frame held at contact) and is home at C + back
	var home_at: int = release + back if hit >= 0 else FOREVER
	glows.append({"key": _attacker, "from": lift, "to": home_at})
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
				"home": home_at if hit >= 0 else -1,
				"queue_end": queue_end,
			}
		)
	)
	return {"release": release, "queue_end": queue_end, "knocked": knocked}


## Which item is the exchange: the first attack damage. An attack whose hits all did nothing (a
## shield on each side, no damage to strike back) has none in the log; its attacker still strikes,
## at the first prevented hit, else straight after what plays before it, unless it dies first.
## -1 when it never strikes (killed by Thorns before the exchange).
func _exchange_at(items: Array[Dictionary], uid: int) -> int:
	var cut: int = items.size()
	for j: int in items.size():
		var kind: String = items[j]["kind"]
		if kind == "exchange":
			return j
		if kind == "death" and cut == items.size():
			cut = j
	for item: Dictionary in items:
		if str(item["kind"]) == "death":
			for value: Variant in item["events"]:
				if _i(_at(_events, _i(value)).get("uid", -1)) == uid:
					return -1
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
	while j < queue.size():
		var item: Dictionary = queue[j]
		var tempo: float = _tempo(t - from)
		var kind: String = item["kind"]
		if kind == "death":
			# the deaths of one pass fall together (CB8 c, plan step 3, staggers them here)
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
			j += run
		else:
			# one beat after another (GROUP, plan step 5, starts a few together here)
			done = _item(item, t, tempo)
			j += 1
		t = _i(done["next"])
		queue_end = maxi(queue_end, _i(done["end"]))
		if done.get("damage", false):
			killed = _i(done["land"])
	return queue_end


## Rule 7: past SPEEDUP_OVER frames of queue, what starts after its first SPEEDUP_FROM frames
## plays faster, up to SPEEDUP_TOP.
func _tempo(into: int) -> float:
	if not _tempo_on:
		return 1.0
	var share: float = clampf(float(into - SPEEDUP_FROM) / float(SPEEDUP_RAMP), 0.0, 1.0)
	return 1.0 + (SPEEDUP_TOP - 1.0) * share


func _fall(item: Dictionary, at: int, length: int) -> void:
	if not _commit:
		return
	_reveal_all(item, at)
	_speeds[at] = float(FALL) / length
	var count: int = 0
	for value: Variant in item["events"]:
		var event: Dictionary = _events[_i(value)]
		var uid: int = _i(event.get("uid", -1))
		_dead[uid] = true
		falls.append({"key": _key(uid), "frame": at, "frames": length})
		count += 1
	var was: Dictionary = _cue_of(at, "death", {"count": 0})
	_cue(at, "death", {"count": _i(was["count"]) + count})


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
		# a stat gain shows here, with its beat's landing (CB14 c, plan step 4, flies it in)
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
	if count > 0:
		jab = (toward / count - _home(source)).normalized() * JAB_PX
	_add(
		key,
		{
			"kind": "pulse",
			"from": start,
			"land": land,
			"lift": up * PULSE_PX,
			"jab": jab,
		}
	)
	glows.append({"key": key, "from": start, "to": land + BEAT_GAP})
	_cue(start, "trigger", {})


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
		if _opens_exchange(i):
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


## The cues by frame, each frame's in CUE_ORDER; a frame's bursts make its hit cue.
func _make_cues() -> void:
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
				cues.append(at[kind])


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
	if launch >= 0 and n > launch:
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
		return _windup_pose(seg, n - start)
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


## The uid of the unit an attack event names by place (a log that leaves out its uids), from the
## board as that event shows it; -1 for none.
func _uid_at(at: int, side_field: String, slot_field: String) -> int:
	var event: Dictionary = _events[at]
	var view: Dictionary = _views[at] if at < _views.size() else {}
	var boards: Array = view.get("boards", [])
	var side: int = _i(event.get(side_field, -1))
	var slot: int = _i(event.get(slot_field, -1))
	if side < 0 or side >= boards.size():
		return -1
	var row: Array = boards[side]
	if slot < 0 or slot >= row.size() or not row[slot] is Dictionary:
		return -1
	var unit: Dictionary = row[slot]
	return _i(unit.get("uid", -1))


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
