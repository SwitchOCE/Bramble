# gdlint:disable=max-public-methods
# The port mirrors SPEC section 7 one method per call, which is more than 20.
extends RefCounted
## The UI's only door into the game. Every screen talks to one of these and nothing else, so the
## fixture version (fixture_port.gd) can be swapped for the real rules core without touching a
## screen. Shapes are SPEC.md's: get_state() is section 6.1, combats are section 5's event log,
## action results are "" on success or a short reason to show the player.
##
## A port backed by the core forwards each method to GameSession / CombatSandbox / UnitLibrary
## (SPEC section 7) one to one; the extra methods are new_game(), library_units()
## and sandbox_fight().

const NOT_AVAILABLE: String = "Not available"


## Starts a fresh game (Play on the main menu). Returns "" or a reason.
func new_game(_seed: int) -> String:
	return NOT_AVAILABLE


## SPEC 6.1 recruit state for the human. {} when there is no game.
func get_state() -> Dictionary:
	return {}


## SPEC 7 get_last_combat(): {"round", "opponent_id", "winner", "damage", "events"}; {} if none.
func get_last_combat() -> Dictionary:
	return {}


func is_over() -> bool:
	return false


func buy(_shop_index: int) -> String:
	return NOT_AVAILABLE


func sell(_slot: int) -> String:
	return NOT_AVAILABLE


func play(_hand_index: int, _slot: int) -> String:
	return NOT_AVAILABLE


func move(_from_slot: int, _to_slot: int) -> String:
	return NOT_AVAILABLE


func refresh() -> String:
	return NOT_AVAILABLE


func toggle_freeze() -> String:
	return NOT_AVAILABLE


func tier_up() -> String:
	return NOT_AVAILABLE


## Runs the round. On "" the screen plays get_last_combat() and then reads get_state() again.
func end_turn() -> String:
	return NOT_AVAILABLE


## Every unit file (SPEC 3), sorted by tier then name: UnitLibrary.all_units().
func library_units() -> Array[Dictionary]:
	return []


## Sandbox fight. boards = [side 0, side 1], each 7 entries of null or
## {"def_id": String, "golden": bool}. Returns {"events", "winner", "damage"} (SPEC 7
## CombatSandbox.fight) or {"error": reason}.
func sandbox_fight(_boards: Array, _seed: int) -> Dictionary:
	return {"error": NOT_AVAILABLE}


## Unit ids whose mechanics aren't built yet: they play as plain stats (UnitLibrary.unbuilt_units).
func unbuilt_units() -> PackedStringArray:
	return PackedStringArray()


## The running game's seed, or -1.
func get_seed() -> int:
	return -1


# Dev panel actions (SPEC 7 dev_*). Same "" or reason convention.


func dev_add_gold(_amount: int) -> String:
	return NOT_AVAILABLE


func dev_spawn_to_hand(_def_id: String, _golden: bool = false) -> String:
	return NOT_AVAILABLE


func dev_set_tier(_tier: int) -> String:
	return NOT_AVAILABLE


## Ends the turn with no fight for the human (SPEC 7): the screen re-reads the state, no combat.
func dev_skip_turn() -> String:
	return NOT_AVAILABLE
