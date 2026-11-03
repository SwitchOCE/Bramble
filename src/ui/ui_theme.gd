# gdlint:disable=class-variable-name
extends RefCounted
## Colours, fonts, shapes and the shared Theme for every Bramble screen, for the active look
## direction (ThemeDirections: "Plain", the default placeholder look, or "Folk Print"). Colours are
## static vars named like constants: screens read UiTheme.GOLD and so on, and UiTheme.use()
## swaps every one of them. The app rebuilds the current screen after a switch.

const Directions := preload("res://src/ui/theme_directions.gd")

const BASE_SIZE: Vector2i = Vector2i(1920, 1080)

const FONT_BODY: int = 22
const FONT_SMALL: int = 18
const FONT_TITLE: int = 34
const FONT_HUGE: int = 96

## Ink B folio trials, cropped, as placeholder art by tribe. Tribes without one show initials.
const TRIBE_PORTRAITS: Dictionary[String, String] = {
	"Fairies": "res://assets/ui/portraits/fairies.jpg",
	"Oozes": "res://assets/ui/portraits/oozes.jpg",
	"Hedgerow folk": "res://assets/ui/portraits/hedgerow.jpg",
	"Hunters": "res://assets/ui/portraits/hunters.jpg",
	"Bog folk": "res://assets/ui/portraits/bog.jpg",
}

## Status badges: label shown on the card, colour, and the keyword whose unit note explains it.
## The reminder text itself is the unit's note, word for word (CardDetail.glossary).
const STATUS_INFO: Dictionary[String, Array] = {
	"nightshade": ["Nightshade ½", Color("9b4fd1"), "Nightshade"],
	"mired": ["Mired", Color("7a6142"), "Mire"],
	"first_bite": ["First Bite", Color("c0392b"), "First Bite"],
	"shell": ["Shell", Color("5f8fa8"), "Shell"],
	"warned": ["Warned", Color("c79a2b"), "Whistle"],
	"waiting": ["Waiting", Color("6c7fa0"), "Bide"],
}

## Where the look choice is saved (tests point it elsewhere).
static var settings_path: String = "user://settings.cfg"
## The active direction's id (ThemeDirections.ORDER).
static var direction: String = Directions.PLAIN
static var TRIBE_COLOURS: Dictionary = {}
static var NEUTRAL_COLOUR: Color
static var BG: Color
static var PANEL: Color
static var PANEL_LIGHT: Color
static var PANEL_BORDER: Color
static var TEXT: Color
static var TEXT_DIM: Color
static var INK: Color
static var PARCHMENT: Color
static var GOLD: Color
## Headings and big numbers that Plain shows in gold (gold text is unreadable on paper).
static var HEADING: Color
static var GOLDEN_FRAME: Color
static var ATTACK: Color
static var HEALTH: Color
static var HEALTH_TEXT: Color
static var HEALTH_DAMAGED: Color
static var STAT_TEXT: Color
static var TIER_FILL: Color
static var TIER_TEXT: Color
static var BUFF: Color
static var DAMAGE: Color
static var NIGHTSHADE: Color
static var FROZEN: Color
static var FROZEN_FILL: Color
static var SELECT: Color
static var DROP_OK: Color
static var SELL: Color
static var SELL_FILL: Color
static var WIN: Color
static var LOSS: Color
static var TIE: Color
static var EMPTY_FILL: Color
static var SLOT_FILL: Color
static var SLOT_BORDER: Color
static var DEV_FILL: Color
static var OUT_FILL: Color
static var BAR_BACK: Color
static var BAR_OUT: Color
static var NOT_BUILT: Color
static var SHADE: Color
static var PORTRAIT_TEXT: Color
static var PILL_BORDER: Color
static var PILL_TEXT: Color
static var PRIMARY: Color
static var PRIMARY_TEXT: Color
## Block shadow under cards and buttons; transparent for none.
static var SHADOW: Color
static var TRAY: Color
static var TRAY_SHADOW: Color
static var STITCH: Color
## Log and inspector text colours (BBCode).
static var LOG_SIDE_0: Color
static var LOG_SIDE_1: Color
static var REMINDER: Color
static var LOG_NIGHTSHADE: Color
static var NOTE_WARN: Color
static var NOTE_GOLDEN: Color

static var _data: Dictionary = {}
static var _theme: Theme = null
static var _fonts: Dictionary[String, Font] = {}
static var _portrait_cache: Dictionary[String, Texture2D] = {}


static func _static_init() -> void:
	use(Directions.PLAIN, false)


## Switches every colour, font and shape to `id`'s direction and rebuilds the Theme. `persist`
## saves the choice to user:// settings (the app reads it back at boot). Unknown ids are ignored.
static func use(id: String, persist: bool = true) -> void:
	if not Directions.DIRECTIONS.has(id):
		return
	direction = id
	_data = Directions.DIRECTIONS[id]
	_theme = null
	_fonts.clear()
	BG = _colour("BG")
	PANEL = _colour("PANEL")
	PANEL_LIGHT = _colour("PANEL_LIGHT")
	PANEL_BORDER = _colour("PANEL_BORDER")
	TEXT = _colour("TEXT")
	TEXT_DIM = _colour("TEXT_DIM")
	INK = _colour("INK")
	PARCHMENT = _colour("PARCHMENT")
	GOLD = _colour("GOLD")
	HEADING = _colour("HEADING")
	GOLDEN_FRAME = _colour("GOLDEN_FRAME")
	ATTACK = _colour("ATTACK")
	HEALTH = _colour("HEALTH")
	HEALTH_TEXT = _colour("HEALTH_TEXT")
	HEALTH_DAMAGED = _colour("HEALTH_DAMAGED")
	STAT_TEXT = _colour("STAT_TEXT")
	TIER_FILL = _colour("TIER_FILL")
	TIER_TEXT = _colour("TIER_TEXT")
	BUFF = _colour("BUFF")
	DAMAGE = _colour("DAMAGE")
	NIGHTSHADE = _colour("NIGHTSHADE")
	FROZEN = _colour("FROZEN")
	FROZEN_FILL = _colour("FROZEN_FILL")
	SELECT = _colour("SELECT")
	DROP_OK = _colour("DROP_OK")
	SELL = _colour("SELL")
	SELL_FILL = _colour("SELL_FILL")
	WIN = _colour("WIN")
	LOSS = _colour("LOSS")
	TIE = _colour("TIE")
	EMPTY_FILL = _colour("EMPTY_FILL")
	SLOT_FILL = _colour("SLOT_FILL")
	SLOT_BORDER = _colour("SLOT_BORDER")
	DEV_FILL = _colour("DEV_FILL")
	OUT_FILL = _colour("OUT_FILL")
	BAR_BACK = _colour("BAR_BACK")
	BAR_OUT = _colour("BAR_OUT")
	NOT_BUILT = _colour("NOT_BUILT")
	SHADE = _colour("SHADE")
	PORTRAIT_TEXT = _colour("PORTRAIT_TEXT")
	PILL_BORDER = _colour("PILL_BORDER")
	PILL_TEXT = _colour("PILL_TEXT")
	PRIMARY = _colour("PRIMARY")
	PRIMARY_TEXT = _colour("PRIMARY_TEXT")
	SHADOW = _colour("SHADOW")
	TRAY = _colour("TRAY")
	TRAY_SHADOW = _colour("TRAY_SHADOW")
	STITCH = _colour("STITCH")
	LOG_SIDE_0 = _colour("LOG_SIDE_0")
	LOG_SIDE_1 = _colour("LOG_SIDE_1")
	REMINDER = _colour("REMINDER")
	LOG_NIGHTSHADE = _colour("LOG_NIGHTSHADE")
	NOTE_WARN = _colour("NOTE_WARN")
	NOTE_GOLDEN = _colour("NOTE_GOLDEN")
	TRIBE_COLOURS = _data["tribes"]
	NEUTRAL_COLOUR = _data["neutral"]
	if persist:
		var settings: ConfigFile = ConfigFile.new()
		settings.load(settings_path)
		settings.set_value("ui", "theme", id)
		settings.save(settings_path)


## The direction saved in user:// settings, or Plain.
static func saved_direction() -> String:
	var settings: ConfigFile = ConfigFile.new()
	if settings.load(settings_path) != OK:
		return Directions.PLAIN
	return str(settings.get_value("ui", "theme", Directions.PLAIN))


## A status or tribe colour made readable as text on the panels: lighter on a dark look,
## darker on a light one.
static func readable(colour: Color) -> Color:
	return colour.darkened(0.2) if BG.get_luminance() > 0.5 else colour.lightened(0.35)


## A colour as BBCode wants it ("1d1a1e").
static func hex(colour: Color) -> String:
	return colour.to_html(false)


static func _colour(key: String) -> Color:
	var colours: Dictionary = _data["colours"]
	var colour: Color = colours[key]
	return colour


## Whether the active direction uses a shape (ThemeDirections lists the keys).
static func has_shape(key: String) -> bool:
	var shapes: Dictionary = _data.get("shapes", {})
	var on: bool = shapes.get(key, false)
	return on


## The direction's body font, or null for Godot's default font.
static func body_font() -> Font:
	return _font("body", "body_font", 0, 0.0)


## Bold body font (names, buttons), or null.
static func bold_font() -> Font:
	return _font("bold", "body_font", 800, 0.0)


## Slanted body font (small notes), or null.
static func italic_font() -> Font:
	return _font("italic", "body_font", 0, 0.2)


## The display font (titles, stat numbers), or null.
static func display_font() -> Font:
	return _font("display", "display_font", 0, 0.0)


static func _font(key: String, path_key: String, weight: int, slant: float) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var path: String = str(_data.get(path_key, ""))
	var font: Font = null
	if not path.is_empty():
		var file: FontFile = load(path) as FontFile
		var variation: FontVariation = FontVariation.new()
		variation.base_font = file
		if weight > 0:
			var tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
			variation.variation_opentype = {tag: weight}
		if slant != 0.0:
			variation.variation_transform = Transform2D(
				Vector2(1, 0), Vector2(slant, 1), Vector2.ZERO
			)
		font = variation
	_fonts[key] = font
	return font


static func tribe_colour(tribes: Array) -> Color:
	if tribes.is_empty():
		return NEUTRAL_COLOUR
	var first: String = str(tribes[0])
	return TRIBE_COLOURS.get(first, NEUTRAL_COLOUR)


static func type_line(tribes: Array) -> String:
	if tribes.is_empty():
		return "Neutral"
	var parts: PackedStringArray = []
	for tribe: Variant in tribes:
		parts.append(str(tribe))
	return " · ".join(parts)


static func portrait(tribes: Array) -> Texture2D:
	if tribes.is_empty():
		return null
	var first: String = str(tribes[0])
	if not TRIBE_PORTRAITS.has(first):
		return null
	if not _portrait_cache.has(first):
		_portrait_cache[first] = load(TRIBE_PORTRAITS[first]) as Texture2D
	return _portrait_cache[first]


static func status_label(status: String) -> String:
	if STATUS_INFO.has(status):
		return str(STATUS_INFO[status][0])
	return status.capitalize()


static func status_colour(status: String) -> Color:
	if STATUS_INFO.has(status):
		var colour: Color = STATUS_INFO[status][1]
		return colour
	return Color("666666")


## The keyword that gives this status ("mired" -> "Mire").
static func status_keyword(status: String) -> String:
	if STATUS_INFO.has(status):
		return str(STATUS_INFO[status][2])
	return status.capitalize()


static func flat_box(
	fill: Color, border: Color = Color.TRANSPARENT, border_width: int = 0, radius: int = 10
) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


## A box with no content margins (bars, thin strips).
static func thin_box(fill: Color, radius: int = 3) -> StyleBoxFlat:
	var box: StyleBoxFlat = flat_box(fill, Color.TRANSPARENT, 0, radius)
	box.content_margin_left = 0
	box.content_margin_right = 0
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box


## The theme every screen root uses. Built in code from the active direction, so there's no
## .tres to keep in step.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var theme: Theme = Theme.new()
	theme.default_font_size = FONT_BODY
	if body_font() != null:
		theme.default_font = body_font()
		theme.set_font("font", "Button", bold_font())
		theme.set_font("bold_font", "RichTextLabel", bold_font())
		theme.set_font("italics_font", "RichTextLabel", italic_font())
	theme.set_color("font_color", "Label", TEXT)
	var button_text: Color = _colour("BUTTON_TEXT")
	for state: String in [
		"font_color", "font_hover_color", "font_pressed_color", "font_focus_color"
	]:
		theme.set_color(state, "Button", button_text)
	theme.set_color("font_disabled_color", "Button", _colour("BUTTON_TEXT_DISABLED"))
	theme.set_font_size("font_size", "Button", FONT_BODY)
	theme.set_stylebox(
		"normal", "Button", button_box(_colour("BUTTON"), _colour("BUTTON_BORDER"), 2)
	)
	theme.set_stylebox(
		"hover", "Button", button_box(_colour("BUTTON_HOVER"), _colour("BUTTON_HOVER_BORDER"), 3)
	)
	theme.set_stylebox(
		"pressed", "Button", button_box(_colour("BUTTON_PRESSED"), _colour("BUTTON_BORDER"), 3)
	)
	theme.set_stylebox(
		"disabled",
		"Button",
		button_box(_colour("BUTTON_DISABLED"), _colour("BUTTON_DISABLED_BORDER"), 2)
	)
	theme.set_stylebox("focus", "Button", flat_box(Color.TRANSPARENT, SELECT, 3))
	theme.set_stylebox("panel", "PanelContainer", flat_box(PANEL, PANEL_BORDER, 2, 12))
	theme.set_stylebox("panel", "Panel", flat_box(PANEL, PANEL_BORDER, 2, 12))
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_font_size("normal_font_size", "RichTextLabel", FONT_SMALL)
	theme.set_font_size("bold_font_size", "RichTextLabel", FONT_SMALL)
	for state: String in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_hover_pressed_color",
		"font_focus_color"
	]:
		theme.set_color(state, "CheckBox", TEXT)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "CheckBox", flat_box(PANEL_LIGHT, PANEL_BORDER, 2, 8))
	if has_shape("paper_inputs"):
		for state: String in ["normal", "focus", "read_only"]:
			theme.set_stylebox(state, "LineEdit", flat_box(PARCHMENT, INK, 2, 6))
		theme.set_color("font_color", "LineEdit", INK)
		theme.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
		theme.set_color("caret_color", "LineEdit", INK)
		for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
			theme.set_stylebox(state, "OptionButton", button_box(PARCHMENT, INK, 2))
		theme.set_color("font_color", "OptionButton", INK)
		theme.set_color("font_hover_color", "OptionButton", INK)
		theme.set_stylebox("panel", "PopupMenu", flat_box(PARCHMENT, INK, 2, 6))
		theme.set_color("font_color", "PopupMenu", INK)
		theme.set_color("font_hover_color", "PopupMenu", PARCHMENT)
		theme.set_stylebox("hover", "PopupMenu", flat_box(INK, Color.TRANSPARENT, 0, 4))
	_theme = theme
	return theme


## A button face in the active direction's shape (Folk Print: arched top, ink block shadow).
static func button_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = flat_box(fill, border, border_width)
	var radius: Array = _data.get("button_radius", [10, 10])
	var top: int = radius[0]
	var bottom: int = radius[1]
	box.corner_radius_top_left = top
	box.corner_radius_top_right = top
	box.corner_radius_bottom_left = bottom
	box.corner_radius_bottom_right = bottom
	var shadow: Vector2 = _data.get("button_shadow", Vector2.ZERO)
	if shadow != Vector2.ZERO:
		box.border_width_left = maxi(border_width, 3)
		box.border_width_right = maxi(border_width, 3)
		box.border_width_top = maxi(border_width, 3)
		box.border_width_bottom = maxi(border_width, 3)
		add_block_shadow(box, shadow)
	return box


## The main action's face (End turn, Fight!, Continue): gold in Plain, vermilion in Folk Print.
static func make_primary(node: Button) -> void:
	node.add_theme_stylebox_override("normal", button_box(PRIMARY, INK, 3))
	node.add_theme_color_override("font_color", PRIMARY_TEXT)
	if PRIMARY_TEXT == _colour("BUTTON_TEXT"):
		return  # Plain: hover and press use the ordinary button faces.
	node.add_theme_stylebox_override("hover", button_box(PRIMARY.lightened(0.12), INK, 3))
	node.add_theme_stylebox_override("pressed", button_box(PRIMARY.darkened(0.15), INK, 3))
	for state: String in ["font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, PRIMARY_TEXT)


## The printed look's offset shadow: a solid copy of the shape, offset down and right.
static func add_block_shadow(box: StyleBoxFlat, offset: Vector2, colour: Color = SHADOW) -> void:
	if colour.a <= 0.0:
		return
	box.shadow_color = colour
	box.shadow_size = 1
	box.shadow_offset = offset


static func label(text: String, size: int = FONT_BODY, colour: Color = TEXT) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	if size >= FONT_TITLE and display_font() != null:
		node.add_theme_font_override("font", display_font())
	node.add_theme_color_override("font_color", colour)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func button(text: String, min_width: int = 0, size: int = FONT_BODY) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.custom_minimum_size = Vector2(min_width, 64)
	node.focus_mode = Control.FOCUS_NONE
	return node


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
