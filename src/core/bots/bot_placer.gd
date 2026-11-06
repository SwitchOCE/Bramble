class_name BotPlacer
extends RefCounted
## Where a bot's units stand. Every change goes through RecruitRules.move, so moves cost what they
## cost a player: turns-in-slot counts restart and on-move text fires. Pinned units stay.

## How many units stand in front for a board of n units.
const FRONT_COUNT: Array[int] = [0, 1, 1, 2, 2, 3, 4, 4]
const FRONT_ORDER: Array[int] = [1, 2, 0, 3]
const BACK_ORDER: Array[int] = [5, 4, 6]
const ROW_WEIGHT: float = 1000.0


## The slots whose unit must not move: a unit that has been counting turns where it stands, or
## every slot while a unit that pins the board stands (bands fade if their unit moves).
static func pinned_slots(
	player: PlayerState, value: BotEval, board_at_start: Dictionary
) -> Array[int]:
	var out: Array[int] = []
	var pins_all: bool = false
	for unit: RecruitUnit in player.board:
		if unit != null and value.has_flag(unit.def_id(), "pins_board"):
			pins_all = true
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null or not board_at_start.has(unit.iid):
			continue
		if pins_all or value.has_flag(unit.def_id(), "pin"):
			out.append(slot)
	return out


## Arranges the board as the level says. `pinned` from pinned_slots.
static func arrange(
	player: PlayerState,
	rules: RecruitRules,
	value: BotEval,
	place: String,
	budget: int,
	pinned: Array[int]
) -> void:
	if place == BotLevel.PLACE_RANDOM or place == BotLevel.PLACE_SIMPLE:
		return
	var layout: Array[int] = rule_layout(player, value, pinned)
	if place == BotLevel.PLACE_SHUFFLED:
		layout = BoardSearch.random_layout(player_occupied(player), player.bot_rng, pinned)
	elif place == BotLevel.PLACE_SEARCH and not player.scout.is_empty():
		layout = _searched(player, rules, layout, value, budget, pinned)
	apply_layout(player, rules, layout)


## Sturdy units in front, hitters and hinted units behind; on each row the best units take the
## slots with the most Ring, and a unit that must not gain stats takes the least.
static func rule_layout(player: PlayerState, value: BotEval, pinned: Array[int]) -> Array[int]:
	var layout: Array[int] = []
	layout.resize(BoardGeometry.SLOTS)
	layout.fill(-1)
	var movers: Array[int] = []
	var count: int = player.board_count()
	var front_left: int = FRONT_COUNT[count]
	for slot: int in BoardGeometry.SLOTS:
		if player.board[slot] == null:
			continue
		if pinned.has(slot):
			layout[slot] = slot
			front_left -= 1 if BoardGeometry.is_front(slot) else 0
		else:
			movers.append(slot)
	movers.sort_custom(
		func(a: int, b: int) -> bool:
			return _front_score(player, value, a) > _front_score(player, value, b)
	)
	var front: Array[int] = []
	var back: Array[int] = []
	var free_front: int = _free_in(layout, BoardGeometry.FRONT)
	var free_back: int = _free_in(layout, BoardGeometry.BACK)
	for slot: int in movers:
		var wants_front: bool = front.size() < maxi(0, front_left)
		var hint: String = player.board[slot].row_hint()
		if hint == "front" and front.size() < free_front:
			wants_front = true
		if hint == "back" and back.size() < free_back:
			wants_front = false
		if wants_front and front.size() >= free_front:
			wants_front = false
		if not wants_front and back.size() >= free_back:
			wants_front = true
		if wants_front:
			front.append(slot)
		else:
			back.append(slot)
	_fill_row(player, value, layout, front, FRONT_ORDER)
	_fill_row(player, value, layout, back, BACK_ORDER)
	return layout


## Moves units until the board matches a layout of the board as it stands now.
static func apply_layout(player: PlayerState, rules: RecruitRules, layout: Array[int]) -> void:
	var wanted: Array = []
	wanted.resize(BoardGeometry.SLOTS)
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0:
			wanted[slot] = player.board[layout[slot]]
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = wanted[slot]
		if unit == null:
			continue
		var now: int = player.board.find(unit)
		if now >= 0 and now != slot:
			rules.move(player, now, slot)
			if player.is_choosing():
				return


## An empty slot for a unit about to be played: its row if it has room, else any. -1 if full.
static func play_slot(player: PlayerState, unit: RecruitUnit, rng: RandomNumberGenerator) -> int:
	var hint: String = unit.row_hint()
	var wants_back: bool = hint == "back" or (hint == "" and unit.attack > unit.health + 1)
	if rng != null:
		var empties: Array[int] = []
		for slot: int in BoardGeometry.SLOTS:
			if player.board[slot] == null:
				empties.append(slot)
		return -1 if empties.is_empty() else empties[rng.randi_range(0, empties.size() - 1)]
	var first: Array[int] = BACK_ORDER if wants_back else FRONT_ORDER
	var second: Array[int] = FRONT_ORDER if wants_back else BACK_ORDER
	for order: Array[int] in [first, second]:
		for slot: int in order:
			if player.board[slot] == null:
				return slot
	return -1


static func player_occupied(player: PlayerState) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if player.board[slot] != null:
			out.append(slot)
	return out


static func _front_score(player: PlayerState, value: BotEval, slot: int) -> float:
	var unit: RecruitUnit = player.board[slot]
	var score: float = unit.health - 0.5 * unit.attack
	var row: String = value.hint(unit.def_id(), "row")
	if row == "":
		row = unit.row_hint()
	if row == "front":
		score += ROW_WEIGHT
	elif row == "back":
		score -= ROW_WEIGHT
	return score


static func _free_in(layout: Array[int], row: Array[int]) -> int:
	var free: int = 0
	for slot: int in row:
		if layout[slot] < 0:
			free += 1
	return free


static func _fill_row(
	player: PlayerState, value: BotEval, layout: Array[int], units: Array[int], order: Array[int]
) -> void:
	var slots: Array[int] = []
	for slot: int in order:
		if layout[slot] < 0:
			slots.append(slot)
	var position: Dictionary = {}
	for index: int in slots.size():
		position[slots[index]] = index
	slots.sort_custom(
		func(a: int, b: int) -> bool:
			var ring_a: int = _ring_at(player, a)
			var ring_b: int = _ring_at(player, b)
			if ring_a != ring_b:
				return ring_a > ring_b
			return CoreUtil.to_int(position[a]) < CoreUtil.to_int(position[b])
	)
	units.sort_custom(
		func(a: int, b: int) -> bool:
			return _ring_score(player, value, a) > _ring_score(player, value, b)
	)
	for index: int in units.size():
		layout[slots[index]] = units[index]


## The stats of a slot's effects.
static func _ring_at(player: PlayerState, slot: int) -> int:
	var total: int = 0
	var effects: Array = player.slot_effects[slot]
	for value: Variant in effects:
		var effect: Dictionary = value
		total += CoreUtil.to_int(effect.get("attack", 0)) + CoreUtil.to_int(effect.get("health", 0))
	return total


static func _ring_score(player: PlayerState, value: BotEval, slot: int) -> float:
	var unit: RecruitUnit = player.board[slot]
	if value.has_flag(unit.def_id(), "shy"):
		return -ROW_WEIGHT
	return value.keep_value(unit)


static func _searched(
	player: PlayerState,
	rules: RecruitRules,
	first: Array[int],
	value: BotEval,
	budget: int,
	pinned: Array[int]
) -> Array[int]:
	var problem := BoardSearch.Problem.new()
	problem.board = BoardSearch.arranged_specs(player.combat_board(), first)
	problem.slots = player.combat_slots()
	problem.hero_effects = HeroRules.effects_of(player.hero)
	problem.tier = player.tier
	problem.enemy = player.scout["specs"]
	problem.enemy_slots = player.scout["slots"]
	problem.enemy_hero_effects = player.scout["hero_effects"]
	problem.enemy_tier = player.scout["tier"]
	problem.pinned = pinned
	problem.layout_bonus = _shy_penalty.bind(player, _shy_slots(player, value, first))
	problem.library = rules.library
	problem.config = rules.config
	var second: Array[int] = BoardSearch.best_layout(problem, player.bot_rng, budget)
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		out.append(first[second[slot]] if second[slot] >= 0 else -1)
	return out


## Which slots of the first arrangement hold a unit that must not gain stats (Shy).
static func _shy_slots(player: PlayerState, value: BotEval, first: Array[int]) -> Array[bool]:
	var out: Array[bool] = []
	for slot: int in BoardGeometry.SLOTS:
		var shy: bool = false
		if first[slot] >= 0:
			shy = value.has_flag(player.board[first[slot]].def_id(), "shy")
		out.append(shy)
	return out


## A Shy unit walking onto a Ring leaves: a search must not treat that as free.
static func _shy_penalty(layout: Array[int], player: PlayerState, shy: Array[bool]) -> float:
	var penalty: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0 and shy[layout[slot]] and _ring_at(player, slot) > 0:
			penalty -= 2.0
	return penalty
