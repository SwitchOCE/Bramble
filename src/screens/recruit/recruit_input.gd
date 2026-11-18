class_name RecruitInput
extends RefCounted
## The recruit screen's pointer input: a press, a card carried, let go and dropped (bought, played,
## cast, moved, sold), a click (a button, an ability, a Discover pick), and a target being chosen.
## It reports what the player asks for through the screen's action_requested and holds no rules.
## Dragging and clicking share the press and the release, so they live together here.
##
## It works through the screen's public face (state, redraw, target_at, card_target_at, geom,
## slot_xy, hand_place, shown_count, is_discovering, toggle_leaderboard, forget_pointer,
## action_requested) and the parts it is given: the card keeper (lands and stops cards), the board
## (slots, lit targets) and the hover detail.
##
## Where a carried card drops is found from the pointer, or from the card's middle as drawn when
## the player has chosen that (GameSettings.drop_by_middle, owner 17 Nov): the slot, a sale, a
## buy, a play, a spell's cast and its target, and where the card is put down (CardKeeper.land).
## A press, a click and the hover stay on the pointer. Nothing lit during a carry depends on where
## the card is (light_drop lights every slot it may go to).

## How far the pointer moves, in px, before a press becomes a drag.
const DRAG_START: float = 8.0
## STAND-IN: how far a spell waiting for its target stands up out of the hand.
const AIM_LIFT: float = 70.0
## A carried card is drawn above everything on the table, slot bonus pills and the vignette too
## (the Discover veil is 8; the hovered card 5). Let go, it is put down at once (CardKeeper.land).
const CARRIED_Z: int = 7

var _screen: RecruitScreen
var _keeper: CardKeeper
var _board: RecruitBoard
var _tips: RecruitTips
## The target pressed, and where.
var _press: Dictionary = {}
var _press_at: Vector2 = Vector2.ZERO
var _dragging: bool = false
## The card being carried, while one is.
var _carry: CardCarry
## A target being chosen: {want, kind, targets, key (the card held), at (where it is held)}.
var _aim: Dictionary = {}
## A buy onto a slot sends a buy, then a play: the buy's state is kept but not drawn, so only the
## play's is (one redraw).
var _draw_held: bool = false
var _draw_pending: bool = false


func _init(
	screen: RecruitScreen, keeper: CardKeeper, board: RecruitBoard, tips: RecruitTips
) -> void:
	_screen = screen
	_keeper = keeper
	_board = board
	_tips = tips


# ---- what the screen asks ----


## A new state has come: a press, a carry and a target choice are over.
func reset() -> void:
	RecruitShop.show_sell(_screen, 0, false)
	_press = {}
	_dragging = false
	_carry = null
	_aim = {}


## Whether the button is held on something or a card is carried (the hover detail waits).
func is_busy() -> bool:
	return _dragging or not _press.is_empty()


## Whether the button is held down on something now (a press not yet let go).
func is_pressing() -> bool:
	return not _press.is_empty()


## Whether a card is carried or pressed now (the counts are drawn on their own meanwhile).
func is_holding() -> bool:
	return _carry != null or not _press.is_empty()


## Whether a buy's state is being kept undrawn until its play (show_state keeps it), and marks it
## waiting to be drawn.
func holds_draw() -> bool:
	if _draw_held:
		_draw_pending = true
	return _draw_held


## Every drawing draws the state as it is now (a held buy's too).
func drawn() -> void:
	_draw_pending = false


## A carried card tilts and floats each frame, the pointer moving or not.
func step(delta: float) -> void:
	if _carry != null:
		_carry.step(delta)


## The window lost (Alt+Tab mid-drag, say): a carried card goes back where the state has it.
func focus_lost() -> void:
	RecruitShop.show_sell(_screen, 0, false)
	var held: Control = _carry.node if _carry != null else null
	if is_instance_valid(held):
		_keeper.land(held)
	var was_dragging: bool = _dragging or held != null
	_press = {}
	_dragging = false
	_carry = null
	if was_dragging and _screen.is_inside_tree():
		_screen.redraw()


# ---- a target being chosen ----


## Whether the screen is waiting for the player to choose a target.
func is_aiming() -> bool:
	return not _aim.is_empty()


## Drops the target choice, putting the card back where the state has it.
func cancel_aim() -> void:
	if _aim.is_empty():
		return
	_aim = {}
	_screen.redraw()


## Where the hand card with this key is held while its target is chosen, or null when it is not.
func aim_place(key: String) -> Variant:
	if is_aiming() and _aim["key"] == key:
		return _aim["at"]
	return null


## Lights the targets being chosen among, not on the card held.
func light_aim() -> void:
	if not is_aiming():
		return
	var lit: Array[int] = _aim["targets"]
	_board.light(str(_aim["kind"]), lit, _held_card())


## The card held while its target is chosen, if any.
func _held_card() -> Control:
	for target: Dictionary in _screen.targets_of("hand"):
		var card: Dictionary = target["card"]
		if GlassScreen.card_key("hand", GlassPieces.as_int(target["index"]), card) == _aim["key"]:
			return target["node"]
	return null


# ---- the pointer ----


func press(at: Vector2, double_click: bool = false) -> void:
	_press = _screen.target_at(at, false)
	_press_at = at
	_dragging = false
	_tips.put_back = null
	if double_click and str(_press.get("kind", "")) == "shop" and _can_carry(_press):
		var index: int = _press["index"]
		_press = {}
		_screen.forget_pointer()
		_buy(false, index, -1)
		return
	# a card pressed may be only clicked: its detail stays until it is dragged (a lifted hand card
	# stays up, to be carried from where it stands)
	if _can_carry(_press) and _press["node"] == _tips.standing:
		_tips.forget_standing()
	if _can_carry(_press):
		_pick_up()


## The pointer moved; whether a carried card took the move (no hover then).
func move(here: Vector2) -> bool:
	if not _press.is_empty() and not _dragging and here.distance_to(_press_at) > DRAG_START:
		_start_drag()
	if _carry != null:
		_carry.move(here)
		var card: Dictionary = _press.get("card", {})
		RecruitShop.show_sell(
			_screen,
			GlassPieces.as_int(card.get("sell_value", 0)),
			(
				_dragging
				and str(_press.get("kind", "")) == "board"
				and card.has("sell_value")
				and _drop_point(here).y < _screen.geom("T0")
			),
			_carry.middle().x
		)
		return true
	return false


func _start_drag() -> void:
	if not _press.is_empty() and str(_press["kind"]) in ["ability", "ability_off"]:
		# a drag that starts on a button carries its card
		_press = _screen.card_target_at(_press_at, ["board"])
	if not _can_carry(_press):
		return
	if _carry == null:
		_pick_up()
	_dragging = true
	# now a drag: the detail fades (and the carried card stays drawn over everything)
	_tips.fade()
	_carry.node.z_index = CARRIED_Z


## A card a press picks up: not during a Discover or a target choice, which take clicks only.
func _can_carry(pressed: Dictionary) -> bool:
	if not pressed.has("card") or is_aiming() or _screen.is_discovering():
		return false
	return ["shop", "spell", "hand", "board"].has(str(pressed["kind"]))


## The pressed card lifted and carried; shop units wait until the drag threshold is crossed.
func _pick_up() -> void:
	# a lifted hand card is carried from where it stands
	_tips.forget_standing()
	var node: Control = _press["node"]
	_keeper.stop(node)
	node.z_index = CARRIED_Z
	_carry = CardCarry.new(node, _press_at)
	if node is GlassCard:
		(node as GlassCard).set_held(true)
	var card: Dictionary = _press["card"]
	var tag: Control = node.get_node_or_null("ShopTag")
	if tag != null:
		tag.hide()
	var index: int = GlassPieces.as_int(_press["index"])
	if _press["kind"] == "board":
		_board.leave_slot(node, card, index)
	if not GlassScreen._is_spell(card):
		_board.light_drop(str(_press["kind"]), index)
	# a spell that aims shows its targets while it is carried
	if _press["kind"] == "hand" and GlassScreen._is_spell(card):
		var want: Dictionary = {"type": "play", "hand": index}
		_board.light(
			RecruitScreen.target_kind(card), RecruitActions.targets(_screen.state, want), node
		)


func release(at: Vector2) -> void:
	RecruitShop.show_sell(_screen, 0, false)
	var pressed: Dictionary = _press
	var was_drag: bool = _dragging
	var lifted: Control = _carry.node if _carry != null else null
	var drop_at: Vector2 = _drop_point(at)
	_press = {}
	_dragging = false
	_carry = null
	if pressed.is_empty():
		return
	if not was_drag:
		var before: int = _screen.shown_count()
		if is_instance_valid(lifted):
			_keeper.land(lifted, at)
			_tips.put_back = lifted
		_click(pressed, at)
		if (
			is_instance_valid(lifted)
			and before == _screen.shown_count()
			and _screen.is_inside_tree()
		):
			_screen.redraw()
		# a click that drew a new state has its hover detail drawn already
		var same: bool = before == _screen.shown_count()
		if same and pressed.has("card") and is_instance_valid(pressed["node"]) and not is_aiming():
			_tips.show(pressed, at)
		return
	var shown: int = _screen.shown_count()
	var dropped: Control = pressed["node"]
	# put down: drawn as it will be when still, over the cards it passes (CardKeeper.land)
	_keeper.land(dropped, drop_at)
	# no hover detail for the dropped card on its way to its new place
	_screen.forget_pointer()
	_drop(pressed, drop_at)
	# nothing new drawn: the card goes back where the state has it
	if shown == _screen.shown_count() and _screen.is_inside_tree():
		_screen.redraw()


## Where a card carried now would drop with the pointer at `at`: the pointer, or the card's middle
## as drawn (GameSettings.drop_by_middle).
func _drop_point(at: Vector2) -> Vector2:
	if _carry != null and is_instance_valid(_carry.node) and GameSettings.drop_by_middle():
		return _carry.middle()
	return at


func _drop(pressed: Dictionary, at: Vector2) -> void:
	var kind: String = pressed["kind"]
	var index: int = pressed["index"]
	var slot: int = _board.slot_at(at)
	if kind == "shop" or kind == "spell":
		if at.y > _screen.geom("shopBot"):
			_buy(kind == "spell", index, slot)
	elif kind == "hand":
		var card: Dictionary = pressed["card"]
		if GlassScreen._is_spell(card):
			if at.y < _screen.geom("sill"):
				_cast(index, card, at)
		elif slot >= 0:
			_play(index, card, slot)
	elif kind == "board":
		if slot >= 0 and slot != index:
			_request({"type": "move", "from": index, "to": slot})
		elif at.y < _screen.geom("T0"):
			_request({"type": "sell", "slot": index})


## A shop card let go below the shop: bought. A unit let go on an empty slot is then played into
## that slot, so it goes straight there; on a unit or anywhere else it goes to the hand. Only the
## very card bought is played: a buy that made a golden (a triple) leaves the golden, and anything
## it brought, in the hand (until the owner decides otherwise).
func _buy(spell: bool, index: int, slot: int) -> void:
	var bought_id: String = bought_onto(_screen.state, spell, index, slot)
	var had: Dictionary = hand_uids(_screen.state)
	_draw_held = bought_id != "" and _screen.is_inside_tree()
	_request({"type": "buy", "spell": spell, "index": index})
	_draw_held = false
	if bought_id != "" and _screen.is_inside_tree():
		var fresh: int = bought_card(_screen.state, had, bought_id)
		if fresh >= 0:
			var hand: Array = _screen.state["hand"]
			var bought: Dictionary = hand[fresh]
			_play(fresh, bought, slot)
	# the buy's state, when no play (or target choice) drew one after it
	if _draw_pending and _screen.is_inside_tree():
		_screen.redraw()


## A unit from the hand into a slot: sent at once, or a target to choose first.
func _play(index: int, card: Dictionary, slot: int) -> void:
	var want: Dictionary = {"type": "play", "hand": index, "slot": slot}
	var targets: Array[int] = RecruitActions.targets(_screen.state, want)
	if targets.is_empty():
		_request(want, {"target": -1})
		return
	_start_aim(
		want,
		RecruitScreen.target_kind(card),
		targets,
		GlassScreen.card_key("hand", index, card),
		_screen.slot_xy(slot)
	)


## A spell let go over the table: on a target it names, cast there; with no target to choose, cast;
## otherwise choose one.
func _cast(index: int, card: Dictionary, at: Vector2) -> void:
	var want: Dictionary = {"type": "play", "hand": index}
	var targets: Array[int] = RecruitActions.targets(_screen.state, want)
	if targets.is_empty():
		_request(want, {"slot": -1, "target": -1})
		return
	var kind: String = RecruitScreen.target_kind(card)
	var on: int = _target_value_at(at, kind)
	if targets.has(on):
		var aimed: Dictionary = want.duplicate()
		aimed["target"] = on
		_request(aimed)
		return
	aim_hand(index, card, want, targets)


## Holds hand card index up out of the hand while its target is chosen.
func aim_hand(index: int, card: Dictionary, want: Dictionary, targets: Array[int]) -> void:
	var key: String = GlassScreen.card_key("hand", index, card)
	var hand: Array = _screen.state.get("hand", [])
	var place: Vector3 = _screen.hand_place(index, hand.size())
	var kind: String = RecruitScreen.target_kind(card)
	_start_aim(want, kind, targets, key, Vector2(place.x, place.y - AIM_LIFT))


## An ability button: used at once, or a target to choose first.
func _use_ability(uid: int, mechanic: String, kind: String) -> void:
	var want: Dictionary = {"type": "ability", "uid": uid, "mechanic": mechanic}
	var targets: Array[int] = RecruitActions.targets(_screen.state, want)
	if targets.is_empty():
		_request(want, {"target": -1})
		return
	_start_aim(want, kind, targets, "", Vector2.ZERO)


## Waits for a target: the valid ones lit, the card held where it was played.
func _start_aim(
	want: Dictionary, kind: String, targets: Array[int], key: String, at: Vector2
) -> void:
	_aim = {"want": want, "kind": kind, "targets": targets, "key": key, "at": at}
	_screen.redraw()


func _click(pressed: Dictionary, at: Vector2) -> void:
	if _screen.target_at(at, false) != pressed:
		return
	if _screen.is_discovering():
		if pressed["kind"] == "discover":
			_request({"type": "pick", "index": pressed["index"]})
		return
	if is_aiming():
		var value: int = _target_value_at(at, str(_aim["kind"]))
		var targets: Array[int] = _aim["targets"]
		if targets.has(value):
			var want: Dictionary = _aim["want"]
			var aimed: Dictionary = want.duplicate()
			aimed["target"] = value
			_aim = {}
			_request(aimed)
		return
	match str(pressed["kind"]):
		"ability":
			_use_ability(
				GlassPieces.as_int(pressed["uid"]), str(pressed["id"]), str(pressed["target"])
			)
		"button":
			match str(pressed["id"]):
				"hero":
					_screen.toggle_leaderboard()
				"tier":
					_request({"type": "upgrade"})
				"refresh", "freeze", "end_turn":
					_request({"type": str(pressed["id"])})


## What a stage point names as a target of a kind: a board unit's uid, a slot, a shop place; -1.
func _target_value_at(at: Vector2, kind: String) -> int:
	match kind:
		"unit":
			var hit: Dictionary = _screen.card_target_at(at, ["board"])
			if hit.is_empty():
				return -1
			var card: Dictionary = hit["card"]
			return GlassPieces.as_int(card.get("uid", -1))
		"slot":
			return _board.slot_at(at)
		"shop":
			var hit: Dictionary = _screen.card_target_at(at, ["shop"])
			return GlassPieces.as_int(hit["index"]) if not hit.is_empty() else -1
	return -1


## Sends the legal action like want; when the state lists none, want with the extra fields.
func _request(want: Dictionary, extra: Dictionary = {}) -> void:
	var found: Array[Dictionary] = RecruitActions.matching(_screen.state, want)
	if not found.is_empty():
		_screen.ask(found[0])
		return
	var built: Dictionary = want.duplicate()
	built.merge(extra)
	_screen.ask(built)


# ---- a buy onto a slot, read from the state ----


## The id of the shop unit a drop buys onto an empty board slot (to be played there), or "".
static func bought_onto(state: Dictionary, spell: bool, index: int, slot: int) -> String:
	var board: Array = state.get("board", [])
	var shop: Array = state.get("shop_units", [])
	if spell or slot < 0 or slot >= board.size() or board[slot] != null:
		return ""
	if index < 0 or index >= shop.size() or not shop[index] is Dictionary:
		return ""
	var offered: Dictionary = shop[index]
	return str(offered.get("id", ""))


## The uids of the cards in the hand, as a set.
static func hand_uids(state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for card: Dictionary in state.get("hand", []):
		out[GlassPieces.as_int(card.get("uid", -1))] = true
	return out


## The hand index of the card a buy put there: exactly one card not in had, the one bought (not a
## triple's golden); -1 otherwise.
static func bought_card(state: Dictionary, had: Dictionary, bought_id: String) -> int:
	var hand: Array = state.get("hand", [])
	var fresh: Array[int] = []
	for i: int in hand.size():
		var card: Dictionary = hand[i]
		if not had.has(GlassPieces.as_int(card.get("uid", -1))):
			fresh.append(i)
	if fresh.size() != 1:
		return -1
	var bought: Dictionary = hand[fresh[0]]
	if str(bought.get("id", "")) != bought_id or bought.get("golden", false) == true:
		return -1
	return fresh[0]
