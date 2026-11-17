class_name RecruitActions
extends RefCounted
## Finds the actions the player means among the state's legal_actions, in the rules core's own
## action format (src/core/README.md). It decides nothing: an action the state does not list is
## still sent as built, so the core can say why it is refused.


## Every legal action whose fields include all of want's (numbers compared as numbers, since a
## state read from JSON carries floats).
static func matching(state: Dictionary, want: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for value: Variant in state.get("legal_actions", []):
		if value is Dictionary:
			var action: Dictionary = value
			if _has_all(action, want):
				out.append(action)
	return out


## The legal action that is exactly want, or want itself when the state does not list it.
static func pick(state: Dictionary, want: Dictionary) -> Dictionary:
	var found: Array[Dictionary] = matching(state, want)
	return found[0] if not found.is_empty() else want


## The targets the legal actions like want offer (their "target" fields other than -1), or none.
static func targets(state: Dictionary, want: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for action: Dictionary in matching(state, want):
		var target: int = GlassPieces.as_int(action.get("target", -1))
		if target >= 0 and not out.has(target):
			out.append(target)
	return out


## Whether any legal action is like want.
static func allows(state: Dictionary, want: Dictionary) -> bool:
	return not matching(state, want).is_empty()


static func _has_all(action: Dictionary, want: Dictionary) -> bool:
	for key: Variant in want:
		if not action.has(key) or not _same(action[key], want[key]):
			return false
	return true


static func _same(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(GlassPieces.as_float(a), GlassPieces.as_float(b))
	if a is bool or b is bool:
		return GlassPieces.as_bool(a) == GlassPieces.as_bool(b)
	return str(a) == str(b)


## The ability buttons a board unit shows: [{id, name, target_kind, reminder, cost, usable}], from
## the contract's {id, name, cost, usable, target_kind, reminder}. Each always shows, dimmed when
## not usable or not in legal_actions.
static func abilities(state: Dictionary, unit: Dictionary) -> Array:
	var out: Array = []
	for value: Variant in unit.get("abilities", []):
		var ability: Dictionary = value
		var id: String = str(ability["id"])
		var want: Dictionary = {"type": "ability", "uid": unit.get("uid", -1), "mechanic": id}
		var kind: String = str(ability.get("target_kind", "none"))
		(
			out
			. append(
				{
					"id": id,
					"target_kind": "" if kind == "none" else kind,
					"name": str(ability["name"]),
					"reminder": str(ability.get("reminder", "")),
					"cost": CoreUtil.to_int(ability.get("cost", 0)),
					"usable": allows(state, want) and GlassPieces.as_bool(ability["usable"]),
				}
			)
		)
	return out


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
