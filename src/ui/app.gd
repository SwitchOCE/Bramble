extends Control
## Owns the game port and swaps screens: menu -> recruit -> combat -> recruit ... -> game over,
## and menu -> sandbox -> combat -> sandbox. Settings and How to play open over whatever is showing,
## so a game goes on underneath. Screens only emit signals; this decides what's next.

const Events := preload("res://src/core/combat/combat_events.gd")

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const Records := preload("res://src/ui/records.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")

const GamePort := preload("res://src/ui/adapter/game_port.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const FightLogPage := preload("res://src/ui/screens/fight_log_page.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const SettingsScreen := preload("res://src/ui/screens/settings_screen.gd")
const HowToPlay := preload("res://src/ui/screens/how_to_play.gd")
const MAX_SEED: int = 999_999_999

static var _heroes_by_name: Dictionary = {}

var port: GamePort
var current: Control
## Kept while the app runs so the sandbox boards survive a fight.
var sandbox: SandboxScreen
## The seed of the current game (shown in the dev panel).
var game_seed: int = -1
## How each fight of this game went: {round, result ("won", "lost", "tie"), damage}.
var round_log: Array[Dictionary] = []

var _seeds: RandomNumberGenerator = RandomNumberGenerator.new()
## This game's result is already in the records.
var _recorded: bool = false
var _new_best: bool = false
## A replay uses the fight's pairing, not the next recruit screen's pairing.
var _combat_round: int = -1
var _combat_side_names: PackedStringArray = []
var _combat_standings_round: int = -1
var _combat_standings: Array = []
var _combat_ghost_owner_id: int = -9


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Sfx.new())


## The sandbox is kept out of the tree while a fight plays; free it with the app.
func _exit_tree() -> void:
	if sandbox != null and sandbox.get_parent() == null:
		sandbox.free()
		sandbox = null


func setup(game_port: GamePort) -> void:
	port = game_port
	_seeds.randomize()
	CardView.set_unbuilt(port.unbuilt_units())
	show_menu()


func _swap(screen: Control) -> void:
	if current != null and current != sandbox:
		current.queue_free()
	if current != null and current.get_parent() == self:
		remove_child(current)
	current = screen
	add_child(screen)


func show_menu() -> void:
	var menu: MainMenu = MainMenu.new()
	menu.play_requested.connect(request_new_game)
	menu.guide_requested.connect(open_guide)
	menu.settings_requested.connect(open_settings)
	menu.sandbox_requested.connect(show_sandbox)
	menu.quit_requested.connect(func() -> void: get_tree().quit())
	_swap(menu)


## The first game opens the guide first; closing it starts.
func request_new_game() -> void:
	if Settings.seen_guide:
		start_game()
		return
	var guide: HowToPlay = open_guide()
	guide.closed.connect(func() -> void: start_game())


## Starts a game from `chosen_seed`, or from a fresh random seed when it is negative (a
## prototype pick: every Play differs; the dev panel shows the seed and replays a typed one).
func start_game(chosen_seed: int = -1) -> void:
	game_seed = chosen_seed if chosen_seed >= 0 else _seeds.randi_range(1, MAX_SEED)
	round_log.clear()
	_combat_round = -1
	_combat_side_names.clear()
	_combat_standings_round = -1
	_combat_standings.clear()
	_combat_ghost_owner_id = -9
	_recorded = false
	_new_best = false
	var reason: String = port.new_game(game_seed)
	if reason.is_empty():
		show_recruit()
	else:
		var error := AcceptDialog.new()
		error.title = "Could not start game"
		error.dialog_text = reason
		error.confirmed.connect(error.queue_free)
		add_child(error)
		error.popup_centered(Vector2i(640, 240))


func open_guide() -> HowToPlay:
	var guide: HowToPlay = HowToPlay.new()
	guide.closed.connect(_on_guide_closed)
	add_child(guide)
	return guide


func _on_guide_closed() -> void:
	if not Settings.seen_guide:
		Settings.seen_guide = true
		Settings.save()


func open_settings() -> SettingsScreen:
	var screen: SettingsScreen = SettingsScreen.new()
	screen.guide_requested.connect(open_guide)
	screen.closed.connect(_on_settings_closed)
	add_child(screen)
	return screen


## The menu's Sandbox leaf and the recruit screen's Dev token follow the setting straight away.
func _on_settings_closed() -> void:
	if current is RecruitScreen:
		(current as RecruitScreen).refresh_settings()
	elif current is MainMenu:
		show_menu()


## Game over once the whole game ends or the human is out (placement set), whatever the lobby does.
func human_is_out() -> bool:
	return port.is_over() or port.get_state().get("placement") != null


func show_recruit() -> void:
	if human_is_out():
		show_game_over()
		return
	var screen: RecruitScreen = RecruitScreen.new()
	screen.combat_ready.connect(show_game_combat)
	screen.menu_requested.connect(show_menu)
	screen.game_over_reached.connect(show_game_over)
	screen.replay_requested.connect(start_game)
	screen.guide_requested.connect(open_guide)
	screen.settings_requested.connect(open_settings)
	_swap(screen)
	screen.last_fight_requested.connect(open_last_fight)
	screen.watch_fight_requested.connect(show_game_combat)
	screen.setup(port)


func open_last_fight() -> void:
	var combat: Dictionary = port.get_last_combat()
	var model := CombatModel.new()
	var fight_log := CombatLog.new()
	fight_log.side_names = _game_combat_names(combat, port.get_state())
	var words: PackedStringArray = []
	for event: Dictionary in Data.a(combat, "events"):
		words.append(fight_log.describe(event, model, false))
		model.apply(event)
	var page := FightLogPage.new()
	page.setup("Turn %d" % Data.i(combat, "round"), "\n".join(words))
	add_child(page)


func show_game_combat() -> void:
	var combat: Dictionary = port.get_last_combat()
	var events: Array = Data.a(combat, "events")
	if events.is_empty():
		show_recruit()
		return
	var start: Dictionary = Events.start(events)
	var state: Dictionary = port.get_state()
	var names: PackedStringArray = _game_combat_names(combat, state)
	var standings: Array = _game_combat_standings(combat, state, start)
	var me: int = player_side(start, Data.i(state, "player_id", 0))
	if me < 0:
		push_error("Cannot show a fight without the player in combat_start.player_ids")
		show_recruit()
		return
	if (
		round_log.is_empty()
		or (
			Data.i(Data.entry(round_log, round_log.size() - 1), "round", -1)
			!= Data.i(combat, "round")
		)
	):
		note_round(combat, me)
	var title: String = "Turn %d" % Data.i(combat, "round", 0)
	var ids: Array = Data.a(start, "player_ids")
	var screen: CombatScreen = CombatScreen.new()
	screen.finished.connect(show_recruit)
	screen.guide_requested.connect(open_guide)
	screen.settings_requested.connect(open_settings)
	screen.menu_requested.connect(show_menu)
	_swap(screen)
	for side: int in 2:
		var id: int = Data.as_int(ids[side]) if ids.size() > side else -1
		for entry: Variant in standings:
			var standing: Dictionary = entry
			var ghost: bool = (
				id == -1 and Data.i(standing, "player_id", -2) == _combat_ghost_owner_id
			)
			if Data.i(standing, "player_id", -2) == id or ghost:
				var hero_name: String = Data.s(standing, "hero")
				screen.hero_views[side] = _hero_named(hero_name)
				if side == me:
					screen.hero_views[side] = Data.d(state, "hero")
				screen.hero_health[side] = -1 if ghost else Data.i(standing, "health", -1)
	screen.set_standings(standings, Data.i(combat, "opponent_id", -2), _combat_ghost_owner_id)
	screen.setup(combat, names, me, title, screen.hero_health[1 - me])


## Core has resolved every fight before playback opens. Keep the recruit rail's snapshot, including
## players who are eliminated by this round, rather than showing future damage beside the fight.
func _game_combat_standings(combat: Dictionary, state: Dictionary, start: Dictionary) -> Array:
	var round_number: int = Data.i(combat, "round", -1)
	if _combat_standings_round == round_number and not _combat_standings.is_empty():
		return _combat_standings.duplicate(true)
	var recorded: Array = Data.a(combat, "standings_before")
	var source: Dictionary = state
	var before_fight: bool = not recorded.is_empty()
	if current is RecruitScreen:
		var recruit_state: Dictionary = (current as RecruitScreen).state
		if Data.i(recruit_state, "round", -2) == round_number:
			source = recruit_state
			before_fight = true
	_combat_standings = (
		(recorded if not recorded.is_empty() else Data.a(source, "standings")).duplicate(true)
	)
	_combat_standings_round = round_number
	var ghost_state: Dictionary = source.duplicate()
	ghost_state["standings"] = _combat_standings
	_combat_ghost_owner_id = Data.i(RecruitView.ghost_owner(ghost_state), "player_id", -9)
	if not before_fight:
		var ids: Array = Data.a(start, "player_ids")
		var health_before: Array = Data.a(combat, "hero_health_before")
		for side: int in mini(2, ids.size()):
			var player_id: int = Data.as_int(ids[side])
			for standing: Dictionary in _combat_standings:
				if Data.i(standing, "player_id", -2) != player_id:
					continue
				standing["health"] = (
					Data.as_int(health_before[side])
					if health_before.size() > side
					else _health_before(state, combat, player_id, 1 - side)
				)
				standing["alive"] = Data.i(standing, "health") > 0
	return _combat_standings.duplicate(true)


func _game_combat_names(combat: Dictionary, state: Dictionary) -> PackedStringArray:
	var round_number: int = Data.i(combat, "round", -1)
	if not _combat_side_names.is_empty() and round_number == _combat_round:
		return _combat_side_names
	# Recruit still holds the pre-fight pairing when combat_ready first arrives.
	var ghost: String = ""
	if current is RecruitScreen:
		ghost = RecruitView.next_name((current as RecruitScreen).state)
	_combat_round = round_number
	_combat_side_names = side_names(Events.start(Data.a(combat, "events")), state, ghost)
	return _combat_side_names


## The content library is immutable during a run; fights reuse its hero views.
static func _hero_named(hero_name: String) -> Dictionary:
	if _heroes_by_name.is_empty():
		for hero: Dictionary in UnitLibrary.load_dir().all_heroes():
			_heroes_by_name[Data.s(hero, "name")] = hero
	return _heroes_by_name.get(hero_name, {})


## The opponent's Health going into this fight: the state is already past it, so a loss gets added
## back. -1 for a ghost, who has none.
func _health_before(state: Dictionary, combat: Dictionary, opponent: int, me: int) -> int:
	for entry: Variant in Data.a(state, "standings"):
		var standing: Dictionary = entry
		if Data.i(standing, "player_id", -2) == opponent:
			var health: int = Data.i(standing, "health", 0)
			if Data.i(combat, "winner", -1) == me:
				health += Data.i(combat, "damage", 0)
			return health
	return -1


func note_round(combat: Dictionary, me: int) -> void:
	var winner: int = Data.i(combat, "winner", -1)
	var result: String = "tie"
	if winner >= 0:
		result = "won" if winner == me else "lost"
	(
		round_log
		. append(
			{
				"round": Data.i(combat, "round", 0),
				"result": result,
				"damage": Data.i(combat, "damage", 0),
				"opponent_id": Data.i(combat, "opponent_id", -1),
				"opponent": opponent_name(Data.i(combat, "opponent_id", -1)),
			}
		)
	)


func opponent_name(player_id: int) -> String:
	for entry: Variant in Data.a(port.get_state(), "standings"):
		var standing: Dictionary = entry
		if Data.i(standing, "player_id", -2) == player_id:
			return UiTheme.player_name(standing)
	return "a ghost"


func show_sandbox() -> void:
	if sandbox == null:
		sandbox = SandboxScreen.new()
		sandbox.fight_ready.connect(show_sandbox_combat)
		sandbox.menu_requested.connect(show_menu)
		sandbox.setup(port)
	_swap(sandbox)


func show_sandbox_combat(result: Dictionary) -> void:
	var screen: CombatScreen = CombatScreen.new()
	screen.finished.connect(show_sandbox)
	_swap(screen)
	var title: String = "Sandbox"
	if sandbox != null and not sandbox.scenario_title.is_empty():
		title = sandbox.scenario_title
	screen.setup(result, PackedStringArray(["You", "Enemy"]), 0, title)


func show_game_over() -> void:
	_record_result()
	var screen: GameOverScreen = GameOverScreen.new()
	screen.menu_requested.connect(show_menu)
	_swap(screen)
	screen.setup(port, round_log, _new_best)


func _record_result() -> void:
	var placement: Variant = port.get_state().get("placement")
	if _recorded or placement == null:
		return
	_recorded = true
	_new_best = Records.add_game(Data.as_int(placement))
	if port is CorePort:
		GameRecordLog.write(port, (port as CorePort).recorded_actions)


## Which side of a fight is the given player; -1 if the start identity is missing.
static func player_side(start_event: Dictionary, player_id: int) -> int:
	return Events.side(start_event, player_id)


## Display names for both sides from the lobby standings ("You", "Pipkin"). `ghost_name`: what to
## call a ghost on the other side.
static func side_names(
	start_event: Dictionary, state: Dictionary, ghost_name: String = ""
) -> PackedStringArray:
	var ids: Array = Data.a(start_event, "player_ids")
	var names: PackedStringArray = ["Side A", "Side B"]
	var standings: Array = Data.a(state, "standings")
	for side: int in mini(2, ids.size()):
		var player_id: int = ids[side]
		if player_id == -1:
			names[side] = (
				ghost_name
				if ghost_name.begins_with("Ghost") or ghost_name == "Field ghost"
				else "A ghost"
			)
		for entry: Variant in standings:
			var standing: Dictionary = entry
			if Data.i(standing, "player_id", -2) == player_id:
				names[side] = UiTheme.player_name(standing)
	return names
