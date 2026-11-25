class_name GlassPieces
extends RefCounted
## The glass mock-ups' own pieces, as tools/glass/pull_mockups.py copies them into assets/glass:
## art and UI textures, layout numbers read out of the mock-ups' CSS and JS, and their fonts.
## layout.json says, for every number, which mock-up file and line it came from.

const ROOT: String = "res://assets/glass/"
const TIERS: int = 6
## Unit card art, one folder per tribe: assets/units/<tribe>/<unit id>.jpg.
const UNITS_ROOT: String = "res://assets/units/"
## STAND-IN: owner-selected shop upgrade icon (18 Nov), until the mock-ups carry it.
## Keep it outside layout.json: pull_mockups.py replaces that file from stage.js.
const STAND_IN_ICONS: Dictionary = {
	"shop_up":
	(
		'<svg viewBox="0 0 24 24"><path d="M3 9h12l-1.5-4h-9z"/>'
		+ '<path d="M3 9a2 2 0 0 0 4 0a2 2 0 0 0 4 0a2 2 0 0 0 4 0"/>'
		+ '<path d="M4.5 11v8M13.5 11v8M3 19h12"/>'
		+ '<path d="M20.5 19V7M18 9.5l2.5-2.5 2.5 2.5"/></svg>'
	)
}

static var _layout: Dictionary = {}
static var _fonts: Dictionary = {}
## Loaded textures are kept here: a texture drawn from a local variable is freed before the frame
## is rendered, and draws as plain white.
static var _textures: Dictionary = {}


## Card art by the mock-ups' name for it, such as "badger-1".
static func art(art_name: String) -> Texture2D:
	return null if art_name == "" else _texture(ROOT + "art/%s.jpg" % art_name)


## Any picture under assets/glass by its path there, such as "ui/pane.jpg".
static func texture(rel: String) -> Texture2D:
	return _texture(ROOT + rel)


## A hero portrait by the mock-ups' name for it, such as "dame_farthing".
static func portrait(portrait_name: String) -> Texture2D:
	return null if portrait_name == "" else _texture(ROOT + "portraits/%s.jpg" % portrait_name)


## Card art for a tribe's unit or token by its id in that tribe's units.json, such as
## unit_art("locust", "green-recruit"). Made by the card art recipe and moved into card space
## (560 x 1000) with its one fixed crop, like the mock-ups' art above. Null if it has no art yet.
static func unit_art(tribe: String, unit_id: String) -> Texture2D:
	var path: String = unit_art_path(tribe, unit_id)
	if not ResourceLoader.exists(path):
		return null
	return _texture(path)


static func unit_art_path(tribe: String, unit_id: String) -> String:
	return UNITS_ROOT + "%s/%s.jpg" % [tribe, unit_id]


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	var tex: Texture2D = _textures[path]
	return tex


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
	if STAND_IN_ICONS.has(icon_name):
		return svg_icon(str(STAND_IN_ICONS[icon_name]), tint, px, stroke)
	return svg_icon(text("stage.icon." + icon_name), tint, px, stroke)


## An icon's SVG text, drawn as stage.js's ICON are (a 24 box, stroked, no fill) at px pixels.
static func svg_icon(svg: String, tint: Color, px: int, stroke: float) -> Texture2D:
	var key: String = "icon/%d/%s/%d/%s" % [svg.hash(), tint.to_html(), px, stroke]
	if not _textures.has(key):
		var attrs: String = (
			(
				'<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="none" '
				+ 'stroke="#%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" '
			)
			% [tint.to_html(false), stroke]
		)
		var image: Image = Image.new()
		var err: Error = image.load_svg_from_string(svg.replace("<svg ", attrs), float(px) / 24.0)
		assert(err == OK, "icon does not load: %s" % svg.left(60))
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


## Card space: every position on a card is in these units (card.js U: 560 wide, 1000 tall).
static func card_units() -> Vector2:
	return Vector2(number("card.units.w"), number("card.units.h"))


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


## Alegreya Sans, the pages' body font: 400 or 700. `lining`: figures at cap height ("0" is not
## an "o").
static func body_font(weight: int = 400, lining: bool = false) -> Font:
	return _font(
		"AlegreyaSans-Bold.ttf" if weight >= 700 else "AlegreyaSans-Regular.ttf", weight, lining
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


static func _read_json(file: String) -> Dictionary:
	var raw: String = FileAccess.get_file_as_string(ROOT + file)
	var parsed: Variant = JSON.parse_string(raw)
	assert(parsed is Dictionary, "%s%s is not a JSON object" % [ROOT, file])
	var out: Dictionary = parsed
	return out
