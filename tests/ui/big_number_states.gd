extends RefCounted
## Full 4-3 boards for reproducible stat-format tests and phone screenshots.

const LaneStates := preload("res://tests/ui/lane_states.gd")
const VALUES: Dictionary = {
	4: [1234, 2345, 5678, 8888, 9001, 9998, 9999],
	5: [10000, 12345, 23456, 56789, 88888, 99998, 99999],
	7: [1000000, 1234567, 2345678, 5678901, 8888888, 9999998, 9999999],
}


static func boards(digits: int) -> Array:
	var out: Array = [[], []]
	var values: Array = VALUES[digits]
	for side: int in 2:
		var row: Array = out[side]
		for slot: int in 7:
			var view: Dictionary = LaneStates.unit("field_vole", side * 100 + slot + 1)
			view["attack"] = values[slot]
			view["health"] = values[6 - slot]
			view["max_health"] = view["health"]
			row.append(view)
	return out


static func recruit(state: Dictionary, digits: int) -> void:
	state["board"] = boards(digits)[0]
	state["hand"] = []
	state["hand_items"] = []
	state["slot_effects"] = [[], [], [], [], [], [], []]
	state["pending_passes"] = []


static func fight(digits: int) -> Dictionary:
	return {
		"events":
		[{"type": "combat_start", "boards": boards(digits), "player_ids": [0, 1], "first_side": 0}]
	}
