extends GutTest
## tools/play's blind variants, its turn walker (what render.sh draws) and the UI's game log writer.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const MAP_PATH: String = "user://test_variant_map.json"
const LOG_DIR: String = "user://test_games"
const SHORT_GAME: Array = [
	["choose", "1"], ["buy", "2"], ["play", "@3", "F1"], ["end"], ["buy", "0"], ["end"]
]

var _old_map: String = ""


func before_each() -> void:
	_old_map = OS.get_environment(PlayVariant.MAP_ENV)


func after_each() -> void:
	OS.set_environment(PlayVariant.MAP_ENV, _old_map)


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
	_use_map('{"X": "B", "Y": "C"}')
	var remapped := PlayGame.from_save(saved)
	assert_eq(remapped.state_hash(), game.state_hash(), "a changed map doesn't change the game")


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
	var game: PlayGame = _blind("X")
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
	var saved: String = JSON.stringify(game.to_save())
	assert_false(saved.contains('"C"'), "the save holds the preset only sealed")


func test_damaged_seal_is_refused() -> void:
	var saved: Dictionary = {"seed": 3, "actions": [], "variant": "X", "variant_seal": "nonsense"}
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
	var path: String = GameRecordLog.write(port, actions, LOG_DIR)
	assert_true(path.ends_with("-29.json"), "named by time and seed: %s" % path)
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var settings: Dictionary = record["settings"]
	assert_eq(str(record["hero"]), GameRecordLog.hero_id(port.get_state()), "the hero")
	assert_eq(str(settings["preset"]), Pass3Rates.default_preset(), "the preset")
	var saved: Dictionary = GameRecordLog.to_save(record)
	var replay := PlayGame.from_save(saved)
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
