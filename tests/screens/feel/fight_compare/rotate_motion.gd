extends FightMotion
## Today's card motion (FightMotion) with the turn toward the target added on top, for the
## rotation switch (rotate.gd) on `today` and `pilot`. Everything today does stays as it is: the
## 4-frame lift with its 6 degree cock, the 8-frame quad strike, 2 frames at contact, the 11-frame
## return, and the attacker straightening while it waits at contact through a trigger. On top: the
## turn to rotate.gd's share of the path's angle, ramped from the lift's first frame (full as the
## lift ends: today's attack is too short for CB9's C-12), 90 % at contact and held there through a
## wait, unwound over 25 frames from the return's start; the lean (tip.gdshader's keystone and the
## shortening along the card's length) with it. Off (turn_on false) it is FightMotion exactly.
## Exploratory (ideation/fight-animation): nothing here reaches the game.

const Rotate := preload("res://tests/screens/feel/fight_compare/rotate.gd")

## The switch: off, every method is FightMotion's.
var turn_on: bool = false
## The turn and lean (rotate.gd SET).
var turn_set: Dictionary = Rotate.SET

## key -> {turn, lead, phase ("in", "held", "back"), today_turn, today_scale, pose, j}: each card
## turned now. today_turn and today_scale are today's own part of its pose; pose is the turn's.
var _aims: Dictionary = {}
## The key of the card being placed (FightMotion's _attack and _hit are given only the node).
var _key: String = ""


func _place(entry: Dictionary, old: Dictionary, first: bool) -> Control:
	if not turn_on:
		return super(entry, old, first)
	var key: String = entry["key"]
	_key = key
	var motion: Dictionary = motions.get(key, {})
	var aimed: Dictionary = _aims.get(key, {})
	var plain: bool = (
		not motion.get("attack", false)
		and not motion.get("hit", false)
		and not motion.get("jab", false)
	)
	var was: Control = old.get("node") if not old.is_empty() else null
	var at: Vector2 = entry["at"]
	var node: Control = super(entry, old, first)
	if not animate or not plain or aimed.is_empty() or was == null:
		return node
	if str(aimed["phase"]) == "in" and node == was and is_busy(node):
		# a new state mid-strike: FightMotion keeps the strike on its own clock
		return node
	if str(aimed["phase"]) != "back":
		# waiting at contact (a trigger before the hit): today straightens its own cock and lift
		# there; the turn holds
		_settle_at_contact(node, at, aimed)
	elif node != was:
		# rebuilt on the way home (its numbers changed): the return carries on where it was
		_return(node, at, aimed, false)
	return node


## Today's attack (FightMotion._attack's numbers and curves), drawn by frame with the turn added.
func _attack(node: Control, at: Vector2, direction: Vector2) -> void:
	if not turn_on:
		super(node, at, direction)
		return
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var lean: float = WINDUP_TURN * (-1.0 if direction.y < 0.0 else 1.0)
	var home: Vector2 = node.position
	var pulled: Vector2 = home - direction * WINDUP_PX
	var lift: float = windup_time * 60.0
	var strike: float = (ATTACK_TIME - windup_time) * 60.0
	var ramp: float = Rotate.ramp_frames(lift, 0.0, strike)
	var aim: Dictionary = Rotate.aim_of(direction, turn_set)
	var aimed: Dictionary = {
		"turn": aim["turn"],
		"lead": aim["lead"],
		"phase": "in",
		"today_turn": 0.0,
		"today_scale": 1.0,
		"pose": {},
		"j": 0.0,
	}
	_aims[_key] = aimed
	var draw: Callable = func(n: float) -> void:
		var pos: Vector2
		var own: float
		var size: float
		if n <= lift:
			var e: float = Rotate._quad_out(n / lift)
			pos = home.lerp(pulled, e)
			own = lean * e
			size = lerpf(1.0, LIFT_SCALE, e)
		else:
			var e: float = pow((n - lift) / strike, 2.0)
			pos = pulled.lerp(at, e)
			own = lerpf(lean, -lean / 2.0, e)
			size = LIFT_SCALE
		node.position = pos
		aimed["today_turn"] = own
		aimed["today_scale"] = size
		aimed["pose"] = Rotate.approach(n, ramp, lift, strike, 2.0, turn_set)
		_draw(node, aimed)
	tween.tween_method(draw, 0.0, lift + strike, ATTACK_TIME / speed)
	tween.tween_callback(func() -> void: aimed["phase"] = "held")


func _hit(node: Control, at: Vector2, motion: Dictionary) -> void:
	var aimed: Dictionary = _aims.get(_key, {})
	if not turn_on or not motion.get("returning", false) or aimed.is_empty():
		if not aimed.is_empty():
			# hit while still turned from its own attack: today's hit takes over, flat
			_aims.erase(_key)
			Rotate.apply_tip(node, 1.0, 1.0)
		super(node, at, motion)
		return
	if motion.get("received", false):
		node.modulate = BLOCK_LIGHT if motion.get("blocked", false) else HIT_LIGHT
	_return(node, at, aimed, true)


## Today's return (2 frames at contact, then home over 11 frames, cubic out), the turn unwinding
## over rotate.gd's 25 frames from the return's start. fresh: from contact; else from where a
## rebuilt card's return had got to.
func _return(node: Control, at: Vector2, aimed: Dictionary, fresh: bool) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var key: String = _key
	var from_at: Vector2 = node.position
	var from_turn: float = aimed["today_turn"]
	var from_scale: float = aimed["today_scale"]
	var from_light: Color = node.modulate
	var back: float = RETURN_TIME * 60.0
	var start: float = 0.0 if fresh else GlassPieces.as_float(aimed["j"])
	var total: float = maxf(back, Rotate.leaving_frames())
	aimed["phase"] = "back"
	if fresh:
		aimed["pose"] = Rotate.contact_pose(turn_set)
		_draw(node, aimed)
		tween.tween_interval(CONTACT_HOLD / speed)
	var draw: Callable = func(j: float) -> void:
		aimed["j"] = j
		var e: float = 1.0
		if j < back:
			e = 1.0 - pow(1.0 - (j - start) / (back - start), 3.0)
		node.position = from_at.lerp(at, e)
		node.modulate = from_light.lerp(Color.WHITE, e)
		aimed["today_turn"] = lerpf(from_turn, 0.0, e)
		aimed["today_scale"] = lerpf(from_scale, 1.0, e)
		aimed["pose"] = Rotate.leaving(j, turn_set)
		_draw(node, aimed)
	tween.tween_method(draw, start, total, (total - start) / 60.0 / speed)
	tween.tween_callback(
		func() -> void:
			Rotate.apply_tip(node, 1.0, 1.0)
			if _aims.get(key) == aimed:
				_aims.erase(key)
	)


## Waiting at contact: today's own cock and lift settle as FightMotion's move does (0.2 s, cubic
## out); the turn and lean stay at their contact pose.
func _settle_at_contact(node: Control, at: Vector2, aimed: Dictionary) -> void:
	var tween: Tween = _run(node)
	set_pivot(node, node.size / 2.0)
	var from_at: Vector2 = node.position
	var from_turn: float = aimed["today_turn"]
	var from_scale: float = aimed["today_scale"]
	aimed["phase"] = "held"
	aimed["pose"] = Rotate.contact_pose(turn_set)
	var draw: Callable = func(u: float) -> void:
		var e: float = 1.0 - pow(1.0 - u, 3.0)
		node.position = from_at.lerp(at, e)
		aimed["today_turn"] = lerpf(from_turn, 0.0, e)
		aimed["today_scale"] = lerpf(from_scale, 1.0, e)
		_draw(node, aimed)
	tween.tween_method(draw, 0.0, 1.0, MOVE_TIME / speed)


## Today's part plus the turn's: rotation, scale (shorter along its own length) and the tip.
func _draw(node: Control, aimed: Dictionary) -> void:
	var pose: Dictionary = aimed["pose"]
	if pose.is_empty():
		return
	var size: float = aimed["today_scale"]
	node.rotation_degrees = (
		GlassPieces.as_float(aimed["today_turn"])
		+ GlassPieces.as_float(aimed["turn"]) * GlassPieces.as_float(pose["share"])
	)
	node.scale = Vector2(size, size * GlassPieces.as_float(pose["length"]))
	Rotate.apply_tip(
		node, GlassPieces.as_float(pose["keystone"]), GlassPieces.as_float(aimed["lead"])
	)
