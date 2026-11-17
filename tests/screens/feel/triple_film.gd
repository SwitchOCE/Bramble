extends "res://tests/screens/feel/feel_game.gd"
## A reproducible purchase -> merge -> golden play -> actual core reward -> Discover.
## The optional interrupt scenario clicks Refresh during the first presentation beat.

var _actions: Array[Dictionary] = []
var _elapsed: float = 0.0
var _active_frames: int = 0
var _events: Array[Dictionary] = []


func feel_setup(scenario: Dictionary) -> void:
	super(scenario)
	var me: PlayerState = game.flow.human()
	me.shop_units.clear()
	me.shop_units.append(&"brock-cub")
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()
	game.recruit._triple.pace = RecruitTripleMotion.PACES[str(scenario.get("pace", "brisk"))]
	game.recruit.action_requested.connect(_action)


func _action(action: Dictionary) -> void:
	_actions.append(action.duplicate(true))
	_events.append({"time": _elapsed, "action": action.duplicate(true)})


func _process(delta: float) -> void:
	_elapsed += delta
	if game != null and game.recruit._triple.active():
		_active_frames += 1


func feel_point(target: String) -> Vector2:
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
		"hand": hand,
		"board_goldens": goldens,
		"discover_options": me.discover_options.size(),
		"active_frames": _active_frames,
		"motion_seconds": RecruitTripleMotion.duration() * game.recruit._triple.pace,
		"active_at_end": game.recruit._triple.active(),
		"added_input_lock_seconds": 0,
	}
