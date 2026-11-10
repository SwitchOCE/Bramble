extends SceneTree
## Eight native viewport frames per recruit cue at fixed 1/120 seconds, as batch 1.
const RecruitMotion := preload("res://src/ui/screens/recruit_motion.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Settings := preload("res://src/ui/settings.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const STEP: float = 1.0 / 120.0
const PIXELS := Vector2i(1688, 780)
var _out: String
var _frames_out: String
var _manual_tweens: Array[Tween] = []
var _base: Dictionary


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() in [1, 2], "usage: -- <batch2 output> [raw frames output]")
	_out = args[0]
	_frames_out = args[1] if args.size() == 2 else "res://build/declutter-b2/frames"
	root.size = PIXELS
	DisplayServer.window_set_size(PIXELS)
	CardView.window_override = Vector2(PIXELS)
	Settings.path = "user://declutter_b2_frames.cfg"
	Settings.reset()
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var states: Dictionary = FixturePort.load_json(_out.path_join("states.json"))
	_base = states["overview"]["state"]
	for mode: String in ["x1", "x4", "reduce"]:
		Settings.fight_speed = 4.0 if mode == "x4" else 1.0
		Settings.reduce_motion = mode == "reduce"
		await _end_turn(mode)
		await _reach(mode)
	print("declutter-b2: all six deterministic strips complete")
	quit()


func _screen(state: Dictionary) -> RecruitScreen:
	var port: FixturePort = FixturePort.new()
	port._state = state
	var screen: RecruitScreen = RecruitScreen.new()
	root.add_child(screen)
	screen.setup(port)
	screen._clear_toast()
	return screen


func _end_turn(mode: String) -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var definition: Dictionary = library.get_unit("standing_committee").duplicate(true)
	definition["id"] = "declutter_test_committee"
	definition.erase(MechanicRegistry.COMPILED_KEY)
	definition["text"] = "End of Turn: give units touching this +1/+1."
	for mechanic: Dictionary in definition["mechanics"]:
		mechanic["trigger"] = "end_of_turn"
	assert(library.register_unit(definition).is_empty())
	var config := GameConfig.full_game()
	var pool: UnitPool = UnitPool.create(library, config)
	var rules: RecruitRules = RecruitRules.create(library, config, pool)
	var player := PlayerState.new()
	rules.setup_player(player)
	for pair: Array in [
		["mr_crumb", 0],
		["declutter_test_committee", 4],
		["field_vole", 1],
		["mr_crumb", 5],
		["field_vole", 2]
	]:
		var slot: int = CoreUtil.to_int(pair[1])
		player.board[slot] = RecruitUnit.make(library.get_unit(str(pair[0])), slot + 1)
	# Queue an actual Mr Crumb On Play effect; it resolves at End of Turn.
	rules.events.fire(player, "on_play", {"subject": player.board[0]})
	assert(player.pending_passes.size() == 1, "real Mr Crumb On Play queued exactly one Pass")
	var state: Dictionary = _base.duplicate(true)
	state["board"] = _views(player)
	state["slot_effects"] = [[], [], [], [], [], [], []]
	state["bands"] = [false, false, false, false, false, false, false]
	state["ring_size"] = player.ring_size
	state["pending_passes"] = player.pending_passes.duplicate(true)
	state["hand"] = []
	state["away"] = []
	state["doorstep"] = []
	var events: Array[Dictionary] = []
	player.log_observer = func(type: String, fields: Dictionary) -> void:
		var entry: Dictionary = fields.duplicate(true)
		entry["type"] = type
		events.append(entry)
	rules.end_phase(player)
	var screen: RecruitScreen = _screen(state)
	for frame: int in 10:
		await process_frame
	_manual_tweens.clear()
	var motion: RecruitMotion = screen.get("_motion")
	var board: BoardView = screen.get("_board")
	var before_snapshot: Array = state["board"]
	before_snapshot = before_snapshot.duplicate(true)
	var duration: float = motion.play_events(board, events)
	motion.set_process(false)
	await _samples(
		screen,
		"end-turn-" + mode,
		duration,
		motion,
		{
			"events": events,
			"before_board": before_snapshot,
			"after_board": _views(player),
			"fixture":
			(
				"Test-only Standing Committee trigger is end_of_turn instead of start_of_combat; "
				+ "all effects and Pass resolution run through real RecruitRules.end_phase. "
				+ "Mr Crumb Pass +1/+1 queued at on_play. No production definition changed."
			)
		}
	)
	root.remove_child(screen)
	screen.free()
	await process_frame


func _views(player: PlayerState) -> Array:
	var views: Array = []
	for unit: RecruitUnit in player.board:
		if unit == null:
			views.append(null)
		else:
			views.append(unit.view())
	return views


func _reach(mode: String) -> void:
	var library: UnitLibrary = UnitLibrary.load_dir()
	var state: Dictionary = _base.duplicate(true)
	var own: Array = [null, null, null, null, null, null, null]
	var enemy: Array = [null, null, null, null, null, null, null]
	for slot: int in [2, 5]:
		own[slot] = UnitViews.from_def(library.get_unit("field_vole"), false, 100 + slot)
	enemy[2] = UnitViews.from_def(library.get_unit("wick"), false, 202)
	enemy[5] = UnitViews.from_def(library.get_unit("old_brock"), false, 205)
	state["board"] = own
	state["slot_effects"] = [[], [], [], [], [], [], []]
	state["bands"] = [false, false, false, false, false, false, false]
	state["next_opponent_last_board"] = enemy
	state["next_opponent_last_slot_effects"] = [[], [], [], [], [], [], []]
	state["next_opponent_last_nests"] = []
	state["hand"] = []
	state["away"] = []
	state["doorstep"] = []
	var screen: RecruitScreen = _screen(state)
	screen.toggle_scout()
	for frame: int in 10:
		await process_frame
	screen._on_tapped("scout", 2)
	_manual_tweens.clear()
	var own_board: Control = screen.get("_board")
	var scout: Control = screen.get("_scout")
	var scout_board: Control = scout.get("_board")
	for board: Control in [own_board, scout_board]:
		var reach_tween: Tween = board.get("_reach_tween")
		assert(reach_tween != null and reach_tween.is_valid(), "reader starts a reach pulse")
		reach_tween.pause()
		_manual_tweens.append(reach_tween)
	await _samples(
		screen,
		"scout-reach-" + mode,
		0.4 / Settings.fight_speed,
		null,
		{
			"fixture":
			(
				"Native current cards: Old Brock at scouted slot5 lends its own across quarry "
				+ "to adjacent Wick at slot2. Opening Wick reader pulses your slot5 "
				+ "rather than straight across slot2."
			),
			"source_slot": 2,
			"lender_slot": 5,
			"expected_target_slot": 5,
			"state": state
		}
	)
	root.remove_child(screen)
	screen.free()
	await process_frame


func _samples(
	screen: Control, name: String, duration: float, motion: Control, truth: Dictionary
) -> void:
	assert(duration > 0.0 and duration <= 1.5, "recruit cue duration fits spec")
	var directory: String = _frames_out.path_join(name)
	DirAccess.make_dir_recursive_absolute(directory)
	var end_tick: int = maxi(7, ceili(duration / STEP))
	var ticks: Array[int] = []
	for index: int in 8:
		ticks.append(roundi(index * float(end_tick) / 7.0))
	var frames: Array[Dictionary] = []
	for tick: int in end_tick + 1:
		if tick > 0:
			if motion != null:
				motion.call("advance", STEP)
				motion.set_process(false)
			for tween: Tween in _manual_tweens:
				if tween.is_valid():
					tween.custom_step(STEP)
		if ticks.has(tick):
			await process_frame
			await RenderingServer.frame_post_draw
			var filename: String = "frame-%03d.png" % frames.size()
			var picture: Image = root.get_texture().get_image()
			assert(picture.get_size() == PIXELS)
			assert(picture.save_png(directory.path_join(filename)) == OK)
			var nodes: Array[Dictionary] = Capture.text_nodes(screen)
			var current_board: Control = screen.get("_board")
			frames.append(
				{
					"file": filename,
					"tick": tick,
					"time": tick * STEP,
					"visible_text_count": nodes.size(),
					"visible_text_nodes": nodes,
					"board_stats": _shown_stats(current_board),
					"reach_values": _reach_values(screen)
				}
			)
	truth["name"] = name
	truth["pixels"] = [PIXELS.x, PIXELS.y]
	truth["fixed_step"] = STEP
	truth["duration"] = duration
	truth["sample_ticks"] = ticks
	truth["frames"] = frames
	if truth.has("events"):
		truth["events_sha256"] = JSON.stringify(truth["events"], "", true, true).sha256_text()
	var file := FileAccess.open(directory.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(truth, "\t", true, true) + "\n")
	print("declutter-b2 strip: ", name, " duration=", duration, " frames=", frames.size())


func _shown_stats(board: Control) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cards: Array = board.get("cards")
	for slot: int in cards.size():
		var card: Control = cards[slot]
		if card != null:
			var unit: Dictionary = card.get("unit")
			var attack_label: Label = card.get("_attack_label")
			var health_label: Label = card.get("_health_label")
			out.append(
				{
					"slot": slot,
					"iid": unit.get("iid", -1),
					"attack": attack_label.text.to_int(),
					"health": health_label.text.to_int()
				}
			)
	return out


func _reach_values(screen: Control) -> Dictionary:
	var board: Control = screen.get("_board")
	var slots: Array = board.get("slots")
	var target: Control = slots[5]
	var across: Control = slots[2]
	return {
		"expected_target5": target.get("reach_flash"), "straight_across2": across.get("reach_flash")
	}
