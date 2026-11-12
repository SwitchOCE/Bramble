extends Control
## A wooden surface drawn in code (.wc-plaque, .wk-hit, .wk-log): a carved edge below, a face with
## burned grain, an ink outline, and optional nails. OAK is the plaque, PAPER a pinned note, BIRCH a
## smooth pale board, PURPLE the "this hit" panel, OUT no shadow and a pale face.

enum Kind { OAK, PAPER, BIRCH, PURPLE, PAINTED }

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Surface := preload("res://src/ui/widgets/painted_surface.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

var kind: Kind = Kind.OAK:
	set(value):
		kind = value
		queue_redraw()
var radius: int = 24
var border: int = 7
var edge: float = 12.0
var nails: bool = false:
	set(value):
		nails = value
		queue_redraw()


func _init(panel_kind: Kind = Kind.OAK) -> void:
	kind = panel_kind
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)


func face_colour() -> Color:
	match kind:
		Kind.PAPER, Kind.BIRCH:
			return UiTheme.BIRCH
		Kind.PURPLE:
			return UiTheme.NIGHTSHADE
	return UiTheme.OAK


func edge_colour() -> Color:
	match kind:
		Kind.PURPLE:
			return UiTheme.NIGHTSHADE_DARK
	return UiTheme.CARVE


func _draw() -> void:
	if kind == Kind.PAINTED:
		Surface.paint(self, Rect2(Vector2.ZERO, size), edge)
		return
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	if edge > 0.0:
		var under: Rect2 = Rect2(Vector2(0, edge), size)
		draw_style_box(_box(edge_colour(), UiTheme.INK, border), under)
	draw_style_box(_box(face_colour(), Color.TRANSPARENT, 0), rect)
	if kind == Kind.OAK:
		var inset: float = float(radius) * 0.4
		var grain: Rect2 = Rect2(0, inset, size.x, size.y - inset * 2.0).grow_individual(
			-2, 0, -2, 0
		)
		draw_texture_rect(Icons.tile("oak"), grain, true)
	draw_style_box(_box(Color.TRANSPARENT, UiTheme.INK, border), rect)
	if nails:
		for x: float in [24.0, size.x - 24.0]:
			draw_circle(Vector2(x, 26), 11.0, UiTheme.INK)
			draw_circle(Vector2(x, 26), 8.0, Color("6e6a63"))


func _box(fill: Color, line: Color, width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = line
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.corner_detail = 6
	return box
