extends SceneTree
## Renders one UI screen from real rules-core state and saves a native-size PNG. Needs a real
## renderer:
##   xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://tests/ui/shots/screenshot.gd -- <screen> <WxH> <out.png>
## Screens: menu, menu_records, settings, guide_1 to guide_14, recruit, recruit_select,
## recruit_triple
## (a dev-spawned triple), recruit_late (tier 6, full board and hand, through the dev panel),
## recruit_frozen, scout_live, scout_live_select, dev, pause, combat_mid, combat_end, sandbox,
## sandbox_scenarios, sandbox_fight, game_over. The human's turns are played by a bot (config
## human_bot) for a few rounds so the board has units. From test fixtures, with cards that aren't in
## the game's lobbies (tests/ui/data/README.md): recruit_spells, discover, hero_choice,
## recruit_slice, scout, pass_drag, ghost_next. render_screens.sh names those files fixture_*.
## clarity_discover_live is a tier-4 Discover from the real pool.
## commit_bonus, commit_harvest and commit_<unit id> stage the commitment package.
## tests/ui/render_screens.sh renders them all and converts them to JPEG.
## Dev-only: BACKDROP=<image path> replaces table backgrounds with a centered cover image.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const Data := preload("res://src/ui/view_data.gd")
const Records := preload("res://src/ui/records.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const CommitmentStates := preload("res://tests/ui/commitment_states.gd")
const HowToPlay := preload("res://src/ui/screens/how_to_play.gd")
const TableBackground := preload("res://src/ui/widgets/table_background.gd")

const ReviewBogStates := preload("res://tests/ui/review_bog_states.gd")
const LaneStates := preload("res://tests/ui/lane_states.gd")

const SEED: int = 20261104
const BOT_ROUNDS: int = 6
const GAME_OVER_ROUNDS: int = 60
const FULL_HAND_IDS: Array[String] = [
	"mrs_mallow",
	"grey_agnes",
	"wee_wobbly",
	"mrs_jay",
	"lantern_man",
	"lob_lie_by_the_fire",
	"pill_bug",
	"toll_bard",
	"chiffchaff",
	"mrs_burdock",
]

var _backdrop: ImageTexture


func _initialize() -> void:
	Records.path = "user://screenshot_records.cfg"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("usage: -- <screen> <WxH> <out.png>")
		quit(2)
		return
	var backdrop_path: String = OS.get_environment("BACKDROP")
	if not backdrop_path.is_empty():
		var backdrop_image: Image = Image.new()
		if backdrop_image.load(backdrop_path) != OK:
			printerr("screenshot: cannot load BACKDROP: %s" % backdrop_path)
			quit(2)
			return
		_backdrop = ImageTexture.create_from_image(backdrop_image)
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


## Keep recruit art/layout comparisons on the same full ten-card pool-unit reserve.
func _stage_full_hand(app: App) -> void:
	var port: CorePort = app.port as CorePort
	var player: PlayerState = port.session._players[0]
	player.hand.clear()
	for id: String in FULL_HAND_IDS:
		var definition: Dictionary = port.library.get_unit(id)
		assert(Data.b(definition, "pool"), "shot hand must use pool units: " + id)
		var unit: RecruitUnit = RecruitUnit.make(definition, port.session._rules.new_iid())
		unit.origin = RecruitUnit.ORIGIN_BOUGHT
		player.hand.append(unit)
	assert(player.hand.size() == 10)
	print("screenshot: staged ten pool units in hand: ", FULL_HAND_IDS)


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
		{
			"unit": made.call("old_tern"),
			"left": player.round_number,
			"due": player.round_number + 3,
			"nest": 2
		}
	)
	player.away.append(
		{
			"unit": made.call("mother_goose"),
			"left": player.round_number,
			"due": player.round_number + 1,
			"nest": 3
		}
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
	if screen_name.begins_with("clarity_"):
		_plain_app(app)
		app.start_game(SEED)
		var port: CorePort = app.port as CorePort
		port.choose(0)
		var player: PlayerState = port.session._players[0]
		player.board.fill(null)
		if screen_name == "clarity_income":
			player.gold = 10
		player.board[0] = RecruitUnit.make(port.library.get_unit("mr_crumb"), 901)
		player.board[0].origin = RecruitUnit.ORIGIN_BOUGHT
		player.board[4] = RecruitUnit.make(port.library.get_unit("mrs_burdock"), 902)
		app.show_recruit()
		var screen: RecruitScreen = app.current as RecruitScreen
		if screen_name == "clarity_sell":
			screen.call("_on_tapped", "board", 0)
		elif screen_name == "clarity_buy":
			screen.call("_on_tapped", "shop", 0)
		elif screen_name == "clarity_discover":
			var cards: Array[Dictionary] = [
				port.library.get_unit("mrs_burdock"), port.library.get_unit("mr_crumb")
			]
			port.session._rules.pool = UnitPool.from_cards(
				cards, port.config, "pool_copies_by_tier", PackedStringArray()
			)
			port.session._rules.discover(player, {"count": 3, "tier": 2})
			screen.render()
		elif screen_name == "clarity_discover_live":
			# A Discover from the real pool: the cards a player meets, unlike the fixture's.
			port.session._rules.discover(player, {"count": 3, "tier": 4})
			screen.render()
		elif screen_name == "clarity_pack":
			var picker := preload("res://src/ui/widgets/card_picker.gd").new()
			screen.add_child(picker)
			var views: Array = [
				preload("res://src/ui/unit_views.gd").from_def(
					port.library.get_unit("brother_wolf")
				)
			]
			picker.show_cards("Discover: pick one", views, false)
		screen.call("_clear_toast")
		await _shoot(window_size, out_path)
		return
	if screen_name.begins_with("engines_"):
		_bot_game(app, 0)
		var port: CorePort = app.port as CorePort
		var session: GameSession = port.session
		for player: PlayerState in session._players:
			player.board.fill(null)
		if screen_name != "engines_lobby_locked":
			for index: int in range(4, 8):
				session._players[index].alive = false
		session._players[0].health = 5
		session._players[1].tier = 6
		session._players[1].board[0] = RecruitUnit.make(port.library.get_unit("mrs_burdock"), 900)
		if screen_name == "engines_blow":
			session._players[0].board[0] = RecruitUnit.make(
				port.library.get_unit("mrs_burdock"), 901
			)
			session._players[1].board[0].perm_attack = 0
			session._players[1].board[0].perm_health = 0
			session._players[0].health = 40
		session._fight(0, 1, session._damage_cap())
		if screen_name.begins_with("engines_lobby"):
			session._players[2].last_stand_used = true
			if screen_name == "engines_lobby":
				for tribe: String in session._lobby_tribes:
					session._players[0].tribe_bonuses[tribe] = 3
			session._pairings = [[0, 1], [2, 3], [4, 5], [6, 7]]
			app.show_recruit()
		elif screen_name == "engines_hero":
			app.show_recruit()
			app.current.call("_on_hero_tapped")
		else:
			app.show_game_combat()
			(app.current as CombatScreen).skip_to_end()
		await _shoot(window_size, out_path)
		return
	if screen_name.begins_with("commit_"):
		_bot_game(app, 0)
		CommitmentStates.stage(app.port as CorePort, screen_name)
		app.show_recruit()
		var screen: RecruitScreen = app.current as RecruitScreen
		if screen_name not in ["commit_bonus", "commit_nest_tile"]:
			screen.call(
				"_on_tapped",
				"hand" if screen_name == "commit_harvest" else "board",
				2 if screen_name == "commit_nest" else 0
			)
		screen.call("_clear_toast")
		await _shoot(window_size, out_path)
		return
	if screen_name.begins_with("guide_"):
		_plain_app(app)
		var guide: HowToPlay = app.open_guide()
		guide.page = screen_name.trim_prefix("guide_").to_int() - 1
		guide.call("_show_page")
		await _shoot(window_size, out_path)
		return
	if (
		screen_name
		in [
			"recruit_bog_preview",
			"recruit_bog_preview_select",
			"recruit_bog_preview_wall",
			"scout_bog_preview"
		]
	):
		var bog_port: FixturePort = FixturePort.new()
		app.setup(bog_port)
		bog_port.use_state_file("res://tests/ui/data/recruit_slice.json")
		ReviewBogStates.recruit(bog_port.get_state())
		app.show_recruit()
		var bog_screen: RecruitScreen = app.current as RecruitScreen
		if screen_name == "scout_bog_preview":
			bog_screen.toggle_scout()
		if screen_name == "recruit_bog_preview_select":
			bog_screen.call("_on_tapped", "board", 4)
		elif screen_name == "recruit_bog_preview_wall":
			bog_screen.call("_on_tapped", "board", 1)
		bog_screen.call("_clear_toast")
		await _shoot(window_size, out_path)
		return
	match screen_name:
		"feedback5_log":
			_plain_app(app)
			var feedback_fight := CombatScreen.new()
			app.add_child(feedback_fight)
			feedback_fight.setup(
				preload("res://tests/ui/feedback5_states.gd").fight(),
				PackedStringArray(["You", "Opponent"]),
				0,
				"Round 5"
			)
			feedback_fight.playing = false
			for event: Dictionary in feedback_fight.events:
				feedback_fight._play_event(event, false)
		"scout_lanes", "scout_lanes_select", "recruit_poached":
			var lane_port: FixturePort = FixturePort.new()
			app.setup(lane_port)
			lane_port.use_state_file("res://tests/ui/data/recruit_slice.json")
			LaneStates.recruit(lane_port.get_state())
			app.show_recruit()
			var lane_screen: RecruitScreen = app.current as RecruitScreen
			if screen_name != "recruit_poached":
				lane_screen.toggle_scout()
			if screen_name == "scout_lanes_select" or screen_name == "recruit_poached":
				lane_screen.call("_on_tapped", "shop", 0)
			lane_screen.call("_clear_toast")
		"combat_lanes", "combat_lanes_after":
			_plain_app(app)
			var lane_fight: CombatScreen = CombatScreen.new()
			app.add_child(lane_fight)
			lane_fight.setup(
				LaneStates.fight(screen_name == "combat_lanes_after"),
				PackedStringArray(["You", "Opponent"]),
				0,
				"Round 8"
			)
			lane_fight.skip_to_end()
			lane_fight.playing = false
		"menu", "menu_records":
			DirAccess.remove_absolute(Records.path)
			if screen_name == "menu_records":
				Records.add_game(3)
				Records.add_game(1)
				Records.add_game(2)
			_plain_app(app)
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
			options.select(ids.find("mrs_burdock"))
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
			_stage_full_hand(app)
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
		"reminder":
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var reading: RecruitScreen = app.current as RecruitScreen
			var detail: Control = reading.get("_detail")
			var shop: Array = reading.state.get("shop", [])
			var notes: RichTextLabel = detail.get("_notes")
			for i: int in shop.size():
				reading.call("_on_tapped", "shop", i)
				if _open_first_reminder(notes):
					break
				reading.call("_on_tapped", "shop", i)
		"combat_reminder":
			_bot_game(app, BOT_ROUNDS)
			app.show_game_combat()
			var watching: CombatScreen = app.current as CombatScreen
			watching.playing = false
			for i: int in 3:
				await process_frame
			await _play_until(watching, mini(9, watching.events.size() - 2))
			var units: Dictionary = watching.get("_cards")
			var note: RichTextLabel = watching.get("_note_text")
			for uid: int in units:
				watching.call("_show_detail", uid)
				if _open_first_reminder(note):
					break
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
			sandbox.place(1, 0, "grey_agnes", false)
			sandbox.place(1, 1, "grizel", true)
			sandbox.place(1, 2, "brother_wolf", false)
			sandbox.place(1, 5, "fairy_monarch", false)
			sandbox.place(0, 1, "mrs_sorrel", false)
			sandbox.place(0, 2, "jenny_greenteeth", false)
			sandbox.place(0, 5, "belladonna", false)
			sandbox.place(1, 3, "hedge_witch", false)
			sandbox.place(0, 3, "pill_bug", false)
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
		"recruit_slice", "scout", "scout_long_name", "pass_drag", "ghost_next":
			var slice: FixturePort = FixturePort.new()
			app.setup(slice)
			slice.use_state_file("res://tests/ui/data/recruit_slice.json")
			if screen_name == "scout_long_name":
				var state: Dictionary = slice.get_state()
				var hero: Dictionary = state["hero"]
				hero["name"] = "Hob Mumblecrust"
				hero["kind"] = "activated"
				state["next_opponent_hero"] = hero.duplicate(true)
			if screen_name == "ghost_next":
				_make_next_a_ghost(slice.get_state())
			app.show_recruit()
			var slice_screen: RecruitScreen = app.current as RecruitScreen
			if screen_name in ["scout", "scout_long_name", "ghost_next"]:
				slice_screen.toggle_scout()
				slice_screen.call("_clear_toast")
				if screen_name == "scout_long_name":
					slice_screen.call("_show_opponent")
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
## Opens the reminder for the first keyword in a rules text, as a hover (PC) or tap (phone) would.
func _open_first_reminder(rich: RichTextLabel) -> bool:
	var found: RegExMatch = RegEx.create_from_string("\\[url=(kw:[^\\]]+)\\]").search(rich.text)
	if found == null:
		return false
	rich.meta_hover_started.emit(found.get_string(1))
	rich.meta_clicked.emit(found.get_string(1))
	return true


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
	if _backdrop != null:
		_replace_tables(root)
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


## Only replace the painted table surface; board trays, panels and unit art stay intact.
## Loading an Image directly also supports external files without Godot's import pipeline.
func _replace_tables(parent: Node) -> void:
	for child: Node in parent.get_children():
		if child.get_script() == TableBackground:
			var table: Control = child as Control
			var backdrop: TextureRect = TextureRect.new()
			backdrop.name = "ShotBackdrop"
			backdrop.texture = _backdrop
			backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(backdrop)
			parent.move_child(backdrop, table.get_index())
			backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			table.hide()
		else:
			_replace_tables(child)
