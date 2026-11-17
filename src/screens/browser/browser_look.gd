class_name BrowserLook
extends RefCounted
## Round 2 card-browser/index.html geometry and typography. Browser look numbers live here.

const BACKGROUND: Dictionary = {
	"ys": 90.0,
	"T0": 1024.0,
	"T1": 1030.0,
	"sill": 1040.0,
	"cL": 254.0,
	"cR": 1666.0,
	"sideW": 214.0
}
const OUTSIDE: Dictionary = {
	"filters": Vector2(30, 70),
	"title": Vector2(290, 112),
	"count": Vector2(470, 128),
	"search": Vector2(1210, 108),
	"grid": Rect2(276, 180, 1390, 830)
}
const INSIDE: Dictionary = {
	"filters": Vector2(150, 80),
	"title": Vector2(400, 74),
	"count": Vector2(580, 90),
	"search": Vector2(1150, 70),
	"grid": Rect2(386, 140, 1260, 880)
}
const PANE: Rect2 = Rect2(120, 40, 1540, 1000)
const PANE_RADIUS: float = 40.0
const DIM: Color = Color(0, 0, 0, 0.55)
const VIGNETTE_ALPHA: float = 0.6
const FILTER_WIDTH: float = 186.0
const BUTTON_HEIGHT: float = 46.0
const BUTTON_PX: float = 21.0
const KIND_PX: float = 19.0
const GAP: float = 8.0
const LABEL_TOP: float = 10.0
const LABEL_PX: float = 20.0
const LABEL_COLOUR: Color = Color("c9bda6")
const MUTED: Color = Color("b9ad96")
const INK: Color = Color("120e0b")
const TITLE_PX: float = 44.0
const COUNT_PX: float = 20.0
const CARD_H: float = 186.0
const CARD_W: float = CARD_H * 0.56
const CELL_H: float = CARD_H + 34.0
const CARD_GAP: Vector2 = Vector2(14, 16)
const GRID_PADDING: Vector2 = Vector2(6, 4)
const GRID_RIGHT: float = 18.0
const GRID_BOTTOM: float = 30.0
const HEADING_TOP: float = 18.0
const HEADING_BOTTOM: float = 10.0
const HEADING_PX: float = 28.0
const HEADING_COUNT_PX: float = 17.0
const HEADING_GAP: float = 12.0
const RULE_HEIGHT: float = 3.0
const RULE_COLOUR: Color = Color(0.725, 0.671, 0.58, 0.4)
const TIER_ICON_PX: int = 24
const TIER_ICON_GAP: float = 4.0
const NAME_PX: float = 15.0
const NAME_DOWN: float = 6.0
const SEARCH_SIZE: Vector2 = Vector2(420, 52)
const SEARCH_ICON: String = (
	'<svg viewBox="0 0 24 24"><circle cx="10.5" cy="10.5" r="6.5"/>'
	+ '<path d="M15.5 15.5 21 21"/></svg>'
)
const SEARCH_ICON_PX: int = 24
const SEARCH_PAD: float = 18.0
const SEARCH_GAP: float = 10.0
const SEARCH_COLOUR: Color = Color("8d8577")
const SEARCH_BG: Color = Color(0.039, 0.031, 0.024, 0.55)
const SCROLL_COLOUR: Color = Color("6d6150")
const SCROLL_WIDTH: int = 6
const BUTTON_AT: Vector2 = Vector2(1763, 64)
const BUTTON_SIDE: float = 62.0
const BUTTON_ICON_PX: int = 32
const BUTTON_LABEL_PX: float = 19.0
const BUTTON_LABEL_GAP: float = 4.0
const CARDS_ICON: String = (
	'<svg viewBox="0 0 24 24"><path d="M3.5 8 10 5.5l3.4 12.6-6.5 2.4z"/>'
	+ '<path d="M12 4.5h6.5v13.5"/><path d="M15.5 7.5l5 1.6-3 10"/></svg>'
)
const SEARCH_BORDER: int = 4
const SEARCH_RADIUS: int = 26
const SEARCH_LEAD: Color = Color("16120e")
const ICON_STROKE: float = 2.4
const TIER_COUNT_DOWN: float = 10.0
const CAPTION_OVERHANG: float = 8.0
const CAPTION_HEIGHT: float = 34.0
const CAPTION_COLOUR: Color = Color("d9cfbb")
const CAPTION_OUTLINE: int = 6
const SPELL_SHOULDER: float = 0.25
const FILTER_INSET: float = 16.0
const SELECTED_COLOUR: Color = Color("ffe2a6")
const HEADING_COLOUR: Color = Color("efe6d2")


static func label(
	on: Control, words: String, at: Vector2, px: float, display: bool = false, colour: Color = MUTED
) -> GlassText:
	var text: GlassText = GlassUi.text_at(on, words, at, px, colour)
	text.family = "display" if display else "body"
	text.weight = 800 if display else 700
	text.stroke_width = 4.0 if display else 3.0
	text.stroke_colour = INK
	text.refresh()
	return text


static func filter_button(
	on: Control,
	words: String,
	at: Vector2,
	width: float,
	action: Callable,
	selected: bool = false,
	centred: bool = false,
	px: float = BUTTON_PX
) -> GlassBox:
	var box: GlassBox = GlassUi.button(on, words, at, width, action)
	box.box_size.y = BUTTON_HEIGHT
	box.refresh()
	for child: Node in box.get_children():
		var text: GlassText = child as GlassText
		if text == null:
			continue
		text.font_px = px
		if selected:
			text.colour = SELECTED_COLOUR
		text.refresh()
		text.position = (
			Vector2(
				(width - text.size.x) / 2.0 if centred else FILTER_INSET,
				(BUTTON_HEIGHT - text.size.y) / 2.0
			)
			. round()
		)
	if selected:
		StartScreen._ring(box)
	return box
