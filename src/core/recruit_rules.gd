# gdlint:disable=max-public-methods
# One public method per rule or action of chapters 3-8; splitting them would hide the list.
class_name RecruitRules
extends RefCounted
## The Recruit Phase actions of rulebook chapters 3-7 on one PlayerState, shared by the human
## and the bots. Actions return "" on success, else a short reason the UI can show. Every trigger
## goes through `events`, every change of gold through spend() or give_gold().

const CHOOSE_FIRST: String = "Make your choice first"
const ACORN: String = "acorn"
const BEADLE: String = "beadle"
const ECHO: String = "echo"
## How many of an Acorn item combine into the next size.
const COMBINE_COUNT: int = 3

var library: UnitLibrary
var config: GameConfig
var pool: UnitPool
## The Tavern spell pool (5.1.2's second row), only when spells are in the shop.
var spell_pool: UnitPool
var events: RecruitEvents
## 5.2.4 this lobby's tribes; empty means all. Bots read it to know which builds are possible.
var lobby_tribes: PackedStringArray = []
## QA hooks (tools/checks/soak.gd): choice_observer(player, pick, options) after each Discover
## offer.
var choice_observer: Callable = Callable()
## Read-only measurement hook, after a shop is ready for its player.
var shop_observer: Callable = Callable()
var _next_iid: int = 1
var _settling: bool = false


static func create(
	unit_library: UnitLibrary, game_config: GameConfig, unit_pool: UnitPool
) -> RecruitRules:
	var rules := RecruitRules.new()
	rules.library = unit_library
	rules.config = game_config
	rules.pool = unit_pool
	rules.events = RecruitEvents.create(rules)
	if game_config.get_bool("spells_in_shop"):
		rules.spell_pool = UnitPool.from_cards(
			unit_library.pool_spells(game_config.card_set()),
			game_config,
			"spell_copies_by_tier",
			PackedStringArray()
		)
	return rules


## A fresh instance id for the game (6.2 iid).
func new_iid() -> int:
	_next_iid += 1
	return _next_iid - 1


func setup_player(player: PlayerState) -> void:
	player.health = config.get_int("starting_health")
	player.tier = 1
	player.gold = 0
	player.upgrade_cost = base_upgrade_cost(1)
	player.freezes_left = config.get_int("freeze_toggles_per_turn")


## 4.6.2: the base cost to upgrade from `tier` to the next; -1 at the top tier.
func base_upgrade_cost(tier: int) -> int:
	if tier >= UnitLibrary.TIERS:
		return -1
	return config.get_int_at("upgrade_costs", tier - 1)


## 6.1.1 units column; rule handlers may change it when a player is given.
func shop_size(tier: int, player: PlayerState = null) -> int:
	var base: int = config.get_int_at("shop_units_by_tier", tier - 1)
	if player == null:
		return base
	return maxi(0, ask("shop_size", player, base) + MarketStalls.unit_bonus(self, player, tier))


## 4.6.3: what the next upgrade costs right now.
func tier_up_cost(player: PlayerState) -> int:
	return maxi(0, ask("tier_up_cost", player, player.upgrade_cost) - player.hunt_discount)


## A rule query: walks the player's handlers in the order they were added and returns the answer.
## refresh_cost, tier_up_cost, income, shop_size and sell_value go through here (architecture-notes
## 1-2). Heroes and effects add handlers; nothing edits GameConfig.
func ask(query: String, player: PlayerState, base: int) -> int:
	var answer: int = base
	for handler: Dictionary in player.rule_handlers:
		if str(handler["query"]) != query or not _handler_applies(handler, player):
			continue
		var value: int = handler["value"]
		match str(handler["op"]):
			"add":
				answer += value
			"set":
				answer = value
			"min":
				answer = mini(answer, value)
			"max":
				answer = maxi(answer, value)
	return answer


func _handler_applies(handler: Dictionary, player: PlayerState) -> bool:
	if handler.get("next_turn", false):
		return false
	if not handler.has("if"):
		return true
	var ctx: RecruitContext = RecruitContext.make(self, player, "rule", {})
	return EffectConditions.all_hold(handler, ctx)


## 4.4.2-4.4.3: the cost of the next paid refresh.
func refresh_cost(player: PlayerState) -> int:
	if player.free_refreshes > 0:
		return 0
	var base: int = config.get_int("refresh_base_cost")
	var first_step: int = config.get_int("refresh_first_step_after")
	var step: int = maxi(1, config.get_int("refresh_step_length"))
	if player.paid_refreshes >= first_step:
		@warning_ignore("integer_division")
		base += 1 + (player.paid_refreshes - first_step) / step
	return maxi(0, ask("refresh_cost", player, base))


## 3.2.1 start of the Recruit Phase on turn `round`.
func start_phase(player: PlayerState, round_number: int) -> void:
	player.round_number = round_number
	player.recruit_log.clear()
	player.carried_gold = player.gold
	var income: int = config.get_int_at("income_by_turn", round_number - 1)
	player.gold += maxi(0, ask("income", player, income)) + player.gold_next_turn
	player.gold_next_turn = 0
	player.gold_spent_turn = 0
	RecruitExtras.rainy_day(player)
	player.gold_at_start = player.gold
	player.buys_this_turn = 0
	player.spells_bought_turn = 0
	RecruitExtras.repay_debt(player)
	if round_number >= 2 and player.tier < UnitLibrary.TIERS:
		var discount: int = config.get_int("upgrade_discount_per_turn")
		player.upgrade_cost = maxi(0, player.upgrade_cost - discount)
	player.paid_refreshes = 0
	player.freezes_left = config.get_int("freeze_toggles_per_turn")
	_reset_limits(player)
	player.power_uses_left = HeroRules.uses_per_turn(player.hero)
	_fill_shop(player)
	HunterRecruit.start_turn(player)
	observe_shop(player)
	player.frozen = false
	HeldUnits.land_due(self, player)
	events.fire(player, "start_of_turn")


## 3.4.1 end of the Recruit Phase: units count this turn in their slots, Passes land, End of Turn
## effects run on the board in reading order (step 1), then unfrozen shop cards return to the pool
## (5.3.2).
func end_phase(player: PlayerState) -> void:
	while player.is_choosing():
		choose(player, 0)
	board_changed(player)
	BoardUpkeep.tick_turns(self, player)
	BoardUpkeep.resolve_passes(self, player)
	events.fire(player, "end_of_turn")
	HunterRecruit.expire(self, player)
	HeldUnits.wash_shop(player)
	var kept: Array[Dictionary] = []
	for handler: Dictionary in player.rule_handlers:
		if handler.get("next_turn", false):
			handler["next_turn"] = false
			handler["turn_only"] = true
			kept.append(handler)
		elif not handler.get("turn_only", false):
			kept.append(handler)
	player.rule_handlers = kept
	if not player.frozen:
		_return_shop(player)


## Whenever a unit, an item or a slot effect changes: Rings and auras, bands and Shy catch up.
func board_changed(player: PlayerState) -> void:
	if _settling:
		return
	_settling = true
	BoardUpkeep.settle(self, player)
	_settling = false


## After the round's fights (12.1.1): "next combat" buffs and combat-only keywords end, then
## "after combat" effects run.
func after_fights(player: PlayerState) -> void:
	check_triples(player)
	for effects: Array in player.slot_effects:
		for index: int in range(effects.size() - 1, -1, -1):
			var effect: Dictionary = effects[index]
			if str(effect.get("name", "")) == "Horseshoe":
				effects.remove_at(index)
	for unit: RecruitUnit in player.owned_units():
		unit.clear_combat_layer()
	board_changed(player)
	events.fire(player, "after_combat")


## Takes gold for an action the caller has checked it can afford (4.1.5).
func spend(player: PlayerState, cost: int) -> void:
	player.gold -= cost
	player.gold_spent_turn += cost
	player.gold_spent_game += cost
	if cost > 0:
		events.fire(player, "on_gold_spent", {"amount": cost})


## Gold from an effect: "now", or "next_turn" (it arrives in the next start-of-turn step 1).
func give_gold(player: PlayerState, amount: int, when: String = "now") -> void:
	if when == "next_turn":
		player.gold_next_turn += amount
	else:
		player.gold = maxi(0, player.gold + amount)
	player.log_event("gold", {"amount": amount, "when": when})


## 4.2 buy a shop unit into hand.
func buy(player: PlayerState, shop_index: int) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if shop_index < 0 or shop_index >= player.shop.size():
		return "No unit there"
	var cost: int = unit_cost(player, player.shop[shop_index])
	if player.gold < cost:
		return "Not enough gold"
	if not has_hand_space(player):
		return "Hand is full"
	if buys_left(player) == 0:
		return "Pipkin can buy only two units each turn; no unit buys left."
	var unit: RecruitUnit = player.shop[shop_index]
	player.shop.remove_at(shop_index)
	unit.poached_discount = 0
	player.hand.append(unit)
	HeldUnits.note_bought(self, player, unit, cost)
	check_triples(player)
	return ""


## A shop unit goes straight into a Belly on the board, or a hand or board unit does. Not a play.
func swallow(player: PlayerState, source: String, index: int, into_slot: int) -> String:
	return (
		CHOOSE_FIRST
		if player.is_choosing()
		else HeldUnits.swallow(self, player, source, index, into_slot)
	)


## What a shop unit costs this player now (Market Day).
func unit_cost(player: PlayerState, unit: RecruitUnit = null) -> int:
	var discount: int = 0 if unit == null else unit.poached_discount
	return maxi(0, ask("unit_cost", player, config.get_int("unit_cost")) - discount)


## Pipkin's limit: how many more units may be bought this turn; -1 for no limit.
func buys_left(player: PlayerState) -> int:
	var limit: int = ask("buys_per_turn", player, -1)
	return -1 if limit < 0 else maxi(0, limit - player.buys_this_turn)


## What a fight needs to know of this player: the Larder and the rules that bend the fight.
func fight_rules(player: PlayerState) -> Dictionary:
	return {
		"larder": player.larder(),
		"back_row_first": ask("back_row_first", player, 0) > 0,
		"bands": player.bands.duplicate(),
		"ammo": player.acorn_values(),
		"nests": HeldUnits.nest_rules(player),
		"goose": HeldUnits.goose_strikes(player),
		"away_birds": HeldUnits.away_birds(player),
	}


## 4.3 sell a board unit.
func sell(player: PlayerState, slot: int) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if not BoardGeometry.is_valid(slot) or player.board[slot] == null:
		return "No unit there"
	var unit: RecruitUnit = player.board[slot]
	events.fire(player, "on_sell", {"subject": unit})
	var now_at: int = player.board.find(unit)
	if now_at < 0:
		return ""
	player.board[now_at] = null
	if HeldUnits.flies(unit, player):
		HeldUnits.send_south(self, player, unit, now_at)
	else:
		player.gold += sell_value(unit, player)
		pool.give_back(unit.pool_id(), unit.pool_copies)
		player.log_event("sell", {"unit": unit.def_id()})
		HeldUnits.release(self, player, unit)
	board_changed(player)
	HeldUnits.drain_doorstep(self, player)
	return ""


## 4.3.3-4.3.4.
func sell_value(unit: RecruitUnit, player: PlayerState = null) -> int:
	var base: int = config.get_int("sell_created")
	if unit.from_triple or unit.origin == RecruitUnit.ORIGIN_BOUGHT:
		base = config.get_int("sell_bought")
	base += (
		CoreUtil.to_int(unit.counters.get("savings", 0)) * unit.mechanic_number("savings", "gold")
	)
	return base if player == null else maxi(0, ask("sell_value", player, base))


## 7.2 play a hand unit into an empty slot.
func play(player: PlayerState, hand_index: int, slot: int) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if hand_index < 0 or hand_index >= player.hand.size():
		return "No unit there"
	if not BoardGeometry.is_valid(slot):
		return "No such slot"
	if player.board[slot] != null:
		return "That slot is taken"
	var unit: RecruitUnit = player.hand[hand_index]
	player.hand.remove_at(hand_index)
	player.board[slot] = unit
	unit.played_round = player.round_number
	player.log_event("play", {"unit": unit.def_id(), "slot": slot})
	if unit.reward_pending:
		unit.reward_pending = false
		_triple_reward(player)
	board_changed(player)
	if player.board[slot] == unit:
		events.fire(player, "on_play", {"subject": unit})
	board_changed(player)
	HeldUnits.drain_doorstep(self, player)
	return ""


## 8.3.3 move into an empty slot, or swap two units. Free.
func move(player: PlayerState, from_slot: int, to_slot: int) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if not BoardGeometry.is_valid(from_slot) or not BoardGeometry.is_valid(to_slot):
		return "No such slot"
	if player.board[from_slot] == null:
		return "No unit there"
	move_on_board(player, from_slot, to_slot)
	return ""


## 8.3.3: the move itself, also used by mechanics. False if nothing moved.
func move_on_board(player: PlayerState, from_slot: int, to_slot: int) -> bool:
	var unit: RecruitUnit = player.board[from_slot]
	if unit == null or from_slot == to_slot:
		return false
	var other: RecruitUnit = player.board[to_slot]
	player.board[from_slot] = other
	player.board[to_slot] = unit
	unit.reset_turns()
	if other != null:
		other.reset_turns()
	player.log_event("move", {"unit": unit.def_id(), "from": from_slot, "to": to_slot})
	board_changed(player)
	events.fire(player, "on_move", {"subject": unit, "amount": from_slot})
	return true


## 4.4 refresh: a free refresh is used first (4.4.5), else gold.
func refresh(player: PlayerState) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if player.free_refreshes > 0:
		player.free_refreshes -= 1
		replace_shop(player, false)
		return ""
	var cost: int = refresh_cost(player)
	if player.gold < cost:
		return "Not enough gold"
	player.paid_refreshes += 1
	spend(player, cost)
	replace_shop(player, true)
	return ""


## 4.4.6: the shop's cards are replaced, frozen or not. Costs nothing and counts toward nothing.
func replace_shop(player: PlayerState, paid: bool = false) -> void:
	var poached: Array[RecruitUnit] = HunterRecruit.pull_offers(player)
	_return_shop(player)
	player.shop.append_array(poached)
	player.frozen = false
	_fill_shop(player)
	observe_shop(player)
	events.fire(player, "on_refresh", {"paid": paid})


## Shake the Tree: a refresh that keeps one shop card. Not paid and not counted toward anything.
func refresh_keeping(player: PlayerState, shop_index: int) -> void:
	if shop_index < 0 or shop_index >= player.shop.size():
		return
	var kept: RecruitUnit = player.shop[shop_index]
	player.shop.remove_at(shop_index)
	var poached: Array[RecruitUnit] = HunterRecruit.pull_offers(player)
	_return_shop(player)
	player.shop.append_array(poached)
	player.frozen = false
	player.shop.append(kept)
	_fill_shop(player)
	observe_shop(player)
	events.fire(player, "on_refresh", {"paid": false})


## 4.5.1 freeze toggles.
func toggle_freeze(player: PlayerState) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if player.freezes_left <= 0:
		return "No freezes left this turn"
	player.frozen = not player.frozen
	player.freezes_left -= 1
	return ""


## 4.6 upgrade the tier. No shop refill (4.6.5).
func tier_up(player: PlayerState) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if player.tier >= UnitLibrary.TIERS:
		return "Already at the top tier"
	var cost: int = tier_up_cost(player)
	if player.gold < cost:
		return "Not enough gold"
	var climb: int = maxi(1, ask("tier_step", player, 1))
	player.tier = mini(player.tier + climb, UnitLibrary.TIERS)
	player.upgrade_cost = base_upgrade_cost(player.tier)
	player.hunt_discount = 0
	spend(player, cost)
	events.fire(player, "on_tier_up")
	return ""


## Jill Down-the-Tree: one tier down; going back up costs `climb_back` if given, else full price.
func tier_down(player: PlayerState, climb_back: int = 0) -> void:
	player.tier = maxi(1, player.tier - 1)
	player.upgrade_cost = base_upgrade_cost(player.tier)
	if climb_back > 0:
		player.upgrade_cost = mini(player.upgrade_cost, climb_back)
	player.log_event("tier_down", {"tier": player.tier})


## 7.3.1: any three non-golden copies of a unit across board and hand combine at once. Call it
## whenever a unit reaches the hand or board in the Recruit Phase (7.3.2).
func check_triples(player: PlayerState) -> void:
	TribeBonus.sync(player)
	var found: bool = true
	while found:
		found = _one_triple(player) or HeldUnits.figgy_pair(self, player)


func _one_triple(player: PlayerState) -> bool:
	var groups: Dictionary = {}
	for unit: RecruitUnit in player.owned_units():
		if unit.golden or unit.plain_copy:
			continue
		var copies: Array = groups.get(unit.def_id(), [])
		copies.append(unit)
		groups[unit.def_id()] = copies
		if copies.size() >= 3:
			combine(player, copies, true)
			return true
	return false


## 7.3.4: double base stats plus every copy's buffs and debuffs, summed from their layers, each
## stat at least the golden base. 7.3.7: on a full hand the golden takes the first vacated slot.
## 5.3.5: it holds the copies' pool copies. Figgy Duff's pairs make no Triple Reward. A copy inside
## a Belly counts and leaves it; a tripled Ooze's contents go to hand.
func combine(player: PlayerState, copies: Array, reward: bool) -> void:
	var first: RecruitUnit = copies[0]
	var golden := RecruitUnit.make(first.def, new_iid(), true)
	var vacated: Array[int] = []
	var any_bought: bool = false
	for entry: Variant in copies:
		var copy: RecruitUnit = entry
		golden.add_permanent(copy.perm_attack, copy.perm_health)
		golden.add_combat(copy.combat_attack, copy.combat_health)
		golden.pool_copies += copy.pool_copies
		if copy.pool_origin != "":
			golden.pool_origin = copy.pool_origin
		if copy.counters.has("kisses"):
			golden.counters["kisses"] = maxi(
				CoreUtil.to_int(golden.counters.get("kisses", 0)),
				CoreUtil.to_int(copy.counters.get("kisses", 0))
			)
		# A wait the player paid for stays: it starts over when the golden lands, as any move does.
		golden.timers.append_array(copy.timers)
		if copy.counters.has("hex"):
			var grown: int = CoreUtil.to_int(golden.counters.get("hex", 0))
			golden.counters["hex"] = grown + CoreUtil.to_int(copy.counters["hex"])
		any_bought = any_bought or copy.origin == RecruitUnit.ORIGIN_BOUGHT
		var slot: int = player.board.find(copy)
		if slot >= 0:
			player.board[slot] = null
			vacated.append(slot)
		else:
			HeldUnits.take_out(player, copy)
		HeldUnits.release(self, player, copy)
	golden.perm_attack = maxi(0, golden.perm_attack)
	golden.perm_health = maxi(0, golden.perm_health)
	golden.origin = RecruitUnit.ORIGIN_BOUGHT if any_bought else RecruitUnit.ORIGIN_CREATED
	golden.from_triple = true
	if has_hand_space(player):
		golden.reward_pending = reward
		player.hand.append(golden)
	elif vacated.is_empty():
		golden.reward_pending = reward
		player.doorstep.append(golden)
	else:
		vacated.sort()
		golden.played_round = player.round_number
		player.board[vacated[0]] = golden
	board_changed(player)
	player.log_event("triple", {"unit": golden.def_id()})
	events.fire(player, "on_triple", {"subject": golden})


## 7.3.6: a Triple Reward spell goes to hand: Discover from the tier above, cast when you like.
## Lost on a full hand (7.1.2).
func _triple_reward(player: PlayerState) -> void:
	give_card(player, "triple_reward")


## 8.4: summons onto the recruit board, next to `source_slot` (-1 for no slot, 8.4.3). All of
## them arrive before a triple can form (7.3.2). A full board loses the rest (8.4.5). Created.
func summon_units(
	player: PlayerState, def_id: String, count: int, golden: bool, source_slot: int
) -> void:
	var unit_def: Dictionary = library.get_unit(def_id)
	if unit_def.is_empty():
		push_error("Summon of an unknown unit '%s'" % def_id)
		return
	var slots: Array[int] = []
	var taken: Array[bool] = player.occupied()
	var missed: int = 0
	for _index: int in count:
		var slot: int = BoardGeometry.summon_slot(taken, source_slot, false)
		if slot < 0:
			player.log_event("no_room", {"unit": def_id, "name": str(unit_def["name"])})
			missed += 1
			continue
		taken[slot] = true
		slots.append(slot)
	place_summons(player, def_id, golden, slots)
	if _board_has(player, BEADLE):
		for _miss: int in missed:
			spill(player)


## Summoned units arrive in these slots, all before a triple can form (7.3.2). Created.
func place_summons(player: PlayerState, def_id: String, golden: bool, slots: Array[int]) -> void:
	var unit_def: Dictionary = library.get_unit(def_id)
	var arrived: Array[RecruitUnit] = []
	for slot: int in slots:
		var unit := RecruitUnit.make(unit_def, new_iid(), golden)
		unit.origin = RecruitUnit.ORIGIN_CREATED
		player.board[slot] = unit
		arrived.append(unit)
		player.log_event("summon", {"unit": def_id, "slot": slot})
	board_changed(player)
	for unit: RecruitUnit in arrived:
		events.fire(player, "on_summon", {"subject": unit})
	check_triples(player)


## Spill: a summon found no room, so an Acorn arrives instead.
func spill(player: PlayerState) -> void:
	player.log_event("spill", {})
	give_card(player, ACORN)
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit != null and unit.has_mechanic_id(BEADLE):
			var stats: int = unit.mechanic_number(BEADLE, "stats")
			player.pending_passes.append(
				{"iid": unit.iid, "slot": slot, "attack": stats, "health": stats}
			)


static func _board_has(player: PlayerState, mechanic_id: String) -> bool:
	for unit: RecruitUnit in player.board:
		if unit != null and unit.has_mechanic_id(mechanic_id):
			return true
	return false


## Gives a player a card by id: a unit into hand, Created; with `from_pool` it takes a real copy
## and returns nothing if none is left (4.3.2). Lost on a full hand (7.1.2).
func give_card(player: PlayerState, card: String, from_pool: bool = false) -> void:
	var unit_def: Dictionary = library.get_unit(card)
	if unit_def.is_empty():
		_give_item(player, card, from_pool)
		return
	if from_pool and not pool.take(card):
		return
	if not has_hand_space(player):
		if from_pool:
			pool.give_back(card)
		return
	var unit := RecruitUnit.make(unit_def, new_iid())
	unit.origin = RecruitUnit.ORIGIN_CREATED
	unit.pool_copies = 1 if from_pool else 0
	player.hand.append(unit)
	player.log_event("card", {"card": card})
	check_triples(player)


## A spell or item by id. Generated, so it holds no pool copy unless `from_pool` (5.3.6).
func _give_item(player: PlayerState, card: String, from_pool: bool) -> void:
	var card_def: Dictionary = library.get_card(card)
	if card_def.is_empty():
		push_error("Unknown card '%s'" % card)
		return
	if not has_hand_space(player) and not RecruitExtras.completes_three(player, card_def):
		return
	var item := HandItem.make(card_def, new_iid())
	if from_pool and spell_pool != null and spell_pool.take(card):
		item.pool_copies = 1
	player.items.append(item)
	player.log_event("card", {"card": card})
	RecruitExtras.combine_items(self, player)
	board_changed(player)


## 7.1.1: the hand holds up to the limit, counting every card in it.
func has_hand_space(player: PlayerState) -> bool:
	return player.hand.size() + player.items.size() < config.get_int("hand_limit")


## 4.2.5: buy a Tavern spell for its own cost; it goes to hand. Prices never rise within a turn.
func spell_cost(player: PlayerState, item: HandItem) -> int:
	return BogFolk.spell_cost(player, item)


func buy_spell(player: PlayerState, index: int) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if index < 0 or index >= player.shop_spells.size():
		return "No spell there"
	var item: HandItem = player.shop_spells[index]
	if item.def_id() == MarketStalls.CARD and MarketStalls.limit_reached(player):
		return "At most 2 Stalls"
	var cost: int = spell_cost(player, item)
	if player.gold < cost:
		return "Not enough gold"
	if not has_hand_space(player):
		return "Hand is full"
	player.shop_spells.remove_at(index)
	item.paid_cost = cost
	player.items.append(item)
	MarketStalls.remove_unavailable(self, player)
	player.log_event("buy_spell", {"card": item.def_id()})
	player.spells_bought_turn += 1
	spend(player, cost)
	return ""


## 6.1.5: plays a spell or item from hand, aimed at `slot` if it needs that (-1 for none). A spell
## is single use and its copy goes back to the pool (5.3.7).
func play_item(player: PlayerState, index: int, slot: int = -1) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	if index < 0 or index >= player.items.size():
		return "No card there"
	var item: HandItem = player.items[index]
	if item.def_id() == MarketStalls.CARD and player.market_stalls >= MarketStalls.LIMIT:
		return "At most 2 Stalls"
	if slot >= 0 and item.gold_value() > 0:
		return _feed(player, index, slot)
	var problem: String = aim_problem(player, item.aim(), slot)
	if problem == "":
		problem = TribeBonus.cast_problem(player, item, slot)
	if problem != "":
		return problem
	player.items.remove_at(index)
	if spell_pool != null:
		spell_pool.give_back(item.def_id(), item.pool_copies)
	var fields: Dictionary = _aim_fields(player, item.aim(), slot)
	fields["card_def"] = item.def
	var ctx: RecruitContext = RecruitContext.make(self, player, "cast", fields)
	ctx.params = item.def
	player.log_event("cast", {"card": item.def_id(), "slot": slot})
	EffectRunner.run(item.def, ctx)
	RecruitExtras.echo(self, player, item, slot, ctx)
	if item.is_spell():
		events.fire(player, "on_spell_cast", fields)
	board_changed(player)
	HeldUnits.drain_doorstep(self, player)
	return ""


## "You may play Acorn items on this": stats for the gold the item is worth, and no gold.
func _feed(player: PlayerState, index: int, slot: int) -> String:
	return HeldUnits.feed(self, player, index, slot)


## Why this aim can't be used; "" if it's fine.
func aim_problem(player: PlayerState, aim: String, slot: int) -> String:
	match aim:
		HandItem.AIM_UNIT, HandItem.AIM_TRIBE_UNIT:
			if not BoardGeometry.is_valid(slot) or player.board[slot] == null:
				return "Choose a unit on your board"
			if aim == HandItem.AIM_TRIBE_UNIT and player.board[slot].tribes().is_empty():
				return "Choose a unit with a tribe"
		HandItem.AIM_EMPTY_SLOT:
			if not BoardGeometry.is_valid(slot) or player.board[slot] != null:
				return "Choose an empty slot"
		HandItem.AIM_ANY_SLOT:
			if not BoardGeometry.is_valid(slot):
				return "Choose a slot"
		HandItem.AIM_SHOP_UNIT:
			if slot < 0 or slot >= player.shop.size():
				return "Choose a unit in the shop"
	return _row_aim_problem(player, aim, slot)


static func _row_aim_problem(player: PlayerState, aim: String, slot: int) -> String:
	if aim == HandItem.AIM_FRONT_UNIT and not _unit_in_row(player, slot, true):
		return "Choose a unit in your front row"
	if aim == HandItem.AIM_BACK_UNIT and not _unit_in_row(player, slot, false):
		return "Choose a unit in your back row"
	return ""


static func _unit_in_row(player: PlayerState, slot: int, front: bool) -> bool:
	return (
		BoardGeometry.is_valid(slot)
		and player.board[slot] != null
		and BoardGeometry.is_front(slot) == front
	)


## A shop aim's "slot" is a shop index, so it names no unit on the board.
func _aim_fields(player: PlayerState, aim: String, slot: int) -> Dictionary:
	var fields: Dictionary = {"chosen_slot": slot}
	if aim == HandItem.AIM_SHOP_UNIT:
		return fields
	if BoardGeometry.is_valid(slot) and player.board[slot] != null:
		fields["chosen"] = player.board[slot]
	return fields


## 2.2.7: uses an activated hero power, aimed like a spell.
func use_power(player: PlayerState, slot: int = -1) -> String:
	if player.is_choosing():
		return CHOOSE_FIRST
	var power: Dictionary = HeroRules.power_of(player.hero)
	var aim: String = str(power.get("aim", HandItem.AIM_NONE))
	var problem: String = _power_problem(player, power, aim, slot)
	if problem != "":
		return problem
	player.power_uses_left -= 1
	player.log_event("power", {"hero": str(player.hero.get("id", "")), "slot": slot})
	spend(player, CoreUtil.to_int(power.get("cost", 0)))
	var ctx: RecruitContext = RecruitContext.make(
		self, player, "activated", _aim_fields(player, aim, slot)
	)
	ctx.params = power
	EffectRunner.run(power, ctx)
	board_changed(player)
	return ""


func _power_problem(player: PlayerState, power: Dictionary, aim: String, slot: int) -> String:
	if str(power.get("kind", "")) != HeroRules.ACTIVATED:
		return "No power to use"
	if player.power_uses_left <= 0:
		return "Already used this turn"
	if player.gold < CoreUtil.to_int(power.get("cost", 0)):
		return "Not enough gold"
	if not power_usable(player):
		return "Can't use that now"
	return aim_problem(player, aim, slot)


## An activated power's "if": whether it may be used right now, before anyone pays for it.
func power_usable(player: PlayerState) -> bool:
	var ctx: RecruitContext = RecruitContext.make(self, player, "activated", {})
	return EffectConditions.all_hold(HeroRules.power_of(player.hero), ctx)


## 6.2: a Discover from a step {"count", "tier", "tribe", "not_tribe", "kind"}. Options are out
## of the pool while shown (5.3.3). With none eligible it does nothing (6.2.3).
func discover(player: PlayerState, step: Dictionary) -> void:
	RecruitDiscover.run(self, player, step)


## Makes the oldest waiting choice. 5.3.3: the chosen card stays out of the pool, the others go
## back; it arrives Created (4.3.2), and is lost with its copy returned on a full hand (7.1.2).
func choose(player: PlayerState, index: int) -> String:
	if not player.is_choosing():
		return "Nothing to choose"
	var choice: Dictionary = player.pending[0]
	var options: PackedStringArray = choice["options"]
	if options.is_empty():
		player.pending.remove_at(0)
		return ""
	if index < 0 or index >= options.size():
		return "No such option"
	player.pending.remove_at(0)
	var from_spells: bool = choice["spells"]
	var source_pool: UnitPool = spell_pool if from_spells else pool
	for other: int in options.size():
		if other != index:
			source_pool.give_back(options[other])
	_receive_discovered(player, options[index], from_spells, source_pool)
	return ""


func _receive_discovered(
	player: PlayerState, card: String, from_spells: bool, source_pool: UnitPool
) -> void:
	player.log_event("chose", {"card": card})
	if not has_hand_space(player):
		source_pool.give_back(card)
		return
	if from_spells:
		var item := HandItem.make(library.get_card(card), new_iid())
		item.pool_copies = 1
		player.items.append(item)
		return
	var unit := RecruitUnit.make(library.get_unit(card), new_iid())
	unit.origin = RecruitUnit.ORIGIN_CREATED
	unit.pool_copies = 1
	player.hand.append(unit)
	check_triples(player)


## Damage in the Recruit Phase is permanent. At 0 Health the unit is destroyed and its copies go
## back (5.3.7).
func damage_unit(player: PlayerState, unit: RecruitUnit, amount: int) -> void:
	unit.add_permanent(0, -amount)
	player.log_event("damage", {"target": unit.def_id(), "amount": amount})
	if unit.health <= 0:
		destroy_unit(player, unit)


## A unit on the board is destroyed in the Recruit Phase: its copies go back (5.3.7).
func destroy_unit(player: PlayerState, unit: RecruitUnit) -> void:
	var slot: int = player.board.find(unit)
	if slot < 0:
		return
	player.board[slot] = null
	pool.give_back(unit.pool_id(), unit.pool_copies)
	player.log_event("destroyed", {"target": unit.def_id(), "slot": slot})
	HeldUnits.release(self, player, unit)
	board_changed(player)


## Applies what a fight sent back (12.1.1 "permanently"; gold and cards earned in combat).
func apply_carry(player: PlayerState, change: Dictionary) -> void:
	RecruitCarry.apply(self, player, change)


## Sergeant-at-Conkers threw an Acorn item worth this much.
static func _spend_acorn(player: PlayerState, gold: int) -> void:
	for index: int in player.items.size():
		if player.items[index].gold_value() == gold:
			player.items.remove_at(index)
			player.log_event("thrown", {"gold": gold})
			return


## 5.3.8: all pool copies a player holds go back (board, hand and shop).
func return_everything(player: PlayerState) -> void:
	for unit: RecruitUnit in player.all_units():
		pool.give_back(unit.pool_id(), unit.pool_copies)
	player.poached_pending.clear()
	player.away.clear()
	player.doorstep.clear()
	while player.is_choosing():
		choose(player, 0)
		for unit: RecruitUnit in player.hand:
			pool.give_back(unit.pool_id(), unit.pool_copies)
		player.hand.clear()
	_return_shop(player)
	if spell_pool != null:
		for item: HandItem in player.items:
			spell_pool.give_back(item.def_id(), item.pool_copies)
	player.items.clear()
	player.hand.clear()
	for slot: int in BoardGeometry.SLOTS:
		player.board[slot] = null


static func _unit_by_iid(player: PlayerState, iid: int) -> RecruitUnit:
	for unit: RecruitUnit in player.owned_units():
		if unit.iid == iid:
			return unit
	return null


## "limit" counts start over each turn.
static func _reset_limits(player: PlayerState) -> void:
	for unit: RecruitUnit in player.owned_units():
		unit.limits.clear()
	player.owner_limits.clear()


## 4.5.2: fill the shop's empty slots up to its size (a frozen shop keeps its cards). 6.1.5 the
## spell slot fills from its own pool on its own stream, so spells can't shift the unit shop.
func _fill_shop(player: PlayerState) -> void:
	var size: int = shop_size(player.tier, player)
	var odds: Array = _shop_odds(player.tier)
	var ordinary: int = size - MarketStalls.unit_bonus(self, player)
	while HunterRecruit.normal_shop_count(player) < size:
		var drawn: String
		if HunterRecruit.normal_shop_count(player) >= ordinary:
			drawn = pool.draw(player.tier, player.shop_rng, player.tier)
		else:
			drawn = pool.draw_by_odds(odds, player.tier, player.shop_rng)
		if drawn == "":
			break
		var unit := RecruitUnit.make(library.get_unit(drawn), new_iid())
		unit.pool_copies = 1
		player.shop.append(unit)
	if spell_pool == null:
		return
	RecruitExtras.show_opening_cards(self, player)
	MarketStalls.remove_unavailable(self, player)
	var spell_slots: int = (
		config.get_int_at("shop_spells_by_tier", player.tier - 1)
		+ MarketStalls.spell_bonus(self, player)
	)
	while player.shop_spells.size() < spell_slots:
		var card: String = MarketStalls.draw_spell(self, player, odds)
		if card == "":
			return
		var item := HandItem.make(library.get_card(card), new_iid())
		item.pool_copies = 1
		player.shop_spells.append(item)


## This tier's odds of showing a card of each tier; [] means every copy left is equally likely.
func _shop_odds(tier: int) -> Array:
	var table: Array = config.get_value("shop_tier_odds")
	if table.is_empty():
		return []
	var row: Array = table[clampi(tier - 1, 0, table.size() - 1)]
	return row


## 5.3.2: shown cards return to the pool.
func _return_shop(player: PlayerState) -> void:
	for unit: RecruitUnit in player.shop:
		pool.give_back(unit.pool_id(), unit.pool_copies)
	player.shop.clear()
	if spell_pool != null:
		for item: HandItem in player.shop_spells:
			spell_pool.give_back(item.def_id(), item.pool_copies)
		player.shop_spells.clear()


func observe_shop(player: PlayerState) -> void:
	if shop_observer.is_valid():
		shop_observer.call(player)
