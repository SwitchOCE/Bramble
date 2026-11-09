extends GutTest
## The shared pool (rulebook 5.1, 5.3) and shop draws (6.1.3-6.1.4).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()


func test_copies_by_tier_5_1_2() -> void:
	var pool: UnitPool = UnitPool.create(_library, GameConfig.defaults())
	assert_eq(pool.copies_left("dewdrop_ooze"), 15, "tier 1")
	assert_eq(pool.copies_left("hoglet_mother"), 15, "tier 2")
	assert_eq(pool.copies_left("wood_mouse_guard"), 13, "tier 3")
	assert_eq(pool.copies_left("stoat_captain"), 11, "tier 4")
	assert_eq(pool.copies_left("great_ooze"), 9, "tier 5")
	var slice_config := GameConfig.defaults()
	slice_config.set_value("pool_filter", "slice")
	var slice_pool := UnitPool.create(_library, slice_config)
	assert_eq(slice_pool.copies_left("fairy_monarch"), 7, "tier 6")
	assert_eq(pool.copies_left("old_crane"), 0, "retired prototype")
	assert_false(pool.has_unit("hoglet"), "tokens are never in the pool (5.3.6)")


func test_draws_only_at_or_below_tier_6_1_3() -> void:
	var pool: UnitPool = UnitPool.create(_library, GameConfig.defaults())
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for _draw: int in 60:
		var id: String = pool.draw(1, rng)
		var tier: int = _library.get_unit(id)["tier"]
		assert_eq(tier, 1, "%s is tier 1" % id)


func test_drawn_copy_leaves_the_pool_6_1_3() -> void:
	var pool: UnitPool = UnitPool.create(_library, GameConfig.defaults())
	var before: int = pool.total_copies()
	var rng := RandomNumberGenerator.new()
	var id: String = pool.draw(6, rng)
	assert_eq(pool.total_copies(), before - 1, "one copy left the pool")
	pool.give_back(id)
	assert_eq(pool.total_copies(), before, "and came back (5.3.2)")


func test_empty_pool_draws_nothing_6_1_4() -> void:
	var config := GameConfig.defaults()
	config.set_value("pool_filter", "skeleton")
	var pool: UnitPool = UnitPool.create(_library, config)
	var rng := RandomNumberGenerator.new()
	for _draw: int in 15:
		assert_eq(pool.draw(1, rng), "dewdrop_ooze", "the skeleton pool's only tier-1 unit")
	assert_eq(pool.draw(1, rng), "", "no copies left: the slot stays empty")


func test_skeleton_filter_10() -> void:
	var config := GameConfig.defaults()
	config.set_value("pool_filter", "skeleton")
	var pool: UnitPool = UnitPool.create(_library, config)
	assert_eq(
		pool.total_copies(),
		15 + 13 + 11,
		"remaining prototype skeleton cards; the Bird and Fairy bodies retired"
	)


func test_give_back_ignores_units_the_pool_never_held_5_3_6() -> void:
	var pool: UnitPool = UnitPool.create(_library, GameConfig.defaults())
	var before: int = pool.total_copies()
	pool.give_back("hoglet", 1)
	assert_eq(pool.total_copies(), before, "Created units never return")
