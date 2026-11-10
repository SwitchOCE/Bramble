extends "res://src/ui/widgets/slot_view.gd"
## The clearing has no resting sockets. Only an active placement target draws a rim.

var quiet: bool = false:
	set(value):
		quiet = value
		queue_redraw()


func _draw() -> void:
	if not quiet:
		super()
		return
	if highlight.a <= 0.0:
		return
	var pulse: float = 0.8 + 0.2 * sin(TAU * _target_age / 0.8)
	var fill: Color = Color(highlight, highlight.a * pulse * 0.22)
	var rim: Color = Color(UiTheme.ACORN, pulse)
	draw_style_box(UiTheme.flat_box(fill, rim, 3, 20), Rect2(Vector2.ZERO, size))
