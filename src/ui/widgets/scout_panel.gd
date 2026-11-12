extends Control

signal hero_pressed
## A standings seat's last recorded board replaces the market. Their slots and portrait
## open the shared reader; buying and refreshing resume after returning to the market.

const ArenaGeometry := preload("res://src/ui/arena_geometry.gd")

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")

## The smallest pocket whose height still makes a finger's tap target on a phone (122).
const POCKET: float = 136.0
const TITLE_H: float = 94.0

## Units on show, for tests.
var unit_count: int = 0
## The title clears public lobby statuses without moving the board's matching columns.
var heading_offset: float = 0.0

var _title: Label
var _board: BoardView
var _empty: Label
var _hero: Interactive
var _hero_art: ArtFrame


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 12
	visible = false
	_board = BoardView.new()
	_board.configure("scout", POCKET, false)
	add_child(_board)
	_title = UiTheme.head("", UiTheme.FONT_SMALL)
	_title.add_theme_color_override("font_color", UiTheme.CREAM)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_stylebox_override(
		"normal", UiTheme.flat_box(Color(UiTheme.INK, 0.9), Color.TRANSPARENT, 0, 8)
	)
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
	_title.visible = false
	_empty.visible = false
	_hero = Interactive.new()
	_hero.zone = "scout_hero"
	_hero.tapped.connect(func(_zone: String, _index: int) -> void: hero_pressed.emit())
	add_child(_hero)
	_hero_art = ArtFrame.new()
	_hero_art.radius = 60.0
	_hero.add_child(_hero_art)
	_hero.visible = false
	resized.connect(_layout)
	ready.connect(_layout)


## The pockets, for the screen to wire: each reports zone "scout" and its slot.
func slots() -> Array:
	return _board.slots


## Share your board's column spacing, so matching slot labels face each other at every size.
func set_column_pitch(pitch: float) -> void:
	_board.gap = pitch - POCKET if pitch > 0.0 else roundf(POCKET * 14.0 / 124.0)
	_board.custom_minimum_size = _board.tray_size()
	_board.size = _board.tray_size()
	_board.call("_layout")
	_layout()


func first_column_center() -> float:
	return _board.slot_position(0).x + _board.pocket.x / 2.0


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
	_opponent: String,
	units: Array,
	slot_effects: Array = [],
	nests: Array = [],
	hero: Dictionary = {}
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
			card.set_card_size(ArenaGeometry.UNIT)
			card.turns_shown = RecruitView.tile_slip(view)
			unit_count += 1
	_empty.visible = false
	_title.text = _opponent
	_title.visible = true
	show_hero(hero)
	var marks: Array = RecruitView.slot_marks({"slot_effects": slot_effects})
	_board.set_marks(RecruitHeld.with_their_nests(marks, nests))
	_layout()


## The tray corner identifies its owner without a title or a second Who? word.
func show_hero(hero: Dictionary) -> void:
	_hero.visible = not hero.is_empty()
	if _hero.visible:
		_hero_art.texture = UiTheme.portrait_for(Data.s(hero, "id"), [])


## Forecast carries the resolved quarry destination, including a neighbour's lent mark.
## `bindings` is LaneProjection.forecast([your_board, scouted_board]), not inferred across.
func pulse_reach(own_board: BoardView, bindings: Dictionary, source_slot: int) -> void:
	# The source keeps its blue selection; only the destination gets a gold target beat.
	_board.show_relations([])
	var targets: Array[int] = []
	var quarries: Array[int] = []
	for kind: String in ["patches", "quarries"]:
		for entry: Dictionary in Data.a(bindings, kind):
			if (
				Data.i(entry, "from_side") == 1
				and (
					Data.i(entry, "from_slot") == source_slot
					or Data.i(entry, "lender_slot", -1) == source_slot
				)
			):
				var target: int = Data.i(entry, "slot", -1)
				if Data.i(entry, "side") == 0 and target >= 0 and not targets.has(target):
					targets.append(target)
				if Data.i(entry, "side") == 0 and target >= 0 and kind == "quarries":
					quarries.append(target)
	own_board.show_relations(targets, -1, quarries)


func _layout() -> void:
	var tray: Vector2 = _board.tray_size()
	_board.position = Vector2.ZERO
	_title.position = Vector2(tray.x + 24, 20)
	_title.size = Vector2(270.0, TITLE_H)
	_empty.position = Vector2(50, tray.y / 2.0 - 70.0)
	_empty.size = Vector2(tray.x - 100.0, 140)
	var side: float = 122.0 if CardView.is_phone() else 90.0
	_hero.position = Vector2(tray.x + 24, 150)
	_hero.size = Vector2(side, side)
	_hero_art.size = _hero.size
