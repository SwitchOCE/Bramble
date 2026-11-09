extends SceneTree
## One designed native Bog fight. Generate once; every before/after replays its full event log.
const CK := preload("res://tests/core/combat_kit.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() == 1, "usage: -- <fixture directory>")
	var library: UnitLibrary = UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	config.set_value("pass3_content", true)
	config.set_value("pass3_preset", "B")
	config.set_value("pass3_loop_guards", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var combat := Combat.create(library, config, rng)
	var mine: Array = CK.board(
		{0: _owned("bridge_toad", 8, 24, 41), 1: _owned("prince_restored", 3, 20, 42)}
	)
	var theirs: Array = CK.board({0: CK.plain(8, 10), 1: CK.plain(2, 3), 2: CK.plain(1, 3)})
	var result: Dictionary = combat.run([mine, theirs], [3, 3], [0, 1], 0)
	var moments: Dictionary = {}
	var latest_attack: int = -1
	var chosen: Array[int] = []
	for index: int in combat.events.size():
		var event: Dictionary = combat.events[index]
		if str(event["type"]) == "attack":
			latest_attack = index
		if (
			str(event["type"]) in ["gain_pending", "kiss", "bog_toll"]
			and not moments.has(str(event["type"]))
		):
			if latest_attack < 0:
				print("opening Bog event ", index, " ", event)
				continue
			moments[str(event["type"])] = {
				"event_index": index, "attack_event_index": latest_attack, "event": event
			}
			if not chosen.has(latest_attack):
				chosen.append(latest_attack)
	for kind: String in ["gain_pending", "kiss", "bog_toll"]:
		assert(moments.has(kind), "designed fight includes " + kind)
	var heroes: Array[Dictionary] = library.all_heroes()
	var fixture: Dictionary = {
		"source_revision": "d400831e",
		"seed": 23,
		"combat": result,
		"names": ["Bog band", "Voles"],
		"bottom_side": 0,
		"opponent_health": 30,
		"hero_views": [heroes[0], heroes[1]],
		"hero_health": [30, 30],
		"state": {},
		"moments": moments,
		"selected_attack_event_indices": chosen,
		"fight_input":
		{
			"boards": [mine, theirs],
			"tiers": [3, 3],
			"player_ids": [0, 1],
			"damage_cap": 0,
			"seed": 23
		},
		"provenance":
		(
			"Designed native-card fight, real Combat.run with seed23, Pass3 B and loop guards. "
			+ "Bridge Toad 8/24 and Prince Restored 3/20 against Field Voles 8/10, 2/3, 1/3. "
			+ "Recruit iids41/42 ensure real queued gains. Full event stream generated once on "
			+ "d400831e and replayed unchanged before/after."
		)
	}
	DirAccess.make_dir_recursive_absolute(args[0])
	var file := FileAccess.open(args[0].path_join("bog_1688x780.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture, "\t", true, true) + "\n")
	print(
		"Bog fixture events=",
		combat.events.size(),
		" selected_attacks=",
		chosen,
		" moments=",
		moments
	)
	quit()


func _owned(id: String, attack: int, health: int, iid: int) -> Dictionary:
	var spec: Dictionary = CK.u(id, attack, health)
	spec["iid"] = iid
	return spec
