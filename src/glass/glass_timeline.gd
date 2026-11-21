class_name GlassTimeline
extends RefCounted
## One clock for a group of moves, as a prototype's timeline (engine.js TL): every move is placed
## at a time in seconds from its start. It runs on a parallel Tween, so it follows the game's
## clock (and the film tool's fixed 60 frames a second). finish() lands everything at its end.

var tween: Tween
## Run when the timeline ends or is finished early, after every move has landed.
var _ends: Array[Callable] = []


func _init(owner: Node) -> void:
	tween = owner.create_tween().set_parallel()
	tween.finished.connect(_end)


func running() -> bool:
	return tween != null and tween.is_valid()


## apply(u) for u from 0 to 1 over time seconds, from at.
func phase(at: float, time: float, apply: Callable) -> void:
	tween.tween_method(apply, 0.0, 1.0, maxf(time, 0.001)).set_delay(at)


## apply() once, at at.
func call_at(at: float, apply: Callable) -> void:
	tween.tween_callback(apply).set_delay(at)


## Web Animations keyframes on a node's pose: steps [[seconds from at, pose, alpha or null], ...]
## under one easing (GlassMotion's curves), as engine.js path().
func path(node: CanvasItem, at: float, steps: Array, curve: Vector4) -> void:
	var last: Array = steps[-1]
	var end: float = last[0]
	var length: float = maxf(end, 0.001)
	var poses: Array = []
	var alphas: Array = []
	for step: Array in steps:
		var time: float = step[0]
		poses.append([time / length, step[1]])
		if step.size() > 2 and step[2] != null:
			var alpha: float = step[2]
			alphas.append([time / length, alpha])
	phase(
		at,
		length,
		func(u: float) -> void:
			var eased: float = GlassMotion.bezier(curve, u)
			var p: Dictionary = GlassMotion.keyframes(poses, eased)
			GlassMotion.apply(node, p)
			if not alphas.is_empty():
				var alpha: float = GlassMotion.keyframes(alphas, eased)
				node.modulate.a = alpha
	)


## Keyframes on any value: steps [[offset 0-1, value], ...] under one easing.
func frames(at: float, time: float, steps: Array, curve: Vector4, apply: Callable) -> void:
	phase(
		at,
		time,
		func(u: float) -> void:
			apply.call(GlassMotion.keyframes(steps, GlassMotion.bezier(curve, u)))
	)


## engine.js fly(): a flight between two poses, linear in time, the place bent by a named curve.
func fly(
	node: CanvasItem,
	from: Dictionary,
	to: Dictionary,
	at: float,
	time: float,
	curve: String,
	lift: float = 0.0,
	lean: float = 0.0
) -> void:
	phase(
		at,
		time,
		func(u: float) -> void:
			GlassMotion.apply(node, GlassMotion.flight(from, to, u, curve, lift, lean))
	)


## A count from one whole number to another, as engine.js num(): eased out (ez out).
func count(at: float, time: float, from: int, to: int, show: Callable) -> void:
	phase(
		at,
		time,
		func(u: float) -> void: show.call(roundi(lerpf(from, to, GlassMotion.ez("out", u))))
	)


## Run end() once the timeline is over, whether it ran out or was finished.
func on_end(end: Callable) -> void:
	_ends.append(end)


## Everything at its end, at once.
func finish() -> void:
	if not running():
		_end()
		return
	tween.custom_step(1000.0)
	if tween != null and tween.is_valid():
		tween.kill()
	_end()


func _end() -> void:
	var ends: Array[Callable] = _ends
	_ends = []
	tween = null
	for end: Callable in ends:
		end.call()
