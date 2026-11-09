extends RefCounted
## Test-only synthetic trajectories rebuilt from current gameplay data once per process.
## No shipped field library or frozen card/hero IDs are needed by integration/UI-choice tests.
## Exact historical combat replay is a separate frozen-fixture regression.

const OUTPUT: String = "res://build/field-test-library.json"
const ROUNDS: int = 24
const SEATS_PER_ROTATION: int = 12

static var _path: String = ""


static func path() -> String:
	if not _path.is_empty():
		return _path
	var library := UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	var current := FieldLibrary.new()
	var hashes: Dictionary = current._content_manifest()
	assert(current.error.is_empty(), current.error)
	var lines: Dictionary = {}
	var pool: Array[Dictionary] = library.pool_units(config.card_set())
	var heroes: Array[Dictionary] = library.heroes_of(config.card_set())
	assert(not pool.is_empty() and not heroes.is_empty(), "Field tests need current game content")
	var rotation: PackedStringArray = library.tribes_in_rotation(
		config.get_int("lobby_tribe_min_units"), config.card_set()
	)
	var wanted: int = config.get_int("tribes_per_lobby")
	var rotations: Array = []
	if wanted <= 0:
		rotations.append(PackedStringArray())
	else:
		_combinations(rotation, mini(wanted, rotation.size()), 0, PackedStringArray(), rotations)
	for index: int in rotations.size():
		var tribes: PackedStringArray = rotations[index]
		_add_rotation(lines, library, config, pool, heroes, tribes, index)
	var data: Dictionary = {
		"version": FieldLibrary.VERSION,
		"config_version": FieldLibrary.CONFIG_VERSION,
		"manifest": "gameplay-v1",
		"content_hashes": hashes,
		"config": config._values.duplicate(true),
		"source":
		{
			"kind": "synthetic_current_content_test_fixture",
			"commit": "test-setup",
			"method": "12 unique seats per current lobby rotation, 8 top4 and 4 lower finishers"
		},
		"lines": lines
	}
	var directory: String = ProjectSettings.globalize_path(OUTPUT.get_base_dir())
	assert(DirAccess.make_dir_recursive_absolute(directory) == OK)
	var ignore := FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	assert(ignore != null)
	ignore.close()
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(data, "", true, true))
	file.close()
	_path = OUTPUT
	return _path


static func _combinations(
	tribes: PackedStringArray, count: int, at: int, chosen: PackedStringArray, out: Array
) -> void:
	if chosen.size() == count:
		out.append(chosen.duplicate())
		return
	for index: int in range(at, tribes.size()):
		var next: PackedStringArray = chosen.duplicate()
		next.append(tribes[index])
		_combinations(tribes, count, index + 1, next, out)


static func _add_rotation(
	lines: Dictionary,
	library: UnitLibrary,
	config: GameConfig,
	pool: Array[Dictionary],
	heroes: Array[Dictionary],
	tribes: PackedStringArray,
	rotation_id: int
) -> void:
	var eligible: Array[Dictionary] = []
	for card: Dictionary in pool:
		var card_tribes: Array = card["tribes"]
		if UnitPool._in_lobby(card_tribes, tribes):
			eligible.append(card)
	assert(not eligible.is_empty(), "Every current test lobby needs a legal unit")
	# Prefer simple, low-tier cards so changing one tribe's engine does not make every field
	# plumbing test depend on that engine. Mechanics still use the real current definitions.
	eligible.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var a_mechanics: Array = a["mechanics"]
			var b_mechanics: Array = b["mechanics"]
			var a_score: int = a_mechanics.size() * 100 + CoreUtil.to_int(a["tier"])
			var b_score: int = b_mechanics.size() * 100 + CoreUtil.to_int(b["tier"])
			return a_score < b_score if a_score != b_score else str(a["id"]) < str(b["id"])
	)
	var rules := RecruitRules.create(library, config, UnitPool.create(library, config, tribes))
	for seat: int in SEATS_PER_ROTATION:
		var tribe: String = tribes[seat % tribes.size()] if not tribes.is_empty() else ""
		var line_id: String = "test_%s" % tribe
		if not lines.has(line_id):
			lines[line_id] = {"tribe": tribe, "trajectories": []}
		var line: Dictionary = lines[line_id]
		var trajectories: Array = line["trajectories"]
		var hero: Dictionary = heroes[seat % heroes.size()]
		var rounds: Dictionary = {}
		for round_number: int in range(1, ROUNDS + 1):
			rounds[str(round_number)] = _frame(
				rules, eligible[seat % mini(eligible.size(), 4)], hero, round_number, seat
			)
		trajectories.append(
			{
				"id": "test:%d:%d" % [rotation_id, seat],
				"hero": hero["id"],
				"name": "Test rival %d" % seat,
				"finish_place": seat % 4 + 1 if seat < 8 else seat - 3,
				"lobby_tribes": Array(tribes),
				"rounds": rounds
			}
		)


static func _frame(
	rules: RecruitRules, card: Dictionary, hero: Dictionary, round_number: int, seat: int
) -> Dictionary:
	var player := PlayerState.new()
	rules.setup_player(player)
	HeroRules.assign(player, hero)
	player.tier = mini(6, 1 + floori(round_number / 3.0))
	player.round_number = round_number
	for slot: int in mini(7, 1 + floori(round_number / 2.0)):
		var unit := RecruitUnit.make(card, 1000 + seat * 10 + slot)
		unit.perm_attack = floori(round_number / 2.0) + seat
		unit.perm_health = floori(round_number / 2.0) + seat
		player.board[slot] = unit
	return {
		"board": player.combat_board(),
		"slots": player.combat_slots(),
		"hero_effects": HeroRules.effects_of(hero),
		"fight_rules": rules.fight_rules(player),
		"tier": player.tier
	}
