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
## the click must reach its target, or it lands in `missed_taps`, as does a target that isn't there.
## Drops still go through the handlers.

const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
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
## Plays to last: climbs on a schedule, buys the biggest units, triples, sells the weakest.
## Otherwise it buys at random, which is more varied but rarely sees turn 10.
var skilled: bool = false
## Skilled only: rounds per tier climbed. Slower makes for a weaker board and a longer game.
var climb_every: float = 2.0
## Skilled only: the most units it fields. Fewer makes for a longer game.
var board_cap: int = 7
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## This turn: cards with no target or whose Play did nothing, so they aren't tried again.
var _cant_play: Dictionary = {}
var _buy_refused: bool = false
## This turn: presses by name that changed nothing and said nothing.
var _no_effect: Dictionary = {}


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
	_cant_play.clear()
	_no_effect.clear()
	_buy_refused = false
	answer_choices(screen)
	if skilled:
		_act_skilled(screen)
		return
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


## The tier this player's climb wants by this round.
func _wanted_tier(round_number: int) -> int:
	return mini(1 + floori(round_number / climb_every), 6)


func _act_skilled(screen: RecruitScreen) -> void:
	_use_power(screen)
	for attempt: int in 12:
		answer_choices(screen)
		var state: Dictionary = screen.state
		var gold: int = Data.i(state, "gold")
		var tier_cost: Variant = state.get("tier_up_cost")
		if (
			tier_cost != null
			and gold >= Data.as_int(tier_cost)
			and Data.i(state, "tier") < _wanted_tier(Data.i(state, "round"))
		):
			_press(screen, "_tier_button", "tier up")
			continue
		_play_hand(screen)
		if _buy_best(screen):
			continue
		if Data.i(screen.state, "gold") >= Data.i(screen.state, "refresh_cost", 99) + 3:
			_press(screen, "_refresh_button", "refresh")
			continue
		break
	_play_hand(screen)
	if _chance(0.3):
		_try_refused_drops(screen)
	if _chance(0.1):
		_move_one(screen)
	if _chance(0.15):
		_press(screen, "_freeze_button", "freeze")
	answer_choices(screen)


## A power that needs no aim, by its leaf on the hero's plaque, when it's up and affordable.
func _use_power(screen: RecruitScreen) -> void:
	var hero_view: Control = screen.get("_hero")
	var leaf: Button = hero_view.get("power")
	var aimless: bool = Data.s(Data.d(screen.state, "hero"), "aim", "none") == "none"
	if aimless and leaf != null and leaf.is_visible_in_tree() and not leaf.disabled:
		var cost: int = Data.i(Data.d(screen.state, "hero"), "power_cost", 0)
		if cost <= Data.i(screen.state, "gold"):
			var before: Dictionary = _before_press(screen)
			press(leaf, "hero power")
			_check_effect(screen, before, "hero power")
			answer_choices(screen)


static func _score(view: Dictionary) -> int:
	return Data.i(view, "attack") + Data.i(view, "health") + Data.i(view, "tier")


## Buys the biggest affordable unit, or a third copy before anything, making room by selling the
## weakest when it's worth it. Spare gold goes on a spell. False when there's nothing to do.
func _buy_best(screen: RecruitScreen) -> bool:
	var state: Dictionary = screen.state
	var gold: int = Data.i(state, "gold")
	var shop: Array = Data.a(state, "shop")
	var copies: Dictionary = RecruitView.copies(state)
	var best: int = -1
	var best_score: int = -1
	var spell: int = -1
	for i: int in shop.size():
		var view: Dictionary = shop[i]
		if Data.i(view, "cost", 3) > gold:
			continue
		if Data.s(view, "kind") != "":
			spell = i
			continue
		var score: int = _score(view) + 100 * Data.i(copies, Data.s(view, "def_id"), 0)
		if score > best_score:
			best = i
			best_score = score
	var placed: int = _board_count(state)
	var held: int = _units_held(state)
	if _buy_refused:
		return false
	if best >= 0 and placed + held < board_cap:
		_buy_at(screen, best)
		return true
	if best >= 0 and placed >= 1 and best_score > _weakest_score(state) + 2 and held == 0:
		_sell_weakest(screen)
		_buy_at(screen, best)
		return true
	var hand: int = Data.a(state, "hand").size()
	if spell >= 0 and _cant_play.is_empty() and hand < Data.i(state, "hand_limit", 10):
		_buy_at(screen, spell)
		return true
	return false


func _buy_at(screen: RecruitScreen, index: int) -> void:
	_count("buy by tap")
	# A refused Buy leaves the card selected, and tapping it again would close it.
	var selected: Dictionary = screen.get("_selected")
	if Data.s(selected, "zone") != "shop" or Data.i(selected, "index", -1) != index:
		tap(screen, "shop", index)
	if not _press_detail_action(screen, "Buy"):
		_buy_refused = true


static func _units_held(state: Dictionary) -> int:
	var units: int = 0
	for entry: Variant in Data.a(state, "hand"):
		var view: Dictionary = entry
		units += 1 if Data.s(view, "kind") == "" else 0
	return units


func _weakest_score(state: Dictionary) -> int:
	var weakest: int = 9999
	for entry: Variant in Data.a(state, "board"):
		if entry is Dictionary:
			var view: Dictionary = entry
			weakest = mini(weakest, _score(view))
	return weakest


## Tap the weakest unit, then Sell.
func _sell_weakest(screen: RecruitScreen) -> void:
	var board: Array = Data.a(screen.state, "board")
	var weakest: int = _weakest_score(screen.state)
	for slot: int in board.size():
		if board[slot] is Dictionary and _score(Data.entry(board, slot)) == weakest:
			_count("sell by tap")
			tap(screen, "board", slot)
			_press_detail_action(screen, "Sell")
			return


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


## Asks the screen whether the drop is allowed, notes a disagreement with `wanted`, and drops
## only when it is allowed.
func _try_drop(
	screen: RecruitScreen,
	from_zone: String,
	from_index: int,
	zone: String,
	index: int,
	wanted: bool
) -> void:
	var data: Dictionary = {"zone": from_zone, "index": from_index}
	var allowed: bool = screen.call("_can_drop", data, zone, index)
	if allowed != wanted:
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


## Refused drops, plus occupied slots that now accept a unit into a Belly.
func _try_refused_drops(screen: RecruitScreen) -> void:
	var state: Dictionary = screen.state
	if not Data.a(state, "hand").is_empty():
		_try_drop(screen, "hand", 0, "shop", -1, false)
	var board: Array = Data.a(state, "board")
	for slot: int in board.size():
		if board[slot] != null and not Data.a(state, "shop").is_empty():
			var into_belly: bool = RecruitHeld.can_swallow(
				Data.entry(board, slot), Data.entry(Data.a(state, "shop"), 0)
			)
			_try_drop(screen, "shop", 0, "board", slot, into_belly)
			return


func _press(screen: RecruitScreen, button_name: String, action: String) -> void:
	var button: Button = screen.get(button_name)
	if button != null and button.is_visible_in_tree() and not button.disabled:
		_count(action)
		var before: Dictionary = _before_press(screen)
		_click_button(button, action)
		if action != "end turn":
			_check_effect(screen, before, action)


## Clears the last toast so a refusal is seen fresh, and returns the state to compare with.
func _before_press(screen: RecruitScreen) -> Dictionary:
	if screen.is_inside_tree():
		screen.call("_clear_toast")
	return screen.state


## A press must change the game or tell the player why not. False if neither: a real click finding
## that is a problem, and three of the same in a turn is a loop, whatever the driver is doing.
func _check_effect(screen: RecruitScreen, before: Dictionary, label: String) -> bool:
	if screen.state != before:
		return true
	var toast: Label = screen.get("_toast")
	var told: bool = toast != null and toast.visible and not toast.text.is_empty()
	if told:
		return false
	if viewport != null:
		missed_taps.append("%s: nothing changed and nothing was said" % label)
	_no_effect[label] = Data.i(_no_effect, label, 0) + 1
	if Data.i(_no_effect, label, 0) == 3:
		missed_taps.append("%s: pressed 3 times in a turn with no effect" % label)
	return false


## A button a person would press, by a real click: it must reach the button.
func press(button: BaseButton, label: String) -> void:
	_count(label)
	_click_button(button, label)


## What a press must have done: a button can take the click and still do nothing.
func expect(done: bool, what: String) -> void:
	if not done:
		missed_taps.append(what)


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


## Presses Buy, Sell or Play on the open card. True if it changed the game.
func _press_detail_action(screen: RecruitScreen, prefix: String) -> bool:
	var detail: CardDetail = screen.get("_detail")
	# Synchronous actions can click in the same frame the buttons were added.
	detail.actions.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child: Node in detail.actions.get_children():
		var button: Button = child as Button
		if (
			button != null
			and (
				button.text.begins_with(prefix) or (prefix == "Sell" and button.text == "Fly south")
			)
		):
			var before: Dictionary = _before_press(screen)
			_click_button(button, prefix)
			return _check_effect(screen, before, prefix)
	if viewport != null:
		missed_taps.append("%s: no such button on the card" % prefix)
	return false


## Plays every hand card it can: tap the card, then tap an empty slot.
func _play_hand(screen: RecruitScreen) -> void:
	for attempt: int in 10:
		# A unit played a moment ago may have opened a Discover, which rightly takes every tap.
		answer_choices(screen)
		var hand: Array = Data.a(screen.state, "hand")
		var empty: Array[int] = _empty_slots(screen.state)
		if hand.is_empty():
			return
		var card_at: int = _first_card(hand)
		if card_at >= 0 and (empty.is_empty() or card_at == 0):
			_play_card(screen, card_at, Data.entry(hand, card_at))
			continue
		var hand_first: Dictionary = hand[0]
		if empty.is_empty() or Data.s(hand_first, "kind") != "":
			return
		_count("play by tap")
		var before: Dictionary = _before_press(screen)
		tap(screen, "hand", 0)
		tap(screen, "board", empty[0] if skilled else empty[rng.randi_range(0, empty.size() - 1)])
		if not _check_effect(screen, before, "play by tap"):
			return


## The first spell or item in the hand still worth trying this turn.
func _first_card(hand: Array) -> int:
	for i: int in hand.size():
		var view: Dictionary = hand[i]
		if Data.s(view, "kind") != "" and not _cant_play.has(Data.s(view, "name")):
			return i
	return -1


## A spell or item in the hand: Play if it needs no aim, else tap where it fits. One with nowhere to
## go must say so on its card, and stays in the hand.
func _play_card(screen: RecruitScreen, at: int, card: Dictionary) -> void:
	var name_of: String = Data.s(card, "name")
	var aim: String = Data.s(card, "aim", "none")
	var no_target: String = RecruitView.no_target_note(screen.state, card)
	tap(screen, "hand", at)
	if not no_target.is_empty():
		_count("spell with no target")
		_cant_play[name_of] = true
		var detail: CardDetail = screen.get("_detail")
		var hint: Label = detail.get("_hint")
		expect(viewport == null or hint.text == no_target, "%s: no target, no word why" % name_of)
		tap(screen, "hand", at)
		return
	_count("play spell")
	if aim == "none":
		if not _press_detail_action(screen, "Play"):
			_cant_play[name_of] = true
		answer_choices(screen)
		return
	var before: Dictionary = _before_press(screen)
	if aim == "shop_unit":
		tap(screen, "shop", _first_shop_unit(screen.state))
	else:
		var board: Array = Data.a(screen.state, "board")
		for slot: int in board.size():
			var target: Dictionary = board[slot] if board[slot] is Dictionary else {}
			if RecruitView.item_lands(card, target, slot):
				tap(screen, "board", slot)
				break
	if not _check_effect(screen, before, name_of):
		_cant_play[name_of] = true
		_selected_off(screen)
	answer_choices(screen)


static func _first_shop_unit(state: Dictionary) -> int:
	var shop: Array = Data.a(state, "shop")
	for i: int in shop.size():
		var offer: Dictionary = shop[i]
		if Data.s(offer, "kind") == "":
			return i
	return 0


## Leaves a card that stayed selected after a refused play, as a person would by tapping it again.
func _selected_off(screen: RecruitScreen) -> void:
	var selected: Dictionary = screen.get("_selected")
	if not selected.is_empty():
		tap(screen, Data.s(selected, "zone"), Data.i(selected, "index", 0))


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
	if (
		target == null
		and zone == "hand"
		and viewport != null
		and _tap_in_crowded_hand(screen, index)
	):
		return
	if target == null and viewport != null:
		missed_taps.append("%s: nothing there to click" % label)
	if target == null or not _click_control(target, "tapped", label):
		screen.call("_on_tapped", zone, index)


## A hand card with no tile of its own is behind "+N more": open that, then tap it there.
func _tap_in_crowded_hand(screen: RecruitScreen, index: int) -> bool:
	var grid: Control = screen.get("_hand_cards")
	var more: Button = grid.get_child(grid.get_child_count() - 1) as Button
	if more == null:
		return false
	_click_button(more, "+N more")
	var picker: Control = screen.get_child(screen.get_child_count() - 1)
	var cards: Array = picker.get("cards")
	if index >= cards.size():
		return false
	var card: Control = cards[index]
	return _click_control(card, "tapped", "hand %d, in the whole hand" % index)


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


func _click_button(button: BaseButton, label: String) -> void:
	if not _click_control(button, "pressed", label):
		button.pressed.emit()


## Clicks the middle of `target` and says whether its `signal_name` fired. A miss is noted. Off,
## with no viewport, it returns false so the caller uses the handler instead.
func _click_control(target: Control, signal_name: String, label: String) -> bool:
	if viewport == null:
		return false
	if not target.is_inside_tree():
		missed_taps.append("%s: not on screen" % label)
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
