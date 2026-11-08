extends GutTest
## The balance step after playtest round 1 (docs/ideation/evidence/playtest-1.md): runaways capped,
## late shops, Discover's three options, economy heroes and the next card batch.
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


func _events(result: Dictionary, type: String) -> Array:
	var out: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == type:
			out.append(event)
	return out


func _sit(unit: RecruitUnit, turns: int) -> void:
	for _turn: int in turns:
		_kit.pass_turn()
	assert_not_null(unit)


# --- Runaways -------------------------------------------------------------------------------------


func test_dozey_doubles_up_to_his_ceiling() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", B2)
	_sit(dozey, 3)
	assert_eq(dozey.attack, 4, "small: a plain double")
	assert_eq(dozey.health, 10)
	var fed: RecruitUnit = _kit.put("alderman_dozey", B1)
	fed.add_permanent(38, 35)
	_sit(fed, 3)
	assert_eq(fed.attack, 14, "permanent bonus capped at +12")
	assert_eq(fed.health, 17)


func test_dozey_moving_doesnt_rearm_his_wake() -> void:
	var dozey: RecruitUnit = _kit.put("alderman_dozey", B2)
	_sit(dozey, 3)
	_rules.move(_player, B2, B1)
	_sit(dozey, 4)
	assert_eq(dozey.attack, 4, "he only wakes once")


func test_witch_hex_stops_at_her_limit() -> void:
	var witch: RecruitUnit = _kit.put("hedge_witch", F1)
	for _spell: int in 12:
		_kit.cast("pinch_of_dust", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "health": 50, "attack": 30}}
	)
	var hex: Dictionary = _events(result, "slot_hex")[0]
	assert_eq(hex["amount"], 1)
	assert_not_null(witch)


func test_a_triple_keeps_a_waiting_cold_frame() -> void:
	var first: RecruitUnit = _kit.put("pill_bug", F1)
	_kit.cast("cold_frame", F1)
	assert_eq(first.timers.size(), 1)
	_kit.put("pill_bug", F2)
	_kit.put("pill_bug", -1)
	_rules.check_triples(_player)
	var golden: RecruitUnit = _player.hand[0]
	assert_true(golden.golden)
	assert_eq(golden.timers.size(), 1, "the prize stays with the golden")


# --- Shops and Discover ---------------------------------------------------------------------------


func test_a_tier_6_shop_is_mostly_high_tiers() -> void:
	var library := UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	var pool := UnitPool.create(library, config)
	var odds: Array = config.get_value("shop_tier_odds")[5]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var low: int = 0
	var high: int = 0
	for _draw: int in 400:
		var card: String = pool.draw_by_odds(odds, 6, rng)
		var tier: int = pool.tier_of(card)
		pool.give_back(card)
		low += 1 if tier <= 2 else 0
		high += 1 if tier >= 4 else 0
	assert_gt(high, 240, "tiers 4-6 are the bulk")
	assert_lt(low, 90, "tiers 1-2 are rare")


func test_odds_for_an_empty_tier_fall_to_the_rest() -> void:
	var library := UnitLibrary.load_dir()
	var pool := UnitPool.create(library, GameConfig.full_game())
	for id: String in pool.ids():
		while pool.tier_of(id) == 1 and pool.copies_left(id) > 0:
			pool.take(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	assert_eq(
		pool.tier_of(pool.draw_by_odds([100, 0], 2, rng)),
		2,
		"tier 1 is out, so nothing to pick there"
	)


func test_every_discover_offers_three_even_from_a_thin_tier() -> void:
	_player.tier = 6
	var pool: UnitPool = _rules.pool
	for id: String in pool.ids():
		if pool.tier_of(id) == 6 and id != "queen_of_elfland":
			while pool.copies_left(id) > 0:
				pool.take(id)
	_rules.discover(_player, {"effect": "discover", "count": 3, "tier": "next"})
	var options: PackedStringArray = _player.pending[0]["options"]
	assert_eq(options.size(), 3)
	assert_eq(pool.tier_of(options[0]), 6)
	assert_eq(pool.tier_of(options[1]), 5, "topped up from the tier below")


# --- Economy --------------------------------------------------------------------------------------


func test_jill_climbs_back_for_two() -> void:
	var hero: Dictionary = _kit.library.get_hero("jill_down_the_tree")
	_player.hero = hero
	_player.power_uses_left = 1
	_player.tier = 4
	_player.gold = 0
	assert_eq(_rules.use_power(_player), "")
	assert_eq(_player.tier, 3)
	assert_eq(_player.gold, 2)
	assert_eq(_rules.tier_up_cost(_player), 2)
	assert_eq(_rules.tier_up(_player), "")
	assert_eq(_player.tier, 4)
	assert_eq(_player.gold, 0)


func test_hob_repays_one_gold_on_each_of_the_next_two_turns() -> void:
	_player.hero = _kit.library.get_hero("hob_mumblecrust")
	_kit.pass_turn()
	_player.power_uses_left = 1
	var start: int = _player.gold
	assert_eq(_rules.use_power(_player), "")
	assert_eq(_player.gold, start + 3)
	var health: int = _player.health
	_player.gold = 0
	_kit.pass_turn()
	assert_eq(_player.gold, 4, "5 income less 1 repaid")
	assert_eq(_player.health, health)
	assert_ne(_rules.use_power(_player), "", "still repaying")
	_player.gold = 0
	_kit.pass_turn()
	assert_eq(_player.gold, 5, "6 income less 1 repaid")
	assert_eq(_player.health, health)
	assert_eq(_rules.use_power(_player), "", "repaid")


func test_rainy_day_pays_by_the_last_fight() -> void:
	_kit.cast("rainy_day")
	_player.gold = 0
	_player.last_result = "loss"
	_kit.pass_turn()
	assert_eq(_player.gold, 4 + 3)
	_kit.cast("rainy_day")
	_player.gold = 0
	_player.last_result = "win"
	_kit.pass_turn()
	assert_eq(_player.gold, 5 + 1)


func test_market_day_lasts_the_turn() -> void:
	_kit.cast("market_day")
	assert_eq(_rules.unit_cost(_player), 2)
	_kit.pass_turn()
	assert_eq(_rules.unit_cost(_player), 3)


func test_snail_sells_for_more_up_to_its_limit() -> void:
	var snail: RecruitUnit = _kit.put("pennywort_snail", F1)
	snail.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(_rules.sell_value(snail, _player), 1)
	_sit(snail, 5)
	assert_eq(_rules.sell_value(snail, _player), 4, "1 plus 3 turns' worth")


func test_money_spider_pays_on_carried_gold() -> void:
	_kit.put("money_spider", F1)
	_player.gold = 12
	_kit.pass_turn()
	assert_eq(_player.gold, 12 + 4 + 1)


func test_bonfire_feeds_a_row_from_everything_spent() -> void:
	var left: RecruitUnit = _kit.put("pill_bug", F1)
	var right: RecruitUnit = _kit.put("pill_bug", F4)
	var behind: RecruitUnit = _kit.put("pill_bug", B1)
	_player.gold = 21
	_kit.cast("beltane_bonfire", F1)
	assert_eq(_player.gold, 0)
	assert_eq(left.perm_attack, 5)
	assert_eq(right.perm_health, 5)
	assert_eq(behind.perm_attack, 0)


func test_harvest_supper_is_a_standing_tribe_bonus() -> void:
	var front: RecruitUnit = _kit.put("field_vole", F1)
	var other: RecruitUnit = _kit.put("field_vole", F2)
	var back: RecruitUnit = _kit.put("field_vole", B1)
	assert_eq(_kit.cast("harvest_supper", F1), "")
	assert_eq(front.tribe_attack, 1)
	assert_eq(other.tribe_attack, 1)
	assert_eq(back.tribe_attack, 1)


# --- Acorns ---------------------------------------------------------------------------------------


func test_sleeping_partner_keeps_paying() -> void:
	_kit.put("sleeping_partner", B1)
	_kit.pass_turn()
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_player.larder(), 2)
	_kit.pass_turn()
	_kit.pass_turn()
	_kit.pass_turn()
	assert_eq(_player.larder(), 6, "four Acorns: three made a Stash")


func test_treasurer_counts_the_larder() -> void:
	var treasurer: RecruitUnit = _kit.put("honorary_treasurer", F1)
	var base: int = treasurer.attack
	_rules.give_card(_player, "stash")
	assert_eq(treasurer.attack, base + 1)


func test_sergeant_throws_his_smallest_acorn_and_it_is_spent() -> void:
	_kit.put("sergeant_at_conkers", F1)
	_rules.give_card(_player, "stash")
	_rules.give_card(_player, "acorn")
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var hits: Array = _events(result, "damage")
	assert_eq(hits[0]["amount"], 3, "the Acorn, not the Stash")
	assert_eq(_kit.item_ids(), ["stash"])


func test_sergeant_keeps_his_ammunition_with_nobody_across() -> void:
	_kit.put("sergeant_at_conkers", F1)
	_rules.give_card(_player, "acorn")
	_kit.fight_board({F2: {"def_id": "pill_bug", "health": 50}})
	assert_eq(_kit.item_ids(), ["acorn"])


func test_beadle_no_longer_makes_plain_failed_summons_spill() -> void:
	for slot: int in [F1, F2, F3, F4, B1, B2]:
		_kit.put("pill_bug", slot)
	_player.board[B2] = null
	_kit.put("beadle_warrenby", B2)
	_rules.summon_units(_player, "pill_bug", 3, false, B2)
	assert_eq(_player.larder(), 0, "one summoned; plain failures do not Spill")
	assert_eq(_player.pending_passes.size(), 0)


func test_beadle_does_not_pass_before_combat_spills_arrive_next_turn() -> void:
	_kit.put("beadle_warrenby", F1)
	_kit.put("mrs_sorrel", F2)
	var combat_rng := RandomNumberGenerator.new()
	combat_rng.seed = 1
	var combat := Combat.create(_kit.library, _kit.config, combat_rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	combat.run([[null], [null]], tiers, ids, 0)
	combat.sides = [[], []]
	var row: Array = []
	row.resize(7)
	var beadle := CombatUnit.make(_kit.library.get_unit("beadle_warrenby"), {}, 1, 0)
	beadle.slot = F1
	row[F1] = beadle
	var enemy_row: Array = []
	enemy_row.resize(7)
	combat.sides = [row, enemy_row]
	for _spill: int in 4:
		combat.spill(0, beadle)
	assert_eq(beadle.attack, 2, "combat Spills only queue next Recruit Phase Acorns")


# --- Fixed or reworked cards ----------------------------------------------------------------------


func test_belladonna_in_the_front_row_poisons_the_enemy_across() -> void:
	_kit.put("belladonna", F2)
	var result: Dictionary = _kit.fight_board({F2: {"def_id": "pill_bug", "health": 50}})
	var statuses: Array = _events(result, "status")
	assert_eq(statuses.size(), 1)
	assert_eq(statuses[0]["status"], "nightshade")


func test_belladonna_in_the_back_row_poisons_the_two_facing() -> void:
	_kit.put("belladonna", B2)
	var result: Dictionary = _kit.fight_board(
		{F2: {"def_id": "pill_bug", "health": 50}, F3: {"def_id": "pill_bug", "health": 50}}
	)
	assert_eq(_events(result, "status").size(), 2)


func test_chaser_grows_with_its_bands_and_pays_per_band() -> void:
	var chaser: RecruitUnit = _kit.play("rainbow_chaser", F1)
	assert_eq(_player.band_count(), 1)
	assert_eq(chaser.attack, 1, "one band is less than a pair")
	_kit.play("pill_bug", F2)
	_kit.play("pill_bug", F3)
	assert_eq(chaser.attack, 2)
	assert_eq(chaser.health, 3)
	_player.gold = 0
	_rules.sell(_player, F1)
	assert_eq(_player.gold, 1, "one pair; a Created Chaser sells for 0")
	assert_eq(_player.band_count(), 0)


func test_chaser_fights_with_its_bands() -> void:
	_kit.play("rainbow_chaser", F1)
	_kit.play("pill_bug", F2)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var start: Dictionary = _events(result, "combat_start")[0]
	assert_eq(start["boards"][0][F1]["attack"], 2)


func test_sexton_pays_twice_a_fight() -> void:
	_kit.put("sexton_beetle", B1)
	_kit.put("kit", F1)
	_kit.put("kit", F2)
	_kit.put("kit", F3)
	_kit.fight_board({F1: {"def_id": "pill_bug", "attack": 9, "health": 90}})
	assert_eq(_player.gold_next_turn, 2)


func test_burner_turns_a_saved_bank_into_stats_behind_it() -> void:
	_kit.put("charcoal_burner", F1)
	var behind: RecruitUnit = _kit.put("pill_bug", B1)
	_player.gold = 15
	_rules.end_phase(_player)
	assert_eq(_player.gold, 9, "six burned from fifteen leaves nine")
	assert_eq(behind.perm_attack, 3)


# --- The next batch -------------------------------------------------------------------------------


func test_cluricaun_gives_units_on_bands_attack_in_both_phases() -> void:
	var cluricaun: RecruitUnit = _kit.play("cluricaun", F1)
	var other: RecruitUnit = _kit.play("pill_bug", F2)
	assert_eq(other.attack, 2)
	assert_eq(cluricaun.attack, 3)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var stats: Array = _events(result, "combat_start")
	assert_eq(stats[0]["boards"][0][F2]["attack"], 2)
	_rules.sell(_player, F1)
	assert_eq(_player.band_count(), 1, "selling it washes nothing")
	assert_eq(other.attack, 1)


func test_fetch_becomes_a_printed_copy_of_the_unit_behind() -> void:
	_kit.put("cradle_fetch", F1)
	var carry: RecruitUnit = _kit.put("pill_bug", B1)
	carry.add_permanent(10, 10)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	var summons: Array = _events(result, "summon")
	assert_eq(summons.size(), 1)
	assert_eq(summons[0]["unit"]["def_id"], "pill_bug")
	assert_eq(summons[0]["unit"]["attack"], 1, "printed, not the buffs")


func test_fetch_with_nobody_behind_stays_itself() -> void:
	_kit.put("cradle_fetch", F1)
	var result: Dictionary = _kit.fight_board({F1: {"def_id": "pill_bug", "health": 50}})
	assert_eq(_events(result, "summon").size(), 0)


func test_changeling_borrows_the_enemy_until_it_has_attacked() -> void:
	_kit.put("changeling", F1)
	_kit.put("pill_bug", F2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 3, "health": 3}}
	)
	var moves: Array = _events(result, "relocate")
	assert_true(moves.size() >= 2, "they traded")
	assert_eq(_events(result, "combat_end").size(), 1)


func test_ichneumon_kills_after_the_next_attack() -> void:
	_kit.put("ichneumon_wasp", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 1, "health": 50}}
	)
	var deaths: Array = _events(result, "death")
	assert_gt(deaths.size(), 0, "the giant dies")


func test_whirligig_swaps_the_enemy_rows() -> void:
	_kit.put("whirligig_beetle", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "health": 50}, B2: {"def_id": "pill_bug", "health": 50}}
	)
	var moves: Array = _events(result, "relocate")
	assert_eq(moves.size(), 2)
	assert_eq(moves[0]["slot"], B1)
	assert_eq(moves[1]["slot"], F2)


func test_echo_also_hits_the_units_beside_it() -> void:
	var left: RecruitUnit = _kit.put("pill_bug", F1)
	_kit.put("pipistrelle_echo", F2)
	var right: RecruitUnit = _kit.put("pill_bug", F3)
	var far: RecruitUnit = _kit.put("pill_bug", F4)
	_kit.cast("pinch_of_dust", F2)
	assert_eq(left.perm_attack, 1)
	assert_eq(right.perm_attack, 1)
	assert_eq(far.perm_attack, 0)


func test_echo_doesnt_spend_twice_on_last_orders() -> void:
	var left: RecruitUnit = _kit.put("pill_bug", F1)
	var echo: RecruitUnit = _kit.put("pipistrelle_echo", F2)
	_player.gold = 10
	_kit.cast("last_orders", F2)
	assert_eq(echo.perm_attack, 5)
	assert_eq(left.perm_attack, 0, "the gold is gone: the echo pays on nothing")


func test_urchin_pricks_and_passes_attack() -> void:
	_kit.put("dr_urchin", F1)
	var end: RecruitUnit = _kit.put("pill_bug", B1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 1, "health": 50}}, 2
	)
	var thorn: bool = false
	for event: Dictionary in _events(result, "damage"):
		thorn = thorn or event.get("amount") == 2
	assert_true(thorn, "Bristle 2")
	assert_not_null(end)


func test_reel_mistress_moves_a_ring_once_and_it_stays_home_after() -> void:
	var slot_row: Array = _player.slot_effects[F1]
	slot_row.append(
		{"name": BoardUpkeep.RING, "text": "", "attack": 4, "health": 0, "golden": false}
	)
	_kit.put("pill_bug", F1)
	_kit.put("pill_bug", F2)
	_kit.put("reel_mistress", B2)
	var result: Dictionary = _kit.fight_board({F4: {"def_id": "pill_bug", "health": 90}})
	var dances: Array = _events(result, "ring_dance")
	assert_gte(dances.size(), 1)
	var once: int = 0
	for dance: Dictionary in dances:
		once += 1 if dance["from"] == F1 else 0
	assert_eq(once, 1, "each Ring dances once a fight")
	assert_eq(_player.slot_effects[F1].size(), 1, "the recruit board's Ring didn't move")
