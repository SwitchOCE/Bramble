extends Control
## The plank the shop's tiles stand on (.wr-shelf): oak with a carved edge and two pegs. While a
## board unit is being dragged it turns red and says where to drop it.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

const EDGE: float = 12.0

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
	var face: Rect2 = Rect2(Vector2.ZERO, size - Vector2(0, EDGE))
	var under: Rect2 = Rect2(Vector2(0, EDGE), face.size)
	var colour: Color = UiTheme.HEALTH if selling else UiTheme.OAK
	var low: Color = UiTheme.HEALTH_HURT if selling else UiTheme.CARVE
	draw_style_box(UiTheme.flat_box(low, UiTheme.INK, 6, 12), under)
	draw_style_box(UiTheme.flat_box(colour, UiTheme.INK, 6, 12), face)
	if not selling:
		draw_texture_rect(Icons.tile("chip"), face.grow(-6.0), true, Color(1, 1, 1, 0.7))
