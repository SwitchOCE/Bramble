class_name FightMotion
extends CardKeeper
## Fight-only card motion. Replay holds and grouping stay in FightReplay. All new motion
## numbers live here, in stage pixels and seconds at playback speed 1.

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
const BURST_IN: float = 3.0 / 60.0
const BURST_SETTLE: float = 5.0 / 60.0
const BURST_SCALE: float = 1.18
const BURST_START: float = 0.55
const BURST_RISE: float = 16.0
const BURST_READ: float = 0.29
const BURST_FADE: float = 0.12

## key -> {attack, hit, blocked, returning, direction}; supplied by FightScreen each layout.
var motions: Dictionary = {}
## Exposed for the film fixture's two wind-up candidates; total attack time stays fixed.
var windup_time: float = WINDUP_TIME


func _init(on: Control) -> void:
	super(on)


func _place(entry: Dictionary, old: Dictionary, first: bool) -> Control:
	var motion: Dictionary = motions.get(entry["key"], {})
	var at: Vector2 = entry["at"]
	# Opening the leaderboard redraws the same state. Keep an in-flight beat on its original
	# clock when its card and destination have not changed.
	if animate and not old.is_empty() and old["look"] == entry["look"]:
		var held: Control = old["node"]
		if (
			not motion.get("attack", false)
			and not motion.get("hit", false)
			and held.get_meta("motion_destination", Vector2.INF) == at
			and is_busy(held)
		):
			return held
	var node: Control = super(entry, old, first)
	node.set_meta("motion_destination", at)
	var direction: Vector2 = motion.get("direction", Vector2.DOWN)
	node.set_meta("death_direction", motion.get("death_direction", direction))
	if old.is_empty() or not animate:
		return node
	if motion.get("attack", false):
		_attack(node, at, direction)
	elif motion.get("hit", false):
		_hit(node, at, motion)
	return node


func _attack(node: Control, at: Vector2, direction: Vector2) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var lean: float = WINDUP_TURN * (-1.0 if direction.y < 0.0 else 1.0)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		node, "position", node.position - direction * WINDUP_PX, windup_time / speed
	)
	tween.parallel().tween_property(node, "rotation_degrees", lean, windup_time / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE * LIFT_SCALE, windup_time / speed)
	tween.set_ease(Tween.EASE_IN)
	var travel: float = (ATTACK_TIME - windup_time) / speed
	tween.tween_property(node, "position", at, travel)
	tween.parallel().tween_property(node, "rotation_degrees", -lean / 2.0, travel)


func _hit(node: Control, at: Vector2, motion: Dictionary) -> void:
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
