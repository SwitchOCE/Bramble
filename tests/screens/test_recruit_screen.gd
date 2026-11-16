extends GutTest
## The recruit screen draws a view state and reports input as signals, with no rules of its own.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")

var _screen: RecruitScreen


func _make(state: Dictionary) -> RecruitScreen:
	_screen = SCREEN.instantiate()
	_screen.state = state
	add_child_autofree(_screen)
	_screen.show_state(state)
	return _screen


func _mockup() -> Dictionary:
	return RecruitScreen.load_state("res://tests/screens/fixtures/recruit_mockup.json")


func _stage() -> Control:
	return _screen.get_node("Stage") as Control


func _count(prefix: String) -> int:
	var n: int = 0
	for child: Node in _stage().get_children():
		if String(child.name).begins_with(prefix):
			n += 1
	return n


func _unit(id: String) -> Dictionary:
	return {"id": id, "tier": 1, "art": "mouse-1", "attack": 1, "health": 2, "name": "Mouse"}


func test_builds_the_mockup_state() -> void:
	_make(_mockup())
	assert_eq(_count("Card_s"), 7, "5 shop units and 2 spells")
	assert_eq(_count("Card_b"), 6, "6 board units")
	assert_eq(_count("Slot_"), 1, "one empty slot, B2")
	assert_eq(_count("Card_h"), 6, "6 cards in hand")
	assert_true(_stage().get_node("Slot_5") is GlassBox, "the empty slot is slot 5 (B2)")
	var count: GlassText = _stage().get_node("HandCount")
	assert_eq(count.words, "Hand 6/7", "the hand limit is 7, not the mock-up's 10")


func test_places_follow_the_mockups_geometry() -> void:
	_make(_mockup())
	var g: Dictionary = GlassPieces.recruit_geom()
	var shop: Control = _stage().get_node("Card_s0")
	var shop_at: Vector2 = Vector2(
		GlassPieces.as_float(g["shopL"]), GlassPieces.as_float(g["shopTop"])
	)
	assert_eq(shop.position, shop_at, "the shop starts at geom()'s shopL")
	var front: Control = _stage().get_node("Card_b0")
	assert_almost_eq(front.position.y, GlassPieces.as_float(g["boardTop"]), 0.001)
	var second: Control = _stage().get_node("Card_b1")
	var back: Control = _stage().get_node("Card_b4")
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
	var first: Control = _stage().get_node("Card_h0")
	var middle: Control = _stage().get_node("Card_h3")
	var last: Control = _stage().get_node("Card_h6")
	assert_almost_eq(middle.rotation_degrees, 0.0, 0.001, "the middle card stands straight")
	assert_almost_eq(first.rotation_degrees, -last.rotation_degrees, 0.001, "the fan is symmetric")
	assert_almost_eq(
		first.position.x + last.position.x, 2.0 * middle.position.x, 0.01, "centred on the middle"
	)
	var count: GlassText = _stage().get_node("HandCount")
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
	_screen.show_state(_mockup())
	assert_not_null(_stage().get_node_or_null("Leaderboard"))


# ---- input: the screen emits; it changes nothing itself ----


func _press(at: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at + _stage().position
	_screen._gui_input(event)


func _move(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at + _stage().position
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
	var card: Control = _stage().get_node("Card_s0")
	var half: Vector2 = card.size / 2.0
	match kind:
		"shop":
			return _screen.shop_xy(i) + half
		"spell":
			var spell: Control = _stage().get_node("Card_s5")
			return _screen.spell_xy(i) + spell.size / 2.0
		_:
			return _screen.slot_xy(i) + half


func test_clicking_a_shop_card_asks_to_buy_it() -> void:
	_make(_mockup())
	watch_signals(_screen)
	_click(_centre(4, "shop"))
	assert_signal_emitted_with_parameters(_screen, "buy_requested", [4, false])
	_click(_centre(1, "spell"))
	assert_signal_emitted_with_parameters(_screen, "buy_requested", [1, true])


func test_dragging_a_shop_card_down_buys_it() -> void:
	_make(_mockup())
	watch_signals(_screen)
	_drag(_centre(2, "shop"), Vector2(960, 1000))
	assert_signal_emitted_with_parameters(_screen, "buy_requested", [2, false])


func test_dragging_from_hand_to_a_slot_plays_it() -> void:
	_make(_mockup())
	watch_signals(_screen)
	var card: Control = _stage().get_node("Card_h2")
	var place: Vector3 = _screen.hand_place(2, 6)
	var grip: Vector2 = Vector2(place.x, place.y) + Vector2(card.size.x / 2.0, card.size.y * 0.8)
	_drag(grip, _centre(5, "slot"))
	assert_signal_emitted_with_parameters(_screen, "play_requested", [2, 5])


func test_dragging_on_the_board_moves_and_up_into_the_shop_sells() -> void:
	_make(_mockup())
	watch_signals(_screen)
	_drag(_centre(0, "board"), _centre(3, "board"))
	assert_signal_emitted_with_parameters(_screen, "move_requested", [0, 3])
	_drag(_centre(1, "board"), Vector2(960, 150))
	assert_signal_emitted_with_parameters(_screen, "sell_requested", [1])


func test_buttons_and_end_turn() -> void:
	_make(_mockup())
	watch_signals(_screen)
	var tier: Control = _stage().get_node("Button_tier")
	var refresh: Control = _stage().get_node("Button_refresh")
	var freeze: Control = _stage().get_node("Button_freeze")
	var end: Control = _stage().get_node("EndTurn")
	for node: Control in [tier, refresh, freeze, end]:
		_click(node.position + node.size / 2.0)
	assert_signal_emitted(_screen, "tier_up_requested")
	assert_signal_emitted(_screen, "refresh_requested")
	assert_signal_emitted(_screen, "freeze_requested")
	assert_signal_emitted(_screen, "end_turn_requested")


func test_a_drop_nowhere_emits_nothing_and_changes_nothing() -> void:
	var state: Dictionary = _mockup()
	_make(state)
	watch_signals(_screen)
	_drag(_centre(0, "board"), Vector2(1800, 700))
	assert_signal_not_emitted(_screen, "move_requested")
	assert_signal_not_emitted(_screen, "sell_requested")
	assert_eq(_screen.state, state, "the screen keeps the state it was given")


func test_hover_shows_the_cards_name_and_rules() -> void:
	_make(_mockup())
	_move(_centre(0, "board"))
	var tip: Control = _stage().get_node("Tip")
	assert_true(tip.visible)
	var words: Array[String] = []
	for node: Node in tip.find_children("*", "GlassText", true, false):
		words.append((node as GlassText).words)
	assert_has(words, "Stag")
	assert_has(words, "TIER 6 · UNIT")
