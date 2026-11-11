extends RefCounted
## Shared contour for drawing, picking, drop targets and floor motion.

const RATIO: float = 0.78
const POINT: float = 0.19
const ROUND: float = 0.07
const STEPS: int = 6


static func fit(box: Rect2) -> Rect2:
	var extent := Vector2(minf(box.size.x, box.size.y * RATIO), 0)
	extent.y = extent.x / RATIO
	return Rect2(box.position + (box.size - extent) / 2.0, extent)


static func polygon(rect: Rect2) -> PackedVector2Array:
	var vertices: PackedVector2Array = [
		Vector2(0.5, 0),
		Vector2(1, POINT),
		Vector2(1, 1 - POINT),
		Vector2(0.5, 1),
		Vector2(0, 1 - POINT),
		Vector2(0, POINT)
	]
	for i: int in vertices.size():
		vertices[i] = rect.position + vertices[i] * rect.size
	var points: PackedVector2Array = []
	var rounding: float = rect.size.y * ROUND
	for i: int in vertices.size():
		var corner: Vector2 = vertices[i]
		var before: Vector2 = corner.move_toward(vertices[posmod(i - 1, 6)], rounding)
		var after: Vector2 = corner.move_toward(vertices[(i + 1) % 6], rounding)
		for step: int in STEPS + 1:
			var t: float = float(step) / STEPS
			points.append(before.lerp(corner, t).lerp(corner.lerp(after, t), t))
	return points


static func closed(rect: Rect2) -> PackedVector2Array:
	var points: PackedVector2Array = polygon(rect)
	points.append(points[0])
	return points


static func contains(rect: Rect2, point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, polygon(rect))


static func perimeter_point(rect: Rect2, fraction: float) -> Vector2:
	var points: PackedVector2Array = closed(rect)
	var total: float = 0.0
	for i: int in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	var remaining: float = fposmod(fraction, 1.0) * total
	for i: int in points.size() - 1:
		var length: float = points[i].distance_to(points[i + 1])
		if remaining <= length:
			return points[i].lerp(points[i + 1], remaining / maxf(length, 0.001))
		remaining -= length
	return points[0]
