extends SceneTree
## Real production callbacks on designed legal recruit states; reader labels reveal no actions.
const RecruitFixture := preload("res://tests/ui/shots/declutter_cold_fixture.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Settings := preload("res://src/ui/settings.gd")
const Capture := preload("res://tests/ui/shots/declutter_capture.gd")
const HowToPlay := preload("res://src/ui/screens/how_to_play.gd")
const TileStates := preload("res://tests/ui/shots/declutter_tile_states.gd")
const STEP: float = 1.0 / 120.0
const PIXELS := Vector2i(1688, 780)
const CASES: Dictionary = {
	"A": "play",
	"B": "ooze",
	"C": "buy",
	"D": "scout",
	"E": "triple",
	"F": "bird",
	"G": "sell",
	"H": "tier-up"
}
var _out: String
var _raw: String
var _revision: String
var _clock_nodes: Array[Node] = []
var _tweens: Array[Tween] = []
var _states: Dictionary = {}
var _events: Array[Dictionary] = []
var _rest: Array[Dictionary] = []
var _selected: PackedStringArray = []


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() in [3, 4], "usage: -- <packet> <raw> <revision> [reader labels]")
	_out = args[0]
	_raw = args[1]
	_revision = args[2]
	if args.size() == 4:
		_selected = args[3].split(",", false)
	Settings.path = "user://declutter_cold.cfg"
	Settings.reset()
	_resize(PIXELS)
	_run.call_deferred()


func _resize(pixels: Vector2i) -> void:
	root.size = pixels
	DisplayServer.window_set_size(pixels)
	CardView.window_override = Vector2(pixels)
	Input.warp_mouse(Vector2(pixels.x - 4, 4))


func _run() -> void:
	await process_frame
	for mode: String in ["x1", "reduce"]:
		Settings.fight_speed = 1.0
		Settings.reduce_motion = mode == "reduce"
		for label: String in CASES:
			if _selected.is_empty() or _selected.has(label):
				await _action(label, str(CASES[label]), mode)
	if not _selected.is_empty():
		print("declutter cold: selected native replays complete")
		quit()
		return
	var source: Dictionary = FixturePort.load_json(
		"res://docs/ideation/evidence/declutter/batch2/states.json"
	)
	for name: String in source:
		_states["spec-" + name] = {"before": source[name]["state"], "after": source[name]["state"]}
	var overview: Dictionary = source["overview"]
	var initial: Dictionary = overview["state"]
	var fan: Dictionary = TileStates.fan10(initial)
	_states["fan10"] = {"before": fan, "after": fan}
	_write(_out.path_join("technical/states.json"), _states)
	await _resting_states()
	await _rules_pages()
	_write(
		_out.path_join("technical/resting-words.json"),
		{
			"production_revision": _revision,
			"captures": _rest,
			"raster_lettering_audit":
			"Native visual inspection required; text controls cannot detect raster letters."
		}
	)
	print("declutter cold: sixteen action sheets, resting states and Rules pages captured")
	quit()


func _action(label: String, kind: String, mode: String) -> void:
	var port: CorePort = RecruitFixture.make(kind)
	var players: Array[PlayerState] = port.session.get("_players")
	var player: PlayerState = players[0]
	var screen := RecruitScreen.new()
	root.add_child(screen)
	screen.setup(port)
	if kind == "scout":
		screen.toggle_scout()
	for index: int in 10:
		await process_frame
	screen._clear_toast()
	var before: Dictionary = port.get_state().duplicate(true)
	_events = []
	player.recruit_log.clear()
	player.log_observer = func(type: String, fields: Dictionary) -> void:
		var event: Dictionary = fields.duplicate(true)
		event["type"] = type
		_events.append(event)
	var directory: String = _raw.path_join(label + "-" + mode)
	DirAccess.make_dir_recursive_absolute(directory)
	var frames: Array[Dictionary] = []
	await _frame(screen, directory, frames, 0)
	RecruitFixture.perform(screen, kind)
	player.log_observer = Callable()
	var after: Dictionary = port.get_state().duplicate(true)
	assert(
		kind in ["scout", "tier-up"] or not _events.is_empty(),
		"production card action must emit actual core events"
	)
	var motion: Control = screen.get("_action_motion")
	var duration: float = 0.4 if kind == "scout" else CoreUtil.to_float(motion.get("duration"))
	assert(duration > 0.0 and duration <= 1.5, "production action cue starts and fits its window")
	var last_tick: int = maxi(7, ceili(duration / STEP) + 2)
	var ticks: Array[int] = []
	for index: int in 8:
		ticks.append(roundi(index * float(last_tick) / 7.0))
	_clock_nodes.clear()
	_tweens.clear()
	_freeze_clocks(screen)
	for tick: int in range(1, last_tick + 1):
		for clock: Node in _clock_nodes:
			clock.call("advance", STEP)
			clock.set_process(false)
		for tween: Tween in _tweens:
			if tween.is_valid():
				tween.custom_step(STEP)
		if ticks.has(tick):
			await _frame(screen, directory, frames, tick)
	assert(frames.size() == 8)
	assert(
		not CoreUtil.to_bool(motion.get("active")), "action helper retires at the captured endpoint"
	)
	assert(_visible_overlays(motion) == 0, "last frame contains no surviving action overlay")
	if mode == "x1":
		_states[label] = {"action": kind, "before": before, "after": after}
	_write(
		directory.path_join("manifest.json"),
		{
			"production_revision": _revision,
			"reader_label": label,
			"action": kind,
			"mode": mode,
			"pixels": [PIXELS.x, PIXELS.y],
			"fixed_step": STEP,
			"duration": duration,
			"capture_duration": last_tick * STEP,
			"settled_ticks": 2,
			"sample_ticks": ticks,
			"frames": frames,
			"before": before,
			"after": after,
			"events": _events,
			"events_sha256": JSON.stringify(_events, "", true, true).sha256_text(),
			"fixture":
			(
				"Designed legal seed72 state; unchanged shipped definitions; actual RecruitScreen "
				+ "callback through CorePort/GameSession/RecruitRules. No synthetic timing or event."
			),
		}
	)
	print("declutter cold: ", label, "-", mode, " action=", kind, " duration=", duration)
	root.remove_child(screen)
	screen.free()
	await process_frame


func _freeze_clocks(node: Node) -> void:
	if node.has_method("advance"):
		node.set_process(false)
		_clock_nodes.append(node)
	for child: Node in node.get_children():
		_freeze_clocks(child)
	for tween: Tween in get_processed_tweens():
		if not _tweens.has(tween):
			tween.pause()
			_tweens.append(tween)


func _frame(screen: Control, directory: String, frames: Array[Dictionary], tick: int) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	assert(image.get_size() == PIXELS)
	var name: String = "frame-%03d.png" % frames.size()
	assert(image.save_png(directory.path_join(name)) == OK)
	var nodes: Array[Dictionary] = Capture.text_nodes(screen)
	var motion: Control = screen.get("_action_motion")
	frames.append(
		{
			"file": name,
			"tick": tick,
			"seconds": tick * STEP,
			"visible_text_count": nodes.size(),
			"visible_text_nodes": nodes,
			"shown_beads": _shown_beads(screen),
			"action_active": CoreUtil.to_bool(motion.get("active")),
			"visible_action_overlays": _visible_overlays(motion),
			"reach_values": _reach_values(screen)
		}
	)


func _visible_overlays(motion: Control) -> int:
	var count: int = 0
	for child: Node in motion.get_children():
		if child is Control:
			var overlay: Control = child
			if overlay.is_visible_in_tree() and overlay.modulate.a > 0.001:
				count += 1
	return count


func _reach_values(screen: Control) -> Dictionary:
	var board: Control = screen.get("_board")
	var slots: Array = board.get("slots")
	var target: Control = slots[5]
	var across: Control = slots[2]
	var quarry: Control = target.get("_quarry_stamp")
	var across_quarry: Control = across.get("_quarry_stamp")
	return {
		"expected_target5": target.get("reach_flash"),
		"straight_across2": across.get("reach_flash"),
		"target_quarry_visible": quarry.is_visible_in_tree() and quarry.modulate.a > 0.001,
		"straight_across_quarry_visible":
		across_quarry.is_visible_in_tree() and across_quarry.modulate.a > 0.001,
	}


func _shown_beads(node: Node) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	if node is CardView:
		var card: CardView = node as CardView
		var attack_label: Label = card.get("_attack_label")
		var health_label: Label = card.get("_health_label")
		found.append(
			{
				"iid": card.unit.get("iid", -1),
				"zone": card.zone,
				"visible": card.is_visible_in_tree(),
				"attack": attack_label.text,
				"health": health_label.text,
				"view_attack": card.unit.get("attack", 0),
				"view_health": card.unit.get("health", 0)
			}
		)
	for child: Node in node.get_children():
		found.append_array(_shown_beads(child))
	return found


func _resting_states() -> void:
	Settings.reduce_motion = true
	for pixels: Vector2i in [PIXELS, Vector2i(1920, 1080)]:
		_resize(pixels)
		for label: String in _states:
			for stage: String in ["before", "after"]:
				if (label.begins_with("spec-") or label == "fan10") and stage == "after":
					continue
				var pair: Dictionary = _states[label]
				var state: Dictionary = pair[stage]
				var port := FixturePort.new()
				port.set("_state", state.duplicate(true))
				var screen := RecruitScreen.new()
				root.add_child(screen)
				screen.setup(port)
				if label in ["D", "spec-scout"]:
					screen.toggle_scout()
				elif label == "spec-reader-reel_mistress-golden":
					var hand: Array = state["hand"]
					for index: int in hand.size():
						var view: Dictionary = hand[index]
						if str(view.get("def_id", "")) == "reel_mistress":
							screen._on_tapped("hand", index)
				for index: int in 10:
					await process_frame
				screen._clear_toast()
				await RenderingServer.frame_post_draw
				var path: String = (
					"technical/stills/%s-%s-%dx%d.png" % [label, stage, pixels.x, pixels.y]
				)
				DirAccess.make_dir_recursive_absolute(_out.path_join("technical/stills"))
				assert(root.get_texture().get_image().save_png(_out.path_join(path)) == OK)
				var nodes: Array[Dictionary] = Capture.text_nodes(screen)
				_rest.append(
					{
						"reader_label": label,
						"stage": stage,
						"reader_open": label == "spec-reader-reel_mistress-golden",
						"pixels": [pixels.x, pixels.y],
						"image": path,
						"state_sha256":
						JSON.stringify(_states[label][stage], "", true, true).sha256_text(),
						"visible_text_count": nodes.size(),
						"visible_text_nodes": nodes,
						"tile_words": Capture.tile_words(screen)
					}
				)
				root.remove_child(screen)
				screen.free()
				await process_frame


func _rules_pages() -> void:
	_resize(PIXELS)
	var guide := HowToPlay.new()
	root.add_child(guide)
	DirAccess.make_dir_recursive_absolute(_out.path_join("reader/rules"))
	for page: int in HowToPlay.PAGES.size():
		guide.page = page
		guide._show_page()
		for index: int in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		assert(
			(
				root.get_texture().get_image().save_png(
					_out.path_join("reader/rules/%02d.png" % [page + 1])
				)
				== OK
			)
		)
	root.remove_child(guide)
	guide.free()


func _write(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t", true, true) + "\n")
