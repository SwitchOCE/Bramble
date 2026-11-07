# gdlint: disable=max-public-methods
extends GutTest
## The balance step's second round: the scope review's cuts and the opening of rounds 1-2.
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


# --- The game's frame ------------------------------------------------------------------------


func test_full_game_has_40_health_and_rising_caps() -> void:
	var config: GameConfig = GameConfig.full_game()
	assert_eq(config.get_int("starting_health"), 40)
	assert_eq(config.get_int_at("damage_cap_by_turn", 0), 3, "round 1")
	assert_eq(config.get_int_at("damage_cap_by_turn", 13), 15, "round 14")
	assert_eq(config.get_int_at("upgrade_costs", 4), 13, "the last climb costs more")
	var defaults: GameConfig = GameConfig.defaults()
	assert_eq(defaults.get_int("starting_health"), 30, "the bare rules keep 30")


func test_a_real_game_starts_on_40_and_no_fight_passes_the_cap() -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("bots", BotLobby.seats(BotLevel.NORMAL))
	config.set_value("human_bot", "normal:varied")
	var session := GameSession.create(5, UnitLibrary.load_dir(), config)
	var caps: Array = config.get_value("damage_cap_by_turn")
	while not session.is_over():
		session.end_turn()
	var rows: Array = session.get_game_log()["players"]
	var checked: int = 0
	for value: Variant in rows:
		var row: Dictionary = value
		if str(row.get("hero", "")) == "hob_mumblecrust":
			continue
		var before: int = 40
		for entry: Variant in row["rounds"]:
			var round_row: Dictionary = entry
			var number: int = round_row["round"]
			var alive: int = 0
			for other: Variant in rows:
				var other_row: Dictionary = other
				var seen: Array = other_row["rounds"]
				alive += 1 if seen.size() >= number else 0
			var health: int = round_row["health"]
			if alive > config.get_int("damage_cap_off_at_alive"):
				assert_lte(
					before - health, CoreUtil.to_int(caps[mini(number - 1, caps.size() - 1)])
				)
				checked += 1
			before = health
	assert_gt(checked, 50, "the game reached far enough to test")


func test_the_cap_comes_off_at_top_4_as_in_the_rulebook() -> void:
	assert_eq(GameConfig.full_game().get_int("damage_cap_off_at_alive"), 4)


func test_fill_shop_draws_by_tier_odds() -> void:
	_player.tier = 6
	var tiers: Dictionary = {}
	for _round: int in 200:
		_rules.refresh(_player)
		_player.gold = 10
		for unit: RecruitUnit in _player.shop:
			tiers[unit.tier()] = CoreUtil.to_int(tiers.get(unit.tier(), 0)) + 1
	var total: int = 0
	for tier: Variant in tiers:
		total += CoreUtil.to_int(tiers[tier])
	assert_gt(100.0 * CoreUtil.to_int(tiers.get(6, 0)) / total, 6.0, "tavern 6 shows tier 6 units")
	assert_lt(100.0 * CoreUtil.to_int(tiers.get(1, 0)) / total, 12.0, "and few tier 1 units")


# --- Cards -------------------------------------------------------------------------------------


func test_hiring_fair_discovers_a_tier_6_unit() -> void:
	assert_eq(_kit.cast("hiring_fair"), "")
	var options: PackedStringArray = _player.pending[0]["options"]
	assert_eq(options.size(), 3)
	for option: String in options:
		assert_eq(_rules.pool.tier_of(option), 6)


func test_squirrel_away_gets_2_acorns() -> void:
	_kit.cast("squirrel_away")
	assert_eq(_kit.item_ids(), ["acorn", "acorn"])


func test_a_golden_dozey_wakes_again_up_to_his_ceiling() -> void:
	var first: RecruitUnit = _kit.put("alderman_dozey", F1)
	for _turn: int in 3:
		_kit.pass_turn()
	assert_eq(first.attack, 2 + 2, "he woke once")
	_kit.put("alderman_dozey", F2)
	_kit.put("alderman_dozey", -1)
	_rules.check_triples(_player)
	var golden: RecruitUnit = _player.hand[0]
	_rules.play(_player, 0, F3)
	var before: int = golden.attack
	for _turn: int in 3:
		_kit.pass_turn()
	assert_gt(golden.attack, before, "the triple's reward: he wakes again")
	assert_lte(golden.attack - before, 16, "within the golden ceiling")


func test_mast_pays_only_for_buying_a_unit_once_a_turn() -> void:
	_kit.put("old_mother_mast", F1)
	_kit.pass_turn()
	assert_eq(_kit.item_ids(), [], "nothing for sitting there")
	_player.gold = 20
	_kit.shop("pill_bug")
	_kit.shop("pill_bug")
	_rules.buy(_player, _player.shop.size() - 1)
	assert_eq(_kit.item_ids(), ["acorn"])
	_rules.buy(_player, _player.shop.size() - 1)
	assert_eq(_kit.item_ids(), ["acorn"], "once a turn")


func test_mast_pays_2_with_a_hoard() -> void:
	_kit.put("old_mother_mast", F1)
	_rules.give_card(_player, "great_hoard")
	_player.gold = 20
	_kit.shop("pill_bug")
	_rules.buy(_player, _player.shop.size() - 1)
	assert_eq(_kit.item_ids(), ["great_hoard", "acorn", "acorn"])


func test_sleeping_partner_stops_after_three_payments() -> void:
	var unit: RecruitUnit = _kit.put("sleeping_partner", B1)
	for _turn: int in 9:
		_kit.pass_turn()
	assert_eq(_player.larder(), 5 + 5, "six Acorns are two Stashes")
	for _turn: int in 6:
		_kit.pass_turn()
	assert_eq(_player.larder(), 5 + 5, "no more")
	assert_eq(unit.view()["turns_goal"], 0, "screens stop counting")


func test_sleeping_partner_a_move_restarts_the_wait_but_never_the_count() -> void:
	var unit: RecruitUnit = _kit.put("sleeping_partner", B1)
	for _turn: int in 4:
		_kit.pass_turn()
	assert_eq(_player.larder(), 2, "one payment, one turn into the next wait")
	_rules.move_on_board(_player, B1, B2)
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_player.larder(), 2, "the wait started over: two turns aren't three")
	_kit.pass_turn()
	assert_eq(_player.larder(), 5 + 1, "second payment: four Acorns are a Stash and one")
	_rules.move_on_board(_player, B2, B3)
	for _turn: int in 3:
		_kit.pass_turn()
	assert_eq(_player.larder(), 5 + 5, "third payment: six Acorns are two Stashes")
	_rules.move_on_board(_player, B3, B1)
	for _turn: int in 6:
		_kit.pass_turn()
	assert_eq(_player.larder(), 5 + 5, "a move never buys a fourth")
	assert_eq(unit.view()["turns_goal"], 0)


func test_a_rebought_sleeping_partner_is_a_new_unit() -> void:
	var old: RecruitUnit = _kit.put("sleeping_partner", B1)
	old.origin = RecruitUnit.ORIGIN_BOUGHT
	for _turn: int in 9:
		_kit.pass_turn()
	assert_false(old.pays_again())
	assert_eq(_rules.sell(_player, B1), "")
	_player.gold = 10
	_player.items.clear()
	_kit.shop("sleeping_partner")
	assert_eq(_rules.buy(_player, _player.shop.size() - 1), "")
	assert_eq(_rules.play(_player, _player.hand.size() - 1, B2), "")
	var fresh: RecruitUnit = _player.board[B2]
	assert_ne(fresh, old, "the sold one is gone")
	assert_true(fresh.pays_again(), "its count starts at nothing")
	for _turn: int in 3:
		_kit.pass_turn()
	assert_eq(_kit.item_ids().count("acorn"), 2, "and it pays")


func test_a_golden_partner_from_a_spent_copy_pays_its_three_times() -> void:
	var spent: RecruitUnit = _kit.put("sleeping_partner", B1)
	for _turn: int in 9:
		_kit.pass_turn()
	assert_false(spent.pays_again())
	_player.gold = 10
	_player.items.clear()
	_kit.put("sleeping_partner", B2)
	_kit.shop("sleeping_partner")
	assert_eq(_rules.buy(_player, _player.shop.size() - 1), "", "the third copy triples")
	var golden: RecruitUnit = _player.hand[_player.hand.size() - 1]
	assert_true(golden.golden, "from a real triple")
	assert_true(golden.pays_again(), "the spent count stays with the spent copy")
	assert_eq(_rules.play(_player, _player.hand.size() - 1, B3), "")
	while _player.is_choosing():
		_rules.choose(_player, 0)
	_player.items.clear()
	for _turn: int in 3:
		_kit.pass_turn()
	assert_eq(_player.larder(), 5 + 1, "golden pays 4 Acorns: a Stash and one over")


func test_a_golden_dozey_adds_16_and_stops() -> void:
	var golden: RecruitUnit = _kit.put("alderman_dozey", F1, true)
	golden.add_permanent(40, 40)
	var attack: int = golden.attack
	var health: int = golden.health
	for _turn: int in 3:
		_kit.pass_turn()
	assert_eq(golden.attack, attack + 16, "the ceiling, not double")
	assert_eq(golden.health, health + 16)
	for _turn: int in 6:
		_kit.pass_turn()
	assert_eq(golden.attack, attack + 16, "once")


func test_rainbow_chaser_all_seven_pays_the_finish() -> void:
	_kit.play("rainbow_chaser", F1)
	for slot: int in [F2, F3, F4, B1, B2, B3]:
		_kit.play("pill_bug", slot)
	_player.gold = 0
	_rules.sell(_player, F1)
	assert_eq(_player.gold, 7 + 5, "1 per band and 5 for all seven")


func test_rainbow_chaser_six_bands_have_no_finish() -> void:
	_kit.play("rainbow_chaser", F1)
	for slot: int in [F2, F3, F4, B1, B2]:
		_kit.play("pill_bug", slot)
	_player.gold = 0
	_rules.sell(_player, F1)
	assert_eq(_player.gold, 6)


# --- The opening -------------------------------------------------------------------------------


func _shop_spell_ids() -> Array:
	var out: Array = []
	for item: HandItem in _player.shop_spells:
		out.append(item.def_id())
	return out


func test_first_shops_of_rounds_1_and_2_offer_the_opening() -> void:
	assert_eq(_shop_spell_ids(), ["rainy_day", "a_leg_up"], "round 1")
	_kit.pass_turn()
	assert_eq(_shop_spell_ids().size(), 2)
	assert_has(_shop_spell_ids(), "a_leg_up", "round 2")


func test_opening_is_gone_after_a_refresh_and_after_round_2() -> void:
	_rules.refresh(_player)
	assert_does_not_have(_shop_spell_ids(), "a_leg_up", "refreshing can't fish for a second")
	_kit.pass_turn()
	_kit.pass_turn()
	assert_does_not_have(_shop_spell_ids(), "a_leg_up", "round 3")


func test_a_leg_up_takes_2_off_the_next_upgrade_only() -> void:
	assert_eq(_rules.tier_up_cost(_player), 5)
	assert_eq(_kit.cast("a_leg_up"), "")
	assert_eq(_rules.tier_up_cost(_player), 3)
	_player.gold = 20
	assert_eq(_rules.tier_up(_player), "")
	assert_eq(_rules.tier_up_cost(_player), _rules.base_upgrade_cost(2))


func test_a_leg_up_never_goes_below_zero() -> void:
	_player.upgrade_cost = 1
	_kit.cast("a_leg_up")
	assert_eq(_rules.tier_up_cost(_player), 0)


func test_the_opening_cards_cost_the_pool_nothing() -> void:
	var before: int = _rules.spell_pool.copies_left("rainy_day")
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_rules.spell_pool.copies_left("rainy_day"), before, "shown, then gone")


# --- Bots --------------------------------------------------------------------------------------


func _session_bot(level: String, strategy: String = "") -> Array:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game())
	var bot_name: String = level if strategy == "" else "%s:%s" % [level, strategy]
	var brain: BotBrain = BotBrain.from_name(bot_name)
	kit.rules.start_phase(kit.player, 1)
	return [brain, kit]


func test_each_opening_is_bought_in_round_1() -> void:
	for plan: String in ["economy", "climb", "tempo"]:
		var pair: Array = _session_bot(BotLevel.HARD)
		var brain: BotBrain = pair[0]
		var kit: KIT = pair[1]
		brain._opening_plan = plan
		brain.play_turn(kit.player, kit.rules, 1)
		if plan == "economy":
			assert_gt(kit.player.rainy_lose, 0, "Rainy Day cast")
		elif plan == "climb":
			assert_eq(kit.player.upgrade_cost, 3, "A Leg Up cast")
		else:
			assert_gte(kit.player.board_count(), 1, "tempo buys a unit")


func test_easy_never_opens_with_a_plan() -> void:
	# Every seed Hard would use for the toss, each with both opening cards there to buy.
	for toss: int in 12:
		var pair: Array = _session_bot(BotLevel.EASY)
		var brain: BotBrain = pair[0]
		var kit: KIT = pair[1]
		kit.player.bot_rng.seed = toss + 1
		brain.play_turn(kit.player, kit.rules, 1)
		assert_eq(brain._opening_plan, "", "no plan drawn")
		assert_eq(kit.player.rainy_lose, 0, "no Rainy Day")
		assert_eq(kit.player.upgrade_cost, 5, "no A Leg Up")


func test_the_opening_toss_does_reach_all_three_plans_at_hard() -> void:
	var seen: Dictionary = {}
	for toss: int in 12:
		var pair: Array = _session_bot(BotLevel.HARD)
		var brain: BotBrain = pair[0]
		var kit: KIT = pair[1]
		kit.player.bot_rng.seed = toss + 1
		brain.play_turn(kit.player, kit.rules, 1)
		seen[brain._opening_plan] = true
	assert_eq(seen.size(), 3, "what Easy is being compared with")


func test_easy_ignores_the_scouted_board() -> void:
	var pair: Array = _session_bot(BotLevel.EASY)
	var brain: BotBrain = pair[0]
	var kit: KIT = pair[1]
	kit.player.scout = {"specs": [], "player_id": 1}
	brain.play_turn(kit.player, kit.rules, 3)
	assert_true(kit.player.scout.is_empty())


func test_easy_leaves_units_where_they_land() -> void:
	var pair: Array = _session_bot(BotLevel.EASY)
	var brain: BotBrain = pair[0]
	var kit: KIT = pair[1]
	var frail: RecruitUnit = kit.put("nan_toadstool", F1)
	var sturdy: RecruitUnit = kit.put("pill_bug", B1)
	kit.player.shop.clear()
	kit.player.gold = 0
	brain.play_turn(kit.player, kit.rules, 3)
	assert_eq(kit.player.board[F1], frail, "a frail unit stays in front")
	assert_eq(kit.player.board[B1], sturdy, "and a sturdy one behind")
	var hard_pair: Array = _session_bot(BotLevel.NORMAL)
	var normal: BotBrain = hard_pair[0]
	var hard_kit: KIT = hard_pair[1]
	var other_frail: RecruitUnit = hard_kit.put("nan_toadstool", F1)
	var other_sturdy: RecruitUnit = hard_kit.put("pill_bug", B1)
	hard_kit.player.shop.clear()
	hard_kit.player.gold = 0
	normal.play_turn(hard_kit.player, hard_kit.rules, 3)
	var moved: bool = hard_kit.player.board[F1] != other_frail
	assert_true(moved or hard_kit.player.board[B1] != other_sturdy, "Normal does rearrange")


func test_easy_buys_the_worse_unit_some_of_the_time() -> void:
	var worse: int = 0
	var calm_worse: int = 0
	for trial: int in 60:
		var pair: Array = _session_bot(BotLevel.EASY)
		var brain: BotBrain = pair[0]
		var kit: KIT = pair[1]
		kit.player.bot_rng.seed = trial
		brain._player = kit.player
		brain._rules = kit.rules
		var pill: float = brain._unit_gain(kit.shop("pill_bug"))
		var sorrel: float = brain._unit_gain(kit.shop("mrs_sorrel"))
		worse += 1 if pill > sorrel else 0
		brain.level.buy_noise = 0.0
		var calm_pill: float = brain._unit_gain(kit.shop("pill_bug"))
		var calm_sorrel: float = brain._unit_gain(kit.shop("mrs_sorrel"))
		calm_worse += 1 if calm_pill > calm_sorrel else 0
	assert_eq(calm_worse, 0, "without the poor eye it would always see which is better")
	assert_gt(worse, 5, "with it, it often doesn't")


func test_easy_keeps_a_weak_unit_on_a_full_board_where_a_sharper_level_replaces_it() -> void:
	var pair: Array = _session_bot(BotLevel.EASY)
	var brain: BotBrain = pair[0]
	var kit: KIT = pair[1]
	brain._player = kit.player
	brain._rules = kit.rules
	brain.level.buy_noise = 0.0
	for slot: int in BoardGeometry.SLOTS:
		kit.put("pill_bug", slot)
	var better: RecruitUnit = kit.shop("dr_urchin")
	assert_lte(brain._unit_gain(better), 0.0, "Easy sees no reason to swap")
	brain.level.replace_margin = BotLevel.of(BotLevel.NORMAL).replace_margin
	assert_gt(brain._unit_gain(better), 0.0, "the same unit at Normal's margin is a swap")


func test_normal_at_4_refreshes_is_a_bench_arm_only() -> void:
	assert_eq(BotLevel.of(BotLevel.NORMAL).max_refreshes, 2)
	assert_eq(BotBrain.from_name("normal@refreshes=4").level.max_refreshes, 4)
	assert_true(BenchSuites.is_known("hard_lobby_normal4"))
	var seats: PackedStringArray = BenchSuites.seats("hard_lobby_normal4", 3)
	assert_eq(seats.size(), 8)
	var focus: int = BenchSuites.focus_seat("hard_lobby_normal4", 3)
	assert_eq(seats[focus], "hard", "the focus seat stays plain Hard")
	for seat: int in seats.size():
		if seat != focus:
			assert_string_ends_with(seats[seat], "@refreshes=4", "every other seat is the arm")
	for bot_name: String in BenchSuites.seats("hard_lobby_normal", 3):
		assert_false(bot_name.contains("refreshes"), "the plain lobby never is")


func test_a_gold_burner_looks_at_one_shop_at_most() -> void:
	var pair: Array = _session_bot(BotLevel.HARD)
	var brain: BotBrain = pair[0]
	var kit: KIT = pair[1]
	brain._player = kit.player
	brain._rules = kit.rules
	assert_false(brain._banks_gold())
	kit.put("charcoal_burner", F1)
	assert_true(brain._banks_gold())


func test_low_health_stops_saving() -> void:
	var pair: Array = _session_bot(BotLevel.HARD, "neutrals_purse")
	var brain: BotBrain = pair[0]
	var kit: KIT = pair[1]
	brain._player = kit.player
	brain._rules = kit.rules
	brain._round_now = 8
	kit.put("pill_bug", F1)
	kit.player.health = 40
	assert_gt(brain._held_back(), 0, "the Purse saves")
	kit.player.health = BotBrain.LOW_HEALTH
	assert_eq(brain._held_back(), 0, "a saver about to die spends")


func test_stay_bonus_favours_the_board_as_it_stands() -> void:
	assert_gt(BotPlacer.STAY_BONUS, 0.0)
	var pair: Array = _session_bot(BotLevel.HARD)
	var brain: BotBrain = pair[0]
	var kit: KIT = pair[1]
	for slot: int in BoardGeometry.SLOTS:
		kit.put("pill_bug", slot)
	var identity: Array[int] = BoardSearch.identity_layout()
	var base: float = BotPlacer._layout_bonus(identity, kit.player, brain.value, identity)
	var moved: Array[int] = identity.duplicate()
	moved[F1] = identity[F2]
	moved[F2] = identity[F1]
	var other: float = BotPlacer._layout_bonus(moved, kit.player, brain.value, identity)
	assert_almost_eq(base - other, BotPlacer.STAY_BONUS, 0.001)
