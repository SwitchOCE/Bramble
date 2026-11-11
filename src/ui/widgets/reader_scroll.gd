extends Node
## Passive hover readers retain wheel scrolling while their text lets taps through.

var _rules: RichTextLabel


func _init(rules: RichTextLabel) -> void:
	_rules = rules


func _input(event: InputEvent) -> void:
	var wheel: InputEventMouseButton = event as InputEventMouseButton
	if wheel == null or not wheel.pressed or not _rules.is_visible_in_tree():
		return
	if not _rules.get_global_rect().has_point(_rules.get_global_mouse_position()):
		return
	var direction: int = 0
	if wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		direction = 1
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
		direction = -1
	if direction == 0:
		return
	var bar: VScrollBar = _rules.get_v_scroll_bar()
	bar.value += direction * _rules.get_theme_font_size("normal_font_size") * 3.0
	get_viewport().set_input_as_handled()
