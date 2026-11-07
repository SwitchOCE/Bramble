extends GutTest
## Easy can refresh stale bodies without gaining Hard's replacement or valuation policy.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _player: PlayerState
var _brain: BotBrain


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_player.tier = 3
	_player.gold = 30
	var stale: RecruitUnit = _kit.put("field_vole", 0)
	stale.attack = 1
	stale.health = 2
	for slot: int in range(1, BoardGeometry.SLOTS):
		var unit: RecruitUnit = _kit.put("field_vole", slot)
		unit.add_permanent(100, 100)
		unit.plain_copy = true
	_brain = BotBrain.from_name("easy")
	_brain._player = _player
	_brain._rules = _kit.rules
	_brain.level.buy_noise = 0.0


func _candidate(attack: int, health: int) -> RecruitUnit:
	return RecruitUnit.make(
		{
			"id": "easy_replacement_probe",
			"name": "Probe",
			"tier": 1,
			"attack": attack,
			"health": health,
			"tribes": [],
			"mechanics": [],
			"keywords": [],
			"text": "",
			"golden_text": "",
			"pool": false
		},
		900
	)


func test_easy_replaces_an_improved_stale_body_once_only() -> void:
	var candidate: RecruitUnit = _candidate(2, 2)
	assert_gt(_brain._unit_gain(candidate), 0.0, "one point better may replace a stale body")
	assert_eq(_brain._clear_slot_for(candidate), 0)
	assert_eq(_brain._replacements, 1)
	_player.board[0] = candidate
	assert_eq(_brain._clear_slot_for(_candidate(3, 2)), -1, "still one replacement per turn")
	assert_eq(_brain._unit_gain(_candidate(3, 2)), 0.0)


func test_easy_requires_two_tiers_of_age_before_waiving_its_margin() -> void:
	_player.tier = 2
	var candidate: RecruitUnit = _candidate(2, 2)
	assert_eq(_brain._unit_gain(candidate), 0.0)
	assert_eq(_brain._clear_slot_for(candidate), -1)
	_player.tier = 3
	assert_gt(_brain._unit_gain(candidate), 0.0)


func test_noise_cannot_buy_a_stale_replacement_that_the_hand_cannot_play() -> void:
	_brain.level.buy_noise = 0.6
	var worse: RecruitUnit = _candidate(1, 1)
	for attempt: int in 30:
		_player.bot_rng.seed = attempt
		assert_eq(_brain._unit_gain(worse), 0.0)
	assert_eq(_brain._clear_slot_for(worse), -1)


func test_low_tier_buffed_giant_is_kept_when_the_new_unit_is_weaker() -> void:
	_player.board[0].add_permanent(30, 30)
	var candidate: RecruitUnit = _candidate(2, 2)
	assert_eq(_brain._unit_gain(candidate), 0.0)
	assert_eq(_brain._clear_slot_for(candidate), -1)
	assert_not_null(_player.board[0])


func test_normal_and_hard_still_require_their_ordinary_margin() -> void:
	for level_name: String in ["normal", "hard"]:
		var brain: BotBrain = BotBrain.from_name(level_name)
		brain._player = _player
		brain._rules = _kit.rules
		brain.level.buy_noise = 0.0
		var candidate: RecruitUnit = _candidate(2, 2)
		assert_lte(brain._unit_gain(candidate), 0.0)
		assert_eq(brain._clear_slot_for(candidate), -1)


func test_easy_counts_a_belly_clear_toward_its_one_replacement_budget() -> void:
	var ooze: RecruitUnit = _kit.put("wee_wobbly", 1)
	ooze.add_permanent(100, 100)
	assert_eq(_brain._clear_slot_for(_candidate(2, 2)), 0)
	assert_eq(ooze.held.size(), 1)
	assert_eq(_brain._replacements, 1)
