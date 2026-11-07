extends GutTest
## Exact Group D alternatives: test the cost and the explicit reward exceptions.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)
	_player.shop.clear()
	_player.gold = 10


func _fly(id: String, slot: int = 1) -> RecruitUnit:
	var bird: RecruitUnit = _kit.put(id, slot)
	bird.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(_rules.sell(_player, slot), "")
	return bird


func _home(bird: RecruitUnit) -> void:
	while not _player.hand.has(bird):
		_kit.pass_turn()


func test_half_egg_rounds_each_stat_up_and_keeps_goose_exception() -> void:
	var bird: RecruitUnit = _kit.put("mrs_jay", 1)
	bird.attack = 6
	bird.health = 9
	var egg: Dictionary = HeldUnits.egg_spec(bird)
	assert_eq(egg["attack"], 3)
	assert_eq(egg["health"], 5)
	var goose: RecruitUnit = _kit.put("mother_goose", 2, true)
	goose.add_permanent(20, 20)
	assert_eq(HeldUnits.egg_spec(goose)["attack"], 0)
	assert_eq(HeldUnits.egg_spec(goose)["health"], 2)


func test_every_printed_flier_now_loses_body_stats_when_it_flies() -> void:
	var zero_loss: Array[String] = []
	for id: String in [
		"one_swallow", "chiffchaff", "mrs_jay", "jack_daw", "old_tern", "mother_goose"
	]:
		var bird: RecruitUnit = _kit.put(id)
		var egg: Dictionary = HeldUnits.egg_spec(bird)
		assert_lt(egg["attack"] + egg["health"], bird.attack + bird.health, id)
		if egg["attack"] == bird.attack and egg["health"] == bird.health:
			zero_loss.append(id)
	assert_eq(zero_loss, [])


func test_half_egg_charges_body_for_old_tern() -> void:
	var bird: RecruitUnit = _fly("old_tern")
	var egg: Dictionary = _player.combat_board()[1]
	assert_eq(egg["attack"], 1)
	assert_eq(egg["health"], 2)
	assert_lt(egg["health"], bird.health)
	_home(bird)
	assert_eq(_player.pending.size(), 1)


func test_half_egg_keeps_repeat_reward_text_as_requested() -> void:
	var front: RecruitUnit = _kit.put("pill_bug", 1)
	var bird: RecruitUnit = _fly("chiffchaff", 4)
	_home(bird)
	var before: int = front.attack
	assert_eq(_rules.play(_player, _player.hand.find(bird), 4), "")
	assert_eq(front.attack, before + 1)


func test_small_birds_each_pay_one_health_per_fight_away() -> void:
	for id: String in ["one_swallow", "chiffchaff"]:
		var bird: RecruitUnit = _kit.put(id)
		var egg: Dictionary = HeldUnits.egg_spec(bird)
		assert_eq([bird.attack, bird.health], [1, 2], id)
		assert_eq([egg["attack"], egg["health"]], [1, 1], id)
		assert_eq(bird.health - egg["health"], 1, "the trip costs one printed Health")
