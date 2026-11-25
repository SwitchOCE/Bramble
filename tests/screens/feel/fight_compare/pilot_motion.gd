extends "res://tests/screens/feel/fight_compare/rotate_motion.gd"
## CB13, how a single card dies: options B (tip and fall) and C (the light goes out) of
## docs/workstreams/fight-animation-24-nov/pilot/death.md, section 4, made from existing pieces
## only. A card that dies alone (pilot.gd's `solo`: the only unit leaving in its death step) plays
## the option; several deaths at once keep today's fall (CB8 owns their stagger). Each beat is
## drawn by frame after D (the death's first frame), from the clock pilot_screen.gd advances in
## game time, so it scales with fight speed. The death is not one of the keeper's tweens: the
## result's settle() lets it finish (death.md section 3).
## It extends rotate_motion.gd, which is FightMotion itself unless the rotation switch is on.
## Exploratory (the fight animation pilot, 24 Nov): nothing here reaches the game.

const Tokens := preload("res://tests/screens/feel/fight_compare/pilot_tokens.gd")

# ---- B: tip and fall ----
const B_TIP_FRAMES: int = 8
const B_TIP_TURN: float = 14.0
const B_TIP_LIGHT: float = 0.85
const B_DROP_FRAMES: int = 14
const B_DROP_PX: float = 120.0
const B_DROP_TURN: float = 36.0
const B_DROP_SCALE: float = 0.88
## Opaque until D + this, then to 0 on the drop's last frame.
const B_OPAQUE_TO: int = 14
# ---- C: the light goes out ----
const C_DARK_FRAMES: int = 8
const C_DARK: float = 0.25
const C_HOLD_FRAMES: int = 4
const C_SINK_FRAMES: int = 12
const C_SINK_PX: float = 24.0
const C_SINK_SCALE: float = 0.9
## The killing number stays on to D + this, then fades over NUMBER_FADE frames.
const B_NUMBER_TO: int = 16
const C_NUMBER_TO: int = 18
const NUMBER_FADE: int = 8

## "b" or "c"; anything else plays today's fall.
var option: String = "today"
## Keys ("u8") of units that die alone.
var solo: Dictionary = {}
## Game seconds, advanced by pilot_screen.gd.
var clock: float = 0.0
## Called with (key, name) as a death reaches a beat: death_tip, death_dark, death_gone.
var on_marker: Callable = Callable()
## `recommended` (recommended_screen.gd): key -> the second its death starts (the schedule's
## frame it leaves the board, / 60), in place of the clock as it leaves; and ages in fractions of
## a frame (whole_frames false), as the game's schedule draws them under FAST. `pilot` leaves both.
var starts: Dictionary = {}
var whole_frames: bool = true
## key -> {node, start, base, pivot, direction, side}
var _dying: Dictionary = {}


## The last frame a death of this option draws (D + n).
static func gone_frame(chosen: String) -> int:
	if chosen == "b":
		return B_TIP_FRAMES + B_DROP_FRAMES - 1
	return C_DARK_FRAMES + C_HOLD_FRAMES + C_SINK_FRAMES - 1


## The killing number's alpha `age` frames after D.
static func number_alpha(chosen: String, age: int) -> float:
	var held_to: int = B_NUMBER_TO if chosen == "b" else C_NUMBER_TO
	if age <= held_to:
		return 1.0
	return clampf(1.0 - float(age - held_to) / NUMBER_FADE, 0.0, 1.0)


func plays(key: String) -> bool:
	return option in ["b", "c"] and solo.has(key)


func _place(entry: Dictionary, old: Dictionary, first: bool) -> Control:
	var node: Control = super(entry, old, first)
	node.set_meta("pilot_key", entry["key"])
	return node


func _fade_out(node: Control) -> void:
	var key: String = str(node.get_meta("pilot_key", ""))
	if not animate or not node.is_inside_tree() or not plays(key):
		super(node)
		return
	stop(node)
	_fading.append(node)
	var direction: Vector2 = node.get_meta("death_direction", Vector2.DOWN)
	var attacker_side: float = -signf(direction.x) if absf(direction.x) > 0.01 else 1.0
	var pivot: Vector2 = node.size / 2.0
	if option == "b":
		# round its bottom corner on the far side from what hit it
		var away: float = signf(direction.x) if absf(direction.x) > 0.01 else attacker_side
		pivot = Vector2(node.size.x if away > 0.0 else 0.0, node.size.y)
		node.set_meta("pilot_tip", away)
	set_pivot(node, pivot)
	var start: float = GlassPieces.as_float(starts.get(key, clock))
	_dying[key] = {"node": node, "start": start, "base": node.position, "direction": direction}
	_mark(key, "death_tip" if option == "b" else "death_dark")
	_draw_death(key, 0.0)


## Every death on its frame of the clock; one that has drawn its last frame is gone.
func advance() -> void:
	for key: Variant in _dying.keys():
		var held: Dictionary = _dying[key]
		var age: float = (clock - GlassPieces.as_float(held["start"])) * 60.0
		_draw_death(str(key), roundf(age) if whole_frames else snappedf(age, 0.0001))


func _draw_death(key: String, age: float) -> void:
	var held: Dictionary = _dying[key]
	var node: Control = held["node"]
	if not is_instance_valid(node):
		_dying.erase(key)
		return
	if age > gone_frame(option):
		_dying.erase(key)
		_mark(key, "death_gone")
		_gone(node)
		return
	var base: Vector2 = held["base"]
	var direction: Vector2 = held["direction"]
	if option == "b":
		var away: float = GlassPieces.as_float(node.get_meta("pilot_tip", 1.0))
		if age < B_TIP_FRAMES:
			var tipped: float = Tokens.fall((age + 1.0) / B_TIP_FRAMES)
			node.rotation_degrees = B_TIP_TURN * away * tipped
			_light(node, lerpf(1.0, B_TIP_LIGHT, tipped), 1.0)
			return
		var into: float = age - B_TIP_FRAMES
		var p: float = (into + 1.0) / B_DROP_FRAMES
		node.position = base + direction * B_DROP_PX * Tokens.gravity(p)
		node.rotation_degrees = lerpf(B_TIP_TURN, B_DROP_TURN, Tokens.fall(p)) * away
		node.scale = Vector2.ONE * lerpf(1.0, B_DROP_SCALE, p)
		var alpha: float = 1.0
		if age > B_OPAQUE_TO:
			alpha = 1.0 - float(age - B_OPAQUE_TO) / (gone_frame("b") - B_OPAQUE_TO)
		_light(node, B_TIP_LIGHT, alpha)
		return
	if age < C_DARK_FRAMES:
		var dark: float = Tokens.exit((age + 1.0) / C_DARK_FRAMES)
		_light(node, lerpf(1.0, C_DARK, dark), 1.0)
		return
	if age < C_DARK_FRAMES + C_HOLD_FRAMES:
		_light(node, C_DARK, 1.0)
		return
	var sink: float = (age - C_DARK_FRAMES - C_HOLD_FRAMES + 1.0) / C_SINK_FRAMES
	var sunk: float = Tokens.fall(sink)
	node.position = base + direction * C_SINK_PX * sunk
	node.scale = Vector2.ONE * lerpf(1.0, C_SINK_SCALE, sunk)
	_light(node, C_DARK, 1.0 - sink)


static func _light(node: Control, light: float, alpha: float) -> void:
	node.modulate = Color(light, light, light, clampf(alpha, 0.0, 1.0))


## Dying cards stay drawn through the result's settle() (they are not the keeper's tweens).
func settle() -> void:
	var keep: Array[Control] = []
	for key: Variant in _dying:
		var node: Control = _dying[key]["node"]
		if is_instance_valid(node):
			keep.append(node)
			_fading.erase(node)
	super()
	for node: Control in keep:
		_fading.append(node)


func clear() -> void:
	_dying.clear()
	super()


func _mark(key: String, name: String) -> void:
	if on_marker.is_valid():
		on_marker.call(key, name)
