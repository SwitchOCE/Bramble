extends GutTest
@warning_ignore_start("unsafe_call_argument")
var _library: UnitLibrary = UnitLibrary.load_dir()


func _unit(id: String) -> RecruitUnit:
	return RecruitUnit.make(_library.get_unit(id), 900)


func test_bot_charges_actual_half_egg_body_loss_and_text() -> void:
	var brain: BotBrain = BotBrain.from_name("hard:birds_summer_winter")
	var player := PlayerState.new()
	var bird: RecruitUnit = _unit("old_tern")
	bird.attack = 9
	bird.health = 11
	player.board[0] = bird
	var expected: float = brain.value.fly_value(bird) - 9.0 - brain.value.text_value(bird)
	assert_eq(BotHeld.trip_score(bird, player, brain.value), expected)
	var goose: RecruitUnit = _unit("mother_goose")
	player.board[0] = goose
	expected = brain.value.fly_value(goose) - (goose.attack + goose.health - 2)
	assert_eq(BotHeld.trip_score(goose, player, brain.value), expected, "Goose keeps away text")
