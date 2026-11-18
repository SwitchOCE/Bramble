extends "res://tests/screens/feel/feel_game.gd"
## A reproducible purchase -> merge -> golden play -> actual core reward -> Discover.
## The optional interrupt scenario clicks Refresh during the first presentation beat.

var _actions: Array[Dictionary] = []
var _elapsed: float = 0.0
var _active_frames: int = 0
var _events: Array[Dictionary] = []
var _mode: String = ""
var _formed: bool = false
var _redraw_requested: bool = false
var _redrawn: bool = false
var _transitions: Array[Dictionary] = []
var _observed: Dictionary = {}


func feel_setup(scenario: Dictionary) -> void:
	super(scenario)
	var me: PlayerState = game.flow.human()
	_mode = str(scenario.get("mode", "purchase"))
	_redraw_requested = scenario.get("counter_redraw", false) == true
	if _mode == "full_hand":
		me.hand.clear()
		for _i: int in 7:
			me.hand.append(
				game.flow.session.new_unit(
					game.flow.content.library.get_card(&"hedge-knight"), true
				)
			)
	elif _mode == "discover":
		me.discover_options.assign([&"brock-cub", &"hedge-knight", &"lance-corporal"])
	me.shop_units.clear()
	me.shop_units.append(&"brock-cub")
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()
	game.recruit._triple.pace = RecruitTripleMotion.PACES[str(scenario.get("pace", "brisk"))]
	game.recruit.action_requested.connect(_action)


func _action(action: Dictionary) -> void:
	_actions.append(action.duplicate(true))
	_events.append({"time": _elapsed, "action": action.duplicate(true)})
	_capture_transition()


func _process(delta: float) -> void:
	_elapsed += delta
	if game == null:
		return
	if _mode == "full_hand" and not _formed and _elapsed >= 0.6:
		_formed = true
		var session: GameSession = game.flow.session
		var me: PlayerState = game.flow.human()
		var first: int = session.events.size()
		RecruitContext.new(session, session.recruit, me).summon(&"brock-cub", 6)
		# Hold this rule edge on the recruit screen, rather than the controller changing to
		# combat. These are the core's real summon/end-turn settlement and resulting events.
		session.recruit.end_turn(me)
		game.recruit.show_state(
			ViewAdapter.recruit_state(game.flow, "", session.events.slice(first))
		)
		_events.append({"time": _elapsed, "fixture": "summon then end-turn settlement"})
	if game.recruit._triple.active():
		_active_frames += 1
		_capture_transition()
		if _redraw_requested and not _redrawn and game.recruit._triple._age >= 0.35:
			_redrawn = true
			var age: float = game.recruit._triple._age
			game.recruit._counts._held = {"gold": game.flow.human().gold}
			game.recruit._counts.arrived()
			_events.append(
				{
					"time": _elapsed,
					"fixture": "counter arrival redraw",
					"age_before": age,
					"age_after": game.recruit._triple._age,
					"active_after": game.recruit._triple.active()
				}
			)


func _capture_transition() -> void:
	for run: Dictionary in game.recruit._triple._runs:
		var uid: int = run["uid"]
		if _observed.has(uid):
			continue
		_observed[uid] = true
		var sources: Array[Dictionary] = []
		for source: Dictionary in run["sources"]:
			var at: Vector2 = source["at"]
			var source_scale: Vector2 = source["scale"]
			var card: Dictionary = source["card"]
			sources.append(
				{
					"origin": source["origin"],
					"stats_from": source["stats_from"],
					"at": [at.x, at.y],
					"scale": [source_scale.x, source_scale.y],
					"id": card["id"],
					"uid": card.get("uid", -1),
					"attack": card["attack"],
					"health": card["health"]
				}
			)
		var hub: Vector2 = run["hub"]
		var end: Vector2 = run["end"]
		_transitions.append(
			{
				"time": _elapsed,
				"uid": uid,
				"hub": [hub.x, hub.y],
				"end": [end.x, end.y],
				"sources": sources
			}
		)


func feel_point(target: String) -> Vector2:
	if target.begins_with("discover:"):
		var option: Control = game.recruit.node_for("discover", target.get_slice(":", 1).to_int())
		return option.position + option.size / 2.0
	if target == "refresh":
		var button: Control = game.recruit.find_child("Button_refresh", true, false)
		return button.position + button.size / 2.0
	return super(target)


func feel_report() -> Dictionary:
	var me: PlayerState = game.flow.human()
	var hand: Array[Dictionary] = []
	for unit: Unit in me.hand:
		hand.append({"id": String(unit.def.id), "uid": unit.uid, "golden": unit.golden})
	var goldens: Array[Dictionary] = []
	for unit: Unit in me.board_units():
		if unit.golden:
			goldens.append({"id": String(unit.def.id), "slot": unit.slot})
	return {
		"actions": _actions,
		"events": _events,
		"transitions": _transitions,
		"hand": hand,
		"board_goldens": goldens,
		"discover_options": me.discover_options.size(),
		"active_frames": _active_frames,
		"motion_seconds": RecruitTripleMotion.duration() * game.recruit._triple.pace,
		"active_at_end": game.recruit._triple.active(),
	}
