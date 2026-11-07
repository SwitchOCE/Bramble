# gdlint:disable=max-public-methods
extends GutTest
## Final Bog folk roster, costing-3 caps, and cross-phase Prince rules.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")
var _kit: KIT
var _combat: Combat


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_kit.rules.start_phase(_kit.player, 1)
	_kit.player.gold = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	_combat = Combat.create(_kit.library, _kit.config, rng)


func _setup(ours: Dictionary, theirs: Dictionary) -> void:
	_combat._setup([FIGHT.board(ours), FIGHT.board(theirs)])
	_combat._recalc_auras(false)
	CombatLanes.bell(_combat)


func _kill(side: int, slot: int) -> void:
	_combat.deal_effect_damage(null, _combat.unit_at(side, slot), 999)
	_combat._resolve_deaths(side)


func _gold() -> int:
	var gold: int = 0
	for change: Dictionary in _combat.carry:
		if change["op"] == "gold_next_turn" and change["side"] == 0:
			gold += int(change["amount"])
	return gold


func _events(kind: String) -> Array[Dictionary]:
	return FIGHT.of_type({"events": _combat.events}, kind)


func test_roster_has_fourteen_pool_cards_and_two_created_cards_all_built() -> void:
	var count: int = 0
	for card: Dictionary in _kit.library.pool_units("slice"):
		if card["tribes"].has("Bog folk"):
			count += 1
	assert_eq(count, 14)
	assert_false(_kit.library.get_unit("prince_restored")["pool"])
	assert_false(_kit.library.get_unit("peatling")["pool"])
	assert_eq(_kit.library.unbuilt_units(), PackedStringArray())


func test_bridge_pays_once_only_when_its_bell_top_attacker_attacks_it() -> void:
	_setup({0: FIGHT.u("bridge_toad", 1, 40)}, {0: FIGHT.plain(5, 40), 1: FIGHT.plain(4, 40)})
	var attacker: CombatUnit = _combat.unit_at(1, 0)
	_combat.buff(attacker, -2, 0, null)
	_combat._attack(attacker, _combat.unit_at(0, 0))
	_combat._attack(attacker, _combat.unit_at(0, 0))
	assert_eq(_gold(), 1, "starting Attack, actual crossing, once a fight")


func test_bridge_wrong_lane_pays_nothing() -> void:
	_setup({0: FIGHT.u("bridge_toad", 1, 40)}, {0: FIGHT.plain(2, 40), 1: FIGHT.plain(5, 40)})
	_combat._attack(_combat.unit_at(1, 0), _combat.unit_at(0, 0))
	assert_eq(_gold(), 0)


func test_golden_bridge_counts_top_attack_ties() -> void:
	_setup({0: FIGHT.u("bridge_toad", 1, 40, true)}, {0: FIGHT.plain(5, 40), 1: FIGHT.plain(5, 40)})
	_combat._attack(_combat.unit_at(1, 0), _combat.unit_at(0, 0))
	assert_eq(_gold(), 2)


func test_pretender_paid_for_a_mired_kill_even_in_a_simultaneous_trade() -> void:
	_setup({0: FIGHT.u("bridge_toad"), 4: FIGHT.u("young_pretender")}, {0: FIGHT.plain(2, 3)})
	_combat._attack(_combat.unit_at(0, 4), _combat.unit_at(1, 0))
	assert_eq(_gold(), 1)
	assert_null(_combat.unit_at(0, 4), "the frog traded")


func test_nan_lends_bitter_and_it_stacks_with_bufos_own_bitter() -> void:
	_setup(
		{
			0: FIGHT.u("warty_nan"),
			1: FIGHT.u("madame_bufo", 1, 40),
			2: FIGHT.u("warty_nan", -1, -1, true)
		},
		{1: FIGHT.plain(10, 40)}
	)
	var attacker: CombatUnit = _combat.unit_at(1, 1)
	_combat._attack(attacker, _combat.unit_at(0, 1))
	assert_eq(attacker.attack, 5, "Bitter 1 + 2 + 2")


func test_bufo_bitter_then_halving_is_the_giant_answer() -> void:
	_setup({0: FIGHT.u("madame_bufo")}, {0: FIGHT.plain(14, 50)})
	var attacker: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(attacker, _combat.unit_at(0, 0))
	assert_eq(attacker.attack, 6, "14 -> Bitter 12 -> half 6")


func test_bufo_halves_her_mired_killer_when_she_dies_to_counter_damage() -> void:
	_setup({0: FIGHT.u("madame_bufo")}, {0: FIGHT.plain(15, 50)})
	var killer: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(_combat.unit_at(0, 0), killer)
	assert_eq(killer.attack, 8, "loses half, rounded down; she wasn't attacked so no Bitter")


func test_bufo_does_not_halve_a_killer_from_someone_elses_lane() -> void:
	_setup({0: FIGHT.u("madame_bufo")}, {1: FIGHT.plain(14, 50)})
	var killer: CombatUnit = _combat.unit_at(1, 1)
	_combat._attack(killer, _combat.unit_at(0, 0))
	assert_eq(killer.attack, 12, "Bitter only")


func test_hopkin_goes_first_each_cycle_in_back_and_gains_only_his_row_bonus() -> void:
	_setup(
		{0: FIGHT.plain(1, 20), 1: FIGHT.plain(1, 20), 4: FIGHT.u("vaulting_hopkin")},
		{0: FIGHT.plain(1, 100)}
	)
	var order: Array = []
	for _index: int in 4:
		order.append(_combat._choose_attacker(0, []).slot)
	assert_eq(order, [4, 0, 1, 4])
	assert_eq(_combat.unit_at(0, 4).attack, 5)
	CombatMoves.swap_rows(_combat, 0)
	assert_eq(_combat.unit_at(0, 0).attack, 3, "bonus goes away in front")


func test_chorus_lends_mire_to_other_tribes_and_not_itself() -> void:
	_setup(
		{0: FIGHT.u("sett_warden"), 1: FIGHT.u("natterjack_chorus"), 2: FIGHT.u("pill_bug")},
		{0: FIGHT.plain(3, 20), 1: FIGHT.plain(3, 20), 2: FIGHT.plain(3, 20)}
	)
	assert_true(_combat.unit_at(1, 0).has_status("mired"))
	assert_false(_combat.unit_at(1, 1).has_status("mired"))
	assert_true(_combat.unit_at(1, 2).has_status("mired"))


func test_sal_burns_only_occupied_patches_after_the_bell() -> void:
	var result: Dictionary = _kit.fight(
		{0: {"def_id": "bridge_toad"}, 4: {"def_id": "spitfire_sal"}},
		{0: {"def_id": "field_vole", "health": 2}, 1: {"def_id": "field_vole", "health": 10}}
	)
	var hits: Array = []
	for event: Dictionary in KIT.of_type(result, "damage"):
		if event["kind"] == "effect":
			hits.append(event)
	assert_eq(hits.size(), 1)
	assert_eq(hits[0]["amount"], 2)
	assert_gt(int(hits[0]["seq"]), FIGHT.index_of(result, "bog_patch"))


func test_cutter_pays_once_even_with_three_mired_deaths() -> void:
	_setup(
		{1: FIGHT.u("prima_donna"), 4: FIGHT.u("peat_cutter")},
		{0: FIGHT.plain(1, 20), 1: FIGHT.plain(1, 20), 2: FIGHT.plain(1, 20)}
	)
	for slot: int in 3:
		_kill(1, slot)
	assert_eq(_gold(), 1)


func test_gideon_counter_has_a_temporary_bonus_and_cannot_chain_counters() -> void:
	_setup({0: FIGHT.u("gideon", 2, 100)}, {0: FIGHT.u("gideon", 2, 100)})
	var ours: CombatUnit = _combat.unit_at(0, 0)
	var theirs: CombatUnit = _combat.unit_at(1, 0)
	_combat._attack(theirs, ours)
	assert_eq(_events("immediate_attack").size(), 1)
	assert_eq(theirs.health, 94, "2 counter-damage, then 4 from the reply")
	assert_eq(ours.attack, 2, "the reply's +2 is not lasting growth")


func test_jenny_weakens_her_patch_and_sends_only_the_strongest_neighbour_even_if_dying() -> void:
	_setup(
		{0: FIGHT.plain(2, 50), 1: FIGHT.u("jenny_greenteeth"), 2: FIGHT.plain(7, 50)},
		{1: FIGHT.plain(10, 50)}
	)
	var enemy: CombatUnit = _combat.unit_at(1, 1)
	assert_eq(enemy.attack, 8, "aura applied after the snapshot")
	var neighbour: int = _combat.unit_at(0, 2).uid
	_combat._attack(enemy, _combat.unit_at(0, 1))
	assert_null(_combat.unit_at(0, 1), "Jenny fainted")
	assert_eq(enemy.attack, 10, "her live aura left")
	assert_eq(_events("immediate_attack").size(), 1)
	assert_eq(_events("immediate_attack")[0]["attacker"], neighbour)


func test_highness_keeps_one_kiss_per_fight_then_transforms_with_buffs_and_identity() -> void:
	_kit.put("prima_donna", 1)
	var highness: RecruitUnit = _kit.put("his_highness", 4)
	highness.add_permanent(2, 20)
	var iid: int = highness.iid
	for fight: int in 3:
		var result: Dictionary = _kit.fight_board(
			{
				0: {"def_id": "field_vole", "attack": 0, "health": 1},
				1: {"def_id": "field_vole", "attack": 0, "health": 1},
				2: {"def_id": "field_vole", "attack": 0, "health": 1}
			}
		)
		assert_eq(KIT.of_type(result, "kiss").size(), 1)
		assert_eq(highness.counters["kisses"], fight + 1)
	assert_eq(highness.def_id(), "prince_restored")
	assert_eq(highness.iid, iid)
	assert_eq(highness.attack, 8)
	assert_eq(highness.health, 27)
	assert_eq(_kit.player.board[4], highness)
	assert_eq(highness.pool_id(), "his_highness")


func test_highness_triple_keeps_the_highest_kiss_count() -> void:
	for count: int in 3:
		var unit: RecruitUnit = _kit.put("his_highness")
		unit.counters["kisses"] = count
	_kit.rules.check_triples(_kit.player)
	assert_eq(_kit.player.hand.size(), 1)
	assert_true(_kit.player.hand[0].golden)
	assert_eq(_kit.player.hand[0].counters["kisses"], 2)


func test_transformed_prince_sale_returns_the_original_pool_copy() -> void:
	var unit: RecruitUnit = _kit.put("his_highness", 0)
	unit.pool_copies = 1
	assert_true(_kit.pool.take("his_highness"))
	var before: int = _kit.pool.copies_left("his_highness")
	_kit.rules.apply_carry(
		_kit.player, {"op": "transform", "iid": unit.iid, "into": "prince_restored"}
	)
	assert_eq(_kit.rules.sell(_kit.player, 0), "")
	assert_eq(_kit.pool.copies_left("his_highness"), before + 1)
	assert_eq(_kit.pool.copies_left("prince_restored"), 0)


func test_prince_first_spell_discount_is_consumed_by_purchase_and_resets_next_turn() -> void:
	_kit.put("prince_restored", 0)
	_kit.player.shop_spells = [
		HandItem.make(_kit.library.get_card("elderflower_cordial"), 900),
		HandItem.make(_kit.library.get_card("elderflower_cordial"), 901)
	]
	var gold: int = _kit.player.gold
	assert_eq(_kit.rules.spell_cost(_kit.player, _kit.player.shop_spells[0]), 0)
	assert_eq(_kit.rules.buy_spell(_kit.player, 0), "")
	assert_eq(_kit.player.gold, gold)
	assert_eq(_kit.rules.spell_cost(_kit.player, _kit.player.shop_spells[0]), 1)
	_kit.rules.start_phase(_kit.player, 2)
	assert_eq(_kit.player.spells_bought_turn, 0)
	assert_eq(
		BogFolk.spell_cost(
			_kit.player, HandItem.make(_kit.library.get_card("elderflower_cordial"), 902)
		),
		0
	)


func test_golden_prince_discount_floors_at_zero_and_does_not_touch_items() -> void:
	_kit.put("prince_restored", 0, true)
	var spell: HandItem = HandItem.make(_kit.library.get_card("elderflower_cordial"), 900)
	assert_eq(_kit.rules.spell_cost(_kit.player, spell), 0)
	var item: HandItem = HandItem.make({"kind": "item", "cost": 3}, 901)
	assert_eq(_kit.rules.spell_cost(_kit.player, item), 3)


func test_tiddy_grows_the_maker_twice_and_sends_permanent_stats_back() -> void:
	var diva: RecruitUnit = _kit.put("prima_donna", 1)
	_kit.put("tiddy_mun", 4)
	_combat._setup(
		[
			_kit.player.combat_board(),
			FIGHT.board({0: FIGHT.plain(1, 20), 1: FIGHT.plain(1, 20), 2: FIGHT.plain(1, 20)})
		]
	)
	_combat._recalc_auras(false)
	CombatLanes.bell(_combat)
	for slot: int in 3:
		_kill(1, slot)
	for change: Dictionary in _combat.carry:
		if change["side"] == 0:
			_kit.rules.apply_carry(_kit.player, change)
	assert_eq(diva.attack, 4)
	assert_eq(diva.health, 10)


func test_tiddy_grows_itself_if_the_maker_has_gone() -> void:
	_setup({0: FIGHT.u("bridge_toad"), 4: FIGHT.u("tiddy_mun")}, {0: FIGHT.plain(1, 20)})
	_kill(0, 0)
	_kill(1, 0)
	assert_eq(_combat.unit_at(0, 4).attack, 4)
	assert_eq(_combat.unit_at(0, 4).health, 6)


func test_prima_donna_in_b2_bogs_the_whole_back_row() -> void:
	_setup(
		{5: FIGHT.u("prima_donna")},
		{4: FIGHT.plain(1, 20), 5: FIGHT.plain(1, 20), 6: FIGHT.plain(1, 20)}
	)
	assert_eq(_combat.bog_patches[1].size(), 3)
	for slot: int in [4, 5, 6]:
		assert_eq(CombatLanes.lock_target(_combat, _combat.unit_at(1, slot)), _combat.unit_at(0, 5))


func test_peat_king_raises_at_most_two_peatlings_in_nearest_gaps() -> void:
	_setup(
		{1: FIGHT.u("prima_donna"), 5: FIGHT.u("peat_king")},
		{0: FIGHT.plain(1, 20), 1: FIGHT.plain(1, 20), 2: FIGHT.plain(1, 20)}
	)
	var expected: int = _combat.named_slot(0, "nearest_empty", 5)
	for slot: int in 3:
		_kill(1, slot)
	var summons: Array[Dictionary] = _events("summon")
	assert_eq(summons.size(), 2)
	assert_eq(summons[0]["slot"], expected)
	assert_eq(summons[0]["unit"]["def_id"], "peatling")
	assert_eq(summons[0]["unit"]["attack"], 4)


func test_golden_peat_king_raises_golden_bitter_peatlings() -> void:
	_setup(
		{0: FIGHT.u("bridge_toad"), 5: FIGHT.u("peat_king", -1, -1, true)}, {0: FIGHT.plain(1, 20)}
	)
	_kill(1, 0)
	var summon: Dictionary = _events("summon")[0]
	assert_eq(summon["unit"]["attack"], 8)
	assert_eq(summon["unit"]["health"], 8)
	var peatling: CombatUnit = _combat.unit_at(0, int(summon["slot"]))
	assert_eq(CombatLanes.parameters(peatling, "bitter")["n"], 4)


func test_princes_triple_only_with_princes_and_keep_the_original_pool_identity() -> void:
	_kit.put("prince_restored", 0).pool_origin = "his_highness"
	_kit.put("prince_restored", 1).pool_origin = "his_highness"
	var third: RecruitUnit = _kit.put("his_highness", 2)
	_kit.rules.check_triples(_kit.player)
	assert_eq(_kit.player.board_count(), 3, "Highness is a different card")
	_kit.rules.apply_carry(
		_kit.player, {"op": "transform", "iid": third.iid, "into": "prince_restored"}
	)
	_kit.rules.after_fights(_kit.player)
	assert_eq(_kit.player.hand.size(), 1)
	assert_eq(_kit.player.hand[0].def_id(), "prince_restored")
	assert_true(_kit.player.hand[0].golden)
	assert_eq(_kit.player.hand[0].pool_id(), "his_highness")


func test_golden_highness_becomes_a_golden_prince() -> void:
	_kit.put("bridge_toad", 0)
	var highness: RecruitUnit = _kit.put("his_highness", 4, true)
	highness.counters["kisses"] = 2
	var result: Dictionary = _kit.fight_board(
		{0: {"def_id": "field_vole", "attack": 0, "health": 1}}
	)
	assert_eq(highness.def_id(), "prince_restored")
	assert_true(highness.golden)
	assert_eq(highness.attack, 12)
	assert_eq(KIT.of_type(result, "transform").size(), 1)
	assert_eq(KIT.of_type(result, "bog_patch").size(), 1, "the Prince missed the bell")


func test_peat_king_does_not_spend_a_summon_on_a_full_board() -> void:
	var ours: Dictionary = {1: FIGHT.u("prima_donna"), 5: FIGHT.u("peat_king")}
	for slot: int in [0, 2, 3, 4, 6]:
		ours[slot] = FIGHT.plain(1, 20)
	_setup(ours, {0: FIGHT.plain(1, 20), 1: FIGHT.plain(1, 20)})
	_kill(1, 0)
	assert_eq(_events("summon").size(), 0)
	_kill(0, 4)
	_kill(1, 1)
	assert_eq(_events("summon").size(), 1, "a later gap can still be used")


func test_gideons_reply_bonus_can_restore_attack_lost_to_hex() -> void:
	_setup({0: FIGHT.u("gideon", 2, 100)}, {0: FIGHT.plain(1, 100)})
	var gideon: CombatUnit = _combat.unit_at(0, 0)
	var enemy: CombatUnit = _combat.unit_at(1, 0)
	_combat.add_hex(enemy, 0, 0, 2)
	assert_eq(gideon.attack, 0)
	_combat._attack(enemy, gideon)
	assert_eq(_events("immediate_attack").size(), 1, "the reply gets its +2 before checking Attack")
	assert_eq(enemy.health, 98)
	assert_eq(gideon.attack, 0, "the temporary bonus ends")
