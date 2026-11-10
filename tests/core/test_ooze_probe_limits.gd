extends GutTest

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func test_overbuff_portions_and_own_stats_respect_the_existing_stat_maximum() -> void:
	var dollop: RecruitUnit = kit.put("little_dollop", 0)
	dollop.add_permanent(4000000000, 4000000000)
	assert_eq(Pass3Oozes.own_stats(dollop), Vector2i(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP))
	assert_eq(
		Pass3Oozes._portion(Vector2i(900000000, 900000000), 6.4),
		Vector2i(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP)
	)


func test_overbuff_golden_soup_sums_six_capped_bodies_without_vector_overflow() -> void:
	kit.player.pass3_rates["oozes_golden_soup_reads"] = 6
	kit.player.pass3_rates["oozes_soup_share"] = 0.9
	kit.put("stone_soup", 0, true)
	for slot: int in range(1, 7):
		var dollop: RecruitUnit = kit.put("little_dollop", slot)
		dollop.add_permanent(900000000, 900000000)
	assert_eq(
		Pass3Oozes.soup_bonus(kit.player), Vector2i(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP)
	)


func test_generated_capped_slices_triple_and_digest_without_vector_overflow() -> void:
	kit.player.pass3_rates["oozes_slice_share"] = 1.0
	kit.player.pass3_rates["oozes_slice_count"] = 3
	var carry: RecruitUnit = kit.put("bubble_and_squeak", 0)
	carry.add_permanent(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP)
	kit.put("aunt_aspic", 4)
	kit.put("cut_and_come_again", 5)
	Pass3Oozes.start_turn(kit.rules, kit.player, false)
	assert_eq(kit.player.hand.size(), 1, "three generated Slices form one golden")
	var slice: RecruitUnit = kit.player.hand.pop_back()
	assert_eq(slice.def_id(), "slice")
	assert_true(slice.golden)
	assert_true(slice.from_triple)
	assert_gt(slice.perm_attack, 2147483647, "the combined permanent layer exceeds Vector2i")
	assert_eq(Pass3Oozes.own_stats(slice), Vector2i(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP))
	var attack: int = carry.perm_attack
	var health: int = carry.perm_health
	Pass3Oozes.eat(kit.rules, kit.player, carry, slice)
	assert_eq(carry.perm_attack - attack, BoardUnit.STAT_CLAMP, "Aspic-scaled Slice gain is capped")
	assert_eq(carry.perm_health - health, BoardUnit.STAT_CLAMP)
