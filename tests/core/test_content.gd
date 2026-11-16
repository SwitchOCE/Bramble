extends GutTest
## The one game set-up (ContentSet): every content folder loads clean, ids are namespaced and
## never replace each other, standing mechanics and the display table reach the session.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")


func test_every_tribe_and_the_test_cards_load_with_no_errors() -> void:
	var all: ContentSet = CoreKit.content([])
	assert_eq(all.errors, PackedStringArray(), "every folder under src/content plus the test cards")
	assert_true(all.folders.has("shared"))
	assert_true(all.folders.has("test"))


func test_mechanic_ids_carry_the_folder_prefix() -> void:
	var made: ContentSet = CoreKit.content()
	assert_true(made.registry.has(&"test_pile_on"))
	assert_false(made.registry.has(&"pile_on"), "a tribe's file name alone is never an id")
	assert_true(made.registry.has(&"taunt"), "shared keywords have no prefix")


func test_a_duplicate_id_is_refused_and_reported() -> void:
	var registry: MechanicRegistry = MechanicRegistry.with_built_ins()
	var first: Mechanic = registry.get_mechanic(&"taunt")
	assert_false(registry.register(&"taunt", Mechanic.new()))
	assert_same(registry.get_mechanic(&"taunt"), first, "the first registration stays")
	assert_eq(registry.errors.size(), 1)
	var twice: ContentSet = ContentSet.load_folders(
		[CoreKit.NEUTRAL, CoreKit.TEST_CARDS, CoreKit.TEST_CARDS]
	)
	assert_true(
		Array(twice.errors).any(func(e: String) -> bool: return e.contains("registered twice")),
		"loading a folder twice is loud: %s" % [twice.errors]
	)


func test_standing_mechanics_reach_every_player() -> void:
	var game: GameSession = CoreKit.bridge_session(3)
	for each: PlayerState in game.players:
		assert_true(each.has_standing(&"test_heap_on_sale"), "player %d" % each.id)
	var plain: GameSession = CoreKit.content(["none"], false).session(3)
	assert_false(plain.player(0).has_standing(&"test_heap_on_sale"))


func test_the_display_table_reaches_the_view() -> void:
	var game: GameSession = CoreKit.bridge_session(4)
	game.start_round()
	var display: Dictionary = game.view_for(0)["display"]
	assert_eq(str(display["taunt"]["name"]), "Taunt", "shared keyword")
	assert_eq(str(display["test_medal"]["name"]), "Medal", "tribe counter")
	assert_true(bool(display["test_tide_rider"]["hidden"]), "helper mechanic stays hidden")


func test_only_the_named_tribes_are_loaded() -> void:
	var none: PackedStringArray = ContentSet.folders_in(ContentSet.ROOT, ["none"])
	assert_eq(none.size(), 1)
	assert_true(none[0].ends_with("/shared"), "shared is always loaded")
