extends GutTest

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func test_capped_mallow_reads_own_stats_before_narrowing_to_vector() -> void:
	var mallow: RecruitUnit = kit.put("mrs_mallow", 0)
	mallow.add_permanent(2400000000, 2400000000)
	assert_eq(mallow.attack, BoardUnit.STAT_CLAMP)
	assert_eq(Pass3Hedgerow.own_stats(mallow), Vector2i(BoardUnit.STAT_CLAMP, BoardUnit.STAT_CLAMP))
	var before: int = mallow.perm_attack
	var ctx: RecruitContext = RecruitContext.make(kit.rules, kit.player, "end_of_turn", {})
	ctx.source = mallow
	Pass3Hedgerow._multiply(ctx, mallow, 3.0)
	assert_eq(
		mallow.perm_attack - before, 2000000000, "triple the capped own stats without wrapping"
	)
	assert_eq(mallow.attack, BoardUnit.STAT_CLAMP)
	assert_eq(mallow.health, BoardUnit.STAT_CLAMP)
