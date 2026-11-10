extends Control
## A temporary directional trace makes a travelling effect readable between sampled frames.

const UiTheme := preload("res://src/ui/ui_theme.gd")

var from_point: Vector2
var to_point: Vector2
var via_point: Vector2 = Vector2.INF
var arrived: bool = false:
	set(value):
		arrived = value
		queue_redraw()
var colour: Color = UiTheme.ACORN
var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _point(t: float) -> Vector2:
	if via_point.is_finite():
		return from_point.lerp(via_point, t).lerp(via_point.lerp(to_point, t), t)
	return from_point.lerp(to_point, t) - Vector2(0, sin(t * PI) * 28)


func _draw() -> void:
	draw_circle(from_point, 11, UiTheme.INK)
	draw_circle(from_point, 7, UiTheme.ACORN)
	var distance: float = from_point.distance_to(to_point)
	if progress <= 0.01 or distance < 2:
		return
	var tangent: Vector2 = (
		(to_point - via_point) * 2
		if via_point.is_finite()
		else to_point - from_point + Vector2(0, PI * 28)
	)
	var rim: float = maxf(0, 1.0 - 24.0 / maxf(24, tangent.length()))
	var flight: PackedVector2Array = [from_point]
	var points: PackedVector2Array = [from_point]
	for index: int in range(1, 49):
		flight.append(_point(rim * index / 48.0))
		points.append(_point(progress * rim * index / 48.0))
	# The complete faint route identifies the destination during transit.
	draw_polyline(flight, Color(UiTheme.INK, 0.25), 5, true)
	draw_polyline(flight, Color(colour, 0.35), 2, true)
	draw_polyline(points, UiTheme.INK, 11, true)
	draw_polyline(points, colour, 5, true)
	# An in-flight arrowhead looked like a landing on a crossed pocket.
	if not arrived:
		return
	var direction: Vector2 = (flight[-1] - flight[-2]).normalized()
	var tip: Vector2 = flight[-1]
	var cross: Vector2 = direction.orthogonal() * 11
	var arrow: PackedVector2Array = [
		tip, tip - direction * 22 + cross, tip - direction * 22 - cross
	]
	draw_colored_polygon(arrow, colour)
	draw_polyline(
		PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), UiTheme.INK, 3, true
	)
