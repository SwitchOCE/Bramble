extends "res://src/ui/screens/recruit_layout.gd"
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

var _toast_timer: Timer
var _hover_timer: Timer
var _hover_view: Dictionary = {}
var _discover: CardPicker
var _pause: PauseMenu
## {"zone": String, "index": int} of the tapped card, or {} for none.
var _selected: Dictionary = {}


func setup(game_port: GamePort) -> void:
	port = game_port
	_dev.setup(port)
	render()
	if Data.i(state, "round", 1) > 1 and Data.d(state, "pending_choice").is_empty():
		Sfx.play("gold")
	if RecruitView.is_ghost_next(state):
		show_toast("Next fight: a ghost, the board someone left behind. Scout it to see.")


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
	_lobby.next_tapped.connect(toggle_scout)
	_stage.add_child(_lobby)
	_build_shop()
	_build_board()
	_build_hand()
	_build_right()
	_build_tools()
	_detail = CardDetail.new()
	_stage.add_child(_detail)
	_detail.visibility_changed.connect(_on_detail_shown)
	_detail.z_index = 13
	_scout = ScoutPanel.new()
	for slot: Interactive in _scout.slots():
		_wire(slot)
	_stage.add_child(_scout)
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
	_shop_cards = GridContainer.new()
	_shop_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_scout_token = TokenButton.new("Scout", "", UiTheme.FONT_SMALL)
	_scout_token.pressed.connect(toggle_scout)
	_stage.add_child(_scout_token)
	_who_token = TokenButton.new("Who?", "", UiTheme.FONT_SMALL)
	_who_token.pressed.connect(_show_opponent)
	_who_token.visible = false
	_stage.add_child(_who_token)
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
	_lobby.show_standings(
		Data.a(state, "standings"),
		Data.i(state, "next_opponent_id", -2),
		Data.i(RecruitView.ghost_owner(state), "player_id", -9)
	)
	_layout()
	_render_shop(frozen)
	_render_board()
	_render_hand()
	_hero.show_hero(Data.d(state, "hero"), Data.i(state, "gold", 0))
	_show_selection()
	_render_discover()
	_refresh_scout()


## The next opponent's last board: a tap on Scout or their plaque, and again to put it away.
func toggle_scout() -> void:
	_scout.visible = not _scout.visible
	_scout_token.lit = _scout.visible
	_who_token.visible = _scout.visible
	_scout_token.set_word("Close" if _scout.visible else "Scout")
	if _selected.get("zone", "") == "scout":
		_selected = {}
	render()
	if _scout.visible and RecruitView.is_ghost_next(state):
		_show_opponent()


func _refresh_scout() -> void:
	if _scout.visible:
		var units: Array = Data.a(state, "next_opponent_last_board")
		var slots: Array = Data.a(state, "next_opponent_last_slot_effects")
		var nests: Array = Data.a(state, "next_opponent_last_nests")
		_scout.show_board(RecruitView.next_name(state), units, slots, nests)


## Who they are, in the card panel: their hero and power, or what a ghost is.
func _show_opponent() -> void:
	var card: Dictionary = RecruitView.opponent_card(state)
	_selected = {}
	_show_selection()
	if not card.is_empty():
		_detail.show_unit(card)


func _render_shop(frozen: bool) -> void:
	_clear(_shop_cards)
	var shop: Array = Data.a(state, "shop")
	var small: bool = _scout.visible
	var width: float = MINI_TILE if small else _tile_width(shop.size())
	var mode: CardView.Mode = CardView.Mode.MINI if small else CardView.Mode.SHOP
	_shop_cards.columns = maxi(ceili(shop.size() / 2.0), 1) if small else maxi(shop.size(), 1)
	_shop_cards.add_theme_constant_override(
		"h_separation", MINI_GAP_X if small else int(_shop_gap())
	)
	_shop_cards.add_theme_constant_override("v_separation", MINI_GAP_Y)
	_shelf.selling = false
	_shop_cards.modulate = Color.WHITE
	for i: int in shop.size():
		var view: Dictionary = shop[i]
		var card: CardView = _make_card(view, "shop", i, width, mode)
		card.frost = frozen
		if frozen and i == 0 and not small:
			card.show_frost_tag(true)
		if not RecruitView.triple_warning(state, view).is_empty():
			card.outline = UiTheme.GILT
		_shop_cards.add_child(card)
	if small:
		# A grid keeps the size it had for the bigger tiles until told otherwise.
		_shop_cards.size = Vector2.ZERO


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
	var marks: Array = RecruitView.slot_marks(state)
	_board.set_marks(marks)
	for slot: int in BoardView.SLOTS:
		if _board.cards[slot] != null:
			var unit: Dictionary = _board.cards[slot].unit
			_board.cards[slot].turns_shown = RecruitView.tile_slip(unit)


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
	var mode: CardView.Mode = CardView.Mode.SHOP if count <= 2 else CardView.Mode.MINI
	for i: int in shown:
		var view: Dictionary = hand[i]
		var card: CardView = _make_card(view, "hand", i, card_size.x, mode)
		card.set_card_size(card_size)
		_hand_cards.add_child(card)
	if count > shown:
		_hand_cards.add_child(_more_button(count - shown, card_size))
	# A grid can keep the height it had before its columns changed; its tiles land outside it.
	_hand_cards.reset_size.call_deferred()


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
		Sfx.play("discover")
	if Data.s(choice, "kind") == "hero":
		_discover.show_cards("Choose your hero", RecruitView.hero_cards(options), false)
	else:
		_discover.show_cards("Discover: pick one", options, false)


func _on_discover_picked(index: int) -> void:
	_discover = null
	_act(port.choose(index), "place")


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
		"scout":
			items = Data.a(state, "next_opponent_last_board")
	if index < 0 or index >= items.size():
		return {}
	var entry: Variant = items[index]
	return entry if entry is Dictionary else {}


func _show_selection() -> void:
	_board.clear_highlights()
	_board.set_pass_landing(-1)
	for card: Node in _shop_cards.get_children() + _hand_cards.get_children():
		if card is CardView:
			(card as CardView).selected = false
	for slot: int in BoardView.SLOTS:
		if _scout.card_at(slot) != null:
			_scout.card_at(slot).selected = false
	_detail.clear_actions()
	if _selected.is_empty():
		_show_sky()
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
			var shop_bellies: Array[int] = _highlight_bellies(view)
			_detail.show_unit(
				_full_view(zone, view), "Or tap an Ooze to buy it in" if shop_bellies else ""
			)
			var cost: int = Data.i(view, "cost", -1)
			_detail.add_action("Buy", _on_buy_selected, cost)
		"hand":
			var aim: String = Data.s(view, "aim", "none")
			if CardView.is_spell(view) and aim == "none":
				_detail.show_unit(view)
				_detail.add_action("Play", _on_spell_selected)
				_highlight_item(view)
			elif CardView.is_spell(view):
				var no_target: String = RecruitView.no_target_note(state, view)
				_detail.show_unit(
					view, no_target if not no_target.is_empty() else "Tap where to play it"
				)
				_highlight_item(view)
			else:
				var into_belly: bool = not _highlight_bellies(view).is_empty()
				_detail.show_unit(
					_full_view(zone, view),
					(
						"Tap a slot to play it, or an Ooze to swallow it"
						if into_belly
						else "Tap an empty slot to play it"
					)
				)
				_highlight_empty_slots()
		"board":
			var mark: Dictionary = Data.entry(RecruitView.slot_marks(state), index)
			var round_now: int = Data.i(state, "round", 1)
			var sell_note: String = RecruitHeld.sell_note(view, round_now)
			_detail.show_unit(
				RecruitView.with_slot_note(view, mark, index),
				sell_note if not sell_note.is_empty() else "Tap a slot to move or swap"
			)
			var board: Array = Data.a(state, "board")
			_board.set_pass_landing(RecruitView.pass_preview(board, view, index, index))
			_detail.add_action(RecruitHeld.sell_word(view, round_now), _on_sell_selected, 1)
			if not RecruitHeld.bellies_for(board, view).is_empty():
				_detail.add_action("Into a Belly", _on_into_belly)
			_highlight_other_slots(index)
			if _selected.has("into_belly"):
				_board.clear_highlights()
				_highlight_bellies(view)
		"scout":
			_detail.show_unit(RecruitHeld.with_inside(view))


## The card as the full text shows it: what a third copy would do, what a fresh golden brings.
func _full_view(zone: String, view: Dictionary) -> Dictionary:
	if zone == "hand":
		return RecruitView.with_reward_note(view)
	var warning: String = RecruitView.triple_warning(state, view) if zone == "shop" else ""
	if warning.is_empty():
		return view
	var full: Dictionary = view.duplicate()
	full["text"] = ("%s\n%s" % [Data.s(view, "text"), warning]).strip_edges()
	return full


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
		"scout":
			return _scout.card_at(index)
	return null


## A Nest tap shows its bird and countdown; idle recruiting keeps the economy controls in view.
func _show_sky() -> void:
	_detail.show_empty()


## Outlines the Oozes this unit could go into, and returns their slots.
func _highlight_bellies(view: Dictionary) -> Array[int]:
	var bellies: Array[int] = RecruitHeld.bellies_for(Data.a(state, "board"), view)
	for slot: int in bellies:
		_board.cards[slot].outline = UiTheme.DROP_OK
	return bellies


## A shop or hand unit dropped or tapped onto an Ooze, or a board unit sent in by the Belly button.
func _try_swallow(from_zone: String, from_index: int, slot: int) -> bool:
	var moved: Dictionary = _unit_at(from_zone, from_index)
	if not RecruitHeld.can_swallow(_unit_at("board", slot), moved):
		return false
	if from_zone == "board" and not _selected.has("into_belly"):
		return false
	_selected = {}
	_act(port.swallow(from_zone, from_index, slot), "buy" if from_zone == "shop" else "place")
	return true


func _on_into_belly() -> void:
	_selected["into_belly"] = true
	_show_selection()


## A mouse resting on a card opens its full text, after a moment so sweeping across doesn't flicker.
func _on_hovered(zone: String, index: int, inside: bool) -> void:
	if not _selected.is_empty():
		return
	var view: Dictionary = _full_view(zone, _unit_at(zone, index)) if inside else {}
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
	if zone != "table":
		Sfx.tap()
	var from_index: int = Data.i(_selected, "index", -1)
	if zone == "board" and _try_swallow(str(_selected.get("zone", "")), from_index, index):
		return
	_tap_without_swallow(zone, index)


func _tap_without_swallow(zone: String, index: int) -> void:
	var has_unit: bool = not _unit_at(zone, index).is_empty()
	var from_zone: String = str(_selected.get("zone", ""))
	var from_index: int = Data.i(_selected, "index", -1)
	if zone == "board" and not _selected.is_empty():
		if from_zone == "power":
			if RecruitView.aim_fits(Data.s(Data.d(state, "hero"), "aim", "none"), has_unit, index):
				_act(port.use_power(index), "hero_power")
				return
		elif from_zone == "hand" and CardView.is_spell(_unit_at("hand", from_index)):
			var item: Dictionary = _unit_at("hand", from_index)
			if RecruitView.item_lands(item, _unit_at("board", index), index):
				_act(port.play_item(Data.i(item, "card_index", -1), index), "keyword")
				return
		elif from_zone == "hand" and not has_unit:
			_act_placed(port.play(from_index, index), _unit_at("hand", from_index))
			return
		if from_zone == "board" and index != from_index:
			_act(port.move(from_index, index), "place")
			return
	if zone == "shop" and from_zone == "hand" and _aimed_at_shop(from_index, index):
		_act(
			port.play_item(Data.i(_unit_at("hand", from_index), "card_index", -1), index), "keyword"
		)
		return
	if not has_unit and (zone == "scout" or (zone == "board" and _selected.is_empty())):
		_selected = {}
		if zone == "scout":
			_show_selection()
			_show_their_bare_slot(index)
		else:
			_show_bare_slot(index)
		return
	if has_unit and not (from_zone == zone and from_index == index):
		_selected = {"zone": zone, "index": index}
	else:
		_selected = {}
	_show_selection()


## A spell aimed at the shop, and a unit on offer to aim it at.
func _aimed_at_shop(hand_index: int, shop_index: int) -> bool:
	var card: Dictionary = _unit_at("hand", hand_index)
	return (
		Data.s(card, "aim") == "shop_unit" and not CardView.is_spell(_unit_at("shop", shop_index))
	)


## A tap on an empty slot says what lies there: Rings and bands stay with nobody on them.
func _show_bare_slot(slot: int) -> void:
	var mark: Dictionary = Data.entry(RecruitView.slot_marks(state), slot)
	var note: String = RecruitView.slot_note(mark, slot)
	if note.is_empty():
		_show_selection()
	else:
		var card: Dictionary = {"name": "On this slot", "kind": "spell", "type_word": "Slot"}
		card["text"] = note
		_detail.show_unit(card)


func _show_their_bare_slot(slot: int) -> void:
	var effects: Array = Data.a(state, "next_opponent_last_slot_effects")
	var mark: Dictionary = Data.entry(RecruitView.slot_marks({"slot_effects": effects}), slot)
	var note: String = RecruitView.slot_note(mark, slot)
	if not note.is_empty():
		_detail.show_unit(
			{"name": "On their slot", "kind": "spell", "type_word": "Slot", "text": note}
		)


func _on_buy_selected() -> void:
	_act(_buy_at(Data.i(_selected, "index", -1)), "buy")


func _buy_at(index: int) -> String:
	var view: Dictionary = _unit_at("shop", index)
	if CardView.is_spell(view):
		return port.buy_spell(Data.i(view, "card_index", -1))
	return port.buy(index)


func _on_sell_selected() -> void:
	_act(port.sell(Data.i(_selected, "index", -1)), "sell")


func _on_spell_selected() -> void:
	var item: Dictionary = _unit_at("hand", Data.i(_selected, "index", -1))
	_act(port.play_item(Data.i(item, "card_index", -1)), "keyword")


func _on_hero_power() -> void:
	if Data.s(Data.d(state, "hero"), "aim", "none") == "none":
		_act(port.use_power(), "hero_power")
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
	show_pass_preview(from_zone, from_index, zone, index)
	var target_empty: bool = _unit_at(zone, index).is_empty()
	match zone:
		"board":
			return _can_drop_on_board(from_zone, from_index, index, target_empty)
		"hand":
			return from_zone == "shop"
		"shop":
			return from_zone == "board"
	return false


## While a card with a Pass is dragged: an arrow on the unit it would land on from here.
func show_pass_preview(from_zone: String, from_index: int, zone: String, index: int) -> void:
	var card: Dictionary = _unit_at(from_zone, from_index)
	var from_slot: int = from_index if from_zone == "board" else -1
	var landing: int = -1
	if zone == "board":
		landing = RecruitView.pass_preview(Data.a(state, "board"), card, from_slot, index)
	elif zone == "shop" and from_slot >= 0:
		landing = RecruitView.pass_preview(Data.a(state, "board"), card, from_slot, -1)
	_board.set_pass_landing(landing)


func _can_drop_on_board(from_zone: String, from_index: int, slot: int, empty: bool) -> bool:
	if from_zone == "board":
		return slot != from_index
	var card: Dictionary = _unit_at(from_zone, from_index)
	if CardView.is_spell(card):
		return from_zone == "hand" and RecruitView.item_lands(card, _unit_at("board", slot), slot)
	if RecruitHeld.can_swallow(_unit_at("board", slot), card):
		return from_zone in ["hand", "shop"]
	return from_zone in ["hand", "shop"] and empty


func _drop(data: Variant, zone: String, index: int) -> void:
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	var from_index: int = Data.i(drag, "index", -1)
	_selected = {}
	if zone == "board" and from_zone != "board" and _try_swallow(from_zone, from_index, index):
		return
	match [from_zone, zone]:
		["shop", "hand"]:
			_act(_buy_at(from_index), "buy")
		["shop", "board"]:
			var bought: Dictionary = _unit_at("shop", from_index)
			_act_placed(RecruitView.buy_and_play(port, from_index, index), bought, "buy")
		["hand", "board"]:
			var card: Dictionary = _unit_at("hand", from_index)
			if CardView.is_spell(card):
				_act(port.play_item(Data.i(card, "card_index", -1), index), "keyword")
			else:
				_act_placed(port.play(from_index, index), card)
		["board", "board"]:
			_act(port.move(from_index, index), "place")
		["board", "shop"]:
			_act(port.sell(from_index), "sell")


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
func _act(reason: String, sound: String = "") -> void:
	if reason.is_empty():
		_selected = {}
		if not sound.is_empty():
			Sfx.play(sound)
		_after_change(true, sound)
		return
	show_toast(reason)
	render()


## A unit landed on the board: oozes and fairies say so.
func _act_placed(reason: String, view: Dictionary, sound: String = "place") -> void:
	if reason.is_empty():
		Sfx.play_voice(Data.a(view, "tribes"))
	_act(reason, sound)


## Re-renders, and says what arrived in the hand that wasn't in the hand or shop before: a
## triple's golden or a Triple Reward (SPEC 7.3). Both have new iids. A dev spawn is new too, so
## the dev panel passes rewards = false.
func _after_change(rewards: bool = true, sound: String = "") -> void:
	var known: Dictionary = {}
	for zone: String in ["hand", "shop", "board"]:
		for entry: Variant in Data.a(state, zone):
			if entry is Dictionary:
				var old: Dictionary = entry
				known[Data.i(old, "iid", -1)] = true
	var copies_before: Dictionary = RecruitView.copies(state)
	var old_state: Dictionary = state
	render()
	var copies_after: Dictionary = RecruitView.copies(state)
	var combined: String = RecruitView.combine_note(old_state, state)
	if rewards:
		_play_change_sounds(old_state, sound)
	if not combined.is_empty():
		Sfx.play("acorns_combine")
		show_toast(combined)
		_pulse_new_hand_card(known)
	for entry: Variant in Data.a(state, "hand"):
		var view: Dictionary = entry
		if known.has(Data.i(view, "iid", -1)):
			continue
		var def_id: String = Data.s(view, "def_id")
		var used: int = copies_before.get(def_id, 0) - copies_after.get(def_id, 0)
		if Data.b(view, "golden", false):
			# A triple took copies that were already owned; a golden dev spawn takes none.
			if used >= 2:
				Sfx.play("triple")
				show_toast(
					"Triple! Golden %s in hand: play it for your reward." % Data.s(view, "name")
				)
		elif rewards and Data.s(view, "origin") == "created":
			show_toast("Triple Reward: %s is in your hand." % Data.s(view, "name"))
	_note_golden_on_board(known, copies_before, copies_after)
	var notice: String = RecruitView.change_notices(old_state, state)
	if not notice.is_empty():
		show_toast(notice)


## A triple on a full hand lands on the board, and the rules give no reward for that (7.1.2).
func _note_golden_on_board(known: Dictionary, before: Dictionary, after: Dictionary) -> void:
	for entry: Variant in Data.a(state, "board"):
		if not entry is Dictionary:
			continue
		var view: Dictionary = entry
		var def_id: String = Data.s(view, "def_id")
		var used: int = Data.i(before, def_id, 0) - Data.i(after, def_id, 0)
		if Data.b(view, "golden", false) and not known.has(Data.i(view, "iid", -1)) and used >= 2:
			Sfx.play("triple")
			show_toast(
				(
					"Triple! Your hand was full: Golden %s took a slot, no reward."
					% Data.s(view, "name")
				)
			)


## What the board and purse did by themselves: a sale's coins are in its own sound.
func _play_change_sounds(old_state: Dictionary, sound: String) -> void:
	if sound != "sell" and Data.i(state, "gold", 0) > Data.i(old_state, "gold", 0):
		Sfx.play("gold")
	if RecruitView.ring_words(state) != RecruitView.ring_words(old_state):
		Sfx.play("ring")


## The Stash or Hoard that just formed swells for a moment, so the combine is seen.
func _pulse_new_hand_card(known: Dictionary) -> void:
	if Settings.reduce_motion:
		return
	for child: Node in _hand_cards.get_children():
		var card: CardView = child as CardView
		if card != null and not known.has(Data.i(card.unit, "iid", -1)):
			card.pivot_offset = card.size / 2.0
			card.scale = Vector2(1.35, 1.35)
			create_tween().tween_property(card, "scale", Vector2.ONE, 0.4)


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = not text.is_empty()
	_size_toast()
	_toast_timer.start(TOAST_SECONDS)


func _clear_toast() -> void:
	_toast.text = ""
	_toast.visible = false


func _on_tier_up() -> void:
	_act(port.tier_up(), "tier_up")


func _on_refresh() -> void:
	_act(port.refresh(), "refresh")


func _on_freeze() -> void:
	_act(port.toggle_freeze(), "freeze")


func _on_end_turn() -> void:
	var reason: String = port.end_turn()
	if reason.is_empty():
		_selected = {}
		Sfx.play("turn_end")
		combat_ready.emit()
	else:
		show_toast(reason)
