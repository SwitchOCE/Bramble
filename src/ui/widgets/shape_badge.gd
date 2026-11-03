extends Control
## A filled, outlined shape drawn in code: the card's stat, tier and cost badges and the name
## ribbon. Plain uses circles; Folk Print uses a shield (Attack), a heart (Health), an 8-point
## star (tier) and a swallowtail ribbon (name). Children (the number) sit on top.

var shape: String = "circle"
var fill: Color = Color.WHITE
var border: Color = Color.BLACK
var border_width: float = 3.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_look(
	badge_shape: String, fill_colour: Color, border_colour: Color, width: float = 3.0
) -> void:
	shape = badge_shape
	fill = fill_colour
	border = border_colour
	border_width = width
	queue_redraw()


func _draw() -> void:
	if shape == "circle":
		# The round badge as it was before looks were data: a StyleBoxFlat ring inset in the box.
		draw_style_box(circle_box(), Rect2(Vector2.ZERO, size))
		return
	var points: PackedVector2Array = outline(shape, size)
	if points.size() < 3:
		return
	draw_colored_polygon(points, fill)
	if border_width > 0.0 and border.a > 0.0:
		var closed: PackedVector2Array = points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, border, border_width, true)


## How wide a number may be and still sit inside the shape, at its middle height.
func inner_width() -> float:
	var share: float = 0.82
	match shape:
		"shield":
			share = 0.78
		"heart":
			share = 0.6
		"star":
			share = 0.56
	return size.x * share


## The round badge's face: fill, and a border of `border_width` drawn inside the box.
func circle_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(int(border_width))
	box.set_corner_radius_all(999)
	return box


## The shape's outline in a box of `box` size, clockwise from the top left.
static func outline(badge_shape: String, box: Vector2) -> PackedVector2Array:
	var w: float = box.x
	var h: float = box.y
	var points: PackedVector2Array = PackedVector2Array()
	match badge_shape:
		"shield":
			# A heater shield: a slightly raised top edge, straight sides, curved to a point.
			points.append(Vector2(0.06 * w, 0.1 * h))
			points.append(Vector2(0.5 * w, 0.02 * h))
			points.append(Vector2(0.94 * w, 0.1 * h))
			points.append(Vector2(0.94 * w, 0.45 * h))
			for i: int in range(1, 12):
				var t: float = float(i) / 12.0
				var a: Vector2 = Vector2(0.94 * w, 0.45 * h)
				var b: Vector2 = Vector2(0.86 * w, 0.82 * h)
				var c: Vector2 = Vector2(0.5 * w, 0.98 * h)
				points.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
			points.append(Vector2(0.5 * w, 0.98 * h))
			for i: int in range(11, 0, -1):
				var t: float = float(i) / 12.0
				var a: Vector2 = Vector2(0.06 * w, 0.45 * h)
				var b: Vector2 = Vector2(0.14 * w, 0.82 * h)
				var c: Vector2 = Vector2(0.5 * w, 0.98 * h)
				points.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
			points.append(Vector2(0.06 * w, 0.45 * h))
		"heart":
			# The classic parametric heart, fitted to the box.
			for i: int in 48:
				var t: float = TAU * float(i) / 48.0
				var x: float = 16.0 * pow(sin(t), 3)
				var y: float = 13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t)
				points.append(Vector2(0.5 * w + x / 34.0 * w, 0.42 * h - y / 31.0 * h))
		"star":
			for i: int in 16:
				var angle: float = -PI / 2.0 + TAU * float(i) / 16.0
				var r: float = 0.5 if i % 2 == 0 else 0.36
				points.append(Vector2(0.5 * w + cos(angle) * r * w, 0.5 * h + sin(angle) * r * h))
		"ribbon":
			var notch: float = minf(h * 0.45, w * 0.2)
			points.append(Vector2(0, 0))
			points.append(Vector2(w, 0))
			points.append(Vector2(w - notch, h / 2.0))
			points.append(Vector2(w, h))
			points.append(Vector2(0, h))
			points.append(Vector2(notch, h / 2.0))
		_:
			for i: int in 40:
				var angle: float = TAU * float(i) / 40.0
				points.append(
					Vector2(0.5 * w + cos(angle) * 0.5 * w, 0.5 * h + sin(angle) * 0.5 * h)
				)
	return points
