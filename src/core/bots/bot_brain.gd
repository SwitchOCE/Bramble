class_name BotBrain
extends Bot
## A bot that plays for a build. One turn flow; a BotLevel says what each difficulty does, a
## strategy (content/bots/strategies/) says what the bot wants, BotEval says what a card is worth,
## BotPlacer says where things stand. Name format: level[:strategy][@place], e.g. "hard",
## "hard:hedgerow_parish", "hard@shuffled".

const OPENINGS: Array = ["tempo", "economy", "climb"]
## Bench arm in a bot's name: "normal@refreshes=4".
const REFRESHES_ARM: String = "refreshes"
const MAX_STEPS: int = 60
const NAIVE_TIER_CHANCE: float = 0.25
const NAIVE_SPELL_CHANCE: float = 0.3
const NAIVE_SELL_CHANCE: float = 0.3
const LOCK_BUILD_ROUND: int = 9
## Health at or under this: the bot stops climbing and fights.
const LOW_HEALTH: int = 12
const BEHIND_RATIO: float = 0.7
const AHEAD_RATIO: float = 1.3
const SAFE_HEALTH: int = 18
const FREEZE_GAIN: float = 12.0
## So lobbies see every hero, and a pinned build doesn't always take the same one.
const HERO_NOISE: float = 3.0

var level: BotLevel
var value: BotEval
var knowledge: BotKnowledge
## Set when the bot is pinned to one strategy for the win-spread test.
var pinned_strategy: String = ""
var _opening_plan: String = ""
var _player: PlayerState
var _rules: RecruitRules
var _round_now: int = 1


## A brain from its name, or null if the name isn't a level.
static func from_name(bot_name: String) -> BotBrain:
	var place_split: PackedStringArray = bot_name.split("@")
	var level_split: PackedStringArray = place_split[0].split(":")
	if not BotLevel.ALL.has(level_split[0]):
		return null
	var brain := BotBrain.new()
	brain.personality = bot_name
	brain.knowledge = BotKnowledge.shared()
	brain.level = BotLevel.of(level_split[0])
	brain.value = BotEval.make(brain.level, brain.knowledge)
	if level_split.size() > 1:
		brain.pinned_strategy = level_split[1]
		brain.value.strategy = brain.knowledge.strategy(level_split[1])
		if brain.value.strategy.is_empty():
			push_error("No such strategy: %s" % level_split[1])
	if place_split.size() > 1:
		var place_parts: PackedStringArray = place_split[1].split("=")
		if place_parts[0] == REFRESHES_ARM:
			brain.level.max_refreshes = place_parts[1].to_int()
			return brain
		brain.level.set_place(place_parts[0])
		if place_parts.size() > 1:
			brain.level.search_budget = place_parts[1].to_int()
	return brain


func build_name() -> String:
	return str(value.strategy.get("id", ""))


## 2.2.1: strong levels pick by hero rating and build; the rest at random.
func pick_hero(offer: PackedStringArray, player: PlayerState) -> int:
	if not level.picks_hero:
		return player.bot_rng.randi_range(0, offer.size() - 1)
	var best: int = 0
	var best_score: float = -1000.0
	var heroes: Dictionary = value.strategy.get("heroes", {})
	for index: int in offer.size():
		var hinted: Dictionary = knowledge.hero(offer[index])
		var score: float = (
			BotEval._number(hinted.get("rating", 0))
			+ BotEval._number(heroes.get(offer[index], 0))
			+ HERO_NOISE * player.bot_rng.randf()
		)
		if score > best_score:
			best = index
			best_score = score
	return best


func play_turn(player: PlayerState, rules: RecruitRules, round_number: int) -> void:
	_player = player
	_rules = rules
	_round_now = round_number
	if not level.scouts:
		player.scout = {}
	if level.name == BotLevel.NAIVE:
		_naive_turn()
	else:
		_smart_turn()
	_settle()
	_player = null
	_rules = null


# --- Naive: legal, random, no plan ---------------------------------------------------------------


func _naive_turn() -> void:
	var rng: RandomNumberGenerator = _player.bot_rng
	_settle()
	_cast_everything()
	if rng.randf() < NAIVE_TIER_CHANCE:
		_rules.tier_up(_player)
	var cost: int = _rules.unit_cost(_player)
	for _step: int in MAX_STEPS:
		if _player.gold < cost or _player.shop.is_empty() or not _rules.has_hand_space(_player):
			break
		if _rules.buy(_player, rng.randi_range(0, _player.shop.size() - 1)) != "":
			break
		_settle()
		_naive_play_hand()
	if not _player.shop_spells.is_empty() and rng.randf() < NAIVE_SPELL_CHANCE:
		_rules.buy_spell(_player, rng.randi_range(0, _player.shop_spells.size() - 1))
	_cast_everything()
	_use_power_now()
	_naive_play_hand()


func _naive_play_hand() -> void:
	var rng: RandomNumberGenerator = _player.bot_rng
	var index: int = 0
	while index < _player.hand.size():
		var slot: int = BotPlacer.random_empty_slot(_player)
		if slot < 0 and rng.randf() < NAIVE_SELL_CHANCE:
			slot = rng.randi_range(0, BoardGeometry.SLOTS - 1)
			_rules.sell(_player, slot)
			_settle()
			if _player.board[slot] != null:
				index += 1
				continue
		if slot < 0 or _rules.play(_player, index, slot) != "":
			index += 1
		_settle()


## Plays every card in hand, aimed at random for a naive bot.
func _cast_everything() -> void:
	var index: int = _player.items.size() - 1
	while index >= 0:
		if index < _player.items.size():
			var item: HandItem = _player.items[index]
			_rules.play_item(_player, index, _aim_for(item.aim(), item.def))
			_settle()
		index -= 1


# --- Easy, Normal, Hard: one flow ----------------------------------------------------------------


## Rounds 1-2: Normal and Hard pick one of three openings by a coin toss, as the bench measures how
## they compare (evidence/balance-1.md). Tempo needs no card.
func _open_with_a_plan() -> void:
	if not level.plans_opening or _round_now > 2:
		return
	if _opening_plan == "":
		_opening_plan = OPENINGS[_player.bot_rng.randi_range(0, OPENINGS.size() - 1)]
	if _round_now != 1:
		return
	if _opening_plan == "economy":
		_buy_and_cast("rainy_day")
	elif _opening_plan == "climb":
		_buy_and_cast("a_leg_up")


func _buy_and_cast(card_id: String) -> void:
	for index: int in _player.shop_spells.size():
		if _player.shop_spells[index].def_id() == card_id:
			if _rules.buy_spell(_player, index) == "":
				_settle()
				_rules.play_item(_player, _player.items.size() - 1, -1)
				_settle()
			return


func _smart_turn() -> void:
	_settle()
	_choose_build()
	_open_with_a_plan()
	if level.cash_at_once:
		_cash_all()
	_cast_spells(false)
	BotHeld.fly_turn(_player, _rules, value, _round_now)
	_settle()
	_sell_for_cash()
	_borrow_if_short()
	_climb(false)
	_shop_loop()
	_play_hand()
	_cast_spells(false)
	_maybe_power()
	_shop_loop()
	_climb(true)
	_feed_eaters()
	_cast_spells(true)
	_freeze()
	_settle()
	BotPlacer.arrange(_player, _rules, value, level.place, level.search_budget)


## Normal commits once from turn 3; Hard reads what it holds and sees until the build locks.
func _choose_build() -> void:
	if not level.uses_builds or pinned_strategy != "":
		return
	if level.reads_shop_for_build:
		if _round_now >= LOCK_BUILD_ROUND and not value.strategy.is_empty():
			return
	elif not value.strategy.is_empty() or _round_now < 3:
		return
	var best: Dictionary = value.strategy
	var best_fit: float = 0.0
	if not best.is_empty():
		best_fit = value.strategy_fit(best, _player) * 1.3
	for entry: Dictionary in knowledge.open_strategies(Array(_rules.lobby_tribes)):
		var fit: float = value.strategy_fit(entry, _player)
		if fit > best_fit:
			best = entry
			best_fit = fit
	value.strategy = best


## Climbs when the plan says. With `leftover`, also a turn early if the gold has no better use.
func _climb(leftover: bool) -> void:
	for _step: int in UnitLibrary.TIERS:
		if _player.tier >= UnitLibrary.TIERS:
			return
		var target: int = _target_round(_player.tier)
		if leftover and level.name != BotLevel.EASY:
			target -= 1
		if _round_now < target:
			return
		var cost: int = _rules.tier_up_cost(_player)
		if (
			_round_now >= 2
			and _player.board_count() == 0
			and _player.gold - cost < _rules.unit_cost(_player)
		):
			return
		if not _pay(cost, 100.0 if not leftover else 0.0):
			return
		if _rules.tier_up(_player) != "":
			return
		_settle()


## The round the plan climbs from `tier`, moved by health and by what was scouted.
func _target_round(tier: int) -> int:
	var curve: Array = value.strategy.get("curve", [])
	if curve.is_empty():
		curve = BotLevel.EASY_CURVE if level.name == BotLevel.EASY else BotLevel.DEFAULT_CURVE
		curve = BotLevel.HARD_CURVE if level.name == BotLevel.HARD else curve
	var target: int = CoreUtil.to_int(curve[mini(tier - 1, curve.size() - 1)])
	if _opening_plan == "climb" and tier <= 2:
		target = 2 if tier == 1 else target - 1
	if not level.reads_pressure:
		return target
	if _player.health <= LOW_HEALTH:
		target += 1
	if not _player.scout.is_empty():
		var mine: int = stat_sum(_player.board_specs())
		var seen: Array = _player.scout["specs"]
		var theirs: int = stat_sum(seen)
		if mine < theirs * BEHIND_RATIO:
			target += 1
		elif mine > theirs * AHEAD_RATIO and _player.health >= SAFE_HEALTH:
			target -= 1
	return target


func _shop_loop() -> void:
	var refreshes: int = 0
	for _step: int in MAX_STEPS:
		_settle()
		var offer: Dictionary = _best_offer()
		if not offer.is_empty():
			var cost: int = offer["cost"]
			var gain: float = offer["gain"]
			if _pay(cost, gain) and _buy_offer(offer):
				continue
		var most: int = CoreUtil.to_int(value.strategy.get("max_refreshes", level.max_refreshes))
		if _banks_gold():
			most = mini(most, 1)
		if refreshes >= most or not _refresh_worth_it():
			return
		if _rules.refresh(_player) != "":
			return
		refreshes += 1


## The best thing on offer by gain per gold: {"spell", "index", "cost", "gain"}; {} if nothing is
## worth it.
func _best_offer() -> Dictionary:
	var best: Dictionary = {}
	var best_rate: float = 0.0
	if not _rules.has_hand_space(_player):
		_cash_one()
	if not _rules.has_hand_space(_player):
		return best
	var spare: int = _player.gold + _player.larder() - _held_back()
	var unit_cost: int = _rules.unit_cost(_player)
	if spare >= unit_cost and _rules.buys_left(_player) != 0:
		for index: int in _player.shop.size():
			var gain: float = _unit_gain(_player.shop[index])
			if gain / unit_cost > best_rate:
				best_rate = gain / unit_cost
				best = {"spell": false, "index": index, "cost": unit_cost, "gain": gain}
	if _player.board_count() == 0 or CoreUtil.to_bool(value.strategy.get("no_spells", false)):
		return best
	for index: int in _player.shop_spells.size():
		var item: HandItem = _player.shop_spells[index]
		var cost: int = maxi(1, _rules.spell_cost(_player, item))
		if _rules.spell_cost(_player, item) > spare or value.has_flag(item.def_id(), "avoid"):
			continue
		if not _can_aim(item.aim()):
			continue
		var gain: float = value.spell_value(item.def, _player.gold + _player.larder())
		if gain / cost > best_rate:
			best_rate = gain / cost
			best = {
				"spell": true,
				"index": index,
				"cost": _rules.spell_cost(_player, item),
				"gain": gain
			}
	return best


## A unit's gain over what it would replace; not positive when the bot shouldn't buy it.
func _unit_gain(unit: RecruitUnit) -> float:
	var worth: float = value.buy_value(unit, _player)
	worth *= 1.0 + level.buy_noise * _player.bot_rng.randf_range(-1.0, 1.0)
	if BotEval.copies_of(_player, unit.def_id()) >= 2:
		return worth
	if _room_left() > _player.hand.size():
		return worth
	if BotHeld.best_belly(_player, value, unit) >= 0:
		return worth * BotHeld.INSIDE_WORTH
	var weakest: int = _weakest_slot()
	if weakest < 0:
		return 0.0
	return worth - value.keep_value(_player.board[weakest]) - level.replace_margin


## Slots the bot means to fill. A build or hero that wants gaps has fewer than 7.
func _room_left() -> int:
	var most: int = CoreUtil.to_int(value.strategy.get("max_units", BoardGeometry.SLOTS))
	var hero_hint: Dictionary = knowledge.hero(str(_player.hero.get("id", "")))
	most = mini(most, CoreUtil.to_int(hero_hint.get("max_units", BoardGeometry.SLOTS)))
	return mini(most, BoardGeometry.SLOTS) - _player.board_count()


func _weakest_slot() -> int:
	var weakest: int = -1
	var lowest: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _player.board[slot]
		if unit == null:
			continue
		var worth: float = value.keep_value(unit)
		if weakest < 0 or worth < lowest:
			weakest = slot
			lowest = worth
	return weakest


func _buy_offer(offer: Dictionary) -> bool:
	var index: int = offer["index"]
	var spell: bool = offer["spell"]
	var problem: String = _rules.buy_spell(_player, index) if spell else _buy_unit(index)
	if problem != "":
		return false
	_settle()
	_play_hand()
	_cast_spells(false)
	return true


func _buy_unit(index: int) -> String:
	var unit: RecruitUnit = _player.shop[index]
	var slot: int = BotHeld.best_belly(_player, value, unit)
	var no_room: bool = _room_left() <= _player.hand.size()
	if BotHeld.buys_into_belly(_player, value, unit, slot, no_room):
		return _rules.swallow(_player, HeldUnits.SHOP, index, slot)
	return _rules.buy(_player, index)


## Whether another shop is worth a coin: only with enough left to buy from it.
func _refresh_worth_it() -> bool:
	var cost: int = _rules.refresh_cost(_player)
	var after: int = _player.gold - cost + _player.larder() - _held_back()
	if after < _rules.unit_cost(_player):
		return false
	return _player.gold >= cost


## A unit on the board turns gold left at End of Turn into stats, so looking at more shops costs it.
func _banks_gold() -> bool:
	for unit: RecruitUnit in _player.board:
		if unit != null and value.has_flag(unit.def_id(), "banks_gold"):
			return true
	return false


## Gold the build keeps back: [[until_round, gold], ...] in the strategy or on the hero.
func _held_back() -> int:
	if _player.board_count() == 0 or _player.health <= LOW_HEALTH:
		return 0
	var total: int = _climb_savings()
	var plans: Array = [value.strategy.get("save", [])]
	plans.append(knowledge.hero(str(_player.hero.get("id", ""))).get("save", []))
	for plan: Variant in plans:
		var rows: Array = plan
		for row: Variant in rows:
			var pair: Array = row
			if _round_now <= CoreUtil.to_int(pair[0]):
				total = maxi(total, CoreUtil.to_int(pair[1]))
				break
	return total


## What must stay unspent to climb next turn, if next turn's income won't cover it.
func _climb_savings() -> int:
	if _player.tier >= UnitLibrary.TIERS or level.name == BotLevel.EASY:
		return 0
	if _round_now + 1 < _target_round(_player.tier):
		return 0
	var income: int = _rules.config.get_int_at("income_by_turn", _round_now)
	var discount: int = _rules.config.get_int("upgrade_discount_per_turn")
	var next_cost: int = _rules.tier_up_cost(_player) - discount
	return maxi(0, next_cost - income - _player.gold_next_turn)


## Makes `cost` gold available, cashing hand items if the purchase is worth more than holding them.
func _pay(cost: int, gain: float) -> bool:
	if _player.gold >= cost:
		return true
	if _player.gold + _player.larder() < cost:
		return false
	if level.reads_text and gain <= _hold_value(cost - _player.gold):
		return false
	var indexes: Array[int] = _items_by_gold()
	for index: int in indexes:
		if _player.gold >= cost:
			break
		_rules.play_item(_player, index, -1)
		_settle()
		return _pay(cost, gain)
	return _player.gold >= cost


## What holding this much gold in hand is worth: cards that read a Larder, say, give it a price.
func _hold_value(gold: int) -> float:
	var per_gold: float = BotEval._number(value.strategy.get("larder_value", 0.0))
	for unit: RecruitUnit in _player.board:
		if unit != null:
			per_gold += BotEval._number(knowledge.card(unit.def_id()).get("larder_value", 0.0))
	return gold * per_gold


## Item indexes that pay gold, cheapest first.
func _items_by_gold() -> Array[int]:
	var out: Array[int] = []
	for index: int in _player.items.size():
		if BotEval.item_gold(_player.items[index].def) > 0:
			out.append(index)
	out.sort_custom(
		func(a: int, b: int) -> bool:
			return BotEval.item_gold(_player.items[a].def) < BotEval.item_gold(_player.items[b].def)
	)
	return out


func _cash_one() -> void:
	var indexes: Array[int] = _items_by_gold()
	if not indexes.is_empty():
		_rules.play_item(_player, indexes[0], -1)
		_settle()


func _cash_all() -> void:
	for _step: int in _player.items.size():
		var indexes: Array[int] = _items_by_gold()
		if indexes.is_empty():
			return
		_rules.play_item(_player, indexes[0], -1)
		_settle()


## Plays each hand unit; on a full board, swaps out the weakest if the new one is clearly better.
func _play_hand() -> void:
	var index: int = 0
	for _step: int in MAX_STEPS:
		if index >= _player.hand.size():
			return
		var unit: RecruitUnit = _player.hand[index]
		var slot: int = BotPlacer.play_slot(_player, unit, value)
		if slot < 0 or _room_left() <= 0:
			var belly: int = BotHeld.best_belly(_player, value, unit)
			if belly >= 0 and _rules.swallow(_player, HeldUnits.HAND, index, belly) == "":
				_settle()
				continue
			slot = _clear_slot_for(unit)
		if slot < 0 or _rules.play(_player, index, slot) != "":
			index += 1
		_settle()


func _clear_slot_for(unit: RecruitUnit) -> int:
	var weakest: int = _weakest_slot()
	if weakest < 0:
		return -1
	if value.keep_value(unit) <= value.keep_value(_player.board[weakest]) + level.replace_margin:
		return -1
	var belly: int = BotHeld.best_belly(_player, value, _player.board[weakest])
	if belly >= 0 and _rules.swallow(_player, HeldUnits.BOARD, weakest, belly) == "":
		_settle()
		return weakest if _player.board[weakest] == null else -1
	if _rules.sell(_player, weakest) != "":
		return -1
	_settle()
	return weakest if _player.board[weakest] == null else -1


## Casts spells and non-gold items in hand. Gold items wait for _pay. Cards that spend everything
## go last, once the shopping is done.
func _cast_spells(last_too: bool) -> void:
	var index: int = _player.items.size() - 1
	while index >= 0:
		if index < _player.items.size():
			var item: HandItem = _player.items[index]
			var waits: bool = value.has_flag(item.def_id(), "cast_last") and not last_too
			if not waits and BotEval.item_gold(item.def) == 0 and _ready_to_cast(item):
				_rules.play_item(_player, index, _aim_for(item.aim(), item.def))
				_settle()
		index -= 1


func _ready_to_cast(item: HandItem) -> bool:
	if not _can_aim(item.aim()):
		return false
	return not _discovers(item.def) or _rules.has_hand_space(_player)


func _can_aim(aim: String) -> bool:
	return aim == HandItem.AIM_NONE or not _legal_aims(aim).is_empty()


func _legal_aims(aim: String) -> Array[int]:
	var out: Array[int] = []
	if aim == HandItem.AIM_SHOP_UNIT:
		for index: int in _player.shop.size():
			out.append(index)
		return out
	for slot: int in BoardGeometry.SLOTS:
		if _rules.aim_problem(_player, aim, slot) == "":
			out.append(slot)
	return out


static func _discovers(card_def: Dictionary) -> bool:
	var step: Variant = card_def.get("do", {})
	if typeof(step) != TYPE_DICTIONARY:
		return false
	var entry: Dictionary = step
	return str(entry.get("effect", "")) == "discover"


## Where to aim a card or power. Naive anywhere legal; otherwise by the card's hint.
func _aim_for(aim: String, card_def: Dictionary) -> int:
	if aim == HandItem.AIM_NONE:
		return -1
	var legal: Array[int] = _legal_aims(aim)
	if legal.is_empty():
		return -1
	if level.name == BotLevel.NAIVE:
		return legal[_player.bot_rng.randi_range(0, legal.size() - 1)]
	if aim == HandItem.AIM_SHOP_UNIT:
		return _best_shop_aim(legal)
	return _best_aim(legal, card_def)


func _best_shop_aim(legal: Array[int]) -> int:
	var best: int = legal[0]
	var best_score: float = -100000.0
	for index: int in legal:
		var score: float = value.buy_value(_player.shop[index], _player)
		if score > best_score:
			best = index
			best_score = score
	return best


## The target worth the most, by the card's `aim_at`. Never stats on a Shy unit by accident.
func _best_aim(legal: Array[int], card_def: Dictionary) -> int:
	var aim_at: String = str(knowledge.card(str(card_def.get("id", ""))).get("aim_at", "carry"))
	if not level.plans_position and (aim_at == "in_front" or aim_at == "behind"):
		aim_at = "carry"
	var best: int = legal[0]
	var best_score: float = -100000.0
	for slot: int in legal:
		var score: float = _aim_score(slot, aim_at)
		if score > best_score:
			best = slot
			best_score = score
	return best


func _aim_score(slot: int, aim_at: String) -> float:
	match aim_at:
		"in_front":
			return _value_of_slots(BoardGeometry.in_front_of(slot))
		"behind":
			return _value_of_slots(BoardGeometry.behind(slot))
	var unit: RecruitUnit = _player.board[slot]
	if unit == null:
		return -slot
	if unit.has_mechanic_id("shy"):
		return -1000.0
	return value.keep_value(unit)


## What a spell that feeds these slots would land on. Shy units count against it.
func _value_of_slots(slots: Array[int]) -> float:
	var total: float = 0.0
	for slot: int in slots:
		var unit: RecruitUnit = _player.board[slot]
		if unit != null:
			total += -20.0 if unit.has_mechanic_id("shy") else value.keep_value(unit)
	return total


## Cards that pay when sold: Rainbow's pot, by the card's hints.
func _sell_for_cash() -> void:
	if not level.reads_text:
		return
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _player.board[slot]
		if unit == null:
			continue
		var hinted: Dictionary = knowledge.card(unit.def_id())
		if not hinted.has("sell_at_bands"):
			continue
		var bands: int = _player.band_count()
		var ready: bool = bands >= CoreUtil.to_int(hinted["sell_at_bands"])
		if (
			_round_now >= CoreUtil.to_int(hinted.get("sell_late_round", 99))
			and bands >= CoreUtil.to_int(hinted.get("sell_late_bands", 99))
		):
			ready = true
		if ready:
			_rules.sell(_player, slot)
			_settle()


## Hob Mumblecrust's kind of power: borrow only to make a climb that's due.
func _borrow_if_short() -> void:
	var hero_id: String = str(_player.hero.get("id", ""))
	if str(knowledge.hero(hero_id).get("power", "")) != "borrow" or _player.power_uses_left <= 0:
		return
	if _player.tier >= UnitLibrary.TIERS or _round_now < _target_round(_player.tier):
		return
	if _player.gold < _rules.tier_up_cost(_player) and _player.health >= LOW_HEALTH:
		_use_power_now()


## Units that eat Acorns: feed everything on the turn before they double, or once they have.
func _feed_eaters() -> void:
	if not level.reads_text:
		return
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _player.board[slot]
		if unit == null or unit.eat_rate() <= 0 or not unit.can_gain_permanent():
			continue
		var goal: int = CoreUtil.to_int(unit.def.get("turns_goal", 0))
		if goal > 0 and unit.turns_in_slot < goal - 1:
			continue
		if goal > 0 and unit.turns_in_slot >= goal and _hold_value(1) > 0.0:
			continue
		for _step: int in _player.items.size():
			if not unit.can_gain_permanent():
				break
			var indexes: Array[int] = _items_by_gold()
			if indexes.is_empty():
				return
			if _rules.play_item(_player, indexes[indexes.size() - 1], slot) != "":
				return


## The hero's activated power, when there's gold to spare or it's free.
func _maybe_power() -> void:
	var power: Dictionary = HeroRules.power_of(_player.hero)
	if str(power.get("kind", "")) != HeroRules.ACTIVATED or _player.power_uses_left <= 0:
		return
	var plan: String = str(knowledge.hero(str(_player.hero.get("id", ""))).get("power", "spare"))
	if plan == "never" or plan == "borrow":
		return
	if plan == "triple_hunt" and not _hunting_below():
		return
	var cost: int = CoreUtil.to_int(power.get("cost", 0))
	if plan == "spare" and _player.gold - cost < _held_back():
		return
	_use_power_now()


## Jill: a pair of a lower tier's unit is worth going down the tree for.
func _hunting_below() -> bool:
	if _player.tier < 3 or _player.gold < 3:
		return false
	for unit: RecruitUnit in _player.owned_units():
		if (
			not unit.golden
			and unit.tier() < _player.tier
			and BotEval.copies_of(_player, unit.def_id()) == 2
		):
			return true
	return false


func _use_power_now() -> void:
	var power: Dictionary = HeroRules.power_of(_player.hero)
	if str(power.get("kind", "")) != HeroRules.ACTIVATED:
		return
	var aim: String = str(power.get("aim", HandItem.AIM_NONE))
	_rules.use_power(_player, _aim_for(aim, {}))
	_settle()


## Keeps a shop worth coming back to: a triple, or a big gain it can't pay for.
func _freeze() -> void:
	if not level.uses_freeze or _player.frozen or _player.freezes_left <= 0:
		return
	for unit: RecruitUnit in _player.shop:
		if (
			BotEval.copies_of(_player, unit.def_id()) >= 2
			or value.buy_value(unit, _player) - _replaced_value() >= FREEZE_GAIN
		):
			_rules.toggle_freeze(_player)
			return


func _replaced_value() -> float:
	if _room_left() > 0:
		return 0.0
	var weakest: int = _weakest_slot()
	return 0.0 if weakest < 0 else value.keep_value(_player.board[weakest])


## Makes every waiting choice: naive at random, others the best by value.
func _settle() -> void:
	for _step: int in MAX_STEPS:
		if not _player.is_choosing():
			return
		var choice: Dictionary = _player.pending[0]
		var options: PackedStringArray = choice["options"]
		_rules.choose(_player, _best_option(options, CoreUtil.to_bool(choice["spells"])))


func _best_option(options: PackedStringArray, spells: bool) -> int:
	if level.name == BotLevel.NAIVE:
		return _player.bot_rng.randi_range(0, maxi(0, options.size() - 1))
	var best: int = 0
	var best_score: float = -100000.0
	for index: int in options.size():
		var score: float = 0.0
		if spells:
			score = value.spell_value(_rules.library.get_card(options[index]))
		else:
			score = value.def_value(_rules.library.get_unit(options[index]), _player)
		if score > best_score:
			best = index
			best_score = score
	return best


static func stat_sum(board: Array) -> int:
	var total: int = 0
	for entry: Variant in board:
		if entry != null:
			var spec: Dictionary = entry
			total += CoreUtil.to_int(spec.get("attack", 0)) + CoreUtil.to_int(spec.get("health", 0))
	return total
