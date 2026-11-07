extends SceneTree
## Controlled Whistlers cap curve on the real Combat engine. Inert Bird support and neutral
## enemies share one stat line; the live Whistlers retains its 3/3 body (golden 6/6).
## Seven Birds saturate every historical cap, so the counterfactual loss is that cap per target.
## godot --headless -s res://tools/sim/commit_whistlers_curve.gd -- 100

const CAPS: Array[int] = [0, 1, 2, 3, 6]
const ARMS: Array[Vector2i] = [Vector2i(4, 6), Vector2i(13, 13), Vector2i(12, 14)]
var _library: UnitLibrary


func _initialize() -> void:
	_library = UnitLibrary.load_dir()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var games: int = args[0].to_int() if not args.is_empty() else 100
	_register("commit_curve_bird", ["Birds"], [])
	_register("commit_curve_enemy", [], [])
	for cap: int in CAPS:
		_register("commit_curve_whistlers_%d" % cap, ["Birds"], [{"id": "whistlers", "stats": cap}])
	for stats: Vector2i in ARMS:
		for golden: bool in [false, true]:
			for cap: int in CAPS:
				print("commit_curve: %s" % JSON.stringify(_sample(stats, golden, cap, games)))
	quit(0)


func _register(id: String, tribes: Array, mechanics: Array) -> void:
	var unit_def: Dictionary = _library.get_unit("seven_whistlers").duplicate(true)
	unit_def.erase(MechanicRegistry.COMPILED_KEY)
	unit_def["id"] = id
	unit_def["tribes"] = tribes
	unit_def["mechanics"] = mechanics
	unit_def["pool"] = false
	var problem: String = _library.register_unit(unit_def)
	assert(problem == "", problem)


func _sample(stats: Vector2i, golden: bool, cap: int, games: int) -> Dictionary:
	var mine: Array = []
	var theirs: Array = []
	for slot: int in BoardGeometry.SLOTS:
		mine.append({"def_id": "commit_curve_bird", "attack": stats.x, "health": stats.y})
		theirs.append({"def_id": "commit_curve_enemy", "attack": stats.x, "health": stats.y})
	mine[6] = {"def_id": "commit_curve_whistlers_%d" % cap, "golden": golden}
	var wins: int = 0
	var draws: int = 0
	var raw: int = 0
	var realized: int = 0
	for index: int in games:
		var rng := RandomNumberGenerator.new()
		rng.seed = 71000 + index
		var combat := Combat.create(_library, GameConfig.defaults(), rng)
		var result: Dictionary = combat.run([mine, theirs], [6, 6], [0, 1], 0)
		wins += 1 if CoreUtil.to_int(result["winner"]) == 0 else 0
		draws += 1 if CoreUtil.to_int(result["winner"]) < 0 else 0
		var loss: Vector2i = _loss(result, stats)
		raw += loss.x
		realized += loss.y
	return {
		"support_and_enemy": "%d/%d" % [stats.x, stats.y],
		"golden": golden,
		"cap": cap * (2 if golden else 1),
		"games": games,
		"win_percent": 100.0 * wins / games,
		"draw_percent": 100.0 * draws / games,
		"raw_stat_loss": float(raw) / games,
		"realized_stat_loss": float(realized) / games,
	}


func _loss(result: Dictionary, stats: Vector2i) -> Vector2i:
	var source: int = 0
	var raw: int = 0
	var realized: int = 0
	var events: Array = result["events"]
	for event: Dictionary in events:
		if event["type"] == "combat_start":
			source = CoreUtil.to_int(event["boards"][0][6]["uid"])
		if event["type"] == "stats" and CoreUtil.to_int(event.get("source", -1)) == source:
			var attack: int = maxi(0, -CoreUtil.to_int(event["attack_delta"]))
			var health: int = maxi(0, -CoreUtil.to_int(event["health_delta"]))
			raw += attack + health
			realized += mini(stats.x, attack) + mini(stats.y, health)
	return Vector2i(raw, realized)
