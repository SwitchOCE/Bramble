extends "res://src/ui/widgets/gold_plaque.gd"
## Currency lives on the bar's wood; its backing and headline scale no longer compete with cards.


func _ready() -> void:
	_value.add_theme_font_size_override("font_size", 44)
	_value.add_theme_color_override("font_color", UiTheme.CREAM)
	_value.add_theme_color_override("font_outline_color", UiTheme.INK)
	_value.add_theme_constant_override("outline_size", 5)
	_big.position = Vector2(4, 16)
	_big.size = Vector2(52, 52)
	_value.position = Vector2(62, 8)
	_value.size = Vector2(82, 72)
	_income.position = Vector2(150, 20)
	_income.size = Vector2(70, 50)
	_income_icon.position = Vector2(148, -4)
	_income_icon.size = Vector2(28, 28)


func _draw() -> void:
	pass
