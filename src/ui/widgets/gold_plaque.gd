extends "res://src/ui/widgets/wood_panel.gd"
## Gold, counted in acorns (.wr-gold): a big acorn, the number, the word GOLD, and a small pile with
## one acorn per coin, up to the most a turn gives.

const PILE_MAX: int = 10
const PILE_COLUMNS: int = 5
const PILE_SIZE: float = 37.0

## The gold shown, for tests.
var gold: int = 0

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
	_pile_texture = Icons.icon("acorn", PILE_SIZE)


func show_gold(amount: int) -> void:
	gold = amount
	_value.text = str(amount)
	queue_redraw()


func _draw() -> void:
	super()
	for i: int in mini(gold, PILE_MAX):
		var row: int = floori(float(i) / PILE_COLUMNS)
		var at: Vector2 = Vector2(256 + (i % PILE_COLUMNS) * 29.0, 30 + row * 44.0)
		draw_texture_rect(_pile_texture, Rect2(at, Vector2(PILE_SIZE, PILE_SIZE)), false)
