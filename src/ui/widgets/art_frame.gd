extends Control
## The portrait panel set into a tile (.wc-art): the art cropped to fill a rounded window, with an
## ink line round it. Drawn as a textured polygon, not with clip_children, so a screen with twenty
## tiles stays cheap on a phone. Works for any art shape; 1:1 portraits crop to the window from well
## above the middle, because every portrait keeps its face in the upper half.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

const HexShape := preload("res://src/ui/widgets/hex_shape.gd")

const CORNER_STEPS: int = 5
## Fractions of the source image: only contact-sheet crops that lose a face or defining prop.
const PORTRAIT_OFFSETS: Dictionary[String, Vector2] = {
	"old_isegrim": Vector2(-0.09, -0.04),
	"signor_ranocchio": Vector2(0.05, -0.12),
	"madame_bufo": Vector2(-0.02, -0.06),
	"gable_ratchet": Vector2(0.04, -0.06),
	"grizel": Vector2(0.07, -0.02),
	"grey_agnes": Vector2(-0.07, 0.0),
	"mrs_jay": Vector2(-0.08, 0.0),
	"sergeant_conkers": Vector2(0.07, 0.0),
	"pennyworth_snail": Vector2(0.06, -0.06),
}

var hexagonal: bool = false
var portrait_offset: Vector2 = Vector2.ZERO

var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
var radius: float = 15.0
var line: float = 4.0
## Rime and icicles over the portrait only: a frozen offer keeps its stats clear.
var frozen: bool = false:
	set(value):
		frozen = value
		frost_progress = 1.0 if value else 0.0
		queue_redraw()
## Animation wipes rime across the portrait; the underlying frozen flag remains exact.
var frost_progress: float = 0.0:
	set(value):
		frost_progress = clampf(value, 0.0, 1.0)
		queue_redraw()
## A second gold ring round the art (golden tiles).
var gilded: bool = false:
	set(value):
		gilded = value
		queue_redraw()
var fill: Color = UiTheme.CARVE


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	if gilded:
		_ring(Rect2(Vector2.ZERO, size).grow(9.0), UiTheme.INK, radius + 8.0)
		_ring(Rect2(Vector2.ZERO, size).grow(5.0), UiTheme.GILT, radius + 5.0)
	var points: PackedVector2Array = (
		HexShape.polygon(Rect2(Vector2.ZERO, size))
		if hexagonal
		else rounded_rect(Rect2(Vector2.ZERO, size), radius)
	)
	draw_colored_polygon(points, fill)
	if texture != null:
		texture_repeat = (
			CanvasItem.TEXTURE_REPEAT_DISABLED if hexagonal else CanvasItem.TEXTURE_REPEAT_ENABLED
		)
		var uvs: PackedVector2Array = _cover_uvs(points)
		draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, texture)
	if frost_progress > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(frost_progress, 1.0))
		_draw_frost(points)
		draw_set_transform(Vector2.ZERO)
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, UiTheme.INK, line, true)


func _ring(rect: Rect2, colour: Color, corner: float) -> void:
	draw_colored_polygon(
		HexShape.polygon(rect) if hexagonal else rounded_rect(rect, corner), colour
	)


func _draw_frost(points: PackedVector2Array) -> void:
	var tile: ImageTexture = Icons.tile("rime")
	var uvs: PackedVector2Array = []
	var tile_size: Vector2 = Vector2(tile.get_size())
	for point: Vector2 in points:
		uvs.append(point / tile_size)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, tile)
	# Crystals follow the contour, so nothing spills through the cut corners.
	for index: int in 12:
		var at: Vector2 = HexShape.perimeter_point(Rect2(Vector2.ZERO, size).grow(-3), index / 12.0)
		if not hexagonal:
			at = Vector2(size.x * index / 12.0, 3)
		var tip: Vector2 = at.move_toward(size / 2.0, 12.0 + (index % 3) * 4.0)
		draw_line(at, tip, Color.WHITE, 3.0, true)


## Cover-crop UVs: the texture fills the window; the crop sits a little above centre (the mock's
## background-position: center 30%).
func _cover_uvs(points: PackedVector2Array) -> PackedVector2Array:
	var art: Vector2 = texture.get_size()
	var fit: float = maxf(size.x / art.x, size.y / art.y) * (1.06 if hexagonal else 1.0)
	var shown: Vector2 = size / fit
	var origin: Vector2 = Vector2((art.x - shown.x) * 0.5, (art.y - shown.y) * 0.2)
	if hexagonal:
		origin.y = clampf(art.y * 0.30 - shown.y * 0.36, 0.0, art.y - shown.y)
		origin += portrait_offset * art
		origin = origin.clamp(Vector2(0.0, -art.y * 0.12), art - shown)
	var uvs: PackedVector2Array = []
	for point: Vector2 in points:
		uvs.append((origin + point / fit) / art)
	return uvs


## A rounded rectangle's outline, clockwise from the top left.
static func rounded_rect(rect: Rect2, corner: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	var r: float = minf(corner, minf(rect.size.x, rect.size.y) / 2.0)
	var centres: Array[Vector2] = [
		rect.position + Vector2(r, r),
		Vector2(rect.end.x - r, rect.position.y + r),
		rect.end - Vector2(r, r),
		Vector2(rect.position.x + r, rect.end.y - r),
	]
	for i: int in 4:
		var start: float = PI + PI / 2.0 * i
		for step: int in CORNER_STEPS + 1:
			var angle: float = start + PI / 2.0 * step / CORNER_STEPS
			points.append(centres[i] + Vector2(cos(angle), sin(angle)) * r)
	return points
