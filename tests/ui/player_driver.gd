extends RefCounted
## Plays recruit turns the way a person would, through the recruit screen's own input paths:
## buttons are pressed, cards are tapped (tap a card, then Buy; tap a hand card, then a slot) or
## dropped (shop to board, board to board, board onto the shop to sell). Random but seeded, so a
## run can be repeated. Used by the scripted playthrough and its gate test.

const Data := preload("res://src/ui/view_data.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")

## Actions tried this run, by name (for the report).
var counts: Dictionary[String, int] = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(run_seed: int = 1) -> void:
	rng.seed = run_seed


## One recruit turn, ending with End turn.
func play_turn(screen: RecruitScreen) -> void:
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
	_play_hand(screen)
	if _chance(0.3):
		_move_one(screen)
	if _chance(0.2) and _board_count(screen.state) >= 6:
		_sell_one(screen)
	_press(screen, "_end_button", "end turn")


func _chance(p: float) -> bool:
	return rng.randf() < p


func _count(action: String) -> void:
	counts[action] = counts.get(action, 0) + 1


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
	if not empty.is_empty() and _chance(0.5):
		_count("buy by drag to board")
		screen.call("_drop", {"zone": "shop", "index": index}, "board", empty[0])
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
		_count("play by tap")
		screen.call("_on_tapped", "hand", 0)
		screen.call("_on_tapped", "board", empty[rng.randi_range(0, empty.size() - 1)])


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
	if to != from:
		_count("move by drag")
		screen.call("_drop", {"zone": "board", "index": from}, "board", to)


func _sell_one(screen: RecruitScreen) -> void:
	var board: Array = Data.a(screen.state, "board")
	for slot: int in board.size():
		if board[slot] != null:
			_count("sell by drag to shop")
			screen.call("_drop", {"zone": "board", "index": slot}, "shop", -1)
			return
