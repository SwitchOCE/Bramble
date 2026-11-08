extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/combat_kit.gd")
const FIRST_SEED: int = 171001
const SEEDS: int = 32


func _run(seed_now: int, logging: bool, line: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_now
	var combat := Combat.create(KIT.library, GameConfig.full_game(), rng)
	combat.log_events = logging
	# v05 Last Blow uses round base; R15 keeps the save/ghost comparison lethal.
	combat.round_number = 15
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
