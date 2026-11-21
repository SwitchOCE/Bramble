class_name KeywordLayout
extends RefCounted
## Find the closest position for the card and Words pane that clears the hovered
## card, visible controls and the fixed keyword column.
const STAGE: Vector2 = Vector2(1920, 1080)


static func place(
	card: Rect2, words: Rect2, preferred: Vector2, obstacles: Array[Rect2]
) -> Vector2:
	var shapes: Array[Rect2] = [words]
	if card.has_area():
		shapes.append(card)
	var bounds: Rect2 = shapes[0]
	for shape: Rect2 in shapes:
		bounds = bounds.merge(shape)
	var gap: float = KeywordStyle.GAP
	if bounds.size.x > STAGE.x - 2.0 * gap or bounds.size.y > STAGE.y - 2.0 * gap:
		return preferred
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
		return fitted
	var best: Vector2 = fitted
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
	return best


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
