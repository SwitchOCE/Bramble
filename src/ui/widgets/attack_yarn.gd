extends Control
## The attack line (.wk-yarn): a red-stitched yarn from attacker to target, drawn along a route the
## screen works out (so it never crosses over tiles in the way) and ending in an arrow. `progress`
## animates it being pulled out.

const UiTheme := preload("res://src/ui/ui_theme.gd")

const STITCH: float = 22.0
const CORNER: float = 26.0

## Share of the route drawn so far, 0 to 1.
var progress: float = 1.0:
	set(value):
		progress = value
		queue_redraw()

var _route: PackedVector2Array = []
var _length: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_route(points: PackedVector2Array) -> void:
	_route = _round_corners(points)
	_length = 0.0
	for i: int in range(1, _route.size()):
		_length += _route[i - 1].distance_to(_route[i])
	visible = true
	queue_redraw()


func hide_route() -> void:
	_route = []
	visible = false


## The route's points, for tests.
func route() -> PackedVector2Array:
	return _route


## Replaces each inside corner with a short curve, so the yarn bends rather than kinks.
func _round_corners(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = []
	for i: int in points.size():
		if i == 0 or i == points.size() - 1:
			out.append(points[i])
			continue
		var before: Vector2 = points[i - 1]
		var corner: Vector2 = points[i]
		var after: Vector2 = points[i + 1]
		var a: Vector2 = corner.move_toward(before, minf(CORNER, corner.distance_to(before) / 2.0))
		var b: Vector2 = corner.move_toward(after, minf(CORNER, corner.distance_to(after) / 2.0))
		for step: int in 7:
			var t: float = step / 6.0
			out.append(a.lerp(corner, t).lerp(corner.lerp(b, t), t))
	return out


func _draw() -> void:
	if _route.size() < 2 or _length <= 0.0:
		return
	var drawn: PackedVector2Array = _cut(_length * progress)
	if drawn.size() < 2:
		return
	draw_polyline(drawn, UiTheme.INK, 17.0, true)
	draw_polyline(drawn, UiTheme.BIRCH, 9.0, true)
	_draw_stitches(drawn)
	if progress >= 0.999:
		_draw_arrow(drawn[drawn.size() - 2], drawn[drawn.size() - 1])


func _cut(wanted: float) -> PackedVector2Array:
	var out: PackedVector2Array = [_route[0]]
	var left: float = wanted
	for i: int in range(1, _route.size()):
		var piece: float = _route[i - 1].distance_to(_route[i])
		if piece >= left:
			out.append(_route[i - 1].move_toward(_route[i], left))
			return out
		out.append(_route[i])
		left -= piece
	return out


func _draw_stitches(line: PackedVector2Array) -> void:
	var on: bool = true
	var left: float = STITCH
	for i: int in range(1, line.size()):
		var from: Vector2 = line[i - 1]
		var to: Vector2 = line[i]
		var piece: float = from.distance_to(to)
		while piece > 0.0:
			var run: float = minf(left, piece)
			var next: Vector2 = from.move_toward(to, run)
			if on:
				draw_line(from, next, UiTheme.YARN, 9.0)
			from = next
			piece -= run
			left -= run
			if left <= 0.0:
				on = not on
				left = STITCH if on else STITCH * 0.5


func _draw_arrow(from: Vector2, to: Vector2) -> void:
	var along: Vector2 = (to - from).normalized()
	var side: Vector2 = along.orthogonal()
	var tip: PackedVector2Array = [
		to + along * 26.0, to - along * 8.0 + side * 28.0, to - along * 8.0 - side * 28.0
	]
	draw_colored_polygon(tip, UiTheme.YARN)
	var closed: PackedVector2Array = tip.duplicate()
	closed.append(tip[0])
	draw_polyline(closed, UiTheme.INK, 6.0, true)
