extends Node2D
## The pointer drawn on a film (tools/feel): an arrow with its tip at the node's position, and a
## soft ring round the tip while the button is held.

const ARROW: PackedVector2Array = [
	Vector2(0, 0),
	Vector2(0, 30),
	Vector2(8, 23),
	Vector2(14, 36),
	Vector2(19, 34),
	Vector2(13, 21),
	Vector2(23, 21),
	Vector2(0, 0),
]
const HELD: Color = Color(1.0, 0.85, 0.3, 0.45)

var down: bool = false


func show_at(at: Vector2, held: bool) -> void:
	position = at
	down = held
	queue_redraw()


func _draw() -> void:
	if down:
		draw_circle(Vector2.ZERO, 16.0, HELD)
	draw_colored_polygon(ARROW, Color.WHITE)
	draw_polyline(ARROW, Color.BLACK, 2.0, true)
