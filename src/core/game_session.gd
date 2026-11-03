class_name GameSession
extends RefCounted
## A full game: the human (player 0) and the bots in one live lobby (SPEC section 9), round by
## round until one player is left (rulebook 1.1.3, 10.2.3) or round 50 ends (2.1.3).
## The UI calls the recruit actions for the human, then end_turn().

const HUMAN_ID: int = 0
const GAME_OVER: String = "The game is over"

var _seed: int = 0
var _library: UnitLibrary
var _config: GameConfig
var _pool: UnitPool
var _rules: RecruitRules
var _players: Array[PlayerState] = []
## Player id -> Bot (the human too when the config's human_bot names a personality).
var _bots: Dictionary = {}
var _round: int = 0
var _pairings: Array = []
var _over: bool = false
var _pairing_rng: RandomNumberGenerator
var _placement_rng: RandomNumberGenerator
## The ghost (2.1.2): the most recently eliminated player's board and tier.
var _ghost_board: Array = []
var _ghost_tier: int = 1
var _last_combat: Dictionary = {}
## dev_skip_turn: the human's pairing has no fight this round.
var _skip_human_fight: bool = false


static func create(game_seed: int, library: UnitLibrary, config: GameConfig = null) -> GameSession:
	var session := GameSession.new()
	session._seed = game_seed
	session._library = library
	session._config = config if config != null else GameConfig.defaults()
	session._setup()
	session._start_round()
	return session


func get_seed() -> int:
	return _seed


## 6.1 recruit state for the human.
func get_state() -> Dictionary:
	var human: PlayerState = _players[HUMAN_ID]
	var shop: Array = []
	for unit: RecruitUnit in human.shop:
		var view: Dictionary = unit.view()
		view["cost"] = _config.get_int("unit_cost")
		shop.append(view)
	var hand: Array = []
	for unit: RecruitUnit in human.hand:
		hand.append(unit.view())
	var board: Array = []
	for unit: RecruitUnit in human.board:
		if unit == null:
			board.append(null)
		else:
			board.append(unit.view())
	var summary: Variant = null
	if not _last_combat.is_empty():
		summary = {
			"round": _last_combat["round"],
			"opponent_id": _last_combat["opponent_id"],
			"winner": _last_combat["winner"],
			"damage": _last_combat["damage"],
		}
	return {
		"round": _round,
		"phase": "game_over" if _over else "recruit",
		"player_id": HUMAN_ID,
		"gold": human.gold,
		"tier": human.tier,
		"tier_up_cost":
		CoreUtil.int_or_null(
			(
				_rules.base_upgrade_cost(human.tier)
				if human.tier >= UnitLibrary.TIERS
				else human.upgrade_cost
			),
			-1
		),
		"refresh_cost": _rules.refresh_cost(human),
		"paid_refreshes": human.paid_refreshes,
		"frozen": human.frozen,
		"freezes_left": human.freezes_left,
		"shop": shop,
		"shop_size": _rules.shop_size(human.tier),
		"hand": hand,
		"hand_limit": _config.get_int("hand_limit"),
		"board": board,
		"health": human.health,
		"next_opponent_id": _opponent_of(HUMAN_ID),
		"last_combat": summary,
		"standings": get_standings(),
		"placement": CoreUtil.int_or_null(human.placement, 0),
	}


## 6.4, sorted by player id.
func get_standings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for player: PlayerState in _players:
		out.append(player.standing())
	return out


func is_over() -> bool:
	return _over


func buy(shop_index: int) -> String:
	return _human_action() if _human_action() != "" else _rules.buy(_human(), shop_index)


func sell(slot: int) -> String:
	return _human_action() if _human_action() != "" else _rules.sell(_human(), slot)


func play(hand_index: int, slot: int) -> String:
	return _human_action() if _human_action() != "" else _rules.play(_human(), hand_index, slot)


func move(from_slot: int, to_slot: int) -> String:
	return _human_action() if _human_action() != "" else _rules.move(_human(), from_slot, to_slot)


func refresh() -> String:
	return _human_action() if _human_action() != "" else _rules.refresh(_human())


func toggle_freeze() -> String:
	return _human_action() if _human_action() != "" else _rules.toggle_freeze(_human())


func tier_up() -> String:
	return _human_action() if _human_action() != "" else _rules.tier_up(_human())


## Ends the human's Recruit Phase, runs the bots' turns, every fight, damage, eliminations and
## the next round's start (3.4, 3.5, chapter 10).
func end_turn() -> String:
	if _over:
		return GAME_OVER
	for player: PlayerState in _living():
		if _bots.has(player.id):
			var bot: Bot = _bots[player.id]
			bot.play_turn(player, _rules, _round)
		_rules.end_phase(player)
	_run_fights()
	_eliminate()
	if not _over:
		_start_round()
	return ""


## The human's last fight: {"round", "opponent_id", "winner", "damage", "events"}; {} before
## the first. "winner" is 0 when the human won, 1 when the opponent did, -1 for a tie.
func get_last_combat() -> Dictionary:
	return _last_combat.duplicate()


## Dev: adds (or with a negative amount removes) gold; never below 0.
func dev_add_gold(amount: int) -> String:
	var error: String = _human_action()
	if error == "":
		_human().gold = maxi(0, _human().gold + amount)
	return error


## Dev: a Created unit in hand, not from the pool (5.3.6); it can complete a triple (7.3.3).
func dev_spawn_to_hand(def_id: String, golden: bool = false) -> String:
	var error: String = _human_action()
	if error != "":
		return error
	var unit_def: Dictionary = _library.get_unit(def_id)
	if unit_def.is_empty():
		return "No such unit"
	var player: PlayerState = _human()
	if player.hand.size() >= _config.get_int("hand_limit"):
		return "Hand is full"
	var unit := RecruitUnit.make(unit_def, _rules.new_iid(), golden)
	unit.origin = RecruitUnit.ORIGIN_CREATED
	player.hand.append(unit)
	_rules.check_triples(player)
	return ""


## Dev: sets the tier (1-6) and the upgrade cost to that tier's base cost.
func dev_set_tier(tier: int) -> String:
	var error: String = _human_action()
	if error != "":
		return error
	if tier < 1 or tier > UnitLibrary.TIERS:
		return "No such tier"
	_human().tier = tier
	_human().upgrade_cost = _rules.base_upgrade_cost(tier)
	return ""


## Dev: ends the turn like end_turn, but the human's pairing doesn't fight (no damage either
## way, and get_last_combat() is {} for the round); everyone else plays and fights as normal.
func dev_skip_turn() -> String:
	var error: String = _human_action()
	if error != "":
		return error
	_skip_human_fight = true
	error = end_turn()
	_skip_human_fight = false
	return error


func _setup() -> void:
	_pool = UnitPool.create(_library, _config)
	_rules = RecruitRules.create(_library, _config, _pool)
	_pairing_rng = _derive("pairing")
	_placement_rng = _derive("placement")
	var personalities: PackedStringArray = _config.get_strings("bots")
	var count: int = maxi(2, _config.get_int("players"))
	for id: int in count:
		var player := PlayerState.new()
		player.id = id
		player.is_human = id == HUMAN_ID
		if player.is_human:
			player.name = "You"
			player.personality = "human"
		else:
			var personality: String = Bot.BALANCED
			if not personalities.is_empty():
				personality = personalities[(id - 1) % personalities.size()]
			player.personality = personality
			player.name = "Bot %d (%s)" % [id, personality]
			_bots[id] = Bot.create(personality)
		player.shop_rng = _derive("shop:%d" % id)
		player.bot_rng = _derive("bot:%d" % id)
		_rules.setup_player(player)
		_players.append(player)
	var human_bot: String = _config.get_string("human_bot")
	if human_bot != "":
		_bots[HUMAN_ID] = Bot.create(human_bot)


## A separate RNG stream per purpose, derived from the game seed (SPEC section 7).
func _derive(label: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%d|%s" % [_seed, label]).hash()
	return rng


## 3.2.1 for every living player, after the round's pairings are known (2.3.3).
func _start_round() -> void:
	_round += 1
	_pairings = Matchmaking.pair(_living(), _pairing_rng)
	for player: PlayerState in _living():
		_rules.start_phase(player, _round)


func _run_fights() -> void:
	var cap: int = _damage_cap()
	for pair: Variant in _pairings:
		var ids: Array = pair
		if _skip_human_fight and ids.has(HUMAN_ID):
			_last_combat = {}
			continue
		_fight(CoreUtil.to_int(ids[0]), CoreUtil.to_int(ids[1]), cap)


## 10.1.4: 0 means no cap.
func _damage_cap() -> int:
	if _living().size() <= _config.get_int("damage_cap_off_at_alive"):
		return 0
	return _config.get_int_at("damage_cap_by_turn", _round - 1)


func _fight(id_a: int, id_b: int, cap: int) -> void:
	var a: PlayerState = _players[id_a]
	var b: PlayerState = null if id_b == Matchmaking.GHOST else _players[id_b]
	var boards: Array = [a.combat_board(), _ghost_board if b == null else b.combat_board()]
	var tiers: Array[int] = [a.tier, _ghost_tier if b == null else b.tier]
	var player_ids: Array[int] = [id_a, id_b]
	var rng: RandomNumberGenerator = _derive("fight:%d:%d:%d" % [_round, id_a, id_b])
	var result: Dictionary = Combat.create(_library, _config, rng).run(
		boards, tiers, player_ids, cap
	)
	var winner: int = result["winner"]
	var damage: int = result["damage"]
	if winner == 1:
		a.health -= damage
	elif winner == 0 and b != null:
		b.health -= damage
	a.last_result = _result_word(winner, 0)
	_remember(a, id_b)
	if b != null:
		b.last_result = _result_word(winner, 1)
		_remember(b, id_a)
	if id_a == HUMAN_ID:
		_last_combat = {
			"round": _round,
			"opponent_id": id_b,
			"winner": winner,
			"damage": damage,
			"events": result["events"],
		}


static func _result_word(winner: int, side: int) -> String:
	if winner < 0:
		return "tie"
	return "win" if winner == side else "loss"


static func _remember(player: PlayerState, opponent: int) -> void:
	player.recent_opponents.append(opponent)
	while player.recent_opponents.size() > 3:
		player.recent_opponents.remove_at(0)


## 10.2: eliminations after all fights; same-round eliminations placed by health (10.2.2).
func _eliminate() -> void:
	var alive_before: int = _living().size()
	var out: Array[PlayerState] = []
	for player: PlayerState in _living():
		if player.health <= 0:
			out.append(player)
	_sort_by_health(out, true)
	for index: int in out.size():
		var player: PlayerState = out[index]
		player.alive = false
		player.placement = alive_before - index
		if index == out.size() - 1:
			_ghost_board = player.combat_board()
			_ghost_tier = player.tier
		_rules.return_everything(player)
	var living: Array[PlayerState] = _living()
	if living.size() <= 1:
		for player: PlayerState in living:
			player.placement = 1
		_over = true
	elif not _players[HUMAN_ID].alive and not _bots.has(HUMAN_ID):
		_over = true
	elif _round >= _config.get_int("max_rounds"):
		_sort_by_health(living, false)
		for index: int in living.size():
			living[index].placement = index + 1
		_over = true


## Sorts by health (ascending or descending); ties are broken at random (10.2.2, 2.1.3).
func _sort_by_health(players: Array[PlayerState], ascending: bool) -> void:
	var keys: Dictionary = {}
	for player: PlayerState in players:
		keys[player.id] = _placement_rng.randi()
	players.sort_custom(
		func(x: PlayerState, y: PlayerState) -> bool:
			if x.health != y.health:
				return x.health < y.health if ascending else x.health > y.health
			return CoreUtil.to_int(keys[x.id]) < CoreUtil.to_int(keys[y.id])
	)


func _living() -> Array[PlayerState]:
	var out: Array[PlayerState] = []
	for player: PlayerState in _players:
		if player.alive:
			out.append(player)
	return out


func _opponent_of(player_id: int) -> int:
	for pair: Variant in _pairings:
		var ids: Array = pair
		if CoreUtil.to_int(ids[0]) == player_id:
			return CoreUtil.to_int(ids[1])
		if CoreUtil.to_int(ids[1]) == player_id:
			return CoreUtil.to_int(ids[0])
	return Matchmaking.GHOST


func _human() -> PlayerState:
	return _players[HUMAN_ID]


## "" when the human may act now, else the reason.
func _human_action() -> String:
	if _over or not _human().alive:
		return GAME_OVER
	return ""
