extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")


func test_board_and_cli_hex_match_the_fight_before_and_after_every_spell() -> void:
	for golden: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game(), true)
		var witch: RecruitUnit = kit.put("hedge_witch", 0, golden)
		for spells: int in 12:
			var view: Dictionary = witch.view()
			var expected: int = mini(
				(spells + 1) * (2 if golden else 1), kit.player.tier + (2 if golden else 0)
			)
			assert_eq(view["hex_amount"], expected)
			assert_string_contains(RecruitView.tile_slip(view), "Hex %d" % expected)
			assert_eq(view["hex_stored"], (spells + 1) * (2 if golden else 1))
			assert_string_contains(PlayView._hex_mark(view), "Hex %d" % expected)
			assert_string_contains(PlayView._unit_marks(view), "Hex %d" % expected)
			if int(view["hex_stored"]) > expected:
				assert_string_contains(
					PlayView._hex_mark(view), "%d stored" % int(view["hex_stored"])
				)
			var result: Dictionary = kit.fight_board({0: {"def_id": "pill_bug", "health": 50}})
			for event: Dictionary in result["events"]:
				if event["type"] == "slot_hex":
					assert_eq(event["amount"], expected, "printed base plus growth, capped")
			assert_eq(kit.cast("pinch_of_dust", 0), "")


func test_borrowed_and_granted_hex_display_matches_combat() -> void:
	for golden: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game(), true)
		var ooze: RecruitUnit = kit.put("frumenty", 0)
		kit.put("hedge_witch", -1, golden)
		assert_eq(kit.rules.swallow(kit.player, HeldUnits.HAND, 0, 0), "")
		assert_eq(kit.cast("pinch_of_dust", 0), "")
		var expected: int = 3 if golden else 1
		assert_eq(ooze.view()["hex_amount"], expected)
		assert_string_contains(RecruitView.tile_slip(ooze.view()), "Hex %d" % expected)
		var result: Dictionary = kit.fight_board({0: {"def_id": "pill_bug", "health": 50}})
		for event: Dictionary in result["events"]:
			if event["type"] == "slot_hex":
				assert_eq(event["amount"], expected)
	var grant_kit := Kit.new()
	grant_kit.setup(GameConfig.full_game(), true)
	var granted: RecruitUnit = grant_kit.put("field_vole", 0)
	granted.grants.append({"entry": {"id": "hex", "n": 1, "most": 8}})
	assert_eq(grant_kit.cast("pinch_of_dust", 0), "")
	assert_eq(granted.view()["hex_amount"], 2)
	var grant_result: Dictionary = grant_kit.fight_board({0: {"def_id": "pill_bug", "health": 50}})
	for event: Dictionary in grant_result["events"]:
		if event["type"] == "slot_hex":
			assert_eq(event["amount"], 2)
