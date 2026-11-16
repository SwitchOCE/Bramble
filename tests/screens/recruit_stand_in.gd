extends Control
## A STAND-IN controller for proving the recruit screen's input with tools/look, driving the real
## rules core: a bridge-card session (tests/screens/core_view.gd) whose view the screen draws.
## Each action the screen asks for goes to GameSession.act unchanged; a refusal shows as the
## message. End turn plays the round's fights and starts the next round. It is not the game flow.

const CoreView := preload("res://tests/screens/core_view.gd")
const LINE: String = "recruit stand-in: %s"

var game: GameSession
var screen: RecruitScreen


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	game = CoreView.playable()
	screen = (load("res://src/screens/recruit/recruit_screen.tscn") as PackedScene).instantiate()
	screen.state = CoreView.recruit_state(game, 0)
	add_child(screen)
	screen.action_requested.connect(_on_action)


func _on_action(action: Dictionary) -> void:
	var refused: String = game.act(0, action)
	print(LINE % ("%s -> %s" % [JSON.stringify(action), refused if refused != "" else "ok"]))
	if action.get("type", "") == "end_turn" and refused == "":
		for each: PlayerState in game.alive_players():
			if not each.turn_ended:
				game.end_turn(each.id)
		game.finish_round()
		game.start_round()
		game.player(0).gold = 30
	var message: String = refused.left(1).to_upper() + refused.substr(1)
	screen.show_state(CoreView.recruit_state(game, 0, message))
