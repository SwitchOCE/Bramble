extends "res://src/ui/widgets/wood_panel.gd"
## Acorns and income on the shared hero bar.

var gold: int = 0

var _income: Label
var _value: Label
var _big: TextureRect
var _income_icon: TextureRect


func _init() -> void:
	super(Kind.OAK)
	_big = TextureRect.new()
	_big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big.texture = Icons.icon("acorn", 105.0)
	_big.position = Vector2(34, 18)
	_big.size = Vector2(105, 105)
	add_child(_big)
	_value = UiTheme.number("", 78)
	_value.position = Vector2(142, 2)
	_value.size = Vector2(110, 96)
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_value)
	_income = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_income.position = Vector2(254, 104)
	_income.size = Vector2(154, 40)
	_income.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_income)
	_income_icon = TextureRect.new()
	_income_icon.texture = Icons.icon("acorn", 36)
	_income_icon.position = Vector2(264, 64)
	_income_icon.size = Vector2(36, 36)
	_income_icon.modulate.a = 0.45
	_income_icon.visible = false
	add_child(_income_icon)


func show_gold(amount: int) -> void:
	gold = amount
	_value.text = str(amount)
	queue_redraw()


func show_income(words: String, difference: int = 0) -> void:
	_income.text = "%+d" % difference if difference != 0 else ""
	_income.visible = difference != 0
	_income_icon.visible = difference != 0
	_income.tooltip_text = words


func _draw() -> void:
	pass


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
