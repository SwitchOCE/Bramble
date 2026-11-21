class_name Recruit
extends RefCounted
## The Recruit Phase (rulebook chapters 3-7): start of turn, the player's actions, end of turn,
## triples. Actions are JSON-shaped dictionaries, so bots, tests and the UI use one path:
##   {"type": "buy", "spell": bool, "index": int, "target": int}       4.2
##   {"type": "sell", "hand": int} or {"type": "sell", "slot": int}                      4.3
##   {"type": "play", "hand": int, "slot": int, "target": int}   7.2, 6.1.5; "target" is a uid,
##     a slot or a shop index by Mechanic.Target, -1 for none
##   {"type": "move", "from": int, "to": int}           8.3.3 (swaps when "to" is taken)
##   {"type": "refresh"}  {"type": "freeze"}  {"type": "upgrade"}       4.4, 4.5, 4.6
##   {"type": "pick", "index": int, "target": int}      6.2 (the only action while choosing)
##   {"type": "ability", "uid": int, "mechanic": id, "target": int}   3.3.1 a unit's ability
##   {"type": "to_hand", "slot": int}               7.2.4-7.2.5
##   {"type": "end_turn"}                               3.4
## Buy/pick target -1 means the recruited unit itself; omit it to choose after gaining.
## A pick that will wait must omit the target.
##   {"type": "recruit_target", "target": uid} resolves that pending choice.
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
func start_turn(player: PlayerState, report: FightReport = null) -> void:
	player.turn_ended = false
	for unit: Unit in player.all_cards() + player.waiting_pile:
		unit.worked_this_turn = false
	var used: Array[Unit] = []
	player.gold += _rules().income(player, session.round_number, used) + player.gold_next_turn
	for source: Unit in used:
		player.mark_worked(source)
	player.gold_next_turn = 0
	if session.round_number >= 2:
		player.turns_waited += 1
	player.refreshes_paid = 0
	player.freezes_used = 0
	for unit: Unit in player.all_cards() + player.waiting_pile:
		unit.turn_counters.clear()
	_fill_shop(player)
	player.frozen = false
	_log(player, {"type": "turn_start", "gold": player.gold, "shop": _shop_view(player)})
	var ctx := RecruitContext.new(session, self, player)
	notify(ctx, &"on_start_of_turn", [report])
	_settle(player)


## 3.4.1 in order: End of Turn triggers, "this turn" ends, the unfrozen shop clears.
## Gold is kept (4.1.2). Every Discover still open or waiting, including one an End of Turn
## trigger opens, is resolved with its first option.
func end_turn(player: PlayerState) -> void:
	if player.turn_ended:
		return
	_resolve_discovers(player)
	var ctx := RecruitContext.new(session, self, player)
	notify(ctx, &"on_end_of_turn", [])
	_resolve_discovers(player)
	_settle(player)
	# Settling End of Turn gifts can form a golden that needs a Recruit target.
	_resolve_discovers(player)
	for unit: Unit in player.all_cards() + player.waiting_pile:
		unit.stats.end_turn()
	if not player.frozen:
		_clear_shop(player)
	player.turn_ended = true
	_log(player, {"type": "turn_end", "gold": player.gold, "frozen": player.frozen})


# --- Actions -------------------------------------------------------------------------------------


func act(player: PlayerState, action: Dictionary) -> String:
	if not player.alive or player.turn_ended:
		return "not in a Recruit Phase"
	var kind: String = CoreUtil.to_text(action.get("type", ""))
	if not player.recruit_choices.is_empty() and kind != "recruit_target":
		return "choose a recruit target first"
	if not player.discover_options.is_empty() and kind not in ["pick", "recruit_target"]:
		return "choose a Discover option first"
	var error: String = ""
	match kind:
		"buy":
			error = _buy(
				player,
				CoreUtil.to_bool(action.get("spell", false)),
				CoreUtil.to_int(action.get("index", -1)),
				CoreUtil.to_int(action.get("target", -2))
			)
		"sell":
			error = _sell(
				player,
				CoreUtil.to_int(action.get("slot", -1)),
				CoreUtil.to_int(action.get("hand", -1))
			)
		"to_hand":
			error = _to_hand(player, CoreUtil.to_int(action.get("slot", -1)))
		"play":
			error = _play(
				player,
				CoreUtil.to_int(action.get("hand", -1)),
				CoreUtil.to_int(action.get("slot", -1)),
				CoreUtil.to_int(action.get("target", -1))
			)
		"recruit_target":
			error = _choose_recruit_target(player, CoreUtil.to_int(action.get("target", -1)))
		"move":
			error = _move(
				player,
				CoreUtil.to_int(action.get("from", -1)),
				CoreUtil.to_int(action.get("to", -1))
			)
		"ability":
			error = _use_ability(
				player,
				CoreUtil.to_int(action.get("uid", -1)),
				StringName(CoreUtil.to_text(action.get("mechanic", ""))),
				CoreUtil.to_int(action.get("target", -1))
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
			return _pick(player, action)
		"end_turn":
			end_turn(player)
			return ""
	return "unknown action '%s'" % kind


## 4.2: buy a unit or spell from the shop into the hand.
func _buy(player: PlayerState, spell: bool, index: int, target: int) -> String:
	var shop: Array[StringName] = player.shop_spells if spell else player.shop_units
	if index < 0 or index >= shop.size() or shop[index] == PlayerState.NO_CARD:
		return "no card in that shop slot"
	if player.hand.size() >= _rules().hand_limit(player):
		return "hand is full"
	var card: UnitDef = session.library.get_card(shop[index])
	var used: Array[Unit] = []
	var price: int = (
		_rules().spell_price(player, card, used)
		if spell
		else _rules().unit_price(player, card, used)
	)
	if player.gold < price:
		return "not enough gold"
	var error: String = _gain_target_error(player, card, target)
	if error != "":
		return error
	player.gold -= price
	for source: Unit in used:
		player.mark_worked(source)
	shop[index] = PlayerState.NO_CARD
	var unit: Unit = session.new_unit(card, false)
	unit.bought_copies = 1
	_log(player, {"type": "buy", "uid": unit.uid, "id": String(card.id), "price": price})
	_gain(player, unit, target)
	_settle(player)
	return ""


## 4.3.7 units sell from hand or board through the same listener path.
func _sell(player: PlayerState, slot: int, hand: int = -1) -> String:
	var unit: Unit
	if hand >= 0:
		if slot >= 0 or hand >= player.hand.size():
			return "no unit at that hand position"
		unit = player.hand[hand]
		if unit.is_spell():
			return "spells can't be sold"
	else:
		if not session.geometry.is_valid(slot) or player.board[slot] == null:
			return "no unit in that slot"
		unit = player.board[slot]
	var value: int = _rules().sell_value(player, unit)
	player.gold += value
	if hand >= 0:
		player.hand.remove_at(hand)
	else:
		player.remove_from_board(unit)
	unit.slot = slot
	_log(
		player,
		{
			"type": "sell",
			"uid": unit.uid,
			"id": String(unit.def.id),
			"slot": slot,
			"gold": value,
			"bought": unit.bought_copies > 0
		}
	)
	var ctx := RecruitContext.new(session, self, player)
	for bound: BoundMechanic in unit.hooks():
		ctx.invoke(unit, bound, &"on_sold")
	notify(ctx, &"on_any_sold", [unit])
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
	var kind: Mechanic.Target = play_target_of(card)
	var target: Unit = (
		player.find_uid(target_uid) if kind == Mechanic.Target.FRIENDLY_UNIT else null
	)
	player.hand.remove_at(hand_index)
	var ctx := RecruitContext.new(session, self, player)
	ctx.target_index = target_uid if kind != Mechanic.Target.NONE else -1
	if card.is_spell():
		_cast(ctx, card, target)
		return ""
	player.place(card, slot)
	_log(player, {"type": "play", "uid": card.uid, "id": String(card.def.id), "slot": slot})
	_settle(player)
	return ""


func _cast(ctx: RecruitContext, spell: Unit, target: Unit) -> void:
	var player: PlayerState = ctx.player
	_log(
		player,
		{
			"type": "cast",
			"uid": spell.uid,
			"id": String(spell.def.id),
			"target_uid": target.uid if target != null else -1,
			"target": ctx.target_index,
		}
	)
	for bound: BoundMechanic in spell.mechanics:
		bound.mechanic.on_played(ctx, spell, target, bound.params)
	_settle(player)


## 7.2.1-7.2.2 a unit needs an empty slot; a card that aims needs a target of its kind when one
## exists (a friendly unit, a slot, a shop unit), and a spell that aims can't be cast without.
func _play_error(player: PlayerState, card: Unit, slot: int, target: int) -> String:
	if not card.is_spell() and (not session.geometry.is_valid(slot) or player.board[slot] != null):
		return "choose an empty slot"
	var kind: Mechanic.Target = play_target_of(card)
	if kind == Mechanic.Target.NONE:
		return "" if target < 0 else "this card has no target"
	var choices: Array[int] = targets_for(player, kind, card)
	if target < 0:
		return "choose a target" if card.is_spell() or not choices.is_empty() else ""
	return "" if choices.has(target) else "not a valid target"


## What playing this card aims at: the first of its mechanics that aims decides.
func play_target_of(card: Unit) -> Mechanic.Target:
	if not card.is_spell():
		return Mechanic.Target.NONE
	for bound: BoundMechanic in card.mechanics:
		var kind: Mechanic.Target = bound.mechanic.play_target(bound.params)
		if kind != Mechanic.Target.NONE:
			return kind
	return Mechanic.Target.NONE


## Spell and ability targets: friendly board uids (other than the source), board slots,
## or filled unit shop indexes. Recruit effects use recruit_targets, which also includes hand.
func targets_for(player: PlayerState, kind: Mechanic.Target, card: Unit) -> Array[int]:
	var out: Array[int] = []
	match kind:
		Mechanic.Target.FRIENDLY_UNIT:
			for unit: Unit in player.board_units():
				if unit != card:
					out.append(unit.uid)
		Mechanic.Target.SLOT:
			for slot: int in session.geometry.slot_count:
				out.append(slot)
		Mechanic.Target.SHOP_UNIT:
			for i: int in player.shop_units.size():
				if player.shop_units[i] != PlayerState.NO_CARD:
					out.append(i)
	return out


## 3.3.1 use a board unit's ability: up to its uses this turn, paying its cost.
func _use_ability(player: PlayerState, uid: int, mechanic_id: StringName, target: int) -> String:
	var unit: Unit = player.find_uid(uid)
	var bound: BoundMechanic = _ability_of(unit, mechanic_id)
	if bound == null:
		return "no such ability on your board"
	var error: String = ability_error(player, unit, bound)
	if error != "":
		return error
	var kind: Mechanic.Target = bound.mechanic.ability_target(bound.params)
	if kind != Mechanic.Target.NONE and not targets_for(player, kind, unit).has(target):
		return "not a valid target"
	var cost: int = bound.mechanic.ability_cost(bound.params)
	var key: StringName = _ability_key(mechanic_id)
	player.gold -= cost
	unit.turn_counters[key] = unit.turn_counter(key) + 1
	_log(
		player,
		{
			"type": "ability",
			"uid": unit.uid,
			"mechanic": String(mechanic_id),
			"target": target,
			"cost": cost
		}
	)
	var ctx := RecruitContext.new(session, self, player)
	ctx.target_index = target if kind != Mechanic.Target.NONE else -1
	var target_unit: Unit = null
	if kind == Mechanic.Target.FRIENDLY_UNIT:
		target_unit = player.find_uid(target)
	player.mark_worked(unit)
	ctx.invoke(unit, bound, &"on_ability", [target_unit])
	_settle(player)
	return ""


## Why a board unit's ability can't be used now ("" when it can), before a target is chosen.
func ability_error(player: PlayerState, unit: Unit, bound: BoundMechanic) -> String:
	if unit.turn_counter(_ability_key(bound.id)) >= bound.mechanic.ability_uses(bound.params):
		return "already used this turn"
	if not bound.mechanic.ability_usable(player, unit, bound.params):
		return "can't be used from here"
	if player.gold < bound.mechanic.ability_cost(bound.params):
		return "not enough gold"
	var kind: Mechanic.Target = bound.mechanic.ability_target(bound.params)
	if kind != Mechanic.Target.NONE and targets_for(player, kind, unit).is_empty():
		return "nothing to target"
	return ""


func _ability_of(unit: Unit, mechanic_id: StringName) -> BoundMechanic:
	if unit == null or unit.slot < 0:
		return null
	for bound: BoundMechanic in unit.hooks():
		if bound.id == mechanic_id and bound.mechanic.has_ability():
			return bound
	return null


static func _ability_key(mechanic_id: StringName) -> StringName:
	return StringName("ability:%s" % mechanic_id)


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
	refresh_auras(player)
	return ""


## 7.2.4/7.2.5: a free zone move, never an acquisition or a replay trigger.
func _to_hand(player: PlayerState, slot: int) -> String:
	var error: String = to_hand_error(player, slot)
	if error != "":
		return error
	var unit: Unit = player.board[slot]
	player.remove_from_board(unit)
	player.hand.append(unit)
	_log(player, {"type": "to_hand", "uid": unit.uid, "id": String(unit.def.id), "slot": slot})
	refresh_auras(player)
	return ""


func to_hand_error(player: PlayerState, slot: int) -> String:
	if not session.geometry.is_valid(slot) or player.board[slot] == null:
		return "no unit in that slot"
	if player.board[slot].worked_this_turn:
		return "Worked this turn: stays for the fight."
	if player.hand.size() >= _rules().hand_limit(player):
		return "hand is full"
	return ""


## 4.4.1-4.4.3 paid refresh: new cards in every shop slot; unfreezes.
func _refresh(player: PlayerState) -> String:
	var used: Array[Unit] = []
	var cost: int = _rules().refresh_cost(player, used)
	if player.gold < cost:
		return "not enough gold"
	player.gold -= cost
	for source: Unit in used:
		player.mark_worked(source)
	# 4.4.5: a refresh made free by an effect doesn't advance the paid counter.
	if cost > 0:
		player.refreshes_paid += 1
	player.frozen = false
	_clear_shop(player)
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
	var used: Array[Unit] = []
	var cost: int = _rules().upgrade_cost(player, used)
	if cost < 0:
		return "already at the top tier"
	if player.gold < cost:
		return "not enough gold"
	player.gold -= cost
	for source: Unit in used:
		player.mark_worked(source)
	player.tier += 1
	player.turns_waited = 0
	_log(player, {"type": "upgrade", "tier": player.tier, "cost": cost})
	return ""


## 6.2 take one Discover option and close the offer. The pick is Created (4.3.2).
func _pick(player: PlayerState, action: Dictionary) -> String:
	var index: int = CoreUtil.to_int(action.get("index", -1))
	if index < 0 or index >= player.discover_options.size():
		return "no such Discover option"
	if action.has("target") and gain_waits(player):
		return "choose a recruit target when the card joins your hand"
	var target: int = CoreUtil.to_int(action.get("target", -2))
	var card: UnitDef = session.library.get_card(player.discover_options[index])
	var error: String = _gain_target_error(player, card, target)
	if error != "":
		return error
	player.discover_options.clear()
	var unit: Unit = session.new_unit(card, false)
	_log(player, {"type": "pick", "uid": unit.uid, "id": String(unit.def.id)})
	_gain(player, unit, target)
	_settle(player)
	# A waiting Discover with no eligible units is skipped for the next one.
	while player.discover_options.is_empty() and not player.discover_queue.is_empty():
		var next: Vector2i = player.discover_queue.pop_front()
		offer_discover(player, next.x, next.y)
	return ""


func _resolve_discovers(player: PlayerState) -> void:
	while not player.discover_options.is_empty() or not player.recruit_choices.is_empty():
		if not player.recruit_choices.is_empty():
			var unit: Unit = player.recruit_choices.pop_front()
			_recruit_unit(player, unit, -1)
			_settle(player)
		else:
			var pick: Dictionary = {"index": 0}
			if not gain_waits(player):
				pick["target"] = -1
			_pick(player, pick)


# --- Pieces mechanics use (through RecruitContext) -----------------------------------------------


## 6.2.1-6.2.3: up to N different units, drawn by their fixed weights.
## With one already shown, this one waits its turn and is drawn when that one is picked.
func offer_discover(player: PlayerState, min_tier: int, max_tier: int) -> void:
	if not player.discover_options.is_empty():
		player.discover_queue.append(Vector2i(min_tier, max_tier))
		_log(player, {"type": "discover_queued", "waiting": player.discover_queue.size()})
		return
	var options: Array[StringName] = []
	for _i: int in _rules().discover_options(player):
		var card_id: StringName = session.unit_odds.draw(
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
func summon(
	ctx: RecruitContext,
	card_id: StringName,
	source_slot: int,
	own_slot_first: bool = false,
	golden: bool = false
) -> Unit:
	var player: PlayerState = ctx.player
	var slot: int = session.geometry.summon_slot(player.occupied(), source_slot, own_slot_first)
	if slot < 0 or not session.library.has(card_id):
		_log(player, {"type": "summon_failed", "id": String(card_id)})
		return null
	var unit: Unit = session.new_unit(session.library.get_card(card_id), golden)
	player.place(unit, slot)
	refresh_auras(player)
	var event: Dictionary = unit.view()
	event["type"] = "summon"
	_log(player, event)
	return unit


## Runs a listener hook for every board unit in reading order, then the player's standing
## mechanics with unit = null. Arguments go between the unit and the params.
func notify(ctx: RecruitContext, hook: StringName, args: Array) -> void:
	for unit: Unit in ctx.player.board_units():
		for bound: BoundMechanic in unit.hooks():
			ctx.invoke(unit, bound, hook, args)
	for bound: BoundMechanic in ctx.player.standing:
		ctx.invoke(null, bound, hook, args)


## A death effect resolving in the Recruit Phase, from where the unit stands (Mechanic
## .on_recruit_death), as many times as Q_DEATH_EFFECT_TIMES says (asked through modify_int).
func run_death_effects(ctx: RecruitContext, unit: Unit) -> void:
	var times: int = maxi(1, ctx.ask(Mechanic.Q_DEATH_EFFECT_TIMES, 1))
	for _time: int in times:
		for bound: BoundMechanic in unit.hooks():
			ctx.invoke(unit, bound, &"on_recruit_death")


## Gains made by an action's effects queue behind older waiting cards, even if it freed space.
func gain_waits(player: PlayerState) -> bool:
	return not player.waiting_pile.is_empty() or player.hand.size() >= _rules().hand_limit(player)


## 7.1.2/7.2.6: an ordinary gained card recruits only when it enters the hand.
## Returns whether it entered the hand immediately.
func _gain(player: PlayerState, unit: Unit, target: int = -2) -> bool:
	var waits: bool = gain_waits(player)
	if waits:
		player.waiting_pile.append(unit)
	else:
		player.hand.append(unit)
	_log_gain(player, unit)
	# Owner, 18 Nov: "Only the golden fires." The completing copy merges without recruiting.
	if not waits and not _completes_triple(player, unit):
		_recruit_unit(player, unit, target)
	return not waits


func _log_gain(player: PlayerState, unit: Unit) -> void:
	_log(player, {"type": "gain", "uid": unit.uid, "id": String(unit.def.id)})


## Fill vacancies in gain order. During a merge, the golden fills its reserved place before
## the Recruit hooks run, so any cards those hooks give are gained after the joining cards.
func _admit_waiting(player: PlayerState, golden: Unit = null) -> void:
	var limit: int = _rules().hand_limit(player) - int(golden != null)
	var recruits: Array[Unit] = []
	while player.hand.size() < limit and not player.waiting_pile.is_empty():
		var card: Unit = player.waiting_pile.pop_front()
		player.hand.append(card)
		_log(player, {"type": "waiting_join", "uid": card.uid, "id": String(card.def.id)})
		if not _completes_triple(player, card):
			recruits.append(card)
	if golden != null:
		player.hand.append(golden)
		_log_gain(player, golden)
		recruits.append(golden)
	for unit: Unit in recruits:
		_recruit_unit(player, unit)


## Called after insertion. Several gains may wait for the enclosing action to settle:
## each third normal copy completes a triple; a later fourth/fifth copy still recruits.
func _completes_triple(player: PlayerState, gained: Unit) -> bool:
	if gained.is_spell() or gained.golden or not gained.def.combines:
		return false
	var copies: int = 0
	for unit: Unit in player.all_cards():
		if not unit.golden and unit.def.id == gained.def.id:
			copies += 1
	return copies >= 3 and copies % 3 == 0


## 7.2.3/7.2.6 unit effects use their own hook; spells still use on_played when cast.
static func recruit_target_of(card: UnitDef, registry: MechanicRegistry) -> Mechanic.Target:
	var effect: BoundMechanic = targeted_recruit(card, registry)
	return effect.mechanic.recruit_target(effect.params) if effect != null else Mechanic.Target.NONE


static func targeted_recruit(card: UnitDef, registry: MechanicRegistry) -> BoundMechanic:
	if not card.is_spell():
		for spec: MechanicSpec in card.mechanics:
			var bound: BoundMechanic = registry.bind(spec, false, false)
			if bound.mechanic.recruit_target(bound.params) != Mechanic.Target.NONE:
				return bound
	return null


## The selectable UIDs, in hand order for an effect restricted to the hand. `source` is the unit
## whose effect it is, once it exists.
static func recruit_targets(
	player: PlayerState, effect: BoundMechanic = null, source: Unit = null
) -> Array[int]:
	var out: Array[int] = []
	var hand_only: bool = (
		effect != null
		and effect.mechanic.recruit_target(effect.params) == Mechanic.Target.HAND_UNIT
	)
	for unit: Unit in player.hand if hand_only else player.all_cards():
		if unit.is_spell():
			continue
		if effect == null or effect.mechanic.accepts_recruit_target(unit, source):
			out.append(unit.uid)
	return out


func _gain_target_error(player: PlayerState, card: UnitDef, target: int) -> String:
	if target < -1:
		return ""
	var effect: BoundMechanic = targeted_recruit(card, session.registry)
	if effect == null:
		return "" if target == -1 else "this card has no recruit target"
	return (
		""
		if target == -1 or recruit_targets(player, effect).has(target)
		else "not a valid recruit target"
	)


func _recruit_unit(player: PlayerState, unit: Unit, target: int = -2) -> void:
	if unit.is_spell():
		return
	var effect: BoundMechanic = targeted_recruit(unit.def, session.registry)
	var chosen: Unit = player.find_uid(target) if target >= 0 else unit
	if target < 0 and effect != null:
		var hand_only: bool = (
			effect.mechanic.recruit_target(effect.params) == Mechanic.Target.HAND_UNIT
		)
		var choices: int = recruit_targets(player, effect, unit).size()
		if target < -1 and choices > (1 if hand_only else 0):
			player.recruit_choices.append(unit)
			return
		if hand_only:
			chosen = null  # The effect picks from the left of the hand.
	var ctx := RecruitContext.new(session, self, player)
	ctx.recruit_source = unit
	for bound: BoundMechanic in unit.mechanics:
		ctx.invoke(unit, bound, &"on_recruited", [chosen])


func _choose_recruit_target(player: PlayerState, target: int) -> String:
	if player.recruit_choices.is_empty():
		return "no recruit target to choose"
	var source: Unit = player.recruit_choices[0]
	var effect: BoundMechanic = targeted_recruit(source.def, session.registry)
	if not recruit_targets(player, effect, source).has(target):
		return "not a valid recruit target"
	var unit: Unit = player.recruit_choices.pop_front()
	_recruit_unit(player, unit, target)
	_settle(player)
	return ""


# --- Shop -----------------------------------------------------------------------------------------


## Fills empty shop slots (4.5.2 a frozen shop keeps its cards), sized by 6.1.1's query.
func _fill_shop(player: PlayerState) -> void:
	_fill(player.shop_units, _rules().shop_units(player), session.unit_odds, player)
	_fill(player.shop_spells, _rules().shop_spells(player), session.spell_odds, player)


func _fill(shop: Array[StringName], size: int, odds: ShopOdds, player: PlayerState) -> void:
	while shop.size() > size:
		shop.pop_back()
	while shop.size() < size:
		shop.append(PlayerState.NO_CARD)
	for i: int in size:
		if shop[i] == PlayerState.NO_CARD:
			shop[i] = odds.draw(1, player.tier, shop_rng(player))


func _clear_shop(player: PlayerState) -> void:
	player.shop_units.fill(PlayerState.NO_CARD)
	player.shop_spells.fill(PlayerState.NO_CARD)


func _shop_view(player: PlayerState) -> Dictionary:
	return {
		"units": player.shop_units.map(func(c: StringName) -> String: return String(c)),
		"spells": player.shop_spells.map(func(c: StringName) -> String: return String(c)),
	}


# --- Triples and upkeep ---------------------------------------------------------------------------


## After action effects resolve, waiting cards join and triples form (7.1.2, 7.3.1-7.3.2).
func _settle(player: PlayerState) -> void:
	if not player.waiting_pile.is_empty() and player.hand.size() < _rules().hand_limit(player):
		# A joining Recruit sees the auras and slot effects of the updated board.
		refresh_auras(player)
	while true:
		_admit_waiting(player)
		if not player.recruit_choices.is_empty():
			var source: Unit = player.recruit_choices[0]
			var effect: BoundMechanic = targeted_recruit(source.def, session.registry)
			if not recruit_targets(player, effect, source).is_empty():
				break
			# Another hook or target choice can use the last eligible hand recipient.
			player.recruit_choices.pop_front()
			_recruit_unit(player, source, -1)
		elif not _combine_one(player):
			break
	refresh_auras(player)


## 7.3.1 three copies of one non-golden unit across board and hand become one golden.
func _combine_one(player: PlayerState) -> bool:
	var copies: Dictionary = {}
	var order: Array[StringName] = []
	for unit: Unit in player.hand + player.board_units():
		if unit.golden or unit.is_spell() or not unit.def.combines:
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
	golden.copies = 0
	golden.counters.clear()  # The copies contribute their remaining Supply.
	var perm := Vector2i.ZERO
	var turn := Vector2i.ZERO
	for unit: Unit in three:
		golden.worked_this_turn = golden.worked_this_turn or unit.worked_this_turn
		golden.copies += unit.copies
		golden.bought_copies += unit.bought_copies
		perm += Vector2i(unit.stats.perm_attack, unit.stats.perm_health)
		turn += Vector2i(unit.stats.turn_attack, unit.stats.turn_health)
		for key: Variant in unit.counters:
			golden.counters[key] = golden.counter(StringName(str(key))) + unit.counters[key]
		for bound: BoundMechanic in unit.mechanics:
			if bound.granted and bound.params.to_dict().is_empty():
				golden.grant(session.registry, bound.id)
			elif bound.granted:
				golden.mechanics.append(bound)
		if unit.slot >= 0:
			vacated.append(unit.slot)
			player.remove_from_board(unit)
		else:
			player.hand.erase(unit)
	# 7.3.4 floors the merged modifiers at formation, after buffs and debuffs offset.
	# Floor the lasting sum too; the temporary layer is the difference, so its expiry
	# preserves permanent buffs without leaving compensation for expired debuffs behind.
	golden.stats.perm_attack = maxi(0, perm.x)
	golden.stats.perm_health = maxi(0, perm.y)
	golden.stats.turn_attack = maxi(0, perm.x + turn.x) - golden.stats.perm_attack
	golden.stats.turn_health = maxi(0, perm.y + turn.y) - golden.stats.perm_health
	if player.hand.size() < _rules().hand_limit(player) or vacated.is_empty():
		# The golden takes one place in the merge. Older gains fill any net vacancies.
		_admit_waiting(player, golden)
	else:
		# 7.3.7: the golden takes the first vacated slot when hand has no room.
		vacated.sort()
		player.place(golden, vacated[0])
		_recruit_unit(player, golden)
	# 7.3.6: every formation grants its spell now, through the ordinary gain path.
	var reward: Unit = session.new_unit(
		session.library.get_card(UnitLibrary.TRIPLE_REWARD_ID), false
	)
	_gain(player, reward)
	_log(
		player,
		{
			"type": "triple",
			"uid": golden.uid,
			"id": String(golden.def.id),
			"slot": golden.slot,
			"reward_uid": reward.uid
		}
	)


## 12.2.1 auras apply only from board units and standing mechanics, and are recalculated
## whenever the board changes; slot effects (8.5) are recalculated with them. A board unit shows
## its slot's Renown too, as it will start the next fight there. Public so a mechanic that
## changes what an aura reads (a player number, a heap) can call it.
func refresh_auras(player: PlayerState) -> void:
	for unit: Unit in player.all_cards():
		unit.stats.aura_attack = 0
		unit.stats.aura_health = 0
		unit.stats.renown = 0
		unit.aura_mechanics = []
	var board: Array[Unit] = player.board_units()
	for unit: Unit in board:
		var here: SlotState = player.slots[unit.slot]
		unit.stats.renown = here.renown
	# As in a fight (FightAuras): a second pass on the totals when an aura read a unit's numbers.
	var view: AuraContext = _aura_pass(player, board)
	if view.read_stats:
		_aura_pass(player, board)


func _aura_pass(player: PlayerState, board: Array[Unit]) -> AuraContext:
	var view := AuraContext.new()
	view.geometry = session.geometry
	view.counters = player.counters
	view.heaps = player.heaps
	view.defs.resize(session.geometry.slot_count)
	view.unit_counters.resize(session.geometry.slot_count)
	view.stats.resize(session.geometry.slot_count)
	for unit: Unit in board:
		view.defs[unit.slot] = unit.def
		view.unit_counters[unit.slot] = unit.counters
		view.stats[unit.slot] = Vector3i(unit.attack(), unit.health(), unit.health())
	for unit: Unit in board:
		unit.stats.aura_attack = 0
		unit.stats.aura_health = 0
		unit.aura_mechanics = []
		for keyword: StringName in player.slots[unit.slot].keywords:
			_give_aura_keyword(unit, keyword)
	var grants: Dictionary = {}
	for source: Unit in board:
		for bound: BoundMechanic in source.mechanics:
			if bound.mechanic.has_aura():
				_apply_aura(view, bound, source.slot, board, grants)
	for bound: BoundMechanic in player.standing:
		if bound.mechanic.has_aura():
			_apply_aura(view, bound, -1, board, grants)
	for unit: Unit in board:
		var given: Array = grants.get(unit.uid, [])
		unit.aura_mechanics.append_array(session.registry.bind_grants(given))
	return view


func _apply_aura(
	view: AuraContext,
	bound: BoundMechanic,
	source_slot: int,
	board: Array[Unit],
	grants: Dictionary
) -> void:
	for target: Unit in board:
		var gain: Vector2i = bound.mechanic.aura(view, source_slot, target.slot, bound.params)
		target.stats.aura_attack += gain.x
		target.stats.aura_health += gain.y
		for keyword: StringName in bound.mechanic.aura_keywords(
			view, source_slot, target.slot, bound.params
		):
			_give_aura_keyword(target, keyword)
		var given: Array = bound.mechanic.aura_grants(view, source_slot, target.slot, bound.params)
		if not given.is_empty():
			var list: Array = grants.get(target.uid, [])
			list.append_array(given)
			grants[target.uid] = list


func _give_aura_keyword(unit: Unit, keyword: StringName) -> void:
	if session.registry.has(keyword) and not unit.has_mechanic(keyword):
		unit.aura_mechanics.append(session.registry.bind(MechanicSpec.new(keyword), false, true))


func _log(player: PlayerState, event: Dictionary) -> void:
	event["player"] = player.id
	session.log_event(event)
