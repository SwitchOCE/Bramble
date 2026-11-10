extends Control
## Every hand card has a real tile and its normal input handlers. Crowded rows overlap deliberately.

const Data := preload("res://src/ui/view_data.gd")

const CardView := preload("res://src/ui/widgets/card_view.gd")

const FOCUS_LIFT: float = 12.0
const COLUMN_GAP: float = 43.0
const ROW_GAP: float = 22.0

var cards: Array[CardView] = []
var focused_index: int = -1
var _homes: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(arrange)


func clear_cards() -> void:
	focused_index = -1
	_homes.clear()
	for value: Variant in cards:
		var card: CardView = Data.control(value) as CardView
		if is_instance_valid(card):
			remove_child(card)
			card.queue_free()
	cards.clear()


func add_card(card: CardView) -> void:
	cards.append(card)
	card.set_meta("hand_fan", true)
	add_child(card)
	card.mouse_entered.connect(_on_entered.bind(card))
	card.mouse_exited.connect(_on_exited.bind(card))
	card.tapped.connect(_on_tapped.bind(card))
	card.drag_started.connect(_on_drag_started.bind(card))
	arrange()


func card_at(index: int) -> CardView:
	for value: Variant in cards:
		var card: CardView = Data.control(value) as CardView
		if is_instance_valid(card) and card.index == index:
			return card
	return null


func arrange() -> void:
	for value: Variant in cards.duplicate():
		if not is_instance_valid(value):
			cards.erase(value)
	if cards.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var columns: int = 1 if cards.size() <= 2 else 2
	var rows: int = ceili(cards.size() / float(columns))
	var tile: Vector2 = cards[0].card_size
	var width: float = tile.x * columns + COLUMN_GAP * (columns - 1)
	var left: float = maxf(0, (size.x - width) / 2.0)
	var pitch: float = tile.y + ROW_GAP
	if rows > 1:
		pitch = minf(pitch, maxf(0.0, (size.y - FOCUS_LIFT - tile.y) / (rows - 1)))
	for index: int in cards.size():
		var card: CardView = cards[index]
		var column: int = index % columns
		var row: int = floori(index / float(columns))
		var at := Vector2(left + column * (tile.x + COLUMN_GAP), FOCUS_LIFT + row * pitch)
		_homes[card] = at
		card.position = at
		card.rotation = 0.0
		card.z_index = 0
	_stack_rest()
	if focused_index >= 0:
		focus(focused_index)


func focus(index: int) -> void:
	for value: Variant in cards:
		var card: CardView = Data.control(value) as CardView
		if card == null:
			continue
		if _homes.has(card):
			card.position = _homes[card]
		card.z_index = 0
	_stack_rest()
	var focused: CardView = card_at(index)
	if focused == null:
		return
	focused_index = index
	# CardView supplies the hover lift/shadow; keep its hit rectangle stable within the fan.
	focused.z_index = 1
	# Node order controls input precedence as well as drawing; canonical indices stay in cards.
	move_child(focused, -1)


## Upper rows paint last, exposing the lower rows' numeric foot rather than covering it.
func _stack_rest() -> void:
	for index: int in cards.size():
		move_child(cards[cards.size() - index - 1], index)


func rest_cards() -> void:
	focused_index = -1
	arrange()


func _on_entered(card: CardView) -> void:
	focus(card.index)


func _on_exited(card: CardView) -> void:
	if (
		focused_index == card.index
		and not card.selected
		and not CoreUtil.to_bool(card.get("_dragging"))
	):
		rest_cards()


func _on_tapped(_zone: String, _index: int, card: CardView) -> void:
	focus(card.index)


func _on_drag_started(_zone: String, _index: int, card: CardView) -> void:
	focus(card.index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		rest_cards()
