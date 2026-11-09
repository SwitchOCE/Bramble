extends Panel
## A keyword's reminder text, kept off the card face. Rules text marks each keyword as a link
## ([url=Word]Word[/url]); hovering it (PC) or tapping it (phone) shows what it means on this slip.
## The slip looks unlike rules text on purpose: italic, smaller, muted ink on its own paper slip.
## On a phone it can't be smaller than the phone minimum, so there it is set apart by the slip, the
## italic and the colour, and the details panel's rules text is a size larger instead.
##
## Floating (default), it sits just under the watched text's last line, or above the text when
## there's no room below.
## Docked, its owner places it and listens for `shown_changed`.

signal shown_changed

const UiTheme := preload("res://src/ui/ui_theme.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")

## Reminder text on a desktop: smaller than the rules beside it (31), and above the desktop floor.
const DESKTOP_FONT: int = 25
const PAD: float = 14.0
## The prefix that marks a link as a keyword, so other links in the same text are left alone.
const LINK: String = "kw:"

## The keyword shown, "" when hidden (read by tests).
var keyword: String = ""
## Placed by its owner instead of floating beside the text.
var docked: bool = false
## Set to sit just above this panel instead, for a small note whose rules may already scroll.
var above: Control = null
## The card the watched text describes, for reminders that depend on it (a golden Burner).
var view: Dictionary = {}
## func(keyword: String) -> String: the reminder for a word. Defaults to the keyword rules.
var reminder_fn: Callable = Callable()

var _text: RichTextLabel
var _watched: RichTextLabel
var _shown_frame: int = -10


func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	add_theme_stylebox_override("panel", box())
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_color_override("default_color", UiTheme.REMINDER)
	_text.add_theme_font_override("normal_font", UiTheme.italic_font())
	_text.add_theme_font_override("italics_font", UiTheme.italic_font())
	_text.add_theme_font_override("bold_font", UiTheme.bold_italic_font())
	_text.add_theme_font_override("bold_italics_font", UiTheme.bold_italic_font())
	_text.add_theme_constant_override("line_separation", 0)
	add_child(_text)


## The slip's paper: a cream note with a thin muted edge, unlike the ink-edged rules slips.
static func box() -> StyleBoxFlat:
	var slip: StyleBoxFlat = UiTheme.flat_box(UiTheme.CREAM, UiTheme.REMINDER, 2, 10)
	slip.border_width_left = 6
	return slip


## The phone keeps everything at its minimum, so the reminder can't shrink there.
static func font_size(phone: bool) -> int:
	return UiTheme.MIN_FONT if phone else DESKTOP_FONT


## The rules-text mark for a keyword: a link the slip answers to.
static func link(word: String, shown: String = "") -> String:
	return "[url=%s%s]%s[/url]" % [LINK, word, word if shown.is_empty() else shown]


## Listens to a rules text's links: hover shows the reminder, leaving hides it (PC); a tap shows
## it, and tapping the same word again hides it (phone, where touch has no hover to end).
func watch(rich: RichTextLabel) -> void:
	_watched = rich
	rich.meta_underlined = true
	rich.meta_hover_started.connect(_on_hover_started)
	rich.meta_hover_ended.connect(_on_hover_ended)
	rich.meta_clicked.connect(_on_clicked)


func show_keyword(word: String) -> void:
	var words: String = _reminder(word)
	if words.is_empty():
		hide_slip()
		return
	keyword = word
	_shown_frame = Engine.get_process_frames()
	var phone: bool = _is_phone()
	_text.add_theme_font_size_override("normal_font_size", font_size(phone))
	_text.add_theme_font_size_override("bold_font_size", font_size(phone))
	_text.add_theme_font_size_override("italics_font_size", font_size(phone))
	_text.add_theme_font_size_override("bold_italics_font_size", font_size(phone))
	# A desktop reads reminders below the phone minimum, as it does tile rules.
	if phone:
		_text.remove_meta("desktop_text")
	else:
		_text.set_meta("desktop_text", true)
	_text.text = words
	visible = true
	if not docked:
		_float()
	shown_changed.emit()


func hide_slip() -> void:
	if keyword.is_empty() and not visible:
		return
	keyword = ""
	visible = false
	_text.text = ""
	shown_changed.emit()


## The slip's height at this width, for an owner that docks it.
func height_for(width: float) -> float:
	_text.position = Vector2(PAD + 4.0, PAD / 2.0)
	_text.size = Vector2(maxf(width - PAD * 2.0 - 4.0, 40.0), 10.0)
	return _text.get_content_height() + PAD + 4.0


## Lays the slip out in this rect (docked owners call it).
func place(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	_text.position = Vector2(PAD + 4.0, PAD / 2.0)
	_text.size = Vector2(rect.size.x - PAD * 2.0 - 4.0, rect.size.y - PAD)


## The reminder as the slip shows it: "[b]Bristle:[/b] When an enemy ...", every word italic.
func _reminder(word: String) -> String:
	var words: String = ""
	if reminder_fn.is_valid():
		words = str(reminder_fn.call(word))
	else:
		words = reminder_bbcode(word)
	return words


## A keyword's reminder, then any term it introduces (Pack's cycle).
static func reminder_bbcode(word: String) -> String:
	var text: String = KeywordRules.text(word)
	if text.is_empty():
		return ""
	var lines: PackedStringArray = ["[b]%s:[/b] %s" % [_title(word), text]]
	for term: String in KeywordRules.terms_in(text):
		if term != word:
			lines.append("[b]%s:[/b] %s" % [_title(term), KeywordRules.text(term)])
	return "\n".join(lines)


static func _title(word: String) -> String:
	return "Golden (*)" if word == "*" else word


func _float() -> void:
	if _watched == null or not is_inside_tree():
		return
	var anchor: Rect2 = _watched.get_global_rect()
	var parent: Control = get_parent() as Control
	var origin: Vector2 = parent.get_global_rect().position if parent != null else Vector2.ZERO
	var screen: Rect2 = get_viewport_rect()
	var wide: float = clampf(anchor.size.x, 420.0, screen.size.x - 32.0)
	var tall: float = height_for(wide)
	var x: float = clampf(anchor.position.x, 16.0, screen.size.x - wide - 16.0)
	# Right under the last line of rules, so it reads as part of the note it explains.
	var used: float = minf(float(_watched.get_content_height()), anchor.size.y)
	var y: float = anchor.position.y + used + 6.0
	if above != null:
		var panel: Rect2 = above.get_global_rect()
		wide = panel.size.x
		tall = height_for(wide)
		x = panel.position.x
		y = panel.position.y - tall - 6.0
	elif y + tall > screen.size.y - 8.0:
		y = maxf(8.0, anchor.position.y - tall - 6.0)
	place(Rect2(Vector2(x, y) - origin, Vector2(wide, tall)))


func _on_hover_started(meta: Variant) -> void:
	var word: String = _word(meta)
	if not word.is_empty():
		show_keyword(word)


func _on_hover_ended(meta: Variant) -> void:
	# Touch has no hover to end, so a tapped reminder stays until the next tap.
	if _is_phone() or _word(meta) != keyword:
		return
	hide_slip()


func _on_clicked(meta: Variant) -> void:
	var word: String = _word(meta)
	if word.is_empty():
		return
	# A tap also arrives as hover, in the same frame: that tap opens the slip, a later one shuts it.
	if word == keyword and Engine.get_process_frames() - _shown_frame > 1:
		hide_slip()
	else:
		show_keyword(word)


static func _word(meta: Variant) -> String:
	var value: String = str(meta)
	return value.trim_prefix(LINK) if value.begins_with(LINK) else ""


static func _is_phone() -> bool:
	return CardView.is_phone()
