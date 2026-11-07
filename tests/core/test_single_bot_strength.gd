extends GutTest
@warning_ignore_start("unsafe_call_argument")


func test_player_game_seats_only_todays_best_bot() -> void:
	var config: GameConfig = GameConfig.full_game()
	var seats: PackedStringArray = config.get_strings("bots")
	assert_eq(seats.size(), 7)
	for seat: String in seats:
		assert_true(seat.begins_with(BotLevel.HARD), "the player gets today's Hard policy")
		assert_false(seat.begins_with(BotLevel.NAIVE), "Naive belongs only in tools")
