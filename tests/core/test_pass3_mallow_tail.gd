extends GutTest

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func test_lone_mallow_never_feeds_itself_or_a_foreign_body() -> void:
	for golden: bool in [false, true]:
		kit.player.board.fill(null)
		var mallow: RecruitUnit = kit.put("mrs_mallow", 0, golden)
		var foreign: RecruitUnit = kit.put("little_dollop", 4)
		kit.rules.end_phase(kit.player)
		assert_eq(mallow.perm_attack, 0)
		assert_eq(mallow.perm_health, 0)
		assert_eq(foreign.perm_attack, 0)
		assert_eq(foreign.perm_health, 0)
		assert_string_contains(
			str(mallow.def["golden_text" if golden else "text"]), "other Hedgerow"
		)


func test_two_mallows_feed_each_other_once_not_themselves_twice() -> void:
	var first: RecruitUnit = kit.put("mrs_mallow", 0)
	var second: RecruitUnit = kit.put("mrs_mallow", 1)
	for round_number: int in [1, 2]:
		kit.player.round_number = round_number
		kit.rules.end_phase(kit.player)
		for mallow: RecruitUnit in [first, second]:
			assert_eq(mallow.attack, 6 if round_number == 1 else 18)
			assert_eq(mallow.health, 15 if round_number == 1 else 45)
