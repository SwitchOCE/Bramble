extends Control
## The recruit phase, laid out as the mock (docs/design-lab/r2/woodcraft): lobby across the top, the
## shop on its shelf, the brick-shaped tray, the hand on its own tray, gold and leaf buttons on the
## right, the hero in the corner the brick leaves free. Renders GamePort.get_state() (SPEC 6.1) and
## never changes it: every action goes through the port, then the screen re-reads the state.
##
## Every drag has a tap alternative:
## - buy: drag a shop card to the hand or an empty slot, or tap it and press Buy;
## - play: drag a hand card to an empty slot, or tap it, then tap an empty slot;
## - move or swap: drag a board unit to another slot, or tap it, then tap the other slot;
## - sell: drag a board unit onto the shop, or tap it and press Sell.

signal combat_ready
signal menu_requested
signal game_over_reached
## The dev panel asked for a new game from this seed.
signal replay_requested(game_seed: int)
## The pause menu asked for these; the app opens them over this screen.
signal guide_requested
signal settings_requested

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
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
var _shop_cards: HBoxContainer
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
var _toast_timer: Timer
var _hover_timer: Timer
var _hover_view: Dictionary = {}
var _dev: DevPanel
var _discover: CardPicker
var _pause: PauseMenu
## {"zone": String, "index": int} of the tapped card, or {} for none.
var _selected: Dictionary = {}


func setup(game_port: GamePort) -> void:
	port = game_port
	_dev.setup(port)
	render()


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiTheme.add_table(self)
	var blank: Interactive = Interactive.new()
	blank.set_anchors_preset(Control.PRESET_FULL_RECT)
	blank.zone = "table"
	blank.tapped.connect(_on_tapped)
	add_child(blank)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_lobby = LobbyStrip.new()
	_stage.add_child(_lobby)
	_build_shop()
	_build_board()
	_build_hand()
	_build_right()
	_build_tools()
	_detail = CardDetail.new()
	_stage.add_child(_detail)
	_detail.visibility_changed.connect(_on_detail_shown)
	_toast = UiTheme.head("", UiTheme.FONT_BODY)
	_toast.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 5, 14))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.z_index = 20
	_toast.visible = false
	_stage.add_child(_toast)
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(_clear_toast)
	add_child(_toast_timer)
	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.timeout.connect(_show_hover)
	add_child(_hover_timer)
	_dev = DevPanel.new()
	_dev.visible = false
	_dev.z_index = 30
	_dev.changed.connect(func() -> void: _after_change(false))
	_dev.turn_skipped.connect(_on_turn_skipped)
	_dev.replay_requested.connect(func(game_seed: int) -> void: replay_requested.emit(game_seed))
	_stage.add_child(_dev)
	resized.connect(_layout)
	ready.connect(_layout)
	_layout()


func _build_shop() -> void:
	_shop_tag = RowTag.new("Shop")
	_stage.add_child(_shop_tag)
	_shelf = ShelfPlank.new()
	_stage.add_child(_shelf)
	_shop_zone = Interactive.new()
	_shop_zone.zone = "shop"
	_shop_zone.index = -1
	_wire(_shop_zone)
	_stage.add_child(_shop_zone)
	_shop_cards = HBoxContainer.new()
	_shop_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_cards.add_theme_constant_override("separation", int(TILE_GAP))
	_stage.add_child(_shop_cards)


func _build_board() -> void:
	_front_tag = RowTag.new("Front")
	_stage.add_child(_front_tag)
	_back_tag = RowTag.new("Back")
	_stage.add_child(_back_tag)
	_board = BoardView.new()
	_board.configure("board", BOARD_POCKET, true, true, true)
	for slot: Interactive in _board.slots:
		_wire(slot)
	_stage.add_child(_board)
	_hero = HeroPlaque.new()
	_hero.visible = false
	_hero.power_pressed.connect(_on_hero_power)
	_hero.portrait_pressed.connect(_on_hero_tapped)
	_stage.add_child(_hero)


func _build_hand() -> void:
	_hand_zone = Interactive.new()
	_hand_zone.zone = "hand"
	_hand_zone.index = -1
	_wire(_hand_zone)
	_stage.add_child(_hand_zone)
	_hand_panel = WoodPanel.new(WoodPanel.Kind.OAK)
	_hand_zone.add_child(_hand_panel)
	_hand_title = UiTheme.head("Hand", UiTheme.FONT_BODY + 2)
	_hand_zone.add_child(_hand_title)
	_hand_count = UiTheme.number("", UiTheme.FONT_SMALL)
	_hand_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hand_zone.add_child(_hand_count)
	_hand_cards = GridContainer.new()
	_hand_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_zone.add_child(_hand_cards)
	_hand_hint = UiTheme.label(
		"Bought units wait here. Drag one to an empty slot.", UiTheme.FONT_SMALL, UiTheme.INK
	)
	_hand_hint.add_theme_font_override("font", UiTheme.bold_font())
	_hand_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hand_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hand_zone.add_child(_hand_hint)
	_board_chip = UiTheme.number("", UiTheme.FONT_SMALL)
	_board_chip.add_theme_stylebox_override("normal", UiTheme.slip_box(UiTheme.BIRCH, 4, 12))
	_board_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stage.add_child(_board_chip)


func _build_right() -> void:
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
	_tier_button = _leaf(LeafButton.Colour.ACORN, _on_tier_up)
	_refresh_button = _leaf(LeafButton.Colour.BIRCH, _on_refresh)
	_freeze_button = _leaf(LeafButton.Colour.FROST, _on_freeze)
	_end_button = _leaf(LeafButton.Colour.MOSS, _on_end_turn)
	_end_button.set_label_size(61)


func _leaf(colour: LeafButton.Colour, on_press: Callable) -> LeafButton:
	var leaf: LeafButton = LeafButton.new()
	leaf.colour = colour
	leaf.pressed.connect(on_press)
	_stage.add_child(leaf)
	return leaf


func _build_tools() -> void:
	_menu_token = TokenButton.new("", "gear")
	_menu_token.pressed.connect(_open_pause)
	_stage.add_child(_menu_token)
	_dev_token = TokenButton.new("Dev")
	_dev_token.pressed.connect(toggle_dev_panel)
	_stage.add_child(_dev_token)
	_dev_token.visible = Settings.show_dev_panel


## Connects a card, slot or zone to this screen's tap, hover and drag-and-drop handlers.
func _wire(node: Interactive) -> void:
	node.tapped.connect(_on_tapped)
	node.hovered.connect(_on_hovered)
	node.drag_started.connect(_on_drag_started)
	node.drag_data_fn = _drag_data
	node.can_drop_fn = _can_drop
	node.drop_fn = _drop
	node.preview_fn = _drag_preview


# --- layout --------------------------------------------------------------------------------


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
	var shop_w: float = maxf(_shop_width(), board_w + 300.0)
	shop_w = minf(shop_w, right_x - left - 20.0)
	_shelf.position = Vector2(left, SHELF_Y)
	_shelf.size = Vector2(shop_w, SHELF_H)
	_shop_zone.position = Vector2(left, SHOP_TOP - 40.0)
	_shop_zone.size = Vector2(shop_w, SHELF_Y + SHELF_H - SHOP_TOP + 40.0)
	_shop_cards.position = Vector2(left + 30.0, SHOP_TOP)
	_shop_cards.size = Vector2(shop_w - 60.0, CardView.SHOP_HEIGHT)
	_place_tag(_shop_tag, Vector2(left - 56.0, SHOP_TOP + 60.0), 180.0)
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
		_dev_token.position = Vector2(8, 108.0 + token + 16.0)
		_dev_token.size = Vector2(token, token + 9.0)
		if left < token + 60.0:
			# 16:9: the corner beside the shop tag is the only free spot.
			_dev_token.position = Vector2(8, SHELF_Y - 20.0)
	_dev.position = Vector2(left, 112)
	_toast.position = Vector2(left + 200.0, 100)
	_size_toast()


## The smallest comfortable tap target at this window's shape, in canvas units.
func tap_size() -> float:
	var view: Vector2 = get_viewport_rect().size if is_inside_tree() else size
	return 122.0 if view.x / maxf(view.y, 1.0) > 2.0 else 90.0


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
		return CardView.size_for(215.0, CardView.Mode.BOARD)
	return Vector2(130, 130)


# --- rendering -----------------------------------------------------------------------------


func render() -> void:
	state = RecruitView.with_cards(port.get_state()) if port != null else {}
	if state.is_empty():
		return
	_gold.show_gold(Data.i(state, "gold", 0))
	_tier_label.text = "Tier %d" % Data.i(state, "tier", 1)
	_round_label.text = "Turn %d" % Data.i(state, "round", 1)
	var tier_cost: Variant = state.get("tier_up_cost")
	if tier_cost == null:
		_tier_button.set_face("Top tier", "tier")
		_tier_button.disabled = true
	else:
		_tier_button.set_face("Tier up", "tier", Data.as_int(tier_cost))
		_tier_button.disabled = false
	_refresh_button.set_face("Refresh", "refresh", Data.i(state, "refresh_cost", 1))
	var frozen: bool = Data.b(state, "frozen", false)
	_freeze_button.set_face("Unfreeze" if frozen else "Freeze", "freeze")
	_end_button.set_face("End turn", "", -1, RecruitView.fight_note(state))
	_lobby.show_standings(Data.a(state, "standings"), Data.i(state, "next_opponent_id", -2))
	_layout()
	_render_shop(frozen)
	_render_board()
	_render_hand()
	_hero.show_hero(Data.d(state, "hero"), Data.i(state, "gold", 0))
	_show_selection()
	_render_discover()


func _render_shop(frozen: bool) -> void:
	_clear(_shop_cards)
	var shop: Array = Data.a(state, "shop")
	var width: float = _tile_width(shop.size())
	_shelf.selling = false
	_shop_cards.modulate = Color.WHITE
	for i: int in shop.size():
		var view: Dictionary = shop[i]
		var card: CardView = _make_card(view, "shop", i, width, CardView.Mode.SHOP)
		card.frost = frozen
		if frozen and i == 0:
			card.show_frost_tag(true)
		_shop_cards.add_child(card)


func _render_board() -> void:
	_board.clear()
	var board: Array = Data.a(state, "board")
	var units: int = 0
	for slot: int in mini(board.size(), BoardView.SLOTS):
		if board[slot] is Dictionary:
			units += 1
			var view: Dictionary = Data.entry(board, slot)
			_board.place_card(_make_card(view, "board", slot, 189.0, CardView.Mode.BOARD), slot)
	_board_chip.text = "Board %d/%d" % [units, BoardView.SLOTS]


func _render_hand() -> void:
	_clear(_hand_cards)
	var hand: Array = Data.a(state, "hand")
	_hand_count.text = "%d/%d" % [hand.size(), Data.i(state, "hand_limit", 10)]
	_hand_hint.visible = hand.is_empty()
	var count: int = hand.size()
	var card_size: Vector2 = _hand_card_size(count)
	_hand_cards.columns = 2 if count >= 3 else 1
	_hand_cards.add_theme_constant_override("h_separation", 43)
	_hand_cards.add_theme_constant_override("v_separation", 22 if count <= 2 else 26)
	var shown: int = count if count <= HAND_SHOWN else HAND_SHOWN - 1
	var mode: CardView.Mode = CardView.Mode.SHOP
	if count == 2:
		mode = CardView.Mode.BOARD
	elif count > 2:
		mode = CardView.Mode.MINI
	for i: int in shown:
		var view: Dictionary = hand[i]
		var card: CardView = _make_card(view, "hand", i, card_size.x, mode)
		card.set_card_size(card_size)
		_hand_cards.add_child(card)
	if count > shown:
		_hand_cards.add_child(_more_button(count - shown, card_size))


## The rest of a crowded hand is one tap away.
func _more_button(more: int, tile: Vector2) -> Button:
	var button: Button = UiTheme.button("+%d more" % more, 0, UiTheme.FONT_SMALL)
	button.custom_minimum_size = Vector2(tile.x, maxf(tile.y, tap_size()))
	button.pressed.connect(_open_hand_picker)
	return button


func _open_hand_picker() -> void:
	var picker: CardPicker = CardPicker.new()
	picker.picked.connect(_on_hand_picked)
	picker.show_cards("Your hand", Data.a(state, "hand"), true)
	add_child(picker)


func _on_hand_picked(index: int) -> void:
	_selected = {"zone": "hand", "index": index}
	_show_selection()


func _make_card(
	view: Dictionary, zone: String, index: int, width: float, mode: CardView.Mode
) -> CardView:
	var card: CardView = CardView.new()
	card.show_unit(view, mode)
	card.set_card_width(width)
	card.zone = zone
	card.index = index
	_wire(card)
	return card


func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


## A choice (state "pending_choice": a Discover, or the hero at the start) opens as soon as it
## appears and can't be dismissed.
func _render_discover() -> void:
	var choice: Dictionary = Data.d(state, "pending_choice")
	var options: Array = Data.a(choice, "options")
	if options.is_empty():
		if _discover != null:
			_discover.queue_free()
			_discover = null
		return
	if _discover == null:
		_discover = CardPicker.new()
		_discover.picked.connect(_on_discover_picked)
		add_child(_discover)
	if Data.s(choice, "kind") == "hero":
		_discover.show_cards("Choose your hero", RecruitView.hero_cards(options), false)
	else:
		_discover.show_cards("Discover: pick one", options, false)


func _on_discover_picked(index: int) -> void:
	_discover = null
	_act(port.choose(index))


# --- selection and the detail panel -------------------------------------------------------


func _unit_at(zone: String, index: int) -> Dictionary:
	var items: Array = []
	match zone:
		"shop":
			items = Data.a(state, "shop")
		"hand":
			items = Data.a(state, "hand")
		"board":
			items = Data.a(state, "board")
	if index < 0 or index >= items.size():
		return {}
	var entry: Variant = items[index]
	return entry if entry is Dictionary else {}


func _show_selection() -> void:
	_board.clear_highlights()
	for card: Node in _shop_cards.get_children() + _hand_cards.get_children():
		if card is CardView:
			(card as CardView).selected = false
	_detail.clear_actions()
	if _selected.is_empty():
		_detail.show_empty()
		return
	var zone: String = _selected["zone"]
	var index: int = _selected["index"]
	if zone == "power":
		var hero: Dictionary = Data.d(state, "hero")
		_detail.show_unit(RecruitView.hero_card(hero), "Tap where to use it")
		_highlight_aim(Data.s(hero, "aim", "none"))
		return
	var view: Dictionary = _unit_at(zone, index)
	if view.is_empty():
		_selected = {}
		_detail.show_empty()
		return
	var card: CardView = _card_at(zone, index)
	if card != null:
		card.selected = true
	match zone:
		"shop":
			_detail.show_unit(view)
			var cost: int = Data.i(view, "cost", -1)
			_detail.add_action("Buy", _on_buy_selected, cost)
		"hand":
			var aim: String = Data.s(view, "aim", "none")
			if CardView.is_spell(view) and aim == "none":
				_detail.show_unit(view)
				_detail.add_action("Play", _on_spell_selected)
			elif CardView.is_spell(view):
				_detail.show_unit(view, "Tap where to play it")
				_highlight_aim(aim)
			else:
				_detail.show_unit(view, "Tap an empty slot to play it")
				_highlight_empty_slots()
		"board":
			_detail.show_unit(view, "Tap a slot to move or swap")
			_detail.add_action("Sell", _on_sell_selected, 1)
			_highlight_other_slots(index)


func _card_at(zone: String, index: int) -> CardView:
	match zone:
		"board":
			return _board.cards[index] if index >= 0 and index < BoardView.SLOTS else null
		"shop", "hand":
			var holder: Node = _hand_cards
			if zone == "shop":
				holder = _shop_cards
			if index >= 0 and index < holder.get_child_count():
				return holder.get_child(index) as CardView
	return null


func _highlight_empty_slots() -> void:
	for slot: int in BoardView.SLOTS:
		if _board.cards[slot] == null:
			_board.slots[slot].highlight = UiTheme.DROP_OK


func _highlight_aim(aim: String) -> void:
	for slot: int in BoardView.SLOTS:
		var has_unit: bool = _board.cards[slot] != null
		if not RecruitView.aim_fits(aim, has_unit):
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


## A mouse resting on a card opens its full text, after a moment so sweeping across doesn't flicker.
func _on_hovered(zone: String, index: int, inside: bool) -> void:
	if not _selected.is_empty():
		return
	var view: Dictionary = _unit_at(zone, index) if inside else {}
	_hover_view = view
	if view.is_empty():
		_hover_timer.stop()
		_detail.show_empty()
		_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_hover_timer.start(HOVER_SECONDS)


func _show_hover() -> void:
	if not _hover_view.is_empty() and _selected.is_empty():
		_detail.show_unit(_hover_view)
		_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_tapped(zone: String, index: int) -> void:
	_hover_timer.stop()
	var has_unit: bool = not _unit_at(zone, index).is_empty()
	var from_zone: String = str(_selected.get("zone", ""))
	var from_index: int = Data.i(_selected, "index", -1)
	if zone == "board" and not _selected.is_empty():
		if from_zone == "power":
			if RecruitView.aim_fits(Data.s(Data.d(state, "hero"), "aim", "none"), has_unit):
				_act(port.use_power(index))
				return
		elif from_zone == "hand" and CardView.is_spell(_unit_at("hand", from_index)):
			var item: Dictionary = _unit_at("hand", from_index)
			var aim: String = Data.s(item, "aim", "none")
			if aim != "none" and RecruitView.aim_fits(aim, has_unit):
				_act(port.play_item(Data.i(item, "card_index", -1), index))
				return
		elif (
			from_zone == "hand"
			and RecruitView.can_play_on(_unit_at("hand", from_index), _unit_at("board", index))
		):
			_act(port.play(from_index, index))
			return
		if from_zone == "board" and index != from_index:
			_act(port.move(from_index, index))
			return
	if has_unit and not (from_zone == zone and from_index == index):
		_selected = {"zone": zone, "index": index}
	else:
		_selected = {}
	_show_selection()


func _on_buy_selected() -> void:
	_act(_buy_at(Data.i(_selected, "index", -1)))


func _buy_at(index: int) -> String:
	var view: Dictionary = _unit_at("shop", index)
	if CardView.is_spell(view):
		return port.buy_spell(Data.i(view, "card_index", -1))
	return port.buy(index)


func _on_sell_selected() -> void:
	_act(port.sell(Data.i(_selected, "index", -1)))


func _on_spell_selected() -> void:
	var item: Dictionary = _unit_at("hand", Data.i(_selected, "index", -1))
	_act(port.play_item(Data.i(item, "card_index", -1)))


func _on_hero_power() -> void:
	if Data.s(Data.d(state, "hero"), "aim", "none") == "none":
		_act(port.use_power())
		return
	_selected = {"zone": "power", "index": 0}
	_show_selection()


func _on_hero_tapped() -> void:
	_selected = {}
	_show_selection()
	var card: Dictionary = RecruitView.hero_card(Data.d(state, "hero"))
	var armor: int = Data.i(state, "armor", 0)
	if armor > 0:
		card["text"] = "%s\nArmor %d: hits take this off first." % [Data.s(card, "text"), armor]
	_detail.show_unit(card)


# --- drag and drop -------------------------------------------------------------------------


func _drag_data(zone: String, index: int) -> Variant:
	if zone not in ["shop", "hand", "board"] or _unit_at(zone, index).is_empty():
		return null
	_hover_timer.stop()
	_detail.show_empty()
	return {"zone": zone, "index": index}


func _drag_preview(zone: String, index: int) -> Control:
	var holder: Control = Control.new()
	var card: CardView = CardView.new()
	card.show_unit(_unit_at(zone, index), CardView.Mode.BOARD)
	card.set_card_width(_board.tile_width())
	card.modulate = Color(1, 1, 1, 0.9)
	card.position = -card.card_size / 2.0
	holder.add_child(card)
	return holder


func _can_drop(data: Variant, zone: String, index: int) -> bool:
	if not data is Dictionary:
		return false
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	var from_index: int = Data.i(drag, "index", -1)
	var target_empty: bool = _unit_at(zone, index).is_empty()
	match zone:
		"board":
			return _can_drop_on_board(from_zone, from_index, index, target_empty)
		"hand":
			return from_zone == "shop"
		"shop":
			return from_zone == "board"
	return false


func _can_drop_on_board(from_zone: String, from_index: int, slot: int, empty: bool) -> bool:
	if from_zone == "board":
		return slot != from_index
	var card: Dictionary = _unit_at(from_zone, from_index)
	if CardView.is_spell(card):
		var aim: String = Data.s(card, "aim", "none")
		return from_zone == "hand" and RecruitView.aim_fits(aim, not empty)
	return from_zone in ["hand", "shop"] and RecruitView.can_play_on(card, _unit_at("board", slot))


func _drop(data: Variant, zone: String, index: int) -> void:
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	var from_index: int = Data.i(drag, "index", -1)
	_selected = {}
	match [from_zone, zone]:
		["shop", "hand"]:
			_act(_buy_at(from_index))
		["shop", "board"]:
			_act(_buy_and_play(from_index, index))
		["hand", "board"]:
			var card: Dictionary = _unit_at("hand", from_index)
			if CardView.is_spell(card):
				var aimed: bool = Data.s(card, "aim", "none") != "none"
				_act(port.play_item(Data.i(card, "card_index", -1), index if aimed else -1))
			else:
				_act(port.play(from_index, index))
		["board", "board"]:
			_act(port.move(from_index, index))
		["board", "shop"]:
			_act(port.sell(from_index))


## Shop to board: buy, then play whatever the buy put in the hand. That is the bought unit
## (same iid), or, if the buy made a triple, the one new hand unit (the golden). Never assumes
## the hand's last slot.
func _buy_and_play(shop_index: int, slot: int) -> String:
	var before: Dictionary = {}
	for entry: Variant in Data.a(port.get_state(), "hand"):
		var old: Dictionary = entry
		before[Data.i(old, "iid", -1)] = true
	var bought_iid: int = Data.i(Data.entry(Data.a(state, "shop"), shop_index), "iid", -1)
	var reason: String = port.buy(shop_index)
	if not reason.is_empty():
		return reason
	var hand: Array = Data.a(port.get_state(), "hand")
	var new_index: int = -1
	var new_count: int = 0
	for i: int in hand.size():
		var iid: int = Data.i(Data.entry(hand, i), "iid", -1)
		if iid == bought_iid:
			return port.play(i, slot)
		if not before.has(iid):
			new_index = i
			new_count += 1
	if new_count == 1:
		return port.play(new_index, slot)
	return "Bought; it's in your hand"


func _on_drag_started(zone: String, index: int) -> void:
	_board.clear_highlights()
	match zone:
		"shop", "hand":
			_highlight_empty_slots()
		"board":
			_highlight_other_slots(index)
			_shelf.selling = true
			_shop_cards.modulate = Color(1, 1, 1, 0.35)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and port != null:
		render()


func toggle_dev_panel() -> void:
	_dev.visible = not _dev.visible
	_dev.refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_QUOTELEFT and Settings.show_dev_panel:
		toggle_dev_panel()
		accept_event()
	elif key.keycode == KEY_ESCAPE:
		_open_pause()
		accept_event()


func _open_pause() -> void:
	if _pause != null:
		return
	_pause = PauseMenu.new()
	_pause.closed.connect(func() -> void: _pause = null)
	_pause.guide_requested.connect(func() -> void: guide_requested.emit())
	_pause.settings_requested.connect(func() -> void: settings_requested.emit())
	_pause.leave_requested.connect(func() -> void: menu_requested.emit())
	add_child(_pause)


## After the settings overlay closes: the dev button follows its setting straight away.
func refresh_settings() -> void:
	_dev_token.visible = Settings.show_dev_panel
	if not Settings.show_dev_panel:
		_dev.visible = false
	_layout()


## A skipped turn has no fight: re-read the new round, or end the game if the human is out.
func _on_turn_skipped() -> void:
	_selected = {}
	if port.is_over() or port.get_state().get("placement") != null:
		game_over_reached.emit()
		return
	render()
	_dev.refresh()


# --- actions -------------------------------------------------------------------------------


## Shows a refused action's reason, or clears the selection and re-reads the state on success.
func _act(reason: String) -> void:
	if reason.is_empty():
		_selected = {}
		_after_change()
		return
	show_toast(reason)
	render()


## Re-renders, and says what arrived in the hand that wasn't in the hand or shop before: a
## triple's golden or a Triple Reward (SPEC 7.3). Both have new iids. A dev spawn is new too, so
## the dev panel passes rewards = false.
func _after_change(rewards: bool = true) -> void:
	var known: Dictionary = {}
	for zone: String in ["hand", "shop", "board"]:
		for entry: Variant in Data.a(state, zone):
			if entry is Dictionary:
				var old: Dictionary = entry
				known[Data.i(old, "iid", -1)] = true
	var copies_before: Dictionary = copies(state)
	render()
	var copies_after: Dictionary = copies(state)
	for entry: Variant in Data.a(state, "hand"):
		var view: Dictionary = entry
		if known.has(Data.i(view, "iid", -1)):
			continue
		var def_id: String = Data.s(view, "def_id")
		var used: int = copies_before.get(def_id, 0) - copies_after.get(def_id, 0)
		if Data.b(view, "golden", false):
			# A triple took copies that were already owned; a golden dev spawn takes none.
			if used >= 2:
				show_toast("Triple! Golden %s is in your hand." % Data.s(view, "name"))
		elif rewards and Data.s(view, "origin") == "created":
			show_toast("Triple Reward: %s is in your hand." % Data.s(view, "name"))


## Non-golden copies owned (hand and board) per def_id.
static func copies(from_state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for zone: String in ["hand", "board"]:
		for entry: Variant in Data.a(from_state, zone):
			if entry is Dictionary:
				var view: Dictionary = entry
				if not Data.b(view, "golden", false):
					var def_id: String = Data.s(view, "def_id")
					out[def_id] = Data.i(out, def_id, 0) + 1
	return out


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = not text.is_empty()
	_size_toast()
	_toast_timer.start(TOAST_SECONDS)


func _clear_toast() -> void:
	_toast.text = ""
	_toast.visible = false


func _size_toast() -> void:
	if _toast.visible:
		_toast.size = _toast.get_minimum_size()
		var room: float = size.x - 480.0
		_toast.position.x = maxf(20.0, (room - _toast.size.x) / 2.0)


func _on_tier_up() -> void:
	_act(port.tier_up())


func _on_refresh() -> void:
	_act(port.refresh())


func _on_freeze() -> void:
	_act(port.toggle_freeze())


func _on_end_turn() -> void:
	var reason: String = port.end_turn()
	if reason.is_empty():
		_selected = {}
		combat_ready.emit()
	else:
		show_toast(reason)
