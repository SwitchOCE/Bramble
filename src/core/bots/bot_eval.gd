class_name BotEval
extends RefCounted
## What a card is worth to a bot right now, in stat points (+1 Attack or +1 Health is 1 point).
## Reads the level, the strategy and the card hints in content/bots/.

const TEXT_PER_TIER: float = 1.5
## Worth of a copy that makes a triple, and of a first pair.
const TRIPLE_BONUS: float = 18.0
const PAIR_BONUS: float = 3.0
const GOLD_POINTS: float = 2.5

var level: BotLevel
var knowledge: BotKnowledge
## Supplied by the turn's rules; Russet evaluates only real, eligible pool cards in the scout.
var library: UnitLibrary
var recruit_rules: RecruitRules
var strategy: Dictionary = {}
var board_owner: PlayerState


static func make(bot_level: BotLevel, bot_knowledge: BotKnowledge) -> BotEval:
	var value := BotEval.new()
	value.level = bot_level
	value.knowledge = bot_knowledge
	return value


## What this unit is worth standing on the board.
func keep_value(unit: RecruitUnit) -> float:
	BotProfile.enter("eval")
	var result: float = _profile_keep_value(unit)
	BotProfile.leave()
	return result


func _profile_keep_value(unit: RecruitUnit) -> float:
	var factor: float = 2.0 if unit.golden else 1.0
	var total: float = unit.attack + unit.health
	if level.reads_text:
		if unit.def_id() == "charcoal_burner" and board_owner != null:
			total += BotBurner.owned_value(unit, board_owner)
		elif unit.has_mechanic_id("back_row_immunity") and board_owner != null:
			total += BotContent5.owl_value(unit, board_owner)
		elif (
			(unit.has_mechanic_id("redwing") or unit.has_mechanic_id("tom_tit"))
			and board_owner != null
		):
			total += BotContent5.redwing_value(unit, board_owner, not board_owner.board.has(unit))
		else:
			total += factor * _hint_number(unit.def, "keep", TEXT_PER_TIER * unit.tier())
	else:
		total += 2.0 * unit.tier()
	for inside: RecruitUnit in unit.held:
		total += BotHeld.INSIDE_WORTH * keep_value(inside)
	return total + build_bonus(unit.def)


## What buying this unit is worth, before what it replaces.
func buy_value(unit: RecruitUnit, player: PlayerState, cost: int = 3) -> float:
	BotProfile.enter("eval")
	var result: float = _profile_buy_value(unit, player, cost)
	BotProfile.leave()
	return result


func _profile_buy_value(unit: RecruitUnit, player: PlayerState, cost: int = 3) -> float:
	var total: float = unit.attack + unit.health
	if level.reads_text:
		if unit.def_id() == "lamp_moth":
			total += BotContent5.lamp_value(unit, player)
		elif unit.def_id() == "charcoal_burner":
			total += BotBurner.purchase_value(unit, player, cost)
		elif unit.has_mechanic_id("back_row_immunity"):
			total += BotContent5.owl_value(unit, player)
		elif unit.has_mechanic_id("redwing") or unit.has_mechanic_id("tom_tit"):
			total += BotContent5.redwing_value(unit, player, true)
		else:
			total += _hint_number(
				unit.def, "buy", _hint_number(unit.def, "keep", TEXT_PER_TIER * unit.tier())
			)
	else:
		total += 2.0 * unit.tier()
	total += build_bonus(unit.def)
	if level.reads_text:
		total += BotCommitment.future_bonus(unit, player)
	var copies: int = copies_of(player, unit.def_id())
	if copies >= 2:
		total += TRIPLE_BONUS + 2.0 * unit.tier()
	elif copies == 1:
		total += PAIR_BONUS
	return total


## What one trip south earns in text and homecoming effects; flying pays no sale gold.
func fly_value(unit: RecruitUnit) -> float:
	BotProfile.enter("eval")
	var result: float = _profile_fly_value(unit)
	BotProfile.leave()
	return result


func _profile_fly_value(unit: RecruitUnit) -> float:
	var hinted: float = _hint_number(unit.def, "fly", 0.0)
	var builds: Dictionary = strategy.get("fly", {})
	return hinted + _number(builds.get(unit.def_id(), 0))


## What this unit's text is worth to something that borrows it.
func text_value(unit: RecruitUnit) -> float:
	BotProfile.enter("eval")
	var result: float = _profile_text_value(unit)
	BotProfile.leave()
	return result


func _profile_text_value(unit: RecruitUnit) -> float:
	return _hint_number(unit.def, "keep", TEXT_PER_TIER * unit.tier())


## Whether its worth is in being played, so a Belly would waste it.
func pays_on_play(unit: RecruitUnit) -> bool:
	return _hint_number(unit.def, "buy", 0.0) > text_value(unit)


## A unit id offered by a Discover: same scale as buy_value, from the printed card.
func def_value(unit_def: Dictionary, player: PlayerState) -> float:
	var unit := RecruitUnit.make(unit_def, 0)
	return buy_value(unit, player, 0)


## What the strategy adds for this card.
func build_bonus(card_def: Dictionary) -> float:
	if strategy.is_empty():
		return 0.0
	var total: float = 0.0
	var units: Dictionary = strategy.get("units", {})
	total += _number(units.get(str(card_def["id"]), 0))
	var tribes: Dictionary = strategy.get("tribes", {})
	var card_tribes: Array = card_def.get("tribes", [])
	for tribe: Variant in card_tribes:
		total += _number(tribes.get(tribe, 0))
	return total


## What a spell is worth to cast, on what's on the board. Only hints and its effect are read.
func spell_value(card_def: Dictionary, gold_now: int = 0, player: PlayerState = null) -> float:
	BotProfile.enter("eval")
	var result: float = _profile_spell_value(card_def, gold_now, player)
	BotProfile.leave()
	return result


func _profile_spell_value(
	card_def: Dictionary, gold_now: int = 0, player: PlayerState = null
) -> float:
	var spells: Dictionary = strategy.get("spells", {})
	var bonus: float = _number(spells.get(str(card_def["id"]), 0))
	if player != null and level.reads_text:
		var content5: float = BotContent5.spell_value(card_def, player, recruit_rules)
		if content5 >= 0.0:
			return content5 + (bonus if content5 > 0.0 else 0.0)
		var live: float = BotCommitment.spell_value(card_def, player)
		if live >= 0.0:
			return live + (bonus if live > 0.0 else 0.0)
	var hinted: Dictionary = knowledge.card(str(card_def["id"]))
	if hinted.has("value"):
		return _number(hinted["value"]) + bonus
	if hinted.has("value_per_gold"):
		return _number(hinted["value_per_gold"]) * gold_now + bonus
	return _effect_value(card_def.get("do", {})) + bonus


## The gold a hand item pays when played; 0 for anything else.
static func item_gold(card_def: Dictionary) -> int:
	return CoreUtil.to_int(card_def.get("gold_value", 0))


## Where a unit wants to stand: the build's word, then the card hint, then the card's own.
func row_of(unit: RecruitUnit) -> String:
	BotProfile.enter("eval")
	var result: String = _profile_row_of(unit)
	BotProfile.leave()
	return result


func _profile_row_of(unit: RecruitUnit) -> String:
	var rows: Dictionary = strategy.get("rows", {})
	if rows.has(unit.def_id()):
		return str(rows[unit.def_id()])
	var hinted: String = hint(unit.def_id(), "row")
	return hinted if hinted != "" else unit.row_hint()


## A hint on a card ("" when absent).
func hint(card_id: String, key: String) -> String:
	return str(knowledge.card(card_id).get(key, ""))


func has_flag(card_id: String, key: String) -> bool:
	return CoreUtil.to_bool(knowledge.card(card_id).get(key, false))


## How well a strategy fits what a player holds and sees (for choosing a build).
func strategy_fit(entry: Dictionary, player: PlayerState) -> float:
	BotProfile.enter("eval")
	var result: float = _profile_strategy_fit(entry, player)
	BotProfile.leave()
	return result


func _profile_strategy_fit(entry: Dictionary, player: PlayerState) -> float:
	var saved: Dictionary = strategy
	strategy = entry
	var total: float = 0.0
	for unit: RecruitUnit in player.all_units():
		total += build_bonus(unit.def) * (2.0 if unit.golden else 1.0)
	for unit: RecruitUnit in player.shop:
		total += 0.5 * build_bonus(unit.def)
	var heroes: Dictionary = entry.get("heroes", {})
	total += _number(heroes.get(str(player.hero.get("id", "")), 0))
	if level.reads_shop_for_build:
		total += _number(entry.get("power", 0))
		var tribes: Dictionary = entry.get("tribes", {})
		for tribe: Variant in tribes:
			total += 4.0 * CoreUtil.to_int(player.tribe_bonuses.get(tribe, 0))
	strategy = saved
	return total


static func copies_of(player: PlayerState, def_id: String) -> int:
	var count: int = 0
	for unit: RecruitUnit in player.owned_units():
		if unit.def_id() == def_id and not unit.golden:
			count += 1
	return count


func _hint_number(card_def: Dictionary, key: String, fallback: float) -> float:
	var hinted: Dictionary = knowledge.card(str(card_def["id"]))
	if hinted.has(key):
		return _number(hinted[key])
	return fallback


## A rough value from an effect's numbers: stats given, gold, a Discover.
static func _effect_value(step: Variant) -> float:
	if typeof(step) == TYPE_ARRAY:
		var steps: Array = step
		var total: float = 0.0
		for entry: Variant in steps:
			total += _effect_value(entry)
		return total
	if typeof(step) != TYPE_DICTIONARY:
		return 0.0
	var entry: Dictionary = step
	match str(entry.get("effect", "")):
		"buff", "slot_effect":
			return _number(entry.get("attack", 0)) + _number(entry.get("health", 0))
		"gold":
			return _number(entry.get("amount", 0)) * GOLD_POINTS
		"discover":
			return 8.0
		"free_refresh":
			return _number(entry.get("count", 1)) * GOLD_POINTS
	return 2.0


static func _number(value: Variant) -> float:
	match typeof(value):
		TYPE_FLOAT:
			var number: float = value
			return number
		TYPE_INT:
			var whole: int = value
			return whole
	return 0.0
