extends SceneTree
## Renders one UI screen from real rules-core state and saves a native-size PNG. Needs a real
## renderer:
##   xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://tests/ui/shots/screenshot.gd -- <screen> <WxH> <out.png>
## Screens: menu, difficulty, settings, guide_1 to guide_8, recruit, recruit_select, recruit_triple
## (a dev-spawned triple), recruit_late (tier 6, full board and hand, through the dev panel),
## recruit_frozen, scout_live, scout_live_select, dev, pause, combat_mid, combat_end, sandbox,
## sandbox_scenarios, sandbox_fight, game_over. The human's turns are played by a bot (config
## human_bot) for a few rounds so the board has units. From test fixtures, with cards that aren't in
## the game's lobbies (tests/ui/data/README.md): recruit_spells, discover, hero_choice,
## recruit_slice, scout, pass_drag, ghost_next. render_screens.sh names those files fixture_*.
## tests/ui/render_screens.sh renders them all and converts them to JPEG.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const Data := preload("res://src/ui/view_data.gd")
const Records := preload("res://src/ui/records.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const HowToPlay := preload("res://src/ui/screens/how_to_play.gd")

const SEED: int = 20261104
const BOT_ROUNDS: int = 6
const GAME_OVER_ROUNDS: int = 60


func _initialize() -> void:
	Records.path = "user://screenshot_records.cfg"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("usage: -- <screen> <WxH> <out.png>")
		quit(2)
		return
	var dims: PackedStringArray = args[1].split("x")
	var window_size: Vector2i = Vector2i(int(dims[0]), int(dims[1]))
	DisplayServer.window_set_size(window_size)
	root.size = window_size
	@warning_ignore("missing_await")
	_run(args[0], window_size, args[2])


## A core game whose human is played by a bot for `rounds` rounds (or until it is out).
func _bot_game(app: App, rounds: int) -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("human_bot", "tribe")
	var port: CorePort = CorePort.new()
	port.setup(config)
	app.setup(port)
	# Cards and rules change, so a fixed seed may not survive: take the first that does.
	for attempt: int in 40:
		port.new_game(SEED + attempt)
		app.round_log.clear()
		for i: int in rounds:
			if port.is_over() or port.get_state().get("placement") != null:
				break
			port.end_turn()
			var combat: Dictionary = port.get_last_combat()
			var events: Array = Data.a(combat, "events")
			if not events.is_empty():
				var me: int = App.player_side(
					Data.entry(events, 0), Data.i(port.get_state(), "player_id", 0)
				)
				app.note_round(combat, me)
		if rounds >= GAME_OVER_ROUNDS or port.get_state().get("placement") == null:
			return


## A board that shows every held-unit mark: Bellies empty and full, a Nest bare and a Nest stood on,
## a bird that can fly and a bird just played, and an Ooze worth dropping things in.
func _stage_held(app: App) -> void:
	var port: CorePort = app.port as CorePort
	var session: GameSession = port.session
	var player: PlayerState = session._players[0]
	var library: UnitLibrary = session._rules.library
	var made: Callable = func(id: String) -> RecruitUnit:
		var unit: RecruitUnit = RecruitUnit.make(library.get_unit(id), session._rules.new_iid())
		unit.origin = RecruitUnit.ORIGIN_BOUGHT
		return unit
	for slot: int in player.board.size():
		player.board[slot] = null
	player.hand.clear()
	player.items.clear()
	var posset: RecruitUnit = made.call("mrs_posset")
	posset.held.append(made.call("mrs_sorrel"))
	var pie: RecruitUnit = made.call("sixpenny_pie")
	pie.held.append(made.call("pill_bug"))
	pie.held.append(made.call("mr_crumb"))
	player.board[0] = posset
	player.board[1] = pie
	player.board[3] = made.call("great_lump")
	player.board[4] = made.call("wee_wobbly")
	player.board[6] = made.call("mrs_jay")
	player.board[6].played_round = 1
	player.away.append(
		{"unit": made.call("old_tern"), "left": player.round_number, "due": player.round_number + 3, "nest": 2}
	)
	player.away.append(
		{"unit": made.call("mother_goose"), "left": player.round_number, "due": player.round_number + 1, "nest": 3}
	)
	player.hand.append(made.call("one_swallow"))
	player.hand.append(made.call("chiffchaff"))


func _stage_their_nests(app: App) -> void:
	var port: CorePort = app.port as CorePort
	var player: PlayerState = port.session._players[0]
	if player.scout.is_empty():
		return
	player.scout["nests"] = [0, 5]


## The first event where someone comes out of a Belly, or the middle of the fight.
func _first_out_of_belly(combat: CombatScreen) -> int:
	for index: int in combat.events.size():
		var event: Dictionary = Data.entry(combat.events, index)
		if event.has("came_out"):
			return index + 1
	return mini(9, combat.events.size() - 2)


func _play_until(combat: CombatScreen, index: int) -> void:
	combat.playing = true
	var frames: int = 0
	while combat.next_index < index and frames < 2000:
		await process_frame
		frames += 1
	for i: int in 22:
		await process_frame


func _run(screen_name: String, window_size: Vector2i, out_path: String) -> void:
	await process_frame
	var app: App = App.new()
	root.add_child(app)
	if screen_name.begins_with("guide_"):
		_plain_app(app)
		var guide: HowToPlay = app.open_guide()
		guide.page = screen_name.trim_prefix("guide_").to_int() - 1
		guide.call("_show_page")
		await _shoot(window_size, out_path)
		return
	match screen_name:
		"menu":
			_plain_app(app)
		"difficulty":
			_plain_app(app)
			(app.current as MainMenu).call("_open_chooser")
		"settings":
			_plain_app(app)
			app.open_settings()
		"recruit_spells", "discover", "hero_choice":
			var fixture: FixturePort = FixturePort.new()
			app.setup(fixture)
			fixture.use_state_file("res://tests/ui/data/recruit_heroes.json")
			if screen_name == "recruit_spells":
				var state: Dictionary = fixture.get_state()
				state.erase("pending_choice")
			if screen_name == "hero_choice":
				var offer: Dictionary = fixture.get_state()
				var hero: Dictionary = offer["hero"]
				offer["pending_choice"] = {"kind": "hero", "options": [hero, hero, hero]}
			app.show_recruit()
		"recruit_triple":
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var triple_screen: RecruitScreen = app.current as RecruitScreen
			var panel: Object = triple_screen.get("_dev")
			var ids: PackedStringArray = panel.get("_ids")
			var options: OptionButton = panel.get("_units")
			options.select(ids.find("field_vole"))
			for i: int in 3:
				panel.call("_on_spawn")
			var hand: Array = Data.a(app.port.get_state(), "hand")
			for i: int in hand.size():
				if Data.b(Data.entry(hand, i), "golden", false):
					triple_screen.call("_on_tapped", "hand", i)
		"recruit_late":
			# Tier 6 through the dev panel: tier 4-6 units (every third golden) fill the board, then
			# the hand.
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var late_screen: RecruitScreen = app.current as RecruitScreen
			var late_panel: Object = late_screen.get("_dev")
			var tier_box: SpinBox = late_panel.get("_tier")
			tier_box.value = 6
			late_panel.call("_on_set_tier")
			var late_options: OptionButton = late_panel.get("_units")
			var golden_box: CheckBox = late_panel.get("_golden")
			var picks: Array[int] = []
			for i: int in late_options.item_count:
				if late_options.get_item_text(i).substr(1, 1).to_int() >= 4:
					picks.append(i)
			for round_trip: int in 2:
				for i: int in 12:
					late_options.select(picks[(i * 5 + round_trip * 3) % picks.size()])
					golden_box.button_pressed = i % 3 == 0
					late_panel.call("_on_spawn")
				if round_trip == 0:
					for i: int in 7:
						var state: Dictionary = app.port.get_state()
						var board: Array = Data.a(state, "board")
						var empty: int = board.find(null)
						if empty < 0 or Data.a(state, "hand").is_empty():
							break
						late_screen.call("_on_tapped", "hand", 0)
						late_screen.call("_on_tapped", "board", empty)
		"recruit_held", "recruit_held_ooze", "recruit_held_bird", "scout_held":
			_bot_game(app, BOT_ROUNDS)
			_stage_held(app)
			app.show_recruit()
			var held: RecruitScreen = app.current as RecruitScreen
			if screen_name == "recruit_held_ooze":
				held.call("_on_tapped", "board", 1)
			elif screen_name == "recruit_held_bird":
				held.call("_on_tapped", "board", 6)
			elif screen_name == "scout_held":
				_stage_their_nests(app)
				held.render()
				held.toggle_scout()
		"combat_held":
			_bot_game(app, BOT_ROUNDS)
			_stage_held(app)
			var held_port: CorePort = app.port as CorePort
			held_port.end_turn()
			app.show_game_combat()
			var held_combat: CombatScreen = app.current as CombatScreen
			held_combat.playing = false
			for i: int in 3:
				await process_frame
			await _play_until(held_combat, _first_out_of_belly(held_combat))
		"scout_live":
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			(app.current as RecruitScreen).toggle_scout()
		"scout_live_select":
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var scouting: RecruitScreen = app.current as RecruitScreen
			scouting.toggle_scout()
			scouting.call("_on_tapped", "scout", 1)
		"recruit", "recruit_select", "recruit_frozen", "dev", "pause":
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var recruit: RecruitScreen = app.current as RecruitScreen
			if screen_name == "recruit_select":
				recruit.call("_on_tapped", "shop", 0)
			elif screen_name == "recruit_frozen":
				recruit.call("_on_freeze")
			elif screen_name == "pause":
				recruit.call("_open_pause")
			elif screen_name == "dev":
				recruit.toggle_dev_panel()
				var dev: Object = recruit.get("_dev")
				dev.call("_on_add_gold")
		"combat_mid", "combat_end":
			_bot_game(app, BOT_ROUNDS)
			app.show_game_combat()
			var combat: CombatScreen = app.current as CombatScreen
			combat.playing = false
			for i: int in 3:
				await process_frame
			if screen_name == "combat_end":
				combat.skip_to_end()
			else:
				await _play_until(combat, mini(9, combat.events.size() - 2))
		"sandbox_scenarios":
			var scenario_port: CorePort = CorePort.new()
			scenario_port.setup()
			app.setup(scenario_port)
			app.show_sandbox()
			app.sandbox.show_tab("Scenarios")
			app.sandbox.load_scenario("nightshade_tall")
		"sandbox", "sandbox_fight":
			var port: CorePort = CorePort.new()
			port.setup()
			app.setup(port)
			app.show_sandbox()
			var sandbox: SandboxScreen = app.sandbox
			sandbox.place(1, 0, "stoat_captain", false)
			sandbox.place(1, 1, "old_badger", true)
			sandbox.place(1, 2, "sett_warden", false)
			sandbox.place(1, 5, "fairy_monarch", false)
			sandbox.place(0, 1, "hoglet_mother", false)
			sandbox.place(0, 2, "bitter_toad", false)
			sandbox.place(0, 5, "belladonna_sprite", false)
			sandbox.place(1, 3, "hedge_witch", false)
			sandbox.place(0, 3, "garden_snail", false)
			sandbox.set_stats(1, 1, 40, 70)
			if screen_name == "sandbox":
				sandbox.call("_on_tapped", "enemy", 1)
			else:
				sandbox.call("_on_fight")
				var fight: CombatScreen = app.current as CombatScreen
				fight.playing = false
				for i: int in 3:
					await process_frame
				await _play_until(fight, mini(8, fight.events.size() - 2))
		"recruit_slice", "scout", "pass_drag", "ghost_next":
			var slice: FixturePort = FixturePort.new()
			app.setup(slice)
			slice.use_state_file("res://tests/ui/data/recruit_slice.json")
			if screen_name == "ghost_next":
				_make_next_a_ghost(slice.get_state())
			app.show_recruit()
			var slice_screen: RecruitScreen = app.current as RecruitScreen
			if screen_name == "scout" or screen_name == "ghost_next":
				slice_screen.toggle_scout()
				slice_screen.call("_clear_toast")
			elif screen_name == "pass_drag":
				slice_screen.show_pass_preview("board", 0, "board", 0)
		"new_game", "new_game_2":
			_plain_app(app)
			app.start_game(SEED)
			if screen_name == "new_game_2":
				app.port.call("choose", 0)
				(app.current as RecruitScreen).render()
		"game_over":
			_bot_game(app, 60)
			app.show_recruit()
		_:
			printerr("unknown screen: %s" % screen_name)
			quit(2)
			return
	await _shoot(window_size, out_path)


## The fixture's next opponent is out, and its board is what the player meets next.
func _make_next_a_ghost(state: Dictionary) -> void:
	var next_id: int = Data.i(state, "next_opponent_id")
	for entry: Variant in Data.a(state, "standings"):
		var standing: Dictionary = entry
		if Data.i(standing, "player_id", -2) == next_id:
			standing["alive"] = false
			standing["placement"] = 5
			standing["health"] = 0
	state["next_opponent_id"] = -1
	state["next_opponent_hero"] = null


func _plain_app(app: App) -> void:
	var port: CorePort = CorePort.new()
	port.setup()
	app.setup(port)


func _shoot(window_size: Vector2i, out_path: String) -> void:
	for i: int in 20:
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image.get_size() != window_size:
		printerr("screenshot: got %s, wanted %s" % [image.get_size(), window_size])
		quit(1)
		return
	image.save_png(out_path)
	print("screenshot: saved %s %s" % [out_path, image.get_size()])
	quit(0)
