# gdlint:disable=max-public-methods
extends GutTest
## Real Bog cards exercise proportional bites, owner state and completed-attack rewards.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const CK := preload("res://tests/core/combat_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup()
	kit.config.set_value("pass3_content", true)
	kit.config.set_value("pass3_preset", "B")
	kit.config.set_value("pass3_loop_guards", true)


func _fight(mine: Dictionary, theirs: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var combat := Combat.create(kit.library, kit.config, rng)
	combat._setup([KIT._board(mine), KIT._board(theirs)])
	combat._recalc_auras(false)
	Pass3BogCombat.prepare(combat)
	combat._start_of_combat()
	return combat


func _owned(id: String, attack: int, health: int, golden: bool = false) -> Dictionary:
	var spec: Dictionary = CK.u(id, attack, health, golden)
	spec["iid"] = 99
	return spec


func _events(combat: Combat, kind: String) -> Array[Dictionary]:
	return CK.of_type({"events": combat.events}, kind)


func test_bridge_keeps_actual_quarter_bites_in_next_turn_queue_without_healing() -> void:
	var combat: Combat = _fight({0: _owned("bridge_toad", 0, 100)}, {0: CK.plain(9, 100)})
	var toad: CombatUnit = combat.unit_at(0, 0)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	combat._attack(enemy, toad)
	assert_eq(enemy.attack, 6, "ceil(9 / 4) is removed before damage")
	assert_eq([toad.pending_attack, toad.pending_health], [6, 6], "B keep is two")
	assert_eq(toad.health, 94, "pending Soak does not heal the fighter")
	assert_eq([toad.perm_attack, toad.combat_attack], [-1, 0])
	combat._attack(enemy, toad)
	assert_eq(enemy.attack, 4)
	assert_eq(toad.pending_attack, 10)
	assert_eq(combat.notes["bog_toll"][0], 5, "raw Toll excludes the keep multiplier")


func test_golden_keep_does_not_increase_bitter_and_never_raises_zero_attack() -> void:
	var combat: Combat = _fight({0: _owned("bridge_toad", 0, 100, true)}, {0: CK.plain(9, 100)})
	var toad: CombatUnit = combat.unit_at(0, 0)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	CombatLanes.bitter(combat, toad, enemy)
	assert_eq([enemy.attack, toad.pending_attack], [6, 12])
	enemy.combat_attack -= 6
	CombatLanes.bitter(combat, toad, enemy)
	assert_eq(enemy.attack, 0)
	enemy.combat_attack += 1
	CombatLanes.bitter(combat, toad, enemy)
	assert_eq(enemy.attack, 1, "Bitter leaves one Attack")
	assert_eq(toad.pending_attack, 12)


func test_free_bitter_adds_toll_but_soak_only_keeps_its_own_patch() -> void:
	var combat: Combat = _fight(
		{0: _owned("bridge_toad", 0, 100), 2: "warty_nan"},
		{0: CK.plain(8, 100), 1: CK.plain(8, 100)}
	)
	var toad: CombatUnit = combat.unit_at(0, 0)
	var free: CombatUnit = combat.unit_at(1, 1)
	CombatLanes.bitter(combat, toad, free)
	assert_eq(toad.pending_attack, 0)
	CombatLanes.bitter(combat, combat.unit_at(0, 2), free)
	assert_eq(combat.notes["bog_toll"][0], 4)
	kit.config.set_value("bog_soak_mired_only", false)
	CombatLanes.bitter(combat, toad, free)
	assert_eq(toad.pending_attack, 2, "free-bite keep is an explicit sweep dial")


func test_chorus_lends_only_bog_mire_and_strongest_soak_without_stacking_bitter() -> void:
	var combat: Combat = _fight(
		{
			0: _owned("bridge_toad", 0, 100),
			1: CK.u("natterjack_chorus", -1, -1, true),
			2: CK.plain(0, 100)
		},
		{0: CK.plain(8, 100), 2: CK.plain(8, 100)}
	)
	var toad: CombatUnit = combat.unit_at(0, 0)
	assert_eq(Pass3BogCombat.soak_keep(combat, toad), 4.0)
	assert_null(CombatLanes.maker_of(combat, combat.unit_at(1, 2)), "non-Bog gets no loan")
	CombatLanes.bitter(combat, toad, combat.unit_at(1, 0))
	assert_eq(combat.unit_at(1, 0).attack, 6, "own/lent Bitter is one quarter")
	assert_eq(toad.pending_attack, 8, "own/lent Soak keeps only the stronger rate")


func test_chorus_enables_nan_but_loan_dial_can_remove_it() -> void:
	var combat: Combat = _fight(
		{0: _owned("warty_nan", 0, 100), 1: "natterjack_chorus"}, {0: CK.plain(8, 100)}
	)
	var nan: CombatUnit = combat.unit_at(0, 0)
	assert_eq(CombatLanes.maker_of(combat, combat.unit_at(1, 0)), nan)
	CombatLanes.bitter(combat, nan, combat.unit_at(1, 0))
	assert_eq(nan.pending_attack, 4)
	kit.config.set_value("bog_chorus_lends", 0)
	assert_eq(Pass3BogCombat.soak_keep(combat, nan), 0.0)


func test_prima_donna_claims_three_slots_and_takes_each_bite() -> void:
	var combat: Combat = _fight(
		{5: _owned("prima_donna", 0, 100)},
		{4: CK.plain(8, 100), 5: CK.plain(8, 100), 6: CK.plain(8, 100)}
	)
	var diva: CombatUnit = combat.unit_at(0, 5)
	for slot: int in [4, 5, 6]:
		assert_eq(CombatLanes.maker_of(combat, combat.unit_at(1, slot)), diva)
		CombatLanes.bitter(combat, diva, combat.unit_at(1, slot))
	assert_eq(diva.pending_attack, 12)
	assert_eq(combat.notes["bog_toll"][0], 6)


func test_gideon_hit_back_is_one_way_and_soak_stays_pending() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight({0: _owned("gideon", 2, 100, golden)}, {0: CK.plain(8, 100)})
		var gideon: CombatUnit = combat.unit_at(0, 0)
		var enemy: CombatUnit = combat.unit_at(1, 0)
		combat._attack(enemy, gideon)
		assert_eq(gideon.health, 94, "no retaliation to the hit back")
		assert_eq(enemy.health, 94 if golden else 96)
		assert_eq(_events(combat, "bog_hit_back").size(), 2 if golden else 1)
		assert_eq(gideon.pending_attack, 8 if golden else 4)


func test_reciprocal_gideons_do_not_counter_chain_even_with_rate_guards_disabled() -> void:
	kit.config.set_value("pass3_loop_guards", false)
	var combat: Combat = _fight({0: CK.u("gideon", 4, 100)}, {0: CK.u("gideon", 4, 100)})
	combat._attack(combat.unit_at(1, 0), combat.unit_at(0, 0))
	assert_eq(_events(combat, "bog_hit_back").size(), 1)
	assert_eq(_events(combat, "immediate_attack").size(), 0, "hit backs are damage, not attacks")


func test_bufo_halves_only_her_own_surviving_mired_killer() -> void:
	for golden: bool in [false, true]:
		var combat: Combat = _fight({0: CK.u("madame_bufo", 0, 1, golden)}, {0: CK.plain(20, 100)})
		var enemy: CombatUnit = combat.unit_at(1, 0)
		combat._attack(enemy, combat.unit_at(0, 0))
		assert_eq(enemy.attack, 3 if golden else 7)
	var other: Combat = _fight({0: "madame_bufo"}, {0: CK.plain(20, 100), 1: CK.plain(20, 100)})
	var free: CombatUnit = other.unit_at(1, 1)
	other.deal_effect_damage(free, other.unit_at(0, 0), 99)
	other._resolve_deaths(0)
	assert_eq(free.attack, 20, "other killers are not halved")


func test_hopkin_borrows_each_back_row_attack_and_pays_bitter_on_borrowed_attack() -> void:
	var combat: Combat = _fight(
		{0: CK.plain(80, 100), 4: CK.u("vaulting_hopkin", 3, 100)}, {4: CK.u("warty_nan", 0, 1000)}
	)
	var hopkin: CombatUnit = combat.unit_at(0, 4)
	var wall: CombatUnit = combat.unit_at(1, 4)
	combat._attack(hopkin, wall)
	assert_eq(wall.health, 985, "20 borrowed, then a quarter Bitter")
	assert_true(hopkin.can_act(), "Bitter erased his own Attack, but the front still lends Attack")
	assert_true(hopkin.can_attack())
	hopkin.flagged = false
	assert_eq(combat._choose_attacker(0, []), hopkin, "the real picker still selects him first")
	combat.unit_at(0, 0).combat_attack += 80
	combat._attack(hopkin, wall)
	assert_eq(wall.health, 955, "the next attack borrows anew: 40 minus ten")
	assert_eq(hopkin.attack, 0, "borrowed Attack does not become a permanent buff")
	assert_eq(combat._attack_order(0)[0], hopkin)
	combat.unit_at(0, 0).combat_attack -= 160
	combat._recalc_auras(true)
	assert_false(hopkin.can_act(), "zero front Attack cannot fund another borrowed attack")


func test_front_hopkin_uses_own_attack_and_golden_back_share_is_half() -> void:
	var combat: Combat = _fight(
		{
			0: CK.u("vaulting_hopkin", 3, 100),
			1: CK.plain(80, 100),
			4: CK.u("vaulting_hopkin", 6, 100, true)
		},
		{0: CK.plain(0, 1000)}
	)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	combat._attack(combat.unit_at(0, 0), enemy)
	combat._attack(combat.unit_at(0, 4), enemy)
	assert_eq(enemy.health, 957)


func test_ranocchio_grows_every_completed_mired_attack_even_in_a_trade() -> void:
	var combat: Combat = _fight(
		{0: "bridge_toad", 4: _owned("signor_ranocchio", 2, 100)}, {0: CK.plain(10, 100)}
	)
	var singer: CombatUnit = combat.unit_at(0, 4)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	combat._attack(singer, enemy)
	combat._attack(singer, enemy)
	assert_eq([singer.attack, singer.max_health], [12, 110])
	assert_eq(_events(combat, "stats").size() > 0, true)
	singer.damage_taken = singer.max_health - 1
	combat._attack(singer, enemy)
	assert_false(singer.on_board)
	assert_lte(singer.health, 0, "a simultaneous permanent reward cannot revive the singer")
	assert_eq(_events(combat, "permanent_reward").size(), 1)


func test_owner_toll_carry_resets_previous_toll_and_excludes_keep() -> void:
	var combat: Combat = _fight({0: "bridge_toad"}, {0: CK.plain(0, 100)})
	combat.side_rules[0]["bog_toll"] = 999
	Pass3BogCombat.finish(combat)
	assert_eq(combat.carry[-1], {"side": 0, "op": "bog_state", "toll": 0, "kisses": 0})


func test_untouched_fight_has_no_bog_events_or_carry() -> void:
	var combat: Combat = _fight({0: CK.plain(1, 100)}, {0: CK.plain(1, 100)})
	Pass3BogCombat.finish(combat)
	assert_false(combat.notes.get("bog_active", false))
	assert_true(combat.carry.is_empty())
	assert_true(_events(combat, "bog_toll").is_empty())


func test_standalone_pass3_bitter_still_records_and_carries_toll() -> void:
	var combat: Combat = _fight({0: CK.u("peatling", 0, 100)}, {0: CK.plain(8, 100)})
	CombatLanes.bitter(combat, combat.unit_at(0, 0), combat.unit_at(1, 0))
	Pass3BogCombat.finish(combat)
	assert_true(combat.notes.get("bog_active", false))
	assert_eq(combat.carry[-1], {"op": "bog_state", "side": 0, "toll": 2, "kisses": 0})
