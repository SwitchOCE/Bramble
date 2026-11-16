extends GutTest
## Picking cards up, carrying them and letting them go on the recruit screen, against the real
## rules core through the game flow's converter, with the card motion running (no settle()): the
## slots stay the board's while a card is carried, a card let go over a place it may go goes
## there at once and stays, a refused or empty drop goes home, and awkward input does not break it.
## Board: Brock Cub (0), Hedge Knight (1, on a +2/+2 slot), Sentry (2), Lance Corporal (4, an
## Order). Hand: Needle Page (a unit with no target). Shop: the seed's.

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")
const BOARD: Dictionary = {0: "brock-cub", 1: "hedge-knight", 2: "sentry", 4: "lance-corporal"}
## A let-go card is at its place within this long (a refused drop: the keeper's HOME_TIME, 0.2 s,
## then its bob, 0.21 s).
const SETTLE_TIME: float = 0.6

var _content: GameContent
var _screen: RecruitScreen
var _flow: GameFlow
var _sent: Array[Dictionary] = []
var _refused: Array[String] = []


func before_all() -> void:
	_content = GameContent.load_default()


func before_each() -> void:
	_flow = GameFlow.create(_content, 7)
	_flow.start_round()
	var me: PlayerState = _flow.human()
	me.gold = 30
	for slot: Variant in BOARD:
		CoreKit.put(_flow.session, me, str(BOARD[slot]), CoreUtil.to_int(slot))
	me.hand.append(CoreKit.unit(_flow.session, "needle-page"))
	me.slots[1].attack = 2
	me.slots[1].health = 2
	_flow.session.recruit.refresh_auras(me)
	_sent.clear()
	_refused.clear()
	_screen = SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(_flow)
	add_child_autofree(_screen)
	_screen.action_requested.connect(_on_action)


## As the game controller does: the action to the core, then the new state from the handler.
func _on_action(action: Dictionary) -> void:
	_sent.append(action)
	var first: int = _flow.session.events.size()
	var refused: String = _flow.act(action)
	if refused != "":
		_refused.append(refused)
	var events: Array = _flow.session.events.slice(first)
	_screen.show_state(ViewAdapter.recruit_state(_flow, refused, events))


func _frame_at() -> Vector2:
	return (_screen.get_node("Frame") as Control).position


func _press(at: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at + _frame_at()
	_screen._gui_input(event)


func _move(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at + _frame_at()
	_screen._gui_input(event)


## Press, carry in a few steps, and stop over `to` with the button still held.
func _carry(from: Vector2, to: Vector2) -> void:
	_press(from, true)
	for k: int in range(1, 5):
		_move(from.lerp(to, k / 4.0))


func _drag(from: Vector2, to: Vector2) -> void:
	_carry(from, to)
	_press(to, false)


func _wait(frames: int) -> void:
	for i: int in frames:
		await get_tree().process_frame


## Game time for a let-go card to land (a frame's delta varies headless, so not frames).
func _settle() -> void:
	await get_tree().create_timer(SETTLE_TIME).timeout


## A card node at a stage point (its top left), to a fraction of a pixel.
func _at(node: Control, place: Vector2, why: String = "") -> void:
	assert_almost_eq(node.position, place, Vector2(0.5, 0.5), why)


func _box() -> Vector2:
	return _screen.card_box()


func _slot_middle(i: int) -> Vector2:
	return _screen.slot_xy(i) + _box() / 2.0


func _shop_middle(i: int) -> Vector2:
	return _screen.shop_xy(i) + _box() / 2.0


func _hand_grip(i: int) -> Vector2:
	var place: Vector3 = _screen.hand_place(i, _screen.targets_of("hand").size())
	return Vector2(place.x, place.y) + Vector2(_box().x / 2.0, 40.0)


func _slot_node(i: int) -> Control:
	return _screen.find_child("Slot_%d" % i, true, false)


func _tip_shown() -> bool:
	var tip: Control = _screen.find_child("Tip", true, false)
	return tip != null and tip.visible


func _board_node(i: int) -> Control:
	return _screen.node_for("board", i)


# ---- a slot belongs to the board ----


func test_every_slot_is_drawn_whether_a_unit_stands_on_it_or_not() -> void:
	for i: int in GlassScreen.BOARD_SLOTS:
		var slot: Control = _slot_node(i)
		assert_not_null(slot, "slot %d drawn" % i)
		assert_true(slot.is_visible_in_tree(), "slot %d shows" % i)
		assert_true(_screen.get_node("Frame/Stage/Back").is_ancestor_of(slot), "under the cards")


func test_a_carried_unit_leaves_its_slot_drawn_and_empty() -> void:
	var knight: Control = _board_node(1)
	_carry(_slot_middle(1), _slot_middle(1) + Vector2(300, 200))
	var slot: Control = _slot_node(1)
	assert_not_null(slot, "the slot is still there")
	assert_true(slot.is_visible_in_tree())
	assert_eq(slot.position, _screen.slot_xy(1), "in its own place")
	assert_false(knight.is_ancestor_of(slot), "nothing of the slot rides on the card")
	assert_ne(knight.position, _screen.slot_xy(1), "the card is carried")


func test_a_slots_bonus_stays_with_the_slot_not_the_unit() -> void:
	var knight: Control = _board_node(1)
	assert_null(knight.find_child("SlotBuff*", true, false), "no slot bonus on the card")
	var pill: Control = _screen.find_child("SlotBuff_1", true, false)
	assert_not_null(pill, "the slot's bonus under its unit")
	_drag(_slot_middle(1), _slot_middle(3))
	await _settle()
	assert_eq(_sent, [{"type": "move", "from": 1, "to": 3}] as Array[Dictionary])
	assert_null(_screen.find_child("SlotBuff_3", true, false), "slot 3 has no bonus")
	var ring: Control = _slot_node(1)
	assert_not_null(ring, "slot 1 keeps its bonus, empty now")


func test_nothing_on_the_board_jumps_while_a_card_is_carried() -> void:
	var before: Dictionary = {}
	for i: int in [0, 2, 4]:
		before[i] = _board_node(i).position
	_carry(_slot_middle(1), _slot_middle(3))
	await _wait(5)
	for i: int in [0, 2, 4]:
		var was: Vector2 = before[i]
		assert_eq(_board_node(i).position, was, "unit %d stays put" % i)


func test_no_hover_detail_while_a_card_is_held() -> void:
	_move(_shop_middle(0))
	await _wait(2)
	_press(_shop_middle(0), true)
	assert_false(_tip_shown(), "the press hides the hover")
	for k: int in range(1, 5):
		_move(_shop_middle(0).lerp(_slot_middle(4), k / 4.0))
		await _wait(1)
		assert_false(_tip_shown(), "none while carried")


# ---- a card let go locks onto its place ----
# A card whose look changes on the way (its numbers, by its new slot's bonus) is drawn anew where
# the old one was, so these find the card by its place in the new state, not by its old node.


func test_a_shop_unit_let_go_on_an_empty_slot_is_bought_onto_that_slot() -> void:
	var bought: Dictionary = _screen.targets_of("shop")[0]["card"]
	var grip: Vector2 = _box() / 2.0
	var release: Vector2 = _slot_middle(3) + Vector2(25, -20)
	_drag(_shop_middle(0), release)
	assert_eq(str(_sent[0]["type"]), "buy")
	assert_eq(str(_sent[1]["type"]), "play")
	assert_eq(CoreUtil.to_int(_sent[1]["slot"]), 3)
	assert_eq(_refused, [] as Array[String])
	assert_eq(String(_flow.human().board[3].def.id), str(bought["id"]), "bought onto slot 3")
	var card: Control = _board_node(3)
	_at(card, release - grip, "it starts where it was let go, not from the shop or the hand")
	assert_gt(card.z_index, 0, "drawn above the rest while it lands")
	await _settle()
	_at(card, _screen.slot_xy(3), "locked onto the slot")
	assert_eq(card.z_index, 0, "among the others once landed")


func test_a_shop_unit_let_go_on_a_unit_is_bought_into_the_hand() -> void:
	var hand_before: int = _flow.human().hand.size()
	_drag(_shop_middle(0), _slot_middle(0))
	assert_eq(_sent.size(), 1)
	assert_eq(str(_sent[0]["type"]), "buy")
	assert_eq(_flow.human().hand.size(), hand_before + 1)


func test_a_moved_unit_is_at_its_new_slot_within_the_settle() -> void:
	var release: Vector2 = _slot_middle(6) + Vector2(20, -15)
	_drag(_slot_middle(1), release)
	var knight: Control = _board_node(6)
	_at(knight, release - _box() / 2.0, "from where it was let go")
	await _settle()
	_at(knight, _screen.slot_xy(6))


func test_a_swap_moves_both_units_at_once() -> void:
	_drag(_slot_middle(0), _slot_middle(2))
	var cub: Control = _board_node(2)
	var sentry: Control = _board_node(0)
	assert_ne(sentry.position, _screen.slot_xy(0), "the other unit moves too, not jumps")
	await _settle()
	_at(cub, _screen.slot_xy(2))
	_at(sentry, _screen.slot_xy(0))


func test_a_hand_unit_let_go_on_an_empty_slot_is_played_there() -> void:
	var release: Vector2 = _slot_middle(3)
	var grip: Vector2 = (
		_hand_grip(0) - Vector2(_screen.hand_place(0, 1).x, _screen.hand_place(0, 1).y)
	)
	_drag(_hand_grip(0), release)
	assert_eq(str(_sent[0]["type"]), "play")
	var card: Control = _board_node(3)
	_at(card, release - grip, "from where it was let go")
	await _settle()
	_at(card, _screen.slot_xy(3))


func test_a_refused_drop_goes_home() -> void:
	var card: Control = _screen.node_for("hand", 0)
	var home: Vector3 = _screen.hand_place(0, 1)
	_drag(_hand_grip(0), _slot_middle(0))
	assert_eq(_refused.size(), 1, "the core refuses a play onto a unit")
	await _settle()
	assert_eq(_screen.node_for("hand", 0), card)
	_at(card, Vector2(home.x, home.y), "back in the hand")


func test_a_drop_on_nothing_goes_home() -> void:
	var card: Control = _board_node(2)
	_drag(_slot_middle(2), Vector2(300, 620))
	assert_eq(_sent, [] as Array[Dictionary])
	await _settle()
	_at(card, _screen.slot_xy(2))
	assert_eq(card.z_index, 0)


# ---- awkward input ----


func test_a_card_pressed_while_still_moving_is_carried_from_where_it_is() -> void:
	var release: Vector2 = _slot_middle(6) + Vector2(-60, -40)
	_drag(_slot_middle(0), release)
	var cub: Control = _board_node(6)
	var midway: Vector2 = cub.position
	var grip: Vector2 = midway + _box() / 2.0
	_carry(grip, _slot_middle(3))
	_at(cub, _slot_middle(3) - _box() / 2.0, "held where it was gripped")
	_press(_slot_middle(3), false)
	await _settle()
	_at(_board_node(3), _screen.slot_xy(3))


func test_two_quick_drags_both_land() -> void:
	_drag(_slot_middle(0), _slot_middle(3))
	_drag(_slot_middle(2), _slot_middle(5))
	await _settle()
	_at(_board_node(3), _screen.slot_xy(3))
	_at(_board_node(5), _screen.slot_xy(5))
	assert_eq(_board_node(3).z_index, 0)
	assert_eq(_board_node(5).z_index, 0)


func test_losing_the_window_mid_drag_puts_the_card_back() -> void:
	var card: Control = _board_node(2)
	_carry(_slot_middle(2), _slot_middle(3))
	_screen.notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await _settle()
	assert_eq(_sent, [] as Array[Dictionary], "nothing sent")
	_at(card, _screen.slot_xy(2), "back in its slot")
	_move(_slot_middle(5))
	_at(card, _screen.slot_xy(2), "no longer follows the pointer")


func test_a_drag_begun_on_an_ability_button_carries_its_card() -> void:
	var corporal: Control = _board_node(4)
	var button: Control = null
	for target: Dictionary in _screen.targets_of("ability"):
		button = target["node"]
	assert_not_null(button, "the Lance Corporal's Order button")
	var grip: Vector2 = corporal.position + button.position + button.size / 2.0
	_drag(grip, _slot_middle(6))
	assert_eq(_sent, [{"type": "move", "from": 4, "to": 6}] as Array[Dictionary])
	await _settle()
	_at(_board_node(6), _screen.slot_xy(6))


func test_a_hovered_hand_card_is_carried_from_where_it_stands() -> void:
	var card: Control = _screen.node_for("hand", 0)
	_move(_hand_grip(0))
	await _wait(2)
	var standing: Vector2 = card.position
	assert_ne(
		standing, Vector2(_screen.hand_place(0, 1).x, _screen.hand_place(0, 1).y), "it stands up"
	)
	var grip: Vector2 = standing + Vector2(_box().x / 2.0, 60.0)
	_press(grip, true)
	_at(card, standing, "the press leaves it standing")
	_move(grip + Vector2(0, -100))
	_move(grip + Vector2(0, -200))
	_at(card, standing + Vector2(0, -200), "carried from where it stood, gripped where pressed")
	_press(grip + Vector2(0, -200), false)


func test_a_sold_unit_sets_off_at_once() -> void:
	var sentry: Control = _board_node(2)
	var release: Vector2 = _shop_middle(2)
	_drag(_slot_middle(2), release)
	assert_eq(str(_sent[0]["type"]), "sell")
	var start: Vector2 = sentry.position
	await _wait(3)
	if is_instance_valid(sentry):
		assert_gt(sentry.position.distance_to(start), 20.0, "it is already on its way")
	await _settle()
	assert_false(is_instance_valid(sentry) and sentry.is_inside_tree(), "and gone")


# ---- the feel (Galaxy's, in the feel reference's baseline-notes.md) ----


func test_a_carried_card_lifts_glows_and_tilts_toward_its_travel() -> void:
	var card: Control = _board_node(2)
	var over: Vector2 = _slot_middle(2) + Vector2(0, -150)
	_carry(_slot_middle(2), over)
	await get_tree().create_timer(0.2).timeout
	assert_gt(card.scale.x, 1.15, "lifted and grown")
	assert_true((card as GlassCard).is_held(), "with the held light under it")
	for k: int in range(1, 9):
		_move(over + Vector2(25 * k, 0))
		await _wait(1)
	assert_gt(card.rotation_degrees, 3.0, "tilted toward its travel (right)")
	await get_tree().create_timer(0.4).timeout
	assert_almost_eq(card.rotation_degrees, 0.0, 1.0, "straight again once the pointer stops")
	_press(_slot_middle(2), false)
	await _settle()
	_at(card, _screen.slot_xy(2), "put down in its own slot")
	assert_eq(card.scale, Vector2.ONE, "its own size again")
	assert_false((card as GlassCard).is_held(), "the held light gone")


func test_a_unit_lifted_off_a_bonus_slot_shows_its_own_numbers() -> void:
	var card: GlassCard = _board_node(1) as GlassCard
	var shown: Vector2i = Vector2i(card.attack, card.health)
	_carry(_slot_middle(1), _slot_middle(1) + Vector2(0, -150))
	assert_eq(
		Vector2i(card.attack, card.health), shown - Vector2i(2, 2), "the slot keeps its +2/+2"
	)
	_press(_slot_middle(1), false)
	await _settle()
	var back: GlassCard = _board_node(1) as GlassCard
	assert_eq(Vector2i(back.attack, back.health), shown, "counted back up as it lands")


func test_while_a_unit_is_carried_the_slots_it_can_go_to_are_lit() -> void:
	_carry(_slot_middle(2), _slot_middle(2) + Vector2(0, -150))
	var lit: Array[int] = []
	for i: int in 7:
		if _slot_node(i).find_child("Lit", false, false) != null:
			lit.append(i)
	assert_eq(lit, [2, 3, 5, 6] as Array[int], "the empty slots and the one it left")
	_press(_slot_middle(2), false)
	await _settle()
	for i: int in 7:
		assert_null(_slot_node(i).find_child("Lit", false, false), "none lit once it is down")
