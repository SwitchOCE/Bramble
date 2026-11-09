extends Control
## Wake progress and Committee runt marks have no text nodes.
const UiTheme := preload("res://src/ui/ui_theme.gd")
var period: int = 0
var progress: int = 0
var runt: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func show_state(view: Dictionary) -> void:
	period = CoreUtil.to_int(view.get("turns_goal", 0)) if view.get("hedgerow_clock", false) else 0
	progress = CoreUtil.to_int(view.get("turns_in_slot", 0))
	runt = CoreUtil.to_bool(view.get("hedgerow_runt", false))
	visible = period > 0 or runt
	queue_redraw()


func _draw() -> void:
	if runt:
		draw_arc(size * 0.5, minf(size.x, size.y) * 0.37, 0.0, TAU, 32, UiTheme.ACORN, 3.0, true)
	if period <= 0:
		return
	var gap: float = minf(16.0, size.x / (period + 2.0))
	for index: int in period:
		var centre := Vector2(size.x * 0.5 + (index - (period - 1) * 0.5) * gap, size.y - 10.0)
		draw_circle(centre, 5.0, UiTheme.INK)
		draw_circle(centre, 3.0, UiTheme.ACORN if index < progress else UiTheme.CREAM)
