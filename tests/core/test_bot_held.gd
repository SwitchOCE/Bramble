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
## One of each, so nothing triples.
const FILLER: Array[String] = [
	"mrs_burdock", "mr_crumb", "mrs_sorrel", "sexton_beetle", "alderman_dozey", "earwig_mother"
]

var _kit: Variant
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
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
	var brain: BotBrain = _brain("normal:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	brain._play_hand()
	assert_eq(ooze.held.size(), 1, "into the Belly")
	assert_eq(ooze.held[0].def_id(), "pill_bug")
	assert_eq(_player.board_count(), 7, "nobody sold")


func test_easy_uses_a_belly_too() -> void:
	var ooze: RecruitUnit = _kit.put("wee_wobbly", F1)
	_fill_to_seven(F2)
	_kit.put("pill_bug")
	var brain: BotBrain = _brain("easy")
	brain._player = _player
	brain._rules = _rules
	brain._play_hand()
	assert_eq(ooze.held.size(), 1)


func test_a_discounting_belly_gets_the_buy_and_charges_less() -> void:
	var ooze: RecruitUnit = _kit.put("little_dollop", F1)
	_player.shop.clear()
	_kit.shop("pill_bug")
	var brain: BotBrain = _brain("normal:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	assert_eq(brain._buy_unit(0), "")
	assert_eq(ooze.held.size(), 1, "bought straight in")
	assert_eq(_player.gold, 10 - _rules.unit_cost(_player) + 1, "a gold off")


func test_a_card_paid_on_play_is_played_not_swallowed() -> void:
	var ooze: RecruitUnit = _kit.put("little_dollop", F1)
	_player.shop.clear()
	_kit.shop("mr_crumb")
	var brain: BotBrain = _brain("normal:oozes_second_helpings")
	brain._player = _player
	brain._rules = _rules
	brain._buy_unit(0)
	assert_eq(ooze.held.size(), 0, "its value is in the playing")
	assert_eq(_player.hand.size(), 1)


func test_hasty_stays_empty_for_a_level_that_reads_cards() -> void:
	_kit.put("hasty_pudding", F1)
	var brain: BotBrain = _brain("normal:oozes_rude_awakening")
	assert_eq(BotHeld.best_belly(_player, brain.value, _unit("pill_bug")), -1)


func test_a_front_ooze_is_chosen_over_a_back_one() -> void:
	_kit.put("wee_wobbly", B1)
	_kit.put("bubble_and_squeak", F2)
	var brain: BotBrain = _brain("normal")
	assert_eq(BotHeld.best_belly(_player, brain.value, _unit("pill_bug")), F2)


func test_a_full_ooze_is_worth_more_than_an_empty_one() -> void:
	var brain: BotBrain = _brain("normal")
	var ooze: RecruitUnit = _kit.put("wee_wobbly", F1)
	var empty: float = brain.value.keep_value(ooze)
	ooze.held.append(_unit("mrs_sorrel"))
	assert_gt(brain.value.keep_value(ooze), empty)


func test_hard_flies_a_bird_with_a_good_trip_and_keeps_the_gold() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	var tern: RecruitUnit = _bird("old_tern", B1)
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_null(_player.board[B1], "it left")
	assert_eq(_player.away.size(), 1)
	assert_eq(_player.away[0]["unit"], tern)
	assert_eq(_player.gold, 11, "the sale paid")


func test_a_big_bird_with_a_small_trip_stays() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	var bird: RecruitUnit = _bird("one_swallow", B1)
	bird.attack = 12
	bird.health = 12
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.board[B1], bird)


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


func test_normal_doesnt_read_the_scout_for_that() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_kit.put("mr_crumb", F3)
	_bird("old_tern", B1)
	_player.scout = {"specs": [{"attack": 40, "health": 40}]}
	var brain: BotBrain = _brain("normal:birds_summer_winter")
	BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.away.size(), 1)


func test_easy_flies_only_when_short_of_gold() -> void:
	_kit.put("mrs_sorrel", F1)
	_kit.put("alderman_dozey", F2)
	_bird("one_swallow", B1)
	var brain: BotBrain = _brain("easy")
	_player.bot_rng.seed = 1
	for _try: int in 20:
		BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.away.size(), 0, "ten gold: no need")
	_player.gold = 0
	for _try: int in 20:
		if _player.away.is_empty():
			BotHeld.fly_turn(_player, _rules, brain.value, 5)
	assert_eq(_player.away.size(), 1)


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


func test_one_swallow_lands_next_to_a_bird() -> void:
	_kit.put("mrs_jay", F4)
	var brain: BotBrain = _brain("hard:birds_summer_winter")
	var slot: int = BotPlacer.play_slot(_player, _unit("one_swallow"), brain.value)
	assert_true(BoardGeometry.neighbours(F4).has(slot), "its gold needs a Bird beside it")


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
	assert_eq(with_egg, BotBrain.stat_sum(_player.board_specs()), "an Egg adds no read strength")


## The scout must show the board, the Nests and no more: not who's away or when they land.
func test_a_bot_cant_read_who_is_away() -> void:
	var game_config: GameConfig = GameConfig.full_game()
	game_config.set_value("bots", BotLobby.seats(BotLevel.HARD))
	var session: GameSession = GameSession.create(3, UnitLibrary.load_dir(), game_config)
	var other: PlayerState = session._players[0]
	var bird: RecruitUnit = RecruitUnit.make(session._rules.library.get_unit("old_tern"), 900)
	other.away.append({"unit": bird, "left": 1, "due": 5, "nest": F2})
	other.fought_nests = [F2]
	other.fought_view = [null]
	var scout: Dictionary = session._scout_of(0)
	assert_false(str(scout).contains("old_tern"), "no name")
	assert_false(scout.has("away"))
	assert_eq(scout["nests"], [F2], "the slot is all that shows")
