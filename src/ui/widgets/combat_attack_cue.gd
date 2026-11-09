extends Control
## A transient, wordless source cue held for the complete reduced-motion attack.

const UiTheme := preload("res://src/ui/ui_theme.gd")

var actor_uid: int = -1
var toward_top: bool = true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(UiTheme.flat_box(Color.TRANSPARENT, UiTheme.INK, 12, 18), rect)
	draw_style_box(UiTheme.flat_box(Color.TRANSPARENT, UiTheme.ACORN, 7, 18), rect)
	var direction: float = -1.0 if toward_top else 1.0
	var centre := Vector2(size.x / 2, 16.0 if toward_top else size.y - 16.0)
	var arrow: PackedVector2Array = [
		centre + Vector2(0, direction * 16),
		centre + Vector2(23, -direction * 10),
		centre + Vector2(-23, -direction * 10)
	]
	draw_colored_polygon(arrow, UiTheme.ACORN)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), UiTheme.INK, 3)
