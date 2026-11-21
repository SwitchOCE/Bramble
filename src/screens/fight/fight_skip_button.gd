class_name FightSkipButton
extends Button
## The fight mock-up's 150 × 68 leaded glass button and hover shortcut.

const AT: Vector2 = Vector2(1722, 930)
const BOX: Vector2 = Vector2(150, 68)
const BONE: Color = Color("efe6d2")
const ICON: String = (
	'<svg viewBox="0 0 24 24">'
	+ '<path fill="#efe6d2" d="M4 5.5v13l8-6.5zM12 5.5v13l8-6.5z"/></svg>'
)
const HOT_SHADOWS: Array[Dictionary] = [
	{"inset": true, "x": 0, "y": 0, "blur": 0, "spread": 2, "colour": "#ffffff24"},
	{"inset": false, "x": 0, "y": 0, "blur": 0, "spread": 3, "colour": "#ffb24a"},
	{"inset": false, "x": 0, "y": 0, "blur": 26, "spread": 6, "colour": "#ffaa4673"},
	{"inset": false, "x": 0, "y": 4, "blur": 8, "spread": 0, "colour": "#00000099"},
]

var _glass: GlassBox
var _shortcut: Control


func _ready() -> void:
	name = "SkipButton"
	text = "Skip"
	position = AT
	size = BOX
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Use Button for input and its accessible name, with the game's glass drawn over it.
	self_modulate = Color.TRANSPARENT
	_glass = GlassBox.new()
	_glass.box_size = BOX
	_glass.use_css("stage", ".btn").refresh()
	add_child(_glass)

	var glyph: TextureRect = TextureRect.new()
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture = GlassPieces.svg_icon(ICON, BONE, 30, 1.6)
	var label: GlassText = GlassText.new()
	label.words = text
	label.use_font(GlassPieces.rule_font("stage", ".btn"))
	label.colour = BONE
	label.refresh()
	var left: float = (BOX.x - 30.0 - 10.0 - label.size.x) / 2.0
	glyph.position = Vector2(left, (BOX.y - 30.0) / 2.0).round()
	label.position = Vector2(left + 40.0, (BOX.y - label.size.y) / 2.0).round()
	_glass.add_child(glyph)
	_glass.add_child(label)

	_shortcut = _make_shortcut()
	add_child(_shortcut)
	_shortcut.hide()
	mouse_entered.connect(_show_hover.bind(true))
	mouse_exited.connect(_show_hover.bind(false))
	visibility_changed.connect(func() -> void: _show_hover(false))


func _show_hover(on: bool) -> void:
	_glass.modulate = Color(1.18, 1.18, 1.18) if on else Color.WHITE
	_glass.shadows = HOT_SHADOWS if on else GlassPieces.rule("stage", ".btn", "box-shadow")
	_glass.refresh()
	_shortcut.visible = on


func _make_shortcut() -> Control:
	var row: Control = Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var key: GlassText = GlassText.new()
	key.words = "Space"
	key.font_px = 15
	key.weight = 700
	key.colour = BONE
	key.refresh()
	var cap: Panel = Panel.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size = Vector2(key.size.x + 16.0, 22.5)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("2b2621")
	style.border_color = Color("6d6150")
	style.set_corner_radius_all(5)
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	cap.add_theme_stylebox_override("panel", style)
	key.position = (((cap.size - key.size) / 2.0) - Vector2(0, 1)).round()
	cap.add_child(key)
	row.add_child(cap)

	var words: GlassText = GlassText.new()
	words.words = "to skip"
	words.font_px = 17
	words.weight = 700
	words.colour = Color("d9cfbb")
	words.stroke_width = 3
	words.stroke_colour = Color("120e0b")
	words.refresh()
	words.position = Vector2(cap.size.x + 8.0, (cap.size.y - words.size.y) / 2.0).round()
	row.add_child(words)
	row.position = Vector2(roundf((BOX.x - words.position.x - words.size.x) / 2.0), 80)
	return row
