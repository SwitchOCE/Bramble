class_name FlowBot
extends SimpleBot
## The flow's bot: SimpleBot's choices, plus what it leaves on the table once its hand and board
## are full (it was seen holding 126 gold late in a game). When SimpleBot would end its turn:
##   1. use any legal ability (a Pigeon's Active, Bury...), a few times a turn at most
##   2. tier up when it can afford it
##   3. refresh with whatever gold is left, looking for a triple or a better unit
## Then end the turn. No tribe knowledge, like SimpleBot; nothing here is in the core.

## Abilities used in one turn, at most (an ability with no cost could otherwise loop).
const MAX_ABILITIES: int = 4
## Refreshes in one turn, at most: a bot spends what it has rather than keep it.
const MAX_SPARE_REFRESHES: int = 30

## Abilities used this turn, and the round they were counted in.
var _abilities_used: int = 0
var _round_seen: int = -1


func choose(session: GameSession, player: PlayerState) -> Dictionary:
	if session.round_number != _round_seen:
		_round_seen = session.round_number
		_abilities_used = 0
	var best: Dictionary = super.choose(session, player)
	var kind: String = CoreUtil.to_text(best.get("type", ""))
	if kind == "ability":
		if _abilities_used < MAX_ABILITIES:
			_abilities_used += 1
			return best
		best = {"type": "end_turn"}
		kind = "end_turn"
	if kind != "end_turn" and kind != "refresh":
		return best
	return _spare(session, player, best)


## What to do instead of ending the turn (or SimpleBot's own refresh): an ability, a tier-up, a
## refresh with spare gold, else `best`.
func _spare(session: GameSession, player: PlayerState, best: Dictionary) -> Dictionary:
	var legal: Array[Dictionary] = session.legal_actions(player.id)
	var ability: Dictionary = _first(legal, "ability")
	var out: Dictionary = best
	if not ability.is_empty() and _abilities_used < MAX_ABILITIES:
		_abilities_used += 1
		out = _random_target(legal, ability)
	elif not _first(legal, "upgrade").is_empty():
		out = _first(legal, "upgrade")
	elif CoreUtil.to_text(best["type"]) == "end_turn":
		var refresh: Dictionary = _first(legal, "refresh")
		if not refresh.is_empty() and player.refreshes_paid < MAX_SPARE_REFRESHES:
			out = refresh
	return out


static func _first(legal: Array[Dictionary], kind: String) -> Dictionary:
	for action: Dictionary in legal:
		if CoreUtil.to_text(action["type"]) == kind:
			return action
	return {}


## One of the legal targets of the same unit's same ability, at random.
func _random_target(legal: Array[Dictionary], ability: Dictionary) -> Dictionary:
	var same: Array[Dictionary] = []
	for action: Dictionary in legal:
		if (
			CoreUtil.to_text(action["type"]) == "ability"
			and action["uid"] == ability["uid"]
			and action["mechanic"] == ability["mechanic"]
		):
			same.append(action)
	return same[rng.index(same.size())]
