extends GutTest
## The recruit screen draws a view state and reports input as signals, with no rules of its own.

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")

var _screen: RecruitScreen


func _make(state: Dictionary) -> RecruitScreen:
	_screen = SCREEN.instantiate()
	_screen.state = state
	add_child_autofree(_screen)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
	_screen.show_state(state)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	return _screen


func _mockup() -> Dictionary:
	return GlassScreen.load_state("res://tests/screens/fixtures/recruit_mockup.json")


func _stage() -> Control:
	return _screen.get_node("Frame/Stage") as Control


## Children of the stage's three layers (Back, Cards, Front) whose names start with prefix.
func _count(prefix: String) -> int:
	var n: int = 0
	for layer: Node in _stage().get_children():
		for child: Node in layer.get_children():
			if String(child.name).begins_with(prefix) and not child.is_queued_for_deletion():
				n += 1
	return n


func _find(node_name: String) -> Node:
	for layer: Node in _stage().get_children():
		var found: Node = layer.get_node_or_null(node_name)
		if found != null:
			return found
	return null


func _unit(id: String) -> Dictionary:
	return {"id": id, "tier": 1, "art": "mouse-1", "attack": 1, "health": 2, "name": "Mouse"}


func test_builds_the_mockup_state() -> void:
	_make(_mockup())
	assert_eq(_count("Card_s"), 7, "5 shop units and 2 spells")
	assert_eq(_count("Card_b"), 6, "6 board units")
	assert_eq(_count("Slot_"), 7, "every slot drawn by the board, under the cards")
	assert_eq(_count("Card_h"), 6, "6 cards in hand")
	assert_true(_find("Slot_5") is GlassBox, "the empty slot B2")
	var count: GlassText = _find("HandCount")
	assert_eq(count.words, "Hand 6/7", "the hand limit is 7, not the mock-up's 10")
	var renown: Array[String] = _texts(_find("Slot_5"))
	assert_eq(renown, ["Renown 4"] as Array[String], "the empty slot shows its Renown")


func test_places_follow_the_mockups_geometry() -> void:
	_make(_mockup())
	var g: Dictionary = RecruitShop.geometry()
	var shop: Control = _find("Card_s0")
	var shop_at: Vector2 = Vector2(
		GlassPieces.as_float(g["shopL"]), GlassPieces.as_float(g["shopTop"])
	)
	assert_eq(shop.position, shop_at, "the shop starts at geom()'s shopL")
	var front: Control = _find("Card_b0")
	assert_almost_eq(front.position.y, GlassPieces.as_float(g["boardTop"]), 0.001)
	var second: Control = _find("Card_b1")
	var back: Control = _find("Card_b4")
	var pitch: float = second.position.x - front.position.x
	assert_almost_eq(
		back.position.x - front.position.x, pitch / 2.0, 0.001, "back row half a slot in"
	)


func test_hand_of_seven_fans_evenly() -> void:
	var state: Dictionary = _mockup()
	var hand: Array = []
	for i: int in 7:
		hand.append(_unit("h%d" % i))
	state["hand"] = hand
	_make(state)
	assert_eq(_count("Card_h"), 7)
	var first: Control = _find("Card_h0")
	var middle: Control = _find("Card_h3")
	var last: Control = _find("Card_h6")
	assert_almost_eq(middle.rotation_degrees, 0.0, 0.001, "the middle card stands straight")
	assert_almost_eq(first.rotation_degrees, -last.rotation_degrees, 0.001, "the fan is symmetric")
	assert_almost_eq(
		first.position.x + last.position.x, 2.0 * middle.position.x, 0.01, "centred on the middle"
	)
	var count: GlassText = _find("HandCount")
	assert_eq(count.words, "Hand 7/7")


func test_empty_board_shows_seven_slots() -> void:
	var state: Dictionary = _mockup()
	state["board"] = [null, null, null, null, null, null, null]
	state["slots"] = []
	state["hand"] = []
	_make(state)
	assert_eq(_count("Slot_"), 7)
	assert_eq(_count("Card_b"), 0)
	assert_eq(_count("Card_h"), 0)


func test_leaderboard_lists_every_player() -> void:
	_screen = SCREEN.instantiate()
	_screen.show_leaderboard = true
	_screen.state = _mockup()
	add_child_autofree(_screen)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
	_screen.show_state(_mockup())
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	assert_not_null(_find("Leaderboard"))


func test_a_player_who_is_out_looks_out_on_the_leaderboard() -> void:
	var state: Dictionary = _mockup()
	var players: Array = state["players"]
	var last: Dictionary = players[players.size() - 1]
	last["alive"] = false
	_screen = SCREEN.instantiate()
	_screen.show_leaderboard = true
	_screen.state = state
	add_child_autofree(_screen)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
	_screen.show_state(state)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var out: int = players.size() - 1
	assert_null(_find("LeaderHealth_%d" % out), "no Health for a player who is out")
	assert_not_null(_find("LeaderHealth_0"))
	var port: Control = _find("LeaderPortrait_%d" % out)
	assert_eq(port.modulate, Color(0.5, 0.5, 0.5), "dark")
	var lit: Control = _find("LeaderPortrait_0")
	assert_eq(lit.modulate, Color.WHITE)


func test_numbers_above_the_printed_ones_are_green_and_the_hover_says_why() -> void:
	var state: Dictionary = _mockup()
	var board: Array = state["board"]
	var unit: Dictionary = board[0]
	unit["base_attack"] = _i(unit["attack"]) - 1
	unit["base_health"] = _i(unit["health"]) + 1
	unit["sources"] = ["Printed 6/5.", "Lancer +0/+8."]
	_make(state)
	var card: GlassCard = _find("Card_b0")
	assert_true(card.up_attack, "Attack above what it prints")
	assert_true(card.hurt, "Health below what it prints")
	_move(_centre(0, "board"))
	var green: Array[String] = []
	for node: Node in _find("Tip").find_children("*", "GlassText", true, false):
		var words: GlassText = node
		if words.colour == GlassParts.TIP_SOURCE:
			green.append(words.words)
	assert_eq(green, ["Printed 6/5.", "Lancer +0/+8."] as Array[String])


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


# ---- input: the screen emits; it changes nothing itself ----


func _press(at: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at + (_screen.get_node("Frame") as Control).position
	_screen._gui_input(event)


func _move(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at + (_screen.get_node("Frame") as Control).position
	_screen._gui_input(event)


func _click(at: Vector2) -> void:
	_press(at, true)
	_press(at, false)


func _drag(from: Vector2, to: Vector2) -> void:
	_press(from, true)
	_move(from.lerp(to, 0.5))
	_move(to)
	_press(to, false)


## The middle of a shop unit, shop spell or board slot, in stage pixels.
func _centre(i: int, kind: String) -> Vector2:
	var card: Control = _find("Card_s0")
	var half: Vector2 = card.size / 2.0
	match kind:
		"shop":
			return _screen.shop_xy(i) + half
		"spell":
			var spell: Control = _find("Card_s5")
			return _screen.spell_xy(i) + spell.size / 2.0
		_:
			return _screen.slot_xy(i) + half


func test_a_click_on_a_shop_card_shows_it_and_buys_nothing() -> void:
	_make(_mockup())
	watch_signals(_screen)
	_click(_centre(4, "shop"))
	_click(_centre(1, "spell"))
	assert_signal_not_emitted(_screen, "action_requested", "a stray click spends no gold")
	# put back with a hop: its detail shows once it is still
	await get_tree().create_timer(0.5).timeout
	assert_true((_find("Tip") as Control).visible, "it shows the card's detail")


func test_a_new_state_mid_drag_drops_the_drag() -> void:
	_make(_mockup())
	watch_signals(_screen)
	var from: Vector2 = _centre(0, "board")
	_press(from, true)
	_move(from + Vector2(40, 40))
	_screen.show_state(_mockup())
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	_move(from + Vector2(80, 80))
	_press(_centre(3, "board"), false)
	assert_signal_not_emitted(_screen, "action_requested")
	assert_eq(_count("Card_b"), 6)


func test_empty_state_is_an_empty_table() -> void:
	_make({})
	assert_eq(_count("Card_"), 0)
	assert_eq(_count("Slot_"), 7)
	assert_null(_find("Button_tier"))


func test_bought_cards_leave_holes_and_frozen_shows() -> void:
	var state: Dictionary = _mockup()
	var units: Array = state["shop_units"]
	units[1] = null
	state["frozen"] = true
	_make(state)
	assert_eq(_count("Card_s"), 6, "four units and two spells")
	var last: Control = _find("Card_s4")
	assert_eq(last.position, _screen.shop_xy(4), "the others keep their places")
	assert_not_null(last.get_node_or_null("Frost"), "STAND-IN frozen look on shop cards")
	assert_not_null(_find("Button_freeze").get_node_or_null("Frost"), "and the button")


func test_top_tier_has_no_upgrade_button_and_short_gold_dims() -> void:
	var state: Dictionary = _mockup()
	state.erase("upgrade_cost")
	state["legal_actions"] = [{"type": "freeze"}, {"type": "end_turn"}]
	_make(state)
	assert_null(_find("Button_tier"))
	assert_not_null(_find("Button_refresh_short"), "refresh is not a legal action")
	assert_not_null(_find("Button_freeze"), "freeze is")
	state["upgrade_cost"] = 1
	state["gold"] = 0
	state["legal_actions"] = [{"type": "upgrade"}, {"type": "refresh"}]
	_screen.show_state(state)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	assert_not_null(_find("Button_tier"), "legal though gold looks short: the core decides")
	assert_not_null(_find("Button_refresh"))
	state.erase("legal_actions")
	_screen.show_state(state)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	assert_not_null(_find("Button_refresh"), "no legal_actions: nothing dimmed")


func test_counters_message_golden_and_renown() -> void:
	var state: Dictionary = _mockup()
	state["counters"] = [{"id": "compost", "value": 3}]
	state["message"] = "Not enough gold."
	var board: Array = state["board"]
	var stag: Dictionary = board[0]
	stag["golden"] = true
	stag["counters"] = [{"id": "tide", "value": 2}]
	var slots: Array = state["slots"]
	slots[0] = {"renown": 1}
	_make(state)
	assert_eq((_find("Message") as GlassText).words, "Not enough gold.")
	var card: GlassCard = _find("Card_b0")
	assert_true(card.golden)
	assert_not_null(card.get_node_or_null("Pill_0"), "the unit's counter")
	assert_null(card.get_node_or_null("Renown"), "nothing of the slot rides on the card")
	assert_not_null(_find("Renown_0"), "the board draws Renown over the unit")


func test_tab_and_the_portrait_toggle_the_leaderboard() -> void:
	_make(_mockup())
	assert_null(_find("Leaderboard"), "hidden at first, as in the mock-up")
	var tab: InputEventKey = InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	_screen._unhandled_key_input(tab)
	assert_not_null(_find("Leaderboard"))
	var hero: Control = _find("Hero")
	_click(hero.position + hero.size / 2.0)
	assert_null(_find("Leaderboard"))


func test_the_stage_is_letterboxed_in_other_window_shapes() -> void:
	_make(_mockup())
	_screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_screen.size = Vector2(2560, 1080)
	_screen._fit()
	var frame: Control = _screen.get_node("Frame")
	assert_eq(frame.size, Vector2(1920, 1080))
	assert_eq(frame.position, Vector2(320, 0))
	assert_true(frame.clip_contents)


func test_dragging_a_shop_card_down_buys_it() -> void:
	_make(_mockup())
	watch_signals(_screen)
	_drag(_centre(2, "shop"), Vector2(960, 1000))
	assert_signal_emitted_with_parameters(
		_screen, "action_requested", [{"type": "buy", "spell": false, "index": 2}]
	)


func test_dragging_from_hand_to_a_slot_plays_it() -> void:
	_make(_mockup())
	watch_signals(_screen)
	var card: Control = _find("Card_h2")
	var place: Vector3 = _screen.hand_place(2, 6)
	var grip: Vector2 = Vector2(place.x, place.y) + Vector2(card.size.x / 2.0, card.size.y * 0.8)
	_drag(grip, _centre(5, "slot"))
	assert_signal_emitted_with_parameters(
		_screen, "action_requested", [{"type": "play", "hand": 2, "slot": 5, "target": -1}]
	)


func test_dragging_on_the_board_moves_and_up_into_the_shop_sells() -> void:
	_make(_mockup())
	watch_signals(_screen)
	_drag(_centre(0, "board"), _centre(3, "board"))
	assert_signal_emitted_with_parameters(
		_screen, "action_requested", [{"type": "move", "from": 0, "to": 3}]
	)
	_drag(_centre(1, "board"), Vector2(960, 150))
	assert_signal_emitted_with_parameters(
		_screen, "action_requested", [{"type": "sell", "slot": 1}]
	)


func test_buttons_and_end_turn() -> void:
	_make(_mockup())
	watch_signals(_screen)
	var tier: Control = _find("Button_tier")
	var refresh: Control = _find("Button_refresh")
	var freeze: Control = _find("Button_freeze")
	var end: Control = _find("EndTurn")
	for node: Control in [tier, refresh, freeze, end]:
		_click(node.position + node.size / 2.0)
	assert_signal_emit_count(_screen, "action_requested", 4)
	var kinds: Array[String] = []
	for i: int in 4:
		var params: Array = get_signal_parameters(_screen, "action_requested", i)
		var sent: Dictionary = params[0]
		kinds.append(str(sent["type"]))
	assert_eq(kinds, ["upgrade", "refresh", "freeze", "end_turn"])


func test_upgrade_caption_is_the_shared_shop_up_icon_with_tiers_and_cost_retained() -> void:
	var state: Dictionary = _mockup()
	_make(state)
	var button: Control = _find("Button_tier")
	var icon: TextureRect = button.find_child("ShopUp", true, false)
	assert_not_null(icon)
	assert_eq(icon.size, Vector2(18, 18), "caption-sized icon")
	assert_same(icon.texture, GlassPieces.icon("shop_up", Color("c9bda6"), 18, 2.4))
	assert_eq(icon.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the button keeps its hit area")
	var tier: int = GlassPieces.as_int(state["tier"])
	assert_eq(_texts(button), ["%d → %d" % [tier, tier + 1]] as Array[String])
	var coins: Array[Node] = button.find_children("*", "GoldCoin", true, false)
	assert_eq(coins.size(), 1)
	assert_eq((coins[0] as GoldCoin).amount, GlassPieces.as_int(state["upgrade_cost"]))


func test_a_drop_nowhere_emits_nothing_and_changes_nothing() -> void:
	var state: Dictionary = _mockup()
	_make(state)
	watch_signals(_screen)
	_drag(_centre(0, "board"), Vector2(1800, 700))
	assert_signal_not_emitted(_screen, "action_requested")
	assert_eq(_screen.state, state, "the screen keeps the state it was given")


func test_hover_shows_the_cards_name_and_rules() -> void:
	_make(_mockup())
	_move(_centre(0, "board"))
	var tip: Control = _find("Tip")
	assert_true(tip.visible)
	var words: Array[String] = []
	for node: Node in tip.find_children("*", "GlassText", true, false):
		words.append((node as GlassText).words)
	assert_has(words, "Stag")
	assert_has(words, "TIER 6 · UNIT")


func test_a_hovered_hand_card_stands_up_whole_with_its_words_beside_it() -> void:
	_make(_mockup())
	var card: Control = _find("Card_h2")
	var rest: Vector2 = card.position
	var turn: float = card.rotation
	assert_gt(rest.y + card.size.y, 1080.0, "at rest a hand card is cut by the bottom")
	_move(Vector2(rest.x + card.size.x / 2.0, 1060.0))
	assert_almost_eq(card.position.y + card.size.y, 1072.0, 0.5, "its foot 8 px above the bottom")
	assert_eq(card.rotation, 0.0, "unturned")
	var tip: Control = _find("Tip")
	assert_true(tip.visible)
	assert_null(tip.get_node_or_null("Card"), "no enlarged copy: the words alone")
	assert_gt(tip.position.x, card.position.x + card.size.x, "beside it")
	var text: GlassBox = tip.get_child(tip.get_child_count() - 1)
	assert_lte(tip.position.y + text.position.y + text.box_size.y, 1080.0, "on the screen")
	_move(Vector2(960, 300))
	assert_eq(card.position, rest, "back to its rest")
	assert_eq(card.rotation, turn)


func test_no_hand_card_covers_a_board_slot_at_rest() -> void:
	_make(_mockup())
	var first: Control = _find("Card_h0")
	var slot_bottom: float = _screen.slot_xy(4).y + first.size.y
	for card: Node in _stage().find_children("Card_h*", "", true, false):
		var hand: Control = card as Control
		var xf: Transform2D = hand.get_transform()
		var top: float = minf((xf * Vector2.ZERO).y, (xf * Vector2(hand.size.x, 0)).y)
		assert_gte(top, slot_bottom, "%s stays below the back row" % hand.name)


func test_discover_options_read_without_a_hover_and_say_how_many_wait() -> void:
	var state: Dictionary = GlassScreen.load_state(
		"res://tests/screens/fixtures/recruit_play_discover.json"
	)
	var discover: Dictionary = state["discover"]
	discover["waiting"] = 2
	_make(state)
	var options: Array = discover["options"]
	for i: int in options.size():
		var pane: Control = _find("DiscoverText_%d" % i)
		assert_not_null(pane, "option %d has its text under it" % i)
		var option: Control = _find("Discover_%d" % i)
		assert_gt(pane.position.y, option.position.y + option.size.y, "under it")
		var words: Array[String] = []
		for node: Node in pane.find_children("*", "GlassText", true, false):
			words.append((node as GlassText).words)
		var option_data: Dictionary = options[i]
		assert_has(words, str(option_data["name"]))
	var more: GlassText = _find("DiscoverWaiting")
	assert_eq(more.words, "2 more to pick")
	var first: Control = _find("Discover_0")
	_move(first.position + first.size / 2.0)
	var tip: Control = _find("Tip")
	assert_true(tip.visible)
	assert_null(tip.get_node_or_null("Card"), "no enlarged copy over the option")
	assert_gt(tip.position.y, first.position.y + first.size.y, "under the option, not over it")
	var second: Control = _find("Discover_1")
	assert_lt(tip.position.x + 300.0, second.position.x + 60.0, "the next option stays clear")


# ---- cards kept by uid between states ----


func _with_uids(state: Dictionary) -> Dictionary:
	var uid: int = 100
	for key: String in ["shop_units", "board", "hand"]:
		for card: Variant in state[key]:
			if card is Dictionary:
				var held: Dictionary = card
				held["uid"] = uid
				uid += 1
	# slot 5 plain, so a card moving there keeps its look
	var slots: Array = state["slots"]
	slots[5] = {}
	return state


func test_a_card_keeps_its_node_and_glides_to_its_new_place() -> void:
	var state: Dictionary = _with_uids(_mockup())
	_make(state)
	var hand_card: Control = _screen.node_for("hand", 2)
	var moved: Dictionary = state.duplicate(true)
	var hand: Array = moved["hand"]
	var board: Array = moved["board"]
	board[5] = hand.pop_at(2)
	_screen.show_state(moved)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	assert_same(_screen.node_for("board", 5), hand_card, "the same node, now on the board")
	assert_ne(hand_card.position, _screen.slot_xy(5), "still on its way")
	_screen.settle()
	assert_eq(hand_card.position, _screen.slot_xy(5))
	assert_almost_eq(hand_card.rotation_degrees, 0.0, 0.001)


func test_a_bought_card_starts_where_the_shop_card_was() -> void:
	var state: Dictionary = _mockup()
	_make(state)
	var shop_card: Control = _screen.node_for("shop", 2)
	var bought: Dictionary = state.duplicate(true)
	var units: Array = bought["shop_units"]
	var card: Dictionary = units[2]
	units[2] = null
	card["uid"] = 7
	var hand: Array = bought["hand"]
	hand.append(card)
	_screen.show_state(bought)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var in_hand: Control = _screen.node_for("hand", 6)
	assert_eq(in_hand.position, shop_card.position, "it moves from the shop")


func test_a_changed_number_pops_and_a_card_that_leaves_fades() -> void:
	var state: Dictionary = _with_uids(_mockup())
	_make(state)
	var next: Dictionary = state.duplicate(true)
	var board: Array = next["board"]
	var second: Dictionary = board[1]
	second["attack"] = 9
	var gone: Control = _screen.node_for("board", 0)
	board[0] = null
	_screen.show_state(next)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var card: GlassCard = _screen.node_for("board", 1)
	assert_gt(card.number_pop.x, 1.0, "Attack pops")
	assert_eq(card.number_pop.y, 1.0, "Health did not change")
	assert_true(is_instance_valid(gone) and gone.is_inside_tree(), "it fades, not vanishes")
	assert_eq(_screen.targets_of("board").size(), 5, "and is no longer a target")


func test_a_new_state_mid_move_wins() -> void:
	var state: Dictionary = _with_uids(_mockup())
	_make(state)
	var node: Control = _screen.node_for("board", 0)
	var first: Dictionary = state.duplicate(true)
	var board: Array = first["board"]
	board[5] = board[0]
	board[0] = null
	_screen.show_state(first)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var back: Dictionary = state.duplicate(true)
	_screen.show_state(back)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	_screen.settle()
	assert_eq(node.position, _screen.slot_xy(0), "it ends where the newest state puts it")


# ---- keywords and counters by the state's display table ----


func _display_state() -> Dictionary:
	var state: Dictionary = _mockup()
	state["display"] = {
		"taunt": {"name": "Taunt", "reminder": "Enemies must attack this first."},
		"tide": {"name": "Tide", "reminder": "Grows when a Tider dies."},
		"heap": {"name": "Heap", "reminder": "Every unit sold goes here."},
		"discover": {"name": "", "reminder": "", "hidden": true},
		"mark": {"name": "Mark", "reminder": "", "hidden": true},
	}
	var board: Array = state["board"]
	var stag: Dictionary = board[0]
	stag["keywords"] = ["taunt", "discover", "mark", "triple_reward"]
	stag["counters"] = [{"id": "tide", "value": 3}, {"id": "mark", "value": 1}]
	state["counters"] = [{"id": "heap", "value": 4}, {"id": "mark", "value": 2}]
	return state


func _texts(node: Node) -> Array[String]:
	var out: Array[String] = []
	for words: Node in node.find_children("*", "GlassText", true, false):
		out.append((words as GlassText).words)
	return out


func _pill_texts(card: Node) -> Array[String]:
	var out: Array[String] = []
	for pill: Node in card.get_children():
		if String(pill.name).begins_with("Pill"):
			out.append((pill as KeywordMark).words)
	return out


func test_pills_are_named_by_the_display_table_and_hidden_ones_left_out() -> void:
	_make(_display_state())
	assert_eq(_pill_texts(_find("Card_b0")), ["Taunt", "Tide 3"] as Array[String])


## Names repeat ("Hopper" is five ids), so a display name is never a key: only ids are looked up.
func test_a_display_name_is_not_a_key() -> void:
	var state: Dictionary = _display_state()
	var board: Array = state["board"]
	var stag: Dictionary = board[0]
	stag["keywords"] = ["Taunt", "Mark"]
	stag["counters"] = [{"id": "Tide", "value": 3}]
	_make(state)
	assert_eq(_pill_texts(_find("Card_b0")), [] as Array[String])


func test_the_hover_keeps_reminders_in_keyword_details() -> void:
	_make(_display_state())
	_move(_centre(0, "board"))
	var words: String = " ".join(_texts(_find("Tip").get_node("Words")))
	assert_false(words.contains("Enemies must attack this first."))
	assert_false(words.contains("Grows when a Tider dies."))
	assert_false(words.contains("Alt"))
	assert_eq(_screen._tips.details.size(), 2)
	assert_false(" ".join(_texts(_find("Tip"))).contains("Mark"), "nothing for a hidden mark")


func test_player_counters_show_name_and_value_with_a_reminder_on_hover() -> void:
	_make(_display_state())
	var chip: GlassBox = _find("Chip_0")
	assert_eq(_texts(chip), ["Heap", "4"] as Array[String])
	assert_null(_find("Chip_1"), "the hidden counter is not drawn")
	var frame: Control = _screen.get_node("Frame")
	_move(chip.global_position - frame.global_position + chip.size / 2.0)
	var tip: Control = _find("Tip")
	assert_true(tip.visible)
	assert_has(_texts(_find("Tip")), "Heap")
	assert_string_contains(" ".join(_texts(_find("Tip"))), "Every unit sold goes here.")


func test_whole_numbers_from_json_drop_their_point() -> void:
	assert_eq(GlassScreen.number_words(3.0), "3")
	assert_eq(GlassScreen.number_words(2.5), "2.5")
	assert_eq(GlassScreen.number_words("×4"), "×4")


func test_contract_abilities_show_dimmed_when_not_usable() -> void:
	var state: Dictionary = GlassScreen.load_state(
		"res://tests/screens/fixtures/recruit_play_ability.json"
	)
	var board: Array = state["board"]
	var stag: Dictionary = board[0]
	stag["abilities"] = [
		{"id": "order_slot", "name": "Order", "cost": 1, "usable": true, "target_kind": "slot"},
		{"id": "rally", "name": "Rally", "cost": 2, "usable": false, "target_kind": "none"},
	]
	_make(state)
	var card: Control = _screen.node_for("board", 0)
	var rally: GlassBox = card.get_node("Ability_rally")
	assert_eq(rally.modulate, RecruitScreen.SHORT_DIM, "drawn, dimmed")
	assert_eq(_screen.targets_of("ability").size(), 1, "only the usable one takes clicks")
	assert_eq(RecruitScreen.target_kind({"target_kind": "none"}), "")
	assert_eq(RecruitScreen.target_kind({"target_kind": "unit"}), "unit")


func test_a_heap_plate_lists_its_entries_on_hover_and_pops_when_it_changes() -> void:
	var state: Dictionary = _display_state()
	var runner: Dictionary = {"id": "runner", "name": "Bramble Runner", "tier": 1}
	var hedge: Dictionary = {"id": "hedge", "name": "Hedge Layer", "tier": 2}
	state["counters"] = [{"id": "heap", "value": 3, "entries": [runner, hedge, runner]}]
	_make(state)
	var plate: Control = _find("Chip_0")
	assert_almost_eq(plate.size.y, 44.0, 0.1, "a 44 px plate")
	_move(plate.position + plate.size / 2.0)
	var words: String = " ".join(_texts(_find("Tip")))
	assert_string_contains(words, "HEAP · 3 UNITS")
	assert_string_contains(words, "Bramble Runner ×2 · tier 1")
	assert_string_contains(words, "Hedge Layer · tier 2")
	var more: Dictionary = state.duplicate(true)
	more["counters"] = [{"id": "heap", "value": 4, "entries": [runner, hedge, runner, hedge]}]
	_screen.show_state(more)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	var popped: Control = _find("Chip_0")
	assert_gt(popped.scale.x, 1.0, "the changed number pops")


func test_counters_by_id_and_slot_keywords() -> void:
	var state: Dictionary = _display_state()
	state["counters"] = [{"id": "heap", "value": 2}]
	var slots: Array = state["slots"]
	slots[2] = {"keywords": [{"id": "taunt"}]}
	_make(state)
	assert_eq(_texts(_find("Chip_0")), ["Heap", "2"] as Array[String])
	assert_eq(_texts(_find("SlotKeyword_2")), ["Taunt"] as Array[String])
