extends Control
## A dimmed overlay of cards to pick from: a Discover (pick 1 of 3, no way out but choosing) or a
## crowded hand laid out in full (a Back leaf closes it). A tap on a card picks it, so nothing may
## hide behind a tap here: with a row's worth of cards, each has its full rules and what its
## keywords mean on a slip beneath it, already open.

signal picked(index: int)

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")

const GAP: float = 44.0
## With this few cards each has its rules text underneath.
const TEXT_COUNT: int = 5
const SLIP_PAD: float = 16.0

## The cards on show, for tests.
var cards: Array[CardView] = []

var _shade: ColorRect
var _title_panel: WoodPanel
var _title: Label
var _back: LeafButton
var _texts: Array[RichTextLabel] = []


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
	for text: RichTextLabel in _texts:
		text.get_parent().queue_free()
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
			_texts.append(_slip(view))
	_layout()


func _on_card_tapped(_zone: String, index: int) -> void:
	# Freeing waits for the frame's end, and until then it would still take taps.
	hide()
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
			_place_slip(_texts[i], at, mid_y)


## The rules and keyword reminders on a slip. It scrolls if a card ever has more than fits.
func _slip(view: Dictionary) -> RichTextLabel:
	var box: Panel = Panel.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", UiTheme.slip_box(UiTheme.BIRCH, 4, 12))
	add_child(box)
	var text: RichTextLabel = RichTextLabel.new()
	text.bbcode_enabled = true
	text.scroll_active = false
	text.set_meta("must_fit", true)
	text.mouse_filter = Control.MOUSE_FILTER_PASS
	text.add_theme_font_size_override("normal_font_size", UiTheme.FONT_SMALL)
	text.add_theme_font_size_override("bold_font_size", UiTheme.FONT_SMALL)
	text.add_theme_constant_override("line_separation", -2)
	text.text = CardDetail.full_text_bbcode(view)
	box.visible = not text.text.is_empty()
	box.add_child(text)
	return text


func _place_slip(text: RichTextLabel, at: Vector2, mid_y: float) -> void:
	var box: Control = text.get_parent()
	var wide: float = CardView.SHOP_WIDTH + 40.0
	box.position = at + Vector2(-20, CardView.SHOP_HEIGHT + 48.0)
	text.position = Vector2(SLIP_PAD, SLIP_PAD / 2.0)
	text.size = Vector2(wide - SLIP_PAD * 2.0, 40.0)
	var room: float = mid_y + 1060.0 - box.position.y
	var tall: float = minf(text.get_content_height() + SLIP_PAD + 6.0, room)
	box.size = Vector2(wide, tall)
	text.size = Vector2(wide - SLIP_PAD * 2.0, tall - SLIP_PAD)
