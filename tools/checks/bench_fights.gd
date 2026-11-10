extends SceneTree
## Fight benchmark: random legal boards from the unit library, the same every run, fought in pure
## Combat with no recruit or bot time. Prints ms per fight and a hash of the event logs, so a
## refactor can prove it changed no fight.
## Usage: godot --headless -s res://tools/checks/bench_fights.gd -- [fights=4000] [seed=1]

const BOARD_MIN: int = 3
## Fields added to views later must not change the hash, so the start event's boards are skipped.
const HASH_SKIP: PackedStringArray = ["combat_start", "summon"]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var fights: int = 4000 if args.size() < 1 else args[0].to_int()
	var first_seed: int = 1 if args.size() < 2 else args[1].to_int()
	var library: UnitLibrary = UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	var units: Array[Dictionary] = _pool_units(library, config)
	if units.is_empty():
		printerr("bench: empty full-game unit pool; no fights started")
		quit(1)
		return
	var pairs: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = first_seed
	for _index: int in fights:
		pairs.append([_board(units, rng), _board(units, rng)])
	var total_events: int = 0
	var tiers: Array[int] = [3, 3]
	var ids: Array[int] = [0, 1]
	var started: int = Time.get_ticks_usec()
	for index: int in fights:
		var pair: Array = pairs[index]
		total_events += _fight(library, config, pair, index, tiers, ids).size()
	var elapsed: int = Time.get_ticks_usec() - started
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_MD5)
	for index: int in fights:
		var pair: Array = pairs[index]
		for event: Dictionary in _fight(library, config, pair, index, tiers, ids):
			if not HASH_SKIP.has(str(event["type"])):
				digest.update(str(event).to_utf8_buffer())
	print(
		(
			"bench: %d fights, %.3f ms per fight, %.1f events per fight, log hash %s"
			% [
				fights,
				elapsed / 1000.0 / maxi(1, fights),
				float(total_events) / maxi(1, fights),
				digest.finish().hex_encode(),
			]
		)
	)
	quit(0)


static func _pool_units(library: UnitLibrary, config: GameConfig) -> Array[Dictionary]:
	return library.pool_units(config.card_set())


static func _fight(
	library: UnitLibrary,
	config: GameConfig,
	pair: Array,
	index: int,
	tiers: Array[int],
	ids: Array[int]
) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = index + 1
	var result: Dictionary = Combat.create(library, config, rng).run(pair, tiers, ids, 0)
	var events: Array[Dictionary] = result["events"]
	return events


static func _board(units: Array[Dictionary], rng: RandomNumberGenerator) -> Array:
	var board: Array = []
	board.resize(BoardGeometry.SLOTS)
	var count: int = rng.randi_range(BOARD_MIN, BoardGeometry.SLOTS)
	var slots: Array[int] = [0, 1, 2, 3, 4, 5, 6]
	for index: int in count:
		var pick: int = rng.randi_range(index, slots.size() - 1)
		var slot: int = slots[pick]
		slots[pick] = slots[index]
		var unit: Dictionary = units[rng.randi_range(0, units.size() - 1)]
		board[slot] = {"def_id": unit["id"], "golden": rng.randf() < 0.1}
	return board
