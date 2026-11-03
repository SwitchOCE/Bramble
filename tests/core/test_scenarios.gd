extends GutTest
## Sandbox scenarios from the mechanics library's scenes (content/scenarios): every file loads,
## fights to a valid end, and shows what its "expect" list says at its seed.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const REASONS: Array = ["board_empty", "no_attacks", "attack_limit", "trigger_limit"]

var _units: UnitLibrary = UnitLibrary.load_dir()
var _scenarios: ScenarioLibrary = ScenarioLibrary.load_dir(_units)


func _fight(scenario: Dictionary, fight_seed: int) -> Dictionary:
	var sandbox := CombatSandbox.create(_units)
	assert_eq(sandbox.load_scenario(scenario), "", "%s loads" % scenario["id"])
	return sandbox.fight(fight_seed)


## The first `expect` entry no event matches, or {} when all are found.
static func _missing(result: Dictionary, expect: Array) -> Dictionary:
	var events: Array = result["events"]
	for wanted: Variant in expect:
		var fields: Dictionary = wanted
		var found: bool = false
		for event: Variant in events:
			var entry: Dictionary = event
			var all_match: bool = true
			for key: Variant in fields:
				if not entry.has(key) or entry[key] != fields[key]:
					all_match = false
					break
			if all_match:
				found = true
				break
		if not found:
			return fields
	return {}


func test_every_scenario_loads() -> void:
	assert_eq(_scenarios.load_errors(), PackedStringArray(), "no load errors")
	assert_gt(_scenarios.all_scenarios().size(), 14, "one per built mechanic, Fast aside")
	var built: Array = []
	for summary: Dictionary in _scenarios.all_scenarios():
		for unit_id: Variant in summary["units"]:
			built.append(unit_id)
	for unit_id: String in [
		"belladonna_sprite",
		"bitter_toad",
		"hoglet_mother",
		"sett_warden",
		"garden_snail",
		"mudwallow_toad",
		"fox_notary",
		"weasel_second",
		"ermine_duellist",
		"drumming_woodpecker",
		"worker_bee",
		"hedgehog_twin",
		"hazel_dormouse",
		"marmot_lookout",
		"fox_cub",
	]:
		assert_true(built.has(unit_id), "a scenario shows %s" % unit_id)


func test_every_scenario_fights_to_a_valid_end_and_shows_its_mechanic() -> void:
	for summary: Dictionary in _scenarios.all_scenarios():
		var scenario: Dictionary = _scenarios.get_scenario(summary["id"])
		var result: Dictionary = _fight(scenario, scenario["seed"])
		var events: Array = result["events"]
		var last: Dictionary = events[-1]
		assert_true(REASONS.has(last["reason"]), "%s ends validly" % scenario["id"])
		var expect: Array = scenario.get("expect", [])
		var missing: Dictionary = _missing(result, expect)
		if missing.is_empty():
			continue
		var good: Array = []
		for fight_seed: int in range(1, 60):
			if _missing(_fight(scenario, fight_seed), expect).is_empty():
				good.append(fight_seed)
		fail_test(
			(
				"%s at seed %d lacks %s; seeds that work: %s"
				% [scenario["id"], scenario["seed"], missing, good]
			)
		)


func test_nightshade_boar_loses_half_its_health_each_time() -> void:
	var scenario: Dictionary = _scenarios.get_scenario("nightshade")
	var result: Dictionary = _fight(scenario, scenario["seed"])
	var boar: int = -1
	for view: Variant in result["events"][0]["boards"][1]:
		if view != null and view["name"] == "Boar":
			boar = view["uid"]
	assert_ne(boar, -1, "the boar is named by its display_name")
	var health: int = 70
	var halvings: int = 0
	for event: Dictionary in result["events"]:
		if event.get("target", -1) != boar:
			continue
		if event["type"] == "health_loss":
			@warning_ignore("integer_division")
			var half: int = health / 2
			assert_eq(event["amount"], half, "half of %d, rounded down" % health)
			halvings += 1
		if event.has("health_after"):
			health = event["health_after"]
	assert_gt(halvings, 2, "halved on several attacks")
	assert_true(health <= 0, "and the boar falls")


func test_sandbox_rejects_an_unknown_scenario() -> void:
	var sandbox := CombatSandbox.create(_units)
	assert_eq(sandbox.load_scenario(_scenarios.get_scenario("nope")), "No such scenario", "{}")


func test_bad_scenario_files_are_reported() -> void:
	var library := ScenarioLibrary.load_dir(_units, "res://tests/core/no_such_dir")
	assert_eq(library.load_errors().size(), 1, "missing directory")
