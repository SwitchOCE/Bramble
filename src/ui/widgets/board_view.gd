extends Control
## The 4-3 brick: four front slots, three back slots offset by half a slot so each back slot sits
## between the two front slots in front of it (rulebook 8.1, 8.2.1). Slots are fixed and always
## drawn. Cards are placed by hand (no containers) so combat playback can move them freely.
##
## `front_toward_top` puts the front row on top (your board, facing an enemy above) or at the
## bottom (the enemy's board, facing you below). Slot indices are SPEC's: 0-3 front, 4-6 back.
## In Folk Print the board sits on a paper tray cut to the 4-3 shape, with a stitch from each
## back slot to the two front slots in front of it.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const SlotView := preload("res://src/ui/widgets/slot_view.gd")

const SLOTS: int = 7
const FRONT: int = 4
const ROW_LABEL_WIDTH: float = 44.0
## How far the Folk Print tray reaches past the slots.
const TRAY_PAD: float = 10.0

var zone: String = "board"
var card_width: float = 168.0
var gap: float = 18.0
var row_gap: float = 16.0
var front_toward_top: bool = true

var slots: Array[SlotView] = []
## Card in each slot, or null.
var cards: Array[CardView] = []

var _front_label: Label
var _back_label: Label
## Woodcraft's slot chips (F1, B2) on each slot's bottom edge, drawn over the cards.
var _chips: Array[Label] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for i: int in SLOTS:
		var slot: SlotView = SlotView.new()
		slot.set_slot(zone, i)
		add_child(slot)
		slots.append(slot)
		cards.append(null)
	_front_label = _row_label("FRONT")
	_back_label = _row_label("BACK")
	if UiTheme.has_shape("slot_chips"):
		for i: int in SLOTS:
			var chip: Label = UiTheme.label(SlotView.SLOT_NAMES[i], 17, UiTheme.SLOT_CHIP_TEXT)
			chip.add_theme_font_override("font", UiTheme.bold_font())
			var face: StyleBoxFlat = UiTheme.flat_box(UiTheme.SLOT_CHIP, Color.TRANSPARENT, 0, 6)
			face.content_margin_left = 6
			face.content_margin_right = 6
			face.content_margin_top = 0
			face.content_margin_bottom = 0
			chip.add_theme_stylebox_override("normal", face)
			chip.z_index = 2
			add_child(chip)
			_chips.append(chip)
	resized.connect(_layout)


func configure(
	board_zone: String, width: float, front_on_top: bool, slot_gap: float = 18.0
) -> void:
	zone = board_zone
	card_width = width
	front_toward_top = front_on_top
	gap = slot_gap
	for i: int in SLOTS:
		slots[i].set_slot(zone, i)
	var card_size: Vector2 = CardView.size_for(card_width)
	custom_minimum_size = Vector2(
		ROW_LABEL_WIDTH + FRONT * card_size.x + (FRONT - 1) * gap, card_size.y * 2 + row_gap
	)
	_layout()


func _row_label(text: String) -> Label:
	var node: Label = UiTheme.label(text, 15, UiTheme.TEXT_DIM)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(node)
	return node


## Top-left of a slot in this board's local coordinates.
func slot_position(slot: int) -> Vector2:
	var card_size: Vector2 = CardView.size_for(card_width)
	var front: bool = slot < FRONT
	var column: float = float(slot) if front else float(slot - FRONT) + 0.5
	var x: float = ROW_LABEL_WIDTH + column * (card_size.x + gap)
	var top_row: bool = front == front_toward_top
	var y: float = 0.0 if top_row else card_size.y + row_gap
	return Vector2(x, y)


func slot_global_center(slot: int) -> Vector2:
	var card_size: Vector2 = CardView.size_for(card_width)
	return get_global_transform() * (slot_position(slot) + card_size / 2.0)


func _layout() -> void:
	var card_size: Vector2 = CardView.size_for(card_width)
	for i: int in SLOTS:
		slots[i].position = slot_position(i)
		slots[i].size = card_size
		var card: CardView = cards[i]
		if card != null:
			card.position = slot_position(i)
	var front_y: float = slot_position(0).y
	var back_y: float = slot_position(FRONT).y
	_front_label.position = Vector2(0, front_y)
	_front_label.size = Vector2(ROW_LABEL_WIDTH - 6, card_size.y)
	_back_label.position = Vector2(0, back_y)
	_back_label.size = Vector2(ROW_LABEL_WIDTH + card_size.x / 2.0 - 6, card_size.y)
	_front_label.text = "F\nR\nO\nN\nT"
	_back_label.text = "B\nA\nC\nK"
	for i: int in _chips.size():
		var chip: Label = _chips[i]
		chip.size = chip.get_minimum_size()
		var centre: Vector2 = slot_position(i) + Vector2(card_size.x / 2.0, card_size.y)
		chip.position = centre - chip.size / 2.0
	queue_redraw()


## Folk Print's tray and stitches, under the slots. Each row is a paper plate with an ink edge and
## a vermilion block shadow; across the gap between the rows, a stitch runs from each back slot
## to each of the two front slots it is behind.
func _draw() -> void:
	if not UiTheme.has_shape("tray"):
		return
	var card_size: Vector2 = CardView.size_for(card_width)
	var rows: Array[Rect2] = [_row_rect(0, FRONT, card_size), _row_rect(FRONT, SLOTS, card_size)]
	var offset: Vector2 = UiTheme.tray_shadow()
	for rect: Rect2 in rows:
		var shadow: StyleBoxFlat = UiTheme.flat_box(UiTheme.TRAY_SHADOW, Color.TRANSPARENT, 0, 18)
		draw_style_box(shadow, Rect2(rect.position + offset, rect.size))
	for rect: Rect2 in rows:
		draw_style_box(UiTheme.flat_box(UiTheme.TRAY, UiTheme.INK, 3, 18), rect)
	var back_y: float = slot_position(FRONT).y
	var front_y: float = slot_position(0).y
	var back_edge: float = back_y + (card_size.y if back_y < front_y else 0.0)
	var front_edge: float = front_y + (card_size.y if front_y < back_y else 0.0)
	var dots: bool = UiTheme.shape_of("stitch", "dashes") == "dots"
	for back: int in range(FRONT, SLOTS):
		var from: Vector2 = Vector2(slot_position(back).x + card_size.x / 2.0, back_edge)
		for front: int in [back - FRONT, back - FRONT + 1]:
			var to: Vector2 = Vector2(slot_position(front).x + card_size.x / 2.0, front_edge)
			if not dots:
				draw_dashed_line(from, to, UiTheme.STITCH, 3.0, 7.0)
				continue
			# Pokerwork grooves: a row of burned dots.
			var steps: int = maxi(2, int(from.distance_to(to) / 9.0))
			for step: int in steps + 1:
				draw_circle(from.lerp(to, float(step) / float(steps)), 2.5, UiTheme.STITCH)


func _row_rect(first: int, end: int, card_size: Vector2) -> Rect2:
	var rect: Rect2 = Rect2(slot_position(first), card_size)
	for slot: int in range(first + 1, end):
		rect = rect.merge(Rect2(slot_position(slot), card_size))
	return rect.grow(TRAY_PAD)


## Puts a card into a slot (replacing whatever was there). The board owns it from now on.
func place_card(card: CardView, slot: int) -> void:
	remove_card(slot)
	cards[slot] = card
	if card.get_parent() != self:
		if card.get_parent() != null:
			card.get_parent().remove_child(card)
		add_child(card)
	card.set_card_width(card_width)
	card.position = slot_position(slot)


## Takes the card out of the slot and frees it.
func remove_card(slot: int) -> void:
	var card: CardView = cards[slot]
	cards[slot] = null
	if card != null:
		remove_child(card)
		card.queue_free()


## Takes the card out of the slot without freeing it (combat moves it elsewhere).
func detach_card(slot: int) -> CardView:
	var card: CardView = cards[slot]
	cards[slot] = null
	return card


func clear() -> void:
	for i: int in SLOTS:
		remove_card(i)


func slot_of_card(card: CardView) -> int:
	return cards.find(card)


func clear_highlights() -> void:
	for slot: SlotView in slots:
		slot.highlight = Color.TRANSPARENT
	for card: CardView in cards:
		if card != null:
			card.outline = Color.TRANSPARENT
			card.selected = false
