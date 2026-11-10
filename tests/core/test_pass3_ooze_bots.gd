extends GutTest
## Short recruit states exercise the same actions used by Hard and committed line seats.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
## Mechanics here are checked at the pre-A3.5 Ooze dials; test_pass3_path covers the path values.
const LEGACY_DIALS: Dictionary = {
	"oozes_aspic_bonus": 0.5,
	"oozes_golden_aspic_multiplier": 2.0,
	"oozes_hasty_share": 0.2,
	"oozes_eat_printed_multiplier": 1,
}
var _kit: Kit
var _player: PlayerState
var _rules: RecruitRules


static func _legacy_config() -> GameConfig:
	var config := GameConfig.full_game()
	for key: String in LEGACY_DIALS:
		config.set_value(key, LEGACY_DIALS[key])
	return config


func before_each() -> void:
	_kit = Kit.new()
	_kit.setup(_legacy_config())
	_player = _kit.player
	_rules = _kit.rules
	_player.round_number = 9
	_player.tier = 5
	_player.health = 40
	_player.gold = 10


func _brain(tempo: bool = false) -> BotBrain:
	var brain: BotBrain = BotBrain.from_name(
		"hard:oozes_second_helpings" if tempo else "hard:oozes_waste_not"
	)
	_rules.board_changed(_player)
	brain._player = _player
	brain._rules = _rules
	brain._round_now = _player.round_number
	brain.value.board_owner = _player
	brain.value.recruit_rules = _rules
	brain.value.library = _kit.library
	return brain


func test_engine_keeps_soup_nell_aspic_and_elder_over_large_new_bodies() -> void:
	var carry: RecruitUnit = _kit.put("bubble_and_squeak", 1)
	carry.add_permanent(60, 60)
	_kit.put("stone_soup", 4)
	_kit.put("dishwater_nell", 5)
	_kit.put("aunt_aspic", 6)
	_kit.put("elder_ooze", 0)
	var brain: BotBrain = _brain()
	for unit: RecruitUnit in _player.board:
		if unit != null:
			assert_false(brain._can_replace(unit), unit.def_id())


func test_only_the_best_engine_copy_is_protected() -> void:
	_kit.put("little_dollop", 0)
	var soup: RecruitUnit = _kit.put("stone_soup", 4)
	var gold: RecruitUnit = _kit.put("stone_soup", 5, true)
	var brain: BotBrain = _brain()
	assert_true(brain._can_replace(soup))
	assert_false(brain._can_replace(gold))


func test_meal_route_bypasses_the_pin_only_to_feed_a_real_digest_belly() -> void:
	var carry: RecruitUnit = _kit.put("little_dollop", 1)
	_kit.put("stone_soup", 4)
	_kit.put("dishwater_nell", 5)
	var food: RecruitUnit = _kit.shop("little_nip")
	food.add_permanent(30, 40)
	var brain: BotBrain = _brain()
	assert_gt(brain._unit_gain(food), 0.0)
	assert_eq(brain._buy_belly(food), 1)
	assert_eq(brain._buy_unit(0), "")
	assert_true(carry.held.has(food))
	assert_false(_player.board.has(food))
	assert_eq(_player.gold, 8, "the actual Dollop discount funds the food")


func test_a_real_engine_offer_is_not_bought_into_an_empty_stomach() -> void:
	_kit.put("little_dollop", 1)
	_kit.put("moss_ooze", 0)
	_kit.put("mrs_posset", 3)
	var soup: RecruitUnit = _kit.shop("stone_soup")
	var brain: BotBrain = _brain()
	assert_eq(brain._buy_belly(soup), -1)
	assert_eq(brain._buy_unit(0), "")
	brain._play_hand()
	assert_true(_player.board.has(soup))


func test_first_empty_dollop_moves_whole_to_the_new_bubble() -> void:
	_player.round_number = 6
	var dollop: RecruitUnit = _kit.put("little_dollop", 1)
	dollop.add_permanent(25, 30)
	var bubble: RecruitUnit = _kit.put("bubble_and_squeak", 2)
	_kit.put("stone_soup", 4)
	BotOoze.prepare(_brain())
	assert_true(bubble.held.has(dollop), "the larger old carry transfers rather than being sold")
	assert_null(_player.board[1])


func test_golden_dollop_is_not_migrated() -> void:
	_player.round_number = 6
	var dollop: RecruitUnit = _kit.put("little_dollop", 1, true)
	dollop.add_permanent(25, 30)
	_kit.put("bubble_and_squeak", 2)
	_kit.put("stone_soup", 4)
	BotOoze.prepare(_brain())
	assert_same(_player.board[1], dollop)


func test_second_stomach_waits_three_turns_and_a_scouted_answer_preserves_it() -> void:
	var dollop: RecruitUnit = _kit.put("little_dollop", 0)
	dollop.counters["bot_stomach_since"] = 8
	var bubble: RecruitUnit = _kit.put("bubble_and_squeak", 1)
	bubble.add_permanent(50, 50)
	var brain: BotBrain = _brain()
	BotOoze.prepare(brain)
	assert_same(_player.board[0], dollop)
	_player.round_number = 11
	_player.scout = {"specs": [{"def_id": "hasty_pudding", "attack": 3, "health": 9}]}
	BotOoze.prepare(brain)
	assert_same(_player.board[0], dollop)
	_player.scout = {}
	BotOoze.prepare(brain)
	assert_true(bubble.held.has(dollop))


func test_aspic_feeds_front_carry_and_nell_touches_it() -> void:
	var carry: RecruitUnit = _kit.put("bubble_and_squeak", 6)
	carry.add_permanent(50, 50)
	var aspic: RecruitUnit = _kit.put("aunt_aspic", 3)
	var nell: RecruitUnit = _kit.put("dishwater_nell", 0)
	_kit.put("stone_soup", 4)
	var brain: BotBrain = _brain()
	var layout: Array[int] = BotPlacer.rule_layout(_player, brain.value, [])
	assert_eq(layout.find(_player.board.find(carry)), 1)
	assert_eq(layout.find(_player.board.find(aspic)), 4)
	assert_eq(layout.find(_player.board.find(nell)), 5)
	assert_eq(layout[2], -1, "a short board leaves a split landing beside the carry")
	assert_eq(BotOoze.max_bodies(_player, brain.value), 6)
	_kit.put("granny_stir_up", 2)
	assert_eq(BotOoze.max_bodies(_player, brain.value), 7, "Granny wants a full family")


func test_pot_luck_reserves_stay_out_of_hasty_when_the_scout_shows_a_carry() -> void:
	_kit.put("bubble_and_squeak", 5)
	_kit.put("hasty_pudding", 0)
	_kit.put("sixpenny_pie", 2)
	_player.scout = {"specs": [{"attack": 60, "health": 60}, {"attack": 1, "health": 1}]}
	var brain: BotBrain = _brain(true)
	var reserve: RecruitUnit = _kit.shop("wee_wobbly")
	assert_eq(BotOoze.best_belly(_player, brain.value, reserve), 2)
	assert_true(BotOoze.wants_hasty(_player))


func test_a_large_slice_is_food_only_in_the_engine_line() -> void:
	_kit.put("bubble_and_squeak", 1)
	_kit.put("stone_soup", 4)
	_kit.put("dishwater_nell", 5)
	var slice: RecruitUnit = _kit.put("slice")
	slice.add_permanent(70, 70)
	assert_eq(BotOoze.hand_belly(_brain(), slice), 1)
	assert_eq(BotOoze.hand_belly(_brain(true), slice), -1)
	assert_eq(
		BotHeld.best_belly(_player, _brain(true).value, slice),
		-1,
		"full-board fallback cannot feed Pot Luck\'s Slice"
	)


func test_freeze_does_not_take_nells_meal_for_generic_shop_quality() -> void:
	_kit.put("little_dollop", 1)
	_kit.put("stone_soup", 4)
	_kit.put("dishwater_nell", 5)
	var food: RecruitUnit = _kit.shop("little_nip")
	food.add_permanent(500, 500)
	var brain: BotBrain = _brain()
	brain._freeze()
	assert_false(_player.frozen)
	_kit.put("little_nip", 0)
	_kit.put("little_nip", 2)
	brain._freeze()
	assert_true(_player.frozen, "a real triple can be protected from Nell")


func test_line_source_is_strictly_valid_and_food_uses_the_same_legal_path() -> void:
	var source: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/sim/lines/oozes.json")
	)
	assert_true(LinePolicies.validate_wave1(source).is_empty())
	var carry: RecruitUnit = _kit.put("little_dollop", 1)
	_kit.put("stone_soup", 4)
	_kit.put("dishwater_nell", 5)
	var food: RecruitUnit = _kit.shop("little_nip")
	var brain: BotBrain = BenchSuites.create_bot("line_oozes_engine") as BotBrain
	brain._player = _player
	brain._rules = _rules
	brain._round_now = 9
	brain.value.board_owner = _player
	brain.value.recruit_rules = _rules
	brain.value.library = _kit.library
	assert_gt(brain._unit_gain(food), 0.0)
	assert_true(brain._buy_offer({"spell": false, "index": 0, "cost": 2, "gain": 10.0}))
	assert_true(carry.held.has(food))


func test_meal_valuation_includes_the_live_soup_layer_exactly_once() -> void:
	var carry: RecruitUnit = _kit.put("little_dollop", 1)
	carry.add_permanent(99, 98)
	_kit.put("stone_soup", 4)
	_kit.put("dishwater_nell", 5)
	var food: RecruitUnit = _kit.shop("little_nip")
	var brain: BotBrain = _brain()
	var own: int = (
		food.base_attack_now() + food.base_health_now() + food.perm_attack + food.perm_health
	)
	var soup: Vector2i = food.get_meta("ooze_soup_bonus", Vector2i.ZERO)
	assert_gt(soup.x + soup.y, 0)
	assert_eq(BotOoze.meal_gain(brain, food), float(own + soup.x + soup.y))


func test_six_protected_investments_allow_a_seventh_engine_but_a_spare_keeps_the_gap() -> void:
	var carry: RecruitUnit = _kit.put("bubble_and_squeak", 1)
	carry.add_permanent(60, 60)
	_kit.put("little_dollop", 0)
	_kit.put("stone_soup", 2)
	_kit.put("aunt_aspic", 4)
	_kit.put("dishwater_nell", 5)
	_kit.put("elder_ooze", 6)
	var brain: BotBrain = _brain()
	assert_eq(BotOoze.max_bodies(_player, brain.value, brain._can_replace), 7)
	assert_eq(brain._room_left(), 1, "the Slice engine has a real route onto this board")
	var slice_engine: RecruitUnit = _kit.put("cut_and_come_again")
	brain._play_hand()
	assert_true(_player.board.has(slice_engine))
	_player.board[0] = null
	_player.board[3] = null
	_kit.put("wee_wobbly", 0)
	assert_eq(BotOoze.max_bodies(_player, brain.value, brain._can_replace), 6)


func _tempo_purchase_brain(line: bool) -> BotBrain:
	if not line:
		return _brain(true)
	var brain: BotBrain = BenchSuites.create_bot("line_oozes_tempo") as BotBrain
	brain._player = _player
	brain._rules = _rules
	brain._round_now = _player.round_number
	brain.value.board_owner = _player
	brain.value.recruit_rules = _rules
	brain.value.library = _kit.library
	_rules.board_changed(_player)
	return brain


func _full_reserve_board() -> RecruitUnit:
	var reserve: RecruitUnit = _kit.put("mrs_posset", 0)
	for slot: int in range(1, BoardGeometry.SLOTS):
		var id: String = _kit.card("weak_ooze_%d" % slot, [], ["Oozes"], 1, 1)
		_kit.put(id, slot)
	return reserve


func test_first_digest_purchase_replaces_a_weak_body_instead_of_becoming_a_reserve() -> void:
	for line: bool in [false, true]:
		for id: String in ["little_dollop", "bubble_and_squeak", "frumenty"]:
			before_each()
			var reserve: RecruitUnit = _full_reserve_board()
			var pot: RecruitUnit = _kit.shop(id)
			var brain: BotBrain = _tempo_purchase_brain(line)
			assert_eq(HeldUnits.room(reserve), 1, "the old reserve route is legally available")
			assert_eq(brain._buy_belly(pot), -1)
			assert_true(brain._buy_offer({"spell": false, "index": 0, "cost": 3, "gain": 50.0}))
			assert_true(_player.board.has(pot), "%s: a live pot, line=%s" % [id, str(line)])
			assert_false(reserve.held.has(pot), "the first Digest must not get buried")
			assert_same(BotOoze.carry(_player), pot)
			assert_false(brain._can_replace(pot), "the live pot remains protected")


func test_bubble_upgrade_is_played_then_receives_the_old_dollop_whole() -> void:
	for line: bool in [false, true]:
		before_each()
		_player.round_number = 7
		var reserve: RecruitUnit = _full_reserve_board()
		var dollop: RecruitUnit = _kit.put("little_dollop", 1)
		dollop.add_permanent(40, 50)
		var bubble: RecruitUnit = _kit.shop("bubble_and_squeak")
		var brain: BotBrain = _tempo_purchase_brain(line)
		assert_eq(brain._buy_belly(bubble), -1, "a better pot is not a spare life")
		assert_true(brain._buy_offer({"spell": false, "index": 0, "cost": 3, "gain": 50.0}))
		assert_true(_player.board.has(bubble))
		assert_false(reserve.held.has(bubble))
		BotOoze.prepare(brain)
		assert_true(bubble.held.has(dollop), "the old permanent body transfers intact")
		assert_false(_player.board.has(dollop))
		assert_false(brain._can_replace(bubble), "the migrated carry remains protected")


func test_tempo_replaces_dead_aspic_while_the_front_carry_engine_keeps_her() -> void:
	for line: bool in [false, true]:
		for golden: bool in [false, true]:
			before_each()
			var carry: RecruitUnit = _kit.put("bubble_and_squeak", 5)
			carry.add_permanent(60, 60)
			var aspic: RecruitUnit = _kit.put("aunt_aspic", 4, golden)
			_kit.put("stone_soup", 0)
			_kit.put("dishwater_nell", 1)
			_kit.put("elder_ooze", 2)
			_kit.put("cut_and_come_again", 3)
			var moss: RecruitUnit = _kit.put("moss_ooze", 6)
			moss.add_permanent(40, 40)
			var brain: BotBrain = _tempo_purchase_brain(line)
			assert_eq(BotOoze.text_value(aspic, _player, brain.value), 0.0)
			assert_true(brain._can_replace(aspic), "Aspic cannot serve the back-row pot")
			var incoming_id: String = _kit.card("new_ooze", [], ["Oozes"], 200, 200)
			var incoming: RecruitUnit = _kit.shop(incoming_id)
			assert_eq(brain._best_replacement_slot(incoming), 4, "retire the dead support")
			if line:
				(brain as LineBrain).configure_line("line_oozes_engine")
			else:
				brain.value.strategy = brain.knowledge.strategy("oozes_waste_not")
			_rules.move(_player, 5, 1)
			assert_gt(BotOoze.text_value(aspic, _player, brain.value), 0.0)
			assert_false(
				brain._can_replace(aspic), "the front-carry line keeps its real meal bonus"
			)
