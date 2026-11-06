extends Control
## A dimmed overlay of cards to pick from: a Discover (pick 1 of 3, no way out but choosing) or a
## crowded hand laid out in full (a Back leaf closes it). Each card is a shop tile with its full
## rules text on a slip beneath when there's room for it.

signal picked(index: int)

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")

const GAP: float = 44.0
## With this few cards each has its rules text underneath.
const TEXT_COUNT: int = 3

## The cards on show, for tests.
var cards: Array[CardView] = []

var _shade: ColorRect
var _title_panel: WoodPanel
var _title: Label
var _back: LeafButton
var _texts: Array[Label] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	_shade = ColorRect.new()
	_shade.color = UiTheme.SHADE
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_title_panel = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_title_panel)
	_title = UiTheme.head("", UiTheme.FONT_TITLE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_panel.add_child(_title)
	_back = LeafButton.new()
	_back.flipped = true
	_back.colour = LeafButton.Colour.ACORN
	_back.set_face("Back")
	_back.pressed.connect(queue_free)
	_back.visible = false
	add_child(_back)
	resized.connect(_layout)
	ready.connect(_layout)


## `can_close`: a Back leaf closes it without picking.
func show_cards(title: String, views: Array, can_close: bool) -> void:
	_title.text = title
	_back.visible = can_close
	for card: CardView in cards:
		card.queue_free()
	for text: Label in _texts:
		text.queue_free()
	cards.clear()
	_texts.clear()
	for i: int in views.size():
		var view: Dictionary = views[i]
		var card: CardView = CardView.new()
		card.show_unit(view, CardView.Mode.SHOP)
		card.set_card_width(CardView.SHOP_WIDTH)
		card.zone = "picker"
		card.index = i
		card.tapped.connect(_on_card_tapped)
		add_child(card)
		cards.append(card)
		if views.size() <= TEXT_COUNT:
			var text: Label = UiTheme.label(Data.s(view, "text"), UiTheme.FONT_SMALL)
			text.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 4, 12))
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.clip_text = true
			text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			text.visible = not text.text.is_empty()
			add_child(text)
			_texts.append(text)
	_layout()


func _on_card_tapped(_zone: String, index: int) -> void:
	picked.emit(index)
	queue_free()


func _layout() -> void:
	var w: float = size.x
	var mid_y: float = maxf(0.0, (size.y - 1080.0) / 2.0)
	var title_w: float = 720.0
	_title_panel.position = Vector2((w - title_w) / 2.0, mid_y + 30.0)
	_title_panel.size = Vector2(title_w, 100)
	_title.position = Vector2.ZERO
	_title.size = _title_panel.size
	_back.position = Vector2(40, mid_y + 24.0)
	_back.size = Vector2(300, 122)
	var count: int = cards.size()
	var per_row: int = mini(count, 5)
	var row_w: float = per_row * CardView.SHOP_WIDTH + (per_row - 1) * (GAP + 16.0)
	var top: float = mid_y + 190.0
	for i: int in count:
		var column: int = i % per_row
		var row: int = floori(float(i) / per_row)
		var at: Vector2 = Vector2(
			(w - row_w) / 2.0 + column * (CardView.SHOP_WIDTH + GAP + 16.0),
			top + row * (CardView.SHOP_HEIGHT + 60.0)
		)
		cards[i].position = at
		if i < _texts.size():
			var text: Label = _texts[i]
			text.position = at + Vector2(-20, CardView.SHOP_HEIGHT + 48.0)
			var wide: float = CardView.SHOP_WIDTH + 40.0
			var words: Vector2 = text.get_theme_font("font").get_multiline_string_size(
				text.text, HORIZONTAL_ALIGNMENT_CENTER, wide - 30.0, UiTheme.FONT_SMALL
			)
			var room: float = mid_y + 1060.0 - text.position.y
			text.size = Vector2(wide, minf(words.y + 30.0, room))
