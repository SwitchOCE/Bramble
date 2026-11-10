extends GutTest
## Lobby tribes (rulebook 5.2.4, 5.2.7, 5.1.3).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup()
	_player = _kit.player
	_rules = _kit.rules


func _neutral_count(pool: UnitPool) -> int:
	var count: int = 0
	for id: String in pool.ids():
		if pool.tribes_of(id).is_empty():
			count += 1
	return count


func test_lobby_draws_the_config_number_of_tribes_5_2_4() -> void:
	var library := TestLibraries.current()
	var config := GameConfig.defaults()
	config.set_value("tribes_per_lobby", 2)
	var state: Dictionary = GameSession.create(3, library, config).get_state()
	assert_eq(state["lobby_tribes"].size(), 2, "the number asked")


func test_lobby_default_means_every_tribe_5_2_4() -> void:
	var state: Dictionary = (
		GameSession.create(3, TestLibraries.current(), GameConfig.defaults()).get_state()
	)
	assert_eq(state["lobby_tribes"], [], "empty: all in")


func test_pool_holds_only_lobby_tribes_and_neutrals_5_1_3_5_2_7() -> void:
	var library := TestLibraries.current()
	var rotation: PackedStringArray = library.tribes_in_rotation()
	var chosen := PackedStringArray([rotation[0]])
	var whole: UnitPool = UnitPool.create(library, _kit.config)
	var pool: UnitPool = UnitPool.create(library, _kit.config, chosen)
	assert_eq(_neutral_count(pool), _neutral_count(whole), "neutrals always in")
	for id: String in pool.ids():
		var tribes: Array = pool.tribes_of(id)
		assert_true(tribes.is_empty() or tribes.has(rotation[0]), "%s fits the lobby" % id)


func test_lobby_draw_is_seeded_5_2_4() -> void:
	var library := TestLibraries.current()
	var config := GameConfig.defaults()
	config.set_value("tribes_per_lobby", 1)
	var one: Array = GameSession.create(8, library, config).get_state()["lobby_tribes"]
	var two: Array = GameSession.create(8, library, config).get_state()["lobby_tribes"]
	assert_eq(one, two, "same seed, same tribes")


func test_thin_tribes_stay_out_of_lobbies_5_2_4() -> void:
	var library := TestLibraries.current()
	var config := GameConfig.defaults()
	config.set_value("spells_in_shop", true)
	config.set_value("hero_choice", true)
	config.set_value("tribes_per_lobby", 5)
	var wanted: int = config.get_int("lobby_tribe_min_units")
	var enough: PackedStringArray = library.tribes_in_rotation(wanted)
	assert_false(enough.has("Hive"), "one unit isn't enough")
	assert_true(library.tribes_in_rotation(1).has("Hive"), "it's only the number that keeps it out")
	for game_seed: int in range(1, 31):
		var tribes: Array = (
			GameSession.create(game_seed, library, config).get_state()["lobby_tribes"]
		)
		assert_false(tribes.has("Hive"), "seed %d" % game_seed)
		assert_eq(
			tribes.size(), mini(config.get_int("tribes_per_lobby"), enough.size()), "the number"
		)


func test_lobby_asking_for_more_than_there_are_still_leaves_thin_tribes_out_5_2_4() -> void:
	var library := TestLibraries.current()
	var config := GameConfig.defaults()
	config.set_value("tribes_per_lobby", 99)
	var tribes: Array = GameSession.create(3, library, config).get_state()["lobby_tribes"]
	assert_eq(
		tribes.size(),
		library.tribes_in_rotation(config.get_int("lobby_tribe_min_units")).size(),
		"all that qualify"
	)
	assert_false(tribes.has("Hive"), "but not the thin one")
