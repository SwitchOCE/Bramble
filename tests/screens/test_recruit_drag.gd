extends GutTest
## Picking cards up, carrying them and letting them go on the recruit screen, against the real
## rules core through the game flow's converter, with the card motion running (no settle()): the
## slots stay the board's while a card is carried, a card let go over a place it may go goes
## there at once and stays, a refused or empty drop goes home, and awkward input does not break it.
## Board: Brock Cub (0), Hedge Knight (1, on a +2/+2 slot), Sentry (2), Lance Corporal (4, an
## Order). Hand: Needle Page (a unit with no target). Shop: the seed's.

const SlotChecks := preload("res://tests/screens/slot_assertions.gd")

const SCREEN: PackedScene = preload("res://src/screens/recruit/recruit_screen.tscn")
const CoreKit := preload("res://tests/core/core_kit.gd")
const BOARD: Dictionary = {0: "brock-cub", 1: "hedge-knight", 2: "sentry", 4: "lance-corporal"}
## A let-go card is at its place within this long (a refused drop: the keeper's FLIGHT_TIME,
## 0.25 s at most, then its HOP_TIME, 0.2 s).
const SETTLE_TIME: float = 0.6

var _content: GameContent
var _screen: RecruitScreen
var _flow: GameFlow
var _sent: Array[Dictionary] = []
var _refused: Array[String] = []


func before_all() -> void:
	_content = GameContent.load_default()


## The tests' own settings file (tools/checks/gut_settings_hook.gd): each test starts and ends with
## cards dropping where the pointer is.
func after_each() -> void:
	GameSettings.set_drop_by_middle(false, false)


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
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "initial slot rows")
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
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")


func _frame_at() -> Vector2:
	return (_screen.get_node("Frame") as Control).position


func _press(at: Vector2, down: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at + _frame_at()
	_screen._gui_input(event)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after press/release")


func _move(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at + _frame_at()
	_screen._gui_input(event)
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows while carrying")


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
		assert_true(_screen.get_node("Frame/Stage/Slots").is_ancestor_of(slot), "under the cards")


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
	assert_true(_slot_says(1).has("+2/+2"), "slot 1 keeps its bonus, written on it, empty now")


func test_a_carried_units_slot_bonus_shows_on_its_slot_not_its_pill() -> void:
	var pill: Control = _screen.find_child("SlotBuff_1", true, false)
	_carry(_slot_middle(1), _slot_middle(1) + Vector2(0, -150))
	assert_false(pill.visible, "the pill under the unit goes with the unit's lift")
	assert_true(_slot_says(1).has("+2/+2"), "the empty slot shows its bonus")


func test_a_unit_landing_on_a_bonus_slot_is_always_under_its_pill() -> void:
	_drag(_slot_middle(0), _slot_middle(1) + Vector2(30, -40))
	var cub: Control = _board_node(1)
	var pill: Control = _screen.find_child("SlotBuff_1", true, false)
	assert_not_null(pill, "slot 1's pill, under the cub that swapped in")
	assert_gt(pill.z_index, cub.z_index, "the pill over the card from the start")
	await _wait(4)
	assert_gt(pill.z_index, cub.z_index, "and while it lands")
	await _settle()
	assert_gt(pill.z_index, cub.z_index, "and once it is down")


func test_a_card_let_go_is_drawn_as_when_still_from_the_start() -> void:
	var card: Control = _screen.node_for("hand", 0)
	_drag(_hand_grip(0), _slot_middle(0))
	assert_eq(card.z_index, 0, "under the vignette at once, as when still")
	await _settle()
	assert_eq(card.z_index, 0)
	assert_eq(card.self_modulate, Color.WHITE, "its own look")


func _slot_says(i: int) -> PackedStringArray:
	var out: PackedStringArray = []
	for node: Node in _slot_node(i).find_children("*", "GlassText", true, false):
		out.append((node as GlassText).words)
	return out


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
	assert_true(_tip_shown(), "a press may be a click: the hover stays")
	_move(_shop_middle(0).lerp(_slot_middle(4), 0.25))
	await get_tree().create_timer(GlassScreen.TIP_FADE_TIME + 0.05).timeout
	assert_false(_tip_shown(), "a drag fades it")
	for k: int in range(2, 5):
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
	assert_eq(card.z_index, 0, "put down at once, under the vignette as when still")
	assert_eq(card.get_index(), card.get_parent().get_child_count() - 1, "over the cards it passes")
	await _settle()
	_at(card, _screen.slot_xy(3), "locked onto the slot")
	assert_eq(card.z_index, 0, "the same once landed")


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
	assert_lt(card.rotation_degrees, -3.0, "moving right, its top trails the hand (leans left)")
	assert_lt(card.scale.x, card.scale.y, "narrowed at speed")
	await get_tree().create_timer(0.4).timeout
	assert_almost_eq(card.rotation_degrees, 0.0, 1.0, "straight again once the pointer stops")
	assert_almost_eq(card.scale.x, card.scale.y, 0.01, "its full width again")
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


# ---- buying onto a slot: only the very card bought is played ----


func _reshop(ids: Array[String]) -> void:
	CoreKit.set_shop(_flow.session, _flow.human(), ids)
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	assert_eq(SlotChecks.check(_screen), PackedStringArray(), "slot rows after state")
	_screen.settle()


func _played() -> Array[Dictionary]:
	return _sent.filter(func(a: Dictionary) -> bool: return str(a["type"]) == "play")


func test_a_buy_that_triples_with_two_on_the_board_leaves_the_golden_in_the_hand() -> void:
	CoreKit.put(_flow.session, _flow.human(), "brock-cub", 5)
	_reshop(["brock-cub"] as Array[String])
	_drag(_shop_middle(0), _slot_middle(3) + Vector2(20, -30))
	assert_eq(_played(), [] as Array[Dictionary], "no play sent")
	assert_null(_flow.human().board[3], "slot 3 still empty")
	var golden: Array = _flow.human().hand.filter(func(u: Unit) -> bool: return u.golden)
	assert_eq(golden.size(), 1, "the golden waits in the hand")


func test_a_buy_that_triples_with_one_in_the_hand_leaves_the_golden_in_the_hand() -> void:
	_flow.human().hand.append(CoreKit.unit(_flow.session, "brock-cub"))
	_reshop(["brock-cub"] as Array[String])
	_drag(_shop_middle(0), _slot_middle(3) + Vector2(20, -30))
	assert_eq(_played(), [] as Array[Dictionary], "no play sent")
	assert_null(_flow.human().board[3], "slot 3 still empty")
	var golden: Array = _flow.human().hand.filter(func(u: Unit) -> bool: return u.golden)
	assert_eq(golden.size(), 1, "the golden waits in the hand")


func test_a_buy_onto_a_slot_with_a_full_hand_plays_nothing() -> void:
	var me: PlayerState = _flow.human()
	while me.hand.size() < 7:
		me.hand.append(CoreKit.unit(_flow.session, "needle-page"))
	_reshop(["sentry"] as Array[String])
	_drag(_shop_middle(0), _slot_middle(3))
	assert_eq(_played(), [] as Array[Dictionary])
	assert_null(me.board[3])


func test_a_buy_onto_a_slot_with_no_gold_plays_nothing() -> void:
	_flow.human().gold = 0
	_reshop(["sentry"] as Array[String])
	_drag(_shop_middle(0), _slot_middle(3))
	assert_eq(_refused.size(), 1, "the buy is refused")
	assert_eq(_played(), [] as Array[Dictionary])
	assert_null(_flow.human().board[3])


func test_a_bought_unit_that_takes_a_target_asks_for_one_on_its_slot() -> void:
	_reshop(["master-at-arms"] as Array[String])
	_drag(_shop_middle(0), _slot_middle(3))
	assert_eq(str(_sent[0]["type"]), "buy")
	assert_eq(_played(), [] as Array[Dictionary], "not played before a target is chosen")
	assert_true(_screen.is_aiming(), "choosing a target for it")
	_assert_recruit_prompt()


func test_a_card_pressed_still_rises_in_place_and_a_click_puts_it_back() -> void:
	var card: Control = _board_node(2)
	_press(_slot_middle(2), true)
	await get_tree().create_timer(0.2).timeout
	assert_gt(card.scale.x, 1.15, "lifted before the pointer moves")
	_press(_slot_middle(2), false)
	await _settle()
	assert_eq(_sent, [] as Array[Dictionary], "a click sends nothing")
	_at(card, _screen.slot_xy(2), "back in its slot")
	assert_eq(card.scale, Vector2.ONE)
	assert_false((card as GlassCard).is_held())


func test_a_lifted_units_number_colour_follows_its_number() -> void:
	var card: GlassCard = _board_node(1) as GlassCard
	assert_true(card.up_attack, "green with its slot's +2")
	_carry(_slot_middle(1), _slot_middle(1) + Vector2(0, -150))
	assert_eq(card.attack, card.base_attack, "its own Attack")
	assert_false(card.up_attack, "not green once the slot's +2 is off")


func test_a_card_sent_home_is_seen_on_its_way() -> void:
	var card: Control = _board_node(2)
	_drag(_slot_middle(2), Vector2(300, 620))
	await get_tree().create_timer(0.1).timeout
	var left: float = card.position.distance_to(_screen.slot_xy(2))
	assert_gt(left, 60.0, "still flying after 6 frames (15 in all)")
	await _settle()
	_at(card, _screen.slot_xy(2))


func _gold_shown() -> PackedStringArray:
	var out: PackedStringArray = []
	var button: Node = _screen.find_child("Button_gold", true, false)
	for node: Node in button.find_children("*", "GlassText", true, false):
		out.append((node as GlassText).words)
	return out


func test_a_sale_changes_the_gold_as_the_card_arrives() -> void:
	var before: int = _flow.human().gold
	_drag(_slot_middle(2), _shop_middle(2))
	assert_eq(str(_sent[0]["type"]), "sell")
	assert_true(_gold_shown().has(str(before)), "the gold waits for the card")
	await get_tree().create_timer(CardKeeper.FLY_TIME * 0.6).timeout
	assert_true(_gold_shown().has(str(before)), "still, mid-flight")
	await _screen._keeper.flown_out
	assert_true(_gold_shown().has(str(_flow.human().gold)), "the sale, on the frame it arrives")


## Gripped low and let go with the pointer just inside an empty slot's top: the card's corner is
## far from the slot (more than half its height), but it was put there, so it drops in (6 frames at
## most) rather than flies (15).
func _assert_dropped_in(card: Control, slot: int) -> void:
	assert_false(_screen._keeper.is_flying(card), "put there: not flying")
	# The drop and hop use a node Tween, advanced after node processing by the engine's
	# process delta (which can be clamped under load). Wait for its actual motion time,
	# rather than a timer that can expire before that frame's Tween step has run.
	var tween: Tween = _screen._keeper._tweens[card]
	var motion_time: float = 7.0 / 60.0
	for frame: int in 600:
		if tween.get_total_elapsed_time() >= motion_time or not tween.is_running():
			break
		await get_tree().process_frame
	assert_gte(tween.get_total_elapsed_time(), motion_time, "drop advanced within 600 frames")
	assert_almost_eq(card.position.x, _screen.slot_xy(slot).x, 0.5, "in its slot")
	assert_almost_eq(card.position.y, _screen.slot_xy(slot).y, 20.0, "in its slot (its hop begun)")


func _low_release(slot: int) -> Vector2:
	return _screen.slot_xy(slot) + Vector2(_box().x / 2.0, 30.0)


func test_a_unit_gripped_low_drops_into_the_slot_let_go_over() -> void:
	var low: Vector2 = Vector2(_box().x / 2.0, _box().y - 12.0)
	_drag(_screen.slot_xy(1) + low, _low_release(6))
	var knight: Control = _board_node(6)
	assert_gt(knight.position.distance_to(_screen.slot_xy(6)), _box().y * 0.5, "corner far off")
	await _assert_dropped_in(knight, 6)


func test_a_shop_unit_gripped_low_drops_into_the_slot_it_is_bought_onto() -> void:
	for shop: int in [1, 3]:
		var grip_y: float = 160.0 if shop == 1 else 220.0
		var grip: Vector2 = (
			_screen.shop_xy(shop) + Vector2(_box().x / 2.0, grip_y * _box().y / 250.0)
		)
		_drag(grip, _low_release(5))
		assert_eq(str(_sent[-1]["type"]), "play", "bought and played")
		var card: Control = _board_node(5)
		await _assert_dropped_in(card, 5)
		await _settle()
		_drag(_slot_middle(5), _shop_middle(2))
		await _settle()


func test_a_card_carried_up_or_down_pitches_back() -> void:
	var card: Control = _board_node(2)
	var from: Vector2 = _slot_middle(2)
	_press(from, true)
	for k: int in range(1, 9):
		_move(from + Vector2(0, -30 * k))
		await _wait(1)
	assert_lt(card.scale.y, card.scale.x * 0.95, "drawn shorter as it travels up")
	await get_tree().create_timer(0.4).timeout
	assert_almost_eq(card.scale.y, card.scale.x, 0.01, "its full height again once still")
	_press(from + Vector2(0, -240), false)


func test_no_detail_on_a_card_until_it_is_still() -> void:
	var release: Vector2 = _slot_middle(6)
	_drag(_slot_middle(1), release)
	_move(release + Vector2(4, 2))
	await _wait(1)
	assert_false(_tip_shown(), "none while it lands")
	await _settle()
	assert_true(_tip_shown(), "then its detail")


func test_the_hand_count_changes_as_a_bought_card_arrives() -> void:
	var before: int = _flow.human().hand.size()
	_drag(_shop_middle(0), _slot_middle(0))
	var label: GlassText = _screen.find_child("HandCount", true, false)
	assert_string_contains(label.words, "Hand %d/" % before, "not yet: the card is on its way")
	await _settle()
	label = _screen.find_child("HandCount", true, false)
	assert_string_contains(label.words, "Hand %d/" % (before + 1), "there now")


func test_a_double_click_on_a_unit_on_a_bonus_slot_keeps_its_numbers_right() -> void:
	var knight: GlassCard = _board_node(1) as GlassCard
	var shown: Vector2i = Vector2i(knight.attack, knight.health)
	_press(_slot_middle(1), true)
	_press(_slot_middle(1), false)
	await _wait(2)
	_press(_slot_middle(1), true)
	assert_eq(knight.attack, knight.base_attack, "its own Attack while held")
	assert_false(knight.hurt, "not hurt")
	assert_false(knight.up_attack, "not green while held")
	_press(_slot_middle(1), false)
	await _settle()
	assert_eq(Vector2i(knight.attack, knight.health), shown, "the slot's bonus again")


func test_a_press_during_the_count_up_shows_the_units_own_numbers() -> void:
	_drag(_slot_middle(1), _slot_middle(6))
	await _settle()
	var own: Vector2i = Vector2i(
		(_board_node(6) as GlassCard).attack, (_board_node(6) as GlassCard).health
	)
	_drag(_slot_middle(6), _slot_middle(1))
	await get_tree().create_timer(0.15).timeout
	var knight: GlassCard = _board_node(1) as GlassCard
	assert_ne(Vector2i(knight.attack, knight.health), own, "counting up to the slot's bonus")
	_press(_slot_middle(1), true)
	assert_eq(Vector2i(knight.attack, knight.health), own, "held: its own numbers")
	await get_tree().create_timer(0.3).timeout
	assert_eq(Vector2i(knight.attack, knight.health), own, "and no count-up while held")
	_press(_slot_middle(1), false)


func test_a_click_on_a_standing_hand_card_leaves_it_standing_with_its_detail() -> void:
	var card: Control = _screen.node_for("hand", 0)
	_move(_hand_grip(0))
	await _wait(2)
	var standing: Vector2 = card.position
	for down: float in [30.0, card.size.y - 20.0]:
		var at: Vector2 = standing + Vector2(card.size.x / 2.0, down)
		_move(at)
		await _wait(1)
		_press(at, true)
		assert_true(_tip_shown(), "its detail stays through the press")
		_press(at, false)
		assert_true(_tip_shown(), "and after it")
		await get_tree().create_timer(0.4).timeout
		assert_true(_tip_shown(), "still, a moment later")
		_at(card, standing, "still standing")


func test_a_click_on_a_shop_or_board_card_never_hides_its_detail() -> void:
	for at: Vector2 in [_shop_middle(1), _slot_middle(2)]:
		_move(at)
		await _wait(1)
		assert_true(_tip_shown(), "its detail")
		_press(at, true)
		assert_true(_tip_shown(), "kept through the press")
		await _wait(2)
		assert_true(_tip_shown(), "kept while held")
		_press(at, false)
		assert_true(_tip_shown(), "kept as it is let go")
		await _wait(1)
		assert_true(_tip_shown(), "and after")
		await _settle()


func test_a_sales_gold_lands_while_another_card_is_held() -> void:
	_drag(_slot_middle(2), _shop_middle(2))
	_press(_slot_middle(0), true)
	_move(_slot_middle(0) + Vector2(0, -60))
	await _screen._keeper.flown_out
	assert_true(_gold_shown().has(str(_flow.human().gold)), "the sale, though a card is held")
	_press(_slot_middle(0) + Vector2(0, -60), false)


# ---- where a carried card drops: the pointer, or the card's middle (GameSettings) ----


## Sentry (slot 2) gripped near its lower left, carried so the pointer is at `pointer`, and held
## still until it has lifted and straightened. Returns where its middle is drawn.
func _hold_low_left(pointer: Vector2) -> Vector2:
	_carry(_screen.slot_xy(2) + _low_left(), pointer)
	await get_tree().create_timer(0.4).timeout
	_move(pointer)
	await _wait(2)
	var held: CardCarry = _screen._input._carry
	return held.middle()


func _low_left() -> Vector2:
	return Vector2(_box().x * 0.3, _box().y * 0.85)


## Where the pointer must be for the held card's middle to be at `middle` (the grip's offset once
## lifted: grown, risen, straight).
func _pointer_for(middle: Vector2) -> Vector2:
	var off: Vector2 = (_box() / 2.0 - _low_left()) * (1.0 + CardCarry.GROW)
	off.y -= CardCarry.RISE * _box().y
	return middle - off


func _over_shop_and_board() -> Vector2:
	return _pointer_for(Vector2(_slot_middle(3).x, _screen.geom("T0") - 90.0))


func test_by_the_pointer_a_card_drops_where_the_pointer_is() -> void:
	var pointer: Vector2 = _pointer_for(_slot_middle(3))
	var middle: Vector2 = await _hold_low_left(pointer)
	assert_eq(_screen._board.slot_at(pointer), 6, "the pointer over slot 6")
	assert_eq(_screen._board.slot_at(middle), 3, "the card's middle over slot 3")
	var sentry: Control = _board_node(2)
	_press(pointer, false)
	assert_eq(_sent.size(), 1)
	assert_eq(_sent[0], {"type": "move", "from": 2, "to": 6}, "moved where the pointer is")
	await _assert_dropped_in(sentry, 6)


func test_by_the_middle_a_card_drops_where_its_middle_is() -> void:
	GameSettings.set_drop_by_middle(true, false)
	var pointer: Vector2 = _pointer_for(_slot_middle(3))
	var middle: Vector2 = await _hold_low_left(pointer)
	assert_eq(_screen._board.slot_at(pointer), 6, "the pointer over slot 6")
	assert_eq(_screen._board.slot_at(middle), 3, "the card's middle over slot 3")
	var sentry: Control = _board_node(2)
	var before: Vector2 = sentry.position
	_press(pointer, false)
	assert_eq(_sent.size(), 1)
	assert_eq(_sent[0], {"type": "move", "from": 2, "to": 3}, "moved where its middle is")
	# put there, not flown: it settles from where it was let go
	await _wait(1)
	assert_lt(sentry.position.distance_to(before), 30.0, "no jump as it is let go")
	await _assert_dropped_in(sentry, 3)


func test_by_the_middle_a_card_held_low_over_the_board_is_sold() -> void:
	GameSettings.set_drop_by_middle(true, false)
	var pointer: Vector2 = _over_shop_and_board()
	var middle: Vector2 = await _hold_low_left(pointer)
	assert_gt(pointer.y, _screen.geom("T0"), "the pointer below the shop")
	assert_lt(middle.y, _screen.geom("T0"), "the card's middle over the shop")
	_press(pointer, false)
	assert_eq(_sent.size(), 1)
	assert_eq(str(_sent[0]["type"]), "sell", "sold")


func test_by_the_pointer_the_same_hold_is_not_a_sale() -> void:
	var pointer: Vector2 = _over_shop_and_board()
	await _hold_low_left(pointer)
	_press(pointer, false)
	assert_false(_sent.any(func(a: Dictionary) -> bool: return a["type"] == "sell"), "not sold")


func test_the_setting_takes_effect_while_the_screen_is_open() -> void:
	var pointer: Vector2 = _pointer_for(_slot_middle(3))
	await _hold_low_left(pointer)
	GameSettings.set_drop_by_middle(true, false)
	_press(pointer, false)
	assert_eq(_sent[0], {"type": "move", "from": 2, "to": 3}, "no restart needed")


func test_the_setting_is_saved_and_read_back() -> void:
	var other: ConfigFile = ConfigFile.new()
	other.set_value("sound", "master", 0.8)
	assert_eq(other.save(GameSettings.path), OK)
	GameSettings.set_drop_by_middle(true)
	other = ConfigFile.new()
	assert_eq(other.load(GameSettings.path), OK)
	var master: float = other.get_value("sound", "master", 0.0)
	assert_almost_eq(master, 0.8, 0.001, "what else the file holds is kept")
	GameSettings.forget()
	assert_true(GameSettings.drop_by_middle(), "card's middle, read back")
	GameSettings.set_drop_by_middle(false)
	GameSettings.forget()
	assert_false(GameSettings.drop_by_middle(), "the pointer, read back")
	assert_eq(DirAccess.remove_absolute(GameSettings.path), OK)
	GameSettings.forget()
	assert_false(GameSettings.drop_by_middle(), "no file: the pointer")
	var odd: ConfigFile = ConfigFile.new()
	odd.set_value("drag", "drop_by_middle", "yes")
	assert_eq(odd.save(GameSettings.path), OK)
	GameSettings.forget()
	assert_false(GameSettings.drop_by_middle(), "not true or false: the pointer")
	assert_eq(DirAccess.remove_absolute(GameSettings.path), OK)
	GameSettings.forget()


# ---- Recruit choices through real mouse events, after the unit has been gained ----


func _click_at(at: Vector2) -> void:
	_press(at, true)
	_press(at, false)


func _fury(unit: Unit) -> int:
	var totals: Dictionary = unit.view()["totals"]
	var fury: Dictionary = totals.get("badger_fury", {})
	return CoreUtil.to_int(fury.get("fury", 0))


func _master_offer() -> void:
	var me: PlayerState = _flow.human()
	me.discover_options.assign([&"master-at-arms"])
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_screen.settle()
	var node: Control = _screen.targets_of("discover")[0]["node"]
	_click_at(node.position + node.size / 2.0)
	assert_true(_screen.is_aiming(), "pick completed; choose a recruit target")
	assert_true(me.discover_options.is_empty())
	_assert_recruit_prompt()


func test_drag_buy_recruit_targets_board_then_plays_without_another_effect() -> void:
	_reshop(["master-at-arms"] as Array[String])
	var knight: Unit = _flow.human().board[1]
	_drag(_shop_middle(0), _slot_middle(3))
	var bought: Unit = _flow.human().hand.back()
	assert_eq(bought.def.id, &"master-at-arms", "bought into hand first")
	assert_eq(_fury(knight), 1, "no effect before choosing")
	_screen.settle()
	_click_at(_slot_middle(1))
	assert_eq(_refused, [] as Array[String])
	assert_eq(_fury(knight), 2)
	assert_false(_screen.is_aiming())
	assert_eq(_flow.human().board[3].def.id, &"master-at-arms")
	assert_eq(
		_sent.map(func(a: Dictionary) -> String: return a["type"]),
		["buy", "recruit_target", "play"]
	)


func test_double_click_buy_recruit_targets_a_hand_card() -> void:
	_reshop(["master-at-arms"] as Array[String])
	var held: Unit = _flow.human().hand[0]
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.double_click = true
	event.position = _shop_middle(0) + _frame_at()
	_screen._gui_input(event)
	_press(_shop_middle(0), false)
	assert_true(_screen.is_aiming())
	_screen.settle()
	_click_at(_hand_grip(0))
	assert_eq(_refused, [] as Array[String])
	assert_eq(_fury(held), 1)
	assert_false(_screen.is_aiming())
	assert_eq(_sent[1], {"type": "recruit_target", "target": held.uid})


func test_drag_buy_recruit_can_target_itself_in_hand() -> void:
	_reshop(["master-at-arms"] as Array[String])
	_drag(_shop_middle(0), _slot_middle(3))
	var master: Unit = _flow.human().hand.back()
	_screen.settle()
	_click_at(_hand_grip(1))
	assert_eq(_refused, [] as Array[String])
	assert_eq(_fury(master), 1)
	assert_eq(_flow.human().board[3], master)


func test_discover_recruit_can_target_a_hand_card() -> void:
	var held: Unit = _flow.human().hand[0]
	_master_offer()
	_screen.settle()
	_click_at(_hand_grip(0))
	assert_eq(_fury(held), 1)
	assert_false(_screen.is_aiming())
	assert_eq(_refused, [] as Array[String])
	assert_eq(_sent[1], {"type": "recruit_target", "target": held.uid})


func test_discover_recruit_can_target_a_board_unit() -> void:
	var cub: Unit = _flow.human().board[0]
	_master_offer()
	_screen.settle()
	_click_at(_slot_middle(0))
	assert_eq(_fury(cub), 2)
	assert_false(_screen.is_aiming())
	assert_eq(_refused, [] as Array[String])
	assert_eq(_sent[1], {"type": "recruit_target", "target": cub.uid})


func test_third_master_buy_aims_only_the_golden_and_gives_two_fury() -> void:
	var me: PlayerState = _flow.human()
	me.hand.append(CoreKit.unit(_flow.session, "master-at-arms"))
	me.hand.append(CoreKit.unit(_flow.session, "master-at-arms"))
	_reshop(["master-at-arms"] as Array[String])
	_drag(_shop_middle(0), _slot_middle(3))
	assert_true(_screen.is_aiming())
	assert_eq(me.recruit_choices.size(), 1)
	var golden: Unit = me.recruit_choices[0]
	assert_true(golden.golden, "the normal third copy never asks for its own target")
	_assert_recruit_prompt()
	_screen.settle()
	_click_at(_slot_middle(1))
	assert_eq(_fury(me.board[1]), 3, "printed Fury 1 plus the golden's +2 only")
	assert_false(_screen.is_aiming())
	assert_null(me.board[3], "the consumed bought copy is never played")
	var triggers: Array[Dictionary] = CoreKit.log_of(_flow.session, "trigger").filter(
		func(e: Dictionary) -> bool: return e["mechanic"] == "badger_arms_master"
	)
	assert_eq(triggers.size(), 1)
	assert_eq(_refused, [] as Array[String])


func _assert_recruit_prompt() -> void:
	var prompt: GlassText = _screen.find_child("Message", true, false) as GlassText
	assert_not_null(prompt, "the existing aim banner is shown after acquiring")
	assert_eq(prompt.words, RecruitScreen.AIM_PROMPT)
	assert_true(prompt.is_visible_in_tree())
	var me: PlayerState = _flow.human()
	var source: Unit = me.recruit_choices[0]
	var index: int = me.hand.find(source)
	var waiting: GlassCard = _screen.node_for("hand", index) as GlassCard
	assert_true(waiting.is_held(), "waiting card has the existing held highlight")
	_screen.cancel_aim()
	assert_true(_screen.is_aiming(), "paid recruit effect must resolve")


# ---- C15 zone moves and the commitment lock ----


func test_hand_unit_dragged_past_sell_line_is_sold_with_the_same_value() -> void:
	var held: Unit = _flow.human().hand[0]
	var gold: int = _flow.human().gold
	var value: int = _flow.session.rules.sell_value(_flow.human(), held)
	_drag(_hand_grip(0), _shop_middle(2))
	assert_eq(_sent, [{"type": "sell", "hand": 0}] as Array[Dictionary])
	assert_true(_flow.human().hand.is_empty())
	assert_eq(_flow.human().gold, gold + value)
	assert_eq(_refused, [] as Array[String])


func test_board_unit_dragged_to_hand_moves_the_same_copy_and_keeps_order_uses() -> void:
	var unit: Unit = _flow.human().board[1]
	unit.stats.perm_attack = 9
	unit.turn_counters[&"ability:core_test_order"] = 1
	var bought: int = unit.bought_copies
	_drag(_slot_middle(1), Vector2(960, 1015))
	assert_eq(_sent, [{"type": "to_hand", "slot": 1}] as Array[Dictionary])
	assert_null(_flow.human().board[1])
	var returned: Unit = _flow.human().hand.back()
	assert_eq(returned, unit)
	assert_eq(unit.bought_copies, bought)
	assert_eq(unit.stats.perm_attack, 9)
	assert_eq(unit.turn_counter(&"ability:core_test_order"), 1)
	assert_eq(unit.slot, -1)
	assert_eq(_refused, [] as Array[String])
	await _settle()


func test_full_hand_return_refusal_uses_the_existing_message_and_returns_card_home() -> void:
	for i: int in 6:
		_flow.human().hand.append(CoreKit.unit(_flow.session, "brock-cub", true))
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_screen.settle()
	var unit: Unit = _flow.human().board[1]
	_drag(_slot_middle(1), Vector2(960, 1015))
	assert_eq(_refused, ["hand is full"] as Array[String])
	assert_eq(str(_screen.state["message"]), "hand is full")
	assert_eq(_flow.human().board[1], unit)
	assert_eq(_flow.human().hand.size(), 7)
	await _settle()
	_at(_screen.node_for("board", 1), _screen.slot_xy(1))


func test_hand_sale_locks_the_gorger_shows_mark_and_refuses_return_but_allows_sale() -> void:
	var me: PlayerState = _flow.human()
	var gorger: Unit = CoreKit.put(_flow.session, me, "gorger", 3)
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_screen.settle()
	_drag(_hand_grip(0), _shop_middle(2))
	assert_true(gorger.worked_this_turn)
	var mark: KeywordMark = (
		_screen.node_for("board", 3).get_node_or_null("WorkedMark") as KeywordMark
	)
	assert_not_null(mark)
	assert_true(mark.is_visible_in_tree())
	var shown_board: Array = _screen.state["board"]
	var shown: Dictionary = shown_board[3]
	assert_true(_screen._reminders(shown).has("Worked this turn: stays for the fight."))
	_drag(_slot_middle(3), Vector2(960, 1015))
	assert_eq(_refused, ["Worked this turn: stays for the fight."] as Array[String])
	assert_eq(me.board[3], gorger)
	await _settle()
	_at(_screen.node_for("board", 3), _screen.slot_xy(3))
	_drag(_slot_middle(3), _shop_middle(2))
	assert_null(me.board[3], "the committed unit can still be sold")
	var last: Dictionary = _sent.back()
	assert_eq(last, {"type": "sell", "slot": 3})


func test_a_spell_dragged_to_shop_casts_instead_of_becoming_a_hand_sale() -> void:
	_flow.human().hand.clear()
	_flow.human().hand.append(CoreKit.unit(_flow.session, "sp_seek"))
	_screen.show_state(ViewAdapter.recruit_state(_flow))
	_screen.settle()
	_drag(_hand_grip(0), _shop_middle(2))
	assert_eq(str(_sent[0]["type"]), "play")
	assert_false(_sent.any(func(a: Dictionary) -> bool: return a["type"] == "sell"))
