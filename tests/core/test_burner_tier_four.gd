extends GutTest
@warning_ignore_start("unsafe_call_argument")
var _library: UnitLibrary = UnitLibrary.load_dir()


func test_burner_is_available_at_tier_four_with_tier_four_supply() -> void:
	var config: GameConfig = GameConfig.full_game()
	var card: Dictionary = _library.get_unit("charcoal_burner")
	assert_eq(card["tier"], 4)
	assert_eq([card["attack"], card["health"]], [4, 6])
	var cards: Array[Dictionary] = [card]
	var pool: UnitPool = UnitPool.from_cards(cards, config, "pool_copies_by_tier", [])
	assert_eq(pool.copies_left("charcoal_burner"), 13)
	assert_eq(pool.eligible_copies(3), 0)
	assert_eq(pool.eligible_copies(4), 13)
	var rng := RandomNumberGenerator.new()
	rng.seed = 73200
	assert_eq(pool.draw(4, rng), "charcoal_burner")


func test_burner_still_needs_funded_real_recipients() -> void:
	var player := PlayerState.new()
	var burner := RecruitUnit.make(_library.get_unit("charcoal_burner"), 900)
	player.gold = 14
	assert_eq(BotBurner.purchase_value(burner, player, 3), 0.0)
	for slot: int in [4, 5]:
		player.board[slot] = RecruitUnit.make(_library.get_unit("field_vole"), slot)
	assert_eq(BotBurner.purchase_value(burner, player, 3), 12.0)
	player.gold = 5
	assert_eq(BotBurner.purchase_value(burner, player, 3), 0.0)
