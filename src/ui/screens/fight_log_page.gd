extends Control
## A full-height reference page; never occupies the combat playmat.

const UiTheme := preload("res://src/ui/ui_theme.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")

var _panel: WoodPanel
var _head: Label
var _text: RichTextLabel
var _close: TokenButton


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 60
	_panel = WoodPanel.new(WoodPanel.Kind.PAPER)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	_head = UiTheme.head("Last fight", UiTheme.FONT_TITLE)
	add_child(_head)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = true
	for key: String in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		_text.add_theme_font_size_override(key, UiTheme.FONT_BODY)
	add_child(_text)
	_close = TokenButton.new("", "close")
	_close.pressed.connect(queue_free)
	add_child(_close)
	resized.connect(_layout)
	ready.connect(_layout)


func setup(title: String, words: String) -> void:
	_head.text = title + " · Last fight"
	_text.text = "[b]Front[/b]  F1   F2   F3   F4\n[b]Back[/b]      B1   B2   B3\n\n" + words


func _layout() -> void:
	_head.position = Vector2(40, 22)
	_head.size = Vector2(size.x - 210, 90)
	_close.position = Vector2(size.x - 156, 20)
	_close.size = Vector2(122, 131)
	_text.position = Vector2(44, 158)
	_text.size = Vector2(size.x - 88, size.y - 192)
