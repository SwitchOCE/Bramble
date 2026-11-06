extends RefCounted
## Plays recruit turns the way a person would, by calling the recruit screen's handlers: button
## presses, card taps (tap a card, then Buy; tap a hand card, then a slot) and drops (shop to
## board, board to board, board onto the shop to sell). It does not go through Godot's drag code:
## each drop first asks the screen's _can_drop, records any disagreement with what the rules
## expect, and also tries drops that must be refused. Random but seeded, so a run can be
## repeated. Used by the scripted playthrough and its gate test.
##
## With `viewport` set, a press or a tap is a real mouse click at the middle of what it aims at,
## sent through the viewport, so something covering a button or a card is a failure and not a pass:
## the click must reach its target, or it lands in `missed_taps`. Drops still go through the
## handlers.

const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")

## Actions tried this run, by name (for the report).
var counts: Dictionary[String, int] = {}
## Drops where _can_drop disagreed with what the rules expect (should stay empty).
var drop_mismatches: PackedStringArray = []
## With `viewport`: clicks that didn't reach what they aimed at (should stay empty).
var missed_taps: PackedStringArray = []
## Set this to click for real; null calls the handlers directly.
var viewport: Viewport = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(run_seed: int = 1) -> void:
	rng.seed = run_seed


## One recruit turn, ending with End turn.
func play_turn(screen: RecruitScreen) -> void:
	act(screen)
	end_turn(screen)


func end_turn(screen: RecruitScreen) -> void:
	_press(screen, "_end_button", "end turn")


## Everything a turn does before End turn.
func act(screen: RecruitScreen) -> void:
	answer_choices(screen)
	if _chance(0.15):
		_press(screen, "_freeze_button", "freeze")
	var state: Dictionary = screen.state
	var tier_cost: Variant = state.get("tier_up_cost")
	if tier_cost != null and Data.i(state, "gold") >= Data.as_int(tier_cost) and _chance(0.5):
		_press(screen, "_tier_button", "tier up")
	for attempt: int in 6:
		if not _buy_one(screen):
			if Data.i(screen.state, "gold") >= Data.i(screen.state, "refresh_cost", 99):
				if _chance(0.5):
					_press(screen, "_refresh_button", "refresh")
					continue
			break
	if _chance(0.3):
		_try_refused_drops(screen)
	_play_hand(screen)
	if _chance(0.3):
		_move_one(screen)
	if _chance(0.2) and _board_count(screen.state) >= 6:
		_sell_one(screen)
	answer_choices(screen)


## A hero offer or a Discover blocks the screen: take a card, as a player tapping it would.
func answer_choices(screen: RecruitScreen) -> void:
	for pick: int in 5:
		var picker: Control = screen.get("_discover")
		if picker == null:
			return
		_count("choice")
		var cards: Array = picker.get("cards")
		var first: Control = cards[0]
		if not _click_control(first, "tapped", "a choice"):
			picker.call("_on_card_tapped", "picker", 0)


func _chance(p: float) -> bool:
	return rng.randf() < p


func _count(action: String) -> void:
	counts[action] = counts.get(action, 0) + 1


## Asks the screen whether the drop is allowed, notes a disagreement with `expect`, and drops
## only when it is allowed.
func _try_drop(
	screen: RecruitScreen,
	from_zone: String,
	from_index: int,
	zone: String,
	index: int,
	expect: bool
) -> void:
	var data: Dictionary = {"zone": from_zone, "index": from_index}
	var allowed: bool = screen.call("_can_drop", data, zone, index)
	if allowed != expect:
		drop_mismatches.append(
			(
				"%s %d -> %s %d: _can_drop says %s"
				% [from_zone, from_index, zone, index, "yes" if allowed else "no"]
			)
		)
	if allowed:
		screen.call("_drop", data, zone, index)
	else:
		_count("refused drop")


## Drops the rules forbid: a hand card onto the shop, and a shop card onto a taken slot.
func _try_refused_drops(screen: RecruitScreen) -> void:
	var state: Dictionary = screen.state
	if not Data.a(state, "hand").is_empty():
		_try_drop(screen, "hand", 0, "shop", -1, false)
	var board: Array = Data.a(state, "board")
	for slot: int in board.size():
		if board[slot] != null and not Data.a(state, "shop").is_empty():
			_try_drop(screen, "shop", 0, "board", slot, false)
			return


func _press(screen: RecruitScreen, button_name: String, action: String) -> void:
	var button: Button = screen.get(button_name)
	if button != null and not button.disabled:
		_count(action)
		_click_button(button, action)


func _empty_slots(state: Dictionary) -> Array[int]:
	var out: Array[int] = []
	var board: Array = Data.a(state, "board")
	for slot: int in board.size():
		if board[slot] == null:
			out.append(slot)
	return out


func _board_count(state: Dictionary) -> int:
	return Data.a(state, "board").size() - _empty_slots(state).size()


## Buys one affordable shop unit: by dragging it to an empty slot, or by tapping it and pressing
## Buy. False when nothing more is worth buying.
func _buy_one(screen: RecruitScreen) -> bool:
	var state: Dictionary = screen.state
	var shop: Array = Data.a(state, "shop")
	var hand: Array = Data.a(state, "hand")
	if shop.is_empty() or hand.size() >= Data.i(state, "hand_limit", 10):
		return false
	var index: int = rng.randi_range(0, shop.size() - 1)
	if Data.i(Data.entry(shop, index), "cost", 3) > Data.i(state, "gold"):
		return false
	if _board_count(state) + hand.size() >= 7 and not _chance(0.2):
		return false
	var empty: Array[int] = _empty_slots(state)
	var unit: bool = Data.s(Data.entry(shop, index), "kind") == ""
	if unit and not empty.is_empty() and _chance(0.5):
		_count("buy by drop on board")
		_try_drop(screen, "shop", index, "board", empty[0], true)
	else:
		_count("buy by tap")
		tap(screen, "shop", index)
		_press_detail_action(screen, "Buy")
	return true


func _press_detail_action(screen: RecruitScreen, prefix: String) -> void:
	var detail: CardDetail = screen.get("_detail")
	for child: Node in detail.actions.get_children():
		var button: Button = child as Button
		if button != null and button.text.begins_with(prefix):
			_click_button(button, prefix)
			return


## Plays every hand card it can: tap the card, then tap an empty slot.
func _play_hand(screen: RecruitScreen) -> void:
	for attempt: int in 10:
		# A unit played a moment ago may have opened a Discover, which rightly takes every tap.
		answer_choices(screen)
		var hand: Array = Data.a(screen.state, "hand")
		var empty: Array[int] = _empty_slots(screen.state)
		if hand.is_empty() or empty.is_empty():
			return
		var first: Dictionary = hand[0]
		if Data.s(first, "kind") != "":
			_play_card(screen, first)
			continue
		_count("play by tap")
		tap(screen, "hand", 0)
		tap(screen, "board", empty[rng.randi_range(0, empty.size() - 1)])


## A spell or item at the front of the hand: Play if it needs no aim, else tap a slot it fits.
func _play_card(screen: RecruitScreen, card: Dictionary) -> void:
	_count("play spell")
	tap(screen, "hand", 0)
	var aim: String = Data.s(card, "aim", "none")
	if aim == "none":
		screen.call("_on_spell_selected")
		answer_choices(screen)
		return
	var board: Array = Data.a(screen.state, "board")
	for slot: int in board.size():
		if RecruitView.aim_fits(aim, board[slot] != null, slot):
			tap(screen, "board", slot)
			answer_choices(screen)
			return
	if aim == "shop_unit" and not Data.a(screen.state, "shop").is_empty():
		tap(screen, "shop", 0)
		answer_choices(screen)
		return
	tap(screen, "hand", 0)


func _move_one(screen: RecruitScreen) -> void:
	var board: Array = Data.a(screen.state, "board")
	var taken: Array[int] = []
	for slot: int in board.size():
		if board[slot] != null:
			taken.append(slot)
	if taken.is_empty():
		return
	var from: int = taken[rng.randi_range(0, taken.size() - 1)]
	var to: int = rng.randi_range(0, board.size() - 1)
	_count("move by drop")
	_try_drop(screen, "board", from, "board", to, to != from)


func _sell_one(screen: RecruitScreen) -> void:
	var board: Array = Data.a(screen.state, "board")
	for slot: int in board.size():
		if board[slot] != null:
			_count("sell by drop on shop")
			_try_drop(screen, "board", slot, "shop", -1, true)
			return


## A tap on a card or slot: a real click when `viewport` is set, or the handler when not.
func tap(screen: RecruitScreen, zone: String, index: int) -> void:
	var target: Control = _tap_target(screen, zone, index)
	var label: String = "%s %d" % [zone, index]
	if target == null or not _click_control(target, "tapped", label):
		screen.call("_on_tapped", zone, index)


func _tap_target(screen: RecruitScreen, zone: String, index: int) -> Control:
	if viewport == null:
		return null
	# A person's tap comes frames after a render; here the grids haven't placed their new tiles yet.
	for grid_name: String in ["_shop_cards", "_hand_cards"]:
		var grid: Control = screen.get(grid_name)
		grid.notification(Container.NOTIFICATION_SORT_CHILDREN)
	if zone == "board" and screen.state.get("board", [])[index] == null:
		var board: Control = screen.get("_board")
		var slots: Array = board.get("slots")
		return slots[index]
	if zone == "scout":
		var scout: Control = screen.get("_scout")
		var pockets: Array = scout.call("slots")
		return pockets[index]
	var card: Control = screen.call("_card_at", zone, index)
	return card


func _click_button(button: Button, label: String) -> void:
	if not _click_control(button, "pressed", label):
		button.pressed.emit()


## Clicks the middle of `target` and says whether its `signal_name` fired. A miss is noted. Off,
## with no viewport, it returns false so the caller uses the handler instead.
func _click_control(target: Control, signal_name: String, label: String) -> bool:
	if viewport == null or not target.is_inside_tree():
		return false
	var fired: Array[bool] = [false]
	var mark: Callable = func(_a: Variant = null, _b: Variant = null) -> void: fired[0] = true
	target.connect(signal_name, mark)
	var at: Vector2 = target.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var click: InputEventMouseButton = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		viewport.push_input(click, true)
		if not is_instance_valid(target):
			return true
	if is_instance_valid(target) and target.is_connected(signal_name, mark):
		target.disconnect(signal_name, mark)
	if not fired[0]:
		var over: Control = viewport.gui_get_hovered_control()
		var hit: String = "nothing" if over == null else str(over.get_path())
		missed_taps.append("%s: the click at %s hit %s" % [label, at, hit])
	return fired[0]
