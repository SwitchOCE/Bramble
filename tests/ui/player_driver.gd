extends RefCounted
## Plays recruit turns the way a person would, by calling the recruit screen's handlers: button
## presses, card taps (tap a card, then Buy; tap a hand card, then a slot) and drops (shop to
## board, board to board, board onto the shop to sell). It does not go through Godot's drag code:
## each drop first asks the screen's _can_drop, records any disagreement with what the rules
## expect, and also tries drops that must be refused. Random but seeded, so a run can be
## repeated. Used by the scripted playthrough and its gate test.

const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const Data := preload("res://src/ui/view_data.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")

## Actions tried this run, by name (for the report).
var counts: Dictionary[String, int] = {}
## Drops where _can_drop disagreed with what the rules expect (should stay empty).
var drop_mismatches: PackedStringArray = []
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
		button.pressed.emit()


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
		screen.call("_on_tapped", "shop", index)
		_press_detail_action(screen, "Buy")
	return true


func _press_detail_action(screen: RecruitScreen, prefix: String) -> void:
	var detail: CardDetail = screen.get("_detail")
	for child: Node in detail.actions.get_children():
		var button: Button = child as Button
		if button != null and button.text.begins_with(prefix):
			button.pressed.emit()
			return


## Plays every hand card it can: tap the card, then tap an empty slot.
func _play_hand(screen: RecruitScreen) -> void:
	for attempt: int in 10:
		var hand: Array = Data.a(screen.state, "hand")
		var empty: Array[int] = _empty_slots(screen.state)
		if hand.is_empty() or empty.is_empty():
			return
		var first: Dictionary = hand[0]
		if Data.s(first, "kind") != "":
			_play_card(screen, first)
			continue
		_count("play by tap")
		screen.call("_on_tapped", "hand", 0)
		screen.call("_on_tapped", "board", empty[rng.randi_range(0, empty.size() - 1)])


## A spell or item at the front of the hand: Play if it needs no aim, else tap a slot it fits.
func _play_card(screen: RecruitScreen, card: Dictionary) -> void:
	_count("play spell")
	screen.call("_on_tapped", "hand", 0)
	var aim: String = Data.s(card, "aim", "none")
	if aim == "none":
		screen.call("_on_spell_selected")
		return
	var board: Array = Data.a(screen.state, "board")
	for slot: int in board.size():
		if RecruitView.aim_fits(aim, board[slot] != null):
			screen.call("_on_tapped", "board", slot)
			return
	screen.call("_on_tapped", "hand", 0)


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
