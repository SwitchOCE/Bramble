# gdlint:disable=max-public-methods
extends GutTest
## Revised Barn Owl: immunity is scoped to its own back-row attack, never to defending.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/combat_kit.gd")
var _library: UnitLibrary
var _combat: Combat


func before_each() -> void:
	_library = UnitLibrary.load_dir()
	_new_combat()


func _new_combat() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 83
	_combat = Combat.create(_library, GameConfig.defaults(), rng)


func _setup(ours: Dictionary, theirs: Dictionary) -> void:
	_combat._setup([KIT.board(ours), KIT.board(theirs)])
	_combat._recalc_auras(false)


func _card(id: String, mechanics: Array) -> void:
	assert_eq(
		_library.register_unit(
			{
				"id": id,
				"name": id,
				"tier": 1,
				"attack": 1,
				"health": 30,
				"tribes": [],
				"text": "test",
				"golden_text": "test",
				"mechanics": mechanics,
				"keywords": [],
				"pool": false,
				"priority": null,
				"skeleton": false,
				"row_hint": null
			}
		),
		""
	)


func test_printed_body_and_golden_keep_the_revised_text() -> void:
	_setup({0: KIT.u("barn_owl"), 1: KIT.u("barn_owl", -1, -1, true)}, {0: KIT.plain(1, 30)})
	assert_eq(_combat.unit_at(0, 0).attack, 3)
	assert_eq(_combat.unit_at(0, 0).health, 4)
	assert_eq(_combat.unit_at(0, 1).attack, 6)
	assert_eq(_combat.unit_at(0, 1).health, 8)
	var card: Dictionary = _library.get_unit("barn_owl")
	assert_eq(card["tier"], 4)
	assert_eq(card["tribes"], ["Birds"])
	assert_eq(
		card["text"], "Swoop. Never takes quarry. Takes no damage when attacking the back row."
	)
	assert_eq(card["golden_text"], card["text"])


func test_swoop_reaches_back_row_from_either_own_row() -> void:
	for slot: int in [0, 4]:
		_new_combat()
		_setup({slot: KIT.u("barn_owl")}, {0: KIT.plain(40, 40), 6: KIT.plain(40, 40)})
		var owl: CombatUnit = _combat.unit_at(0, slot)
		var back: CombatUnit = _combat.unit_at(1, 6)
		assert_eq(_combat._choose_target(owl), back)
		_combat._attack(owl, back)
		assert_eq(owl.health, 4, "a large buffed back-row carry cannot hit back")
		assert_eq(back.health, 37, "immunity does not increase its damage")


func test_bristle_cannot_damage_owl_during_back_row_attack() -> void:
	_setup({0: KIT.u("barn_owl")}, {4: KIT.u("hoglet_mother", 8, 30)})
	var owl: CombatUnit = _combat.unit_at(0, 0)
	_combat._attack(owl, _combat.unit_at(1, 4))
	assert_eq(owl.health, 4)
	assert_false(owl.damaged)
	var bristle_fired: bool = false
	for event: Dictionary in KIT.of_type({"events": _combat.events}, "damage"):
		if event["target"] == owl.uid:
			assert_eq(event["amount"], 0)
	for event: Dictionary in KIT.of_type({"events": _combat.events}, "trigger"):
		bristle_fired = bristle_fired or event["mechanic"] == "bristle"
	assert_true(bristle_fired, "Bristle fires but its damage cannot land")


func test_mire_overrides_swoop_and_bitter_still_reduces_attack() -> void:
	_setup({4: KIT.u("barn_owl")}, {4: KIT.u("madame_bufo", 12, 30), 5: KIT.plain(1, 30)})
	CombatLanes.bell(_combat)
	var owl: CombatUnit = _combat.unit_at(0, 4)
	var toad: CombatUnit = _combat.unit_at(1, 4)
	assert_true(owl.has_status("mired"))
	assert_eq(_combat._choose_target(owl), toad)
	_combat._attack(owl, toad)
	assert_eq(owl.health, 4)
	assert_eq(owl.attack, 1, "Bitter is stat loss, so immunity does not stop it")


func test_front_row_mire_forces_a_vulnerable_attack() -> void:
	_setup({0: KIT.u("barn_owl")}, {0: KIT.u("madame_bufo", 3, 30), 4: KIT.plain(40, 30)})
	CombatLanes.bell(_combat)
	var owl: CombatUnit = _combat.unit_at(0, 0)
	assert_eq(_combat._choose_target(owl), _combat.unit_at(1, 0))
	_combat._attack(owl, _combat.unit_at(1, 0))
	assert_eq(owl.health, 1)


func test_empty_back_row_removes_immunity() -> void:
	_setup({0: KIT.u("barn_owl")}, {0: KIT.plain(3, 30)})
	var owl: CombatUnit = _combat.unit_at(0, 0)
	var front: CombatUnit = _combat.unit_at(1, 0)
	assert_eq(_combat._choose_target(owl), front)
	_combat._attack(owl, front)
	assert_eq(owl.health, 1)


func test_immunity_ends_before_the_enemy_attacks_owl() -> void:
	_setup({0: KIT.u("barn_owl")}, {4: KIT.plain(3, 30)})
	var owl: CombatUnit = _combat.unit_at(0, 0)
	var enemy: CombatUnit = _combat.unit_at(1, 4)
	_combat._attack(owl, enemy)
	assert_eq(owl.health, 4)
	assert_false(owl.counters.has("attacking_back_row"))
	_combat._attack(enemy, owl)
	assert_eq(owl.health, 1)


func test_prevented_damage_preserves_shell_and_never_fires_damage_hooks() -> void:
	_setup({0: KIT.u("barn_owl")}, {4: KIT.u("bitter_toad", 8, 30)})
	var owl: CombatUnit = _combat.unit_at(0, 0)
	owl.add_grant({"entry": {"id": "shell", "n": 4}, "golden": false})
	_combat._attack(owl, _combat.unit_at(1, 4))
	assert_eq(owl.health, 4)
	assert_true(owl.has_status("shell"), "zero damage cannot break a Shell")
	assert_false(owl.has_status("nightshade"), "Bitter Toad dealt no damage")
	for event: Dictionary in KIT.of_type({"events": _combat.events}, "damage"):
		assert_ne(event["target"], owl.uid, "prevented damage has no damage event")


func test_immunity_still_allows_nondamage_status_from_golden_bitter_toad() -> void:
	_setup({0: KIT.u("barn_owl")}, {4: KIT.u("bitter_toad", 8, 30, true)})
	var owl: CombatUnit = _combat.unit_at(0, 0)
	_combat._attack(owl, _combat.unit_at(1, 4))
	assert_eq(owl.health, 4)
	assert_true(owl.has_status("nightshade"), "the Owl did damage, so golden Toad's text fires")


func test_quick_enemy_can_kill_the_owl_first() -> void:
	_setup({4: KIT.u("barn_owl")}, {0: KIT.u("ermine_duellist", 4, 30)})
	var owl: CombatUnit = _combat.unit_at(0, 4)
	var enemy: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(enemy, owl)
	assert_false(owl.on_board)
	assert_eq(enemy.health, 30, "Quick kills it before the return blow")


func test_snail_and_egg_decoys_both_share_random_swoop_targeting() -> void:
	_setup(
		{0: KIT.u("barn_owl")},
		{0: KIT.plain(1, 30), 4: KIT.u("garden_snail"), 5: KIT.u("nest_egg")}
	)
	var chosen: Dictionary = {}
	for fight_seed: int in range(1, 33):
		_combat.rng.seed = fight_seed
		chosen[_combat._choose_target(_combat.unit_at(0, 0)).slot] = true
	assert_eq(chosen.size(), 2)
	assert_true(chosen.has(4))
	assert_true(chosen.has(5))


func test_neither_brock_nor_laird_can_lend_quarry_to_owl() -> void:
	for lender: String in ["young_brock", "old_brock", "laird_of_sett"]:
		_new_combat()
		_setup(
			{0: KIT.u("barn_owl"), 1: KIT.u(lender)},
			{0: KIT.plain(1, 30), 1: KIT.plain(1, 30), 6: KIT.plain(1, 30)}
		)
		CombatLanes.bell(_combat)
		var owl: CombatUnit = _combat.unit_at(0, 0)
		assert_eq(owl.quarry, 0, lender)
		assert_false(owl.quarry_reach, lender)
		assert_eq(_combat._choose_target(owl), _combat.unit_at(1, 6), lender)
		assert_eq(owl.attack, 4 if lender == "old_brock" else 3, "only Brock's live aura remains")


func test_no_quarry_also_refuses_granted_own_quarry_text() -> void:
	_setup({0: KIT.u("barn_owl")}, {0: KIT.plain(1, 30)})
	var owl: CombatUnit = _combat.unit_at(0, 0)
	owl.add_grant({"entry": {"id": "quarry", "reach": true}, "golden": false})
	CombatLanes.bell(_combat)
	assert_eq(owl.quarry, 0)


func test_mag_pye_steals_immunity_and_refusal_before_quarry_binds() -> void:
	_setup(
		{0: KIT.u("barn_owl", 3, 30), 1: KIT.u("young_brock"), 4: KIT.plain(20, 30)},
		{0: KIT.u("mag_pye", 4, 30), 1: KIT.u("young_brock"), 4: KIT.plain(20, 30)}
	)
	_combat._start_of_combat()
	var owl: CombatUnit = _combat.unit_at(0, 0)
	var thief: CombatUnit = _combat.unit_at(1, 0)
	assert_false(owl.has_mechanic("back_row_immunity"))
	assert_true(thief.has_mechanic("back_row_immunity"))
	assert_eq(owl.quarry, _combat.unit_at(1, 1).uid, "textless Owl accepts Brock's loan")
	assert_eq(thief.quarry, 0, "stolen refusal prevents a loan")
	_combat._attack(thief, _combat.unit_at(0, 4))
	assert_eq(thief.health, 30)
	_combat._attack(owl, _combat.unit_at(1, 4))
	assert_eq(owl.health, 10)


func test_defensive_declaration_effects_are_damage_and_are_prevented() -> void:
	_card("owl_ends", [{"id": "both_ends", "attack": 0, "health": 0, "prick": 12}])
	_setup({0: KIT.u("barn_owl")}, {4: KIT.u("owl_ends"), 6: KIT.u("owl_ends")})
	var owl: CombatUnit = _combat.unit_at(0, 0)
	_combat._attack(owl, _combat.unit_at(1, 4))
	assert_eq(owl.health, 4)
	assert_false(owl.damaged)


func test_dame_hoolet_can_send_back_row_owl_before_front_row() -> void:
	_combat.side_rules = [{"back_row_first": true}, {}]
	_setup({0: KIT.plain(1, 30), 4: KIT.u("barn_owl")}, {0: KIT.plain(1, 30), 4: KIT.plain(1, 30)})
	assert_eq(_combat._choose_attacker(0, []), _combat.unit_at(0, 4))
