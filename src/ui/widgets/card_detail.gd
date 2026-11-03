extends PanelContainer
## The full card: a large card plus what its keywords and statuses mean (SPEC keyword_text), so
## the owner can play without the mechanics library open. Shown on hover or tap. Screens add
## their own action buttons (Buy, Sell) to `actions`.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")

## Keyword -> its unit's note, word for word, from every library unit's keyword_text. Statuses
## are explained with it, so the reminder never drifts from the rules the owner wrote.
static var glossary: Dictionary[String, String] = {}

var card: CardView
var actions: VBoxContainer

var _hint: Label
var _notes: RichTextLabel
var _card_holder: CenterContainer
var _card_width: float = 300.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_card_holder = CenterContainer.new()
	_card_holder.custom_minimum_size = Vector2(0, 16)
	box.add_child(Control.new())
	box.add_child(_card_holder)
	card = CardView.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_holder.add_child(card)
	_hint = UiTheme.label("", UiTheme.FONT_BODY, UiTheme.TEXT_DIM)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hint)
	_notes = RichTextLabel.new()
	_notes.bbcode_enabled = true
	_notes.fit_content = true
	_notes.scroll_active = false
	_notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notes.add_theme_font_size_override("normal_font_size", UiTheme.FONT_SMALL + 1)
	_notes.add_theme_font_size_override("bold_font_size", UiTheme.FONT_SMALL + 1)
	box.add_child(_notes)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	set_card_width(_card_width)
	show_empty("Tap or hover a card to read it in full.")


func set_card_width(width: float) -> void:
	_card_width = width
	card.set_card_width(width)


func show_empty(hint: String) -> void:
	card.visible = false
	_hint.text = hint
	_notes.text = ""
	clear_actions()


func show_unit(view: Dictionary, hint: String = "") -> void:
	card.visible = true
	card.show_unit(view.duplicate(true), CardView.Mode.DETAIL)
	card.set_card_width(_card_width)
	_hint.text = hint
	_hint.visible = not hint.is_empty()
	_notes.text = notes_bbcode(view)


func clear_actions() -> void:
	for child: Node in actions.get_children():
		actions.remove_child(child)
		child.queue_free()


func add_action(text: String, on_press: Callable) -> Button:
	var button: Button = UiTheme.button(text)
	button.pressed.connect(on_press)
	actions.add_child(button)
	return button


## Fills the glossary from library unit defs (GamePort.library_units()).
static func set_glossary(defs: Array) -> void:
	glossary.clear()
	for entry: Variant in defs:
		var def: Dictionary = entry
		var keyword_text: Array = Data.a(UnitViews.from_def(def, false), "keyword_text")
		for item_entry: Variant in keyword_text:
			var item: Dictionary = item_entry
			var keyword: String = str(item.get("keyword", ""))
			if not glossary.has(keyword):
				glossary[keyword] = str(item.get("text", ""))


## Keyword and status reminders as BBCode lines: "[b]Bristle 1[/b]: ...".
static func notes_bbcode(view: Dictionary) -> String:
	var lines: PackedStringArray = []
	var keyword_text: Array = Data.a(view, "keyword_text")
	var shown: Dictionary = {}
	for entry: Variant in keyword_text:
		var item: Dictionary = entry
		var text: String = str(item.get("text", ""))
		var keyword: String = str(item.get("keyword", ""))
		shown[keyword] = true
		lines.append(_bold_head(text, keyword))
	var statuses: Array = Data.a(view, "statuses")
	for entry: Variant in statuses:
		var status: Dictionary = entry
		var key: String = str(status.get("status", ""))
		var colour: String = UiTheme.status_colour(key).lightened(0.35).to_html(false)
		var keyword: String = UiTheme.status_keyword(key)
		var text: String = "" if shown.has(keyword) else glossary.get(keyword, "")
		var line: String = "[b]%s[/b]" % UiTheme.status_label(key)
		if not text.is_empty():
			line = _bold_head(text, keyword)
		elif not shown.has(keyword):
			line += ": (no rules text in the library)"
		lines.append("[color=#%s]On this unit · %s[/color]" % [colour, line])
	if CardView.is_unbuilt(view):
		(
			lines
			. append(
				"[color=#ff9a8a][b]Not built yet[/b]: plays as plain stats; its text does nothing.[/color]"
			)
		)
	var golden: bool = Data.b(view, "golden", false)
	if golden:
		lines.append(
			"[color=#ffcf3f][b]Golden[/b]: double stats; numbers in its text double.[/color]"
		)
	if str(view.get("origin", "")) == "created":
		lines.append("[b]Created[/b]: made by a card, not bought.")
	return "\n".join(lines)


## Bolds the text before the first colon ("Shell (N): ..."), or the keyword if there's no colon.
static func _bold_head(text: String, keyword: String) -> String:
	var colon: int = text.find(":")
	if colon > 0 and colon < 40:
		return "[b]%s[/b]%s" % [text.left(colon), text.substr(colon)]
	if keyword.is_empty():
		return text
	return "[b]%s[/b]: %s" % [keyword, text]
