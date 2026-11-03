# gdlint:disable=max-public-methods
# The port mirrors SPEC section 7 one method per call, which is more than 20.
extends "res://src/ui/adapter/game_port.gd"
## The GamePort backed by the rules core (src/core, SPEC section 7): every call forwards to
## GameSession, CombatSandbox or UnitLibrary unchanged. The UI's default port.

var library: UnitLibrary
var config: GameConfig
var session: GameSession


## Loads the unit library. Pass a config to change tunables (tests use human_bot).
func setup(game_config: GameConfig = null) -> void:
	library = UnitLibrary.load_dir()
	config = game_config if game_config != null else GameConfig.defaults()


func new_game(game_seed: int) -> String:
	if library == null:
		setup()
	if library.all_units().is_empty():
		return "No units found in content/units"
	session = GameSession.create(game_seed, library, config)
	return ""


func get_state() -> Dictionary:
	return session.get_state() if session != null else {}


func get_last_combat() -> Dictionary:
	return session.get_last_combat() if session != null else {}


func is_over() -> bool:
	return session != null and session.is_over()


func get_seed() -> int:
	return session.get_seed() if session != null else -1


func buy(shop_index: int) -> String:
	return session.buy(shop_index) if session != null else NOT_AVAILABLE


func sell(slot: int) -> String:
	return session.sell(slot) if session != null else NOT_AVAILABLE


func play(hand_index: int, slot: int) -> String:
	return session.play(hand_index, slot) if session != null else NOT_AVAILABLE


func move(from_slot: int, to_slot: int) -> String:
	return session.move(from_slot, to_slot) if session != null else NOT_AVAILABLE


func refresh() -> String:
	return session.refresh() if session != null else NOT_AVAILABLE


func toggle_freeze() -> String:
	return session.toggle_freeze() if session != null else NOT_AVAILABLE


func tier_up() -> String:
	return session.tier_up() if session != null else NOT_AVAILABLE


func end_turn() -> String:
	return session.end_turn() if session != null else NOT_AVAILABLE


func library_units() -> Array[Dictionary]:
	if library == null:
		setup()
	return library.all_units()


func unbuilt_units() -> PackedStringArray:
	if library == null:
		setup()
	return library.unbuilt_units()


func sandbox_fight(boards: Array, fight_seed: int) -> Dictionary:
	if library == null:
		setup()
	var sandbox: CombatSandbox = CombatSandbox.create(library, config)
	for side: int in mini(2, boards.size()):
		var board: Array = boards[side]
		var reason: String = sandbox.set_board(side, board)
		if not reason.is_empty():
			return {"error": reason}
	return sandbox.fight(fight_seed)


func dev_add_gold(amount: int) -> String:
	return session.dev_add_gold(amount) if session != null else NOT_AVAILABLE


func dev_spawn_to_hand(def_id: String, golden: bool = false) -> String:
	return session.dev_spawn_to_hand(def_id, golden) if session != null else NOT_AVAILABLE


func dev_set_tier(tier: int) -> String:
	return session.dev_set_tier(tier) if session != null else NOT_AVAILABLE


func dev_skip_turn() -> String:
	return session.dev_skip_turn() if session != null else NOT_AVAILABLE
