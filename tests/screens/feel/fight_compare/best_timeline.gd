extends RefCounted
## The best proposal's schedule for the comparison fight (best.md beside this folder's plans:
## docs/workstreams/fight-animation-24-nov/plans/best.md, sections 2 and 3): from the rules core's
## log and the board after each event, the frame each change shows, every card's motion, every
## burst and glow. best_screen.gd plays it. Each contested branch (best.md section 6, CB1-CB7) is a
## parameter, so an option is a parameter set ({"CB2": "c"}), not its own code path; a branch not
## named plays the proposal's pick. Frames at 60 fps; frame 0 is the boards at rest. Every motion
## is evaluated per frame from these numbers (pose), so a card node the keeper rebuilds (its
## numbers changed) keeps its motion. Exploratory (ideation/fight-animation): nothing here reaches
## the game, and no one has watched it move.

## One card height on the 1920 x 1080 stage.
const H: float = 250.0
## The proposal's pick for each contested branch.
const PICKS: Dictionary = {
	"CB1": "best",
	"CB2": "best",
	"CB3": "linear",
	"CB4": "hold",
	"CB5": "best",
	"CB6": "best",
	"CB7": "best",
}
## CB1, the wind-up: lift frames, the scale it lifts to, pull-back px, the least hold.
const WINDUPS: Dictionary = {
	"today": {"lift": 4, "scale": 1.04, "pull": 12.0, "hold": 0},
	"a": {"lift": 10, "scale": 1.15, "pull": 0.0, "hold": 18},
	"b": {"lift": 8, "scale": 1.14, "pull": 15.0, "hold": 14},
	"c": {"lift": 10, "scale": 1.18, "pull": 20.0, "hold": 14},
	"best": {"lift": 10, "scale": 1.14, "pull": 12.0, "hold": 16},
}
## CB2, where it stops: the gap between centres in card heights, `near` up to `near_d` card heights
## away, `far` from `far_d`, straight between; `back` for any back-row target (-1: no rule).
const STOPS: Dictionary = {
	"a": {"near": 0.78, "near_d": 1.4, "far": 0.45, "far_d": 2.2, "back": 0.35},
	"b": {"near": 0.70, "near_d": 1.18, "far": 0.50, "far_d": 3.18, "back": -1.0},
	"best": {"near": 0.62, "near_d": 1.4, "far": 0.45, "far_d": 2.4, "back": 0.40},
	"c": {"near": 0.50, "near_d": 1.3, "far": 0.42, "far_d": 2.6, "back": -1.0},
}
## CB3, the strike's curve: the power of its ease-in (1: constant speed).
const CURVES: Dictionary = {"linear": 1.0, "mild": 1.6, "quad": 2.0}
## CB4, a trigger before the hit: "hold" (in the raised hold), "freeze" (the attacker waits at
## contact, today's order), "after" (after the return, its change already in the hit's numbers).
const BEFORE_MODES: Array[String] = ["hold", "freeze", "after"]
## CB5, when a card killed in the exchange falls: frames after contact.
const FALLS: Dictionary = {"b": 14, "c": 24, "best": 30, "bg": 60}
## CB6, when the next attacker lifts: at C + after (C + knocked when it was hit in that exchange),
## and no earlier than queue end - lead (lead -1: no queue gate).
const LIFTS: Dictionary = {
	"b": {"after": 8, "knocked": 12, "lead": -1},
	"best": {"after": 28, "knocked": 28, "lead": 16},
	"a": {"after": 36, "knocked": 36, "lead": 50},
	"bg": {"after": 40, "knocked": 40, "lead": -1},
}
## CB7, one trigger many times: the first gap, how each gap shrinks, its floor, whether from the
## 9th the rest land together, how long the count holds at the end. "best_xn" is best with a
## plain-text xN placeholder over the source (labels).
const COMBOS: Dictionary = {
	"bg": {"first": 64.0, "full": 1, "shrink": 0.926, "floor": 0.0, "together": false, "end": 0},
	"a": {"first": 18.0, "full": 2, "shrink": 0.7, "floor": 8.0, "together": false, "end": 16},
	"c": {"first": 18.0, "full": 1, "shrink": -1.3, "floor": 0.0, "together": false, "end": 16},
	"best": {"first": 18.0, "full": 1, "shrink": 0.75, "floor": 5.0, "together": true, "end": 16},
	"best_xn":
	{"first": 18.0, "full": 1, "shrink": 0.75, "floor": 5.0, "together": true, "end": 16},
}
## C's tempo cap (x1.3 a repeat, up to x3.5).
const TEMPO_CAP: float = 3.5

const REST: int = 30
const POP: float = 1.24
const LEAN: float = 4.0
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
const SCALE_HOME: int = 5
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
const COMBO_TOGETHER_FROM: int = 8
const SPEEDUP_OVER: int = 120
const SPEEDUP_FROM: int = 60
const SPEEDUP_RAMP: int = 60
const SPEEDUP_TOP: float = 1.5
const END_AFTER: int = 24
const END_HOLD: int = 90
## Glows that last until the card leaves (an attacker killed before it strikes).
const FOREVER: int = 1 << 20

## {CB1: "a", ...}: the options this film plays.
var options: Dictionary = {}
## [{state, hold, kind, frame, speed}]: FightReplay's steps, each shown from its frame.
var steps: Array[Dictionary] = []
## key -> [{kind, ...}]: every motion of a card, by frame.
var segments: Dictionary = {}
## [{frame, key, side, slot, amount, blocked, taken}], by frame.
var bursts: Array[Dictionary] = []
## [{key, from, to}]: the attacker's (and a trigger's) glow.
var glows: Array[Dictionary] = []
## [{key, from, to, text}]: the xN placeholder (CB7 "best_xn" only).
var labels: Array[Dictionary] = []
## The plan, per attack: what each phase is scheduled to do, by frame (frame 0 = the boards).
var attacks: Array[Dictionary] = []
## The film's frame of frame 0 (best_screen.gd sets it), for comparing the plan with the log.
var frame_offset: int = -1
var end_frame: int = 0
## Where the schedule had to bend a rule of the proposal.
var notes: PackedStringArray = []

var _events: Array = []
var _snaps: Array = []
var _reveal: Array[int] = []
var _speeds: Dictionary = {}
var _lifts: Array[Dictionary] = []
var _place: Callable
var _where: Dictionary = {}
var _dead: Dictionary = {}
var _attacker: String = ""
var _commit: bool = true
var _tempo_on: bool = false
var _falls: Array[Dictionary] = []


func _init(chosen: Dictionary = {}) -> void:
	options = chosen.duplicate()


## The option a branch plays: the scenario's, else the proposal's pick.
func pick(branch: String) -> String:
	return str(options.get(branch, PICKS[branch]))


## events: the rules core's log; snaps: the view state after each event (best_replay.gd); place:
## (side, slot) -> where a unit stands (FightScreen.unit_xy).
func build(events: Array, snaps: Array, place: Callable) -> void:
	_events = events
	_snaps = snaps
	_place = place
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
	var last: Dictionary = {}
	for k: int in attack_at.size():
		var to: int = attack_at[k + 1] if k + 1 < attack_at.size() else end_at
		last = _attack(attack_at[k], to, last)
	var result: int = _i(last.get("queue_end", REST)) + END_AFTER
	_reveal[end_at] = result
	_make_steps(result)


## Each card's pose at a frame, as offsets from where it stands: {offset, scale, turn, light}.
func pose(key: String, n: int) -> Dictionary:
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


## The keys glowing at a frame.
func glowing(n: int) -> Dictionary:
	var out: Dictionary = {}
	for glow: Dictionary in glows:
		if n >= _i(glow["from"]) and n < _i(glow["to"]):
			out[str(glow["key"])] = true
	return out


## The xN placeholder showing at a frame, or {}.
func label_at(n: int) -> Dictionary:
	for label: Dictionary in labels:
		if n >= _i(label["from"]) and n < _i(label["to"]):
			return label
	return {}


## What the report keeps: the options, the plan per attack, the film's frame of frame 0.
func report() -> Dictionary:
	var chosen: Dictionary = {}
	for branch: String in PICKS:
		chosen[branch] = pick(branch)
	return {
		"options": chosen,
		"frame_offset": frame_offset,
		"end_frame": end_frame,
		"attacks": attacks,
		"falls": _falls,
		"bursts": bursts.size(),
		"notes": notes,
		"claims":
		{
			"windup": WINDUPS[pick("CB1")],
			"stop": STOPS[pick("CB2")],
			"curve": CURVES[pick("CB3")],
			"before": pick("CB4"),
			"exchange_fall": FALLS[pick("CB5")],
			"next_lift": LIFTS[pick("CB6")],
			"combo": COMBOS[pick("CB7")],
		},
	}


# ---- one attack and what it causes ----


func _attack(at: int, to: int, last: Dictionary) -> Dictionary:
	var event: Dictionary = _events[at]
	var uid: int = _i(event["uid"])
	var target: int = _i(event["target_uid"])
	_attacker = _key(uid)
	var from_xy: Vector2 = _home(uid)
	var line: Vector2 = _home(target) - from_xy
	var d: float = line.length() / H
	var way: Vector2 = line.normalized()
	var strike: int = 7 if d <= 1.4 else (8 if d <= 2.4 else 9)
	var back: int = 12 if d <= 1.4 else (14 if d <= 2.4 else 16)
	var windup: Dictionary = WINDUPS[pick("CB1")]
	var lift_f: int = _i(windup["lift"])
	var lift: int = REST if last.is_empty() else _lift_at(last, _attacker)
	if not last.is_empty():
		var previous: Dictionary = attacks.back()
		previous["next_lift"] = lift
	_lifts.append({"frame": lift, "lunge": _lunge(event)})
	var hold0: int = lift + lift_f
	var queue_was: int = _i(last.get("queue_end", 0))
	var items: Array[Dictionary] = _items(at + 1, to)
	var hit: int = -1
	for j: int in items.size():
		if str(items[j]["kind"]) == "exchange":
			hit = j
			break
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
	var mode: String = pick("CB4") if hit >= 0 and not before.is_empty() else "hold"
	var t: int = maxi(hold0, queue_was)
	var last_land: int = -1
	if mode == "hold":
		for item: Dictionary in before:
			var done: Dictionary = _item(item, t, 1.0)
			t = _i(done["next"])
			last_land = maxi(last_land, _i(done["land"]))
	var hold_min: int = _i(windup["hold"])
	var hold_need: int = hold_min
	if last_land >= 0:
		hold_need = maxi(hold_min, last_land + HOLD_PAST - hold0)
	var launch: int = maxi(hold0 + hold_need, queue_was + LAUNCH_PAST)
	var contact: int = -1
	var release: int = last_land
	if hit >= 0:
		contact = launch + strike
		release = contact
		if mode == "freeze":
			t = contact
			for item: Dictionary in before:
				var done: Dictionary = _item(item, t, 1.0)
				t = _i(done["next"])
				last_land = maxi(last_land, _i(done["land"]))
			release = last_land + HOLD_PAST
	else:
		launch = -1
	var gap: float = _stop_gap(d, _i(event["target_slot"]) >= 4)
	var stop: Vector2 = line - way * gap * H
	var pull: Vector2 = -way * _f(windup["pull"])
	_add(
		_attacker,
		{
			"kind": "attack",
			"from": lift,
			"lift": lift_f,
			"scale": _f(windup["scale"]),
			"pull": pull,
			"lean": LEAN * way.x,
			"launch": launch,
			"strike": strike,
			"curve": _f(CURVES[pick("CB3")]),
			"contact": contact,
			"stop": stop,
			"release": release,
			"back": back,
		}
	)
	var home_at: int = release + 1 + back if hit >= 0 else FOREVER
	glows.append({"key": _attacker, "from": lift, "to": home_at})
	var knocked: Array[String] = []
	if hit >= 0:
		knocked = _exchange(items[hit], release, way)
		if mode == "after":
			for item: Dictionary in before:
				_reveal_all(item, release + NUMBERS_AT)
	var queue_from: int = release + AFTER_AT
	var queue: Array[Dictionary] = []
	if mode == "after":
		for item: Dictionary in before:
			var quiet: Dictionary = item.duplicate()
			quiet["quiet"] = true
			queue.append(quiet)
	if hit >= 0 and not after.is_empty() and str(after[0]["kind"]) == "death":
		after[0]["exchange_kill"] = true
	queue.append_array(after)
	var kill_land: int = release if hit < 0 else release + NUMBERS_AT
	_commit = false
	_tempo_on = false
	var first_pass: int = _run_queue(queue, queue_from, release, kill_land)
	_tempo_on = first_pass - queue_from > SPEEDUP_OVER
	_commit = true
	var falls_before: int = _falls.size()
	var queue_end: int = maxi(
		_run_queue(queue, queue_from, release, kill_land), release + NUMBERS_AT
	)
	(
		attacks
		. append(
			{
				"attack": attacks.size(),
				"attacker": _attacker,
				"target": _key(target),
				"distance_h": snappedf(d, 0.001),
				"lift": lift,
				"lift_frames": lift_f,
				"lift_scale": _f(windup["scale"]),
				"pull_px": _f(windup["pull"]),
				"hold_frames": launch - hold0 if launch >= 0 else -1,
				"launch": launch,
				"strike_frames": strike if hit >= 0 else -1,
				"contact": contact,
				"release": release,
				"stop_gap_h": snappedf(gap, 0.001) if hit >= 0 else -1.0,
				"return_frames": back if hit >= 0 else -1,
				"home": home_at if hit >= 0 else -1,
				"numbers": release + NUMBERS_AT if hit >= 0 else -1,
				"before_mode": mode,
				"before_items": before.size(),
				"falls": _falls.slice(falls_before),
				"queue_from": queue_from,
				"queue_end": queue_end,
				"speedup": _tempo_on,
				"no_strike": hit < 0,
				"next_lift": -1,
			}
		)
	)
	return {"release": release, "queue_end": queue_end, "knocked": knocked}


## When the next attacker lifts (CB6), from the last attack's C and queue end.
func _lift_at(last: Dictionary, key: String) -> int:
	var rule: Dictionary = LIFTS[pick("CB6")]
	var knocked: Array = last.get("knocked", [])
	var after: int = _i(rule["knocked"]) if knocked.has(key) else _i(rule["after"])
	var at: int = _i(last["release"]) + after
	var lead: int = _i(rule["lead"])
	if lead >= 0:
		at = maxi(at, _i(last["queue_end"]) - lead)
	return at


## CB2: the gap between centres at the stop, in card heights.
func _stop_gap(d: float, back_row: bool) -> float:
	var stop: Dictionary = STOPS[pick("CB2")]
	if back_row and _f(stop["back"]) >= 0.0:
		return _f(stop["back"])
	var near_d: float = _f(stop["near_d"])
	var far_d: float = _f(stop["far_d"])
	var share: float = clampf((d - near_d) / (far_d - near_d), 0.0, 1.0)
	return lerpf(_f(stop["near"]), _f(stop["far"]), share)


## The exchange lands at C+2 on every card it damaged; the target is knocked from C. Returns the
## keys knocked.
func _exchange(item: Dictionary, at: int, way: Vector2) -> Array[String]:
	var knocked: Array[String] = []
	_reveal_all(item, at + NUMBERS_AT)
	for value: Variant in item["events"]:
		var i: int = _i(value)
		var event: Dictionary = _events[i]
		var key: String = _key(_i(event["uid"]))
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
			var fall: int = killed + roundi(EFFECT_KILL / tempo)
			if item.get("exchange_kill", false):
				fall = at + _i(FALLS[pick("CB5")])
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
			done = _item(item, t, tempo)
			j += 1
		t = _i(done["next"])
		queue_end = maxi(queue_end, _i(done["end"]))
		if done.get("damage", false):
			killed = _i(done["land"])
	return queue_end


## Rule 7: past 120 f of queue, what starts after its first 60 f plays faster, up to x1.5.
func _tempo(into: int) -> float:
	if not _tempo_on:
		return 1.0
	var share: float = clampf(float(into - SPEEDUP_FROM) / SPEEDUP_RAMP, 0.0, 1.0)
	return 1.0 + (SPEEDUP_TOP - 1.0) * share


func _fall(item: Dictionary, at: int, length: int) -> void:
	if not _commit:
		return
	_reveal_all(item, at)
	_speeds[at] = float(FALL) / length
	for value: Variant in item["events"]:
		var event: Dictionary = _events[_i(value)]
		var uid: int = _i(event["uid"])
		_dead[uid] = true
		_falls.append({"key": _key(uid), "frame": at, "frames": length})


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


## Rule 5 (CB7): one trigger many times, each gap shorter than the last.
func _combo(run: Array[Dictionary], start: int, from: int) -> Dictionary:
	var combo: Dictionary = COMBOS[pick("CB7")]
	var together: bool = combo["together"]
	var t: float = float(start)
	var lands: Array[int] = []
	var together_at: int = -1
	var damage: bool = false
	for k: int in run.size():
		var at: int = roundi(t)
		if together and k >= COMBO_TOGETHER_FROM:
			if together_at < 0:
				together_at = at
			at = together_at
		var tempo: float = _tempo(at - from)
		var done: Dictionary = _item(run[k], at, tempo)
		lands.append(_i(done["land"]))
		damage = damage or done.get("damage", false)
		t += maxf(_f(combo["floor"]), _combo_gap(combo, k) / tempo)
	var last: int = lands.max()
	var end: int = last + _i(combo["end"])
	if _commit and pick("CB7") == "best_xn":
		var key: String = _key(_i(run[0]["source"]))
		for k: int in lands.size():
			var until: int = lands[k + 1] if k + 1 < lands.size() else end
			labels.append({"key": key, "from": lands[k], "to": until, "text": "x%d" % (k + 1)})
	return {"land": last, "next": last + BEAT_GAP, "end": end, "damage": damage}


## The gap after the k-th repeat (0 = after the first), before the floor and tempo.
static func _combo_gap(combo: Dictionary, k: int) -> float:
	var first: float = _f(combo["first"])
	var shrink: float = _f(combo["shrink"])
	var full: int = _i(combo["full"])
	if k < full:
		return first
	if shrink < 0.0:
		# a tempo that rises by -shrink per repeat, up to TEMPO_CAP
		return first / minf(pow(-shrink, k), TEMPO_CAP)
	return first * pow(shrink, k - full + 1)


## One item at `start`: a trigger's beat (pulse, jab, landing), an arrival, or a rider. Returns
## {land, next, end, damage}.
func _item(item: Dictionary, start: int, tempo: float) -> Dictionary:
	var kind: String = item["kind"]
	if kind == "arrival":
		return _arrive(item, start, tempo)
	if kind != "beat":
		if _commit and not item.get("quiet", false):
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
		if not item.get("quiet", false):
			_reveal_all(item, land)
		for value: Variant in item["events"]:
			var i: int = _i(value)
			if _kind(i) in ["damage", "destroy", "prevented"]:
				var hurt: Dictionary = _events[i]
				_burst(hurt, land, _kind(i) == "prevented")
				damage = true
	return {"land": land, "next": land + roundi(BEAT_GAP / tempo), "end": land, "damage": damage}


## A unit arriving: it drops in from above its slot with today's fade, landing at f9.
func _arrive(item: Dictionary, at: int, tempo: float) -> Dictionary:
	var land: int = at + roundi(DROP_LAND / tempo)
	if _commit:
		_reveal_all(item, at)
		for value: Variant in item["events"]:
			var i: int = _i(value)
			if _kind(i) in ["summon", "reserve", "return"]:
				var event: Dictionary = _events[i]
				_add(_key(_i(event["uid"])), {"kind": "summon", "from": at, "tempo": tempo})
	return {
		"land": land,
		"next": land + roundi(BEAT_GAP / tempo),
		"end": at + roundi(DROP / tempo),
		"damage": false
	}


## The source's pulse (today's trigger lift and glow), and its jab toward the target when the
## effect lands on another card (today's jab, standing in for a drawn link).
func _pulse(item: Dictionary, start: int, land: int) -> void:
	if not _commit:
		return
	var source: int = _i(item["source"])
	var key: String = _key(source)
	var where: Array = _where[source]
	var up: Vector2 = Vector2.UP if _i(where[0]) == 0 else Vector2.DOWN
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


# ---- grouping the log ----


## The events from `from` up to `to` as items: the exchange, death passes, beats (a trigger and
## what it does), arrivals, riders.
func _items(from: int, to: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var i: int = from
	while i < to:
		var event: Dictionary = _events[i]
		var kind: String = _kind(i)
		var listed: Array = [i]
		var item: Dictionary = {"kind": "rider", "events": listed}
		var j: int = i + 1
		if kind == "damage" and event.get("from_attack", false):
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
		if kind in ["trigger", "death", "attack", "combat_end"] or _exchange_part(j):
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


# ---- the steps ----


## The view state at each frame something shows: the board after the longest run of the log
## whose changes have all shown, with the attack's lunge (for the fixture's log) and the result.
func _make_steps(result: int) -> void:
	var shown: int = 0
	for i: int in _events.size():
		if _reveal[i] < 0:
			_reveal[i] = shown
		elif _reveal[i] < shown:
			notes.append("event %d (%s) shown at %d, not %d" % [i, _kind(i), shown, _reveal[i]])
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
		var snap: Dictionary = _snaps[upto]
		var view: Dictionary = snap.duplicate(true)
		var was: Dictionary = view.get("moment", {})
		var moment: Dictionary = {}
		if was.has("result") and frame >= result:
			moment["result"] = was["result"]
			kind = "end"
		if not lunge.is_empty():
			moment["lunge"] = lunge.duplicate()
		view["moment"] = moment
		var speed: float = _f(_speeds.get(frame, 1.0))
		steps.append({"state": view, "hold": 0.0, "kind": kind, "frame": frame, "speed": speed})
	for k: int in steps.size():
		var step: Dictionary = steps[k]
		var next: int = _i(steps[k + 1]["frame"]) if k + 1 < steps.size() else result + END_HOLD
		step["hold"] = (next - _i(step["frame"])) / 60.0
	end_frame = result + END_HOLD


# ---- poses ----


func _attack_pose(seg: Dictionary, n: int) -> Dictionary:
	var start: int = seg["from"]
	if n <= start:
		return {}
	var launch: int = seg["launch"]
	if launch < 0 or n <= launch:
		return _windup_pose(seg, n - start)
	var contact: int = seg["contact"]
	var stop: Vector2 = seg["stop"]
	var lifted: float = seg["scale"]
	if n < contact:
		var u: float = float(n - launch) / _i(seg["strike"])
		var pull: Vector2 = seg["pull"]
		var along: float = pow(u, _f(seg["curve"]))
		return {
			"offset": pull.lerp(stop, along), "scale": lifted, "turn": _f(seg["lean"]) * (1 - u)
		}
	if n == contact:
		return {"offset": stop, "scale": POP}
	return _return_pose(seg, n)


func _windup_pose(seg: Dictionary, k: int) -> Dictionary:
	var lift: int = seg["lift"]
	var e: float = 1.0 if lift <= 0 else _quad_out(minf(1.0, float(k) / lift))
	var pull: Vector2 = seg["pull"]
	return {
		"offset": pull * e,
		"scale": lerpf(1.0, _f(seg["scale"]), e),
		"turn": _f(seg["lean"]) * e,
	}


func _return_pose(seg: Dictionary, n: int) -> Dictionary:
	var release: int = seg["release"]
	var stop: Vector2 = seg["stop"]
	var lifted: float = seg["scale"]
	if n <= release + 1:
		return {"offset": stop, "scale": lifted}
	var v: float = float(n - release - 1) / _i(seg["back"])
	if v >= 1.0:
		return {}
	var e: float = 1.0 - pow(1.0 - v, 4.0)
	var shrink: float = clampf(float(n - release - 1) / SCALE_HOME, 0.0, 1.0)
	return {"offset": stop.lerp(Vector2.ZERO, e), "scale": lerpf(lifted, 1.0, shrink)}


func _knock_pose(seg: Dictionary, n: int) -> Dictionary:
	var k: int = n - _i(seg["from"])
	if k <= 0 or k >= KNOCK_IN + KNOCK_SETTLE:
		return {}
	var a: float = float(k) / KNOCK_IN
	if k > KNOCK_IN:
		a = 1.0 - _cubic_out(float(k - KNOCK_IN) / KNOCK_SETTLE)
	var way: Vector2 = seg["way"]
	return {"offset": way * a, "turn": _f(seg["turn"]) * a}


func _summon_pose(seg: Dictionary, n: int) -> Dictionary:
	var tempo: float = seg["tempo"]
	var k: float = (n - _i(seg["from"])) * tempo
	if k >= DROP:
		return {}
	var fall: float = clampf(k / DROP_LAND, 0.0, 1.0)
	return {
		"offset": Vector2.UP * DROP_PX * (1.0 - fall * fall),
		"alpha": clampf(k / DROP, 0.0, 1.0),
	}


func _pulse_lift(seg: Dictionary, n: int) -> float:
	var start: int = seg["from"]
	var land: int = seg["land"]
	if n <= start:
		return 0.0
	if n <= land:
		return _quad_out(minf(1.0, float(n - start) / PULSE_IN))
	return 1.0 - _cubic_out(minf(1.0, float(n - land) / PULSE_SETTLE))


func _jab_offset(seg: Dictionary, n: int) -> Vector2:
	var jab: Vector2 = seg["jab"]
	var k: int = n - _i(seg["from"])
	var land: int = seg["land"]
	if jab == Vector2.ZERO or k <= JAB_FROM:
		return Vector2.ZERO
	if n <= land:
		return jab * _quad_out(minf(1.0, float(k - JAB_FROM) / (JAB_TO - JAB_FROM)))
	return jab * (1.0 - _cubic_out(minf(1.0, float(n - land) / JAB_SETTLE)))


func _light(seg: Dictionary, n: int) -> Color:
	var k: int = n - _i(seg["from"])
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
	var key: String = _key(_i(event["uid"]))
	(
		bursts
		. append(
			{
				"frame": at,
				"key": key,
				"side": _i(event["side"]),
				"slot": _i(event["slot"]),
				"amount": _i(event.get("amount", 0)) if _kind_of(event) == "damage" else 0,
				"blocked": blocked,
				"taken": key == _attacker,
			}
		)
	)


func _lunge(event: Dictionary) -> Dictionary:
	return {
		"side": _i(event["side"]),
		"slot": _i(event["slot"]),
		"target_side": _i(event["target_side"]),
		"target_slot": _i(event["target_slot"]),
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


func _kind(i: int) -> String:
	var event: Dictionary = _events[i]
	return _kind_of(event)


static func _kind_of(event: Dictionary) -> String:
	return str(event.get("type", ""))


static func _key(uid: int) -> String:
	return "u%d" % uid


static func _quad_out(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)


static func _cubic_out(u: float) -> float:
	return 1.0 - pow(1.0 - u, 3.0)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
