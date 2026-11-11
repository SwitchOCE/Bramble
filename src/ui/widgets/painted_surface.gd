extends RefCounted
## The world's painted stump under quiet ink contours and translucent colour washes.

enum Finish { BARK, STALL, MOSS, CLOTH, BAR }

const STUMP: Texture2D = preload("res://assets/ui/world/stump.jpg")

const INK := Color("17231e")
const KEY_LIGHT := Color("dfd2a4")


static func paint(
	canvas: CanvasItem, rect: Rect2, depth: float = 12.0, material: Finish = Finish.MOSS
) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var base: Color = _base_colour(material)
	var radius: float = minf(22.0, minf(rect.size.x, rect.size.y) / 2.0)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.025, 0.04, 0.03, 0.3)
	shadow.set_corner_radius_all(int(radius))
	shadow.shadow_color = Color(0.015, 0.025, 0.02, 0.28)
	shadow.shadow_size = 16
	shadow.shadow_offset = Vector2(0, 9)
	canvas.draw_style_box(shadow, Rect2(rect.position + Vector2(0, depth), rect.size))
	var edge := StyleBoxFlat.new()
	edge.bg_color = base.darkened(0.32)
	edge.border_color = INK
	edge.set_border_width_all(2)
	edge.set_corner_radius_all(int(radius))
	canvas.draw_style_box(edge, Rect2(rect.position + Vector2(0, depth), rect.size))
	var contour: PackedVector2Array = _contour(rect, radius)
	var colours: PackedColorArray = []
	for point: Vector2 in contour:
		var at: Vector2 = (point - rect.position) / rect.size
		var warmth: float = at.x * (1.0 - at.y)
		colours.append(base.darkened(0.08 * (1.0 - at.x)).lerp(KEY_LIGHT, warmth * 0.12))
	if material in [Finish.BARK, Finish.STALL, Finish.BAR, Finish.MOSS]:
		var uv: PackedVector2Array = []
		for point: Vector2 in contour:
			uv.append((point - rect.position) / rect.size)
		canvas.draw_polygon(contour, PackedColorArray([Color.WHITE]), uv, STUMP)
		for index: int in colours.size():
			colours[index].a = 0.90 if material == Finish.MOSS else 0.76
	canvas.draw_polygon(contour, colours)
	# Large feathered washes provide material variation without competing with the card art.
	_wash(canvas, rect, Vector2(0.68, 0.29), Vector2(0.29, 0.23), Color(KEY_LIGHT, 0.13))
	_wash(canvas, rect, Vector2(0.3, 0.68), Vector2(0.27, 0.24), Color(INK, 0.19))
	_material_marks(canvas, rect, material, base)
	contour.append(contour[0])
	canvas.draw_polyline(contour, Color(INK, 0.85), 2.5, true)
	# A broken cream lip catches the canopy light along the upper-right edge.
	var lip: PackedVector2Array = [
		rect.position + Vector2(rect.size.x * 0.56, 3),
		rect.position + Vector2(rect.size.x - radius, 3),
		rect.position + Vector2(rect.size.x - 4, radius),
		rect.position + Vector2(rect.size.x - 4, rect.size.y * 0.35),
	]
	if rect.size.x > radius * 4.0 and rect.size.y > radius * 4.0:
		canvas.draw_polyline(lip, Color(KEY_LIGHT, 0.24), 1.5, true)


static func _base_colour(material: Finish) -> Color:
	match material:
		Finish.BARK:
			return Color("4a4940")
		Finish.STALL:
			return Color("766747")
		Finish.CLOTH:
			return Color("404d54")
		Finish.BAR:
			return Color("51463b")
	return Color("344b3e")


static func _contour(rect: Rect2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for corner: int in 4:
		var center: Vector2 = (
			rect.position
			+ Vector2(
				rect.size.x - radius if corner in [0, 1] else radius,
				rect.size.y - radius if corner in [1, 2] else radius
			)
		)
		for step: int in 7:
			var angle: float = -PI / 2.0 + corner * PI / 2.0 + step * PI / 12.0
			points.append(center + Vector2.from_angle(angle) * radius)
		# Slightly uneven long edges keep the contour from reading as a UI bevel.
		var next_center: Vector2 = (
			rect.position
			+ Vector2(
				rect.size.x - radius if corner in [0, 3] else radius,
				rect.size.y - radius if corner in [0, 1] else radius
			)
		)
		var edge_start: Vector2 = points[-1]
		var edge_end: Vector2 = next_center + Vector2.from_angle(corner * PI / 2.0) * radius
		var inward: Vector2 = Vector2.from_angle(corner * PI / 2.0) * -1.0
		for step: int in range(1, 8):
			points.append(
				edge_start.lerp(edge_end, float(step) / 8.0) + inward * (1.5 if step % 2 else 3.0)
			)
	return points


## A translucent oval fading to clear at its perimeter; all points remain within the face.
static func _wash(
	canvas: CanvasItem, rect: Rect2, center: Vector2, radii: Vector2, tint: Color
) -> void:
	var middle: Vector2 = rect.position + rect.size * center
	var clear := Color(tint, 0.0)
	for step: int in 20:
		var angle: float = TAU * float(step) / 20.0
		var next_angle: float = TAU * float(step + 1) / 20.0
		var points: PackedVector2Array = [
			middle,
			middle + Vector2.from_angle(angle) * rect.size * radii,
			middle + Vector2.from_angle(next_angle) * rect.size * radii,
		]
		canvas.draw_polygon(points, PackedColorArray([tint, clear, clear]))


static func _material_marks(canvas: CanvasItem, rect: Rect2, material: Finish, base: Color) -> void:
	var inset: Rect2 = rect.grow(-minf(18.0, minf(rect.size.x, rect.size.y) * 0.15))
	match material:
		Finish.BARK:
			for index: int in 4:
				var x: float = inset.position.x + inset.size.x * (0.14 + index * 0.23)
				var stroke: PackedVector2Array = [
					Vector2(x, inset.position.y + inset.size.y * 0.12),
					Vector2(x - 5, inset.position.y + inset.size.y * 0.47),
					Vector2(x + 3, inset.end.y - inset.size.y * 0.12),
				]
				canvas.draw_polyline(stroke, Color(INK, 0.18), 2.0, true)
		Finish.STALL:
			var hem := Rect2(
				rect.position + Vector2(14, rect.size.y - 13), Vector2(rect.size.x - 28, 8)
			)
			canvas.draw_style_box(_hem(Color("685851")), hem)
			_wash(canvas, rect, Vector2(0.46, 0.5), Vector2(0.4, 0.3), Color("a58852", 0.12))
			for fraction: float in [0.34, 0.7]:
				var y: float = inset.position.y + inset.size.y * fraction
				canvas.draw_line(
					Vector2(inset.position.x, y), Vector2(inset.end.x, y + 2), Color(INK, 0.14), 1.5
				)
		Finish.MOSS:
			for index: int in 7:
				var at: float = 0.08 + index * 0.14
				_wash(canvas, rect, Vector2(at, 0.91), Vector2(0.06, 0.07), Color("73815a", 0.11))
			_wash(canvas, rect, Vector2(0.45, 0.55), Vector2(0.36, 0.33), Color("688264", 0.13))
		Finish.CLOTH:
			_wash(canvas, rect, Vector2(0.4, 0.46), Vector2(0.32, 0.29), Color("8b9b9d", 0.1))
			var stitches: int = mini(18, int(inset.size.x / 34.0))
			for index: int in stitches:
				var x: float = inset.position.x + (index + 0.5) * inset.size.x / stitches
				canvas.draw_line(
					Vector2(x, inset.end.y - 2),
					Vector2(x + 7, inset.end.y - 3),
					Color(KEY_LIGHT, 0.22),
					1.0,
					true
				)
		Finish.BAR:
			_wash(canvas, rect, Vector2(0.55, 0.4), Vector2(0.39, 0.2), Color("a18a66", 0.13))
			canvas.draw_line(
				Vector2(inset.position.x, inset.end.y),
				inset.end,
				Color(base.darkened(0.4), 0.36),
				2.0,
				true
			)


static func _hem(tint: Color) -> StyleBoxFlat:
	var hem := StyleBoxFlat.new()
	hem.bg_color = tint
	hem.set_corner_radius_all(3)
	return hem
