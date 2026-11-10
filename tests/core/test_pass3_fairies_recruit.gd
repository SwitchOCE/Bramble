extends GutTest
## Pass 3 recruit rules, with diagnostic counterexamples proving the shared clock/copy guards.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	var config: GameConfig = GameConfig.full_game()
	config.set_value("pass3_preset", "A")
	_kit.setup(config)
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)


func _count(slot: int) -> int:
	for ring: Dictionary in _player.slot_effects[slot]:
		if str(ring.get("name", "")) == BoardUpkeep.RING:
			return Pass3Fairies.ring_count(ring)
	return 0


func _ring(slot: int, count: int = 1) -> void:
	Pass3Fairies.add_ring(_player, slot, {"count": count})
	_rules.board_changed(_player)


func _rainbow(count: int = 1) -> void:
	for slot: int in BoardGeometry.SLOTS:
		_ring(slot, count)


func _tier_up() -> void:
	_player.gold = 100
	assert_eq(_rules.tier_up(_player), "")


func _end_turn() -> void:
	_rules.end_phase(_player)


func _next_turn() -> void:
	_kit.pass_turn()


func test_nan_adds_count_when_played_and_sold_and_ring_survives_the_sale() -> void:
	var nan: RecruitUnit = _kit.play("nan_toadstool", 4)
	assert_eq(_count(4), 1)
	assert_eq(nan.attack, 3)
	assert_eq(_rules.sell(_player, 4), "")
	assert_null(_player.board[4])
	assert_eq(_count(4), 2)


func test_golden_nan_and_ring_spell_counts_use_the_casters_current_size() -> void:
	_player.ring_size = 3.0
	var nan: RecruitUnit = _kit.play("nan_toadstool", 4, true)
	assert_eq(_count(4), 2)
	assert_eq(nan.attack, 10, "golden 4 plus 2 Rings of size 3")
	assert_eq(_kit.cast("spore_cloud", 5), "")
	assert_eq(_count(5), 2)
	assert_eq(BoardUpkeep.ring_value(_player.slot_effects[5]), Vector2i(6, 6))
	assert_eq(_kit.cast("boundary_stone", 5), "")
	assert_eq(_count(5), 5)
	assert_eq(BoardUpkeep.ring_value(_player.slot_effects[5]), Vector2i(15, 15))


func test_ring_size_fraction_is_retained_and_rounded_once_for_the_slot() -> void:
	_player.ring_size = 1.25
	_ring(0, 4)
	assert_eq(_count(0), 4)
	assert_eq(BoardUpkeep.ring_value(_player.slot_effects[0]), Vector2i(5, 5))
	_ring(0)
	assert_eq(BoardUpkeep.ring_value(_player.slot_effects[0]), Vector2i(7, 7))
	assert_eq(_player.ring_size, 1.25, "rounding never destroys the fractional size")


func test_new_rings_have_no_four_stat_cap_and_persist_through_movement() -> void:
	var nan: RecruitUnit = _kit.play("nan_toadstool", 0)
	_ring(0, 100)
	assert_eq(_count(0), 101)
	assert_eq(_rules.move(_player, 0, 1), "")
	assert_eq(_count(0), 101)
	assert_eq(nan.attack, 2, "the Ring stays on its slot")
	assert_eq(_kit.cast("spore_cloud", 0), "", "a full legacy Ring never blocks pass 3")
	assert_eq(_count(0), 103)


func test_chaser_counts_ringed_slots_including_empty_slots_and_golden_doubles_gold() -> void:
	_ring(0, 100)
	_ring(3)
	_ring(6)
	_kit.put("rainbow_chaser", 2, true)
	var before: int = _player.gold
	assert_eq(_rules.sell(_player, 2), "")
	assert_eq(_player.gold - before, 6, "created body has no ordinary sale gold")


func test_annis_rings_behind_at_end_of_turn_and_after_each_sale_but_not_her_own() -> void:
	_kit.put("old_moth_annis", 1)
	_kit.put("nan_toadstool", 0)
	_end_turn()
	assert_eq([_count(4), _count(5)], [1, 1])
	assert_eq(_rules.sell(_player, 0), "")
	assert_eq([_count(4), _count(5)], [2, 2])
	assert_eq(_rules.sell(_player, 1), "")
	assert_eq([_count(4), _count(5)], [2, 2], "a sold Annis no longer watches the sale")


func test_annis_sale_dial_and_golden_ring_count_are_data() -> void:
	_kit.config.set_value("fairies_annis_sale", false)
	_kit.put("old_moth_annis", 0, true)
	_kit.put("nan_toadstool", 1)
	assert_eq(_rules.sell(_player, 1), "")
	assert_eq(_count(4), 0)
	_kit.config.set_value("fairies_annis_rings", 3)
	_end_turn()
	assert_eq(_count(4), 6)


func test_sally_spreads_to_nearest_unringed_slot_and_golden_rings_twice() -> void:
	var card: Dictionary = _kit.library.get_unit("sally_spore")
	assert_eq(str(card["text"]), "End of Turn: Ring your nearest unringed slot.")
	assert_eq(str(card["golden_text"]), "End of Turn: Ring your nearest unringed slot twice.")
	_kit.put("sally_spore", 0, true)
	_kit.put("nan_toadstool", 1)
	_ring(0)
	_end_turn()
	assert_eq(_count(0), 1, "an existing Ring is skipped")
	assert_eq(_count(1), 2, "occupied F2 is the nearest unringed slot")
	for slot: int in [2, 3, 4, 5, 6]:
		assert_eq(_count(slot), 0)


func test_sally_completes_the_rainbow_on_a_full_board_then_stops() -> void:
	for slot: int in BoardGeometry.SLOTS:
		_kit.put("sally_spore" if slot == 0 else "chiffchaff", slot)
	for turn: int in BoardGeometry.SLOTS:
		_player.round_number = turn + 1
		_end_turn()
	for slot: int in BoardGeometry.SLOTS:
		assert_eq(_count(slot), 1)
	_player.round_number += 1
	_end_turn()
	for slot: int in BoardGeometry.SLOTS:
		assert_eq(_count(slot), 1, "a full rainbow adds no more Rings")


func test_cluricaun_requires_every_slot_and_grows_at_end_of_turn_even_at_tier_six() -> void:
	_kit.put("cluricaun", 0)
	for slot: int in 6:
		_ring(slot, 4)
	_end_turn()
	assert_eq(_player.ring_size, 1.0, "six Ringed slots do not qualify")
	_ring(6, 4)
	_tier_up()
	assert_eq(_player.ring_size, 1.0, "tier-up no longer fires growth")
	_end_turn()
	assert_eq(_player.ring_size, 2.0)
	assert_eq(BoardUpkeep.ring_value(_player.slot_effects[4]), Vector2i(8, 8))
	_player.tier = 6
	_kit.config.set_value("fairies_ring_growth", 0.75)
	_end_turn()
	assert_eq(_player.ring_size, 2.75, "T6 keeps the end-turn engine")


func test_cluricaun_copies_share_one_grow_and_strongest_copy_wins() -> void:
	_kit.put("cluricaun", 0)
	_kit.put("cluricaun", 1, true)
	_rainbow()
	_end_turn()
	assert_eq(_player.ring_size, 3.0, "one golden grow, rather than normal plus golden")


func test_cluricaun_copy_guard_counterexample_without_fix() -> void:
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.put("cluricaun", 0)
	_kit.put("cluricaun", 1, true)
	_rainbow()
	_end_turn()
	assert_eq(_player.ring_size, 4.0, "without the shared-copy guard both growers fire")


func test_golden_borrowed_growth_keeps_its_text_factor_on_a_normal_body() -> void:
	var borrower: RecruitUnit = _kit.put("chiffchaff", 0)
	(
		borrower
		. grants
		. append(
			{
				"entry": {"id": "pass3_fairy", "ability": "cluricaun", "factor": 1},
				"golden": true,
			}
		)
	)
	_kit.put("cluricaun", 1)
	_rainbow()
	_end_turn()
	assert_eq(_player.ring_size, 3.0, "the text's golden factor wins over the normal body")


func test_lob_banks_real_turns_through_moves_and_only_thanking_cashes_them() -> void:
	var lob: RecruitUnit = _kit.put("lob_lie_by_the_fire", 0)
	_next_turn()
	assert_eq(_rules.move(_player, 0, 1), "")
	_next_turn()
	assert_eq(_rules.move(_player, 1, 2), "")
	_next_turn()
	assert_eq(lob.counters["pass3_turns_stayed"], 3)
	assert_eq(_kit.cast("pinch_of_dust", 2), "")
	assert_null(_player.board[2])
	assert_eq(_player.ring_size, 2.0)
	assert_eq(_player.gold_next_turn, 2)


func test_lob_sale_never_counts_as_leaving() -> void:
	_kit.put("lob_lie_by_the_fire", 0)
	for _turn: int in 6:
		_next_turn()
	assert_eq(_rules.sell(_player, 0), "")
	assert_eq(_player.ring_size, 1.0)
	assert_eq(_player.gold_next_turn, 0)


func test_golden_lob_uses_data_period_and_growth_and_moving_never_erases_it() -> void:
	_kit.config.set_value("fairies_lob_turns", 2)
	_kit.config.set_value("fairies_lob_growth", 0.5)
	_kit.put("lob_lie_by_the_fire", 0, true)
	for _turn: int in 4:
		_next_turn()
	assert_eq(_kit.cast("pinch_of_dust", 0), "")
	assert_eq(_player.ring_size, 3.0)
	assert_eq(_player.gold_next_turn, 4)


func test_silky_shared_growth_counts_departure_once_and_includes_herself() -> void:
	_kit.put("silky", 0)
	_kit.put("silky", 1, true)
	_kit.put("hob_in_the_hearth", 2)
	assert_eq(_kit.cast("pinch_of_dust", 2), "")
	assert_eq(_player.ring_size, 3.0)
	assert_eq(_kit.cast("pinch_of_dust", 1), "")
	assert_eq(_player.ring_size, 5.0, "departing golden Silky still supplies the shared grow")
	assert_eq(_kit.cast("pinch_of_dust", 0), "")
	assert_eq(_player.ring_size, 6.0, "a departing lone Silky hears herself")


func test_silky_copy_guard_counterexample_without_fix() -> void:
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.put("silky", 0)
	_kit.put("silky", 1, true)
	_kit.put("hob_in_the_hearth", 2)
	assert_eq(_kit.cast("pinch_of_dust", 2), "")
	assert_eq(_player.ring_size, 4.0, "without the shared grow guard both Silkies pay out")


func test_shy_ignores_ring_stats_and_destroying_a_shy_unit_is_not_thanking() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 4)
	_kit.put("silky", 0)
	_ring(4, 100)
	assert_eq(Vector2i(hob.attack, hob.health), Vector2i(2, 5))
	_rules.destroy_unit(_player, hob)
	assert_eq(_player.gold_next_turn, 0)
	assert_eq(_player.ring_size, 1.0)


func test_monarch_copies_share_one_clock_and_golden_triples_once() -> void:
	_kit.put("fairy_monarch", 0)
	_kit.put("fairy_monarch", 1, true)
	_ring(4, 10)
	_next_turn()
	_next_turn()
	assert_eq(_player.ring_size, 1.0)
	_end_turn()
	assert_eq(_player.ring_size, 3.0)
	assert_eq(BoardUpkeep.ring_value(_player.slot_effects[4]), Vector2i(30, 30))


func test_monarch_copy_guard_counterexample_without_fix() -> void:
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.put("fairy_monarch", 0)
	_kit.put("fairy_monarch", 1, true)
	_next_turn()
	assert_eq(_player.owner_counters["pass3_midsummer"], 2)
	_next_turn()
	assert_eq(_player.ring_size, 2.0, "without a shared clock copies reach Midsummer early")


func _doubler() -> void:
	_kit.card("p3_end_doubler", [{"id": "end_turn_doubler"}])
	_kit.put("p3_end_doubler", 3)


func test_monarch_extra_triggers_never_move_the_clock_or_repeat_doubling() -> void:
	_kit.put("fairy_monarch", 0)
	_doubler()
	_next_turn()
	assert_eq(_player.owner_counters["pass3_midsummer"], 1)
	assert_eq(_player.ring_size, 1.0)
	_next_turn()
	_end_turn()
	assert_eq(_player.ring_size, 2.0, "third real turn doubles exactly once")
	assert_eq(_player.owner_counters["pass3_midsummer"], 0)


func test_monarch_countdown_guard_counterexample_without_fix() -> void:
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.put("fairy_monarch", 0)
	_doubler()
	_next_turn()
	assert_eq(_player.owner_counters["pass3_midsummer"], 2)
	_next_turn()
	assert_eq(_player.ring_size, 2.0, "without the guard it doubles a real turn early")
	assert_eq(_player.owner_counters["pass3_midsummer"], 1)


func test_monarch_doubling_guard_counterexample_without_fix() -> void:
	_kit.config.set_value("fairies_monarch_period", 1)
	_kit.put("fairy_monarch", 0)
	_doubler()
	_end_turn()
	assert_eq(_player.ring_size, 2.0)
	before_each()
	_kit.config.set_value("fairies_monarch_period", 1)
	_kit.config.set_value("pass3_loop_guards", false)
	_kit.put("fairy_monarch", 0)
	_doubler()
	_end_turn()
	assert_eq(_player.ring_size, 4.0, "without the guard the same turn doubles twice")


func test_queen_tithes_at_start_of_turn_and_the_empty_slots_can_be_refilled() -> void:
	_kit.put("queen_of_elfland", 1)
	_kit.put("hob_in_the_hearth", 4)
	_kit.put("nan_toadstool", 5)
	_kit.put("silky", 0)
	_end_turn()
	assert_not_null(_player.board[4], "End of Turn leaves the fighters in place")
	_rules.start_phase(_player, 2)
	assert_null(_player.board[4])
	assert_null(_player.board[5])
	assert_eq(_player.gold_next_turn, 0, "destroyed Hob is never thanked")
	assert_eq(_player.ring_size, 1.0, "Silky ignores destruction")
	for slot: int in BoardGeometry.SLOTS:
		assert_eq(_count(slot), 2)
	var refill: RecruitUnit = _kit.play("field_vole", 4)
	assert_eq(_player.board[4], refill, "recruiting stays open after the tithe")
	_end_turn()
	assert_eq(_player.board[4], refill, "the replacement survives into combat")


func test_golden_queen_uses_start_turn_period_and_end_turn_repeats_cannot_tick_it() -> void:
	_kit.config.set_value("fairies_queen_period", 2)
	_kit.config.set_value("fairies_queen_rings", 3)
	_kit.put("queen_of_elfland", 0, true)
	_kit.put("nan_toadstool", 4)
	_doubler()
	_rules.start_phase(_player, 2)
	assert_not_null(_player.board[4])
	_end_turn()
	assert_not_null(_player.board[4], "End of Turn repeats do not move the Start of Turn clock")
	_rules.start_phase(_player, 3)
	assert_null(_player.board[4])
	for slot: int in BoardGeometry.SLOTS:
		assert_eq(_count(slot), 6)


func test_queen_countdown_guard_counterexample_without_fix() -> void:
	_kit.config.set_value("fairies_queen_period", 2)
	var queen: RecruitUnit = _kit.put("queen_of_elfland", 0)
	_kit.put("nan_toadstool", 4)
	_rules.events.fire(_player, "start_of_turn")
	var ctx: RecruitContext = RecruitContext.make(_rules, _player, "start_of_turn", {})
	ctx.source = queen
	ctx.source_slot = 0
	ctx.params = {"ability": "queen", "factor": 1}
	ctx.repeat_index = 1
	Pass3Fairies.recruit_hook(ctx)
	assert_not_null(_player.board[4], "an extra trigger cannot advance the countdown")
	_kit.config.set_value("pass3_loop_guards", false)
	Pass3Fairies.recruit_hook(ctx)
	assert_null(_player.board[4], "without the guard the repeated start ticks a second turn")
	assert_eq(_count(4), 1)


func test_ring_metadata_is_copied_into_fight_snapshots() -> void:
	_player.ring_size = 2.25
	_ring(4, 12)
	_player.remember_fought_board()
	var snapshot: Array = _player.fought_slots
	var rings: Array = snapshot[4]
	assert_eq(rings[0]["count"], 12)
	assert_eq(rings[0]["ring_size"], 2.25)
	assert_eq(rings[0]["attack"], 27)
	_ring(4)
	assert_eq(rings[0]["count"], 12, "fights and ghosts keep independent Ring snapshots")


func _printed_and_borrowed_grower(ability: String, held_card: String) -> RecruitUnit:
	(
		_kit
		. card(
			"double_grower",
			[
				{"id": "pass3_fairy", "ability": ability, "factor": 1},
				{"id": "belly", "size": 1},
				{"id": "borrows_text"},
			],
			["Fairies"]
		)
	)
	var borrower: RecruitUnit = _kit.put("double_grower", 0)
	var inner := RecruitUnit.make(_kit.library.get_unit(held_card), _rules.new_iid())
	borrower.held.append(inner)
	assert_eq(borrower.borrowed_text().size(), 1, "the same grower is printed and truly borrowed")
	return borrower


func test_printed_and_borrowed_cluricaun_grows_once_per_end_of_turn() -> void:
	_kit.config.set_value("fairies_ring_growth", 1.0)
	_printed_and_borrowed_grower("cluricaun", "cluricaun")
	_rainbow()
	_end_turn()
	assert_eq(_player.ring_size, 2.0, "one +1 grow despite two matching entries on one source")
	_kit.config.set_value("pass3_loop_guards", false)
	_end_turn()
	assert_eq(_player.ring_size, 4.0, "without the event guard both matching entries grow")


func test_printed_and_borrowed_monarch_ticks_and_doubles_once() -> void:
	_printed_and_borrowed_grower("monarch", "fairy_monarch")
	_kit.config.set_value("fairies_monarch_period", 1)
	_end_turn()
	assert_eq(_player.ring_size, 2.0, "one Midsummer despite two matching entries on one source")
	_kit.config.set_value("pass3_loop_guards", false)
	_end_turn()
	assert_eq(_player.ring_size, 8.0, "without the event guard both matching entries double")
