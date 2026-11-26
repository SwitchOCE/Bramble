extends RefCounted
## CB12, damage to the player after a fight: options B (the winner's portrait strikes) and C (in
## place, no travel) of docs/workstreams/fight-animation-24-nov/pilot/player-damage.md, section 4,
## made from existing pieces only. Every number of the beat specs is here, by frame after R (the
## first frame the result is on screen), at fight speed 1. pose(f) is the whole picture at frame f:
## a pure function, so the screen, the tests and the log check read the same schedule.
##
## Readings of the spec it does not spell out (each a guess, said in the fixture's README):
## - A strike's frames are the in-between frames; contact (C) is the frame after them, so B's
##   strike moves on R+37..R+46 and is at contact on R+47, as the spec's C = R+47 says.
## - A big loss's first landing shakes 12 px and counts the base; the second shakes 18 px and
##   counts the last 3 over 8 f. When the second contact comes before the first count would end
##   (B: C+15, C: C+16, against C+20), the first count is squeezed to end the frame before it.
## - C's knock "into the loser's window": down for your portrait, up for the opponent's.
## - The landing's light goes back to full (1.0), not to C's 0.85 dim.
## Exploratory (the fight animation pilot, 24 Nov): nothing here reaches the game.

const Tokens := preload("res://tests/screens/feel/fight_compare/pilot_tokens.gd")
const Rotate := preload("res://tests/screens/feel/fight_compare/rotate.gd")

## The result banner reads alone this long before anything moves.
const BANNER_READ: int = 12
# ---- B: the winner's portrait strikes ----
const B_LIFT_START: int = 12
const B_LIFT_FRAMES: int = 11
const B_LIFT_PX: float = 30.0
const B_LIFT_SCALE: float = 1.15
const B_LIFT_LIGHT: float = 1.3
const B_LIFT_TURN: float = 8.0
const B_STRIKE_START: int = 37
const B_STRIKE_FRAMES: int = 10
const B_CONTACT: int = 47
## How much the rims overlap at contact, as a share of the loser's diameter.
const B_OVERLAP: float = 0.2
const B_RETURN_FRAMES: int = 16
const B_PULL_FRAMES: int = 6
const B_PULL_PX: float = 60.0
const B_STRIKE2_FRAMES: int = 5
# ---- C: in place ----
const C_CAUSE_START: int = 12
const C_CAUSE_FRAMES: int = 12
const C_PULSE_SCALE: float = 1.06
const C_PULSE_LIGHT: float = 1.3
const C_DIM: float = 0.85
const C_CONTACT: int = 32
const C_PULSE2_AFTER: int = 10
const C_PULSE2_FRAMES: int = 6
# ---- the shared landing (L) ----
const HIT_LIGHT: Color = Color(1.6, 1.25, 1.1)
const LIGHT_BACK: int = 12
const KNOCK_PX: float = 14.0
const KNOCK_IN: int = 3
const KNOCK_BACK: int = 12
const SHAKE_FRAMES: int = 18
const SHAKE_SMALL: float = 12.0
const SHAKE_BIG: float = 18.0
## The amount and the count start this many frames after contact.
const AFTER_CONTACT: int = 2
const BURST_START: float = 0.55
const BURST_SCALE: float = 1.18
const BURST_IN: int = 3
const BURST_SETTLE: int = 5
const BURST_HELD_TO: int = 130
const BURST_FADE: int = 8
const COUNT_FRAMES: int = 18
const SWELL: float = 1.5
const SWELL_FRAMES: int = 14
const BIG_POP: float = 1.3
const BIG_POP_FRAMES: int = 8
const BIG_COUNT_FRAMES: int = 8
## Everything has ended by R + this.
const BUDGET: int = 150

var option: String = "b"
var big: bool = false
## Health before, the base loss and the whole loss (base + 3 on a big loss).
var old_health: int = 0
var base: int = 0
var total: int = 0
## Portrait centres and radii (stage px), and the board's middle.
var winner_at: Vector2 = Vector2.ZERO
var loser_at: Vector2 = Vector2.ZERO
var winner_r: float = 64.0
var loser_r: float = 64.0
var board_at: Vector2 = Vector2(960.0, 540.0)
## Whether the loser is you (the lower left portrait).
var loser_is_you: bool = true
## The rotation switch's set (rotate.gd SET), or {} when it is off. On, B's striker also turns so
## the point of its disc facing the loser leads, and shortens along that line (pilot_screen.gd draws
## no keystone: the portrait has its own shader), on CB9's timing (_aim): its
## lift is the lift, its strike the strike, the return the return; held between two strikes.
var rotation_set: Dictionary = {}
## `recommended` with the game's turn (CB9 aim_lean, rotate.gd SET_LEAN): the set's in-plane lean
## too, the same way as the turn, as every attack has it (up with the lift, gone by contact). Off
## for `pilot`, whose striker turns without it.
var lean_in_plane: bool = false


func _init(chosen: String = "b") -> void:
	option = chosen


## The hit's direction: from the winner's portrait to the loser's (B), or into the loser's window
## (C: down for yours, up for theirs).
func incoming() -> Vector2:
	if option == "c":
		return Vector2.DOWN if loser_is_you else Vector2.UP
	return (loser_at - winner_at).normalized()


## Frames after R of each contact: [C] or, on a big loss, [C, C2].
func contacts() -> Array[int]:
	var first: int = B_CONTACT if option == "b" else C_CONTACT
	if not big:
		return [first]
	if option == "b":
		return [first, first + Tokens.STOP_HIT_FRAMES + B_PULL_FRAMES + B_STRIKE2_FRAMES]
	return [first, first + C_PULSE2_AFTER + C_PULSE2_FRAMES]


## The frame (after R) the striker is home, for B; -1 for C (nothing travels).
func home_frame() -> int:
	if option != "b":
		return -1
	return contacts().back() + Tokens.STOP_HIT_FRAMES + B_RETURN_FRAMES - 1


## [first frame, frames, from, to] of each Health count.
func counts() -> Array[Array]:
	var c: Array[int] = contacts()
	var first_frames: int = COUNT_FRAMES
	if c.size() > 1:
		first_frames = mini(COUNT_FRAMES, c[1] - c[0] - AFTER_CONTACT - 1)
	var first: Array = [c[0] + AFTER_CONTACT, first_frames, old_health, _floor(old_health - base)]
	var out: Array[Array] = [first]
	if c.size() > 1:
		(
			out
			. append(
				[
					c[1] + AFTER_CONTACT,
					BIG_COUNT_FRAMES,
					_floor(old_health - base),
					_floor(old_health - total),
				]
			)
		)
	return out


## The frame the Health shows its last value.
func count_end() -> int:
	var last: Array = counts().back()
	var start: int = last[0]
	var frames: int = last[1]
	return start + frames


## Markers by frame after R: {frame: [names]}.
func markers() -> Dictionary:
	var out: Dictionary = {0: ["result_shown"]}
	var c: Array[int] = contacts()
	_add(out, BANNER_READ, "hero_windup")
	if option == "b":
		_add(out, B_STRIKE_START, "hero_launch")
	_add(out, c[0], "hero_contact")
	_add(out, c[0] + AFTER_CONTACT, "hero_burst")
	_add(out, c[0] + AFTER_CONTACT, "health_count_start")
	if c.size() > 1:
		_add(out, c[1], "hero_contact_2")
	_add(out, count_end(), "health_count_end")
	if home_frame() >= 0:
		_add(out, home_frame(), "hero_home")
	return out


## Everything drawn at frame f after R: striker {offset, scale, turn, light}, loser {offset,
## light}, stage (offset), health (shown), badge (its scale), burst {shown, scale, alpha, amount}.
func pose(f: int) -> Dictionary:
	var striker: Dictionary = {"offset": Vector2.ZERO, "scale": 1.0, "turn": 0.0, "light": 1.0}
	var loser: Dictionary = {"offset": Vector2.ZERO, "light": Color.WHITE}
	if option == "b":
		striker = _striker_b(f)
	else:
		striker = _striker_c(f)
		var dim: float = 1.0
		if f >= C_CAUSE_START:
			dim = lerpf(1.0, C_DIM, Tokens.exit(_p(f, C_CAUSE_START, C_CAUSE_FRAMES)))
		loser["light"] = Color(dim, dim, dim)
	var stage: Vector2 = Vector2.ZERO
	var c: Array[int] = contacts()
	for k: int in c.size():
		var at: int = c[k]
		var age: int = f - at
		if age < 0:
			continue
		var amplitude: float = SHAKE_BIG if k > 0 else SHAKE_SMALL
		stage = incoming() * Tokens.shake(age, SHAKE_FRAMES, amplitude)
		if age <= LIGHT_BACK:
			var w: float = Tokens.exit(float(age) / LIGHT_BACK)
			loser["light"] = HIT_LIGHT.lerp(Color.WHITE, w)
		else:
			loser["light"] = Color.WHITE
		var knock: float = 0.0
		if age <= KNOCK_IN:
			knock = KNOCK_PX * Tokens.enter(float(age) / KNOCK_IN)
		elif age <= KNOCK_IN + KNOCK_BACK:
			knock = KNOCK_PX * (1.0 - Tokens.back(float(age - KNOCK_IN) / KNOCK_BACK))
		loser["offset"] = incoming() * knock
	var health: int = old_health
	var badge: float = 1.0
	for count: Array in counts():
		var start: int = count[0]
		if f < start:
			continue
		var frames: int = count[1]
		var from: int = count[2]
		var to: int = count[3]
		health = Tokens.roll(from, to, f - start, frames)
		badge = _swell(f - start)
	return {
		"striker": striker,
		"loser": loser,
		"stage": stage,
		"health": health,
		"badge": badge,
		"burst": _burst(f),
	}


func _striker_b(f: int) -> Dictionary:
	var lean: float = B_LIFT_TURN * (1.0 if incoming().x >= 0.0 else -1.0)
	var lifted: Vector2 = (board_at - winner_at).normalized() * B_LIFT_PX
	var at_contact: Vector2 = contact_offset()
	var c: Array[int] = contacts()
	var last: int = c.back()
	# how far into its lifted look (size, lean, light): up on the lift, down on the way home
	var look: float = 1.0
	var offset: Vector2 = lifted
	if f < B_LIFT_START + B_LIFT_FRAMES:
		look = Tokens.enter(_p(f, B_LIFT_START, B_LIFT_FRAMES))
		offset = lifted * look
	elif f >= B_STRIKE_START and f < c[0]:
		# the strike's in-between frames: contact is the frame after them
		var w: float = Tokens.strike(float(f - B_STRIKE_START + 1) / (B_STRIKE_FRAMES + 1))
		offset = lifted.lerp(at_contact, w)
	elif f >= c[0] and f < last:
		offset = _between_strikes(f - c[0], at_contact)
	elif f >= last:
		offset = at_contact
		var after: int = f - last
		if after >= Tokens.STOP_HIT_FRAMES:
			var r: float = Tokens.back(float(after - Tokens.STOP_HIT_FRAMES + 1) / B_RETURN_FRAMES)
			offset = at_contact.lerp(Vector2.ZERO, r)
			look = 1.0 - r
	var out: Dictionary = {
		"offset": offset,
		"scale": lerpf(1.0, B_LIFT_SCALE, look),
		"turn": lean * look,
		"light": lerpf(1.0, B_LIFT_LIGHT, look),
	}
	if not rotation_set.is_empty():
		var aim: Dictionary = Rotate.aim_of(incoming(), rotation_set)
		var aimed: Dictionary = _aim(f)
		var turn: float = out["turn"]
		out["turn"] = (
			turn + GlassPieces.as_float(aim["turn"]) * GlassPieces.as_float(aimed["share"])
		)
		out["length"] = aimed["length"]
		out["keystone"] = aimed["keystone"]
		out["lead"] = aim["lead"]
		if lean_in_plane and f < last:
			var n: float = f - B_LIFT_START + 1
			var launch: float = B_STRIKE_START - B_LIFT_START
			var share: float = Rotate.lean_share(n, B_LIFT_FRAMES, launch, B_STRIKE_FRAMES + 1)
			var leaned: float = GlassPieces.as_float(out["turn"])
			out["turn"] = leaned + Rotate.lean_of(incoming(), rotation_set) * share
	return out


## B's turn and lean at frame f after R (rotate.gd, on CB9's timing): from the lift's first frame,
## full at C-12, 90 % at contact, held through a big loss's second strike, unwound over 25 frames
## from the return's first moving frame.
func _aim(f: int) -> Dictionary:
	var n: float = f - B_LIFT_START + 1
	# the strike's in-between frames run from B_STRIKE_START; contact is the frame after them
	var launch: float = B_STRIKE_START - B_LIFT_START
	var strike: float = B_STRIKE_FRAMES + 1
	var c: Array[int] = contacts()
	var last: int = c.back()
	if f < c[0]:
		var ramp: float = Rotate.ramp_frames(B_LIFT_FRAMES, launch - B_LIFT_FRAMES, strike)
		return Rotate.approach(n, ramp, launch, strike, 2.0, rotation_set)
	if f < last + Tokens.STOP_HIT_FRAMES:
		return Rotate.contact_pose(rotation_set)
	return Rotate.leaving(f - last - Tokens.STOP_HIT_FRAMES + 1, rotation_set)


## B's big loss between its two contacts, `age` frames after the first: held, pulled back 60 px,
## then the second strike.
func _between_strikes(age: int, at_contact: Vector2) -> Vector2:
	var pulled: Vector2 = at_contact - incoming() * B_PULL_PX
	if age < Tokens.STOP_HIT_FRAMES:
		return at_contact
	if age < Tokens.STOP_HIT_FRAMES + B_PULL_FRAMES:
		var w: float = Tokens.enter(float(age - Tokens.STOP_HIT_FRAMES + 1) / B_PULL_FRAMES)
		return at_contact.lerp(pulled, w)
	var into: int = age - Tokens.STOP_HIT_FRAMES - B_PULL_FRAMES
	return pulled.lerp(at_contact, Tokens.strike(float(into + 1) / (B_STRIKE2_FRAMES + 1)))


## Where B's striker's centre stops, from its home centre: the rims overlapping B_OVERLAP of the
## loser's diameter, the striker at its lifted size.
func contact_offset() -> Vector2:
	var gap: float = winner_r * B_LIFT_SCALE + loser_r - B_OVERLAP * 2.0 * loser_r
	return loser_at - incoming() * gap - winner_at


func _striker_c(f: int) -> Dictionary:
	var out: Dictionary = {"offset": Vector2.ZERO, "scale": 1.0, "turn": 0.0, "light": 1.0}
	var pulses: Array[Array] = [[C_CAUSE_START, C_CAUSE_FRAMES]]
	var c: Array[int] = contacts()
	if c.size() > 1:
		pulses.append([c[0] + C_PULSE2_AFTER, C_PULSE2_FRAMES])
	for pulse: Array in pulses:
		var start: int = pulse[0]
		var frames: int = pulse[1]
		if f >= start and f < start + frames:
			var w: float = sin(PI * _p(f, start, frames))
			out["scale"] = lerpf(1.0, C_PULSE_SCALE, w)
			out["light"] = lerpf(1.0, C_PULSE_LIGHT, w)
	return out


## The "-N" on the loser's portrait: pops in at C+2, held to R+130, fades over 8 f. On a big loss
## its number rolls from the base to the whole loss with the second count, popping again.
func _burst(f: int) -> Dictionary:
	var c: Array[int] = contacts()
	var start: int = c[0] + AFTER_CONTACT
	if f < start or f >= BURST_HELD_TO + BURST_FADE:
		return {"shown": false, "scale": 1.0, "alpha": 0.0, "amount": 0}
	var age: int = f - start
	var scale: float = 1.0
	if age < BURST_IN:
		scale = lerpf(BURST_START, BURST_SCALE, float(age + 1) / BURST_IN)
	elif age < BURST_IN + BURST_SETTLE:
		scale = lerpf(BURST_SCALE, 1.0, float(age - BURST_IN + 1) / BURST_SETTLE)
	var amount: int = base
	if c.size() > 1:
		var second: int = c[1] + AFTER_CONTACT
		if f >= second:
			amount = base + (Tokens.roll(0, total - base, f - second, BIG_COUNT_FRAMES))
			var into: int = f - second
			if into < BIG_POP_FRAMES:
				scale = lerpf(BIG_POP, 1.0, Tokens.back(float(into) / BIG_POP_FRAMES))
	var alpha: float = 1.0
	if f >= BURST_HELD_TO:
		alpha = 1.0 - float(f - BURST_HELD_TO + 1) / BURST_FADE
	return {"shown": true, "scale": scale, "alpha": alpha, "amount": amount}


## The Health disc: swells to x1.5 as its count starts and settles back over 14 f.
static func _swell(age: int) -> float:
	if age < 0 or age >= SWELL_FRAMES:
		return 1.0
	return lerpf(SWELL, 1.0, Tokens.back(float(age) / SWELL_FRAMES))


## Progress through a beat of `frames` frames starting at `start`: 1/frames on its first frame,
## 1 on its last.
static func _p(f: int, start: int, frames: int) -> float:
	return clampf(float(f - start + 1) / frames, 0.0, 1.0)


static func _floor(value: int) -> int:
	return maxi(0, value)


static func _add(out: Dictionary, frame: int, marker: String) -> void:
	var listed: Array = out.get(frame, [])
	listed.append(marker)
	out[frame] = listed
