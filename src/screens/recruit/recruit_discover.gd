class_name RecruitDiscover
extends RefCounted
## The recruit screen's Discover picker (docs/ideation-track-2/mockups/recruit-play.html,
## ?discover=1): a dark veil over the table, the prompt, and the options as big cards in a row.
## Clicking one picks it; the hover detail reads it.

## STAND-IN Discover picker, as recruit-play.html draws it: the veil, the cards 1.4 x the table's,
## their gap and middle line, the prompt's size and how far above the cards it stands.
const VEIL: Color = Color(0.03, 0.02, 0.015, 0.62)
const SCALE: float = 1.4
## polish.html moves the row up and apart, to make room for each option's text under it.
const GAP: float = 90.0
const MIDDLE: float = 470.0
const PROMPT_PX: float = 40.0
const PROMPT_UP: float = 76.0
const Z: int = 8
## STAND-IN (polish.html .opt, .wait): the text pane's distance under its option, and the count of
## Discovers still waiting, smaller and softer, under the prompt.
const TEXT_DOWN: float = 14.0
const WAIT_UP: float = 30.0
const WAIT_PX: float = 22.0
const WAIT: Color = Color("c9bda6")
const WAIT_WORDS: String = "%d more to pick"


## The picker over the table: a dark veil, the prompt, and the options as big cards in a row.
## Clicking one picks it; the hover detail reads it.
static func build(screen: RecruitScreen, discover: Dictionary) -> void:
	var veil: ColorRect = ColorRect.new()
	veil.name = "DiscoverVeil"
	veil.color = VEIL
	veil.size = screen._stage.size
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = Z
	screen._front.add_child(veil)
	var options: Array = discover.get("options", [])
	var height: float = screen._h() * SCALE
	var width: float = GlassCard.card_size(height).x
	var row: float = options.size() * width + maxf(0.0, options.size() - 1.0) * GAP
	var top: float = MIDDLE - height / 2.0
	var prompt: GlassText = GlassText.from_rule("stage", ".lbl", str(discover.get("prompt", "")))
	prompt.name = "DiscoverPrompt"
	prompt.font_px = PROMPT_PX
	prompt.refresh()
	prompt.z_index = Z + 1
	prompt.position = Vector2(960.0 - prompt.size.x / 2.0, top - PROMPT_UP).round()
	screen._front.add_child(prompt)
	var waiting: int = GlassPieces.as_int(discover.get("waiting", 0))
	if waiting > 0:
		var more: GlassText = GlassText.from_rule("stage", ".lbl", WAIT_WORDS % waiting)
		more.name = "DiscoverWaiting"
		more.font_px = WAIT_PX
		more.colour = WAIT
		more.refresh()
		more.z_index = Z + 1
		more.position = Vector2(960.0 - more.size.x / 2.0, top - WAIT_UP).round()
		screen._front.add_child(more)
	for i: int in options.size():
		var option: Dictionary = options[i]
		var node: Control
		var outline: PackedVector2Array
		if RecruitScreen._is_spell(option):
			var spell_size: Vector2 = screen._spell_size() * SCALE
			node = screen._spell_card(option, spell_size)
			outline = GlassBox.hexagon(
				Rect2(Vector2.ZERO, spell_size), RecruitScreen._f(screen._g["SS"])
			)
		else:
			node = screen._unit_card(option, height)
			outline = L1CardFace.unit_outline(GlassCard.card_size(height))
		node.name = "Discover_%d" % i
		node.z_index = Z + 1
		var x: float = 960.0 - row / 2.0 + i * (width + GAP)
		node.position = Vector2(x, top)
		screen._front.add_child(node)
		var words: GlassBox = GlassParts.option_text(
			str(option.get("name", "")), str(option.get("text", ""))
		)
		words.name = "DiscoverText_%d" % i
		words.z_index = Z + 1
		words.position = (
			Vector2(x + width / 2.0 - GlassParts.OPTION_W / 2.0, top + height + TEXT_DOWN).round()
		)
		screen._front.add_child(words)
		screen._targets.append(
			{"kind": "discover", "index": i, "node": node, "poly": outline, "card": option}
		)
