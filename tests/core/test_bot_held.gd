# gdlint: disable=max-public-methods
extends GutTest
## Bots really use Bellies and Fly South, and read nothing a player can't see.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const F1: int = 0
const F2: int = 1
const F3: int = 2
const F4: int = 3
const B1: int = 4
const B2: int = 5
const B3: int = 6
const HELD_ROUNDS: int = 12
## One of each, so nothing triples.
const FILLER: Array[String] = [
	"mrs_burdock", "mr_crumb", "mrs_sorrel", "sexton_beetle", "alderman_dozey", "earwig_mother"
]

var _kit: Variant
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game(), true)
	_player = _kit.player
	_rules = _kit.rules
	_player.gold = 10
	_player.round_number = 5


func _brain(bot_name: String) -> BotBrain:
	return BotBrain.from_name(bot_name)


func _fill_to_seven(from_slot: int) -> void:
	var index: int = 0
	for slot: int in range(from_slot, BoardGeometry.SLOTS):
		_kit.put(FILLER[index], slot)
		index += 1


func _unit(id: String) -> RecruitUnit:
	return RecruitUnit.make(_kit.library.get_unit(id), 900)


func _bird(id: String, slot: int) -> RecruitUnit:
	var unit: RecruitUnit = _kit.put(id, slot)
	unit.played_round = 1
	unit.origin = RecruitUnit.ORIGIN_BOUGHT
	return unit


func test_a_full_board_tucks_a_hand_unit_into_a_belly_instead_of_selling() -> void:
	var ooze: RecruitUnit = _kit.put("wee_wobbly", F1)
	_fill_to_seven(F2)
	_kit.put("pill_bug")
	var brain: BotBrain = _brain("hard:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	brain._play_hand()
	assert_eq(ooze.held.size(), 1, "into the Belly")
	assert_eq(ooze.held[0].def_id(), "pill_bug")
	assert_eq(_player.board_count(), 7, "nobody sold")


func test_a_discounting_belly_gets_the_buy_and_charges_less() -> void:
	var ooze: RecruitUnit = _kit.put("little_dollop", F1)
	_kit.put("mrs_sorrel", F2)
	_player.shop.clear()
	_kit.shop("pill_bug")
	var brain: BotBrain = _brain("hard:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	assert_eq(brain._buy_unit(0), "")
	assert_eq(ooze.held.size(), 1, "bought straight in")
	assert_eq(_player.gold, 10 - _rules.unit_cost(_player) + 1, "a gold off")


func test_on_a_near_empty_board_a_unit_fights_rather_than_saves_a_gold() -> void:
	var ooze: RecruitUnit = _kit.put("little_dollop", F1)
	_player.shop.clear()
	_kit.shop("pill_bug")
	var brain: BotBrain = _brain("hard:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	brain._buy_unit(0)
	assert_eq(ooze.held.size(), 0)
	assert_eq(_player.hand.size(), 1)


func test_depth_first_waits_for_a_board_worth_backing_up() -> void:
	var ooze: RecruitUnit = _kit.put("wee_wobbly", F1)
	_kit.put("mrs_sorrel", F2)
	_kit.put("mr_crumb", F3)
	_player.shop.clear()
	_kit.shop("pill_bug")
	var brain: BotBrain = _brain("hard:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	brain._buy_unit(0)
	assert_eq(ooze.held.size(), 0, "three on the board: not yet")
	_player.hand.clear()
	_kit.put("sexton_beetle", F4)
	_kit.shop("pill_bug")
	brain._buy_unit(_player.shop.size() - 1)
	assert_eq(ooze.held.size(), 1, "four: deep now")


func test_a_card_paid_on_play_is_played_not_swallowed() -> void:
	var ooze: RecruitUnit = _kit.put("little_dollop", F1)
	_kit.put("mrs_sorrel", F2)
	_player.shop.clear()
	_kit.shop("mr_crumb")
	var brain: BotBrain = _brain("hard:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	brain._buy_unit(0)
	assert_eq(ooze.held.size(), 0, "its value is in the playing")
	assert_eq(_player.hand.size(), 1)


func test_hasty_stays_empty_for_a_level_that_reads_cards() -> void:
	_kit.put("hasty_pudding", F1)
	var brain: BotBrain = _brain("hard:oozes_rude_awakening")
	assert_eq(BotHeld.best_belly(_player, brain.value, _unit("pill_bug")), -1)


func test_a_front_ooze_is_chosen_over_a_back_one() -> void:
	_kit.put("wee_wobbly", B1)
	_kit.put("bubble_and_squeak", F2)
	var brain: BotBrain = _brain("hard")
	assert_eq(BotHeld.best_belly(_player, brain.value, _unit("pill_bug")), F2)


func test_a_full_ooze_is_worth_more_than_an_empty_one() -> void:
	var brain: BotBrain = _brain("hard")
	var ooze: RecruitUnit = _kit.put("wee_wobbly", F1)
	var empty: float = brain.value.keep_value(ooze)
	ooze.held.append(_unit("mrs_sorrel"))
	assert_gt(brain.value.keep_value(ooze), empty)


func test_hard_flies_a_bird_with_a_good_trip_without_sale_gold() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	var tern: RecruitUnit = _bird("old_tern", B1)
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_null(_player.board[B1], "it left")
	assert_eq(_player.away.size(), 1)
	assert_eq(_player.away[0]["unit"], tern)
	assert_eq(_player.gold, 10, "flying pays no sale gold")


func test_a_big_tern_keeps_its_body_when_a_trip_loses_more_than_the_group_return() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	var bird: RecruitUnit = _bird("old_tern", B1)
	bird.attack = 12
	bird.health = 12
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_same(_player.board[B1], bird)
	assert_eq(_player.away.size(), 0)


func test_a_bird_played_this_turn_never_flies() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	var tern: RecruitUnit = _kit.put("old_tern", B1)
	tern.played_round = 5
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.board[B1], tern, "that would be a plain sale")


func test_flying_leaves_the_build_its_fewest_bodies() -> void:
	_kit.put("mrs_sorrel", F1)
	_bird("old_tern", B1)
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.away.size(), 0, "two on the ground is the floor")
	_kit.put("mr_crumb", F3)
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.away.size(), 1)


func test_late_in_the_game_the_floor_rises() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("mr_crumb", F3)
	_kit.put("alderman_dozey", F2)
	_bird("old_tern", B1)
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, BotHeld.LATE_ROUND)
	assert_eq(_player.away.size(), 0, "four is the floor from round 8")


func test_hard_doesnt_thin_a_board_already_behind_what_it_scouted() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	_bird("old_tern", B1)
	_player.scout = {"specs": [{"attack": 40, "health": 40}]}
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.away.size(), 0)


func test_the_lump_stands_on_a_nest_when_played_and_stays_there() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	_bird("mrs_jay", B3)
	_rules.sell(_player, B3)
	var lump: RecruitUnit = _unit("great_lump")
	var brain: BotBrain = _brain("hard:birds_passage")
	assert_eq(BotPlacer.play_slot(_player, lump, brain.value), B3)
	_player.board[B3] = lump
	assert_true(BotPlacer.pinned_slots(_player).has(B3), "Nests don't move, so it doesn't")


func test_a_plain_unit_isnt_pinned_by_a_nest() -> void:
	_bird("mrs_jay", B3)
	_rules.sell(_player, B3)
	_player.board[B3] = _unit("mrs_sorrel")
	assert_false(BotPlacer.pinned_slots(_player).has(B3))


func test_one_swallow_no_longer_needs_a_bird_beside_it() -> void:
	_kit.put("mrs_jay", F4)
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	var slot: int = BotPlacer.play_slot(_player, _unit("one_swallow"), brain.value)
	assert_true(BoardGeometry.is_valid(slot))
	assert_eq(brain.value.hint("one_swallow", "next_to"), "")


func test_placing_ignores_eggs_as_movers() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	_kit.put("sexton_beetle", B1)
	_bird("mrs_jay", B3)
	_rules.sell(_player, B3)
	var brain: BotBrain = _brain("hard")
	var layout: Array[int] = BotPlacer.rule_layout(_player, brain.value, [])
	var moved: int = 0
	for slot: int in BoardGeometry.SLOTS:
		if layout[slot] >= 0:
			moved += 1
	assert_eq(moved, 4, "four units, no Egg")
	assert_eq(_player.combat_board()[B3]["def_id"], HeldUnits.EGG, "the fight has one")
	assert_eq(_player.board_specs()[B3], null, "the bot's layout doesn't")
	var with_egg: int = BotBrain.stat_sum(_player.combat_board())
	assert_gt(with_egg, BotBrain.stat_sum(_player.board_specs()), "the mirrored Egg adds strength")


## The scout must show the board, the Nests and no more: not who's away or when they land.
func test_a_bot_cant_read_who_is_away() -> void:
	var game_config: GameConfig = GameConfig.full_game()
	game_config.set_value("pass3_content", false)
	game_config.set_value("bots", BotLobby.seats(BotLevel.HARD))
	var session: GameSession = GameSession.create(3, LegacyWave1.library(), game_config)
	var other: PlayerState = session._players[0]
	var bird: RecruitUnit = RecruitUnit.make(session._rules.library.get_unit("old_tern"), 900)
	other.away.append({"unit": bird, "left": 1, "due": 5, "nest": F2})
	other.fought_nests = [F2]
	other.fought_view = [null]
	var scout: Dictionary = session._scout_of(0)
	assert_false(str(scout).contains("old_tern"), "no name")
	assert_false(scout.has("away"))
	assert_eq(scout["nests"], [F2], "the slot is all that shows")


func test_a_scouted_egg_doesnt_trip_up_facing_or_judging() -> void:
	var specs: Array = [{"def_id": HeldUnits.EGG, "golden": false, "egg": true}, null]
	assert_eq(BotBrain.stat_sum(specs), 0)
	_player.scout = {"specs": specs, "slots": [], "views": [], "tier": 1, "hero_effects": []}
	var brain: BotBrain = _brain("hard")
	_kit.put("mag_pye", F1)
	assert_eq(BotPlacer.rule_layout(_player, brain.value, []).size(), BoardGeometry.SLOTS)


func test_a_ghost_keeps_its_nests_and_its_birds_copies_go_home() -> void:
	var game_config: GameConfig = GameConfig.full_game()
	game_config.set_value("pass3_content", false)
	game_config.set_value("bots", BotLobby.seats(BotLevel.HARD))
	var session: GameSession = GameSession.create(3, LegacyWave1.library(), game_config)
	var gone: PlayerState = session._players[2]
	var bird: RecruitUnit = RecruitUnit.make(session._rules.library.get_unit("old_tern"), 900)
	gone.away.append({"unit": bird, "left": 1, "due": 5, "nest": F2})
	gone.remember_fought_board()
	gone.health = 0
	session._eliminate()
	assert_eq(session._ghost_board[F2]["def_id"], HeldUnits.EGG, "the ghost fights with its Egg")
	assert_eq(session._ghost_nests, [F2])
	assert_eq(session._ghost_rules["nests"].size(), 1, "and its Nest counts in that fight")
	assert_true(gone.away.is_empty(), "the eliminated player keeps nothing")


func test_a_lobby_deals_the_new_builds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var seats: PackedStringArray = []
	for _seat: int in 8:
		seats.append("hard:varied")
	var tribes: PackedStringArray = ["Hedgerow folk", "Fairies", "Oozes", "Birds"]
	var eligible: Dictionary = {}
	for entry: Dictionary in BotKnowledge.shared().open_strategies(Array(tribes)):
		var id: String = str(entry["id"])
		eligible[id] = true
		var brain: BotBrain = _brain("hard:" + id)
		assert_not_null(brain, id + " has a usable bot factory")
		assert_eq(brain.build_name(), id)
		assert_true(BotKnowledge.tribes_available(entry, Array(tribes)))
	assert_gte(eligible.size(), seats.size(), "this pool can deal eight distinct builds")
	for build: String in [
		"oozes_second_helpings",
		"oozes_waste_not",
		"oozes_rude_awakening",
		"birds_summer_winter",
		"birds_passage",
		"birds_highway",
	]:
		assert_true(eligible.has(build), build + " remains available to the deal")
	var names: PackedStringArray = BotLobby.resolve(seats, tribes, rng)
	assert_eq(names.size(), 8)
	var dealt: Dictionary = {}
	for bot_name: String in names:
		var build: String = bot_name.get_slice(":", 1)
		assert_true(eligible.has(build), "the deal uses only lobby-legal builds")
		assert_false(dealt.has(build), "the deck does not repeat before exhausting the pool")
		dealt[build] = true
	var repeated_rng := RandomNumberGenerator.new()
	repeated_rng.seed = 5
	assert_eq(BotLobby.resolve(seats, tribes, repeated_rng), names, "the seeded deal is repeatable")
	var bench_names: Array = BenchSuites._strategy_names()
	assert_true(bench_names.has("birds_passage"), "and the bench's spread has them")


## Real Hard play for HELD_ROUNDS rounds (was up to 40 turns, a whole game; pass3_bots also stops
## at a fixed round). A strategy the bot never carries out wouldn't be a strategy.
func _count_in_games(bots: Array, game_seed: int) -> Dictionary:
	var counts: Dictionary = {}
	var game_config: GameConfig = GameConfig.full_game()
	game_config.set_value("pass3_content", false)
	# This integration fixture exercises both mechanics, so both tribes must be available.
	game_config.set_value("tribes_per_lobby", 6)
	game_config.set_value("bots", bots)
	game_config.set_value("human_bot", str(bots[0]))
	var session: GameSession = GameSession.create(game_seed, LegacyWave1.library(), game_config)
	var note: Callable = func(type: String, _fields: Dictionary) -> void:
		counts[type] = CoreUtil.to_int(counts.get(type, 0)) + 1
	for player: PlayerState in session._players:
		player.log_observer = note
	var turns: int = 0
	while not session.is_over() and turns < HELD_ROUNDS:
		session.end_turn()
		turns += 1
	return counts


func test_hard_really_swallows_and_flies() -> void:
	var bots: Array = [
		"hard:oozes_second_helpings",
		"hard:oozes_waste_not",
		"hard:oozes_rude_awakening",
		"hard:birds_summer_winter",
		"hard:birds_passage",
		"hard:birds_highway",
		"hard:birds_summer_winter",
	]
	var counts: Dictionary = _count_in_games(bots, 42)
	assert_gt(CoreUtil.to_int(counts.get("swallow", 0)), 0)
	assert_gt(CoreUtil.to_int(counts.get("fly_south", 0)), 0)
	assert_gt(CoreUtil.to_int(counts.get("home", 0)), 0)


func test_half_eggs_charge_half_the_growth_including_goose() -> void:
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	var tern: RecruitUnit = _bird("old_tern", F1)
	var before: float = BotHeld.trip_score(tern, _player, brain.value)
	tern.add_permanent(20, 20)
	assert_eq(BotHeld.trip_score(tern, _player, brain.value), before - 20.0)
	var goose: RecruitUnit = _bird("mother_goose", F2)
	before = BotHeld.trip_score(goose, _player, brain.value)
	goose.add_permanent(20, 20)
	assert_eq(BotHeld.trip_score(goose, _player, brain.value), before - 20.0)
