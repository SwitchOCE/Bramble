extends "res://src/ui/screens/recruit_actions.gd"

signal last_fight_requested
signal watch_fight_requested
signal combat_ready
signal menu_requested
signal game_over_reached
signal replay_requested(game_seed: int)
signal guide_requested
signal settings_requested

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const RecruitActionMotion := preload("res://src/ui/screens/recruit_action_motion.gd")
const RecruitMotion := preload("res://src/ui/screens/recruit_motion.gd")
const RecruitFeedback := preload("res://src/ui/screens/recruit_feedback.gd")
const RecruitHud := preload("res://src/ui/screens/recruit_hud.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")

var _toast_timer: Timer
var _hover_timer: Timer
var _leave_timer: Timer
var _hover_view: Dictionary = {}
var _discover: CardPicker
var _pause: PauseMenu
var _selected: Dictionary = {}
var _ooze_ui: RecruitOozes = RecruitOozes.new()

var _projection: LaneProjection = LaneProjection.new()
var _action_motion: RecruitActionMotion
var _motion: RecruitMotion
var _feedback: RecruitFeedback
var _hover_zone: String = ""
var _hover_index: int = -1
var _landing_round: int = -1
var _ending: bool = false
var _drag_card: CardView
var _drag_source: CardView
var _drop_pocket: RecruitHeld.DropPocket
var _released_card: Dictionary = {}
var _drag_committed: bool = false
var _reader_pinned: bool = false
var _scout_player_id: int = -2
var _scout_snapshot: Dictionary = {}


func setup(game_port: GamePort) -> void:
	port = game_port
	_dev.setup(port)
	render()
	var notice: String = _feedback.present(self, {})
	if not notice.is_empty():
		show_toast(notice)
	if Data.i(state, "round", 1) > 1 and Data.d(state, "pending_choice").is_empty():
		Sfx.play("gold")


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UiTheme.add_world(self, "recruit")
	var blank: Interactive = Interactive.new()
	blank.set_anchors_preset(Control.PRESET_FULL_RECT)
	blank.zone = "table"
	_wire(blank)
	add_child(blank)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	_stage.set_meta("arena_layout", true)
	_bar_contents = _stage
	_lobby = preload("res://src/ui/widgets/lobby_strip.gd").new()
	_lobby.scout_requested.connect(scout_player)
	_lobby.hero_requested.connect(_show_lobby_hero)
	_stage.add_child(_lobby)
	_tribes = preload("res://src/ui/widgets/tribe_bonuses.gd").new()
	_stage.add_child(_tribes)
	_build_shop(_wire)
	_market_return.pressed.connect(toggle_scout)
	_build_board(_wire, _on_hero_power, _on_hero_tapped)
	_build_hand(_wire)
	_away_tray.bird_requested.connect(_show_away_bird)
	_build_right(_on_tier_up, _on_refresh, _on_freeze, _on_end_turn)
	_kin_button = _leaf(
		LeafButton.Colour.BIRCH, func() -> void: _act(port.ask_for_kin(), "refresh")
	)
	_build_tools(_open_pause, toggle_scout, _show_opponent, toggle_dev_panel)
	_detail = CardDetail.new()
	_stage.add_child(_detail)
	_detail.add_child(preload("res://src/ui/widgets/reader_scroll.gd").new(_detail._notes))
	var rules_links: RichTextLabel = _detail.get("_notes")
	rules_links.meta_clicked.connect(
		func(meta: Variant) -> void:
			var word: String = str(meta).trim_prefix("kw:").to_lower()
			if word in ["behind", "touching", "beside", "next to", "across", "quarry", "mire"]:
				_pulse_reader_reach()
	)
	_detail.z_index = 13
	_scout = ScoutPanel.new()
	_scout.hero_pressed.connect(_show_opponent)
	for slot: Interactive in _scout.slots():
		_wire(slot)
	_stage.add_child(_scout)
	_detail.attach_recruit_overlay(
		_stage,
		_gold,
		_end_button,
		{
			"shop": _shop_cards,
			"board": _board,
			"hand": _hand_zone,
			"scout": _scout,
			"lobby": _lobby,
			"market_controls": _market_controls
		}
	)
	_motion = RecruitMotion.new()
	_stage.add_child(_motion)
	_action_motion = RecruitActionMotion.new()
	_stage.add_child(_action_motion)
	_feedback = RecruitFeedback.new()
	_stage.add_child(_feedback)
	_lanes = LaneOverlay.new()
	_lanes.boards = [_board, _scout.get("_board")]
	_stage.add_child(_lanes)
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
	_leave_timer = Timer.new()
	_leave_timer.one_shot = true
	_leave_timer.timeout.connect(_on_leave_check)
	add_child(_leave_timer)
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


func _wire(node: Interactive) -> void:
	node.tapped.connect(_on_tapped)
	node.hovered.connect(_on_hovered)
	node.drag_started.connect(_on_drag_started)
	node.drag_data_fn = _drag_data
	node.can_drop_fn = _can_drop
	node.drop_fn = _drop
	node.preview_fn = _drag_preview


func render() -> void:
	state = RecruitView.with_cards(port.get_state()) if port != null else {}
	if state.is_empty():
		return
	var frozen: bool = RecruitHud.populate(self)
	_layout()
	_render_shop(frozen)
	_render_board()
	_render_hand()
	_layout()
	_hero.show_hero(Data.d(state, "hero"), Data.i(state, "gold", 0))
	_show_selection()
	_render_discover()
	_refresh_scout()
	_land_queued_gains()


func toggle_scout() -> void:
	_reader_pinned = false
	_hover_timer.stop()
	_leave_timer.stop()
	_hover_view = {}
	_selected = {}
	_detail.show_empty()
	_scout.visible = not _scout.visible
	if _scout.visible:
		_scout_player_id = Data.i(state, "next_opponent_id", -2)
	_scout_token.lit = _scout.visible
	_who_token.visible = false
	render()
	if _scout.visible and RecruitView.is_ghost_next(state):
		_show_opponent()


func scout_player(player_id: int) -> void:
	_reader_pinned = false
	_hover_timer.stop()
	_leave_timer.stop()
	_selected = {}
	_hover_view = {}
	_detail.show_empty()
	_scout_player_id = player_id
	_scout.show()
	render()


func _refresh_scout() -> void:
	if not _scout.visible:
		return
	_scout_snapshot = port.scout_player(_scout_player_id)
	var units: Array = Data.a(_scout_snapshot, "board")
	_scout.show_board(
		Data.s(_scout_snapshot, "name", RecruitView.next_name(state)),
		units,
		Data.a(_scout_snapshot, "slot_effects"),
		Data.a(_scout_snapshot, "nests"),
		Data.d(_scout_snapshot, "hero")
	)
	_lanes.bindings = _projection.forecast([Data.a(state, "board"), units])
	_layout()


func _show_opponent() -> void:
	var card: Dictionary = (
		LobbyPlaque.reader_card(
			Data.d(_scout_snapshot, "standing"), Data.d(_scout_snapshot, "hero")
		)
		if _scout.visible and not _scout_snapshot.is_empty()
		else RecruitView.opponent_card(state)
	)
	if not card.is_empty():
		_read_external(card)


func _read_external(view: Dictionary) -> void:
	_reader_pinned = true
	_hover_timer.stop()
	_leave_timer.stop()
	_hover_view = {}
	_selected = {}
	_show_selection()
	_detail.show_unit(view)


func _show_away_bird(view: Dictionary, nest: int) -> void:
	_read_external(view)
	if nest >= 0:
		_board.show_relations([nest])


func _show_lobby_hero(standing: Dictionary) -> void:
	if _scout.visible:
		return
	var hero: Dictionary = {}
	if Data.b(standing, "is_human"):
		hero = Data.d(state, "hero")
	elif Data.i(standing, "player_id", -9) == Data.i(state, "next_opponent_id", -2):
		hero = Data.d(state, "next_opponent_hero")
	_read_external(LobbyPlaque.reader_card(standing, hero))


func _render_board() -> void:
	_board.clear()
	var board: Array = Data.a(state, "board")
	for slot: int in mini(board.size(), BoardView.SLOTS):
		if board[slot] is Dictionary:
			var view: Dictionary = _projection.recruit_unit(board, slot)
			_board.place_card(_make_card(view, "board", slot, 189.0, CardView.Mode.BOARD), slot)
	var marks: Array = RecruitView.slot_marks(state)
	_board.set_marks(marks)
	for slot: int in BoardView.SLOTS:
		if _board.cards[slot] != null:
			var unit: Dictionary = _board.cards[slot].unit
			_board.cards[slot].turns_shown = RecruitView.tile_slip(unit)
	_ooze_ui.render(_board, _motion, _shop_cards)


func _render_hand() -> void:
	_hand_cards.clear_cards()
	var hand: Array = Data.a(state, "hand")
	_hand_zone.tooltip_text = Data.s(RecruitView.larder_card(state), "text")
	_hand_count.text = "%d/%d" % [hand.size(), Data.i(state, "hand_limit", 4)]
	var larder: int = Data.i(state, "larder")
	if larder > 0:
		_hand_count.text = "%dg · %s" % [larder, _hand_count.text]
	_hand_count.visible = hand.size() >= Data.i(state, "hand_limit", 4)
	var count: int = hand.size()
	var card_size: Vector2 = _hand_card_size(count)
	var mode: CardView.Mode = CardView.Mode.MINI if count > 2 else CardView.Mode.SHOP
	for index: int in count:
		var view: Dictionary = hand[index]
		var card: CardView = _make_card(view, "hand", index, card_size.x, mode)
		card.set_card_size(card_size)
		_hand_cards.add_card(card)
	_hand_cards.arrange()


func _make_card(
	view: Dictionary, zone: String, index: int, width: float, mode: CardView.Mode
) -> CardView:
	var card: CardView = CardView.new()
	card.show_unit(view, mode)
	card.set_card_width(width)
	card.zone = zone
	card.index = index
	_wire(card)
	var caption: Label = card.get("_name_label")
	caption.clip_text = true
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return card


func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


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
		_discover.show_cards("Discover: pick one", options, false, Data.s(choice, "note"))


func _on_discover_picked(index: int) -> void:
	_discover = null
	_act(port.choose(index), "place")


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
			items = Data.a(_scout_snapshot, "board")
	return Data.entry(items, index)


func _show_selection() -> void:
	_board.clear_highlights()
	_board.set_pass_landing(-2)
	for card: Node in _shop_cards.get_children() + _hand_cards.get_children():
		if card is CardView:
			(card as CardView).selected = false
	for slot: int in BoardView.SLOTS:
		if _scout.card_at(slot) != null:
			_scout.card_at(slot).selected = false
	_detail.clear_actions()
	if _selected.is_empty():
		_detail.show_empty()
		_away_tray.show_state(state)
		return
	var zone: String = _selected["zone"]
	_detail.read_zone = zone
	var index: int = _selected["index"]
	if zone == "power":
		var hero: Dictionary = Data.d(state, "hero")
		_detail.show_unit(RecruitView.hero_card(hero), "Tap where to use it")
		_highlight_aim(Data.s(hero, "aim", "none"))
		return
	var view: Dictionary = _unit_at(zone, index)
	if zone == "board":
		view = _projection.recruit_unit(Data.a(state, "board"), index)
	if view.is_empty():
		_selected = {}
		_detail.show_empty()
		return
	var card: CardView = _card_at(zone, index)
	if card != null:
		card.selected = true
	match zone:
		"shop":
			_highlight_bellies(view)
			_detail.show_unit(_full_view(zone, view))
			var cost: int = Data.i(view, "cost", -1)
			_detail.add_action("Buy", _on_buy_selected, cost)
		"hand":
			var aim: String = Data.s(view, "aim", "none")
			var no_target: String = RecruitView.no_target_note(state, view)
			if CardView.is_spell(view) and not no_target.is_empty():
				_detail.show_unit(_ring_aim_card(view))
				_detail.add_unavailable_action(no_target)
			elif CardView.is_spell(view) and aim == "none":
				_detail.show_unit(view)
				_detail.add_action("Play", _on_spell_selected)
				_highlight_item(view)
			elif CardView.is_spell(view):
				_detail.show_unit(_ring_aim_card(view))
				_highlight_item(view)
			else:
				_highlight_bellies(view)
				_detail.show_unit(_full_view(zone, view))
				_highlight_empty_slots()
		"board":
			var mark: Dictionary = Data.entry(RecruitView.slot_marks(state), index)
			var round_now: int = Data.i(state, "round", 1)
			var sell_note: String = RecruitHeld.sell_note(view, round_now)
			_detail.show_unit(
				_full_view(zone, RecruitView.with_slot_note(view, mark, index)),
				(
					"%s %s"
					% [
						sell_note if not sell_note.is_empty() else "Tap a slot to move or swap.",
						RecruitView.geometry_note(view, index, Data.a(state, "board"))
					]
				)
			)
			var board: Array = Data.a(state, "board")
			if RecruitView.pass_direction(view) != 0:
				_board.set_pass_landing(RecruitView.pass_preview(board, view, index, index))
			_detail.add_action(
				RecruitHeld.sell_word(view, round_now),
				_on_sell_selected,
				RecruitHeld.sell_gold(view, round_now)
			)
			if not RecruitHeld.bellies_for(board, view).is_empty():
				_detail.add_action("Into a Belly", _on_into_belly)
			_highlight_other_slots(index)
			_board.show_relations(RecruitView.related_slots(view, index))
			if _selected.has("into_belly"):
				_board.clear_highlights()
				_highlight_bellies(view)
		"scout":
			_detail.show_unit(RecruitHeld.with_inside(view))
			_scout.pulse_reach(_board, _lanes.bindings, index)


func _card_at(zone: String, index: int) -> CardView:
	match zone:
		"board":
			return _board.cards[index] if index >= 0 and index < BoardView.SLOTS else null
		"hand":
			return _hand_cards.card_at(index)
		"shop":
			if index >= 0 and index < _shop_cards.get_child_count():
				return _shop_cards.get_child(index) as CardView
		"scout":
			return _scout.card_at(index)
	return null


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


func _on_hovered(zone: String, index: int, inside: bool) -> void:
	if not is_instance_valid(_leave_timer) or not _leave_timer.is_inside_tree():
		return
	if CardView.is_phone() or get_viewport().gui_is_dragging():
		return
	if _reader_pinned and (not inside or _unit_at(zone, index).is_empty()):
		return
	_reader_pinned = false
	if not _selected.is_empty():
		_hover_ring_aim(_selected, zone, index, inside)
		return
	_hover_zone = zone
	_hover_index = index
	var view: Dictionary = _full_view(zone, _unit_at(zone, index)) if inside else {}
	view = _ooze_ui.hover(_board, view, index, inside and zone == "board")

	if inside and zone == "board" and _unit_at(zone, index).is_empty():
		view = RecruitHeld.egg_card(Data.entry(RecruitView.slot_marks(state), index))
	_hover_view = view
	if view.is_empty():
		_hover_timer.stop()
		# The pointer may be on its way to the panel to hover a keyword: give it a moment.
		if _detail.visible and not CardView.is_phone():
			_leave_timer.start(LEAVE_SECONDS)
			return
		_end_hover()
	else:
		_leave_timer.stop()
		_hover_timer.start(HOVER_SECONDS)


func _end_hover() -> void:
	_leave_timer.stop()
	_board.set_pass_landing(-2)
	_board.show_relations([])
	_detail.show_empty()


func _on_leave_check() -> void:
	if _reader_pinned:
		return
	if not _hover_view.is_empty() or not _selected.is_empty() or not _detail.visible:
		return
	if _detail.get_global_rect().has_point(get_global_mouse_position()):
		_leave_timer.start(LEAVE_SECONDS)
	else:
		_end_hover()


func _show_hover() -> void:
	if not _reader_pinned and not _hover_view.is_empty() and _selected.is_empty():
		_detail.read_zone = _hover_zone
		_detail.show_unit(_hover_view)
		if _hover_zone == "scout":
			_scout.pulse_reach(_board, _lanes.bindings, _hover_index)
		elif _hover_zone == "board":
			_board.show_relations(RecruitView.related_slots(_hover_view, _hover_index))


func _on_tapped(zone: String, index: int) -> void:
	_reader_pinned = false
	_hover_timer.stop()
	if zone != "table":
		Sfx.tap()
	if zone == "hand" and index < 0 and Data.i(state, "larder") > 0:
		_read_external(RecruitView.larder_card(state))
		return
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
				_act(_safe_power(index), "hero_power")
				return
		elif from_zone == "hand" and CardView.is_spell(_unit_at("hand", from_index)):
			var item: Dictionary = _unit_at("hand", from_index)
			if RecruitView.item_lands(item, _unit_at("board", index), index, state):
				_act(_safe_item(Data.i(item, "card_index", -1), index), "keyword")
				return
		elif from_zone == "hand" and not has_unit:
			_act_placed(_safe_play(from_index, index), _unit_at("hand", from_index))
			return
		if from_zone == "board" and index != from_index:
			_act(_safe_move(from_index, index), "place")
			return
	if zone == "shop" and from_zone == "hand" and _aimed_at_shop(from_index, index):
		_act(_safe_item(Data.i(_unit_at("hand", from_index), "card_index", -1), index), "keyword")
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
	if zone == "hand" and not _selected.is_empty():
		var item: Dictionary = _unit_at(zone, index)
		if CardView.is_spell(item) and not RecruitView.no_target_note(state, item).is_empty():
			_feedback.refuse(_card_at(zone, index))


func _aimed_at_shop(hand_index: int, shop_index: int) -> bool:
	return RecruitHeld.shop_aim_fits(
		_unit_at("hand", hand_index), _unit_at("shop", shop_index), shop_index
	)


func _show_bare_slot(slot: int) -> void:
	var mark: Dictionary = Data.entry(RecruitView.slot_marks(state), slot)
	var view: Dictionary = RecruitHeld.slot_card(mark, RecruitView.slot_note(mark, slot))
	if view.is_empty():
		_show_selection()
	else:
		_detail.show_unit(view)


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
	_act(_safe_item(Data.i(item, "card_index", -1)), "keyword")


func _on_hero_power() -> void:
	if Data.s(Data.d(state, "hero"), "aim", "none") == "none":
		_act(_safe_power(), "hero_power")
		return
	_selected = {"zone": "power", "index": 0}
	_show_selection()


func _on_hero_tapped() -> void:
	_selected = {}
	_show_selection()
	var card: Dictionary = RecruitView.hero_card(Data.d(state, "hero"))
	var armor: int = Data.i(state, "armor", 0)
	if armor > 0:
		card["text"] = "%s\nArmor %d: lost before Health." % [Data.s(card, "text"), armor]
	_detail.show_unit(card)
	if not Data.a(port.get_last_combat(), "events").is_empty():
		_detail.add_action("Last fight", func() -> void: last_fight_requested.emit())
		_detail.add_action("Watch again", func() -> void: watch_fight_requested.emit())


func _drag_data(zone: String, index: int) -> Variant:
	if zone not in ["shop", "hand", "board"] or _unit_at(zone, index).is_empty():
		return null
	_reader_pinned = false
	_hover_timer.stop()
	_leave_timer.stop()
	_hover_view = {}
	_detail.show_empty()
	_drag_committed = false
	return {"zone": zone, "index": index}


func _drag_preview(zone: String, index: int) -> Control:
	var holder := RecruitHeld.DragLift.new()
	var card: CardView = CardView.new()
	_drag_card = card
	_drag_source = _card_at(zone, index)
	var view: Dictionary = _unit_at(zone, index)
	if zone == "board":
		view = _projection.recruit_unit(Data.a(state, "board"), index)
	card.show_unit(view, CardView.Mode.BOARD)
	card.set_card_size(ArenaGeometry.UNIT)
	holder.hold(card, CardView.is_phone())
	return holder


func _can_drop(data: Variant, zone: String, index: int) -> bool:
	if not data is Dictionary:
		return false
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	var from_index: int = Data.i(drag, "index", -1)
	show_pass_preview(from_zone, from_index, zone, index)
	var target_empty: bool = _unit_at(zone, index).is_empty()
	var allowed: bool = false
	match zone:
		"board":
			allowed = _can_drop_on_board(from_zone, from_index, index, target_empty)
		"hand":
			allowed = from_zone == "shop"
		"shop":
			allowed = (
				from_zone == "board" or (from_zone == "hand" and _aimed_at_shop(from_index, index))
			)
		"table":
			allowed = (
				from_zone == "hand"
				and CardView.is_spell(_unit_at(from_zone, from_index))
				and Data.s(_unit_at(from_zone, from_index), "aim", "none") == "none"
			)
	if is_instance_valid(_drop_pocket):
		_drop_pocket.aim_recruit(_board, _hand_zone, _shop_zone, zone, index, allowed)
	return allowed


func show_pass_preview(from_zone: String, from_index: int, zone: String, index: int) -> void:
	var card: Dictionary = _unit_at(from_zone, from_index)
	if is_instance_valid(_drag_card) and Data.s(card, "def_id") == "great_lump":
		var mark: Dictionary = (
			Data.entry(RecruitView.slot_marks(state), index) if zone == "board" else {}
		)
		_drag_card.show_unit(RecruitHeld.lump_preview(card, mark), CardView.Mode.BOARD)
	if zone == "board":
		_board.show_relations(RecruitView.related_slots(card, index), index)


func _can_drop_on_board(from_zone: String, from_index: int, slot: int, empty: bool) -> bool:
	if from_zone == "board":
		return slot != from_index
	var card: Dictionary = _unit_at(from_zone, from_index)
	if CardView.is_spell(card):
		return (
			from_zone == "hand"
			and RecruitView.item_lands(card, _unit_at("board", slot), slot, state)
		)
	if RecruitHeld.can_swallow(_unit_at("board", slot), card):
		return from_zone in ["hand", "shop"]
	return from_zone in ["hand", "shop"] and empty


func _drop(data: Variant, zone: String, index: int) -> void:
	var drag: Dictionary = data
	var from_zone: String = str(drag.get("zone", ""))
	var from_index: int = Data.i(drag, "index", -1)
	_released_card = {}
	if is_instance_valid(_drag_card):
		_released_card = {
			"zone": from_zone,
			"index": from_index,
			"rect":
			_action_motion.get_global_transform().affine_inverse() * _drag_card.get_global_rect(),
			"mode": _drag_card.mode,
		}
	_drag_committed = true
	if zone == "board" and from_zone != "board" and _try_swallow(from_zone, from_index, index):
		return
	_selected = {}
	match [from_zone, zone]:
		["shop", "hand"]:
			_act(_buy_at(from_index), "buy")
		["shop", "board"]:
			var bought: Dictionary = _unit_at("shop", from_index)
			_act_placed(_safe_buy_play(from_index, index), bought, "buy")
		["hand", "board"]:
			var card: Dictionary = _unit_at("hand", from_index)
			if CardView.is_spell(card):
				_act(_safe_item(Data.i(card, "card_index", -1), index), "keyword")
			else:
				_act_placed(_safe_play(from_index, index), card)
		["hand", "shop"]:
			var item: Dictionary = _unit_at("hand", from_index)
			_act(_safe_item(Data.i(item, "card_index", -1), index), "keyword")
		["hand", "table"]:
			var item: Dictionary = _unit_at("hand", from_index)
			_act(_safe_item(Data.i(item, "card_index", -1)), "keyword")
		["board", "board"]:
			_act(_safe_move(from_index, index), "place")
		["board", "shop"]:
			_act(port.sell(from_index), "sell")


func _on_drag_started(zone: String, index: int) -> void:
	_action_motion.finish()
	if is_instance_valid(_drag_source):
		_drag_source.modulate.a = 0.22
	_drop_pocket = RecruitHeld.DropPocket.new()
	_stage.add_child(_drop_pocket)
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
		if is_instance_valid(_drag_source):
			_drag_source.modulate.a = 1.0
		if is_instance_valid(_drop_pocket):
			_drop_pocket.hide()
			_drop_pocket.queue_free()
		_drag_card = null
		_drag_source = null
		_released_card = {}
		_shelf.selling = false
		_shop_cards.modulate = Color.WHITE
		if not _drag_committed:
			_show_selection()
		_drag_committed = false


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
		if _scout.visible:
			toggle_scout()
		else:
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


func refresh_settings() -> void:
	_dev_token.visible = Settings.show_dev_panel
	if not Settings.show_dev_panel:
		_dev.visible = false
	_layout()


func _on_turn_skipped() -> void:
	_selected = {}
	if port.is_over() or port.get_state().get("placement") != null:
		game_over_reached.emit()
		return
	render()
	_dev.refresh()


func _act(reason: String, sound: String = "") -> void:
	if reason == "Shy warning: repeat to confirm":
		return
	if reason.is_empty():
		_selected = {}
		if not sound.is_empty():
			Sfx.play(sound)
		_after_change(true, sound)
		return
	show_toast(reason)
	render()


func _act_placed(reason: String, view: Dictionary, sound: String = "place") -> void:
	if reason.is_empty():
		Sfx.play_voice(Data.a(view, "tribes"))
	_act(reason, sound)


func _after_change(rewards: bool = true, sound: String = "") -> void:
	_feedback.finish()
	_action_motion.finish()
	var before: Dictionary = _action_motion.snapshot(self)
	for source: Dictionary in Data.a(before, "cards"):
		if (
			Data.s(source, "zone") == Data.s(_released_card, "zone")
			and Data.i(source, "index", -1) == Data.i(_released_card, "index", -2)
		):
			source["rect"] = _released_card["rect"]
			source["mode"] = _released_card["mode"]
			source["released"] = true
	_released_card = {}
	var old_state: Dictionary = state
	render()
	_action_motion.present(self, before, sound)
	var notice: String = _feedback.present(self, before)
	if not notice.is_empty():
		show_toast(notice)
	if rewards:
		_play_change_sounds(old_state, sound)


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
	var reason: String = port.toggle_freeze()
	_act(reason, "freeze")
	if reason.is_empty():
		var delay: float = 0.0
		for child: Node in _shop_cards.get_children():
			var card: CardView = child as CardView
			if card != null:
				card.animate_frost(
					Data.b(state, "frozen"), delay, Settings.fight_speed, Settings.reduce_motion
				)
				delay += 0.05 / maxf(1.0, Settings.fight_speed)


func _on_end_turn() -> void:
	if _ending:
		_ending = false
		_feedback.finish()
		_motion.finish()
		combat_ready.emit()
		return
	if not _allow_shy("end_turn"):
		return
	var captured: Array[Dictionary] = []
	_feedback.finish()
	_action_motion.finish()
	var before: Dictionary = _action_motion.snapshot(self)
	var player: PlayerState = null
	var previous: Callable
	if port is CorePort:
		var core: CorePort = port as CorePort
		var players: Array[PlayerState] = core.session.get("_players")
		player = players[0]
		previous = player.log_observer
		player.log_observer = func(type: String, fields: Dictionary) -> void:
			var entry: Dictionary = fields.duplicate(true)
			entry["type"] = type
			captured.append(entry)
			if previous.is_valid():
				previous.call(type, fields)
	var reason: String = port.end_turn()
	if player != null:
		player.log_observer = previous
	if reason.is_empty():
		_selected = {}
		_detail.show_empty()
		Sfx.play("turn_end")
		_ending = true
		var notice: String = _feedback.present(self, before, captured)
		if not notice.is_empty():
			show_toast(notice)
		_motion.play_events(_board, captured, _complete_end_turn)
	else:
		show_toast(reason)


func _complete_end_turn() -> void:
	var remaining: float = _feedback.duration - _feedback.elapsed
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	if not _ending:
		return
	_feedback.finish()
	_ending = false
	combat_ready.emit()


func _land_queued_gains() -> void:
	var round_now: int = Data.i(state, "round")
	if _landing_round == round_now:
		return
	_landing_round = round_now
	for event: Dictionary in Data.a(state, "recruit_log"):
		if Data.s(event, "type") != "gain_landed":
			continue
		for card: CardView in _board.cards:
			if card != null and Data.i(card.unit, "iid") == Data.i(event, "iid", -2):
				_motion.roll_gain(card, Data.i(event, "attack"), Data.i(event, "health"))


func _pulse_reader_reach() -> void:
	var zone: String = Data.s(_selected, "zone", _hover_zone)
	var index: int = Data.i(_selected, "index", _hover_index)
	if zone == "scout":
		_scout.pulse_reach(_board, _lanes.bindings, index)
	elif zone == "board":
		_board.show_relations(RecruitView.related_slots(_unit_at(zone, index), index))
