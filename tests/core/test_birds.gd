# gdlint: disable=max-public-methods
extends GutTest
## Frozen pass 2 design regression; current pool rules are tested in test_pass3_*.
## Revised Birds pass 1: both homecoming and Hatchery use the same current-stat Birds.
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
	_kit.setup(GameConfig.full_game(), true)
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)
	_player.shop.clear()
	_player.gold = 10


func _away(id: String, slot: int, golden: bool = false) -> RecruitUnit:
	var bird: RecruitUnit = _kit.put(id, slot, golden)
	bird.origin = RecruitUnit.ORIGIN_BOUGHT
	_rules.sell(_player, slot)
	return bird


func _triggered(result: Dictionary, mechanic: String) -> int:
	var count: int = 0
	for event: Dictionary in KIT.of_type(result, "trigger"):
		count += 1 if event["mechanic"] == mechanic else 0
	return count


func test_swallow_next_to_a_bird_pays_1() -> void:
	_kit.put("tom_tit", F1)
	_kit.play("one_swallow", F2)
	assert_eq(_player.gold, 11)


func test_swallow_alone_pays_1() -> void:
	_kit.play("one_swallow", F2)
	assert_eq(_player.gold, 11)


func test_swallow_next_to_another_tribe_pays_1() -> void:
	_kit.put("pill_bug", F1)
	_kit.play("one_swallow", F2)
	assert_eq(_player.gold, 11)


func test_golden_swallow_pays_2() -> void:
	_kit.put("tom_tit", F1)
	_kit.play("one_swallow", F2, true)
	assert_eq(_player.gold, 12)


func test_dunnock_beside_the_nest_shortens_one_trip_and_keeps_the_egg() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_dunnock", F1)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F2)["due"], _player.round_number + 1)
	var egg: Dictionary = _player.combat_board()[F2]
	assert_eq(egg["def_id"], "nest_egg", "the Egg keeps fighting")
	assert_false(_player.hand.has(bird), "never home earlier than next turn")
	_rules.after_fights(_player)
	_rules.start_phase(_player, _player.round_number + 1)
	assert_true(_player.hand.has(bird))


func test_dunnock_on_the_nest_does_not_shorten_its_trip() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_dunnock", F2)
	_kit.pass_turn()
	assert_false(_player.hand.has(bird))


func test_dunnock_does_not_reach_the_other_row() -> void:
	_away("mrs_jay", F2)
	_kit.put("mrs_dunnock", B1)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F2)["due"], _player.round_number + 2)


func test_golden_dunnock_never_sooner_than_next_turn() -> void:
	var bird: RecruitUnit = _away("old_tern", F2)
	_kit.put("mrs_dunnock", F1, true)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F2)["due"], _player.round_number + 1)
	_rules.after_fights(_player)
	_rules.start_phase(_player, _player.round_number + 1)
	assert_true(_player.hand.has(bird))


func test_dunnock_shortens_only_one_eligible_nest_in_reading_order() -> void:
	_away("old_tern", F1)
	_away("old_tern", F3)
	_kit.put("mrs_dunnock", F2)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F1)["due"], _player.round_number + 1)
	assert_eq(_player.nest_at(F3)["due"], _player.round_number + 2)


func test_dunnock_skips_a_nest_due_next_turn_and_shortens_the_next_eligible_one() -> void:
	_away("mrs_jay", F1)
	_away("old_tern", F3)
	_player.nest_at(F1)["due"] = _player.round_number + 1
	_kit.put("mrs_dunnock", F2)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F1)["due"], _player.round_number + 1)
	assert_eq(_player.nest_at(F3)["due"], _player.round_number + 1)


func test_chiffchaff_grows_itself_when_played_and_keeps_the_growth_away() -> void:
	var other: RecruitUnit = _kit.put("pill_bug", F1)
	var chiff: RecruitUnit = _kit.play("chiffchaff", F2)
	assert_eq(Vector2i(chiff.attack, chiff.health), Vector2i(2, 3))
	assert_eq(Vector2i(other.attack, other.health), Vector2i(1, 4))
	_kit.pass_turn()
	_rules.sell(_player, F2)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_rules.play(_player, _player.hand.find(chiff), F2), "")
	assert_eq(Vector2i(chiff.attack, chiff.health), Vector2i(3, 4))


func test_golden_chiffchaff_grows_by_two() -> void:
	var chiff: RecruitUnit = _kit.play("chiffchaff", F1, true)
	assert_eq(Vector2i(chiff.attack, chiff.health), Vector2i(4, 6))


func test_tom_tit_reaches_all_eggs_in_both_rows() -> void:
	_away("mrs_jay", F1)
	_away("mother_goose", B3)
	_kit.put("tom_tit", B1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "kit", "health": 99}})
	var board: Array = KIT.of_type(result, "combat_start")[0]["boards"][0]
	assert_eq(Vector2i(board[F1]["attack"], board[F1]["health"]), Vector2i(2, 3))
	assert_eq(Vector2i(board[B3]["attack"], board[B3]["health"]), Vector2i(2, 7))


func test_only_strongest_tom_tit_counts_and_matches_forecast() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F1)
	_kit.put("tom_tit", B1)
	_kit.put("tom_tit", B2, true)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "kit", "health": 99}})
	var egg: Dictionary = KIT.of_type(result, "combat_start")[0]["boards"][0][F1]
	var forecast: Dictionary = HeldUnits.egg_forecast(_player, bird, F1)
	assert_eq(Vector2i(egg["attack"], egg["health"]), Vector2i(3, 3))
	assert_eq(egg["attack"], forecast["attack"])
	assert_eq(egg["health"], forecast["health"])


func test_tom_tit_adds_after_redwing_and_reaches_normal_goose_egg() -> void:
	var bird: RecruitUnit = _away("mother_goose", F1)
	bird.add_permanent(3, 2)
	_kit.put("redwing", F2, true)
	_kit.put("tom_tit", B1)
	var forecast: Dictionary = HeldUnits.egg_forecast(_player, bird, F1)
	assert_eq(Vector2i(forecast["attack"], forecast["health"]), Vector2i(9, 11))
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "kit", "health": 99}})
	var egg: Dictionary = KIT.of_type(result, "combat_start")[0]["boards"][0][F1]
	assert_eq(Vector2i(egg["attack"], egg["health"]), Vector2i(9, 11))


func test_tom_tit_aura_is_lost_when_tit_dies() -> void:
	_away("mrs_jay", B3)
	var tit: RecruitUnit = _kit.put("tom_tit", F1)
	tit.add_permanent(0, -3)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "kit", "attack": 99, "health": 99}})
	var lost: bool = false
	for event: Dictionary in KIT.of_type(result, "stats"):
		if event["attack_delta"] == 0 and event["health_delta"] == -1:
			lost = true
	assert_true(lost, "Egg loses its aura without losing permanent Bird growth")


func test_tom_tit_no_longer_swoops_or_pays_for_kills() -> void:
	var tit: RecruitUnit = _kit.put("tom_tit", F1)
	tit.add_permanent(0, 50)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "kit", "health": 1}})
	assert_eq(_triggered(result, "swoop"), 0)
	assert_eq(_player.gold_next_turn, 0)


func test_cuckoo_sets_longer_trip_only_when_the_bird_flies() -> void:
	_kit.put("cuckoo", F2)
	var jay: RecruitUnit = _away("mrs_jay", F1)
	assert_eq(_player.nest_at(F1)["due"], _player.round_number + 3)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F1)["due"], _player.round_number + 3)
	assert_eq(Vector2i(jay.attack, jay.health), Vector2i(5, 5))
	var egg: Dictionary = HeldUnits.egg_forecast(_player, jay, F1)
	assert_eq(Vector2i(egg["attack"], egg["health"]), Vector2i(3, 3))
	_rules.move_on_board(_player, F2, F4)
	_rules.end_phase(_player)
	assert_eq(Vector2i(jay.attack, jay.health), Vector2i(5, 5), "growth follows current position")
	assert_eq(_player.nest_at(F1)["due"], _player.round_number + 3)


func test_cuckoo_grows_both_beside_nests_even_when_covered() -> void:
	_kit.put("cuckoo", F2)
	var one: RecruitUnit = _away("mrs_jay", F1)
	var two: RecruitUnit = _away("chiffchaff", F3)
	_kit.put("great_lump", F1)
	_rules.end_phase(_player)
	assert_eq(Vector2i(one.perm_attack, one.perm_health), Vector2i(2, 2))
	assert_eq(Vector2i(two.perm_attack, two.perm_health), Vector2i(2, 2))


func test_golden_cuckoo_extends_two_turns_and_grows_four() -> void:
	_kit.put("cuckoo", F2, true)
	var bird: RecruitUnit = _away("mrs_jay", F1)
	assert_eq(_player.nest_at(F1)["due"], _player.round_number + 4)
	_rules.end_phase(_player)
	assert_eq(Vector2i(bird.perm_attack, bird.perm_health), Vector2i(4, 4))


func test_cuckoo_added_after_departure_does_not_extend_existing_trip() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F1)
	_kit.put("cuckoo", F2)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_true(_player.hand.has(bird))
	assert_eq(Vector2i(bird.perm_attack, bird.perm_health), Vector2i(4, 4))


func test_lump_on_a_nest_has_half_the_birds_current_stats() -> void:
	var bird: RecruitUnit = _away("mother_goose", F2)
	bird.add_permanent(30, 30)
	var lump: RecruitUnit = _kit.put("great_lump", F2)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 3 + 17, "half of 34 Attack")
	assert_eq(lump.health, 5 + 19, "half of 37 Health, rounded up")


func test_lump_off_a_nest_is_plain() -> void:
	_away("mother_goose", F2)
	var lump: RecruitUnit = _kit.put("great_lump", F3)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 3)


func test_lump_has_the_same_stats_in_a_fight() -> void:
	_away("mother_goose", F2)
	_kit.put("great_lump", F2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 0, "health": 9}}
	)
	var lump: Dictionary = KIT.of_type(result, "combat_start")[0]["boards"][0][F2]
	assert_eq(lump["attack"], 5)
	assert_eq(lump["health"], 9)


func test_lump_shrinks_when_the_bird_lands() -> void:
	_away("mrs_jay", F2)
	var lump: RecruitUnit = _kit.put("great_lump", F2)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 5)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(lump.attack, 3)


func test_golden_lump_has_full_current_stats() -> void:
	_away("mrs_jay", F2)
	var lump: RecruitUnit = _kit.put("great_lump", F2, true)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 6 + 3)


func test_redbreast_grows_per_nest_on_the_board_and_in_the_fight() -> void:
	_away("mrs_jay", F2)
	_away("one_swallow", F3)
	var robin: RecruitUnit = _kit.put("mr_redbreast", F1)
	_rules.board_changed(_player)
	assert_eq(robin.attack, 2 + 2)
	assert_eq(robin.health, 4 + 2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 0, "health": 9}}
	)
	assert_eq(KIT.of_type(result, "combat_start")[0]["boards"][0][F1]["attack"], 4)


func test_golden_redbreast_gets_2_per_nest() -> void:
	_away("mrs_jay", F2)
	var robin: RecruitUnit = _kit.put("mr_redbreast", F1, true)
	_rules.board_changed(_player)
	assert_eq(robin.attack, 4 + 2)


func test_jay_gets_an_acorn_each_flight() -> void:
	_away("mrs_jay", F1)
	assert_eq(_kit.item_ids(), ["acorn"])


func test_golden_jay_gets_two() -> void:
	_away("mrs_jay", F1, true)
	assert_eq(_kit.item_ids(), ["acorn", "acorn"])


func test_daw_takes_two_attack_without_health_or_gold() -> void:
	_kit.put("jack_daw", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 9, "health": 200}}
	)
	assert_eq(_triggered(result, "jack_daw"), 1)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[1]["attack_delta"], 2)
	assert_eq(stats[1]["health_delta"], 0)
	assert_eq(_player.gold_next_turn, 0)


func test_daw_takes_attack_from_a_plain_card_and_never_goes_below_zero() -> void:
	_kit.put("jack_daw", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug"}})
	assert_eq(_triggered(result, "jack_daw"), 1)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -1)
	assert_eq(_player.gold_next_turn, 0)


func test_golden_daw_steals_four_attack_without_gold() -> void:
	_kit.put("jack_daw", F1, true)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 200, "health": 200}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[1]["attack_delta"], 4)
	assert_eq(_player.gold_next_turn, 0)


func test_tern_returns_after_two_turns_without_a_discover() -> void:
	_player.tier = 3
	var tern: RecruitUnit = _away("old_tern", F1)
	_kit.pass_turn()
	assert_false(_player.hand.has(tern), "two turns")
	_kit.pass_turn()
	assert_true(_player.hand.has(tern))
	assert_true(_player.pending.is_empty())


func test_golden_tern_returns_after_one_turn() -> void:
	var tern: RecruitUnit = _away("old_tern", F1, true)
	_kit.pass_turn()
	assert_true(_player.hand.has(tern))
	assert_true(_player.pending.is_empty())


func test_stork_brings_home_a_bird_that_has_missed_a_fight_after_6_gold() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_stork", F1)
	_kit.pass_turn()
	assert_false(_player.hand.has(bird))
	_player.gold = 20
	_rules.spend(_player, 3)
	assert_false(_player.hand.has(bird), "3 of 6")
	_rules.spend(_player, 3)
	assert_true(_player.hand.has(bird))
	assert_eq(_player.nest_count(), 0)


func test_stork_takes_the_bird_away_longest() -> void:
	var older: RecruitUnit = _away("mrs_jay", F2)
	_player.nest_at(F2)["due"] = _player.round_number + 4
	_kit.pass_turn()
	var newer: RecruitUnit = _away("one_swallow", F3)
	_kit.put("mrs_stork", F1)
	_kit.pass_turn()
	_player.gold = 20
	_rules.spend(_player, 6)
	assert_true(_player.hand.has(older))
	assert_false(_player.hand.has(newer))


func test_golden_stork_brings_two() -> void:
	var one: RecruitUnit = _away("old_tern", F2)
	var two: RecruitUnit = _away("old_tern", F3)
	_kit.put("mrs_stork", F1, true)
	_kit.pass_turn()
	_player.gold = 20
	_rules.spend(_player, 6)
	assert_true(_player.hand.has(one))
	assert_true(_player.hand.has(two))


func test_a_bird_stork_brought_home_cant_fly_again_this_turn_once_played() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_stork", F1)
	_kit.pass_turn()
	_player.gold = 20
	_rules.spend(_player, 6)
	_rules.play(_player, _player.hand.find(bird), F2)
	_rules.sell(_player, F2)
	assert_eq(_player.away.size(), 0, "a plain sale")


func test_stork_counts_refreshes() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_stork", F1)
	_kit.pass_turn()
	_player.gold = 20
	for _time: int in 6:
		_rules.refresh(_player)
	assert_true(_player.hand.has(bird), "gold spent is gold spent")


func test_pye_takes_the_text_of_the_enemy_across_first_of_all() -> void:
	_kit.put("mag_pye", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "hedge_witch"}, F2: {"def_id": "kit"}}
	)
	assert_eq(KIT.of_type(result, "text_taken").size(), 1)
	var hexes: Array[Dictionary] = KIT.of_type(result, "slot_hex")
	assert_eq(hexes.size(), 1, "the Witch's Hex fired once, from Pye")
	assert_eq(hexes[0]["side"], 1, "and it now hits the Witch's own side")


func test_pye_doesnt_take_a_belly() -> void:
	_kit.put("mag_pye", F1)
	var ooze: Dictionary = _player_spec("mrs_posset", "pill_bug")
	var result: Dictionary = _kit.fight_board({F1: ooze, F2: {"def_id": "kit", "health": 99}})
	assert_eq(KIT.of_type(result, "text_taken").size(), 1, "its death text goes")
	var outs: Array = []
	for event: Dictionary in KIT.of_type(result, "summon"):
		if event.get("came_out", false):
			outs.append(event["side"])
	assert_eq(outs, [1], "the Belly still opens, on its own side")


func _player_spec(id: String, inside: String) -> Dictionary:
	return {"def_id": id, "golden": false, "held": [{"def_id": inside, "golden": false}]}


func test_pye_takes_nothing_from_a_textless_unit() -> void:
	_kit.put("mag_pye", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "kit", "attack": 0, "health": 3}})
	assert_eq(KIT.of_type(result, "text_taken").size(), 0)


func test_golden_pye_also_takes_from_the_next_slot_along() -> void:
	_kit.put("mag_pye", F2, true)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "hedge_witch"}, F3: {"def_id": "hedge_witch"}}
	)
	assert_eq(KIT.of_type(result, "text_taken").size(), 2)


func test_goose_away_each_nest_strikes_across_for_flat_two() -> void:
	var goose: RecruitUnit = _away("mother_goose", F1)
	goose.add_permanent(50, 0)
	_away("mrs_jay", F2)
	_kit.put("pill_bug", F3)
	var result: Dictionary = _kit.fight_board(
		{
			F1: {"def_id": "pill_bug", "health": 100, "attack": 0},
			F2: {"def_id": "pill_bug", "health": 100, "attack": 0}
		}
	)
	var strikes: Array[Dictionary] = KIT.of_type(result, "goose_strike")
	assert_eq(strikes.size(), 2, "her own Nest too")
	var amounts: Array = []
	for event: Dictionary in KIT.of_type(result, "damage"):
		if event["source"] == null:
			amounts.append(event["amount"])
	assert_eq(amounts, [2, 2], "neither base nor current Bird Attack")


func test_goose_at_home_strikes_nothing() -> void:
	_kit.put("mother_goose", F1)
	_away("mrs_jay", F2)
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "health": 100}})
	assert_eq(KIT.of_type(result, "goose_strike").size(), 0)


func test_a_nest_with_nobody_across_is_wasted() -> void:
	_away("mother_goose", F1)
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "health": 100}})
	assert_eq(KIT.of_type(result, "goose_strike").size(), 0)


func test_two_geese_strike_as_one() -> void:
	_away("mother_goose", F1)
	_away("mother_goose", F2)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 100}})
	assert_eq(KIT.of_type(result, "goose_strike").size(), 1, "one Goose per side, F1's Nest once")


func test_golden_goose_strikes_once_for_four() -> void:
	_away("mother_goose", F1, true)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 100}})
	assert_eq(KIT.of_type(result, "goose_strike").size(), 1)
	var damage: Dictionary = KIT.of_type(result, "damage")[0]
	assert_eq(damage["amount"], 4)


func test_goose_ignores_ring_on_the_slot() -> void:
	_away("mrs_jay", F2)
	_away("mother_goose", F1)
	_player.slot_effects[F2] = [{"name": "Ring", "attack": 9, "health": 0}]
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "health": 100}})
	for event: Dictionary in KIT.of_type(result, "damage"):
		if event["source"] == null:
			assert_eq(event["amount"], 2, "flat damage ignores the Ring")


func test_ratchet_lands_the_bird_when_the_egg_on_its_nest_dies() -> void:
	_away("mrs_jay", F2)
	_kit.put("gabble_ratchet", B3)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 5, "health": 500}}
	)
	var landed: Array[Dictionary] = []
	for event: Dictionary in KIT.of_type(result, "summon"):
		if event.get("landed", false):
			landed.append(event)
	assert_eq(landed.size(), 1)
	assert_eq(str(landed[0]["unit"]["def_id"]), "mrs_jay")
	assert_eq(landed[0]["slot"], F2)


func test_ratchet_lands_for_a_real_unit_on_the_nest_too() -> void:
	_away("mrs_jay", F2)
	_kit.put("pill_bug", F2)
	_kit.put("gabble_ratchet", B3)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 99, "health": 500}}
	)
	assert_eq(_triggered(result, "gabble_ratchet"), 1)


func test_ratchet_ignores_deaths_off_a_nest() -> void:
	_kit.put("pill_bug", F1)
	_kit.put("gabble_ratchet", B3)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 99, "health": 500}}
	)
	assert_eq(_triggered(result, "gabble_ratchet"), 0)


func test_each_bird_lands_once_with_two_ratchets() -> void:
	_away("mrs_jay", F2)
	_kit.put("gabble_ratchet", B3)
	_kit.put("gabble_ratchet", B2)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 5, "health": 500}}
	)
	assert_eq(_triggered(result, "gabble_ratchet"), 1)


func test_golden_ratchet_doubles_current_attack_before_slot_bonuses() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	bird.add_permanent(5, 7)
	_player.slot_effects[F2] = [{"name": "Ring", "attack": 3, "health": 2}]
	_kit.put("gabble_ratchet", B3, true)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 50, "health": 500}}
	)
	for event: Dictionary in KIT.of_type(result, "summon"):
		if event.get("landed", false):
			assert_eq(event["unit"]["attack"], 16, "(3 + 5) * 2 before auras")
			assert_eq(event["unit"]["health"], 10, "3 + 7 before auras")
			for stats: Dictionary in KIT.of_type(result, "stats"):
				if stats["target"] == event["unit"]["uid"]:
					assert_eq(stats["attack_delta"], 3, "Ring applies once after landing")
					assert_eq(stats["health_delta"], 2)
					return
			fail_test("the landed Bird did not receive its slot bonus")
			return
	fail_test("the Nest's Bird did not land")


func test_ratchet_landing_never_ends_the_trip_or_counts_as_homecoming() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	bird.add_permanent(5, 7)
	var due: int = _player.nest_at(F2)["due"]
	_kit.put("gabble_ratchet", B3)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 50, "health": 500}}
	)
	assert_eq(_triggered(result, "gabble_ratchet"), 1)
	assert_eq(_player.nest_at(F2)["due"], due)
	assert_eq(_player.away.size(), 1)
	assert_false(_player.hand.has(bird))
	assert_eq(_player.homecomings_this_turn, 0)
	var egg: Dictionary = _player.combat_board()[F2]
	assert_eq(egg["def_id"], HeldUnits.EGG)
	assert_eq(Vector2i(egg["attack"], egg["health"]), Vector2i(4, 5))


func test_whistlers_hits_only_enemies_across_birds() -> void:
	_player.homecomings_this_turn = 1
	_kit.put("mrs_jay", F1)
	_kit.put("seven_whistlers", B3)
	_kit.put("pill_bug", F2)
	var result: Dictionary = _kit.fight_board(
		{
			F1: {"def_id": "pill_bug", "attack": 8, "health": 40},
			F2: {"def_id": "pill_bug", "attack": 8, "health": 40},
			B3: {"def_id": "pill_bug", "attack": 8, "health": 40}
		}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats.size(), 2)
	for event: Dictionary in stats:
		assert_eq(event["attack_delta"], -1)
		assert_eq(event["health_delta"], -1)
	var across_neutral: int = KIT.of_type(result, "combat_start")[0]["boards"][1][F2]["uid"]
	assert_ne(stats[0]["target"], across_neutral)
	assert_ne(stats[1]["target"], across_neutral)


func test_whistlers_full_flock_still_loses_only_one_per_target() -> void:
	_player.homecomings_this_turn = 1
	for slot: int in [F1, F2, F3, F4, B1, B2]:
		_kit.put("mrs_jay", slot)
	_kit.put("seven_whistlers", B3)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 20, "health": 40}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -1)
	assert_eq(stats[0]["health_delta"], -1)


func test_whistlers_does_not_target_an_away_birds_egg() -> void:
	_player.homecomings_this_turn = 1
	_away("mrs_jay", F1)
	_kit.put("seven_whistlers", B3)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 8, "health": 40}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats.size(), 0, "an Egg is not a Bird")


func test_golden_whistlers_loses_two_per_target() -> void:
	_player.homecomings_this_turn = 1
	for slot: int in [F1, F2, F3, F4, B1, B2]:
		_kit.put("mrs_jay", slot)
	_kit.put("seven_whistlers", B3, true)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 20, "health": 40}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -2)
	assert_eq(stats[0]["health_delta"], -2)


func test_each_whistlers_fires_as_printed() -> void:
	_player.homecomings_this_turn = 1
	_kit.put("seven_whistlers", F1)
	_kit.put("seven_whistlers", F2)
	var result: Dictionary = _kit.fight_board(
		{
			F1: {"def_id": "pill_bug", "attack": 20, "health": 40},
			F2: {"def_id": "pill_bug", "attack": 20, "health": 40}
		}
	)
	assert_eq(_triggered(result, "whistlers"), 2)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats.size(), 4)


func test_whistlers_health_loss_can_faint_an_enemy_before_attacks() -> void:
	_player.homecomings_this_turn = 1
	_kit.put("seven_whistlers", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 20, "health": 1}}
	)
	assert_eq(result["winner"], 0)
	assert_eq(KIT.of_type(result, "attack").size(), 0, "loss resolves at Start of Combat")


func test_goose_homecoming_permanently_buffs_birds_on_board_in_hand_and_away() -> void:
	var goose: RecruitUnit = _away("mother_goose", F1)
	var away: RecruitUnit = _away("old_tern", F2)
	var board: RecruitUnit = _kit.put("mrs_jay", F3)
	var hand: RecruitUnit = _kit.put("chiffchaff")
	var neutral: RecruitUnit = _kit.put("pill_bug", F4)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_true(_player.hand.has(goose))
	for bird: RecruitUnit in [goose, away, board, hand]:
		assert_eq(Vector2i(bird.perm_attack, bird.perm_health), Vector2i(1, 1))
	assert_eq(Vector2i(neutral.perm_attack, neutral.perm_health), Vector2i.ZERO)
	assert_eq(_player.away.size(), 0, "Tern and Goose return on their two-turn trips")


func test_golden_goose_homecoming_buffs_two() -> void:
	var goose: RecruitUnit = _away("mother_goose", F1, true)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(Vector2i(goose.perm_attack, goose.perm_health), Vector2i(2, 2))


func test_whistlers_without_homecomings_does_nothing() -> void:
	_kit.put("seven_whistlers", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 20, "health": 40}}
	)
	assert_eq(_triggered(result, "whistlers"), 0)


func test_homecomings_count_natural_and_stork_returns_then_reset_next_turn() -> void:
	_away("one_swallow", F1)
	_away("old_tern", F2)
	_kit.put("mrs_stork", F3)
	_kit.pass_turn()
	assert_eq(_player.homecomings_this_turn, 0)
	_player.gold = 20
	_rules.spend(_player, 6)
	assert_eq(_player.homecomings_this_turn, 1)
	_kit.pass_turn()
	assert_eq(_player.homecomings_this_turn, 1, "Tern's natural homecoming counts this turn")
	assert_eq(_rules.fight_rules(_player)["homecomings"], 1)
	_kit.pass_turn()
	assert_eq(_player.homecomings_this_turn, 0, "homecomings clear on the next turn")


func test_whistlers_caps_three_homecomings_and_golden_caps_six_stats() -> void:
	_player.homecomings_this_turn = 8
	_kit.put("seven_whistlers", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 20, "health": 40}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -3)
	assert_eq(stats[0]["health_delta"], -3)
	_player.board[F1] = null
	_kit.put("seven_whistlers", F1, true)
	result = _kit.fight_board({F1: {"def_id": "pill_bug", "attack": 20, "health": 40}})
	stats = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -6)
	assert_eq(stats[0]["health_delta"], -6)


func test_combat_egg_shows_current_bird_stats_and_trip_timer_but_scout_hides_them() -> void:
	_kit.put("cuckoo", F2)
	var bird: RecruitUnit = _away("mrs_jay", F1)
	bird.add_permanent(2, 4)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "kit", "health": 99}})
	var egg: Dictionary = KIT.of_type(result, "combat_start")[0]["boards"][0][F1]
	assert_eq(egg["bird_attack"], 5)
	assert_eq(egg["bird_health"], 7)
	assert_eq(egg["turns_left"], 3)
	_player.remember_fought_board()
	var scout: Dictionary = _player.fought_specs[F1]
	assert_false(scout.has("bird_attack"))
	assert_false(scout.has("bird_health"))
	assert_false(scout.has("turns_left"))


func test_golden_stork_two_homecomings_make_whistlers_give_minus_two() -> void:
	_away("mrs_jay", F1)
	_away("one_swallow", F2)
	_kit.put("mrs_stork", B1, true)
	_kit.put("seven_whistlers", F3)
	_kit.pass_turn()
	_player.gold = 20
	_rules.spend(_player, 6)
	assert_eq(_player.homecomings_this_turn, 2)
	var result: Dictionary = _kit.fight_board(
		{F3: {"def_id": "pill_bug", "attack": 20, "health": 40}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -2)
	assert_eq(stats[0]["health_delta"], -2)


func test_ratchet_cannot_land_elsewhere_when_the_nest_slot_is_filled() -> void:
	_away("mrs_jay", F2)
	# Own death summons precede friendly-death listeners; Belly release follows them.
	_kit.put("hoglet_mother", F2)
	_kit.put("gabble_ratchet", B3)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "attack": 50, "health": 500}}
	)
	assert_eq(_triggered(result, "gabble_ratchet"), 0, "the Hoglet filled the Nest first")
	var failures: int = 0
	for event: Dictionary in KIT.of_type(result, "no_room"):
		if str(event.get("def_id", "")) == "mrs_jay":
			failures += 1
	assert_eq(failures, 1, "one attempted landing per Nest, even after the Hoglet dies")
