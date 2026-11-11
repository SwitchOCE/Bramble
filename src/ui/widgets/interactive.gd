extends Control
## Shared input for cards and slots: a tap (press and release without moving far), hover, and
## drag and drop through callables the screen provides. Works with mouse and with touch (Godot
## emulates the mouse from touch by default), so every drag has a tap alternative on the screen.

signal tapped(zone: String, index: int)
signal hovered(zone: String, index: int, inside: bool)
signal drag_started(zone: String, index: int)

const HexShape := preload("res://src/ui/widgets/hex_shape.gd")

const TAP_SLOP: float = 18.0

## Where this lives on the screen ("shop", "hand", "board", "enemy", "library", ...) and its index.
var zone: String = ""
var index: int = -1
## Cards and slots opt into their painted contour; general screen zones stay rectangular.
var hex_hit_test: bool = false
## func(zone: String, index: int) -> Variant: drag data, or null to refuse. Unset: not draggable.
var drag_data_fn: Callable = Callable()
## func(data: Variant, zone: String, index: int) -> bool
var can_drop_fn: Callable = Callable()
## func(data: Variant, zone: String, index: int) -> void
var drop_fn: Callable = Callable()
## func(zone: String, index: int) -> Control: the preview shown under the finger while dragging.
var preview_fn: Callable = Callable()

var _press_position: Vector2 = Vector2.ZERO
var _pressing: bool = false
var _dragging: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Hex faces use exactly the same rounded contour as their paint.
func face_rect() -> Rect2:
	return HexShape.fit(Rect2(Vector2.ZERO, size).grow(-6.0))


func _has_point(point: Vector2) -> bool:
	if hex_hit_test:
		return HexShape.contains(face_rect(), point)
	return Rect2(Vector2.ZERO, size).has_point(point)


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed and _has_point(button.position):
		_pressing = true
		_dragging = false
		_press_position = button.position
	elif _pressing:
		_pressing = false
		if (
			not _dragging
			and _has_point(button.position)
			and button.position.distance_to(_press_position) <= TAP_SLOP
		):
			tapped.emit(zone, index)
			accept_event()


func _get_drag_data(at_position: Vector2) -> Variant:
	# Godot requests drag data after the pointer crosses its movement threshold. A press
	# that began on the face remains valid when that movement leaves the face's edge.
	if (not _pressing and not _has_point(at_position)) or not drag_data_fn.is_valid():
		return null
	var data: Variant = drag_data_fn.call(zone, index)
	if data == null:
		return null
	_dragging = true
	_pressing = false
	if preview_fn.is_valid():
		var preview: Control = preview_fn.call(zone, index)
		if preview != null:
			set_drag_preview(preview)
	drag_started.emit(zone, index)
	return data


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not _has_point(at_position) or not can_drop_fn.is_valid():
		return false
	var ok: bool = can_drop_fn.call(data, zone, index)
	return ok


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _has_point(at_position) and drop_fn.is_valid():
		drop_fn.call(data, zone, index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_dragging = false


func _on_mouse_entered() -> void:
	hovered.emit(zone, index, true)


func _on_mouse_exited() -> void:
	hovered.emit(zone, index, false)
