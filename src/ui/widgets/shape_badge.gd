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
