extends GutTest
@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")
const Candidate := preload("res://tools/sim/committed_line_brain.gd")
const PROFILES: String = "res://tools/sim/line_profiles.committed.json"
var _kit: Kit
var _brain: Candidate


func before_each() -> void:
	BenchSuites.reload_lines(PROFILES)
	_kit = Kit.new()
	_kit.setup(GameConfig.full_game())
	_kit.player.gold = 10
	_kit.player.health = 40
	_kit.player.round_number = 5
	_brain = BenchSuites.create_bot("line_hunters_engine") as Candidate
	_brain._player = _kit.player
	_brain._rules = _kit.rules
	_brain._round_now = 5
	_brain.value.board_owner = _kit.player
	_brain.value.library = _kit.library
	_brain.value.recruit_rules = _kit.rules


func after_each() -> void:
	_brain.value.board_owner = null
	_brain.value.recruit_rules = null
	_brain._player = null
	_brain._rules = null
	BenchSuites.reload_lines(LinePolicies.DEFAULT_PATH)


func _fill(from_slot: int, attack: int = 10, health: int = 10) -> void:
	for slot: int in range(from_slot, BoardGeometry.SLOTS):
		var id: String = _kit.card("line_filler_%d" % slot, [], ["Hunters"], attack, health)
		_kit.put(id, slot)


func test_priorities_add_to_hard_knowledge_without_mutating_it() -> void:
	var known: Dictionary = BotKnowledge.shared().strategy("hunters_pact")
	var units: Dictionary = known["units"]
	var before: String = JSON.stringify(known)
	var own: Dictionary = _brain.value.strategy["units"]
	assert_gt(BotEval._number(own["grizel"]), BotEval._number(units["grizel"]))
	var original: float = BotEval._number(own["grizel"])
	_brain.configure_line("line_hunters_engine")
	own = _brain.value.strategy["units"]
	assert_eq(BotEval._number(own["grizel"]), original, "configuration does not accumulate priors")
	assert_eq(JSON.stringify(known), before)


func test_committed_buy_rejects_an_unlisted_off_tribe_body() -> void:
	_kit.put("wick", 0)
	_kit.put("sable", 1)
	_kit.put("brother_wolf", 2)
	var off: RecruitUnit = _kit.shop("squire_lollop")
	assert_eq(_brain._unit_gain(off), 0.0, "the hunter line cannot become a Lollop line")
	assert_true(_brain._permits(_kit.shop("grizel")))
	_brain._round_now = 2
	assert_true(_brain._permits(off), "early legal tempo fillers remain available")


func test_one_engine_copy_survives_carrier_retirement_but_duplicates_can_upgrade() -> void:
	var wolf: RecruitUnit = _kit.put("brother_wolf", 0)
	wolf.attack = 1
	wolf.health = 1
	_fill(1, 100, 100)
	var incoming: RecruitUnit = _kit.shop("laird_of_sett")
	assert_true(_brain._protected(wolf))
	assert_ne(_brain._weakest_slot(), 0)
	assert_ne(_brain._clear_slot_for(incoming), 0)
	assert_same(_kit.player.board[0], wolf, "a new high-tier body cannot sell the only pack engine")
	var stronger: RecruitUnit = _kit.put("brother_wolf", 1, true)
	assert_true(_brain._protected(stronger))
	assert_false(_brain._protected(wolf), "the weaker duplicate is no longer indispensable")


func _custom_line_engine() -> RecruitUnit:
	var id: String = _kit.card("line_only_engine", [], ["Hunters"], 1, 1)
	var engine: RecruitUnit = _kit.put(id, 0)
	_brain.profile["engine_pieces"] = [id]
	_fill(1, 100, 100)
	assert_false(BotPass3.keep_engine(_kit.player, engine, _brain.value))
	assert_true(_brain._protected(engine), "only the committed line protects this body")
	return engine


func test_ordinary_clear_slot_respects_line_only_engine_protection() -> void:
	var engine: RecruitUnit = _custom_line_engine()
	var id: String = _kit.card("line_large_replacement", [], ["Hunters"], 1000, 1000)
	var incoming: RecruitUnit = _kit.shop(id)
	assert_ne(_brain._best_replacement_slot(incoming), 0)
	assert_gt(_brain._clear_slot_for(incoming), 0, "replace an eligible filler instead")
	assert_same(_kit.player.board[0], engine)


func test_carrier_clear_slot_respects_line_only_engine_protection() -> void:
	var engine: RecruitUnit = _custom_line_engine()
	var incoming: RecruitUnit = _kit.shop("standing_committee")
	assert_true(BotCarrier.upgrade_plan(_brain, incoming).is_empty())
	assert_eq(_brain._clear_slot_for(incoming), -1, "no eligible body is worth retiring")
	assert_same(_kit.player.board[0], engine)


func test_affordable_climb_can_precede_the_written_schedule() -> void:
	_fill(0)
	_kit.player.tier = 2
	_kit.player.upgrade_cost = 2
	assert_eq(_brain._target_round(2), 6)
	_brain._climb(false)
	assert_eq(_kit.player.tier, 3, "round five can climb when there is also money for a body")


func test_climb_does_not_spend_money_that_is_not_available() -> void:
	_fill(0)
	_kit.player.tier = 2
	_kit.player.upgrade_cost = 7
	_kit.player.gold = 1
	_brain._climb(false)
	_brain._climb(true)
	assert_eq(_kit.player.tier, 2)
	assert_eq(_kit.player.gold, 1)


func test_low_health_does_not_all_in_on_a_scheduled_climb() -> void:
	_fill(0)
	_kit.player.tier = 2
	_kit.player.upgrade_cost = 7
	_kit.player.gold = 7
	_kit.player.health = 5
	_brain._round_now = 6
	_brain._climb(false)
	assert_eq(_kit.player.tier, 2)
	assert_eq(_kit.player.gold, 7, "keep a recruit-phase response available when near death")


func test_version_one_profiles_still_create_the_frozen_brain() -> void:
	BenchSuites.reload_lines("res://tools/sim/evidence/line_profiles.v1.json")
	var frozen: Bot = BenchSuites.create_bot("line_fast")
	assert_true(frozen is LineBrain)
	assert_false(frozen is Candidate)
