extends GutTest
@warning_ignore_start("unsafe_call_argument")

const K := preload("res://tests/core/recruit_kit.gd")
var _kit: K


func test_tripling_preserves_combat_growth_without_thanking_shy() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 4)
	_kit.rules.apply_carry(_kit.player, {"op": "buff", "iid": hob.iid, "attack": 3, "health": 5})
	_kit.put("hob_in_the_hearth")
	_kit.put("hob_in_the_hearth")
	_kit.rules.check_triples(_kit.player)
	assert_eq(_kit.player.hand.size(), 1)
	var golden: RecruitUnit = _kit.player.hand[0]
	assert_true(golden.golden)
	assert_eq(golden.perm_attack, 3)
	assert_eq(golden.perm_health, 5)
	assert_eq(_kit.player.gold_next_turn, 0)


func before_each() -> void:
	_kit = K.new()
	_kit.setup(GameConfig.full_game(), true)
	_kit.rules.start_phase(_kit.player, 1)


func test_shy_ignores_rings_tribe_bonuses_and_untargeted_unit_buffs() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 4)
	BoardUpkeep.add_ring(_kit.player, 4, {"attack": 3, "health": 3})
	_kit.player.tribe_bonuses["Fairies"] = 3
	hob.add_permanent(4, 4)
	_kit.rules.board_changed(_kit.player)
	assert_eq(Vector2i(hob.attack, hob.health), Vector2i(1, 3))
	assert_eq(_kit.player.board[4], hob)
	assert_eq(_kit.player.gold_next_turn, 0)


func test_an_aimed_supper_still_raises_fairy_bonus_before_shy_leaves() -> void:
	_kit.put("hob_in_the_hearth", 4)
	var fairy: RecruitUnit = _kit.put("nan_toadstool", 0)
	assert_eq(_kit.cast("harvest_supper", 4), "")
	assert_null(_kit.player.board[4])
	assert_eq(_kit.player.tribe_bonuses["Fairies"], 1)
	assert_eq(fairy.tribe_attack, 1)
	assert_eq(_kit.player.gold_next_turn, 2)


func test_an_aimed_ring_thanks_a_golden_shy_unit_after_creating_the_ring() -> void:
	_kit.put("hob_in_the_hearth", 4, true)
	assert_eq(_kit.cast("spore_cloud", 4), "")
	assert_null(_kit.player.board[4])
	assert_eq(BoardUpkeep.ring_value(_kit.player.slot_effects[4]), Vector2i(2, 2))
	assert_eq(_kit.player.gold_next_turn, 4)


func test_splash_from_a_spell_aimed_elsewhere_does_not_buff_or_thank_shy() -> void:
	_kit.put("nan_toadstool", 0)
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 4)
	assert_eq(_kit.cast("stand_behind_me", 0), "")
	assert_eq(Vector2i(hob.attack, hob.health), Vector2i(1, 3))
	assert_eq(_kit.player.board[4], hob)
	assert_eq(_kit.player.gold_next_turn, 0)


func test_shy_keeps_permanent_buffs_earned_in_combat_without_a_thank_you() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 4)
	_kit.rules.apply_carry(_kit.player, {"op": "buff", "iid": hob.iid, "attack": 2, "health": 2})
	_kit.rules.board_changed(_kit.player)
	assert_eq(Vector2i(hob.attack, hob.health), Vector2i(3, 5))
	assert_eq(_kit.player.board[4], hob)
	assert_eq(_kit.player.gold_next_turn, 0)


func test_a_spell_without_an_aim_never_thanks_an_incidental_slot() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 4)
	assert_eq(_kit.cast("rainy_day", 4), "")
	assert_eq(_kit.player.board[4], hob)
	assert_eq(_kit.player.gold_next_turn, 0)
