# gdlint: disable=max-public-methods
extends GutTest
## Fly South and Nests (docs/ideation/content/birds.md, costing-2.md).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const F1: int = 0
const F2: int = 1
const F3: int = 2
const F4: int = 3
const B1: int = 4
const B2: int = 5
const B3: int = 6

## One of each, so nothing triples while a test waits for room.
const HAND_OF_ONES: Array[String] = [
	"mrs_burdock",
	"mr_crumb",
	"mrs_sorrel",
	"pill_bug",
	"sexton_beetle",
	"alderman_dozey",
	"sleeping_partner",
	"earwig_mother",
	"dr_urchin",
	"old_mother_mast",
]

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


## A bird that has fought: bought, standing, not played this turn.
func _bird(id: String, slot: int) -> RecruitUnit:
	var unit: RecruitUnit = _kit.put(id, slot)
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	return unit


func _to_round(round_number: int) -> void:
	while _player.round_number < round_number:
		_kit.pass_turn()


func test_a_sold_bird_keeps_the_gold_and_goes_away() -> void:
	var bird: RecruitUnit = _bird("one_swallow", F2)
	var copies: int = _kit.pool.copies_left("one_swallow")
	assert_eq(_rules.sell(_player, F2), "")
	assert_eq(_player.gold, 11, "the sale still pays")
	assert_null(_player.board[F2])
	assert_false(_player.hand.has(bird))
	assert_false(_player.owned_units().has(bird), "not owned for triples while away")
	assert_true(_player.all_units().has(bird))
	assert_eq(_kit.pool.copies_left("one_swallow"), copies, "its copy stays out of the pool")


func test_a_bird_played_this_turn_is_a_plain_sale() -> void:
	var bird: RecruitUnit = _kit.play("one_swallow", F2)
	bird.pool_copies = 1
	var copies: int = _kit.pool.copies_left("one_swallow")
	assert_eq(_rules.sell(_player, F2), "")
	assert_eq(_player.away.size(), 0, "gone for good")
	assert_eq(_kit.pool.copies_left("one_swallow"), copies + 1, "the copy went back")
	assert_eq(_player.nest_count(), 0, "no Nest")


func test_a_bird_played_earlier_flies() -> void:
	_kit.play("one_swallow", F2)
	_kit.pass_turn()
	assert_eq(_rules.sell(_player, F2), "")
	assert_eq(_player.away.size(), 1)


func test_it_comes_home_two_turns_after_the_sale() -> void:
	var bird: RecruitUnit = _bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.pass_turn()
	assert_false(_player.hand.has(bird), "still away next turn")
	_kit.pass_turn()
	assert_true(_player.hand.has(bird), "home the turn after")
	assert_eq(_player.away.size(), 0)


func test_a_bird_never_comes_home_the_turn_it_left() -> void:
	var bird: RecruitUnit = _bird("mrs_jay", F2)
	_kit.put("mrs_stork", F1)
	_player.gold = 20
	_rules.sell(_player, F2)
	_rules.spend(_player, 12)
	assert_false(_player.hand.has(bird), "Stork can't reach one sold this turn")


func test_when_played_fires_again_on_each_return() -> void:
	var bird: RecruitUnit = _bird("chiffchaff", B2)
	var front: RecruitUnit = _kit.put("pill_bug", F2)
	_rules.sell(_player, B2)
	_to_round(3)
	assert_true(_player.hand.has(bird))
	var attack: int = front.attack
	_player.gold = 0
	assert_eq(_rules.play(_player, _player.hand.find(bird), B2), "")
	assert_eq(front.attack, attack + 1, "Chiffchaff's text again")


func test_it_comes_home_as_it_left() -> void:
	var bird: RecruitUnit = _bird("one_swallow", F2)
	bird.add_permanent(3, 3)
	bird.golden = true
	_rules.sell(_player, F2)
	_to_round(3)
	assert_eq(bird.perm_attack, 3)
	assert_true(bird.golden)


func test_flight_pays_base_value_without_sell_bonuses() -> void:
	_player.rule_handlers.append({"query": "sell_value", "op": "max", "value": 3})
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	assert_eq(_player.gold, 11, "base 1, not the raised sale")


func test_a_plain_sale_still_gets_the_bonus() -> void:
	_player.rule_handlers.append({"query": "sell_value", "op": "max", "value": 3})
	_kit.play("one_swallow", F2)
	_rules.sell(_player, F2)
	assert_eq(_player.gold, 13)


func test_when_sold_fires_on_a_flight() -> void:
	_bird("mrs_jay", F2)
	_rules.sell(_player, F2)
	assert_eq(_kit.item_ids(), ["acorn"])


func test_a_full_hand_keeps_it_on_the_doorstep_and_the_nest_ends_on_time() -> void:
	var bird: RecruitUnit = _bird("mrs_jay", F2)
	_rules.sell(_player, F2)
	_player.items.clear()
	for index: int in _kit.config.get_int("hand_limit"):
		_kit.put(HAND_OF_ONES[index])
	_to_round(3)
	assert_true(_player.doorstep.has(bird), "never lost")
	assert_eq(_player.nest_count(), 0, "the Nest ended on its due turn")
	assert_eq(_rules.play(_player, 0, F3), "")
	assert_true(_player.hand.has(bird), "room came")


func test_a_landing_that_completes_a_triple_ignores_the_hand_limit() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.put("one_swallow", F3)
	_kit.put("one_swallow", F4)
	for _index: int in _kit.config.get_int("hand_limit"):
		_kit.put("field_vole")
	_rules.check_triples(_player)
	while _rules.has_hand_space(_player):
		_kit.put("marsh_frog")
	_to_round(3)
	assert_eq(_player.doorstep.size(), 0)
	var goldens: int = 0
	for unit: RecruitUnit in _player.owned_units():
		goldens += 1 if unit.golden and unit.def_id() == "one_swallow" else 0
	assert_eq(goldens, 1, "the three made a golden")


func test_three_copies_combine_only_once_the_third_is_home() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.put("one_swallow", F3)
	_kit.put("one_swallow")
	_rules.check_triples(_player)
	assert_false(_player.hand[0].golden, "two at home, one away")
	_to_round(3)
	var goldens: int = 0
	for unit: RecruitUnit in _player.owned_units():
		goldens += 1 if unit.golden else 0
	assert_eq(goldens, 1)


func test_landing_comes_before_start_of_turn_text() -> void:
	_kit.card(
		"counter_unit",
		[
			KIT.effect(
				"start_of_turn",
				{"effect": "gold", "amount": 1},
				{"if": [{"kind": "hand", "at_least": 1}]}
			)
		]
	)
	_kit.put("counter_unit", F1)
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.pass_turn()
	_kit.pass_turn()
	var heard: int = 0
	for entry: Dictionary in _player.recruit_log:
		if entry["type"] == "trigger" and entry["source"] == "counter_unit":
			heard += 1
	assert_eq(heard, 1, "the bird was in hand when the text asked")


func test_elimination_returns_copies_away_and_on_the_doorstep() -> void:
	var bird: RecruitUnit = _bird("one_swallow", F2)
	bird.pool_copies = 1
	assert_true(_kit.pool.take("one_swallow"))
	var left: int = _kit.pool.copies_left("one_swallow")
	_rules.sell(_player, F2)
	var waiting: RecruitUnit = _kit.put("mrs_jay")
	_player.hand.erase(waiting)
	waiting.pool_copies = 1
	assert_true(_kit.pool.take("mrs_jay"))
	var jays: int = _kit.pool.copies_left("mrs_jay")
	_player.doorstep.append(waiting)
	_rules.return_everything(_player)
	assert_eq(_kit.pool.copies_left("one_swallow"), left + 1)
	assert_eq(_kit.pool.copies_left("mrs_jay"), jays + 1)
	assert_eq(_player.away.size(), 0)
	assert_eq(_player.doorstep.size(), 0)


# --- Nests --------------------------------------------------------------------------------------


func test_its_slot_holds_a_nest_until_it_is_home() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	assert_false(_player.nest_at(F2).is_empty())
	_kit.pass_turn()
	assert_false(_player.nest_at(F2).is_empty())
	_kit.pass_turn()
	assert_true(_player.nest_at(F2).is_empty(), "gone when it lands")


func test_a_slot_holds_one_nest_and_the_older_bird_still_comes_home() -> void:
	var first: RecruitUnit = _bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.pass_turn()
	var second: RecruitUnit = _bird("mrs_jay", F2)
	_rules.sell(_player, F2)
	assert_eq(_player.nest_count(), 1)
	assert_eq(_player.nest_at(F2)["unit"], second)
	_kit.pass_turn()
	assert_true(_player.hand.has(first), "still home on time, with no Nest to its name")


func test_a_unit_may_stand_on_a_nest() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.put("field_vole")
	assert_eq(_rules.play(_player, 0, F2), "")
	assert_false(_player.nest_at(F2).is_empty(), "the Nest stays under it")


func test_an_empty_nest_holds_an_egg_in_a_fight() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	var board: Array = _player.combat_board()
	assert_eq(str(board[F2]["def_id"]), HeldUnits.EGG)
	assert_null(_player.board_specs()[F2], "only in the fight")
	assert_null(_player.board[F2], "the recruit slot stays free")


func test_a_unit_on_the_nest_means_no_egg() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.put("field_vole", F2)
	assert_eq(str(_player.combat_board()[F2]["def_id"]), "field_vole")


func test_an_egg_is_0_2_and_keeps_a_ring() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_player.slot_effects[F2] = [{"name": "Ring", "attack": 2, "health": 2}]
	_kit.put("field_vole", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 1, "health": 9}}
	)
	var start: Dictionary = KIT.of_type(result, "combat_start")[0]
	var egg: Dictionary = start["boards"][0][F2]
	assert_eq(egg["attack"], 2)
	assert_eq(egg["health"], 4)


func test_an_egg_blocks_summons() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.card("dropper", [KIT.effect("on_death", {"effect": "summon", "unit": "kit"})])
	_kit.put("dropper", F1)
	_kit.put("sett_warden", F3)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 9, "health": 99}}
	)
	var slots: Array = []
	for event: Dictionary in KIT.of_type(result, "summon"):
		slots.append(event["slot"])
	assert_false(slots.has(F2), "the Egg's slot is taken")


func test_a_surviving_egg_adds_no_damage() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	var bird: RecruitUnit = _kit.put("mrs_jay", F1)
	bird.add_permanent(20, 20)
	_player.tier = 6
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 0, "health": 1}}
	)
	assert_eq(result["winner"], 0)
	assert_eq(result["damage"], 7, "tier 6 plus ceil(2 / 2), nothing for the Egg")


func test_fight_rules_name_the_nests_and_the_sky() -> void:
	_bird("mother_goose", F2)
	_rules.sell(_player, F2)
	var rules: Dictionary = _rules.fight_rules(_player)
	var nests: Array = rules["nests"]
	assert_eq(nests[0]["slot"], F2)
	assert_eq(nests[0]["attack"], 4, "the card's Attack")
	assert_eq(rules["goose"], 1)
	assert_eq(rules["away_birds"], ["mother_goose"])


func test_the_view_shows_when_it_lands() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	var sky: Array = HeldUnits.away_views(_player)
	assert_eq(sky[0]["turns_left"], 2)
	assert_eq(sky[0]["nest"], F2)


func test_what_it_fought_with_is_scouted_with_its_nests() -> void:
	_bird("one_swallow", F2)
	_rules.sell(_player, F2)
	_kit.put("field_vole", F1)
	_player.remember_fought_board()
	assert_eq(_player.fought_nests, [F2])
	var egg: Dictionary = _player.fought_specs[F2]
	assert_eq(egg["def_id"], HeldUnits.EGG, "the scout saw an Egg")
	assert_eq(_player.fought_view[F2], null, "the tile view has no unit there")


func test_a_golden_auto_boarded_with_a_full_hand_must_fight_before_flying() -> void:
	for id: String in ["one_swallow", "mrs_jay"]:
		before_each()
		for slot: int in [F1, F2, F3]:
			_bird(id, slot)
		for filler: String in HAND_OF_ONES:
			_kit.put(filler)
		assert_false(_rules.has_hand_space(_player))
		_rules.check_triples(_player)
		var golden: RecruitUnit = _player.board[F1]
		assert_true(golden.golden)
		assert_eq(golden.played_round, _player.round_number)
		assert_false(HeldUnits.flies(golden, _player))
		assert_eq(_rules.sell(_player, F1), "")
		assert_eq(_player.away.size(), 0, "hasn't fought as a golden")
