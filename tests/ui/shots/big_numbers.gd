extends "res://tests/ui/shots/screenshot.gd"
## Phone evidence: recruit_4/5/7 or combat_4/5/7, WxH, output PNG.
## Seven-digit captures tap the second unit once to reveal its exact stats.

const BigCardView := preload("res://src/ui/widgets/card_view.gd")
const BigNumberStates := preload("res://tests/ui/big_number_states.gd")


func _run(screen_name: String, window_size: Vector2i, out_path: String) -> void:
	BigCardView.window_override = Vector2(window_size)
	var parts: PackedStringArray = screen_name.split("_")
	if parts.size() != 2 or not BigNumberStates.VALUES.has(int(parts[1])):
		printerr("big_numbers: use recruit_4/5/7 or combat_4/5/7")
		quit(2)
		return
	var digits: int = int(parts[1])
	var app := App.new()
	root.add_child(app)
	var fixture := FixturePort.new()
	app.setup(fixture)
	fixture.use_state_file("res://tests/ui/data/recruit_slice.json")
	BigNumberStates.recruit(fixture.get_state(), digits)
	if parts[0] == "recruit":
		app.show_recruit()
		if digits == 7:
			var recruit: RecruitScreen = app.current as RecruitScreen
			recruit._on_tapped("board", 1)
	else:
		var fight := CombatScreen.new()
		app.add_child(fight)
		fight.setup(
			BigNumberStates.fight(digits), PackedStringArray(["You", "Opponent"]), 0, "Round 14"
		)
		fight.playing = false
		var first: Dictionary = fight.events[0]
		fight._play_event(first, false)
		if digits == 7:
			fight._on_card_tapped("combat", 2)
	await _shoot(window_size, out_path)
