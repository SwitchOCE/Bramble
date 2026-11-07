extends GutTest
@warning_ignore_start("unsafe_method_access", "unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")


func test_golden_changeling_fires_once_in_both_start_orders() -> void:
	for fight_seed: int in range(1, 21):
		var kit := Kit.new()
		kit.setup(GameConfig.full_game())
		kit.put("changeling", 0, true)
		kit.put("pill_bug", 1)
		var boards: Array = [
			kit.player.combat_board(),
			[
				{"def_id": "pill_bug", "golden": false, "attack": 2, "health": 40},
				null,
				null,
				null,
				null,
				null,
				null
			]
		]
		var rng := RandomNumberGenerator.new()
		rng.seed = fight_seed
		var combat: Combat = Combat.create(kit.library, kit.config, rng)
		var result: Dictionary = combat.run(boards, [4, 4], [0, 1], 0)
		var fired: int = 0
		var bonus: int = 0
		for event: Dictionary in result["events"]:
			if event["type"] == "trigger" and event["mechanic"] == "changeling":
				fired += 1
			if event["type"] == "stats" and event["attack_delta"] == 4:
				bonus += 1
		assert_eq(fired, 1, "Start of Combat once, seed %d" % fight_seed)
		assert_eq(bonus, 1, "exactly one +4/+4")


func test_stable_hand_handles_do_not_cash_an_item_after_a_buy() -> void:
	var state: Dictionary = {"hand": [], "hand_items": [{"iid": 56}]}
	assert_eq(PlayGame.hand_number(state, "@56"), 0)
	state["hand"].append({"iid": 99})
	assert_eq(PlayGame.hand_number(state, "@56"), 1)
	assert_eq(PlayGame.hand_number(state, "@99"), 0)
	state["hand_items"].clear()
	assert_eq(PlayGame.hand_number(state, "@56"), -1, "removed handles refuse")


func test_shy_walkout_is_explicit_and_keeps_its_gold() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var unit: RecruitUnit = kit.put("hob_in_the_hearth", 0)
	kit.rules.board_changed(kit.player)
	unit.add_permanent(1, 0)
	kit.rules.board_changed(kit.player)
	var found: bool = false
	for entry: Dictionary in kit.player.recruit_log:
		if entry["type"] == "walk_out":
			found = true
			assert_string_contains(RecruitView.event_note(entry), "walked out of F1")
	assert_true(found)


func test_keywords_and_nest_loss_are_explained() -> void:
	for word: String in ["Shy", "Mired", "Borrowed"]:
		assert_false(KeywordRules.text(word).is_empty())
	var note: String = RecruitView.event_note(
		{"type": "nest_replaced", "name": "Mother Goose", "slot": 1}
	)
	assert_string_contains(note, "stored strikes are lost")
	assert_string_contains(note, "still returns")
