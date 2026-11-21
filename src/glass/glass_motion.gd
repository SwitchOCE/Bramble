class_name GlassMotion
extends RefCounted
## Motion as the owner's accepted animation prototypes draw it
## (docs/design/mockups/fix-round-20-nov/anim-recruit/engine.js), so a timing, an easing and a
## path built in the game move as the prototype does, frame for frame.
##
## The prototype runs Web Animations: an effect's easing bends its whole run, and its keyframes
## sit on that bent progress, each pair joined in a straight line (path(), the price tag's swing,
## a pulse). Its flights (fly()) are sampled the other way round: the named curve (ez) is applied
## to the place along the path and the run itself is linear. Both are kept apart here so each
## animation can follow the one its prototype used.
##
## A pose is {at: top left (unscaled, unturned), turn: degrees, scale}, turned and scaled about
## the node's pivot, as a prototype's element is about its middle (transform-origin 50% 50%).

## engine.js EASE: cubic-bezier control points (x1, y1, x2, y2).
const OUT: Vector4 = Vector4(0.2, 0.8, 0.2, 1.0)
const INOUT: Vector4 = Vector4(0.45, 0.0, 0.25, 1.0)
const IN: Vector4 = Vector4(0.55, 0.0, 0.9, 0.45)
const BACK: Vector4 = Vector4(0.3, 1.55, 0.5, 1.0)
const LINEAR: Vector4 = Vector4(0.0, 0.0, 1.0, 1.0)


## A CSS cubic-bezier easing at progress x (0 to 1).
static func bezier(curve: Vector4, x: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0
	if curve == LINEAR:
		return x
	# solve x(s) = x for the curve's parameter s, then read y(s)
	var s: float = x
	for _i: int in 8:
		var dx: float = _cubic(curve.x, curve.z, s) - x
		var slope: float = _slope(curve.x, curve.z, s)
		if absf(dx) < 1e-6:
			break
		if absf(slope) < 1e-6:
			s = _bisect(curve, x)
			break
		s = clampf(s - dx / slope, 0.0, 1.0)
	return _cubic(curve.y, curve.w, s)


## engine.js ez: the curves its flights are sampled with.
static func ez(name: String, u: float) -> float:
	match name:
		"out":
			return 1.0 - pow(1.0 - u, 3.0)
		"inout":
			return 4.0 * u * u * u if u < 0.5 else 1.0 - pow(-2.0 * u + 2.0, 3.0) / 2.0
		"in":
			return u * u * u
		"arrive":
			# sets off gently and arrives at speed, as the build's let-go flight
			return u * u * (1.6 - 0.6 * u)
	return u


static func pose(at: Vector2, turn: float = 0.0, scale: float = 1.0) -> Dictionary:
	return {"at": at, "turn": turn, "scale": scale}


static func apply(node: CanvasItem, p: Dictionary) -> void:
	var at: Vector2 = p["at"]
	var turn: float = p["turn"]
	var size: float = p["scale"]
	var control: Control = node as Control
	if control != null:
		control.position = at
		control.rotation_degrees = turn
		control.scale = Vector2.ONE * size
		return
	var item: Node2D = node as Node2D
	item.position = at
	item.rotation_degrees = turn
	item.scale = Vector2.ONE * size


static func mix(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var a_at: Vector2 = a["at"]
	var b_at: Vector2 = b["at"]
	var a_turn: float = a["turn"]
	var b_turn: float = b["turn"]
	var a_scale: float = a["scale"]
	var b_scale: float = b["scale"]
	return {
		"at": a_at.lerp(b_at, k),
		"turn": lerpf(a_turn, b_turn, k),
		"scale": lerpf(a_scale, b_scale, k),
	}


## Web Animations keyframes: steps [[offset 0-1, value], ...] read at an eased progress, each
## neighbouring pair joined straight. Values are poses, floats, Colors or Vector2s.
static func keyframes(steps: Array, eased: float) -> Variant:
	var first: Array = steps[0]
	var first_at: float = first[0]
	if eased <= first_at:
		return first[1]
	for i: int in range(1, steps.size()):
		var a: Array = steps[i - 1]
		var b: Array = steps[i]
		var a_at: float = a[0]
		var b_at: float = b[0]
		if eased <= b_at or i == steps.size() - 1:
			var k: float = (eased - a_at) / maxf(b_at - a_at, 1e-6)
			var from: Variant = a[1]
			var to: Variant = b[1]
			if from is Dictionary:
				var pose_a: Dictionary = from
				var pose_b: Dictionary = to
				return mix(pose_a, pose_b, k)
			return lerp(from, to, k)
	var last: Array = steps[-1]
	return last[1]


## engine.js fly(): a flight from one pose to another, the place along it bent by the named
## curve, arced up by lift at its middle and leaning lean degrees at its middle.
static func flight(
	from: Dictionary, to: Dictionary, u: float, curve: String, lift: float, lean: float
) -> Dictionary:
	var k: float = ez(curve, u)
	var p: Dictionary = mix(from, to, k)
	var at: Vector2 = p["at"]
	var turn: float = p["turn"]
	p["at"] = at - Vector2(0.0, lift * 4.0 * k * (1.0 - k))
	p["turn"] = turn + lean * sin(PI * k)
	return p


## engine.js hop(): after a card lands it rises 6.4% of its height and swells 1.06 at 45%, then
## settles, over 0.2 s, easing in and out.
static func hop(rest: Dictionary, height: float, u: float) -> Dictionary:
	var at: Vector2 = rest["at"]
	var size: float = rest["scale"]
	var up: Dictionary = rest.duplicate()
	up["at"] = at - Vector2(0.0, 0.064 * height)
	up["scale"] = size * 1.06
	var p: Dictionary = keyframes([[0.0, rest], [0.45, up], [1.0, rest]], bezier(INOUT, u))
	return p


static func _cubic(p1: float, p2: float, s: float) -> float:
	var r: float = 1.0 - s
	return 3.0 * r * r * s * p1 + 3.0 * r * s * s * p2 + s * s * s


static func _slope(p1: float, p2: float, s: float) -> float:
	var r: float = 1.0 - s
	return 3.0 * r * r * p1 + 6.0 * r * s * (p2 - p1) + 3.0 * s * s * (1.0 - p2)


static func _bisect(curve: Vector4, x: float) -> float:
	var lo: float = 0.0
	var hi: float = 1.0
	var s: float = x
	for _i: int in 30:
		s = (lo + hi) / 2.0
		if _cubic(curve.x, curve.z, s) < x:
			lo = s
		else:
			hi = s
	return s
