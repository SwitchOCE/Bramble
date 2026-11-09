extends Control
## A scrollable forecast beside the hand, without covering recruiting actions or the reader.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const RecruitHeld := preload("res://src/ui/screens/recruit_held.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")

var shown: Dictionary = {}
var _panel: WoodPanel
var _heading: Label
var _notes: RichTextLabel


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	_panel = WoodPanel.new(WoodPanel.Kind.PAPER)
	_panel.nails = false
	add_child(_panel)
	_heading = UiTheme.head("Birds away", UiTheme.FONT_BODY)
	add_child(_heading)
	_notes = RichTextLabel.new()
	_notes.scroll_active = true
	_notes.mouse_filter = Control.MOUSE_FILTER_STOP
	_notes.add_theme_color_override("default_color", UiTheme.INK)
	_notes.add_theme_font_size_override("normal_font_size", UiTheme.MIN_FONT)
	add_child(_notes)
	resized.connect(_layout)
	ready.connect(_layout)


func show_state(state: Dictionary) -> void:
	shown = RecruitHeld.sky_card(state)
	visible = not shown.is_empty()
	_notes.text = "Now → landing\n" + Data.s(shown, "text")
	_layout()


func _layout() -> void:
	_panel.size = size
	_heading.position = Vector2(16, 10)
	_heading.size = Vector2(maxf(0, size.x - 32), 46)
	_notes.position = Vector2(16, 60)
	_notes.size = Vector2(maxf(0, size.x - 32), maxf(0, size.y - 76))
