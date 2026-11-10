extends Control
## The gear's menu during a game: back to the game, how to play, settings, leave. Leaving asks once,
## because a game can't be picked up again.

signal closed
signal guide_requested
signal settings_requested
signal leave_requested

const UiTheme := preload("res://src/ui/ui_theme.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")

const WIDTH: float = 620.0
const LEAF_H: float = 136.0

var _panel: WoodPanel
var _title: Label
var _leaves: Array[LeafButton] = []
var _leave: LeafButton


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	var shade: ColorRect = ColorRect.new()
	shade.color = UiTheme.SHADE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_panel = WoodPanel.new(WoodPanel.Kind.OAK)
	add_child(_panel)
	_title = UiTheme.head("Paused", UiTheme.FONT_TITLE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_title)
	_add_leaf("Back to game", LeafButton.Colour.MOSS, _close)
	_add_leaf("How to play", LeafButton.Colour.BIRCH, func() -> void: guide_requested.emit())
	_add_leaf("Settings", LeafButton.Colour.BIRCH, func() -> void: settings_requested.emit())
	_leave = _add_leaf("Leave game", LeafButton.Colour.ACORN, _on_leave)
	resized.connect(_layout)
	ready.connect(_layout)


func add_fight_actions(log_action: Callable, replay_action: Callable) -> void:
	_add_leaf("Log", LeafButton.Colour.BIRCH, log_action)
	_add_leaf(
		"Watch again",
		LeafButton.Colour.BIRCH,
		func() -> void:
			_close()
			replay_action.call()
	)


func _add_leaf(words: String, colour: LeafButton.Colour, on_press: Callable) -> LeafButton:
	var leaf: LeafButton = LeafButton.new()
	leaf.colour = colour
	leaf.set_face(words)
	leaf.pressed.connect(on_press)
	_panel.add_child(leaf)
	_leaves.append(leaf)
	return leaf


func _close() -> void:
	closed.emit()
	queue_free()


func _on_leave() -> void:
	if _leave.text == "Leave game":
		_leave.set_face("Sure? Game ends")
		return
	closed.emit()
	leave_requested.emit()


func _layout() -> void:
	var height: float = 110.0 + _leaves.size() * (LEAF_H + 10.0) + 20.0
	_panel.position = (size - Vector2(WIDTH, height)) / 2.0
	_panel.size = Vector2(WIDTH, height)
	_title.position = Vector2(0, 22)
	_title.size = Vector2(WIDTH, 80)
	var y: float = 110.0
	for leaf: LeafButton in _leaves:
		leaf.position = Vector2(30, y)
		leaf.size = Vector2(WIDTH - 60.0, LEAF_H)
		y += LEAF_H + 10.0
