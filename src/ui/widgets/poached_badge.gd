extends Control
## A pool copy reserved from the last opponent. Cost comes from the actual shop view.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
var cost: int = 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5


func _draw() -> void:
	draw_style_box(UiTheme.slip_box(UiTheme.ACORN, 3, 8), Rect2(Vector2.ZERO, size))
	LaneOverlay.paw(self, Vector2(19, 20), 13)
	var words: String = "%d gold" % cost
	draw_string(
		UiTheme.bold_font(), Vector2(39, 29), words, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, UiTheme.INK
	)
