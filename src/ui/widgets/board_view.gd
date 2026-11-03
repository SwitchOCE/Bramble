extends Control
## The 4-3 brick: four front slots, three back slots offset by half a slot so each back slot sits
## between the two front slots in front of it (rulebook 8.1, 8.2.1). Slots are fixed and always
## drawn. Cards are placed by hand (no containers) so combat playback can move them freely.
##
## `front_toward_top` puts the front row on top (your board, facing an enemy above) or at the
## bottom (the enemy's board, facing you below). Slot indices are SPEC's: 0-3 front, 4-6 back.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const SlotView := preload("res://src/ui/widgets/slot_view.gd")

const SLOTS: int = 7
const FRONT: int = 4
const ROW_LABEL_WIDTH: float = 44.0

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
