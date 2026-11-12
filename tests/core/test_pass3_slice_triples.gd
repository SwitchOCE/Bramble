extends GutTest
## Fixed generated-Slice counterexamples: combine each fully buffed arrival immediately.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.player.round_number = 5
	kit.player.gold = 100


func test_generated_third_slice_triples_after_its_stats_are_applied() -> void:
	_engine()
	_slice(3, 5)
	_slice(7, 11)
	_start()
	assert_eq(kit.player.hand.size(), 1, "the generated third copy combines immediately")
	if kit.player.hand.size() != 1:
		return
	var golden: RecruitUnit = kit.player.hand[0]
	assert_eq(golden.def_id(), "slice")
	assert_true(golden.golden)
	assert_eq(Pass3Oozes.own_stats(golden), Vector2i(29, 35))
	assert_true(golden.from_triple)
	assert_true(golden.reward_pending)
	assert_false(golden.plain_copy)
	assert_eq(golden.origin, RecruitUnit.ORIGIN_CREATED)
	assert_eq(golden.pool_copies, 0)


func test_golden_first_slice_triple_frees_hand_room_for_its_second_slice() -> void:
	_engine(true)
	_slice(20, 20)
	_slice(20, 20)
	var hand_limit: int = kit.config.get_int("hand_limit")
	for _index: int in hand_limit - 3:
		kit.put("field_vole", -1, true)
	assert_eq(kit.player.hand.size(), hand_limit - 1)
	_start()
	assert_eq(
		kit.player.hand.size(), hand_limit - 1, "the first copy's triple makes room for the second"
	)
	assert_eq(_slice_cards(), 2, "both golden-source arrivals are generated")
	var golden_count: int = 0
	var normal_count: int = 0
	for unit: RecruitUnit in kit.player.hand:
		if unit.def_id() != "slice":
			continue
		if unit.golden:
			golden_count += 1
			assert_eq(Pass3Oozes.own_stats(unit), Vector2i(59, 59))
		else:
			normal_count += 1
			assert_eq(Pass3Oozes.own_stats(unit), Vector2i(20, 20))
	assert_eq(golden_count, 1)
	assert_eq(normal_count, 1)
	kit.put("field_vole", -1, true)
	_start()
	assert_eq(
		kit.player.hand.size(), hand_limit, "a hand already full still loses generated Slices"
	)
	assert_eq(_slice_cards(), 2)


func test_generated_slice_triple_includes_a_copy_inside_a_belly() -> void:
	_engine()
	var holder: RecruitUnit = kit.put("mrs_posset", 0)
	_slice(3, 5)
	var held: RecruitUnit = _slice(7, 11)
	kit.player.hand.erase(held)
	holder.held.append(held)
	_start()
	assert_true(holder.held.is_empty(), "the triple removes its copy from the non-Digest Belly")
	assert_eq(kit.player.hand.size(), 1)
	if kit.player.hand.size() != 1:
		return
	var golden: RecruitUnit = kit.player.hand[0]
	assert_eq(golden.def_id(), "slice")
	assert_true(golden.golden)
	assert_eq(Pass3Oozes.own_stats(golden), Vector2i(29, 35))
	assert_true(golden.reward_pending)


func _engine(golden: bool = false) -> void:
	var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
	carry.add_permanent(97, 96)
	kit.put("cut_and_come_again", 6, golden)


func _slice(attack: int, health: int) -> RecruitUnit:
	var unit: RecruitUnit = kit.put("slice")
	unit.add_permanent(attack - unit.base_attack_now(), health - unit.base_health_now())
	return unit


func _start() -> void:
	kit.rules.board_changed(kit.player)
	Pass3Oozes.start_turn(kit.rules, kit.player, false)


func _slice_cards() -> int:
	var count: int = 0
	for event: Dictionary in kit.player.recruit_log:
		if str(event.get("type", "")) == "card" and str(event.get("card", "")) == "slice":
			count += 1
	return count
