class_name VolumeSlider
extends Control
## A volume slider for the pause panel (STAND-IN look, 21 Nov: no mock-up has one yet): a lead
## groove, lit amber up to the value, and a round knob. Press or drag along it to set the value;
## `changed` follows the pointer and `released` fires once when it is let go.

signal changed(value: float)
signal released(value: float)

const GROOVE_H: float = 10.0
const KNOB_R: float = 13.0
const LEAD: Color = Color("1b1410")
const GROOVE: Color = Color("4a3d30")

var value: float = 0.8:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()

var _held: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		_held = click.pressed
		_follow(click.position.x)
		if not click.pressed:
			released.emit(value)
		accept_event()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _held:
		_follow(motion.position.x)
		accept_event()


func _follow(x: float) -> void:
	var left: float = KNOB_R
	var span: float = maxf(1.0, size.x - 2.0 * KNOB_R)
	value = (x - left) / span
	changed.emit(value)


func _draw() -> void:
	var mid: float = size.y / 2.0
	var left: float = KNOB_R
	var right: float = size.x - KNOB_R
	var groove: Rect2 = Rect2(left, mid - GROOVE_H / 2.0, right - left, GROOVE_H)
	draw_rect(groove.grow(2.0), LEAD)
	draw_rect(groove, GROOVE)
	var at: float = left + (right - left) * value
	draw_rect(Rect2(left, groove.position.y, at - left, GROOVE_H), GlassUi.GO)
	draw_circle(Vector2(at, mid), KNOB_R + 2.0, LEAD)
	draw_circle(Vector2(at, mid), KNOB_R, GlassUi.MUTED)
