extends Control
## Wake progress and Committee runt marks have no text nodes.
const UiTheme := preload("res://src/ui/ui_theme.gd")
var period: int = 0
var progress: int = 0
var runt: bool = false
var reset_preview: bool = false
var hunker: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func show_state(view: Dictionary, selected: bool = false) -> void:
	period = CoreUtil.to_int(view.get("turns_goal", 0)) if view.get("hedgerow_clock", false) else 0
	progress = CoreUtil.to_int(view.get("turns_in_slot", 0))
	runt = CoreUtil.to_bool(view.get("hedgerow_runt", false))
	reset_preview = selected and period > 0 and progress > 0
	hunker = false
	for entry: Dictionary in view.get("statuses", []):
		hunker = hunker or str(entry.get("status", "")) == "hunker"
	visible = period > 0 or runt or hunker
	queue_redraw()


func _draw() -> void:
	if hunker:
		var centre := Vector2(size.x - 15.0, 16.0)
		draw_colored_polygon(
			PackedVector2Array(
				[
					centre + Vector2(-9, -9),
					centre + Vector2(9, -9),
					centre + Vector2(8, 3),
					centre + Vector2(0, 11),
					centre + Vector2(-8, 3),
				]
			),
			UiTheme.ACORN
		)
	if runt:
		draw_arc(size * 0.5, minf(size.x, size.y) * 0.37, 0.0, TAU, 32, UiTheme.ACORN, 3.0, true)
	if period <= 0:
		return
	var gap: float = minf(16.0, size.x / (period + 2.0))
	if reset_preview:
		var width: float = gap * (period - 1) + 20.0
		draw_rect(
			Rect2((size.x - width) * 0.5, size.y - 20.0, width, 19.0), UiTheme.SELECT, false, 2.0
		)
	for index: int in period:
		var centre := Vector2(size.x * 0.5 + (index - (period - 1) * 0.5) * gap, size.y - 10.0)
		draw_circle(centre, 5.0, UiTheme.INK)
		draw_circle(centre, 3.0, UiTheme.ACORN if index < progress else UiTheme.CREAM)
