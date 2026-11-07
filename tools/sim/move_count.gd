extends SceneTree
## Moves bots make under the sticky-move arms (evidence/placing.md): per bot turn, units that
## stand in another slot than at the end of their last turn, counted moves and gold paid for them.
##   godot --headless -s res://tools/sim/move_count.gd -- games=20 first_seed=1 set="key:value"

const MAX_TURNS: int = 60

var _options: Dictionary = {"suite": "place_search", "games": "20", "first_seed": "1", "set": ""}
var _turns: int = 0
var _moves: int = 0
var _paid: int = 0
## Units that ended last turn in another slot, against where they end this one.
var _shifted: int = 0
var _last_slots: Dictionary = {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() == 2 and _options.has(parts[0]):
			_options[parts[0]] = parts[1]
	var library: UnitLibrary = UnitLibrary.load_dir()
	var first: int = str(_options["first_seed"]).to_int()
	for game_seed: int in range(first, first + str(_options["games"]).to_int()):
		var seats: PackedStringArray = BenchSuites.seats(str(_options["suite"]), game_seed)
		var config: GameConfig = GameConfig.full_game()
		config.set_value("human_bot", seats[0])
		config.set_value("bots", Array(seats.slice(1)))
		var problem: String = BenchSuites.apply_settings(config, str(_options["set"]))
		if problem != "":
			printerr("ERROR move_count: %s" % problem)
			quit(2)
			return
		var session: GameSession = GameSession.create(game_seed, library, config)
		session.turn_observer = _on_turn.bind(config)
		var turns: int = 0
		while not session.is_over() and turns < MAX_TURNS:
			session.end_turn()
			turns += 1
	var per: float = maxf(1.0, _turns)
	print(
		(
			"move_count: %d bot turns; a turn: %.2f units shifted, %.2f counted moves, %.3f gold"
			% [_turns, _shifted / per, _moves / per, _paid / per]
		)
	)
	quit(0)


func _on_turn(player: PlayerState, _round: int, _usec: int, config: GameConfig) -> void:
	_turns += 1
	_moves += player.counted_moves
	var key: int = player.get_instance_id()
	var before: Dictionary = _last_slots.get(key, {})
	var now: Dictionary = {}
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit != null:
			now[unit.iid] = slot
			if before.has(unit.iid) and CoreUtil.to_int(before[unit.iid]) != slot:
				_shifted += 1
	_last_slots[key] = now
	var free: int = config.get_int("free_moves_per_turn")
	if free >= 0:
		_paid += maxi(0, player.counted_moves - free) * config.get_int("move_cost")
