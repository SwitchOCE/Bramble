class_name BoardSearch
extends RefCounted
## Finds a good arrangement of a board by playing headless fights against given opponent boards:
## successive halving over random layouts, the current one and swaps of the early leader, with the
## same opponents and fight seeds for every layout. Pure: it never touches a live game, so a Hard
## bot can reuse it. `budget` is the most fights one call may run.
##
## A layout is 7 ints: layout[slot] is the slot of the input board whose unit stands there, or -1.

const FIRST_ROUND_FIGHTS: int = 2
const MAX_SWAPS: int = 12
const MIN_CANDIDATES: int = 8
## Score of one fight, from side 0: win/loss plus this much per point of damage, so that stale
## boards the bot now outclasses still separate layouts.
const DAMAGE_WEIGHT: float = 0.1


## The opponents a player would search against: this round's opponent's last seen board counts
## twice, then the last three opponents' boards. `oracle` uses the real board instead.
static func opponents_for(player: PlayerState, oracle: bool) -> Array:
	if oracle:
		return [] if player.scouted_board.is_empty() else [player.scouted_board]
	var out: Array = []
	if player.seen_boards.has(player.next_opponent):
		var next_board: Array = player.seen_boards[player.next_opponent]
		out.append(next_board)
		out.append(next_board)
	for opponent: int in player.recent_opponents:
		var seen: Array = player.seen_boards[opponent]
		if not out.has(seen):
			out.append(seen)
	return out


## Returns the best layout found; the unchanged board when there is nothing to search against.
static func best_layout(
	board: Array,
	opponents: Array,
	library: UnitLibrary,
	config: GameConfig,
	rng: RandomNumberGenerator,
	budget: int
) -> Array[int]:
	var current: Array[int] = identity_layout()
	var occupied: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if slot < board.size() and board[slot] != null:
			occupied.append(slot)
	if occupied.is_empty() or opponents.is_empty() or budget < FIRST_ROUND_FIGHTS:
		return current
	var state := _Search.new()
	state.board = board
	state.opponents = opponents
	state.library = library
	state.config = config
	state.remaining = budget
	state.base_seed = rng.randi()
	var pool: Array[_Candidate] = [_Candidate.make(current)]
	var seen: Dictionary = {str(current): true}
	@warning_ignore("integer_division")
	var wanted: int = maxi(MIN_CANDIDATES, budget / (4 * FIRST_ROUND_FIGHTS))
	for attempt: int in wanted * 3:
		if pool.size() >= wanted:
			break
		_add_if_new(pool, seen, random_layout(occupied, rng))
	var target: int = FIRST_ROUND_FIGHTS
	var added_swaps: bool = false
	while pool.size() > 1 and state.remaining > 0:
		state.top_up(pool, target)
		pool.sort_custom(_better)
		pool.resize(maxi(1, ceili(pool.size() / 2.0)))
		if not added_swaps:
			added_swaps = true
			for swapped: Array[int] in _swaps(pool[0].layout, rng):
				_add_if_new(pool, seen, swapped)
		target *= 2
	pool.sort_custom(_better)
	return pool[0].layout


## Any arrangement of the given occupied slots over the 7 slots, each equally likely.
static func random_layout(occupied: Array[int], rng: RandomNumberGenerator) -> Array[int]:
	var slots: Array[int] = identity_layout()
	for i: int in range(slots.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = slots[i]
		slots[i] = slots[j]
		slots[j] = swap
	var layout: Array[int] = []
	layout.resize(BoardGeometry.SLOTS)
	layout.fill(-1)
	for index: int in occupied.size():
		layout[slots[index]] = occupied[index]
	return layout


static func identity_layout() -> Array[int]:
	return [0, 1, 2, 3, 4, 5, 6]


## A typed recruit board rearranged by a layout.
static func arranged(board: Array[RecruitUnit], layout: Array[int]) -> Array[RecruitUnit]:
	var out: Array[RecruitUnit] = []
	out.resize(BoardGeometry.SLOTS)
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0:
			out[slot] = board[layout[slot]]
	return out


## A combat board (null or spec entries) rearranged by a layout.
static func arranged_specs(board: Array, layout: Array[int]) -> Array:
	var out: Array = []
	out.resize(BoardGeometry.SLOTS)
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0:
			out[slot] = board[layout[slot]]
	return out


static func _add_if_new(pool: Array[_Candidate], seen: Dictionary, layout: Array[int]) -> void:
	var key: String = str(layout)
	if not seen.has(key):
		seen[key] = true
		pool.append(_Candidate.make(layout))


static func _swaps(layout: Array[int], rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for a: int in BoardGeometry.SLOTS:
		for b: int in range(a + 1, BoardGeometry.SLOTS):
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
	return out.slice(0, MAX_SWAPS)


static func _better(a: _Candidate, b: _Candidate) -> bool:
	return a.mean() > b.mean()


class _Candidate:
	extends RefCounted
	var layout: Array[int] = []
	var total: float = 0.0
	var fights: int = 0

	static func make(from_layout: Array[int]) -> _Candidate:
		var candidate := _Candidate.new()
		candidate.layout = from_layout
		return candidate

	func mean() -> float:
		return total / maxi(1, fights)


class _Search:
	extends RefCounted
	var board: Array = []
	var opponents: Array = []
	var library: UnitLibrary
	var config: GameConfig
	var remaining: int = 0
	var base_seed: int = 0

	## Plays each candidate up to `target` fights in all, while the budget lasts. Fight number n
	## has the same opponent and seed for every candidate.
	func top_up(pool: Array[_Candidate], target: int) -> void:
		var fight_rng := RandomNumberGenerator.new()
		var tiers: Array[int] = [1, 1]
		var ids: Array[int] = [0, 1]
		for candidate: _Candidate in pool:
			var mine: Array = BoardSearch.arranged_specs(board, candidate.layout)
			while candidate.fights < target and remaining > 0:
				remaining -= 1
				var number: int = candidate.fights
				var theirs: Array = opponents[number % opponents.size()]
				fight_rng.seed = base_seed + number
				var combat: Combat = Combat.create(library, config, fight_rng)
				combat.log_events = false
				candidate.total += BoardSearch.fight_score(
					combat.run([mine, theirs], tiers, ids, 0)
				)
				candidate.fights += 1


## One fight's value for side 0.
static func fight_score(result: Dictionary) -> float:
	var winner: int = result["winner"]
	var damage: int = result["damage"]
	if winner == 0:
		return 1.0 + DAMAGE_WEIGHT * damage
	if winner == 1:
		return -1.0 - DAMAGE_WEIGHT * damage
	return 0.0
