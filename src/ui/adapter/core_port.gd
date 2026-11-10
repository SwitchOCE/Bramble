# gdlint:disable=max-public-methods
# The port mirrors SPEC section 7 one method per call, which is more than 20.
extends "res://src/ui/adapter/game_port.gd"
## The GamePort backed by the rules core (src/core, SPEC section 7): every call forwards to
## GameSession, CombatSandbox, UnitLibrary or ScenarioLibrary unchanged. The UI's default port.

const Data := preload("res://src/ui/view_data.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const Settings := preload("res://src/ui/settings.gd")

var library: UnitLibrary
var config: GameConfig
var session: GameSession
var scenario_library: ScenarioLibrary
## True: the screen shows hand_items and pending_choice. False: the Triple Reward is cast and a
## choice taken at once, for callers that don't know them (tests of the bare rules).
var manual_choices: bool = true
var _uses_saved_settings: bool = true
var _field_library_path: String = ""
var _launch_error: String = ""
var _fight_floor: Array = []
var _fight_health: Array[int] = []
var _fight_ids: Array = []


## Loads the unit library, for the full game unless a config says otherwise (tests use human_bot).
func setup(game_config: GameConfig = null) -> void:
	library = UnitLibrary.load_dir()
	config = game_config if game_config != null else GameConfig.full_game()
	_uses_saved_settings = game_config == null
	_field_library_path = ""
	_launch_error = ""
	if _uses_saved_settings:
		var args: PackedStringArray = OS.get_cmdline_user_args()
		var index: int = args.find("--field-library")
		if index >= 0:
			if not Settings.field_mode_enabled:
				if OS.has_feature("editor"):
					Settings.field_mode_enabled = true
				else:
					_launch_error = "Strong field is not enabled in this build"
					return
			if index + 1 >= args.size() or args[index + 1].begins_with("--"):
				_launch_error = "--field-library needs a path"
			else:
				_field_library_path = args[index + 1]


func new_game(game_seed: int) -> String:
	_fight_floor.clear()
	_fight_health.clear()
	_fight_ids.clear()
	if library == null:
		setup()
	if _launch_error != "":
		return _launch_error
	if library.all_units().is_empty():
		return "No units found in content/units"
	var field_path: String = _field_library_path
	var prepared_field: FieldLibrary = null
	if _uses_saved_settings:
		# The previous field game's source config must not leak into a later Bots game.
		config = GameConfig.full_game()
		config.set_value("ask_for_kin", Settings.ask_for_kin)
		if field_path.is_empty() and Settings.field_mode_enabled and Settings.opponents == "field":
			field_path = Settings.field_library_path
	if not field_path.is_empty():
		prepared_field = FieldLibrary.prepare(config, library, field_path)
		if prepared_field.error != "":
			return prepared_field.error
	if (
		config.get_string("opponents") == "field"
		and not Settings.field_mode_enabled
		and not OS.has_feature("editor")
	):
		return "Strong field is not enabled in this build"
	session = GameSession.create(game_seed, library, config, Bot.create, prepared_field)
	if session == null:
		return "Cannot start this opponent configuration."
	_settle()
	return ""


## Keeps a screen that doesn't know choices or hand cards playing (see manual_choices).
func _settle() -> void:
	if manual_choices or session == null:
		return
	var state: Dictionary = session.get_state()
	var items: Array = state["hand_items"]
	for index: int in range(items.size() - 1, -1, -1):
		var item: Dictionary = items[index]
		if str(item["def_id"]) == "triple_reward":
			session.play_item(index)
	while session.get_state()["pending_choice"] != null:
		if session.choose(0) != "":
			return


func get_state() -> Dictionary:
	return session.get_state() if session != null else {}


func get_last_combat() -> Dictionary:
	if session == null:
		return {}
	var combat: Dictionary = session.get_last_combat().duplicate(true)
	combat["floor_marks"] = _fight_floor.duplicate(true)
	combat["hero_health_before"] = _fight_health.duplicate()
	combat["hero_health_after"] = _health_for_ids(_fight_ids)
	return combat


func is_over() -> bool:
	return session != null and session.is_over()


func get_seed() -> int:
	return session.get_seed() if session != null else -1


func buy(shop_index: int) -> String:
	return _after(session.buy(shop_index)) if session != null else NOT_AVAILABLE


func sell(slot: int) -> String:
	return session.sell(slot) if session != null else NOT_AVAILABLE


func swallow(source: String, index: int, into_slot: int) -> String:
	return session.swallow(source, index, into_slot) if session != null else NOT_AVAILABLE


func play(hand_index: int, slot: int) -> String:
	return _after(session.play(hand_index, slot)) if session != null else NOT_AVAILABLE


func move(from_slot: int, to_slot: int) -> String:
	return session.move(from_slot, to_slot) if session != null else NOT_AVAILABLE


func refresh() -> String:
	return _after(session.refresh()) if session != null else NOT_AVAILABLE


func ask_for_kin() -> String:
	return _after(session.ask_for_kin()) if session != null else NOT_AVAILABLE


func buy_spell(index: int) -> String:
	return _after(session.buy_spell(index)) if session != null else NOT_AVAILABLE


func play_item(index: int, slot: int = -1) -> String:
	return _after(session.play_item(index, slot)) if session != null else NOT_AVAILABLE


func use_power(slot: int = -1) -> String:
	return _after(session.use_power(slot)) if session != null else NOT_AVAILABLE


func choose(index: int) -> String:
	return session.choose(index) if session != null else NOT_AVAILABLE


func get_game_log() -> Dictionary:
	return session.get_game_log() if session != null else {}


func _after(result: String) -> String:
	_settle()
	return result


func toggle_freeze() -> String:
	return session.toggle_freeze() if session != null else NOT_AVAILABLE


func tier_up() -> String:
	return session.tier_up() if session != null else NOT_AVAILABLE


func end_turn() -> String:
	if session == null:
		return NOT_AVAILABLE
	# Observe the exact fight inputs without changing any rules or taking over evidence hooks.
	var previous: Callable = session.fight_capture_observer
	session.fight_capture_observer = func(
		input: Dictionary, result: Dictionary, fight: Combat
	) -> void:
		var ids: Array = Data.a(input, "player_ids")
		if ids.has(0):
			_fight_ids = ids.duplicate()
			_fight_health = _health_for_ids(ids)
			_fight_floor = []
			var slots: Array = Data.a(input, "slots")
			var rules: Array = Data.a(input, "fight_rules")
			for side: int in 2:
				var side_rules: Dictionary = Data.entry(rules, side)
				var bands: Array = []
				for band: Variant in Data.a(side_rules, "bands"):
					if band is bool:
						bands.append(band)
					else:
						bands.append(Data.as_int(band, 0) > 0)
				var marks: Array = RecruitView.slot_marks(
					{"slot_effects": slots[side] if slots.size() > side else [], "bands": bands}
				)
				for nest: Dictionary in Data.a(side_rules, "nests"):
					marks[Data.i(nest, "slot")]["nest"] = true
				_fight_floor.append(marks)
		if previous.is_valid():
			previous.call(input, result, fight)
	var reason: String = session.end_turn()
	session.fight_capture_observer = previous
	return _after(reason)


func _health_for_ids(ids: Array) -> Array[int]:
	var out: Array[int] = []
	for id: Variant in ids:
		var health: int = -1
		for standing: Dictionary in Data.a(session.get_state(), "standings"):
			if Data.i(standing, "player_id", -2) == Data.as_int(id):
				health = Data.i(standing, "health")
		out.append(health)
	return out


func library_units() -> Array[Dictionary]:
	if library == null:
		setup()
	return library.all_units()


func unbuilt_units() -> PackedStringArray:
	if library == null:
		setup()
	return library.unbuilt_units()


func sandbox_fight(boards: Array, fight_seed: int, tiers: Array = [1, 1]) -> Dictionary:
	if library == null:
		setup()
	var sandbox: CombatSandbox = CombatSandbox.create(library, config)
	for side: int in mini(2, boards.size()):
		var board: Array = boards[side]
		var reason: String = sandbox.set_board(side, board)
		if not reason.is_empty():
			return {"error": reason}
		sandbox.set_tier(side, Data.as_int(tiers[side]) if side < tiers.size() else 1)
	return sandbox.fight(fight_seed)


func scenarios() -> Array[Dictionary]:
	return _scenario_library().all_scenarios()


func load_scenario(id: String) -> Dictionary:
	var scenario: Dictionary = _scenario_library().get_scenario(id)
	var sandbox: CombatSandbox = CombatSandbox.create(library, config)
	var reason: String = sandbox.load_scenario(scenario)
	if not reason.is_empty():
		return {"error": reason}
	var tiers: Array = scenario.get("tiers", [1, 1])
	return {
		"boards": [sandbox.get_board(0), sandbox.get_board(1)],
		"seed": Data.i(scenario, "seed", 1),
		"tiers": tiers.duplicate(),
	}


func _scenario_library() -> ScenarioLibrary:
	if library == null:
		setup()
	if scenario_library == null:
		scenario_library = ScenarioLibrary.load_dir(library)
	return scenario_library


func dev_add_gold(amount: int) -> String:
	return session.dev_add_gold(amount) if session != null else NOT_AVAILABLE


func dev_spawn_to_hand(def_id: String, golden: bool = false) -> String:
	return _after(session.dev_spawn_to_hand(def_id, golden)) if session != null else NOT_AVAILABLE


func dev_set_tier(tier: int) -> String:
	return session.dev_set_tier(tier) if session != null else NOT_AVAILABLE


func dev_skip_turn() -> String:
	return session.dev_skip_turn() if session != null else NOT_AVAILABLE


func shy_warning(action: String, first: int = -1, second: int = -1) -> String:
	return session.shy_warning(action, first, second) if session != null else ""
