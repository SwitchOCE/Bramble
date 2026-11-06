extends GutTest
## The slice's Hedgerow folk (docs/ideation/content/SLICE.md, hedgerow.md): each card's text.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const F1: int = 0
const F2: int = 1
const F3: int = 2
const F4: int = 3
const B1: int = 4
const B2: int = 5
const B3: int = 6

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)


func test_mrs_burdock_summons_a_kit_behind_this() -> void:
	_kit.play("mrs_burdock", F2)
	assert_eq(_player.board[B1].def_id(), "kit", "the first slot behind F2")


func test_mrs_burdock_golden_summons_two_kits() -> void:
	_kit.play("mrs_burdock", F2, true)
	assert_eq(_player.board[B1].def_id(), "kit")
	assert_eq(_player.board[B2].def_id(), "kit")
	assert_false(_player.board[B1].golden, "the Kits aren't golden")


func test_mrs_burdock_spills_when_there_is_no_room_behind() -> void:
	_kit.put("pill_bug", B1)
	_kit.play("mrs_burdock", F1)
	assert_eq(_kit.item_ids(), ["acorn"], "F1 has one slot behind it, and it's taken")


func test_mrs_sorrel_summons_a_shrewlet_behind_after_she_attacks() -> void:
	_kit.put("mrs_sorrel", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var summons: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "summon":
			summons.append(event["slot"])
	assert_has(summons, B1, "a Shrewlet behind F1")


func test_mrs_sorrel_spills_after_the_fight_when_full_behind() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("pill_bug", B1)
	_kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	assert_has(_kit.item_ids(), "acorn", "the Spill's Acorn comes home")


func test_mrs_sorrel_golden_summons_two_but_f1_has_one_slot_so_one_spills() -> void:
	_kit.put("mrs_sorrel", F1, true)
	_kit.fight_board({F1: {"def_id": "pill_bug", "attack": 0, "health": 3}})
	assert_has(_kit.item_ids(), "acorn", "two summons, one slot behind")


func test_alderman_dozey_eats_an_acorn_for_stats_and_no_gold() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", F1)
	_rules.give_card(_player, "acorn")
	_player.gold = 0
	assert_eq(_rules.play_item(_player, 0, F1), "")
	assert_eq(dozey.attack, 3)
	assert_eq(dozey.health, 6)
	assert_eq(_player.gold, 0, "no gold as well")


func test_alderman_dozey_eats_a_stash_for_five_golden_doubles() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", F1, true)
	_rules.give_card(_player, "stash")
	assert_eq(_rules.play_item(_player, 0, F1), "")
	assert_eq(dozey.attack, 4 + 10)
	assert_eq(dozey.health, 10 + 10)


func test_alderman_dozey_others_dont_eat() -> void:
	_kit.put("pill_bug", F1)
	_rules.give_card(_player, "acorn")
	assert_ne(_rules.play_item(_player, 0, F1), "", "refused")
	assert_eq(_player.items.size(), 1, "still held")


func test_alderman_dozey_doubles_after_3_turns_in_this_slot_once() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", F1)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(dozey.attack, 2, "not yet")
	_kit.pass_turn()
	assert_eq(dozey.attack, 4)
	assert_eq(dozey.health, 10)
	_kit.pass_turn()
	assert_eq(dozey.attack, 4, "once")


func test_alderman_dozey_a_move_restarts_the_count() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", F1)
	_kit.pass_turn()
	_kit.pass_turn()
	_rules.move_on_board(_player, F1, F2)
	_kit.pass_turn()
	assert_eq(dozey.attack, 2, "one turn in the new slot")
	assert_eq(dozey.turns_in_slot, 1)


func test_mr_crumb_passes_right_when_played_at_end_of_turn() -> void:
	_kit.put("pill_bug", B1)
	var last: RecruitUnit = _kit.put("pill_bug", F2)
	_kit.play("mr_crumb", F1)
	assert_eq(last.attack, 1, "it waits for End of Turn")
	_rules.end_phase(_player)
	assert_eq(last.attack, 2)
	assert_eq(last.health, 5)


func test_mr_crumb_sold_passes_from_the_slot_it_left() -> void:
	var crumb: RecruitUnit = _kit.put("mr_crumb", F1)
	var next: RecruitUnit = _kit.put("pill_bug", B1)
	assert_true(crumb != null)
	_rules.sell(_player, F1)
	_rules.end_phase(_player)
	assert_eq(next.attack, 2, "F1's Pass still travels")


func test_mr_crumb_golden_passes_plus_two() -> void:
	var next: RecruitUnit = _kit.put("pill_bug", B1)
	_kit.play("mr_crumb", F1, true)
	_rules.end_phase(_player)
	assert_eq(next.attack, 3)
	assert_eq(next.health, 6)


func test_sleeping_partner_gets_2_acorns_every_3_turns_in_this_slot() -> void:
	_kit.put("sleeping_partner", B1)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_kit.item_ids(), [])
	_kit.pass_turn()
	assert_eq(_kit.item_ids(), ["acorn", "acorn"])
	_kit.pass_turn()
	assert_eq(_kit.item_ids(), ["acorn", "acorn"], "not next turn")
	assert_eq(_player.board[B1].view()["turns_goal"], 3, "screens keep counting")


func test_sleeping_partner_golden_gets_4_which_combine() -> void:
	_kit.put("sleeping_partner", B1, true)
	for _turn: int in 3:
		_kit.pass_turn()
	assert_eq(_kit.item_ids(), ["stash", "acorn"], "four Acorns: three become a Stash")


func test_honorary_treasurer_grows_per_2_gold_of_held_acorns() -> void:
	var treasurer: RecruitUnit = _kit.put("honorary_treasurer", B1)
	assert_eq(treasurer.attack, 3)
	_rules.give_card(_player, "stash")
	assert_eq(treasurer.attack, 3 + 2, "5 gold is two lots of 2")
	assert_eq(treasurer.health, 5 + 2)
	_rules.play_item(_player, 0)
	assert_eq(treasurer.attack, 3, "spent, it falls back")


func test_honorary_treasurer_golden_doubles_and_fights_with_it() -> void:
	var treasurer: RecruitUnit = _kit.put("honorary_treasurer", B1, true)
	_rules.give_card(_player, "stash")
	assert_eq(treasurer.attack, 6 + 4)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var start: Dictionary = result["events"][0]
	assert_eq(start["boards"][0][B1]["attack"], 10, "the Larder goes into the fight")


func test_standing_committee_touching_units_get_attack() -> void:
	_kit.put("standing_committee", F1)
	_kit.put("pill_bug", B1)
	_kit.put("pill_bug", F3)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var after: Dictionary = {}
	for event: Dictionary in result["events"]:
		if event["type"] == "stats":
			after[event["target"]] = event["attack"]
	assert_eq(after.size(), 2, "F1 and B1 touch; F3 is cut off by the gap at F2")


func test_standing_committee_all_seven_touch_for_plus_three() -> void:
	_kit.put("standing_committee", F1)
	for slot: int in [F2, F3, F4, B1, B2, B3]:
		_kit.put("pill_bug", slot)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var raised: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "stats" and event["attack"] == 4:
			raised.append(event["target"])
	assert_eq(raised.size(), 6, "six Pill Bugs from 1 to 4")


func test_standing_committee_golden_doubles_both() -> void:
	var golden: Dictionary = _kit.library.get_unit("standing_committee")
	assert_string_contains(str(golden["golden_text"]), "+4")
	_kit.put("standing_committee", F1, true)
	_kit.put("pill_bug", B1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var raised: bool = false
	for event: Dictionary in result["events"]:
		raised = raised or (event["type"] == "stats" and event["attack"] == 5)
	assert_true(raised, "the Pill Bug goes from 1 to 5 at +4")


func test_old_mother_mast_golden_doubles() -> void:
	_kit.put("old_mother_mast", F1, true)
	_player.gold = 20
	_kit.shop("pill_bug")
	_rules.buy(_player, _player.shop.size() - 1)
	assert_eq(_kit.item_ids(), ["acorn", "acorn"])
