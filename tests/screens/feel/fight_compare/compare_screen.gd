extends FightScreen
## The fight screen with a treatment's card motion in place of FightMotion. The motion is swapped
## in as the stage is first built, before any card is placed, so `today` (FightMotion itself)
## plays exactly as the game's screen does.

## The treatment (fight_treatment.gd or a subclass); set before the screen enters the tree.
var treatment: RefCounted


func _ensure_stage() -> void:
	var fresh: bool = _frame == null
	super()
	if fresh and treatment != null:
		_keeper = treatment.call("make_motion", _cards)
