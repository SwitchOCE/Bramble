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
