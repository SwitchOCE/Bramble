extends Control
## The game flow's plain screens with the mock-up pages' own stand-in data, for
## tools/glass/compare.py against docs/ideation-track-2/mockups/ (start.html, result.html,
## pause.html, pause.html?panel=hint).

@export_enum("start", "result", "pause", "hint") var which: String = "start"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	match which:
		"start":
			var start: StartScreen = StartScreen.new()
			start.tribes = PackedStringArray(["Badgers", "Mice", "Pigeons", "Locusts", "Briars"])
			add_child(start)
			start.toggle("Locusts")
		"result":
			var result: ResultScreen = ResultScreen.new()
			result.round_number = 14
			var order: Array[int] = [2, 4, 0, 1, 3, 5, 6, 7]
			for i: int in order.size():
				var player: Dictionary = GameFlow.PLAYERS[order[i]]
				var row: Dictionary = {
					"name": player["name"],
					"portrait": player["portrait"],
					"place": i + 1,
					"health": 12 if i == 0 else 0,
					"you": order[i] == 0,
				}
				result.standings.append(row)
			add_child(result)
		"pause", "hint":
			var stage: Control = GlassUi.stage(self)
			GlassUi.backdrop(stage)
			if which == "hint":
				GlassUi.title(stage, GameController.SKIP_HINT, 960, 1040, 22, GlassUi.MUTED)
				GlassUi.vignette(stage)
			else:
				GlassUi.vignette(stage)
				add_child(PausePanel.new())
