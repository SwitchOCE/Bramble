extends RefCounted
## Shared stump material, a thin lit lip and a soft contact shadow; no panel outside the surface.

const WOOD: Texture2D = preload("res://assets/ui/world/stump.jpg")


static func paint(canvas: CanvasItem, rect: Rect2, depth: float = 12.0) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.025, 0.045, 0.03, 0.35)
	shadow.set_corner_radius_all(24)
	shadow.shadow_color = Color(0.015, 0.035, 0.025, 0.38)
	shadow.shadow_size = 20
	shadow.shadow_offset = Vector2(0, 12)
	canvas.draw_style_box(shadow, Rect2(rect.position + Vector2(0, depth), rect.size))
	var edge := StyleBoxFlat.new()
	edge.bg_color = Color("57452e")
	edge.border_color = Color("80704a")
	edge.set_border_width_all(2)
	edge.set_corner_radius_all(22)
	canvas.draw_style_box(edge, Rect2(rect.position + Vector2(0, depth), rect.size))
	var corners: PackedVector2Array = []
	var uv: PackedVector2Array = []
	var radius: float = minf(22, rect.size.y / 2.0)
	for corner: int in 4:
		var center: Vector2 = (
			rect.position
			+ Vector2(
				rect.size.x - radius if corner in [0, 1] else radius,
				rect.size.y - radius if corner in [1, 2] else radius
			)
		)
		for step: int in 7:
			var angle: float = (-PI / 2.0) + corner * PI / 2.0 + step * PI / 12.0
			var point: Vector2 = center + Vector2.from_angle(angle) * radius
			corners.append(point)
			uv.append((point - rect.position) / rect.size)
	canvas.draw_polygon(corners, PackedColorArray([Color.WHITE]), uv, WOOD)
	corners.append(corners[0])
	canvas.draw_polyline(corners, Color(0.85, 0.75, 0.48, 0.45), 2.0, true)
