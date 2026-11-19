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
		if behind.is_empty() or not combat.trigger(unit, &"test_behind_buff"):
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
	registry.register(&"test_behind_buff", BehindBuff.new())
	registry.register(&"test_cheap_shop", CheapShop.new())
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
				"effects": [{"mechanic": "test_behind_buff", "attack": 3}],
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
				"effects": [{"mechanic": "test_behind_buff", "attack": 3}]
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
				"effects": [{"mechanic": "test_cheap_shop"}]
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
	assert_eq(library.drawable_cards(false).size(), 21, "21 drawable units")
	assert_eq(library.drawable_cards(true).size(), 3, "3 stand-in spells; the reward isn't offered")


func test_5_1_3_lobby_tribes_filter_draws() -> void:
	var registry: MechanicRegistry = CoreKit.registry()
	var library: UnitLibrary = UnitLibrary.with_system_cards(registry)
	(
		library
		. add_cards(
			[
				{"id": "in_tribe", "tier": 1, "attack": 1, "health": 1, "tribes": ["Alpha"]},
				{"id": "out_tribe", "tier": 1, "attack": 1, "health": 1, "tribes": ["Beta"]},
				{"id": "neutral", "tier": 1, "attack": 1, "health": 1},
				{"id": "dual", "tier": 1, "tribes": ["Beta", "Alpha"]},
				{"id": "all", "tier": 1, "tribes": ["All"]},
			],
			registry
		)
	)
	var game: GameSession = GameSession.create(1, library, registry, null, ["Alpha"])
	var eligible: Array[StringName] = [&"in_tribe", &"neutral", &"dual", &"all"]
	game.start_round()
	for player: PlayerState in game.alive_players():
		for id: StringName in player.shop_units:
			assert_has(eligible, id, "shop offers a matching tribe or neutral")
	var player: PlayerState = game.player(0)
	game.config.discover_options = 5
	game.recruit.offer_discover(player, 1, 1)
	assert_eq(player.discover_options.size(), eligible.size(), "Discover offers all eligible ids")
	for id: StringName in eligible:
		assert_has(player.discover_options, id)
	var unfiltered: GameSession = GameSession.create(1, library, registry)
	assert_gt(unfiltered.unit_odds.weight_of(&"out_tribe"), 0, "empty tribe list includes all")


func test_shop_draws_use_the_configured_weights_by_card_kind_and_tier() -> void:
	var registry: MechanicRegistry = CoreKit.registry()
	var library: UnitLibrary = UnitLibrary.with_system_cards(registry)
	var unit_weights: Array[int] = [15, 15, 13, 11, 9, 7, 5]
	var spell_weights: Array[int] = [5, 7, 9, 11, 9, 7, 0]
	var unit_tickets: Array[StringName] = []
	var spell_tickets: Array[StringName] = []
	for tier: int in range(1, 8):
		var unit_id := StringName("unit_%d" % tier)
		var spell_id := StringName("spell_%d" % tier)
		library.add_cards(
			[{"id": unit_id, "tier": tier}, {"id": spell_id, "kind": "spell", "tier": tier}],
			registry
		)
		for _ticket: int in unit_weights[tier - 1]:
			unit_tickets.append(unit_id)
		for _ticket: int in spell_weights[tier - 1]:
			spell_tickets.append(spell_id)
	var game: GameSession = GameSession.create(1, library, registry)
	var actual := Rng.new(8)
	var expected := Rng.new(8)
	for _draw: int in 100:
		assert_eq(
			game.unit_odds.draw(1, 7, actual), unit_tickets[expected.index(unit_tickets.size())]
		)
		assert_eq(
			game.spell_odds.draw(1, 7, actual), spell_tickets[expected.index(spell_tickets.size())]
		)
	assert_eq(game.spell_odds.draw(7, 7, actual), PlayerState.NO_CARD)
	assert_eq(game.spell_odds.weight_of(UnitLibrary.TRIPLE_REWARD_ID), 0)
