extends HSlider
## A volume: a groove burned into the plank with an acorn peg, the filled part moss (the mock's
## .ws-slider). Reads 0 to 100.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")

const PEG: float = 44.0


func _init() -> void:
	min_value = 0.0
	max_value = 100.0
	step = 5.0
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(240, 96)
	var groove: StyleBoxFlat = UiTheme.flat_box(UiTheme.CARVE, UiTheme.INK, 3, 9)
	groove.content_margin_top = 9.0
	groove.content_margin_bottom = 9.0
	var fill: StyleBoxFlat = UiTheme.flat_box(UiTheme.MOSS, UiTheme.INK, 3, 9)
	fill.content_margin_top = 9.0
	fill.content_margin_bottom = 9.0
	add_theme_stylebox_override("slider", groove)
	add_theme_stylebox_override("grabber_area", fill)
	add_theme_stylebox_override("grabber_area_highlight", fill)
	var peg: Texture2D = Icons.icon("acorn", PEG)
	add_theme_icon_override("grabber", peg)
	add_theme_icon_override("grabber_highlight", peg)
