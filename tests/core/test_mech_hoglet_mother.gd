extends GutTest
## Hoglet Mother (library entry 7): Bristle, and a death summon into its own slot (rulebook
## 8.4.1) that joins the attack order by 9.4.8.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/combat_kit.gd")


func test_bristle_pricks_after_the_exchange_before_deaths() -> void:
	var mine: Array = Kit.board({1: Kit.u("hoglet_mother")})
	var theirs: Array = Kit.board({0: Kit.plain(5, 5), 1: Kit.plain(0, 9)})
	var result: Dictionary = Kit.run(mine, theirs, 3)
	var first_attack: Dictionary = Kit.of_type(result, "attack")[0]
	assert_eq(first_attack["attacker"], 2, "the 5/5 attacks first (more units)")
	var at: int = Kit.index_of(result, "attack")
	assert_eq(
		Kit.types_from(result, at, 6),
		["attack", "damage", "damage", "trigger", "damage", "death"],
		"exchange, Bristle, thorns, then the death"
	)
	var thorns: Dictionary = Kit.events(result)[at + 4]
	assert_eq([thorns["kind"], thorns["amount"], thorns["target"]], ["thorns", 1, 2], "1 thorn")


func test_thorns_never_trigger_thorns() -> void:
	var mine: Array = Kit.board({0: Kit.u("hoglet_mother", 1, 20)})
	var theirs: Array = Kit.board({0: Kit.u("hoglet_mother", 1, 20)})
	var result: Dictionary = Kit.run(mine, theirs)
	var at: int = Kit.index_of(result, "attack")
	assert_eq(
		Kit.types_from(result, at, 7),
		["attack", "damage", "damage", "trigger", "damage", "trigger", "damage"],
		"each pricks the other once, and the pricks don't prick back"
	)
	assert_eq(Kit.events(result)[at + 7]["type"], "attack", "then the next attack")


func test_golden_bristle_doubles_7_3_5() -> void:
	var mine: Array = Kit.board({0: Kit.u("hoglet_mother", 0, 20, true)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 20)})
	var result: Dictionary = Kit.run(mine, theirs)
	for hit: Dictionary in Kit.of_type(result, "damage"):
		if hit["kind"] == "thorns":
			assert_eq(hit["amount"], 2, "Bristle 2")
			return
	fail_test("no thorns")


func test_death_summons_a_hoglet_into_its_slot_8_4_1() -> void:
	var mine: Array = Kit.board({2: Kit.u("hoglet_mother")})
	var theirs: Array = Kit.board({0: Kit.plain(5, 50), 1: Kit.plain(0, 50)})
	var result: Dictionary = Kit.run(mine, theirs)
	var summons: Array[Dictionary] = Kit.of_type(result, "summon")
	assert_eq(summons.size(), 1, "one Hoglet")
	var summon: Dictionary = summons[0]
	var unit: Dictionary = summon["unit"]
	assert_eq([summon["slot"], summon["side"], summon["source"]], [2, 0, 1], "its own slot")
	assert_eq([unit["def_id"], unit["attack"], unit["health"]], ["hoglet", 1, 1], "a 1/1 Hoglet")
	var at: int = Kit.index_of(result, "death")
	assert_eq(Kit.types_from(result, at, 3), ["death", "trigger", "summon"], "death, then summon")


func test_golden_mother_summons_a_golden_hoglet() -> void:
	var mine: Array = Kit.board({0: Kit.u("hoglet_mother", -1, -1, true)})
	var theirs: Array = Kit.board({0: Kit.plain(9, 50), 1: Kit.plain(0, 50)})
	var result: Dictionary = Kit.run(mine, theirs)
	var unit: Dictionary = Kit.of_type(result, "summon")[0]["unit"]
	assert_eq([unit["golden"], unit["attack"], unit["health"]], [true, 2, 2], "golden 2/2")


func test_full_board_loses_the_summon_8_4_5() -> void:
	var mine: Array = Kit.board({})
	var combat := Combat.create(Kit.library, GameConfig.defaults(), RandomNumberGenerator.new())
	var full: Dictionary = {}
	for slot: int in 7:
		full[slot] = Kit.plain(1, 1)
	combat._setup([Kit.board(full), mine])
	assert_null(combat.summon("hoglet", false, 0, 3, null), "no empty slot")


func test_summon_flags_by_pointer_9_4_8() -> void:
	var combat := Combat.create(Kit.library, GameConfig.defaults(), RandomNumberGenerator.new())
	combat._setup([Kit.board({}), Kit.board({})])
	combat.pointers[0] = 2
	assert_true(combat.summon("hoglet", false, 0, 0, null).flagged, "j < P waits")
	assert_false(combat.summon("hoglet", false, 0, 2, null).flagged, "j = P attacks next")
	assert_false(combat.summon("hoglet", false, 0, 3, null).flagged, "j > P in order")


func test_dead_attackers_hoglet_attacks_next_9_4_8() -> void:
	var mine: Array = Kit.board({0: Kit.u("hoglet_mother", 1, 1), 1: Kit.plain(1, 50)})
	var theirs: Array = Kit.board({0: Kit.plain(1, 50)})
	for fight_seed: int in 30:
		var result: Dictionary = Kit.run(mine, theirs, fight_seed)
		var attacks: Array[Dictionary] = Kit.of_type(result, "attack")
		if attacks[1]["defender"] != 2:
			continue
		var hoglet: int = Kit.of_type(result, "summon")[0]["unit"]["uid"]
		assert_eq(attacks[0]["attacker"], 1, "Hoglet Mother attacks and dies on the return blow")
		assert_eq(attacks[2]["attacker"], hoglet, "its Hoglet (F1, j = P) attacks before F2")
		return
	fail_test("no seed where the enemy hit F2")


func test_reproduces_the_combat_fixture_5() -> void:
	var path: String = "res://docs/prototype/fixtures/combat_nightshade.json"
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var mine: Array = Kit.board({1: Kit.u("hoglet_mother"), 5: Kit.u("belladonna_sprite")})
	var theirs: Array = Kit.board({1: Kit.u("stoat_captain"), 2: Kit.u("field_vole")})
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var tiers: Array[int] = [6, 4]
	var ids: Array[int] = [0, 3]
	var result: Dictionary = Combat.create(Kit.library, GameConfig.defaults(), rng).run(
		[mine, theirs], tiers, ids, 10
	)
	var got: Array = JSON.parse_string(_without_keyword_text(JSON.stringify(result["events"])))
	var expected: Array = JSON.parse_string(
		_without_keyword_text(JSON.stringify(fixture["events"]))
	)
	assert_eq(got, expected, "seed 6 plays the fixture's fight event for event")


static func _without_keyword_text(json: String) -> String:
	var pattern := RegEx.new()
	pattern.compile(',?"keyword_text":\\[(\\{[^\\]]*\\})?\\]')
	return pattern.sub(json, "", true)
