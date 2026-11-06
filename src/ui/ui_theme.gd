# gdlint:disable=max-public-methods
# One look, so this is a toolbox of small builders; splitting it would only scatter them.
extends RefCounted
## Hedgerow Woodcraft, the game's one look (decided 6 Nov, DECISIONS.md): every colour, font and
## shared builder. Colours and sizes come from the design lab's mock (docs/design-lab/r3/woodcraft/
## wc.css); mock pixels on its 640 px stage are 1.6875 canvas units on our 1080 tall canvas.

const Sfx := preload("res://src/ui/sfx.gd")

const BASE_SIZE: Vector2i = Vector2i(1920, 1080)
## The canvas is 1080 tall at every window size, so a phone at 1688x780 shows it at 0.722.
## Nothing on screen is smaller than MIN_FONT: 22 window px there, 11 pt on that phone at 2x
## (tests/ui/layout_check.gd works it out and fails anything smaller).
const MIN_FONT: int = 31
const FONT_SMALL: int = 31
const FONT_BODY: int = 34
const FONT_LEAF: int = 40
const FONT_TITLE: int = 52
const FONT_HUGE: int = 96

const WALNUT: Color = Color("3b2416")
const LIME: Color = Color("e6d3ab")
const LIME_BAND: Color = Color("e2cea4")
const LIME_SEAM: Color = Color("cdb283")
const INK: Color = Color("2b1a0f")
const OAK: Color = Color("c08a52")
const CARVE: Color = Color("8c5a2e")
const BIRCH: Color = Color("fbf3e2")
const CREAM: Color = Color("f7ecd4")
const MOSS: Color = Color("41662c")
const ACORN: Color = Color("d9a441")
const ATTACK: Color = Color("f2a43a")
const HEALTH: Color = Color("a52a21")
const HEALTH_HURT: Color = Color("7a1c16")
const YARN: Color = Color("b8322a")
const NIGHTSHADE: Color = Color("5e3a86")
const NIGHTSHADE_DARK: Color = Color("3a2356")
const FROST: Color = Color("a8d4e6")
const FROST_FACE: Color = Color("e3f1f7")
const RIME: Color = Color("2f6680")
const GILT: Color = Color("f0c14b")
const BRASS: Color = Color("a8761e")
const PINE: Color = Color("f1e6c8")
const MUTE: Color = Color("5a3a20")
const OUT_FACE: Color = Color("dcc79c")
const OUT_MARK: Color = Color("8c7a62")
const SPELL_FACE: Color = Color("efe6f4")

## Roles the rest of the UI reads, in the look's colours.
const BG: Color = LIME
const PANEL: Color = OAK
const PANEL_LIGHT: Color = BIRCH
const PANEL_BORDER: Color = INK
const TEXT: Color = INK
const TEXT_DIM: Color = MUTE
const PARCHMENT: Color = CREAM
const GOLD: Color = ACORN
const HEADING: Color = INK
const BUFF: Color = MOSS
const DAMAGE: Color = YARN
const FROZEN: Color = RIME
const SELECT: Color = ACORN
const DROP_OK: Color = MOSS
const SELL: Color = HEALTH
const WIN: Color = MOSS
const LOSS: Color = HEALTH
const TIE: Color = MUTE
const SHADE: Color = Color(0.17, 0.1, 0.06, 0.55)
const LOG_SIDE_0: Color = MOSS
const LOG_SIDE_1: Color = HEALTH
const REMINDER: Color = MUTE
const LOG_NIGHTSHADE: Color = NIGHTSHADE
const NOTE_WARN: Color = HEALTH
const NOTE_GOLDEN: Color = BRASS

## Placeholder art until each card has its own: assets/portraits/<def_id>.jpg wins when it exists
## (1:1), else the tribe's portrait here, else the neutral one.
const UNIT_PORTRAIT_DIR: String = "res://assets/portraits/%s.jpg"
const NEUTRAL_PORTRAIT: String = "res://assets/ui/portraits/neutral.jpg"
const TRIBE_PORTRAITS: Dictionary[String, String] = {
	"Fairies": "res://assets/ui/portraits/fairies.jpg",
	"Hive": "res://assets/ui/portraits/fairies.jpg",
	"Oozes": "res://assets/ui/portraits/oozes.jpg",
	"Hedgerow folk": "res://assets/ui/portraits/hedgerow.jpg",
	"Hunters": "res://assets/ui/portraits/hunters.jpg",
	"Bog folk": "res://assets/ui/portraits/bog.jpg",
	"Birds": "res://assets/ui/portraits/birds.jpg",
}

## Status tags: the label on the hanging tag, its colour, and the keyword whose note explains it.
const STATUS_INFO: Dictionary[String, Array] = {
	"nightshade": ["Nightshade", NIGHTSHADE, "Nightshade"],
	"mired": ["Mired", Color("6b5535"), "Mire"],
	"first_bite": ["First Bite", YARN, "First Bite"],
	"shell": ["Shell", RIME, "Shell"],
	"warned": ["Warned", BRASS, "Whistle"],
	"waiting": ["Waiting", Color("4f6280"), "Bide"],
}

const FONT_PATHS: Dictionary[String, String] = {
	"head": "res://assets/fonts/Grenze-Variable.ttf",
	"body": "res://assets/fonts/AlegreyaSans-Regular.ttf",
	"bold": "res://assets/fonts/AlegreyaSans-Bold.ttf",
	"number": "res://assets/fonts/Bitter-Variable.ttf",
	"title": "res://assets/fonts/GrenzeGotisch-Variable.ttf",
}

static var _theme: Theme = null
static var _fonts: Dictionary[String, Font] = {}
static var _portrait_cache: Dictionary[String, Texture2D] = {}

# --- fonts -------------------------------------------------------------------------------------


static func body_font() -> Font:
	return _font("body", "body")


static func bold_font() -> Font:
	return _font("bold", "bold")


## Slanted body font (reminder text).
static func italic_font() -> Font:
	return _font("italic", "body", 0, 0.0, 0.2)


## Card names and headings: Grenze, heavy.
static func head_font() -> Font:
	return _font("head", "head", 800)


## Burned-in capitals ("THIS HIT"): Grenze, heavy, tracked out.
static func burned_font() -> Font:
	return _font("burned", "head", 800, 3.0)


## Numbers on beads, discs and coins: Bitter, black.
static func number_font() -> Font:
	return _font("number", "number", 900)


## The big carved titles: Grenze Gotisch.
static func title_font() -> Font:
	return _font("title", "title", 700)


## Kept for callers that ask for "the display font".
static func display_font() -> Font:
	return head_font()


static func _font(
	key: String, file: String, weight: int = 0, spacing: float = 0.0, slant: float = 0.0
) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var variation: FontVariation = FontVariation.new()
	variation.base_font = load(FONT_PATHS[file]) as FontFile
	if weight > 0:
		var tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
		variation.variation_opentype = {tag: weight}
	if spacing != 0.0:
		variation.spacing_glyph = roundi(spacing)
	if slant != 0.0:
		variation.variation_transform = Transform2D(Vector2(1, 0), Vector2(slant, 1), Vector2.ZERO)
	_fonts[key] = variation
	return variation


# --- small helpers -------------------------------------------------------------------------------


## A status or tribe colour made readable as text on paper.
static func readable(colour: Color) -> Color:
	return colour.darkened(0.2) if colour.get_luminance() > 0.45 else colour


static func hex(colour: Color) -> String:
	return colour.to_html(false)


static func type_line(tribes: Array) -> String:
	if tribes.is_empty():
		return "Neutral"
	var parts: PackedStringArray = []
	for tribe: Variant in tribes:
		parts.append(str(tribe))
	return " · ".join(parts)


## The tribe as it fits between a tile's beads at the phone minimum: the first tribe, without
## "folk" ("Hedgerow"). The card's full text gives the whole type line.
static func short_tribe(tribes: Array) -> String:
	if tribes.is_empty():
		return "Neutral"
	return str(tribes[0]).trim_suffix(" folk")


## True when this card or hero has its own picture in assets/portraits/.
static func has_own_portrait(def_id: String) -> bool:
	return not def_id.is_empty() and ResourceLoader.exists(UNIT_PORTRAIT_DIR % def_id)


## The art of a unit, spell, item or hero: its own portrait if it has one, else its tribe's, else
## the neutral one.
static func portrait_for(def_id: String, tribes: Array) -> Texture2D:
	if not def_id.is_empty():
		var own: String = UNIT_PORTRAIT_DIR % def_id
		if _portrait_cache.has(own):
			return _portrait_cache[own]
		if ResourceLoader.exists(own):
			_portrait_cache[own] = load(own) as Texture2D
			return _portrait_cache[own]
	return portrait(tribes)


static func portrait(tribes: Array) -> Texture2D:
	var path: String = NEUTRAL_PORTRAIT
	if not tribes.is_empty():
		path = TRIBE_PORTRAITS.get(str(tribes[0]), NEUTRAL_PORTRAIT)
	if not _portrait_cache.has(path):
		_portrait_cache[path] = load(path) as Texture2D
	return _portrait_cache[path]


static func status_label(status: String) -> String:
	if STATUS_INFO.has(status):
		return str(STATUS_INFO[status][0])
	return status.capitalize()


static func status_colour(status: String) -> Color:
	if STATUS_INFO.has(status):
		var colour: Color = STATUS_INFO[status][1]
		return colour
	return MUTE


## The keyword that gives this status ("mired" -> "Mire").
static func status_keyword(status: String) -> String:
	if STATUS_INFO.has(status):
		return str(STATUS_INFO[status][2])
	return status.capitalize()


## A bot's name without the prototype's strategy note: "Bot 3 (wide)" -> "Bot 3".
static func short_name(player_name: String) -> String:
	var bracket: int = player_name.find(" (")
	return player_name.left(bracket) if bracket > 0 else player_name


static func ordinal(n: int) -> String:
	var suffix: String = "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"
	return "%d%s" % [n, suffix]


# --- boxes ---------------------------------------------------------------------------------------


static func flat_box(
	fill: Color, border: Color = Color.TRANSPARENT, border_width: int = 0, radius: int = 12
) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.corner_detail = 6
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


## A box with no content margins.
static func thin_box(fill: Color, radius: int = 4) -> StyleBoxFlat:
	var box: StyleBoxFlat = flat_box(fill, Color.TRANSPARENT, 0, radius)
	box.set_content_margin_all(0)
	return box


## The ink-edged paper slip used for chips, name strips and small notes.
static func slip_box(fill: Color = BIRCH, border: int = 4, radius: int = 12) -> StyleBoxFlat:
	var box: StyleBoxFlat = flat_box(fill, INK, border, radius)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 1
	box.content_margin_bottom = 3
	return box


## A wooden button face: birch on ink with a carved bottom edge.
static func button_box(fill: Color, border: Color = INK, border_width: int = 5) -> StyleBoxFlat:
	var box: StyleBoxFlat = flat_box(fill, border, border_width, 18)
	box.border_width_bottom = border_width + 5
	return box


# --- the shared Theme ---------------------------------------------------------------------


## The theme every screen root uses, built in code so there's no .tres to keep in step.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var theme: Theme = Theme.new()
	theme.default_font = body_font()
	theme.default_font_size = FONT_BODY
	theme.set_font("font", "Button", head_font())
	theme.set_font_size("font_size", "Button", FONT_BODY)
	theme.set_font("bold_font", "RichTextLabel", bold_font())
	theme.set_font("italics_font", "RichTextLabel", italic_font())
	theme.set_color("font_color", "Label", INK)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_font_size("normal_font_size", "RichTextLabel", FONT_BODY)
	theme.set_font_size("bold_font_size", "RichTextLabel", FONT_BODY)
	theme.set_font_size("italics_font_size", "RichTextLabel", FONT_SMALL)
	for state: String in [
		"font_color", "font_hover_color", "font_pressed_color", "font_focus_color"
	]:
		theme.set_color(state, "Button", INK)
		theme.set_color(state, "CheckBox", INK)
		theme.set_color(state, "OptionButton", INK)
	theme.set_color("font_disabled_color", "Button", MUTE)
	theme.set_stylebox("normal", "Button", button_box(BIRCH))
	theme.set_stylebox("hover", "Button", button_box(CREAM))
	theme.set_stylebox("pressed", "Button", button_box(ACORN))
	theme.set_stylebox("disabled", "Button", button_box(OUT_FACE, MUTE))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "PanelContainer", flat_box(OAK, INK, 5, 18))
	theme.set_stylebox("panel", "Panel", flat_box(OAK, INK, 5, 18))
	for state: String in ["normal", "focus", "read_only"]:
		theme.set_stylebox(state, "LineEdit", slip_box())
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTE)
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_font_size("font_size", "LineEdit", FONT_SMALL)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "OptionButton", button_box(BIRCH))
	theme.set_font_size("font_size", "OptionButton", FONT_SMALL)
	theme.set_stylebox("panel", "PopupMenu", flat_box(BIRCH, INK, 4, 10))
	theme.set_font_size("font_size", "PopupMenu", FONT_SMALL)
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", BIRCH)
	theme.set_stylebox("hover", "PopupMenu", flat_box(INK, Color.TRANSPARENT, 0, 6))
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "CheckBox", slip_box())
	theme.set_font_size("font_size", "CheckBox", FONT_SMALL)
	_theme = theme
	return theme


# --- builders ------------------------------------------------------------------------------------


static func label(text: String, size: int = FONT_BODY, colour: Color = INK) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", colour)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Text in the heading font (names, plaque titles).
static func head(text: String, size: int = FONT_BODY, colour: Color = INK) -> Label:
	var node: Label = label(text, size, colour)
	node.add_theme_font_override("font", head_font())
	return node


## Burned capitals: "COMBAT LOG".
static func burned(text: String, size: int = FONT_SMALL, colour: Color = INK) -> Label:
	var node: Label = label(text.to_upper(), size, colour)
	node.add_theme_font_override("font", burned_font())
	return node


## A bold number in Bitter.
static func number(text: String, size: int = FONT_SMALL, colour: Color = INK) -> Label:
	var node: Label = label(text, size, colour)
	node.add_theme_font_override("font", number_font())
	return node


## Fills `parent` with the limewood table: bands, seams and a light grain (.wc-table).
static func add_table(parent: Control) -> Control:
	var script: GDScript = load("res://src/ui/widgets/table_background.gd")
	var table: Control = script.new()
	table.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(table)
	return table


## A wooden button for dev and sandbox tools (players see leaf buttons).
static func button(text: String, min_width: int = 0, size: int = FONT_BODY) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.custom_minimum_size = Vector2(min_width, 122)
	node.focus_mode = Control.FOCUS_NONE
	node.pressed.connect(Sfx.tap)
	return node


## The main action's wooden face.
static func make_primary(node: Button) -> void:
	node.add_theme_stylebox_override("normal", button_box(MOSS))
	node.add_theme_stylebox_override("hover", button_box(MOSS.lightened(0.12)))
	node.add_theme_stylebox_override("pressed", button_box(MOSS.darkened(0.15)))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		node.add_theme_color_override(state, CREAM)
