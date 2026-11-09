extends GutTest
@warning_ignore_start("unsafe_call_argument")

const FIGHT := preload("res://tests/core/combat_kit.gd")


func _combat() -> Combat:
	var config := GameConfig.full_game()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var combat := Combat.create(
		ScaleOverlay.library_for(UnitLibrary.load_dir(), config), config, rng
	)
	combat.slot_effects = [[[], [], [], [], [], [], []], [[], [], [], [], [], [], []]]
	combat.slot_effects[1][4] = [{"name": "Ring", "attack": 40, "health": 40}]
	combat._slots_active = true
	combat._setup(
		[
			FIGHT.board({0: FIGHT.u("whirligig_beetle")}),
			FIGHT.board({0: FIGHT.plain(90, 100), 4: FIGHT.plain(2, 3)})
		]
	)
	combat._recalc_auras(false)
	return combat


func test_ring_guard_counterexample_prevents_moving_the_carry_to_the_bigger_ring() -> void:
	var guarded: Combat = _combat()
	var carry: CombatUnit = guarded.unit_at(1, 0)
	assert_eq(CombatMoves.swap_rows(guarded, 1, true).size(), 0)
	assert_eq(carry.slot, 0)
	assert_eq(carry.attack, 90)
	var unguarded: Combat = _combat()
	var other: CombatUnit = unguarded.unit_at(1, 0)
	assert_eq(CombatMoves.swap_rows(unguarded, 1, false).size(), 2)
	assert_eq(other.slot, 4)
	assert_eq(other.attack, 130, "without the guard the hostile swap improves the carry")


func test_real_beetle_skips_damage_for_the_blocked_pair_and_explains_it() -> void:
	var combat: Combat = _combat()
	var carry: CombatUnit = combat.unit_at(1, 0)
	var source: CombatUnit = combat.unit_at(0, 0)
	MechanicRegistry.get_mechanic("row_swap").on_start_of_combat(combat, source, {"damage": 2})
	assert_eq(carry.slot, 0)
	assert_eq(carry.health, 100)
	assert_string_contains(str(source.def["text"]), "without improving Rings")


func test_equal_ring_pairs_still_swap_and_legacy_face_is_unchanged() -> void:
	var combat: Combat = _combat()
	combat.slot_effects[1][0] = [{"name": "Ring", "attack": 40, "health": 40}]
	combat._recalc_auras(false)
	assert_eq(CombatMoves.swap_rows(combat, 1, true).size(), 2)
	var old: Dictionary = UnitLibrary.load_dir().get_unit("whirligig_beetle")
	assert_eq(
		old["text"], "Start of Combat: swap the enemy's rows. Each enemy moved takes 2 damage."
	)
