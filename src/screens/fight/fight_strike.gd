class_name FightStrike
extends RefCounted
## Damage to the player after a fight (CB12 b, the owner's yes to the stand-in, 25 Nov: "the
## portrait strike stands in for the glass bolt"; docs/workstreams/fight-animation-24-nov/pilot/
## player-damage.md, section 4 B): the result shows the loser's old Health; 12 frames after it the
## winner's portrait lifts out of its window toward the board, holds, strikes the loser's portrait,
## and the loser's Health counts down from the impact, the "-N" popping on the loser's portrait. On
## a big loss (rulebook 10.1.2) the striker pulls back and strikes again, and the last 3 count.
## Ported from the fight fixture's pilot_hero_damage.gd (option B), which keeps every option.
##
## The striker turns toward the loser as every attack does (owner, 24 Nov: "Every animation, I
## want to have the rotation included"): FightMotion's TURN_AIM of the path's angle, with the
## TURN_LEAN in-plane lean the same way, no 3D tip, on the attacks' timing (full 12 frames before
## contact, TURN_AT_CONTACT at contact and held between two strikes, unwound over TURN_UNWIND
## from the return's start). Its own 8 degree lift lean stays on top.
##
## pose(f) is the whole picture f frames of game time after the result (R, its first frame), at
## fight speed 1: a pure function, so any frame rate and a skip show the same thing. FightScreen
## draws it. The portraits travelling is a stand-in the owner allowed (25 Nov), until the glass
## bolt's picture has his yes. Silent: the impact's own sound is the later sound step's (plan S).
## No one has watched this move.

## The result banner reads alone this long before anything moves.
const BANNER_READ: int = 12
## The lift: from R+12 over 11 frames, 30 px out of its window toward the board, x1.15, light
## 1.3, leaning 8 degrees toward the loser.
const LIFT_START: int = 12
const LIFT_FRAMES: int = 11
const LIFT_PX: float = 30.0
const LIFT_SCALE: float = 1.15
const LIFT_LIGHT: float = 1.3
const LIFT_TURN: float = 8.0
## The strike moves on R+37..R+46; contact (C) is the frame after its in-between frames.
const STRIKE_START: int = 37
const STRIKE_FRAMES: int = 10
const CONTACT: int = 47
## How much the rims overlap at contact, as a share of the loser's diameter.
const OVERLAP: float = 0.2
## stop.hit: the striker holds this many frames at contact.
const STOP_HIT: int = 4
## Home over 16 frames from C+4.
const RETURN_FRAMES: int = 16
## A big loss: pulled back 60 px over 6 frames, then a second strike of 5.
const PULL_FRAMES: int = 6
const PULL_PX: float = 60.0
const STRIKE2_FRAMES: int = 5
## The landing on the loser: its light from HIT_LIGHT back over 12 frames, a 14 px knock along the
## hit (in 3, back over 12), the stage shaking along it for 18 frames (12 px, 18 on a big loss's
## second landing; one swing every SHAKE_PERIOD frames, trauma squared).
const HIT_LIGHT: Color = Color(1.6, 1.25, 1.1)
const LIGHT_BACK: int = 12
const KNOCK_PX: float = 14.0
const KNOCK_IN: int = 3
const KNOCK_BACK: int = 12
const SHAKE_FRAMES: int = 18
const SHAKE_SMALL: float = 12.0
const SHAKE_BIG: float = 18.0
const SHAKE_PERIOD: float = 6.0
## The "-N" and the count start this many frames after contact.
const AFTER_CONTACT: int = 2
## The "-N": pops x0.55 to x1.18 in 3 frames, to x1 in 5, held to R+130, fading over 8.
const BURST_START: float = 0.55
const BURST_SCALE: float = 1.18
const BURST_IN: int = 3
const BURST_SETTLE: int = 5
const BURST_HELD_TO: int = 130
const BURST_FADE: int = 8
## The Health counts one step at a time over 18 frames, its badge swelling to x1.5 and back over
## 14; a big loss's last 3 count over 8 frames, the "-N" rolling to the whole loss with a x1.3 pop.
const COUNT_FRAMES: int = 18
const SWELL: float = 1.5
const SWELL_FRAMES: int = 14
const BIG_POP: float = 1.3
const BIG_POP_FRAMES: int = 8
const BIG_COUNT_FRAMES: int = 8

## Whether it was a big loss (the session's), the loser's Health before, the base loss and the
## whole loss (base + the big loss's extra).
var big: bool = false
var old_health: int = 0
var base: int = 0
var total: int = 0
## Whether the loser is you (the lower left portrait).
var loser_is_you: bool = true
## Portrait centres and radii (stage px), and the board's middle; the screen places them (place).
var winner_at: Vector2 = Vector2.ZERO
var loser_at: Vector2 = Vector2.ZERO
var winner_r: float = 64.0
var loser_r: float = 64.0
var board_at: Vector2 = Vector2(960.0, 540.0)
## The result's view as the loss leaves it: {health, opponent_health, players}, for the screen to
## show once the count has landed.
var landed: Dictionary = {}


## Where the portraits stand, from the screen's own nodes.
func place(winner: Vector2, loser: Vector2, w_r: float, l_r: float, board: Vector2) -> void:
	winner_at = winner
	loser_at = loser
	winner_r = w_r
	loser_r = l_r
	board_at = board


## The hit's direction: from the winner's portrait to the loser's.
func incoming() -> Vector2:
	return (loser_at - winner_at).normalized()


## The new Health, after the whole loss (never below 0).
func new_health() -> int:
	return maxi(0, old_health - total)


## Frames after R of each contact: [C] or, on a big loss, [C, C2].
func contacts() -> Array[int]:
	if not big:
		return [CONTACT]
	return [CONTACT, CONTACT + STOP_HIT + PULL_FRAMES + STRIKE2_FRAMES]


## The frame (after R) the striker is home.
func home_frame() -> int:
	return contacts().back() + STOP_HIT + RETURN_FRAMES - 1


## [first frame, frames, from, to] of each Health count. A big loss's first count ends the frame
## before the second contact when that comes first.
func counts() -> Array[Array]:
	var c: Array[int] = contacts()
	var first_frames: int = COUNT_FRAMES
	if c.size() > 1:
		first_frames = mini(COUNT_FRAMES, c[1] - c[0] - AFTER_CONTACT - 1)
	var out: Array[Array] = [
		[c[0] + AFTER_CONTACT, first_frames, old_health, maxi(0, old_health - base)]
	]
	if c.size() > 1:
		out.append(
			[c[1] + AFTER_CONTACT, BIG_COUNT_FRAMES, maxi(0, old_health - base), new_health()]
		)
	return out


## The frame (after R) the Health shows its last value.
func count_end() -> int:
	var last: Array = counts().back()
	return _i(last[0]) + _i(last[1])


## The frame (after R) from which nothing moves or shows any more: the "-N" gone, the striker home.
func end() -> int:
	return maxi(BURST_HELD_TO + BURST_FADE, home_frame() + 1)


## Everything drawn f frames after R: striker {offset, scale, turn, light}, loser {offset, light},
## stage (the shake's offset), health (shown), badge (its scale), burst {shown, scale, alpha,
## amount}.
func pose(f: float) -> Dictionary:
	var loser: Dictionary = {"offset": Vector2.ZERO, "light": Color.WHITE}
	var stage: Vector2 = Vector2.ZERO
	var c: Array[int] = contacts()
	for k: int in c.size():
		var age: float = f - c[k]
		if age < 0.0:
			continue
		var amplitude: float = SHAKE_BIG if k > 0 else SHAKE_SMALL
		stage = incoming() * shake(age, SHAKE_FRAMES, amplitude)
		loser["light"] = Color.WHITE
		if age <= LIGHT_BACK:
			loser["light"] = HIT_LIGHT.lerp(Color.WHITE, _exit(age / LIGHT_BACK))
		var knock: float = 0.0
		if age <= KNOCK_IN:
			knock = KNOCK_PX * _enter(age / KNOCK_IN)
		elif age <= KNOCK_IN + KNOCK_BACK:
			knock = KNOCK_PX * (1.0 - _back((age - KNOCK_IN) / KNOCK_BACK))
		loser["offset"] = incoming() * knock
	var health: int = old_health
	var badge: float = 1.0
	for count: Array in counts():
		var start: int = count[0]
		if f < start:
			continue
		health = FightTimeline.roll(_i(count[2]), _i(count[3]), f - start, _i(count[1]))
		badge = _swell(f - start)
	return {
		"striker": _striker(f),
		"loser": loser,
		"stage": stage,
		"health": health,
		"badge": badge,
		"burst": _burst(f),
	}


## The striker at frame f after R: out of its window on the lift, the strike, held at contact,
## (a big loss's pull and second strike), home.
func _striker(f: float) -> Dictionary:
	var lean: float = LIFT_TURN * (1.0 if incoming().x >= 0.0 else -1.0)
	var lifted: Vector2 = (board_at - winner_at).normalized() * LIFT_PX
	var at_contact: Vector2 = contact_offset()
	var c: Array[int] = contacts()
	var last: int = c.back()
	# how far into its lifted look (size, lean, light): up on the lift, down on the way home
	var look: float = 1.0
	var offset: Vector2 = lifted
	if f < LIFT_START + LIFT_FRAMES:
		look = _enter(_p(f, LIFT_START, LIFT_FRAMES))
		offset = lifted * look
	elif f >= STRIKE_START and f < c[0]:
		# the strike's in-between frames: contact is the frame after them
		var w: float = _strike((f - STRIKE_START + 1.0) / (STRIKE_FRAMES + 1))
		offset = lifted.lerp(at_contact, w)
	elif f >= c[0] and f < last:
		offset = _between_strikes(f - c[0], at_contact)
	elif f >= last:
		offset = at_contact
		var after: float = f - last
		if after >= STOP_HIT:
			var r: float = _back((after - STOP_HIT + 1.0) / RETURN_FRAMES)
			offset = at_contact.lerp(Vector2.ZERO, r)
			look = 1.0 - r
	return {
		"offset": offset,
		"scale": lerpf(1.0, LIFT_SCALE, look),
		"turn": lean * look + _aim(f),
		"light": lerpf(1.0, LIFT_LIGHT, look),
	}


## The turn toward the loser at frame f after R (degrees): FightMotion's turn and lean on the
## attacks' timing, its lift the lift, its strike the strike, its return the return.
func _aim(f: float) -> float:
	var way: Vector2 = incoming()
	var lead: float = -1.0 if way.y > 0.0 else 1.0
	var full: float = FightMotion.TURN_AIM * rad_to_deg(Vector2(0.0, -lead).angle_to(way))
	var leaning: float = FightMotion.TURN_LEAN * way.x * lead
	var c: Array[int] = contacts()
	var last: int = c.back()
	var n: float = f - LIFT_START + 1.0
	# the strike's in-between frames run from STRIKE_START; contact is the frame after them
	var launch: float = STRIKE_START - LIFT_START
	var strike: float = STRIKE_FRAMES + 1
	if f < c[0]:
		if n <= 0.0:
			return 0.0
		var ramp: float = maxf(LIFT_FRAMES, launch + strike - FightTimeline.AIM_FULL_BEFORE)
		var share: float = sin(PI / 2.0 * minf(1.0, n / ramp))
		var lean_share: float = _quad_out(minf(1.0, n / LIFT_FRAMES))
		if n > launch:
			var u: float = minf(1.0, (n - launch) / strike)
			share *= lerpf(1.0, FightMotion.TURN_AT_CONTACT, u)
			lean_share = maxf(0.0, 1.0 - u)
		return full * share + leaning * lean_share
	if f < last + STOP_HIT:
		return full * FightMotion.TURN_AT_CONTACT
	var j: float = f - last - STOP_HIT + 1.0
	var unwind: float = FightMotion.TURN_UNWIND * 60.0
	return full * FightMotion.TURN_AT_CONTACT * (1.0 - _smoother(clampf(j / unwind, 0.0, 1.0)))


## A big loss between its two contacts, `age` frames after the first: held, pulled back 60 px,
## then the second strike.
func _between_strikes(age: float, at_contact: Vector2) -> Vector2:
	var pulled: Vector2 = at_contact - incoming() * PULL_PX
	if age < STOP_HIT:
		return at_contact
	if age < STOP_HIT + PULL_FRAMES:
		return at_contact.lerp(pulled, _enter((age - STOP_HIT + 1.0) / PULL_FRAMES))
	var into: float = age - STOP_HIT - PULL_FRAMES
	return pulled.lerp(at_contact, _strike((into + 1.0) / (STRIKE2_FRAMES + 1)))


## Where the striker's centre stops, from its home centre: the rims overlapping OVERLAP of the
## loser's diameter, the striker at its lifted size.
func contact_offset() -> Vector2:
	var gap: float = winner_r * LIFT_SCALE + loser_r - OVERLAP * 2.0 * loser_r
	return loser_at - incoming() * gap - winner_at


## The "-N" on the loser's portrait: pops in at C+2, held to R+130, fades over 8 frames. On a big
## loss its number rolls from the base to the whole loss with the second count, popping again.
func _burst(f: float) -> Dictionary:
	var c: Array[int] = contacts()
	var start: int = c[0] + AFTER_CONTACT
	if f < start or f >= BURST_HELD_TO + BURST_FADE:
		return {"shown": false, "scale": 1.0, "alpha": 0.0, "amount": 0}
	var age: float = f - start
	var scale: float = 1.0
	if age < BURST_IN:
		scale = lerpf(BURST_START, BURST_SCALE, minf(1.0, (age + 1.0) / BURST_IN))
	elif age < BURST_IN + BURST_SETTLE:
		scale = lerpf(BURST_SCALE, 1.0, minf(1.0, (age - BURST_IN + 1.0) / BURST_SETTLE))
	var amount: int = base
	if c.size() > 1:
		var second: int = c[1] + AFTER_CONTACT
		if f >= second:
			amount = base + FightTimeline.roll(0, total - base, f - second, BIG_COUNT_FRAMES)
			var into: float = f - second
			if into < BIG_POP_FRAMES:
				scale = lerpf(BIG_POP, 1.0, _back(into / BIG_POP_FRAMES))
	var alpha: float = 1.0
	if f >= BURST_HELD_TO:
		alpha = clampf(1.0 - (f - BURST_HELD_TO + 1.0) / BURST_FADE, 0.0, 1.0)
	return {"shown": true, "scale": scale, "alpha": alpha, "amount": amount}


## The Health badge: x1.5 as its count starts, settling back over 14 frames.
static func _swell(age: float) -> float:
	if age < 0.0 or age >= SWELL_FRAMES:
		return 1.0
	return lerpf(SWELL, 1.0, _back(age / SWELL_FRAMES))


## shake.dir: the stage's offset along the hit, `age` frames after the impact, for a shake of
## `amplitude` px gone after `frames` frames (trauma squared).
static func shake(age: float, frames: float, amplitude: float) -> float:
	if age < 0.0 or age >= frames:
		return 0.0
	var trauma: float = 1.0 - age / frames
	return amplitude * trauma * trauma * cos(TAU * age / SHAKE_PERIOD)


## Progress through a beat of `frames` frames from `start`: 1/frames on its first frame, 1 on its
## last.
static func _p(f: float, start: int, frames: int) -> float:
	return clampf((f - start + 1.0) / frames, 0.0, 1.0)


## ease.enter: decelerate, cubic-bezier(0, 0, 0.2, 1).
static func _enter(p: float) -> float:
	return GlassMotion.bezier(Vector4(0.0, 0.0, 0.2, 1.0), p)


## ease.exit: accelerate, cubic-bezier(0.4, 0, 1, 1).
static func _exit(p: float) -> float:
	return GlassMotion.bezier(Vector4(0.4, 0.0, 1.0, 1.0), p)


## ease.strike: speeds up into contact (quad in).
static func _strike(p: float) -> float:
	var q: float = clampf(p, 0.0, 1.0)
	return q * q


## ease.return: fast first (cubic out).
static func _back(p: float) -> float:
	var q: float = 1.0 - clampf(p, 0.0, 1.0)
	return 1.0 - q * q * q


static func _quad_out(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)


static func _smoother(u: float) -> float:
	return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)
