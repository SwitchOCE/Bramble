extends Control
## A temporary directional trace makes a travelling effect readable between sampled frames.

const UiTheme := preload("res://src/ui/ui_theme.gd")

var from_point: Vector2
var to_point: Vector2
var colour: Color = UiTheme.ACORN
var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _point(t: float) -> Vector2:
	return from_point.lerp(to_point, t) - Vector2(0, sin(t * PI) * 28)


func _draw() -> void:
	draw_circle(from_point, 11, UiTheme.INK)
	draw_circle(from_point, 7, UiTheme.ACORN)
	if progress <= 0.01 or from_point.distance_to(to_point) < 2:
		return
	var points: PackedVector2Array = [from_point]
	for index: int in range(1, 25):
		points.append(_point(progress * index / 24.0))
	# The arrow stops at the stat's rim so it never crosses its number.
	var direction: Vector2 = (points[-1] - points[-2]).normalized()
	var tip: Vector2 = points[-1] - direction * 24
	points[-1] = tip
	draw_polyline(points, UiTheme.INK, 11, true)
	draw_polyline(points, colour, 5, true)
	var cross: Vector2 = direction.orthogonal() * 11
	var arrow: PackedVector2Array = [
		tip, tip - direction * 22 + cross, tip - direction * 22 - cross
	]
	draw_colored_polygon(arrow, colour)
	draw_polyline(
		PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), UiTheme.INK, 3, true
	)
