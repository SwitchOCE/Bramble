extends SceneTree
## What the reveal's swaps are worth in the fights bots really have (evidence/reveal.md). Plays
## full bench games with the reveal on and, at every fight between two players, scores each side's
## snapshot against the enemy board as it fought (after the enemy's own swaps), on the same 32
## fight seeds: standing still, random swaps, the bot's swaps, and the best board within the swap
## limit (every reachable board, a 600-fight search). It also replays the real fight with this
## side standing still, to say whether its swaps changed the result.
##   godot --headless -s res://tools/sim/reveal_probe.gd -- games=1 first_seed=31 out=<csv> \
##     set="reveal_swaps:1"

const MAX_TURNS: int = 60
const EVAL_SEEDS: int = 32
const RANDOMS: int = 8
const SEEDS_PER_RANDOM: int = 4
const ORACLE_BUDGET: int = 600

var _options: Dictionary = {
	"suite": "place_search", "games": "1", "first_seed": "31", "out": "reveal.csv", "set": ""
}
var _library: UnitLibrary
var _file: FileAccess
var _session: GameSession
var _config: GameConfig
var _seed: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() == 2 and _options.has(parts[0]):
			_options[parts[0]] = parts[1]
	_library = UnitLibrary.load_dir()
	_file = FileAccess.open(str(_options["out"]), FileAccess.WRITE)
	(
		_file
		. store_line(
			"seed,round,seat,units,swaps_made,still,random,chosen,best,usec,changed,won,won_still,replay_ok"
		)
	)
	var first: int = str(_options["first_seed"]).to_int()
	for game_seed: int in range(first, first + str(_options["games"]).to_int()):
		_play(str(_options["suite"]), game_seed)
	_file.close()
	quit(0)


func _play(suite: String, game_seed: int) -> void:
	var seats: PackedStringArray = BenchSuites.seats(suite, game_seed)
	_config = GameConfig.full_game()
	_config.set_value("human_bot", seats[0])
	_config.set_value("bots", Array(seats.slice(1)))
	var problem: String = BenchSuites.apply_settings(_config, str(_options["set"]))
	if problem != "":
		printerr("ERROR reveal_probe: %s" % problem)
	_seed = game_seed
	_session = GameSession.create(game_seed, _library, _config)
	_session.fight_observer = _on_fight
	var turns: int = 0
	while not _session.is_over() and turns < MAX_TURNS:
		_session.end_turn()
		turns += 1


func _on_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	if id_b < 0 or not result.has("reveal"):
		return
	var players: Array = _session.get("_players")
	var rules: RecruitRules = _session.get_rules()
	var sides: Array[PlayerState] = [players[id_a], players[id_b]]
	var reveal: Dictionary = result["reveal"]
	var winner: int = result["winner"]
	var slots: Array = [sides[0].combat_slots(), sides[1].combat_slots()]
	var heroes: Array = [HeroRules.effects_of(sides[0].hero), HeroRules.effects_of(sides[1].hero)]
	var tiers: Array[int] = [sides[0].tier, sides[1].tier]
	var side_rules: Array = [rules.fight_rules(sides[0]), rules.fight_rules(sides[1])]
	var before: Array = reveal["before"]
	var after: Array = reveal["after"]
	var replay_ok: bool = _replay(reveal, after, slots, heroes, tiers, side_rules) == winner
	for side: int in 2:
		var board: Array = before[side]
		var units: int = 0
		for spec: Variant in board:
			units += 1 if spec != null else 0
		if units == 0:
			continue
		# This side's snapshot against the enemy as it fought.
		var real: Array = after.duplicate()
		real[side] = before[side]
		var problem: BoardSearch.Problem = Reveal.problem_for(
			real, slots, heroes, tiers, side_rules, side, _library, _config
		)
		var rng := RandomNumberGenerator.new()
		rng.seed = ("reveal|%d|%d|%d" % [_seed, round_number, sides[side].id]).hash()
		var base: int = rng.randi()
		var layouts: Array = reveal["layouts"]
		var picked: Array = layouts[side]
		var chosen: Array[int] = []
		chosen.assign(picked)
		var swaps: int = _config.get_int("reveal_swaps")
		var random_total: float = 0.0
		for index: int in RANDOMS:
			random_total += _score(
				problem,
				Reveal.random_swaps(board, swaps, rng),
				base + index * SEEDS_PER_RANDOM,
				SEEDS_PER_RANDOM
			)
		var oracle: BoardSearch.Problem = _with_all(problem, board, swaps)
		var best: Array[int] = BoardSearch.best_layout(oracle, rng, ORACLE_BUDGET)
		var still_winner: int = _replay(reveal, real, slots, heroes, tiers, side_rules)
		var usec: Array = reveal["usec"]
		(
			_file
			. store_line(
				(
					"%d,%d,%d,%d,%d,%.4f,%.4f,%.4f,%.4f,%d,%d,%.1f,%.1f,%d"
					% [
						_seed,
						round_number,
						sides[side].id,
						units,
						_swaps_in(chosen),
						_score(problem, BoardSearch.identity_layout(), base, EVAL_SEEDS),
						random_total / RANDOMS,
						_score(problem, chosen, base, EVAL_SEEDS),
						_score(problem, best, base + 100000, EVAL_SEEDS),
						usec[side],
						1 if still_winner != winner else 0,
						_points(winner, side),
						_points(still_winner, side),
						1 if replay_ok else 0,
					]
				)
			)
		)


## The problem with every board within the swap limit as a challenger.
static func _with_all(
	problem: BoardSearch.Problem, board: Array, swaps: int
) -> BoardSearch.Problem:
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
	var all: Array = Reveal.reachable(board, swaps)
	all.pop_front()
	out.challengers = all
	out.only_challengers = true
	out.first_round_fights = 1
	return out


## Slots that changed, halved: a swap moves two.
static func _swaps_in(layout: Array[int]) -> int:
	var moved: int = 0
	for slot: int in BoardGeometry.SLOTS:
		moved += 1 if layout[slot] != slot else 0
	@warning_ignore("integer_division")
	return (moved + 1) / 2


## 1 for a win for `side`, 0.5 for a tie, 0 for a loss.
static func _points(winner: int, side: int) -> float:
	if winner == side:
		return 1.0
	return 0.0 if winner == 1 - side else 0.5


## The real fight again, with these boards: its winner.
func _replay(
	reveal: Dictionary,
	boards: Array,
	slots: Array,
	heroes: Array,
	tiers: Array[int],
	side_rules: Array
) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = reveal["fight_seed"]
	rng.state = reveal["fight_state"]
	var combat: Combat = Combat.create(_library, _config, rng)
	combat.log_events = false
	combat.slot_effects = slots
	combat.hero_effects = heroes
	combat.side_rules = side_rules
	var ids: Array[int] = [0, 1]
	var result: Dictionary = combat.run(boards, tiers, ids, 0)
	return result["winner"]


## Win rate (ties half) over `count` fights from seed `first`.
func _score(problem: BoardSearch.Problem, layout: Array[int], first: int, count: int) -> float:
	var mine: Array = BoardSearch.arranged_specs(problem.board, layout)
	var wins: float = 0.0
	var fight_rng := RandomNumberGenerator.new()
	for index: int in count:
		fight_rng.seed = first + index
		var combat: Combat = Combat.create(problem.library, problem.config, fight_rng)
		combat.log_events = false
		combat.side_rules = problem.side_rules
		combat.slot_effects = [problem.slots, problem.enemy_slots]
		combat.hero_effects = [problem.hero_effects, problem.enemy_hero_effects]
		var result: Dictionary = combat.run(
			[mine, problem.enemy], [problem.tier, problem.enemy_tier], [0, 1], 0
		)
		var winner: int = result["winner"]
		if winner == 0:
			wins += 1.0
		elif winner != 1:
			wins += 0.5
	return wins / count
