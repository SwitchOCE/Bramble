extends GutTest
## Hard reads measured route strength, while real signature cards still support their own route.
@warning_ignore_start("unsafe_call_argument")
var _library: UnitLibrary = UnitLibrary.load_dir()


func _bird(player: PlayerState, id: String, slot: int) -> void:
	player.board[slot] = RecruitUnit.make(_library.get_unit(id), slot + 1)


func test_hard_prefers_the_demonstrated_stronger_route_on_a_small_shared_start() -> void:
	var player := PlayerState.new()
	_bird(player, "one_swallow", 0)
	var brain: BotBrain = BotBrain.from_name("hard")
	var highway: Dictionary = brain.knowledge.strategy("birds_highway")
	var summer: Dictionary = brain.knowledge.strategy("birds_summer_winter")
	var passage: Dictionary = brain.knowledge.strategy("birds_passage")
	assert_gt(brain.value.strategy_fit(highway, player), brain.value.strategy_fit(summer, player))
	assert_gt(brain.value.strategy_fit(highway, player), brain.value.strategy_fit(passage, player))


func test_owned_rotation_cards_still_make_the_rotation_route_fit() -> void:
	var player := PlayerState.new()
	_bird(player, "one_swallow", 0)
	_bird(player, "chiffchaff", 1)
	_bird(player, "old_tern", 2)
	var brain: BotBrain = BotBrain.from_name("hard")
	assert_gt(
		brain.value.strategy_fit(brain.knowledge.strategy("birds_summer_winter"), player),
		brain.value.strategy_fit(brain.knowledge.strategy("birds_highway"), player)
	)


func test_normal_does_not_read_the_hard_strength_prior() -> void:
	var player := PlayerState.new()
	_bird(player, "one_swallow", 0)
	var brain: BotBrain = BotBrain.from_name("normal")
	assert_gt(
		brain.value.strategy_fit(brain.knowledge.strategy("birds_summer_winter"), player),
		brain.value.strategy_fit(brain.knowledge.strategy("birds_highway"), player)
	)


func test_bird_pins_keep_their_named_route() -> void:
	for id: String in ["birds_highway", "birds_passage", "birds_summer_winter"]:
		var brain: BotBrain = BotBrain.from_name("hard:" + id)
		brain._choose_build()
		assert_eq(brain.build_name(), id)
