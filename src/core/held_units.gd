class_name HeldUnits
extends RefCounted
## The one place for units a player holds off the board and out of the hand: inside a Belly, away
## on Fly South, or on the doorstep. RecruitRules calls these from its actions; fights use
## CombatHeld. Units inside count for triples (`owned_units`); birds away don't until they land.

const SHOP: String = "shop"
const HAND: String = "hand"
const BOARD: String = "board"
const EGG: String = "nest_egg"
const BELLY: String = "belly"
const FLY: String = "fly_south"
const GOOSE: String = "mother_goose"
const BIRDS: String = "Birds"
const SOUP_COUNTER: String = "soup"

# --- Belly --------------------------------------------------------------------------------------


static func belly_size(unit: RecruitUnit) -> int:
	return unit.mechanic_number(BELLY, "size")


static func room(unit: RecruitUnit) -> int:
	return maxi(0, belly_size(unit) - unit.held.size())


## What a shop unit costs bought into this Ooze.
static func swallow_cost(
	rules: RecruitRules, player: PlayerState, ooze: RecruitUnit, bought: RecruitUnit = null
) -> int:
	return maxi(0, rules.unit_cost(player, bought) - ooze.mechanic_number("belly_discount", "gold"))


## Why this swallow can't happen; "" if it can.
static func swallow_problem(
	rules: RecruitRules, player: PlayerState, source: String, index: int, into_slot: int
) -> String:
	if not BoardGeometry.is_valid(into_slot) or player.board[into_slot] == null:
		return "No unit there"
	var ooze: RecruitUnit = player.board[into_slot]
	if belly_size(ooze) <= 0:
		return "That unit has no Belly"
	if room(ooze) <= 0:
		return "That Belly is full"
	var unit: RecruitUnit = _candidate(player, source, index)
	if unit == null:
		return "No unit to swallow there"
	if unit == ooze:
		return "A unit can't swallow itself"
	if not unit.held.is_empty():
		return "It's holding units of its own"
	if source == SHOP:
		if player.gold < swallow_cost(rules, player, ooze, unit):
			return "Not enough gold"
		if rules.buys_left(player) == 0:
			return "Pipkin can buy only two units each turn; no unit buys left."
	return ""


static func swallow(
	rules: RecruitRules, player: PlayerState, source: String, index: int, into_slot: int
) -> String:
	var problem: String = swallow_problem(rules, player, source, index, into_slot)
	if problem != "":
		return problem
	var ooze: RecruitUnit = player.board[into_slot]
	var unit: RecruitUnit = _candidate(player, source, index)
	var cost: int = swallow_cost(rules, player, ooze, unit)
	match source:
		SHOP:
			player.shop.remove_at(index)
			unit.poached_discount = 0
		HAND:
			player.hand.remove_at(index)
		BOARD:
			player.board[index] = null
	unit.set_aura(0, 0)
	ooze.held.append(unit)
	player.log_event(
		"swallow", {"unit": unit.def_id(), "by": ooze.def_id(), "slot": into_slot, "from": source}
	)
	if source == SHOP:
		note_bought(rules, player, unit, cost)
		if ooze.mechanic_number("belly_discount", "gold") > 0:
			player.log_event("trigger", {"mechanic": "belly_discount", "source": ooze.def_id()})
	rules.events.fire(player, "on_swallow", {"subject": unit, "paid": source == SHOP})
	rules.board_changed(player)
	rules.check_triples(player)
	drain_doorstep(rules, player)
	return ""


## What buying a unit always does, wherever it went (4.2).
static func note_bought(
	rules: RecruitRules, player: PlayerState, unit: RecruitUnit, cost: int
) -> void:
	player.buys_this_turn += 1
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	player.units_bought += 1
	for tribe: Variant in unit.tribes():
		player.bought_by_tribe[tribe] = CoreUtil.to_int(player.bought_by_tribe.get(tribe, 0)) + 1
	rules.spend(player, cost)
	player.log_event("buy", {"unit": unit.def_id()})
	rules.events.fire(player, "on_buy", {"subject": unit})
	rules.events.fire(player, "on_unit_bought", {"subject": unit})


static func _candidate(player: PlayerState, source: String, index: int) -> RecruitUnit:
	var row: Array = []
	match source:
		SHOP:
			row = player.shop
		HAND:
			row = player.hand
		BOARD:
			row = player.board
	if index < 0 or index >= row.size() or row[index] == null:
		return null
	var unit: RecruitUnit = row[index]
	return unit


## An Ooze left without dying in a fight: what's inside goes to hand, last in first. A full hand
## leaves the rest on the doorstep, so nothing is lost.
static func release(rules: RecruitRules, player: PlayerState, ooze: RecruitUnit) -> void:
	var inside: Array[RecruitUnit] = ooze.held
	ooze.held = []
	for index: int in range(inside.size() - 1, -1, -1):
		_to_hand(rules, player, inside[index])
		player.log_event("came_out", {"unit": inside[index].def_id(), "by": ooze.def_id()})


## A copy leaves hand or Belly because a triple took it.
static func take_out(player: PlayerState, unit: RecruitUnit) -> void:
	if player.hand.has(unit):
		player.hand.erase(unit)
		return
	for ooze: RecruitUnit in player.board:
		if ooze != null and ooze.held.has(unit):
			ooze.held.erase(unit)
			if not unit.timers.is_empty():
				player.log_event("timer_lost", {"unit": unit.def_id()})
			return


## Figgy Duff pairs two Bought copies with a Triple Reward, then skips the following turn.
static func figgy_pair(rules: RecruitRules, player: PlayerState) -> bool:
	for ooze: RecruitUnit in player.board:
		if ooze == null or not ooze.has_mechanic_id("figgy_duff"):
			continue
		var last_round: int = CoreUtil.to_int(ooze.counters.get("figgy_round", -2))
		if player.round_number < last_round + 2:
			continue
		for inner: RecruitUnit in ooze.held:
			var other: RecruitUnit = _bought_twin(player, inner)
			if other != null:
				ooze.counters["figgy_round"] = player.round_number
				player.log_event("trigger", {"mechanic": "figgy_duff", "source": ooze.def_id()})
				rules.combine(player, [inner, other], true)
				return true
	return false


static func _bought_twin(player: PlayerState, unit: RecruitUnit) -> RecruitUnit:
	if unit.golden or unit.plain_copy or unit.origin != RecruitUnit.ORIGIN_BOUGHT:
		return null
	for other: RecruitUnit in player.owned_units():
		if other == unit or other.golden or other.plain_copy:
			continue
		if other.def_id() == unit.def_id() and other.origin == RecruitUnit.ORIGIN_BOUGHT:
			return other
	return null


## Stone Soup: what the shop gained lasts the turn. A unit bought keeps it; a frozen one doesn't.
static func soak_shop(player: PlayerState, gain: int) -> void:
	for unit: RecruitUnit in player.shop:
		unit.add_permanent(gain, gain)
		unit.counters[SOUP_COUNTER] = CoreUtil.to_int(unit.counters.get(SOUP_COUNTER, 0)) + gain


static func wash_shop(player: PlayerState) -> void:
	for unit: RecruitUnit in player.shop:
		var gain: int = CoreUtil.to_int(unit.counters.get(SOUP_COUNTER, 0))
		if gain > 0:
			unit.add_permanent(-gain, -gain)
			unit.counters.erase(SOUP_COUNTER)


## Cut-and-Come-Again: a plain Created copy that holds no pool copy and can't help a triple.
static func give_plain_copy(rules: RecruitRules, player: PlayerState, def_id: String) -> void:
	if not rules.has_hand_space(player):
		return
	var unit := RecruitUnit.make(rules.library.get_unit(def_id), rules.new_iid())
	unit.origin = RecruitUnit.ORIGIN_CREATED
	unit.plain_copy = true
	player.hand.append(unit)
	player.log_event("card", {"card": def_id})


# --- Fly South ----------------------------------------------------------------------------------


## A bird that has fought flies; plain copies and birds played this turn sell for good.
static func flies(unit: RecruitUnit, player: PlayerState) -> bool:
	return (
		not unit.plain_copy
		and unit.has_mechanic_id(FLY)
		and unit.played_round != player.round_number
	)


## Sold means flown: it leaves a Nest without sale gold. A slot holds one Nest, so a new
## one ends the old (that bird still comes home).
static func send_south(
	_rules: RecruitRules, player: PlayerState, unit: RecruitUnit, slot: int
) -> void:
	for entry: Dictionary in player.away:
		if CoreUtil.to_int(entry["nest"]) == slot:
			var previous: RecruitUnit = entry["unit"]
			player.log_event("nest_replaced", {"name": str(previous.def["name"]), "slot": slot})
			entry["nest"] = -1
	var due: int = player.round_number + unit.flight_turns()
	for adjacent: int in BoardGeometry.adjacent(slot):
		var cuckoo: RecruitUnit = player.board[adjacent]
		if cuckoo != null:
			due += support_number(cuckoo, "cuckoo", "turns")
	player.away.append({"unit": unit, "left": player.round_number, "due": due, "nest": slot})
	unit.set_aura(0, 0)
	unit.clear_combat_layer()
	player.log_event("fly_south", {"unit": unit.def_id(), "slot": slot, "due": due})
	player.log_event("trigger", {"mechanic": FLY, "source": unit.def_id()})


## Start of turn, before Start of Turn text: everyone due lands, then their home text, then triples.
static func land_due(rules: RecruitRules, player: PlayerState) -> void:
	drain_doorstep(rules, player)
	var due: Array[Dictionary] = []
	for entry: Dictionary in player.away:
		if CoreUtil.to_int(entry["due"]) <= player.round_number:
			due.append(entry)
	_land(rules, player, due)
	rules.check_triples(player)


## Mrs Stork: never one sold this turn, so a bird that comes home has missed a fight.
static func bring_home(rules: RecruitRules, player: PlayerState, count: int) -> void:
	var ready: Array[Dictionary] = []
	for entry: Dictionary in player.away:
		if CoreUtil.to_int(entry["left"]) < player.round_number:
			ready.append(entry)
	ready.sort_custom(_longest_away)
	if ready.size() > count:
		ready.resize(count)
	_land(rules, player, ready)


static func _longest_away(first: Dictionary, second: Dictionary) -> bool:
	var a: int = CoreUtil.to_int(first["left"])
	var b: int = CoreUtil.to_int(second["left"])
	if a != b:
		return a < b
	var first_slot: int = BoardGeometry.ZIGZAG.find(CoreUtil.to_int(first["nest"]))
	var second_slot: int = BoardGeometry.ZIGZAG.find(CoreUtil.to_int(second["nest"]))
	return (7 if first_slot < 0 else first_slot) < (7 if second_slot < 0 else second_slot)


## Old Tern may end a trip before its due turn, including a Bird flown this turn.
static func land_flock(rules: RecruitRules, player: PlayerState) -> void:
	var flock: Array[Dictionary] = []
	for entry: Dictionary in player.away:
		var bird: RecruitUnit = entry["unit"]
		if bird.has_tribe(BIRDS):
			flock.append(entry)
	_land(rules, player, flock)


static func _land(rules: RecruitRules, player: PlayerState, entries: Array[Dictionary]) -> void:
	var landed: Array[RecruitUnit] = []
	for entry: Dictionary in entries:
		player.away.erase(entry)
		var unit: RecruitUnit = entry["unit"]
		unit.played_round = player.round_number
		if _completes_triple(player, unit):
			player.hand.append(unit)
		else:
			_to_hand(rules, player, unit)
		landed.append(unit)
		player.log_event("home", {"unit": unit.def_id()})
		if unit.has_tribe(BIRDS):
			player.homecomings_this_turn += 1
	for unit: RecruitUnit in landed:
		rules.events.fire(player, "on_home", {"subject": unit})
	if not landed.is_empty():
		rules.board_changed(player)
		rules.check_triples(player)


static func _completes_triple(player: PlayerState, unit: RecruitUnit) -> bool:
	if unit.golden or unit.plain_copy:
		return false
	var copies: int = 0
	for other: RecruitUnit in player.owned_units():
		if other.def_id() == unit.def_id() and not other.golden and not other.plain_copy:
			copies += 1
	return copies >= 2


## Mrs Dunnock: the bird of this Nest comes home sooner, but never sooner than next turn, nor the
## turn it left.
static func shorten_trip(player: PlayerState, slot: int, turns: int) -> void:
	var entry: Dictionary = player.nest_at(slot)
	if entry.is_empty():
		return
	var floor_round: int = maxi(CoreUtil.to_int(entry["left"]) + 1, player.round_number + 1)
	entry["due"] = maxi(floor_round, CoreUtil.to_int(entry["due"]) - turns)


static func _to_hand(rules: RecruitRules, player: PlayerState, unit: RecruitUnit) -> void:
	if rules.has_hand_space(player):
		player.hand.append(unit)
	else:
		player.doorstep.append(unit)


## Whoever waited on a full hand comes in as room appears.
static func drain_doorstep(rules: RecruitRules, player: PlayerState) -> void:
	var moved: bool = false
	while not player.doorstep.is_empty() and rules.has_hand_space(player):
		player.hand.append(player.doorstep.pop_front())
		moved = true
	if moved:
		rules.check_triples(player)


# --- What a fight reads -------------------------------------------------------------------------


## What a fight reads of the sky, for a ghost to keep.
static func sky_rules(player: PlayerState) -> Dictionary:
	return {
		"nests": nest_rules(player),
		"goose": goose_strikes(player),
		"away_birds": away_birds(player),
		"homecomings": player.homecomings_this_turn,
	}


## Eggs and the Lump read the away Bird's current stats before auras; odd halves round up.
static func lump_bonus(bird: RecruitUnit, factor: int = 1) -> Vector2i:
	var body: Dictionary = bird.combat_spec()
	return Vector2i(
		ceili(CoreUtil.to_int(body["attack"]) * factor / 2.0),
		ceili(CoreUtil.to_int(body["health"]) * factor / 2.0)
	)


## An empty Nest keeps half its Bird's current stats and none of its text.
static func egg_spec(bird: RecruitUnit) -> Dictionary:
	var body: Vector2i = lump_bonus(bird)
	return {"def_id": EGG, "golden": false, "egg": true, "attack": body.x, "health": body.y}


## The body an empty Nest would show beside the current (or proposed) recruit layout. Rings
## belong to the slot and are added later. Combat starts from egg_spec and keeps this as an aura.
static func egg_forecast(
	player: PlayerState, bird: RecruitUnit, slot: int, layout: Array = []
) -> Dictionary:
	var out: Dictionary = egg_spec(bird)
	if not BoardGeometry.is_valid(slot):
		return out
	var row: Array = player.board if layout.is_empty() else layout
	var factor: int = 0
	for adjacent: int in BoardGeometry.adjacent(slot):
		var source: RecruitUnit = row[adjacent]
		if source != null:
			factor = maxi(factor, redwing_factor(source))
	if factor > 0:
		var body: Dictionary = bird.combat_spec()
		var bonus: int = maxi(0, factor - 1) * 2
		out["attack"] = CoreUtil.to_int(body["attack"]) + bonus
		out["health"] = CoreUtil.to_int(body["health"]) + bonus
	var tit: int = 0
	for source: RecruitUnit in row:
		if source != null:
			tit = maxi(tit, support_number(source, "tom_tit", "full"))
	var bird_body: Dictionary = bird.combat_spec()
	if tit >= 1:
		out["health"] = maxi(CoreUtil.to_int(out["health"]), CoreUtil.to_int(bird_body["health"]))
	if tit >= 2:
		out["attack"] = maxi(CoreUtil.to_int(out["attack"]), CoreUtil.to_int(bird_body["attack"]))
	return out


## Printed, granted and Frumenty's borrowed text all give the same support.
static func redwing_factor(source: RecruitUnit) -> int:
	return support_number(source, "redwing", "factor")


## Multiple copies of the same support on one unit use its strongest value.
static func support_number(source: RecruitUnit, mechanic: String, key: String) -> int:
	var most: int = source.mechanic_number(mechanic, key)
	for group: Array in [source.grants, source.borrowed_text()]:
		for grant: Dictionary in group:
			var entry: Dictionary = grant.get("entry", {})
			if str(entry.get("id", "")) != mechanic:
				continue
			var params: Dictionary = MechanicRegistry.params_for(
				entry, CoreUtil.to_bool(grant.get("golden", false))
			)
			most = maxi(most, CoreUtil.to_int(params.get(key, 0)))
	return most


## Each Nest: its slot and the Bird's current stats and spec (Lump and Ratchet).
static func nest_rules(player: PlayerState) -> Array:
	var out: Array = []
	for entry: Dictionary in player.away:
		var slot: int = entry["nest"]
		if slot < 0:
			continue
		var unit: RecruitUnit = entry["unit"]
		var spec: Dictionary = unit.combat_spec()
		(
			out
			. append(
				{
					"slot": slot,
					"def_id": unit.def_id(),
					"attack": CoreUtil.to_int(spec["attack"]),
					"health": CoreUtil.to_int(spec["health"]),
					"spec": spec,
				}
			)
		)
	return out


## Mother Goose away: flat damage from each Nest. Only the strongest Goose fires.
static func goose_strikes(player: PlayerState) -> int:
	var most: int = 0
	for entry: Dictionary in player.away:
		var unit: RecruitUnit = entry["unit"]
		most = maxi(most, unit.mechanic_number(GOOSE, "damage"))
	return most


## The ids of the Birds in the air (The Seven Whistlers count them).
static func away_birds(player: PlayerState) -> Array:
	var out: Array = []
	for entry: Dictionary in player.away:
		var unit: RecruitUnit = entry["unit"]
		if unit.has_tribe(BIRDS):
			out.append(unit.def_id())
	return out


## What a screen shows of the sky: who, when it lands, which Nest.
static func away_views(player: PlayerState) -> Array:
	var out: Array = []
	for entry: Dictionary in player.away:
		var unit: RecruitUnit = entry["unit"]
		var view: Dictionary = unit.view()
		view["nest"] = entry["nest"]
		view["due"] = entry["due"]
		view["turns_left"] = CoreUtil.to_int(entry["due"]) - player.round_number
		var egg: Dictionary = egg_forecast(player, unit, CoreUtil.to_int(entry["nest"]))
		view["egg_attack"] = egg["attack"]
		view["egg_health"] = egg["health"]
		out.append(view)
	return out


## Acorn feeding respects a printed permanent ceiling and never wastes a fully capped item.
static func feed(rules: RecruitRules, player: PlayerState, index: int, slot: int) -> String:
	var unit: RecruitUnit = player.board[slot] if BoardGeometry.is_valid(slot) else null
	if unit == null or unit.eat_rate() <= 0:
		return "That unit doesn't take Acorns"
	if not unit.can_gain_permanent():
		return "Its permanent buffs are capped; cash the Acorn instead."
	var item: HandItem = player.items[index]
	var stats: int = unit.acorn_stats(item.gold_value())
	player.items.remove_at(index)
	unit.add_permanent(stats, stats)
	player.log_event("eat", {"unit": unit.def_id(), "card": item.def_id(), "stats": stats})
	player.log_event("trigger", {"mechanic": "eats_acorns", "source": unit.def_id()})
	rules.events.fire(player, "on_item_played", {"card_def": item.def})
	rules.board_changed(player)
	return ""
