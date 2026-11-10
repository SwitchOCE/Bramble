extends GutTest
## Combat for plain units by rulebook chapter 9, damage by 10.1, and the event log of SPEC
## section 5 checked against docs/prototype/fixtures/combat_nightshade.json.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const FIXTURE: String = "res://docs/prototype/fixtures/combat_nightshade.json"
const BIG: int = 1000000

var _library: UnitLibrary = TestLibraries.current()


## A plain unit with chosen stats (Field Vole is tier 1, Elder Ooze tier 6).
func _u(attack: int, health: int, def_id: String = "field_vole") -> Dictionary:
	return {"def_id": def_id, "golden": false, "attack": attack, "health": health}


func _board(units: Dictionary) -> Array:
	var board: Array = []
	board.resize(BoardGeometry.SLOTS)
	for slot: int in units:
		board[slot] = units[slot]
	return board


func _run(board_0: Array, board_1: Array, fight_seed: int = 1, cap: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(_library, GameConfig.defaults(), rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	return combat.run([board_0, board_1], tiers, ids, cap)


func _of_type(result: Dictionary, type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var events: Array[Dictionary] = result["events"]
	for event: Dictionary in events:
		if event["type"] == type:
			out.append(event)
	return out


func _last(result: Dictionary) -> Dictionary:
	var events: Array[Dictionary] = result["events"]
	return events[events.size() - 1]


func test_more_units_attack_first_9_2_1() -> void:
	var result: Dictionary = _run(_board({0: _u(1, 5)}), _board({0: _u(1, 5), 1: _u(1, 5)}))
	var start: Dictionary = result["events"][0]
	assert_eq(start["first_side"], 1, "side 1 has more units")
	var attacks: Array[Dictionary] = _of_type(result, "attack")
	assert_eq(attacks[0]["side"], 1, "and attacks first")


func test_equal_units_first_side_random_9_2_1() -> void:
	var seen: Dictionary = {}
	for fight_seed: int in 20:
		var result: Dictionary = _run(_board({0: _u(1, 5)}), _board({0: _u(1, 5)}), fight_seed)
		var start: Dictionary = result["events"][0]
		seen[start["first_side"]] = true
	assert_eq(seen.size(), 2, "both sides go first for some seed")


func test_attack_order_front_then_back_9_4_2_9_4_5() -> void:
	var mine: Array = _board({0: _u(1, BIG), 2: _u(1, BIG), 5: _u(1, BIG)})
	var theirs: Array = _board({0: _u(0, BIG)})
	var result: Dictionary = _run(mine, theirs)
	var attacks: Array[Dictionary] = _of_type(result, "attack")
	var order: Array = []
	for index: int in 7:
		order.append(attacks[index]["attacker"])
	assert_eq(order, [1, 2, 3, 1, 2, 3, 1], "F1, F3, B2, then the cycle repeats (9.4.7 gaps skip)")


func test_zero_attack_never_attacks_and_side_passes_9_4_6_9_4_10() -> void:
	var result: Dictionary = _run(_board({0: _u(0, 5), 1: _u(1, 50)}), _board({0: _u(1, 50)}))
	for attack: Dictionary in _of_type(result, "attack"):
		assert_ne(attack["attacker"], 1, "the 0-Attack unit never attacks")
	var passes: Array[Dictionary] = _of_type(result, "pass")
	assert_eq(passes.size(), 0, "side 0 still has an attacker, so it never passes")
	var lone: Dictionary = _run(_board({0: _u(0, 50)}), _board({0: _u(1, 5)}))
	assert_gt(_of_type(lone, "pass").size(), 0, "a side with no attacker passes")


func test_back_row_protected_while_front_lives_9_5_1() -> void:
	var mine: Array = _board({0: _u(1, BIG)})
	var theirs: Array = _board({1: _u(0, 3), 4: _u(0, 100)})
	var result: Dictionary = _run(mine, theirs)
	var attacks: Array[Dictionary] = _of_type(result, "attack")
	for index: int in 3:
		assert_eq(attacks[index]["defender"], 2, "the front unit is hit first")
	assert_eq(attacks[3]["defender"], 3, "then the back row is the candidate row")


func test_random_target_among_front_units_9_5_5() -> void:
	var seen: Dictionary = {}
	for fight_seed: int in 20:
		var mine: Array = _board({0: _u(1, 10)})
		var theirs: Array = _board({0: _u(0, 10), 3: _u(0, 10), 5: _u(0, 10)})
		var attacks: Array[Dictionary] = _of_type(_run(mine, theirs, fight_seed), "attack")
		seen[attacks[0]["defender"]] = true
	assert_eq(seen.keys().size(), 2, "both front units get hit; never the back unit")
	assert_false(seen.has(4), "the back unit is protected")


func test_simultaneous_damage_and_tie_9_6_1_9_9_2() -> void:
	var result: Dictionary = _run(_board({0: _u(3, 3)}), _board({0: _u(3, 3)}))
	var damage: Array[Dictionary] = _of_type(result, "damage")
	assert_eq(damage.size(), 2, "both deal damage")
	assert_eq(
		damage[0]["source"], _of_type(result, "attack")[0]["attacker"], "attacker first (9.6.2)"
	)
	assert_eq(_of_type(result, "death").size(), 2, "both die together (9.6.3)")
	var end: Dictionary = _last(result)
	assert_eq(end["winner"], -1, "both boards empty is a tie")
	assert_eq(end["reason"], "board_empty", "reason")
	assert_eq(end["damage"], 0, "a tie deals nothing (10.1.6)")


func test_damage_stays_for_the_combat_9_6_4() -> void:
	var result: Dictionary = _run(_board({0: _u(2, 10)}), _board({0: _u(1, 10)}))
	var to_side_1: Array = []
	for event: Dictionary in _of_type(result, "damage"):
		if event["target"] == 2:
			to_side_1.append(event["health_after"])
	assert_eq(to_side_1.slice(0, 3), [8, 6, 4], "damage adds up")


func test_death_order_active_side_first_9_7_3() -> void:
	var mine: Array = _board({0: _u(5, 1)})
	var theirs: Array = _board({0: _u(5, 1), 1: _u(0, 1)})
	var result: Dictionary = _run(mine, theirs)
	var deaths: Array[Dictionary] = _of_type(result, "death")
	assert_eq(deaths[0]["side"], 1, "side 1 attacked first (more units), so its dead go first")
	assert_eq(deaths[1]["side"], 0, "then the other side")
	assert_eq(deaths[0]["slot"], 0, "the slot it left (9.7.1)")


func test_winner_damage_formula_10_1_1() -> void:
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(_library, GameConfig.defaults(), rng)
	var tiers: Array[int] = [3, 2]
	var ids: Array[int] = [0, 1]
	var mine: Array = _board({0: _u(10, 10, "elder_ooze"), 4: _u(10, 10, "fieldfare")})
	var result: Dictionary = combat.run([mine, _board({0: _u(1, 1)})], tiers, ids, 0)
	assert_eq(result["winner"], 0, "side 0 wins")
	assert_eq(result["damage"], 3 + 5 + 2, "tier 3 plus surviving tiers 5 and 2, both rows")


func test_damage_cap_10_1_4() -> void:
	var mine: Array = _board({0: _u(10, 10, "elder_ooze"), 1: _u(10, 10, "elder_ooze")})
	var result: Dictionary = _run(mine, _board({0: _u(1, 1)}), 1, 5)
	var end: Dictionary = _last(result)
	assert_eq(end["damage_uncapped"], 11, "1 + 5 + 5")
	assert_eq(end["damage"], 5, "capped")


func test_golden_counts_normal_tier_10_1_2() -> void:
	var golden: Dictionary = {"def_id": "elder_ooze", "golden": true}
	var result: Dictionary = _run(_board({0: golden}), _board({0: _u(1, 1)}))
	assert_eq(result["damage"], 1 + 5, "golden keeps tier 5")


func test_neither_side_can_attack_is_a_tie_9_9_1() -> void:
	var result: Dictionary = _run(_board({0: _u(0, 5)}), _board({0: _u(0, 5)}))
	var end: Dictionary = _last(result)
	assert_eq(end["reason"], "no_attacks", "reason")
	assert_eq(end["winner"], -1, "tie")


func test_attack_limit_9_10_1() -> void:
	var result: Dictionary = _run(_board({0: _u(1, BIG)}), _board({0: _u(1, BIG)}))
	assert_eq(_of_type(result, "attack").size(), 200, "200 attacks")
	var end: Dictionary = _last(result)
	assert_eq(end["reason"], "attack_limit", "reason")
	assert_eq(end["winner"], -1, "ends as a tie")


func test_empty_board_ends_at_once_9_3_5() -> void:
	var result: Dictionary = _run(_board({0: _u(1, 1)}), _board({}))
	assert_eq(_of_type(result, "attack").size(), 0, "no attacks")
	assert_eq(result["winner"], 0, "the side with units wins")


func test_same_seed_same_log() -> void:
	var mine: Array = _board({0: _u(2, 6), 2: _u(3, 4), 4: _u(1, 9)})
	var theirs: Array = _board({1: _u(4, 4), 3: _u(2, 7), 6: _u(3, 3)})
	assert_eq(_run(mine, theirs, 77)["events"], _run(mine, theirs, 77)["events"], "deterministic")


# Damage mode/performance metadata is now present even on the unchanged legacy fixture.
func test_event_fields_match_the_fixture_5() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var fixture_events: Array = fixture["events"]
	var shapes: Dictionary = {}
	for event: Variant in fixture_events:
		var entry: Dictionary = event
		shapes[entry["type"]] = _sorted_keys(entry)
	var mine: Array = _board({0: _u(3, 4), 5: _u(2, 2)})
	var result: Dictionary = _run(mine, _board({1: _u(2, 3)}))
	var checked: Dictionary = {}
	var produced: Array[Dictionary] = result["events"]
	for event: Dictionary in produced:
		var type: String = event["type"]
		if shapes.has(type):
			assert_eq(_sorted_keys(event), shapes[type], "%s has the fixture's fields" % type)
			checked[type] = true
	for type: String in ["combat_start", "phase", "attack", "damage", "death", "combat_end"]:
		assert_true(checked.has(type), "%s was produced and checked" % type)
	var seqs: Array = []
	var events: Array[Dictionary] = result["events"]
	for event: Dictionary in events:
		seqs.append(event["seq"])
	assert_eq(seqs, range(seqs.size()), "seq counts from 0")


func test_combat_unit_view_matches_fixture_6_3() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var fixture_start: Dictionary = fixture["events"][0]
	var fixture_view: Dictionary = fixture_start["boards"][0][1]
	var expected: Array = _sorted_keys(fixture_view)
	if not expected.has("keyword_text"):
		expected.append("keyword_text")
	expected.sort()
	var result: Dictionary = _run(_board({1: _u(1, 3, "hoglet_mother")}), _board({0: _u(1, 1)}))
	var start: Dictionary = result["events"][0]
	var view: Dictionary = start["boards"][0][1]
	assert_eq(_sorted_keys(view), expected, "6.3 view plus keyword_text")
	assert_eq(view["max_health"], 3, "max_health")
	assert_null(start["boards"][0][0], "empty slots are null")


func _sorted_keys(entry: Dictionary) -> Array:
	var keys: Array = entry.keys()
	keys.sort()
	return keys
