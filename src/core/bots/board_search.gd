class_name BoardSearch
extends RefCounted
## Finds a good arrangement of a board by playing quiet fights against the board the bot has
## scouted: successive halving over the current layout, swaps of it and a few random layouts, with
## the same seed for every layout. Pure: it never touches a live game. `budget` is the most fights
## one call may run. Ported from ideation/position-test (evidence/position-test.md) to Engine v2:
## it carries slot effects and heroes into the fights, and pinned slots stay put.
##
## A layout is 7 ints: layout[slot] is the slot of the input board whose unit stands there, or -1.

const FIRST_ROUND_FIGHTS: int = 2
const MIN_CANDIDATES: int = 6
const RANDOM_SHARE: float = 0.25
## Score of one fight, from side 0: win/loss plus this much per point of damage, so that boards
## the bot outclasses still separate layouts.
const DAMAGE_WEIGHT: float = 0.1


## What a search needs to know about both sides. `pinned` lists slots whose unit may not move.
## `layout_bonus` is optional: Callable(layout: Array[int]) -> float, in fight-score units.
class Problem:
	extends RefCounted
	var board: Array = []
	var slots: Array = []
	var hero_effects: Array = []
	var tier: int = 1
	var enemy: Array = []
	var enemy_slots: Array = []
	var enemy_hero_effects: Array = []
	var enemy_tier: int = 1
	var side_rules: Array = [{}, {}]
	var pinned: Array[int] = []
	var layout_bonus: Callable = Callable()
	## Layouts to try besides the current one, before swaps and random ones.
	var challengers: Array = []
	## The layout bonus counts in full however many fights a layout gets; otherwise it fades as
	## fights add up, as it always has.
	var fixed_bonus: bool = false
	var library: UnitLibrary
	var config: GameConfig


## Returns the best layout found; the unchanged board when there is nothing to search against.
static func best_layout(problem: Problem, rng: RandomNumberGenerator, budget: int) -> Array[int]:
	var current: Array[int] = identity_layout()
	var occupied: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if problem.board[slot] != null:
			occupied.append(slot)
	if occupied.is_empty() or problem.enemy.is_empty() or budget < FIRST_ROUND_FIGHTS:
		return current
	var search := _Search.new()
	search.problem = problem
	search.remaining = budget
	search.base_seed = rng.randi()
	var pool: Array[_Candidate] = [_Candidate.make(current)]
	var seen: Dictionary = {str(current): true}
	@warning_ignore("integer_division")
	var wanted: int = maxi(MIN_CANDIDATES, budget / (3 * FIRST_ROUND_FIGHTS))
	for value: Variant in problem.challengers:
		if value is Array:
			var challenger: Array[int] = []
			var entries: Array = value
			challenger.assign(entries)
			_add_if_new(pool, seen, challenger)
	var randoms: int = ceili(wanted * RANDOM_SHARE)
	for attempt: int in randoms * 3:
		if pool.size() > randoms + problem.challengers.size():
			break
		var layout: Array[int] = random_layout(occupied, rng, problem.pinned)
		_add_if_new(pool, seen, layout)
	for swapped: Array[int] in _swaps(current, rng, problem.pinned):
		if pool.size() >= wanted:
			break
		_add_if_new(pool, seen, swapped)
	var target: int = FIRST_ROUND_FIGHTS
	while pool.size() > 1 and search.remaining > 0:
		search.top_up(pool, target)
		pool.sort_custom(_better)
		pool.resize(maxi(1, ceili(pool.size() / 2.0)))
		target *= 2
	pool.sort_custom(_better)
	return pool[0].layout


## Any arrangement of the occupied slots over the 7 slots, each equally likely; pinned slots stay.
static func random_layout(
	occupied: Array[int], rng: RandomNumberGenerator, pinned: Array[int] = []
) -> Array[int]:
	var free_slots: Array[int] = []
	var movers: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if not pinned.has(slot):
			free_slots.append(slot)
	for slot: int in occupied:
		if not pinned.has(slot):
			movers.append(slot)
	for i: int in range(free_slots.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = free_slots[i]
		free_slots[i] = free_slots[j]
		free_slots[j] = swap
	var layout: Array[int] = []
	layout.resize(BoardGeometry.SLOTS)
	layout.fill(-1)
	for slot: int in pinned:
		if occupied.has(slot):
			layout[slot] = slot
	for index: int in movers.size():
		layout[free_slots[index]] = movers[index]
	return layout


static func identity_layout() -> Array[int]:
	return [0, 1, 2, 3, 4, 5, 6]


## A combat board (null or spec entries) rearranged by a layout.
static func arranged_specs(board: Array, layout: Array[int]) -> Array:
	var out: Array = []
	out.resize(BoardGeometry.SLOTS)
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0:
			out[slot] = board[layout[slot]]
	return out


## One fight's value for side 0.
static func fight_score(result: Dictionary) -> float:
	var winner: int = result["winner"]
	var damage: int = result["damage"]
	if winner == 0:
		return 1.0 + DAMAGE_WEIGHT * damage
	if winner == 1:
		return -1.0 - DAMAGE_WEIGHT * damage
	return 0.0


static func _add_if_new(pool: Array[_Candidate], seen: Dictionary, layout: Array[int]) -> void:
	var key: String = str(layout)
	if not seen.has(key):
		seen[key] = true
		pool.append(_Candidate.make(layout))


## Every two-slot swap of a layout that moves a unit and no pinned slot, in random order.
static func _swaps(layout: Array[int], rng: RandomNumberGenerator, pinned: Array[int]) -> Array:
	var out: Array = []
	for a: int in BoardGeometry.SLOTS:
		for b: int in range(a + 1, BoardGeometry.SLOTS):
			if pinned.has(a) or pinned.has(b):
				continue
			if layout[a] >= 0 or layout[b] >= 0:
				var swapped: Array[int] = layout.duplicate()
				swapped[a] = layout[b]
				swapped[b] = layout[a]
				out.append(swapped)
	for i: int in range(out.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Array[int] = out[i]
		out[i] = out[j]
		out[j] = swap
	return out


static func _better(a: _Candidate, b: _Candidate) -> bool:
	return a.mean() > b.mean()


class _Candidate:
	extends RefCounted
	var layout: Array[int] = []
	var total: float = 0.0
	var fights: int = 0
	## The layout bonus when the problem's fixed_bonus is on.
	var bonus: float = 0.0

	static func make(from_layout: Array[int]) -> _Candidate:
		var candidate := _Candidate.new()
		candidate.layout = from_layout
		return candidate

	func mean() -> float:
		return total / maxi(1, fights) + bonus


class _Search:
	extends RefCounted
	var problem: Problem
	var remaining: int = 0
	var base_seed: int = 0

	## Plays each candidate up to `target` fights in all, while the budget lasts. Fight number n
	## has the same seed for every candidate.
	func top_up(pool: Array[_Candidate], target: int) -> void:
		var fight_rng := RandomNumberGenerator.new()
		var tiers: Array[int] = [problem.tier, problem.enemy_tier]
		var ids: Array[int] = [0, 1]
		for candidate: _Candidate in pool:
			var mine: Array = BoardSearch.arranged_specs(problem.board, candidate.layout)
			if candidate.fights == 0 and problem.layout_bonus.is_valid():
				var bonus: float = problem.layout_bonus.call(candidate.layout)
				if problem.fixed_bonus:
					candidate.bonus = bonus
				else:
					candidate.total = bonus * target
			while candidate.fights < target and remaining > 0:
				remaining -= 1
				fight_rng.seed = base_seed + candidate.fights
				var combat: Combat = Combat.create(problem.library, problem.config, fight_rng)
				combat.log_events = false
				combat.side_rules = problem.side_rules
				combat.slot_effects = [problem.slots, problem.enemy_slots]
				combat.hero_effects = [problem.hero_effects, problem.enemy_hero_effects]
				var result: Dictionary = combat.run([mine, problem.enemy], tiers, ids, 0)
				candidate.total += BoardSearch.fight_score(result)
				candidate.fights += 1
