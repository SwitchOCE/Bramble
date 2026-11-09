# gdlint:disable=max-public-methods
# One public method per player action and per state view.
class_name GameSession
extends RefCounted
## A full game: the human (player 0) and the bots in one live lobby (SPEC section 9), round by
## round until one player is left (rulebook 1.1.3, 10.2.3) or round 50 ends (2.1.3).
## The UI calls the recruit actions for the human, then end_turn().

const RainbowValue := preload("res://src/core/rainbow_value.gd")

const HUMAN_ID: int = 0
const CHOOSE_HERO: String = "Choose a hero first"
const GAME_OVER: String = "The game is over"

## QA hook (tools/checks/soak.gd): called after every fight with
## (round, player_id_a, player_id_b, result), where result is Combat.run's dictionary.
var fight_observer: Callable = Callable()
## Tools-only capture at the combat boundary, before carry, Health and session event changes.
## (input, raw_result, combat); RNG strings keep JSON from rounding 64-bit values.
var fight_capture_observer: Callable = Callable()
## QA hook (tools/sim/bench.gd): called after every bot turn with (player, round, microseconds).
var turn_observer: Callable = Callable()
## Optional tools factory; ordinary games use Bot.create. Called after the normal build deal.
var _bot_factory: Callable = Bot.create

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
var _ghost_nests: Array = []


static func create(
	game_seed: int,
	library: UnitLibrary,
	config: GameConfig = null,
	bot_factory: Callable = Bot.create
) -> GameSession:
	var session := GameSession.new()
	session._bot_factory = bot_factory
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
	var poached: Array[int] = []
	for unit: RecruitUnit in human.shop:
		var view: Dictionary = unit.view()
		view["cost"] = _rules.unit_cost(human, unit)
		view["sell_value"] = _rules.sell_value(unit, human)
		if unit.poached_discount > 0:
			poached.append(shop.size())
		shop.append(view)
	var hand: Array = []
	for unit: RecruitUnit in human.hand:
		var view: Dictionary = unit.view()
		view["sell_value"] = _rules.sell_value(unit, human)
		hand.append(view)
	var board: Array = []
	var ammo: Array = human.acorn_values()
	for unit: RecruitUnit in human.board:
		if unit == null:
			board.append(null)
		else:
			var view: Dictionary = unit.view()
			view["sell_value"] = _rules.sell_value(unit, human)
			view["sell_payout"] = _sale_payout(unit, human)
			if unit.has_mechanic_id("sergeant"):
				var gold: int = CoreUtil.to_int(ammo.pop_front()) if not ammo.is_empty() else 0
				view["next_acorn"] = (
					(
						"Next Acorn: %d gold → %d damage"
						% [gold, gold * unit.mechanic_number("sergeant", "damage")]
					)
					if gold > 0
					else "No Acorn to throw"
				)
				view["text"] = (
					"%s\n%s. Thrown only if an enemy is across; earlier Sergeants throw first."
					% [str(view["text"]), str(view["next_acorn"])]
				)
			board.append(view)
	var spells: Array = []
	for item: HandItem in human.shop_spells:
		var view: Dictionary = item.view()
		view["cost"] = _rules.spell_cost(human, item)
		spells.append(view)
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
		"round_toll": _round_toll(),
		"damage_mode": _config.get_string("damage_mode"),
		"base_damage": _config.get_int_at("base_damage_by_turn", _round - 1),
		"damage_cap": _damage_cap(),
		"last_stand_used": human.last_stand_used,
		"last_stand_enabled": _config.get_bool("last_stand"),
		"last_stand_active": _last_stand_active(),
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
		"ask_for_kin_enabled": _config.get_bool("ask_for_kin"),
		"can_ask_for_kin": RecruitKin.available(_rules, human),
		"paid_refreshes": human.paid_refreshes,
		"frozen": human.frozen,
		"freezes_left": human.freezes_left,
		"shop": shop,
		"shop_size": _rules.shop_size(human.tier, human),
		"shop_spells": spells,
		"tribe_bonuses": human.tribe_bonuses.duplicate(),
		"harvest_supper_used": human.harvest_supper_round == human.round_number,
		"takes_last_fight": human.takes_last_fight,
		"poached": poached,
		"hand_items": items,
		"pending_choice": _pending_view(human),
		"hero": _hero_view(human),
		"armor": human.armor,
		"free_refreshes": human.free_refreshes,
		"gold_next_turn": human.gold_next_turn,
		"early_spoils_next_turn": human.early_spoils_next_turn,
		"early_spoils_income": human.early_spoils_income,
		"next_turn_income":
		_config.get_int_at("income_by_turn", _round) - mini(human.debt, human.debt_payment),
		"gold_spent_turn": human.gold_spent_turn,
		"slot_effects": human.slot_effects.duplicate(true),
		"bands": _bands_view(human),
		"band_count": human.band_count(),
		"larder": human.larder(),
		"debt": human.debt,
		"debt_payment": human.debt_payment,
		"buys_left": _rules.buys_left(human),
		"pending_passes": _passes_view(human),
		"lobby_tribes": Array(_lobby_tribes),
		"away": HeldUnits.away_views(human),
		"doorstep": _doorstep_view(human),
		"next_opponent_last_nests": human.scout.get("nests", []),
		"recruit_log": human.recruit_log.duplicate(),
		"hand": hand,
		"hand_limit": _config.get_int("hand_limit"),
		"board": board,
		"health": human.health,
		"next_opponent_id": _opponent_of(player_id),
		"next_opponent_last_board": _scouted_view(human),
		"next_opponent_last_slot_effects": _scouted_slots(human),
		"next_opponent_hero": _next_hero_view(player_id),
		"last_combat": summary,
		"standings": get_standings(),
		"placement": CoreUtil.int_or_null(human.placement, 0),
	}


## Per slot, whether it has a Rainbow band.
static func _doorstep_view(player: PlayerState) -> Array:
	var out: Array = []
	for unit: RecruitUnit in player.doorstep:
		out.append(unit.view())
	return out


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
		var source: RecruitUnit = RecruitRules._unit_by_iid(player, CoreUtil.to_int(entry["iid"]))
		(
			out
			. append(
				{
					"attack": entry["attack"],
					"health": entry["health"],
					"from_slot": start,
					"landing_slot":
					BoardGeometry.pass_landing(
						player.occupied(),
						start if source != null and source in player.board else -1
					),
				}
			)
		)
	return out


func _phase_name() -> String:
	if _over:
		return "game_over"
	return "hero_choice" if not _hero_offer.is_empty() else "recruit"


## Sale display only: Rainbow pays before ordinary sale gold, then wipes the paint.
func _sale_payout(unit: RecruitUnit, player: PlayerState) -> int:
	var entries: Array[Dictionary] = []
	for entry: Dictionary in unit.def["mechanics"]:
		entries.append({"entry": entry, "golden": unit.golden})
	entries.append_array(unit.grants)
	entries.append_array(unit.borrowed_text())
	var payout: int = _rules.sell_value(unit, player)
	for grant: Dictionary in entries:
		var entry: Dictionary = grant["entry"]
		if str(entry.get("id", "")) != "rainbow":
			continue
		var params: Dictionary = MechanicRegistry.params_for(
			entry, CoreUtil.to_bool(grant.get("golden", false))
		)
		var per: int = CoreUtil.to_int(params.get("gold", 0))
		if per <= 0:
			continue
		payout += RainbowValue.sale_bonus(params, player.band_count())
		break
	return payout


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
	return {"kind": choice["kind"], "options": options, "note": choice.get("note", "")}


func _hero_view(player: PlayerState) -> Variant:
	if player.hero.is_empty():
		return null
	var view: Dictionary = _hero_card(player.hero)
	view["last_stand_used"] = player.last_stand_used
	if _config.get_bool("last_stand"):
		view["text"] = (
			str(view["text"])
			+ "\nLast Stand: "
			+ ("used." if player.last_stand_used else "unused.")
		)
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


## Who they are is public: the next opponent's hero and power text. Null for the ghost or before
## they have chosen.
func _next_hero_view(player_id: int) -> Variant:
	var opponent: int = _opponent_of(player_id)
	if opponent == Matchmaking.GHOST or opponent < 0:
		return null
	var seen: PlayerState = _players[opponent]
	if seen.hero.is_empty():
		return null
	return _hero_view(seen)


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
		var standing: Dictionary = player.standing()
		standing["last_stand_enabled"] = _config.get_bool("last_stand")
		standing["last_stand_active"] = _last_stand_active()
		standing["last_stand_used"] = player.last_stand_used
		out.append(standing)
	return out


func is_over() -> bool:
	return _over


func buy(shop_index: int) -> String:
	return _human_action() if _human_action() != "" else _rules.buy(_human(), shop_index)


func sell(slot: int) -> String:
	return _human_action() if _human_action() != "" else _rules.sell(_human(), slot)


## Belly: from "shop", "hand" or "board" into the Ooze in `into_slot`.
func swallow(source: String, index: int, into_slot: int) -> String:
	if _human_action() != "":
		return _human_action()
	return _rules.swallow(_human(), source, index, into_slot)


func play(hand_index: int, slot: int) -> String:
	return _human_action() if _human_action() != "" else _rules.play(_human(), hand_index, slot)


func move(from_slot: int, to_slot: int) -> String:
	return _human_action() if _human_action() != "" else _rules.move(_human(), from_slot, to_slot)


func refresh() -> String:
	return _human_action() if _human_action() != "" else _rules.refresh(_human())


func ask_for_kin() -> String:
	return _human_action() if _human_action() != "" else RecruitKin.ask(_rules, _human())


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
		_pick_bot_heroes()
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
func shy_warning(action: String, first: int = -1, second: int = -1) -> String:
	const Preview := preload("res://src/core/recruit_preview.gd")
	return Preview.shy_warning(_human(), _rules, action, first, second)


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
			_bots[id] = _bot_factory.call(personality)
		player.shop_rng = _derive("shop:%d" % id)
		player.bot_rng = _derive("bot:%d" % id)
		player.effect_rng = _derive("effects:%d" % id)
		player.discover_rng = _derive("discover:%d" % id)
		player.spell_rng = _derive("spells:%d" % id)
		_rules.setup_player(player)
		_players.append(player)
	if seated[0] != "":
		_bots[HUMAN_ID] = _bot_factory.call(seated[0])
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


## 2.2.1: deal offers now; bots pick after the person has chosen.
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
		player.hero_offer = offer
		if not _bots.has(player.id):
			_hero_offer = offer
	if _hero_offer.is_empty():
		_pick_bot_heroes()


## Nine heroes cannot reserve three human options plus seven distinct bot picks. Wait for the
## person's choice, then let bots pick the remaining heroes without changing that choice.
func _pick_bot_heroes() -> void:
	var dealt: PackedStringArray = []
	var taken: PackedStringArray = []
	for player: PlayerState in _players:
		for id: String in player.hero_offer:
			if not dealt.has(id):
				dealt.append(id)
		if not _bots.has(player.id) and not player.hero.is_empty():
			taken.append(str(player.hero["id"]))
	for player: PlayerState in _players:
		if not _bots.has(player.id) or player.hero_offer.is_empty():
			continue
		var offer: PackedStringArray = _untaken(player.hero_offer, dealt, taken)
		player.hero_offer = offer
		var bot: Bot = _bots[player.id]
		var pick: String = offer[bot.pick_hero(offer, player)]
		taken.append(pick)
		HeroRules.assign(player, _library.get_hero(pick))


## A player is known by their hero on screen, so no two bots share one (ideation DECISIONS, 7 Nov):
## a bot picks from what's left of its offer, or if that's all gone from what's left of the deal.
static func _untaken(
	offer: PackedStringArray, dealt: PackedStringArray, taken: PackedStringArray
) -> PackedStringArray:
	for pool: PackedStringArray in [offer, dealt]:
		var left: PackedStringArray = []
		for id: String in pool:
			if not taken.has(id):
				left.append(id)
		if not left.is_empty():
			return left
	return offer


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
			"nests": _ghost_nests,
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
		"nests": seen.fought_nests,
	}


func _run_fights() -> void:
	var cap: int = _damage_cap()
	for pair: Variant in _pairings:
		var ids: Array = pair
		if _skip_human_fight and ids.has(HUMAN_ID):
			_last_combat = {}
			continue
		_fight(CoreUtil.to_int(ids[0]), CoreUtil.to_int(ids[1]), cap)


## Last Stand guards only the last-four cliff; the alive flags settle after all fights.
func _last_stand_active() -> bool:
	return _config.get_bool("last_stand") and _living().size() <= 4


## 10.1.4: 0 means no cap.
func _damage_cap() -> int:
	if _config.uses_v05_damage() or _living().size() <= _config.get_int("damage_cap_off_at_alive"):
		return 0
	return _config.get_int_at("damage_cap_by_turn", _round - 1)


## One pressure rule: failing to win costs a toll, one until round 8, then one more each round.
## A draw charges both sides. Existing damage caps and Armor still apply normally.
func _round_toll() -> int:
	return (
		maxi(1, _round - 7)
		if _config.get_bool("round_toll") and not _config.uses_v05_damage()
		else 0
	)


func _apply_round_toll(result: Dictionary, cap: int) -> void:
	var toll: int = _round_toll()
	if toll == 0:
		return
	var before: int = CoreUtil.to_int(result["damage"])
	var uncapped: int = CoreUtil.to_int(result["damage_uncapped"]) + toll
	var damage: int = mini(cap, uncapped) if cap > 0 else uncapped
	result["damage_uncapped"] = uncapped
	result["damage"] = damage
	var log_events: Array = result["events"]
	for event: Dictionary in log_events:
		if str(event.get("type", "")) == "combat_end":
			event["damage"] = damage
			event["damage_uncapped"] = uncapped
			event["round_toll"] = toll
			event["round_toll_added"] = damage - before


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
	combat.round_number = _round
	var captured: Dictionary = {}
	if fight_capture_observer.is_valid():
		captured = {
			"version": 1,
			"boards": boards.duplicate(true),
			"slots": slots.duplicate(true),
			"hero_effects": heroes.duplicate(true),
			"fight_rules": combat.side_rules.duplicate(true),
			"tiers": tiers.duplicate(),
			"player_ids": player_ids.duplicate(),
			"round": _round,
			"damage_cap": cap,
			"config": _config._values.duplicate(true),
			"rng_seed": str(rng.seed),
			"rng_state": str(rng.state),
			"effect_rng_seed": str(combat.effect_rng.seed),
			"effect_rng_state": str(combat.effect_rng.state),
		}
	var result: Dictionary = combat.run(boards, tiers, player_ids, cap)
	if fight_capture_observer.is_valid():
		fight_capture_observer.call(captured, result, combat)
	_apply_round_toll(result, cap)
	var carried: Array[Dictionary] = result["carry"]
	for change: Dictionary in carried:
		var receiver: PlayerState = a if CoreUtil.to_int(change["side"]) == 0 else b
		if receiver != null:
			_rules.apply_carry(receiver, change)
	a.takes_last_fight = combat.takes[0]
	if b != null:
		b.takes_last_fight = combat.takes[1]
	var winner: int = result["winner"]
	if _config.get_bool("early_spoils") and _round <= 4 and b != null and winner >= 0:
		var victor: PlayerState = a if winner == 0 else b
		victor.gold_next_turn += 1
		victor.early_spoils_next_turn += 1
		var log_events: Array = result["events"]
		log_events.insert(
			log_events.size() - 1, {"type": "early_spoils", "side": winner, "amount": 1}
		)
	var damage: int = result["damage"]
	var saved: Array[int] = []
	if winner != 0:
		if HeroRules.take_combat_loss(a, damage, b != null and winner == 1, _last_stand_active()):
			saved.append(0)
	if winner != 1 and b != null:
		if HeroRules.take_combat_loss(b, damage, winner == 0, _last_stand_active()):
			saved.append(1)
	result["last_stand_sides"] = saved
	for event: Dictionary in result["events"]:
		if str(event["type"]) == "combat_end":
			event["last_stand_sides"] = saved
			event["alive"] = _living().size()
			event["damage_cap"] = cap
	if fight_observer.is_valid():
		fight_observer.call(_round, id_a, id_b, result)
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
			for slot: int in player.fought_nests:
				if player.board[slot] == null:
					var egg: Dictionary = player.fought_specs[slot]
					_ghost_board[slot] = egg.duplicate()
			_ghost_slots = player.combat_slots().duplicate(true)
			for slot: int in _ghost_slots.size():
				var effects: Array = _ghost_slots[slot]
				_ghost_slots[slot] = effects.filter(
					func(effect: Dictionary) -> bool:
						return str(effect.get("name", "")) != "Horseshoe"
				)
			_ghost_view = player.fought_view
			_ghost_rules = {"larder": player.larder(), "bands": player.bands.duplicate()}
			_ghost_rules.merge(HeldUnits.sky_rules(player))
			_ghost_nests = player.fought_nests
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
