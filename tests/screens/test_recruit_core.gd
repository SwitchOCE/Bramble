extends GutTest
## The recruit screen against the real rules core (through the stand-in conversion): what it asks
## for is the core's own legal action, and the core takes it.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreView := preload("res://tests/screens/core_view.gd")

var _screen: RecruitScreen
var _game: GameSession
var _sent: Array[Dictionary] = []


func before_each() -> void:
	_game = CoreView.playable()
	_sent.clear()
	_screen = SCREEN.instantiate()
	_screen.state = CoreView.recruit_state(_game, 0)
	add_child_autofree(_screen)
	_screen.action_requested.connect(_on_action)


## The stand-in flow: the action to the core unchanged, then the new state.
func _on_action(action: Dictionary) -> void:
	_sent.append(action)
	var refused: String = _game.act(0, action)
	assert_eq(refused, "", "the core takes %s" % JSON.stringify(action))
	_screen.show_state(CoreView.recruit_state(_game, 0, refused))


func _gui(event: InputEvent) -> void:
	_screen._gui_input(event)


func _press(at: Vector2, down: bool, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = down
	event.position = at + (_screen.get_node("Frame") as Control).position
	_gui(event)


func _move(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at + (_screen.get_node("Frame") as Control).position
	_gui(event)


func _drag(from: Vector2, to: Vector2) -> void:
	_press(from, true)
	_move(from.lerp(to, 0.5))
	_move(to)
	_press(to, false)


func _click(at: Vector2) -> void:
	_press(at, true)
	_press(at, false)


func _card_middle(i: int) -> Vector2:
	return _screen.shop_xy(i) + GlassCard.card_size(250.0) / 2.0


func _legal() -> Array:
	return _game.view_for(0)["legal_actions"]


func test_a_drag_out_of_the_shop_sends_the_cores_buy() -> void:
	var hand_before: int = _game.player(0).hand.size()
	_drag(_card_middle(0), Vector2(960, 1000))
	assert_eq(_sent.size(), 1)
	assert_eq(_sent[0], {"type": "buy", "spell": false, "index": 0})
	assert_eq(_game.player(0).hand.size(), hand_before + 1)


func test_buttons_send_the_cores_actions() -> void:
	var refresh: Control = _screen.find_child("Button_refresh", true, false)
	var frame: Control = _screen.get_node("Frame")
	_click(refresh.global_position - frame.global_position + refresh.size / 2)
	assert_eq(_sent, [{"type": "refresh"}] as Array[Dictionary])


func test_a_move_on_the_board_is_the_cores_move() -> void:
	_drag(_screen.slot_xy(2) + Vector2(70, 125), _screen.slot_xy(3) + Vector2(70, 125))
	assert_eq(_sent, [{"type": "move", "from": 2, "to": 3}] as Array[Dictionary])
	assert_eq(_game.player(0).board[3].def.id, &"t3_twin")


func test_an_action_the_state_does_not_list_is_still_sent() -> void:
	_screen.action_requested.disconnect(_on_action)
	watch_signals(_screen)
	var state: Dictionary = _screen.state.duplicate()
	state["legal_actions"] = []
	_screen.show_state(state)
	_drag(_card_middle(0), Vector2(960, 1000))
	assert_signal_emitted_with_parameters(
		_screen, "action_requested", [{"type": "buy", "spell": false, "index": 0}]
	)


func test_matching_reads_numbers_from_json() -> void:
	var state: Dictionary = {"legal_actions": [{"type": "move", "from": 1.0, "to": 2.0}]}
	var found: Array[Dictionary] = RecruitActions.matching(state, {"type": "move", "from": 1})
	assert_eq(found.size(), 1)
	assert_true(RecruitActions.matching(state, {"type": "move", "from": 2}).is_empty())
	assert_eq(
		_legal().filter(func(a: Dictionary) -> bool: return a["type"] == "end_turn").size(), 1
	)


# ---- spells, targets, abilities, Discover (hand: Tutor, Sharpen, Seek, Gift, Triple Reward) ----


func _hand_grip(i: int) -> Vector2:
	var node: Control = _screen.node_for("hand", i)
	var place: Vector3 = _screen.hand_place(i, _screen.targets_of("hand").size())
	return Vector2(place.x, place.y) + Vector2(node.size.x / 2.0, 40.0)


func _board_middle(slot: int) -> Vector2:
	return _screen.slot_xy(slot) + GlassCard.card_size(250.0) / 2.0


func _uid_at(slot: int) -> int:
	return _game.player(0).board[slot].uid


func _key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.pressed = true
	_screen._unhandled_key_input(event)


func _lit_count() -> int:
	return _screen.find_children("Lit", "", true, false).size()


func _press_node(node: Control) -> void:
	var frame: Control = _screen.get_node("Frame")
	_click(node.global_position - frame.global_position + node.size / 2.0)


func test_spells_in_hand_are_drawn_as_spells() -> void:
	for i: int in [1, 2, 3, 4]:
		assert_true(_screen.node_for("hand", i) is GlassSpell, "hand card %d is a spell" % i)
	assert_true(_screen.node_for("hand", 0) is GlassCard)


func test_a_spell_with_no_target_casts_on_the_table_and_opens_a_discover() -> void:
	_drag(_hand_grip(2), Vector2(1400, 600))
	assert_eq(_sent[0], {"type": "play", "hand": 2, "slot": -1, "target": -1})
	assert_true(_screen.state.has("discover"), "Seek opened a Discover")
	assert_eq(_screen.targets_of("discover").size(), 3)
	_drag(_board_middle(0), _board_middle(3))
	assert_eq(_sent.size(), 1, "nothing but a pick while choosing")
	var option: Control = _screen.node_for("discover", 1)
	_click(option.position + option.size / 2.0)
	assert_eq(_sent[1], {"type": "pick", "index": 1})
	assert_false(_screen.state.has("discover"))
	assert_eq(_game.player(0).hand.size(), 5, "Seek left, the pick came in")


func test_a_targeted_spell_dropped_on_a_unit_casts_there() -> void:
	var twin: int = _uid_at(2)
	var before: int = _game.player(0).board[2].attack()
	_drag(_hand_grip(1), _board_middle(2))
	assert_eq(_sent[0], {"type": "play", "hand": 1, "slot": -1, "target": twin})
	assert_eq(_game.player(0).board[2].attack(), before + 2)


func test_a_targeted_spell_on_the_table_asks_for_a_target_and_escape_cancels() -> void:
	_drag(_hand_grip(1), Vector2(1400, 600))
	assert_true(_screen.is_aiming())
	assert_eq(_sent.size(), 0)
	assert_eq(_lit_count(), 4, "the four friendly units are lit")
	_key(KEY_ESCAPE)
	assert_false(_screen.is_aiming())
	assert_eq(_lit_count(), 0)
	_screen.settle()
	_drag(_hand_grip(1), Vector2(1400, 600))
	assert_true(_screen.is_aiming(), "aiming again")
	_press(Vector2(1400, 600), true, MOUSE_BUTTON_RIGHT)
	assert_false(_screen.is_aiming(), "a right click cancels too")
	_screen.settle()
	_drag(_hand_grip(1), Vector2(1400, 600))
	assert_true(_screen.is_aiming(), "and again")
	_click(Vector2(1300, 600))
	assert_true(_screen.is_aiming(), "a click on nothing keeps waiting")
	var guard: int = _uid_at(4)
	_click(_board_middle(4))
	assert_eq(
		_sent, [{"type": "play", "hand": 1, "slot": -1, "target": guard}] as Array[Dictionary]
	)


func test_a_unit_that_aims_waits_in_its_slot_for_a_target() -> void:
	_drag(_hand_grip(0), _board_middle(3))
	assert_true(_screen.is_aiming())
	_screen.settle()
	assert_eq(_screen.node_for("hand", 0).position, _screen.slot_xy(3), "held in the slot")
	var officer: int = _uid_at(0)
	_click(_board_middle(0))
	assert_eq(_sent[0], {"type": "play", "hand": 0, "slot": 3, "target": officer})
	assert_eq(_game.player(0).board[3].def.id, &"st_tutor")


func test_a_slot_spell_lights_slots_and_takes_an_empty_one() -> void:
	_drag(_hand_grip(3), Vector2(1450, 300))
	assert_true(_screen.is_aiming())
	assert_eq(_lit_count(), 7, "every slot")
	_click(_board_middle(5))
	assert_eq(_sent[0], {"type": "play", "hand": 3, "slot": -1, "target": 5})


func test_the_triple_reward_casts_and_discovers() -> void:
	_drag(_hand_grip(4), Vector2(1400, 600))
	assert_eq(_sent[0], {"type": "play", "hand": 4, "slot": -1, "target": -1})
	assert_true(_screen.state.has("discover"))


func test_ability_buttons_show_when_legal_and_aim() -> void:
	var abilities: Array[Dictionary] = _screen.targets_of("ability")
	assert_eq(abilities.size(), 2, "Order on the officer, Bury on the burier")
	var order: Control = abilities[0]["node"]
	var words: GlassText = order.get_child(0)
	assert_eq(words.words, "Order", "named by the display table")
	_press_node(order)
	assert_true(_screen.is_aiming())
	_click(_board_middle(6))
	assert_eq(str(_sent[0]["type"]), "ability")
	assert_eq(GlassPieces.as_int(_sent[0]["target"]), 6)
	var left: Array[Dictionary] = _screen.targets_of("ability")
	var bury: Control = left[left.size() - 1]["node"]
	_press_node(bury)
	_click(_card_middle(0))
	assert_eq(str(_sent[1]["mechanic"]), "bury")
	assert_eq(GlassPieces.as_int(_sent[1]["target"]), 0)


func test_no_ability_button_when_the_state_does_not_list_it() -> void:
	var state: Dictionary = _screen.state.duplicate()
	state["legal_actions"] = []
	_screen.show_state(state)
	assert_eq(_screen.targets_of("ability").size(), 0)
