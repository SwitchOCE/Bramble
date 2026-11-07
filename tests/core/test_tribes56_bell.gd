# gdlint:disable=max-public-methods
extends GutTest
## Binding calls in design-review-3: one snapshot, slots versus identities, live Take witnesses.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/combat_kit.gd")
var _library: UnitLibrary
var _combat: Combat


func before_each() -> void:
	_library = UnitLibrary.load_dir()
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	_combat = Combat.create(_library, GameConfig.defaults(), rng)
	_card("toad", [{"id": "mire", "spread": false}])
	_card("hunter", [{"id": "quarry", "reach": false}], ["Hunters"])
	_card(
		"lender",
		[
			{
				"id": "lend_quarry",
				"select": "adjacent",
				"reach": true,
				"attack": 1,
				"own_across": false
			}
		],
		["Hunters"]
	)


func _card(id: String, mechanics: Array, tribes: Array = []) -> void:
	assert_eq(
		_library.register_unit(
			{
				"id": id,
				"name": id,
				"tier": 1,
				"attack": 2,
				"health": 5,
				"tribes": tribes,
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


func _setup(ours: Dictionary, theirs: Dictionary) -> void:
	_combat._setup([KIT.board(ours), KIT.board(theirs)])
	_combat._recalc_auras(false)


func _bell() -> void:
	CombatLanes.bell(_combat)


func test_bell_runs_after_mag_pye_and_before_other_start_text() -> void:
	for fight_seed: int in range(1, 9):
		_combat.rng.seed = fight_seed
		var result: Dictionary = _combat.run(
			[KIT.board({0: KIT.u("mag_pye")}), KIT.board({0: KIT.u("toad")})], [1, 1], [0, 1], 0
		)
		var stolen: int = KIT.index_of(result, "text_taken")
		var patch: int = KIT.index_of(result, "bog_patch")
		assert_gt(patch, stolen, "the stolen Mire lays the patch")
		assert_eq(KIT.of_type(result, "bog_patch")[0]["side"], 1)
		# Combat is one-shot; use a fresh instance each seed.
		var rng := RandomNumberGenerator.new()
		rng.seed = fight_seed
		_combat = Combat.create(_library, GameConfig.defaults(), rng)


func test_quarry_fixed_before_row_swap_and_patch_stays_on_ground() -> void:
	_setup({0: KIT.u("toad"), 4: KIT.u("hunter")}, {0: KIT.plain(4, 5), 4: KIT.plain(8, 9)})
	_bell()
	var front: CombatUnit = _combat.unit_at(1, 0)
	var back: CombatUnit = _combat.unit_at(1, 4)
	var hunter: CombatUnit = _combat.unit_at(0, 4)
	assert_eq(hunter.quarry, back.uid)
	CombatMoves.swap_rows(_combat, 1)
	assert_eq(hunter.quarry, back.uid, "the mark follows the animal")
	assert_false(front.has_status("mired"), "moving off the mud frees it")
	assert_true(back.has_status("mired"), "the new occupant is Mired")
	assert_eq(CombatLanes.lock_target(_combat, back), _combat.unit_at(0, 0))


func test_empty_slot_waits_for_a_summon_but_is_never_quarry() -> void:
	_setup({0: KIT.u("toad"), 1: KIT.u("hunter")}, {2: KIT.plain(1, 5)})
	_bell()
	assert_eq(_combat.unit_at(0, 1).quarry, 0)
	var arrival: CombatUnit = _combat.summon_into("field_vole", false, 1, 0, null)
	assert_true(arrival.has_status("mired"))
	_combat.summon_into("field_vole", false, 1, 1, null)
	assert_eq(_combat.unit_at(0, 1).quarry, 0, "no refill farm")


func test_first_patch_in_reading_order_wins_overlap() -> void:
	_card("diva", [{"id": "mire", "spread": true}])
	_setup({0: KIT.u("toad"), 1: KIT.u("diva")}, {0: KIT.plain(1, 5), 1: KIT.plain(1, 5)})
	_bell()
	assert_eq(CombatLanes.maker_of(_combat, _combat.unit_at(1, 0)), _combat.unit_at(0, 0))
	assert_eq(CombatLanes.maker_of(_combat, _combat.unit_at(1, 1)), _combat.unit_at(0, 1))
	assert_eq(_combat.bog_patches[1].size(), 3)


func test_chorus_lends_mire_before_reading_order_claims() -> void:
	_card("chorus", [{"id": "bog_aura", "mire": true, "bitter": 1}])
	_setup({0: KIT.plain(1, 8), 1: KIT.u("chorus"), 2: KIT.plain(1, 8)}, {0: KIT.plain(1, 5)})
	_bell()
	assert_eq(_combat.bog_patches[1].size(), 2)
	assert_eq(CombatLanes.maker_of(_combat, _combat.unit_at(1, 0)), _combat.unit_at(0, 0))


func test_own_quarry_beats_lent_quarry_and_lenders_use_reading_order() -> void:
	_setup(
		{0: KIT.u("lender"), 1: KIT.u("hunter"), 2: KIT.u("lender"), 3: KIT.plain(1, 3)},
		{0: KIT.plain(1, 5), 1: KIT.plain(1, 5), 2: KIT.plain(1, 5)}
	)
	_bell()
	assert_eq(_combat.unit_at(0, 1).quarry, _combat.unit_at(1, 1).uid)
	assert_false(_combat.unit_at(0, 1).quarry_reach, "the losing loan gives no reach")
	assert_eq(_combat.unit_at(0, 3).quarry, _combat.unit_at(1, 2).uid)
	assert_true(_combat.unit_at(0, 3).quarry_reach)
	assert_eq(_combat.unit_at(0, 3).attack, 2, "loan buff after bindings")


func test_mire_overrides_quarry_and_swoop_even_into_back_row() -> void:
	_card("swooping_hunter", [{"id": "quarry", "reach": true}, {"id": "swoop"}], ["Hunters"])
	_setup(
		{4: KIT.u("toad"), 0: KIT.plain(1, 9)}, {4: KIT.u("swooping_hunter"), 5: KIT.plain(1, 9)}
	)
	_bell()
	var attacker: CombatUnit = _combat.unit_at(1, 4)
	attacker.quarry = _combat.unit_at(0, 0).uid
	assert_eq(_combat._choose_target(attacker), _combat.unit_at(0, 4))


func test_protected_quarry_waits_but_reach_ignores_rows() -> void:
	_setup({4: KIT.u("hunter")}, {0: KIT.plain(1, 9), 4: KIT.plain(1, 9)})
	_bell()
	var hunter: CombatUnit = _combat.unit_at(0, 4)
	assert_eq(_combat._choose_target(hunter), _combat.unit_at(1, 0))
	hunter.quarry_reach = true
	assert_eq(_combat._choose_target(hunter), _combat.unit_at(1, 4))


func test_eggs_are_not_quarry() -> void:
	_setup({0: KIT.u("hunter")}, {0: KIT.u("nest_egg")})
	_bell()
	assert_eq(_combat.unit_at(0, 0).quarry, 0)


func test_maker_death_ends_lock_but_not_mired_condition() -> void:
	_setup({0: KIT.u("toad")}, {0: KIT.plain(1, 9)})
	_bell()
	var enemy: CombatUnit = _combat.unit_at(1, 0)
	_combat.unit_at(0, 0).take_damage(99)
	_combat._resolve_deaths(0)
	assert_null(CombatLanes.lock_target(_combat, enemy))
	assert_true(enemy.has_status("mired"))


func test_side_change_breaks_patch_lock_permanently() -> void:
	_setup({0: KIT.u("toad")}, {0: KIT.plain(1, 9)})
	_bell()
	var maker: CombatUnit = _combat.unit_at(0, 0)
	var enemy: CombatUnit = _combat.unit_at(1, 0)
	CombatMoves.trade_sides(_combat, maker, enemy)
	CombatMoves.trade_sides(_combat, maker, enemy)
	assert_null(CombatLanes.lock_target(_combat, enemy), "coming home doesn't remake the lock")
	assert_true(enemy.has_status("mired"))


func test_swallow_permanently_clears_quarry_without_take() -> void:
	_setup({0: KIT.u("hunter")}, {0: KIT.plain(1, 9), 1: KIT.u("hasty_pudding")})
	_bell()
	var quarry: CombatUnit = _combat.unit_at(1, 0)
	CombatHeld.swallow(_combat, _combat.unit_at(1, 1), quarry)
	CombatHeld.return_inside(_combat, _combat.unit_at(1, 1))
	assert_eq(_combat.unit_at(0, 0).quarry, 0)
	assert_eq(_combat.takes, [0, 0])


func test_side_change_clears_both_incoming_and_outgoing_marks() -> void:
	_setup({0: KIT.u("hunter")}, {0: KIT.u("hunter")})
	_bell()
	CombatMoves.trade_sides(_combat, _combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_combat.unit_at(0, 0).quarry, 0)
	assert_eq(_combat.unit_at(1, 0).quarry, 0)


func test_simultaneous_death_is_a_take_but_an_earlier_dead_hunter_claims_nothing() -> void:
	_setup({0: KIT.u("hunter"), 1: KIT.u("hunter")}, {0: KIT.plain(1, 9), 1: KIT.plain(1, 9)})
	_bell()
	_combat.unit_at(0, 0).take_damage(99)
	_combat.unit_at(1, 0).take_damage(99)
	_combat._resolve_deaths(0)
	assert_eq(_combat.takes, [1, 0], "they go down together")
	_combat.unit_at(0, 1).take_damage(99)
	_combat._resolve_deaths(0)
	_combat.unit_at(1, 1).take_damage(99)
	_combat._resolve_deaths(1)
	assert_eq(_combat.takes, [1, 0], "gone Hunters make no more Takes")


func test_shared_quarry_credits_one_hunter_in_reading_order() -> void:
	_setup({0: KIT.u("hunter"), 1: KIT.u("lender"), 2: KIT.u("hunter")}, {1: KIT.plain(1, 9)})
	_bell()
	_combat.unit_at(1, 1).take_damage(99)
	_combat._resolve_deaths(1)
	var takes: Array[Dictionary] = KIT.of_type({"events": _combat.events}, "take")
	assert_eq(takes.size(), 1)
	assert_eq(takes[0]["hunter"], _combat.unit_at(0, 0).uid)
	assert_eq(_combat.unit_at(0, 2).quarry, 0)


func test_non_hunter_with_lent_quarry_makes_no_take() -> void:
	_setup({0: KIT.plain(1, 3), 1: KIT.u("lender")}, {1: KIT.plain(1, 9)})
	_bell()
	_combat.unit_at(1, 1).take_damage(99)
	_combat._resolve_deaths(1)
	assert_eq(_combat.takes, [0, 0])


func test_enemy_death_filter_and_take_subject_other_are_data_effects() -> void:
	_card(
		"paid_hunter",
		[
			{"id": "quarry", "reach": false},
			{"id": "effect", "trigger": "on_take", "do": {"effect": "gold", "amount": 2}}
		],
		["Hunters"]
	)
	_card(
		"cutter",
		[
			{
				"id": "effect",
				"trigger": "on_enemy_death",
				"if": [{"kind": "subject_mired"}],
				"do": {"effect": "gold", "amount": 1}
			}
		]
	)
	_setup(
		{0: KIT.u("toad"), 1: KIT.u("paid_hunter"), 2: KIT.u("cutter")},
		{0: KIT.plain(1, 9), 1: KIT.plain(1, 9)}
	)
	_bell()
	_combat.unit_at(1, 0).take_damage(99)
	_combat.unit_at(1, 1).take_damage(99)
	_combat._resolve_deaths(1)
	var gold: int = 0
	for change: Dictionary in _combat.carry:
		gold += int(change.get("amount", 0))
	assert_eq(gold, 3, "one Mired death and the personal Take")


func test_snap_chooses_highest_mired_enemy_anywhere() -> void:
	_card("snapper", [{"id": "snap"}])
	_setup(
		{0: KIT.u("toad"), 4: KIT.u("toad"), 5: KIT.u("snapper")},
		{0: KIT.plain(2, 9), 4: KIT.plain(20, 9), 5: KIT.plain(30, 9)}
	)
	_bell()
	assert_eq(_combat._choose_target(_combat.unit_at(0, 5)), _combat.unit_at(1, 4))


func test_bitter_stacks_with_aura_floors_at_one_and_runs_before_death() -> void:
	_card("bitter_toad", [{"id": "bitter", "n": 2, "once_per_enemy": false}])
	_card("nan", [{"id": "bog_aura", "mire": false, "bitter": 1}])
	_setup({0: KIT.u("bitter_toad", 1, 1), 1: KIT.u("nan")}, {0: KIT.plain(3, 20)})
	var enemy: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(enemy, _combat.unit_at(0, 0))
	assert_eq(enemy.attack, 1)
	var all: Dictionary = {"events": _combat.events}
	assert_lt(KIT.index_of(all, "stats"), KIT.index_of(all, "death"))


func test_bitter_once_per_enemy_and_once_per_whole_peck_attack() -> void:
	_card("diva", [{"id": "bitter", "n": 3, "once_per_enemy": true}])
	_setup({0: KIT.u("diva", 1, 200)}, {0: KIT.u("drumming_woodpecker", 12, 200)})
	var enemy: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(enemy, _combat.unit_at(0, 0))
	assert_eq(enemy.attack, 9, "one Bitter, not one per strike")
	_combat._attack(enemy, _combat.unit_at(0, 0))
	assert_eq(enemy.attack, 9, "once per enemy")


func test_immediate_attacks_ignore_rows_keep_pointer_and_respect_mire() -> void:
	_setup({0: KIT.plain(2, 9), 4: KIT.u("toad")}, {4: KIT.u("lodger", 1, 9)})
	_bell()
	var enemy: CombatUnit = _combat.unit_at(1, 4)
	_combat.queue_attack(enemy, _combat.unit_at(0, 0), "pounce")
	_combat.reactions.drain(_combat)
	assert_eq(_combat.attacks_made, 0, "Mire refuses a pounce at someone else")
	_combat.queue_attack(enemy, _combat.unit_at(0, 4), "pounce")
	_combat.reactions.drain(_combat)
	assert_eq(_combat.attacks_made, 1)
	assert_eq(_combat.pointers, [-1, -1])
	assert_false(enemy.flagged)
