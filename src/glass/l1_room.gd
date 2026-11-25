class_name L1Room
extends Control
## The painted room for the recruit screen. Gradients here are the room's shading and shadows.

var _table_shade: GradientTexture2D
var _glass: Dictionary[String, Texture2D] = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_table_shade = GradientTexture2D.new()
	_table_shade.fill = GradientTexture2D.FILL_RADIAL
	_table_shade.fill_from = Vector2(0.5, 0.5)
	_table_shade.fill_to = Vector2(1.0, 0.5)
	_table_shade.gradient = Gradient.new()
	_table_shade.gradient.offsets = PackedFloat32Array(
		[0.0, L1Layout.number("room.table.shade_clear"), 1.0]
	)
	_table_shade.gradient.colors = PackedColorArray(
		[Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.38)]
	)
	for file: String in [
		"l1z-quarry-slate.jpg",
		"l1z-quarry-moss.jpg",
		"l1z-headglass-slate.png",
		"l1z-headglass-moss.png",
	]:
		var glass: Image = _piece(file).get_image()
		glass.adjust_bcs(1.0, 1.0, L1Layout.number("column.glass.saturation"))
		_glass[file] = ImageTexture.create_from_image(glass)


func _draw() -> void:
	var middle: Rect2 = L1Layout.middle()
	_draw_middle(middle)
	_draw_column(0.0, "slate", true)
	_draw_column(middle.end.x, "moss", false)


func _draw_middle(middle: Rect2) -> void:
	var wall: Rect2 = middle
	wall.size.y = L1Layout.number("room.wall.h")
	var wall_tile: float = L1Layout.number("room.wall.tile")
	_tiles(_piece("l1r-wall.jpg"), wall, Vector2.ONE * wall_tile)
	_gradient(wall, Color(0.039, 0.051, 0.071, 0.55), Color(0.039, 0.051, 0.071, 0.38))
	var course: Rect2 = wall
	course.size.y = L1Layout.number("room.wall.foot")
	course.position.y = wall.end.y - course.size.y
	_gradient(course, Color("5a5f63"), Color("33373a"))

	var table: Rect2 = Rect2(
		wall.position.x, wall.end.y, wall.size.x, L1Layout.number("room.table.h")
	)
	_tiles(_piece("l1p-oak-top.jpg"), table, Vector2.ONE * L1Layout.number("room.table.tile"))
	var centre: Vector2 = (
		table.position
		+ (
			table.size
			* Vector2(L1Layout.number("room.table.shade_x"), L1Layout.number("room.table.shade_y"))
		)
	)
	var radii: Vector2 = (
		table.size
		* Vector2(L1Layout.number("room.table.shade_rx"), L1Layout.number("room.table.shade_ry"))
	)
	_crop(_table_shade, Rect2(centre - radii, 2.0 * radii), table)
	var wall_shadow: Rect2 = Rect2(
		table.position, Vector2(table.size.x, L1Layout.number("room.table.shadow"))
	)
	_gradient(wall_shadow, Color(0, 0, 0, 0.6), Color(0, 0, 0, 0))

	var edge: Rect2 = Rect2(
		table.position.x, table.end.y, table.size.x, L1Layout.number("room.edge.h")
	)
	var ledge: Rect2 = Rect2(edge.position.x, edge.end.y, edge.size.x, middle.end.y - edge.end.y)
	var brightness: float = L1Layout.number("room.ledge.brightness")
	draw_texture_rect(
		_piece("l1r-leather.jpg"), ledge, false, Color(brightness, brightness, brightness)
	)
	# The lip casts a soft shadow onto the leather.
	_gradient(
		Rect2(ledge.position, Vector2(ledge.size.x, 20)), Color(0, 0, 0, 0.6), Color(0, 0, 0, 0)
	)
	var front: Texture2D = _piece("l1p-table-edge.jpg")
	_tiles(front, edge, Vector2(edge.size.y * front.get_size().aspect(), edge.size.y))
	draw_texture_rect(_piece("l1z-board.png"), L1Layout.rect("shop.tablet"), false)


func _draw_column(x: float, hue: String, left: bool) -> void:
	var width: float = L1Layout.number("column.w")
	var head_h: float = L1Layout.number("column.head.h")
	var tile_h: float = L1Layout.number("column.tile.h")
	var height: float = L1Layout.stage_size().y
	var glass_zone: Rect2 = Rect2(x, head_h, width, height - head_h)
	var brightness: float = L1Layout.number("column.glass.brightness")
	var dim: Color = Color(brightness, brightness, brightness)
	_tiles(_glass["l1z-quarry-%s.jpg" % hue], glass_zone, Vector2(width, tile_h), dim)

	var pier: Texture2D = _piece("l1p-pier.jpg")
	var pier_size: Vector2 = Vector2(width, width / pier.get_size().aspect())
	var head: Rect2 = Rect2(x, 0, width, head_h)
	_crop(pier, Rect2(head.position, pier_size), head)
	draw_texture_rect(_glass["l1z-headglass-%s.png" % hue], head, false, dim)

	var strip: float = L1Layout.number("column.mullion.w")
	var shadow: float = L1Layout.number("column.mullion.shadow")
	var stone_tile: Rect2 = Rect2(glass_zone.position, pier_size)
	while stone_tile.position.y < height:
		_crop(pier, stone_tile, Rect2(x, head_h, strip, glass_zone.size.y))
		_crop(pier, stone_tile, Rect2(x + width - strip, head_h, strip, glass_zone.size.y))
		stone_tile.position.y += pier_size.y
	var clear: Color = Color(0, 0, 0, 0)
	var dark: Color = Color(0, 0, 0, 0.5)
	_gradient(Rect2(x + strip, head_h, shadow, glass_zone.size.y), dark, clear, true)
	_gradient(
		Rect2(x + width - strip - shadow, head_h, shadow, glass_zone.size.y), clear, dark, true
	)

	var bar: float = L1Layout.number("column.transom.h")
	var y: float = head_h - bar / 2.0
	while y < height:
		_gradient(Rect2(x, y + bar, width, 5), dark, clear)
		_gradient(Rect2(x, y, width, 0.6 * bar), Color("3a4043"), Color("15191a"))
		_gradient(Rect2(x, y + 0.6 * bar, width, 0.4 * bar), Color("15191a"), Color("0c0e0f"))
		y += tile_h
	var shade: float = width * L1Layout.number("column.shade.width")
	var inner: Color = Color(0, 0, 0, L1Layout.number("column.shade.alpha"))
	var shade_x: float = x + width - shade if left else x
	_gradient(
		Rect2(shade_x, 0, shade, height), clear if left else inner, inner if left else clear, true
	)


func _tiles(texture: Texture2D, area: Rect2, tile_size: Vector2, tint: Color = Color.WHITE) -> void:
	for y: int in ceili(area.size.y / tile_size.y):
		for x: int in ceili(area.size.x / tile_size.x):
			var tile: Rect2 = Rect2(area.position + Vector2(x, y) * tile_size, tile_size)
			_crop(texture, tile, area, tint)


func _crop(texture: Texture2D, tile: Rect2, area: Rect2, tint: Color = Color.WHITE) -> void:
	var visible_area: Rect2 = area.intersection(tile)
	var scale_to_source: Vector2 = texture.get_size() / tile.size
	var source: Rect2 = Rect2(
		(visible_area.position - tile.position) * scale_to_source,
		visible_area.size * scale_to_source
	)
	draw_texture_rect_region(texture, visible_area, source, tint)


func _gradient(area: Rect2, start: Color, end: Color, horizontal: bool = false) -> void:
	var corners: PackedVector2Array = GlassParts.rect_poly(area.size)
	for i: int in corners.size():
		corners[i] += area.position
	var colours: PackedColorArray = (
		PackedColorArray([start, end, end, start])
		if horizontal
		else PackedColorArray([start, start, end, end])
	)
	draw_polygon(corners, colours)


static func _piece(file: String) -> Texture2D:
	return GlassPieces.texture("l1/" + file)
