extends GutTest
## The flow's content comes from the core's ContentSet: the tribe folders under src/content, the
## stand-in cards only when there is none.

const TEST_CARDS: String = "res://tests/core/content/test"
const SHARED: String = "res://src/content/shared"


func test_with_no_tribe_folder_the_stand_ins_play() -> void:
	var content: GameContent = GameContent.load_folders([SHARED])
	assert_eq(content.errors, PackedStringArray(), "no load errors")
	assert_true(content.stand_ins, "stand-ins in use")
	assert_true(content.tribes.is_empty(), "no tribes to pick")
	assert_gt(content.library.pool_cards(false).size(), 10, "units to buy")
	assert_gt(content.library.pool_cards(true).size(), 0, "spells to buy")
	assert_eq(content.art_for("t1_plain"), "hedgehog-1", "stand-in art name")
	assert_eq(content.display_name("taunt"), "Guard", "names from the shared display.json")


func test_the_default_content_loads_clean() -> void:
	var content: GameContent = GameContent.load_default()
	assert_eq(content.errors, PackedStringArray(), "no load errors")
	assert_gt(content.library.pool_cards(false).size(), 10, "units to buy")
	assert_eq(content.stand_ins, content.tribes.is_empty(), "stand-ins only without tribes")


func test_with_a_tribe_folder_the_stand_in_units_are_out() -> void:
	var content: GameContent = GameContent.load_folders([SHARED, TEST_CARDS])
	assert_eq(content.errors, PackedStringArray(), "no load errors")
	assert_false(content.stand_ins, "the tribe's cards, not the stand-ins")
	assert_eq(content.tribes.size(), 1, "one tribe")
	assert_eq(str(content.tribes[0]["folder"]), "test", "found by its folder")
	assert_false(content.library.has(&"t1_plain"), "stand-in units out of the pool")
	assert_true(content.standing.has(&"test_heap_on_sale"), "the tribe's standing mechanic")
	assert_eq(content.folder_of("b2_driller"), "test", "a card knows its folder")


func test_stand_in_spells_join_only_when_no_tribe_has_one() -> void:
	var content: GameContent = GameContent.load_folders([SHARED, TEST_CARDS])
	var tribe_spells: int = 0
	var stand_in_spells: int = 0
	for card: UnitDef in content.library.pool_cards(true):
		if String(card.id) in ["sp_sharpen", "sp_seek", "sp_forage"]:
			stand_in_spells += 1
		else:
			tribe_spells += 1
	assert_gt(tribe_spells, 0, "the test content has a spell")
	assert_eq(stand_in_spells, 0, "so the stand-in spells stay out")


func test_a_session_on_tribe_content_has_the_display_table() -> void:
	var content: GameContent = GameContent.load_folders([SHARED, TEST_CARDS])
	var session: GameSession = content.new_session(3)
	assert_true(session.display.has("taunt"), "the merged display table reaches the session")
	assert_true(session.player(0).has_standing(&"test_heap_on_sale"), "standing given")


func test_a_tribe_unit_draws_its_own_art_or_its_tribe_panel() -> void:
	var content: GameContent = GameContent.load_folders([SHARED])
	content._folder_of["brood-mother"] = "locust"
	content._folder_of["no-art-yet"] = "badger"
	content._folder_of["b1_piler"] = "test"
	var own: String = content.art_for("brood-mother")
	assert_eq(own, "../../units/locust/brood-mother", "the tribe's picture")
	assert_eq(content.art_for("no-art-yet"), "../../game/stand-in/badger", "the tribe's panel")
	assert_eq(content.art_for("b1_piler"), "../../game/stand-in/neutral", "a tribe with no colour")
	for card_id: String in ["brood-mother", "no-art-yet", "b1_piler"]:
		assert_not_null(GlassPieces.art(content.art_for(card_id)), "%s draws" % card_id)


## A tribe's standing mechanics (the Compost, the Tide) belong only to games that tribe is in.
func test_a_tribes_standing_rules_only_join_its_games() -> void:
	var content: GameContent = GameContent.load_default()
	var thorn: String = content.tribe_name("thorn")
	var locust: String = content.tribe_name("locust")
	if thorn == "" or locust == "":
		pass_test("no thorn or locust folder")
		return
	var locusts: GameSession = content.new_session(3, PackedStringArray([locust]))
	assert_false(locusts.player(0).has_standing(&"thorn_compost"), "no Compost without briars")
	assert_true(locusts.player(0).has_standing(&"locust_swarm"), "the locusts' own rule")
	var everyone: GameSession = content.new_session(3)
	assert_true(everyone.player(0).has_standing(&"thorn_compost"), "all tribes: the Compost")
