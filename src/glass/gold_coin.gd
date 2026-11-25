class_name GoldCoin
extends Control
## Gold, with a stamped number for costs and no number for the balance icon.
## Candidate drawings and typography stay together for the owner's morning comparison.

const SELECTED: int = 0
const INK: Color = Color("352009")
const POOR_INK: Color = Color("ffb4a2")
## An Active's cost you can't afford: a strong red on the grey coin, with a pale rim to the digits.
const SHORT_INK: Color = Color("b01e14")
const SHORT_RIM: Color = Color("f6eee0")
const PALETTES: Array[Array] = [
	["fff8bf", "fbd14a", "c27b12", "ffe9a0", "eebc39", "a56a12"],
	["e5e1d5", "a8a59b", "66645e", "bcb8ac", "8f8c82", "59574f"],
]

static var _textures: Dictionary = {}
static var _pewter: Texture2D

var amount: int = -1
var diameter: float = 44.0
var poor: bool = false
var candidate: int = SELECTED
var painted: bool = false
## A reward coin shows what the balance is gaining.
var show_plus: bool = false
## Cap-height figures, so a 0 reads as zero: an Active's cost (a 0 is common there).
var lining: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	size = Vector2.ONE * diameter


func _draw() -> void:
	if painted:
		_draw_painted()
		return
	draw_circle(Vector2(diameter * 0.5, diameter * 0.56), diameter * 0.47, Color(0, 0, 0, 0.5))
	draw_texture_rect(texture(candidate, poor), Rect2(Vector2.ZERO, Vector2.ONE * diameter), false)
	if amount < 0:
		var stamp: PackedVector2Array = PackedVector2Array()
		for i: int in 8:
			var radius: float = diameter * (0.23 if i % 2 == 0 else 0.10)
			stamp.append(Vector2.ONE * diameter * 0.5 + Vector2.from_angle(i * PI / 4.0) * radius)
		draw_colored_polygon(stamp, INK)
		return
	var words: String = ("+" if show_plus else "") + str(amount)
	var font: Font = (
		GlassPieces.body_font(700, lining)
		if candidate == 0
		else GlassPieces.display_font(900, true)
	)
	var px: int = roundi(diameter * (0.62 if candidate == 0 else 0.67))
	var width: float = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var room: float = diameter * 0.65
	if width > room:
		px = maxi(8, floori(px * room / width))
		width = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var baseline: float = diameter * 0.5 + (font.get_ascent(px) - font.get_descent(px)) * 0.5
	baseline += diameter * (0.025 if candidate == 2 else 0.0)
	var at: Vector2 = Vector2((diameter - width) * 0.5, baseline)
	var rim: Color = Color("3b2820") if poor else Color("ffdf76")
	var ink: Color = POOR_INK if poor else INK
	if poor and lining:
		rim = SHORT_RIM
		ink = SHORT_INK
	draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 2, rim)
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)


static func painted_cost(value: int, side: float, unaffordable: bool) -> GoldCoin:
	var coin: GoldCoin = make(value, side, unaffordable)
	coin.painted = true
	return coin


func _draw_painted() -> void:
	var centre: Vector2 = Vector2.ONE * diameter / 2.0
	var shadow: Vector2 = Vector2(0, L1Layout.number("shop.coin.shadow_y"))
	draw_circle(centre + shadow, diameter / 2.0, Color(0, 0, 0, 0.6), true, -1.0, true)
	draw_texture_rect(_painted_texture(poor), Rect2(Vector2.ZERO, Vector2.ONE * diameter), false)
	var font: Font = GlassPieces.body_font(700, true)
	var words: String = str(amount)
	var px: int = roundi(diameter * L1Layout.number("shop.coin.font_share"))
	var width: float = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var room: float = diameter * 0.65
	if width > room:
		px = maxi(8, floori(px * room / width))
		width = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var baseline: float = centre.y + (font.get_ascent(px) - font.get_descent(px)) / 2.0
	baseline -= diameter * L1Layout.number("shop.coin.rise")
	var at: Vector2 = Vector2(centre.x - width / 2.0, baseline)
	if not poor:
		draw_string(
			font, at + Vector2.DOWN, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color("ffe9a8")
		)
	var ink: Color = Color("1d1f20") if poor else Color("5a3606")
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)


static func _painted_texture(dull: bool) -> Texture2D:
	var gold: Texture2D = GlassPieces.texture("l1/l1p-coin.png")
	if not dull:
		return gold
	if _pewter == null:
		var image: Image = gold.get_image()
		# All shop coins are 46 px or smaller at stage scale.
		image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		var brightness: float = L1Layout.number("shop.coin.poor_brightness")
		var contrast: float = L1Layout.number("shop.coin.poor_contrast")
		for y: int in image.get_height():
			for x: int in image.get_width():
				var pixel: Color = image.get_pixel(x, y)
				var grey: float = (pixel.get_luminance() * brightness - 0.5) * contrast + 0.5
				image.set_pixel(x, y, Color(grey, grey, grey, pixel.a))
		_pewter = ImageTexture.create_from_image(image)
	return _pewter


## `cost`: an Active's cost (cap-height figures).
static func make(
	value: int, side: float = 44.0, unaffordable: bool = false, cost: bool = false
) -> GoldCoin:
	var coin: GoldCoin = GoldCoin.new()
	coin.lining = cost
	coin.name = "PriceCoin"
	coin.amount = value
	coin.diameter = side
	coin.size = Vector2.ONE * side
	coin.poor = unaffordable
	return coin


static func texture(style: int = SELECTED, dull: bool = false) -> Texture2D:
	var key: String = "%d/%s" % [style, dull]
	if not _textures.has(key):
		var image: Image = Image.new()
		var error: Error = image.load_svg_from_string(_svg(style, dull), 2.0)
		assert(error == OK, "gold coin SVG did not load")
		image.generate_mipmaps()
		_textures[key] = ImageTexture.create_from_image(image)
	var result: Texture2D = _textures[key]
	return result


static func _svg(style: int, dull: bool) -> String:
	var colours: Array = PALETTES[1 if dull else 0]
	var detail: String = ""
	var count: int = 24 if style == 0 else 12
	for i: int in count:
		var angle: float = TAU * i / count
		var p: Vector2 = Vector2(32, 32) + Vector2.from_angle(angle) * 26.0
		var q: Vector2 = (
			Vector2(32, 32) + Vector2.from_angle(angle) * (24.0 if style == 0 else 22.5)
		)
		detail += '<path d="M%.2f %.2f L%.2f %.2f"/>' % [p.x, p.y, q.x, q.y]
	var face: String = '<circle cx="32" cy="32" r="22"'
	if style == 1:
		face = '<path d="M32 10 L48 16 L54 32 L48 48 L32 54 L16 48 L10 32 L16 16 Z"'
	return (
		(
			(
				'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
				+ '<defs><radialGradient id="rim" cx="32%%" cy="24%%" r="80%%">'
				+ '<stop stop-color="#%s"/><stop offset=".42" stop-color="#%s"/>'
				+ '<stop offset="1" stop-color="#%s"/></radialGradient>'
				+ '<radialGradient id="face" cx="36%%" cy="28%%" r="82%%">'
				+ '<stop stop-color="#%s"/><stop offset=".7" stop-color="#%s"/>'
				+ '<stop offset="1" stop-color="#%s"/></radialGradient></defs>'
			)
			% Array(colours)
		)
		+ (
			'<circle cx="32" cy="32" r="30" fill="url(#rim)" stroke="#21180e" stroke-width="3"/>'
			+ '<circle cx="32" cy="32" r="27.5" fill="none" stroke="#fff2b0" stroke-width="1"/>'
			+ '<g stroke="#875313" stroke-width="1.4">%s</g>' % detail
			+ face
			+ ' fill="url(#face)" stroke="#8c5711" stroke-width="1.5"/>'
			+ '<path d="M12 23 A22 22 0 0 1 25 11" fill="none" stroke="#fff9d9" '
			+ 'stroke-width="2" stroke-linecap="round"/>'
			+ '<path d="M47 47 L50 43 L53 47 L50 51 Z" fill="#fff6c2"/></svg>'
		)
	)
