extends "res://src/ui/widgets/wood_panel.gd"
## The combat log as a pinned paper note (.wk-log): earlier lines muted at the top, the line being
## played bold below them with a red rule. Each event's line either starts a new sentence or joins
## the current one, so one attack reads as one short paragraph.

const HEAD_H: float = 62.0
const PAD: float = 34.0
const CURRENT_MAX: float = 0.72

var _head: Label
var _title: Label
var _older: RichTextLabel
var _current: RichTextLabel
var _plain: PackedStringArray = []


func _init() -> void:
	super(Kind.PAPER)
	nails = true
	_head = UiTheme.burned("Combat log", UiTheme.FONT_SMALL, UiTheme.MUTE)
	add_child(_head)
	_title = UiTheme.burned("", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.set_meta("ellipsis_ok", true)
	add_child(_title)
	_older = _text_box(UiTheme.FONT_SMALL, UiTheme.MUTE)
	_older.scroll_active = true
	_older.scroll_following = true
	_older.get_v_scroll_bar().modulate = Color.TRANSPARENT
	_current = _text_box(UiTheme.FONT_BODY, UiTheme.INK)
	_current.add_theme_font_override("normal_font", UiTheme.bold_font())
	# It scrolls rather than fits: fit_content lets one long attack push the note off the screen.
	_current.scroll_active = true
	_current.scroll_following = true
	_current.get_v_scroll_bar().modulate = Color.TRANSPARENT
	resized.connect(_layout)
	ready.connect(_layout)


func _text_box(font_size: int, colour: Color) -> RichTextLabel:
	var box: RichTextLabel = RichTextLabel.new()
	box.bbcode_enabled = true
	box.scroll_active = false
	box.selection_enabled = false
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_font_size_override("normal_font_size", font_size)
	box.add_theme_font_size_override("bold_font_size", font_size)
	box.add_theme_font_size_override("italics_font_size", font_size)
	box.add_theme_color_override("default_color", colour)
	box.add_theme_constant_override("line_separation", -2)
	add_child(box)
	return box


func set_title(words: String) -> void:
	_title.text = words.to_upper()


func clear() -> void:
	_older.clear()
	_current.clear()
	_current.text = ""
	_plain.clear()
	_layout()


## Adds an event's line. `new_sentence` moves what was current up into the muted lines first.
func push(line: String, new_sentence: bool) -> void:
	_plain.append(line)
	if line.is_empty():
		return
	if new_sentence or _current.text.is_empty():
		if not _current.text.is_empty():
			_older.append_text(_current.text + "\n")
		_current.text = line
	else:
		_current.text = _current.text + " " + line
	_layout()


## Every line pushed since the last clear, joined (tests).
func all_text() -> String:
	return "\n".join(_plain)


func _layout() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0:
		return
	_head.position = Vector2(PAD, 22)
	_head.size = Vector2(240, 42)
	_title.position = Vector2(PAD + 230.0, 22)
	_title.size = Vector2(w - PAD * 2.0 - 230.0 - 36.0, 42)
	var room: float = h - HEAD_H - 28.0
	_current.position = Vector2(PAD + 18.0, 0)
	_current.size = Vector2(w - PAD * 2.0 - 18.0, 0)
	var used: float = minf(_current.get_content_height(), room * CURRENT_MAX)
	_current.size = Vector2(w - PAD * 2.0 - 18.0, used)
	_current.position = Vector2(PAD + 18.0, h - 18.0 - used)
	_older.position = Vector2(PAD, HEAD_H)
	_older.size = Vector2(w - PAD * 2.0, maxf(room - used - 10.0, 0.0))
	queue_redraw()


func _draw() -> void:
	super()
	if _current.text.is_empty():
		return
	var top: float = _current.position.y + 2.0
	draw_rect(Rect2(PAD - 2.0, top, 7.0, _current.size.y - 4.0), UiTheme.YARN)
