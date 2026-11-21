class_name KeywordLayout
extends RefCounted
## Keep the card's words and keyword reminders together. Move the whole group to avoid the
## hovered card and important controls; never send an individual reminder to a distant column.
const STAGE: Vector2 = Vector2(1920, 1080)


static func arrange(
	card: Rect2,
	words: Rect2,
	preferred: Vector2,
	source: Rect2,
	sizes: Array[Vector2],
	protected: Array[Rect2] = []
) -> Array[Vector2]:
	var obstacles: Array[Rect2] = [source]
	obstacles.append_array(protected)
	var height: float = 0.0
	for size: Vector2 in sizes:
		height += size.y
	var width: float = sizes[0].x if not sizes.is_empty() else 0.0
	var below: Vector2 = words.position + Vector2(0, words.size.y)
	var column: Rect2 = Rect2(below, Vector2(width, height))
	var shapes: Array[Rect2] = _shapes(card, words, column, true)
	var places: Array[Vector2] = _positions(shapes, preferred, obstacles)
	if not places.is_empty():
		return _result(places[0], below, sizes)
	if words.has_area() and not sizes.is_empty():
		# The full column cannot fit. Keep the reminder stack intact on the far side of Words.
		var card_x: float = (
			card.get_center().x if card.has_area() else source.get_center().x - preferred.x
		)
		var right: bool = words.get_center().x >= card_x
		var beside: Vector2 = Vector2(
			words.end.x if right else words.position.x - width, words.position.y
		)
		column.position = beside
		places = _positions(_shapes(card, words, column, false), preferred, obstacles)
		if not places.is_empty():
			return _result(places[0], beside, sizes)
	return []


static func _shapes(card: Rect2, words: Rect2, column: Rect2, below: bool) -> Array[Rect2]:
	var shapes: Array[Rect2] = []
	if card.has_area():
		shapes.append(card)
	if words.has_area():
		shapes.append(words.merge(column) if below and column.has_area() else words)
	if column.has_area() and (not below or not words.has_area()):
		shapes.append(column)
	return shapes


static func _result(origin: Vector2, start: Vector2, sizes: Array[Vector2]) -> Array[Vector2]:
	var result: Array[Vector2] = [origin]
	var at: Vector2 = origin + start
	for size: Vector2 in sizes:
		result.append(at)
		at.y += size.y
	return result


static func _positions(
	shapes: Array[Rect2], preferred: Vector2, obstacles: Array[Rect2]
) -> Array[Vector2]:
	if shapes.is_empty():
		return [preferred]
	var bounds: Rect2 = shapes[0]
	for shape: Rect2 in shapes:
		bounds = bounds.merge(shape)
	var gap: float = KeywordStyle.GAP
	if bounds.size.x > STAGE.x - 2.0 * gap or bounds.size.y > STAGE.y - 2.0 * gap:
		return []
	var low: Vector2 = Vector2.ONE * gap - bounds.position
	var high: Vector2 = STAGE - Vector2.ONE * gap - bounds.end
	var xs: Array[float] = [clampf(preferred.x, low.x, high.x), low.x, high.x]
	var ys: Array[float] = [clampf(preferred.y, low.y, high.y), low.y, high.y]
	for obstacle: Rect2 in obstacles:
		for shape: Rect2 in shapes:
			xs.append(obstacle.position.x - gap - shape.end.x)
			xs.append(obstacle.end.x + gap - shape.position.x)
			ys.append(obstacle.position.y - gap - shape.end.y)
			ys.append(obstacle.end.y + gap - shape.position.y)
	# Most hovers already fit. Otherwise prune by distance before testing rectangles, rather
	# than checking and sorting every candidate.
	var fitted: Vector2 = Vector2(xs[0], ys[0])
	if _clear(shapes, fitted, obstacles):
		return [fitted]
	var best: Vector2 = Vector2.ZERO
	var distance: float = INF
	for x: float in xs:
		var dx: float = absf(x - preferred.x)
		if x < low.x or x > high.x or dx > distance:
			continue
		for y: float in ys:
			var cost: float = dx + absf(y - preferred.y)
			if y < low.y or y > high.y or cost >= distance:
				continue
			var at: Vector2 = Vector2(x, y)
			if _clear(shapes, at, obstacles):
				best = at
				distance = cost
	var result: Array[Vector2] = []
	if distance < INF:
		result.append(best)
	return result


static func _clear(shapes: Array[Rect2], at: Vector2, obstacles: Array[Rect2]) -> bool:
	for shape: Rect2 in shapes:
		for obstacle: Rect2 in obstacles:
			if (
				obstacle.has_area()
				and Rect2(at + shape.position, shape.size).grow(KeywordStyle.GAP / 2.0).intersects(
					obstacle
				)
			):
				return false
	return true
