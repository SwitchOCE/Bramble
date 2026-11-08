extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")


func test_supported_egg_preview_matches_combat_and_changes_when_redwing_flies() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	kit.rules.start_phase(kit.player, 1)
	var bird: RecruitUnit = kit.put("mrs_jay", 0)
	bird.attack = 7
	bird.health = 9
	bird.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(kit.rules.sell(kit.player, 0), "")
	var redwing: RecruitUnit = kit.put("redwing", 1, true)
	kit.player.slot_effects[0] = [{"name": "Ring", "attack": 3, "health": 5}]
	var marks: Array = RecruitView.slot_marks(
		{"away": HeldUnits.away_views(kit.player), "slot_effects": kit.player.combat_slots()}
	)
	assert_eq(marks[0]["egg_attack"], 12)
	assert_eq(marks[0]["egg_health"], 16)
	var fight: Dictionary = kit.fight_board({0: {"def_id": "pill_bug", "attack": 0, "health": 99}})
	var egg: Dictionary = KIT.of_type(fight, "combat_start")[0]["boards"][0][0]
	assert_eq(marks[0]["egg_attack"], egg["attack"])
	assert_eq(marks[0]["egg_health"], egg["health"])
	redwing.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(kit.rules.sell(kit.player, 1), "")
	marks = RecruitView.slot_marks(
		{"away": HeldUnits.away_views(kit.player), "slot_effects": kit.player.combat_slots()}
	)
	assert_eq(marks[0]["egg_attack"], 7, "half 4 plus Ring 3")
	assert_eq(marks[0]["egg_health"], 10, "half 5 plus Ring 5")
