extends GutTest
## The combat model replays SPEC section 5 events into slots, stats and statuses, and the log
## has a line for every event type.

const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")

const CombatKit := preload("res://tests/core/combat_kit.gd")

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


func test_the_log_speaks_of_you_properly() -> void:
	var log_text: CombatLog = CombatLog.new()
	log_text.side_names = PackedStringArray(["You", "Bot 2"])
	var model: CombatModel = CombatModel.new()
	var yours: String = log_text.describe({"type": "side_trigger", "side": 0}, model, false)
	var theirs: String = log_text.describe({"type": "side_trigger", "side": 1}, model, false)
	assert_string_contains(yours, "Your hero power")
	assert_string_contains(theirs, "Bot 2's hero power")


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
	assert_true("stalled" in names, "Stalled applied")
	assert_eq(model.winner, 1)


func test_bog_events_have_readable_lines_and_transform_the_replayed_frog() -> void:
	var highness: Dictionary = CombatKit.u("his_highness")
	highness["kisses"] = 2
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var combat := Combat.create(LegacyBog.library(), GameConfig.defaults(), rng)
	var result: Dictionary = combat.run(
		[
			CombatKit.board({0: CombatKit.u("bridge_toad"), 4: highness}),
			CombatKit.board({0: CombatKit.plain(0, 1)})
		],
		[1, 1],
		[0, 1],
		0
	)
	var model: CombatModel = CombatModel.new()
	var log_text: CombatLog = CombatLog.new()
	for value: Variant in result["events"]:
		var event: Dictionary = value
		var line: String = log_text.describe(event, model)
		# The bell and Start of Combat are one phase to the player: the second header is dropped.
		if str(event["type"]) != "phase":
			assert_false(line.is_empty(), str(event["type"]))
		model.apply(event)
	assert_eq(str(model.unit(2)["def_id"]), "prince_restored")
	assert_eq(str(model.unit(2)["name"]), "The Prince Restored")
	assert_eq(CoreUtil.to_int(model.unit(2)["kisses"]), 3)
	assert_eq(model.bog_patches.size(), 1)


func test_quarry_mark_and_loss_replay_on_the_hunter_identity() -> void:
	var data: Dictionary = FixturePort.load_json(ALL_EVENTS)
	var model: CombatModel = CombatModel.new()
	var events: Array = data["events"]
	var first: Dictionary = events[0]
	model.apply(first)
	var mark: Dictionary = {"type": "quarry_marked", "hunter": 1, "quarry": 4, "source": 1}
	var log_text: CombatLog = CombatLog.new()
	assert_string_contains(log_text.describe(mark, model), "as quarry")
	model.apply(mark)
	assert_eq(CoreUtil.to_int(model.unit(1)["quarry"]), 4)
	model.apply({"type": "quarry_lost", "hunter": 1, "quarry": 4})
	assert_eq(CoreUtil.to_int(model.unit(1)["quarry"]), 0)
