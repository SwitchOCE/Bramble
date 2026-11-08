extends RefCounted
## Combat-only placing bar on real, pre-fight bench snapshots. See placing-bar.md for seeds.
## The runner is placing_bar_run.gd; run_probe is also used by the two-board GUT smoke.

const FIRST_GAME: int = 11082001
const SAMPLE_SEED: int = 12082001
const SCREEN_SEED: int = 13082000000
const SEARCH_SEED: int = 14082000000
const EVAL_SEED: int = 15082000000
const SHUFFLE_SEED: int = 16082000000
const SCREEN_FIGHTS: int = 40
const STRIDE: int = 1000
const MIN_ROUND: int = 6
const LATE_ROUND: int = 10

var library: UnitLibrary = UnitLibrary.load_dir()
var candidates: Array[Dictionary] = []
var sample_rng := RandomNumberGenerator.new()


## Override only the fight boundary: capture before combat carry mutates recruit units.
class BenchSession:
	extends GameSession
	var capture: Callable

	func _run_fights() -> void:
		capture.call(self)
		super._run_fights()


func collect(first: int, games: int) -> void:
	for game_seed: int in range(first, first + games):
		var seats: PackedStringArray = BenchSuites.seats("hard_lobby_hard", game_seed)
		var config: GameConfig = GameConfig.full_game()
		config.set_value("human_bot", seats[0])
		config.set_value("bots", Array(seats.slice(1)))
		var session := BenchSession.new()
		session._seed = game_seed
		session._library = library
		session._config = config
		session.capture = _capture
		session._setup()
		if session._hero_offer.is_empty():
			session._start_round()
		var turns: int = 0
		while not session.is_over() and turns < 60:
			session.end_turn()
			turns += 1
		assert(session.is_over(), "bench game did not finish")
		session.capture = Callable()
		print(
			"placing_game: seed=%d rounds=%d candidates=%d" % [game_seed, turns, candidates.size()]
		)


func _capture(session: BenchSession) -> void:
	if session._round < MIN_ROUND:
		return
	for pairing: Array in session._pairings:
		if pairing.has(Matchmaking.GHOST):
			continue
		var side: int = sample_rng.randi_range(0, 1)
		var player: PlayerState = session._players[CoreUtil.to_int(pairing[side])]
		var enemy: PlayerState = session._players[CoreUtil.to_int(pairing[1 - side])]
		if player.board_count() < 5:
			continue
		var brain: BotBrain = session._bots[player.id]
		brain.value.board_owner = player
		var pins: Array[int] = BotPlacer.pinned_slots(player)
		var rule: Array[int] = BotPlacer.rule_layout(player, brain.value, pins)
		brain.value.board_owner = null
		var problem := BoardSearch.Problem.new()
		problem.board = BoardSearch.arranged_specs(player.board_specs(), rule).duplicate(true)
		problem.empty_specs = BotEggs.specs(player).duplicate(true)
		problem.slots = player.combat_slots().duplicate(true)
		problem.hero_effects = HeroRules.effects_of(player.hero).duplicate(true)
		problem.tier = player.tier
		problem.enemy = enemy.combat_board().duplicate(true)
		problem.enemy_slots = enemy.combat_slots().duplicate(true)
		problem.enemy_hero_effects = HeroRules.effects_of(enemy.hero).duplicate(true)
		problem.enemy_tier = enemy.tier
		problem.side_rules = [
			session._rules.fight_rules(player).duplicate(true),
			session._rules.fight_rules(enemy).duplicate(true),
		]
		problem.pinned = pins
		problem.library = library
		problem.config = session._config
		(
			candidates
			. append(
				{
					"game_seed": session._seed,
					"round": session._round,
					"seat": player.id,
					"opponent": enemy.id,
					"units": player.board_count(),
					"rule_layout": rule,
					"problem": problem,
				}
			)
		)


## Exactly half mid-game, half late-game. Never lower the requested board count silently.
func run_probe(
	boards: int = 100,
	games: int = 24,
	fights: int = 40,
	budget: int = 200,
	first_game: int = FIRST_GAME,
	sampling_seed: int = SAMPLE_SEED,
	output: String = ""
) -> Dictionary:
	sample_rng.seed = sampling_seed
	collect(first_game, games)
	_shuffle(candidates)
	var rows: Array[Dictionary] = []
	var counts: Array[int] = [0, 0]
	var tested: int = 0
	var cursor: int = 0
	var next_game: int = first_game + games
	while rows.size() < boards:
		if cursor == candidates.size():
			if next_game >= first_game + 100:
				push_error("Not enough eligible boards: %d/%d" % [rows.size(), boards])
				break
			var old_size: int = candidates.size()
			collect(next_game, 1)
			next_game += 1
			var extra: Array[Dictionary] = candidates.slice(old_size)
			_shuffle(extra)
			candidates.resize(old_size)
			candidates.append_array(extra)
		var candidate: Dictionary = candidates[cursor]
		cursor += 1
		var stratum: int = 1 if CoreUtil.to_int(candidate["round"]) >= LATE_ROUND else 0
		@warning_ignore("integer_division")
		var wanted: int = boards / 2 + (boards % 2 if stratum == 1 else 0)
		if counts[stratum] >= wanted:
			continue
		var index: int = tested
		tested += 1
		var problem: BoardSearch.Problem = candidate["problem"]
		var screening: float = win_points(
			problem, BoardSearch.identity_layout(), SCREEN_SEED + STRIDE * index, SCREEN_FIGHTS
		)
		if screening < 0.2 or screening > 0.8:
			continue
		var row: Dictionary = measure(candidate, index, fights, budget)
		row["screen"] = screening
		rows.append(row)
		counts[stratum] += 1
		print("placing_board: %s" % JSON.stringify(row))
		if output != "":
			_write(output, {"rows": rows, "screened": tested, "complete": rows.size() == boards})
	var report: Dictionary = summarize(rows)
	report.merge(
		{
			"rows": rows,
			"screened": tested,
			"games": next_game - first_game,
			"fights": fights,
			"budget": budget,
			"complete": rows.size() == boards
		}
	)
	if output != "":
		_write(output, report)
	return report


func measure(candidate: Dictionary, index: int, fights: int, budget: int) -> Dictionary:
	var problem: BoardSearch.Problem = candidate["problem"]
	var rng := RandomNumberGenerator.new()
	rng.seed = SEARCH_SEED + STRIDE * index
	# BoardSearch draws uint32 seeds (< 2^32); screening/evaluation seeds are > 13 billion.
	var best: Array[int] = BoardSearch.best_layout(problem, rng, budget)
	var occupied: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if problem.board[slot] != null:
			occupied.append(slot)
	rng.seed = SHUFFLE_SEED + STRIDE * index
	var shuffled: Array[int] = BoardSearch.random_layout(occupied, rng, problem.pinned)
	var base: int = EVAL_SEED + STRIDE * index
	var rule_points: float = win_points(problem, BoardSearch.identity_layout(), base, fights)
	var best_points: float = win_points(problem, best, base, fights)
	var shuffled_points: float = win_points(problem, shuffled, base, fights)
	var changed: bool = false
	for slot: int in BoardGeometry.SLOTS:
		var source: int = best[slot]
		if source >= 0 and problem.board[source] != null:
			if BoardGeometry.is_front(slot) != BoardGeometry.is_front(source):
				changed = true
	var row: Dictionary = candidate.duplicate()
	row.erase("problem")
	row.merge(
		{
			"index": index,
			"rule": rule_points,
			"best": best_points,
			"shuffled": shuffled_points,
			"row_changed": changed,
			"best_layout": best,
			"shuffled_layout": shuffled,
			"eval_seed": base,
			"search_seed": SEARCH_SEED + STRIDE * index
		}
	)
	return row


## Same held-out seeds across layouts; never reselect the layout using these outcomes.
func win_points(problem: BoardSearch.Problem, layout: Array[int], base: int, fights: int) -> float:
	var points: float = 0.0
	var rng := RandomNumberGenerator.new()
	var board: Array = BoardSearch.combat_specs(problem, layout)
	var tiers: Array[int] = [problem.tier, problem.enemy_tier]
	var ids: Array[int] = [0, 1]
	for number: int in fights:
		rng.seed = base + number
		var combat: Combat = Combat.create(library, problem.config, rng)
		combat.log_events = false
		combat.side_rules = problem.side_rules
		combat.slot_effects = [problem.slots, problem.enemy_slots]
		combat.hero_effects = [problem.hero_effects, problem.enemy_hero_effects]
		var result: Dictionary = combat.run([board, problem.enemy], tiers, ids, 0)
		var winner: int = result["winner"]
		points += 1.0 if winner == 0 else (0.5 if winner < 0 else 0.0)
	return points / fights


static func summarize(rows: Array[Dictionary]) -> Dictionary:
	var gain: float = 0.0
	var smoke: float = 0.0
	var changed: int = 0
	for row: Dictionary in rows:
		var best: float = row["best"]
		var rule: float = row["rule"]
		var shuffled: float = row["shuffled"]
		gain += 100.0 * (best - rule)
		smoke += 100.0 * (best - shuffled)
		changed += 1 if CoreUtil.to_bool(row["row_changed"]) else 0
	var count: int = rows.size()
	assert(count > 1)
	gain /= count
	smoke /= count
	var squares: float = 0.0
	for row: Dictionary in rows:
		var best: float = row["best"]
		var rule: float = row["rule"]
		var delta: float = 100.0 * (best - rule)
		squares += (delta - gain) ** 2
	# Exact two-sided t(99) for the registered sample; two-board smoke uses t(1).
	assert(count == 100 or count == 2)
	var critical: float = 1.9842169515 if count == 100 else 12.7062047364
	var half: float = critical * sqrt(squares / (count - 1) / count)
	return {
		"boards": count,
		"gain_pp": gain,
		"ci_low_pp": gain - half,
		"ci_high_pp": gain + half,
		"row_changes": changed,
		"row_change_share": float(changed) / count,
		"smoke_pp": smoke,
		"pass_a": gain >= 5.0 and gain - half > 0.0,
		"pass_b": float(changed) / count >= 0.25
	}


func _shuffle(items: Array[Dictionary]) -> void:
	for index: int in range(items.size() - 1, 0, -1):
		var other: int = sample_rng.randi_range(0, index)
		var swap: Dictionary = items[index]
		items[index] = items[other]
		items[other] = swap


static func _write(path: String, value: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "cannot write probe output")
	file.store_line(JSON.stringify(value, "\t"))
