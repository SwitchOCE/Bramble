extends RefCounted
## Colours, font sizes and the shared Theme for every Bramble screen. Placeholder look: flat tribe
## colours in the spirit of the folio's "Ink + flat B" trials, dark woodland background, light
## parchment card faces with dark text so rules text stays readable on a phone.

const BASE_SIZE: Vector2i = Vector2i(1920, 1080)

const BG: Color = Color("1c2a1d")
const PANEL: Color = Color("2a3b29")
const PANEL_LIGHT: Color = Color("3a4f38")
const PANEL_BORDER: Color = Color("55704f")
const TEXT: Color = Color("f1eee2")
const TEXT_DIM: Color = Color("b9c2ac")
const INK: Color = Color("1d1d1b")
const PARCHMENT: Color = Color("f4efe1")
const GOLD: Color = Color("f2c14e")
const GOLDEN_FRAME: Color = Color("ffcf3f")
const ATTACK: Color = Color("f2b53c")
const HEALTH: Color = Color("d9443a")
const HEALTH_DAMAGED: Color = Color("7d1f1a")
const BUFF: Color = Color("7fd36b")
const DAMAGE: Color = Color("ff5a4a")
const NIGHTSHADE: Color = Color("9b4fd1")
const FROZEN: Color = Color("8fd3ff")
const SELECT: Color = Color("ffe680")
const DROP_OK: Color = Color("9cf08a")
const SELL: Color = Color("ff8a6a")
const WIN: Color = Color("8be07a")
const LOSS: Color = Color("ff7a6a")
const TIE: Color = Color("d9d3b5")

const FONT_BODY: int = 22
const FONT_SMALL: int = 18
const FONT_TITLE: int = 34
const FONT_HUGE: int = 96

const TRIBE_COLOURS: Dictionary[String, Color] = {
	"Fairies": Color("9a86cf"),
	"Oozes": Color("6aa84f"),
	"Hedgerow folk": Color("c98a52"),
	"Hunters": Color("d9653b"),
	"Birds": Color("4a90c2"),
	"Bog folk": Color("3f8a7e"),
	"Hive": Color("e1b530"),
}
const NEUTRAL_COLOUR: Color = Color("9a9a8e")

## Ink B folio trials, cropped, as placeholder art by tribe. Tribes without one show initials.
const TRIBE_PORTRAITS: Dictionary[String, String] = {
	"Fairies": "res://assets/ui/portraits/fairies.jpg",
	"Oozes": "res://assets/ui/portraits/oozes.jpg",
	"Hedgerow folk": "res://assets/ui/portraits/hedgerow.jpg",
	"Hunters": "res://assets/ui/portraits/hunters.jpg",
	"Bog folk": "res://assets/ui/portraits/bog.jpg",
}

## Status badges: label shown on the card, colour, and the one-line reminder in the detail view.
const STATUS_INFO: Dictionary[String, Array] = {
	"nightshade":
	[
		"Nightshade ½",
		Color("9b4fd1"),
		"Nightshade: the next time this is hit, its Health is halved first (not damage).",
	],
	"mired": ["Mired", Color("7a6142"), "Mired: skips its next attack."],
	"first_bite": ["First Bite", Color("c0392b"), "First Bite: strikes first in its next fight."],
	"shell": ["Shell", Color("5f8fa8"), "Shell: the first damage this combat is capped."],
	"warned": ["Warned", Color("c79a2b"), "Warned: its next attack deals half damage."],
	"waiting": ["Waiting", Color("6c7fa0"), "Waiting (Bide): skips and grows until damaged."],
}

static var _theme: Theme = null
static var _portrait_cache: Dictionary[String, Texture2D] = {}


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


static func status_reminder(status: String) -> String:
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


## The theme every screen root uses. Built once in code so there's no .tres to keep in step.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var theme: Theme = Theme.new()
	theme.default_font_size = FONT_BODY
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("6d6d66"))
	theme.set_font_size("font_size", "Button", FONT_BODY)
	theme.set_stylebox("normal", "Button", flat_box(Color("e8dfc4"), Color("8c7f5c"), 2))
	theme.set_stylebox("hover", "Button", flat_box(Color("fff4d6"), Color("c9a94f"), 3))
	theme.set_stylebox("pressed", "Button", flat_box(Color("d2c49b"), Color("8c7f5c"), 3))
	theme.set_stylebox("disabled", "Button", flat_box(Color("a7a28f"), Color("77735f"), 2))
	theme.set_stylebox("focus", "Button", flat_box(Color.TRANSPARENT, SELECT, 3))
	theme.set_stylebox("panel", "PanelContainer", flat_box(PANEL, PANEL_BORDER, 2, 12))
	theme.set_stylebox("panel", "Panel", flat_box(PANEL, PANEL_BORDER, 2, 12))
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_font_size("normal_font_size", "RichTextLabel", FONT_SMALL)
	theme.set_font_size("bold_font_size", "RichTextLabel", FONT_SMALL)
	theme.set_color("font_color", "CheckBox", TEXT)
	theme.set_color("font_hover_color", "CheckBox", TEXT)
	theme.set_color("font_pressed_color", "CheckBox", TEXT)
	theme.set_color("font_hover_pressed_color", "CheckBox", TEXT)
	theme.set_color("font_focus_color", "CheckBox", TEXT)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "CheckBox", flat_box(PANEL_LIGHT, PANEL_BORDER, 2, 8))
	_theme = theme
	return theme


static func label(text: String, size: int = FONT_BODY, colour: Color = TEXT) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
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
