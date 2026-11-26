extends FightReplay
## FightReplay that also keeps the view state after every event of the log (snaps[i] is the board
## once event i has happened), for best_timeline.gd to show each change on its own frame. Its
## steps are replaced by the timeline's (best.gd). Exploratory: nothing here reaches the game.

## The view state after each event, by the event's index in the log.
var snaps: Array = []
## The schedule this replay is played by (best_timeline.gd), set by best.gd.
var timeline: RefCounted


func apply(event: Dictionary, damage: int = -1) -> void:
	super(event, damage)
	var view: Dictionary = {}
	if not steps.is_empty():
		var last: Dictionary = steps[steps.size() - 1]
		var shown: Dictionary = last["state"]
		view = shown.duplicate(true)
	snaps.append(view)
