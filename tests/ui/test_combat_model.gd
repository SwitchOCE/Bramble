extends GutTest
## The combat model replays SPEC section 5 events into slots, stats and statuses, and the log
## has a line for every event type.

const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")

const ALL_EVENTS: String = "res://tests/ui/data/combat_all_events.json"


func _replay(events: Array) -> CombatModel:
	var model: CombatModel = CombatModel.new()
	for entry: Variant in events:
		var event: Dictionary = entry
		model.apply(event)
	return model


func test_nightshade_fixture_ends_with_belladonna_alone() -> void:
	var events: Array = FixturePort.load_fixture("combat_nightshade")["events"]
	var model: CombatModel = _replay(events)
	assert_true(model.finished, "combat_end reached")
	assert_eq(model.winner, 0)
	assert_eq(model.damage, 10)
	assert_eq(model.damage_uncapped, 12)
	assert_eq(model.uid_at(0, 5), 2, "Belladonna Sprite still in B2")
	var health: int = model.unit(2)["health"]
	assert_eq(health, 3, "Belladonna took 2 from the Vole")
	for slot: int in CombatModel.SLOTS:
		assert_eq(model.uid_at(1, slot), -1, "side 1 slot %d empty" % slot)
	assert_eq(model.uid_at(0, 1), -1, "the Hoglet died in F2")


func test_nightshade_status_and_halving() -> void:
	var events: Array = FixturePort.load_fixture("combat_nightshade")["events"]
	var model: CombatModel = _replay(events.slice(0, 7))
	var stoat: Dictionary = model.unit(3)
	var stoat_health: int = stoat["health"]
	assert_eq(stoat_health, 3, "halved 5 -> 3 by Nightshade")
	var statuses: Array = stoat["statuses"]
	var first: Dictionary = statuses[0]
	var status_name: String = first["status"]
	assert_eq(status_name, "nightshade")


func test_summon_takes_the_dying_slot() -> void:
	var events: Array = FixturePort.load_fixture("combat_nightshade")["events"]
	var model: CombatModel = _replay(events.slice(0, 14))
	assert_eq(model.uid_at(0, 1), 5, "Hoglet summoned into F2")
	var alive: bool = model.unit(1)["alive"]
	assert_false(alive, "Hoglet Mother is dead")


func test_every_event_type_replays_and_logs() -> void:
	var data: Dictionary = FixturePort.load_json(ALL_EVENTS)
	var events: Array = data["events"]
	var model: CombatModel = CombatModel.new()
	var log_text: CombatLog = CombatLog.new()
	log_text.side_names = PackedStringArray(["You", "Bot 2"])
	for entry: Variant in events:
		var event: Dictionary = entry
		var line: String = log_text.describe(event, model)
		assert_false(line.begins_with("("), "event %s has a log line" % event["type"])
		model.apply(event)
	assert_eq(model.slot_marks.size(), 1, "slot mark recorded")
	var attack: int = model.unit(2)["attack"]
	assert_eq(attack, 2, "stats event applied")
	var warned: Array = model.unit(1)["statuses"]
	var names: PackedStringArray = []
	for status: Variant in warned:
		var entry: Dictionary = status
		var key: String = entry["status"]
		names.append(key)
	assert_false("warned" in names, "status off removed Warned")
	assert_true("mired" in names, "Mired applied")
	assert_eq(model.winner, 1)
