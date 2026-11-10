extends GutTest

const ORIGINAL_B := preload("res://tests/core/pass3_original_b.gd")
## Dial regressions use the production BotEval and food action paths.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT


func _setup(t: float) -> void:
	var config := GameConfig.full_game()
	var path: Dictionary = ORIGINAL_B.path(t)
	for key: String in path:
		config.set_value(key, path[key])
	_kit = KIT.new()
	_kit.setup(config)
	_kit.player.round_number = 9
	_kit.player.gold = 10


func _brain(strategy: String = "birds_passage") -> BotBrain:
	_kit.rules.board_changed(_kit.player)
	var brain := BotBrain.from_name("hard:" + strategy)
	brain._player = _kit.player
	brain._rules = _kit.rules
	brain._round_now = 9
	brain.value.recruit_rules = _kit.rules
	brain.value.board_owner = _kit.player
	brain.value.library = _kit.library
	brain.value.strategy.erase("fly")
	brain.value.strategy.erase("spells")
	return brain


func test_chiffchaff_keep_and_fly_values_read_its_printed_play_gain() -> void:
	for row: Array in [[0.0, 2.0, 2.0, 4.0], [3.0, 128.0, 128.0, 256.0]]:
		_setup(row[0])
		var bird: RecruitUnit = _kit.put("chiffchaff", 0)
		var brain: BotBrain = _brain()
		assert_eq(BotPass3.text_value(bird, _kit.player, brain.value), row[1])
		assert_eq(brain.value.fly_value(bird), row[2])
		bird.set_base(bird.def, true)
		assert_eq(BotPass3.text_value(bird, _kit.player, brain.value), row[1] * 2.0)
		assert_eq(brain.value.fly_value(bird), row[3])


func test_omitted_optional_gain_uses_authored_one_and_explicit_zero_stays_zero() -> void:
	var config := GameConfig.full_game()
	config.set_value("pass3_preset", "A")
	_kit = KIT.new()
	_kit.setup(config)
	var bird: RecruitUnit = _kit.put("chiffchaff", 0)
	var brain: BotBrain = _brain()
	assert_eq(brain.value.fly_value(bird), 2.0, "A omits the dial and keeps authored +1/+1")
	assert_eq(BotPass3.text_value(bird, _kit.player, brain.value), 2.0)
	config.set_value("birds_chiffchaff_gain", 0)
	assert_eq(brain.value.fly_value(bird), 0.0, "an explicit zero is a real override")
	assert_eq(BotPass3.text_value(bird, _kit.player, brain.value), 0.0)


func test_stork_value_reads_spending_step_for_both_twins() -> void:
	for row: Array in [[0.0, 12.0], [3.0, 18.0]]:
		_setup(row[0])
		for golden: bool in [false, true]:
			var stork: RecruitUnit = _kit.put("mrs_stork", 0, golden)
			var brain: BotBrain = _brain()
			assert_eq(
				BotPass3.text_value(stork, _kit.player, brain.value), row[1] * stork.golden_factor()
			)


func test_monarch_values_actual_ring_size_gain_and_each_twins_own_dial() -> void:
	_setup(0.0)
	BoardUpkeep.add_ring(_kit.player, 0, {"attack": 1, "health": 1})
	var monarch: RecruitUnit = _kit.put("fairy_monarch", 4)
	var brain: BotBrain = _brain("fairies_rings")
	assert_eq(BotPass3.text_value(monarch, _kit.player, brain.value), 8.0)
	monarch.set_base(monarch.def, true)
	assert_eq(BotPass3.text_value(monarch, _kit.player, brain.value), 12.0)
	_kit.config.set_value("fairies_golden_monarch_multiplier", 6.0)
	assert_eq(BotPass3.text_value(monarch, _kit.player, brain.value), 20.0)
	monarch.set_base(monarch.def, false)
	_kit.config.set_value("fairies_monarch_multiplier", 5.0)
	assert_eq(BotPass3.text_value(monarch, _kit.player, brain.value), 16.0)


func test_egg_values_real_gain_on_legal_birds_and_zero_without_a_target() -> void:
	for row: Array in [[0.0, 20.0], [3.0, 120.0]]:
		_setup(row[0])
		var bird: RecruitUnit = _kit.put("chiffchaff", 0)
		bird.add_permanent(10 - bird.base_attack_now(), 10 - bird.base_health_now())
		var neutral: RecruitUnit = _kit.put("pill_bug", 1)
		neutral.add_permanent(1000, 1000)
		var brain: BotBrain = _brain()
		var egg: Dictionary = _kit.library.get_card("golden_egg")
		assert_eq(brain.value.spell_value(egg, 10, _kit.player), row[1])
		bird.counters["egged"] = true
		assert_eq(brain.value.spell_value(egg, 10, _kit.player), 0.0)


func _food_setup(multiplier: int) -> BotBrain:
	_setup(0.0)
	_kit.config.set_value("oozes_eat_printed_multiplier", multiplier)
	_kit.put("little_dollop", 1)
	_kit.put("moss_ooze", 4)
	_kit.put("mrs_posset", 5)
	_kit.card("a35_buffed_food", [], [], 1, 1)
	_kit.card("a35_printed_food", [], [], 4, 4)
	return _brain("oozes_waste_not")


func test_feed_prefers_actual_printed_return_over_a_larger_buffed_body() -> void:
	for multiplier: int in [1, 2, 7]:
		var brain: BotBrain = _food_setup(multiplier)
		var buffed: RecruitUnit = _kit.shop("a35_buffed_food")
		buffed.add_permanent(4, 4)
		var printed: RecruitUnit = _kit.shop("a35_printed_food")
		# One affordable meal makes the choice observable through the real swallow action.
		_kit.player.gold = 2
		BotOoze.feed(brain)
		var eater: RecruitUnit = _kit.player.board[1]
		assert_eq(eater.held.size(), 1)
		assert_same(eater.held[0], buffed if multiplier == 1 else printed)


func test_slice_hand_and_belly_choices_use_the_same_live_food_return() -> void:
	for multiplier: int in [1, 2, 7]:
		var brain: BotBrain = _food_setup(multiplier)
		var slice: RecruitUnit = _kit.put("slice")
		slice.add_permanent(4, 4)
		_kit.shop("a35_printed_food")
		var expected: int = 1 if multiplier == 1 else -1
		assert_eq(BotOoze.hand_belly(brain, slice), expected)
		assert_eq(BotOoze.best_belly(_kit.player, brain.value, slice), expected)


func test_mallow_values_its_live_multiplier_on_normal_and_golden_targets() -> void:
	for row: Array in [[0.0, 40.0], [3.0, 240.0]]:
		for golden: bool in [false, true]:
			_setup(row[0])
			_kit.card("dial_runt", [], ["Hedgerow folk"], 5, 5)
			for slot: int in [0, 1, 2, 4]:
				_kit.put("dial_runt", slot)
			var mallow: RecruitUnit = _kit.put("mrs_mallow", 6, golden)
			mallow.add_permanent(50, 50)
			var brain: BotBrain = _brain("hedgerow_parish")
			assert_eq(
				BotPass3.text_value(mallow, _kit.player, brain.value),
				row[1] * mallow.golden_factor()
			)


func test_dozey_values_each_wake_dial_and_keeps_the_supper_route() -> void:
	for row: Array in [[0.0, 80.0], [3.0, 480.0]]:
		for golden: bool in [false, true]:
			_setup(row[0])
			var dozey: RecruitUnit = _kit.put("alderman_dozey", 6, golden)
			dozey.add_permanent(40 - dozey.base_attack_now(), 60 - dozey.base_health_now())
			var brain: BotBrain = _brain("hedgerow_supper")
			assert_eq(BotPass3.text_value(dozey, _kit.player, brain.value), row[1])
			_kit.config.set_value("hedgerow_dozey_wake_multiplier", 2.5)
			_kit.config.set_value("hedgerow_golden_dozey_wake_multiplier", 3.5)
			_kit.rules.board_changed(_kit.player)
			assert_eq(
				BotPass3.text_value(dozey, _kit.player, brain.value), 200.0 if golden else 120.0
			)


func test_treasurer_values_the_live_per_gold_dial_for_both_twins() -> void:
	for row: Array in [[0.0, 10.0], [3.0, 80.0]]:
		for golden: bool in [false, true]:
			_setup(row[0])
			var bank: RecruitUnit = _kit.put("honorary_treasurer", 6, golden)
			_kit.rules.give_card(_kit.player, "stash")
			var brain: BotBrain = _brain("hedgerow_treasury")
			assert_eq(
				BotPass3.text_value(bank, _kit.player, brain.value), row[1] * bank.golden_factor()
			)
