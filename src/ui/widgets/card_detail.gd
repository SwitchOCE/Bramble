extends Control
## The full card, one tap or hover away: a pinned note with the art, the name on an oak banner, the
## type line, the whole rules text, what its keywords and statuses mean, any actions (Buy, Sell).
## It lands on the right-hand column, so the shop, board and hand stay visible while you read it.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")

const ACTION_H: float = 128.0
const SIDE_ACTION_H: float = 122.0

var actions: VBoxContainer
## The unit shown ({} when empty), for tests.
var shown: Dictionary = {}

var _panel: WoodPanel
var _art: ArtFrame
var _banner: Panel
var _name_label: Label
var _type: Label
var _notes: RichTextLabel
var _hint: Label
var _tier: ShapeBadge
var _tier_label: Label
var _attack: ShapeBadge
var _attack_label: Label
var _health: ShapeBadge
var _health_label: Label
var _action_column: Rect2 = Rect2()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_panel = WoodPanel.new(WoodPanel.Kind.PAPER)
	_panel.nails = false
	add_child(_panel)
	_art = ArtFrame.new()
	_art.radius = 20.0
	_art.line = 5.0
	add_child(_art)
	_banner = Panel.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_stylebox_override("panel", UiTheme.flat_box(UiTheme.OAK, UiTheme.INK, 5, 14))
	add_child(_banner)
	_name_label = UiTheme.head("", UiTheme.FONT_BODY + 4)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_constant_override("line_spacing", -16)
	# Clipped so a layout at a narrow width can't leave it stretched tall out of the banner.
	_name_label.clip_text = true
	_banner.add_child(_name_label)
	_type = UiTheme.burned("", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_type.clip_text = true
	_type.add_theme_constant_override("line_spacing", -8)
	add_child(_type)
	_notes = RichTextLabel.new()
	_notes.bbcode_enabled = true
	_notes.scroll_active = true
	_notes.mouse_filter = Control.MOUSE_FILTER_PASS
	_notes.add_theme_font_size_override("normal_font_size", UiTheme.FONT_SMALL)
	_notes.add_theme_font_size_override("bold_font_size", UiTheme.FONT_SMALL)
	_notes.add_theme_font_size_override("italics_font_size", UiTheme.FONT_SMALL)
	_notes.add_theme_constant_override("line_separation", 4)
	add_child(_notes)
	_hint = UiTheme.label("", UiTheme.FONT_SMALL, UiTheme.MUTE)
	_hint.add_theme_font_override("font", UiTheme.bold_font())
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)
	_tier = ShapeBadge.new("knot")
	add_child(_tier)
	_tier_label = _number(_tier, 34, UiTheme.INK)
	_attack = ShapeBadge.new("nut")
	add_child(_attack)
	_attack_label = _number(_attack, 45, UiTheme.INK)
	_health = ShapeBadge.new("rosehip")
	add_child(_health)
	_health_label = _number(_health, 45, UiTheme.CREAM)
	_health_label.offset_top = 4.0
	_attack_label.add_theme_font_size_override("font_size", 40)
	_health_label.add_theme_font_size_override("font_size", 40)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	add_child(actions)
	resized.connect(_layout)
	ready.connect(_layout)


func _number(badge: ShapeBadge, font_size: int, colour: Color) -> Label:
	var number: Label = UiTheme.number("", font_size, colour)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(number)
	return number


func show_empty() -> void:
	shown = {}
	visible = false
	clear_actions()


func show_unit(view: Dictionary, hint: String = "") -> void:
	shown = view
	visible = true
	var spell: bool = CardView.is_spell(view)
	_art.texture = UiTheme.portrait_for(Data.s(view, "def_id"), Data.a(view, "tribes"))
	# A note about a slot or a ghost is nobody's portrait.
	_art.visible = not Data.s(view, "def_id").is_empty()
	_name_label.text = Data.s(view, "name")
	_fit_name()
	_type.text = (
		(CardView.card_word(view) if spell else UiTheme.type_line(Data.a(view, "tribes")))
		. to_upper()
	)
	_tier_label.text = str(Data.i(view, "cost", 1) if spell else Data.i(view, "tier", 1))
	_tier.visible = Data.s(view, "type_word").is_empty()
	_attack.visible = not spell
	_health.visible = not spell
	_attack_label.text = str(Data.i(view, "attack", 0))
	_health_label.text = str(maxi(Data.i(view, "health", 0), 0))
	_hint.text = hint
	_hint.visible = not hint.is_empty()
	_notes.text = full_text_bbcode(view)
	_layout()


func clear_actions() -> void:
	for child: Node in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	_layout()


func add_action(words: String, on_press: Callable, cost: int = -1) -> Button:
	var button: LeafButton = LeafButton.new()
	button.colour = LeafButton.Colour.ACORN
	button.custom_minimum_size = Vector2(0, ACTION_H)
	button.set_face(words, "", cost)
	button.pressed.connect(on_press)
	actions.add_child(button)
	_layout()
	return button


## A wide recruit screen can place actions beside the reader, keeping the full page for text.
func set_action_column(rect: Rect2 = Rect2()) -> void:
	_action_column = rect
	_layout()


func _layout() -> void:
	var w: float = size.x
	if w < 10.0:
		return
	var side_actions: bool = _action_column.has_area()
	var gap: int = 0 if side_actions else 6
	var button_h: float = SIDE_ACTION_H if side_actions else ACTION_H
	actions.add_theme_constant_override("separation", gap)
	var action_h: float = 0.0
	for child: Node in actions.get_children():
		(child as Control).custom_minimum_size.y = button_h
		action_h += button_h + gap
	var bottom: float = size.y if side_actions else size.y - action_h
	_panel.position = Vector2.ZERO
	_panel.size = Vector2(w, bottom - 14.0)
	var art: float = 176.0 if _art.visible else 0.0
	_art.position = Vector2(24, 24)
	_art.size = Vector2(art, art)
	_banner.position = Vector2(art + 36.0 if _art.visible else 24.0, 28)
	_banner.size = Vector2(w - _banner.position.x - 18.0, 104)
	_name_label.position = Vector2(4, 0)
	_name_label.size = Vector2(_banner.size.x - 8.0, _banner.size.y)
	_fit_name()
	_type.position = Vector2(_banner.position.x, 136)
	_type.size = Vector2(_banner.size.x, 92)
	_tier.position = Vector2(4, 4)
	_tier.size = Vector2(58, 58)
	_attack.size = Vector2(76, 76)
	_health.size = Vector2(76, 76)
	_attack.position = Vector2(8, 152.0)
	_health.position = Vector2(152.0, 152.0)
	var hint_h: float = 0.0
	if _hint.visible:
		hint_h = maxf(84.0, _wrapped_height(_hint, w - 48.0))
		_hint.position = Vector2(24, bottom - 14.0 - hint_h - 8.0)
		_hint.size = Vector2(w - 48.0, hint_h)
	var notes_top: float = 248.0 if _art.visible else 186.0
	_notes.position = Vector2(26, notes_top)
	_notes.size = Vector2(w - 52.0, maxf(bottom - 14.0 - notes_top - 16.0 - hint_h, 40.0))
	actions.position = Vector2(0, bottom)
	actions.size = Vector2(w, action_h)
	if side_actions:
		actions.position = _action_column.position
		actions.size = Vector2(_action_column.size.x, action_h)


## Measure wrapped help at its actual width so a third line stays above the action buttons.
func _wrapped_height(label: Label, width: float) -> float:
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	return ceilf(
		font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size).y
	)


## A name that would take more than two lines drops to the smallest size, where it fits the banner.
func _fit_name() -> void:
	var big: int = UiTheme.FONT_BODY + 4
	var font: Font = UiTheme.head_font()
	var tall: float = (
		font
		. get_multiline_string_size(
			_name_label.text, HORIZONTAL_ALIGNMENT_CENTER, _name_label.size.x, big
		)
		. y
	)
	var long: bool = tall > font.get_height(big) * 2.5
	_name_label.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL if long else big)


## The rules text in full, keyword names in bold, then the reminders.
static func full_text_bbcode(view: Dictionary) -> String:
	var lines: PackedStringArray = []
	var rules: String = Data.s(view, "text")
	if rules.is_empty() and not CardView.is_spell(view):
		lines.append("[color=#%s]No special rules.[/color]" % UiTheme.hex(UiTheme.MUTE))
	elif not rules.is_empty():
		lines.append(_keyword_marks(rules))
	if view.has("recruit_bitter"):
		lines.append(
			(
				"[b]Bitter total: %d[/b] (%d printed + %d from beside auras)."
				% [
					Data.i(view, "recruit_bitter"),
					Data.i(view, "recruit_bitter_printed"),
					Data.i(view, "recruit_bitter_borrowed")
				]
			)
		)
	if view.has("recruit_kisses"):
		lines.append(
			"[b]Kisses: %d/3[/b] toward The Prince Restored." % Data.i(view, "recruit_kisses")
		)
	var notes: String = notes_bbcode(view)
	if not notes.is_empty():
		lines.append(notes)
	return "\n".join(lines)


static func _keyword_marks(rules: String) -> String:
	return rules.replace(
		"Nightshade", "[b][color=#%s]Nightshade[/color][/b]" % UiTheme.hex(UiTheme.NIGHTSHADE)
	)


## Keyword and status reminders as BBCode lines: "[b]Bristle 1[/b]: ...".
static func notes_bbcode(view: Dictionary) -> String:
	var lines: PackedStringArray = []
	var shown_words: Dictionary = {}
	var remind: String = UiTheme.hex(UiTheme.MUTE)
	for keyword: String in KeywordRules.named_on(view):
		shown_words[keyword] = true
		var text: String = KeywordRules.text(keyword)
		lines.append("[color=#%s]%s[/color]" % [remind, _bold_head(text, keyword)])
	var statuses: Array = Data.a(view, "statuses")
	for entry: Variant in statuses:
		var status: Dictionary = entry
		var key: String = str(status.get("status", ""))
		var colour: String = UiTheme.hex(UiTheme.readable(UiTheme.status_colour(key)))
		var keyword: String = UiTheme.status_keyword(key)
		var text: String = "" if shown_words.has(keyword) else KeywordRules.text(keyword)
		var line: String = "[b]%s[/b]" % UiTheme.status_label(key)
		if not text.is_empty():
			line = _bold_head(text, keyword)
		lines.append("[color=#%s]On this unit · %s[/color]" % [colour, line])
	if CardView.is_unbuilt(view):
		var warn: String = "[color=#%s][b]Not built yet[/b]: " % UiTheme.hex(UiTheme.NOTE_WARN)
		lines.append(warn + "plays as plain stats; its text does nothing.[/color]")
	if Data.b(view, "golden", false):
		lines.append(
			(
				"[color=#%s][b]Golden[/b]: double stats; numbers in its text double.[/color]"
				% UiTheme.hex(UiTheme.NOTE_GOLDEN)
			)
		)
	if str(view.get("origin", "")) == "created":
		lines.append("[b]Created[/b]: made by a card, not bought.")
	return "\n".join(lines)


## Bolds the text before the first colon ("Shell (N): ..."), or the keyword if there's no colon.
static func _bold_head(text: String, keyword: String) -> String:
	if keyword.is_empty():
		return text
	return "[b]%s[/b]: %s" % [keyword, text]
