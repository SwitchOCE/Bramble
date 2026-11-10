extends SceneTree
## One bounded ablation of the sampled C Bog carry; no new lobbies or dial fits.

const DRIVER := preload("res://tools/sim/field_fights.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var library := UnitLibrary.load_dir()
	var rows: Array = []
	for number: String in ["12", "14"]:
		var boards: Array = data["rounds"][number]["boards"]
		var bog: Dictionary
		for board: Dictionary in boards:
			if board["line"] == "line_bog_court":
				bog = board
		var config: Dictionary = bog["config"]
		library = FightCapture.library_for(config, library)
		var opponents: int = 0
		for board: Dictionary in boards:
			if board["line"] == "line_bog_court" or opponents >= 8:
				continue
			opponents += 1
			var left: Dictionary = bog if boards.find(bog) < boards.find(board) else board
			var right: Dictionary = board if left == bog else bog
			var fight_seed: int = DRIVER.seed_for(number, str(left["id"]), str(right["id"]), 0)
			var reset: Dictionary = bog.duplicate(true)
			for raw: Variant in reset["board"]:
				if not raw is Dictionary:
					continue
				var spec: Dictionary = raw
				if spec.get("def_id") == "jenny_greenteeth":
					var card: Dictionary = library.get_unit("jenny_greenteeth")
					var factor: int = 2 if spec.get("golden", false) else 1
					spec["attack"] = CoreUtil.to_int(card["attack"]) * factor
					spec["health"] = CoreUtil.to_int(card["health"]) * factor
			var result: Dictionary = {"round": number, "opponent": board["line"]}
			for variant: String in ["native", "jenny_growth_removed"]:
				var mine: Dictionary = bog if variant == "native" else reset
				var points: float = 0.0
				for orientation: int in 2:
					var fight: Dictionary = FieldCombat.fight(
						mine if orientation == 0 else board,
						board if orientation == 0 else mine,
						fight_seed,
						library
					)
					var winner: int = CoreUtil.to_int(fight["winner"])
					points += 0.5 if winner < 0 else 1.0 if winner == orientation else 0.0
				result[variant] = points / 2.0
			rows.append(result)
	var file := FileAccess.open(args[1], FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "  ") + "\n")
	print("Bog triage: ", rows.size(), " pairs; 16 fights per round per treatment")
	quit()
