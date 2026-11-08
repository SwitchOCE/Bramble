extends Control
## Earned tribe bonuses, named on screen and shown on their tribe portraits.

const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const HEIGHT: float = 40.0
const WIDTH: float = 152.0
const GAP: float = 16.0
const CAPTION_WIDTH: float = 184.0

var bonuses: Dictionary = {}
var tribes: Array = []
var chips: Array[Control] = []
var _caption: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption = UiTheme.head("Tribe bonus", UiTheme.FONT_SMALL)
	_caption.name = "Caption"
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.visible = false
	add_child(_caption)
	resized.connect(_place)


func show_bonuses(lobby: Array, values: Dictionary) -> void:
	tribes.clear()
	bonuses = values.duplicate()
	for child: Control in chips:
		remove_child(child)
		child.queue_free()
	chips.clear()
	for value: Variant in lobby:
		if Data.i(bonuses, str(value)) > 0:
			tribes.append(value)
	_caption.visible = not tribes.is_empty()
	for value: Variant in tribes:
		var tribe: String = str(value)
		var bonus: int = Data.i(bonuses, tribe)
		var button: Panel = Panel.new()
		button.name = tribe.replace(" ", "") + "Bonus"
		button.tooltip_text = "%s tribe bonus: +%d/+%d." % [tribe, bonus, bonus]
		button.add_theme_stylebox_override(
			"panel", UiTheme.flat_box(UiTheme.BIRCH, UiTheme.INK, 2, 20)
		)

		add_child(button)
		chips.append(button)
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
	var chips_width: float = tribes.size() * (WIDTH + GAP) - GAP
	var captioned: bool = not tribes.is_empty() and size.x >= CAPTION_WIDTH + GAP + chips_width
	_caption.visible = captioned
	var start: float = CAPTION_WIDTH + GAP if captioned else 0.0
	var gap: float = minf(
		GAP, maxf(0.0, (size.x - start - tribes.size() * WIDTH) / maxf(tribes.size() - 1, 1))
	)
	_caption.position = Vector2.ZERO
	_caption.size = Vector2(CAPTION_WIDTH, HEIGHT)
	for index: int in chips.size():
		var icon: Control = chips[index]
		icon.position = Vector2(start + index * (WIDTH + gap), 0)
		icon.size = Vector2(WIDTH, HEIGHT)
