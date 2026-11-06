extends Control
## A wooden slider (.wc-slider): a moss-filled groove with a round peg. 0 to 100. Tap anywhere on
## the groove, or drag the peg.

signal changed(value: int)

const UiTheme := preload("res://src/ui/ui_theme.gd")

const PEG: float = 84.0
const GROOVE: float = 32.0

var value: int = 80:
	set(new_value):
		value = clampi(new_value, 0, 100)
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(240, 122)


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	var dragging: bool = motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		_set_from(button.position.x)
		accept_event()
	elif dragging:
		_set_from(motion.position.x)
		accept_event()


func _set_from(x: float) -> void:
	var run: float = maxf(size.x - PEG, 1.0)
	var new_value: int = roundi(clampf((x - PEG / 2.0) / run, 0.0, 1.0) * 100.0)
	if new_value != value:
		value = new_value
		changed.emit(value)


func _draw() -> void:
	var mid: float = size.y / 2.0
	var run: float = size.x - PEG
	var peg_x: float = PEG / 2.0 + run * value / 100.0
	var groove: Rect2 = Rect2(PEG / 4.0, mid - GROOVE / 2.0, size.x - PEG / 2.0, GROOVE)
	draw_style_box(UiTheme.flat_box(UiTheme.CARVE, UiTheme.INK, 5, 16), groove)
	var filled: Rect2 = Rect2(groove.position, Vector2(peg_x - groove.position.x, GROOVE))
	draw_style_box(UiTheme.flat_box(UiTheme.MOSS, UiTheme.INK, 5, 16), filled)
	var centre: Vector2 = Vector2(peg_x, mid)
	draw_circle(centre + Vector2(0, 8), PEG / 2.0, UiTheme.INK)
	draw_circle(centre + Vector2(0, 8), PEG / 2.0 - 5.0, UiTheme.CARVE)
	draw_circle(centre, PEG / 2.0, UiTheme.INK)
	draw_circle(centre, PEG / 2.0 - 5.0, UiTheme.BIRCH)
	draw_circle(centre, 18.0, UiTheme.INK)
	draw_circle(centre, 14.0, UiTheme.ACORN)
