extends RefCounted
## Small, deterministic board states for lane layout checks and screenshots, using real cards.

const UnitViews := preload("res://src/ui/unit_views.gd")


static func unit(id: String, uid: int) -> Dictionary:
	return UnitViews.from_def(TestLibraries.current().get_unit(id), false, uid)


static func boards() -> Array:
	return [
		[
			unit("prima_donna", 1),
			unit("little_nip", 2),
			unit("wick", 3),
			null,
			null,
			unit("old_brock", 4),
			null
		],
		[
			unit("field_vole", 101),
			unit("mrs_sorrel", 102),
			unit("sleeping_partner", 103),
			null,
			null,
			unit("mother_goose", 104),
			null
		]
	]


static func recruit(state: Dictionary) -> void:
	var shown: Array = boards()
	state["board"] = shown[0]
	state["next_opponent_last_board"] = shown[1]
	state["next_opponent_last_slot_effects"] = [[], [], [], [], [], [], []]
	state["next_opponent_last_nests"] = []
	state["hand"] = []
	var poached: Dictionary = unit("mrs_sorrel", 201)
	poached["poached"] = true
	poached["cost"] = 2
	state["shop"] = [poached, unit("young_brock", 202), unit("bridge_toad", 203)]
	state["shop"][1]["cost"] = 3
	state["shop"][2]["cost"] = 3


static func fight(after_death: bool = false) -> Dictionary:
	var events: Array = [
		{"type": "combat_start", "boards": boards(), "player_ids": [0, 1], "first_side": 0},
		{"type": "phase", "name": "bell"},
		{"type": "bog_patch", "side": 1, "slot": 0, "maker": 1},
		{"type": "bog_patch", "side": 1, "slot": 1, "maker": 1},
		{"type": "quarry_marked", "hunter": 2, "quarry": 102, "source": 2},
		{"type": "quarry_marked", "hunter": 3, "quarry": 104, "source": 4},
		{"type": "relocate", "uid": 102, "side": 1, "slot": 3},
		{"type": "attack", "attacker": 2, "defender": 102, "pack": true, "joiners": [3]},
	]
	if after_death:
		events.append({"type": "death", "uid": 1})
	return {"events": events}
