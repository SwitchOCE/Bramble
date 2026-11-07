extends GutTest
## The Birds, card by card (docs/ideation/content/birds.md, design-review-2.md, costing-2.md).
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


func test_swallow_pays_when_played_next_to_a_bird() -> void:
	_kit.put("tom_tit", F1)
	_kit.play("one_swallow", F2)
	assert_eq(_player.gold, 11)


func test_swallow_alone_pays_nothing() -> void:
	_kit.play("one_swallow", F2)
	assert_eq(_player.gold, 10)


func test_swallow_next_to_another_tribe_pays_nothing() -> void:
	_kit.put("pill_bug", F1)
	_kit.play("one_swallow", F2)
	assert_eq(_player.gold, 10)


func test_golden_swallow_pays_2() -> void:
	_kit.put("tom_tit", F1)
	_kit.play("one_swallow", F2, true)
	assert_eq(_player.gold, 12)


func test_dunnock_brings_the_bird_of_her_nest_home_a_turn_sooner() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_dunnock", F2)
	_kit.pass_turn()
	assert_true(_player.hand.has(bird), "home next turn, not the one after")


func test_dunnock_off_the_nest_does_nothing() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_dunnock", F3)
	_kit.pass_turn()
	assert_false(_player.hand.has(bird))


func test_golden_dunnock_never_sooner_than_next_turn() -> void:
	var bird: RecruitUnit = _away("old_tern", F2)
	_kit.put("mrs_dunnock", F2, true)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F2)["due"], _player.round_number + 1, "3 less 2")
	_rules.after_fights(_player)
	_rules.start_phase(_player, _player.round_number + 1)
	assert_true(_player.hand.has(bird))


func test_dunnock_stops_at_the_floor() -> void:
	var bird: RecruitUnit = _away("mrs_jay", F2)
	_kit.put("mrs_dunnock", F2, true)
	_rules.end_phase(_player)
	assert_eq(_player.nest_at(F2)["due"], _player.round_number + 1, "2 less 2 would be today")
	assert_false(_player.hand.has(bird))


func test_chiffchaff_gives_the_units_in_front_attack_only() -> void:
	var one: RecruitUnit = _kit.put("pill_bug", F1)
	var two: RecruitUnit = _kit.put("kit", F2)
	var side: RecruitUnit = _kit.put("mrs_posset", F3)
	var stats: Array[Vector2i] = [
		Vector2i(one.attack, one.health), Vector2i(two.attack, two.health), Vector2i(side.attack, side.health)
	]
	_kit.play("chiffchaff", B1)
	assert_eq(Vector2i(one.attack, one.health), stats[0] + Vector2i(1, 0))
	assert_eq(Vector2i(two.attack, two.health), stats[1] + Vector2i(1, 0))
	assert_eq(Vector2i(side.attack, side.health), stats[2], "B1 reaches F1 and F2 only")


func test_golden_chiffchaff_gives_2() -> void:
	var one: RecruitUnit = _kit.put("pill_bug", F1)
	var attack: int = one.attack
	_kit.play("chiffchaff", B1, true)
	assert_eq(one.attack, attack + 2)


func test_tom_tit_swoops_at_the_back_row_from_either_row() -> void:
	for slot: int in [F1, B2]:
		_player.board[F1] = null
		_player.board[B2] = null
		_kit.put("tom_tit", slot)
		var result: Dictionary = _kit.fight_board(
			{F1: {"def_id": "pill_bug", "attack": 0, "health": 50}, B3: {"def_id": "kit", "attack": 0, "health": 50}}
		)
		var attack: Dictionary = KIT.of_type(result, "attack")[0]
		var back_uid: int = KIT.of_type(result, "combat_start")[0]["boards"][1][B3]["uid"]
		assert_eq(attack["defender"], back_uid, "past the front row")


func test_tom_tit_attacks_as_usual_with_nobody_in_the_back() -> void:
	_kit.put("tom_tit", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "attack": 0, "health": 50}})
	assert_eq(_triggered(result, "swoop"), 0)
	assert_gt(KIT.of_type(result, "attack").size(), 0)


func test_tom_tit_pays_for_a_kill_once_a_fight() -> void:
	var tit: RecruitUnit = _kit.put("tom_tit", F1)
	tit.add_permanent(0, 50)
	_kit.fight_board(
		{B1: {"def_id": "kit", "attack": 0, "health": 1}, B2: {"def_id": "kit", "attack": 0, "health": 1}}
	)
	assert_eq(_player.gold_next_turn, 1, "two kills, one gold")


func test_tom_tit_without_a_kill_pays_nothing() -> void:
	var tit: RecruitUnit = _kit.put("tom_tit", F1)
	tit.add_permanent(0, 50)
	_kit.fight_board({F1: {"def_id": "kit", "attack": 0, "health": 500}})
	assert_eq(_player.gold_next_turn, 0)


func test_lump_on_a_nest_has_the_birds_card_stats() -> void:
	var bird: RecruitUnit = _away("mother_goose", F2)
	bird.add_permanent(30, 30)
	var lump: RecruitUnit = _kit.put("great_lump", F2)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 1 + 4, "the card's 4, not the buffs")
	assert_eq(lump.health, 3 + 7)


func test_lump_off_a_nest_is_plain() -> void:
	_away("mother_goose", F2)
	var lump: RecruitUnit = _kit.put("great_lump", F3)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 1)


func test_lump_has_the_same_stats_in_a_fight() -> void:
	_away("mother_goose", F2)
	_kit.put("great_lump", F2)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "attack": 0, "health": 9}})
	var lump: Dictionary = KIT.of_type(result, "combat_start")[0]["boards"][0][F2]
	assert_eq(lump["attack"], 5)
	assert_eq(lump["health"], 10)


func test_lump_shrinks_when_the_bird_lands() -> void:
	_away("mrs_jay", F2)
	var lump: RecruitUnit = _kit.put("great_lump", F2)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 3)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(lump.attack, 1)


func test_golden_lump_has_it_twice() -> void:
	_away("mrs_jay", F2)
	var lump: RecruitUnit = _kit.put("great_lump", F2, true)
	_rules.board_changed(_player)
	assert_eq(lump.attack, 2 + 4)


func test_redbreast_grows_per_nest_on_the_board_and_in_the_fight() -> void:
	_away("mrs_jay", F2)
	_away("one_swallow", F3)
	var robin: RecruitUnit = _kit.put("mr_redbreast", F1)
	_rules.board_changed(_player)
	assert_eq(robin.attack, 1 + 2)
	assert_eq(robin.health, 2 + 2)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "attack": 0, "health": 9}})
	assert_eq(KIT.of_type(result, "combat_start")[0]["boards"][0][F1]["attack"], 3)


func test_golden_redbreast_gets_2_per_nest() -> void:
	_away("mrs_jay", F2)
	var robin: RecruitUnit = _kit.put("mr_redbreast", F1, true)
	_rules.board_changed(_player)
	assert_eq(robin.attack, 2 + 2)


func test_jay_gets_an_acorn_each_flight() -> void:
	_away("mrs_jay", F1)
	assert_eq(_kit.item_ids(), ["acorn"])


func test_golden_jay_gets_two() -> void:
	_away("mrs_jay", F1, true)
	assert_eq(_kit.item_ids(), ["acorn", "acorn"])


func test_daw_takes_a_quarter_of_what_the_enemy_gained_up_to_4_and_pays() -> void:
	_kit.put("jack_daw", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 9, "health": 200}}
	)
	assert_eq(_triggered(result, "jack_daw"), 1)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[1]["attack_delta"], 2, "a quarter of the Attack gain, rounded down")
	assert_eq(stats[1]["health_delta"], 4, "the cap")
	assert_eq(_player.gold_next_turn, 1)


func test_daw_takes_nothing_from_a_plain_card() -> void:
	_kit.put("jack_daw", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug"}})
	assert_eq(_triggered(result, "jack_daw"), 0)
	assert_eq(_player.gold_next_turn, 0)


func test_golden_daw_caps_at_8_and_pays_2() -> void:
	_kit.put("jack_daw", F1, true)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "attack": 200, "health": 200}})
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[1]["attack_delta"], 8)
	assert_eq(_player.gold_next_turn, 2)


func test_tern_stays_away_3_turns_and_discovers_a_unit_of_your_tier_when_home() -> void:
	_player.tier = 3
	var tern: RecruitUnit = _away("old_tern", F1)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_false(_player.hand.has(tern), "3 turns")
	_kit.pass_turn()
	assert_true(_player.hand.has(tern))
	assert_eq(_player.pending.size(), 1)
	var options: PackedStringArray = _player.pending[0]["options"]
	for id: String in options:
		assert_eq(CoreUtil.to_int(_kit.library.get_unit(id)["tier"]), 3, "exactly your tier")


func test_golden_tern_discovers_twice() -> void:
	_player.tier = 3
	_away("old_tern", F1, true)
	for _time: int in 3:
		_kit.pass_turn()
	assert_eq(_player.pending.size(), 2)


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
	var older: RecruitUnit = _away("old_tern", F2)
	_kit.pass_turn()
	var newer: RecruitUnit = _away("old_tern", F3)
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


func test_goose_away_each_nest_strikes_across_for_its_card_attack() -> void:
	var goose: RecruitUnit = _away("mother_goose", F1)
	goose.add_permanent(50, 0)
	_away("mrs_jay", F2)
	_kit.put("pill_bug", F3)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "health": 100, "attack": 0}, F2: {"def_id": "pill_bug", "health": 100, "attack": 0}}
	)
	var strikes: Array[Dictionary] = KIT.of_type(result, "goose_strike")
	assert_eq(strikes.size(), 2, "her own Nest too")
	var amounts: Array = []
	for event: Dictionary in KIT.of_type(result, "damage"):
		if event["source"] == null:
			amounts.append(event["amount"])
	assert_eq(amounts, [4, 2], "card Attack, not buffs")


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


func test_golden_goose_strikes_twice() -> void:
	_away("mother_goose", F1, true)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 100}})
	assert_eq(KIT.of_type(result, "goose_strike").size(), 2)


func test_goose_ignores_ring_on_the_slot() -> void:
	_away("mrs_jay", F2)
	_away("mother_goose", F1)
	_player.slot_effects[F2] = [{"name": "Ring", "attack": 9, "health": 0}]
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "health": 100}})
	for event: Dictionary in KIT.of_type(result, "damage"):
		if event["source"] == null:
			assert_eq(event["amount"], 2, "the bird's own Attack")


func test_ratchet_lands_the_bird_when_the_egg_on_its_nest_dies() -> void:
	_away("mrs_jay", F2)
	_kit.put("gabble_ratchet", B3)
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "attack": 5, "health": 500}})
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
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "attack": 99, "health": 500}})
	assert_eq(_triggered(result, "gabble_ratchet"), 1)


func test_ratchet_ignores_deaths_off_a_nest() -> void:
	_kit.put("pill_bug", F1)
	_kit.put("gabble_ratchet", B3)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "attack": 99, "health": 500}})
	assert_eq(_triggered(result, "gabble_ratchet"), 0)


func test_each_bird_lands_once_with_two_ratchets() -> void:
	_away("mrs_jay", F2)
	_kit.put("gabble_ratchet", B3)
	_kit.put("gabble_ratchet", B2)
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "attack": 5, "health": 500}})
	assert_eq(_triggered(result, "gabble_ratchet"), 1)


func test_golden_ratchet_lands_it_with_double_attack() -> void:
	_away("mrs_jay", F2)
	_kit.put("gabble_ratchet", B3, true)
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "attack": 5, "health": 500}})
	var stats: Array[Dictionary] = []
	for event: Dictionary in KIT.of_type(result, "stats"):
		if event["attack_delta"] == 2:
			stats.append(event)
	assert_eq(stats.size(), 1, "Jay's 2 again")


func _different_birds_home(count: int) -> void:
	var ids: Array = ["one_swallow", "chiffchaff", "tom_tit", "mrs_dunnock", "mrs_jay", "great_lump"]
	var slots: Array = [F1, F2, F3, F4, B1, B2]
	for index: int in count:
		_kit.put(str(ids[index]), slots[index])


func test_whistlers_below_seven_only_the_enemy_across_loses_a_quarter() -> void:
	_different_birds_home(1)
	_kit.put("seven_whistlers", B3)
	var result: Dictionary = _kit.fight_board(
		{B3: {"def_id": "pill_bug", "attack": 8, "health": 40}, F1: {"def_id": "pill_bug", "attack": 8, "health": 40}}
	)
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -2)
	assert_eq(stats[0]["health_delta"], -10)
	var across: int = KIT.of_type(result, "combat_start")[0]["boards"][1][B3]["uid"]
	assert_eq(stats[0]["target"], across)


func test_whistlers_at_seven_every_enemy_loses_a_quarter() -> void:
	_different_birds_home(6)
	_kit.put("seven_whistlers", B3)
	var result: Dictionary = _kit.fight_board(
		{B3: {"def_id": "pill_bug", "attack": 8, "health": 40}, F1: {"def_id": "pill_bug", "attack": 8, "health": 40}}
	)
	var hit: int = 0
	for event: Dictionary in KIT.of_type(result, "stats"):
		hit += 1 if event["attack_delta"] == -2 else 0
	assert_eq(hit, 2)


func test_whistlers_counts_birds_away() -> void:
	_different_birds_home(5)
	_away("mother_goose", B2)
	_kit.put("seven_whistlers", B3)
	var rules: Dictionary = _rules.fight_rules(_player)
	assert_eq(rules["away_birds"], ["mother_goose"])
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 8, "health": 40}, F2: {"def_id": "pill_bug", "attack": 8, "health": 40}}
	)
	var hit: int = 0
	for event: Dictionary in KIT.of_type(result, "stats"):
		hit += 1 if event["attack_delta"] == -2 else 0
	assert_eq(hit, 2, "five home, one Whistlers, one away: seven")


func test_whistlers_copies_count_once() -> void:
	for slot: int in [F1, F2, F3, F4, B1, B2]:
		_kit.put("mrs_jay", slot)
	_kit.put("seven_whistlers", B3)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 8, "health": 40}, F2: {"def_id": "pill_bug", "attack": 8, "health": 40}}
	)
	var hit: int = 0
	for event: Dictionary in KIT.of_type(result, "stats"):
		hit += 1 if event["attack_delta"] == -2 else 0
	assert_eq(hit, 0, "two different Birds, and nobody across B3")


func test_golden_whistlers_takes_half_and_never_kills() -> void:
	_kit.put("seven_whistlers", F1, true)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "attack": 8, "health": 1}})
	var stats: Array[Dictionary] = KIT.of_type(result, "stats")
	assert_eq(stats[0]["attack_delta"], -4)
	assert_eq(stats[0]["health_delta"], 0, "half of 1 rounds down, so it lives")


func test_one_whistlers_fires_per_side() -> void:
	_kit.put("seven_whistlers", F1)
	_kit.put("seven_whistlers", F2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "health": 40}, F2: {"def_id": "pill_bug", "health": 40}}
	)
	assert_eq(_triggered(result, "whistlers"), 1)
