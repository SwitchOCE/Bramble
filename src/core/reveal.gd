class_name Reveal
extends RefCounted
## The reveal, a test rule that is off by default (evidence/reveal.md). After recruiting, both
## players see each other's real fight board, and each makes up to `reveal_swaps` swaps of their
## own slots, chosen at the same time from one snapshot. The swaps hold for this fight only: the
## recruit board, its turn counts, bands and Passes are untouched. Units carry home by iid, so the
## fight's buffs still find them.
##
## A layout here is a permutation of all 7 slots: layout[slot] is the slot of the snapshot whose
## entry (unit, Egg or gap) stands there. A swap exchanges two slots, at least one of them filled.

## Fights per greedy step for Hard, and for the levels that use a short search. Hard's 45 play up
## to 22 swaps once each, the better half twice, the best 6 four times.
const HARD_BUDGET: int = 45
const SHORT_BUDGET: int = 12


## Whether this round has a reveal.
static func applies(config: GameConfig, round_number: int) -> bool:
	return (
		config.get_int("reveal_swaps") > 0
		and round_number >= maxi(1, config.get_int("reveal_from_round"))
	)


## Every slot pair a swap may exchange on this board.
static func swap_pairs(board: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for a: int in BoardGeometry.SLOTS:
		for b: int in range(a + 1, BoardGeometry.SLOTS):
			if board[a] != null or board[b] != null:
				out.append(Vector2i(a, b))
	return out


static func swapped(layout: Array[int], pair: Vector2i) -> Array[int]:
	var out: Array[int] = layout.duplicate()
	out[pair.x] = layout[pair.y]
	out[pair.y] = layout[pair.x]
	return out


## `inner` applied first, then `outer` on the board it made.
static func compose(inner: Array[int], outer: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		out.append(inner[outer[slot]])
	return out


## Every distinct board within `swaps` swaps, as layouts of the snapshot, the snapshot first.
static func reachable(board: Array, swaps: int) -> Array:
	var start: Array[int] = BoardSearch.identity_layout()
	var seen: Dictionary = {_key(board, start): true}
	var out: Array = [start]
	var frontier: Array = [start]
	for step: int in swaps:
		var next: Array = []
		for value: Variant in frontier:
			var entries: Array = value
			var layout: Array[int] = []
			layout.assign(entries)
			var here: Array = BoardSearch.arranged_specs(board, layout)
			for pair: Vector2i in swap_pairs(here):
				var moved: Array[int] = swapped(layout, pair)
				var key: String = _key(board, moved)
				if not seen.has(key):
					seen[key] = true
					out.append(moved)
					next.append(moved)
		frontier = next
	return out


## Up to `swaps` random swaps.
static func random_swaps(board: Array, swaps: int, rng: RandomNumberGenerator) -> Array[int]:
	var layout: Array[int] = BoardSearch.identity_layout()
	for step: int in swaps:
		var pairs: Array[Vector2i] = swap_pairs(BoardSearch.arranged_specs(board, layout))
		if pairs.is_empty():
			break
		layout = swapped(layout, pairs[rng.randi_range(0, pairs.size() - 1)])
	return layout


## Greedy: the best single swap against the problem's enemy, `swaps` times, each step a search
## of `budget` fights over standing still and every swap. Stops when standing still wins.
static func search(
	problem: BoardSearch.Problem, swaps: int, rng: RandomNumberGenerator, budget: int
) -> Array[int]:
	var total: Array[int] = BoardSearch.identity_layout()
	var board: Array = problem.board
	for step: int in swaps:
		var here := _copy(problem)
		here.board = BoardSearch.arranged_specs(board, total)
		var options: Array = []
		for pair: Vector2i in swap_pairs(here.board):
			options.append(swapped(BoardSearch.identity_layout(), pair))
		if options.is_empty():
			break
		here.challengers = options
		here.only_challengers = true
		here.first_round_fights = 1
		var best: Array[int] = BoardSearch.best_layout(here, rng, budget)
		if best == BoardSearch.identity_layout():
			break
		total = compose(total, best)
	return total


## A search problem for one side of a fight from the snapshot.
static func problem_for(
	boards: Array,
	slots: Array,
	heroes: Array,
	tiers: Array[int],
	side_rules: Array,
	side: int,
	library: UnitLibrary,
	config: GameConfig
) -> BoardSearch.Problem:
	var other: int = 1 - side
	var problem := BoardSearch.Problem.new()
	problem.board = boards[side]
	problem.slots = slots[side]
	problem.hero_effects = heroes[side]
	problem.tier = tiers[side]
	problem.enemy = boards[other]
	problem.enemy_slots = slots[other]
	problem.enemy_hero_effects = heroes[other]
	problem.enemy_tier = tiers[other]
	var enemy_rules: Dictionary = side_rules[other]
	problem.side_rules = [side_rules[side], hidden_rules(enemy_rules)]
	problem.library = library
	problem.config = config
	return problem


## The enemy's fight rules as the reveal shows them: absent Birds stay hidden, so their Nests,
## Mother Goose's strikes and the Whistlers' count of Birds away are left out.
static func hidden_rules(rules: Dictionary) -> Dictionary:
	var out: Dictionary = rules.duplicate()
	out["nests"] = []
	out["goose"] = 0
	out["away_birds"] = []
	return out


static func _copy(problem: BoardSearch.Problem) -> BoardSearch.Problem:
	var out := BoardSearch.Problem.new()
	out.board = problem.board
	out.slots = problem.slots
	out.hero_effects = problem.hero_effects
	out.tier = problem.tier
	out.enemy = problem.enemy
	out.enemy_slots = problem.enemy_slots
	out.enemy_hero_effects = problem.enemy_hero_effects
	out.enemy_tier = problem.enemy_tier
	out.side_rules = problem.side_rules
	out.library = problem.library
	out.config = problem.config
	return out


static func _key(board: Array, layout: Array[int]) -> String:
	return str(BoardSearch.arranged_specs(board, layout))
