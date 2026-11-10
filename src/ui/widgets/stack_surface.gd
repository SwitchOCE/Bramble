extends Control
## One player surface includes formation and reserve; the action bar is its own slim lip.

const Surface := preload("res://src/ui/widgets/painted_surface.gd")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	Surface.paint(self, Rect2(Vector2.ZERO, size), 12.0)
