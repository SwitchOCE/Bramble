extends "res://src/ui/widgets/wood_panel.gd"
## Gold, counted in acorns (.wr-gold): a big acorn, the number, the word GOLD, and a small pile with
## one acorn per coin, up to the most a turn gives.

const PILE_MAX: int = 10
const PILE_COLUMNS: int = 5
const PILE_SIZE: float = 37.0

## The gold shown, for tests.
var gold: int = 0

var _income: Label
var _value: Label
var _word: Label
var _big: TextureRect
var _pile_texture: Texture2D


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
	_word = UiTheme.burned("Gold", UiTheme.FONT_SMALL, UiTheme.INK)
	_word.position = Vector2(142, 90)
	_word.size = Vector2(110, 44)
	_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_word)
	_income = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.CREAM)
	_income.position = Vector2(254, 24)
	_income.size = Vector2(150, 110)
	_income.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_income)
	_pile_texture = Icons.icon("acorn", PILE_SIZE)


func show_gold(amount: int) -> void:
	gold = amount
	_value.text = str(amount)
	queue_redraw()


func show_income(words: String) -> void:
	# The short face is visible beside the shop; the reader carries the full explanation too.
	_income.text = words.get_slice(";", 0).get_slice(".", 0).replace("Next income: ", "Next turn\n")
	_income.tooltip_text = words + " Card and hero earnings can add more."


func _draw() -> void:
	super()
	for i: int in 0 if not _income.text.is_empty() else mini(gold, PILE_MAX):
		var row: int = floori(float(i) / PILE_COLUMNS)
		var at: Vector2 = Vector2(256 + (i % PILE_COLUMNS) * 29.0, 30 + row * 44.0)
		draw_texture_rect(_pile_texture, Rect2(at, Vector2(PILE_SIZE, PILE_SIZE)), false)
