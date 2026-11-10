extends GutTest
## tools/play's blind variants, its turn walker (what render.sh draws) and the UI's game log writer.

const Play := preload("res://tools/play/play.gd")
const FieldTestData := preload("res://tests/core/field_test_data.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const MAP_PATH: String = "user://test_variant_map.json"
const LOG_DIR: String = "user://test_games"
const SHORT_GAME: Array = [
	["choose", "1"], ["buy", "2"], ["play", "@3", "F1"], ["end"], ["buy", "0"], ["end"]
]

var _old_map: String = ""
var _old_log_dir: String = ""
var _old_build: Variant


func before_each() -> void:
	_old_map = OS.get_environment(PlayVariant.MAP_ENV)
	_old_log_dir = GameRecordLog.dir
	GameRecordLog.dir = LOG_DIR
	_old_build = ProjectSettings.get_setting("application/config/build_commit")


func after_each() -> void:
	OS.set_environment(PlayVariant.MAP_ENV, _old_map)
	GameRecordLog.dir = _old_log_dir
	ProjectSettings.set_setting("application/config/build_commit", _old_build)


func _use_map(text: String) -> void:
	var file: FileAccess = FileAccess.open(MAP_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	OS.set_environment(PlayVariant.MAP_ENV, ProjectSettings.globalize_path(MAP_PATH))


## A blind game on the variant's preset, played a few actions in.
func _blind(variant: String, game_seed: int = 11) -> PlayGame:
	var entry: Dictionary = PlayVariant.lookup(variant)
	assert_false(entry.has("error"), str(entry))
	var game := PlayGame.start(game_seed, "", "top4", str(entry["preset"]), variant)
	assert_eq(game.load_error, "", "starts")
	for words: Array in SHORT_GAME:
		assert_eq(game.run(PackedStringArray(words)), "", "ran %s" % str(words))
	return game


func test_variant_needs_a_map() -> void:
	OS.set_environment(PlayVariant.MAP_ENV, "")
	var entry: Dictionary = PlayVariant.lookup("X")
	assert_true(str(entry.get("error", "")).contains(PlayVariant.MAP_ENV), "says which env var")
	_use_map('{"X": "C"}')
	assert_true(PlayVariant.lookup("Y").has("error"), "no entry for Y")
	assert_true(PlayVariant.lookup("Z").has("error"), "only X and Y")
	_use_map('{"X": "Q"}')
	var unknown: Dictionary = PlayVariant.lookup("X")
	assert_false(str(unknown.get("error", "")).contains("Q"), "a bad preset isn't echoed")


func test_variant_replays_without_the_map() -> void:
	_use_map('{"X": "C", "Y": "B"}')
	var game: PlayGame = _blind("X")
	var saved: Dictionary = game.to_save()
	OS.set_environment(PlayVariant.MAP_ENV, "")
	var copied: Dictionary = JSON.parse_string(JSON.stringify(saved))
	var again := PlayGame.from_save(copied)
	assert_eq(again.load_error, "", "replays with no map")
	assert_eq(again.state_hash(), game.state_hash(), "to the same state")
	assert_eq(again.preset, "C", "on the sealed preset")
	assert_eq(PlayVariant.reveal(again), "Variant X plays preset C", "reveal opens the seal")


func test_variant_plays_its_preset() -> void:
	_use_map('{"X": "C", "Y": "B"}')
	var on_c: PlayGame = _blind("X")
	var on_b: PlayGame = _blind("Y")
	var plain := PlayGame.start(11, "", "top4", "C")
	for words: Array in SHORT_GAME:
		plain.run(PackedStringArray(words))
	assert_eq(on_c.state_hash(), plain.state_hash(), "X is the same game as preset C")
	assert_eq(on_b.preset, "B", "Y is B")


func test_blind_output_never_names_the_preset() -> void:
	_use_map('{"X": "C", "Y": "B"}')
	var field_path: String = _field_on_c()
	var game := PlayGame.start(11, field_path, "top4", "C", "X")
	assert_eq(game.load_error, "")
	assert_eq(game.run(["choose", "1"]), "")
	for turn: int in 60:
		if game.session.is_over():
			break
		assert_eq(game.run(["end"]), "", "turn %d" % turn)
	assert_true(game.session.is_over(), "scrub is checked at game over")
	assert_true(game.session.get_game_log().has("field_source"), "the unsanitized log has a source")
	assert_true(game.session.get_game_log().has("field_switches"), "and switches")
	var words := RegEx.create_from_string("\\bC\\b")
	var outputs: Dictionary = {
		"screen": PlayView.text(game, ""),
		"log": PlayView.log_text(game),
		"json": PlayView.json(game, ""),
	}
	for shown: String in outputs:
		var text: String = outputs[shown]
		assert_false(text.to_lower().contains("preset"), "%s doesn't say preset" % shown)
		assert_null(words.search(text), "%s doesn't show C" % shown)
		assert_false(text.contains(field_path), "%s hides the library path" % shown)
	var saved: String = JSON.stringify(game.to_save())
	assert_false(saved.contains('"C"'), "the save holds the preset only sealed")
	assert_false(saved.contains(field_path), "the save seals the library reference")
	var json: Dictionary = JSON.parse_string(PlayView.json(game, ""))
	var summary: Dictionary = json["game_log"]
	assert_false(summary.has("field_source"))
	assert_false(summary.has("field_switches"))
	var save_data: Dictionary = JSON.parse_string(saved)
	var replay := PlayGame.from_save(save_data)
	assert_eq(replay.load_error, "")
	assert_eq(replay.state_hash(), game.state_hash(), "sealed field game replays to game over")


func test_damaged_seal_is_refused() -> void:
	var saved: Dictionary = {
		"seed": 3,
		"actions": [],
		"variant": "X",
		"variant_seal": Marshalls.utf8_to_base64("wrong-prefix")
	}
	var game := PlayGame.from_save(saved)
	assert_true(game.load_error.contains("seal"), game.load_error)


func test_turns_walk_the_same_twice_and_match_the_log() -> void:
	var game := PlayGame.start(11)
	for words: Array in SHORT_GAME:
		game.run(PackedStringArray(words))
	var first: Array = _moments(game.to_save())
	var second: Array = _moments(game.to_save())
	assert_eq(first, second, "same moments and state hashes")
	var kinds: PackedStringArray = []
	for moment: Dictionary in first:
		kinds.append("%s%d" % [moment["kind"], moment["round"]])
	assert_eq(
		",".join(kinds), "start1,end1,fight1,start2,end2,fight2,start3", "every turn's moments"
	)
	for moment: Dictionary in first:
		if moment["kind"] == PlayTurns.FIGHT:
			var fight: Dictionary = moment["fight"]
			assert_eq(
				CoreUtil.to_int(fight["round"]),
				CoreUtil.to_int(moment["round"]),
				"the turn's own fight"
			)
			assert_eq(str(fight["result"]), str(fight["log_result"]), "as the log reports it")
	var last: Dictionary = first[-1]
	var turn_end: Dictionary = first[1]
	assert_eq(str(last["hash"]), game.state_hash(), "ends where the save does")
	# The turn's end is drawn before "end": its hash is the state after the turn's buys.
	var before_end := PlayGame.start(11)
	for words: Array in SHORT_GAME.slice(0, 3):
		before_end.run(PackedStringArray(words))
	assert_eq(str(turn_end["hash"]), before_end.state_hash(), "turn 1's end is before its fight")


func _moments(save: Dictionary) -> Array:
	var turns := PlayTurns.open(save)
	assert_eq(turns.error, "", "opens")
	var out: Array = []
	while true:
		var moment: Dictionary = turns.next()
		if moment.is_empty():
			break
		out.append(moment)
	return out


## A scripted game through the UI's port, every action recorded as the UI hook would.
func test_game_log_replays_to_the_same_final_state() -> void:
	var port := CorePort.new()
	port.setup(GameConfig.full_game())
	assert_eq(port.new_game(29), "", "starts")
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	var actions: Array = []
	var taken: Dictionary = {}
	var steps: int = 0
	while not port.is_over() and CoreUtil.to_int(port.get_state()["round"]) <= 6 and steps < 400:
		steps += 1
		var state: Dictionary = port.get_state()
		var legal: Array[Dictionary] = LegalActions.of(state)
		var pick: Dictionary = legal[rng.randi_range(0, legal.size() - 1)]
		if rng.randf() < 0.15:
			pick = legal[-1]
		var action: String = pick["action"]
		var args: Array = pick["args"]
		var words: Array = GameRecordLog.words(action, args, state)
		var result: String = port.callv(action, args)
		assert_eq(result, "", "legal %s" % str(pick))
		if result == "":
			actions.append(words)
			taken[str(words[0])] = true
	var path: String = GameRecordLog.write(port, actions)
	assert_true(path.ends_with("-29.json"), "named by time and seed: %s" % path)
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var settings: Dictionary = record["settings"]
	assert_eq(str(record["hero"]), GameRecordLog.hero_id(port.get_state()), "the hero")
	assert_eq(str(settings["preset"]), Pass3Rates.default_preset(), "the preset")
	var replay: PlayGame = Play._from_log(record, "")
	assert_eq(replay.load_error, "", "replays")
	var expected: String = JSON.stringify(port.get_state(), "", true).sha256_text()
	assert_eq(replay.state_hash(), expected, "to the same final state")
	for word: String in ["choose", "buy", "play", "end"]:
		assert_true(taken.has(word), "the script used %s" % word)
	DirAccess.remove_absolute(path)


func test_game_log_words_match_tools_play() -> void:
	var state: Dictionary = {
		"shop": [{}, {}, {}],
		"hand": [{}],
		"hand_items": [{"aim": HandItem.AIM_SHOP_UNIT}, {"aim": "slot"}],
	}
	var cases: Array = [
		["buy_spell", [1], ["buy", "4"]],
		["play", [0, 4], ["play", "0", "B1"]],
		["play_item", [0, 2], ["play", "1", "2"]],
		["play_item", [1, 0], ["play", "2", "F1"]],
		["play_item", [1, -1], ["play", "2"]],
		["swallow", [HeldUnits.HAND, 0, 1], ["swallow", "h0", "F2"]],
		["swallow", [HeldUnits.BOARD, 6, 0], ["swallow", "B3", "F1"]],
		["use_power", [-1], ["power"]],
		["toggle_freeze", [], ["freeze"]],
		["dev_add_gold", [5], ["dev_add_gold", "5"]],
	]
	for case: Array in cases:
		var method: String = case[0]
		var args: Array = case[1]
		var expected: Array = case[2]
		assert_eq(GameRecordLog.words(method, args, state), expected, str(case))


func test_not_a_game_log_is_refused() -> void:
	assert_true(GameRecordLog.to_save({"seed": 1}).has("error"), "no format")
	var wrong: Dictionary = {"format": GameRecordLog.FORMAT, "version": 99, "settings": {}}
	assert_true(GameRecordLog.to_save(wrong).has("error"), "a later version")


func _field_on_c() -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FieldTestData.path()))
	data["config"]["pass3_preset"] = "C"
	var path: String = "user://test_field_C.json"
	data["source"]["path"] = path
	data["source"]["preset"] = "C"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	return path


func test_cli_start_uses_the_variant_map_and_refuses_library_overrides() -> void:
	var cli := Play.new()
	OS.set_environment(PlayVariant.MAP_ENV, "")
	assert_string_contains(cli._start(["--variant", "X"]).load_error, PlayVariant.MAP_ENV)
	_use_map('{"X": "C"}')
	var plain: PlayGame = cli._start(["--seed", "11", "--variant", "x"])
	assert_eq(plain.load_error, "")
	assert_eq(plain.preset, "C")
	assert_eq(plain.variant, "X")
	assert_eq(plain.seed_value, 11)
	for map: String in [
		'{"X": "C"}', JSON.stringify({"X": {"preset": "C", "field_library": _field_on_c()}})
	]:
		_use_map(map)
		var refused: PlayGame = cli._start(["--variant", "X", "--field-library", "anything"])
		assert_string_contains(refused.load_error, "cannot be combined")
	var field: PlayGame = cli._start(["--seed", "11", "--variant", "X"])
	assert_eq(field.load_error, "")
	assert_eq(field.field_library_path, "user://test_field_C.json")
	var opponents: String = field.session.get_state()["opponents"]
	assert_eq(opponents, "field")
	cli.free()


func test_library_on_another_preset_is_refused_without_naming_the_presets() -> void:
	var game := PlayGame.start(11, _field_on_c(), "top4", "B", "X")
	assert_eq(game.load_error, "The field library was captured on a different preset.")
	assert_null(game.session)


func test_export_build_setting_overrides_checkout_and_dev_cannot_be_matched() -> void:
	var commit: String = "0123456789abcdef0123456789abcdef01234567"
	ProjectSettings.set_setting("application/config/build_commit", commit)
	var record: Dictionary = GameRecordLog.make(11, GameConfig.full_game(), {}, [])
	assert_eq(str(record["build"]), commit, "the baked revision wins over the editor's checkout")
	assert_false(GameRecordLog.to_save(record).has("error"))
	ProjectSettings.set_setting("application/config/build_commit", "dev")
	assert_string_contains(str(GameRecordLog.to_save(record).get("error")), "cannot be matched")
	var dev_record: Dictionary = GameRecordLog.make(11, GameConfig.full_game(), {}, [])
	assert_eq(str(dev_record["build"]), "dev")
	assert_string_contains(str(GameRecordLog.to_save(dev_record).get("error")), "cannot be matched")
	ProjectSettings.set_setting("application/config/build_commit", commit)
	assert_string_contains(str(GameRecordLog.to_save(dev_record).get("error")), "cannot be matched")


func test_from_log_checks_build_hash_placement_and_hero() -> void:
	var game := PlayGame.start(11, _field_on_c(), "top4", "C")
	assert_eq(game.run(["choose", "1"]), "")
	for turn: int in 60:
		if game.session.is_over():
			break
		assert_eq(game.run(["end"]), "", "turn %d" % turn)
	assert_true(game.session.is_over())
	var record: Dictionary = GameRecordLog.make(
		11, game.session._config, game.session.get_state(), game.actions
	)
	assert_eq(str(record["build"]).length(), 40, "full commit id")
	assert_eq(str(record["final_state_hash"]), game.state_hash())
	var replay: PlayGame = Play._from_log(record, "")
	assert_eq(replay.load_error, "")
	assert_eq(replay.state_hash(), game.state_hash())
	for key: String in ["build", "final_state_hash", "placement", "hero"]:
		var changed: Dictionary = record.duplicate(true)
		changed[key] = "incorrect"
		if key == "placement":
			changed[key] = -99
		var refused: PlayGame = Play._from_log(changed, "")
		var labels: Dictionary = {
			"build": "build", "final_state_hash": "hash", "placement": "placement", "hero": "hero"
		}
		assert_string_contains(refused.load_error.to_lower(), str(labels[key]))
	var missing: Dictionary = record.duplicate(true)
	missing.erase("build")
	assert_string_contains(Play._from_log(missing, "").load_error, "Build mismatch")


func test_from_log_relocates_a_field_library_and_checks_its_hash() -> void:
	var game := PlayGame.start(11, _field_on_c(), "top4", "C")
	assert_eq(game.load_error, "")
	assert_eq(game.run(["choose", "1"]), "")
	assert_eq(game.run(["end"]), "")
	var record: Dictionary = GameRecordLog.make(
		11, game.session._config, game.session.get_state(), game.actions
	)
	record["settings"]["field_library"] = "user://missing-original.json"
	assert_string_contains(Play._from_log(record, "").load_error, "missing")
	var replay: PlayGame = Play._from_log(record, game.field_library_path)
	assert_eq(replay.load_error, "")
	assert_eq(replay.state_hash(), game.state_hash())
	record["settings"]["field_library_sha256"] = "incorrect"
	assert_string_contains(Play._from_log(record, game.field_library_path).load_error, "changed")


## Every action is applied once by the API and once by the recorded words, from equal states.
## Hand-built states cover actions a random seed need not visit, including all target grammars.
func test_every_action_kind_round_trips_through_play_game_run() -> void:
	var cases: Array = [
		["choose", [1]],
		["buy", [1]],
		["buy_spell", [0]],
		["play", [0, 3]],
		["play_item", [0, -1]],
		["play_item", [1, 0]],
		["play_item", [2, 1]],
		["swallow", [HeldUnits.HAND, 0, 0]],
		["swallow", [HeldUnits.BOARD, 4, 0]],
		["swallow", [HeldUnits.SHOP, 1, 0]],
		["use_power", [-1]],
		["use_power", [2]],
		["sell", [4]],
		["move", [4, 5]],
		["refresh", []],
		["ask_for_kin", []],
		["toggle_freeze", []],
		["tier_up", []],
		["end_turn", []],
	]
	for case: Array in cases:
		var method: String = case[0]
		var args: Array = case[1]
		var direct: PlayGame = _action_state(method, args)
		var replay: PlayGame = _action_state(method, args)
		assert_eq(direct.state_hash(), replay.state_hash(), "equal starting states: %s" % str(case))
		var words: Array = GameRecordLog.words(method, args, direct.session.get_state())
		var result: String = direct.session.callv(method, args)
		assert_eq(result, "", "direct %s" % str(case))
		assert_eq(replay.run(PackedStringArray(words)), "", "replayed %s" % str(words))
		assert_eq(direct.state_hash(), replay.state_hash(), "same result: %s" % str(case))
		assert_eq(replay.actions, [words], "recorded %s" % str(case))


func _action_state(method: String, args: Array) -> PlayGame:
	var config := GameConfig.full_game()
	config.set_value("ask_for_kin", true)
	config.set_value("bots", ["naive", "naive", "naive", "naive", "naive", "naive", "naive"])
	var game := PlayGame.new()
	game._library = TestLibraries.current()
	game.session = GameSession.create(29, game._library, config)
	if method == "choose":
		return game
	assert_eq(game.session.choose(0), "")
	var player: PlayerState = game.session._players[0]
	var rules: RecruitRules = game.session._rules
	player.gold = 100
	player.tier = 3
	player.hand.clear()
	player.items.clear()
	player.shop.clear()
	player.shop_spells.clear()
	player.board.fill(null)
	player.board[0] = RecruitUnit.make(rules.library.get_unit("little_dollop"), rules.new_iid())
	player.board[4] = RecruitUnit.make(rules.library.get_unit("field_vole"), rules.new_iid())
	player.hand.append(RecruitUnit.make(rules.library.get_unit("field_vole"), rules.new_iid()))
	for id: String in ["field_vole", "pill_bug"]:
		player.shop.append(RecruitUnit.make(rules.library.get_unit(id), rules.new_iid()))
	for id: String in ["acorn", "sample_growth", "shake_the_tree"]:
		player.items.append(HandItem.make(rules.library.get_card(id), rules.new_iid()))
	player.shop_spells.append(
		HandItem.make(rules.library.get_card("sample_growth"), rules.new_iid())
	)
	if method == "use_power":
		var hero: Dictionary = rules.library.get_hero("sample_painter").duplicate(true)
		if args[0] == -1:
			hero["power"] = {
				"kind": "activated", "cost": 1, "uses_per_turn": 1, "do": {"effect": "free_refresh"}
			}
		HeroRules.assign(player, hero)
	return game
