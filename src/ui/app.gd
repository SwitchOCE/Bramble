extends Control
## Owns the game port and swaps screens: menu -> recruit -> combat -> recruit ... -> game over,
## and menu -> sandbox -> combat -> sandbox. Screens only emit signals; this decides what's next.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")

var port: GamePort
var current: Control
## Kept while the app runs so the sandbox boards survive a fight.
var sandbox: SandboxScreen
var game_seed: int = 1


func _init() -> void:
	theme = UiTheme.get_theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)


## The sandbox is kept out of the tree while a fight plays; free it with the app.
func _exit_tree() -> void:
	if sandbox != null and sandbox.get_parent() == null:
		sandbox.free()
		sandbox = null


func setup(game_port: GamePort) -> void:
	port = game_port
	CardView.set_unbuilt(port.unbuilt_units())
	CardDetail.set_glossary(port.library_units())
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
	menu.play_requested.connect(start_game)
	menu.sandbox_requested.connect(show_sandbox)
	menu.quit_requested.connect(func() -> void: get_tree().quit())
	_swap(menu)


func start_game() -> void:
	var reason: String = port.new_game(game_seed)
	game_seed += 1
	if reason.is_empty():
		show_recruit()


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
	_swap(screen)
	screen.setup(port)


func show_game_combat() -> void:
	var combat: Dictionary = port.get_last_combat()
	var events: Array = Data.a(combat, "events")
	if events.is_empty():
		show_recruit()
		return
	var start: Dictionary = Data.entry(events, 0)
	var names: PackedStringArray = side_names(start, port.get_state())
	var me: int = player_side(start, Data.i(port.get_state(), "player_id", 0))
	var title: String = (
		"Round %d   ·   %s vs %s" % [Data.i(combat, "round", 0), names[me], names[1 - me]]
	)
	var screen: CombatScreen = CombatScreen.new()
	screen.finished.connect(show_recruit)
	_swap(screen)
	screen.setup(combat, names, me, title)


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
	screen.setup(result, PackedStringArray(["Your board", "Enemy board"]), 0, "Sandbox fight")


func show_game_over() -> void:
	var screen: GameOverScreen = GameOverScreen.new()
	screen.menu_requested.connect(show_menu)
	_swap(screen)
	screen.setup(port)


## Which side of a fight is the given player: player_ids in combat_start; side 0 if absent.
static func player_side(start_event: Dictionary, player_id: int) -> int:
	var ids: Array = Data.a(start_event, "player_ids")
	var side: int = ids.find(player_id)
	return side if side >= 0 else 0


## Display names for both sides from the lobby standings ("You", "Bot 3 (wide)").
static func side_names(start_event: Dictionary, state: Dictionary) -> PackedStringArray:
	var ids: Array = start_event.get("player_ids", [-1, -1])
	var names: PackedStringArray = ["Side A", "Side B"]
	var standings: Array = Data.a(state, "standings")
	for side: int in mini(2, ids.size()):
		var player_id: int = ids[side]
		if player_id == -1:
			names[side] = "The ghost"
		for entry: Variant in standings:
			var standing: Dictionary = entry
			if Data.i(standing, "player_id", -2) == player_id:
				names[side] = str(standing.get("name", names[side]))
	return names
