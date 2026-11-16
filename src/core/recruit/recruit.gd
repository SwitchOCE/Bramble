class_name Recruit
extends RefCounted
## The Recruit Phase (rulebook chapters 3-7): start of turn, the player's actions, end of turn,
## triples. Actions are JSON-shaped dictionaries, so bots, tests and the UI use one path:
##   {"type": "buy", "spell": bool, "index": int}       4.2
##   {"type": "sell", "slot": int}                      4.3
##   {"type": "play", "hand": int, "slot": int, "target": uid or -1}   7.2, 6.1.5
##   {"type": "move", "from": int, "to": int}           8.3.3 (swaps when "to" is taken)
##   {"type": "refresh"}  {"type": "freeze"}  {"type": "upgrade"}       4.4, 4.5, 4.6
##   {"type": "pick", "index": int}                     6.2 (the only action while choosing)
##   {"type": "end_turn"}                               3.4
## act() returns "" when the action was taken, otherwise why it is illegal (and changes nothing).

## The session owns this object, so it holds the session weakly (no reference cycle).
var session: GameSession:
	get:
		var owner: GameSession = _session_ref.get_ref()
		return owner
var _session_ref: WeakRef
var _shop_rng: Dictionary = {}
var _discover_rng: Dictionary = {}
var _effect_rng: Dictionary = {}


func _init(game: GameSession) -> void:
	_session_ref = weakref(game)


func _stream(cache: Dictionary, label: String, player: PlayerState) -> Rng:
	if not cache.has(player.id):
		cache[player.id] = Rng.derive(session.seed_value, "%s:%d" % [label, player.id])
	var stream: Rng = cache[player.id]
	return stream


func shop_rng(player: PlayerState) -> Rng:
	return _stream(_shop_rng, "shop", player)


func discover_rng(player: PlayerState) -> Rng:
	return _stream(_discover_rng, "discover", player)


func effect_rng(player: PlayerState) -> Rng:
	return _stream(_effect_rng, "recruit_effect", player)


func _rules() -> Rules:
	return session.rules


# --- Start and end of the Recruit Phase --------------------------------------------------------


## 3.2.1 in order: gold, upgrade discount, refresh counter, shop refill, start-of-turn triggers.
func start_turn(player: PlayerState) -> void:
	player.turn_ended = false
	player.gold += _rules().income(player, session.round_number)
	if session.round_number >= 2:
		player.turns_waited += 1
	player.refreshes_paid = 0
	player.freezes_used = 0
	_fill_shop(player)
	player.frozen = false
	_log(player, {"type": "turn_start", "gold": player.gold, "shop": _shop_view(player)})
	var ctx := RecruitContext.new(session, self, player)
	for unit: Unit in player.board_units():
		for bound: BoundMechanic in unit.mechanics:
			bound.mechanic.on_start_of_turn(ctx, unit, bound.params)
	_settle(player)


## 3.4.1 in order: End of Turn triggers, "this turn" ends, unfrozen shop returns to the pool.
## Gold is kept (4.1.2). Every Discover still open or waiting, including one an End of Turn
## trigger opens, is resolved with its first option.
func end_turn(player: PlayerState) -> void:
	if player.turn_ended:
		return
	_resolve_discovers(player)
	var ctx := RecruitContext.new(session, self, player)
	for unit: Unit in player.board_units():
		for bound: BoundMechanic in unit.mechanics:
			bound.mechanic.on_end_of_turn(ctx, unit, bound.params)
	_resolve_discovers(player)
	_settle(player)
	for unit: Unit in player.all_cards():
		unit.stats.end_turn()
	if not player.frozen:
		_return_shop(player)
	player.turn_ended = true
	_log(player, {"type": "turn_end", "gold": player.gold, "frozen": player.frozen})


# --- Actions -------------------------------------------------------------------------------------


func act(player: PlayerState, action: Dictionary) -> String:
	if not player.alive or player.turn_ended:
		return "not in a Recruit Phase"
	var kind: String = CoreUtil.to_text(action.get("type", ""))
	if not player.discover_options.is_empty() and kind != "pick":
		return "choose a Discover option first"
	var error: String = ""
	match kind:
		"buy":
			error = _buy(
				player,
				CoreUtil.to_bool(action.get("spell", false)),
				CoreUtil.to_int(action.get("index", -1))
			)
		"sell":
			error = _sell(player, CoreUtil.to_int(action.get("slot", -1)))
		"play":
			error = _play(
				player,
				CoreUtil.to_int(action.get("hand", -1)),
				CoreUtil.to_int(action.get("slot", -1)),
				CoreUtil.to_int(action.get("target", -1))
			)
		"move":
			error = _move(
				player,
				CoreUtil.to_int(action.get("from", -1)),
				CoreUtil.to_int(action.get("to", -1))
			)
		_:
			error = _act_simple(player, kind, action)
	return error


func _act_simple(player: PlayerState, kind: String, action: Dictionary) -> String:
	match kind:
		"refresh":
			return _refresh(player)
		"freeze":
			return _freeze(player)
		"upgrade":
			return _upgrade(player)
		"pick":
			return _pick(player, CoreUtil.to_int(action.get("index", -1)))
		"end_turn":
			end_turn(player)
			return ""
	return "unknown action '%s'" % kind


## 4.2: buy a unit or spell from the shop into the hand.
func _buy(player: PlayerState, spell: bool, index: int) -> String:
	var shop: Array[StringName] = player.shop_spells if spell else player.shop_units
	if index < 0 or index >= shop.size() or shop[index] == PlayerState.NO_CARD:
		return "no card in that shop slot"
	if player.hand.size() >= _rules().hand_limit(player):
		return "hand is full"
	var card: UnitDef = session.library.get_card(shop[index])
	var price: int = (
		_rules().spell_price(player, card) if spell else _rules().unit_price(player, card)
	)
	if player.gold < price:
		return "not enough gold"
	player.gold -= price
	shop[index] = PlayerState.NO_CARD
	var unit: Unit = session.new_unit(card, false)
	unit.bought_copies = 1
	unit.pool_copies = 1
	player.hand.append(unit)
	_log(player, {"type": "buy", "uid": unit.uid, "id": String(card.id), "price": price})
	_settle(player)
	return ""


## 4.3: sell a board unit; its pool copies return (5.3.4-5.3.5).
func _sell(player: PlayerState, slot: int) -> String:
	if not session.geometry.is_valid(slot) or player.board[slot] == null:
		return "no unit in that slot"
	var unit: Unit = player.board[slot]
	var value: int = _rules().sell_value(player, unit)
	player.gold += value
	player.remove_from_board(unit)
	session.units.give_back(unit.def.id, unit.pool_copies)
	_log(player, {"type": "sell", "uid": unit.uid, "id": String(unit.def.id), "gold": value})
	var ctx := RecruitContext.new(session, self, player)
	for bound: BoundMechanic in unit.mechanics:
		bound.mechanic.on_sold(ctx, unit, bound.params)
	_settle(player)
	return ""


## 7.2 play a unit into a chosen empty slot, or 6.1.5 cast a spell.
func _play(player: PlayerState, hand_index: int, slot: int, target_uid: int) -> String:
	if hand_index < 0 or hand_index >= player.hand.size():
		return "no card at that hand position"
	var card: Unit = player.hand[hand_index]
	var error: String = _play_error(player, card, slot, target_uid)
	if error != "":
		return error
	var target: Unit = player.find_uid(target_uid) if target_uid >= 0 else null
	player.hand.remove_at(hand_index)
	if card.is_spell():
		_cast(player, card, target)
		return ""
	player.place(card, slot)
	_log(player, {"type": "play", "uid": card.uid, "id": String(card.def.id), "slot": slot})
	_refresh_auras(player)
	var ctx := RecruitContext.new(session, self, player)
	for bound: BoundMechanic in card.mechanics:
		bound.mechanic.on_played(ctx, card, target, bound.params)
	if card.from_triple:
		card.from_triple = false
		_gain(
			player, session.new_unit(session.library.get_card(UnitLibrary.TRIPLE_REWARD_ID), false)
		)
	_settle(player)
	return ""


func _cast(player: PlayerState, spell: Unit, target: Unit) -> void:
	_log(
		player,
		{
			"type": "cast",
			"uid": spell.uid,
			"id": String(spell.def.id),
			"target_uid": target.uid if target != null else -1
		}
	)
	var ctx := RecruitContext.new(session, self, player)
	for bound: BoundMechanic in spell.mechanics:
		bound.mechanic.on_played(ctx, spell, target, bound.params)
	# The spell's pool copy returns once cast (5.3.7 read for spells; see README).
	session.spells.give_back(spell.def.id, spell.pool_copies)
	_settle(player)


## 7.2.1-7.2.2 a unit needs an empty slot; a card that aims needs another board unit as its
## target when one exists, and a spell that aims can't be cast without one.
func _play_error(player: PlayerState, card: Unit, slot: int, target_uid: int) -> String:
	var target: Unit = null
	if target_uid >= 0:
		target = player.find_uid(target_uid)
		if target == null or target.slot < 0 or target == card:
			return "target must be another unit on your board"
	var aims: bool = needs_target(card)
	if aims and target == null and (card.is_spell() or _has_target_for(player, card)):
		return "choose a target"
	if not card.is_spell() and (not session.geometry.is_valid(slot) or player.board[slot] != null):
		return "choose an empty slot"
	return ""


## Whether playing this card asks for a friendly target.
func needs_target(card: Unit) -> bool:
	for bound: BoundMechanic in card.mechanics:
		if bound.mechanic.play_target(bound.params) == Mechanic.Target.FRIENDLY_UNIT:
			return true
	return false


func _has_target_for(player: PlayerState, card: Unit) -> bool:
	for unit: Unit in player.board_units():
		if unit != card:
			return true
	return false


## 8.3.3 move to an empty slot or swap, free.
func _move(player: PlayerState, from_slot: int, to_slot: int) -> String:
	var geometry: BoardGeometry = session.geometry
	if not geometry.is_valid(from_slot) or player.board[from_slot] == null:
		return "no unit to move"
	if not geometry.is_valid(to_slot) or to_slot == from_slot:
		return "choose another slot"
	var moving: Unit = player.board[from_slot]
	var other: Unit = player.board[to_slot]
	player.board[from_slot] = null
	player.place(moving, to_slot)
	if other != null:
		player.place(other, from_slot)
	_log(player, {"type": "move", "uid": moving.uid, "from": from_slot, "to": to_slot})
	_refresh_auras(player)
	return ""


## 4.4.1-4.4.3 paid refresh: new cards in every shop slot; unfreezes.
func _refresh(player: PlayerState) -> String:
	var cost: int = _rules().refresh_cost(player)
	if player.gold < cost:
		return "not enough gold"
	player.gold -= cost
	player.refreshes_paid += 1
	player.frozen = false
	_return_shop(player)
	_fill_shop(player)
	_log(player, {"type": "refresh", "cost": cost, "shop": _shop_view(player)})
	return ""


## 4.5.1 toggle the freeze, up to the limit per turn.
func _freeze(player: PlayerState) -> String:
	if player.freezes_used >= _rules().freeze_limit(player):
		return "no freezes left this turn"
	player.freezes_used += 1
	player.frozen = not player.frozen
	_log(player, {"type": "freeze", "frozen": player.frozen})
	return ""


## 4.6 upgrade the shop tier; 4.6.4 the discount restarts; 4.6.5 the shop doesn't refill.
func _upgrade(player: PlayerState) -> String:
	var cost: int = _rules().upgrade_cost(player)
	if cost < 0:
		return "already at the top tier"
	if player.gold < cost:
		return "not enough gold"
	player.gold -= cost
	player.tier += 1
	player.turns_waited = 0
	_log(player, {"type": "upgrade", "tier": player.tier, "cost": cost})
	return ""


## 6.2 take one Discover option; the others return (5.3.3). The pick is Created (4.3.2).
func _pick(player: PlayerState, index: int) -> String:
	if index < 0 or index >= player.discover_options.size():
		return "no such Discover option"
	var options: Array[StringName] = player.discover_options.duplicate()
	player.discover_options.clear()
	for i: int in options.size():
		if i != index:
			session.units.give_back(options[i])
	var unit: Unit = session.new_unit(session.library.get_card(options[index]), false)
	unit.pool_copies = 1
	_log(player, {"type": "pick", "uid": unit.uid, "id": String(unit.def.id)})
	_gain(player, unit)
	_settle(player)
	# A waiting Discover whose draw finds nothing (an empty pool) is skipped for the next one.
	while player.discover_options.is_empty() and not player.discover_queue.is_empty():
		var next: Vector2i = player.discover_queue.pop_front()
		offer_discover(player, next.x, next.y)
	return ""


func _resolve_discovers(player: PlayerState) -> void:
	while not player.discover_options.is_empty():
		_pick(player, 0)


# --- Pieces mechanics use (through RecruitContext) -----------------------------------------------


## 6.2.1-6.2.3: up to N different units, each drawn by 6.1.3 and out of the pool while shown.
## With one already shown, this one waits its turn and is drawn when that one is picked.
func offer_discover(player: PlayerState, min_tier: int, max_tier: int) -> void:
	if not player.discover_options.is_empty():
		player.discover_queue.append(Vector2i(min_tier, max_tier))
		_log(player, {"type": "discover_queued", "waiting": player.discover_queue.size()})
		return
	var options: Array[StringName] = []
	for _i: int in _rules().discover_options(player):
		var card_id: StringName = session.units.draw(
			min_tier, max_tier, discover_rng(player), options
		)
		if card_id == &"":
			break
		options.append(card_id)
	player.discover_options = options
	_log(
		player,
		{
			"type": "discover",
			"options": options.map(func(c: StringName) -> String: return String(c))
		}
	)


## 8.4.3, 8.4.7: a Recruit Phase summon, Created. Null and logged when the board is full.
func summon(player: PlayerState, card_id: StringName, source_slot: int) -> Unit:
	var slot: int = session.geometry.summon_slot(player.occupied(), source_slot, false)
	if slot < 0 or not session.library.has(card_id):
		_log(player, {"type": "summon_failed", "id": String(card_id)})
		return null
	var unit: Unit = session.new_unit(session.library.get_card(card_id), false)
	player.place(unit, slot)
	_log(player, {"type": "summon", "uid": unit.uid, "id": String(card_id), "slot": slot})
	_refresh_auras(player)
	return unit


## 7.1.2: a card gained while the hand is full is lost (its pool copies go back).
func _gain(player: PlayerState, unit: Unit) -> bool:
	if player.hand.size() >= _rules().hand_limit(player):
		var pool: CardPool = session.spells if unit.is_spell() else session.units
		pool.give_back(unit.def.id, unit.pool_copies)
		_log(player, {"type": "card_lost", "id": String(unit.def.id)})
		return false
	player.hand.append(unit)
	_log(player, {"type": "gain", "uid": unit.uid, "id": String(unit.def.id)})
	return true


# --- Shop -----------------------------------------------------------------------------------------


## Fills empty shop slots (4.5.2 a frozen shop keeps its cards), sized by 6.1.1's query.
func _fill_shop(player: PlayerState) -> void:
	_fill(player.shop_units, _rules().shop_units(player), session.units, player)
	_fill(player.shop_spells, _rules().shop_spells(player), session.spells, player)


func _fill(shop: Array[StringName], size: int, pool: CardPool, player: PlayerState) -> void:
	while shop.size() > size:
		var extra: StringName = shop.pop_back()
		pool.give_back(extra)
	while shop.size() < size:
		shop.append(PlayerState.NO_CARD)
	for i: int in size:
		if shop[i] == PlayerState.NO_CARD:
			shop[i] = pool.draw(1, player.tier, shop_rng(player))


## 5.3.2 shown cards go back to the pool.
func _return_shop(player: PlayerState) -> void:
	for i: int in player.shop_units.size():
		session.units.give_back(player.shop_units[i])
		player.shop_units[i] = PlayerState.NO_CARD
	for i: int in player.shop_spells.size():
		session.spells.give_back(player.shop_spells[i])
		player.shop_spells[i] = PlayerState.NO_CARD


func _shop_view(player: PlayerState) -> Dictionary:
	return {
		"units": player.shop_units.map(func(c: StringName) -> String: return String(c)),
		"spells": player.shop_spells.map(func(c: StringName) -> String: return String(c)),
	}


# --- Triples and upkeep ---------------------------------------------------------------------------


## After every action: triples form (7.3.1-7.3.2, after all summons) and auras are recomputed.
func _settle(player: PlayerState) -> void:
	while _combine_one(player):
		pass
	_refresh_auras(player)


## 7.3.1 three copies of one non-golden unit across board and hand become one golden.
func _combine_one(player: PlayerState) -> bool:
	var copies: Dictionary = {}
	var order: Array[StringName] = []
	for unit: Unit in player.hand + player.board_units():
		if unit.golden or unit.is_spell():
			continue
		if not copies.has(unit.def.id):
			copies[unit.def.id] = [] as Array[Unit]
			order.append(unit.def.id)
		var list: Array[Unit] = copies[unit.def.id]
		list.append(unit)
	for card_id: StringName in order:
		var list: Array[Unit] = copies[card_id]
		if list.size() >= 3:
			_combine(player, list.slice(0, 3))
			return true
	return false


func _combine(player: PlayerState, three: Array[Unit]) -> void:
	var vacated: Array[int] = []
	var golden: Unit = session.new_unit(three[0].def, true)
	golden.from_triple = true
	var perm := Vector2i.ZERO
	var turn := Vector2i.ZERO
	for unit: Unit in three:
		golden.bought_copies += unit.bought_copies
		golden.pool_copies += unit.pool_copies
		perm += Vector2i(unit.stats.perm_attack, unit.stats.perm_health)
		turn += Vector2i(unit.stats.turn_attack, unit.stats.turn_health)
		for bound: BoundMechanic in unit.mechanics:
			if bound.granted:
				golden.grant(session.registry, bound.id)
		if unit.slot >= 0:
			vacated.append(unit.slot)
			player.remove_from_board(unit)
		else:
			player.hand.erase(unit)
	# 7.3.4 keeps every buff and debuff, and each stat is at least the golden base.
	golden.stats.perm_attack = maxi(0, perm.x)
	golden.stats.perm_health = maxi(0, perm.y)
	golden.stats.turn_attack = turn.x
	golden.stats.turn_health = turn.y
	if player.hand.size() < _rules().hand_limit(player) or vacated.is_empty():
		player.hand.append(golden)
	else:
		# 7.3.7 into the first vacated slot. It is never played, so its Triple Reward is gained
		# now, into a full hand: lost by 7.1.2.
		vacated.sort()
		player.place(golden, vacated[0])
		golden.from_triple = false
		_gain(
			player, session.new_unit(session.library.get_card(UnitLibrary.TRIPLE_REWARD_ID), false)
		)
	_log(
		player,
		{"type": "triple", "uid": golden.uid, "id": String(golden.def.id), "slot": golden.slot}
	)


## 12.2.1 auras apply only from board units and are recalculated whenever the board changes.
func _refresh_auras(player: PlayerState) -> void:
	for unit: Unit in player.all_cards():
		unit.stats.aura_attack = 0
		unit.stats.aura_health = 0
	for source: Unit in player.board_units():
		for bound: BoundMechanic in source.mechanics:
			if not bound.mechanic.has_aura():
				continue
			for target: Unit in player.board_units():
				var gain: Vector2i = bound.mechanic.aura(
					session.geometry, source.slot, target.slot, bound.params
				)
				target.stats.aura_attack += gain.x
				target.stats.aura_health += gain.y


func _log(player: PlayerState, event: Dictionary) -> void:
	event["player"] = player.id
	session.log_event(event)
