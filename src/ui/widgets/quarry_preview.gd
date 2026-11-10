extends Control
## A momentary quarry reticle: this is the aimed-at unit, not another selected card.

const UiTheme := preload("res://src/ui/ui_theme.gd")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(72, 72)


func _draw() -> void:
	var center: Vector2 = size / 2.0
	draw_circle(center, 31, UiTheme.INK)
	draw_circle(center, 27, UiTheme.CREAM)
	for quadrant: int in 4:
		var angle: float = quadrant * PI / 2.0
		draw_arc(center, 20, angle + 0.18, angle + PI / 2.0 - 0.18, 12, UiTheme.YARN, 5, true)
		var direction: Vector2 = Vector2.from_angle(angle)
		draw_line(center + direction * 13, center + direction * 32, UiTheme.INK, 4, true)
	draw_circle(center, 5, UiTheme.YARN)
