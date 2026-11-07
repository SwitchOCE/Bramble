extends "res://src/ui/screens/recruit_layout.gd"
## Guard recruit actions before they mutate state; the screen supplies its ordinary toast.

var _pending_shy: String = ""
var _shy_notice: Callable


## A second identical action confirms a precise warning. A changed state requires a fresh warning.
func _allow_shy(action: String, first: int = -1, second: int = -1) -> bool:
	var warning: String = port.shy_warning(action, first, second)
	if warning.is_empty():
		_pending_shy = ""
		return true
	var key: String = (
		"%s:%d:%d:%d" % [action, first, second, JSON.stringify(port.get_state()).hash()]
	)
	if key == _pending_shy:
		_pending_shy = ""
		return true
	_pending_shy = key
	_shy_notice.call(warning)
	return false


func _safe_item(index: int, slot: int = -1) -> String:
	return (
		port.play_item(index, slot)
		if _allow_shy("play_item", index, slot)
		else "Shy warning: repeat to confirm"
	)


func _safe_move(first: int, second: int) -> String:
	return (
		port.move(first, second)
		if _allow_shy("move", first, second)
		else "Shy warning: repeat to confirm"
	)


func _safe_play(index: int, slot: int) -> String:
	return (
		port.play(index, slot)
		if _allow_shy("play", index, slot)
		else "Shy warning: repeat to confirm"
	)


func _safe_power(slot: int = -1) -> String:
	return port.use_power(slot) if _allow_shy("power", slot) else "Shy warning: repeat to confirm"


func _safe_buy_play(index: int, slot: int) -> String:
	return (
		RecruitView.buy_and_play(port, index, slot)
		if _allow_shy("buy_play", index, slot)
		else "Shy warning: repeat to confirm"
	)


## What the board and purse did by themselves: a sale's coins are in its own sound.
func _play_change_sounds(old_state: Dictionary, sound: String) -> void:
	if sound != "sell" and Data.i(state, "gold", 0) > Data.i(old_state, "gold", 0):
		Sfx.play("gold")
	if RecruitView.ring_words(state) != RecruitView.ring_words(old_state):
		Sfx.play("ring")


## The Stash or Hoard that just formed swells for a moment, so the combine is seen.
func _pulse_new_hand_card(known: Dictionary) -> void:
	if Settings.reduce_motion:
		return
	for child: Node in _hand_cards.get_children():
		var card: CardView = child as CardView
		if card != null and not known.has(Data.i(card.unit, "iid", -1)):
			card.pivot_offset = card.size / 2.0
			card.scale = Vector2(1.35, 1.35)
			create_tween().tween_property(card, "scale", Vector2.ONE, 0.4)
