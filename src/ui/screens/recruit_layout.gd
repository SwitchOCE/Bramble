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
const BoardView := preload("res://src/ui/widgets/board_view.gd")
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
const ShelfPlank := preload("res://src/ui/widgets/shelf_plank.gd")
const GoldPlaque := preload("res://src/ui/widgets/gold_plaque.gd")
const HeroPlaque := preload("res://src/ui/widgets/hero_plaque.gd")
const CardPicker := preload("res://src/ui/widgets/card_picker.gd")
const PauseMenu := preload("res://src/ui/widgets/pause_menu.gd")

const LaneOverlay := preload("res://src/ui/widgets/lane_overlay.gd")
const LaneProjection := preload("res://src/ui/lane_projection.gd")

const CANVAS_H: float = 1080.0
const RIGHT_W: float = 442.0
const DETAIL_W: float = 500.0
const DETAIL_GAP: float = 24.0
const READING_POCKET: float = 180.0
const BOARD_POCKET: float = 209.0
const HAND_W: float = 331.0
const HAND_TOP: float = 489.0
const SHOP_TOP: float = 152.0
const SHELF_Y: float = 384.0
const SHELF_H: float = 57.0
const TILE_GAP: float = 44.0
const READING_TILE_GAP: float = 20.0
const WRAP_MIN: float = 101.0
const END_H: float = 189.0
const LEAF_H: float = 128.0
const TOAST_SECONDS: float = 3.5
## The full hand is always represented by real tiles.
const HAND_SHOWN: int = 10
const HOVER_SECONDS: float = 0.2
## How long a hovered card's panel waits for the pointer to reach it before closing.
const LEAVE_SECONDS: float = 0.3
## Scouting: the shop's small tiles beside their board.
const MINI_TILE: float = 130.0
const MINI_GAP_X: int = 30
const MINI_GAP_Y: int = 30
const SCOUT_TOP: float = 98.0
const SCOUT_SHOP_TOP: float = 160.0
## Two cards in hand stay tall enough for their rules.
const HAND_TWO_H: float = 215.0

var port: GamePort
var state: Dictionary = {}

var _lanes: LaneOverlay
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
var _scout_token: TokenButton
var _who_token: TokenButton


func _layout() -> void:
	if _stage == null or size.x < 10.0:
		return
	var w: float = size.x
	_stage.position = Vector2(0, maxf(0.0, (size.y - CANVAS_H) / 2.0))
	_stage.size = Vector2(w, CANVAS_H)
	var reading: bool = _split_detail()
	var pocket_width: float = READING_POCKET if reading else BOARD_POCKET
	if not is_equal_approx(_board.pocket.x, pocket_width):
		_board.configure("board", pocket_width, true, true, true)
	var board_w: float = _board.tray_size().x
	var content: float = board_w + 51.0 + HAND_W
	var economy_x: float = w - 30.0 - RIGHT_W
	var right_x: float = economy_x - DETAIL_W - DETAIL_GAP if reading else economy_x
	var left: float = WRAP_MIN + maxf(0.0, (right_x - WRAP_MIN - content) / 2.0)
	_lobby.position = Vector2(20, 17)
	_lobby.size = Vector2(w - 54.0, LobbyStrip.HEIGHT)
	_lobby.visible = not _scout.visible
	var token: float = tap_size()
	var late_status: bool = false
	for plaque: Control in _lobby.plaques:
		late_status = late_status or plaque.has_node("LastStand")
	var tools_top: float = 140.0 if late_status else 108.0
	_menu_token.position = Vector2(8, tools_top)
	_menu_token.size = Vector2(token, token + 9.0)
	_scout_token.position = Vector2(8, tools_top + token + 16.0)
	_scout_token.size = Vector2(token, token + 9.0)
	_scout_token.visible = _scout.visible
	_who_token.visible = false
	_who_token.position = Vector2(8, tools_top + (token + 16.0) * 2.0)
	_who_token.size = Vector2(token, token + 9.0)
	_shop_cards.add_theme_constant_override(
		"h_separation", MINI_GAP_X if _scout.visible else int(_shop_gap())
	)
	var shop_w: float = maxf(_shop_width(), board_w + 300.0)
	shop_w = minf(shop_w, right_x - left - 20.0)
	_shelf.position = Vector2(left, SHELF_Y)
	_shelf.size = Vector2(shop_w, SHELF_H)
	_tribes.position = Vector2(left + 20, 93)
	_tribes.visible = not _scout.visible and not _tribes.tribes.is_empty()
	_tribes.size = Vector2(right_x - left - 40, TribeBonuses.HEIGHT)
	_tribes.z_index = _board.z_index + 1 if late_status else 0
	if late_status:
		_tribes.position = Vector2(left + 12, HAND_TOP + 8)
		_tribes.size.x = board_w - 24.0
	_shop_zone.position = Vector2(left, SHOP_TOP - 40.0)
	_shop_zone.size = Vector2(shop_w, SHELF_Y + SHELF_H - SHOP_TOP + 40.0)
	_shop_cards.position = Vector2(left + 30.0, SHOP_TOP)
	_shop_cards.size = Vector2(shop_w - 60.0, CardView.SHOP_HEIGHT)
	var narrow: bool = left < token + 60.0
	_board.position = Vector2(left, HAND_TOP)
	_board.size = _board.tray_size()
	var back: Rect2 = _board.row_rect(false)
	_layout_hero(left + back.position.x - 52.0)
	_layout_hand(left + board_w + 51.0)
	_layout_right(economy_x, w)
	if _dev_token.visible:
		_dev_token.position = Vector2(8, tools_top + (token + 16.0) * 2.0)
		_dev_token.size = Vector2(token, token + 9.0)
		if narrow:
			_dev_token.position = Vector2(8, SHELF_Y + 70.0)
	_dev.position = Vector2(left, 112)
	# Over the lobby strip: it never covers the shop's badges, and the strip is back in a moment.
	_toast.position = Vector2(left + 200.0, 12)
	_size_toast()
	if _scout.visible:
		_layout_scouting(left, right_x)
	_lanes.visible = false
	_shelf.visible = not _scout.visible
	_shop_cards.visible = not _scout.visible
	_shop_zone.visible = not _scout.visible
	_shop_scroll.visible = false
	if not _scout.visible:
		if _shop_cards.get_parent() != _stage:
			_shop_cards.reparent(_stage, false)
		var offers: int = _shop_cards.get_child_count()
		for child: Node in _shop_cards.get_children():
			var card: CardView = child as CardView
			if card != null:
				card.set_card_width(_tile_width(offers))


## Scouting focuses the two boards. The shop and lobby return on the close token.
func _layout_scouting(left: float, right_x: float) -> void:
	_scout.set_column_pitch(_board.pocket.x + _board.gap)
	var offset: float = (
		_board.slot_position(0).x + _board.pocket.x / 2.0 - _scout.first_column_center()
	)
	var x: float = left + offset
	_scout.position = Vector2(x, SCOUT_TOP)
	_scout.heading_offset = 0.0
	_scout.size = Vector2(right_x - 20.0 - x, _scout.tray_height())
	_scout.call("_layout")


## The smallest comfortable tap target at this window's shape, in canvas units.
func tap_size() -> float:
	var view: Vector2 = get_viewport_rect().size if is_inside_tree() else size
	return 122.0 if view.x / maxf(view.y, 1.0) > 2.0 else 104.0


func _layout_hero(right_edge: float) -> void:
	var width: float = clampf(right_edge - 12.0, 150.0, 200.0)
	if _split_detail():
		width = 170.0
	_hero.position = Vector2(maxf(12.0, right_edge - width), 770)
	_hero.size = Vector2(width, 300)


func _layout_hand(x: float) -> void:
	var right_edge: float = size.x - 30.0 - RIGHT_W
	if _split_detail():
		right_edge -= DETAIL_W + DETAIL_GAP
	x = minf(x, right_edge - HAND_W - 24.0)
	var count: int = Data.a(state, "hand").size()
	var card: Vector2 = _hand_card_size(count)
	var columns: int = 1 if count <= 2 else 2
	var rows: int = ceili(count / float(columns))
	# Reserving the same journey row keeps hand tiles and fan spacing stable when Birds fly.
	var maximum: float = CANVAS_H - 24.0 - HAND_TOP - 12.0 - _away_tray.row_height()
	var wanted: float = (
		tap_size()
		if count == 0
		else 66.0 + HandFan.FOCUS_LIFT + rows * card.y + maxf(0, rows - 1) * HandFan.ROW_GAP + 12.0
	)
	var height: float = minf(maximum, wanted)
	_hand_zone.position = Vector2(x, HAND_TOP)
	_hand_zone.size = Vector2(HAND_W, height)
	_hand_panel.position = Vector2.ZERO
	_hand_panel.size = _hand_zone.size
	var has_larder: bool = Data.i(state, "larder") > 0
	_hand_count.position = Vector2(30 if has_larder else 170, 8)
	_hand_count.size = Vector2(HAND_W - (60.0 if has_larder else 200.0), 44)
	_hand_cards.position = Vector2(0, 66)
	_hand_cards.size = Vector2(HAND_W, maxf(0.0, height - 66.0 - 12.0))
	_hand_cards.arrange()
	_away_tray.position = Vector2(x, HAND_TOP + height + 12.0)
	var away_w: float = minf(HAND_W, size.x - 30.0 - RIGHT_W - x - 12.0)
	_away_tray.size = Vector2(away_w, _away_tray.row_height())
	_away_tray.show_state(state)


func _layout_right(x: float, w: float) -> void:
	var leaf_x: float = x
	var leaf_w: float = RIGHT_W
	_gold.position = Vector2(x + 6.0, 122)
	_gold.size = Vector2(RIGHT_W - 12.0, 152)
	_tier_icon.position = Vector2(x + 22.0, 298)
	_tier_icon.size = Vector2(46, 46)
	_tier_label.position = Vector2(x + 76.0, 294)
	_tier_label.size = Vector2(170, 54)
	_round_label.position = Vector2(w - 30.0 - 180.0 - 16.0, 294)
	_round_label.size = Vector2(180, 54)
	var y: float = 362.0
	var tools: Array[LeafButton] = [_tier_button, _refresh_button, _freeze_button]
	var kin: bool = Data.b(state, "ask_for_kin_enabled") and not _detail.visible
	if kin:
		tools.append(_kin_button)
	var tool_h: float = CardDetail.SIDE_ACTION_H if kin else LEAF_H
	for leaf: LeafButton in tools:
		leaf.position = Vector2(leaf_x, y)
		leaf.size = Vector2(leaf_w, tool_h)
		y += tool_h + (2.0 if kin else 22.0)
	_end_button.position = Vector2(leaf_x, CANVAS_H - 24.0 - END_H)
	_end_button.size = Vector2(leaf_w, END_H)
	_detail.position = Vector2(x, 112)
	_detail.size = Vector2(RIGHT_W, _end_button.position.y - 112.0 - 8.0)
	_detail.set_action_column()
	_end_button.set_label_size(61)
	if _split_detail():
		_detail.position.x = x - DETAIL_W - DETAIL_GAP
		_detail.size = Vector2(DETAIL_W, CANVAS_H - 112.0 - 24.0)
		_gold.position.y = 108.0
		_tier_icon.position.y = 270.0
		_tier_label.position.y = 266.0
		_round_label.position.y = 266.0
		var tools_y: float = 322.0
		for leaf: LeafButton in tools:
			leaf.position.y = tools_y
			leaf.size.y = CardDetail.SIDE_ACTION_H
			tools_y += leaf.size.y
		_detail.set_action_column(Rect2(DETAIL_W + DETAIL_GAP, tools_y - 112.0, RIGHT_W, 244))
		_end_button.position.y = CANVAS_H - 24.0 - CardDetail.SIDE_ACTION_H
		_end_button.size.y = CardDetail.SIDE_ACTION_H
		_end_button.set_label_size(UiTheme.FONT_LEAF)
	if not CardView.is_phone() and _detail.visible:
		_detail.position = Vector2(
			clampf(get_local_mouse_position().x + 30.0, 20.0, w - DETAIL_W - 20.0), 110
		)
		_detail.size = Vector2(DETAIL_W, 740)
		if _reader_is_hand():
			# Read across the shop space, left of the whole fan and above every destination.
			_detail.position = Vector2(20, 110)
			_detail.size = Vector2(_hand_zone.position.x - 44.0, HAND_TOP - 122.0)
			# Actions keep their full targets in the economy column, clear of both trays.
			_detail.set_action_column(Rect2(x - 20.0, 252, RIGHT_W, 244))
	var clear: bool = (
		not _detail.visible
		or _split_detail()
		or (not CardView.is_phone() and not _reader_is_hand())
	)
	for node: Control in [
		_gold, _tier_icon, _tier_label, _round_label, _tier_button, _refresh_button, _freeze_button
	]:
		node.visible = clear
	_gold.visible = true
	_kin_button.visible = clear and kin


## Wide phones keep a reader beside the economy column, with every board slot still tappable.
func _split_detail() -> bool:
	return _detail != null and _detail.visible and size.x >= 2200.0


func _on_detail_shown() -> void:
	_layout()


## Every offer at full width, or less when a high tier's six offers need the room.
func _shop_width() -> float:
	var offers: int = maxi(Data.i(state, "shop_size", 4), 4)
	return offers * CardView.SHOP_WIDTH + (offers - 1) * TILE_GAP + 60.0


func _shop_gap() -> float:
	var offers: int = Data.a(state, "shop").size()
	if _split_detail() or (not CardView.is_phone() and offers >= 6):
		return READING_TILE_GAP
	return TILE_GAP


func _tile_width(offers: int) -> float:
	var room: float = _shelf.size.x - 60.0 - (offers - 1) * _shop_gap()
	return minf(CardView.SHOP_WIDTH, floorf(room / maxf(offers, 1.0)))


func _hand_card_size(count: int) -> Vector2:
	if count <= 1:
		return Vector2(CardView.SHOP_WIDTH, CardView.SHOP_HEIGHT)
	if count == 2:
		return Vector2(CardView.SHOP_WIDTH, HAND_TWO_H)
	return Vector2(130, 130)


func _size_toast() -> void:
	if _toast.visible:
		_toast.size = _toast.get_minimum_size()
		var room: float = size.x - 480.0
		_toast.position.x = maxf(20.0, (room - _toast.size.x) / 2.0)


# --- what a selection lights up ---------------------------------------------------------------


func _highlight_empty_slots() -> void:
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
			if RecruitView.ring_preview(state, item, slot) == "Full":
				_board.slots[slot].highlight = UiTheme.OUT_FACE
				if has_unit:
					_board.cards[slot].outline = UiTheme.OUT_MARK
			continue
		if has_unit:
			_board.cards[slot].outline = UiTheme.DROP_OK
		else:
			_board.slots[slot].highlight = UiTheme.DROP_OK


func _highlight_other_slots(from_slot: int) -> void:
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
	var effects: Array = Data.a(state, "next_opponent_last_slot_effects")
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
	_shop_cards = GridContainer.new()
	_shop_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_shop_cards)


func _build_board(wire: Callable, power: Callable, portrait: Callable) -> void:
	_board = BoardView.new()
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


## Identify the hand reader before the fan focus signal arrives.
func _reader_is_hand() -> bool:
	var shown: Dictionary = _detail.shown
	for card: CardView in _hand_cards.cards:
		if Data.i(shown, "iid", -1) > 0 and Data.i(card.unit, "iid", -2) == Data.i(shown, "iid"):
			return true
		if (
			Data.i(shown, "card_index", -1) >= 0
			and Data.i(card.unit, "card_index", -2) == Data.i(shown, "card_index")
		):
			return true
	return false
