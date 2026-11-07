extends Control
## The recruit screen's nodes and where they stand, with no behaviour: RecruitScreen builds them,
## fills them from the state and handles the taps.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const ScoutPanel := preload("res://src/ui/widgets/scout_panel.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const LobbyStrip := preload("res://src/ui/widgets/lobby_strip.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const DevPanel := preload("res://src/ui/widgets/dev_panel.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")
const RowTag := preload("res://src/ui/widgets/row_tag.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const ShelfPlank := preload("res://src/ui/widgets/shelf_plank.gd")
const GoldPlaque := preload("res://src/ui/widgets/gold_plaque.gd")
const HeroPlaque := preload("res://src/ui/widgets/hero_plaque.gd")
const CardPicker := preload("res://src/ui/widgets/card_picker.gd")
const PauseMenu := preload("res://src/ui/widgets/pause_menu.gd")

const CANVAS_H: float = 1080.0
const RIGHT_W: float = 442.0
const BOARD_POCKET: float = 209.0
const HAND_W: float = 331.0
const HAND_TOP: float = 469.0
const SHOP_TOP: float = 152.0
const SHELF_Y: float = 384.0
const SHELF_H: float = 57.0
const TILE_GAP: float = 44.0
const WRAP_MIN: float = 101.0
const END_H: float = 189.0
const LEAF_H: float = 128.0
const TOAST_SECONDS: float = 3.5
## Past this many cards the hand shows five and a "+N more" button.
const HAND_SHOWN: int = 6
const HOVER_SECONDS: float = 0.2
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

var _stage: Control
var _lobby: LobbyStrip
var _menu_token: TokenButton
var _dev_token: TokenButton
var _shop_tag: RowTag
var _front_tag: RowTag
var _back_tag: RowTag
var _shop_zone: Interactive
var _shelf: ShelfPlank
var _shop_cards: GridContainer
var _board: BoardView
var _hand_zone: Interactive
var _hand_panel: WoodPanel
var _hand_title: Label
var _hand_count: Label
var _hand_cards: GridContainer
var _hand_hint: Label
var _board_chip: Label
var _gold: GoldPlaque
var _tier_icon: TextureRect
var _tier_label: Label
var _round_label: Label
var _tier_button: LeafButton
var _refresh_button: LeafButton
var _freeze_button: LeafButton
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
	var board_w: float = _board.tray_size().x
	var content: float = board_w + 51.0 + HAND_W
	var right_x: float = w - 30.0 - RIGHT_W
	var left: float = WRAP_MIN + maxf(0.0, (right_x - WRAP_MIN - content) / 2.0)
	_lobby.position = Vector2(20, 17)
	_lobby.size = Vector2(w - 54.0, LobbyStrip.HEIGHT)
	var token: float = tap_size()
	_menu_token.position = Vector2(8, 108)
	_menu_token.size = Vector2(token, token + 9.0)
	_scout_token.position = Vector2(8, 108.0 + token + 16.0)
	_scout_token.size = Vector2(token, token + 9.0)
	_who_token.position = Vector2(8, 108.0 + (token + 16.0) * 2.0)
	_who_token.size = Vector2(token, token + 9.0)
	var shop_w: float = maxf(_shop_width(), board_w + 300.0)
	shop_w = minf(shop_w, right_x - left - 20.0)
	_shelf.position = Vector2(left, SHELF_Y)
	_shelf.size = Vector2(shop_w, SHELF_H)
	_shop_zone.position = Vector2(left, SHOP_TOP - 40.0)
	_shop_zone.size = Vector2(shop_w, SHELF_Y + SHELF_H - SHOP_TOP + 40.0)
	_shop_cards.position = Vector2(left + 30.0, SHOP_TOP)
	_shop_cards.size = Vector2(shop_w - 60.0, CardView.SHOP_HEIGHT)
	# 16:9: the tag stands lower, under the tools in the same narrow margin.
	var narrow: bool = left < token + 60.0
	var shop_tag_y: float = 352.0 if narrow else SHOP_TOP + 60.0
	_place_tag(_shop_tag, Vector2(left - 56.0, shop_tag_y), 100.0 if narrow else 180.0)
	_board.position = Vector2(left, HAND_TOP)
	_board.size = _board.tray_size()
	var row_h: float = _board.row_rect(true).size.y
	_place_tag(_front_tag, Vector2(left - 50.0, HAND_TOP + 60.0), row_h - 90.0)
	var back: Rect2 = _board.row_rect(false)
	var back_at: Vector2 = Vector2(left + back.position.x - 46.0, HAND_TOP + back.position.y + 60.0)
	_place_tag(_back_tag, back_at, 150.0)
	_layout_hero(left + back.position.x - 52.0)
	_layout_hand(left + board_w + 51.0)
	_layout_right(right_x, w)
	if _dev_token.visible:
		_dev_token.position = Vector2(8, 108.0 + (token + 16.0) * 2.0)
		_dev_token.size = Vector2(token, token + 9.0)
		if narrow:
			_dev_token.position = Vector2(8, SHELF_Y + 70.0)
	_dev.position = Vector2(left, 112)
	# Over the lobby strip: it never covers the shop's badges, and the strip is back in a moment.
	_toast.position = Vector2(left + 200.0, 12)
	_size_toast()
	if _scout.visible:
		_layout_scouting(left, right_x)
	_shelf.visible = not _scout.visible


## Their board takes the shop's place; the shop's small tiles stand beside it, so your board, your
## hand and every button stay where they were.
func _layout_scouting(left: float, right_x: float) -> void:
	var x: float = left + 14.0
	var room: float = right_x - 20.0 - x
	_scout.position = Vector2(x, SCOUT_TOP)
	_scout.size = Vector2(room, _scout.tray_height())
	var shop_x: float = x + _scout.tray_width() + 56.0
	_place_tag(_shop_tag, Vector2(shop_x - 48.0, SCOUT_SHOP_TOP + 60.0), 140.0)
	_shop_cards.position = Vector2(shop_x, SCOUT_SHOP_TOP)
	_shop_cards.size = Vector2.ZERO
	_shop_zone.position = Vector2(shop_x - 20.0, SCOUT_SHOP_TOP - 10.0)
	_shop_zone.size = Vector2(right_x - shop_x, HAND_TOP - SCOUT_SHOP_TOP)


## The smallest comfortable tap target at this window's shape, in canvas units.
func tap_size() -> float:
	var view: Vector2 = get_viewport_rect().size if is_inside_tree() else size
	return 122.0 if view.x / maxf(view.y, 1.0) > 2.0 else 104.0


func _place_tag(tag: RowTag, top_left: Vector2, height: float) -> void:
	tag.position = top_left
	tag.size = Vector2(RowTag.WIDTH, height)


func _layout_hero(right_edge: float) -> void:
	var width: float = clampf(right_edge - 12.0, 150.0, 200.0)
	_hero.position = Vector2(right_edge - width, 770)
	_hero.size = Vector2(width, 300)


func _layout_hand(x: float) -> void:
	var count: int = Data.a(state, "hand").size()
	var bottom: float = 905.0 if count <= 1 else 1000.0
	_hand_zone.position = Vector2(x, HAND_TOP)
	_hand_zone.size = Vector2(HAND_W, bottom - HAND_TOP)
	_hand_panel.position = Vector2.ZERO
	_hand_panel.size = _hand_zone.size
	_hand_title.position = Vector2(30, 8)
	_hand_title.size = Vector2(150, 50)
	_hand_count.position = Vector2(170, 12)
	_hand_count.size = Vector2(HAND_W - 200.0, 44)
	_hand_hint.position = Vector2(24, 90)
	_hand_hint.size = Vector2(HAND_W - 48.0, 200)
	var card_w: float = _hand_card_size(count).x
	var columns: int = 2 if count >= 3 else 1
	var gap: float = 43.0 if columns == 2 else 0.0
	var grid_w: float = card_w * columns + gap * (columns - 1)
	_hand_cards.position = Vector2((HAND_W - grid_w) / 2.0, 66)
	_hand_cards.size = Vector2(grid_w, 0)
	_board_chip.position = Vector2(x + (HAND_W - 200.0) / 2.0, bottom + 28.0)
	_board_chip.size = Vector2(200, 50)
	_board_chip.visible = bottom + 78.0 < CANVAS_H


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
	for leaf: LeafButton in [_tier_button, _refresh_button, _freeze_button]:
		leaf.position = Vector2(leaf_x, y)
		leaf.size = Vector2(leaf_w, LEAF_H)
		y += LEAF_H + 22.0
	_end_button.position = Vector2(leaf_x, CANVAS_H - 24.0 - END_H)
	_end_button.size = Vector2(leaf_w, END_H)
	_detail.position = Vector2(x, 112)
	_detail.size = Vector2(RIGHT_W, _end_button.position.y - 112.0 - 8.0)


## The full card takes the column: the plaques and leaves under it step aside, End turn stays.
func _on_detail_shown() -> void:
	var clear: bool = not _detail.visible
	for node: Control in [
		_gold, _tier_icon, _tier_label, _round_label, _tier_button, _refresh_button, _freeze_button
	]:
		node.visible = clear


## Every offer at full width, or less when a high tier's six offers need the room.
func _shop_width() -> float:
	var offers: int = maxi(Data.i(state, "shop_size", 4), 4)
	return offers * CardView.SHOP_WIDTH + (offers - 1) * TILE_GAP + 60.0


func _tile_width(offers: int) -> float:
	var room: float = _shelf.size.x - 60.0 - (offers - 1) * TILE_GAP
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
	if Data.s(item, "aim") == "shop_unit":
		for card: Node in _shop_cards.get_children():
			if card is CardView and not CardView.is_spell((card as CardView).unit):
				(card as CardView).outline = UiTheme.DROP_OK
		return
	for slot: int in BoardView.SLOTS:
		var has_unit: bool = _board.cards[slot] != null
		var target: Dictionary = _board.cards[slot].unit if has_unit else {}
		if not RecruitView.item_lands(item, target, slot):
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
