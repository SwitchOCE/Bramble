extends FightScreen
## The fight screen with a treatment's card motion in place of FightMotion. The motion is swapped
## in as the stage is first built, before any card is placed.
##
## Since the game plays its fight from a schedule (FightTimeline, plan step 1b), this keeps the
## game's step-by-step playback from before that (FightScreen at review/fight-anim-game-1a,
## b94a8021): each FightReplay step shown for its hold, then the next, with its sound cues. So
## `today`, `pilot` and `rotate` play the steps they played before; `best` and its subclasses
## play their own schedule over it, as before. Nothing here is the game.

## The treatment (fight_treatment.gd or a subclass); set before the screen enters the tree.
var treatment: RefCounted
## Seconds left of the step showing.
var _wait: float = 0.0


func _ensure_stage() -> void:
	var fresh: bool = _frame == null
	super()
	if fresh and treatment != null:
		_keeper = treatment.call("make_motion", _cards)


## Plays a fight: each step of the replay is shown for its hold time, then the next.
func play(replay: FightReplay) -> void:
	# a new fight starts from a clean table: no card of the last fight is left fading or popping
	if _keeper != null:
		_keeper.clear()
	_replay = replay
	_shown_lunge = {}
	_shown_splashes = []
	_recoiled = false
	_step = -1
	_wait = 0.0
	_next_step()


## Jumps to the end of the fight being played. Once there, a second skip does nothing: the
## result keeps its hold and then finishes.
func skip() -> void:
	if _replay == null or _step >= _replay.steps.size() - 1:
		return
	_step = _replay.steps.size() - 2
	_wait = 0.0
	_next_step()


func is_playing() -> bool:
	return _replay != null


func _process(delta: float) -> void:
	super(delta)
	if _replay == null:
		return
	_wait -= delta * speed
	if _wait <= 0.0:
		_next_step()


func _next_step() -> void:
	_step += 1
	if _step >= _replay.steps.size():
		_replay = null
		playback_finished.emit()
		return
	var step: Dictionary = _replay.steps[_step]
	_keeper.speed = maxf(speed, 0.01)
	var view: Dictionary = step["state"]
	show_state(view)
	Sound.fight_step(step, _replay.steps[_step - 1] if _step > 0 else {})
	_wait = _f(step["hold"])
	if _step == _replay.steps.size() - 1:
		# the result: no dead unit still fading over its slot
		settle()
		result_shown.emit()
