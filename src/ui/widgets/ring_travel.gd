extends Control
## One travelling floor frame; no labels, static links or autonomous clock.

const DOTS: int = 26
const INK: Color = Color("30291f")
const GOLD: Color = Color("e9c75a")
const FLASH: Color = Color("fff5c5")

var from_rect: Rect2
var to_rect: Rect2
var reduced: bool = false
var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Exposes the actual drawn geometry to the motion tests and fixed-step evidence.
func dot_points() -> PackedVector2Array:
	var points: PackedVector2Array = []
	for dot: int in DOTS:
		var phase: float = progress
		if reduced:
			phase = 0.0 if progress < 0.5 else 1.0
		else:
			var stagger: float = (dot % 6) * 0.02
			phase = clampf((progress - stagger) / (1.0 - stagger), 0.0, 1.0)
		var rect: Rect2 = Rect2(
			from_rect.position.lerp(to_rect.position, phase),
			from_rect.size.lerp(to_rect.size, phase)
		)
		var along: float = (rect.size.x + rect.size.y) * 2.0 * dot / DOTS
		var point: Vector2 = rect.position
		if along < rect.size.x:
			point += Vector2(along, 0)
		elif along < rect.size.x + rect.size.y:
			point += Vector2(rect.size.x, along - rect.size.x)
		elif along < rect.size.x * 2.0 + rect.size.y:
			point += Vector2(rect.size.x * 2.0 + rect.size.y - along, rect.size.y)
		else:
			point += Vector2(0, (rect.size.x + rect.size.y) * 2.0 - along)
		if not reduced:
			point.y -= sin(phase * PI) * 28.0
		points.append(point)
	return points


func _draw() -> void:
	for point: Vector2 in dot_points():
		if reduced:
			# A stationary flash must differ from an existing pile's quiet dots.
			draw_circle(point, 9.0, Color(GOLD, 0.45))
			draw_circle(point, 6.5, FLASH)
		else:
			draw_circle(point, 5.0, INK)
			draw_circle(point, 3.5, GOLD)
