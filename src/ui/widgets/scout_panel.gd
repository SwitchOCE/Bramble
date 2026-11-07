extends Control
## The next opponent's board as it fought last round, by slot, in the shop's place at the top of the
## screen. Their front row faces your board underneath, as in a fight. The shop shrinks to small
## tiles beside it, so their board, what you might buy, your board and your hand are all in view at
## once. Their slots are tap targets the recruit screen wires up: the full text lands in the card
## panel, where every other full text lands.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")

## The smallest pocket whose height still makes a finger's tap target on a phone (122).
const POCKET: float = 136.0
const TITLE_H: float = 54.0

## Units on show, for tests.
var unit_count: int = 0

var _title: Label
var _board: BoardView
var _empty: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 12
	visible = false
	_board = BoardView.new()
	_board.configure("scout", POCKET, false)
	add_child(_board)
	_title = UiTheme.head("", UiTheme.FONT_BODY + 2)
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.set_meta("ellipsis_ok", true)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_title)
	_empty = UiTheme.label(
		"They haven't fought yet. After this round you can see how they stood.",
		UiTheme.FONT_SMALL,
		UiTheme.INK
	)
	_empty.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 4, 14))
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.clip_text = true
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.z_index = 3
	add_child(_empty)
	resized.connect(_layout)
	ready.connect(_layout)


## The pockets, for the screen to wire: each reports zone "scout" and its slot.
func slots() -> Array:
	return _board.slots


func tray_width() -> float:
	return _board.tray_size().x


func tray_height() -> float:
	return _board.tray_size().y


func card_at(slot: int) -> CardView:
	return _board.cards[slot] if slot >= 0 and slot < BoardView.SLOTS else null


## `units`: one entry per slot (null when empty), the state's next_opponent_last_board.
## `slot_effects`: its next_opponent_last_slot_effects, the Rings on those slots.
## `nests`: the slots where a bird of theirs left, the state's next_opponent_last_nests.
func show_board(
	opponent: String, units: Array, slot_effects: Array = [], nests: Array = []
) -> void:
	_board.clear()
	unit_count = 0
	for slot: int in mini(units.size(), BoardView.SLOTS):
		if units[slot] is Dictionary:
			var view: Dictionary = Data.entry(units, slot)
			var card: CardView = CardView.new()
			card.chip_hidden = true
			card.show_unit(view, CardView.Mode.BOARD)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.set_meta("overlap_checked", true)
			_board.place_card(card, slot)
			card.turns_shown = RecruitView.tile_slip(view)
			unit_count += 1
	_empty.visible = unit_count == 0
	_title.text = "%s's last fight" % opponent
	var marks: Array = RecruitView.slot_marks({"slot_effects": slot_effects})
	_board.set_marks(RecruitHeld.with_their_nests(marks, nests))
	_layout()


func _layout() -> void:
	var tray: Vector2 = _board.tray_size()
	_board.position = Vector2.ZERO
	var title_x: float = tray.x + 16.0
	_title.position = Vector2(title_x, 0)
	_title.size = Vector2(maxf(size.x - title_x, 10.0), TITLE_H)
	_empty.position = Vector2(50, tray.y / 2.0 - 70.0)
	_empty.size = Vector2(tray.x - 100.0, 140)
