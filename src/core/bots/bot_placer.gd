class_name BotPlacer
extends RefCounted
## Where a bot's units stand. Every change goes through RecruitRules.move, so moves cost what they
## cost a player: turn counts restart, bands fade and on-move text fires. Pinned units stay.

## How many units stand in front for a board of n units.
const FRONT_COUNT: Array[int] = [0, 1, 1, 2, 2, 3, 4, 4]
const FRONT_ORDER: Array[int] = [1, 2, 0, 3]
const BACK_ORDER: Array[int] = [5, 4, 6]
const ROW_WEIGHT: float = 1000.0
const PASS_WEIGHT: float = 0.1
const SEARCH_MIN_UNITS: int = 4
const SEARCH_MIN_RATIO: float = 0.6
const SEARCH_MAX_RATIO: float = 1.7
## A unit already in a row needs this much reason to change it.
const ROW_STAY: float = 3.0
## In fight-score units: what a search must find before a board is rearranged.
const STAY_BONUS: float = 0.2


## The slots whose unit must not move: partway through a turn count, or waiting on a timer, or
## standing on the band it painted.
static func pinned_slots(player: PlayerState) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit == null:
			continue
		var goal: int = CoreUtil.to_int(unit.def.get("turns_goal", 0))
		var counting: bool = goal > 0 and unit.turns_in_slot > 0 and unit.turns_in_slot < goal
		if goal > 0 and unit.pays_again():
			counting = true
		if counting or not unit.timers.is_empty() or player.bands[slot] != 0:
			out.append(slot)
		elif _keeps_its_nest(player, unit, slot):
			out.append(slot)
	return out


## The Lump borrows stats only standing on a Nest, and Nests don't move.
static func _keeps_its_nest(player: PlayerState, unit: RecruitUnit, slot: int) -> bool:
	if player.nest_at(slot).is_empty():
		return false
	return unit.has_mechanic_id("lump") or unit.def_id() == "great_lump"


## Arranges the board as the level says.
static func arrange(
	player: PlayerState, rules: RecruitRules, value: BotEval, place: String, budget: int
) -> void:
	value.library = rules.library
	if place == BotLevel.PLACE_RANDOM or place == BotLevel.PLACE_SIMPLE:
		return
	var pinned: Array[int] = pinned_slots(player)
	var layout: Array[int] = rule_layout(player, value, pinned)
	if place == BotLevel.PLACE_SHUFFLED:
		layout = BoardSearch.random_layout(player_occupied(player), player.bot_rng, pinned)
	elif place == BotLevel.PLACE_SEARCH and _worth_searching(player):
		layout = _searched(player, rules, layout, value, budget, pinned)
	apply_layout(player, rules, layout)


## Fights out of reach or boards too small don't reward a search (evidence/position-test.md).
static func _worth_searching(player: PlayerState) -> bool:
	if player.scout.is_empty():
		return false
	var combat_board: Array = player.combat_board()
	if (
		combat_board.filter(func(spec: Variant) -> bool: return spec != null).size()
		< SEARCH_MIN_UNITS
	):
		return false
	var mine: int = BotBrain.stat_sum(combat_board)
	var seen: Array = player.scout["specs"]
	var theirs: int = BotBrain.stat_sum(seen)
	return mine >= theirs * SEARCH_MIN_RATIO and mine <= theirs * SEARCH_MAX_RATIO


## Sturdy units in front, hitters and hinted units behind; on each row the best units take the
## slots with the most Ring. Then the units that aim across face the best enemy they can see, a
## Shy unit gets out from behind whatever would feed it, and a planner's Passes land on its carry.
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
		var row: String = value.row_of(player.board[slot])
		if row == "front" and front.size() < free_front:
			wants_front = true
		if row == "back" and back.size() < free_back:
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
	_face_the_best(player, value, layout, pinned)
	if value.level.plans_position:
		_land_passes_on_carry(player, value, layout, pinned)
	_shelter_from_the_tithe(player, value, layout, pinned)
	BotLanes.arrange(player, value, layout, pinned)
	if value.level.reads_text:
		BotEggs.preserve(player, layout, pinned)
	BotPass3.arrange(player, value, layout, pinned)
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


## An empty slot for a unit about to be played. A unit that may gain stats takes the biggest empty
## Ring; otherwise its row if it has room, else any. -1 if the board is full.
static func play_slot(player: PlayerState, unit: RecruitUnit, value: BotEval) -> int:
	var pass3_slot: int = BotPass3.play_slot(player, unit, value)
	if pass3_slot >= 0:
		return pass3_slot
	if value.level.reads_text and HeldUnits.redwing_factor(unit) > 0:
		return BotContent5.redwing_play_slot(player, unit)
	var shy: bool = unit.has_mechanic_id("shy")
	var best: int = -1
	var best_ring: int = 0
	for slot: int in BoardGeometry.SLOTS:
		if (
			BotEggs.playable(player, unit, value, slot)
			and not shy
			and _ring_at(player, slot) > best_ring
		):
			best = slot
			best_ring = _ring_at(player, slot)
	if best >= 0:
		return best
	var chosen: int = _hinted_slot(player, unit, value)
	if chosen >= 0:
		return chosen
	var row: String = value.row_of(unit)
	var wants_back: bool = row == "back" or (row == "" and unit.attack > unit.health + 1)
	var first: Array[int] = BACK_ORDER if wants_back else FRONT_ORDER
	var second: Array[int] = FRONT_ORDER if wants_back else BACK_ORDER
	for order: Array[int] in [first, second]:
		for slot: int in order:
			if BotEggs.playable(player, unit, value, slot):
				return slot
	return -1


## A slot the card's text asks for: on a Nest, or touching a Bird when its play text needs one.
static func _hinted_slot(player: PlayerState, unit: RecruitUnit, value: BotEval) -> int:
	if not value.level.reads_text:
		return -1
	var wants_nest: bool = value.has_flag(unit.def_id(), "on_nest")
	var next_to: String = value.hint(unit.def_id(), "next_to")
	if not wants_nest and next_to == "":
		return -1
	for slot: int in FRONT_ORDER + BACK_ORDER:
		if not BotEggs.playable(player, unit, value, slot):
			continue
		if wants_nest and not player.nest_at(slot).is_empty():
			return slot
		if next_to != "" and _touches_tribe(player, slot, next_to):
			return slot
	return -1


static func _touches_tribe(player: PlayerState, slot: int, tribe: String) -> bool:
	for other: int in BoardGeometry.neighbours(slot):
		var unit: RecruitUnit = player.board[other]
		if unit != null and unit.tribes().has(tribe):
			return true
	return false


static func random_empty_slot(player: PlayerState) -> int:
	var empties: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if player.board[slot] == null:
			empties.append(slot)
	return -1 if empties.is_empty() else empties[player.bot_rng.randi_range(0, empties.size() - 1)]


static func player_occupied(player: PlayerState) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if player.board[slot] != null:
			out.append(slot)
	return out


static func _front_score(player: PlayerState, value: BotEval, slot: int) -> float:
	var unit: RecruitUnit = player.board[slot]
	var score: float = unit.health - 0.5 * unit.attack
	if BoardGeometry.is_front(slot):
		score += ROW_STAY
	var row: String = value.row_of(unit)
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
	var ringed: Array[int] = []
	var plain: Array[int] = []
	for slot: int in order:
		if layout[slot] >= 0:
			continue
		if _ring_at(player, slot) > 0:
			ringed.append(slot)
		else:
			plain.append(slot)
	ringed.sort_custom(
		func(a: int, b: int) -> bool: return _ring_at(player, a) > _ring_at(player, b)
	)
	units.sort_custom(
		func(a: int, b: int) -> bool:
			return _ring_score(player, value, a) > _ring_score(player, value, b)
	)
	# The best units take the Rings; the rest stay where they stand unless they have to move.
	var rest: Array[int] = []
	for unit_slot: int in units:
		if not ringed.is_empty():
			layout[ringed.pop_front()] = unit_slot
		elif plain.has(unit_slot):
			layout[unit_slot] = unit_slot
			plain.erase(unit_slot)
		else:
			rest.append(unit_slot)
	for unit_slot: int in rest:
		layout[plain.pop_front()] = unit_slot


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
	if unit.has_mechanic_id("shy"):
		return 0.0
	return value.keep_value(unit)


## Units with a `faces` hint stand across from (or behind) the scouted unit with the most Attack.
static func _face_the_best(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	if player.scout.is_empty():
		return
	var target: int = _best_enemy_slot(player)
	if target < 0:
		return
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] < 0 or pinned.has(slot):
			continue
		var kind: String = value.hint(player.board[layout[slot]].def_id(), "faces")
		if kind == "":
			continue
		var wanted: int = target
		if kind == "behind":
			var options: Array[int] = BoardGeometry.behind(target)
			wanted = options[0] if not options.is_empty() else -1
		if wanted >= 0 and wanted != slot and not pinned.has(wanted):
			_swap(layout, slot, wanted)
		return


static func _best_enemy_slot(player: PlayerState) -> int:
	var seen: Array = player.scout["specs"]
	var best: int = -1
	var most: int = -1
	for slot: int in BoardGeometry.SLOTS:
		if slot < seen.size() and seen[slot] != null:
			var spec: Dictionary = seen[slot]
			var attack: int = CoreUtil.to_int(spec.get("attack", 0))
			if attack > most:
				best = slot
				most = attack
	return best


## Where each waiting Pass ends if the board stands like this.
static func _pass_landings(player: PlayerState, layout: Array[int]) -> Array[int]:
	var out: Array[int] = []
	if player.pending_passes.is_empty():
		return out
	var occupied: Array[bool] = []
	for slot: int in BoardGeometry.SLOTS:
		occupied.append(layout[slot] >= 0)
	for entry: Dictionary in player.pending_passes:
		var start: int = CoreUtil.to_int(entry["slot"])
		for slot: int in BoardGeometry.SLOTS:
			if (
				layout[slot] >= 0
				and player.board[layout[slot]].iid == CoreUtil.to_int(entry["iid"])
			):
				start = slot
		out.append(BoardGeometry.pass_landing(occupied, start))
	return out


## Puts the best unit that may gain stats where the most Passes end.
static func _land_passes_on_carry(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	var landings: Array[int] = _pass_landings(player, layout)
	if landings.is_empty() or landings[0] < 0 or pinned.has(landings[0]):
		return
	var target: int = landings[0]
	var best: int = -1
	var most: float = _ring_score(player, value, layout[target])
	# A swap can move the unit the Pass starts from, so each one is judged by where it then lands.
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] < 0 or pinned.has(slot) or slot == target:
			continue
		_swap(layout, slot, target)
		var landed: int = _pass_landings(player, layout)[0]
		var score: float = _ring_score(player, value, layout[landed]) if landed >= 0 else most
		_swap(layout, slot, target)
		if score > most:
			best = slot
			most = score
	if best >= 0:
		_swap(layout, best, target)


## The Queen's tithe destroys the units behind her: she stands in a corner with the least valuable
## unit behind her, and never with nobody there, which would cost herself.
static func _shelter_from_the_tithe(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> void:
	var queen: int = -1
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0 and player.board[layout[slot]].has_mechanic_id("teind"):
			queen = slot
	if queen < 0 or pinned.has(queen) or not BoardGeometry.is_front(queen):
		return
	for corner: int in [0, 3]:
		if corner == queen:
			break
		if not pinned.has(corner):
			_swap(layout, queen, corner)
			queen = corner
			break
	var behind: Array[int] = BoardGeometry.behind(queen)
	if behind.is_empty() or pinned.has(behind[0]):
		return
	var cheapest: int = -1
	var lowest: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] < 0 or slot == queen or pinned.has(slot):
			continue
		var worth: float = value.keep_value(player.board[layout[slot]])
		if cheapest < 0 or worth < lowest:
			cheapest = slot
			lowest = worth
	if cheapest >= 0:
		_swap(layout, cheapest, behind[0])


static func _swap(layout: Array[int], a: int, b: int) -> void:
	var keep: int = layout[a]
	layout[a] = layout[b]
	layout[b] = keep


static func _searched(
	player: PlayerState,
	rules: RecruitRules,
	first: Array[int],
	value: BotEval,
	budget: int,
	pinned: Array[int]
) -> Array[int]:
	BotProfile.enter("setup")
	var problem := BoardSearch.Problem.new()
	problem.board = BoardSearch.arranged_specs(player.board_specs(), first)
	problem.empty_specs = BotEggs.specs(player)
	problem.slots = player.combat_slots()
	problem.hero_effects = HeroRules.effects_of(player.hero)
	problem.tier = player.tier
	problem.round_number = player.round_number
	problem.enemy = player.scout["specs"]
	problem.enemy_slots = player.scout["slots"]
	problem.enemy_hero_effects = player.scout["hero_effects"]
	problem.enemy_tier = player.scout["tier"]
	problem.side_rules = [rules.fight_rules(player), player.scout["rules"]]
	problem.pinned = _search_pins(player, value, first, pinned)
	# This layout is fixed for the whole search; scoring it per candidate is wasted work.
	var base_lane_score: float = BotLanes.score(player, value, first)
	problem.layout_bonus = _layout_bonus.bind(player, value, first, base_lane_score)
	problem.library = rules.library
	problem.config = rules.config
	BotProfile.leave()
	var second: Array[int] = BoardSearch.best_layout(problem, player.bot_rng, budget)
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		out.append(first[second[slot]] if second[slot] >= 0 else -1)
	return out


## A generic carry is a reliable landmark for the next opponent's scout. Keep its slot during
## speculative fight search; lane cards and cards with a specific facing still choose matchups.
static func _search_pins(
	player: PlayerState, value: BotEval, layout: Array[int], pinned: Array[int]
) -> Array[int]:
	var out: Array[int] = pinned.duplicate()
	var best: int = -1
	var most: float = 0.0
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] < 0:
			continue
		var unit: RecruitUnit = player.board[layout[slot]]
		if BotLanes.positional(unit) or value.hint(unit.def_id(), "faces") != "":
			continue
		var worth: float = value.keep_value(unit)
		if best < 0 or worth > most:
			best = slot
			most = worth
	if best >= 0 and not out.has(best):
		out.append(best)
	if BotPass3.active(player) and BotPass3.fairy_build(value):
		for slot: int in BoardGeometry.SLOTS:
			if layout[slot] >= 0:
				var unit: RecruitUnit = player.board[layout[slot]]
				if unit.def_id() in BotPass3.FAIRY_ENGINES and not out.has(slot):
					out.append(slot)
	return out


## What a fight cannot show about a layout: who keeps the permanent Passes.
static func _layout_bonus(
	second: Array[int],
	player: PlayerState,
	value: BotEval,
	first: Array[int],
	base_lane_score: float
) -> float:
	var layout: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		layout.append(first[second[slot]] if second[slot] >= 0 else -1)
	var bonus: float = 0.0
	if second == BoardSearch.identity_layout():
		bonus += STAY_BONUS
	for landing: int in _pass_landings(player, layout):
		if (
			landing >= 0
			and layout[landing] >= 0
			and not player.board[layout[landing]].has_mechanic_id("shy")
		):
			bonus += PASS_WEIGHT * value.keep_value(player.board[layout[landing]]) / 10.0
	bonus += 0.01 * (BotLanes.score(player, value, layout) - base_lane_score)
	return bonus
