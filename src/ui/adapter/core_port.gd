# gdlint:disable=max-public-methods
# The port mirrors SPEC section 7 one method per call, which is more than 20.
extends "res://src/ui/adapter/game_port.gd"
## The GamePort backed by the rules core (src/core, SPEC section 7): every call forwards to
## GameSession, CombatSandbox, UnitLibrary or ScenarioLibrary unchanged. The UI's default port.

const Data := preload("res://src/ui/view_data.gd")

var library: UnitLibrary
var config: GameConfig
var session: GameSession
var scenario_library: ScenarioLibrary
## True: the screen shows hand_items and pending_choice. False: the Triple Reward is cast and a
## choice taken at once, for callers that don't know them (tests of the bare rules).
var manual_choices: bool = true


## Loads the unit library, for the full game unless a config says otherwise (tests use human_bot).
func setup(game_config: GameConfig = null) -> void:
	library = UnitLibrary.load_dir()
	config = game_config if game_config != null else GameConfig.full_game()


func new_game(game_seed: int) -> String:
	if library == null:
		setup()
	if library.all_units().is_empty():
		return "No units found in content/units"
	session = GameSession.create(game_seed, library, config)
	_settle()
	return ""


func set_difficulty(id: String) -> void:
	if config == null:
		setup()
	config.set_value("difficulty", id)


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
	return session.get_last_combat() if session != null else {}


func is_over() -> bool:
	return session != null and session.is_over()


func get_seed() -> int:
	return session.get_seed() if session != null else -1


func buy(shop_index: int) -> String:
	return _after(session.buy(shop_index)) if session != null else NOT_AVAILABLE


func sell(slot: int) -> String:
	return session.sell(slot) if session != null else NOT_AVAILABLE


func play(hand_index: int, slot: int) -> String:
	return _after(session.play(hand_index, slot)) if session != null else NOT_AVAILABLE


func move(from_slot: int, to_slot: int) -> String:
	return session.move(from_slot, to_slot) if session != null else NOT_AVAILABLE


func refresh() -> String:
	return _after(session.refresh()) if session != null else NOT_AVAILABLE


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
	return _after(session.end_turn()) if session != null else NOT_AVAILABLE


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
