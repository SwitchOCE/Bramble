extends GutTest
## The game's sound (src/sound): which cues a fight step asks for, by the rules in Neon's table
## (assets/audio/cues.json); how the player picks takes and drops plays; that a real fight played
## through the fight screen asks for its hits; and that the rules core never refers to sound.
## Whether it sounds right is the owner's call (docs/AGENT-BLIND-SPOTS.md, section 8).

const CoreKit := preload("res://tests/core/core_kit.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")

var _table: Dictionary


func before_all() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SoundPlayer.TABLE_PATH))
	assert_true(parsed is Dictionary, "the cue table reads")
	_table = parsed if parsed is Dictionary else {}


func _splash(splashes: Array) -> Dictionary:
	return {"kind": "splash", "state": {"moment": {"splashes": splashes}}, "hold": 0.55}


func _hit(amount: int) -> Dictionary:
	return {"side": 0, "slot": 0, "amount": amount}


func _names(cues: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for cue: Dictionary in cues:
		out.append(str(cue["cue"]))
	return out


func test_every_hit_cue_the_rules_name_has_takes_that_load() -> void:
	var cues: Dictionary = _table["cues"]
	for cue_name: String in ["fight.hit.light", "fight.hit.medium", "fight.hit.heavy"]:
		assert_true(cues.has(cue_name), cue_name)
		var spec: Dictionary = CoreUtil.to_dict(cues.get(cue_name, {}))
		var files: Array = CoreUtil.to_array(spec.get("files", []))
		assert_gt(files.size(), 1, "%s has several takes" % cue_name)
		for file: Variant in files:
			assert_true(load(str(file)) is AudioStream, "%s loads" % file)


func test_hit_weight_follows_damage() -> void:
	var weights: Dictionary = _table["hit_weights"]
	assert_eq(SoundCues.hit_cue(1, weights), "fight.hit.light")
	assert_eq(SoundCues.hit_cue(4, weights), "fight.hit.light")
	assert_eq(SoundCues.hit_cue(5, weights), "fight.hit.medium")
	assert_eq(SoundCues.hit_cue(13, weights), "fight.hit.medium")
	assert_eq(SoundCues.hit_cue(14, weights), "fight.hit.heavy")
	assert_eq(SoundCues.hit_cue(0, weights), "fight.hit.heavy", "a destroy")


func test_two_hits_at_once_play_the_heaviest_once() -> void:
	var cues: Array[Dictionary] = SoundCues.for_fight_step(_splash([_hit(3), _hit(9)]), _table)
	assert_eq(_names(cues), ["fight.hit.medium"])
	assert_eq(SoundPlayer._num(cues[0]["delay_s"]), 0.0)


func test_a_hit_and_a_block_play_the_hit_then_the_block() -> void:
	var blocked: Dictionary = {"side": 1, "slot": 0, "amount": 0, "blocked": true}
	var cues: Array[Dictionary] = SoundCues.for_fight_step(_splash([_hit(20), blocked]), _table)
	assert_eq(_names(cues), ["fight.hit.heavy", "fight.hit.blocked"])
	assert_almost_eq(SoundPlayer._num(cues[1]["delay_s"]), 0.015, 0.0001)
	assert_almost_eq(SoundPlayer._num(cues[1]["gain_db"]), -3.0, 0.0001)
	var only: Array[Dictionary] = SoundCues.for_fight_step(_splash([blocked]), _table)
	assert_eq(_names(only), ["fight.hit.blocked"])


func test_a_cleave_plays_at_most_three_staggered_heaviest_first() -> void:
	var step: Dictionary = _splash([_hit(2), _hit(30), _hit(7), _hit(1), _hit(8)])
	var cues: Array[Dictionary] = SoundCues.for_fight_step(step, _table)
	assert_eq(_names(cues), ["fight.hit.heavy", "fight.hit.medium", "fight.hit.medium"])
	assert_almost_eq(SoundPlayer._num(cues[1]["delay_s"]), 0.028, 0.0001)
	assert_almost_eq(SoundPlayer._num(cues[2]["gain_db"]), -7.0, 0.0001)


func test_other_steps_are_silent_for_now() -> void:
	for kind: String in ["", "trigger", "death", "summon", "change"]:
		var step: Dictionary = {"kind": kind, "state": {"moment": {}}, "hold": 0.3}
		assert_eq(SoundCues.for_fight_step(step, _table).size(), 0, kind)


func test_takes_never_repeat_back_to_back_and_missing_cues_stay_silent() -> void:
	var player: SoundPlayer = SoundPlayer.new()
	player.keep_log = true
	add_child_autofree(player)
	# no gap between starts in this test: each play is a separate moment
	var cues: Dictionary = player.table["cues"]
	var medium: Dictionary = cues["fight.hit.medium"]
	medium["min_gap_s"] = 0.0
	medium["max_voices"] = 99
	var last: String = ""
	for i: int in 20:
		# headless sound never finishes on its own: free the voices as time would
		for voice: Node in player.get_children():
			(voice as AudioStreamPlayer).stop()
		player.play("fight.hit.medium")
		var entry: Dictionary = player.heard[player.heard.size() - 1]
		assert_eq(str(entry["dropped"]), "", "played")
		assert_ne(str(entry["file"]), last, "a new take each time")
		last = str(entry["file"])
	player.play("fight.no_such_cue")
	assert_eq(str(player.heard[player.heard.size() - 1]["dropped"]), "missing")


func test_a_second_start_inside_the_gap_is_dropped() -> void:
	var player: SoundPlayer = SoundPlayer.new()
	player.keep_log = true
	add_child_autofree(player)
	player.play("fight.hit.heavy")
	player.play("fight.hit.heavy")
	assert_eq(str(player.heard[0]["dropped"]), "")
	assert_eq(str(player.heard[1]["dropped"]), "gap", "the same cue twice in one moment")


func test_a_real_fight_through_the_screen_asks_for_its_hits() -> void:
	var content: GameContent = GameContent.load_default()
	if content.tribe_name("badger") == "" or content.tribe_name("mouse") == "":
		pass_test("no badger or mouse folder")
		return
	var flow: GameFlow = FlowFixture.live(content, 11)
	flow.start_round()
	var session: GameSession = flow.session
	CoreKit.put(session, flow.human(), "armsbearer", 0)
	var them: PlayerState = session.player(session.opponent_of(GameFlow.HUMAN))
	CoreKit.put(session, them, "bell-ringer", 0)
	CoreKit.put(session, them, "hedgerow-scout", 1)
	them.turn_ended = true
	var record: Dictionary = flow.finish_round()
	var replay: FightReplay = FightReplay.build(
		ViewAdapter.fight_base(flow, record),
		CoreUtil.to_array(record["events"]),
		ViewAdapter.catalog(content),
		CoreUtil.to_int(record["damage"])
	)
	var splash_steps: int = 0
	for step: Dictionary in replay.steps:
		if str(step["kind"]) == "splash":
			splash_steps += 1
	assert_gt(splash_steps, 0, "the fight has hits")
	Sound.keep_log = true
	Sound.heard.clear()
	var screen: FightScreen = SCREEN.instantiate()
	add_child_autofree(screen)
	screen.play(replay)
	for _guard: int in 2000:
		if not screen.is_playing():
			break
		screen._process(0.1)
	Sound.keep_log = false
	var hits: int = 0
	for entry: Dictionary in Sound.heard:
		if str(entry["cue"]).begins_with("fight.hit."):
			hits += 1
	assert_gte(hits, splash_steps, "at least one hit cue per hit step")
	Sound.heard.clear()


func test_the_rules_core_never_refers_to_sound() -> void:
	var found: PackedStringArray = []
	_scan("res://src/core", found)
	assert_eq(found, PackedStringArray(), "rules files that mention sound")


func _scan(dir: String, found: PackedStringArray) -> void:
	for file: String in DirAccess.get_files_at(dir):
		if not file.ends_with(".gd"):
			continue
		var text: String = FileAccess.get_file_as_string(dir.path_join(file))
		for word: String in ["Sound", "AudioStream", "AudioServer", "src/sound"]:
			if text.contains(word):
				found.append("%s: %s" % [dir.path_join(file), word])
	for sub: String in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(sub), found)


func test_the_pause_panel_sets_volume_and_mute_and_they_reach_the_bus() -> void:
	GameSettings.forget()
	var panel: PausePanel = PausePanel.new()
	add_child_autofree(panel)
	var bus: int = AudioServer.get_bus_index(SoundPlayer.BUS)
	assert_gte(bus, 0, "the sound bus exists")
	panel.set_muted(true)
	assert_true(GameSettings.muted())
	assert_true(AudioServer.is_bus_mute(bus), "muted")
	var mute: Node = panel.find_child("Button_Mute", true, false)
	assert_not_null(mute.get_node_or_null("Lit"), "Mute lit")
	panel.set_volume(0.5)
	assert_false(GameSettings.muted(), "moving the volume unmutes")
	assert_false(AudioServer.is_bus_mute(bus))
	assert_null(mute.get_node_or_null("Lit"), "Mute not lit")
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.01)
	GameSettings.forget()
	assert_almost_eq(GameSettings.volume(), 0.5, 0.0001, "saved")
	panel.set_volume(GameSettings.DEFAULT_VOLUME)
