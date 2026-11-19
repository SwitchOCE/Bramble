class_name Rules
extends RefCounted
## Named rule queries (architecture notes 1-2). Each rule the game asks about has one base
## answer here, from GameConfig, then unit text gets to change it, then hard caps apply. Shop,
## combat and the session call these and never compute a rule themselves. Game- and
## player-level layers (anomalies, quests) are left out until something needs them.

const INCOME: StringName = &"income"
const UNIT_PRICE: StringName = &"unit_price"
const SPELL_PRICE: StringName = &"spell_price"
const SELL_VALUE: StringName = &"sell_value"
const REFRESH_COST: StringName = &"refresh_cost"
const UPGRADE_COST: StringName = &"upgrade_cost"
const HAND_LIMIT: StringName = &"hand_limit"
const SHOP_UNITS: StringName = &"shop_units"
const SHOP_SPELLS: StringName = &"shop_spells"
const FREEZE_LIMIT: StringName = &"freeze_limit"
const DISCOVER_OPTIONS: StringName = &"discover_options"
const TRIPLE_REWARD_TIER: StringName = &"triple_reward_tier"
const LOSS_DAMAGE: StringName = &"loss_damage"
var config: GameConfig


func _init(game_config: GameConfig) -> void:
	config = game_config


## The walk: base -> unit -> caps. With no unit given, the unit layer is the
## text of the player's board units in reading order (a unit that changes a player's rule).
func ask(
	query: StringName, base: int, player: PlayerState, unit: Unit, used: Array[Unit] = []
) -> int:
	var value: int = base
	var contributors: Array[Unit] = []
	var sources: Array[Unit] = []
	if unit != null:
		sources.append(unit)
	elif player != null:
		sources = player.board_units()
	for source: Unit in sources:
		value = _unit_layer(source, query, value, player, contributors)
	value = _cap(query, value)
	# Remove an earlier weaker non-stacking modifier when a later stronger one superseded it.
	# Equal backups never entered contributors, so the first applying copy remains the source.
	if contributors.size() > 1:
		for source: Unit in contributors.duplicate():
			var without: int = base
			for other: Unit in contributors:
				if other != source:
					without = _unit_layer(other, query, without, player)
			if _cap(query, without) == value:
				contributors.erase(source)
	for source: Unit in contributors:
		if not used.has(source):
			used.append(source)
	return value


func _unit_layer(
	unit: Unit, query: StringName, value: int, player: PlayerState, used: Array[Unit] = []
) -> int:
	for bound: BoundMechanic in unit.mechanics:
		var next: int = bound.mechanic.modify_int(query, value, player, unit, bound.params)
		if _cap(query, next) != _cap(query, value) and not used.has(unit):
			used.append(unit)
		value = next
	return value


## Hard caps: no price, cost or limit below 0 (4.1.5), and the hand holds at least one card.
func _cap(query: StringName, value: int) -> int:
	if query == HAND_LIMIT:
		return maxi(1, value)
	if query == TRIPLE_REWARD_TIER:
		return clampi(value, 1, config.max_tier)
	return maxi(0, value)


## 4.1.1 income on `turn` (1-based), then 4.1.4's changes through the query.
func income(player: PlayerState, turn: int, used: Array[Unit] = []) -> int:
	var amount: int = config.income_first
	for _step: int in range(1, turn):
		if amount < config.income_fast_until:
			amount = mini(amount + config.income_fast_step, config.income_fast_until)
		else:
			amount += config.income_slow_step
	return ask(INCOME, amount, player, null, used)


## 4.2.1 a unit costs its tier + 1.
func unit_price(player: PlayerState, def: UnitDef, used: Array[Unit] = []) -> int:
	return ask(UNIT_PRICE, def.tier + 1, player, null, used)


## 4.2.5 a Tavern spell costs its listed cost.
func spell_price(player: PlayerState, def: UnitDef, used: Array[Unit] = []) -> int:
	return ask(SPELL_PRICE, def.cost, player, null, used)


## 4.3.3-4.3.4: half the tier rounded up for each Bought copy; Created copies add nothing.
func sell_value(player: PlayerState, unit: Unit) -> int:
	var each: int = CoreUtil.ceil_div(unit.def.tier, 2)
	return ask(SELL_VALUE, each * unit.bought_copies, player, unit)


## 4.4.2-4.4.3: the cost of the player's next paid refresh this turn.
func refresh_cost(player: PlayerState, used: Array[Unit] = []) -> int:
	var next_paid: int = player.refreshes_paid + 1
	var cost: int = config.refresh_base_cost
	if next_paid > config.refresh_first_step_after:
		var over: int = next_paid - config.refresh_first_step_after
		cost += CoreUtil.ceil_div(over, config.refresh_step_length)
	return ask(REFRESH_COST, cost, player, null, used)


## Paid refreshes remaining at the current step, including the next one (4.4.2-4.4.5).
func refreshes_left(player: PlayerState) -> int:
	var paid: int = player.refreshes_paid
	if paid < config.refresh_first_step_after:
		return config.refresh_first_step_after - paid
	return (
		config.refresh_step_length
		- (paid - config.refresh_first_step_after) % config.refresh_step_length
	)


## 4.6.2-4.6.6: base cost of the next tier, less the discount for turns waited on this tier.
## -1 when the player is at the top tier.
func upgrade_cost(player: PlayerState, used: Array[Unit] = []) -> int:
	if player.tier >= config.max_tier:
		return -1
	var base: int = config.upgrade_costs[player.tier - 1]
	return ask(
		UPGRADE_COST, maxi(0, base - waiting_discount(player.turns_waited)), player, null, used
	)


## 4.6.3, 4.6.6: total discount after `turns` turns waited: 1, 3, 6, 10, 15, then +5 a turn.
func waiting_discount(turns: int) -> int:
	var total: int = 0
	for turn: int in range(1, turns + 1):
		total += mini(turn, config.discount_step_cap)
	return total


func hand_limit(player: PlayerState) -> int:
	return ask(HAND_LIMIT, config.hand_limit, player, null)


func shop_units(player: PlayerState) -> int:
	return ask(SHOP_UNITS, config.shop_units, player, null)


func shop_spells(player: PlayerState) -> int:
	return ask(SHOP_SPELLS, config.shop_spells, player, null)


func freeze_limit(player: PlayerState) -> int:
	return ask(FREEZE_LIMIT, config.freeze_toggles_per_turn, player, null)


func discover_options(player: PlayerState) -> int:
	return ask(DISCOVER_OPTIONS, config.discover_options, player, null)


## 7.3.6: the tier above the player's current tier, or the top tier at the top.
func triple_reward_tier(player: PlayerState) -> int:
	return ask(TRIPLE_REWARD_TIER, mini(player.tier + 1, config.max_tier), player, null)


## 10.1.1-10.1.3: round + 1 up to 10; a big loss deals 3 more. Asked for the loser.
func loss_damage(loser: PlayerState, round_number: int, big: bool) -> int:
	var amount: int = mini(round_number + config.loss_round_offset, config.loss_cap)
	if big:
		amount += config.big_loss_extra
	return ask(LOSS_DAMAGE, amount, loser, null)
