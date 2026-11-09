extends SceneTree
## Repeatable Hard-policy sanity comparison; ordinary recruit actions and real combats.
## Seeds from the deleted reviewer probe were not logged; these three are explicit replacements.
## Usage: ... -s res://tools/checks/wave1_fairy_bot_probe.gd -- out=... growth=0.25 label=before

const SEEDS: Array[int] = [412, 413, 414]
const ROUTES: Array[String] = [
	"hard:birds_summer_winter",
	"hard:birds_passage",
	"hard:birds_highway",
	"hard:fairies_rings",
	"hard:fairies_rainbow",
	"hard:fairies_help",
	"hard:fairies_hag",
	"hard:birds_summer_winter"
]
const WATCH: Array[String] = ["lob_lie_by_the_fire", "hob_in_the_hearth", "cluricaun"]

var _counts: Dictionary = {}
var _rows: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _seats: Dictionary = {}
var _seed: int


func _initialize() -> void:
	var options: Dictionary = {
		"out": "/tmp/wave1-fairy-bots.json", "growth": "0.25", "label": "before", "health": "80"
	}
	for arg: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = arg.split("=", true, 1)
		if pair.size() == 2:
			options[pair[0]] = pair[1]
	var library: UnitLibrary = UnitLibrary.load_dir()
	for game_seed: int in SEEDS:
		_seed = game_seed
		_play(library, str(options["growth"]).to_float(), str(options["health"]).to_int())
	var report: Dictionary = {
		"label": options["label"],
		"seeds": SEEDS,
		"rounds": 15,
		"routes": ROUTES,
		"growth": str(options["growth"]).to_float(),
		"starting_health": str(options["health"]).to_int(),
		"tribes_per_lobby": 6,
		"counts": _counts,
		"seats": _seats,
		"fairy_seats_round12": _rows,
		"events": _events,
		"seed_provenance":
		"Replacement seeds: reviewer deleted the probe; surviving event log omits seeds/config."
	}
	var file := FileAccess.open(str(options["out"]), FileAccess.WRITE)
	if file == null:
		push_error("Cannot open probe report: " + str(options["out"]))
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print(JSON.stringify({"label": options["label"], "counts": _counts, "round12": _rows}))
	quit()


func _play(library: UnitLibrary, growth: float, health: int) -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("tribes_per_lobby", 6)
	config.set_value("starting_health", health)
	config.set_value("fairies_ring_growth", growth)
	config.set_value("human_bot", ROUTES[0])
	config.set_value("bots", ROUTES.slice(1))
	var game: GameSession = GameSession.create(_seed, library, config)
	for player: PlayerState in game._players:
		var key: String = "%d:%d" % [_seed, player.id]
		_seats[key] = {"route": ROUTES[player.id], "counts": {}}
		player.log_observer = _note.bind(player)
	game.turn_observer = _turn
	for _round: int in 15:
		if game.is_over():
			break
		game.end_turn()
	for player: PlayerState in game._players:
		player.log_observer = Callable()
	game.turn_observer = Callable()
	print("probe completed seed ", _seed)


func _turn(player: PlayerState, round_number: int, _usec: int) -> void:
	if round_number != 12 or not ROUTES[player.id].begins_with("hard:fairies"):
		return
	var board: Array[String] = []
	for unit: RecruitUnit in player.board:
		board.append(unit.def_id() if unit != null else "")
	_rows.append(
		{
			"seed": _seed,
			"seat": player.id,
			"route": ROUTES[player.id],
			"ring_size": player.ring_size,
			"ringed_slots": BotPass3.ring_count(player),
			"rings": BotPass3.ring_total(player),
			"tier": player.tier,
			"board": board
		}
	)


func _note(type: String, fields: Dictionary, player: PlayerState) -> void:
	var unit: String = str(fields.get("unit", ""))
	var key: String = ""
	if type == "walk_out":
		key = "thanks"
	elif (type == "buy" or type == "sell") and WATCH.has(unit):
		key = type + ":" + unit
	elif type == "ring_size":
		key = "ring_size_growths"
	if key.is_empty():
		return
	_counts[key] = CoreUtil.to_int(_counts.get(key, 0)) + 1
	var seat: Dictionary = _seats["%d:%d" % [_seed, player.id]]
	var counts: Dictionary = seat["counts"]
	counts[key] = CoreUtil.to_int(counts.get(key, 0)) + 1
	_events.append(
		{
			"seed": _seed,
			"seat": player.id,
			"round": player.round_number,
			"tier": player.tier,
			"type": type,
			"fields": fields.duplicate(true)
		}
	)
