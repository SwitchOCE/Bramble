extends RefCounted
## The best proposal's schedule for the comparison fight (best.md beside this folder's plans:
## docs/workstreams/fight-animation-24-nov/plans/best.md, sections 2 and 3): from the rules core's
## log and the board after each event, the frame each change shows, every card's motion, every
## burst and glow. best_screen.gd plays it. Each contested branch (best.md section 6, CB1-CB7;
## CB8 from research/mass-deaths.md, CB9 from research/rotation.md) is a parameter, so an option
## is a parameter set ({"CB2": "c"}), not its own code path; a branch not named plays the
## proposal's pick. Frames at 60 fps; frame 0 is the boards at rest. Every motion is evaluated per
## frame from these numbers (pose), so a card node the keeper rebuilds (its numbers changed) keeps
## its motion. Exploratory (ideation/fight-animation): nothing here reaches the game, and no one
## has watched it move.

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
	"CB8": "a",
	"CB9": "none",
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
## "a" (shallow) stops 0.70 far, with no back-row rule, so it is shallower than "b" at every
## distance (plan A's 0.45 far and 0.35 back row went deeper than B's; scope review, 24 Nov).
const STOPS: Dictionary = {
	"a": {"near": 0.78, "near_d": 1.4, "far": 0.70, "far_d": 2.2, "back": -1.0},
	"b": {"near": 0.70, "near_d": 1.18, "far": 0.50, "far_d": 3.18, "back": -1.0},
	"best": {"near": 0.62, "near_d": 1.4, "far": 0.45, "far_d": 2.4, "back": 0.40},
	"c": {"near": 0.50, "near_d": 1.3, "far": 0.42, "far_d": 2.6, "back": -1.0},
	# Galaxy (R2): stops 0.2-0.57 h past the target's centre; the centre gap is negative
	"galaxy": {"near": -0.3, "near_d": 1.4, "far": -0.3, "far_d": 2.4, "back": -1.0},
}
## CB3, the strike's curve: the power of its ease-in (1: constant speed). "gentle" is CB11's
## gentler speed-up (the owner, 24 Nov: "maybe even a slower speed-up would be better").
const CURVES: Dictionary = {"linear": 1.0, "gentle": 1.3, "mild": 1.6, "quad": 2.0}
## CB4, a trigger before the hit: "hold" (in the raised hold), "freeze" (today's order: the
## trigger flares while the attacker waits at contact, and its change shows with the exchange's at
## C+22), "after" (after the return: the log is reordered by reorder(), so the exchange's numbers
## show first and the trigger's own at its landing). Lethal Thorns can't play "after": the
## attacker never strikes, so it plays "hold".
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
## 9th the rest land together, how long the count holds at the end, whether a card hit again and
## again keeps one burst that re-pops with the running total ("total"), and whether rule 7's
## speed-up applies ("speedup"). "best" is the proposal (rule 7 on); for the CB7 comparison every
## other option runs with rule 7 off, "best_no7" being the proposal without it. "best_xn" adds a
## plain-text xN placeholder over the source (labels). "b" is plan B's: max(4, 14 x 0.75^(k-1)).
const COMBOS: Dictionary = {
	"bg":
	{
		"first": 64.0,
		"full": 1,
		"shrink": 0.926,
		"floor": 0.0,
		"together": false,
		"end": 0,
		"total": false,
		"speedup": false,
	},
	"a":
	{
		"first": 18.0,
		"full": 2,
		"shrink": 0.7,
		"floor": 8.0,
		"together": false,
		"end": 16,
		"total": false,
		"speedup": false,
	},
	"b":
	{
		"first": 14.0,
		"full": 1,
		"shrink": 0.75,
		"floor": 4.0,
		"together": true,
		"end": 16,
		"total": true,
		"speedup": false,
	},
	"c":
	{
		"first": 18.0,
		"full": 1,
		"shrink": -1.3,
		"floor": 0.0,
		"together": false,
		"end": 16,
		"total": false,
		"speedup": false,
	},
	"best":
	{
		"first": 18.0,
		"full": 1,
		"shrink": 0.75,
		"floor": 5.0,
		"together": true,
		"end": 16,
		"total": true,
		"speedup": true,
	},
	"best_no7":
	{
		"first": 18.0,
		"full": 1,
		"shrink": 0.75,
		"floor": 5.0,
		"together": true,
		"end": 16,
		"total": true,
		"speedup": false,
	},
	"best_xn":
	{
		"first": 18.0,
		"full": 1,
		"shrink": 0.75,
		"floor": 5.0,
		"together": true,
		"end": 16,
		"total": true,
		"speedup": false,
	},
}
## CB8, several deaths at once (research/mass-deaths.md): the gaps between fall starts, in frames
## (the k-th gap is gaps[k], the floor past the list), and the cap on the whole spread (-1: none);
## a spread past the cap shrinks every gap by the same factor. "a" is all at once, the proposal as
## it is. Display order only: the deaths still resolve at one moment. Order (rulebook 9.7.3): the
## active side's dying units first, then the other side's, each in reading order. In b, c and d,
## each death's own "after a friendly unit dies" gain (Old Brock) lands STAGGER_LAND after that
## fall starts, not after the group; reorder() moves those events beside their death.
const STAGGERS: Dictionary = {
	"a": {"gaps": [], "floor": 0, "cap": 0},
	"b": {"gaps": [4], "floor": 4, "cap": 24},
	"c": {"gaps": [10, 7, 5, 4, 4], "floor": 4, "cap": 30},
	"d": {"gaps": [12], "floor": 12, "cap": -1},
}
## A staggered death's gain lands as its fall ends (the slot empty).
const STAGGER_LAND: int = 15
## CB9, rotation (research/rotation.md, Galaxy measured; the owner, 24 Nov: "the card should tilt
## or rotate to point at what it's hitting"). The point facing the target leads: the top of your
## cards, the bottom of theirs. "aim" is the share of the path's angle the card turns to, in its
## own plane (0: the proposal's 4 degree lean instead). "keystone" is the leading edge's width over
## the trailing edge's at full tip (tip.gdshader, true perspective). "length" is the card's length
## at contact (its scale along its own length, as card_carry.gd's pitch; 0.75 reads as a tip of
## about 41 degrees). Galaxy: aim 89-104 %, leading edge 8-12 % shorter, length 0.67-0.78.
const ROTATIONS: Dictionary = {
	"none": {"aim": 0.0, "keystone": 1.0, "length": 1.0},
	"aim": {"aim": 0.95, "keystone": 1.0, "length": 1.0},
	"tip": {"aim": 0.95, "keystone": 0.9, "length": 0.75},
	# the aim and the shortening without the shader's keystone: does the shader add anything?
	"length": {"aim": 0.95, "keystone": 1.0, "length": 0.75},
	# CB17, the tip's strength (the owner, 24 Nov: "Maybe a small lean is actually nice ... Leaning
	# with turning in the same direction as the turn makes a lot of sense to me"): the length is
	# the cosine of the dip, as 0.75 reads as about 41 degrees; "tip" is the strong one. Small:
	# about 15 degrees (cos 15 = 0.966); medium: about 32 (cos 32 = 0.85).
	"tip_small": {"aim": 0.95, "keystone": 0.97, "length": 0.965},
	"tip_medium": {"aim": 0.95, "keystone": 0.94, "length": 0.85},
	# the turn plus the proposal's 4 degree in-plane lean, no tip (the owner, 24 Nov: "A small lean,
	# like four degrees, might be excellent"): the lean tips the leading point toward the target,
	# the same way as the turn, through the wind-up, and is gone by contact
	"aim_lean": {"aim": 0.95, "keystone": 1.0, "length": 1.0, "lean": 4.0},
	# CB15, the amount of turn, each with the medium tip (the owner, 24 Nov: "Where's the rotate
	# amount?"): half, three-quarters, 95 % (tip_medium), and 95 % with the full turn capped at 30
	# degrees ("cap", degrees)
	"tip_half": {"aim": 0.5, "keystone": 0.94, "length": 0.85},
	"tip_3q": {"aim": 0.75, "keystone": 0.94, "length": 0.85},
	"tip_cap30": {"aim": 0.95, "keystone": 0.94, "length": 0.85, "cap": 30.0},
}
## The turn is full this many frames before contact (Galaxy: -13 to -12); it ramps from the
## lift's first frame, so it is full at C-12 when the hold is its least.
const AIM_FULL_BEFORE: int = 12
## Share of the full turn left at contact (Galaxy 89-95 %), eased back over the strike.
const AIM_AT_CONTACT: float = 0.9
## Straight again this many frames after the return starts (Galaxy about +25: slower than the card
## moves home, so it lands turned and straightens in its slot; 65-100 % still there at +10).
const AIM_STRAIGHT: int = 25
## The keystone fades over this many frames after the return starts (Galaxy about 10).
const TIP_FADE: int = 10
## The length is back to 1 this many frames after the return starts (Galaxy 0.95 by +5 to +8).
const LENGTH_BACK: int = 8
## C's tempo cap (x1.3 a repeat, up to x3.5).
const TEMPO_CAP: float = 3.5

const REST: int = 30
const POP: float = 1.24
## The proposal's lean toward the target (degrees, times the path's sideways share), tipping the
## leading point (the top of yours, the bottom of theirs) toward it. Before the fix of 24 Nov it
## turned clockwise for a target to the right on both sides, tipping their bottom point away.
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
const COMBO_TOGETHER_FROM: int = 8
const SPEEDUP_OVER: int = 120
const SPEEDUP_FROM: int = 60
const SPEEDUP_RAMP: int = 60
const SPEEDUP_TOP: float = 1.5
## Rule 7's numbers ("R7" in the options; fight_length.gd's what-ifs, not contested branches):
## the queue length that turns it on, where in the queue it starts, the ramp, the top speed.
## "best" is the proposal's (the constants above).
const SPEEDUPS: Dictionary = {
	"best": {"over": SPEEDUP_OVER, "from": SPEEDUP_FROM, "ramp": SPEEDUP_RAMP, "top": SPEEDUP_TOP},
	"x2": {"over": SPEEDUP_OVER, "from": SPEEDUP_FROM, "ramp": SPEEDUP_RAMP, "top": 2.0},
	"early": {"over": 60, "from": 30, "ramp": 30, "top": 1.5},
	"early_x2": {"over": 60, "from": 30, "ramp": 30, "top": 2.0},
}
## A fight-wide speed-up ("FAST" in the options; a what-if from research/fight-length.md, not a
## contested branch): Battlegrounds 31.6, "combat animations will now accelerate as the battle
## rages on". From the lift of attack number `attack` (1: the first) to the result, everything
## this schedule holds plays `speed` times faster: best_screen.gd runs it on a clock that moves
## speed_at() frames of the schedule each drawn frame (advance()). The result's hold plays at x1.
## A fight with fewer attacks plays at x1 throughout.
const FASTS: Dictionary = {
	"none": {"attack": 0, "speed": 1.0},
	"a5": {"attack": 5, "speed": 1.5},
}
const END_AFTER: int = 24
const END_HOLD: int = 90
## Glows that last until the card leaves (an attacker killed before it strikes).
const FOREVER: int = 1 << 20
## The rotation switch (rotate.gd): with "ROTATE": "on", rotate.gd's set in place of CB9's option.
const Rotate := preload("res://tests/screens/feel/fight_compare/rotate.gd")

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
## [{kind, from, to}]: each beat (trigger, to its next), arrival (summon), fall (death) and a
## combo's closing count (trigger), by frame; fight_length.gd's breakdown of a fight's time.
var spans: Array[Dictionary] = []
## "FAST": the schedule's frames from which, and up to which, it plays faster (-1: never).
var fast_from: int = -1
var fast_to: int = -1
## The schedule frames the clock moves this drawn frame (best_screen.gd sets it): the contact
## pop shows for this long, so a sped-up clock still draws it once.
var clock_step: float = 1.0

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
## key -> the running total a combo's re-popping burst shows (rule 5), while a combo plays.
var _totals: Dictionary = {}
var _total_on: bool = false
## [{attack, start, lands}]: every combo, by frame.
var _combos: Array[Dictionary] = []
## [{attack, base, falls: [{key, frame}], lands}]: every staggered group of deaths (CB8), by frame.
var _staggers: Array[Dictionary] = []


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
	var fast: Dictionary = _fast()
	var nth: int = _i(fast["attack"])
	if nth >= 1 and attacks.size() >= nth and _f(fast["speed"]) > 1.0:
		var from: Dictionary = attacks[nth - 1]
		fast_from = _i(from["lift"])
		fast_to = result
	_make_steps(result)


## "FAST": the options', else none.
func _fast() -> Dictionary:
	return FASTS[str(options.get("FAST", "none"))]


## How many schedule frames one drawn frame moves at schedule frame t (1, or FAST's speed).
func speed_at(t: float) -> float:
	if fast_from >= 0 and t >= fast_from and t < fast_to:
		return _f(_fast()["speed"])
	return 1.0


## The clock after one more drawn frame from t. It lands on the result's frame itself, which then
## plays at x1 (before the speed-up the clock is on whole frames, so it lands on its start too).
func advance(t: float) -> float:
	var next: float = t + speed_at(t)
	if fast_from >= 0 and t < fast_to and next > fast_to:
		next = float(fast_to)
	return next


## Drawn frames from schedule frame 0 until the clock reaches frame m (the film's count).
func drawn_frames_to(m: int) -> int:
	var t: float = 0.0
	var n: int = 0
	while t < m:
		t = advance(t)
		n += 1
	return n


## Each card's pose at a frame, as offsets from where it stands: {offset, scale, turn, light,
## length, keystone, lead}. length: its scale along its own length on top of scale (CB9 "tip");
## keystone: its leading edge's width over its trailing edge's (1: flat); lead: 1 when its top edge
## leads, -1 its bottom.
func pose(key: String, n: float) -> Dictionary:
	var offset: Vector2 = Vector2.ZERO
	var size: float = 1.0
	var turn: float = 0.0
	var length: float = 1.0
	var keystone: float = 1.0
	var lead: float = 1.0
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
		length *= _f(part.get("length", 1.0))
		if part.has("keystone") and _f(part["keystone"]) < keystone:
			keystone = _f(part["keystone"])
			lead = _f(part["lead"])
		if part.has("alpha"):
			light.a *= _f(part["alpha"])
	offset += lift_way * lifted
	return {
		"offset": offset,
		"scale": size,
		"turn": turn,
		"light": light,
		"length": length,
		"keystone": keystone,
		"lead": lead,
	}


## The keys glowing at a frame.
func glowing(n: float) -> Dictionary:
	var out: Dictionary = {}
	for glow: Dictionary in glows:
		if n >= _i(glow["from"]) and n < _i(glow["to"]):
			out[str(glow["key"])] = true
	return out


## The xN placeholder showing at a frame, or {}.
func label_at(n: float) -> Dictionary:
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
		"combos": _combos,
		"staggers": _staggers,
		"bursts": bursts.size(),
		"notes": notes,
		# FAST's frames in this schedule
		"fast": {"from": fast_from, "to": fast_to, "speed": _f(_fast()["speed"])},
		"claims":
		{
			"windup": WINDUPS[pick("CB1")],
			"stop": STOPS[pick("CB2")],
			"curve": CURVES[pick("CB3")],
			"before": pick("CB4"),
			"exchange_fall": FALLS[pick("CB5")],
			"next_lift": LIFTS[pick("CB6")],
			"combo": COMBOS[pick("CB7")],
			"stagger": STAGGERS[pick("CB8")],
			"rotation": _rotation(),
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
	if hit >= 0 and not after.is_empty() and after[0].get("after_hit", false):
		mode = "after"
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
			# today's order: the trigger flares while the attacker waits at contact; what it
			# changes shows only with the exchange's numbers
			t = contact
			for item: Dictionary in before:
				var flare: Dictionary = item.duplicate()
				flare["quiet"] = true
				flare["silent"] = true
				var done: Dictionary = _item(flare, t, 1.0)
				t = _i(done["next"])
				last_land = maxi(last_land, _i(done["land"]))
			release = last_land + HOLD_PAST
	else:
		launch = -1
	var gap: float = _stop_gap(d, _i(event["target_slot"]) >= 4)
	var stop: Vector2 = line - way * gap * H
	var pull: Vector2 = -way * _f(windup["pull"])
	var rotation: Dictionary = _rotation()
	var aim_share: float = _f(rotation["aim"])
	# the point facing the target leads: the top edge when the target is above, else the bottom
	var lead: float = -1.0 if way.y > 0.0 else 1.0
	var aim: float = aim_share * rad_to_deg(Vector2(0.0, -lead).angle_to(way))
	# CB15 "tip_cap30": the full turn no more than the cap (90 % of it is left at contact)
	var cap: float = _f(rotation.get("cap", -1.0))
	if cap >= 0.0:
		aim = clampf(aim, -cap, cap)
	# full at C-12 when the hold is its least; it holds through a longer one
	var aim_ramp: int = maxi(1, lift_f + _i(windup["hold"]) + strike - AIM_FULL_BEFORE)
	# the lean tips the leading point toward the target; the aim takes its place, unless the
	# option keeps a lean beside it (CB17 "aim_lean": the same way as the turn)
	var lean: float = _f(rotation.get("lean", LEAN if aim_share <= 0.0 else 0.0)) * way.x * lead
	_add(
		_attacker,
		{
			"kind": "attack",
			"from": lift,
			"lift": lift_f,
			"scale": _f(windup["scale"]),
			"pull": pull,
			"lean": lean,
			"launch": launch,
			"strike": strike,
			"curve": _f(CURVES[pick("CB3")]),
			"contact": contact,
			"stop": stop,
			"release": release,
			"back": back,
			"aim": aim,
			"aim_ramp": aim_ramp,
			"keystone": _f(rotation["keystone"]),
			"length": _f(rotation["length"]),
			"lead": lead,
		}
	)
	# the return moves from C+1 (no frame held at contact) and is home at C + back
	var home_at: int = release + back if hit >= 0 else FOREVER
	glows.append({"key": _attacker, "from": lift, "to": home_at})
	var knocked: Array[String] = []
	if hit >= 0:
		knocked = _exchange(items[hit], release, way)
		if mode == "freeze":
			for item: Dictionary in before:
				_land_now(item, release + NUMBERS_AT)
	# after the hit: from C+14, and no earlier than the attacker is home (a far return ends later)
	var queue_from: int = release + AFTER_AT
	if hit >= 0:
		queue_from = maxi(queue_from, home_at)
	var queue: Array[Dictionary] = []
	if hit >= 0:
		for item: Dictionary in after:
			if str(item["kind"]) == "death":
				item["exchange_kill"] = true
				break
			if not item.get("after_hit", false):
				break
	queue.append_array(after)
	var kill_land: int = release if hit < 0 else release + NUMBERS_AT
	_commit = false
	_tempo_on = false
	var first_pass: int = _run_queue(queue, queue_from, release, kill_land)
	var combo_rule: Dictionary = COMBOS[pick("CB7")]
	_tempo_on = (
		combo_rule.get("speedup", false) == true
		and first_pass - queue_from > _i(_speedup()["over"])
	)
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
				"aim_deg": snappedf(aim, 0.01),
				"lean_deg": snappedf(lean, 0.01),
				"aim_full": lift + aim_ramp,
				"lead": "top" if lead > 0.0 else "bottom",
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


## CB9's numbers {aim, keystone, length}: a CB9 option named in the options (CB15, CB17), else
## the switch's set when it is on, else CB9's pick.
func _rotation() -> Dictionary:
	if options.has("CB9"):
		return ROTATIONS[pick("CB9")]
	if Rotate.on(options):
		return Rotate.SET
	return ROTATIONS[pick("CB9")]


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
	# "GROUP" (a what-if for fight_length.gd, plan B's "up to 3 different triggers at once"): up
	# to GROUP single beats in a row start together, at the first one's start
	var group_limit: int = _i(options.get("GROUP", 1))
	var group_at: int = -1
	var grouped: int = 0
	while j < queue.size():
		var item: Dictionary = queue[j]
		var tempo: float = _tempo(t - from)
		var kind: String = item["kind"]
		if kind != "beat":
			group_at = -1
		if kind == "stagger":
			var spread: Dictionary = _stagger(item, killed + roundi(EFFECT_KILL / tempo))
			t = maxi(t, _i(spread["next"]))
			queue_end = maxi(queue_end, _i(spread["end"]))
			j += 1
			continue
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
			group_at = -1
			j += run
		else:
			var begin: int = t
			if group_limit > 1 and kind == "beat" and group_at >= 0 and grouped < group_limit:
				begin = group_at
				grouped += 1
			elif kind == "beat":
				group_at = t
				grouped = 1
			done = _item(item, begin, tempo)
			j += 1
		t = maxi(t, _i(done["next"])) if group_limit > 1 else _i(done["next"])
		queue_end = maxi(queue_end, _i(done["end"]))
		if done.get("damage", false):
			killed = maxi(killed, _i(done["land"])) if group_limit > 1 else _i(done["land"])
	return queue_end


## Rule 7: past 120 f of queue, what starts after its first 60 f plays faster, up to x1.5.
func _tempo(into: int) -> float:
	if not _tempo_on:
		return 1.0
	var rule: Dictionary = _speedup()
	var share: float = clampf(float(into - _i(rule["from"])) / _f(rule["ramp"]), 0.0, 1.0)
	return 1.0 + (_f(rule["top"]) - 1.0) * share


## Rule 7's numbers: the options' "R7", else the proposal's.
func _speedup() -> Dictionary:
	return SPEEDUPS[str(options.get("R7", "best"))]


func _fall(item: Dictionary, at: int, length: int) -> void:
	if not _commit:
		return
	_reveal_all(item, at)
	_speeds[at] = float(FALL) / length
	spans.append({"kind": "death", "from": at, "to": at + length})
	for value: Variant in item["events"]:
		var event: Dictionary = _events[_i(value)]
		var uid: int = _i(event["uid"])
		_dead[uid] = true
		_falls.append({"key": _key(uid), "frame": at, "frames": length})


## CB8: a group of deaths at once, each falling at base + its stagger_at (reorder() set it), each
## for FALL frames (no speed-up, so every option's falls match); each death's own gain lands at
## its stagger_at, the source pulsing before it. Returns {next, end}.
func _stagger(item: Dictionary, base: int) -> Dictionary:
	var listed: Array = item["events"]
	var last: int = _i(listed.back()) + 1
	var fall_end: int = base
	var lands: Array[int] = []
	var falls: Array[Dictionary] = []
	var k: int = 0
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
			falls.append({"key": _key(_i(event["uid"])), "frame": at})
		elif _commit:
			_reveal[i] = at
		k += 1
	if _commit:
		_staggers.append(
			{"attack": attacks.size(), "base": base, "falls": falls, "lands": lands.duplicate()}
		)
	if lands.is_empty():
		return {"next": fall_end, "end": fall_end}
	var hold: int = _i(COMBOS[pick("CB7")]["end"])
	return {
		"next": maxi(fall_end, _i(lands.max()) + BEAT_GAP),
		"end": maxi(fall_end, _i(lands.max()) + hold),
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


## Rule 5 (CB7): one trigger many times, each gap shorter than the last.
func _combo(run: Array[Dictionary], start: int, from: int) -> Dictionary:
	var combo: Dictionary = COMBOS[pick("CB7")]
	var together: bool = combo["together"]
	var t: float = float(start)
	var lands: Array[int] = []
	var together_at: int = -1
	var damage: bool = false
	_totals = {}
	_total_on = combo.get("total", false) == true
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
	_total_on = false
	var last: int = lands.max()
	var end: int = last + _i(combo["end"])
	if _commit:
		spans.append({"kind": "trigger", "from": last, "to": end})
		_combos.append({"attack": attacks.size(), "start": start, "lands": lands.duplicate()})
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
			if _commit:
				spans.append({"kind": "trigger", "from": start, "to": at})
		return _arrive(item, at, tempo)
	var targets: Array = item["targets"]
	var to_self: bool = targets.is_empty() or (targets.size() == 1 and _i(targets[0]) == source)
	var land: int = start + roundi((SELF_LAND if to_self else BEAT_LAND) / tempo)
	if alive:
		_pulse(item, start, land)
	var damage: bool = false
	if _commit:
		spans.append({"kind": "trigger", "from": start, "to": land + roundi(BEAT_GAP / tempo)})
		if not item.get("quiet", false):
			_reveal_all(item, land)
		for value: Variant in item["events"]:
			var i: int = _i(value)
			if _kind(i) in ["damage", "destroy", "prevented"]:
				var hurt: Dictionary = _events[i]
				if not item.get("silent", false):
					_burst(hurt, land, _kind(i) == "prevented")
				damage = true
	return {"land": land, "next": land + roundi(BEAT_GAP / tempo), "end": land, "damage": damage}


## A unit arriving: it drops in from above its slot with today's fade, landing at f9.
func _arrive(item: Dictionary, at: int, tempo: float) -> Dictionary:
	var land: int = at + roundi(DROP_LAND / tempo)
	if _commit:
		spans.append({"kind": "summon", "from": at, "to": at + roundi(DROP / tempo)})
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


## An item's changes and bursts, all at `at` (CB4 "freeze": with the exchange's).
func _land_now(item: Dictionary, at: int) -> void:
	_reveal_all(item, at)
	for value: Variant in item["events"]:
		var i: int = _i(value)
		if _kind(i) in ["damage", "destroy", "prevented"]:
			var hurt: Dictionary = _events[i]
			_burst(hurt, at, _kind(i) == "prevented")


## CB4 "after": the log with what each attacker's own triggers did before its exchange moved to
## just after the exchange, so the exchange's numbers show first and stay true (a damage event's
## health is the Health left after it: the exchange's damage on the same card gets the moved
## damage back, and the moved damage loses the exchange's). An attack with no exchange (lethal
## Thorns) or a death before its exchange is left as it is. The first moved event is marked
## after_hit. Any other option: the log unchanged.
## CB8 b, c, d: also each group of deaths at once in display order (_staggered()).
static func reorder(events: Array, chosen: Dictionary) -> Array:
	var played: Array = events
	if str(chosen.get("CB4", PICKS["CB4"])) == "after":
		played = _after_hit(played)
	var rule: Dictionary = STAGGERS[str(chosen.get("CB8", PICKS["CB8"]))]
	var gaps: Array = rule["gaps"]
	if not gaps.is_empty():
		played = _staggered(played, rule)
	return played


## CB8: when each of n deaths at once starts its fall, in frames after the first.
static func stagger_starts(n: int, rule: Dictionary) -> Array[int]:
	var gaps: Array = rule["gaps"]
	var widths: Array[float] = []
	var total: float = 0.0
	for k: int in maxi(n - 1, 0):
		var gap: float = _f(gaps[k]) if k < gaps.size() else _f(rule["floor"])
		widths.append(gap)
		total += gap
	var cap: float = _f(rule["cap"])
	var shrink: float = 1.0
	if cap >= 0.0 and total > cap:
		shrink = cap / total
	var out: Array[int] = [0]
	var sum: float = 0.0
	for gap: float in widths:
		sum += gap * shrink
		out.append(roundi(sum))
	return out


## CB8: every run of two or more deaths at once, each death tagged with its fall's frame after the
## first (stagger_starts, in the rulebook 9.7.3 order: the active side's first, then the other
## side's, each in reading order). When the run is followed by one "after a friendly unit dies"
## beat per friendly death, of one mechanic, from a living source (Old Brock), the k-th beat is
## that side's k-th death in the log and lands STAGGER_LAND after that death's fall starts. The
## group is sorted by those frames; when that changes the order of the beats, their buffs' Attack
## and Health are recounted so each stays true and the last equals the log's. Otherwise (a death
## effect among them, say) what follows waits for the last fall.
static func _staggered(events: Array, rule: Dictionary) -> Array:
	var out: Array = []
	var active: int = -1
	var i: int = 0
	while i < events.size():
		var event: Dictionary = events[i]
		if _kind_of(event) == "attack":
			active = _i(event["side"])
		var run: int = i
		while run < events.size() and _kind_at(events, run) == "death":
			run += 1
		if run - i < 2:
			out.append(event)
			i += 1
			continue
		var deaths: Array[Dictionary] = []
		for k: int in range(i, run):
			deaths.append(_at(events, k))
		var beats: Array[Array] = _friendly_beats(events, run, deaths)
		var shown: Array[Dictionary] = deaths.duplicate()
		shown.sort_custom(
			func(x: Dictionary, y: Dictionary) -> bool:
				return _reading(x, active) < _reading(y, active)
		)
		var starts: Array[int] = stagger_starts(shown.size(), rule)
		var start_of: Dictionary = {}
		# [frame after the first fall, 0 death / 1 beat, index, events]
		var rows: Array[Array] = []
		for k: int in shown.size():
			var death: Dictionary = shown[k].duplicate()
			death["stagger_at"] = starts[k]
			start_of[_i(death["uid"])] = starts[k]
			rows.append([starts[k], 0, k, [death]])
		var friendly: Array[int] = []
		if not beats.is_empty():
			var trigger: Dictionary = beats[0][0]
			for death: Dictionary in deaths:
				if _i(death["side"]) == _i(trigger["side"]):
					friendly.append(_i(death["uid"]))
		for k: int in beats.size():
			var at: int = _i(start_of[friendly[k]]) + STAGGER_LAND
			var tagged: Array[Dictionary] = []
			for value: Variant in beats[k]:
				var part: Dictionary = value
				var copy: Dictionary = part.duplicate()
				copy["stagger_at"] = at
				tagged.append(copy)
			rows.append([at, 1, k, tagged])
		rows.sort_custom(_row_before)
		var moved: bool = false
		var next_beat: int = 0
		for row: Array in rows:
			if _i(row[1]) == 1:
				moved = moved or _i(row[2]) != next_beat
				next_beat += 1
		if moved:
			_recount(rows, beats, events, i)
		for row: Array in rows:
			var part: Array = row[3]
			out.append_array(part)
		i = run
		for beat: Array in beats:
			i += beat.size()
	return out


## Where a dying unit stands in rulebook 9.7.3's order: the active side first, then reading order.
static func _reading(death: Dictionary, active: int) -> int:
	var other: int = 0 if _i(death["side"]) == active else 1
	return other * 100 + _i(death["slot"])


static func _row_before(x: Array, y: Array) -> bool:
	for c: int in 3:
		if _i(x[c]) != _i(y[c]):
			return _i(x[c]) < _i(y[c])
	return false


## The beats right after a run of deaths that are one per friendly death (see _staggered), each
## [trigger, what it does...], or [] when they are not.
static func _friendly_beats(events: Array, from: int, deaths: Array[Dictionary]) -> Array[Array]:
	var none: Array[Array] = []
	if from >= events.size() or _kind_at(events, from) != "trigger":
		return none
	var first: Dictionary = events[from]
	var source: int = _i(first.get("uid", -1))
	var side: int = _i(first.get("side", -1))
	for death: Dictionary in deaths:
		if _i(death["uid"]) == source:
			return none
	var beats: Array[Array] = []
	var j: int = from
	while j < events.size():
		var trigger: Dictionary = events[j]
		if (
			_kind_of(trigger) != "trigger"
			or _i(trigger.get("uid", -1)) != source
			or str(trigger.get("mechanic", "")) != str(first.get("mechanic", ""))
		):
			break
		var beat: Array = [trigger]
		j += 1
		while (
			j < events.size()
			and not _kind_at(events, j) in ["trigger", "death", "attack", "combat_end"]
		):
			beat.append(events[j])
			j += 1
		beats.append(beat)
	var friendly: int = 0
	for death: Dictionary in deaths:
		if _i(death["side"]) == side:
			friendly += 1
	return beats if beats.size() == friendly else none


## The buffs of a group in its new order (rows, sorted), recounted: each is its unit's Attack and
## Health before the group plus every gain on that unit shown so far, so the numbers stay true and
## the last equals the log's. A gain is what its buff added in the log's own order (beats).
static func _recount(rows: Array[Array], beats: Array[Array], events: Array, upto: int) -> void:
	var stats: Dictionary = {}
	var start: Dictionary = events[0]
	var boards: Array = start.get("boards", [])
	for row: Variant in boards:
		var units: Array = row
		for value: Variant in units:
			if value is Dictionary:
				var unit: Dictionary = value
				stats[_i(unit["uid"])] = Vector2i(
					_i(unit.get("attack", 0)), _i(unit.get("health", 0))
				)
	for k: int in upto:
		var event: Dictionary = events[k]
		var uid: int = _i(event.get("uid", -1))
		if _kind_of(event) == "buff":
			stats[uid] = Vector2i(_i(event["attack"]), _i(event["health"]))
		elif _kind_of(event) == "damage" and stats.has(uid):
			var had: Vector2i = stats[uid]
			stats[uid] = Vector2i(had.x, _i(event["health"]))
	var was: Dictionary = stats.duplicate()
	var gains: Array[Vector2i] = []
	for beat: Array in beats:
		var gain: Vector2i = Vector2i.ZERO
		for value: Variant in beat:
			var event: Dictionary = value
			if _kind_of(event) == "buff":
				var uid: int = _i(event["uid"])
				var now: Vector2i = Vector2i(_i(event["attack"]), _i(event["health"]))
				var before: Vector2i = was.get(uid, Vector2i.ZERO)
				gain += now - before
				was[uid] = now
		gains.append(gain)
	for row: Array in rows:
		if _i(row[1]) != 1:
			continue
		var part: Array = row[3]
		for value: Variant in part:
			var event: Dictionary = value
			if _kind_of(event) != "buff":
				continue
			var uid: int = _i(event["uid"])
			var had: Vector2i = stats.get(uid, Vector2i.ZERO)
			var now: Vector2i = had + gains[_i(row[2])]
			stats[uid] = now
			event["attack"] = now.x
			event["health"] = now.y


static func _after_hit(events: Array) -> Array:
	var out: Array = []
	var i: int = 0
	while i < events.size():
		var event: Dictionary = events[i]
		out.append(event)
		i += 1
		if _kind_of(event) != "attack":
			continue
		var stop: int = i
		while stop < events.size() and not _kind_at(events, stop) in ["attack", "combat_end"]:
			stop += 1
		var hit: int = -1
		var plain: bool = true
		for j: int in range(i, stop):
			var each: Dictionary = events[j]
			if _kind_of(each) == "damage" and each.get("from_attack", false):
				hit = j
				break
			if _kind_of(each) == "death":
				plain = false
		if hit <= i or not plain:
			continue
		var ends: int = hit
		while ends < stop and _hit_part(_at(events, ends)):
			ends += 1
		var moved: Array = []
		for j: int in range(i, hit):
			var source: Dictionary = events[j]
			var copy: Dictionary = source.duplicate()
			if moved.is_empty():
				copy["after_hit"] = true
			moved.append(copy)
		for j: int in range(hit, ends):
			var original: Dictionary = events[j]
			var part: Dictionary = original.duplicate()
			for value: Variant in moved:
				var was: Dictionary = value
				if (
					_kind_of(was) == "damage"
					and _kind_of(part) == "damage"
					and _i(was.get("uid", -1)) == _i(part.get("uid", -2))
				):
					part["health"] = _i(part["health"]) + _i(was.get("amount", 0))
					was["health"] = _i(was["health"]) - _i(part.get("amount", 0))
			out.append(part)
		out.append_array(moved)
		i = ends
	return out


static func _at(events: Array, k: int) -> Dictionary:
	var event: Dictionary = events[k]
	return event


static func _kind_at(events: Array, k: int) -> String:
	return _kind_of(_at(events, k))


static func _hit_part(event: Dictionary) -> bool:
	if _kind_of(event) == "prevented":
		return true
	return _kind_of(event) == "damage" and event.get("from_attack", false)


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
		if event.has("stagger_at"):
			# CB8: a group of deaths with their own gains, played by _stagger()
			item["kind"] = "stagger"
			while j < to and _at(_events, j).has("stagger_at"):
				listed.append(j)
				j += 1
		elif kind == "damage" and event.get("from_attack", false):
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
		"after_hit": trigger.get("after_hit", false),
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
		# the card keeper's own tweens (a death's fall, numbers rolling) follow FAST too
		var speed: float = _f(_speeds.get(frame, 1.0)) * speed_at(frame)
		steps.append({"state": view, "hold": 0.0, "kind": kind, "frame": frame, "speed": speed})
	for k: int in steps.size():
		var step: Dictionary = steps[k]
		var next: int = _i(steps[k + 1]["frame"]) if k + 1 < steps.size() else result + END_HOLD
		step["hold"] = (next - _i(step["frame"])) / 60.0
	end_frame = result + END_HOLD


# ---- poses ----


## The attacker's motion, plus CB9's turn, keystone and length (_aim_pose), which outlast it: the
## card lands home still turned and straightens there.
func _attack_pose(seg: Dictionary, n: float) -> Dictionary:
	var part: Dictionary = _move_pose(seg, n)
	var aim: Dictionary = _aim_pose(seg, n)
	if aim.is_empty():
		return part
	var out: Dictionary = part.duplicate()
	out["turn"] = _f(part.get("turn", 0.0)) + _f(aim["turn"])
	out["length"] = aim["length"]
	if _f(aim["keystone"]) < 1.0:
		out["keystone"] = aim["keystone"]
		out["lead"] = seg["lead"]
	return out


## CB9: {turn, keystone, length} at frame n, or {} when flat and straight. The turn ramps from the
## lift's first frame (sine out: it starts at once and eases in), full at aim_ramp, eases back to
## AIM_AT_CONTACT over the strike, and unwinds from the return's start over AIM_STRAIGHT frames
## (smootherstep). The keystone ramps and fades with it (fading over TIP_FADE). The length
## shortens over the strike with the travel (the strike's own curve), and is back by LENGTH_BACK.
func _aim_pose(seg: Dictionary, n: float) -> Dictionary:
	var aim: float = _f(seg.get("aim", 0.0))
	var keystone: float = _f(seg.get("keystone", 1.0))
	var short: float = 1.0 - _f(seg.get("length", 1.0))
	var start: int = seg["from"]
	if n <= start or (is_zero_approx(aim) and keystone >= 1.0 and short <= 0.0):
		return {}
	var ramp: float = sin(PI / 2.0 * minf(1.0, float(n - start) / _i(seg["aim_ramp"])))
	var share: float = ramp
	var tip: float = ramp
	var length: float = 1.0
	var launch: int = seg["launch"]
	var contact: int = seg["contact"]
	var release: int = seg["release"]
	if launch >= 0 and n > launch:
		if n < contact:
			var u: float = float(n - launch) / _i(seg["strike"])
			share = ramp * lerpf(1.0, AIM_AT_CONTACT, u)
			length = 1.0 - short * pow(u, _f(seg["curve"]))
		elif n <= release:
			share = AIM_AT_CONTACT
			tip = 1.0
			length = 1.0 - short
		else:
			var j: float = n - release
			if j >= AIM_STRAIGHT and j >= TIP_FADE and j >= LENGTH_BACK:
				return {}
			share = AIM_AT_CONTACT * (1.0 - _smoother(minf(1.0, float(j) / AIM_STRAIGHT)))
			tip = 1.0 - _smooth(minf(1.0, float(j) / TIP_FADE))
			length = 1.0 - short * (1.0 - _quad_out(minf(1.0, float(j) / LENGTH_BACK)))
	return {
		"turn": aim * share,
		"keystone": 1.0 - (1.0 - keystone) * tip,
		"length": length,
	}


func _move_pose(seg: Dictionary, n: float) -> Dictionary:
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
	# the pop holds one drawn frame: one schedule frame, or the clock's step under FAST
	if n < contact + clock_step:
		return {"offset": stop, "scale": POP}
	return _return_pose(seg, n)


func _windup_pose(seg: Dictionary, k: float) -> Dictionary:
	var lift: int = seg["lift"]
	var e: float = 1.0 if lift <= 0 else _quad_out(minf(1.0, float(k) / lift))
	var pull: Vector2 = seg["pull"]
	return {
		"offset": pull * e,
		"scale": lerpf(1.0, _f(seg["scale"]), e),
		"turn": _f(seg["lean"]) * e,
	}


func _return_pose(seg: Dictionary, n: float) -> Dictionary:
	var release: int = seg["release"]
	var stop: Vector2 = seg["stop"]
	var lifted: float = seg["scale"]
	if n <= release:
		return {"offset": stop, "scale": lifted}
	var v: float = float(n - release) / _i(seg["back"])
	if v >= 1.0:
		return {}
	var e: float = 1.0 - pow(1.0 - v, 4.0)
	var shrink: float = clampf(float(n - release) / SCALE_HOME, 0.0, 1.0)
	return {"offset": stop.lerp(Vector2.ZERO, e), "scale": lerpf(lifted, 1.0, shrink)}


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
	var key: String = _key(_i(event["uid"]))
	var amount: int = _i(event.get("amount", 0)) if _kind_of(event) == "damage" else 0
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
				"side": _i(event["side"]),
				"slot": _i(event["slot"]),
				"amount": amount,
				"blocked": blocked,
				"taken": key == _attacker,
				"merge": merge,
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


static func _smooth(u: float) -> float:
	return u * u * (3.0 - 2.0 * u)


static func _smoother(u: float) -> float:
	return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
