extends Control
## One player surface includes formation and reserve; the action bar is its own slim lip.

const Surface := preload("res://src/ui/widgets/painted_surface.gd")

var formation_size: Vector2 = Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var face: Rect2 = Rect2(Vector2.ZERO, size)
	if formation_size != Vector2.ZERO:
		face = Rect2(Vector2((size.x - formation_size.x) / 2.0, 0), formation_size)
	Surface.paint(self, face, 12.0)
