class_name PlayerState
extends RefCounted
## One player's game state: hero, economy, shop, hand and the 7-slot board (index = slot).

const LOG_CAP: int = 200

var id: int = 0
var name: String = ""
var personality: String = "human"
var is_human: bool = false
var health: int = 30
## Once per game, a lethal loss to another hero from 2+ Health leaves 1.
var last_stand_used: bool = false
var gold: int = 0
var tier: int = 1
var upgrade_cost: int = 0
var paid_refreshes: int = 0
var asked_for_kin: bool = false
var early_spoils_next_turn: int = 0
var early_spoils_income: int = 0
var cards_next_turn: Array[Dictionary] = []
var frozen: bool = false
var freezes_left: int = 0
var shop: Array[RecruitUnit] = []
## Tavern spells on offer next to the units (6.1.5).
var shop_spells: Array[HandItem] = []
## Market Stall: permanent shop upgrades already cast, at most two.
var market_stalls: int = 0
## Harvest Supper: a standing +N/+N for each tribe, capped at 3.
var tribe_bonuses: Dictionary = {}
var harvest_supper_round: int = -1
var spells_bought_turn: int = 0
var poached_pending: Array[RecruitUnit] = []
var hunt_discount: int = 0
var hunt_discount_next: int = 0
var takes_last_fight: int = 0
var hand: Array[RecruitUnit] = []
## Cards in hand that aren't units: spells and items. They share the hand limit (7.1.1).
var items: Array[HandItem] = []
var board: Array[RecruitUnit] = []
## 8.5: per slot, the effects it holds for the rest of the game.
var slot_effects: Array = [[], [], [], [], [], [], []]
## Rainbow, per slot: the iid of the unit that painted its band; 0 for none.
var bands: Array[int] = [0, 0, 0, 0, 0, 0, 0]
## Passes waiting for End of Turn: {"iid", "slot", "attack", "health"}. "slot" is where the source
## last stood, for a source that has left.
var pending_passes: Array[Dictionary] = []
## Units bought this turn (buys_per_turn).
var buys_this_turn: int = 0
## Gold held over from last turn, before income (Dame Farthing).
var carried_gold: int = 0
## Hob Mumblecrust: total gold still to repay over future turns.
var debt: int = 0
var debt_payment: int = 0
## Rainy Day: gold next turn after a win or a tie, and after a loss.
var rainy_win: int = 0
var rainy_lose: int = 0
## The last round whose first shop showed the opening spells.
var opening_shown: int = 0
## Choices waiting to be made, oldest first: {"kind", "options", ...} (Discover, hero).
var pending: Array[Dictionary] = []
var hero: Dictionary = {}
## QA hook (tools/checks/soak.gd): log_observer(type, fields) on every recruit log event.
var log_observer: Callable = Callable()
var armor: int = 0
var power_uses_left: int = 0
## Rule handlers from the hero and from effects (RecruitRules.ask).
var rule_handlers: Array[Dictionary] = []
## Copies bought per tribe this game, for the game log.
var bought_by_tribe: Dictionary = {}
var alive: bool = true
## 0 while alive (shown as null).
var placement: int = 0
## "win", "loss", "tie" or "" (shown as null).
var last_result: String = ""
## Last opponents, most recent last (-1 is the ghost).
var recent_opponents: Array[int] = []
var shop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var bot_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Discover and Triple Reward picks, and the shop's spell slot: their own streams (5.3, 6.1.5).
var discover_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var spell_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Data effects' random choices (a separate stream, so they can't shift the shop).
var effect_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## The round this player's Recruit Phase belongs to.
var round_number: int = 0
## Unpaid refreshes waiting to be used (4.4.5).
var free_refreshes: int = 0
## Gold that arrives at the start of the next turn.
var gold_next_turn: int = 0
var gold_spent_turn: int = 0
var gold_spent_game: int = 0
## Counters and limits for an owner that isn't a unit (a hero).
var owner_counters: Dictionary = {}
var owner_limits: Dictionary = {}
## Scouting: what this player's board looked like when it last fought, by slot. Empty before the
## first fight. `fought_view` holds unit views, `fought_specs` combat entries, `fought_slots` the
## slot effects.
var fought_view: Array = []
var fought_specs: Array = []
var fought_slots: Array = []
var fought_rules: Dictionary = {}
## Which slots held a Nest in that fight. Not who is in the air.
var fought_nests: Array = []
## What can be seen of this round's opponent (GameSession._scout_of): {} in the first round.
var scout: Dictionary = {}
## Gold at the start of this Recruit Phase, units bought this game (for the bench).
var gold_at_start: int = 0
var units_bought: int = 0
## The heroes this player was offered (2.2.1), for the bench.
var hero_offer: PackedStringArray = []
## This phase's recruit events, oldest first, for the UI and tools/play ({"type", ...}).
var recruit_log: Array[Dictionary] = []
## Fly South: birds in the air, {"unit", "left": round, "due": round, "nest": slot or -1}.
var away: Array[Dictionary] = []
## Birds that returned to hand or the doorstep during this Recruit Phase.
var homecomings_this_turn: int = 0
## Units with nowhere to go on a full hand. They enter as soon as there's room, so none is lost.
var doorstep: Array[RecruitUnit] = []


func _init() -> void:
	board.resize(BoardGeometry.SLOTS)


func board_count() -> int:
	var count: int = 0
	for unit: RecruitUnit in board:
		if unit != null:
			count += 1
	return count


func first_empty_slot() -> int:
	for slot: int in BoardGeometry.SLOTS:
		if board[slot] == null:
			return slot
	return -1


## Which slots hold a unit.
func occupied() -> Array[bool]:
	var out: Array[bool] = []
	for unit: RecruitUnit in board:
		out.append(unit != null)
	return out


## What the Acorn items in hand are worth in gold.
## The gold value of each Acorn item in hand, smallest first (Sergeant-at-Conkers' ammunition).
func acorn_values() -> Array:
	var out: Array = []
	for item: HandItem in items:
		if item.gold_value() > 0:
			out.append(item.gold_value())
	out.sort()
	return out


func larder() -> int:
	var total: int = 0
	for item: HandItem in items:
		total += item.gold_value()
	return total


func holds_item(card_id: String) -> bool:
	for item: HandItem in items:
		if item.def_id() == card_id:
			return true
	return false


func band_count() -> int:
	var count: int = 0
	for iid: int in bands:
		if iid != 0:
			count += 1
	return count


## All units the player holds on board, in hand and inside Bellies. Birds away and units on the
## doorstep aren't here: they don't count for triples until they're home.
func owned_units() -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	for unit: RecruitUnit in board:
		if unit != null:
			out.append(unit)
			out.append_array(unit.held)
	out.append_array(hand)
	return out


## Everything the player holds a pool copy through, wherever it is.
func all_units() -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = owned_units()
	for entry: Dictionary in away:
		var unit: RecruitUnit = entry["unit"]
		out.append(unit)
	out.append_array(doorstep)
	out.append_array(poached_pending)
	return out


## The board a fight takes: an empty Nest holds an Egg.
func combat_board() -> Array:
	var out: Array = board_specs()
	for entry: Dictionary in away:
		var slot: int = entry["nest"]
		if slot >= 0 and out[slot] == null:
			var bird: RecruitUnit = entry["unit"]
			var egg: Dictionary = HeldUnits.egg_spec(bird)
			var body: Dictionary = bird.combat_spec()
			egg["bird_attack"] = body["attack"]
			egg["bird_health"] = body["health"]
			egg["turns_left"] = CoreUtil.to_int(entry["due"]) - round_number
			out[slot] = egg
	return out


## The board's units as CombatSandbox-style entries (null or {"def_id", "golden", ...}).
func board_specs() -> Array:
	var out: Array = []
	for unit: RecruitUnit in board:
		if unit == null:
			out.append(null)
		else:
			out.append(unit.combat_spec())
	return out


## The Nest on this slot's away entry; {} if it has none.
func nest_at(slot: int) -> Dictionary:
	for entry: Dictionary in away:
		if CoreUtil.to_int(entry["nest"]) == slot:
			return entry
	return {}


func nest_count() -> int:
	var count: int = 0
	for entry: Dictionary in away:
		if CoreUtil.to_int(entry["nest"]) >= 0:
			count += 1
	return count


## Whether a choice must be made before anything else (6.2).
func is_choosing() -> bool:
	return not pending.is_empty()


## Scouting: notes the board as it is about to fight.
func remember_fought_board() -> void:
	fought_view = []
	for unit: RecruitUnit in board:
		if unit == null:
			fought_view.append(null)
		else:
			fought_view.append(unit.view())
	fought_specs = combat_board()
	for value: Variant in fought_specs:
		if value == null:
			continue
		var spec: Dictionary = value
		if str(spec["def_id"]) == HeldUnits.EGG:
			for field: String in ["bird_attack", "bird_health", "turns_left"]:
				spec.erase(field)
	fought_slots = combat_slots().duplicate(true)
	fought_nests = []
	var tit_support: bool = false
	for source: RecruitUnit in board:
		if source != null and HeldUnits.support_number(source, "tom_tit", "full") > 0:
			tit_support = true
	for entry: Dictionary in away:
		var slot: int = CoreUtil.to_int(entry["nest"])
		if slot < 0:
			continue
		fought_nests.append(slot)
		if board[slot] != null:
			continue
		var supported: bool = tit_support
		for adjacent: int in BoardGeometry.adjacent(slot):
			if board[adjacent] != null and HeldUnits.redwing_factor(board[adjacent]) > 0:
				supported = true
		if not supported:
			continue
		var bird: RecruitUnit = entry["unit"]
		var body: Dictionary = bird.combat_spec()
		var spec: Dictionary = fought_specs[slot]
		# Egg support needs the full body to rebuild and remove its aura in scout fights.
		# Keep the plain half body separate; Bird identity and trip timers stay hidden.
		spec["egg_full_attack"] = body["attack"]
		spec["egg_full_health"] = body["health"]
		var egg: Dictionary = HeldUnits.egg_forecast(self, bird, slot)
		var effects: Array = fought_slots[slot]
		var ring: Vector2i = BoardUpkeep.ring_stats(effects)
		egg["name"] = "Egg"
		egg["attack"] = CoreUtil.to_int(egg["attack"]) + ring.x
		egg["health"] = CoreUtil.to_int(egg["health"]) + ring.y
		fought_view[slot] = egg


## 8.5.2 the slot effects a fight copies.
func combat_slots() -> Array:
	return slot_effects.duplicate()


## Notes something that happened this phase. Capped, so a trigger loop can't eat memory.
func log_event(type: String, fields: Dictionary = {}) -> void:
	if log_observer.is_valid():
		log_observer.call(type, fields)
	if recruit_log.size() >= LOG_CAP:
		return
	var entry: Dictionary = fields.duplicate()
	entry["type"] = type
	recruit_log.append(entry)


## 6.4 standing.
func standing() -> Dictionary:
	return {
		"hero": str(hero.get("name", "")),
		"armor": armor,
		"player_id": id,
		"name": name,
		"is_human": is_human,
		"personality": personality,
		"health": health,
		"tier": tier,
		"alive": alive,
		"placement": CoreUtil.int_or_null(placement, 0),
		"last_result": CoreUtil.string_or_null(last_result),
	}
