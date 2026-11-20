class_name CardCarry
extends RefCounted
## A card carried by the pointer, after Once Upon a Galaxy (the feel reference's
## baseline-notes.md): picked up, it lifts and grows about a fifth in about five frames, then
## floats; it stays glued to the pointer, hanging from where it was gripped: its top trails the
## hand, leaning back against its sideways travel, more the faster it goes, and it straightens
## within about ten frames when the pointer stops. At speed it also narrows, as Galaxy's card turns
## toward edge-on. The screen calls move() on each pointer motion and step() each frame;
## CardKeeper lands it when it is let go. Carried up or down, it pitches back as it travels
## (foreshortened: drawn shorter), as it leans when carried sideways; both swing past straight a
## little when the hand stops, and settle, for weight.
## STAND-IN numbers: tuned against the Galaxy clips, then calmed on the owner's word after playing
## (17 Nov: "a bit too bouncy ... moving it side to side. It tilts a bit too much"; our cards are
## bigger than Galaxy's): about a third less lean, a quarter of the swing past straight.

## Scale gained when lifted.
const GROW: float = 0.2
## How far the card rises from where it was grabbed, as a share of its height (35 px on a 250 px
## card).
const RISE: float = 0.14
## The lift's time (9 frames), eased out: quick off the table, slowing as it reaches its height.
const LIFT_TIME: float = 9.0 / 60.0
## Degrees of lean per pixel a second of sideways travel (9 degrees at 1250 px/s), and the most.
const TILT_PER_SPEED: float = 0.0075
const TILT_MAX: float = 16.0
## Per second: how fast the measured speed follows the pointer.
const SPEED_RATE: float = 60.0
## The spring the lean and the pitch follow their targets on: its stiffness (a natural frequency,
## radians a second) and damping ratio. Let go of a 9 degree lean, it is straight in about 4
## frames, swings about 1 degree past and is still in about 12.
const SPRING: float = 30.0
const DAMPING: float = 0.5
## How much shorter the card is drawn per pixel a second of up or down travel (8% at 30 px a
## frame), and the most (at about 40 px a frame).
const PITCH_PER_SPEED: float = 0.08 / 1800.0
const PITCH_MAX: float = 0.11
## At NARROW_SPEED px/s and over, the card is NARROW of its width narrower.
const NARROW: float = 0.25
const NARROW_SPEED: float = 2500.0

var node: Control
## The pointer's place on the card when it was picked up (before the lift).
var _grab: Vector2
var _pointer: Vector2
var _last: Vector2
var _lift: float = 0.0
var _lift_time: float = 0.0
var _speed: Vector2 = Vector2.ZERO
## The lean in degrees and the pitch (a share of the height), each with its rate of change.
var _tilt: float = 0.0
var _tilt_rate: float = 0.0
var _pitch: float = 0.0
var _pitch_rate: float = 0.0


## Picks up a card under the pointer: it turns and grows about the point gripped from now on, and
## keeps whatever turn it had (a hand card's fan) until its travel or stillness sets one.
func _init(card: Control, pointer: Vector2) -> void:
	node = card
	var turn: Transform2D = Transform2D(card.rotation, card.scale, 0.0, Vector2.ZERO)
	var grip: Vector2 = turn.affine_inverse() * (pointer - card.position - card.pivot_offset)
	grip = (grip + card.pivot_offset).clamp(Vector2.ZERO, card.size)
	CardKeeper.set_pivot(card, grip)
	_grab = pointer - card.position
	_tilt = card.rotation_degrees
	_pointer = pointer
	_last = pointer


## The card's middle as drawn now (lifted, grown and turned), on its parent: where it drops when
## the player has chosen to drop cards by their middle (GameSettings).
func middle() -> Vector2:
	return node.get_transform() * (node.size / 2.0)


func move(pointer: Vector2) -> void:
	_pointer = pointer
	_place()


func step(delta: float) -> void:
	if delta <= 0.0 or not is_instance_valid(node):
		return
	var speed: Vector2 = (_pointer - _last) / delta
	_last = _pointer
	_lift_time += delta
	_lift = 1.0 - pow(1.0 - minf(_lift_time / LIFT_TIME, 1.0), 3.0)
	# Advance the speed filter and spring together. Using the end-of-frame speed for every
	# spring step would make the card react early during a long frame.
	var left: float = delta
	while left > 0.0:
		var dt: float = minf(left, 1.0 / 60.0)
		left -= dt
		_speed = _speed.lerp(speed, 1.0 - exp(-dt * SPEED_RATE))
		var tilt: float = clampf(-_speed.x * TILT_PER_SPEED, -TILT_MAX, TILT_MAX)
		var pitch: float = minf(absf(_speed.y) * PITCH_PER_SPEED, PITCH_MAX)
		_tilt_rate += (SPRING * SPRING * (tilt - _tilt) - 2.0 * DAMPING * SPRING * _tilt_rate) * dt
		_tilt += _tilt_rate * dt
		_pitch_rate += (
			(SPRING * SPRING * (pitch - _pitch) - 2.0 * DAMPING * SPRING * _pitch_rate) * dt
		)
		_pitch += _pitch_rate * dt
	node.rotation_degrees = _tilt
	_place()


func _place() -> void:
	if not is_instance_valid(node):
		return
	var narrow: float = 1.0 - NARROW * minf(absf(_speed.x) / NARROW_SPEED, 1.0)
	node.scale = Vector2(narrow, 1.0 - _pitch) * (1.0 + GROW * _lift)
	node.position = _pointer - _grab - Vector2(0.0, RISE * node.size.y * _lift)
