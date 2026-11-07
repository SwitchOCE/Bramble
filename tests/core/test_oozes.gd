# gdlint: disable=max-public-methods
extends GutTest
## The Oozes, card by card (docs/ideation/content/oozes.md, design-review-2.md, costing-2.md).
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
	_player.shop.clear()
	_player.gold = 20


func _into(id: String, slot: int) -> RecruitUnit:
	var unit: RecruitUnit = _kit.put(id)
	assert_eq(_rules.swallow(_player, HeldUnits.HAND, _player.hand.find(unit), slot), "")
	return unit


func _fought_triggers(result: Dictionary, mechanic: String) -> int:
	var count: int = 0
	for event: Dictionary in KIT.of_type(result, "trigger"):
		if event["mechanic"] == mechanic:
			count += 1
	return count


func _came_out(result: Dictionary) -> Array:
	var out: Array = []
	for event: Dictionary in KIT.of_type(result, "summon"):
		if event.get("came_out", false):
			out.append(str(event["unit"]["def_id"]))
	return out


## An enemy that never dies quickly, hitting for `attack`.
func _foe(attack: int, health: int = 500) -> Dictionary:
	return {F1: {"def_id": "pill_bug", "attack": attack, "health": health}}


func test_wobbly_lets_out_what_is_inside_when_it_survives_a_hit() -> void:
	_kit.put("wee_wobbly", F1)
	_into("field_vole", F1)
	var result: Dictionary = _kit.fight_board(_foe(1))
	assert_eq(_came_out(result), ["field_vole"])


func test_wobbly_summons_a_drip_with_nobody_inside_twice_a_fight() -> void:
	_kit.put("wee_wobbly", F1)
	_player.board[F1].add_permanent(5, 20)
	var result: Dictionary = _kit.fight_board(_foe(1))
	var drips: int = 0
	for event: Dictionary in KIT.of_type(result, "summon"):
		drips += 1 if event["unit"]["def_id"] == "drip" else 0
	assert_eq(drips, 2, "twice a fight, however many hits")


func test_wobbly_does_nothing_if_it_dies_from_the_hit() -> void:
	_kit.put("wee_wobbly", F1)
	var result: Dictionary = _kit.fight_board(_foe(9))
	assert_eq(_fought_triggers(result, "wobbly"), 0)


func test_posset_hits_the_enemy_across_for_3_when_she_dies() -> void:
	_kit.put("mrs_posset", F1)
	var result: Dictionary = _kit.fight_board(_foe(9))
	var hit: bool = false
	for event: Dictionary in KIT.of_type(result, "damage"):
		hit = hit or (event["kind"] == "effect" and event["amount"] == 3)
	assert_true(hit)


func test_golden_posset_hits_for_6() -> void:
	_kit.put("mrs_posset", F1, true)
	var result: Dictionary = _kit.fight_board(_foe(99))
	var hit: bool = false
	for event: Dictionary in KIT.of_type(result, "damage"):
		hit = hit or (event["kind"] == "effect" and event["amount"] == 6)
	assert_true(hit)


func _shop_of_tier(id: String) -> RecruitUnit:
	var unit: RecruitUnit = _kit.shop(id)
	unit.pool_copies = 1
	assert_true(_kit.pool.take(id))
	return unit


func test_nell_swaps_the_lowest_tier_shop_unit_for_one_of_your_tier() -> void:
	_player.tier = 3
	_shop_of_tier("pill_bug")
	_shop_of_tier("sexton_beetle")
	_kit.put("dishwater_nell", B1)
	var copies: int = _kit.pool.copies_left("pill_bug")
	_kit.rules.events.fire(_player, "start_of_turn")
	assert_eq(_player.shop[0].tier(), 3, "the tier 1 is gone")
	assert_eq(_kit.pool.copies_left("pill_bug"), copies + 1, "its copy went back")


func test_nell_pays_only_for_a_unit_2_tiers_lower_touching_an_ooze() -> void:
	_player.tier = 3
	_shop_of_tier("pill_bug")
	_kit.put("dishwater_nell", F1)
	_kit.put("mrs_posset", B1)
	var gold: int = _player.gold
	_rules.events.fire(_player, "start_of_turn")
	assert_eq(_player.gold, gold + 1)


func test_nell_not_touching_an_ooze_pays_nothing_but_still_swaps() -> void:
	_player.tier = 3
	_shop_of_tier("pill_bug")
	_kit.put("dishwater_nell", F1)
	var gold: int = _player.gold
	_rules.events.fire(_player, "start_of_turn")
	assert_eq(_player.gold, gold)
	assert_eq(_player.shop[0].tier(), 3)


func test_nell_one_tier_lower_pays_nothing() -> void:
	_player.tier = 2
	_shop_of_tier("pill_bug")
	_kit.put("dishwater_nell", F1)
	_kit.put("mrs_posset", B1)
	var gold: int = _player.gold
	_rules.events.fire(_player, "start_of_turn")
	assert_eq(_player.gold, gold)


func test_only_the_first_nell_pays() -> void:
	_player.tier = 3
	_shop_of_tier("pill_bug")
	_shop_of_tier("pill_bug")
	_kit.put("dishwater_nell", F1)
	_kit.put("dishwater_nell", F2)
	_kit.put("mrs_posset", B1)
	var gold: int = _player.gold
	_rules.events.fire(_player, "start_of_turn")
	assert_eq(_player.gold, gold + 1)


func test_golden_nell_swaps_two_and_pays_2() -> void:
	_player.tier = 3
	_shop_of_tier("pill_bug")
	_shop_of_tier("tom_tit")
	_kit.put("dishwater_nell", F1, true)
	_kit.put("mrs_posset", B1)
	var gold: int = _player.gold
	_rules.events.fire(_player, "start_of_turn")
	assert_eq(_player.shop[0].tier(), 3)
	assert_eq(_player.shop[1].tier(), 3)
	assert_eq(_player.gold, gold + 2)


func test_nell_leaves_a_shop_of_your_tier_alone() -> void:
	_player.tier = 1
	var unit: RecruitUnit = _shop_of_tier("pill_bug")
	_kit.put("dishwater_nell", F1)
	_rules.events.fire(_player, "start_of_turn")
	assert_eq(_player.shop[0], unit)


func test_stone_soup_grows_the_shop_after_a_unit_is_bought_into_a_belly() -> void:
	_kit.put("stone_soup", F1)
	_kit.put("mrs_posset", F2)
	var bought: RecruitUnit = _kit.shop("pill_bug")
	var other: RecruitUnit = _kit.shop("field_vole")
	var attack: int = other.attack
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, F2), "")
	assert_eq(other.attack, attack + 1, "from any Belly")
	assert_false(_player.shop.has(bought))


func test_stone_soup_doesnt_hear_a_free_swallow() -> void:
	_kit.put("stone_soup", F1)
	var other: RecruitUnit = _kit.shop("field_vole")
	var attack: int = other.attack
	_into("pill_bug", F1)
	assert_eq(other.attack, attack)


func test_a_unit_bought_from_the_soup_keeps_it_but_the_frozen_rest_lose_it() -> void:
	_kit.put("stone_soup", F1)
	_kit.put("mrs_posset", F2)
	_kit.shop("pill_bug")
	var kept: RecruitUnit = _kit.shop("field_vole")
	var frozen: RecruitUnit = _kit.shop("marsh_frog")
	var base: int = frozen.attack
	_rules.swallow(_player, HeldUnits.SHOP, 0, F2)
	var attack: int = kept.attack
	assert_eq(_rules.buy(_player, 0), "")
	_rules.toggle_freeze(_player)
	_rules.end_phase(_player)
	assert_eq(kept.attack, attack, "bought, so it stays")
	assert_eq(frozen.attack, base, "a freeze doesn't keep it")


func test_golden_stone_soup_gives_2() -> void:
	_kit.put("stone_soup", F1, true)
	_kit.shop("pill_bug")
	var other: RecruitUnit = _kit.shop("field_vole")
	var attack: int = other.attack
	_rules.swallow(_player, HeldUnits.SHOP, 0, F1)
	assert_eq(other.attack, attack + 2)


func test_aspic_feeds_what_is_inside_the_oozes_in_front() -> void:
	_kit.put("mrs_posset", F1)
	var fed: RecruitUnit = _into("pill_bug", F1)
	_kit.put("little_dollop", F3)
	var not_fed: RecruitUnit = _into("field_vole", F3)
	_kit.put("aunt_aspic", B1)
	var fed_attack: int = fed.attack
	var other: int = not_fed.attack
	_rules.end_phase(_player)
	assert_eq(fed.attack, fed_attack + 1, "B1 reaches F1 and F2")
	assert_eq(not_fed.attack, other, "F3 isn't in front of B1")


func test_aspic_only_feeds_inside_oozes_not_the_oozes() -> void:
	var ooze: RecruitUnit = _kit.put("mrs_posset", F1)
	_into("pill_bug", F1)
	_kit.put("aunt_aspic", B1)
	var attack: int = ooze.attack
	_rules.end_phase(_player)
	assert_eq(ooze.attack, attack)


func test_golden_aspic_gives_2() -> void:
	_kit.put("mrs_posset", F1)
	var fed: RecruitUnit = _into("pill_bug", F1)
	_kit.put("aunt_aspic", B1, true)
	var health: int = fed.health
	_rules.end_phase(_player)
	assert_eq(fed.health, health + 2)


func test_bubble_splits_half_into_a_copy_once_a_fight_with_an_empty_belly() -> void:
	var bubble: RecruitUnit = _kit.put("bubble_and_squeak", F1)
	bubble.add_permanent(7, 16)
	_into("pill_bug", F1)
	var result: Dictionary = _kit.fight_board(_foe(4))
	var copies: Array[Dictionary] = []
	for event: Dictionary in KIT.of_type(result, "summon"):
		if event["unit"]["def_id"] == "bubble_and_squeak":
			copies.append(event)
	assert_eq(copies.size(), 1, "the copy's split is used")
	assert_eq(copies[0]["unit"]["attack"], 5, "half of 10")
	assert_eq(copies[0]["unit"]["held"], 0, "empty Belly")


func test_bubble_needs_a_gap() -> void:
	_kit.put("bubble_and_squeak", F1)
	for slot: int in [F2, F3, F4, B1, B2, B3]:
		_kit.put("sett_warden", slot)
	var result: Dictionary = _kit.fight_board(_foe(1))
	assert_eq(_fought_triggers(result, "bubble"), 0)


func test_golden_bubble_splits_twice() -> void:
	var bubble: RecruitUnit = _kit.put("bubble_and_squeak", F1, true)
	bubble.add_permanent(20, 40)
	var result: Dictionary = _kit.fight_board(_foe(1))
	assert_eq(_fought_triggers(result, "bubble"), 2)


func test_pie_pays_1_next_turn_when_2_come_out() -> void:
	_kit.put("sixpenny_pie", F1)
	_into("pill_bug", F1)
	_into("field_vole", F1)
	_kit.fight_board(_foe(9))
	assert_eq(_player.gold_next_turn, 1)


func test_pie_pays_nothing_for_one() -> void:
	_kit.put("sixpenny_pie", F1)
	_into("pill_bug", F1)
	_kit.fight_board(_foe(9))
	assert_eq(_player.gold_next_turn, 0)


func test_pie_pays_only_for_those_that_found_room() -> void:
	_kit.put("sixpenny_pie", F1)
	_into("pill_bug", F1)
	_into("field_vole", F1)
	for slot: int in [F2, F3, F4, B1, B2, B3]:
		_kit.put("sett_warden", slot)
	_kit.fight_board(_foe(9, 5000))
	assert_eq(_player.gold_next_turn, 0, "one out, one lost")


func test_golden_pie_pays_2() -> void:
	_kit.put("sixpenny_pie", F1, true)
	_into("pill_bug", F1)
	_into("field_vole", F1)
	_kit.fight_board(_foe(99))
	assert_eq(_player.gold_next_turn, 2)


func test_frumenty_has_the_text_of_what_is_inside_in_a_fight() -> void:
	_kit.put("frumenty", F1)
	_into("hedge_witch", F1)
	var result: Dictionary = _kit.fight_board(_foe(0))
	assert_eq(KIT.of_type(result, "slot_hex").size(), 1, "the Witch's Hex, from her slot")


func test_frumenty_has_the_text_in_the_recruit_phase() -> void:
	_kit.card(
		"payer", [KIT.effect("end_of_turn", {"effect": "gold", "amount": 2, "when": "next_turn"})]
	)
	_kit.put("frumenty", F1)
	_into("payer", F1)
	_rules.end_phase(_player)
	assert_eq(_player.gold_next_turn, 2)


func test_frumenty_doesnt_borrow_belly_fly_south_or_when_played() -> void:
	var fru: RecruitUnit = _kit.put("frumenty", F1)
	_into("sixpenny_pie", F1)
	assert_eq(HeldUnits.belly_size(fru), 1, "her own Belly only")
	fru.held.clear()
	_into("one_swallow", F1)
	fru.origin = RecruitUnit.ORIGIN_BOUGHT
	var borrowed: Array[Dictionary] = fru.borrowed_text()
	assert_eq(borrowed.size(), 0, "Fly South and When played don't lend")
	_rules.sell(_player, F1)
	assert_eq(_player.away.size(), 0, "she doesn't fly")


func test_frumentys_borrowed_aura_counts() -> void:
	var fru: RecruitUnit = _kit.put("frumenty", F1)
	_bird_away(F2)
	_into("mr_redbreast", F1)
	assert_eq(fru.aura_attack, 1, "Redbreast's text, in her")


func _bird_away(slot: int) -> void:
	var bird: RecruitUnit = _kit.put("mrs_jay", slot)
	bird.origin = RecruitUnit.ORIGIN_BOUGHT
	_rules.sell(_player, slot)


func test_syllabub_fires_start_of_combat_text_of_what_comes_out() -> void:
	_kit.put("mrs_posset", F1)
	_into("hedge_witch", F1)
	_kit.put("mr_syllabub", B2)
	var result: Dictionary = _kit.fight_board(_foe(9))
	assert_eq(KIT.of_type(result, "slot_hex").size(), 1, "off it goes at the bell it missed")


func test_golden_syllabub_fires_it_twice() -> void:
	_kit.put("mrs_posset", F1)
	_into("hedge_witch", F1)
	_kit.put("mr_syllabub", B2, true)
	var result: Dictionary = _kit.fight_board(_foe(9))
	assert_eq(KIT.of_type(result, "slot_hex").size(), 2)


func test_syllabub_doesnt_fire_for_a_plain_summon() -> void:
	_kit.card("dropper", [KIT.effect("on_death", {"effect": "summon", "unit": "hedge_witch"})])
	_kit.put("dropper", F1)
	_kit.put("mr_syllabub", B2)
	var result: Dictionary = _kit.fight_board(_foe(9))
	assert_eq(_fought_triggers(result, "syllabub"), 0)


func test_hasty_swallows_the_enemy_across() -> void:
	_kit.put("hasty_pudding", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "field_vole", "attack": 50, "health": 50}, F2: {"def_id": "marsh_frog"}}
	)
	var gone: Array[Dictionary] = KIT.of_type(result, "swallowed")
	assert_eq(gone.size(), 1)
	assert_eq(gone[0]["slot"], F1)
	assert_eq(gone[0]["side"], 1)


func test_hasty_with_a_full_belly_swallows_nobody() -> void:
	_kit.put("hasty_pudding", F1)
	_into("pill_bug", F1)
	var result: Dictionary = _kit.fight_board(_foe(1))
	assert_eq(KIT.of_type(result, "swallowed").size(), 0)


func test_a_swallowed_enemy_goes_back_when_the_pudding_dies() -> void:
	_kit.put("hasty_pudding", F1)
	var result: Dictionary = _kit.fight_board(
		{
			F1: {"def_id": "field_vole", "attack": 3, "health": 50},
			F2: {"def_id": "marsh_frog", "attack": 50, "health": 50}
		}
	)
	var back: Array = []
	for event: Dictionary in KIT.of_type(result, "summon"):
		if event.get("came_out", false):
			back.append(event)
	assert_eq(back[0]["side"], 1, "its own side")
	assert_eq(back[0]["slot"], F1, "its own slot")


func test_a_swallowed_enemy_goes_back_after_3_of_your_units_die() -> void:
	_kit.put("hasty_pudding", B3)
	_kit.put("kit", F1)
	_kit.put("kit", F2)
	_kit.put("kit", F3)
	_kit.put("mr_syllabub", F4)
	var result: Dictionary = _kit.fight_board(
		{
			B3: {"def_id": "field_vole", "attack": 1, "health": 50},
			F1: {"def_id": "marsh_frog", "attack": 2, "health": 500}
		}
	)
	var back: Array = KIT.of_type(result, "summon")
	var returned: bool = false
	for event: Dictionary in back:
		returned = returned or (event.get("came_out", false) and event["side"] == 1)
	assert_true(returned)


func test_a_swallowed_enemy_goes_back_when_its_side_has_nobody_else() -> void:
	_kit.put("hasty_pudding", F1)
	var result: Dictionary = _kit.fight_board(_foe(1, 3))
	assert_eq(KIT.of_type(result, "swallowed").size(), 1)
	var back: Array = KIT.of_type(result, "summon")
	assert_eq(back.size(), 1, "it was the only one, so it came straight back")


func test_two_puddings_across_dont_deadlock() -> void:
	_kit.put("hasty_pudding", F1)
	_kit.put("pill_bug", F4)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "hasty_pudding"}, F2: {"def_id": "kit"}}
	)
	assert_eq(
		KIT.of_type(result, "swallowed").size(), 1, "the first swallows the other, so it can't"
	)


func test_golden_hasty_swallows_two() -> void:
	_kit.put("hasty_pudding", F2, true)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "field_vole"}, F3: {"def_id": "marsh_frog"}, B1: {"def_id": "kit"}}
	)
	assert_eq(KIT.of_type(result, "swallowed").size(), 2)


func test_a_swallowed_unit_doesnt_count_for_damage_if_you_win() -> void:
	_kit.put("hasty_pudding", F1)
	_player.board[F1].add_permanent(50, 50)
	_player.tier = 1
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "field_vole", "attack": 1, "health": 1}, F2: {"def_id": "kit"}}
	)
	assert_eq(result["winner"], 0)
	var carry: Array = KIT.of_type(result, "combat_end")[0]["survivors"][1]
	assert_eq(carry.size(), 0)


func test_figgy_makes_a_golden_from_two_bought_copies_with_no_reward() -> void:
	_kit.put("figgy_duff", B1)
	var inner: RecruitUnit = _kit.put("field_vole")
	inner.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(_rules.swallow(_player, HeldUnits.HAND, 0, B1), "")
	var other: RecruitUnit = _kit.put("field_vole", F1)
	other.origin = RecruitUnit.ORIGIN_BOUGHT
	_rules.check_triples(_player)
	assert_eq(_player.board[B1].held.size(), 0)
	assert_null(_player.board[F1])
	var golden: RecruitUnit = _player.hand[0]
	assert_true(golden.golden)
	assert_false(golden.reward_pending, "no Triple Reward")


func test_figgy_needs_both_bought() -> void:
	_kit.put("figgy_duff", B1)
	var inner: RecruitUnit = _kit.put("field_vole")
	inner.origin = RecruitUnit.ORIGIN_BOUGHT
	_rules.swallow(_player, HeldUnits.HAND, 0, B1)
	_kit.put("field_vole", F1)
	_rules.check_triples(_player)
	assert_eq(_player.board[B1].held.size(), 1, "the other was Created")


func test_figgy_needs_one_inside() -> void:
	_kit.put("figgy_duff", B1)
	var one: RecruitUnit = _kit.put("field_vole", F1)
	var two: RecruitUnit = _kit.put("field_vole", F2)
	one.origin = RecruitUnit.ORIGIN_BOUGHT
	two.origin = RecruitUnit.ORIGIN_BOUGHT
	_rules.check_triples(_player)
	assert_eq(_player.board[F1], one)


func test_figgy_fires_once_a_turn() -> void:
	_kit.put("figgy_duff", B1, true)
	for id: String in ["field_vole", "marsh_frog"]:
		var inner: RecruitUnit = _kit.put(id)
		inner.origin = RecruitUnit.ORIGIN_BOUGHT
		_rules.swallow(_player, HeldUnits.HAND, _player.hand.find(inner), B1)
		var other: RecruitUnit = _kit.put(id, F1 if id == "field_vole" else F2)
		other.origin = RecruitUnit.ORIGIN_BOUGHT
	_rules.check_triples(_player)
	assert_eq(_player.board[B1].held.size(), 1, "one pair this turn")
	_kit.pass_turn()
	assert_eq(_player.board[B1].held.size(), 0, "the next turn, the other")


func test_cut_and_come_gives_a_plain_copy_every_other_turn() -> void:
	var cut: RecruitUnit = _kit.put("cut_and_come_again", B1)
	var inner: RecruitUnit = _into("pill_bug", B1)
	inner.add_permanent(5, 5)
	_kit.pass_turn()
	assert_eq(_player.hand.size(), 0, "the first turn counts")
	_kit.pass_turn()
	assert_eq(_player.hand.size(), 1, "the second pays")
	var copy: RecruitUnit = _player.hand[0]
	assert_eq(copy.def_id(), "pill_bug")
	assert_eq(copy.perm_attack, 0, "plain")
	assert_eq(copy.origin, RecruitUnit.ORIGIN_CREATED)
	assert_eq(copy.pool_copies, 0)
	assert_eq(cut.held[0], inner, "the one inside stays")


func test_cut_and_come_copies_dont_count_for_triples() -> void:
	_kit.put("cut_and_come_again", B1)
	_into("pill_bug", B1)
	for _time: int in 4:
		_kit.pass_turn()
	assert_eq(_player.hand.size(), 2)
	_rules.check_triples(_player)
	assert_eq(_player.hand.size(), 2, "three copies and no golden")
	assert_false(_player.hand[0].golden)


func test_cut_and_come_skips_oozes_inside() -> void:
	_kit.put("cut_and_come_again", B1, true)
	_into("pill_bug", B1)
	_into("mrs_posset", B1)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_player.hand.size(), 2, "golden: two copies")
	assert_eq(_player.hand[0].def_id(), "pill_bug", "the last non-Ooze")


func test_cut_and_come_with_nothing_inside_waits() -> void:
	_kit.put("cut_and_come_again", B1)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_player.hand.size(), 0)
	_into("pill_bug", B1)
	_kit.pass_turn()
	assert_eq(_player.hand.size(), 1, "it was ready")


func test_granny_takes_touching_oozes_inside_and_gains_their_attack_only() -> void:
	_kit.put("granny_stir_up", F2)
	var left: RecruitUnit = _kit.put("mrs_posset", B1)
	_kit.put("pill_bug", F4)
	var result: Dictionary = _kit.fight_board(_foe(0, 50))
	var gone: Array[Dictionary] = KIT.of_type(result, "swallowed")
	assert_eq(gone.size(), 1)
	assert_eq(gone[0]["slot"], B1)
	var stats: Dictionary = KIT.of_type(result, "stats")[0]
	assert_eq(stats["attack_delta"], left.attack)
	assert_eq(stats["health_delta"], 0, "no Health: that was the runaway")


func test_a_gap_cuts_who_joins_granny() -> void:
	_kit.put("granny_stir_up", F1)
	_kit.put("mrs_posset", F2)
	var result: Dictionary = _kit.fight_board(_foe(0, 50))
	assert_eq(KIT.of_type(result, "swallowed").size(), 0, "B1 is empty, so F2 doesn't touch")


func test_others_in_grannys_run_stay_put() -> void:
	_kit.put("granny_stir_up", F1)
	_kit.put("pill_bug", B1)
	var result: Dictionary = _kit.fight_board(_foe(0, 50))
	assert_eq(KIT.of_type(result, "swallowed").size(), 0)


func test_grannys_oozes_return_to_their_slots_still_holding_when_she_dies() -> void:
	_kit.put("granny_stir_up", F2)
	_kit.put("mrs_posset", B1)
	_into("pill_bug", B1)
	var result: Dictionary = _kit.fight_board(_foe(99))
	var back: Array = []
	for event: Dictionary in KIT.of_type(result, "summon"):
		if event["unit"]["def_id"] == "mrs_posset":
			back.append(event)
	assert_eq(back[0]["slot"], B1)
	assert_eq(back[0]["unit"]["held"], 1, "still holding")


func test_golden_granny_doubles_the_attack() -> void:
	_kit.put("granny_stir_up", F2, true)
	var left: RecruitUnit = _kit.put("mrs_posset", B1)
	var result: Dictionary = _kit.fight_board(_foe(0, 50))
	var stats: Dictionary = KIT.of_type(result, "stats")[0]
	assert_eq(stats["attack_delta"], left.attack * 2)
