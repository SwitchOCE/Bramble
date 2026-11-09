extends GutTest
## CombatSandbox: set two boards, fight, get the log (PLAN item 6, SPEC section 7).
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

var _library: UnitLibrary = UnitLibrary.load_dir()


func _board(entries: Dictionary) -> Array:
	var board: Array = []
	board.resize(7)
	for slot: int in entries:
		board[slot] = entries[slot]
	return board


func test_set_and_get_board() -> void:
	var sandbox: CombatSandbox = CombatSandbox.create(_library)
	var board: Array = _board({0: {"def_id": "field_vole", "golden": false}})
	assert_eq(sandbox.set_board(0, board), "", "valid board")
	assert_eq(sandbox.get_board(0), board, "round trip")


func test_set_board_rejects_bad_input() -> void:
	var sandbox: CombatSandbox = CombatSandbox.create(_library)
	assert_eq(sandbox.set_board(2, _board({})), "Side must be 0 or 1", "side")
	assert_eq(sandbox.set_board(0, []), "A board has 7 slots", "size")
	var unknown: Array = _board({1: {"def_id": "dragon"}})
	assert_eq(sandbox.set_board(0, unknown), "Unknown unit: dragon", "unknown unit")
	var weak: Array = _board({1: {"def_id": "field_vole", "health": 0}})
	assert_eq(sandbox.set_board(0, weak), "Health must be at least 1", "health")


func test_fight_returns_log_winner_and_damage() -> void:
	var sandbox: CombatSandbox = CombatSandbox.create(_library)
	sandbox.set_board(0, _board({0: {"def_id": "elder_ooze"}}))
	sandbox.set_board(1, _board({0: {"def_id": "field_vole"}}))
	sandbox.set_tier(0, 4)
	var result: Dictionary = sandbox.fight(3)
	assert_eq(result.keys().size(), 3, "events, winner, damage")
	assert_eq(result["winner"], 0, "the Elder wins")
	assert_eq(result["damage"], 4 + 5, "tier 4 plus the Elder Ooze's tier 5, no cap")


func test_golden_and_stat_overrides_7_3_4() -> void:
	var sandbox: CombatSandbox = CombatSandbox.create(_library)
	sandbox.set_board(0, _board({0: {"def_id": "field_vole", "golden": true}}))
	sandbox.set_board(1, _board({0: {"def_id": "field_vole", "attack": 1, "health": 40}}))
	var result: Dictionary = sandbox.fight(1)
	var start: Dictionary = result["events"][0]
	var golden: Dictionary = start["boards"][0][0]
	assert_eq([golden["attack"], golden["health"]], [4, 6], "golden doubles 2/3")
	var tall: Dictionary = start["boards"][1][0]
	assert_eq([tall["attack"], tall["health"]], [1, 40], "overrides")
