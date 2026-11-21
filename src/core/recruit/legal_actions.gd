class_name LegalActions
extends RefCounted
## Every action a player may take right now, in Recruit's action format. Bots and the UI choose
## from this list; Recruit.act checks the same rules, and the soak proves the two agree.


static func of(session: GameSession, player: PlayerState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not player.alive or player.turn_ended:
		return out
	if not player.recruit_choices.is_empty():
		var source: Unit = player.recruit_choices[0]
		var effect: BoundMechanic = Recruit.targeted_recruit(source.def, session.registry)
		for target: int in Recruit.recruit_targets(player, effect, source):
			out.append({"type": "recruit_target", "target": target})
		return out
	if not player.discover_options.is_empty():
		for i: int in player.discover_options.size():
			var pick: Dictionary = {"type": "pick", "index": i}
			if session.recruit.gain_waits(player):
				out.append(pick)
			else:
				var card: UnitDef = session.library.get_card(player.discover_options[i])
				_gains(session, player, card, pick, out)
		return out
	_buys(session, player, out)
	for unit: Unit in player.board_units():
		out.append({"type": "sell", "slot": unit.slot})
	for i: int in player.hand.size():
		if not player.hand[i].is_spell():
			out.append({"type": "sell", "hand": i})
	for unit: Unit in player.board_units():
		if session.recruit.to_hand_error(player, unit.slot) == "":
			out.append({"type": "to_hand", "slot": unit.slot})
	_plays(session, player, out)
	_abilities(session, player, out)
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
	var hand_room: bool = player.hand.size() < session.rules.hand_limit(player)
	var empty: Array[int] = player.empty_slots()
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
				var buy: Dictionary = {"type": "buy", "spell": spell, "index": i}
				if hand_room:
					_gains(session, player, card, buy, out)
				if not spell:
					for slot: int in empty:
						var on_board: Dictionary = buy.duplicate()
						on_board["slot"] = slot
						_gains(session, player, card, on_board, out)


static func _plays(session: GameSession, player: PlayerState, out: Array[Dictionary]) -> void:
	var recruit: Recruit = session.recruit
	for i: int in player.hand.size():
		var card: Unit = player.hand[i]
		if not card.is_spell():
			for slot: int in session.geometry.slot_count:
				var swap: bool = player.board[slot] != null
				if recruit.play_slot_error(player, slot, swap) == "":
					var play: Dictionary = {"type": "play", "hand": i, "slot": slot, "target": -1}
					if swap:
						play["swap"] = true
					out.append(play)
			continue
		var kind: Mechanic.Target = recruit.play_target_of(card)
		var choices: Array[int] = [-1]
		if kind != Mechanic.Target.NONE:
			var targets: Array[int] = recruit.targets_for(player, kind, card)
			if not targets.is_empty():
				choices = targets
			else:
				continue
		for target: int in choices:
			out.append({"type": "play", "hand": i, "slot": -1, "target": target})


## 3.3.1 every usable ability of a board unit, once per legal target.
static func _abilities(session: GameSession, player: PlayerState, out: Array[Dictionary]) -> void:
	var recruit: Recruit = session.recruit
	for unit: Unit in player.board_units():
		for bound: BoundMechanic in unit.hooks():
			if not bound.mechanic.has_ability() or recruit.ability_error(player, unit, bound) != "":
				continue
			var kind: Mechanic.Target = bound.mechanic.ability_target(bound.params)
			var choices: Array[int] = [-1]
			if kind != Mechanic.Target.NONE:
				choices = recruit.targets_for(player, kind, unit)
			for target: int in choices:
				out.append(
					{
						"type": "ability",
						"uid": unit.uid,
						"mechanic": String(bound.id),
						"target": target
					}
				)


static func _moves(session: GameSession, player: PlayerState, out: Array[Dictionary]) -> void:
	for unit: Unit in player.board_units():
		for slot: int in session.geometry.slot_count:
			if slot != unit.slot:
				out.append({"type": "move", "from": unit.slot, "to": slot})


## -1 selects the new unit itself before its uid exists; other targets are existing uids.
static func _gains(
	session: GameSession,
	player: PlayerState,
	card: UnitDef,
	want: Dictionary,
	out: Array[Dictionary]
) -> void:
	var targets: Array[int] = [-1]
	var effect: BoundMechanic = Recruit.targeted_recruit(card, session.registry)
	if effect != null:
		targets.append_array(Recruit.recruit_targets(player, effect))
	for target: int in targets:
		var action: Dictionary = want.duplicate()
		action["target"] = target
		out.append(action)
