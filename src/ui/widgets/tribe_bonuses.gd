extends Control
## The lobby's tribes, each with its standing bonus on its portrait.

const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const HEIGHT: float = 40.0
const WIDTH: float = 152.0
const GAP: float = 16.0

var bonuses: Dictionary = {}
var tribes: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)


func show_bonuses(lobby: Array, values: Dictionary) -> void:
	tribes = lobby.duplicate()
	bonuses = values.duplicate()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	for value: Variant in tribes:
		var tribe: String = str(value)
		var bonus: int = Data.i(bonuses, tribe)
		var button: Panel = Panel.new()
		button.name = tribe.replace(" ", "") + "Bonus"
		button.tooltip_text = (
			"%s: +%d/+%d tribe bonus. Harvest Supper grants this to owned units and future arrivals."
			% [tribe, bonus, bonus]
		)
		button.add_theme_stylebox_override(
			"panel", UiTheme.flat_box(UiTheme.BIRCH, UiTheme.INK, 2, 20)
		)

		add_child(button)
		var icon: ArtFrame = ArtFrame.new()
		icon.texture = UiTheme.portrait([tribe])
		icon.radius = 18
		icon.line = 2
		icon.position = Vector2(2, 2)
		icon.size = Vector2(36, 36)
		button.add_child(icon)
		var label: Label = UiTheme.number("+%d/+%d" % [bonus, bonus], UiTheme.FONT_SMALL)
		label.name = "Bonus"
		label.position = Vector2(42, 0)
		label.size = Vector2(WIDTH - 46, HEIGHT)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
	_place()


func _place() -> void:
	for index: int in get_child_count():
		var icon: Control = get_child(index) as Control
		icon.position = Vector2(index * (WIDTH + GAP), 0)
		icon.size = Vector2(WIDTH, HEIGHT)
