class_name RecruitSeam
extends RefCounted
## The one place that knows how the recruit screen reports input. The contract's signal is
## `action_requested(action)` in the core's own format; a screen that has it is passed straight
## through. Until the screens worker's change lands, the screen's index-based signals
## (buy_requested and the rest) are turned into the same actions here, reading the state the
## screen was given (uids, the hand's spells, legal_actions). Delete the `_old_*` half then.

signal action_requested(action: Dictionary)

var _screen: Control


func attach(screen: Control) -> void:
	_screen = screen
	if screen.has_signal("action_requested"):
		screen.connect("action_requested", _pass)
		return
	screen.connect("buy_requested", _old_buy)
	screen.connect("play_requested", _old_play)
	screen.connect("move_requested", _old_move)
	screen.connect("sell_requested", _old_sell)
	screen.connect("refresh_requested", _pass.bind({"type": "refresh"}))
	screen.connect("freeze_requested", _pass.bind({"type": "freeze"}))
	screen.connect("tier_up_requested", _pass.bind({"type": "upgrade"}))
	screen.connect("end_turn_requested", _pass.bind({"type": "end_turn"}))


func _pass(action: Dictionary) -> void:
	action_requested.emit(action.duplicate(true))


func _state() -> Dictionary:
	var value: Variant = _screen.get("state")
	return value if value is Dictionary else {}


func _old_buy(index: int, is_spell: bool) -> void:
	_pass({"type": "buy", "spell": is_spell, "index": index})


func _old_sell(slot: int) -> void:
	_pass({"type": "sell", "slot": slot})


func _old_move(from_slot: int, to_slot: int) -> void:
	_pass({"type": "move", "from": from_slot, "to": to_slot})


## A hand card dropped on a slot. A unit is played there; a spell is cast, on the unit in that
## slot when it takes a target. With no target picking on the screen yet, the dropped-on unit is
## the target when it is legal, else the first legal target.
func _old_play(hand_index: int, slot: int) -> void:
	var state: Dictionary = _state()
	var hand: Array = state.get("hand", [])
	var card: Dictionary = (
		hand[hand_index] if hand_index < hand.size() and hand[hand_index] is Dictionary else {}
	)
	var spell: bool = CoreUtil.to_bool(card.get("spell", false))
	var wanted: int = -1
	var board: Array = state.get("board", [])
	if spell and slot >= 0 and slot < board.size() and board[slot] is Dictionary:
		var target: Dictionary = board[slot]
		wanted = CoreUtil.to_int(target.get("uid", -1))
	var fallback: Dictionary = {}
	for value: Variant in state.get("legal_actions", []):
		var action: Dictionary = value
		if str(action.get("type", "")) != "play" or CoreUtil.to_int(action["hand"]) != hand_index:
			continue
		if not spell and CoreUtil.to_int(action["slot"]) != slot:
			continue
		if CoreUtil.to_int(action["target"]) == wanted or wanted == -1:
			_pass(action)
			return
		if fallback.is_empty():
			fallback = action
	if not fallback.is_empty():
		_pass(fallback)
		return
	# nothing legal: let the core say why
	_pass({"type": "play", "hand": hand_index, "slot": -1 if spell else slot, "target": wanted})
