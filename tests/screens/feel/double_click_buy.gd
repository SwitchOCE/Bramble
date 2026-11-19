extends "res://tests/screens/feel/feel_game.gd"
## The feel runner sends synthetic presses without a platform double-click flag. This fixture
## marks the second press as the OS would; routing, purchase and motion remain the real game's.

var _presses: int = 0
var _actions: Array[Dictionary] = []
var _gold_before: int = 0


func feel_setup(scenario: Dictionary) -> void:
	super(scenario)
	var me: PlayerState = game.flow.human()
	me.shop_units.assign([&"sentry"])
	game.recruit.show_state(ViewAdapter.recruit_state(game.flow))
	game.recruit.settle()
	_gold_before = me.gold
	game.recruit.action_requested.connect(_action)


func _input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		_presses += 1
		button.double_click = _presses == 2


func _action(action: Dictionary) -> void:
	_actions.append(action.duplicate(true))


func feel_report() -> Dictionary:
	var me: PlayerState = game.flow.human()
	var hand: Array[String] = []
	for card: Unit in me.hand:
		hand.append(String(card.def.id))
	return {
		"presses": _presses,
		"actions": _actions,
		"gold_before": _gold_before,
		"gold_after": me.gold,
		"hand": hand,
		"board_units": me.board_units().size(),
		"holding": game.recruit.is_holding(),
	}
