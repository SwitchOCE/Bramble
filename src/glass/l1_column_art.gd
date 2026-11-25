class_name L1ColumnArt
extends RefCounted
## Painted plates, roundels and text shared by the L1 recruit HUD.

const CREAM: Color = Color("fbf3dc")
const PLATE_INK: Color = Color("efe6d0")
const BOOK: String = (
	'<path d="M12 6.5C9.5 4.8 6.5 4.5 3.5 5v13c3-.5 6-.2 8.5 1.5'
	+ ' 2.5-1.7 5.5-2 8.5-1.5V5c-3-.5-6-.2-8.5 1.5zM12 6.5v13"/>'
)
const HISTORY: String = '<path d="M4.5 12a7.5 7.5 0 1 0 2.4-5.5M4 4.5v4h4M12 8v4.2l2.8 1.8"/>'
const COG: String = (
	'<circle cx="12" cy="12" r="3.2"/>'
	+ '<path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1'
	+ 'M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>'
)


static func area(rect: Rect2) -> Control:
	var node: Control = Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = rect.position
	node.size = rect.size
	return node


static func picture(texture: Texture2D, rect: Rect2) -> TextureRect:
	var node: TextureRect = TextureRect.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.position = rect.position
	node.size = rect.size
	node.texture = texture
	return node


static func piece(file: String, rect: Rect2) -> TextureRect:
	var node: TextureRect = picture(GlassPieces.texture("l1/" + file + ".png"), rect)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return node


static func text(words: String, px: float, ink: Color) -> GlassText:
	var label: GlassText = GlassText.new()
	label.words = words
	label.weight = 700
	label.font_px = px
	label.colour = ink
	return label.refresh()


static func fit_number(
	label: GlassText, words: String, px: float, center: Vector2, room: float
) -> void:
	label.words = words
	label.font_px = px
	var width: float = label.line_size().x
	# STAND-IN: long numbers keep their whole value by using a smaller font.
	if width > room:
		label.font_px = maxf(1.0, floorf(px * room / width))
	label.refresh()
	label.position = center - label.size / 2.0


static func shadow(y: float, blur: float, colour: String) -> Dictionary:
	return {"x": 0.0, "y": y, "blur": blur, "colour": colour, "spread": 0.0, "inset": false}


static func gradient(
	colours: PackedColorArray, stops: PackedFloat32Array, from: Vector2, to: Vector2
) -> GradientTexture2D:
	var ramp: Gradient = Gradient.new()
	ramp.colors = colours
	ramp.offsets = stops
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = ramp
	texture.fill_from = from
	texture.fill_to = to
	return texture


static func icon_texture(markup: String, tint: Color, px: int, stroke: float) -> Texture2D:
	return GlassPieces.svg_icon('<svg viewBox="0 0 24 24">' + markup + "</svg>", tint, px, stroke)


static func icon(markup: String, tint: Color, px: int, stroke: float) -> TextureRect:
	return picture(icon_texture(markup, tint, px, stroke), Rect2(Vector2.ZERO, Vector2.ONE * px))


static func roundel(key: String, markup: String) -> TextureRect:
	var rect: Rect2 = L1Layout.rect(key)
	var face: TextureRect = piece("l1p-roundel-slate", rect)
	var mark: TextureRect = icon(
		markup, CREAM, int(L1Layout.number(key + ".icon")), L1Layout.number(key + ".stroke")
	)
	mark.name = "Icon"
	mark.position = (face.size - mark.size) / 2.0
	face.add_child(mark)
	return face


static func set_roundel_hover(face: TextureRect, key: String, markup: String, hot: bool) -> void:
	var mark: TextureRect = face.get_node("Icon")
	mark.texture = icon_texture(
		markup, GlassUi.GO if hot else CREAM, int(mark.size.x), L1Layout.number(key + ".stroke")
	)


## An icon entry with the same release-to-open behaviour as GlassUi.button.
static func entry(key: String, markup: String, open: Callable) -> TextureRect:
	var face: TextureRect = roundel(key, markup)
	face.mouse_filter = Control.MOUSE_FILTER_STOP
	face.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	face.mouse_entered.connect(func() -> void: set_roundel_hover(face, key, markup, true))
	face.mouse_exited.connect(func() -> void: set_roundel_hover(face, key, markup, false))
	face.gui_input.connect(
		func(event: InputEvent) -> void:
			var click: InputEventMouseButton = event as InputEventMouseButton
			if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
				open.call()
	)
	return face
