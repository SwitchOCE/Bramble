extends Control
## A scene for proving tools/look: a button that counts its presses, and keys that log on purpose.
## E pushes an error and a warning; Q quits with code 3. tools/look/demo.sh drives it.

const PRESSED_LINE: String = "look demo: pressed %d"
const ERROR_TEXT: String = "look demo: E was pressed"

var _presses: int = 0

@onready var _button: Button = $Button
@onready var _label: Label = $Label


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_E:
		push_error(ERROR_TEXT)
		push_warning("look demo: a warning after the error")
	elif key.keycode == KEY_Q:
		get_tree().quit(3)


func _on_button_pressed() -> void:
	_presses += 1
	_label.text = "Pressed %d time%s" % [_presses, "" if _presses == 1 else "s"]
	print(PRESSED_LINE % _presses)
