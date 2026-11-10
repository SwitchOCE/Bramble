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
