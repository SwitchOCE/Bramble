# gdlint:disable=max-public-methods
extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const FIGHT := preload("res://tests/core/combat_kit.gd")
var _kit: KIT
var _combat: Combat


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_kit.rules.start_phase(_kit.player, 1)
	_kit.player.gold = 30
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	_combat = Combat.create(_kit.library, _kit.config, rng)
	_combat._tiers = [6, 6]


func _setup(ours: Dictionary, theirs: Dictionary) -> void:
	_combat._setup([FIGHT.board(ours), FIGHT.board(theirs)])
	_combat._recalc_auras(false)
	CombatLanes.bell(_combat)


func _events(type: String) -> Array[Dictionary]:
	return FIGHT.of_type({"events": _combat.events}, type)


func _kill(side: int, slot: int) -> void:
	_combat.deal_effect_damage(null, _combat.unit_at(side, slot), 999)
	_combat._resolve_deaths(side)


func _gold() -> int:
	var gold: int = 0
	for change: Dictionary in _combat.carry:
		if change["op"] == "gold_next_turn" and change["side"] == 0:
			gold += int(change["amount"])
	return gold


func test_all_sixteen_hunters_are_built_and_five_tribes_are_in_lobbies() -> void:
	var count: int = 0
	for card: Dictionary in _kit.library.pool_units("slice"):
		count += 1 if card["tribes"].has("Hunters") else 0
	assert_eq(count, 16)
	assert_eq(_kit.library.unbuilt_units(), PackedStringArray())
	assert_eq(GameConfig.full_game().get_int("tribes_per_lobby"), 5)


func test_nip_take_in_a_trade_and_no_refill_take() -> void:
	_setup({0: FIGHT.u("little_nip")}, {0: FIGHT.u("little_dollop", 1, 2)})
	_combat.unit_at(1, 0).held_specs = [{"def_id": "field_vole", "golden": false}]
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_combat.takes, [1, 0])
	assert_eq(_gold(), 0, "Nip now grows without paying gold")
	assert_eq(_events("summon").size(), 1)


func test_young_brock_lends_without_overwriting_an_own_mark() -> void:
	_setup(
		{0: FIGHT.u("sable"), 1: FIGHT.u("young_brock"), 2: FIGHT.u("wick")},
		{0: FIGHT.plain(1, 10), 1: FIGHT.plain(1, 10)}
	)
	assert_eq(_combat.unit_at(0, 0).quarry, _combat.unit_at(1, 0).uid)
	assert_eq(_combat.unit_at(0, 0).attack, 2, "no loan buff for own Quarry")
	assert_eq(_combat.unit_at(0, 2).quarry, _combat.unit_at(1, 1).uid)
	assert_eq(_combat.unit_at(0, 2).attack, 3)


func test_pack_deals_joint_damage_and_only_leader_takes_counter_damage() -> void:
	_setup({0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("wick")}, {0: FIGHT.plain(5, 30)})
	var wick: CombatUnit = _combat.unit_at(0, 1)
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_combat.unit_at(1, 0).health, 26)
	assert_eq(_combat.unit_at(0, 0).health, 15)
	assert_eq(wick.health, 3)
	assert_eq(wick.attack, 3, "growth after this exchange")
	assert_true(wick.flagged)
	assert_eq(_events("attack")[0]["joiners"], [wick.uid])


func test_pack_bristle_hits_the_leader_for_each_damage_hit() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("wick")}, {0: FIGHT.u("hoglet_mother", 1, 30)}
	)
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_combat.unit_at(0, 0).health, 17, "counter 1 plus two Bristle pricks")
	assert_eq(_combat.unit_at(0, 1).health, 3)


func test_mired_pack_unit_cannot_join_against_someone_other_than_its_maker() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("wick")},
		{0: FIGHT.plain(1, 20), 1: FIGHT.u("bridge_toad", 1, 20)}
	)
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_events("attack")[0]["joiners"], [])
	assert_false(_combat.unit_at(0, 1).flagged)


func test_brother_wolf_joins_each_neighbour_once_and_resumes_after_cycle_reset() -> void:
	_setup(
		{
			0: FIGHT.u("little_nip", 1, 100),
			1: FIGHT.u("brother_wolf", 3, 100),
			2: FIGHT.u("sable", 1, 100)
		},
		{0: FIGHT.plain(1, 200)}
	)
	var target: CombatUnit = _combat.unit_at(1, 0)
	for slot: int in [0, 2, 0]:
		_combat._attack(_combat.unit_at(0, slot), target)
	assert_eq(_events("attack")[0]["joiners"].size(), 1)
	assert_eq(_events("attack")[1]["joiners"].size(), 1)
	assert_eq(_events("attack")[2]["joiners"].size(), 0)
	assert_false(CombatHunt.can_lead(_combat, _combat.unit_at(0, 1)))
	_combat.cycles[0] += 1
	_combat._attack(_combat.unit_at(0, 0), target)
	assert_eq(_events("attack")[3]["joiners"].size(), 1)


func test_two_brother_wolves_without_other_neighbours_can_lead() -> void:
	_setup({0: FIGHT.u("brother_wolf"), 1: FIGHT.u("brother_wolf")}, {0: FIGHT.plain(1, 40)})
	assert_true(CombatHunt.can_lead(_combat, _combat.unit_at(0, 0)))
	assert_true(CombatHunt.can_lead(_combat, _combat.unit_at(0, 1)))


func test_sable_reads_her_fixed_quarry_at_start_of_combat() -> void:
	var result: Dictionary = _kit.fight(
		{0: {"def_id": "sable"}}, {0: {"def_id": "field_vole", "attack": 10, "health": 20}}
	)
	var growth: bool = false
	for event: Dictionary in KIT.of_type(result, "stats"):
		growth = growth or (event["attack_delta"] == 3)
	assert_true(growth)


func test_toll_bard_golden_pays_once_and_reduces_attack_twice() -> void:
	_setup({0: FIGHT.u("toll_bard", 1, 100, true)}, {0: FIGHT.plain(10, 100)})
	for _index: int in 4:
		_combat._attack(_combat.unit_at(1, 0), _combat.unit_at(0, 0))
	assert_eq(_gold(), 2)
	assert_eq(_combat.unit_at(1, 0).attack, 6)


func test_old_lutra_reaches_a_protected_back_quarry_and_pays_for_back_take() -> void:
	_setup({4: FIGHT.u("old_lutra", 4, 20)}, {0: FIGHT.plain(1, 100), 4: FIGHT.plain(1, 2)})
	assert_eq(_combat._choose_target(_combat.unit_at(0, 4)), _combat.unit_at(1, 4))
	_combat._attack(_combat.unit_at(0, 4), _combat.unit_at(1, 4))
	assert_eq(_gold(), 1)


func test_pounce_once_a_cycle_ignores_rows_and_grows_the_surviving_lodger() -> void:
	_setup(
		{0: FIGHT.u("old_lutra", 1, 100), 4: FIGHT.u("lodger", 4, 100)}, {0: FIGHT.plain(1, 100)}
	)
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_events("immediate_attack").size(), 1)
	assert_eq(_combat.unit_at(0, 4).attack, 6)
	assert_eq(_combat.pointers, [-1, -1])
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_events("immediate_attack").size(), 1)
	_combat.cycles[0] += 1
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_events("immediate_attack").size(), 2)


func test_old_brock_lends_reach_to_four_neighbours_but_live_aura_ends_on_death() -> void:
	_setup(
		{
			1: FIGHT.u("wick"),
			2: FIGHT.u("lodger"),
			4: FIGHT.plain(2, 20),
			5: FIGHT.u("old_brock"),
			6: FIGHT.u("brother_wolf")
		},
		{5: FIGHT.plain(1, 100)}
	)
	for slot: int in [1, 2, 4, 6]:
		assert_true(_combat.unit_at(0, slot).quarry_reach)
		assert_eq(_combat.unit_at(0, slot).quarry, _combat.unit_at(1, 5).uid)
	assert_eq(_combat.unit_at(0, 1).attack, 3)
	assert_true(CombatHunt.has_pounce(_combat, _combat.unit_at(0, 1)))
	_kill(0, 5)
	assert_eq(_combat.unit_at(0, 1).attack, 2)
	assert_false(CombatHunt.has_pounce(_combat, _combat.unit_at(0, 1)))
	assert_true(_combat.unit_at(0, 1).quarry_reach)
	assert_ne(_combat.unit_at(0, 1).quarry, 0)


func test_glutton_growth_is_combat_only_and_grizel_growth_is_permanent_attack_only() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 2, 30), 1: FIGHT.u("grizel"), 4: FIGHT.u("mountain_glutton")},
		{0: FIGHT.plain(1, 6)}
	)
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_combat.unit_at(0, 4).attack, 6)
	assert_eq(_combat.unit_at(0, 4).health, 7)
	assert_eq(_combat.unit_at(0, 0).attack, 4, "Nip Take +1 and Grizel +1")
	assert_eq(_combat.unit_at(0, 1).attack, 6)
	assert_eq(_combat.unit_at(0, 1).max_health, 6)


func test_laird_grants_own_across_marks_only_to_our_side_and_buffs_only_hunters() -> void:
	_setup(
		{0: FIGHT.u("little_nip"), 1: FIGHT.plain(2, 20), 4: FIGHT.u("laird_of_sett")},
		{0: FIGHT.plain(1, 100), 1: FIGHT.plain(1, 100)}
	)
	assert_ne(_combat.unit_at(0, 1).quarry, 0)
	assert_eq(_combat.unit_at(0, 0).attack, 2, "no bonus before the first Take")
	assert_eq(_combat.unit_at(0, 1).attack, 2)
	assert_eq(_combat.unit_at(1, 0).quarry, 0)


func test_ermeline_discount_is_after_other_discounts_and_expires_next_turn() -> void:
	_kit.put("madame_ermeline", 4, true)
	_kit.player.takes_last_fight = 4
	_kit.rules.after_fights(_kit.player)
	assert_eq(_kit.player.hunt_discount_next, 6)
	_kit.rules.start_phase(_kit.player, 2)
	assert_eq(_kit.rules.tier_up_cost(_kit.player), 0)
	_kit.rules.end_phase(_kit.player)
	assert_eq(_kit.player.hunt_discount, 0)


func test_ermeline_tier_six_golden_gold_is_capped_at_three() -> void:
	_kit.put("madame_ermeline", 4, true)
	_kit.player.tier = 6
	_kit.player.takes_last_fight = 8
	_kit.rules.after_fights(_kit.player)
	assert_eq(_kit.player.gold_next_turn, 3)


func test_poach_reserves_a_pool_copy_for_next_shop_persists_refresh_then_expires_even_frozen(
) -> void:
	var before: int = _kit.pool.copies_left("pill_bug")
	_kit.rules.apply_carry(_kit.player, {"op": "poach", "card": "pill_bug", "discount": 1})
	assert_eq(_kit.pool.copies_left("pill_bug"), before - 1)
	assert_eq(_kit.player.poached_pending.size(), 1)
	var poached: RecruitUnit = _kit.player.poached_pending[0]
	_kit.rules.start_phase(_kit.player, 2)
	assert_true(_kit.player.shop.has(poached))
	assert_eq(_kit.rules.unit_cost(_kit.player, poached), 2)
	assert_eq(HunterRecruit.normal_shop_count(_kit.player), _kit.rules.shop_size(1, _kit.player))
	_kit.rules.replace_shop(_kit.player)
	assert_true(_kit.player.shop.has(poached))
	_kit.player.frozen = true
	_kit.rules.end_phase(_kit.player)
	assert_false(_kit.player.shop.has(poached))


func test_buying_a_golden_russet_offer_spends_one_and_clears_the_shop_discount() -> void:
	_kit.rules.apply_carry(_kit.player, {"op": "poach", "card": "pill_bug", "discount": 2})
	_kit.rules.start_phase(_kit.player, 2)
	_kit.player.gold = 1
	var unit: RecruitUnit = _kit.player.shop.back()
	assert_eq(_kit.rules.buy(_kit.player, _kit.player.shop.find(unit)), "")
	assert_eq(_kit.player.gold, 0)
	assert_eq(unit.poached_discount, 0)
	assert_true(_kit.player.hand.has(unit))


func test_poach_has_no_created_fallback_when_the_pool_is_empty_or_card_above_tier() -> void:
	while _kit.pool.take("pill_bug"):
		pass
	_kit.rules.apply_carry(_kit.player, {"op": "poach", "card": "pill_bug", "discount": 1})
	_kit.rules.apply_carry(_kit.player, {"op": "poach", "card": "grizel", "discount": 1})
	assert_eq(_kit.player.poached_pending.size(), 0)


func test_mire_prevents_pounce_at_a_different_quarry() -> void:
	_setup(
		{0: FIGHT.u("little_nip", 1, 40), 4: FIGHT.u("lodger", 2, 40)},
		{0: FIGHT.plain(1, 100), 4: FIGHT.u("madame_bufo", 1, 100)}
	)
	_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
	assert_eq(_events("immediate_attack").size(), 0)


func test_two_pouncers_chain_but_each_acts_once_in_the_cycle() -> void:
	_setup(
		{1: FIGHT.u("little_nip", 1, 40), 4: FIGHT.u("lodger", 2, 40), 5: FIGHT.u("lodger", 2, 40)},
		{1: FIGHT.plain(1, 100)}
	)
	_combat._attack(_combat.unit_at(0, 1), _combat.unit_at(1, 1))
	assert_eq(_events("immediate_attack").size(), 2)
	assert_eq(_combat.unit_at(1, 1).health, 95)


func test_pounce_does_not_recruit_pack_joiners() -> void:
	_setup({4: FIGHT.u("lodger", 2, 40), 5: FIGHT.u("wick")}, {0: FIGHT.plain(1, 100)})
	_combat.queue_attack(_combat.unit_at(0, 4), _combat.unit_at(1, 0), "pounce")
	_combat.reactions.drain(_combat)
	assert_eq(_events("attack")[0]["joiners"], [])
	assert_eq(_combat.unit_at(0, 5).attack, 2)


func test_russet_poach_is_really_carried_to_a_pool_backed_offer() -> void:
	_kit.put("mistress_russet", 0)
	_kit.fight_board({0: {"def_id": "pill_bug", "attack": 1, "health": 1}})
	assert_eq(_kit.player.poached_pending.size(), 1)
	assert_eq(_kit.player.poached_pending[0].def_id(), "pill_bug")
	assert_eq(_kit.player.poached_pending[0].pool_copies, 1)


func test_grizel_sends_only_attack_back_to_real_owned_units() -> void:
	var nip: RecruitUnit = _kit.put("little_nip", 0)
	var mother: RecruitUnit = _kit.put("grizel", 1)
	_kit.fight_board({0: {"def_id": "field_vole", "attack": 1, "health": 6}})
	assert_eq(nip.perm_attack, 2, "Nip own growth and Grizel Attack")
	assert_eq(nip.perm_health, 1, "only Nip own growth adds Health")
	assert_eq(mother.perm_attack, 1)
	assert_eq(mother.perm_health, 0)


func test_poach_expiry_returns_its_exact_copy_even_when_the_shop_is_frozen() -> void:
	_kit.rules.apply_carry(_kit.player, {"op": "poach", "card": "pill_bug", "discount": 1})
	_kit.rules.start_phase(_kit.player, 2)
	_kit.player.frozen = true
	var before: int = _kit.pool.copies_left("pill_bug")
	_kit.rules.end_phase(_kit.player)
	assert_eq(_kit.pool.copies_left("pill_bug"), before + 1)


func test_damage_from_a_friendly_nest_or_hero_can_trigger_pounce() -> void:
	_setup({0: FIGHT.u("little_nip", 1, 40), 4: FIGHT.u("lodger", 2, 40)}, {0: FIGHT.plain(1, 100)})
	_combat.deal_effect_damage(null, _combat.unit_at(1, 0), 2, 0)
	_combat._resolve_deaths(0)
	_combat.reactions.drain(_combat)
	assert_eq(_events("immediate_attack").size(), 1)


func test_ermeline_reward_reduces_only_the_next_upgrade() -> void:
	_kit.player.hunt_discount = 3
	assert_eq(_kit.rules.tier_up(_kit.player), "")
	assert_eq(_kit.player.hunt_discount, 0)
	assert_eq(_kit.rules.tier_up_cost(_kit.player), _kit.rules.base_upgrade_cost(_kit.player.tier))
	var before: int = _kit.player.gold
	var full_cost: int = _kit.rules.tier_up_cost(_kit.player)
	assert_eq(_kit.rules.tier_up(_kit.player), "")
	assert_eq(_kit.player.gold, before - full_cost)


func test_a_refused_upgrade_keeps_the_take_discount() -> void:
	_kit.player.hunt_discount = 1
	_kit.player.gold = 0
	assert_eq(_kit.rules.tier_up(_kit.player), "Not enough gold")
	assert_eq(_kit.player.hunt_discount, 1)


func test_brother_wolf_can_lead_beside_a_whistler_that_never_attacks() -> void:
	_setup({0: FIGHT.u("marmot_lookout"), 1: FIGHT.u("brother_wolf")}, {0: FIGHT.plain(1, 40)})
	assert_true(CombatHunt.can_lead(_combat, _combat.unit_at(0, 1)))
	_combat.unit_at(0, 0).flagged = true
	assert_eq(_combat._choose_attacker(0, []).slot, 1)
