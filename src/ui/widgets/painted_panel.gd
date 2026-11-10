extends "res://src/ui/widgets/wood_panel.gd"
## Menu wood shares the counter's quiet material and canopy light.

const Surface := preload("res://src/ui/widgets/painted_surface.gd")


func _draw() -> void:
	Surface.paint(self, Rect2(Vector2.ZERO, size), edge)
