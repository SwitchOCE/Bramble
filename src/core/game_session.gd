# gdlint:disable=max-public-methods
# One public method per player action and per state view.
class_name GameSession
extends RefCounted
## A full game: the human (player 0) and the bots in one live lobby (SPEC section 9), round by
## round until one player is left (rulebook 1.1.3, 10.2.3) or round 50 ends (2.1.3).
## The UI calls the recruit actions for the human, then end_turn().

const HUMAN_ID: int = 0
const CHOOSE_HERO: String = "Choose a hero first"
const GAME_OVER: String = "The game is over"

## QA hook (tools/checks/soak.gd): called after every fight with
## (round, player_id_a, player_id_b, result), where result is Combat.run's dictionary.
var fight_observer: Callable = Callable()
## QA hook (tools/sim/bench.gd): called after every bot turn with (player, round, microseconds).
var turn_observer: Callable = Callable()

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
## 5.2.4 this lobby's tribes; empty means all.
var _lobby_tribes: PackedStringArray = []
## The human's hero offer while it waits to be chosen (2.2.1).
var _hero_offer: PackedStringArray = []
var _log: GameLog = GameLog.new()
var _ghost_slots: Array = []
var _ghost_view: Array = []
var _ghost_rules: Dictionary = {}


static func create(game_seed: int, library: UnitLibrary, config: GameConfig = null) -> GameSession:
	var session := GameSession.new()
	session._seed = game_seed
	session._library = library
	session._config = config if config != null else GameConfig.defaults()
	session._setup()
	if session._hero_offer.is_empty():
		session._start_round()
	return session


func get_seed() -> int:
	return _seed


## 6.1 recruit state for the human, or for another player (a bot or a test reading the same view).
func get_state(player_id: int = HUMAN_ID) -> Dictionary:
	var human: PlayerState = _players[player_id]
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
	var spells: Array = []
	for item: HandItem in human.shop_spells:
		spells.append(item.view())
	var items: Array = []
	for item: HandItem in human.items:
		items.append(item.view())
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
		"phase": _phase_name(),
		"player_id": HUMAN_ID,
		"gold": human.gold,
		"tier": human.tier,
		"tier_up_cost":
		CoreUtil.int_or_null(
			(
				_rules.base_upgrade_cost(human.tier)
				if human.tier >= UnitLibrary.TIERS
				else _rules.tier_up_cost(human)
			),
			-1
		),
		"refresh_cost": _rules.refresh_cost(human),
		"paid_refreshes": human.paid_refreshes,
		"frozen": human.frozen,
		"freezes_left": human.freezes_left,
		"shop": shop,
		"shop_size": _rules.shop_size(human.tier, human),
		"shop_spells": spells,
		"hand_items": items,
		"pending_choice": _pending_view(human),
		"hero": _hero_view(human),
		"armor": human.armor,
		"free_refreshes": human.free_refreshes,
		"gold_next_turn": human.gold_next_turn,
		"gold_spent_turn": human.gold_spent_turn,
		"slot_effects": human.slot_effects.duplicate(true),
		"bands": _bands_view(human),
		"band_count": human.band_count(),
		"larder": human.larder(),
		"debt": human.debt,
		"buys_left": _rules.buys_left(human),
		"pending_passes": _passes_view(human),
		"lobby_tribes": Array(_lobby_tribes),
		"recruit_log": human.recruit_log.duplicate(),
		"hand": hand,
		"hand_limit": _config.get_int("hand_limit"),
		"board": board,
		"health": human.health,
		"next_opponent_id": _opponent_of(player_id),
		"next_opponent_last_board": _scouted_view(human),
		"next_opponent_last_slot_effects": _scouted_slots(human),
		"last_combat": summary,
		"standings": get_standings(),
		"placement": CoreUtil.int_or_null(human.placement, 0),
	}


## Per slot, whether it has a Rainbow band.
static func _bands_view(player: PlayerState) -> Array:
	var out: Array = []
	for iid: int in player.bands:
		out.append(iid != 0)
	return out


## Each Pass waiting for End of Turn, and where it lands if nothing changes.
static func _passes_view(player: PlayerState) -> Array:
	var out: Array = []
	for entry: Dictionary in player.pending_passes:
		var start: int = BoardUpkeep.pass_start(player, entry)
		(
			out
			. append(
				{
					"attack": entry["attack"],
					"health": entry["health"],
					"from_slot": start,
					"landing_slot": BoardGeometry.pass_landing(player.occupied(), start),
				}
			)
		)
	return out


func _phase_name() -> String:
	if _over:
		return "game_over"
	return "hero_choice" if not _hero_offer.is_empty() else "recruit"


## What the human must choose right now, or null: {"kind", "options": [views]}.
func _pending_view(human: PlayerState) -> Variant:
	if not _hero_offer.is_empty():
		var heroes: Array = []
		for id: String in _hero_offer:
			heroes.append(_hero_card(_library.get_hero(id)))
		return {"kind": "hero", "options": heroes}
	if not human.is_choosing():
		return null
	var choice: Dictionary = human.pending[0]
	var options: Array = []
	var ids: PackedStringArray = choice["options"]
	for id: String in ids:
		if CoreUtil.to_bool(choice["spells"]):
			options.append(HandItem.make(_library.get_card(id), 0).view())
		else:
			options.append(RecruitUnit.make(_library.get_unit(id), 0).view())
	return {"kind": choice["kind"], "options": options}


func _hero_view(player: PlayerState) -> Variant:
	if player.hero.is_empty():
		return null
	var view: Dictionary = _hero_card(player.hero)
	view["uses_left"] = player.power_uses_left
	view["usable"] = _rules.power_usable(player)
	return view


## The rule: everyone sees the next opponent's board as it fought last round, by slot. [] before
## the first fight.
static func _scouted_view(player: PlayerState) -> Array:
	if player.scout.is_empty():
		return []
	var views: Array = player.scout["views"]
	return views.duplicate(true)


## Rings and the like on the slots of that board, in the shape of the state's slot_effects. Separate
## from the units because a Ring can lie on an empty slot.
static func _scouted_slots(player: PlayerState) -> Array:
	if player.scout.is_empty():
		return []
	var slots: Array = player.scout["slots"]
	return slots.duplicate(true)


static func _hero_card(hero: Dictionary) -> Dictionary:
	var power: Dictionary = HeroRules.power_of(hero)
	return {
		"id": str(hero["id"]),
		"name": str(hero["name"]),
		"text": str(hero.get("text", "")),
		"kind": str(power.get("kind", HeroRules.PASSIVE)),
		"cost": CoreUtil.to_int(power.get("cost", 0)),
		"uses_per_turn": HeroRules.uses_per_turn(hero),
		"aim": str(power.get("aim", HandItem.AIM_NONE)),
		"armor": CoreUtil.to_int(hero.get("armor", 0)),
		"sample": CoreUtil.to_bool(hero.get("sample", false)),
	}


## The build a bot seat is following now; "" for a seat with none. For the bench's report.
func build_of(player_id: int) -> String:
	var bot: Bot = _bots.get(player_id)
	return bot.build_name() if bot != null else ""


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


## 4.2.5 buys a Tavern spell (index into the state's shop_spells).
func buy_spell(index: int) -> String:
	return _human_action() if _human_action() != "" else _rules.buy_spell(_human(), index)


## 6.1.5 plays a spell or item from hand (index into hand_items), aimed at a slot if it needs one.
func play_item(index: int, slot: int = -1) -> String:
	return _human_action() if _human_action() != "" else _rules.play_item(_human(), index, slot)


## 2.2.7 uses the hero's activated power.
func use_power(slot: int = -1) -> String:
	return _human_action() if _human_action() != "" else _rules.use_power(_human(), slot)


## Makes the waiting choice: the hero at the start of the game, or a Discover (6.2).
func choose(index: int) -> String:
	if not _hero_offer.is_empty():
		if index < 0 or index >= _hero_offer.size():
			return "No such option"
		HeroRules.assign(_human(), _library.get_hero(_hero_offer[index]))
		_hero_offer = PackedStringArray()
		_start_round()
		return ""
	if _over or not _human().alive:
		return GAME_OVER
	return _rules.choose(_human(), index)


## The heroes a player was offered (2.2.1), for the bench.
func hero_offer_of(player_id: int) -> PackedStringArray:
	return _players[player_id].hero_offer


## The rules this session plays by, for QA hooks (tools/checks/soak.gd).
func get_rules() -> RecruitRules:
	return _rules


## The review summary so far (docs/ideation/engine.md): boards by round, placements, gold spent,
## per-tribe stats. For the game-over screen and bots' evaluation.
func get_game_log() -> Dictionary:
	return _log.summary(_players, _lobby_tribes)


## Ends the human's Recruit Phase, runs the bots' turns, every fight, damage, eliminations and
## the next round's start (3.4, 3.5, chapter 10).
func end_turn() -> String:
	if _over:
		return GAME_OVER
	if not _hero_offer.is_empty():
		return CHOOSE_HERO
	if _human().is_choosing() and not _bots.has(HUMAN_ID):
		return RecruitRules.CHOOSE_FIRST
	for player: PlayerState in _living():
		if _bots.has(player.id):
			var bot: Bot = _bots[player.id]
			var started: int = Time.get_ticks_usec()
			bot.play_turn(player, _rules, _round)
			if turn_observer.is_valid():
				turn_observer.call(player, _round, Time.get_ticks_usec() - started)
		_rules.end_phase(player)
	for player: PlayerState in _living():
		player.remember_fought_board()
		player.fought_rules = _rules.fight_rules(player)
	_run_fights()
	_log.record_round(_round, _living())
	_eliminate()
	if not _over:
		for player: PlayerState in _living():
			_rules.after_fights(player)
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
	_lobby_tribes = _draw_lobby_tribes()
	_pool = UnitPool.create(_library, _config, _lobby_tribes)
	_rules = RecruitRules.create(_library, _config, _pool)
	_rules.lobby_tribes = _lobby_tribes
	_pairing_rng = _derive("pairing")
	_placement_rng = _derive("placement")
	var seated: PackedStringArray = [_config.get_string("human_bot")]
	seated.append_array(_config.get_strings("bots"))
	seated = BotLobby.resolve(seated, _lobby_tribes, _derive("lobby_builds"))
	var personalities: PackedStringArray = seated.slice(1)
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
			player.name = "Bot %d (%s)" % [id, personality.get_slice(":", 0)]
			_bots[id] = Bot.create(personality)
		player.shop_rng = _derive("shop:%d" % id)
		player.bot_rng = _derive("bot:%d" % id)
		player.effect_rng = _derive("effects:%d" % id)
		player.discover_rng = _derive("discover:%d" % id)
		player.spell_rng = _derive("spells:%d" % id)
		_rules.setup_player(player)
		_players.append(player)
	if seated[0] != "":
		_bots[HUMAN_ID] = Bot.create(seated[0])
	if _config.get_bool("hero_choice"):
		_deal_heroes()


## 5.2.4: each game draws a subset of the tribes in rotation; neutrals are always in (5.2.7).
## 0 in the config means all of them. Only tribes with enough units are drawn.
func _draw_lobby_tribes() -> PackedStringArray:
	var wanted: int = _config.get_int("tribes_per_lobby")
	if wanted <= 0:
		return PackedStringArray()
	var rotation: PackedStringArray = _library.tribes_in_rotation(
		_config.get_int("lobby_tribe_min_units"), _config.card_set()
	)
	var rng: RandomNumberGenerator = _derive("lobby")
	var drawn: PackedStringArray = []
	while drawn.size() < wanted and not rotation.is_empty():
		var index: int = rng.randi_range(0, rotation.size() - 1)
		drawn.append(rotation[index])
		rotation.remove_at(index)
	drawn.sort()
	return drawn


## 2.2.1: the bots pick now; the human's offer waits for choose() and the first round after it.
func _deal_heroes() -> void:
	var offers: Array = HeroRules.deal(
		_library.heroes_of(_config.card_set()),
		_lobby_tribes,
		_players.size(),
		_config.get_int("heroes_offered"),
		_derive("heroes")
	)
	for player: PlayerState in _players:
		var offer: PackedStringArray = offers[player.id]
		if offer.is_empty():
			continue
		player.hero_offer = offer
		if _bots.has(player.id):
			var bot: Bot = _bots[player.id]
			HeroRules.assign(player, _library.get_hero(offer[bot.pick_hero(offer, player)]))
		else:
			_hero_offer = offer


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
		player.scout = _scout_of(_opponent_of(player.id))
		_rules.start_phase(player, _round)


## What the rule shows of a player (or the ghost): {} until they have fought. A bot reads only this,
## so it holds only what a player can see: the board and slots by slot, the tier from the standings,
## and what the hero's text says. Not the Larder: nobody can see an opponent's hand.
func _scout_of(opponent: int) -> Dictionary:
	if opponent == Matchmaking.GHOST:
		if _ghost_view.is_empty():
			return {}
		return {
			"views": _ghost_view,
			"specs": _ghost_board,
			"slots": _ghost_slots,
			"hero_effects": [],
			"rules": {},
			"tier": _ghost_tier,
		}
	var seen: PlayerState = _players[opponent]
	if seen.fought_view.is_empty():
		return {}
	return {
		"views": seen.fought_view,
		"specs": seen.fought_specs,
		"slots": seen.fought_slots,
		"hero_effects": HeroRules.effects_of(seen.hero),
		"rules": {"back_row_first": seen.fought_rules.get("back_row_first", false)},
		"tier": seen.tier,
	}


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
	var slots: Array = [a.combat_slots(), _ghost_slots if b == null else b.combat_slots()]
	var heroes: Array = [
		HeroRules.effects_of(a.hero), [] if b == null else HeroRules.effects_of(b.hero)
	]
	var tiers: Array[int] = [a.tier, _ghost_tier if b == null else b.tier]
	var player_ids: Array[int] = [id_a, id_b]
	var rng: RandomNumberGenerator = _derive("fight:%d:%d:%d" % [_round, id_a, id_b])
	var combat: Combat = Combat.create(_library, _config, rng)
	combat.slot_effects = slots
	combat.hero_effects = heroes
	combat.side_rules = [
		_rules.fight_rules(a), _ghost_rules if b == null else _rules.fight_rules(b)
	]
	var result: Dictionary = combat.run(boards, tiers, player_ids, cap)
	if fight_observer.is_valid():
		fight_observer.call(_round, id_a, id_b, result)
	var carried: Array[Dictionary] = result["carry"]
	for change: Dictionary in carried:
		var receiver: PlayerState = a if CoreUtil.to_int(change["side"]) == 0 else b
		if receiver != null:
			_rules.apply_carry(receiver, change)
	var winner: int = result["winner"]
	var damage: int = result["damage"]
	if winner == 1:
		HeroRules.take_hero_damage(a, damage)
	elif winner == 0 and b != null:
		HeroRules.take_hero_damage(b, damage)
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
			_ghost_slots = player.combat_slots()
			_ghost_view = player.fought_view
			_ghost_rules = {"larder": player.larder()}
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
	return CHOOSE_HERO if not _hero_offer.is_empty() else ""
