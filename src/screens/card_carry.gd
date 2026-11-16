class_name CardCarry
extends RefCounted
## A card carried by the pointer, after Once Upon a Galaxy (the feel reference's
## baseline-notes.md): picked up, it lifts and grows about a fifth in about five frames, then
## floats; it stays glued to the pointer; it tilts toward its sideways travel, more the faster it
## goes, and straightens within a few frames when the pointer stops. The screen calls move() on
## each pointer motion and step() each frame; CardKeeper lands it when it is let go.
## STAND-IN numbers: tuned against the Galaxy clips, not designed.

## Scale gained when lifted.
const GROW: float = 0.2
## How far the card rises from where it was grabbed, as a share of its height.
const RISE: float = 0.12
## Per second: the lift is 90% done after about five frames, and creeps on after.
const LIFT_RATE: float = 28.0
## Degrees of tilt per pixel a second of sideways travel (15 degrees at 1250 px/s), and the most.
const TILT_PER_SPEED: float = 0.012
const TILT_MAX: float = 28.0
## Per second: how fast the measured speed, then the tilt, follow the pointer.
const SPEED_RATE: float = 25.0
const TILT_RATE: float = 30.0

var node: Control
## The pointer's place on the card when it was picked up (before the lift).
var _grab: Vector2
var _pointer: Vector2
var _last: Vector2
var _lift: float = 0.0
var _speed_x: float = 0.0


## Picks up a card under the pointer: it turns and grows about its middle from now on, and keeps
## whatever turn it had (a hand card's fan) until its travel or stillness sets one.
func _init(card: Control, pointer: Vector2) -> void:
	node = card
	CardKeeper.set_pivot(card, card.size / 2.0)
	_grab = pointer - card.position
	_pointer = pointer
	_last = pointer


func move(pointer: Vector2) -> void:
	_pointer = pointer
	_place()


func step(delta: float) -> void:
	if delta <= 0.0 or not is_instance_valid(node):
		return
	var speed_x: float = (_pointer.x - _last.x) / delta
	_last = _pointer
	_speed_x = lerpf(_speed_x, speed_x, 1.0 - exp(-delta * SPEED_RATE))
	_lift = lerpf(_lift, 1.0, 1.0 - exp(-delta * LIFT_RATE))
	var tilt: float = clampf(_speed_x * TILT_PER_SPEED, -TILT_MAX, TILT_MAX)
	node.rotation_degrees = lerpf(node.rotation_degrees, tilt, 1.0 - exp(-delta * TILT_RATE))
	_place()


func _place() -> void:
	if not is_instance_valid(node):
		return
	node.scale = Vector2.ONE * (1.0 + GROW * _lift)
	node.position = _pointer - _grab - Vector2(0.0, RISE * node.size.y * _lift)


## A unit lifted off its slot shows its own numbers, without what the slot gives it
## (slot_attack, slot_health in its card), until it lands: Galaxy's slot that matters.
static func take_slot_bonus(unit: Control, card: Dictionary) -> void:
	var glass: GlassCard = unit as GlassCard
	var given: Vector2i = Vector2i(
		GlassPieces.as_int(card.get("slot_attack", 0)),
		GlassPieces.as_int(card.get("slot_health", 0))
	)
	if glass != null and given != Vector2i.ZERO:
		glass.attack -= given.x
		glass.health -= given.y
		glass.queue_redraw()
