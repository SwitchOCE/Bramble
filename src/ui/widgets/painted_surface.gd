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
	edge.bg_color = Color("384638")
	edge.border_color = Color("65715a")
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
	# Grain is subordinate to the clearing: cool muted wood, warmed by the upper-right canopy.
	var light: PackedColorArray = []
	for point: Vector2 in corners:
		var at: Vector2 = (point - rect.position) / rect.size
		var warmth: float = at.x * (1.0 - at.y)
		light.append(Color("344b3e").lerp(Color("9c9a72"), warmth * 0.6))
	for index: int in light.size():
		light[index].a = 0.88
	canvas.draw_polygon(corners, light)
	corners.append(corners[0])
	canvas.draw_polyline(corners, Color(0.85, 0.82, 0.65, 0.24), 2.0, true)
