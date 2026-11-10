extends GutTest
## A recorded field fight must show its real Health, and its complete result.

const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")


class OldCard:
	extends Control
	var _attack_label: Label
	var _health_label: Label


class OldCombat:
	extends Control
	var _cards: Dictionary = {}
	var _fight_health: Label


func test_baseline_budget_excludes_only_explicitly_owned_primary_stat_labels() -> void:
	var screen := OldCombat.new()
	add_child_autofree(screen)
	var card := OldCard.new()
	screen.add_child(card)
	screen._cards[1] = card
	card._attack_label = Label.new()
	card._attack_label.text = "12"
	card.add_child(card._attack_label)
	card._health_label = Label.new()
	card._health_label.text = "7"
	card.add_child(card._health_label)
	screen._fight_health = Label.new()
	screen._fight_health.text = "30"
	screen.add_child(screen._fight_health)
	var speed := Label.new()
	speed.text = "1×"
	screen.add_child(speed)
	Capture.tag_baseline_primary_stats(screen)
	var raw: Array[Dictionary] = Capture.text_nodes(screen)
	var ancillary: Array[Dictionary] = Capture.budget_nodes(screen)
	assert_eq(raw.size(), 4, "raw count retains every visible label")
	assert_eq(ancillary.size(), 1, "only unit stats and hero Health are excluded")
	assert_eq(str(ancillary[0]["text"]), "1×", "a numeric control still spends the budget")
	assert_true(CoreUtil.to_bool(card._attack_label.get_meta("combat_primary_stat", false)))
	assert_true(CoreUtil.to_bool(card._health_label.get_meta("combat_primary_stat", false)))
	assert_true(CoreUtil.to_bool(screen._fight_health.get_meta("combat_primary_stat", false)))


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
