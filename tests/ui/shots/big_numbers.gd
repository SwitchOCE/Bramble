extends "res://tests/ui/shots/screenshot.gd"
## Reproducible phone evidence: full 4-3 boards with unabridged four/five-digit stats.

const BigCardView := preload("res://src/ui/widgets/card_view.gd")


func _run(screen_name: String, window_size: Vector2i, out_path: String) -> void:
	BigCardView.window_override = Vector2(window_size)
	var app := App.new()
	root.add_child(app)
	var fixture := FixturePort.new()
	app.setup(fixture)
	fixture.use_state_file("res://tests/ui/data/recruit_slice.json")
	var boards: Array = [[], []]
	var values: Array[int] = [1234, 5678, 9999, 10000, 23456, 88888, 99999]
	for side: int in 2:
		for slot: int in 7:
			var view: Dictionary = LaneStates.unit("field_vole", side * 100 + slot + 1)
			view["attack"] = values[slot]
			view["health"] = values[6 - slot]
			view["max_health"] = view["health"]
			var row: Array = boards[side]
			row.append(view)
	fixture.get_state()["board"] = boards[0]
	fixture.get_state()["hand"] = []
	if screen_name == "recruit":
		app.show_recruit()
	else:
		var fight := CombatScreen.new()
		app.add_child(fight)
		fight.setup(
			{
				"events":
				[{"type": "combat_start", "boards": boards, "player_ids": [0, 1], "first_side": 0}]
			},
			PackedStringArray(["You", "Opponent"]),
			0,
			"Round 14"
		)
		fight.playing = false
		var first: Dictionary = fight.events[0]
		fight._play_event(first, false)
	await _shoot(window_size, out_path)
