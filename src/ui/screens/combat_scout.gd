extends RefCounted
## The read-only upper board shown while fight playback is paused.

const Arena := preload("res://src/ui/arena_geometry.gd")
const BoardView := preload("res://src/ui/screens/arena_board.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Data := preload("res://src/ui/view_data.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")

var board: BoardView
var heading: Label
var empty: Label
var back: LeafButton
var unit_count: int = 0
var _screen: Control


func _init(screen: Control) -> void:
	_screen = screen
	var stage: Control = screen.get("_stage")
	board = BoardView.new()
	Arena.size_board(board, "scout", false)
	stage.add_child(board)
	heading = UiTheme.head("", UiTheme.FONT_SMALL)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage.add_child(heading)
	empty = UiTheme.label("No recorded board", UiTheme.FONT_SMALL, UiTheme.MUTE)
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage.add_child(empty)
	back = LeafButton.new()
	back.set_face("Back to fight")
	back.set_label_size(UiTheme.FONT_SMALL)
	back.pressed.connect(Callable(screen, "close_scout"))
	stage.add_child(back)
	set_visible(false)


func populate(view: Dictionary) -> void:
	board.clear()
	unit_count = 0
	var units: Array = Data.a(view, "board")
	for slot: int in mini(units.size(), BoardView.SLOTS):
		if not units[slot] is Dictionary or Data.entry(units, slot).is_empty():
			continue
		var card: CardView = CardView.new()
		card.chip_hidden = true
		card.zone = "scout"
		card.index = slot
		card.show_unit(Data.entry(units, slot), CardView.Mode.BOARD)
		card.tapped.connect(_on_tapped)
		card.hovered.connect(_on_hovered)
		board.place_card(card, slot)
		unit_count += 1
	var marks: Array = RecruitView.slot_marks({"slot_effects": Data.a(view, "slot_effects")})
	board.set_marks(RecruitHeld.with_their_nests(marks, Data.a(view, "nests")))
	heading.text = Data.s(view, "name", "Player") + "\nLast board"


func set_visible(on: bool) -> void:
	board.visible = on
	heading.visible = on
	back.visible = on
	empty.visible = on and unit_count == 0


func layout(canvas: Vector2) -> void:
	Arena.place_board(board, canvas, true)
	var hero: Rect2 = Arena.hero_rect(canvas, true)
	heading.position = hero.position + Vector2(0, -76)
	heading.size = Vector2(270, 70)
	back.position = hero.position + Vector2(-12, 170)
	back.size = Vector2(294, 122)
	empty.position = Arena.board_rect(canvas, true).position + Vector2(24, 192)
	empty.size = Vector2(Arena.BOARD.x - 48.0, 100)


func show_lobby_hero(standing: Dictionary) -> void:
	_screen.call("_open_reader")
	var heroes: Array = _screen.get("hero_views")
	var bottom: int = _screen.get("bottom_side")
	var hero: Dictionary = heroes[bottom] if Data.b(standing, "is_human") else {}
	var reader: CardDetail = _screen.get("_reader")
	reader.show_unit(LobbyPlaque.reader_card(standing, hero))


func _on_tapped(_zone: String, slot: int) -> void:
	var reader: CardDetail = _screen.get("_reader")
	if reader.visible:
		_screen.call("_close_reader")
	else:
		_show_detail(slot)


func _on_hovered(_zone: String, slot: int, inside: bool) -> void:
	if CardView.is_phone():
		return
	var timer: Timer = _screen.get("_hover_close")
	if inside:
		timer.stop()
		_show_detail(slot)
	else:
		timer.start()


func _show_detail(slot: int) -> void:
	var card: CardView = board.cards[slot]
	if card == null:
		return
	_screen.call("_open_reader")
	var reader: CardDetail = _screen.get("_reader")
	reader.show_unit(card.unit)
	var notes: RichTextLabel = _screen.get("_note_text")
	CardDetail.show_rules(notes, card.unit, false)
