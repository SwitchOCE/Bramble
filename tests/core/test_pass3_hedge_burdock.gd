extends GutTest
## Live pass 3 golden Burdock uses two plain summons, with one Spill per denied attempt.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func test_live_golden_burdock_summons_two_plain_one_one_kits_behind_f2() -> void:
	var burdock: RecruitUnit = kit.play("mrs_burdock", 1, true)
	assert_true(Pass3Hedgerow.has(burdock, "mrs_burdock"), "use the live native definition")
	assert_eq([burdock.attack, burdock.health], [2, 4])
	for slot: int in [4, 5]:
		var token: RecruitUnit = kit.player.board[slot]
		assert_not_null(token)
		assert_eq(token.def_id(), "kit")
		assert_eq([token.attack, token.health], [1, 1])
		assert_false(token.golden)
	assert_eq(kit.item_ids(), [])


func test_live_golden_burdock_at_f1_summons_one_kit_and_spills_the_second_attempt() -> void:
	kit.play("mrs_burdock", 0, true)
	assert_eq(kit.player.board[4].def_id(), "kit")
	assert_eq([kit.player.board[4].attack, kit.player.board[4].health], [1, 1])
	assert_false(kit.player.board[4].golden)
	assert_eq(kit.item_ids(), ["acorn"])


func test_live_golden_burdock_in_back_row_spills_both_attempts() -> void:
	var burdock: RecruitUnit = kit.play("mrs_burdock", 4, true)
	assert_true(Pass3Hedgerow.has(burdock, "mrs_burdock"))
	assert_eq(kit.player.occupied().count(true), 1)
	assert_eq(kit.item_ids(), ["acorn", "acorn"])
