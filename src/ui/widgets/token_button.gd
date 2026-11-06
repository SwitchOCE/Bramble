extends Button
## A round wooden token (.wk-tok): the fight's speed buttons and the small round tools. Sits proud
## on a carved edge; when lit it is pressed down and turns acorn.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

const EDGE: float = 9.0

## Lit: pressed in, acorn face (the active speed).
var lit: bool = false:
	set(value):
		lit = value
		_place()
		queue_redraw()

var _word: Label
var _glyph: TextureRect


func _init(word: String = "", icon_name: String = "", word_size: int = UiTheme.FONT_BODY) -> void:
	pressed.connect(Sfx.tap)
	focus_mode = Control.FOCUS_NONE
	set_meta("drawn_face", true)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_theme_font_size_override("font_size", 1)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	text = word
	_word = UiTheme.number(word, word_size)
	_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_word)
	_glyph = TextureRect.new()
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_glyph)
	set_icon_name(icon_name)
	resized.connect(_place)
	ready.connect(_place)


func set_icon_name(icon_name: String) -> void:
	_glyph.visible = not icon_name.is_empty()
	if _glyph.visible:
		_glyph.texture = Icons.icon(icon_name, 48.0)


func set_word(word: String) -> void:
	text = word
	_word.text = word


func _face_rect() -> Rect2:
	var side: float = minf(size.x, size.y - EDGE)
	var x: float = (size.x - side) / 2.0
	var y: float = EDGE if lit else 0.0
	return Rect2(x, y, side, side)


func _place() -> void:
	var face: Rect2 = _face_rect()
	_word.position = face.position
	_word.size = face.size
	var inset: float = face.size.x * 0.22
	_glyph.position = face.position + Vector2(inset, inset)
	_glyph.size = face.size - Vector2(inset, inset) * 2.0


func _draw() -> void:
	var face: Rect2 = _face_rect()
	var box: StyleBoxFlat = UiTheme.flat_box(UiTheme.CARVE, UiTheme.INK, 5, 200)
	box.corner_detail = 16
	if not lit:
		draw_style_box(box, Rect2(face.position + Vector2(0, EDGE), face.size))
	box = UiTheme.flat_box(UiTheme.ACORN if lit else UiTheme.BIRCH, UiTheme.INK, 5, 200)
	box.corner_detail = 16
	draw_style_box(box, face)
