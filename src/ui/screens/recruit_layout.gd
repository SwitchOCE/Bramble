extends Control
## The recruit screen's nodes and where they stand, with no behaviour: RecruitScreen builds them,
## fills them from the state and handles the taps.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitOozes := preload("res://src/ui/screens/recruit_oozes.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const ScoutPanel := preload("res://src/ui/widgets/scout_panel.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/screens/arena_board.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const AwayTray := preload("res://src/ui/widgets/away_tray.gd")
const HandFan := preload("res://src/ui/widgets/hand_fan.gd")
const TribeBonuses := preload("res://src/ui/widgets/tribe_bonuses.gd")
const LobbyStrip := preload("res://src/ui/widgets/lobby_strip.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const DevPanel := preload("res://src/ui/widgets/dev_panel.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const PlayFrame := preload("res://src/ui/widgets/play_frame.gd")
const Surface := preload("res://src/ui/widgets/painted_surface.gd")
const ShelfPlank := preload("res://src/ui/widgets/shelf_plank.gd")
const GoldPlaque := preload("res://src/ui/widgets/gold_plaque.gd")
const HeroPlaque := preload("res://src/ui/widgets/hero_plaque.gd")
const CardPicker := preload("res://src/ui/widgets/card_picker.gd")
const PauseMenu := preload("res://src/ui/widgets/pause_menu.gd")

const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")

const ArenaGeometry := preload("res://src/ui/arena_geometry.gd")

const CANVAS_H: float = 1080.0
const RIGHT_W: float = 442.0
const BOARD_POCKET: float = 209.0
const SHELF_H: float = 57.0
const TILE_GAP: float = 44.0
const LEAF_H: float = 128.0
const TOAST_SECONDS: float = 3.5
## The full hand is always represented by real tiles.
const HAND_SHOWN: int = 4
const HOVER_SECONDS: float = 0.2
## How long a hovered card's panel waits for the pointer to reach it before closing.
const LEAVE_SECONDS: float = 0.3
## Scouting: the shop's small tiles beside their board.
const MINI_TILE: float = 130.0
const MINI_GAP_X: int = 30
const MINI_GAP_Y: int = 30
## Two cards in hand stay tall enough for their rules.

var port: GamePort
var state: Dictionary = {}

var _lanes: LaneOverlay
var _frame: PlayFrame
var _bar_contents: Control
var _stage: Control
var _tribes: TribeBonuses
var _lobby: LobbyStrip
var _menu_token: TokenButton
var _dev_token: TokenButton
var _shop_zone: Interactive
var _shelf: ShelfPlank
var _shop_scroll: ScrollContainer
var _shop_cards: GridContainer
var _board: BoardView
var _hand_zone: Interactive
var _hand_panel: WoodPanel
var _hand_count: Label
var _hand_cards: HandFan
var _away_tray: AwayTray
var _gold: GoldPlaque
var _tier_icon: TextureRect
var _tier_label: Label
var _round_label: Label
var _tier_button: LeafButton
var _refresh_button: LeafButton
var _freeze_button: LeafButton
var _kin_button: LeafButton
var _end_button: LeafButton
var _detail: CardDetail
var _hero: HeroPlaque
var _toast: Label
var _dev: DevPanel
var _scout: ScoutPanel
var _scout_snapshot: Dictionary = {}
var _scout_token: TokenButton
var _who_token: TokenButton
var _market_controls: Control
var _market_return: LeafButton
var _market_title: Label


func _layout() -> void:
	if _stage == null or size.x < 10.0:
		return
	_stage.position = Vector2(0, maxf(0.0, (size.y - CANVAS_H) / 2.0))
	_stage.size = Vector2(size.x, CANVAS_H)
	if _bar_contents != null:
		_bar_contents.scale = Vector2.ONE
	var market: Rect2 = ArenaGeometry.market_rect(_stage.size)
	ArenaGeometry.size_board(_board, "board", true)
	ArenaGeometry.place_board(_board, _stage.size)
	var rail: Rect2 = ArenaGeometry.lobby_rect(_stage.size)
	_lobby.position = rail.position
	_lobby.size = rail.size
	_lobby.visible = not _scout.visible
	_menu_token.position = Vector2(16, 112)
	_menu_token.size = Vector2(122, 131)
	_scout_token.hide()
	_who_token.hide()
	_shop_zone.position = market.position
	_shop_zone.size = market.size
	_shop_zone.visible = not _scout.visible
	_shop_cards.add_theme_constant_override("h_separation", int(_shop_gap()))
	var offers: int = _shop_cards.get_child_count()
	var shop_width: float = offers * ArenaGeometry.UNIT.x + maxf(0, offers - 1) * _shop_gap()
	_shop_cards.scale = Vector2.ONE
	_shop_cards.position = Vector2((size.x - shop_width) / 2.0, 142)
	_shop_cards.size = Vector2(shop_width, ArenaGeometry.UNIT.y)
	_shop_cards.visible = not _scout.visible
	_shop_scroll.hide()
	_shelf.hide()
	for child: Node in _shop_cards.get_children():
		var card: CardView = child as CardView
		if card != null:
			card.set_card_size(ArenaGeometry.UNIT)
	_layout_hand(0)
	_layout_hero(0)
	_layout_right(market.position.x, size.x)
	_dev_token.position = Vector2(16, 250)
	_dev_token.size = Vector2(122, 131)
	_dev.position = Vector2(148, 112)
	_toast.position = Vector2(size.x / 2.0 - 250, 530)
	_size_toast()
	_lanes.hide()
	if _scout.visible:
		_layout_scouting(0, 0)
	_layout_frame(market.position.x, market.size.x)


## Only the top zone swaps. The hand, own formation, hero and purchase context stay anchored.
func _layout_scouting(_left: float, _right_x: float) -> void:
	var theirs: BoardView = _scout.get("_board")
	ArenaGeometry.size_board(theirs, "scout", false)
	var frame: Rect2 = ArenaGeometry.board_rect(_stage.size, true)
	_scout.position = frame.position + (frame.size - theirs.size) / 2.0
	_scout.size = theirs.size
	_scout.heading_offset = 0.0
	_scout.call("_layout")


func tap_size() -> float:
	return 122.0


func _layout_hero(_center: float) -> void:
	var rect: Rect2 = ArenaGeometry.hero_rect(_stage.size)
	_hero.position = rect.position
	_hero.size = rect.size
	var health: int = 0
	var armor: int = 0
	for entry: Dictionary in Data.a(state, "standings"):
		if Data.b(entry, "is_human"):
			health = Data.i(entry, "health")
			armor = Data.i(entry, "armor")
	_hero.show_health(health, armor)


func _layout_hand(_x: float) -> void:
	var rect: Rect2 = ArenaGeometry.hand_rect(_stage.size)
	_hand_zone.show()
	_hand_zone.position = rect.position
	_hand_zone.size = rect.size
	_hand_panel.hide()
	_hand_count.position = Vector2(16, 0)
	_hand_count.size = Vector2(rect.size.x - 32, 40)
	_hand_count.add_theme_color_override("font_color", UiTheme.CREAM)
	_hand_count.add_theme_color_override("font_outline_color", UiTheme.INK)
	_hand_count.add_theme_constant_override("outline_size", 5)
	_hand_cards.position = Vector2(12, 38)
	_hand_cards.size = Vector2(rect.size.x - 24, 472)
	for card: CardView in _hand_cards.cards:
		card.set_card_size(ArenaGeometry.UNIT)
	_hand_cards.arrange()
	_away_tray.position = Vector2(ArenaGeometry.board_rect(_stage.size).end.x + 36, 788)
	_away_tray.size = Vector2(270, _away_tray.row_height())
	_away_tray.show_state(state)


func _layout_right(x: float, _w: float) -> void:
	var board: Rect2 = ArenaGeometry.board_rect(_stage.size)
	_gold.position = Vector2(x + ArenaGeometry.MARKET.x - 246, 30)
	_gold.size = Vector2(222, 80)
	_round_label.position = Vector2(24, 28)
	_round_label.size = Vector2(230, 60)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_round_label.add_theme_color_override("font_color", UiTheme.CREAM)
	_round_label.add_theme_color_override("font_outline_color", UiTheme.INK)
	_round_label.add_theme_constant_override("outline_size", 5)
	_market_title.position = Vector2(x + 32, 28)
	_market_title.size = Vector2(520, 68)
	_market_title.visible = not _scout.visible
	_market_controls.position = Vector2(size.x / 2.0 - 350, 394)
	_market_controls.size = Vector2(700, 122)
	_tier_button.compact_cost()
	_tier_button.position = _market_controls.position
	_tier_button.size = Vector2(220, 122)
	_tier_icon.hide()
	_tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_button.compact_cost()
	_refresh_button.position = _market_controls.position + Vector2(236, 0)
	_refresh_button.size = Vector2(140, 122)
	_freeze_button.position = _market_controls.position + Vector2(392, 0)
	_freeze_button.size = Vector2(140, 122)
	_freeze_button.set_pressed_no_signal(Data.b(state, "frozen"))
	_kin_button.visible = Data.b(state, "ask_for_kin_enabled")
	_kin_button.position = _market_controls.position + Vector2(548, 0)
	_kin_button.size = Vector2(140, 122)
	_kin_button.compact_cost()
	_end_button.position = Vector2(board.end.x + 36, 936)
	_end_button.size = Vector2(270, 122)
	_end_button.set_label_size(UiTheme.FONT_LEAF)
	_tribes.position = Vector2(board.end.x + 36, 554)
	_tribes.size = Vector2(312, 88)
	_tribes.visible = not _tribes.chips.is_empty()
	_market_return.position = Vector2(x + 24, 30)
	_market_return.size = Vector2(270, 122)
	_market_return.visible = _scout.visible
	if _scout.visible:
		var side_x: float = ArenaGeometry.hand_rect(_stage.size).position.x
		_market_return.position = Vector2(side_x, 24)
		_market_controls.position = Vector2(side_x, 160)
		_market_controls.size = Vector2(392, 260)
		_tier_button.position = Vector2(side_x, 160)
		_refresh_button.position = Vector2(side_x + 236, 160)
		_freeze_button.position = Vector2(side_x, 296)
		_kin_button.position = Vector2(side_x + 156, 296)
		_gold.position = Vector2(side_x, 440)
	_gold.show()


func _render_shop(frozen: bool) -> void:
	call("_clear", _shop_cards)
	var shop: Array = Data.a(state, "shop")
	_shop_cards.columns = maxi(shop.size(), 1)
	_shop_cards.add_theme_constant_override("h_separation", int(_shop_gap()))
	_shop_cards.add_theme_constant_override("v_separation", 16)
	_shelf.selling = false
	_shop_cards.modulate = Color.WHITE
	for index: int in shop.size():
		var view: Dictionary = shop[index]
		var card: CardView = call(
			"_make_card", view, "shop", index, ArenaGeometry.UNIT.x, CardView.Mode.SHOP
		)
		card.set_card_size(ArenaGeometry.UNIT)
		card.frost = frozen
		if frozen and index == 0:
			card.show_frost_tag(true)
		if not RecruitView.triple_warning(state, view).is_empty():
			card.outline = UiTheme.GILT
		_shop_cards.add_child(card)


func _shop_width() -> float:
	return ArenaGeometry.MARKET.x


func _shop_gap() -> float:
	return 16.0


func _tile_width(_offers: int) -> float:
	return ArenaGeometry.UNIT.x


func _hand_card_size(_count: int) -> Vector2:
	return ArenaGeometry.UNIT


func _size_toast() -> void:
	if _toast.visible:
		_toast.size = _toast.get_minimum_size()
		var room: float = size.x - 480.0
		_toast.position.x = maxf(20.0, (room - _toast.size.x) / 2.0)


# --- what a selection lights up ---------------------------------------------------------------


func _highlight_bellies(view: Dictionary) -> Array[int]:
	var bellies: Array[int] = RecruitHeld.bellies_for(Data.a(state, "board"), view)
	for slot: int in bellies:
		_board.cards[slot].outline = UiTheme.DROP_OK
	return bellies


func _show_drop_targets() -> bool:
	var pocket: Control = get("_drop_pocket")
	return get_viewport().gui_is_dragging() or (is_instance_valid(pocket) and pocket.visible)


func _highlight_empty_slots() -> void:
	if not _show_drop_targets():
		return
	for slot: int in BoardView.SLOTS:
		if _board.cards[slot] == null:
			_board.slots[slot].highlight = UiTheme.DROP_OK


func _highlight_aim(aim: String) -> void:
	_highlight_item({"aim": aim})


## Every slot this card can land on, and the shop's offers for a card aimed at the shop.
func _highlight_item(item: Dictionary) -> void:
	if not RecruitView.no_target_note(state, item).is_empty() and not item.has("ring_add"):
		return
	if Data.s(item, "aim") == "shop_unit":
		for card: Node in _shop_cards.get_children():
			if card is CardView and not CardView.is_spell((card as CardView).unit):
				(card as CardView).outline = UiTheme.DROP_OK
		return
	for slot: int in BoardView.SLOTS:
		var has_unit: bool = _board.cards[slot] != null
		var target: Dictionary = _board.cards[slot].unit if has_unit else {}
		if not RecruitView.item_lands(item, target, slot, state):
			if RecruitView.ring_preview(state, item, slot) == "Full" and _show_drop_targets():
				_board.slots[slot].highlight = UiTheme.OUT_FACE
				if has_unit:
					_board.cards[slot].outline = UiTheme.OUT_MARK
			continue
		if has_unit:
			_board.cards[slot].outline = UiTheme.DROP_OK
		elif _show_drop_targets():
			_board.slots[slot].highlight = UiTheme.DROP_OK


func _highlight_other_slots(from_slot: int) -> void:
	if not _show_drop_targets():
		return
	for slot: int in BoardView.SLOTS:
		if slot == from_slot:
			continue
		if _board.cards[slot] == null:
			_board.slots[slot].highlight = UiTheme.DROP_OK
		else:
			_board.cards[slot].outline = UiTheme.DROP_OK


func _build_right(
	on_tier: Callable, on_refresh: Callable, on_freeze: Callable, on_end: Callable
) -> void:
	_gold = GoldPlaque.new()
	_stage.add_child(_gold)
	_tier_icon = TextureRect.new()
	_tier_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tier_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tier_icon.texture = Icons.icon("tier", 46.0)
	_stage.add_child(_tier_icon)
	_tier_label = UiTheme.head("", UiTheme.FONT_BODY + 4)
	_stage.add_child(_tier_label)
	_round_label = UiTheme.head("", UiTheme.FONT_BODY + 4)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stage.add_child(_round_label)
	_tier_button = _leaf(LeafButton.Colour.ACORN, on_tier)
	var stack_icon: Control = _tier_button.get("_icon")
	_tier_label.reparent(stack_icon, false)
	_tier_label.position = Vector2.ZERO
	_tier_label.size = Vector2(50, 50)
	_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tier_label.add_theme_font_size_override("font_size", UiTheme.MIN_FONT)
	_tier_label.add_theme_color_override("font_color", UiTheme.CREAM)
	_tier_label.add_theme_color_override("font_outline_color", UiTheme.INK)
	_tier_label.add_theme_constant_override("outline_size", 4)
	_refresh_button = _leaf(LeafButton.Colour.BIRCH, on_refresh)
	_freeze_button = _leaf(LeafButton.Colour.FROST, on_freeze)
	_end_button = _leaf(LeafButton.Colour.MOSS, on_end)
	_end_button.set_label_size(61)


func _leaf(colour: LeafButton.Colour, on_press: Callable) -> LeafButton:
	var leaf: LeafButton = LeafButton.new()
	leaf.colour = colour
	leaf.pressed.connect(on_press)
	_stage.add_child(leaf)
	return leaf


## The card as the full text shows it: what a third copy would do, what a fresh golden brings.
func _full_view(zone: String, view: Dictionary) -> Dictionary:
	var full: Dictionary = RecruitView.full_view(zone, view, state).duplicate(true)
	if zone == "board":
		full = RecruitOozes.reader_view(_board, full)
	if zone != "board" or not _scout.visible:
		full.erase("soak_preview")
		full.erase("hunter_take_preview")
	return full


func _show_their_bare_slot(slot: int) -> void:
	var effects: Array = Data.a(_scout_snapshot, "slot_effects")
	var mark: Dictionary = Data.entry(RecruitView.slot_marks({"slot_effects": effects}), slot)
	var note: String = RecruitView.slot_note(mark, slot)
	if not note.is_empty():
		_detail.show_unit(
			{"name": "On their slot", "kind": "spell", "type_word": "Slot", "text": note}
		)


## The tap preview lives in the scrollable text, above the spell's usual targeting hint.
func _ring_aim_card(item: Dictionary) -> Dictionary:
	var note: String = RecruitView.ring_aim_note(state, item)
	if note.is_empty():
		return item
	var card: Dictionary = item.duplicate()
	card["text"] = Data.s(item, "text") + "\n" + note
	return card


## A selected Ring spell keeps its identity while the pointer inspects a destination.
func _hover_ring_aim(selection: Dictionary, zone: String, slot: int, inside: bool) -> void:
	if Data.s(selection, "zone") != "hand":
		return
	var item: Dictionary = Data.entry(Data.a(state, "hand"), Data.i(selection, "index", -1))
	if not item.has("ring_add"):
		return
	var note: String = "Tap where to play it"
	if zone == "board" and inside:
		note = (
			"%s: %s" % [RecruitView.SLOT_NAMES[slot], RecruitView.ring_preview(state, item, slot)]
		)
	_detail.show_unit(_ring_aim_card(item), note)


## Build the trays here; the screen supplies their interaction callbacks.
func _build_shop(wire: Callable) -> void:
	_shelf = ShelfPlank.new()
	_stage.add_child(_shelf)
	_shop_zone = Interactive.new()
	_shop_zone.zone = "shop"
	_shop_zone.index = -1
	wire.call(_shop_zone)
	_stage.add_child(_shop_zone)
	_shop_scroll = ScrollContainer.new()
	_shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_shop_scroll.add_theme_stylebox_override("panel", UiTheme.slip_box(Color.TRANSPARENT, 0, 16))
	_stage.add_child(_shop_scroll)
	_market_controls = Control.new()
	_market_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_market_controls)
	_market_title = UiTheme.head("Market", UiTheme.FONT_BODY + 4)
	_market_title.add_theme_color_override("font_color", UiTheme.CREAM)
	_stage.add_child(_market_title)
	_market_return = LeafButton.new()
	_market_return.set_face("Market", "close")
	_stage.add_child(_market_return)
	_shop_cards = GridContainer.new()
	_shop_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_shop_cards)


func _build_board(wire: Callable, power: Callable, portrait: Callable) -> void:
	_frame = PlayFrame.new()
	_stage.add_child(_frame)
	_stage.move_child(_frame, 0)
	_board = BoardView.new()
	_board.compact = true
	_board.surface_visible = false
	_board.configure("board", BOARD_POCKET, true, true, true)
	for slot: Interactive in _board.slots:
		wire.call(slot)
	_stage.add_child(_board)
	_hero = HeroPlaque.new()
	_hero.visible = false
	_hero.power_pressed.connect(power)
	_hero.portrait_pressed.connect(portrait)
	_stage.add_child(_hero)


func _build_hand(wire: Callable) -> void:
	_hand_zone = Interactive.new()
	_hand_zone.zone = "hand"
	_hand_zone.index = -1
	wire.call(_hand_zone)
	_stage.add_child(_hand_zone)
	_hand_panel = WoodPanel.new(WoodPanel.Kind.OAK)
	_hand_zone.add_child(_hand_panel)
	_hand_count = UiTheme.number("", UiTheme.FONT_SMALL)
	_hand_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hand_count.tooltip_text = "Larder: the gold held in your Acorns, Stashes and Great Hoards."
	_hand_zone.add_child(_hand_count)
	_hand_cards = HandFan.new()
	_hand_zone.add_child(_hand_cards)
	_away_tray = AwayTray.new()
	_stage.add_child(_away_tray)


func _build_tools(menu: Callable, scout: Callable, who: Callable, dev: Callable) -> void:
	_menu_token = TokenButton.new("", "gear")
	_menu_token.pressed.connect(menu)
	_stage.add_child(_menu_token)
	_scout_token = TokenButton.new("", "close", UiTheme.FONT_SMALL)
	_scout_token.tooltip_text = "Close scouting"
	_scout_token.pressed.connect(scout)
	_stage.add_child(_scout_token)
	_who_token = TokenButton.new("Who?", "", UiTheme.FONT_SMALL)
	_who_token.pressed.connect(who)
	_who_token.visible = false
	_stage.add_child(_who_token)
	_dev_token = TokenButton.new("Dev")
	_dev_token.pressed.connect(dev)
	_stage.add_child(_dev_token)
	_dev_token.visible = Settings.show_dev_panel


func _play_width() -> float:
	return ArenaGeometry.MARKET.x


func _layout_frame(_left: float, _width: float) -> void:
	_frame.size = _stage.size
	_frame.clear_regions()
	_frame.add_region(ArenaGeometry.board_rect(_stage.size), Surface.Finish.MOSS)
	if _scout.visible:
		_frame.add_region(ArenaGeometry.board_rect(_stage.size, true), Surface.Finish.MOSS)
		_frame.add_region(
			Rect2(ArenaGeometry.hand_rect(_stage.size).position.x - 12, 16, 416, 510),
			Surface.Finish.STALL
		)
	else:
		_frame.add_region(ArenaGeometry.market_rect(_stage.size), Surface.Finish.STALL)
	if not _hand_cards.cards.is_empty():
		_frame.add_region(ArenaGeometry.hand_rect(_stage.size), Surface.Finish.CLOTH)
	_frame.add_region(Rect2(_hero.position - Vector2(12, 8), Vector2(300, 140)), Surface.Finish.BAR)
	if _lobby.visible:
		_frame.add_region(ArenaGeometry.lobby_rect(_stage.size), Surface.Finish.BARK)
