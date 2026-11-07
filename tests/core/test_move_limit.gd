extends GutTest
## The free-move limit, a test rule that is off by default (evidence/placing.md).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()
var _config: GameConfig
var _rules: RecruitRules
var _player: PlayerState


func before_each() -> void:
	_config = GameConfig.defaults()
	_config.set_value("free_moves_per_turn", 1)
	_rules = RecruitRules.create(_library, _config, UnitPool.create(_library, _config))
	_player = PlayerState.new()
	_rules.setup_player(_player)


func _unit(def_id: String) -> RecruitUnit:
	return RecruitUnit.make(_library.get_unit(def_id), _rules.new_iid())


func _settle() -> void:
	_player.counted_moves = 0
	_player.iids_at_start = _player.board_iids()


func test_off_by_default() -> void:
	var config: GameConfig = GameConfig.defaults()
	var rules := RecruitRules.create(_library, config, UnitPool.create(_library, config))
	assert_false(RecruitExtras.limits_moves(rules))


func test_one_free_move_then_gold() -> void:
	_player.board[0] = _unit("field_vole")
	_player.board[1] = _unit("marsh_frog")
	_settle()
	_player.gold = 1
	assert_eq(_rules.move(_player, 0, 6), "", "the free move")
	assert_eq(_player.gold, 1, "free")
	assert_eq(_rules.move(_player, 6, 0), "", "a paid move")
	assert_eq(_player.gold, 0, "costs move_cost")
	assert_eq(_rules.move(_player, 0, 5), "Not enough gold")
	assert_eq(_player.board[0].def_id(), "field_vole", "didn't move")


func test_units_played_this_turn_move_freely() -> void:
	_player.board[0] = _unit("field_vole")
	_settle()
	_player.gold = 0
	_player.board[3] = _unit("marsh_frog")
	assert_eq(_rules.move(_player, 3, 4), "", "into an empty slot")
	assert_eq(_rules.move(_player, 4, 5), "", "and again")
	assert_eq(_player.counted_moves, 0)
	assert_eq(_rules.move(_player, 5, 0), "", "a swap with a settled unit counts")
	assert_eq(_player.counted_moves, 1)
	assert_eq(_rules.move(_player, 0, 5), "Not enough gold")


func test_start_of_turn_resets_the_count() -> void:
	_player.board[0] = _unit("field_vole")
	_player.counted_moves = 5
	_rules.start_phase(_player, 2)
	assert_eq(_player.counted_moves, 0)
	assert_eq(_player.iids_at_start, _player.board_iids())
