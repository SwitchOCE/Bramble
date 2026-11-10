class_name PlayTurns
extends RefCounted
## Walks a tools/play save one action at a time and stops at each moment a reviewer's turn has:
## a turn's start, its end (just before "end"), the fight that "end" ran, and the game's end.
## render.gd draws each moment on the real UI; tests read the same moments without drawing.

const START: String = "start"
const END: String = "end"
const FIGHT: String = "fight"
const OVER: String = "over"

var game: PlayGame
var error: String = ""
var _actions: Array = []
var _next: int = 0
var _round: int = 0
var _queued: Array[Dictionary] = []
var _over_sent: bool = false
## The action whose turn-end moment has been sent; it runs on the next step.
var _ended_at: int = -1


## The save's game, rebuilt with no actions, ready to step. error says why it can't be.
static func open(save: Dictionary) -> PlayTurns:
	var turns := PlayTurns.new()
	var actions: Variant = save.get("actions")
	if not actions is Array:
		turns.error = "Save needs an action list."
		return turns
	var bare: Dictionary = save.duplicate(true)
	bare["actions"] = []
	turns.game = PlayGame.from_save(bare)
	if turns.game.load_error != "":
		turns.error = turns.game.load_error
		return turns
	turns._actions = actions
	turns._round = turns.current_round()
	if turns._round > 0:
		turns._queue(START)
	return turns


func current_round() -> int:
	return CoreUtil.to_int(game.session.get_state().get("round", 0))


## The next moment: {"kind", "round", "hash", and for a fight "fight"}; {} when the save is done.
## A saved action that no longer replays sets error and ends the walk.
func next() -> Dictionary:
	while _queued.is_empty():
		if _next >= _actions.size() or error != "":
			if error == "" and not _over_sent and game.session.is_over():
				_over_sent = true
				_queue(OVER)
				continue
			return {}
		_step()
	return _queued.pop_front()


func _step() -> void:
	var list: Array = _actions[_next]
	var words: PackedStringArray = PackedStringArray(list)
	var ending: bool = not words.is_empty() and words[0] == "end"
	# The turn's end is drawn before "end" runs, so the step stops here once.
	if ending and _ended_at != _next:
		_ended_at = _next
		_queue(END)
		return
	_next += 1
	var problem: String = game.run(words)
	if problem != "":
		error = "Saved action %d no longer works: %s" % [_next, problem]
		return
	var fought: Dictionary = game.session.get_last_combat()
	if ending and CoreUtil.to_int(fought.get("round", -1)) == _round:
		_queue(FIGHT, fight_summary(game, fought))
	var now: int = current_round()
	if now != _round and not game.session.is_over():
		_round = now
		_queue(START)


func _queue(kind: String, fight: Dictionary = {}) -> void:
	var moment: Dictionary = {"kind": kind, "round": _round, "hash": game.state_hash()}
	if not fight.is_empty():
		moment["fight"] = fight
	_queued.append(moment)


## The human's side of a fight, in the words `play.sh <save> log` uses (win, loss, tie).
static func fight_summary(played: PlayGame, fight: Dictionary) -> Dictionary:
	var events: Array = fight.get("events", [])
	var mine: int = 0
	if not events.is_empty():
		var start: Dictionary = events[0]
		var ids: Array = start.get("player_ids", [])
		mine = maxi(0, ids.find(GameSession.HUMAN_ID))
	var winner: int = CoreUtil.to_int(fight.get("winner", -1))
	var result: String = "tie"
	if winner >= 0:
		result = "win" if winner == mine else "loss"
	return {
		"round": CoreUtil.to_int(fight.get("round", 0)),
		"opponent_id": CoreUtil.to_int(fight.get("opponent_id", -1)),
		# The name `play.sh <save>` prints on its LAST FIGHT line.
		"opponent": PlayView.player_name(played.session.get_state(), fight.get("opponent_id")),
		"result": result,
		"damage": CoreUtil.to_int(fight.get("damage", 0)),
		"events": events.size(),
		"log_result": logged_result(played, CoreUtil.to_int(fight.get("round", 0))),
	}


## What the game log (the source of `play.sh <save> log`) says the human did that round.
static func logged_result(played: PlayGame, round_number: int) -> String:
	var summary: Dictionary = played.session.get_game_log()
	for value: Variant in summary.get("players", []):
		var row: Dictionary = value
		if CoreUtil.to_int(row.get("player_id", -1)) != GameSession.HUMAN_ID:
			continue
		for round_value: Variant in row.get("rounds", []):
			var round_row: Dictionary = round_value
			if CoreUtil.to_int(round_row.get("round", -1)) == round_number:
				return str(round_row.get("result", ""))
	return ""
