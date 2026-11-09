extends GutTest
## A recorded field fight must show its real Health, and its complete result.

const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")


func test_rival_plaque_health_is_recovered_from_recorded_round_history() -> void:
	var source: Dictionary = FixturePort.load_json(
		"res://docs/ideation/evidence/strong-field/ui-1688x780.json"
	)
	for size: String in ["1688x780", "1920x1080"]:
		var fixture: Dictionary = FixturePort.load_json(
			"res://docs/ideation/evidence/declutter/batch1/before/rival-fight_" + size + ".json"
		)
		var input: Dictionary = fixture["fight_input"]
		var fight: Dictionary = fixture["combat"]
		var health: Dictionary = Capture.recorded_hero_health(source, input, fight)
		var before: Array = health["before"]
		var after: Array = health["after"]
		assert_eq(CoreUtil.to_int(before[0]), 30, "human starts round 8 on recorded 30 Health")
		assert_eq(CoreUtil.to_int(after[0]), 23, "the recorded 7 damage visibly lands")
		assert_eq(CoreUtil.to_int(before[1]), 40)
		assert_eq(CoreUtil.to_int(after[1]), 40)
		var captured_before: Array = fight["hero_health_before"]
		var captured_after: Array = fight["hero_health_after"]
		assert_eq(captured_before, before, "capture no longer hides unknown Health")
		assert_eq(captured_after, after)
