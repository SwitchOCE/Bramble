extends GutTest
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")


func test_null_is_a_literal_noop_and_the_engine_never_enters_the_pool() -> void:
	var library := UnitLibrary.load_dir()
	var count: int = library.all_units().size()
	var pool_count: int = library.pool_units("slice").size()
	assert_true(PlantedEngine.install(library, 0).is_empty())
	assert_eq(library.all_units().size(), count)
	var card: Dictionary = PlantedEngine.install(library, 256)
	assert_false(CoreUtil.to_bool(card["pool"]))
	assert_eq(library.pool_units("slice").size(), pool_count)
	assert_eq(library.all_units().size(), count + 1)


func test_real_end_of_turn_effects_grow_permanently() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var card: Dictionary = PlantedEngine.install(kit.library, 128)
	var unit: RecruitUnit = kit.put(str(card["id"]), 0)
	kit.rules.end_phase(kit.player)
	assert_eq(unit.attack, 129)
	assert_eq(unit.health, 129)
	kit.rules.start_phase(kit.player, 2)
	kit.rules.end_phase(kit.player)
	assert_eq(unit.attack, 257)
	assert_eq(unit.health, 257)
