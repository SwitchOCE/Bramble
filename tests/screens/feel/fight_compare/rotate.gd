extends RefCounted
## Rotation everywhere (the owner, 24 Nov, dictated: "Every animation, I want to have the rotation
## included ... Even today can be modified as if it had rotation"). One switch for every treatment,
## `today`, `best`, `pilot`, `buffs` and `recommended` alike: "options": {"ROTATE": "on"} in a
## scenario. With it on, an attacker turns so the point facing its target leads (the top of yours,
## the bottom of theirs) and leans the same way (the tip: its leading end dipping away), on CB9's
## timing (best_timeline.gd). `best` swaps it in for CB9's option (best_timeline.gd _rotation());
## `today` and `pilot` add it on top of today's own motion (rotate_motion.gd), and CB12's striking
## portrait gets it too (pilot_hero_damage.gd). Off (no "ROTATE"), every treatment plays exactly as
## before. Exploratory (ideation/fight-animation): nothing here reaches the game.

const OPTION: String = "ROTATE"

## The set every film uses until the owner picks the amount of turn (CB15) and the lean (CB17):
## aim at 95 % of the path's angle, a medium lean (the tip: leading edge 0.94 of the trailing
## edge's width, length 0.85, about 32 degrees). Change these three numbers and every treatment
## follows.
const SET: Dictionary = {"aim": 0.95, "keystone": 0.94, "length": 0.85}

## CB9's timing (best_timeline.gd, from Galaxy): the turn is full this many frames before contact,
## 90 % of it is left at contact, and it is straight again this many frames after the return
## starts; the keystone fades over TIP_FADE, the length is back by LENGTH_BACK.
const AIM_FULL_BEFORE: int = 12
const AIM_AT_CONTACT: float = 0.9
const AIM_STRAIGHT: int = 25
const TIP_FADE: int = 10
const LENGTH_BACK: int = 8

const TIP_SHADER: Shader = preload("res://tests/screens/feel/fight_compare/tip.gdshader")


## Whether a scenario's options turn rotation on.
static func on(options: Dictionary) -> bool:
	return str(options.get(OPTION, "")) == "on"


## The turn for an attack along `way`: {turn (degrees, clockwise +, the full turn), lead (1: the
## top edge leads, -1: the bottom)}. The point facing the target leads.
static func aim_of(way: Vector2, chosen: Dictionary = SET) -> Dictionary:
	var lead: float = -1.0 if way.y > 0.0 else 1.0
	var full: float = rad_to_deg(Vector2(0.0, -lead).angle_to(way))
	return {"turn": GlassPieces.as_float(chosen["aim"]) * full, "lead": lead}


## Frames from the lift's first frame until the turn is full: C-12 when the hold is its least, as
## CB9; a wind-up shorter than that (today's whole attack is 12 frames) is full as its lift ends.
static func ramp_frames(lift: float, hold: float, strike: float) -> float:
	return maxf(maxf(lift, 1.0), lift + hold + strike - AIM_FULL_BEFORE)


## On the way in, n frames after the lift starts (n > 0): {share (of the full turn), keystone,
## length}. The strike runs from `launch` for `strike` frames (contact at launch + strike) on an
## ease-in of power `curve`; the turn eases from full to 90 % over it and the card shortens with
## the travel. Past contact it holds there (contact_pose).
static func approach(
	n: float, ramp: float, launch: float, strike: float, curve: float, chosen: Dictionary = SET
) -> Dictionary:
	if n <= 0.0:
		return {"share": 0.0, "keystone": 1.0, "length": 1.0}
	var rise: float = sin(PI / 2.0 * minf(1.0, n / ramp))
	var share: float = rise
	var tip: float = rise
	var length: float = 1.0
	var short: float = 1.0 - GlassPieces.as_float(chosen["length"])
	if n > launch:
		var u: float = minf(1.0, (n - launch) / strike)
		share = rise * lerpf(1.0, AIM_AT_CONTACT, u)
		length = 1.0 - short * pow(u, curve)
		if u >= 1.0:
			return contact_pose(chosen)
	return {"share": share, "keystone": _keystone(tip, chosen), "length": length}


## At contact, and held there until the return starts.
static func contact_pose(chosen: Dictionary = SET) -> Dictionary:
	return {
		"share": AIM_AT_CONTACT,
		"keystone": GlassPieces.as_float(chosen["keystone"]),
		"length": GlassPieces.as_float(chosen["length"]),
	}


## On the way home, j frames after the return starts: the turn unwinds over AIM_STRAIGHT
## (smootherstep), so the card lands home still turned and straightens there.
static func leaving(j: float, chosen: Dictionary = SET) -> Dictionary:
	var short: float = 1.0 - GlassPieces.as_float(chosen["length"])
	var share: float = AIM_AT_CONTACT * (1.0 - _smoother(clampf(j / AIM_STRAIGHT, 0.0, 1.0)))
	var tip: float = 1.0 - _smooth(clampf(j / TIP_FADE, 0.0, 1.0))
	var length: float = 1.0 - short * (1.0 - _quad_out(clampf(j / LENGTH_BACK, 0.0, 1.0)))
	return {"share": share, "keystone": _keystone(tip, chosen), "length": length}


## Frames after the return starts until it is all gone.
static func leaving_frames() -> int:
	return maxi(AIM_STRAIGHT, maxi(TIP_FADE, LENGTH_BACK))


## The leading end tipped away (tip.gdshader) while keystone < 1; otherwise the node drawn as the
## game draws it (no material). As best_screen.gd _tip.
static func apply_tip(node: CanvasItem, keystone: float, lead: float) -> void:
	var mat: ShaderMaterial = node.material as ShaderMaterial
	if keystone >= 1.0:
		if mat != null and mat.shader == TIP_SHADER:
			node.material = null
		return
	if mat == null or mat.shader != TIP_SHADER:
		mat = ShaderMaterial.new()
		mat.shader = TIP_SHADER
		node.material = mat
	if node is Control:
		mat.set_shader_parameter("card_size", (node as Control).size)
	mat.set_shader_parameter("keystone", keystone)
	mat.set_shader_parameter("lead", lead)


static func _keystone(tip: float, chosen: Dictionary) -> float:
	return 1.0 - (1.0 - GlassPieces.as_float(chosen["keystone"])) * tip


static func _quad_out(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)


static func _smooth(u: float) -> float:
	return u * u * (3.0 - 2.0 * u)


static func _smoother(u: float) -> float:
	return u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
