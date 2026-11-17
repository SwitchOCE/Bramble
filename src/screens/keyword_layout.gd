class_name KeywordLayout
extends RefCounted
## Place the primary tooltip and separate reminder panes in free stage space. Coordinates are
## stage units, so the same layout scales to laptop and desktop windows.
const STAGE: Vector2 = Vector2(1920, 1080)


static func arrange(
	primary_size: Vector2, preferred: Vector2, source: Rect2, sizes: Array[Vector2]
) -> Array[Vector2]:
	var mains: Array[Vector2] = _positions(primary_size, preferred, [source])
	for main: Vector2 in mains:
		var occupied: Array[Rect2] = [source, Rect2(main, primary_size)]
		var result: Array[Vector2] = [main]
		var next: Vector2 = main + Vector2(primary_size.x + KeywordStyle.GAP, 0)
		for size: Vector2 in sizes:
			var places: Array[Vector2] = _positions(size, next, occupied)
			if places.is_empty():
				break
			var at: Vector2 = places[0]
			result.append(at)
			occupied.append(Rect2(at, size))
			next = at + Vector2(0, size.y + KeywordStyle.GAP)
		if result.size() == sizes.size() + 1:
			return result
	# A primary without an enlarged copy (icon hover) has no occupied primary rectangle.
	# The second pass can use its preferred point as the first reminder's anchor.
	if primary_size == Vector2.ZERO:
		var occupied: Array[Rect2] = [source]
		var result: Array[Vector2] = [preferred]
		for size: Vector2 in sizes:
			var places: Array[Vector2] = _positions(size, preferred, occupied)
			if places.is_empty():
				return []
			result.append(places[0])
			occupied.append(Rect2(places[0], size))
		return result
	# Prefer a visible failure over silently overlapping a card. Callers can retry after a resize.
	return []


static func _positions(size: Vector2, preferred: Vector2, occupied: Array[Rect2]) -> Array[Vector2]:
	var gap: float = KeywordStyle.GAP
	var xs: Array[float] = [
		clampf(preferred.x, gap, STAGE.x - gap - size.x), gap, STAGE.x - gap - size.x
	]
	var ys: Array[float] = [
		clampf(preferred.y, gap, STAGE.y - gap - size.y), gap, STAGE.y - gap - size.y
	]
	for box: Rect2 in occupied:
		xs.append(box.position.x - gap - size.x)
		xs.append(box.end.x + gap)
		ys.append(box.position.y - gap - size.y)
		ys.append(box.end.y + gap)
	var result: Array[Vector2] = []
	for x: float in xs:
		for y: float in ys:
			var box: Rect2 = Rect2(Vector2(x, y), size)
			if x < gap or y < gap or box.end.x > STAGE.x - gap or box.end.y > STAGE.y - gap:
				continue
			var fits: bool = true
			for other: Rect2 in occupied:
				if other.has_area() and box.grow(gap / 2.0).intersects(other):
					fits = false
					break
			if fits:
				result.append(box.position)
	result.sort_custom(
		func(a: Vector2, b: Vector2) -> bool:
			return (
				absf(a.x - preferred.x) + absf(a.y - preferred.y)
				< absf(b.x - preferred.x) + absf(b.y - preferred.y)
			)
	)
	return result
