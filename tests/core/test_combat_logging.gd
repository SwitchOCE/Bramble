extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/combat_kit.gd")
const LEGACY := preload("res://tests/core/legacy_wave1.gd")
const FIRST_SEED: int = 171001
const SEEDS: int = 32


func _run(seed_now: int, logging: bool, line: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_now
	var library: UnitLibrary = LEGACY.with_oozes(KIT.library) if line == "posset" else KIT.library
	var combat := Combat.create(library, GameConfig.full_game(), rng)
	combat.log_events = logging
	combat.round_number = 11  # Arm B base 7 makes the Last Stand/ghost checks lethal.
	var boards: Array = [KIT.board({0: KIT.plain(3, 3)}), KIT.board({0: KIT.plain(3, 3)})]
	if line == "posset":
		boards[1] = KIT.board({0: KIT.u("mrs_posset", 0, 1)})
	elif line == "parasite":
		boards = [KIT.board({0: KIT.plain(3, 10)}), KIT.board({0: KIT.u("ichneumon_wasp", 2, 1)})]
	var result: Dictionary
	if line == "exchange":
		result = combat.run(boards, [6, 5], [0, 1], 0)
	else:
		# Fix the declared attacker so these paths necessarily execute, for every seed.
		combat._setup(boards)
		combat._attacks_started = true
		combat._perform_attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
		result = combat._finish(Combat.REASON_BOARD_EMPTY, [6, 5], 0)
	var events: Array = result["events"]
	assert_eq(not events.is_empty(), logging)
	if line == "parasite" and logging:
		assert_eq(KIT.of_type(result, "health_loss")[0]["cause"], "parasite")
	result.erase("events")
	var boards_after: Array = []
	for side: int in 2:
		var row: Array = []
		for unit: CombatUnit in combat.sides[side]:
			if unit == null:
				row.append(null)
			else:
				row.append(
					{
						"view": unit.view(),
						"counters": unit.counters,
						"limits": unit.limits,
						"statuses": unit.statuses
					}
				)
		boards_after.append(row)
	return {
		"result": result,
		"boards": boards_after,
		"rng": rng.state,
		"effect_rng": combat.effect_rng.state,
		"pointers": combat.pointers,
		"attacks": combat.attacks_made,
		"triggers": combat._triggers,
		"halted": combat._halted,
		"slots": combat.slot_effects,
		"last_blow_side": combat._last_blow_side,
		"last_blow_source": combat._last_blow_source,
		"last_blow_kind": combat._last_blow_kind,
	}


func test_last_blow_credit_and_results_are_identical_without_event_logging() -> void:
	for line: String in ["exchange", "posset", "parasite"]:
		for seed_now: int in range(FIRST_SEED, FIRST_SEED + SEEDS):
			var logged: Dictionary = _run(seed_now, true, line)
			var quiet: Dictionary = _run(seed_now, false, line)
			assert_eq_deep(quiet, logged)
			var result: Dictionary = quiet["result"]
			assert_true(result["last_blow"])
			if line != "exchange":
				assert_eq(result["winner"], 1)
				assert_eq(quiet["last_blow_source"], 2)
				assert_eq(quiet["last_blow_kind"], Hit.EFFECT)


func _native_posset(
	seed_now: int, logging: bool, effect_kill: bool, swapped: bool, golden: bool
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_now
	var combat := Combat.create(KIT.library, GameConfig.full_game(), rng)
	combat.log_events = logging
	combat._setup(
		[KIT.board({6: KIT.plain(11, 9)}), KIT.board({0: KIT.u("mrs_posset", 0, 1, golden)})]
	)
	var killer: CombatUnit = combat.unit_at(0, 6)
	var posset: CombatUnit = combat.unit_at(1, 0)
	assert_true(Pass3OozeCombat.has(posset, "mrs_posset"), "this exercises current native text")
	if swapped:
		CombatMoves.trade_sides(combat, killer, posset)
	combat._attacks_started = true
	if effect_kill:
		combat.deal_effect_damage(killer, posset, 1)
		combat._resolve_deaths(killer.side)
	else:
		combat._perform_attack(killer, posset)
	var result: Dictionary = combat._finish(Combat.REASON_BOARD_EMPTY, [6, 5], 0)
	var events: Array = result["events"]
	assert_eq(not events.is_empty(), logging)
	if logging:
		var deaths: Array[Dictionary] = KIT.of_type(result, "death")
		assert_eq(deaths[0]["killer"], killer.uid)
	result.erase("events")
	return {
		"result": result,
		"killer_stats": [killer.attack, killer.health],
		"killed_by": posset.killed_by,
		"credit": [combat._last_blow_side, combat._last_blow_source, combat._last_blow_kind],
		"rng": rng.state,
		"effect_rng": combat.effect_rng.state,
		"carry": combat.carry,
		"triggers": combat._triggers,
	}


func test_native_posset_halving_preserves_actual_damage_credit_with_or_without_logging() -> void:
	for seed_now: int in [FIRST_SEED, FIRST_SEED + 1, FIRST_SEED + 7]:
		for effect_kill: bool in [false, true]:
			for swapped: bool in [false, true]:
				for golden: bool in [false, true]:
					var logged: Dictionary = _native_posset(
						seed_now, true, effect_kill, swapped, golden
					)
					var quiet: Dictionary = _native_posset(
						seed_now, false, effect_kill, swapped, golden
					)
					assert_eq_deep(quiet, logged)
					assert_eq(
						quiet["killer_stats"], [6, 5], "native halving is nonlethal stat loss"
					)
					assert_eq(quiet["killed_by"], 1, "the actual killer was not across Posset")
					assert_eq(
						quiet["credit"],
						[1 if swapped else 0, 1, Hit.EFFECT if effect_kill else Hit.ATTACK]
					)
					var result: Dictionary = quiet["result"]
					assert_eq(result["winner"], 1 if swapped else 0)
					assert_false(
						result["last_blow"], "the killer survives; Posset cannot claim a wipe"
					)


func test_last_stand_and_ghost_damage_use_identical_quiet_results() -> void:
	for seed_now: int in range(FIRST_SEED, FIRST_SEED + SEEDS):
		for real_opponent: bool in [true, false]:
			var states: Array = []
			for logging: bool in [true, false]:
				var fight: Dictionary = _run(seed_now, logging, "exchange")
				var result: Dictionary = fight["result"]
				var loser := PlayerState.new()
				loser.health = 2
				var saved: bool = HeroRules.take_combat_loss(
					loser, result["damage"], real_opponent, true
				)
				assert_eq(saved, real_opponent)
				states.append([loser.health, loser.armor, loser.last_stand_used, saved])
				if real_opponent:
					assert_eq(loser.health, 1)
					assert_false(HeroRules.take_combat_loss(loser, 99, true, true))
					assert_lt(loser.health, 1)
			assert_eq_deep(states[0], states[1])


func test_initial_spider_aura_is_in_start_snapshot_without_pre_start_status_events() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var combat := Combat.create(KIT.library, GameConfig.full_game(), rng)
	var result: Dictionary = combat.run(
		[
			KIT.board({1: KIT.u("ballooning_spider"), 4: KIT.plain(30, 30)}),
			KIT.board({0: KIT.plain(1, 1)})
		],
		[3, 1],
		[7, 0],
		0
	)
	var events: Array = result["events"]
	var start: Dictionary = events[0]
	assert_eq(start["type"], "combat_start")
	assert_eq(start["seq"], 0)
	assert_eq(start["player_ids"], [7, 0])
	var boards: Array = start["boards"]
	var recipient: Dictionary = boards[0][4]
	var statuses: Array = recipient["statuses"]
	assert_true(
		statuses.any(func(status: Dictionary) -> bool: return status["status"] == "lent_swoop")
	)
