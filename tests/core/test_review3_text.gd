extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")


func test_acorn_reminder_uses_the_gold_each_item_actually_pays() -> void:
	var reminder: String = KeywordRules.text("Acorn")
	for card_id: String in ["acorn", "stash", "great_hoard"]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game())
		var card: Dictionary = kit.library.get_card(card_id)
		var before: int = kit.player.gold
		assert_eq(kit.cast(card_id), "")
		var paid: int = kit.player.gold - before
		assert_eq(paid, card["gold_value"])
		assert_string_contains(reminder, "%s %d" % [card["name"], paid])
		kit.rules.give_card(kit.player, card_id)
		assert_eq(kit.player.items[0].view()["keyword_text"][0]["text"], reminder)
	assert_false(reminder.contains("{"), "all placeholders resolve")


func test_shy_reminder_names_the_actual_normal_and_golden_gold() -> void:
	var reminder: String = KeywordRules.text("Shy")
	assert_string_contains(reminder, "2 gold")
	assert_string_contains(reminder, "Only a spell aimed at this")
	for golden: bool in [false, true]:
		var kit := Kit.new()
		kit.setup(GameConfig.full_game())
		kit.rules.start_phase(kit.player, 1)
		var hob: RecruitUnit = kit.put("hob_in_the_hearth", 0, golden)
		kit.rules.board_changed(kit.player)
		if golden:
			assert_string_contains(str(hob.view()["text"]), "Shy pays 4 gold")
		assert_eq(kit.cast("pinch_of_dust", 0), "")
		assert_null(kit.player.board[0])
		assert_eq(kit.player.gold_next_turn, 4 if golden else 2)
