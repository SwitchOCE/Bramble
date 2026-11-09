# gdlint:disable=max-public-methods
extends GutTest
## Hard still executes real actions while learning the two replacement engines.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: Variant
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_rules = _kit.rules
	_player.round_number = 5
	_player.gold = 10


func _brain(strategy: String) -> BotBrain:
	var brain: BotBrain = BotBrain.from_name("hard:" + strategy)
	brain._player = _player
	brain._rules = _rules
	brain._round_now = _player.round_number
	brain.value.library = _rules.library
	brain.value.recruit_rules = _rules
	brain.value.board_owner = _player
	return brain


func _stayers() -> void:
	_kit.put("mrs_sorrel", 0)
	_kit.put("alderman_dozey", 1)
	_kit.put("sexton_beetle", 2)


func _away(id: String, slot: int, stats: int = 10) -> RecruitUnit:
	var unit: RecruitUnit = _kit.put(id)
	_player.hand.erase(unit)
	unit.attack = stats
	unit.health = stats
	_player.away.append({"unit": unit, "left": 3, "due": 6, "nest": slot, "missed_fight": true})
	return unit


func test_hard_flies_a_mature_chiffchaff_and_keeps_three_bodies() -> void:
	_stayers()
	var bird: RecruitUnit = _kit.put("chiffchaff", 4)
	bird.played_round = 3
	var brain: BotBrain = _brain("birds_summer_winter")
	var gold: int = _player.gold
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.away.size(), 1)
	assert_eq(_player.away[0]["unit"], bird)
	assert_eq(_player.board_count(), 3)
	assert_eq(_player.gold, gold, "flight pays no sale gold")


func test_played_this_turn_cannot_be_flown_even_when_its_growth_is_large() -> void:
	_stayers()
	var bird: RecruitUnit = _kit.put("chiffchaff", 4)
	bird.played_round = 5
	bird.add_permanent(100, 100)
	var brain: BotBrain = _brain("birds_passage")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_same(_player.board[4], bird)
	assert_true(_player.away.is_empty())


func test_tern_waits_for_two_birds_in_the_sky() -> void:
	_stayers()
	var tern: RecruitUnit = _kit.put("old_tern", 4)
	tern.played_round = 3
	var brain: BotBrain = _brain("birds_summer_winter")
	assert_eq(BotPass3.best_flight(_player, brain.value, 5), -1)
	_away("chiffchaff", 5)
	assert_eq(BotPass3.best_flight(_player, brain.value, 5), -1)
	_away("mrs_jay", 6)
	assert_eq(BotPass3.best_flight(_player, brain.value, 5), 4)


func test_omen_turn_keeps_every_bird_home() -> void:
	var ids: Array[String] = [
		"chiffchaff",
		"mrs_jay",
		"one_swallow",
		"mr_redbreast",
		"tom_tit",
		"mrs_stork",
		"seven_whistlers"
	]
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _kit.put(ids[slot], slot)
		unit.played_round = 3
	var brain: BotBrain = _brain("birds_highway")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.board_count(), 7)
	assert_true(_player.away.is_empty())


func test_elimination_guard_keeps_the_biggest_bird() -> void:
	_stayers()
	var bird: RecruitUnit = _kit.put("chiffchaff", 4)
	bird.played_round = 3
	bird.add_permanent(100, 100)
	_player.health = 8
	var brain: BotBrain = _brain("birds_summer_winter")
	assert_eq(BotPass3.best_flight(_player, brain.value, 5), -1)


func test_the_lump_chooses_the_largest_empty_nest() -> void:
	_away("mrs_jay", 0, 10)
	_away("chiffchaff", 6, 60)
	var lump: RecruitUnit = _kit.put("great_lump")
	var brain: BotBrain = _brain("birds_passage")
	assert_eq(BotPlacer.play_slot(_player, lump, brain.value), 6)


func test_ring_layout_feeds_the_carry_and_places_fetch_in_front() -> void:
	_kit.put("old_moth_annis", 2)
	_kit.put("hedge_witch", 0)
	_kit.put("cradle_fetch", 3)
	_kit.put("hob_in_the_hearth", 6)
	BoardUpkeep.add_ring(_player, 4, {"attack": 10, "health": 10})
	_rules.board_changed(_player)
	var brain: BotBrain = _brain("fairies_rings")
	var layout: Array[int] = BotPlacer.rule_layout(_player, brain.value, [])
	assert_eq(_player.board[layout[0]].def_id(), "old_moth_annis")
	assert_eq(_player.board[layout[4]].def_id(), "hedge_witch")
	assert_eq(_player.board[layout[1]].def_id(), "cradle_fetch")
	BotPlacer.apply_layout(_player, _rules, layout)
	_rules.end_phase(_player)
	assert_gt(BoardUpkeep.ring_value(_player.slot_effects[4]).x, 10)


func test_ring_spells_finish_the_rainbow_then_feed_the_big_ring() -> void:
	for slot: int in BoardGeometry.SLOTS:
		if slot != 6:
			BoardUpkeep.add_ring(_player, slot, {"attack": 1, "health": 1})
	BoardUpkeep.add_ring(_player, 4, {"attack": 12, "health": 12})
	var brain: BotBrain = _brain("fairies_rings")
	var card: Dictionary = _kit.library.get_card("spore_cloud")
	assert_eq(brain._aim_for(str(card["aim"]), card), 6)
	BoardUpkeep.add_ring(_player, 6, {"attack": 1, "health": 1})
	assert_eq(brain._aim_for(str(card["aim"]), card), 4)


func test_golden_egg_aims_at_the_biggest_eligible_bird() -> void:
	var bird: RecruitUnit = _kit.put("chiffchaff", 0)
	bird.add_permanent(30, 30)
	_kit.put("mrs_jay", 1)
	var neutral: RecruitUnit = _kit.put("pill_bug", 2)
	neutral.add_permanent(1000, 1000)
	var brain: BotBrain = _brain("birds_passage")
	var card: Dictionary = _kit.library.get_card("golden_egg")
	assert_eq(brain._aim_for(str(card["aim"]), card), 0)
	bird.counters["egged"] = true
	assert_eq(brain._aim_for(str(card["aim"]), card), 1)


func test_thanking_lob_values_ring_growth_and_rejects_an_early_cashout() -> void:
	var lob: RecruitUnit = _kit.put("lob_lie_by_the_fire", 5)
	for slot: int in BoardGeometry.SLOTS:
		BoardUpkeep.add_ring(_player, slot, {"attack": 3, "health": 3})
	lob.counters["pass3_turns_stayed"] = 2
	assert_false(BotPass3.thank_ready(_player, 5, _rules.config))
	var early: float = BotContent5.shy_departure_value(lob, _player, 10.0, _rules.config)
	lob.counters["pass3_turns_stayed"] = 3
	_kit.put("silky", 6)
	assert_true(BotPass3.thank_ready(_player, 5, _rules.config))
	var grown: float = BotContent5.shy_departure_value(lob, _player, 10.0, _rules.config)
	assert_gt(grown, early)
	assert_gt(grown, 0.0)


func test_hard_keeps_lob_hob_and_live_cluricaun_instead_of_selling_the_engine() -> void:
	_player.tier = 3
	var lob: RecruitUnit = _kit.put("lob_lie_by_the_fire", 0)
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 1)
	var cluricaun: RecruitUnit = _kit.put("cluricaun", 2)
	lob.counters["pass3_turns_stayed"] = 2
	var brain: BotBrain = _brain("fairies_rings")
	assert_true(BotPass3.keep_engine(_player, lob, brain.value))
	assert_true(BotPass3.keep_engine(_player, hob, brain.value))
	assert_true(BotPass3.keep_engine(_player, cluricaun, brain.value))
	assert_eq(brain._weakest_slot(), -1, "a replacement cannot sell the last live engine")
	_player.tier = UnitLibrary.TIERS
	assert_false(BotPass3.keep_engine(_player, cluricaun, brain.value))
	assert_eq(brain._weakest_slot(), 2, "Cluricaun may retire after the final tier-up")


func test_hard_buys_a_thank_you_for_lobs_mature_bank_and_aims_past_a_large_carry() -> void:
	var lob: RecruitUnit = _kit.put("lob_lie_by_the_fire", 5)
	lob.counters["pass3_turns_stayed"] = 3
	var carry: RecruitUnit = _kit.put("hedge_witch", 4)
	carry.add_permanent(100, 100)
	for slot: int in BoardGeometry.SLOTS:
		BoardUpkeep.add_ring(_player, slot, {"attack": 1, "health": 1})
	_player.shop_spells.append(HandItem.make(_kit.library.get_card("pinch_of_dust"), 0))
	var brain: BotBrain = _brain("fairies_rings")
	var offer: Dictionary = brain._best_offer()
	assert_true(CoreUtil.to_bool(offer.get("spell", false)))
	assert_gt(CoreUtil.to_float(offer.get("gain", 0)), 2.0, "the spell prices Lob's payout")
	assert_true(brain._buy_offer(offer), "buy and cast through the real rules")
	assert_null(_player.board[5], "the aimed spell thanks Lob rather than buffing the carry")
	assert_same(_player.board[4], carry)
	assert_eq(_player.ring_size, 2.0)
	assert_eq(_player.gold, 9)


func test_hob_only_leaves_when_silkys_growth_pays_for_the_lost_shield() -> void:
	_kit.put("hob_in_the_hearth", 0)
	_kit.put("silky", 1)
	var carry: RecruitUnit = _kit.put("hedge_witch", 4)
	carry.add_permanent(100, 100)
	for slot: int in BoardGeometry.SLOTS:
		BoardUpkeep.add_ring(_player, slot, {"attack": 1, "health": 1})
	assert_false(BotPass3.thank_ready(_player, 0, _rules.config), "keep a valuable carry's Shield")
	for slot: int in BoardGeometry.SLOTS:
		for _ring: int in 10:
			BoardUpkeep.add_ring(_player, slot, {"attack": 1, "health": 1})
	assert_true(
		BotPass3.thank_ready(_player, 0, _rules.config), "many Rings make the trade worthwhile"
	)


func test_hard_completes_cluricauns_rainbow_before_paying_for_the_tier_up() -> void:
	_player.tier = 3
	_player.round_number = 10
	_rules.config.set_value("fairies_ring_growth", 1.0)
	_kit.put("cluricaun", 0)
	for slot: int in range(6):
		BoardUpkeep.add_ring(_player, slot, {"attack": 1, "health": 1})
	_player.shop_spells.append(HandItem.make(_kit.library.get_card("spore_cloud"), 0))
	var brain: BotBrain = _brain("fairies_rainbow")
	brain._climb(false)
	assert_eq(BotPass3.ring_count(_player), 7)
	assert_gt(_player.tier, 3)
	assert_gt(_player.ring_size, 1.0, "the completed rainbow grows on this tier-up")
	assert_true(_player.shop_spells.is_empty())


func test_cluricaun_and_missing_ring_values_read_the_resolved_growth_dial() -> void:
	_player.tier = 3
	var cluricaun: RecruitUnit = _kit.put("cluricaun", 0)
	for slot: int in range(6):
		BoardUpkeep.add_ring(_player, slot, {"attack": 1, "health": 1})
	var brain: BotBrain = _brain("fairies_rainbow")
	var spell: Dictionary = _kit.library.get_card("spore_cloud")
	_rules.config.set_value("fairies_ring_growth", 0.25)
	var small: float = brain.value.keep_value(cluricaun)
	var ring_small: float = brain.value.spell_value(spell, 10, _player)
	_rules.config.set_value("fairies_ring_growth", 2.0)
	assert_gt(brain.value.keep_value(cluricaun), small)
	assert_gt(brain.value.spell_value(spell, 10, _player), ring_small)


func test_annis_surplus_gold_churn_uses_real_buys_and_grows_rings() -> void:
	_kit.put("old_moth_annis", 0)
	_kit.put("hedge_witch", 4)
	_kit.shop("pill_bug")
	_kit.shop("sexton_beetle")
	var brain: BotBrain = _brain("fairies_rings")
	var buys: int = _player.units_bought
	BotPass3.churn(brain)
	assert_eq(_player.units_bought, buys + 2)
	assert_true(_player.hand.is_empty())
	assert_eq(_player.board_count(), 2)
	assert_eq(BotPass3.ring_total(_player), 2)
	assert_lt(_player.gold, 10)


func test_chaser_sells_by_ringed_slots_without_rainbow_bands() -> void:
	_kit.put("rainbow_chaser", 4)
	for slot: int in range(6):
		BoardUpkeep.add_ring(_player, slot, {"attack": 1, "health": 1})
	var brain: BotBrain = _brain("fairies_rainbow")
	brain._sell_for_cash()
	assert_null(_player.board[4])
	assert_gt(_player.gold, 10)
	assert_eq(_player.band_count(), 0)


func test_a_real_hard_lobby_plays_both_replacement_engines() -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("tribes_per_lobby", 6)
	config.set_value("starting_health", 80)
	config.set_value("human_bot", "hard:birds_summer_winter")
	config.set_value(
		"bots",
		[
			"hard:birds_passage",
			"hard:birds_highway",
			"hard:fairies_rings",
			"hard:fairies_rainbow",
			"hard:fairies_help",
			"hard:fairies_hag",
			"hard:birds_summer_winter"
		]
	)
	var game: GameSession = GameSession.create(412, UnitLibrary.load_dir(), config)
	var counts: Dictionary = {}
	var note: Callable = func(type: String, _fields: Dictionary) -> void:
		counts[type] = CoreUtil.to_int(counts.get(type, 0)) + 1
	for player: PlayerState in game._players:
		player.log_observer = note
	for _turn: int in 12:
		if game.is_over():
			break
		game.end_turn()
	var rings: int = 0
	for player: PlayerState in game._players:
		rings += BotPass3.ring_total(player)
	assert_gt(CoreUtil.to_int(counts.get("fly_south", 0)), 0)
	assert_gt(CoreUtil.to_int(counts.get("home", 0)), 0)
	assert_gt(rings, 0)


func test_whistlers_face_total_stats_and_daw_takes_the_second_target() -> void:
	_kit.put("seven_whistlers", 0)
	_kit.put("jack_daw", 1)
	_kit.put("mr_redbreast", 4)
	_player.scout = {
		"specs":
		[
			{"def_id": "pill_bug", "attack": 50, "health": 2},
			null,
			{"def_id": "pill_bug", "attack": 10, "health": 200},
			null,
			null,
			null,
			null
		]
	}
	var brain: BotBrain = _brain("birds_highway")
	var layout: Array[int] = BotPlacer.rule_layout(_player, brain.value, [])
	assert_eq(_player.board[layout[2]].def_id(), "seven_whistlers")
	assert_eq(_player.board[layout[0]].def_id(), "jack_daw")


func test_golden_egg_waits_for_the_larger_bird_due_next_turn() -> void:
	_kit.put("mrs_jay", 0)
	_away("chiffchaff", 5, 80)
	assert_true(BotPass3.hold_egg(_player))
	_player.away[0]["due"] = 8
	assert_false(BotPass3.hold_egg(_player), "a longer absence can use the Egg at home")
