class_name SimpleBot
extends Bot
## A plain greedy player: scores every legal action and takes the best, ending its turn when
## nothing scores above 0. Upgrades on a rough curve, buys the strongest unit it can afford,
## fills the board front first, swaps its weakest unit out for a stronger one, refreshes a
## little. No tribe knowledge: it sees only tier, stats and triples.

const MAX_REFRESHES: int = 3


func choose(session: GameSession, player: PlayerState) -> Dictionary:
	var best: Dictionary = {"type": "end_turn"}
	var best_score: float = 0.0
	var refresh: Dictionary = {}
	var will_buy: bool = false
	for action: Dictionary in session.legal_actions(player.id):
		if action["type"] == "refresh":
			refresh = action
			continue
		var score: float = _score(session, player, action)
		will_buy = will_buy or (action["type"] == "buy" and score > 0.0)
		if score > best_score:
			best_score = score
			best = action
	var may_refresh: bool = player.refreshes_paid < MAX_REFRESHES and player.gold >= 3
	if best_score <= 0.0 and not refresh.is_empty() and not will_buy and may_refresh:
		return refresh
	return best


func _score(session: GameSession, player: PlayerState, action: Dictionary) -> float:
	var score: float = -1.0
	match CoreUtil.to_text(action["type"]):
		"recruit_target":
			var target: Unit = player.find_uid(CoreUtil.to_int(action["target"]))
			score = 100.0 + _unit_worth(target)
		"pick":
			var option: UnitDef = session.library.get_card(
				player.discover_options[CoreUtil.to_int(action["index"])]
			)
			score = 100.0 + _worth(option)
		"upgrade":
			score = _upgrade_score(session, player)
		"play":
			score = _play_score(player, action)
		"buy":
			score = _buy_score(session, player, action)
		"sell":
			score = (
				_sell_score(player, CoreUtil.to_int(action["slot"])) if action.has("slot") else -1.0
			)
		"ability":
			score = 2.0  # an ability a card offers is worth using
	return score


## Tier first, stats second.
static func _worth(card: UnitDef) -> float:
	return card.tier * 10.0 + (card.attack + card.health) * 0.1


static func _unit_worth(unit: Unit) -> float:
	return (
		(unit.def.tier + (2 if unit.golden else 0)) * 10.0 + (unit.attack() + unit.health()) * 0.1
	)


func _upgrade_score(session: GameSession, player: PlayerState) -> float:
	var cost: int = session.rules.upgrade_cost(player)
	if cost == 0:
		return 90.0
	@warning_ignore("integer_division")
	var goal: int = 1 + (session.round_number + 1) / 2
	return 60.0 if player.tier < goal else -1.0


func _play_score(player: PlayerState, action: Dictionary) -> float:
	var card: Unit = player.hand[CoreUtil.to_int(action["hand"])]
	var score: float = 45.0 if card.is_spell() else 50.0 + card.def.tier
	var slot: int = CoreUtil.to_int(action["slot"])
	if slot >= 0:
		score -= slot * 0.1
	var target: Unit = player.find_uid(CoreUtil.to_int(action["target"]))
	if target != null:
		score += target.attack() * 0.001
	return score


func _buy_score(session: GameSession, player: PlayerState, action: Dictionary) -> float:
	var spell: bool = CoreUtil.to_bool(action["spell"])
	var shop: Array[StringName] = player.shop_spells if spell else player.shop_units
	var card: UnitDef = session.library.get_card(shop[CoreUtil.to_int(action["index"])])
	if spell:
		return 20.0 if player.board_count() > 0 else -1.0
	var held: int = 0
	var units_in_hand: int = 0
	for unit: Unit in player.all_cards():
		if unit.def.id == card.id and not unit.golden:
			held += 1
		if unit.slot < 0 and not unit.is_spell():
			units_in_hand += 1
	var room: bool = player.board_count() + units_in_hand < session.geometry.slot_count
	var weakest: Unit = _weakest(player)
	if not room and (weakest == null or _worth(card) <= _unit_worth(weakest) + 5.0):
		return 15.0 * held if held > 0 else -1.0
	return 40.0 + _worth(card) * 0.1 + 15.0 * held


func _sell_score(player: PlayerState, slot: int) -> float:
	if not player.empty_slots().is_empty():
		return -1.0
	var weakest: Unit = _weakest(player)
	if weakest == null or weakest.slot != slot:
		return -1.0
	for unit: Unit in player.hand:
		if not unit.is_spell() and _unit_worth(unit) > _unit_worth(weakest):
			return 35.0
	return -1.0


static func _weakest(player: PlayerState) -> Unit:
	var weakest: Unit = null
	for unit: Unit in player.board_units():
		if weakest == null or _unit_worth(unit) < _unit_worth(weakest):
			weakest = unit
	return weakest
