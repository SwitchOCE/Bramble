extends GutTest
## The one game set-up (ContentSet): every content folder loads clean, ids are namespaced and
## never replace each other, standing mechanics and the display table reach the session.

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")
## Content folders that are wrong on purpose, one fault each (tests/core/content/fixtures/;
## never loaded by the game or the soak).
const FIXTURES: String = "res://tests/core/content/fixtures"


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
	assert_eq(str(display["taunt"]["name"]), "Guard", "shared keyword, SHARED-RULES name")
	assert_eq(str(display["test_medal"]["name"]), "Medal", "tribe counter")
	assert_true(bool(display["test_tide_rider"]["hidden"]), "helper mechanic stays hidden")


func test_only_the_named_tribes_are_loaded() -> void:
	var none: PackedStringArray = ContentSet.folders_in(ContentSet.ROOT, ["none"])
	assert_eq(none.size(), 1)
	assert_true(none[0].ends_with("/shared"), "shared is always loaded")


func _errors_loading(folder: String) -> String:
	var made: ContentSet = ContentSet.load_folders([CoreKit.TEST_CARDS, FIXTURES + "/" + folder])
	return "\n".join(made.errors)


func test_c18_a_folder_with_no_prefix_is_refused_unless_it_is_shared() -> void:
	assert_string_contains(_errors_loading("no_prefix"), "has no prefix")
	assert_eq(CoreKit.content(["none"], false, false).errors, PackedStringArray(), "shared is fine")


func test_c18_two_folders_may_not_share_a_prefix() -> void:
	assert_string_contains(_errors_loading("same_prefix"), "prefix test_ is already used")


func test_c18_a_helper_in_mechanics_is_refused_with_where_helpers_go() -> void:
	assert_string_contains(_errors_loading("helper"), "put helper code in lib/")


func test_c18_two_tribes_declaring_one_class_name_are_reported() -> void:
	var clashes: PackedStringArray = ContentSet.class_name_clashes(
		{"a/x.gd": "extends Mechanic\nclass_name Fury\n", "b/y.gd": "class_name Fury\n"}
	)
	assert_eq(clashes.size(), 1)
	assert_string_contains(clashes[0], "class_name Fury is declared twice")


func test_c20_a_mechanic_with_no_display_entry_is_reported() -> void:
	assert_string_contains(_errors_loading("no_display"), "mechanic nodisp_plain has no display")


func test_c20_a_display_id_without_the_prefix_is_reported() -> void:
	assert_string_contains(_errors_loading("stray_display"), "display id other lacks the prefix")


func test_c19_a_name_without_a_prefix_is_reported_where_the_core_sees_it() -> void:
	var registry: MechanicRegistry = CoreKit.content().registry
	registry.loud = false
	registry.check_name(&"test_medal", "unit counter")
	registry.check_name(&"core_anything", "state")
	assert_eq(registry.errors.size(), 0)
	registry.check_name(&"medal", "unit counter")
	assert_eq(registry.errors.size(), 1)
	assert_string_contains(registry.errors[0], "'medal' has no content prefix")


func test_c21_every_tribe_loads_alone_and_plays_a_round() -> void:
	var all: ContentSet = CoreKit.all_tribes()
	assert_eq(all.errors, PackedStringArray(), "the shipped set alone")
	var game: GameSession = all.session(5)
	game.start_round()
	game.finish_round()
	assert_eq(game.round_number, 1)


func test_c22_one_shared_display_id_for_a_slot_buff() -> void:
	var made: ContentSet = CoreKit.content()
	assert_eq(str(made.display["slot_buff"]["name"]), "Slot buff")
