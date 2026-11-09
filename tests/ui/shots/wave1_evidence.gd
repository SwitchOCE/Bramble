extends SceneTree
## Full-window evidence from production UI and a controlled, real-rules scenario.
## Every staged unit uses the production dev spawn; all flights, Rings and returns use rules.
## Run under the shared flock/systemd MemoryMax=3G wrapper, with a real xvfb renderer.
##   godot ... -s res://tests/ui/shots/wave1_evidence.gd -- <WxH> <output directory>

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const Records := preload("res://src/ui/records.gd")

var _app: App
var _port: CorePort
var _window: Vector2i
var _out: String
var _seed: int = 101
var _actions: Array[Dictionary] = []
var _captures: Array[Dictionary] = []
var _problems: PackedStringArray = []
var _before_flight: Dictionary = {}
var _home_log: Array = []
var _include_natural: bool = false


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() not in [2, 3]:
		printerr("usage: -- <WxH> <output directory> [--natural]")
		quit(2)
		return
	var dims: PackedStringArray = args[0].split("x")
	_window = Vector2i(int(dims[0]), int(dims[1]))
	_out = args[1]
	_include_natural = args.has("--natural")
	DirAccess.make_dir_recursive_absolute(_out)
	DisplayServer.window_set_size(_window)
	root.size = _window
	CardView.window_override = Vector2(_window)
	Records.path = "user://wave1_evidence_records.cfg"
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	await process_frame
	_app = App.new()
	root.add_child(_app)
	_port = CorePort.new()
	_port.setup(GameConfig.full_game())
	_app.setup(_port)
	_find_shop()
	_app.show_recruit()
	await _capture(
		"shop-birds-fairies",
		{
			"criterion": "Natural turn-1 shop offers both tribes.",
			"mode": "Natural full-game turn-1 shop; no dev actions before this capture."
		}
	)
	_stage_board()
	_app.show_recruit()
	var away: Array = _port.get_state()["away"]
	_require(away.size() == 2, "mixed board has two genuinely flown Birds")
	_require(_port.session._players[0].ring_size == 1.25, "Cluricaun grew Rings on a real tier-up")
	await _capture(
		"ring-carry-away-birds",
		{
			"criterion":
			"Ring carry, half-stat Fetch overlay and two away Birds with Nest countdowns.",
			"permanent_before_flight": _before_flight,
		}
	)
	var recruit: RecruitScreen = _app.current as RecruitScreen
	recruit._on_tapped("board", 3)
	var detail: CardDetail = recruit.get("_detail")
	_require(str(detail.shown.get("name", "")) == "Egg", "bare Nest opens Egg reader")
	await _capture(
		"away-nest-reader",
		{
			"criterion":
			"Tap the bare Jay Nest: production Egg reader gives current Bird and countdown.",
			"interaction": ["tap board F4"],
		}
	)
	recruit._on_tapped("table", -1)
	_require(
		not detail.visible and detail.shown.is_empty(),
		"clearing selection hides reader despite away Birds"
	)
	await _capture(
		"away-sky-preview-gap",
		{
			"criterion":
			"Observed gap: clearing selection with two Birds away hides reader; no current-to-home tray.",
			"interaction": ["tap board F4", "tap empty table"],
			"observed_issue":
			"RecruitScreen._show_sky() calls CardDetail.show_empty(); sky_card() is not displayed.",
		}
	)
	_expect(_port.end_turn(), "end turn 2: both away Birds miss their first fight")
	var returned: Dictionary = _find_hand("one_swallow")
	_require(not returned.is_empty(), "one-turn Swallow comes home at Start of Turn 3")
	_require(
		CoreUtil.to_int(returned.get("attack")) == 14, "Swallow permanent Attack doubles 7 to 14"
	)
	_require(
		CoreUtil.to_int(returned.get("health")) == 16, "Swallow permanent Health doubles 8 to 16"
	)
	_home_log = _port.get_state()["recruit_log"]
	var home_seen: bool = false
	for event: Dictionary in _home_log:
		if str(event.get("type", "")) == "home" and str(event.get("unit", "")) == "one_swallow":
			home_seen = true
	_require(home_seen, "home event exists in the real Start of Turn log")
	_app.show_recruit()
	await _capture(
		"homecoming-return",
		{
			"criterion":
			"Real Start of Turn homecoming: 7/8 Swallow is 14/16 in hand; Jay remains away.",
			"homecoming_phase": "Start of Turn, before Start of Turn effects; not during combat.",
			"home_events": _home_log,
		}
	)
	_play_hand_id("one_swallow", 3)
	_expect(_port.end_turn(), "end turn 3: fight with the returned Swallow")
	var fight: Dictionary = _port.get_last_combat()
	_require(CoreUtil.to_int(fight.get("round")) == 3, "following combat is turn 3")
	_write("screenshots-homecoming-combat.json", fight)
	_app.show_game_combat()
	var screen: CombatScreen = _app.current as CombatScreen
	screen.playing = false
	var seen_swallow: bool = false
	for event: Dictionary in screen.events:
		if str(event.get("type", "")) == "attack":
			break
		screen._play_event(event, false)
		screen.next_index += 1
	# The first combat_start snapshot gives the strongest engine assertion independent of UI internals.
	var start: Dictionary = screen.events[0]
	for spec: Variant in start["boards"][0]:
		if spec != null:
			var unit: Dictionary = spec
			if str(unit.get("def_id", "")) == "one_swallow":
				seen_swallow = true
	_require(seen_swallow, "returned Swallow participates in the following combat")
	await _capture(
		"homecoming-following-combat",
		{
			"criterion": "Following combat includes the returned Swallow before attacks begin.",
			"stat_explanation":
			"Swallow's permanent body remains 14/16; its destination's 3/3 Ring adds combat stats.",
			"combat_round": 3,
			"homecoming_phase": "The return occurred at Start of Turn 3, before this combat.",
		}
	)
	await _readers()
	await _natural_checkpoints()
	_write(
		"screenshots-" + _dimensions() + ".json",
		{
			"source_checkpoint": "6a54286",
			"render_command_template":
			(
				"source /opt/bramble/env.sh; flock /tmp/bramble-godot.lock "
				+ "systemd-run --user --scope -p MemoryMax=3G timeout 240 "
				+ "xvfb-run -a -s '-screen 0 2560x1440x24' "
				+ "godot --rendering-driver opengl3 --audio-driver Dummy "
				+ "-s res://tests/ui/shots/wave1_evidence.gd -- "
				+ _dimensions()
				+ " docs/ideation/evidence/wave1 --natural"
			),
			"mode":
			"Controlled production-UI scenario plus explicitly named natural tools/play checkpoints.",
			"seed": _seed,
			"window": [_window.x, _window.y],
			"actions": _actions,
			"captures": _captures,
			"problems": Array(_problems),
			"visual_notes":
			[
				"At phone size with the reader open, the large B1 Ring badge covers part of the B1 slot name.",
				"The phone End turn subtitle sits at the lower edge and is partially clipped.",
				(
					"Cluricaun displays Ring +0 for +0.25 growth. "
					+ "See natural-fairies-ring-carry-1920x1080.png; "
					+ "src/ui/widgets/card_view.gd:211 uses an integer-only regex."
				),
				"On PC, long shop names such as His Highness and Jenny wrap into stat-badge space.",
				(
					"Nest countdown badges work, but no current-to-landing tray appears. "
					+ "RecruitScreen._show_sky calls show_empty()."
				),
			],
			"longest_selection":
			(
				"All 64 faces; whitespace words, count descending then card ID; unique cards. "
				+ "Golden Mag Pye 18, golden Reel-Mistress 18, golden Cradle Fetch 17. "
				+ "Normal Jack Daw ties at 17 and is a fourth capture."
			),
		}
	)
	print("wave1 screenshots: ", _captures.size(), " captures; ", _problems.size(), " layout notes")
	quit(0 if _problems.is_empty() else 1)


func _find_shop() -> void:
	for candidate: int in range(101, 141):
		_expect(_port.new_game(candidate), "new game seed %d" % candidate)
		_expect(_port.choose(0), "choose first offered hero")
		var tribes: Dictionary = {}
		for card: Dictionary in _port.get_state()["shop"]:
			for tribe: String in card["tribes"]:
				tribes[tribe] = true
		if tribes.has("Birds") and tribes.has("Fairies"):
			_seed = candidate
			_actions.clear()
			_actions.append(
				{
					"action": "new",
					"seed": _seed,
					"selection": "first seed from 101 with both tribes naturally offered at turn 1"
				}
			)
			_actions.append({"action": "choose", "index": 0})
			_require(CoreUtil.to_int(_port.get_state()["round"]) == 1, "natural shop is turn 1")
			return
	_require(false, "could not find natural mixed shop among seeds 101..140")


func _stage_board() -> void:
	_expect(_port.dev_set_tier(3), "controlled dev: set tier 3")
	_expect(_port.dev_add_gold(200), "controlled dev: add setup gold")
	for pair: Array in [
		["old_moth_annis", 0],
		["cradle_fetch", 1],
		["one_swallow", 2],
		["mrs_jay", 3],
		["hedge_witch", 4],
		["mr_redbreast", 5],
		["cluricaun", 6]
	]:
		_spawn(str(pair[0]), CoreUtil.to_int(pair[1]))
	for slot: int in BoardGeometry.SLOTS:
		_cast_created("spore_cloud", slot)
	for _index: int in 10:
		_cast_created("boundary_stone", 4)
	for _index: int in 6:
		_cast_created("pinch_of_dust", 2)
	for _index: int in 4:
		_cast_created("pinch_of_dust", 3)
	_expect(_port.tier_up(), "real tier-up triggers Cluricaun growth from 1 to 1.25")
	_expect(_port.end_turn(), "end turn 1: all staged Birds actually fight at home")
	var owner: PlayerState = _port.session._players[0]
	for slot: int in [2, 3]:
		var bird: RecruitUnit = owner.board[slot]
		_before_flight[bird.def_id()] = {
			"attack": bird.base_attack_now() + bird.perm_attack,
			"health": bird.base_health_now() + bird.perm_health,
			"excludes": "slot Ring aura and all non-permanent layers",
		}
	_expect(_port.sell(2), "real sale: Swallow flies for one turn")
	_expect(_port.sell(3), "real sale: Jay flies for two turns")
	_spawn("great_lump", 2)
	_expect(_port.sell(6), "sell tier-up grower after its growth")
	_spawn("hob_in_the_hearth", 6)
	var state: Dictionary = _port.get_state()
	_expect(
		_port.dev_add_gold(10 - CoreUtil.to_int(state["gold"])),
		"controlled dev: normalize displayed gold to 10"
	)
	_actions.append(
		{
			"board_note":
			(
				"Units: production dev-spawn and ordinary play. "
				+ "Spells: created for setup, then ordinary play_item. "
				+ "No snapshot stats were assigned."
			)
		}
	)


func _spawn(id: String, slot: int, golden: bool = false) -> void:
	_expect(_port.dev_spawn_to_hand(id, golden), "controlled dev spawn %s golden=%s" % [id, golden])
	_play_hand_id(id, slot)


func _play_hand_id(id: String, slot: int) -> void:
	var hand: Array = _port.get_state()["hand"]
	for index: int in hand.size():
		var unit: Dictionary = hand[index]
		if str(unit["def_id"]) == id:
			_expect(_port.play(index, slot), "play %s at %s" % [id, BoardGeometry.LABELS[slot]])
			return
	_require(false, "hand lacks " + id)


func _cast_created(id: String, slot: int) -> void:
	var player: PlayerState = _port.session._players[0]
	_port.session._rules.give_card(player, id)
	_expect(
		_port.play_item(player.items.size() - 1, slot),
		"created setup spell %s at %s" % [id, BoardGeometry.LABELS[slot]]
	)


func _find_hand(id: String) -> Dictionary:
	for unit: Dictionary in _port.get_state()["hand"]:
		if str(unit["def_id"]) == id:
			return unit
	return {}


func _readers() -> void:
	for pair: Array in [
		["mag_pye", true, 18],
		["reel_mistress", true, 18],
		["cradle_fetch", true, 17],
		["jack_daw", false, 17]
	]:
		var id: String = str(pair[0])
		var golden: bool = CoreUtil.to_bool(pair[1])
		_expect(
			_port.dev_spawn_to_hand(id, golden),
			"controlled reader specimen %s golden=%s" % [id, golden]
		)
		_app.show_recruit()
		var recruit: RecruitScreen = _app.current as RecruitScreen
		var hand: Array = _port.get_state()["hand"]
		var at: int = -1
		for index: int in hand.size():
			var unit: Dictionary = hand[index]
			if str(unit["def_id"]) == id and CoreUtil.to_bool(unit["golden"]) == golden:
				at = index
		_require(at >= 0, "reader specimen exists in real hand")
		recruit._on_tapped("hand", at)
		recruit._clear_toast()
		var card: Dictionary = hand[at]
		_require(
			str(card["text"]).split(" ", false).size() == CoreUtil.to_int(pair[2]),
			"measured text length for " + id
		)
		await _capture(
			"reader-" + id + ("-golden" if golden else ""),
			{
				"criterion": "Production full card reader, exact current authored text.",
				"card_id": id,
				"golden": golden,
				"words": pair[2],
				"text": card["text"],
			}
		)


func _natural_checkpoints() -> void:
	if not _include_natural:
		return
	var first_home_round: int = -1
	for label: String in ["mixed_shop", "ring_and_away", "first_homecoming"]:
		var filename: String = "birds-checkpoint-" + label + ".json"
		var path: String = _out.path_join(filename)
		if not FileAccess.file_exists(path):
			continue
		var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var game := PlayGame.from_save(save)
		_require(game.load_error.is_empty(), "replay natural checkpoint " + filename)
		_port.session = game.session
		_port.library = game._library
		_port.config = game.session._config
		_app.show_recruit()
		var state: Dictionary = _port.get_state()
		if label == "mixed_shop":
			var tribes: Dictionary = {}
			for card: Dictionary in state["shop"]:
				for tribe: String in card["tribes"]:
					tribes[tribe] = true
			_require(
				tribes.has("Birds") and tribes.has("Fairies"),
				"natural mixed shop offers both tribes"
			)
		elif label == "ring_and_away":
			var has_ring: bool = false
			for effects: Array in state["slot_effects"]:
				has_ring = has_ring or BoardUpkeep.has_ring(effects)
			var away: Array = state["away"]
			_require(
				has_ring and not away.is_empty(), "natural real board has Rings and away Birds"
			)
		else:
			var seen: bool = false
			for event: Dictionary in state["recruit_log"]:
				seen = seen or str(event.get("type", "")) == "home"
			_require(seen, "natural first-homecoming checkpoint contains real home event")
			first_home_round = CoreUtil.to_int(state["round"])
		await _capture(
			"natural-birds-" + label.replace("_", "-"),
			{
				"mode": "Natural tools/play full-game checkpoint; no dev actions or staged cards.",
				"checkpoint": filename,
				"checkpoint_actions": game.actions.size(),
				"checkpoint_seed": game.seed_value,
				"criterion": "Exact replay of the committed Birds player's accepted commands.",
			}
		)

	var following_path: String = _out.path_join("birds-checkpoint-homecoming_following_fight.json")
	if first_home_round >= 0 and FileAccess.file_exists(following_path):
		var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(following_path))
		var game := PlayGame.from_save(save)
		_require(game.load_error.is_empty(), "replay natural following-fight checkpoint")
		_port.session = game.session
		_port.library = game._library
		_port.config = game.session._config
		var fight: Dictionary = _port.get_last_combat()
		_require(
			CoreUtil.to_int(fight["round"]) == first_home_round,
			"natural following fight comes after same-turn homecoming"
		)
		var first: Dictionary = fight["events"][0]
		var our_board: Array = first["boards"][0]
		var returned_fights: bool = false
		var returned_spec: Dictionary = {}
		for spec: Variant in our_board:
			if spec != null:
				var unit: Dictionary = spec
				if str(unit.get("def_id", "")) == "chiffchaff":
					returned_fights = true
					returned_spec = unit
		_require(
			returned_fights, "naturally returned Chiffchaff participates in true following combat"
		)
		_app.show_game_combat()
		var screen: CombatScreen = _app.current as CombatScreen
		screen.playing = false
		for event: Dictionary in screen.events:
			if str(event.get("type", "")) == "attack":
				break
			screen._play_event(event, false)
			screen.next_index += 1
		await _capture(
			"natural-birds-homecoming-following-combat",
			{
				"mode": "Natural tools/play following combat; no dev actions or staged cards.",
				"checkpoint": "birds-checkpoint-homecoming_following_fight.json",
				"checkpoint_actions": game.actions.size(),
				"criterion":
				"Return occurs at Start of Turn 5; this is actual turn-5 fight, not the previous turn-4 fight.",
				"returned_bird_combat_view": returned_spec,
				"stat_explanation":
				(
					"Chiffchaff returns 4/6; replay adds +1/+1. "
					+ "Destination Rings add a separate combat layer."
				),
			}
		)
	var fairy_path: String = _out.path_join("fairies-checkpoint-ring_carry.json")
	if FileAccess.file_exists(fairy_path):
		var save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fairy_path))
		var game := PlayGame.from_save(save)
		_require(game.load_error.is_empty(), "replay natural Fairy Ring carry")
		_port.session = game.session
		_port.library = game._library
		_port.config = game.session._config
		_app.show_recruit()
		await _capture(
			"natural-fairies-ring-carry",
			{
				"mode":
				"Natural tools/play committed-Fairies checkpoint; no dev actions or staged cards.",
				"checkpoint": "fairies-checkpoint-ring_carry.json",
				"checkpoint_actions": game.actions.size(),
				"criterion": "Naturally acquired Fairy board and permanent Ring carry.",
			}
		)


func _capture(name: String, details: Dictionary) -> void:
	if _app.current is RecruitScreen:
		(_app.current as RecruitScreen)._clear_toast()
	for _frame: int in 20:
		await process_frame
	var image: Image = root.get_texture().get_image()
	_require(image.get_size() == _window, "native full-window resolution for " + name)
	var filename: String = name + "-" + _dimensions() + ".png"
	_require(image.save_png(_out.path_join(filename)) == OK, "save screenshot " + filename)
	var notes: PackedStringArray = LayoutCheck.problems(_app.current, name, false)
	for note: String in notes:
		_problems.append(note)
	details["mode"] = details.get("mode", "Controlled real-rules production-UI scenario.")
	details["file"] = filename
	details["seed"] = _port.get_seed()
	details["pixels"] = [_window.x, _window.y]
	details["viewport_rect"] = str(root.get_visible_rect())
	details["screen_rect"] = str(_app.current.get_global_rect())
	details["actions_through"] = details.get("checkpoint_actions", _actions.size())
	details["state"] = _port.get_state()
	details["layout_notes"] = Array(notes)
	_captures.append(details)
	print("wave1 screenshot: ", filename)


func _expect(problem: String, action: String) -> void:
	_actions.append({"action": action, "result": problem})
	_require(problem.is_empty(), action + ": " + problem)


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error("wave1 screenshot assertion: " + message)
		quit(2)
		assert(condition, message)


func _dimensions() -> String:
	return "%dx%d" % [_window.x, _window.y]


func _write(filename: String, value: Dictionary) -> void:
	var output := FileAccess.open(_out.path_join(filename), FileAccess.WRITE)
	output.store_string(JSON.stringify(value, "  "))
