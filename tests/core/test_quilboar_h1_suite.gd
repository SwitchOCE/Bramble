extends GutTest
@warning_ignore_start("unsafe_call_argument")

const EXPECTED: Array[String] = [
	"line_quilboar_engine",
	"line_birds_homecoming",
	"line_fairies_ring",
	"line_bog_engine",
	"line_hedgerow_engine",
	"line_hunters_engine",
	"line_oozes_engine",
	"hard:varied"
]


func test_h1_has_one_reference_six_tribal_engines_and_one_hard_anchor() -> void:
	assert_true(BenchSuites.is_known("quilboar_h1"))
	for seed_value: int in [2910001, 2910002, 2910003, 2910004]:
		var seats: Array = Array(BenchSuites.seats("quilboar_h1", seed_value))
		seats.sort()
		var expected: Array = EXPECTED.duplicate()
		expected.sort()
		assert_eq(seats, expected)
		assert_eq(
			BenchSuites.seats("quilboar_h1", seed_value),
			BenchSuites.seats("quilboar_h1", seed_value)
		)


func test_reference_registry_selects_the_native_cycling_brain() -> void:
	var bot: Bot = BenchSuites.create_bot("line_quilboar_engine")
	assert_true(bot is BotBrain)
	assert_eq(bot.build_name(), "quilboar_choose_one")
	assert_true(BenchSuites.is_candidate("line_quilboar_engine", "quilboar_h1"))
