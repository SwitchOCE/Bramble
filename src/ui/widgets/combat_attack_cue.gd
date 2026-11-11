extends Control
## A transient, wordless source cue held for the complete reduced-motion attack.

const HexShape := preload("res://src/ui/widgets/hex_shape.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

var actor_uid: int = -1
var toward_top: bool = true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25


func _draw() -> void:
	# CombatMotion gives this cue the card box grown by 6 on each side.
	# Recover the same inset silhouette as the face, rather than its old art window.
	var rect: Rect2 = HexShape.fit(Rect2(Vector2.ONE * 6.0, size - Vector2.ONE * 12.0).grow(-6.0))
	var path: PackedVector2Array = HexShape.closed(rect.grow(3))
	draw_polyline(path, UiTheme.INK, 6.0, true)
	draw_polyline(path, UiTheme.ACORN, 2.0, true)
	var direction: float = -1.0 if toward_top else 1.0
	var centre := Vector2(size.x / 2, rect.position.y + 18.0 if toward_top else rect.end.y - 18.0)
	var arrow: PackedVector2Array = [
		centre + Vector2(0, direction * 16),
		centre + Vector2(23, -direction * 10),
		centre + Vector2(-23, -direction * 10)
	]
	draw_colored_polygon(arrow, UiTheme.ACORN)
	draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[0]]), UiTheme.INK, 3)
