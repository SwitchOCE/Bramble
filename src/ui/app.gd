extends Control
## Owns the game port and swaps screens: menu -> recruit -> combat -> recruit ... -> game over,
## and menu -> sandbox -> combat -> sandbox. Settings and How to play open over whatever is showing,
## so a game goes on underneath. Screens only emit signals; this decides what's next.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const Sfx := preload("res://src/ui/sfx.gd")
const Records := preload("res://src/ui/records.gd")
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
	fight_log.side_names = side_names(Data.entry(Data.a(combat, "events"), 0), port.get_state())
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
	var start: Dictionary = Data.entry(events, 0)
	var state: Dictionary = port.get_state()
	# The ghost fought was named before the fight: this fight may have knocked out someone new.
	var ghost: String = ""
	if current is RecruitScreen:
		ghost = RecruitView.next_name((current as RecruitScreen).state)
	var names: PackedStringArray = side_names(start, state, ghost)
	var me: int = player_side(start, Data.i(state, "player_id", 0))
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
	var health: int = -1
	if ids.size() > 1 - me:
		health = _health_before(state, combat, Data.as_int(ids[1 - me]), me)
	var screen: CombatScreen = CombatScreen.new()
	screen.finished.connect(show_recruit)
	screen.guide_requested.connect(open_guide)
	screen.settings_requested.connect(open_settings)
	screen.menu_requested.connect(show_menu)
	_swap(screen)
	for side: int in 2:
		var id: int = Data.as_int(ids[side]) if ids.size() > side else -1
		for entry: Variant in Data.a(state, "standings"):
			var standing: Dictionary = entry
			if Data.i(standing, "player_id", -2) == id:
				var hero_name: String = Data.s(standing, "hero")
				for hero: Dictionary in UnitLibrary.load_dir().all_heroes():
					if Data.s(hero, "name") == hero_name:
						screen.hero_views[side] = hero
				if side == me:
					screen.hero_views[side] = Data.d(state, "hero")
				screen.hero_health[side] = _health_before(state, combat, id, 1 - side)
	screen.setup(combat, names, me, title, health)


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


## Which side of a fight is the given player: player_ids in combat_start; side 0 if absent.
static func player_side(start_event: Dictionary, player_id: int) -> int:
	var ids: Array = Data.a(start_event, "player_ids")
	var side: int = ids.find(player_id)
	return side if side >= 0 else 0


## Display names for both sides from the lobby standings ("You", "Pipkin"). `ghost_name`: what to
## call a ghost on the other side.
static func side_names(
	start_event: Dictionary, state: Dictionary, ghost_name: String = ""
) -> PackedStringArray:
	var ids: Array = start_event.get("player_ids", [-1, -1])
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
