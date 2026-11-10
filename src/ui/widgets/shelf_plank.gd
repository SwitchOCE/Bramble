extends Control
## The plank the shop's tiles stand on (.wr-shelf): oak with a carved edge and two pegs. While a
## board unit is being dragged it turns red and says where to drop it.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Surface := preload("res://src/ui/widgets/painted_surface.gd")

var selling: bool = false:
	set(value):
		selling = value
		_sell_label.visible = value
		queue_redraw()

var _sell_label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_sell_label = UiTheme.head("Drop here to sell", UiTheme.FONT_BODY + 6, UiTheme.CREAM)
	_sell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sell_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sell_label.visible = false
	add_child(_sell_label)
	resized.connect(queue_redraw)


func _draw() -> void:
	Surface.paint(self, Rect2(0, -20, size.x, 64), 18.0)
	if selling:
		draw_style_box(
			UiTheme.flat_box(Color(UiTheme.HEALTH, 0.8), Color.TRANSPARENT, 0, 18),
			Rect2(Vector2.ZERO, size)
		)
