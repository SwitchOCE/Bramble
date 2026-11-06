extends Button
## An on/off latch (.wc-latch): a pill with a sliding acorn. Moss when on, carved wood when off, and
## it says which in words.

const UiTheme := preload("res://src/ui/ui_theme.gd")

const WIDTH: float = 190.0
const HEIGHT: float = 92.0

var _word: Label


func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	set_meta("drawn_face", true)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_theme_font_size_override("font_size", 1)
	for state: String in [
		"font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"
	]:
		add_theme_color_override(state, Color.TRANSPARENT)
	custom_minimum_size = Vector2(WIDTH, 122)
	_word = UiTheme.burned("", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_word)
	toggled.connect(func(_on: bool) -> void: _place())
	resized.connect(_place)
	ready.connect(_place)
	_place()


## Sets the state without firing `toggled`'s handlers elsewhere.
func set_on(on: bool) -> void:
	set_pressed_no_signal(on)
	_place()


func _place() -> void:
	_word.text = "ON" if button_pressed else "OFF"
	var top: float = (size.y - HEIGHT) / 2.0
	_word.size = Vector2(90, HEIGHT)
	_word.position = Vector2(26.0 if button_pressed else WIDTH - 86.0, top)
	queue_redraw()


func _draw() -> void:
	var top: float = (size.y - HEIGHT) / 2.0
	var pill: Rect2 = Rect2(0, top, WIDTH, HEIGHT)
	var fill: Color = UiTheme.MOSS if button_pressed else UiTheme.CARVE
	var box: StyleBoxFlat = UiTheme.flat_box(fill, UiTheme.INK, 6, 46)
	box.corner_detail = 14
	draw_style_box(box, pill)
	var radius: float = HEIGHT / 2.0 - 11.0
	var x: float = WIDTH - HEIGHT / 2.0 if button_pressed else HEIGHT / 2.0
	var centre: Vector2 = Vector2(x, top + HEIGHT / 2.0)
	draw_circle(centre, radius + 5.0, UiTheme.INK)
	draw_circle(centre, radius, UiTheme.ACORN if button_pressed else UiTheme.BIRCH)
