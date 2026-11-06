extends SceneTree
## Which rules text creates a placement decision? Puts each unit in each slot of sampled boards
## (the other six units and the opponent's seven drawn from nearby tiers of pool b), and splits the
## value of placing it in two:
##   fixed    = the best slot overall, against an average slot: one rule of thumb gets this.
##   adaptive = choosing the slot per board, against the best slot overall: a real decision.
## "adaptive" picks on half the fights and scores on the other half, so noise can't pass for depth.
##
## Usage: godot --headless -s res://tools/sim/position_unit_value.gd -- out.csv [boards] [fights]
##   [rules] ; fights is per slot and per half.

const Tournament := preload("res://tools/sim/position_tournament.gd")

var _library: UnitLibrary
var _config: GameConfig
var _rng := RandomNumberGenerator.new()
var _fight_rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var boards: int = 60 if args.size() < 2 else args[1].to_int()
	var fights: int = 20 if args.size() < 3 else args[2].to_int()
	_library = UnitLibrary.load_dir(UnitLibrary.DEFAULT_DIR, "position_test")
	_config = GameConfig.defaults()
	if args.size() >= 4:
		_config.set_value("combat_rules", Array(args[3].split(",", false)))
	var excluded: PackedStringArray = Tournament.FILLER_CUT
	var pool: Array[Dictionary] = []
	for unit: Dictionary in _library.pool_units():
		if not excluded.has(str(unit["id"])):
			pool.append(unit)
	var file: FileAccess = FileAccess.open(args[0], FileAccess.WRITE)
	file.store_line("unit,tier,experiment,mean,fixed,adaptive,best_slot,best_slot_share,slots")
	for unit: Dictionary in pool:
		file.store_line(_measure(unit, pool, boards, fights))
		file.flush()
	print("position_unit_value: %d units" % pool.size())
	quit(0)


func _measure(unit: Dictionary, pool: Array[Dictionary], boards: int, fights: int) -> String:
	var id: String = unit["id"]
	var tier: int = unit["tier"]
	_rng.seed = id.hash()
	var near: Array[Dictionary] = []
	for other: Dictionary in pool:
		var other_tier: int = other["tier"]
		if absi(other_tier - tier) <= 1:
			near.append(other)
	var picks: Array = []
	var scores_a: Array = []
	var scores_b: Array = []
	for board_index: int in boards:
		var row_a: Array[float] = []
		var row_b: Array[float] = []
		var others: Array = _draw(near, 6)
		var theirs: Array = _layout_of(_draw(near, 7))
		var base_seed: int = _rng.randi()
		for slot: int in BoardGeometry.SLOTS:
			var mine: Array = _with_unit(id, slot, others)
			row_a.append(_win_rate(mine, theirs, base_seed, fights))
			row_b.append(_win_rate(mine, theirs, base_seed + 100000, fights))
		scores_a.append(row_a)
		scores_b.append(row_b)
		picks.append(_argmax(row_a))
	return _row(unit, picks, scores_a, scores_b)


func _row(unit: Dictionary, picks: Array, scores_a: Array, scores_b: Array) -> String:
	var boards: int = picks.size()
	var slot_means: Array[float] = []
	for slot: int in BoardGeometry.SLOTS:
		var total: float = 0.0
		for index: int in boards:
			var row_a: Array[float] = scores_a[index]
			var row_b: Array[float] = scores_b[index]
			total += (row_a[slot] + row_b[slot]) / 2.0
		slot_means.append(total / boards)
	# The global best slot is chosen on half A too, so both gains are scored on half B alone.
	var a_means: Array[float] = []
	for slot: int in BoardGeometry.SLOTS:
		var total: float = 0.0
		for index: int in boards:
			var row_a: Array[float] = scores_a[index]
			total += row_a[slot]
		a_means.append(total / boards)
	var best: int = _argmax(a_means)
	var mean_b: float = 0.0
	var fixed_b: float = 0.0
	var adaptive_b: float = 0.0
	var same: int = 0
	for index: int in boards:
		var row_b: Array[float] = scores_b[index]
		var pick: int = picks[index]
		for slot: int in BoardGeometry.SLOTS:
			mean_b += row_b[slot] / BoardGeometry.SLOTS
		fixed_b += row_b[best]
		adaptive_b += row_b[pick]
		same += 1 if pick == best else 0
	var source: Dictionary = unit["source"]
	var cells: PackedStringArray = []
	for value: float in slot_means:
		cells.append("%.3f" % value)
	return (
		"%s,%d,%d,%.4f,%.4f,%.4f,%s,%.3f,%s"
		% [
			str(unit["id"]),
			CoreUtil.to_int(unit["tier"]),
			1 if source.has("experiment") else 0,
			mean_b / boards,
			(fixed_b - mean_b) / boards,
			(adaptive_b - fixed_b) / boards,
			BoardGeometry.LABELS[best],
			float(same) / boards,
			" ".join(cells),
		]
	)


func _draw(near: Array[Dictionary], count: int) -> Array:
	var out: Array = []
	for index: int in count:
		var unit: Dictionary = near[_rng.randi_range(0, near.size() - 1)]
		out.append({"def_id": unit["id"], "golden": false})
	return out


## Seven units with Health order standing in for a player's sensible layout: sturdiest in front.
func _layout_of(units: Array) -> Array:
	var sorted: Array = units.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _health(a) > _health(b))
	return sorted


func _health(spec: Dictionary) -> int:
	var unit: Dictionary = _library.get_unit(str(spec["def_id"]))
	var health: int = unit["health"]
	return health


## The six others keep their sturdiest-first order around the unit's slot.
func _with_unit(id: String, slot: int, others: Array) -> Array:
	var sorted: Array = _layout_of(others)
	var out: Array = []
	var next: int = 0
	for index: int in BoardGeometry.SLOTS:
		if index == slot:
			out.append({"def_id": id, "golden": false})
		else:
			out.append(sorted[next])
			next += 1
	return out


func _win_rate(mine: Array, theirs: Array, base_seed: int, fights: int) -> float:
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	var points: float = 0.0
	for number: int in fights:
		_fight_rng.seed = base_seed + number
		var combat: Combat = Combat.create(_library, _config, _fight_rng)
		combat.log_events = false
		var result: Dictionary = combat.run([mine, theirs], tiers, ids, 0)
		var winner: int = result["winner"]
		points += 1.0 if winner == 0 else (0.5 if winner < 0 else 0.0)
	return points / fights


static func _argmax(values: Array[float]) -> int:
	var best: int = 0
	for index: int in values.size():
		if values[index] > values[best]:
			best = index
	return best
