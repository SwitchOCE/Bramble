extends Control
## The limewood table behind every screen (.wc-table): pale bands, a seam every plank and a light
## burned grain. Flat fills only.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const PLANK: float = 270.0
const SEAM: float = 5.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.LIME)
	var y: float = 0.0
	var band: int = 0
	while y < size.y:
		if band % 2 == 1:
			draw_rect(Rect2(0, y, size.x, PLANK), UiTheme.LIME_BAND)
		draw_rect(Rect2(0, y + PLANK - SEAM, size.x, SEAM), Color(UiTheme.LIME_SEAM, 0.75))
		y += PLANK
		band += 1
	draw_texture_rect(Icons.tile("lime"), Rect2(Vector2.ZERO, size), true)
