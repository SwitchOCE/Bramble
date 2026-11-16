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
