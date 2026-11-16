class_name GlassPieces
extends RefCounted
## The glass mock-ups' own pieces, as tools/glass/pull_mockups.py copies them into assets/glass:
## the six tier frames, the card data (each tier's Attack and Health discs, the art polygon), the
## layout numbers read out of the mock-ups' CSS and JS, and the fonts the pages use.
## layout.json says, for every number, which mock-up file and line it came from.

const ROOT: String = "res://assets/glass/"
const TIERS: int = 6

static var _layout: Dictionary = {}
static var _card_data: Dictionary = {}
static var _fonts: Dictionary = {}
## Loaded textures are kept here: a texture drawn from a local variable is freed before the frame
## is rendered, and draws as plain white.
static var _textures: Dictionary = {}


## The frame texture for a tier, 1 to 6.
static func frame(tier: int) -> Texture2D:
	assert(tier >= 1 and tier <= TIERS, "tier %d is not 1 to %d" % [tier, TIERS])
	return _texture(ROOT + "frames/tier%d.webp" % tier)


## Card art by the mock-ups' name for it, such as "badger-1".
static func art(art_name: String) -> Texture2D:
	return null if art_name == "" else _texture(ROOT + "art/%s.jpg" % art_name)


## Any picture under assets/glass by its path there, such as "ui/pane.jpg".
static func texture(rel: String) -> Texture2D:
	return _texture(ROOT + rel)


## A hero portrait by the mock-ups' name for it, such as "dame_farthing".
static func portrait(portrait_name: String) -> Texture2D:
	return null if portrait_name == "" else _texture(ROOT + "portraits/%s.jpg" % portrait_name)


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	var tex: Texture2D = _textures[path]
	return tex


static func card_data() -> Dictionary:
	if _card_data.is_empty():
		_card_data = _read_json("card_data.json")
	return _card_data


## The source record: which mock-ups commit the pieces came from, and each file's hash.
static func source() -> Dictionary:
	return _read_json("source.json")


static func layout() -> Dictionary:
	if _layout.is_empty():
		_layout = _read_json("layout.json")
	return _layout


static func has_value(key: String) -> bool:
	return layout().has(key)


## The raw value for a layout key, such as "card.num.one_digit_scale".
static func value(key: String) -> Variant:
	assert(layout().has(key), "layout.json has no %s" % key)
	var entry: Dictionary = layout()[key]
	return entry.get("value")


## A pulled CSS declaration, such as rule("stage", ".btn", "height"), as css_values.py reads it.
static func rule(file: String, selector: String, property: String) -> Variant:
	return value("css/%s/%s/%s" % [file, selector, property])


## The same, or fallback when the rule does not set that property.
static func rule_or(file: String, selector: String, property: String, fallback: Variant) -> Variant:
	var key: String = "css/%s/%s/%s" % [file, selector, property]
	return value(key) if has_value(key) else fallback


static func rule_number(file: String, selector: String, property: String) -> float:
	var raw: float = rule(file, selector, property)
	return raw


static func rule_colour(file: String, selector: String, property: String) -> Color:
	return Color.html(str(rule(file, selector, property)))


## A pulled CSS font shorthand: {weight, size, line_height, family}.
static func rule_font(file: String, selector: String) -> Dictionary:
	var raw: Dictionary = rule(file, selector, "font")
	return raw


## recruit.html's geom() for the chosen version: every size on the recruit screen follows from it.
static func recruit_geom() -> Dictionary:
	var raw: Dictionary = value("stage.recruit.geom")
	return raw


## fight.html's geom(): both boards, the transom between them and the sill.
static func fight_geom() -> Dictionary:
	var raw: Dictionary = value("stage.fight.geom")
	return raw


## A button icon (stage.js ICON) drawn at px pixels with the given stroke colour and width.
static func icon(icon_name: String, tint: Color, px: int, stroke: float) -> Texture2D:
	var key: String = "icon/%s/%s/%d/%s" % [icon_name, tint.to_html(), px, stroke]
	if not _textures.has(key):
		var svg: String = text("stage.icon." + icon_name)
		var attrs: String = (
			(
				'<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="none" '
				+ 'stroke="#%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" '
			)
			% [tint.to_html(false), stroke]
		)
		svg = svg.replace("<svg ", attrs)
		var image: Image = Image.new()
		var err: Error = image.load_svg_from_string(svg, float(px) / 24.0)
		assert(err == OK, "icon %s does not load" % icon_name)
		image.generate_mipmaps()
		_textures[key] = ImageTexture.create_from_image(image)
	var tex: Texture2D = _textures[key]
	return tex


## A JSON number or flag as a float, whether JSON gave it as int, float or bool.
static func as_float(v: Variant) -> float:
	if v is int:
		var i: int = v
		return i
	if v is bool:
		return 1.0 if v else 0.0
	var f: float = v
	return f


static func as_int(v: Variant) -> int:
	return roundi(as_float(v))


static func as_bool(v: Variant) -> bool:
	if v is bool:
		var b: bool = v
		return b
	return as_float(v) != 0.0


static func number(key: String) -> float:
	var raw: float = value(key)
	return raw


static func array(key: String) -> Array:
	var raw: Array = value(key)
	return raw


static func text(key: String) -> String:
	return str(value(key))


static func colour(key: String) -> Color:
	return css_colour(text(key))


## A CSS colour: "#rrggbb" or "#rgb", or the inside of rgba(), such as "255,240,200,.7".
static func css_colour(css: String) -> Color:
	if css.begins_with("#"):
		return Color.html(css)
	var parts: PackedStringArray = css.split(",")
	assert(parts.size() == 4, "not a colour: %s" % css)
	return Color(
		parts[0].to_float() / 255.0,
		parts[1].to_float() / 255.0,
		parts[2].to_float() / 255.0,
		parts[3].to_float()
	)


## A tier's disc for "attack" or "health": centre in card units (x, y) and radius (z).
static func disc(tier: int, which: String) -> Vector3:
	var tiers: Dictionary = card_data().get("roundels", {})
	var discs: Dictionary = tiers.get("tier%d" % tier, {})
	var entry: Dictionary = discs.get(which, {})
	var centre: Array = entry.get("centre_units", [0.0, 0.0])
	var x: float = centre[0]
	var y: float = centre[1]
	var radius: float = entry.get("radius_units", 0.0)
	return Vector3(x, y, radius)


## Card space: every position on a card is in these units (card.js U: 560 wide, 1000 tall).
static func card_units() -> Vector2:
	return Vector2(number("card.units.w"), number("card.units.h"))


## The art window: the polygon the art is clipped to, in card units.
static func art_polygon() -> PackedVector2Array:
	var raw: Array = card_data().get("art", [])
	return _points(raw)


## A line of text as a browser lays it out with line-height: normal, for "display" or "body" at
## a pixel size: ascent (x), descent (y) and line gap (z), each rounded to whole pixels as
## browsers do. The line is x + y + z tall; its baseline sits z / 2 + x below its top.
static func css_line(family: String, font_size: float) -> Vector3:
	var key: String = "font.%s." % family
	return Vector3(
		roundf(number(key + "ascent") * font_size),
		roundf(number(key + "descent") * font_size),
		roundf(number(key + "line_gap") * font_size)
	)


## Alegreya, the pages' display font (cards' numbers, headings), at a weight from 400 to 900.
## lining: true asks for lining figures, as card.css's font-variant-numeric: lining-nums does.
static func display_font(weight: int, lining: bool = false) -> Font:
	return _font("Alegreya[wght].ttf", weight, lining)


## Alegreya Sans, the pages' body font: 400 or 700.
static func body_font(weight: int = 400) -> Font:
	return _font(
		"AlegreyaSans-Bold.ttf" if weight >= 700 else "AlegreyaSans-Regular.ttf", weight, false
	)


static func _font(file: String, weight: int, lining: bool) -> Font:
	var key: String = "%s/%d/%s" % [file, weight, lining]
	if _fonts.has(key):
		var cached: Font = _fonts[key]
		return cached
	var server: TextServer = TextServerManager.get_primary_interface()
	var variation: FontVariation = FontVariation.new()
	variation.base_font = load(ROOT + "fonts/" + file) as FontFile
	if file.contains("[wght]"):
		variation.variation_opentype = {server.name_to_tag("wght"): weight}
	if lining:
		variation.opentype_features = {server.name_to_tag("lnum"): 1}
	_fonts[key] = variation
	return variation


static func _points(raw: Array) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for point: Array in raw:
		var x: float = point[0]
		var y: float = point[1]
		out.append(Vector2(x, y))
	return out


static func _read_json(file: String) -> Dictionary:
	var raw: String = FileAccess.get_file_as_string(ROOT + file)
	var parsed: Variant = JSON.parse_string(raw)
	assert(parsed is Dictionary, "%s%s is not a JSON object" % [ROOT, file])
	var out: Dictionary = parsed
	return out
