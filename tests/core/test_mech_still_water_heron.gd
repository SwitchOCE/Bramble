extends GutTest
## Still-Water Heron (library entry 56): Fast (refresh, 2). At End of Turn (rulebook 3.4.1 step 1)
## a turn without a paid refresh counts up; at 2 the Feast gives +2/+2 permanently.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()
var _rules: RecruitRules
var _player: PlayerState


func before_each() -> void:
	var config: GameConfig = GameConfig.defaults()
	_rules = RecruitRules.create(_library, config, UnitPool.create(_library, config))
	_player = PlayerState.new()
	_player.shop_rng.seed = 5
	_rules.setup_player(_player)


func _heron(golden: bool = false) -> RecruitUnit:
	var unit := RecruitUnit.make(_library.get_unit("still_water_heron"), _rules.new_iid(), golden)
	_player.board[2] = unit
	return unit


func _turn(round_number: int, refreshes: int) -> void:
	_rules.start_phase(_player, round_number)
	_player.gold = 99
	for _index: int in refreshes:
		assert_eq(_rules.refresh(_player), "", "refresh")
	_rules.end_phase(_player)


func test_two_quiet_turns_feast() -> void:
	var heron: RecruitUnit = _heron()
	_turn(1, 0)
	assert_eq([heron.counters["fast"], heron.attack, heron.health], [1, 2, 2], "count 1")
	_turn(2, 0)
	assert_eq([heron.counters["fast"], heron.attack, heron.health], [0, 4, 4], "Feast, reset")
	assert_eq(heron.view()["counters"], {"fast": 0}, "the count is on the card")


func test_a_paid_refresh_resets_the_count() -> void:
	var heron: RecruitUnit = _heron()
	_turn(1, 0)
	_turn(2, 1)
	assert_eq([heron.counters["fast"], heron.attack], [0, 2], "back to 0, no Feast")
	_turn(3, 0)
	_turn(4, 0)
	assert_eq(heron.attack, 4, "two quiet turns again")


func test_only_board_units_count() -> void:
	var heron := RecruitUnit.make(_library.get_unit("still_water_heron"), _rules.new_iid())
	_player.hand.append(heron)
	_turn(1, 0)
	assert_false(heron.counters.has("fast"), "End of Turn is a board effect")


func test_golden_feasts_for_four() -> void:
	var heron: RecruitUnit = _heron(true)
	_turn(1, 0)
	_turn(2, 0)
	assert_eq([heron.attack, heron.health], [8, 8], "4/4 + 4/4, still every 2 turns")
