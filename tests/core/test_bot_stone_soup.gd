extends GutTest
## Fixed recruit states for the approved Soup route, no-carry pin exception and plain pair value.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
const Kit := preload("res://tests/core/recruit_kit.gd")
const POLICIES: Array[String] = [
	"hard:oozes_waste_not",
	"hard:oozes_second_helpings",
	"line_oozes_engine",
	"line_oozes_tempo",
]
var kit: Kit
var player: PlayerState
var rules: RecruitRules


func before_each() -> void:
	kit = Kit.new()
	kit.setup(GameConfig.full_game())
	player = kit.player
	rules = kit.rules
	player.round_number = 6
	player.tier = 3
	player.gold = 20
	player.health = 40


func _brain(policy_name: String) -> BotBrain:
	var brain: BotBrain = (
		BenchSuites.create_bot(policy_name) as BotBrain
		if policy_name.begins_with("line_")
		else BotBrain.from_name(policy_name)
	)
	brain.value.strategy = brain.value.strategy.duplicate(true)
	rules.board_changed(player)
	brain._player = player
	brain._rules = rules
	brain._round_now = player.round_number
	brain.value.board_owner = player
	brain.value.recruit_rules = rules
	brain.value.library = rules.library
	return brain


func _supports() -> void:
	kit.put("mrs_posset", 0)
	kit.put("moss_ooze", 1)
	kit.put("wee_wobbly", 2)


func test_hard_and_both_lines_buy_dollop_before_soup_until_a_digest_carry_is_down() -> void:
	for policy: String in POLICIES:
		before_each()
		_supports()
		var dollop: RecruitUnit = kit.shop("little_dollop")
		var soup: RecruitUnit = kit.shop("stone_soup")
		var brain: BotBrain = _brain(policy)
		assert_null(BotOoze.carry(player))
		assert_gt(
			brain.value.buy_value(dollop, player), brain.value.buy_value(soup, player), policy
		)
		var normal_units: Dictionary = brain.value.strategy["units"]
		var expected_soup_weight: float = BotEval._number(normal_units.get("stone_soup", 0))
		kit.put("little_dollop", 3)
		rules.board_changed(player)
		assert_eq(BotOoze.priority_weight(soup.def, player, brain.value), expected_soup_weight)
		assert_gt(
			brain.value.buy_value(soup, player), brain.value.buy_value(dollop, player), policy
		)


func test_soup_twelve_point_commitment_bonus_requires_an_on_board_digest_carry() -> void:
	var large: RecruitUnit = kit.put("wee_wobbly", 0)
	large.add_permanent(100 - large.attack, 100 - large.health)
	var soup: RecruitUnit = kit.shop("stone_soup")
	var brain: BotBrain = _brain("hard:oozes_waste_not")
	var before: float = BotOoze.text_value(soup, player, brain.value)
	kit.put("little_dollop", 1)
	rules.board_changed(player)
	assert_eq(BotOoze.text_value(soup, player, brain.value), before + 12.0)


func test_hard_pin_allows_off_tribe_bodies_after_round_four_without_digest() -> void:
	_supports()
	var offer: RecruitUnit = kit.shop("little_nip")
	offer.add_permanent(30, 40)
	var brain: BotBrain = _brain("hard:oozes_waste_not")
	assert_true(brain.value.flexible_purchases(player, 6))
	assert_gt(brain._unit_gain(offer), 0.0)
	kit.put("little_dollop", 3)
	rules.board_changed(player)
	assert_false(brain.value.flexible_purchases(player, 6), "the special pin exception ends")
	assert_gt(brain._unit_gain(offer), 0.0, "a real Digest can still buy off-tribe food")


func test_committed_line_pin_exception_ends_when_digest_is_on_board() -> void:
	for policy: String in ["line_oozes_engine", "line_oozes_tempo"]:
		before_each()
		_supports()
		var offer: RecruitUnit = kit.shop("little_nip")
		offer.add_permanent(30, 40)
		var brain: CommittedLineBrain = _brain(policy) as CommittedLineBrain
		assert_true(brain._permits(offer), policy + " needs bodies before Digest")
		assert_gt(brain._unit_gain(offer), 0.0)
		kit.put("little_dollop", 3)
		rules.board_changed(player)
		assert_false(brain._permits(offer), policy + " restores its ordinary route pin")


func test_second_plain_soup_has_only_body_plus_pair_for_hard_and_lines() -> void:
	for policy: String in POLICIES:
		before_each()
		var carry: RecruitUnit = kit.put("little_dollop", 1)
		carry.add_permanent(50, 60)
		var keeper: RecruitUnit = kit.put("stone_soup", 4)
		var second: RecruitUnit = kit.shop("stone_soup")
		var brain: BotBrain = _brain(policy)
		var unit_weights: Dictionary = brain.value.strategy["units"]
		unit_weights["stone_soup"] = 999.0
		var tribe_weights: Dictionary = brain.value.strategy["tribes"]
		tribe_weights["Oozes"] = 888.0
		player.tribe_bonuses["Oozes"] = 100
		var body: float = second.attack + second.health
		assert_eq(brain.value.buy_value(second, player), body + BotEval.PAIR_BONUS, policy)
		assert_eq(brain.value.keep_value(second), body, "no duplicate engine/build inflation")
		assert_eq(BotOoze.text_value(second, player, brain.value), 0.0)
		assert_gt(brain.value.keep_value(keeper), float(keeper.attack + keeper.health))
		assert_false(brain._can_replace(keeper), policy + " retains the active Soup keeper")


func test_plain_pair_restriction_preserves_third_copy_and_golden_valuation() -> void:
	kit.put("little_dollop", 1)
	kit.put("stone_soup", 4)
	var second: RecruitUnit = kit.put("stone_soup", 5)
	var third: RecruitUnit = kit.shop("stone_soup")
	var brain: BotBrain = _brain("hard:oozes_waste_not")
	assert_gt(
		brain.value.buy_value(third, player),
		float(third.attack + third.health) + BotEval.PAIR_BONUS
	)
	assert_eq(brain.value.keep_value(second), float(second.attack + second.health))
	var golden: RecruitUnit = RecruitUnit.make(
		rules.library.get_unit("stone_soup"), rules.new_iid(), true
	)
	assert_gt(
		brain.value.buy_value(golden, player),
		float(golden.attack + golden.health) + BotEval.PAIR_BONUS
	)


func test_other_tribes_and_frozen_legacy_oozes_do_not_gain_the_no_digest_exception() -> void:
	_supports()
	var offer: RecruitUnit = kit.shop("little_nip")
	offer.add_permanent(30, 40)
	var birds: BotBrain = _brain("hard:birds_highway")
	assert_false(birds.value.flexible_purchases(player, 6))
	assert_eq(birds._unit_gain(offer), 0.0)
	var ooze: BotBrain = _brain("hard:oozes_waste_not")
	player.pass3_content = false
	assert_false(ooze.value.flexible_purchases(player, 6))

	# Wave 1's pool flag is on even when the Ooze definitions are frozen pass 2.
	player.pass3_content = true
	var archive: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_oozes_units.json")
	)
	var legacy := UnitLibrary.new()
	for card: Dictionary in archive["units"]:
		if str(card["id"]) == "stone_soup":
			assert_eq(legacy.register_unit(card), "")
	ooze.value.library = legacy
	assert_false(
		ooze.value.flexible_purchases(player, 6),
		"a shared pass 3 pool flag must not change frozen pass 2 Ooze decisions"
	)
