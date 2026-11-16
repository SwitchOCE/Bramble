extends Control
## The film tool's own demo (tools/feel/demo/demo.json): two rectangles to drag and two places to
## drop them. A rectangle let go over a place snaps there; anywhere else it goes back.

## Sizes and places as shares of the scene's size, so it fits any window or project size.
const BOX: Vector2 = Vector2(0.083, 0.2)
const PLACES: Array[Vector2] = [Vector2(0.26, 0.28), Vector2(0.66, 0.28)]
const BOXES: Array[Vector2] = [Vector2(0.36, 0.6), Vector2(0.55, 0.6)]
## Where the demo drops a box on nothing.
const SPOT: Vector2 = Vector2(0.47, 0.46)
const COLOURS: Array[Color] = [Color("c8553d"), Color("3d7cc8")]

var _box: Vector2
var _places: Array[Vector2] = []
var _boxes: Array[ColorRect] = []
var _homes: Array[Vector2] = []
var _held: int = -1
var _grip: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var whole: Vector2 = get_viewport_rect().size
	_box = BOX * whole
	for share: Vector2 in PLACES:
		var place: ColorRect = ColorRect.new()
		place.color = Color(1, 1, 1, 0.12)
		place.size = _box
		place.position = share * whole
		_places.append(place.position)
		place.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(place)
	for i: int in BOXES.size():
		var box: ColorRect = ColorRect.new()
		box.color = COLOURS[i]
		box.size = _box
		box.position = BOXES[i] * whole
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
		_boxes.append(box)
		_homes.append(box.position)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("1b1714"))


## A scenario's named targets: "box:i" (a rectangle's middle), "place:i" (a drop place's middle),
## "spot" (empty floor); null for any other.
func feel_point(target: String) -> Variant:
	if target == "spot":
		return SPOT * get_viewport_rect().size
	var parts: PackedStringArray = target.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return null
	var i: int = parts[1].to_int()
	if parts[0] == "box" and i >= 0 and i < _boxes.size():
		return _boxes[i].position + _box / 2.0
	if parts[0] == "place" and i >= 0 and i < _places.size():
		return _places[i] + _box / 2.0
	return null


## Where each rectangle ended, as the scene saw it: "place:i", "home", or "elsewhere".
func feel_report() -> Dictionary:
	var out: Dictionary = {}
	for i: int in _boxes.size():
		var at: Vector2 = _boxes[i].position
		var where: String = "elsewhere"
		if at.is_equal_approx(BOXES[i] * get_viewport_rect().size):
			where = "home"
		for k: int in _places.size():
			if at.is_equal_approx(_places[k]):
				where = "place:%d" % k
		out["box:%d" % i] = where
	return out


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			for i: int in range(_boxes.size() - 1, -1, -1):
				if _boxes[i].get_rect().has_point(button.position):
					_held = i
					_grip = button.position - _boxes[i].position
					move_child(_boxes[i], -1)
					break
		elif _held >= 0:
			_let_go(button.position)
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _held >= 0:
		_boxes[_held].position = motion.position - _grip


func _let_go(at: Vector2) -> void:
	var box: ColorRect = _boxes[_held]
	var to: Vector2 = _homes[_held]
	for place: Vector2 in _places:
		if Rect2(place, _box).has_point(at):
			to = place
			_homes[_held] = place
	_held = -1
	var tween: Tween = box.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "position", to, 0.12)
