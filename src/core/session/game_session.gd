class_name GameSession
extends RefCounted
## One lobby (chapters 1-3 and 10): 8 players, rounds of Recruit Phase then Combat Phase,
## damage, elimination, game end. Pure and headless: bots, tests and a UI drive it through
## start_round / act / end_turn / finish_round. A live lobby is this track's reading of the
## open async rule 2.1.5. No heroes or hero powers on this track.
## Round order:
##   start_round: round + 1, pairing (2.3; known during recruit, 2.3.3), ghost (2.1.2),
##     every living player's start of turn (3.2.1)
##   act / end_turn per player (3.3, 3.4)
##   finish_round: any open turn ends; every pair fights (9); loss damage (10.1); eliminations
##     after all fights (10.2.1-10.2.2); game end (10.2.3, 2.1.3)

var config: GameConfig
var rules: Rules
var geometry: BoardGeometry
var registry: MechanicRegistry
var library: UnitLibrary
var units: CardPool
var spells: CardPool
var recruit: Recruit
var players: Array[PlayerState] = []
var seed_value: int = 0
var round_number: int = 0
## This round's pairs: [a, b], b = Matchmaking.GHOST for the ghost.
var pairings: Array = []
## The game log: JSON-shaped events (see src/core/README.md).
var events: Array[Dictionary] = []
## Each fight of the game: {"round", "players", "result", "events", "after"} ("after": the game
## log's events from after_fight, what the fight changed on the real boards).
var fights: Array[Dictionary] = []
## False keeps only each fight's result (soaks and simulations).
var keep_fight_events: bool = true
var over: bool = false
## 2.1.2 the most recently eliminated player's board and tier.
var ghost_board: Array[Unit] = []
## The ghost's hand, for its Reserve units (a saved board carries its hand).
var ghost_hand: Array[Unit] = []
var ghost_tier: int = 1
var ghost_of: int = -1
## The ghost's player state, for its slot effects and heaps; its fights never write back.
var ghost_player: PlayerState
## The display table (ContentSet.display): id -> name, reminder, icon, hidden. Screens hide
## keywords and counters marked hidden.
var display: Dictionary = {}
var _next_uid: int = 1
var _rr_order: Array[int] = []
var _rr_index: int = 0
var _any_eliminated: bool = false


static func create(
	game_seed: int,
	card_library: UnitLibrary,
	mechanic_registry: MechanicRegistry,
	game_config: GameConfig = null,
	lobby_tribes: PackedStringArray = []
) -> GameSession:
	var session := GameSession.new()
	session.seed_value = game_seed
	session.config = game_config if game_config != null else GameConfig.new()
	session.rules = Rules.new(session.config)
	session.geometry = BoardGeometry.standard(session.config.front_slots, session.config.back_slots)
	session.registry = mechanic_registry
	session.library = card_library
	session.units = CardPool.create(
		card_library.pool_cards(false), session.config.unit_copies_by_tier, lobby_tribes
	)
	session.spells = CardPool.create(
		card_library.pool_cards(true), session.config.spell_copies_by_tier, lobby_tribes
	)
	session.recruit = Recruit.new(session)
	for player_id: int in session.config.players:
		session.players.append(
			PlayerState.create(
				player_id,
				session.geometry.slot_count,
				session.config.starting_health,
				session.config.starting_armor
			)
		)
		session._rr_order.append(player_id)
	Rng.derive(game_seed, "round_robin").shuffle(session._rr_order)
	return session


func new_unit(card: UnitDef, golden: bool) -> Unit:
	_next_uid += 1
	return Unit.create(card, _next_uid - 1, golden, registry, config.stat_max)


func log_event(event: Dictionary) -> void:
	if not event.has("round"):
		event["round"] = round_number
	events.append(event)


func player(player_id: int) -> PlayerState:
	return players[player_id]


func alive_players() -> Array[PlayerState]:
	var out: Array[PlayerState] = []
	for each: PlayerState in players:
		if each.alive:
			out.append(each)
	return out


func alive_ids() -> Array[int]:
	var out: Array[int] = []
	for each: PlayerState in alive_players():
		out.append(each.id)
	return out


# --- Round flow ---------------------------------------------------------------------------------


func start_round() -> void:
	if over:
		return
	round_number += 1
	pairings = _pair_round()
	log_event({"type": "round_start", "pairs": pairings.duplicate(true)})
	for each: PlayerState in alive_players():
		recruit.start_turn(each)


## 2.3.3 the opponent for this round: a player id, Matchmaking.GHOST, or -2 if not paired.
func opponent_of(player_id: int) -> int:
	for value: Variant in pairings:
		var pair: Array = value
		if CoreUtil.to_int(pair[0]) == player_id:
			return CoreUtil.to_int(pair[1])
		if CoreUtil.to_int(pair[1]) == player_id:
			return CoreUtil.to_int(pair[0])
	return -2


func act(player_id: int, action: Dictionary) -> String:
	return recruit.act(player(player_id), action)


func legal_actions(player_id: int) -> Array[Dictionary]:
	return LegalActions.of(self, player(player_id))


func end_turn(player_id: int) -> void:
	recruit.end_turn(player(player_id))


## Ends any open turn, fights every pair, deals damage, eliminates. Returns this round's fights.
func finish_round() -> Array[Dictionary]:
	var round_fights: Array[Dictionary] = []
	if over:
		return round_fights
	for each: PlayerState in alive_players():
		recruit.end_turn(each)
	for value: Variant in pairings:
		var pair: Array = value
		round_fights.append(_fight(CoreUtil.to_int(pair[0]), CoreUtil.to_int(pair[1])))
	_eliminate()
	_check_end()
	return round_fights


func _pair_round() -> Array:
	var ids: Array[int] = alive_ids()
	var pairs: Array = []
	if not _any_eliminated and ids.size() == _rr_order.size() and ids.size() % 2 == 0:
		pairs = Matchmaking.round_robin(_rr_order, _rr_index)
		_rr_index += 1
	else:
		var history: Dictionary = {}
		for each: PlayerState in players:
			history[each.id] = each.opponents
		pairs = Matchmaking.avoiding(ids, history, Rng.derive(seed_value, "pair:%d" % round_number))
	for value: Variant in pairs:
		var pair: Array = value
		var a: int = CoreUtil.to_int(pair[0])
		var b: int = CoreUtil.to_int(pair[1])
		player(a).opponents.append(b)
		if b != Matchmaking.GHOST:
			player(b).opponents.append(a)
	return pairs


func _fight(a: int, b: int) -> Dictionary:
	var is_ghost: bool = b == Matchmaking.GHOST
	var board_b: Array[Unit] = ghost_board if is_ghost else player(b).board
	var owner_b: PlayerState = ghost_player if is_ghost else player(b)
	var hand_b: Array[Unit] = ghost_hand if is_ghost else player(b).hand
	var fight_seed: int = Rng.hash32("%d|fight|%d|%d|%d" % [seed_value, round_number, a, b])
	var combat: Combat = Combat.create(geometry, config, registry, library, fight_seed)
	var result: Dictionary = combat.run(
		[player(a).board, board_b],
		[a, b],
		[player(a), owner_b],
		[true, not is_ghost],
		[player(a).hand, hand_b]
	)
	var winner: int = CoreUtil.to_int(result["winner"])
	var damage: int = 0
	var loser_id: int = -2
	if winner >= 0:
		var loser_side: int = 1 - winner
		loser_id = a if loser_side == 0 else b
		var starting: Array = result["starting"]
		var killed: Array = result["killed"]
		var winner_start: int = CoreUtil.to_int(starting[winner])
		var winner_killed: int = CoreUtil.to_int(killed[winner])
		var big: bool = winner_killed * 2 < winner_start
		if loser_id != Matchmaking.GHOST:
			var loser: PlayerState = player(loser_id)
			damage = rules.loss_damage(loser, round_number, big)
			_take_damage(loser, damage)
	var fight: Dictionary = {
		"round": round_number,
		"players": [a, b],
		"result": result,
		"loser": loser_id,
		"damage": damage,
		"events": combat.events if keep_fight_events else [],
	}
	fights.append(fight)
	var first_after: int = events.size()
	_after_fight(player(a), result, 0, b)
	if not is_ghost:
		_after_fight(player(b), result, 1, a)
	# What after_fight changed on the real boards, for the screen that shows the fight.
	fight["after"] = events.slice(first_after)
	log_event(
		{
			"type": "fight",
			"players": [a, b],
			"winner": winner,
			"loser": loser_id,
			"damage": damage,
			"reason": result["reason"]
		}
	)
	return fight


## Mechanic.after_fight on the player's real board, with what the fight showed.
func _after_fight(each: PlayerState, result: Dictionary, side: int, opponent: int) -> void:
	var report := FightReport.new()
	var winner: int = CoreUtil.to_int(result["winner"])
	report.outcome = 0 if winner < 0 else (1 if winner == side else -1)
	report.opponent = opponent
	var kept: Array = result["survivor_recruit_uids"]
	var mine: Array = kept[side]
	report.survivors.assign(mine)
	var deaths: Array = result["deaths"]
	report.deaths = CoreUtil.to_int(deaths[side])
	var outnumbered: Array = result["outnumbered_by"]
	report.outnumbered_by = CoreUtil.to_int(outnumbered[side])
	recruit.after_fight(each, report)


## Everything a screen needs for one player in one call: PlayerState.view() plus prices, the
## current opponent and the legal actions.
func view_for(player_id: int) -> Dictionary:
	var each: PlayerState = player(player_id)
	var out: Dictionary = each.view()
	var unit_prices: Array = []
	for card_id: StringName in each.shop_units:
		unit_prices.append(
			(
				-1
				if card_id == PlayerState.NO_CARD
				else rules.unit_price(each, library.get_card(card_id))
			)
		)
	var spell_prices: Array = []
	for card_id: StringName in each.shop_spells:
		spell_prices.append(
			(
				-1
				if card_id == PlayerState.NO_CARD
				else rules.spell_price(each, library.get_card(card_id))
			)
		)
	var sell: Array = []
	for unit: Unit in each.board:
		sell.append(-1 if unit == null else rules.sell_value(each, unit))
	out["costs"] = {
		"refresh": rules.refresh_cost(each),
		"upgrade": rules.upgrade_cost(each),
		"shop_units": unit_prices,
		"shop_spells": spell_prices,
		"sell": sell,
	}
	out["round"] = round_number
	out["opponent"] = opponent_of(player_id)
	out["legal_actions"] = legal_actions(player_id)
	out["display"] = display
	return out


## Gives every player a standing mechanic (a rule the whole lobby plays with, such as a heap
## every sale feeds). Call after create.
func give_standing(mechanic_id: StringName) -> void:
	for each: PlayerState in players:
		if not each.has_standing(mechanic_id):
			each.standing.append(registry.bind(MechanicSpec.new(mechanic_id), false, false))


## 10.1.5 armor first, then health.
func _take_damage(loser: PlayerState, amount: int) -> void:
	var absorbed: int = mini(loser.armor, amount)
	loser.armor -= absorbed
	loser.health -= amount - absorbed


## 10.2.1-10.2.2 after all fights; lower health places lower, ties at random. 5.3.8 their cards
## go back to the pool. 2.1.2 the best-placed of them becomes the ghost.
func _eliminate() -> void:
	var out: Array[PlayerState] = []
	for each: PlayerState in alive_players():
		if each.health <= 0:
			out.append(each)
	if out.is_empty():
		return
	var rng: Rng = Rng.derive(seed_value, "placement:%d" % round_number)
	rng.shuffle(out)
	out.sort_custom(func(x: PlayerState, y: PlayerState) -> bool: return x.health < y.health)
	var place: int = alive_players().size()
	var hands: Dictionary = {}
	for each: PlayerState in out:
		hands[each.id] = each.hand.duplicate()
		_retire(each, place)
		place -= 1
	var ghost: PlayerState = out[out.size() - 1]
	ghost_board = ghost.board.duplicate()
	var kept: Array = hands[ghost.id]
	ghost_hand.assign(kept)
	ghost_player = ghost
	ghost_tier = ghost.tier
	ghost_of = ghost.id
	_any_eliminated = true


func _retire(each: PlayerState, place: int) -> void:
	each.alive = false
	each.placement = place
	each.eliminated_round = round_number
	for card: Unit in each.all_cards():
		var pool: CardPool = spells if card.is_spell() else units
		pool.give_back(card.def.id, card.pool_copies)
	for card_id: StringName in each.shop_units:
		units.give_back(card_id)
	for card_id: StringName in each.shop_spells:
		spells.give_back(card_id)
	for card_id: StringName in each.discover_options:
		units.give_back(card_id)
	each.shop_units.clear()
	each.shop_spells.clear()
	each.discover_options.clear()
	each.discover_queue.clear()
	each.hand.clear()
	log_event({"type": "eliminated", "player": each.id, "placement": place, "health": each.health})


## 10.2.3 one player left; 2.1.3 the round limit places the rest by health plus armor.
func _check_end() -> void:
	var left: Array[PlayerState] = alive_players()
	if left.size() > 1 and round_number < config.round_limit:
		return
	var rng: Rng = Rng.derive(seed_value, "final_places")
	rng.shuffle(left)
	left.sort_custom(
		func(x: PlayerState, y: PlayerState) -> bool: return x.health + x.armor > y.health + y.armor
	)
	for i: int in left.size():
		left[i].placement = i + 1
	over = true
	log_event({"type": "game_end", "placements": placements()})


## player id -> place (1 = winner), once the game is over.
func placements() -> Dictionary:
	var out: Dictionary = {}
	for each: PlayerState in players:
		out[each.id] = each.placement
	return out
