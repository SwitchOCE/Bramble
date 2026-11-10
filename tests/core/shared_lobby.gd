extends RefCounted
## Test-only: one real Hard lobby (`GameConfig.full_game()`, 8 Hard seats of varied builds, seed 5)
## played once a run and shared by every test that only needs a finished game to read (test-suite
## plan step 4, 5b). Callers get deep copies of what was recorded, never the session, so no test
## can change what another sees. Hard plays it with its real search budget.
## Readers: test_balance_2 (damage bound), test_full_games (pool conservation, places),
## test_bot_brain (Hard plays a whole game to the end).

const SEED: int = 5
const MAX_TURNS: int = 60
## Hard with a 4-fight board search (Hard's is BotLevel.HARD_SEARCH_BUDGET, 20): the same policy
## at a fraction of the cost, for tests that need real opponents but don't test Hard's choices.
const QUICK_HARD: String = "hard:varied@search=4"

static var _played: Dictionary = {}


## {"config", "game_log", "standings", "builds", "turns", "over", "end_turn_errors",
## "pool_start", "pool_by_turn"}: copies of one finished lobby.
static func hard() -> Dictionary:
	if _played.is_empty():
		_played = _play()
	return _played.duplicate(true)


## Seven QUICK_HARD seats, for a config's "bots".
static func quick_seats() -> Array:
	var out: Array = []
	for _seat: int in BotLobby.SEATS:
		out.append(QUICK_HARD)
	return out


static func config() -> GameConfig:
	var out: GameConfig = GameConfig.full_game()
	out.set_value("bots", BotLobby.seats(BotLevel.HARD))
	out.set_value("human_bot", "hard:varied")
	return out


static func _play() -> Dictionary:
	var game_config: GameConfig = config()
	var session := GameSession.create(SEED, TestLibraries.current(), game_config)
	var errors: Array = []
	var pool_by_turn: Array = []
	var pool_start: int = copies_accounted(session)
	var turns: int = 0
	while not session.is_over() and turns < MAX_TURNS:
		var error: String = session.end_turn()
		if error != "":
			errors.append("turn %d: %s" % [turns, error])
		turns += 1
		pool_by_turn.append(copies_accounted(session))
	var builds: Array = []
	for seat: int in game_config.get_int("players"):
		builds.append(session.build_of(seat))
	return {
		"config": game_config._values.duplicate(true),
		"game_log": session.get_game_log(),
		"standings": session.get_standings(),
		"builds": builds,
		"turns": turns,
		"over": session.is_over(),
		"end_turn_errors": errors,
		"pool_start": pool_start,
		"pool_by_turn": pool_by_turn,
	}


## Copies in the pool plus every copy a player holds in shop, hand, board, bellies, away, on the
## doorstep or poached (rulebook 5.3; PlayerState.all_units).
static func copies_accounted(session: GameSession) -> int:
	var total: int = session._pool.total_copies()
	for player: PlayerState in session._players:
		for unit: RecruitUnit in player.all_units():
			total += unit.pool_copies
		for unit: RecruitUnit in player.shop:
			total += unit.pool_copies
	return total
