extends GutTest
## The hook interface tribe mechanics will plug into: a mechanic written outside the core is
## registered, named in card data, type-checked when loaded and run by the engine.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")


## A stand-in for a future tribe mechanic: Start of Combat, give the units behind this +N Attack.
class BehindBuff:
	extends Mechanic

	func param_kinds() -> Dictionary:
		return {"attack": MechanicParams.Kind.NUMBER}

	func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
		var behind: Array[CombatUnit] = combat.select(unit, "behind")
		if behind.is_empty() or not combat.trigger(unit, &"behind_buff"):
			return
		for friend: CombatUnit in behind:
			combat.buff(friend, params.num(&"attack"), 0, unit)


## A player-level rule from a unit: while on the board, refreshes cost 1 less.
class CheapShop:
	extends Mechanic

	func modify_int(
		query: StringName, value: int, _player: PlayerState, _unit: Unit, _params: MechanicParams
	) -> int:
		return value - 1 if query == Rules.REFRESH_COST else value


func _game_with(cards: Array) -> GameSession:
	var registry: MechanicRegistry = CoreKit.registry()
	registry.register(&"behind_buff", BehindBuff.new())
	registry.register(&"cheap_shop", CheapShop.new())
	var library: UnitLibrary = CoreKit.library(registry)
	library.add_cards(cards, registry)
	assert_eq(library.errors, PackedStringArray(), "library loads")
	return GameSession.create(2, library, registry)


func test_a_registered_mechanic_runs_from_card_data() -> void:
	var game: GameSession = _game_with(
		[
			{
				"id": "x_captain",
				"tier": 2,
				"attack": 2,
				"health": 4,
				"effects": [{"mechanic": "behind_buff", "attack": 3}],
			}
		]
	)
	var a: Array[Unit] = CoreKit.board(game, {1: "x_captain", 4: "t1_plain", 5: "t1_plain"})
	var combat: Combat = CoreKit.fight(game, a, CoreKit.board(game, {0: "t1_plain"}))
	var buffed: Array[int] = []
	for event: Dictionary in CoreKit.events_of(combat, "buff"):
		buffed.append(event["slot"])
		assert_eq(event["attack"], 5)
	assert_eq(buffed, [4, 5] as Array[int], "8.2.1 F2 has B1 and B2 behind it")


func test_golden_copy_doubles_a_plugged_in_number() -> void:
	var game: GameSession = _game_with(
		[
			{
				"id": "x_captain",
				"tier": 2,
				"attack": 2,
				"health": 4,
				"effects": [{"mechanic": "behind_buff", "attack": 3}]
			}
		]
	)
	var golden: Unit = CoreKit.unit(game, "x_captain", true)
	assert_eq(golden.mechanics[0].params.num(&"attack"), 6)


func test_unit_text_changes_a_player_rule_while_on_the_board() -> void:
	var game: GameSession = _game_with(
		[
			{
				"id": "x_broker",
				"tier": 1,
				"attack": 2,
				"health": 2,
				"effects": [{"mechanic": "cheap_shop"}]
			}
		]
	)
	game.start_round()
	var p: PlayerState = game.player(0)
	assert_eq(game.rules.refresh_cost(p), 1)
	CoreKit.put(game, p, "x_broker", 0)
	assert_eq(game.rules.refresh_cost(p), 0)


func test_library_rejects_unknown_mechanics_and_bad_params() -> void:
	var registry: MechanicRegistry = CoreKit.registry()
	var library: UnitLibrary = UnitLibrary.with_system_cards(registry)
	(
		library
		. add_cards(
			[
				{"id": "bad_a", "tier": 1, "attack": 1, "health": 1, "keywords": ["flying"]},
				{
					"id": "bad_b",
					"tier": 1,
					"attack": 1,
					"health": 1,
					"effects": [{"mechanic": "play_buff", "attack": 2, "to": "adjacent"}]
				},
				{
					"id": "bad_c",
					"tier": 1,
					"attack": 1,
					"health": 1,
					"effects": [{"mechanic": "rally_gain", "attack": "lots"}]
				},
				{
					"id": "bad_d",
					"tier": 1,
					"attack": 1,
					"health": 1,
					"effects": [{"mechanic": "rally_gain", "attack": 1, "extra": 2}]
				},
			],
			registry
		)
	)
	assert_eq(library.errors.size(), 4, str(library.errors))
	assert_false(library.has(&"bad_a"))
	assert_false(library.has(&"bad_b"), "missing parameter")
	assert_false(library.has(&"bad_c"), "wrong type")
	assert_false(library.has(&"bad_d"), "unknown parameter")


func test_test_library_loads_clean() -> void:
	var registry: MechanicRegistry = CoreKit.registry()
	var library: UnitLibrary = CoreKit.library(registry)
	assert_eq(library.errors, PackedStringArray())
	assert_eq(library.pool_cards(false).size(), 21, "21 pool units")
	assert_eq(library.pool_cards(true).size(), 3, "3 stand-in spells; the reward isn't offered")


func test_5_1_3_lobby_tribes_filter_the_pool() -> void:
	var registry: MechanicRegistry = CoreKit.registry()
	var library: UnitLibrary = UnitLibrary.with_system_cards(registry)
	(
		library
		. add_cards(
			[
				{"id": "in_tribe", "tier": 1, "attack": 1, "health": 1, "tribes": ["Alpha"]},
				{"id": "out_tribe", "tier": 1, "attack": 1, "health": 1, "tribes": ["Beta"]},
				{"id": "neutral", "tier": 1, "attack": 1, "health": 1},
			],
			registry
		)
	)
	var game: GameSession = GameSession.create(1, library, registry, null, ["Alpha"])
	assert_true(game.units.has_card(&"in_tribe"))
	assert_false(game.units.has_card(&"out_tribe"))
	assert_true(game.units.has_card(&"neutral"), "5.2.7 neutral units are always in")
	assert_eq(game.units.copies_left(&"neutral"), 15, "5.1.2 15 copies at tier 1")
