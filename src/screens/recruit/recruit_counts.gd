class_name RecruitCounts
extends RefCounted
## What the recruit screen counts: the gold, the player's counters and the hand's count ("Hand
## 2/7"). Each changes as the card that changed it arrives: a sold card's gold and counters as it
## reaches its plate (CardKeeper.flown_out), the hand's count as a bought card flies into the hand
## (CardKeeper.flown). Until then the old ones are drawn.
##
## A part of its screen: it draws on the screen's layers and redraws it.

## While a card that left (sold) flies to where it went: the gold and counters from before, so
## they change as it arrives ({gold, counters}; empty: the state's).
var _held: Dictionary = {}
## While a card flies into the hand: the hand's count from before (-1: the state's).
var _hand_held: int = -1
var _screen: RecruitScreen


func _init(screen: RecruitScreen) -> void:
	_screen = screen


## The gold drawn now.
func gold() -> int:
	return GlassPieces.as_int(_held.get("gold", _screen.state.get("gold", 0)))


## The counters drawn now.
func counters() -> Array:
	return _held.get("counters", _screen.state.get("counters", []))


## A new state is about to be drawn after before: when a card left (the state's `leaving`), the
## gold and counters from before are kept until it arrives.
func before_state(before: Dictionary, new_state: Dictionary) -> void:
	_held = {}
	_hand_held = -1
	var leaving: Dictionary = (
		new_state.get("leaving") if new_state.get("leaving") is Dictionary else {}
	)
	if not leaving.is_empty() and not before.is_empty():
		_held = {"gold": before.get("gold", 0), "counters": before.get("counters", [])}


## The new state is drawn: the hand's count waits for a card flying into it; with nothing flying
## out, the gold and counters change now.
func after_state(before: Dictionary) -> void:
	_hold_hand_count(before)
	# the counts change as the card that left arrives (CardKeeper.flown_out); none flying, now
	if not _held.is_empty() and not _screen._keeper.is_flying_out():
		arrived()


## The card that left has arrived: the held gold and counters let go (with a card held, only
## they are drawn again).
func arrived() -> void:
	if _held.is_empty():
		return
	_held = {}
	if not _screen.is_inside_tree():
		return
	if not _screen.is_holding():
		_screen.redraw()
	else:
		_redraw()


## The gold and the counters drawn again from the state, the rest left as it is (a card is held).
func _redraw() -> void:
	var gold_button: Node = _screen._back.get_node_or_null("Button_gold")
	if gold_button != null:
		for label: Node in gold_button.find_children("*", "GlassText", true, false):
			var text: GlassText = label
			text.words = str(GlassPieces.as_int(_screen.state.get("gold", 0)))
			text.refresh()
	_screen._counters.clear()
	_screen._counters.build(counters())


## The hand's count, left of the hand: "Hand 2/7".
func build_hand_count() -> void:
	var hand: Array = _screen.state.get("hand", [])
	var n: int = hand.size()
	# a card on its way to the hand counts once it is there
	var shown: int = _hand_held if _hand_held >= 0 else n
	var w: float = _screen.card_box().x
	var step: float = w * GlassPieces.number("stage.recruit.hand.step_per_w")
	var hw: float = step * (n - 1) + w
	var label: GlassText = GlassText.from_rule(
		"stage",
		".lbl",
		"Hand %d/%d" % [shown, GlassPieces.as_int(_screen.state.get("hand_limit", 7))]
	)
	label.name = "HandCount"
	label.font_px = GlassPieces.number("stage.recruit.hand_label.size")
	label.colour = GlassPieces.colour("stage.recruit.hand_label.colour")
	label.refresh()
	label.position = Vector2(
		960.0 - hw / 2.0 - GlassPieces.number("stage.recruit.hand_label.left"),
		_screen.geom("handTop") + GlassPieces.number("stage.recruit.hand_label.down")
	)
	_screen._front.add_child(label)


## A card bought onto a unit flies to the hand: the hand's count from before shows until it is
## there (CardKeeper.flown).
func _hold_hand_count(before: Dictionary) -> void:
	var was_hand: Array = before.get("hand", [])
	var hand: Array = _screen.state.get("hand", [])
	var was: int = was_hand.size()
	if before.is_empty() or was >= hand.size():
		return
	if not _hand_flying():
		return
	_hand_held = was
	_show_hand_count()


## A flight ended: once no card is still flying into the hand, the hand's count is the state's.
func flight_over() -> void:
	if _hand_held < 0 or _hand_flying():
		return
	_hand_held = -1
	_show_hand_count()


func _hand_flying() -> bool:
	for target: Dictionary in _screen.targets_of("hand"):
		var node: Control = target.get("node")
		if node != null and _screen._keeper.is_flying(node):
			return true
	return false


func _show_hand_count() -> void:
	var label: Node = _screen._front.get_node_or_null("HandCount")
	if label != null:
		_screen._front.remove_child(label)
		label.queue_free()
	build_hand_count()
