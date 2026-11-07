extends SceneTree
## How much a layout is worth in the fights bots really have (evidence/placing.md). Plays full
## bench games and, at every fight between two players, replays each side's board against the real
## enemy board with: the layout it chose, random layouts that move every unit, random layouts that
## keep pinned units, and the best layout a big search finds against the real board. Same fight
## seeds for every variant. Usage:
##   godot --headless -s res://tools/sim/place_probe.gd -- suite=place_search games=10 first_seed=1 out=<csv>

const MAX_TURNS: int = 60
const LAYOUTS: int = 8
const SEEDS_PER_LAYOUT: int = 4
const EVAL_SEEDS: int = 32
const ORACLE_BUDGET: int = 150

var _options: Dictionary = {
	"suite": "place_search", "games": "4", "first_seed": "1", "out": "probe.csv"
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
	_file.store_line(
		"seed,round,seat,units,pinned,mine_stats,their_stats,actual,shuffled_all,shuffled_free,best,"
		+ "actual_dmg,shuffled_all_dmg,best_dmg,rule,scouted,searched,mine,theirs,rule_old,rule_aim,rule_new,hard_old,hard_new,generic,scout_same"
	)
	var first: int = str(_options["first_seed"]).to_int()
	var games: int = str(_options["games"]).to_int()
	var suite: String = str(_options["suite"])
	for game_seed: int in range(first, first + games):
		_play(suite, game_seed)
	_file.close()
	quit(0)


func _play(suite: String, game_seed: int) -> void:
	var seats: PackedStringArray = BenchSuites.seats(suite, game_seed)
	_config = GameConfig.full_game()
	_config.set_value("human_bot", seats[0])
	_config.set_value("bots", Array(seats.slice(1)))
	_seed = game_seed
	_session = GameSession.create(game_seed, _library, _config)
	_session.fight_observer = _on_fight
	var turns: int = 0
	while not _session.is_over() and turns < MAX_TURNS:
		_session.end_turn()
		turns += 1


## Runs after the real fight and before its carry or damage, so both boards are as they fought.
func _on_fight(round_number: int, id_a: int, id_b: int, _result: Dictionary) -> void:
	if id_b < 0:
		return
	var players: Array = _session.get("_players")
	var rules: RecruitRules = _session.get_rules()
	var a: PlayerState = players[id_a]
	var b: PlayerState = players[id_b]
	_probe_side(round_number, a, b, rules)
	_probe_side(round_number, b, a, rules)


func _probe_side(round_number: int, me: PlayerState, them: PlayerState, rules: RecruitRules) -> void:
	var board: Array = me.combat_board()
	var occupied: Array[int] = []
	for slot: int in BoardGeometry.SLOTS:
		if board[slot] != null:
			occupied.append(slot)
	if occupied.size() < 2 or them.board_count() == 0:
		return
	var pinned: Array[int] = BotPlacer.pinned_slots(me)
	var problem := BoardSearch.Problem.new()
	problem.board = board
	problem.slots = me.combat_slots()
	problem.hero_effects = HeroRules.effects_of(me.hero)
	problem.tier = me.tier
	problem.enemy = them.combat_board()
	problem.enemy_slots = them.combat_slots()
	problem.enemy_hero_effects = HeroRules.effects_of(them.hero)
	problem.enemy_tier = them.tier
	problem.side_rules = [rules.fight_rules(me), rules.fight_rules(them)]
	problem.library = _library
	problem.config = _config
	var rng := RandomNumberGenerator.new()
	rng.seed = ("probe|%d|%d|%d" % [_seed, round_number, me.id]).hash()
	var base: int = rng.randi()
	var identity: Array[int] = BoardSearch.identity_layout()
	var actual: Vector2 = _score(problem, identity, base, EVAL_SEEDS)
	var all_total := Vector2.ZERO
	var free_total := Vector2.ZERO
	for index: int in LAYOUTS:
		var first: int = base + index * SEEDS_PER_LAYOUT
		all_total += _score(problem, BoardSearch.random_layout(occupied, rng), first, SEEDS_PER_LAYOUT)
		free_total += _score(
			problem, BoardSearch.random_layout(occupied, rng, pinned), first, SEEDS_PER_LAYOUT
		)
	var best_layout: Array[int] = BoardSearch.best_layout(problem, rng, ORACLE_BUDGET)
	# Scored on fresh seeds, so the search's luck on its own seeds doesn't count.
	var best: Vector2 = _score(problem, best_layout, base + 100000, EVAL_SEEDS)
	var rule: float = -1.0
	var scouted: float = -1.0
	var bots: Dictionary = _session.get("_bots")
	var brain: BotBrain = null
	var held: Variant = bots.get(me.id)
	if held is BotBrain:
		brain = held
	var same_board: bool = me.board_specs() == board
	if brain != null and same_board:
		var layout: Array[int] = BotPlacer.rule_layout(me, brain.value, pinned)
		rule = _score(problem, layout, base, EVAL_SEEDS).x
		if not me.scout.is_empty():
			var seen := BoardSearch.Problem.new()
			seen.board = board
			seen.slots = problem.slots
			seen.hero_effects = problem.hero_effects
			seen.tier = me.tier
			seen.enemy = me.scout["specs"]
			seen.enemy_slots = me.scout["slots"]
			seen.enemy_hero_effects = me.scout["hero_effects"]
			seen.enemy_tier = me.scout["tier"]
			seen.side_rules = [problem.side_rules[0], me.scout["rules"]]
			seen.pinned = pinned
			seen.library = _library
			seen.config = _config
			var found: Array[int] = BoardSearch.best_layout(seen, rng, ORACLE_BUDGET)
			scouted = _score(problem, found, base, EVAL_SEEDS).x
	_file.store_line(
		(
			"%d,%d,%d,%d,%d,%d,%d,%.4f,%.4f,%.4f,%.4f,%.3f,%.3f,%.3f,%.4f,%.4f,%d,%s,%s,%s,%.4f,%.4f"
			% [
				_seed,
				round_number,
				me.id,
				occupied.size(),
				pinned.size(),
				BotBrain.stat_sum(board),
				BotBrain.stat_sum(problem.enemy),
				actual.x,
				all_total.x / LAYOUTS,
				free_total.x / LAYOUTS,
				best.x,
				actual.y,
				all_total.y / LAYOUTS,
				best.y,
				rule,
				scouted,
				1 if BotPlacer.worth_searching(me) else 0,
				_ids(board),
				_ids(problem.enemy),
				_variants(problem, me, brain, rules, pinned, base) if same_board else "-1,-1,-1,-1,-1",
				_generic(problem, me, them, rules, rng, base),
				_scout_same(me, problem.enemy),
			]
		)
	)


## (win rate with ties as half, mean signed damage) over `count` fights from seed `first`.
func _score(problem: BoardSearch.Problem, layout: Array[int], first: int, count: int) -> Vector2:
	var mine: Array = BoardSearch.arranged_specs(problem.board, layout)
	var wins: float = 0.0
	var damage: float = 0.0
	var fight_rng := RandomNumberGenerator.new()
	for index: int in count:
		fight_rng.seed = first + index
		var combat: Combat = Combat.create(problem.library, problem.config, fight_rng)
		combat.log_events = false
		combat.side_rules = problem.side_rules
		combat.slot_effects = [problem.slots, problem.enemy_slots]
		combat.hero_effects = [problem.hero_effects, problem.enemy_hero_effects]
		var result: Dictionary = combat.run([mine, problem.enemy], [problem.tier, problem.enemy_tier], [0, 1], 0)
		var winner: int = result["winner"]
		var dealt: int = result["damage"]
		if winner == 0:
			wins += 1.0
			damage += dealt
		elif winner == 1:
			damage -= dealt
		else:
			wins += 0.5
	return Vector2(wins / count, damage / count)


## The board's unit ids by slot, ";"-joined, "-" for a gap.
static func _ids(board: Array) -> String:
	var out: PackedStringArray = []
	for spec: Variant in board:
		if spec is Dictionary:
			var entry: Dictionary = spec
			out.append(str(entry.get("def_id", "?")))
		else:
			out.append("-")
	return ";".join(out)


## The placer's switches on the same fight: rule before, rule aiming every aimer, rule that also
## reads Whirligig; then Hard's search on the rule before and on the rule now.
func _variants(
	problem: BoardSearch.Problem,
	me: PlayerState,
	brain: BotBrain,
	rules: RecruitRules,
	pinned: Array[int],
	base: int
) -> String:
	if brain == null:
		return "-1,-1,-1,-1,-1"
	var out: PackedStringArray = []
	var settings: Array = [[false, false], [true, false], [true, true]]
	for setting: Array in settings:
		BotPlacer.test_aim_all = setting[0]
		BotPlacer.test_reads_swap = setting[1]
		var layout: Array[int] = BotPlacer.rule_layout(me, brain.value, pinned)
		out.append("%.4f" % _score(problem, layout, base, EVAL_SEEDS).x)
	for setting: Array in [settings[0], settings[2]]:
		BotPlacer.test_aim_all = setting[0]
		BotPlacer.test_reads_swap = setting[1]
		var layout: Array[int] = BotPlacer.rule_layout(me, brain.value, pinned)
		if BotPlacer.worth_searching(me):
			var keep: int = me.bot_rng.state
			layout = BotPlacer._searched(
				me, rules, layout, brain.value, brain.level.search_budget, pinned
			)
			me.bot_rng.state = keep
		out.append("%.4f" % _score(problem, layout, base, EVAL_SEEDS).x)
	BotPlacer.test_aim_all = true
	BotPlacer.test_reads_swap = true
	return ",".join(out)


## A big search against another living player's board, not the real opponent's: what a good
## layout is worth with no knowledge of who you meet. -1 if nobody else is left.
func _generic(
	problem: BoardSearch.Problem,
	me: PlayerState,
	them: PlayerState,
	rules: RecruitRules,
	rng: RandomNumberGenerator,
	base: int
) -> float:
	var players: Array = _session.get("_players")
	var others: Array[PlayerState] = []
	for value: Variant in players:
		var someone: PlayerState = value
		if someone != me and someone != them and someone.health > 0 and someone.board_count() > 0:
			others.append(someone)
	if others.is_empty():
		return -1.0
	var other: PlayerState = others[rng.randi_range(0, others.size() - 1)]
	var stand_in := BoardSearch.Problem.new()
	stand_in.board = problem.board
	stand_in.slots = problem.slots
	stand_in.hero_effects = problem.hero_effects
	stand_in.tier = problem.tier
	stand_in.enemy = other.combat_board()
	stand_in.enemy_slots = other.combat_slots()
	stand_in.enemy_hero_effects = HeroRules.effects_of(other.hero)
	stand_in.enemy_tier = other.tier
	stand_in.side_rules = [problem.side_rules[0], rules.fight_rules(other)]
	stand_in.pinned = BotPlacer.pinned_slots(me)
	stand_in.library = _library
	stand_in.config = _config
	var found: Array[int] = BoardSearch.best_layout(stand_in, rng, ORACLE_BUDGET)
	return _score(problem, found, base, EVAL_SEEDS).x


## Of the units the scout showed, the share that stand in the same slot in the real fight, by card;
## -1 with no scout.
static func _scout_same(me: PlayerState, real: Array) -> float:
	if me.scout.is_empty():
		return -1.0
	var seen: Array = me.scout["specs"]
	var shown: int = 0
	var same: int = 0
	for slot: int in BoardGeometry.SLOTS:
		if slot < seen.size() and seen[slot] is Dictionary:
			var was: Dictionary = seen[slot]
			shown += 1
			if real[slot] is Dictionary:
				var now: Dictionary = real[slot]
				if str(now.get("def_id", "")) == str(was.get("def_id", "")):
					same += 1
	return -1.0 if shown == 0 else float(same) / shown
