extends GutTest
## Amended pass 2 Hunters and Hedgerow rules through their real phase boundaries.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const K := preload("res://tests/core/recruit_kit.gd")
const C := preload("res://tests/core/combat_kit.gd")
var _kit: K
var _combat: Combat


func before_each() -> void:
	_kit = K.new()
	_kit.setup(
		GameConfig.full_game(), false, LegacyWave1.with_hedgerow(LegacyWave1.current_with_hunters())
	)
	_kit.rules.start_phase(_kit.player, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	_combat = Combat.create(_kit.library, _kit.config, rng)


func _setup(ours: Dictionary, theirs: Dictionary) -> void:
	_combat._setup([C.board(ours), C.board(theirs)])
	_combat._recalc_auras(false)


func test_pool_parity_and_reviewed_bodies() -> void:
	for tribe: String in ["Hunters", "Hedgerow folk"]:
		var counts: Array[int] = [0, 0, 0, 0, 0, 0]
		for card: Dictionary in _kit.library.pool_units("slice"):
			if card["tribes"].has(tribe):
				counts[int(card["tier"]) - 1] += 1
		assert_eq(counts, [3, 3, 3, 3, 2, 2], tribe)
	assert_eq(_kit.library.get_unit("young_brock")["attack"], 1)
	for id: String in ["wick", "little_nip", "mistress_russet"]:
		assert_eq(_kit.library.get_unit(id)["health"], 3)
	assert_eq(_kit.library.get_unit("grey_agnes")["health"], 5)
	assert_eq(_kit.library.get_unit("mrs_mallow")["health"], 5)
	assert_eq(_kit.library.get_unit("mrs_clover")["health"], 4)


func test_beadle_counts_acorn_gains_once_and_pym_counts_the_combination() -> void:
	_kit.put("beadle_warrenby", 0)
	_kit.put("mr_pym", 4)
	var end: RecruitUnit = _kit.put("pill_bug", 3)
	for _index: int in 3:
		_kit.rules.give_card(_kit.player, "acorn")
	assert_eq(_kit.item_ids(), ["stash"])
	assert_eq(_kit.player.pending_passes.size(), 2, "one Beadle and one Pym")
	_kit.rules.end_phase(_kit.player)
	assert_eq([end.attack, end.health], [4, 7])


func test_partner_payout_passes_land_during_that_same_end_of_turn() -> void:
	_kit.rules.give_card(_kit.player, "acorn")
	_kit.put("beadle_warrenby", 0)
	_kit.put("mr_pym", 1)
	var partner: RecruitUnit = _kit.put("sleeping_partner", 4)
	partner.turns_in_slot = 2
	partner.home_slot = 4
	var end: RecruitUnit = _kit.put("pill_bug", 3)
	_kit.rules.end_phase(_kit.player)
	assert_eq(_kit.item_ids(), ["stash"])
	assert_eq(end.perm_attack, 3, "Beadle and Pym land after the EOT payout queue")
	assert_true(_kit.player.pending_passes.is_empty())


func test_beadle_and_pym_golden_pass_values_double() -> void:
	_kit.put("beadle_warrenby", 0, true)
	_kit.put("mr_pym", 4, true)
	var end: RecruitUnit = _kit.put("pill_bug", 3)
	_kit.rules.give_card(_kit.player, "acorn")
	_kit.rules.give_card(_kit.player, "stash")
	_kit.rules.end_phase(_kit.player)
	assert_eq([end.attack, end.health], [7, 10])


func test_beadle_does_not_count_an_acorn_lost_to_a_full_hand() -> void:
	_kit.put("beadle_warrenby", 0)
	for _index: int in _kit.config.get_int("hand_limit"):
		_kit.rules.give_card(_kit.player, "elderflower_cordial")
	_kit.rules.give_card(_kit.player, "acorn")
	assert_true(_kit.player.pending_passes.is_empty())


func test_beadle_resets_once_per_turn_and_stash_is_not_an_acorn() -> void:
	_kit.put("beadle_warrenby", 0)
	var end: RecruitUnit = _kit.put("pill_bug", 3)
	_kit.rules.give_card(_kit.player, "stash")
	assert_true(_kit.player.pending_passes.is_empty())
	_kit.rules.give_card(_kit.player, "acorn")
	_kit.pass_turn()
	_kit.rules.give_card(_kit.player, "acorn")
	_kit.rules.end_phase(_kit.player)
	assert_eq(end.perm_attack, 2)


func test_pym_does_not_count_a_great_hoard() -> void:
	_kit.put("mr_pym", 0)
	_kit.rules.give_card(_kit.player, "great_hoard")
	assert_true(_kit.player.pending_passes.is_empty())


func test_hayward_cashing_and_feeding_buff_touching_hedgerow_including_himself() -> void:
	var hayward: RecruitUnit = _kit.put("goodman_hayward", 0)
	var dozey: RecruitUnit = _kit.put("alderman_dozey", 4)
	var neutral: RecruitUnit = _kit.put("pill_bug", 1)
	var isolated: RecruitUnit = _kit.put("mr_crumb", 3)
	_kit.rules.give_card(_kit.player, "stash")
	assert_eq(_kit.rules.play_item(_kit.player, 0), "")
	assert_eq(hayward.perm_attack, 1)
	assert_eq(dozey.perm_attack, 1)
	assert_eq(neutral.perm_attack, 0)
	assert_eq(isolated.perm_attack, 0, "gap breaks touching")
	_kit.rules.give_card(_kit.player, "great_hoard")
	assert_eq(_kit.rules.play_item(_kit.player, 0, 4), "")
	assert_eq(hayward.perm_attack, 2)
	assert_eq(dozey.perm_attack, 10, "two Hayward buffs and eight from fed Hoard")


func test_hayward_golden_doubles_stats_and_ignores_small_acorns() -> void:
	var hayward: RecruitUnit = _kit.put("goodman_hayward", 0, true)
	_kit.rules.give_card(_kit.player, "acorn")
	assert_eq(_kit.rules.play_item(_kit.player, 0), "")
	assert_eq(hayward.perm_attack, 0)
	_kit.rules.give_card(_kit.player, "stash")
	assert_eq(_kit.rules.play_item(_kit.player, 0), "")
	assert_eq(hayward.perm_attack, 2)


func test_clover_buffs_two_recruit_summons_but_not_played_units() -> void:
	_kit.put("mrs_clover", 6)
	var burdock: RecruitUnit = _kit.play("mrs_burdock", 0)
	assert_eq(burdock.perm_attack, 0)
	assert_eq(_kit.player.board[4].attack, 2, "Kit was summoned")
	for id: String in ["drip", "shrewlet", "mouse"]:
		_kit.rules.summon_units(_kit.player, id, 1, false, 0)
	assert_eq(_kit.player.board[1].perm_attack, 1)
	for slot: int in [2, 3]:
		assert_eq(_kit.player.board[slot].perm_attack, 0)


func test_clover_buffs_only_two_combat_summons_and_golden_doubles() -> void:
	for golden: bool in [false, true]:
		_setup({6: C.u("mrs_clover", -1, -1, golden)}, {0: C.plain(0, 100)})
		var source: CombatUnit = _combat.unit_at(0, 6)
		var summoned: Array[CombatUnit] = []
		for slot: int in [0, 1, 2]:
			summoned.append(_combat.summon_into("drip", false, 0, slot, source))
		var stats: int = 2 if golden else 1
		assert_eq(summoned[0].combat_attack, stats)
		assert_eq(summoned[1].combat_attack, stats)
		assert_eq(summoned[2].combat_attack, 0)


func test_mallow_uses_total_stats_skips_shy_and_breaks_ties_by_zigzag() -> void:
	_kit.put("mrs_mallow", 6)
	var shy: RecruitUnit = _kit.put("hob_in_the_hearth", 0)
	var later: RecruitUnit = _kit.put("pill_bug", 1)
	var earlier: RecruitUnit = _kit.put("pill_bug", 4)
	_kit.rules.end_phase(_kit.player)
	assert_eq(shy.perm_attack, 0)
	assert_eq(earlier.perm_attack, 1)
	assert_eq(later.perm_attack, 0)


func test_mallow_golden_doubles_and_can_pick_herself() -> void:
	var mallow: RecruitUnit = _kit.put("mrs_mallow", 0, true)
	_kit.rules.end_phase(_kit.player)
	assert_eq([mallow.perm_attack, mallow.perm_health], [2, 2])


func test_lollop_buffs_only_the_touching_run_this_fight() -> void:
	_setup({0: C.u("squire_lollop"), 4: C.plain(1, 4), 3: C.plain(1, 4)}, {0: C.plain(0, 100)})
	_combat._start_of_combat()
	assert_eq(_combat.unit_at(0, 0).attack, 7)
	assert_eq(_combat.unit_at(0, 4).attack, 2)
	assert_eq(_combat.unit_at(0, 3).attack, 1)
	assert_eq(_combat.unit_at(0, 0).perm_attack, 0)


func test_lollop_full_board_and_golden_doubles_both_values() -> void:
	for golden: bool in [false, true]:
		var ours: Dictionary = {0: C.u("squire_lollop", -1, -1, golden)}
		for slot: int in [1, 2, 3, 4, 5, 6]:
			ours[slot] = C.plain(1, 4)
		_setup(ours, {0: C.plain(0, 100)})
		_combat._start_of_combat()
		assert_eq(_combat.unit_at(0, 4).attack, 5 if golden else 3)


func test_agnes_aura_and_grant_only_reach_the_next_row_slot_and_end_on_death() -> void:
	_setup(
		{0: C.plain(1, 20), 1: C.u("grey_agnes"), 2: C.plain(1, 20), 3: C.plain(1, 20)},
		{0: C.plain(0, 100)}
	)
	var agnes: CombatUnit = _combat.unit_at(0, 1)
	var next: CombatUnit = _combat.unit_at(0, 2)
	assert_eq(_combat.unit_at(0, 0).attack, 1)
	assert_eq(next.attack, 2)
	var joins: Array[CombatUnit] = CombatHunt.joiners(_combat, agnes, _combat.unit_at(1, 0))
	assert_eq(joins, [next])
	_combat.deal_effect_damage(null, agnes, 99)
	_combat._resolve_deaths(0)
	assert_eq(next.attack, 1)
	next.flagged = false
	assert_true(
		CombatHunt.joiners(_combat, _combat.unit_at(0, 3), _combat.unit_at(1, 0)).is_empty()
	)


func test_agnes_never_grants_across_a_gap_or_the_row_boundary() -> void:
	_setup(
		{0: C.u("grey_agnes"), 2: C.plain(1, 20), 3: C.u("grey_agnes"), 4: C.plain(1, 20)},
		{0: C.plain(0, 100)}
	)
	assert_eq(_combat.unit_at(0, 2).attack, 1)
	assert_eq(_combat.unit_at(0, 4).attack, 1)


func test_isegrim_only_adds_to_joiner_damage_and_leaves_no_stat_bonus() -> void:
	for golden: bool in [false, true]:
		_setup(
			{0: C.plain(1, 20), 1: C.u("wick"), 6: C.u("old_isegrim", -1, -1, golden)},
			{0: C.plain(0, 100)}
		)
		var joiner: CombatUnit = _combat.unit_at(0, 1)
		_combat._attack(_combat.unit_at(0, 0), _combat.unit_at(1, 0))
		assert_eq(_combat.unit_at(1, 0).health, 91 if golden else 94)
		assert_eq(joiner.attack, 3, "only Wick's after-join growth remains")
		assert_eq(_combat.unit_at(0, 0).attack, 1, "the leader never gets the bonus")
