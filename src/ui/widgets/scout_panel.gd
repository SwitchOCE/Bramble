extends Control
## The next opponent's board as it fought last round, by slot, beside your own so you can place
## against it. Their front row faces you, as in a fight. Tap a unit for its rules.

signal closed

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")

const POCKET: float = 172.0
const CLOSE_W: float = 240.0

## Units on show, for tests.
var unit_count: int = 0

var _panel: WoodPanel
var _title: Label
var _board: BoardView
var _empty: Label
var _notes: RichTextLabel
var _close: LeafButton
var _units: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 12
	visible = false
	_panel = WoodPanel.new(WoodPanel.Kind.PAPER)
	_panel.nails = false
	add_child(_panel)
	_title = UiTheme.head("", UiTheme.FONT_BODY + 4)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.clip_text = true
	add_child(_title)
	_board = BoardView.new()
	_board.configure("scout", POCKET, false)
	add_child(_board)
	_empty = UiTheme.label(
		"They haven't fought yet. After this round you can see how they lined up.",
		UiTheme.FONT_BODY,
		UiTheme.INK
	)
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_empty)
	_notes = RichTextLabel.new()
	_notes.bbcode_enabled = true
	_notes.scroll_active = true
	_notes.mouse_filter = Control.MOUSE_FILTER_PASS
	_notes.add_theme_font_size_override("normal_font_size", UiTheme.FONT_SMALL)
	_notes.add_theme_font_size_override("bold_font_size", UiTheme.FONT_SMALL)
	_notes.add_theme_constant_override("line_separation", -2)
	add_child(_notes)
	_close = LeafButton.new()
	_close.flipped = true
	_close.colour = LeafButton.Colour.ACORN
	_close.set_face("Close")
	_close.pressed.connect(func() -> void: closed.emit())
	add_child(_close)
	resized.connect(_layout)
	ready.connect(_layout)


## `units`: one entry per slot (null when empty), the state's next_opponent_last_board.
## `slot_effects`: its next_opponent_last_slot_effects, the Rings on those slots.
func show_board(opponent: String, units: Array, slot_effects: Array = []) -> void:
	_title.text = "%s last fought like this" % opponent
	_board.clear()
	_units = units
	unit_count = 0
	for slot: int in mini(units.size(), BoardView.SLOTS):
		if units[slot] is Dictionary:
			var card: CardView = CardView.new()
			card.show_unit(Data.entry(units, slot), CardView.Mode.BOARD)
			card.zone = "scout"
			card.index = slot
			card.tapped.connect(_on_unit_tapped)
			_board.place_card(card, slot)
			unit_count += 1
	var none: bool = unit_count == 0
	_empty.visible = none
	_board.visible = not none
	var marks: Array = RecruitView.slot_marks({"slot_effects": slot_effects})
	_board.set_marks(marks)
	_notes.text = "" if none else "Tap a unit for its rules."
	for slot: int in marks.size():
		var mark: Dictionary = marks[slot]
		if mark["has_ring"] == true:
			_notes.text += " " + RecruitView.slot_note(mark, slot)
	_layout()


func _on_unit_tapped(_zone: String, slot: int) -> void:
	var view: Dictionary = Data.entry(_units, slot)
	_notes.text = "[b]%s.[/b] %s" % [Data.s(view, "name"), CardDetail.full_text_bbcode(view)]


func _layout() -> void:
	if size.x < 10.0:
		return
	_panel.size = size
	_title.position = Vector2(30, 18)
	_title.size = Vector2(size.x - 60.0, 60)
	var tray: Vector2 = _board.tray_size()
	_board.position = Vector2((size.x - tray.x) / 2.0, 84)
	_empty.position = Vector2(50, 180)
	_empty.size = Vector2(size.x - 100.0, 200)
	var notes_y: float = 84.0 + tray.y + 8.0
	var leaf_h: float = 122.0
	_notes.position = Vector2(30, notes_y)
	_notes.size = Vector2(size.x - 60.0 - CLOSE_W, size.y - notes_y - 16.0)
	_close.position = Vector2(size.x - CLOSE_W - 16.0, size.y - leaf_h - 12.0)
	_close.size = Vector2(CLOSE_W, leaf_h)
