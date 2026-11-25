class_name RecruitInput
extends RefCounted
## The recruit screen's pointer input: a press, a card carried, let go and dropped (bought, played,
## cast, moved, sold), a click (a button, an ability, a Discover pick), and a target being chosen.
## It reports what the player asks for through the screen's action_requested and holds no rules.
## Dragging and clicking share the press and the release, so they live together here.
##
## It works through the screen's public face (state, redraw, target_at, card_target_at, geom,
## slot_xy, hand_place, shown_count, is_discovering, forget_pointer,
## action_requested) and the parts it is given: the card keeper (lands and stops cards), the board
## (slots, lit targets) and the hover detail.
##
## Where a carried card drops is found from the pointer, or from the card's middle as drawn when
## the player has chosen that (GameSettings.drop_by_middle, owner 17 Nov): the slot, a sale, a
## buy, a play, a spell's cast and its target, and where the card is put down (CardKeeper.land).
## A press, a click and the hover stay on the pointer. Drop previews follow the actual drop point.

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
	_board.clear_drop_preview()
	_set_button_pressed(false)
	_press = {}
	_dragging = false
	_carry = null
	_aim = {}
	var choice: Dictionary = _screen.state.get("recruit_choice", {})
	if not choice.is_empty():
		_aim = {
			"want": {"type": "recruit_target"},
			"kind": choice["kind"],
			"targets": RecruitActions.targets(_screen.state, {"type": "recruit_target"}),
			"key": "",
			"at": Vector2.ZERO,
			"uid": choice["uid"]
		}

		var hand: Array = _screen.state.get("hand", [])
		for i: int in hand.size():
			var card: Dictionary = hand[i]
			if GlassPieces.as_int(card.get("uid", -1)) == GlassPieces.as_int(choice["uid"]):
				var place: Vector3 = _screen.hand_place(i, hand.size())
				_aim["key"] = GlassScreen.card_key("hand", i, card)
				_aim["at"] = Vector2(place.x, place.y - AIM_LIFT)
				break


## Whether the button is held on something or a card is carried (the hover detail waits).
func is_busy() -> bool:
	return _dragging or not _press.is_empty()


## Whether the button is held down on something now (a press not yet let go).
func is_pressing() -> bool:
	return not _press.is_empty()


## Whether a card is carried or pressed now (the counts are drawn on their own meanwhile).
func is_holding() -> bool:
	return _carry != null or not _press.is_empty()


## A carried card tilts and floats each frame, the pointer moving or not.
func step(delta: float) -> void:
	if _carry != null:
		_carry.step(delta)
		if _dragging and GameSettings.drop_by_middle():
			_preview_drop(_carry.middle())


## The window lost (Alt+Tab mid-drag, say): a carried card goes back where the state has it.
func focus_lost() -> void:
	RecruitShop.show_sell(_screen, 0, false)
	_board.clear_drop_preview()
	var held: Control = _carry.node if _carry != null else null
	if is_instance_valid(held):
		_keeper.land(held)
	var was_dragging: bool = _dragging or held != null
	_set_button_pressed(false)
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
	if _aim.is_empty() or _aim["want"]["type"] == "recruit_target":
		return
	_aim = {}
	_screen.redraw()


## Where the hand card with this key is held while its target is chosen, or null when it is not.
func aim_place(key: String) -> Variant:
	if is_aiming() and _aim["key"] == key:
		return _aim["at"]
	return null


## Lights the targets being chosen among, not on the card held.
func light_aim(light_targets: bool = true) -> void:
	if not is_aiming():
		return
	var lit: Array[int] = _aim["targets"]
	var held: Control = _held_card()
	if held is GlassCard:
		(held as GlassCard).set_held(true)
	# The waiting recruit remains a legal self-target.
	if light_targets:
		_board.light(
			str(_aim["kind"]), lit, null if _aim["want"]["type"] == "recruit_target" else held
		)


## The card held while its target is chosen, if any.
func _held_card() -> Control:
	for target: Dictionary in _screen.targets_of("hand") + _screen.targets_of("board"):
		var card: Dictionary = target["card"]
		var waiting: bool = (
			_aim.has("uid")
			and GlassPieces.as_int(card.get("uid", -1)) == GlassPieces.as_int(_aim["uid"])
		)
		if (
			waiting
			or (
				GlassScreen.card_key(str(target["kind"]), GlassPieces.as_int(target["index"]), card)
				== _aim["key"]
			)
		):
			return target["node"]
	return null


# ---- the pointer ----


func press(at: Vector2, double_click: bool = false) -> void:
	_press = _screen.target_at(at, false)
	_set_button_pressed(true)
	_press_at = at
	_dragging = false
	_tips.put_back = null
	# a double-click on a shop unit or spell buys it into the hand (owner, 18 Nov 2026)
	var kind: String = str(_press.get("kind", ""))
	if double_click and (kind == "shop" or kind == "spell") and _can_carry(_press):
		var index: int = _press["index"]
		_press = {}
		_screen.forget_pointer()
		_buy(kind == "spell", index, -1)
		return
	# a card pressed may be only clicked: its detail stays until it is dragged (a lifted hand card
	# stays up, to be carried from where it stands)
	if _can_carry(_press) and _press["node"] == _tips.standing:
		_tips.forget_standing()
	if _can_carry(_press):
		_pick_up()


## The pointer moved; whether a carried card took the move (no hover then).
func move(here: Vector2) -> bool:
	if _press.has("pressed_face"):
		_set_button_pressed(_screen.target_at(here, false) == _press)
	if not _press.is_empty() and not _dragging and here.distance_to(_press_at) > DRAG_START:
		_start_drag()
	if _carry != null:
		_carry.move(here)
		var drop_at: Vector2 = _drop_point(here)
		if _dragging:
			_preview_drop(drop_at)
		var card: Dictionary = _press.get("card", {})
		RecruitShop.show_sell(
			_screen,
			GlassPieces.as_int(card.get("sell_value", 0)),
			(
				_dragging
				and str(_press.get("kind", "")) in ["board", "hand"]
				and card.has("sell_value")
				and drop_at.y < _screen.geom("T0")
			),
			_carry.middle().x
		)
		return true
	return false


func _set_button_pressed(pressed: bool) -> void:
	var face: Control = _press.get("pressed_face")
	if is_instance_valid(face):
		face.position.y = GlassPieces.as_float(_press["press_offset"]) if pressed else 0.0


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
	var tag: Control = _carry.node.get_node_or_null("ShopTag")
	# the price travels with a carried shop card (recruit/NOTES.md 2; the owner, 22 Nov)
	if tag != null:
		tag.show()


## A card a press picks up: not during a Discover or a target choice, which take clicks only.
func _can_carry(pressed: Dictionary) -> bool:
	if not pressed.has("card") or is_aiming() or _screen.is_discovering():
		return false
	return ["shop", "spell", "hand", "board"].has(str(pressed["kind"]))


## The pressed card lifted and carried, from the press on (it may yet be only a click).
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
		# hidden at the press; it comes back on the card once the press is a drag
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
	_board.clear_drop_preview()
	var pressed: Dictionary = _press
	var was_drag: bool = _dragging
	var lifted: Control = _carry.node if _carry != null else null
	var drop_at: Vector2 = _drop_point(at)
	_set_button_pressed(false)
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


func _preview_drop(at: Vector2) -> void:
	var kind: String = _press["kind"]
	var card: Dictionary = _press["card"]
	if kind in ["shop", "hand"] and not GlassScreen._is_spell(card):
		_board.preview_drop(kind, GlassPieces.as_int(_press["index"]), _board.slot_at(at))


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
		elif at.y < _screen.geom("T0"):
			_request({"type": "sell", "hand": index})
		elif slot >= 0:
			var play: Dictionary = {"type": "play", "hand": index, "slot": slot}
			if _board.has_unit(slot):
				play["swap"] = true
			_request(play, {"target": -1})
	elif kind == "board":
		if slot >= 0 and slot != index:
			_request({"type": "move", "from": index, "to": slot})
		elif at.y < _screen.geom("T0"):
			_request({"type": "sell", "slot": index})
		elif at.y >= _screen.geom("sill"):
			_request({"type": "to_hand", "slot": index})


## A unit let go on an empty slot is bought there. Other drops below the shop buy into hand.
func _buy(spell: bool, index: int, slot: int) -> void:
	var buy: Dictionary = {"type": "buy", "spell": spell, "index": index}
	if not spell and slot >= 0 and not _board.has_unit(slot):
		buy["slot"] = slot
	_screen.ask(buy)


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
	if _screen.is_discovering():
		if pressed["kind"] == "discover":
			_screen.ask({"type": "pick", "index": pressed["index"]})
		return
	match str(pressed["kind"]):
		"ability":
			_use_ability(
				GlassPieces.as_int(pressed["uid"]), str(pressed["id"]), str(pressed["target"])
			)
		"button":
			match str(pressed["id"]):
				"tier":
					_request({"type": "upgrade"})
				"refresh", "freeze", "end_turn":
					_request({"type": str(pressed["id"])})


## What a stage point names as a target of a kind: a board unit's uid, a slot, a shop place; -1.
func _target_value_at(at: Vector2, kind: String) -> int:
	match kind:
		"unit":
			var zones: Array = ["board"]
			if is_aiming() and _aim["want"]["type"] == "recruit_target":
				zones.append("hand")
			var hit: Dictionary = _screen.card_target_at(at, zones)
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
