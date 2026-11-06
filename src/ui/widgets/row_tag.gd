extends Control
## A burned word read bottom to top, beside a row or shelf (.wc-rowtag: SHOP, FRONT, BACK, YOU).

const UiTheme := preload("res://src/ui/ui_theme.gd")

const WIDTH: float = 40.0

var text: String = "":
	set(value):
		text = value.to_upper()
		queue_redraw()
var font_size: int = UiTheme.FONT_SMALL
var colour: Color = UiTheme.INK


func _init(word: String = "") -> void:
	text = word
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func text_length() -> float:
	var font: Font = UiTheme.burned_font()
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _draw() -> void:
	var font: Font = UiTheme.burned_font()
	var length: float = text_length()
	var ascent: float = font.get_ascent(font_size)
	draw_set_transform(Vector2(size.x / 2.0, size.y / 2.0), -PI / 2.0)
	draw_string(
		font,
		Vector2(-length / 2.0, ascent * 0.38),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		colour
	)
