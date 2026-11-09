extends Control
## Wordless recruit state, drawn inside the portrait: the ladle, Soup's pot and a held meal.
## The Elder landing pulse uses the same marks; explanations stay in the reader.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

var ladle: bool = false
var soup: bool = false
var meal: Texture2D
var landing: float = 0.0:
	set(value):
		landing = value
		queue_redraw()
var _pulse: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func show_state(view: Dictionary) -> void:
	ladle = Data.b(view, "ooze_ladle")
	var bonus: Vector2i = view.get("ooze_soup_bonus", Vector2i.ZERO)
	soup = bonus != Vector2i.ZERO
	var held: Array = Data.a(view, "held")
	meal = null
	if view.has("ooze_ladle") and Data.a(view, "tribes").has("Oozes") and not held.is_empty():
		var inside: Dictionary = Data.entry(held, held.size() - 1)
		meal = UiTheme.portrait_for(Data.s(inside, "def_id"), Data.a(inside, "tribes"))
	visible = ladle or soup or meal != null or landing > 0.0
	queue_redraw()


func share_landed() -> void:
	if _pulse != null and _pulse.is_valid():
		_pulse.kill()
	visible = true
	landing = 1.0
	_pulse = create_tween()
	_pulse.tween_property(self, "landing", 0.0, 0.65).set_trans(Tween.TRANS_QUAD)


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	var radius: float = clampf(minf(size.x, size.y) * 0.13, 11.0, 18.0)
	if meal != null:
		var centre: Vector2 = size * Vector2(0.5, 0.47)
		draw_circle(centre, radius + 6.0, Color(UiTheme.FROST, 0.6))
		draw_texture_rect(
			meal, Rect2(centre - Vector2.ONE * radius, Vector2.ONE * radius * 2), false
		)
		draw_arc(centre, radius + 6.0, 0.0, TAU, 24, UiTheme.CREAM, 2.5, true)
	if ladle:
		_ladle(Vector2(size.x - radius - 8.0, radius + 8.0), radius)
	if soup:
		_pot(Vector2(radius + 9.0, size.y * 0.55), radius)
	if landing > 0.0:
		var centre: Vector2 = size * 0.5
		var reach: float = minf(size.x, size.y) * (0.18 + (1.0 - landing) * 0.24)
		draw_arc(centre, reach, 0.0, TAU, 32, Color(UiTheme.ACORN, landing), 5.0, true)
		for index: int in 4:
			var angle: float = TAU * index / 4.0 + PI / 4.0
			var point: Vector2 = centre + Vector2.from_angle(angle) * reach
			draw_circle(point, 3.0 * landing, Color(UiTheme.CREAM, landing))


func _ladle(centre: Vector2, radius: float) -> void:
	draw_circle(centre, radius, Color(UiTheme.INK, 0.8))
	var bowl: Vector2 = centre + Vector2(-radius * 0.22, radius * 0.26)
	draw_line(centre + Vector2(radius * 0.42, -radius * 0.65), bowl, UiTheme.ACORN, 4.0, true)
	draw_arc(bowl, radius * 0.42, 0.0, PI, 12, UiTheme.CREAM, 4.0, true)


func _pot(centre: Vector2, radius: float) -> void:
	draw_circle(centre, radius, Color(UiTheme.INK, 0.8))
	draw_arc(centre, radius * 0.55, 0.0, PI, 16, UiTheme.CREAM, 4.0, true)
	draw_line(
		centre + Vector2(-radius * 0.6, 0),
		centre + Vector2(radius * 0.6, 0),
		UiTheme.CREAM,
		3.0,
		true
	)
	for offset: float in [-0.25, 0.25]:
		var steam: Vector2 = centre + Vector2(radius * offset, -radius * 0.25)
		draw_line(steam, steam + Vector2(2.0, -radius * 0.4), UiTheme.FROST, 2.0, true)
