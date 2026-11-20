extends Control
## Make the same board as recruit_pigeon_marks.tscn, then let the real recruit input move the
## Territorial. Record the core's zone changes and the hand marks the screen receives.

const Marks := preload("res://tests/screens/recruit_pigeon_marks.gd")

var _screen: RecruitScreen
var _flow: GameFlow
var _reserve_uid: int
var _initial: Dictionary
var _moves: Array[Dictionary] = []


func _ready() -> void:
	GameSettings.set_drop_by_middle(false, false)
	_flow = Marks.make_flow()
	_reserve_uid = _flow.human().hand[0].uid
	_screen = Marks.SCREEN.instantiate()
	_screen.state = ViewAdapter.recruit_state(_flow)
	_screen.action_requested.connect(_action)
	add_child(_screen)
	_initial = _marks()


func feel_point(target: String) -> Variant:
	var box: Vector2 = _screen.card_box()
	match target:
		"reserve":
			var place: Vector3 = _screen.hand_place(0, _flow.human().hand.size())
			return Vector2(place.x, place.y) + box * Vector2(0.5, 0.3)
		"renown_slot":
			return _screen.slot_xy(2) + box / 2.0
		"hand_tray":
			return Vector2(960, 1015)
	return null


func _action(action: Dictionary) -> void:
	var first: int = _flow.session.events.size()
	var reason: String = _flow.act(action)
	assert(reason.is_empty(), reason)
	var events: Array = _flow.session.events.slice(first)
	_screen.show_state(ViewAdapter.recruit_state(_flow, reason, events))
	for event: Dictionary in events:
		if GlassPieces.as_int(event.get("uid", -1)) == _reserve_uid:
			if str(event["type"]) in ["play", "to_hand"]:
				_moves.append(
					{"frame": Engine.get_frames_drawn(), "event": event, "marks": _marks()}
				)


func _marks() -> Dictionary:
	var hand: Array = _screen.state["hand"]
	var board: Array = _screen.state["board"]
	var sentry: Dictionary = board[0]
	var display: Dictionary = _flow.content.display_table()
	return {
		"hand_size": hand.size(),
		"reserve_limit": _screen.state.get("reserve_limit", 0),
		"sentry_pips": CardTerms.pips(sentry, display),
	}


func feel_report() -> Dictionary:
	assert(_moves.size() == 2)
	assert(_flow.human().board[2] == null and _flow.human().hand[0].uid == _reserve_uid)
	return {"initial": _initial, "moves": _moves, "final": _marks()}
