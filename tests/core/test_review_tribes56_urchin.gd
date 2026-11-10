extends GutTest
@warning_ignore_start("unsafe_call_argument")

const FIGHT := preload("res://tests/core/combat_kit.gd")


func test_slice_urchin_redirects_each_pack_prick_and_still_passes_right() -> void:
	for golden: bool in [false, true]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 53
		var combat := Combat.create(
			LegacyWave1.with_hedgerow(FIGHT.library), GameConfig.full_game(), rng
		)
		combat._setup(
			[
				FIGHT.board({0: FIGHT.u("little_nip", 2, 20), 1: FIGHT.u("wick", 2, 20)}),
				FIGHT.board(
					{0: FIGHT.u("dr_urchin", 1, 30, golden), 4: FIGHT.u("little_nip", 2, 20)}
				)
			]
		)
		var leader: CombatUnit = combat.unit_at(0, 0)
		var joiner: CombatUnit = combat.unit_at(0, 1)
		var doctor: CombatUnit = combat.unit_at(1, 0)
		var neighbour: CombatUnit = combat.unit_at(1, 4)
		assert_eq(str(doctor.def["set"]), "slice")
		combat._attack(leader, doctor)
		assert_eq(leader.health, 11 if golden else 15, "counter plus both redirected pricks")
		assert_eq(joiner.health, 20, "Pack joiner takes neither counter nor Bristle")
		assert_eq(neighbour.attack, 6 if golden else 4, "each prick still passes right")
		assert_eq(doctor.health, 26, "both Pack members damaged the Doctor")


func test_slice_urchin_still_pricks_a_lone_attacker() -> void:
	var rng := RandomNumberGenerator.new()
	var combat := Combat.create(
		LegacyWave1.with_hedgerow(FIGHT.library), GameConfig.full_game(), rng
	)
	combat._setup(
		[
			FIGHT.board({0: FIGHT.u("little_nip", 2, 20)}),
			FIGHT.board({0: FIGHT.u("dr_urchin", 1, 30)})
		]
	)
	var leader: CombatUnit = combat.unit_at(0, 0)
	combat._attack(leader, combat.unit_at(1, 0))
	assert_eq(leader.health, 17, "one counter and one prick without Pack")
