extends HBoxContainer
## "Look: [Plain] [Folk Print]": picks the look direction (ThemeDirections). The active one is
## pressed. Emits `chosen`; the app switches, saves the choice and rebuilds the screen.

signal chosen(direction: String)

const UiTheme := preload("res://src/ui/ui_theme.gd")
const Directions := preload("res://src/ui/theme_directions.gd")


func _init() -> void:
	name = "ThemeSwitch"
	add_theme_constant_override("separation", 8)
	var title: Label = UiTheme.label("Look", UiTheme.FONT_SMALL, UiTheme.TEXT_DIM)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)
	for id: String in Directions.ORDER:
		var option: Button = UiTheme.button(Directions.TITLES[id], 0, UiTheme.FONT_SMALL)
		option.name = "Look_" + id
		option.custom_minimum_size = Vector2(0, 52)
		option.toggle_mode = true
		option.button_pressed = id == UiTheme.direction
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.pressed.connect(_on_pick.bind(id, option))
		add_child(option)


func _on_pick(id: String, option: Button) -> void:
	option.button_pressed = true
	if id != UiTheme.direction:
		chosen.emit(id)
