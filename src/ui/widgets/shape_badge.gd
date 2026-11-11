extends Control
## A number's backing, from the mock: the hexagon nut (Attack), the rosehip (Health), or a carved
## knot disc (tier). The number is a child Label named by the owner.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

## "nut", "rosehip", "rosehip_hurt", "rosehip_out", "knot", "knot_gold" or "knot_out".
var shape: String = "knot":
	set(value):
		shape = value
		queue_redraw()


func _init(badge_shape: String = "knot") -> void:
	shape = badge_shape
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## How wide a number may be and still sit inside the shape, at its middle height.
func inner_width() -> float:
	return size.x * (0.86 if shape.begins_with("knot") else 0.8)


func _draw() -> void:
	if size.x > size.y + 1.0 and (shape == "nut" or shape.begins_with("rosehip")):
		_draw_wide_stat()
		return
	match shape:
		"nut":
			draw_texture_rect(Icons.icon("atk", size.x), Rect2(Vector2.ZERO, size), false)
		"rosehip":
			draw_texture_rect(Icons.icon("hp", size.x), Rect2(Vector2.ZERO, size), false)
		"rosehip_hurt":
			draw_texture_rect(Icons.icon("hp_hurt", size.x), Rect2(Vector2.ZERO, size), false)
		"rosehip_out":
			draw_texture_rect(Icons.icon("hp_out", size.x), Rect2(Vector2.ZERO, size), false)
		"knot_gold":
			_knot(UiTheme.GILT, UiTheme.BRASS)
		"knot_out":
			_knot(UiTheme.LIME_SEAM, UiTheme.LIME_SEAM)
		_:
			_knot(UiTheme.OAK, UiTheme.CARVE)


func _knot(fill: Color, ring: Color) -> void:
	var centre: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) / 2.0
	draw_circle(centre, radius, UiTheme.INK)
	draw_circle(centre, radius - 4.5, ring)
	draw_circle(centre, radius - 10.0, fill)


## Wide numerals need a wide body, not a stretched round icon with its old narrow ink area.
func _draw_wide_stat() -> void:
	var weight: float = clampf(size.y * 0.04, 2.0, 3.0)
	var points: PackedVector2Array = []
	var fill: Color = Color("f2a43a")
	if shape == "nut":
		for at: Vector2 in [
			Vector2(0.5, 0.03),
			Vector2(0.97, 0.24),
			Vector2(0.97, 0.76),
			Vector2(0.5, 0.97),
			Vector2(0.03, 0.76),
			Vector2(0.03, 0.24)
		]:
			points.append(at * size)
	else:
		fill = UiTheme.HEALTH
		if shape == "rosehip_hurt":
			fill = Color("7a1c16")
		elif shape == "rosehip_out":
			fill = Color("8c7a62")
		var centre := Vector2(size.x / 2.0, size.y * 0.56)
		var radius := Vector2(size.x / 2.0 - 3.0, size.y * 0.39)
		for step: int in 48:
			var angle: float = TAU * step / 48.0
			points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, UiTheme.INK, weight, true)
	if shape == "nut":
		var inner: PackedVector2Array = []
		for point: Vector2 in points:
			inner.append(size / 2.0 + (point - size / 2.0) * 0.84)
		draw_polyline(inner, Color("b86e14"), weight * 0.5, true)
	else:
		var crown: PackedVector2Array = [
			Vector2(-7, 0),
			Vector2(-3, 2),
			Vector2(0, -4),
			Vector2(3, 2),
			Vector2(7, 0),
			Vector2(0, 8)
		]
		for i: int in crown.size():
			crown[i] += Vector2(size.x / 2.0, size.y * 0.11)
		draw_colored_polygon(crown, UiTheme.MOSS)
		crown.append(crown[0])
		draw_polyline(crown, UiTheme.INK, weight * 0.7, true)
