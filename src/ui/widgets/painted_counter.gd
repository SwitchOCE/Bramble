extends "res://src/ui/widgets/shelf_plank.gd"
## Merchant counter shares the board's wood and catches the same warm canopy light.

const Surface := preload("res://src/ui/widgets/painted_surface.gd")


func _draw() -> void:
	Surface.paint(self, Rect2(0, -20, size.x, 64), 18.0)
	if selling:
		draw_style_box(
			UiTheme.flat_box(Color(UiTheme.HEALTH, 0.8), Color.TRANSPARENT, 0, 18),
			Rect2(Vector2.ZERO, size)
		)
