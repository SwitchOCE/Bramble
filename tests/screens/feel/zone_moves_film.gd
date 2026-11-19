extends "res://tests/screens/feel/feel_game.gd"
## Real input, core results and the lock mark for the C15 review film.

var _actions: Array[Dictionary] = []
var _refused: Array[String] = []
var _returned: Unit
var _locked: Unit


func feel_setup(scenario: Dictionary) -> void:
	super(scenario)
	_returned = game.flow.human().board[0]
	_locked = game.flow.human().board[1]
	game.recruit.action_requested.connect(_action)


func _action(action: Dictionary) -> void:
	_actions.append(action.duplicate(true))
	var message: String = str(game.recruit.state.get("message", ""))
	if message != "":
		_refused.append(message)


func feel_report() -> Dictionary:
	var player: PlayerState = game.flow.human()
	var returned: bool = player.hand.has(_returned) and player.board[0] == null
	var stayed: bool = player.board[1] == _locked and _locked.worked_this_turn
	assert(returned, "board unit moved to hand")
	assert(stayed, "working Gorger stayed for the fight")
	var expected: Array[String] = ["Worked this turn: stays for the fight."]
	assert(_refused == expected)
	assert(_actions.size() == 3)
	return {
		"actions": _actions,
		"refused": _refused,
		"returned_same_copy": returned,
		"locked_unit_stayed": stayed,
		"gold": player.gold
	}
