extends Control
## The recruit phase: shop, the 4-3 brick board, the hand, gold, tier, refresh, freeze, End Turn,
## and the lobby. Renders GamePort.get_state() (SPEC 6.1) and never changes it: every action goes
## through the port, then the screen re-reads the state.
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
## The dev panel's look switch: the app rebuilds this screen, the game goes on.
signal theme_chosen(direction: String)

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const LobbyStrip := preload("res://src/ui/widgets/lobby_strip.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const DevPanel := preload("res://src/ui/widgets/dev_panel.gd")

const SHOP_CARD_WIDTH: float = 160.0
const BOARD_CARD_WIDTH: float = 168.0
const HAND_CARD_WIDTH: float = 140.0
const TOAST_SECONDS: float = 3.5

var port: GamePort
var state: Dictionary = {}

var _lobby: LobbyStrip
var _detail: CardDetail
var _board: BoardView
var _shop_zone: Interactive
var _shop_panel: Panel
var _shop_title: Label
var _shop_cards: HBoxContainer
var _hand_zone: Interactive
var _hand_panel: Panel
var _hand_title: Label
var _hand_cards: HBoxContainer
var _gold_label: Label
var _tier_label: Label
var _round_label: Label
var _health_label: Label
var _tier_button: Button
var _refresh_button: Button
var _freeze_button: Button
var _end_button: Button
## "then fight <opponent>" inside End turn (Folk Print).
var _fight_note: Label
var _toast: Label
var _toast_timer: Timer
var _dev: DevPanel
## {"zone": String, "index": int} of the tapped card, or {} for none.
var _selected: Dictionary = {}


func setup(game_port: GamePort) -> void:
	port = game_port
	_dev.setup(port)
	render()


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = UiTheme.BG
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	margin.add_child(columns)
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	left.add_theme_constant_override("separation", 10)
	var menu_row: HBoxContainer = HBoxContainer.new()
	menu_row.add_theme_constant_override("separation", 8)
	var menu: Button = UiTheme.button("Menu", 96)
	menu.pressed.connect(func() -> void: menu_requested.emit())
	menu_row.add_child(menu)
	var dev: Button = UiTheme.button("Dev", 64, UiTheme.FONT_SMALL)
	dev.pressed.connect(toggle_dev_panel)
	menu_row.add_child(dev)
	_round_label = UiTheme.label("", UiTheme.FONT_BODY, UiTheme.TEXT)
	_round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_row.add_child(_round_label)
	left.add_child(menu_row)
	_lobby = LobbyStrip.new()
	_lobby.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_lobby)
	columns.add_child(left)
	columns.add_child(_build_centre())
	columns.add_child(_build_side())
	_dev = DevPanel.new()
	_dev.visible = false
	_dev.custom_minimum_size = Vector2(380, 0)
	_dev.position = Vector2(270, 90)
	_dev.changed.connect(func() -> void: _after_change(false))
	_dev.turn_skipped.connect(_on_turn_skipped)
	_dev.theme_chosen.connect(func(id: String) -> void: theme_chosen.emit(id))
	_dev.replay_requested.connect(func(game_seed: int) -> void: replay_requested.emit(game_seed))
	add_child(_dev)


func _build_centre() -> VBoxContainer:
	var centre: VBoxContainer = VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 10)
	centre.add_child(_build_top_bar())
	_shop_zone = _zone("shop", 282)
	_shop_panel = _zone_panel(_shop_zone)
	_shop_title = UiTheme.label("Shop", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	_shop_cards = HBoxContainer.new()
	_shop_cards.add_theme_constant_override("separation", 26)
	_shop_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_fill_zone(_shop_zone, _shop_title, _shop_cards)
	centre.add_child(_shop_zone)
	var board_holder: CenterContainer = CenterContainer.new()
	board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board = BoardView.new()
	_board.configure("board", BOARD_CARD_WIDTH, true)
	for slot: Interactive in _board.slots:
		_wire(slot)
	board_holder.add_child(_board)
	centre.add_child(board_holder)
	_hand_zone = _zone("hand", 196)
	_hand_panel = _zone_panel(_hand_zone)
	_hand_title = UiTheme.label("Hand", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	_hand_cards = HBoxContainer.new()
	_hand_cards.add_theme_constant_override("separation", 18)
	_hand_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_fill_zone(_hand_zone, _hand_title, _hand_cards)
	centre.add_child(_hand_zone)
	return centre


func _build_top_bar() -> HBoxContainer:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 14)
	_gold_label = UiTheme.label("", UiTheme.FONT_TITLE, UiTheme.HEADING)
	_gold_label.custom_minimum_size = Vector2(140, 0)
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(_gold_label)
	_tier_label = UiTheme.label("", UiTheme.FONT_TITLE)
	_tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(_tier_label)
	_tier_button = UiTheme.button("", 180)
	_tier_button.pressed.connect(_on_tier_up)
	bar.add_child(_tier_button)
	_refresh_button = UiTheme.button("", 170)
	_refresh_button.pressed.connect(_on_refresh)
	bar.add_child(_refresh_button)
	_freeze_button = UiTheme.button("", 190)
	_freeze_button.pressed.connect(_on_freeze)
	bar.add_child(_freeze_button)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_health_label = UiTheme.label("", UiTheme.FONT_BODY + 4, UiTheme.HEALTH_TEXT)
	_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(_health_label)
	_end_button = UiTheme.button("End turn", 200, UiTheme.FONT_TITLE - 4)
	UiTheme.make_primary(_end_button)
	_fight_note = UiTheme.label("", UiTheme.FONT_SMALL - 3, UiTheme.PRIMARY_TEXT)
	_fight_note.name = "FightNote"
	_fight_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fight_note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_fight_note.offset_top = -25
	_fight_note.offset_bottom = -5
	_fight_note.visible = UiTheme.has_shape("fight_note")
	if UiTheme.italic_font() != null:
		_fight_note.add_theme_font_override("font", UiTheme.italic_font())
	_end_button.add_child(_fight_note)
	if _fight_note.visible:
		# Room for the note under the words "End turn", in the same bar height.
		_end_button.add_theme_font_size_override("font_size", UiTheme.FONT_BODY + 2)
		for face_state: String in ["normal", "hover", "pressed", "disabled"]:
			var face: StyleBox = UiTheme.get_theme().get_stylebox(face_state, "Button")
			if _end_button.has_theme_stylebox_override(face_state):
				face = _end_button.get_theme_stylebox(face_state)
			var lifted: StyleBox = face.duplicate()
			lifted.content_margin_top = 2
			lifted.content_margin_bottom = 22
			_end_button.add_theme_stylebox_override(face_state, lifted)
	_end_button.pressed.connect(_on_end_turn)
	bar.add_child(_end_button)
	return bar


func _build_side() -> VBoxContainer:
	var side: VBoxContainer = VBoxContainer.new()
	side.custom_minimum_size = Vector2(360, 0)
	side.add_theme_constant_override("separation", 12)
	_detail = CardDetail.new()
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.set_card_width(280)
	side.add_child(_detail)
	_toast = UiTheme.label("", UiTheme.FONT_BODY, UiTheme.SELECT)
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.custom_minimum_size = Vector2(0, 64)
	side.add_child(_toast)
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(func() -> void: _toast.text = "")
	add_child(_toast_timer)
	return side


func _zone(zone_name: String, height: float) -> Interactive:
	var zone_node: Interactive = Interactive.new()
	zone_node.zone = zone_name
	zone_node.index = -1
	zone_node.custom_minimum_size = Vector2(0, height)
	_wire(zone_node)
	return zone_node


func _zone_panel(zone_node: Interactive) -> Panel:
	var panel: Panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone_node.add_child(panel)
	return panel


func _fill_zone(zone_node: Interactive, title: Label, cards: HBoxContainer) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_right = -14
	box.offset_top = 6
	box.offset_bottom = -6
	box.add_theme_constant_override("separation", 12)
	title.custom_minimum_size = Vector2(0, 28)
	box.add_child(title)
	cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(cards)
	zone_node.add_child(box)


## Connects a card, slot or zone to this screen's tap, hover and drag-and-drop handlers.
func _wire(node: Interactive) -> void:
	node.tapped.connect(_on_tapped)
	node.hovered.connect(_on_hovered)
	node.drag_started.connect(_on_drag_started)
	node.drag_data_fn = _drag_data
	node.can_drop_fn = _can_drop
	node.drop_fn = _drop
	node.preview_fn = _drag_preview


# --- rendering -----------------------------------------------------------------------------


func render() -> void:
	state = port.get_state() if port != null else {}
	if state.is_empty():
		return
	var gold: int = Data.i(state, "gold", 0)
	var tier: int = Data.i(state, "tier", 1)
	_gold_label.text = "%d gold" % gold
	_tier_label.text = "Tier %d" % tier
	var tier_cost: Variant = state.get("tier_up_cost")
	if tier_cost == null:
		_tier_button.text = "Top tier"
		_tier_button.disabled = true
	else:
		_tier_button.text = "Tier up · %dg" % Data.as_int(tier_cost)
		_tier_button.disabled = false
	_refresh_button.text = "Refresh · %dg" % Data.i(state, "refresh_cost", 1)
	var frozen: bool = Data.b(state, "frozen", false)
	var freezes_left: int = Data.i(state, "freezes_left", 0)
	_freeze_button.text = ("Unfreeze" if frozen else "Freeze") + " (%d)" % freezes_left
	_round_label.text = "Round %d" % Data.i(state, "round", 1)
	_health_label.text = "Health %d" % Data.i(state, "health", 0)
	_lobby.show_standings(Data.a(state, "standings"), Data.i(state, "next_opponent_id", -2))
	_fight_note.text = fight_note(state)
	_render_shop(frozen)
	_render_board()
	_render_hand()
	_show_selection()


## "then fight Old Tansy": the next opponent's name from the standings; "the ghost" for -1.
static func fight_note(view: Dictionary) -> String:
	var next_id: int = Data.i(view, "next_opponent_id", -2)
	if next_id == -1:
		return "then fight the ghost"
	for entry: Variant in Data.a(view, "standings"):
		var standing: Dictionary = entry
		if Data.i(standing, "player_id", -3) == next_id:
			return "then fight %s" % Data.s(standing, "name", "?")
	return ""


func _render_shop(frozen: bool) -> void:
	_clear(_shop_cards)
	var shop: Array = Data.a(state, "shop")
	var shop_size: int = state.get("shop_size", shop.size())
	var title: String = "Shop  ·  tier %d" % Data.i(state, "tier", 1)
	if frozen:
		title = "FROZEN  ·  these cards stay next turn  ·  " + title
	_shop_title.text = title
	_shop_title.add_theme_color_override(
		"font_color", UiTheme.FROZEN if frozen else UiTheme.TEXT_DIM
	)
	var border: Color = UiTheme.FROZEN if frozen else UiTheme.PANEL_BORDER
	var fill: Color = UiTheme.FROZEN_FILL if frozen else UiTheme.PANEL
	_shop_panel.add_theme_stylebox_override(
		"panel", UiTheme.flat_box(fill, border, 4 if frozen else 2)
	)
	for i: int in shop.size():
		var view: Dictionary = shop[i]
		var card: CardView = _make_card(view, "shop", i, SHOP_CARD_WIDTH, CardView.Mode.FULL)
		if frozen:
			card.outline = UiTheme.FROZEN
		_shop_cards.add_child(card)
	for i: int in range(shop.size(), shop_size):
		var empty: Panel = Panel.new()
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.custom_minimum_size = CardView.size_for(SHOP_CARD_WIDTH)
		empty.add_theme_stylebox_override(
			"panel", UiTheme.flat_box(UiTheme.EMPTY_FILL, UiTheme.PANEL_BORDER, 2, 12)
		)
		_shop_cards.add_child(empty)


func _render_board() -> void:
	_board.clear()
	var board: Array = Data.a(state, "board")
	for slot: int in mini(board.size(), BoardView.SLOTS):
		var entry: Variant = board[slot]
		if entry is Dictionary:
			var card: CardView = _make_card(
				Data.entry(board, slot), "board", slot, BOARD_CARD_WIDTH, CardView.Mode.FULL
			)
			_board.place_card(card, slot)


func _render_hand() -> void:
	_clear(_hand_cards)
	var hand: Array = Data.a(state, "hand")
	var limit: int = Data.i(state, "hand_limit", 10)
	_hand_title.text = "Hand  ·  %d / %d" % [hand.size(), limit]
	_hand_panel.add_theme_stylebox_override(
		"panel", UiTheme.flat_box(UiTheme.PANEL, UiTheme.PANEL_BORDER, 2)
	)
	for i: int in hand.size():
		var view: Dictionary = hand[i]
		_hand_cards.add_child(_make_card(view, "hand", i, HAND_CARD_WIDTH, CardView.Mode.COMPACT))
	if hand.is_empty():
		_hand_cards.add_child(
			UiTheme.label(
				"Bought units wait here. Drag one to an empty slot to play it.",
				UiTheme.FONT_SMALL,
				UiTheme.TEXT_DIM
			)
		)


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
		_detail.show_empty(
			"Tap or hover a card to read it in full.\nDrag to buy, play, move or sell."
		)
		return
	var zone: String = _selected["zone"]
	var index: int = _selected["index"]
	var view: Dictionary = _unit_at(zone, index)
	if view.is_empty():
		_selected = {}
		_detail.show_empty("")
		return
	var card: CardView = _card_at(zone, index)
	if card != null:
		card.selected = true
	match zone:
		"shop":
			_detail.show_unit(view, "In the shop")
			var cost: int = Data.i(view, "cost", -1)
			_detail.add_action("Buy · %dg" % cost if cost >= 0 else "Buy", _on_buy_selected)
		"hand":
			_detail.show_unit(view, "Tap an empty slot to play it")
			_highlight_empty_slots()
		"board":
			_detail.show_unit(view, "Tap another slot to move or swap")
			_detail.add_action("Sell", _on_sell_selected)
			_highlight_other_slots(index)


func _card_at(zone: String, index: int) -> CardView:
	match zone:
		"board":
			return _board.cards[index] if index >= 0 and index < BoardView.SLOTS else null
		"shop", "hand":
			var holder: HBoxContainer = _shop_cards if zone == "shop" else _hand_cards
			if index >= 0 and index < holder.get_child_count():
				return holder.get_child(index) as CardView
	return null


func _highlight_empty_slots() -> void:
	for slot: int in BoardView.SLOTS:
		if _board.cards[slot] == null:
			_board.slots[slot].highlight = UiTheme.DROP_OK


func _highlight_other_slots(from_slot: int) -> void:
	for slot: int in BoardView.SLOTS:
		if slot == from_slot:
			continue
		if _board.cards[slot] == null:
			_board.slots[slot].highlight = UiTheme.DROP_OK
		else:
			_board.cards[slot].outline = UiTheme.DROP_OK


func _on_hovered(zone: String, index: int, inside: bool) -> void:
	if not _selected.is_empty() or zone == "shop" and index < 0 or zone == "hand" and index < 0:
		return
	var view: Dictionary = _unit_at(zone, index) if inside else {}
	if view.is_empty():
		_detail.show_empty(
			"Tap or hover a card to read it in full.\nDrag to buy, play, move or sell."
		)
	else:
		_detail.show_unit(view)


func _on_tapped(zone: String, index: int) -> void:
	var has_unit: bool = not _unit_at(zone, index).is_empty()
	var from_zone: String = str(_selected.get("zone", ""))
	var from_index: int = Data.i(_selected, "index", -1)
	if zone == "board" and not _selected.is_empty():
		if from_zone == "hand" and not has_unit:
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
	_act(port.buy(Data.i(_selected, "index", -1)))


func _on_sell_selected() -> void:
	_act(port.sell(Data.i(_selected, "index", -1)))


# --- drag and drop -------------------------------------------------------------------------


func _drag_data(zone: String, index: int) -> Variant:
	if zone not in ["shop", "hand", "board"] or _unit_at(zone, index).is_empty():
		return null
	return {"zone": zone, "index": index}


func _drag_preview(zone: String, index: int) -> Control:
	var holder: Control = Control.new()
	var card: CardView = CardView.new()
	card.show_unit(_unit_at(zone, index), CardView.Mode.COMPACT)
	card.set_card_width(HAND_CARD_WIDTH)
	card.modulate = Color(1, 1, 1, 0.85)
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
			if from_zone == "board":
				return index != from_index
			return from_zone in ["hand", "shop"] and target_empty
		"hand":
			return from_zone == "shop"
		"shop":
			return from_zone == "board"
	return false


func _drop(data: Variant, zone: String, index: int) -> void:
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	var from_index: int = Data.i(drag, "index", -1)
	_selected = {}
	match [from_zone, zone]:
		["shop", "hand"]:
			_act(port.buy(from_index))
		["shop", "board"]:
			_act(_buy_and_play(from_index, index))
		["hand", "board"]:
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
		"shop":
			_highlight_empty_slots()
			_hand_panel.add_theme_stylebox_override(
				"panel", UiTheme.flat_box(UiTheme.PANEL, UiTheme.DROP_OK, 4)
			)
		"hand":
			_highlight_empty_slots()
		"board":
			_highlight_other_slots(index)
			_shop_title.text = "Drop here to sell"
			_shop_title.add_theme_color_override("font_color", UiTheme.SELL)
			_shop_panel.add_theme_stylebox_override(
				"panel", UiTheme.flat_box(UiTheme.SELL_FILL, UiTheme.SELL, 4)
			)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and port != null:
		render()


func toggle_dev_panel() -> void:
	_dev.visible = not _dev.visible
	_dev.refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_QUOTELEFT:
		toggle_dev_panel()
		accept_event()


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
	_toast_timer.start(TOAST_SECONDS)


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
