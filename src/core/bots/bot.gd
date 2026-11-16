class_name Bot
extends RefCounted
## A bot plays one player's Recruit Phase through the same actions as anyone else. Subclasses
## choose from LegalActions; `refused` counts actions the session refused, which a legal list
## must never produce (the soak checks it stays 0).

const MAX_ACTIONS: int = 120

var rng: Rng
var refused: int = 0
var last_refusal: String = ""


func _init(stream: Rng) -> void:
	rng = stream


## Plays until the bot ends its turn (or MAX_ACTIONS). `after_action` is called with each action
## taken, for checks.
func take_turn(session: GameSession, player_id: int, after_action: Callable = Callable()) -> void:
	var player: PlayerState = session.player(player_id)
	for _step: int in MAX_ACTIONS:
		if player.turn_ended or not player.alive:
			return
		var action: Dictionary = choose(session, player)
		var error: String = session.act(player_id, action)
		if error != "":
			refused += 1
			last_refusal = "%s -> %s" % [action, error]
			break
		if after_action.is_valid():
			after_action.call(action)
	session.end_turn(player_id)


## The next action. Must be one of LegalActions.of(session, player).
func choose(_session: GameSession, _player: PlayerState) -> Dictionary:
	return {"type": "end_turn"}
