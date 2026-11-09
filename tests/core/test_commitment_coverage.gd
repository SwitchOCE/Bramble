extends GutTest
## Coverage follows a real aura application; buying or merely fielding the Monarch is insufficient.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _coverage: SoakCoverage


func before_each() -> void:
	_coverage = SoakCoverage.new()
	BoardUpkeep.aura_observer = _coverage.note_aura


func after_each() -> void:
	BoardUpkeep.aura_observer = Callable()


func test_monarch_counts_only_when_its_bonus_is_applied_to_a_fairy_ring() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game(), true)
	kit.put("fairy_monarch", 0)
	var fairy: RecruitUnit = kit.put("wisp", 1)
	BoardUpkeep.add_ring(kit.player, 1, {"attack": 1, "health": 1})
	assert_eq(_coverage.card_counts().get("fairy_monarch", 0), 0, "presence does not count")
	kit.rules.board_changed(kit.player)
	assert_eq(fairy.aura_attack, 2, "Ring plus the actual Monarch contribution")
	assert_eq(_coverage.card_counts().get("fairy_monarch", 0), 1)
	kit.rules.board_changed(kit.player)
	assert_eq(
		_coverage.card_counts().get("fairy_monarch", 0),
		1,
		"unchanged recalculation is not a new application"
	)


func test_monarch_without_a_fairy_on_a_ring_does_not_count() -> void:
	var kit: KIT = KIT.new()
	kit.setup(GameConfig.full_game(), true)
	kit.put("fairy_monarch", 0)
	kit.put("wisp", 1)
	kit.put("pill_bug", 2)
	BoardUpkeep.add_ring(kit.player, 2, {"attack": 2, "health": 2})
	kit.rules.board_changed(kit.player)
	_coverage.note_board(kit.player)
	assert_eq(_coverage.card_counts().get("fairy_monarch", 0), 0)
	kit.player.board[0] = null
	BoardUpkeep.add_ring(kit.player, 1, {"attack": 2, "health": 2})
	kit.rules.board_changed(kit.player)
	assert_eq(
		_coverage.card_counts().get("fairy_monarch", 0),
		0,
		"a Fairy Ring without a Monarch is not its effect"
	)
