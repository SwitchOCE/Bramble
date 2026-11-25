class_name FightMotion
extends CardKeeper
## Fight-only card motion. Replay holds and grouping live in FightReplay; both may change
## (owner, 18 Nov: docs/design/owner-notes/2026-11-18b-fight-timing-and-grouping.md).
## All new motion numbers live here, in stage pixels and seconds at playback speed 1.
##
## Every attack turns its card toward its target, on top of the attack's own lift, cock, strike,
## hold and return (owner, 24 Nov: "Every animation, I want to have the rotation included, because
## that's an absolute mandatory one for me"; 25 Nov: the 4 degree in-plane lean with the turn, no
## 3D tip, until he picks another). The point facing the target leads (the top of yours, the
## bottom of theirs). The turn rises with the lift and is full as it ends, eases to TURN_AT_CONTACT
## over the strike, holds there while the attacker waits at contact, and unwinds over TURN_UNWIND
## from the return's start, so the card lands home still turned and straightens in its slot. The
## lean rises with the lift and is gone by contact. Every part is timed in seconds of game time
## (the tween's clock, scaled by speed), never in drawn frames.

const ATTACK_TIME: float = 12.0 / 60.0
const WINDUP_TIME: float = 4.0 / 60.0
const WINDUP_LONG: float = 6.0 / 60.0
const WINDUP_PX: float = 12.0
const WINDUP_TURN: float = 6.0
const LIFT_SCALE: float = 1.04
## Distance between centres on contact: enough overlap to read as a collision.
const CONTACT_PER_H: float = 0.62
const CONTACT_HOLD: float = 2.0 / 60.0
const RETURN_TIME: float = 11.0 / 60.0
const HIT_TIME: float = 3.0 / 60.0
const HIT_PX: float = 16.0
const HIT_TURN: float = 4.0
const BLOCK_SHARE: float = 0.3
const HIT_LIGHT: Color = Color(1.6, 1.25, 1.1)
const BLOCK_LIGHT: Color = Color(1.1, 1.35, 1.6)
const DEATH_TIME: float = 15.0 / 60.0
const DEATH_PX: float = 48.0
const DEATH_TURN: float = 16.0
const DEATH_SCALE: float = 0.72
const DEATH_FADE_DELAY: float = 4.0 / 60.0
## A unit piling on: a quick jab out towards the target, landing as its hit shows, then a settle;
## it holds out there until its attacker lunges (FightReplay). Taste call, 19 Nov.
const JAB_IN: float = 4.0 / 60.0
const JAB_HOLD: float = 3.0 / 60.0
const JAB_SETTLE: float = 10.0 / 60.0
const JAB_TURN: float = 5.0
const BURST_IN: float = 3.0 / 60.0
const BURST_SETTLE: float = 5.0 / 60.0
const BURST_SCALE: float = 1.18
const BURST_START: float = 0.55
const BURST_RISE: float = 16.0
const BURST_READ: float = 0.29
const BURST_FADE: float = 0.12

## The turn toward the target. The owner has not picked the amount (CB15) or the lean (CB17) for
## good (docs/workstreams/fight-animation-24-nov/PLAN-implement.md): a later pick changes these.
## Share of the path's angle the card turns by.
const TURN_AIM: float = 0.95
## Share of the turn left at contact, and held while the attacker waits there.
const TURN_AT_CONTACT: float = 0.9
## The in-plane lean the same way as the turn: degrees, times the path's sideways share.
const TURN_LEAN: float = 4.0
## The turn is gone this long after the return starts.
const TURN_UNWIND: float = 25.0 / 60.0
## A jab (pile-on, effect) turns at most this far, in degrees: a jab along its own row would
## otherwise lie almost sideways for a 20 px nudge. Attacks are not capped (CB15 is open).
const JAB_TURN_CAP: float = 30.0

## key -> {attack, hit, blocked, returning, direction}; supplied by FightScreen each layout.
var motions: Dictionary = {}
## CB13 c: the keys of units that die on their own (FightTimeline.single_deaths), whose death the
## fight screen draws from its schedule (FightTimeline.death_pose) instead of this fall. Each one
## leaving stays where it stood, in `dying` (key -> {node, base}), until the screen lets it go.
var drawn_deaths: Dictionary = {}
var dying: Dictionary = {}
## Exposed for the film fixture's two wind-up candidates; total attack time stays fixed.
var windup_time: float = WINDUP_TIME

## key -> an attacker's turn while it lasts: {aim (the full turn, degrees, clockwise +), lean
## (degrees), phase ("in", "held" at contact, "back"), own (the attack's own cock, degrees), size
## (its lift scale), share (of aim, now), leaning (degrees, now), back (seconds into the return)}.
var _turns: Dictionary = {}
## The key of the card being placed (_attack and _hit are given only its node).
var _placing: String = ""


func _init(on: Control) -> void:
	super(on)


func _place(entry: Dictionary, old: Dictionary, first: bool) -> Control:
	var key: String = entry["key"]
	var motion: Dictionary = motions.get(key, {})
	var at: Vector2 = entry["at"]
	var plain: bool = (
		not motion.get("attack", false)
		and not motion.get("hit", false)
		and not motion.get("jab", false)
	)
	var turning: Dictionary = _turns.get(key, {})
	_placing = key
	# Opening the leaderboard redraws the same state. Keep an in-flight beat on its original
	# clock when its card and destination have not changed.
	if animate and not old.is_empty() and old["look"] == entry["look"]:
		var held: Control = old["node"]
		if plain and held.get_meta("motion_destination", Vector2.INF) == at and is_busy(held):
			if not turning.is_empty() and str(turning["phase"]) == "held":
				_hold_turn(held, at, turning)
			return held
	var was: Control = null if old.is_empty() else old["node"]
	var node: Control = super(entry, old, first)
	node.set_meta("motion_destination", at)
	node.set_meta("keeper_key", key)
	var direction: Vector2 = motion.get("direction", Vector2.DOWN)
	node.set_meta("death_direction", motion.get("death_direction", direction))
	if old.is_empty() or not animate:
		return node
	if motion.get("attack", false):
		_attack(node, at, direction)
	elif motion.get("hit", false):
		_hit(node, at, motion)
	elif motion.get("jab", false):
		var home: Vector2 = motion.get("home", node.position)
		_jab(node, home, at)
	elif not turning.is_empty():
		var attacking: bool = motion.get("returning", false)
		_keep_turning(key, node, was, at, turning, attacking)
	return node


## A turned card placed with no motion of its own: it waits at contact (a trigger before the hit)
## holding its turn, or is rebuilt on the way home (its numbers changed) and goes on unwinding.
## Anywhere else (a skip, a slot it moves to) its move straightens it, as before the turn.
func _keep_turning(
	key: String, node: Control, was: Control, at: Vector2, turning: Dictionary, attacking: bool
) -> void:
	var phase: String = turning["phase"]
	if phase == "back":
		if node != was:
			_turn_home(node, at, turning, false)
		else:
			_turns.erase(key)
		return
	if not attacking:
		_turns.erase(key)
		return
	if phase == "in" and node == was and is_busy(node):
		return
	_hold_turn(node, at, turning)


func _jab(node: Control, home: Vector2, at: Vector2) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	node.position = home
	var by: Vector2 = at - home
	var lean: float = JAB_TURN * signf(by.x) if absf(by.x) > 1.0 else 0.0
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, JAB_IN / speed)
	tween.parallel().tween_property(node, "rotation_degrees", lean, JAB_IN / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE * LIFT_SCALE, JAB_IN / speed)
	tween.tween_interval(JAB_HOLD / speed)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "rotation_degrees", 0.0, JAB_SETTLE / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, JAB_SETTLE / speed)


## The lift (quad out: back from the target, cocked, lifted) and the strike (quad in, to contact,
## the cock swinging past straight), with the turn and the lean on top. t: seconds at speed 1.
func _attack(node: Control, at: Vector2, direction: Vector2) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var cock: float = WINDUP_TURN * (-1.0 if direction.y < 0.0 else 1.0)
	var home: Vector2 = node.position
	var pulled: Vector2 = home - direction * WINDUP_PX
	var lift: float = windup_time
	var strike: float = ATTACK_TIME - windup_time
	var turning: Dictionary = _turn_toward(direction)
	_turns[_placing] = turning
	var pose: Callable = func(t: float) -> void:
		if t <= lift:
			var e: float = 1.0 - pow(1.0 - t / lift, 2.0)
			node.position = home.lerp(pulled, e)
			turning["own"] = cock * e
			turning["size"] = lerpf(1.0, LIFT_SCALE, e)
			turning["share"] = sin(PI / 2.0 * t / lift)
			turning["leaning"] = _num(turning["lean"]) * e
		else:
			var u: float = (t - lift) / strike
			var e: float = u * u
			node.position = pulled.lerp(at, e)
			turning["own"] = lerpf(cock, -cock / 2.0, e)
			turning["size"] = LIFT_SCALE
			turning["share"] = lerpf(1.0, TURN_AT_CONTACT, u)
			turning["leaning"] = _num(turning["lean"]) * (1.0 - u)
		_draw_turned(node, turning)
	tween.tween_method(pose, 0.0, ATTACK_TIME, ATTACK_TIME / speed)
	tween.tween_callback(func() -> void: turning["phase"] = "held")


## The turn for an attack along `direction` (a unit vector): the point facing the target leads.
static func _turn_toward(direction: Vector2) -> Dictionary:
	var lead: float = -1.0 if direction.y > 0.0 else 1.0
	var full: float = rad_to_deg(Vector2(0.0, -lead).angle_to(direction))
	return {
		"aim": TURN_AIM * full,
		"lean": TURN_LEAN * direction.x * lead,
		"phase": "in",
		"own": 0.0,
		"size": 1.0,
		"share": 0.0,
		"leaning": 0.0,
		"back": 0.0,
	}


## Waiting at contact: the attack's own cock and lift settle (as a plain move does, MOVE_TIME,
## cubic out); the turn holds at contact and the lean is gone.
func _hold_turn(node: Control, at: Vector2, turning: Dictionary) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var from_at: Vector2 = node.position
	var from_own: float = turning["own"]
	var from_size: float = turning["size"]
	turning["phase"] = "held"
	turning["share"] = TURN_AT_CONTACT
	turning["leaning"] = 0.0
	var pose: Callable = func(u: float) -> void:
		var e: float = 1.0 - pow(1.0 - u, 3.0)
		node.position = from_at.lerp(at, e)
		turning["own"] = lerpf(from_own, 0.0, e)
		turning["size"] = lerpf(from_size, 1.0, e)
		_draw_turned(node, turning)
	tween.tween_method(pose, 0.0, 1.0, MOVE_TIME / speed)


## The return, as a hit sends the attacker home (CONTACT_HOLD at contact, then RETURN_TIME,
## cubic out), with the turn unwinding over TURN_UNWIND from the return's start (smootherstep).
## fresh: from contact; else a rebuilt card's return, going on from where it had got to.
func _turn_home(node: Control, at: Vector2, turning: Dictionary, fresh: bool) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var key: String = _placing
	var from_at: Vector2 = node.position
	var from_own: float = turning["own"]
	var from_size: float = turning["size"]
	var from_light: Color = node.modulate
	var start: float = 0.0 if fresh else _num(turning["back"])
	var total: float = maxf(RETURN_TIME, TURN_UNWIND)
	turning["phase"] = "back"
	turning["leaning"] = 0.0
	if fresh:
		turning["share"] = TURN_AT_CONTACT
		_draw_turned(node, turning)
		tween.tween_interval(CONTACT_HOLD / speed)
	var pose: Callable = func(j: float) -> void:
		turning["back"] = j
		if j < RETURN_TIME:
			var e: float = 1.0 - pow(1.0 - (j - start) / (RETURN_TIME - start), 3.0)
			node.position = from_at.lerp(at, e)
			node.modulate = from_light.lerp(Color.WHITE, e)
			turning["own"] = lerpf(from_own, 0.0, e)
			turning["size"] = lerpf(from_size, 1.0, e)
		else:
			node.position = at
			node.modulate = Color.WHITE
			turning["own"] = 0.0
			turning["size"] = 1.0
		var v: float = clampf(j / TURN_UNWIND, 0.0, 1.0)
		turning["share"] = TURN_AT_CONTACT * (1.0 - v * v * v * (v * (v * 6.0 - 15.0) + 10.0))
		_draw_turned(node, turning)
	tween.tween_method(pose, start, total, (total - start) / speed)
	tween.tween_callback(
		func() -> void:
			if is_same(_turns.get(key), turning):
				_turns.erase(key)
	)


## The attack's own pose with the turn and the lean added.
static func _draw_turned(node: Control, turning: Dictionary) -> void:
	node.rotation_degrees = (
		_num(turning["own"])
		+ _num(turning["aim"]) * _num(turning["share"])
		+ _num(turning["leaning"])
	)
	node.scale = Vector2.ONE * _num(turning["size"])


static func _num(value: Variant) -> float:
	return GlassPieces.as_float(value)


## A new fight starts from a clean table: no turn left over from the last.
func clear() -> void:
	super()
	_turns.clear()
	dying.clear()


## Every card at once where it is going; a death the screen draws goes too.
func settle() -> void:
	super()
	dying.clear()


## A death the screen draws is done: the card goes.
func let_go(key: String) -> void:
	var held: Dictionary = dying.get(key, {})
	dying.erase(key)
	var node: Variant = held.get("node")
	if node is Control and is_instance_valid(node):
		var card: Control = node
		_gone(card)


func _hit(node: Control, at: Vector2, motion: Dictionary) -> void:
	var turning: Dictionary = _turns.get(_placing, {})
	if not turning.is_empty():
		if motion.get("returning", false):
			if motion.get("received", false):
				node.modulate = BLOCK_LIGHT if motion.get("blocked", false) else HIT_LIGHT
			_turn_home(node, at, turning, true)
			return
		# hit while still turned from its own attack: the hit takes over, flat
		_turns.erase(_placing)
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var direction: Vector2 = motion["direction"]
	var blocked: bool = motion.get("blocked", false)
	var share: float = BLOCK_SHARE if blocked else 1.0
	if motion.get("received", false):
		node.modulate = BLOCK_LIGHT if blocked else HIT_LIGHT
	if motion.get("returning", false):
		# Keep the collision for two frames, then let the eye follow the survivor home.
		tween.tween_interval(CONTACT_HOLD / speed)
	else:
		tween.tween_property(node, "position", at + direction * HIT_PX * share, HIT_TIME / speed)
		tween.parallel().tween_property(
			node, "rotation_degrees", HIT_TURN * signf(direction.y) * share, HIT_TIME / speed
		)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, RETURN_TIME / speed)
	tween.parallel().tween_property(node, "rotation_degrees", 0.0, RETURN_TIME / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, RETURN_TIME / speed)
	tween.parallel().tween_property(node, "modulate", Color.WHITE, RETURN_TIME / speed)


func _fade_out(node: Control) -> void:
	if not animate or not node.is_inside_tree():
		super(node)
		return
	stop(node)
	_fading.append(node)
	set_pivot(node, node.size / 2.0)
	var key: String = str(node.get_meta("keeper_key", ""))
	if drawn_deaths.has(key):
		# CB13 c: the screen draws it from the schedule, where it stood
		dying[key] = {"node": node, "base": node.position}
		return
	var direction: Vector2 = node.get_meta("death_direction", Vector2.DOWN)
	var tween: Tween = _run(node)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "position", node.position + direction * DEATH_PX, DEATH_TIME / speed)
	tween.parallel().tween_property(
		node, "rotation_degrees", DEATH_TURN * signf(direction.y), DEATH_TIME / speed
	)
	tween.parallel().tween_property(node, "scale", Vector2.ONE * DEATH_SCALE, DEATH_TIME / speed)
	(
		tween
		. parallel()
		. tween_property(node, "modulate:a", 0.0, (DEATH_TIME - DEATH_FADE_DELAY) / speed)
		. set_delay(DEATH_FADE_DELAY / speed)
	)
	tween.tween_callback(func() -> void: _gone(node))


## Damage stays upright beside its recipient as it recoils. Later effects start at that
## recipient's current pose, rather than at an attack's old collision point.
func burst(hit: Control, recipient: Control = null) -> Tween:
	if not animate:
		return null
	hit.pivot_offset = hit.size / 2.0
	hit.scale = Vector2.ONE * BURST_START
	var origin: Vector2 = hit.position
	var offset: Vector2 = origin - recipient.position if recipient != null else Vector2.ZERO
	var duration: float = BURST_IN + BURST_SETTLE + BURST_READ + BURST_FADE
	var tween: Tween = hit.create_tween()
	# Created after the cards' tweens: follow their pose in the same frame, without inheriting
	# their rotation/scale. One clock covers pop, read and fade, including the following motion.
	var draw_burst: Callable = func(age: float) -> void:
		var swell: float = 1.0
		if age < BURST_IN:
			swell = lerpf(BURST_START, BURST_SCALE, age / BURST_IN)
		elif age < BURST_IN + BURST_SETTLE:
			swell = lerpf(BURST_SCALE, 1.0, (age - BURST_IN) / BURST_SETTLE)
		var fade: float = clampf((age - duration + BURST_FADE) / BURST_FADE, 0.0, 1.0)
		var at: Vector2 = origin
		if is_instance_valid(recipient):
			at = recipient.position + offset
		hit.position = at + Vector2.UP * BURST_RISE * fade
		hit.scale = Vector2.ONE * swell
		hit.modulate.a = 1.0 - fade
	tween.tween_method(draw_burst, 0.0, duration, duration / speed)
	return tween
