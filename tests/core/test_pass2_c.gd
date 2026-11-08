extends GutTest
@warning_ignore_start("unsafe_call_argument")

const K := preload("res://tests/core/recruit_kit.gd")
var _kit: K


func before_each() -> void:
	_kit = K.new()
	_kit.setup(GameConfig.full_game())
	_kit.rules.start_phase(_kit.player, 1)


func test_lob_grows_both_neighbours_but_never_another_shy_unit() -> void:
	var first: RecruitUnit = _kit.put("pill_bug", 0)
	_kit.put("lob_lie_by_the_fire", 1)
	var second: RecruitUnit = _kit.put("pill_bug", 2)
	_kit.rules.end_phase(_kit.player)
	assert_eq([first.attack, second.attack], [2, 2])
	_kit.player.board[2] = null
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 2)
	_kit.rules.end_phase(_kit.player)
	assert_eq(hob.attack, 1)
	assert_eq(_kit.player.board[2], hob)


func test_silky_rings_other_shy_departures_and_her_own_slot() -> void:
	_kit.put("hob_in_the_hearth", 0)
	_kit.put("silky", 4)
	assert_eq(_kit.cast("pinch_of_dust", 0), "")
	assert_eq(BoardUpkeep.ring_value(_kit.player.slot_effects[0]), Vector2i(2, 2))
	assert_eq(_kit.cast("pinch_of_dust", 4), "")
	assert_eq(BoardUpkeep.ring_value(_kit.player.slot_effects[4]), Vector2i(2, 2))
	assert_eq(_kit.player.gold_next_turn, 4)


func test_silky_golden_ring_is_capped_and_destruction_is_not_a_thank_you() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 0)
	_kit.put("silky", 4, true)
	_kit.rules.destroy_unit(_kit.player, hob)
	assert_eq(BoardUpkeep.ring_value(_kit.player.slot_effects[0]), Vector2i.ZERO)
	assert_eq(_kit.player.gold_next_turn, 0)
	BoardUpkeep.add_ring(_kit.player, 4, {"attack": 3, "health": 3})
	assert_eq(_kit.cast("pinch_of_dust", 4), "")
	assert_eq(BoardUpkeep.ring_value(_kit.player.slot_effects[4]), Vector2i(4, 4))
	assert_eq(_kit.player.gold_next_turn, 4)


func test_a_shortened_tern_trip_brings_home_cuckoo_delayed_and_newer_birds() -> void:
	_kit.put("cuckoo", 1)
	var jay: RecruitUnit = _fly("mrs_jay", 0)
	assert_eq(_kit.player.nest_at(0)["due"], 4)
	var tern: RecruitUnit = _fly("old_tern", 3, true)
	_kit.pass_turn()
	assert_true(_kit.player.hand.has(tern))
	assert_true(_kit.player.hand.has(jay))
	assert_true(_kit.player.away.is_empty())
	assert_eq(jay.played_round, 2)
	assert_true(_kit.player.pending.is_empty())


func test_golden_tern_sale_note_and_actual_flight_use_one_base_turn() -> void:
	const Held := preload("res://src/ui/screens/recruit_held.gd")
	var tern: RecruitUnit = _kit.put("old_tern", 0, true)
	assert_eq(tern.view()["fly_south"], 1)
	assert_string_contains(Held.sell_note(tern.view(), 1), "home in 1")
	assert_eq(_kit.rules.sell(_kit.player, 0), "")
	assert_eq(_kit.player.nest_at(0)["due"], 2)
	_kit.pass_turn()
	assert_true(_kit.player.hand.has(tern))


func test_cuckoo_extends_a_golden_terns_one_turn_base_flight() -> void:
	_kit.put("cuckoo", 1)
	var tern: RecruitUnit = _fly("old_tern", 0, true)
	assert_eq(tern.flight_turns(), 1)
	assert_eq(_kit.player.nest_at(0)["due"], 3)
	_kit.pass_turn()
	assert_false(_kit.player.hand.has(tern))
	_kit.pass_turn()
	assert_true(_kit.player.hand.has(tern))


func test_stork_never_returns_a_bird_flown_this_turn_and_ties_go_left() -> void:
	var right: RecruitUnit = _fly("mrs_jay", 2)
	var left: RecruitUnit = _fly("one_swallow", 0)
	_kit.put("mrs_stork", 4)
	_kit.player.gold = 20
	_kit.rules.spend(_kit.player, 6)
	assert_eq(_kit.player.away.size(), 2)
	assert_false(_kit.player.hand.has(left))
	_kit.pass_turn()
	_kit.player.gold = 20
	_kit.rules.spend(_kit.player, 6)
	assert_true(_kit.player.hand.has(left))
	assert_false(_kit.player.hand.has(right))


func test_lamp_moth_discount_stacks_and_cannot_make_tier_up_negative() -> void:
	var cost: int = _kit.rules.tier_up_cost(_kit.player)
	_kit.play("lamp_moth", 0)
	assert_eq(_kit.rules.tier_up_cost(_kit.player), maxi(0, cost - 1))
	_kit.play("lamp_moth", 1, true)
	assert_eq(_kit.rules.tier_up_cost(_kit.player), maxi(0, cost - 3))
	_kit.player.upgrade_cost = 0
	_kit.play("lamp_moth", 2)
	assert_eq(_kit.rules.tier_up_cost(_kit.player), 0)


func test_scout_tom_tit_without_redwing_keeps_egg_stats_and_hides_bird_details() -> void:
	for golden: bool in [false, true]:
		before_each()
		var bird: RecruitUnit = _fly("mrs_jay", 0)
		bird.add_permanent(2, 4)
		_kit.put("tom_tit", 5, golden)
		BoardUpkeep.add_ring(_kit.player, 0, {"attack": 2, "health": 2})
		_assert_scout_egg_matches_live(Vector2i(7 if golden else 5, 9))


func test_scout_tom_tit_support_includes_granted_and_borrowed_rules() -> void:
	for borrowed: bool in [false, true]:
		before_each()
		var bird: RecruitUnit = _fly("mrs_jay", 0)
		bird.add_permanent(2, 4)
		if borrowed:
			var tit: RecruitUnit = _kit.put("tom_tit", 5, true)
			var frumenty: RecruitUnit = _kit.put("frumenty", 4)
			frumenty.held.append(tit)
			_kit.player.board[5] = null
		else:
			var support: RecruitUnit = _kit.put("pill_bug", 5)
			support.grants.append(
				{"entry": {"id": "tom_tit", "full": 1}, "golden": true, "keyword": ""}
			)
		_assert_scout_egg_matches_live(Vector2i(5, 7))


func _assert_scout_egg_matches_live(expected: Vector2i) -> void:
	var live: Dictionary = _kit.fight_board({0: {"def_id": "pill_bug", "health": 99}})
	var live_egg: Dictionary = K.of_type(live, "combat_start")[0]["boards"][0][0]
	assert_eq(Vector2i(live_egg["attack"], live_egg["health"]), expected)
	_kit.player.remember_fought_board()
	var view: Dictionary = _kit.player.fought_view[0]
	assert_eq(Vector2i(view["attack"], view["health"]), expected)
	var spec: Dictionary = _kit.player.fought_specs[0]
	assert_eq(spec["egg_full_attack"], 5)
	assert_eq(spec["egg_full_health"], 7)
	for field: String in ["bird_attack", "bird_health", "turns_left", "due", "bird", "spec"]:
		assert_false(spec.has(field), field)
		assert_false(view.has(field), field)
	assert_eq(view["def_id"], HeldUnits.EGG)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var combat := Combat.create(_kit.library, _kit.config, rng)
	combat.slot_effects = [_kit.player.fought_slots, []]
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	var scout: Dictionary = combat.run(
		[_kit.player.fought_specs, K._board({0: {"def_id": "pill_bug", "health": 99}})],
		tiers,
		ids,
		0
	)
	var scout_egg: Dictionary = K.of_type(scout, "combat_start")[0]["boards"][0][0]
	assert_eq(Vector2i(scout_egg["attack"], scout_egg["health"]), expected)


func _fly(id: String, slot: int, golden: bool = false) -> RecruitUnit:
	var bird: RecruitUnit = _kit.put(id, slot, golden)
	assert_eq(_kit.rules.sell(_kit.player, slot), "")
	return bird
