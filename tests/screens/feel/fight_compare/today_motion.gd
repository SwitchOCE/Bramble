extends FightMotion
## Today's card motion, kept: the game's FightMotion as it was before the turn came into `src/`
## (src/screens/fight/fight_motion.gd at 00ceea90, 25 Nov), so `today`, `pilot` and the rotation
## switch film exactly what they filmed then (plan step 0,
## docs/workstreams/fight-animation-24-nov/PLAN-implement.md). It overrides every method
## FightMotion has, and CardKeeper._place's body is copied in as _keeper_place (it cannot call past
## FightMotion's _place), so later changes to FightMotion don't reach it. Its numbers are
## FightMotion's at that commit under their own names: a subclass can't reuse a constant's name.
## It is a FightMotion only so the fight screen takes it (motions, burst). Nothing here is the game.

const TODAY_ATTACK_TIME: float = 12.0 / 60.0
const TODAY_WINDUP_TIME: float = 4.0 / 60.0
const TODAY_WINDUP_LONG: float = 6.0 / 60.0
const TODAY_WINDUP_PX: float = 12.0
const TODAY_WINDUP_TURN: float = 6.0
const TODAY_LIFT_SCALE: float = 1.04
const TODAY_CONTACT_HOLD: float = 2.0 / 60.0
const TODAY_RETURN_TIME: float = 11.0 / 60.0
const TODAY_HIT_TIME: float = 3.0 / 60.0
const TODAY_HIT_PX: float = 16.0
const TODAY_HIT_TURN: float = 4.0
const TODAY_BLOCK_SHARE: float = 0.3
const TODAY_HIT_LIGHT: Color = Color(1.6, 1.25, 1.1)
const TODAY_BLOCK_LIGHT: Color = Color(1.1, 1.35, 1.6)
const TODAY_DEATH_TIME: float = 15.0 / 60.0
const TODAY_DEATH_PX: float = 48.0
const TODAY_DEATH_TURN: float = 16.0
const TODAY_DEATH_SCALE: float = 0.72
const TODAY_DEATH_FADE_DELAY: float = 4.0 / 60.0
const TODAY_JAB_IN: float = 4.0 / 60.0
const TODAY_JAB_HOLD: float = 3.0 / 60.0
const TODAY_JAB_SETTLE: float = 10.0 / 60.0
const TODAY_JAB_TURN: float = 5.0
const TODAY_BURST_IN: float = 3.0 / 60.0
const TODAY_BURST_SETTLE: float = 5.0 / 60.0
const TODAY_BURST_SCALE: float = 1.18
const TODAY_BURST_START: float = 0.55
const TODAY_BURST_RISE: float = 16.0
const TODAY_BURST_READ: float = 0.29
const TODAY_BURST_FADE: float = 0.12


func _init(on: Control) -> void:
	super(on)
	windup_time = TODAY_WINDUP_TIME


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
			and not motion.get("jab", false)
			and held.get_meta("motion_destination", Vector2.INF) == at
			and is_busy(held)
		):
			return held
	var node: Control = _keeper_place(entry, old, first)
	node.set_meta("motion_destination", at)
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
	return node


## CardKeeper._place at 00ceea90, as FightMotion's _place called it (super).
func _keeper_place(entry: Dictionary, old: Dictionary, first: bool) -> Control:
	var at: Vector2 = entry["at"]
	var turn: float = entry["turn"]
	var node: Control
	# the numbers a let-go card shows now, to count up from as it lands
	var shown: Vector2i = Vector2i(-1, -1)
	if not old.is_empty() and old["look"] == entry["look"]:
		node = old["node"]
		shown = _numbers_of(node)
	else:
		var make: Callable = entry["make"]
		node = make.call()
		layer.add_child(node)
		if old.is_empty():
			node.position = at
			node.rotation_degrees = turn
			if not first and animate:
				node.modulate.a = 0.0
				_run(node).tween_property(node, "modulate:a", 1.0, FADE_TIME / speed)
			return node
		var was: Control = old["node"]
		node.pivot_offset = was.pivot_offset
		node.position = was.position
		node.rotation_degrees = was.rotation_degrees
		node.scale = was.scale
		if _landing.has(was):
			_landing.erase(was)
			_landing[node] = true
			if _let_go.has(was):
				_let_go[node] = _let_go[was]
				_let_go.erase(was)
			node.z_index = was.z_index
			shown = _numbers_of(was)
			if was is GlassCard and node is GlassCard and (was as GlassCard).is_held():
				(node as GlassCard).set_held(true)
		elif not quiet_numbers.has(entry["key"]):
			var before: Vector2i = old["numbers"]
			var after: Vector2i = entry["numbers"]
			_pop(node, before, after)
		stop(was)
		layer.remove_child(was)
		was.queue_free()
	stop(node)
	node.modulate.a = 1.0
	var numbers: Vector2i = entry["numbers"]
	if not animate:
		node.position = at
		node.rotation_degrees = turn
		node.scale = Vector2.ONE
		if _landing.has(node):
			_set_numbers(node, numbers)
		_landed(node)
		return node
	if _landing.has(node):
		_land(node, at, turn, shown, numbers)
		return node
	var still: bool = node.position.is_equal_approx(at) and node.scale.is_equal_approx(Vector2.ONE)
	if still and is_equal_approx(node.rotation_degrees, turn):
		return node
	var time: float = entry["time"]
	var tween: Tween = _run(node)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, (MOVE_TIME if time < 0.0 else time) / speed)
	tween.parallel().tween_property(node, "rotation_degrees", turn, MOVE_TIME / speed)
	if not node.scale.is_equal_approx(Vector2.ONE):
		tween.parallel().tween_property(node, "scale", Vector2.ONE, MOVE_TIME / speed)
	return node


func _jab(node: Control, home: Vector2, at: Vector2) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	node.position = home
	var by: Vector2 = at - home
	var lean: float = TODAY_JAB_TURN * signf(by.x) if absf(by.x) > 1.0 else 0.0
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, TODAY_JAB_IN / speed)
	tween.parallel().tween_property(node, "rotation_degrees", lean, TODAY_JAB_IN / speed)
	tween.parallel().tween_property(
		node, "scale", Vector2.ONE * TODAY_LIFT_SCALE, TODAY_JAB_IN / speed
	)
	tween.tween_interval(TODAY_JAB_HOLD / speed)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "rotation_degrees", 0.0, TODAY_JAB_SETTLE / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, TODAY_JAB_SETTLE / speed)


func _attack(node: Control, at: Vector2, direction: Vector2) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var lean: float = TODAY_WINDUP_TURN * (-1.0 if direction.y < 0.0 else 1.0)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		node, "position", node.position - direction * TODAY_WINDUP_PX, windup_time / speed
	)
	tween.parallel().tween_property(node, "rotation_degrees", lean, windup_time / speed)
	tween.parallel().tween_property(
		node, "scale", Vector2.ONE * TODAY_LIFT_SCALE, windup_time / speed
	)
	tween.set_ease(Tween.EASE_IN)
	var travel: float = (TODAY_ATTACK_TIME - windup_time) / speed
	tween.tween_property(node, "position", at, travel)
	tween.parallel().tween_property(node, "rotation_degrees", -lean / 2.0, travel)


func _hit(node: Control, at: Vector2, motion: Dictionary) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var direction: Vector2 = motion["direction"]
	var blocked: bool = motion.get("blocked", false)
	var share: float = TODAY_BLOCK_SHARE if blocked else 1.0
	if motion.get("received", false):
		node.modulate = TODAY_BLOCK_LIGHT if blocked else TODAY_HIT_LIGHT
	if motion.get("returning", false):
		# Keep the collision for two frames, then let the eye follow the survivor home.
		tween.tween_interval(TODAY_CONTACT_HOLD / speed)
	else:
		tween.tween_property(
			node, "position", at + direction * TODAY_HIT_PX * share, TODAY_HIT_TIME / speed
		)
		tween.parallel().tween_property(
			node,
			"rotation_degrees",
			TODAY_HIT_TURN * signf(direction.y) * share,
			TODAY_HIT_TIME / speed
		)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", at, TODAY_RETURN_TIME / speed)
	tween.parallel().tween_property(node, "rotation_degrees", 0.0, TODAY_RETURN_TIME / speed)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, TODAY_RETURN_TIME / speed)
	tween.parallel().tween_property(node, "modulate", Color.WHITE, TODAY_RETURN_TIME / speed)


func _fade_out(node: Control) -> void:
	if not animate or not node.is_inside_tree():
		_keeper_fade_out(node)
		return
	stop(node)
	_fading.append(node)
	set_pivot(node, node.size / 2.0)
	var direction: Vector2 = node.get_meta("death_direction", Vector2.DOWN)
	var tween: Tween = _run(node)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(
		node, "position", node.position + direction * TODAY_DEATH_PX, TODAY_DEATH_TIME / speed
	)
	tween.parallel().tween_property(
		node, "rotation_degrees", TODAY_DEATH_TURN * signf(direction.y), TODAY_DEATH_TIME / speed
	)
	tween.parallel().tween_property(
		node, "scale", Vector2.ONE * TODAY_DEATH_SCALE, TODAY_DEATH_TIME / speed
	)
	(
		tween
		. parallel()
		. tween_property(
			node, "modulate:a", 0.0, (TODAY_DEATH_TIME - TODAY_DEATH_FADE_DELAY) / speed
		)
		. set_delay(TODAY_DEATH_FADE_DELAY / speed)
	)
	tween.tween_callback(func() -> void: _gone(node))


## CardKeeper._fade_out at 00ceea90, as FightMotion's _fade_out called it (super).
func _keeper_fade_out(node: Control) -> void:
	stop(node)
	_landing.erase(node)
	if not animate or not node.is_inside_tree():
		layer.remove_child(node)
		node.queue_free()
		return
	node.z_index = 0
	_fading.append(node)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, FADE_TIME / speed)
	tween.tween_callback(func() -> void: _gone(node))


## Damage stays upright beside its recipient as it recoils. Later effects start at that
## recipient's current pose, rather than at an attack's old collision point.
func burst(hit: Control, recipient: Control = null) -> Tween:
	if not animate:
		return null
	hit.pivot_offset = hit.size / 2.0
	hit.scale = Vector2.ONE * TODAY_BURST_START
	var origin: Vector2 = hit.position
	var offset: Vector2 = origin - recipient.position if recipient != null else Vector2.ZERO
	var duration: float = TODAY_BURST_IN + TODAY_BURST_SETTLE + TODAY_BURST_READ + TODAY_BURST_FADE
	var tween: Tween = hit.create_tween()
	# Created after the cards' tweens: follow their pose in the same frame, without inheriting
	# their rotation/scale. One clock covers pop, read and fade, including the following motion.
	var draw_burst: Callable = func(age: float) -> void:
		var swell: float = 1.0
		if age < TODAY_BURST_IN:
			swell = lerpf(TODAY_BURST_START, TODAY_BURST_SCALE, age / TODAY_BURST_IN)
		elif age < TODAY_BURST_IN + TODAY_BURST_SETTLE:
			swell = lerpf(TODAY_BURST_SCALE, 1.0, (age - TODAY_BURST_IN) / TODAY_BURST_SETTLE)
		var fade: float = clampf((age - duration + TODAY_BURST_FADE) / TODAY_BURST_FADE, 0.0, 1.0)
		var at: Vector2 = origin
		if is_instance_valid(recipient):
			at = recipient.position + offset
		hit.position = at + Vector2.UP * TODAY_BURST_RISE * fade
		hit.scale = Vector2.ONE * swell
		hit.modulate.a = 1.0 - fade
	tween.tween_method(draw_burst, 0.0, duration, duration / speed)
	return tween
