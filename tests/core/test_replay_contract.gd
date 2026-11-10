extends GutTest
## The replay projection must never erase a gameplay difference or unrelated snapshot text.

const Contract := preload("res://tests/core/replay_contract.gd")


func test_ring_projection_keeps_gameplay_values_order_and_future_fields() -> void:
	var event: Dictionary = {
		"type": "ring_dance",
		"from": 1,
		"to": 4,
		"moved_count": 2,
		"from_ring": {"count": 0},
		"to_ring": {"count": 2},
		"future_gameplay_field": 7,
	}
	var result: Dictionary = {"events": [event, {"type": "hit", "damage": 3}], "carry": [4]}
	var projected: Dictionary = Contract.gameplay(result)
	var events: Array = projected["events"]
	var first: Dictionary = events[0]
	assert_false(first.has("moved_count"))
	assert_false(first.has("from_ring"))
	assert_false(first.has("to_ring"))
	assert_eq(CoreUtil.to_int(first["future_gameplay_field"]), 7)
	assert_eq(CoreUtil.to_int(first["from"]), 1)
	assert_eq(CoreUtil.to_int(first["to"]), 4)
	var changed: Dictionary = result.duplicate(true)
	changed["events"][1]["damage"] = 4
	assert_ne(_project(changed), projected, "damage changes remain detectable")
	changed = result.duplicate(true)
	changed["carry"] = [5]
	assert_ne(_project(changed), projected, "carry changes remain detectable")
	changed = result.duplicate(true)
	var reordered: Array = changed["events"]
	reordered.reverse()
	assert_ne(_project(changed), projected, "event order remains detectable")


func test_same_named_fields_on_other_events_are_not_projected_out() -> void:
	var event: Dictionary = {
		"type": "hit",
		"damage": 3,
		"moved_count": 2,
		"from_ring": {"health": 4},
		"to_ring": {"health": 5},
	}
	assert_eq(_project(event), event)


func test_only_the_exact_mandated_pass_reminder_in_a_unit_snapshot_is_aliased() -> void:
	var snapshot: Dictionary = {
		"uid": 1,
		"def_id": "mr_crumb",
		"keyword_text": [{"keyword": "Pass", "text": Contract.CURRENT_PASS}],
	}
	var projected: Dictionary = Contract.gameplay(snapshot)
	var reminders: Array = projected["keyword_text"]
	var reminder: Dictionary = reminders[0]
	var wording: String = reminder["text"]
	assert_eq(wording, Contract.FROZEN_PASS)
	var unrelated: Dictionary = snapshot.duplicate(true)
	unrelated.erase("uid")
	assert_eq(_project(unrelated), unrelated, "non-unit text is unchanged")
	unrelated = snapshot.duplicate(true)
	unrelated["keyword_text"][0]["text"] = "Pass X: changes the actual rule."
	assert_eq(_project(unrelated), unrelated, "any other reminder change stays visible")
	unrelated = snapshot.duplicate(true)
	unrelated["keyword_text"][0]["keyword"] = "Other"
	assert_eq(_project(unrelated), unrelated, "unrelated keywords stay compared")


func _project(value: Dictionary) -> Dictionary:
	var result: Dictionary = Contract.gameplay(value)
	return result
