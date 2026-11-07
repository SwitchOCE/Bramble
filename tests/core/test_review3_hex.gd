extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")


func test_board_and_cli_hex_match_the_fight_before_and_after_every_spell() -> void:
	for golden: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game())
		var witch: RecruitUnit = kit.put("hedge_witch", 0, golden)
		for spells: int in 12:
			var view: Dictionary = witch.view()
			var expected: int = mini((spells + 1) * (2 if golden else 1), 16 if golden else 8)
			assert_eq(view["hex_amount"], expected)
			assert_eq(RecruitView.tile_slip(view), "Hex %d" % expected)
			assert_eq(PlayView._hex_mark(view), " [Hex %d]" % expected)
			assert_string_contains(PlayView._unit_marks(view), "Hex %d" % expected)
			var result: Dictionary = kit.fight_board({0: {"def_id": "pill_bug", "health": 50}})
			for event: Dictionary in result["events"]:
				if event["type"] == "slot_hex":
					assert_eq(event["amount"], expected, "printed base plus growth, capped")
			assert_eq(kit.cast("pinch_of_dust", 0), "")
