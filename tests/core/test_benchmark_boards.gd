extends GutTest
@warning_ignore_start("unsafe_call_argument")

const Boards := preload("res://tools/sim/benchmark_boards.gd")
const Tournament := preload("res://tools/sim/benchmark_tournament.gd")

var _library: UnitLibrary
var _loaded: Dictionary


func before_all() -> void:
	_library = UnitLibrary.load_dir()
	_loaded = Boards.load_all(_library)


func _find(tribe: String, round_number: int, roll: String) -> Dictionary:
	for board: Dictionary in _loaded["boards"]:
		var source: Dictionary = board["source"]
		if source["tribe"] == tribe and source["round"] == round_number and source["roll"] == roll:
			return board
	return {}


func _fixture(entries: Dictionary) -> Dictionary:
	var slots: Dictionary = {}
	for label: String in BoardGeometry.LABELS:
		slots[label] = entries.get(label)
	return {
		"tribe": "test",
		"round": 3,
		"roll": "average",
		"tier": 1,
		"rank": 1,
		"stat_total": 0,
		"slots": slots
	}


func _translated(entries: Dictionary) -> Dictionary:
	var source: Dictionary = _fixture(entries)
	var total: int = 0
	for value: Variant in entries.values():
		var entry: Dictionary = value
		total += CoreUtil.to_int(entry["attack"]) + CoreUtil.to_int(entry["health"])
		for inner: Dictionary in entry.get("belly", []):
			total += CoreUtil.to_int(inner["attack"]) + CoreUtil.to_int(inner["health"])
	source["stat_total"] = total
	return Boards.translate(source, _library)


func _u(id: String, attack: int, health: int, golden: bool = false) -> Dictionary:
	return {"unit": id, "attack": attack, "health": health, "golden": golden, "keywords": []}


func _combat_before_start(left: Dictionary, right: Dictionary) -> Combat:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(_library, GameConfig.full_game(), rng)
	combat.side_rules = [left["rules"], right["rules"]]
	combat.slot_effects = [left["slot_effects"], right["slot_effects"]]
	combat._slots_active = BoardUpkeep.any_slot_effects(combat.slot_effects)
	combat._setup([left["specs"], right["specs"]])
	combat._recalc_auras(false)
	return combat


func test_all_72_boards_load_with_source_stat_totals() -> void:
	assert_eq(_loaded["errors"], [])
	var boards: Array = _loaded["boards"]
	assert_eq(boards.size(), 72)
	for board: Dictionary in boards:
		assert_eq(
			board["stat_total"], CoreUtil.to_int(board["source"]["stat_total"]), str(board["id"])
		)


func test_slot_labels_keep_holes_and_reading_order() -> void:
	var board: Dictionary = _translated({"F4": _u("pill_bug", 2, 6), "B2": _u("mrs_jay", 7, 8)})
	assert_eq(board["errors"], [])
	var specs: Array = board["specs"]
	assert_eq(specs.size(), 7)
	assert_eq(specs[0], null)
	assert_eq(specs[3]["def_id"], "pill_bug")
	assert_eq(specs[5]["def_id"], "mrs_jay")
	assert_eq(specs[6], null)


func test_every_supplied_stat_is_exact_before_start_of_combat() -> void:
	var empty: Dictionary = _translated({})
	for board: Dictionary in _loaded["boards"]:
		var result: Dictionary = Tournament.fight(
			_library, GameConfig.full_game(), board, empty, 7, true
		)
		var events: Array[Dictionary] = result["events"]
		var start: Dictionary = events[0]
		assert_eq(start["type"], "combat_start")
		var actual: Array = start["boards"][0]
		var slots: Dictionary = board["source"]["slots"]
		for slot: int in BoardGeometry.SLOTS:
			var expected: Variant = slots[BoardGeometry.LABELS[slot]]
			if expected == null:
				assert_eq(actual[slot], null)
			else:
				assert_eq(
					actual[slot]["attack"], CoreUtil.to_int(expected["attack"]), str(board["id"])
				)
				assert_eq(
					actual[slot]["health"], CoreUtil.to_int(expected["health"]), str(board["id"])
				)
				assert_eq(actual[slot]["golden"], expected["golden"], str(board["id"]))


func test_golden_stats_are_totals_and_native_mechanics_still_double() -> void:
	var board: Dictionary = _translated({"F1": _u("mrs_sorrel", 6, 8, true)})
	var specs: Array = board["specs"]
	var unit: CombatUnit = CombatUnit.make(_library.get_unit("mrs_sorrel"), specs[0], 1, 0)
	assert_true(unit.golden)
	assert_eq([unit.attack, unit.health], [6, 8], "do not double supplied totals again")
	var steps: Array = MechanicRegistry.steps_of(unit.params[0])
	assert_eq(steps[0]["copies"], 2, "the card's golden text still applies")


func test_bellies_keep_order_stats_and_borrowed_text() -> void:
	var board: Dictionary = _find("Oozes", 6, "high")
	var specs: Array = board["specs"]
	var inside: Array = specs[0]["held"]
	assert_eq(inside.size(), 2)
	assert_eq([inside[0]["def_id"], inside[0]["attack"], inside[0]["health"]], ["pill_bug", 4, 7])
	assert_eq(inside[1]["def_id"], "mrs_posset")
	var frumenty: Dictionary = _find("Oozes", 9, "average")["specs"][2]
	var grants: Array = frumenty["grants"]
	assert_eq(grants.size(), 1)
	assert_eq(grants[0]["entry"]["trigger"], "start_of_combat")


func test_hex_annotation_means_total_not_counter_growth() -> void:
	var board: Dictionary = _find("Fairies", 9, "high")
	var spec: Dictionary = board["specs"][3]
	assert_eq(spec["hex"], 5, "printed Hex 1 plus growth 5 is annotated Hex 6")
	var enemy: Dictionary = _translated({"F4": _u("field_vole", 20, 100)})
	var result: Dictionary = Tournament.fight(
		_library, GameConfig.full_game(), board, enemy, 1, true
	)
	var events: Array[Dictionary] = result["events"]
	var found: bool = false
	for event: Dictionary in events:
		if event["type"] == "slot_hex":
			found = true
			# Pass 1 fixes cap plain Hedge Witch Hex at your tier (5 on this board).
			assert_eq(event["amount"], 5)
	assert_true(found)


func test_explicit_persistent_counters_reach_combat_unit() -> void:
	var entry: Dictionary = _u("his_highness", 3, 4)
	entry["kisses"] = 2
	entry["paid_pie"] = 3
	entry["egg_full_attack"] = 7
	entry["egg_full_health"] = 9
	var board: Dictionary = _translated({"F1": entry})
	var spec: Dictionary = board["specs"][0]
	var unit: CombatUnit = CombatUnit.make(_library.get_unit("his_highness"), spec, 1, 0)
	assert_eq(unit.counters["kisses"], 2)
	assert_eq(unit.counters["paid_pie"], 3)
	assert_eq(unit.counters["egg_full_attack"], 7)
	assert_eq(unit.counters["egg_full_health"], 9)


func test_unknown_unit_bad_stats_unknown_slot_and_total_mismatch_are_errors() -> void:
	var board: Dictionary = _translated({"F1": _u("not_a_unit", 1, 2)})
	assert_ne(board["errors"], [])
	board = _translated({"F1": _u("field_vole", -1, 0)})
	assert_ne(board["errors"], [])
	var source: Dictionary = _fixture({"F1": _u("field_vole", 1, 2)})
	var slots: Dictionary = source["slots"]
	slots["B4"] = null
	board = Boards.translate(source, _library)
	assert_ne(board["errors"], [])
	slots.erase("B4")
	board = Boards.translate(source, _library)
	assert_ne(board["errors"], [], "stat_total 0 does not describe a 1/2 body")


func test_missing_auxiliary_state_is_explicit_and_conkers_ammo_loads_when_stated() -> void:
	var late_birds: Dictionary = _find("Birds", 12, "high")
	assert_ne(late_birds["unrepresentable"], [])
	var fairy: Dictionary = _find("Fairies", 9, "average")
	assert_ne(fairy["unrepresentable"], [])
	var conkers: Dictionary = _find("Hedgerow folk", 9, "low")
	assert_eq(conkers["rules"]["ammo"], [1])


func test_clear_prose_loads_paint_and_larder_and_bare_rings_keep_presence() -> void:
	for round_number: int in [9, 12]:
		var board: Dictionary = _find("Fairies", round_number, "high")
		assert_eq(board["rules"]["bands"], [1, 1, 1, 1, 1, 1, 1])
		assert_ne(board["assumptions"], [], "paint inferred from Golden Chaser +14/+14")
	var hedgerow: Dictionary = _find("Hedgerow folk", 9, "average")
	assert_eq(hedgerow["rules"]["larder"], 4, "explicit in buffs prose")
	var fairy: Dictionary = _find("Fairies", 12, "high")
	var effects: Array = fairy["slot_effects"][4]
	assert_true(BoardUpkeep.has_ring(effects), "bare Rings preserves presence")
	assert_eq(BoardUpkeep.ring_stats(effects), Vector2i.ZERO, "unknown amount is not invented")


func test_known_paint_bonus_leaves_when_hasty_pudding_swallows_cluricaun() -> void:
	var fairy: Dictionary = _find("Fairies", 9, "high")
	var enemy: Dictionary = _translated({"B3": _u("hasty_pudding", 0, 100)})
	var combat: Combat = _combat_before_start(fairy, enemy)
	var chaser: CombatUnit = combat.unit_at(0, 0)
	var cluricaun: CombatUnit = combat.unit_at(0, 6)
	assert_eq([chaser.attack, chaser.health], [25, 28])
	combat._start_of_combat()
	assert_false(cluricaun.on_board)
	assert_eq(combat.unit_at(0, 6), null)
	assert_eq([chaser.attack, chaser.health], [24, 28], "painted-slot Attack is a live aura")


func test_known_larder_bonus_leaves_when_mag_pye_takes_treasurer_text() -> void:
	var hedgerow: Dictionary = _find("Hedgerow folk", 9, "average")
	var enemy: Dictionary = _translated({"F3": _u("mag_pye", 0, 100)})
	var combat: Combat = _combat_before_start(hedgerow, enemy)
	var treasurer: CombatUnit = combat.unit_at(0, 2)
	assert_eq([treasurer.attack, treasurer.health], [5, 7])
	combat._start_of_combat()
	assert_false(treasurer.has_mechanic("larder_stats"))
	assert_eq([treasurer.attack, treasurer.health], [4, 6], "four held gold gives a live +1/+1")


func test_schedule_has_180_unique_same_round_roll_cross_tribe_pairs() -> void:
	var boards: Array = _loaded["boards"]
	var pairs: Array[Dictionary] = Tournament.schedule(boards)
	assert_eq(pairs.size(), 180)
	var appearances: Dictionary = {}
	var seen: Dictionary = {}
	for pair: Dictionary in pairs:
		var a: int = pair["a"]
		var b: int = pair["b"]
		var left: Dictionary = boards[a]["source"]
		var right: Dictionary = boards[b]["source"]
		assert_lt(a, b)
		assert_ne(left["tribe"], right["tribe"])
		assert_eq(left["round"], right["round"])
		assert_eq(left["roll"], right["roll"])
		var key: String = "%d:%d" % [a, b]
		assert_false(seen.has(key))
		seen[key] = true
		appearances[a] = CoreUtil.to_int(appearances.get(a, 0)) + 1
		appearances[b] = CoreUtil.to_int(appearances.get(b, 0)) + 1
	assert_eq(appearances.size(), 72)
	for count: Variant in appearances.values():
		assert_eq(count, 5)


func test_orientation_results_and_draw_rates_use_each_boards_perspective() -> void:
	var record: Dictionary = Tournament.empty_record()
	Tournament.record_result(record, 0, 0, "board_empty")
	Tournament.record_result(record, 0, 1, "board_empty")
	Tournament.record_result(record, -1, 1, "no_attacks")
	var row: Dictionary = Tournament.rates(record)
	assert_eq([row["wins"], row["losses"], row["draws"], row["fights"]], [1, 1, 1, 3])
	assert_almost_eq(row["win_rate"], 1.0 / 3.0, 0.00001)
	assert_almost_eq(row["draw_rate"], 1.0 / 3.0, 0.00001)
	assert_eq(row["point_rate"], 0.5)


func test_measured_ranks_use_half_draws_and_keep_ties_and_guesses() -> void:
	var boards: Array = []
	var records: Array = []
	for rank: int in [3, 1, 2]:
		var board: Dictionary = _translated({"F1": _u("field_vole", 1, 2)})
		board["source"]["rank"] = rank
		boards.append(board)
		var record: Dictionary = Tournament.empty_record()
		Tournament.record_result(record, 0 if rank == 3 else -1, 0, "board_empty")
		records.append(record)
	var rows: Array[Dictionary] = Tournament.board_rows(boards, records)
	assert_eq(
		[rows[0]["measured_rank"], rows[1]["measured_rank"], rows[2]["measured_rank"]], [1, 2, 2]
	)
	assert_eq(rows[0]["guessed_rank"], 3)
	assert_eq(rows[0]["rank_change"], 2)
	var tribes: Array[Dictionary] = Tournament.tribe_rows(boards, records)
	assert_eq(tribes[0]["fights"], 3)
	assert_eq(tribes[0]["draws"], 2)


func test_real_combat_both_orientations_preserves_inputs_and_repeats_seed() -> void:
	var strong: Dictionary = _translated({"F1": _u("field_vole", 100, 100)})
	var weak: Dictionary = _translated({"F1": _u("field_vole", 1, 1)})
	var before: Dictionary = strong.duplicate(true)
	var config: GameConfig = GameConfig.full_game()
	var left: Dictionary = Tournament.fight(_library, config, strong, weak, 31)
	var right: Dictionary = Tournament.fight(_library, config, weak, strong, 31)
	assert_eq(left["winner"], 0)
	assert_eq(right["winner"], 1)
	assert_eq(strong, before)
	assert_eq(Tournament.fight(_library, config, strong, weak, 31), left)
