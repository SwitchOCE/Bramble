extends GutTest
@warning_ignore_start("unsafe_call_argument")

const FIGHT := preload("res://tests/core/combat_kit.gd")


func test_a_real_slice_take_counts_as_on_take_coverage() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(LegacyWave1.current_with_hunters(), GameConfig.defaults(), rng)
	var tiers: Array[int] = [1, 1]
	var ids: Array[int] = [0, 1]
	var result: Dictionary = combat.run(
		[FIGHT.board({0: FIGHT.u("little_nip")}), FIGHT.board({0: FIGHT.plain(1, 2)})],
		tiers,
		ids,
		0
	)
	var types: Dictionary = {}
	for event: Dictionary in FIGHT.events(result):
		var type: String = str(event["type"])
		types[type] = CoreUtil.to_int(types.get(type, 0)) + 1
	assert_eq(types.get("take", 0), 1, "Nip's simultaneous trade really made a Take")
	assert_false(SoakCoverage.gaps({}, {}, types).has("trigger:on_take"))
	assert_true(SoakCoverage.gaps({}, {}, types).has("effect:gold"), "no unrelated alias")


func test_no_take_still_reports_the_gap() -> void:
	assert_true(SoakCoverage.gaps({}, {}, {}).has("trigger:on_take"))
	assert_true(SoakCoverage.gaps({}, {}, {"take": 0}).has("trigger:on_take"))


func test_named_synthetic_on_take_effect_still_counts() -> void:
	assert_false(SoakCoverage.gaps({}, {"trigger:on_take": 1}, {}).has("trigger:on_take"))
