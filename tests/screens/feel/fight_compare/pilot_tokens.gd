extends RefCounted
## The motion tokens the pilot's options use (GUIDELINES.md §2, rule S1), in one place, as plain
## curves of progress p in [0, 1]. The easing curves are the guidelines' tokens; four are new
## tokens the pilot asked for (pilot/player-damage.md, pilot/death.md): stop.hit, shake.dir,
## count.roll and fall.gravity. Numbers are the pilot's starting points, not decisions.
## Exploratory (the fight animation pilot, 24 Nov): nothing here reaches the game.

## stop.hit: how many frames a striker holds at contact before it moves on.
const STOP_HIT_FRAMES: int = 4
## shake.dir: one swing back and forth along the hit's direction takes this many frames.
const SHAKE_PERIOD: float = 6.0


## ease.enter: decelerate, cubic-bezier(0, 0, 0.2, 1).
static func enter(p: float) -> float:
	return GlassMotion.bezier(Vector4(0.0, 0.0, 0.2, 1.0), p)


## ease.exit: accelerate, cubic-bezier(0.4, 0, 1, 1).
static func exit(p: float) -> float:
	return GlassMotion.bezier(Vector4(0.4, 0.0, 1.0, 1.0), p)


## ease.strike: speeds up into contact; today's quad-in.
static func strike(p: float) -> float:
	var q: float = clampf(p, 0.0, 1.0)
	return q * q


## ease.return: fast first, cubic out.
static func back(p: float) -> float:
	var q: float = 1.0 - clampf(p, 0.0, 1.0)
	return 1.0 - q * q * q


## ease.fall: accelerate (quad in, today's death fall).
static func fall(p: float) -> float:
	var q: float = clampf(p, 0.0, 1.0)
	return q * q


## fall.gravity (new): the distance fallen from rest under a constant pull, as a share of the
## whole fall: p squared, the same curve as ease.fall, named for what it models.
static func gravity(p: float) -> float:
	var q: float = clampf(p, 0.0, 1.0)
	return q * q


## shake.dir (new): the stage's offset along the hit's direction, `age` frames after the impact,
## for a shake of `amplitude` px that is gone after `frames` frames (trauma squared, Eiserloh).
static func shake(age: float, frames: float, amplitude: float) -> float:
	if age < 0.0 or age >= frames:
		return 0.0
	var trauma: float = 1.0 - age / frames
	return amplitude * trauma * trauma * cos(TAU * age / SHAKE_PERIOD)


## count.roll (new): the number shown `age` frames into a count from `from` to `to`, one step at a
## time, the steps spread evenly over `frames` frames (the last step lands on the last frame).
static func roll(from: int, to: int, age: int, frames: int) -> int:
	if age < 0:
		return from
	var steps: int = absi(to - from)
	if steps == 0 or age >= frames:
		return to
	var done: int = 0
	for i: int in range(1, steps + 1):
		if age >= roundi(float(i) * frames / steps):
			done = i
	return from + done * signi(to - from)
