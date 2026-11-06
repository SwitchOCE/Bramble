extends SceneTree
## The position test: does placement matter? One Balanced bot (player 0) in a lobby of the seven
## default bots, in full games at fixed seeds; only its placement differs between arms. See
## docs/ideation/evidence/position-test.md.
##
## Usage: godot --headless -s res://tools/sim/position_tournament.gd -- key=value ...
##   pool=a|b                a = today's pool; b = the 12 position units in, filler reduced
##   arm=shuffled|heuristic|search|scout|oracle
##   games=100 first_seed=1 budget=200 out=<prefix>
##   rules=a,b               rule flags (Combat.RULE_*), comma separated
##   probe=true              heuristic games, plus same-board layout probes before each fight
## Writes <prefix>.games.csv and <prefix>.fights.csv (and <prefix>.probes.csv with probe=true).

const FILLER_CUT: PackedStringArray = [
	"field_vole",
	"marsh_frog",
	"pixie_scout",
	"hedge_sprite",
	"moss_ooze",
	"bramble_ooze",
	"brownie_porter",
	"carrion_crow",
	"common_toad",
	"buzzard",
	"crested_newt",
	"moth_fairy",
	"great_ooze",
	"old_badger",
	"fairy_monarch",
	"old_crane",
]
const MAX_TURNS: int = 60
const PROBE_RANDOM_LAYOUTS: int = 10
const PROBE_FIGHTS_EACH: int = 10
const PROBE_LAYOUT_FIGHTS: int = 60

var _options: Dictionary = {
	"pool": "a",
	"arm": "heuristic",
	"games": "10",
	"first_seed": "1",
	"budget": "200",
	"out": "user://position",
	"rules": "",
	"probe": "false",
	"exclude_more": "",
}
var _library: UnitLibrary
var _config: GameConfig
var _session: GameSession
var _game_seed: int = 0
var _games_file: FileAccess
var _fights_file: FileAccess
var _probes_file: FileAccess
var _probe_rng := RandomNumberGenerator.new()
var _position_ids: Dictionary = {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() != 2 or not _options.has(parts[0]):
			printerr("position_tournament: bad option %s" % arg)
			quit(2)
			return
		_options[parts[0]] = parts[1]
	var on_pool_b: bool = _opt("pool") == "b"
	_library = UnitLibrary.load_dir(UnitLibrary.DEFAULT_DIR, "position_test" if on_pool_b else "")
	for unit: Dictionary in _library.all_units():
		var source: Dictionary = unit["source"]
		if source.has("experiment"):
			_position_ids[str(unit["id"])] = true
	_open_files()
	var first: int = _opt("first_seed").to_int()
	var started: int = Time.get_ticks_msec()
	var games: int = _opt("games").to_int()
	for game_seed: int in range(first, first + games):
		_play(game_seed)
	print(
		(
			"position_tournament: %s %s %d games in %.1f s"
			% [_opt("pool"), _opt("arm"), games, (Time.get_ticks_msec() - started) / 1000.0]
		)
	)
	quit(0)


func _opt(key: String) -> String:
	return str(_options[key])


func _open_files() -> void:
	var prefix: String = _opt("out")
	_games_file = FileAccess.open(prefix + ".games.csv", FileAccess.WRITE)
	_games_file.store_line(
		"pool,arm,rules,seed,place,rounds,final_units,final_position_units,final_tier,final_health"
	)
	_fights_file = FileAccess.open(prefix + ".fights.csv", FileAccess.WRITE)
	_fights_file.store_line(
		"pool,arm,rules,seed,round,units,position_units,opp_units,result,damage,reason"
	)
	if _opt("probe") == "true":
		_probes_file = FileAccess.open(prefix + ".probes.csv", FileAccess.WRITE)
		_probes_file.store_line(
			(
				"pool,rules,seed,round,units,position_units,opp_units,stat_edge,random_mean,"
				+ "random_best,random_worst,heuristic,search_stale,search_scout,search_real"
			)
		)


func _make_config() -> GameConfig:
	var config := GameConfig.defaults()
	config.set_value("human_bot", Bot.BALANCED)
	config.set_value("human_search_budget", _opt("budget").to_int())
	var arm: String = _opt("arm")
	config.set_value("human_placement", Bot.PLACE_HEURISTIC if _opt("probe") == "true" else arm)
	var excluded: Array = []
	if _opt("pool") == "b":
		excluded.append_array(Array(FILLER_CUT))
	for id: String in _opt("exclude_more").split(",", false):
		excluded.append(id)
	config.set_value("pool_exclude", excluded)
	config.set_value("combat_rules", Array(_opt("rules").split(",", false)))
	return config


func _play(game_seed: int) -> void:
	_game_seed = game_seed
	_config = _make_config()
	_session = GameSession.create(game_seed, _library, _config)
	_session.fight_observer = _on_fight
	if _probes_file != null:
		_session.pre_fight_observer = _on_before_fights
	var focus: PlayerState = _session._players[GameSession.HUMAN_ID]
	var turns: int = 0
	while focus.alive and not _session.is_over() and turns < MAX_TURNS:
		_session.end_turn()
		turns += 1
	(
		_games_file
		. store_line(
			(
				"%s,%s,%s,%d,%d,%d,%d,%d,%d,%d"
				% [
					_opt("pool"),
					_opt("arm"),
					_opt("rules").replace(",", "+"),
					game_seed,
					focus.placement,
					turns,
					focus.board_count(),
					_position_count(focus.board),
					focus.tier,
					focus.health,
				]
			)
		)
	)


func _position_count(board: Array) -> int:
	var count: int = 0
	for entry: Variant in board:
		if entry == null:
			continue
		if entry is RecruitUnit:
			var unit: RecruitUnit = entry
			count += 1 if _position_ids.has(unit.def_id()) else 0
		else:
			var spec: Dictionary = entry
			count += 1 if _position_ids.has(str(spec["def_id"])) else 0
	return count


func _on_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	if id_a != GameSession.HUMAN_ID and id_b != GameSession.HUMAN_ID:
		return
	var focus_side: int = 0 if id_a == GameSession.HUMAN_ID else 1
	var other: int = id_b if focus_side == 0 else id_a
	var focus: PlayerState = _session._players[GameSession.HUMAN_ID]
	var opp_units: int = 0
	if other != Matchmaking.GHOST:
		var opponent: PlayerState = _session._players[other]
		opp_units = opponent.board_count()
	var winner: int = result["winner"]
	var word: String = "tie"
	if winner >= 0:
		word = "win" if winner == focus_side else "loss"
	var damage: int = result["damage"]
	(
		_fights_file
		. store_line(
			(
				"%s,%s,%s,%d,%d,%d,%d,%d,%s,%d,%s"
				% [
					_opt("pool"),
					_opt("arm"),
					_opt("rules").replace(",", "+"),
					_game_seed,
					round_number,
					focus.board_count(),
					_position_count(focus.board),
					opp_units,
					word,
					damage,
					str(result["reason"]),
				]
			)
		)
	)


## Same board, same real opponent: what is each way of arranging it worth in fight score?
func _on_before_fights(round_number: int) -> void:
	var focus: PlayerState = _session._players[GameSession.HUMAN_ID]
	if focus.next_opponent == Matchmaking.GHOST or focus.board_count() == 0:
		return
	var opponent: PlayerState = _session._players[focus.next_opponent]
	var real: Array = opponent.combat_board()
	var mine: Array = focus.combat_board()
	_probe_rng.seed = ("%d|%d" % [_game_seed, round_number]).hash()
	var occupied: Array[int] = focus.occupied_slots()
	var total: float = 0.0
	var best: float = -999.0
	var worst: float = 999.0
	for index: int in PROBE_RANDOM_LAYOUTS:
		var layout: Array[int] = BoardSearch.random_layout(occupied, _probe_rng)
		var value: float = _value(mine, layout, real, PROBE_FIGHTS_EACH)
		total += value
		best = maxf(best, value)
		worst = minf(worst, value)
	var heuristic: float = _value(mine, BoardSearch.identity_layout(), real, PROBE_LAYOUT_FIGHTS)
	var budget: int = _opt("budget").to_int()
	var stale: Array[int] = BoardSearch.best_layout(
		mine, BoardSearch.opponents_for(focus, false), _library, _config, _probe_rng, budget
	)
	var scout: Array[int] = BoardSearch.identity_layout()
	if not focus.scout_report.is_empty():
		scout = BoardSearch.best_layout(
			mine, [focus.scout_report], _library, _config, _probe_rng, budget
		)
	var oracle: Array[int] = BoardSearch.best_layout(
		mine, [real], _library, _config, _probe_rng, budget
	)
	(
		_probes_file
		. store_line(
			(
				"%s,%s,%d,%d,%d,%d,%d,%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f"
				% [
					_opt("pool"),
					_opt("rules").replace(",", "+"),
					_game_seed,
					round_number,
					focus.board_count(),
					_position_count(focus.board),
					opponent.board_count(),
					_stats(mine) - _stats(real),
					total / PROBE_RANDOM_LAYOUTS,
					best,
					worst,
					heuristic,
					_value(mine, stale, real, PROBE_LAYOUT_FIGHTS),
					_value(mine, scout, real, PROBE_LAYOUT_FIGHTS),
					_value(mine, oracle, real, PROBE_LAYOUT_FIGHTS),
				]
			)
		)
	)


## The win rate of a layout against a board, ties counting half.
func _value(mine: Array, layout: Array[int], theirs: Array, fights: int) -> float:
	var arranged: Array = BoardSearch.arranged_specs(mine, layout)
	var fight_rng := RandomNumberGenerator.new()
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	var points: float = 0.0
	for number: int in fights:
		fight_rng.seed = _probe_rng.randi()
		var combat: Combat = Combat.create(_library, _config, fight_rng)
		combat.log_events = false
		var result: Dictionary = combat.run([arranged, theirs], tiers, ids, 0)
		var winner: int = result["winner"]
		if winner == 0:
			points += 1.0
		elif winner < 0:
			points += 0.5
	return points / fights


static func _stats(board: Array) -> int:
	var total: int = 0
	for entry: Variant in board:
		if entry != null:
			var spec: Dictionary = entry
			var attack: int = spec["attack"]
			var health: int = spec["health"]
			total += attack + health
	return total
