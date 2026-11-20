extends Control
## Seed the round as in fight_renown.gd and play it through the real fight screen.
## The report ties combat event indices to the replay steps and zero-based movie frames.

const CoreKit := preload("res://tests/core/core_kit.gd")
const SCREEN: PackedScene = preload("res://src/screens/fight/fight_screen.tscn")

@export var pigeon: bool = false

var _screen: FightScreen
var _replay: FightReplay
var _events: Array
var _event_steps: Array[int] = []
var _step_frames: Array[int] = []
var _you_side: int


func _ready() -> void:
	process_priority = 1  # Observe the new step after the screen processes it, before it draws.
	var flow: GameFlow = GameFlow.create(GameContent.load_default(), 11)
	flow.start_round()
	var session: GameSession = flow.session
	var me: PlayerState = flow.human()
	var them: PlayerState = session.player(session.opponent_of(GameFlow.HUMAN))
	if pigeon:
		CoreKit.put(session, me, "sentry", 0)
		CoreKit.put(session, me, "the-colonel", 4)
		CoreKit.put(session, me, "bugler", 5)
		CoreKit.put(session, me, "air-marshal", 6)
		me.slots[0].renown = 3
		me.slots[0].keywords.append(&"taunt")
		me.hand.append(CoreKit.unit(session, "territorial"))
	else:
		CoreKit.put(session, me, "thimble-sentinel", 0)
		CoreKit.put(session, me, "fencing-master", 1)
		CoreKit.put(session, me, "dormouse-cook", 2)
		CoreKit.put(session, me, "thimble-captain", 5)
	# A single opponent tuned to survive the opening exchanges and let the effects resolve.
	var enemy: Unit = CoreKit.put(session, them, "regimental-sergeant-major", 0)
	enemy.stats.set_attack = 11 if pigeon else 7
	enemy.stats.set_health = 35
	session.recruit.refresh_auras(me)
	me.turn_ended = true
	them.turn_ended = true
	var record: Dictionary = flow.finish_round()
	var logged: Array = record["events"]
	_events = FightReplay.mark_pile_ons(logged)
	_you_side = CoreUtil.to_int(record["you_side"])
	_replay = FightReplay.start(
		ViewAdapter.fight_base(flow, record), ViewAdapter.catalog(flow.content)
	)
	var damage: int = CoreUtil.to_int(record["damage"])
	for event: Dictionary in _events:
		var previous_state: Variant = (
			null if _replay.steps.is_empty() else _replay.steps.back()["state"]
		)
		_replay.apply(event, damage)
		var step: Dictionary = _replay.steps.back()
		# A grouped step keeps its index but replaces its state with the latest view.
		_event_steps.append(
			-1 if is_same(previous_state, step["state"]) else _replay.steps.size() - 1
		)
	_screen = SCREEN.instantiate()
	_screen.state = _replay.steps[0]["state"]
	add_child(_screen)


func feel_setup(_scenario: Dictionary) -> void:
	_screen.play(_replay)


func _process(_delta: float) -> void:
	if _screen.is_playing() and _screen._step == _step_frames.size():
		_step_frames.append(Engine.get_frames_drawn())


func feel_report() -> Dictionary:
	var holds: float = 0.0
	for step: Dictionary in _replay.steps:
		holds += GlassPieces.as_float(step["hold"])
	return {
		"you_side": _you_side,
		"events": _events,
		"event_steps": _event_steps,
		"step_frames": _step_frames,
		"steps": _replay.steps.size(),
		"planned_seconds": holds,
		"finished": not _screen.is_playing() and _step_frames.size() == _replay.steps.size(),
	}
