class_name LegalActions
extends RefCounted
## Every action a player may take right now, in Recruit's action format. Bots and the UI choose
## from this list; Recruit.act checks the same rules, and the soak proves the two agree.


static func of(session: GameSession, player: PlayerState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not player.alive or player.turn_ended:
		return out
	if not player.discover_options.is_empty():
		for i: int in player.discover_options.size():
			out.append({"type": "pick", "index": i})
		return out
	_buys(session, player, out)
	for unit: Unit in player.board_units():
		out.append({"type": "sell", "slot": unit.slot})
	_plays(session, player, out)
	_moves(session, player, out)
	var rules: Rules = session.rules
	if player.gold >= rules.refresh_cost(player):
		out.append({"type": "refresh"})
	if player.freezes_used < rules.freeze_limit(player):
		out.append({"type": "freeze"})
	var upgrade: int = rules.upgrade_cost(player)
	if upgrade >= 0 and player.gold >= upgrade:
		out.append({"type": "upgrade"})
	out.append({"type": "end_turn"})
	return out


static func _buys(session: GameSession, player: PlayerState, out: Array[Dictionary]) -> void:
	if player.hand.size() >= session.rules.hand_limit(player):
		return
	for spell: bool in [false, true]:
		var shop: Array[StringName] = player.shop_spells if spell else player.shop_units
		for i: int in shop.size():
			if shop[i] == PlayerState.NO_CARD:
				continue
			var card: UnitDef = session.library.get_card(shop[i])
			var price: int = (
				session.rules.spell_price(player, card)
				if spell
				else session.rules.unit_price(player, card)
			)
			if player.gold >= price:
				out.append({"type": "buy", "spell": spell, "index": i})


static func _plays(session: GameSession, player: PlayerState, out: Array[Dictionary]) -> void:
	var targets: Array[int] = []
	for unit: Unit in player.board_units():
		targets.append(unit.uid)
	var empty: Array[int] = player.empty_slots()
	for i: int in player.hand.size():
		var card: Unit = player.hand[i]
		var aimed: bool = session.recruit.needs_target(card)
		var choices: Array[int] = [-1]
		if aimed and not targets.is_empty():
			choices = targets
		if card.is_spell():
			if aimed and targets.is_empty():
				continue
			for target: int in choices:
				out.append({"type": "play", "hand": i, "slot": -1, "target": target})
			continue
		for slot: int in empty:
			for target: int in choices:
				out.append({"type": "play", "hand": i, "slot": slot, "target": target})


static func _moves(session: GameSession, player: PlayerState, out: Array[Dictionary]) -> void:
	for unit: Unit in player.board_units():
		for slot: int in session.geometry.slot_count:
			if slot != unit.slot:
				out.append({"type": "move", "from": unit.slot, "to": slot})
