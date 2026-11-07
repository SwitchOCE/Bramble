class_name BotHeld
extends RefCounted
## How Easy, Normal and Hard use Bellies and Fly South. Reads only the player's own state, its scout
## and the card hints; BotBrain calls these from its turn.

## A unit in a Belly is a later body, not one now: worth this share of standing on the board.
const INSIDE_WORTH: float = 0.8
const FRONT_BELLY: float = 2.0
## Fewest units a level leaves on the ground, by how far the game has gone.
const MIN_BODIES_EARLY: int = 2
const MIN_BODIES_LATE: int = 4
const LATE_ROUND: int = 8
## What a trip costs per stat point away: it misses two fights.
const AWAY_COST: float = 1.0
const BEHIND_RATIO: float = 0.8
const EASY_FLY_CHANCE: float = 0.5
const EASY_MIN_BODIES: int = 3
## A unit inside doesn't fight yet: this many stand on the board before a build goes for depth.
const DEPTH_BODIES: int = 4
const DISCOUNT_BODIES: int = 2


# --- Fly South ----------------------------------------------------------------------------------


## Sends south every bird this level thinks should go, best trip first.
static func fly_turn(
	player: PlayerState, rules: RecruitRules, value: BotEval, round_number: int
) -> void:
	if not value.level.reads_text:
		_easy_flight(player, rules)
		return
	for _step: int in BoardGeometry.SLOTS:
		var slot: int = _best_flight(player, value, round_number)
		if slot < 0 or rules.sell(player, slot) != "":
			return


## Easy's rule: short of gold with a board to spare, it flies a bird at a coin toss.
static func _easy_flight(player: PlayerState, rules: RecruitRules) -> void:
	if player.gold >= rules.unit_cost(player) or player.board_count() < EASY_MIN_BODIES:
		return
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit != null and HeldUnits.flies(unit, player):
			if player.bot_rng.randf() < EASY_FLY_CHANCE:
				rules.sell(player, slot)
			return


static func _best_flight(player: PlayerState, value: BotEval, round_number: int) -> int:
	if player.board_count() <= min_bodies(value, round_number) or _too_far_behind(player, value):
		return -1
	var best: int = -1
	var best_score: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or not HeldUnits.flies(unit, player):
			continue
		var score: float = trip_score(unit, player, value)
		if score > best_score:
			best = slot
			best_score = score
	return best


## Stat points a trip earns less what the unit gives by missing two fights.
static func trip_score(unit: RecruitUnit, player: PlayerState, value: BotEval) -> float:
	var gain: float = value.fly_value(unit)
	if player.nest_at(player.board.find(unit)).is_empty():
		return gain - AWAY_COST * (unit.attack + unit.health)
	# It stands on another bird's Nest, and a new Nest would end that one.
	return gain - AWAY_COST * (unit.attack + unit.health) - FRONT_BELLY


static func min_bodies(value: BotEval, round_number: int) -> int:
	if value.strategy.has("min_bodies"):
		return CoreUtil.to_int(value.strategy["min_bodies"])
	return MIN_BODIES_LATE if round_number >= LATE_ROUND else MIN_BODIES_EARLY


## A level that reads pressure doesn't thin a board that's already losing to what it scouted.
static func _too_far_behind(player: PlayerState, value: BotEval) -> bool:
	if not value.level.reads_pressure or player.scout.is_empty():
		return false
	var mine: int = BotBrain.stat_sum(player.board_specs())
	var seen: Array = player.scout["specs"]
	return mine < BotBrain.stat_sum(seen) * BEHIND_RATIO


# --- Belly --------------------------------------------------------------------------------------


## The best Belly for this unit: the slot, or -1. Front Oozes die first, so what's inside gets out.
static func best_belly(player: PlayerState, value: BotEval, unit: RecruitUnit) -> int:
	if unit == null or not unit.held.is_empty():
		return -1
	var best: int = -1
	var best_score: float = -1000.0
	for slot: int in BoardGeometry.SLOTS:
		var ooze: RecruitUnit = player.board[slot]
		if ooze == null or ooze == unit or HeldUnits.room(ooze) <= 0:
			continue
		if value.level.reads_text and value.has_flag(ooze.def_id(), "keep_empty"):
			continue
		var score: float = 0.0
		if BoardGeometry.is_front(slot):
			score += FRONT_BELLY
		score += ooze.mechanic_number("belly_discount", "gold") * BotEval.GOLD_POINTS
		if ooze.has_mechanic_id("borrows_text"):
			score += value.text_value(unit)
		if score > best_score:
			best = slot
			best_score = score
	return best


## Whether a shop unit should be bought straight into a Belly rather than into hand: only if its
## text doesn't need playing, and only where a Belly makes it cheaper or the build wants depth now.
static func buys_into_belly(
	player: PlayerState, value: BotEval, unit: RecruitUnit, slot: int, no_room: bool
) -> bool:
	if slot < 0:
		return false
	if no_room:
		return true
	if not value.level.reads_text or value.pays_on_play(unit):
		return false
	var ooze: RecruitUnit = player.board[slot]
	if ooze.mechanic_number("belly_discount", "gold") > 0:
		return player.board_count() >= DISCOUNT_BODIES
	return (
		CoreUtil.to_bool(value.strategy.get("depth_first", false))
		and player.board_count() >= DEPTH_BODIES
	)
