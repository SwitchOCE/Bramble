extends SceneTree
## Small reproducible six-tribe experiment. Run after art/UI; no balance tuning from this sample.
## godot --headless -s res://tools/sim/tribes56_probe.gd -- [games_per_tribe=9] [first_seed=56000]

const BUILDS: Dictionary = {
	"Hedgerow folk": ["hedgerow_parish", "hedgerow_treasury"],
	"Fairies": ["fairies_rings", "fairies_help", "fairies_hag"],
	"Oozes": ["oozes_second_helpings", "oozes_waste_not", "oozes_rude_awakening"],
	"Birds": ["birds_passage", "birds_highway", "birds_summer_winter"],
	"Bog folk": ["bog_bitter", "bog_tongues", "bog_borrowed"],
	"Hunters": ["hunters_open_season", "hunters_sett", "hunters_pact"],
}
var _focus: int = 0
var _tribe: String = ""
var _shops: Dictionary = {}
var _stats: Dictionary = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var games: int = 9 if args.is_empty() else args[0].to_int()
	var first: int = 56000 if args.size() < 2 else args[1].to_int()
	var library: UnitLibrary = UnitLibrary.load_dir()
	var number: int = 0
	for tribe: String in BUILDS:
		_tribe = tribe
		_stats[tribe] = {"games": 0, "wins": 0, "place_sum": 0, "final_units": 0, "on_tribe": 0}
		_shops[tribe] = {"units": 0, "on_tribe": 0, "shops": 0}
		var builds: Array = BUILDS[tribe]
		for game: int in games:
			var seed_now: int = first + number
			number += 1
			_focus = seed_now % 8
			var seats: Array[String] = []
			for _seat: int in 8:
				seats.append("normal")
			seats[_focus] = "normal:%s" % str(builds[game % builds.size()])
			var config: GameConfig = GameConfig.full_game()
			config.set_value("human_bot", seats[0])
			config.set_value("bots", seats.slice(1))
			var session: GameSession = GameSession.create(seed_now, library, config)
			session.get_rules().shop_observer = _note_shop
			for player: PlayerState in session._players:
				_note_shop(player)
			var turns: int = 0
			while not session.is_over() and turns < 60:
				session.end_turn()
				turns += 1
			if not session.is_over():
				push_error("Focus game did not finish: seed %d" % seed_now)
				quit(1)
				return
			var focus: PlayerState = session._players[_focus]
			var stats: Dictionary = _stats[tribe]
			stats["games"] += 1
			stats["wins"] += 1 if focus.placement == 1 else 0
			stats["place_sum"] += focus.placement
			var game_log: Dictionary = session.get_game_log()
			var players: Array = game_log["players"]
			for row: Dictionary in players:
				if CoreUtil.to_int(row["player_id"]) != _focus:
					continue
				var rounds: Array = row["rounds"]
				var last: Dictionary = rounds.back()
				var board: Array = last["board"]
				for value: Variant in board:
					if value == null:
						continue
					var unit: Dictionary = value
					var tribes: Array = unit["tribes"]
					stats["final_units"] += 1
					stats["on_tribe"] += 1 if tribes.has(tribe) else 0
			print(
				(
					"tribes56_game: %s"
					% JSON.stringify(
						{
							"seed": seed_now,
							"tribe": tribe,
							"seat": _focus,
							"build": str(builds[game % builds.size()]),
							"place": focus.placement,
							"rounds": turns
						}
					)
				)
			)
	for tribe: String in BUILDS:
		print(
			(
				"tribes56_result: %s"
				% JSON.stringify({"tribe": tribe, "focus": _stats[tribe], "shop": _shops[tribe]})
			)
		)
	quit(0)


func _note_shop(player: PlayerState) -> void:
	if player.id != _focus:
		return
	var counts: Dictionary = _shops[_tribe]
	counts["shops"] += 1
	for unit: RecruitUnit in player.shop:
		counts["units"] += 1
		counts["on_tribe"] += 1 if unit.has_tribe(_tribe) else 0
