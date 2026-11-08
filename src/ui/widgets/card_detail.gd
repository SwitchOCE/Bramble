extends Control
## The full card, one tap or hover away: a pinned note with the art, the name on an oak banner, the
## type line, the whole rules text, any actions (Buy, Sell). Keywords in the text are links: hover
## (PC) or tap (phone) shows what one means on a ReminderSlip docked under the rules.
## It lands on the right-hand column, so the shop, board and hand stay visible while you read it.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const KeywordRules := preload("res://src/ui/keyword_rules.gd")
const CardRulings := preload("res://src/ui/card_rulings.gd")
const WoodPanel := preload("res://src/ui/widgets/wood_panel.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const ArtFrame := preload("res://src/ui/widgets/art_frame.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const LeafButton := preload("res://src/ui/widgets/leaf_button.gd")
const ReminderSlip := preload("res://src/ui/widgets/reminder_slip.gd")

const ACTION_H: float = 128.0
const SIDE_ACTION_H: float = 122.0
## Words that aren't game keywords but still have a reminder on the details panel.
const STATE_WORDS: Dictionary[String, String] = {
	"Golden": "Double stats; numbers in its text double.",
	"Created": "Made by a card, not bought.",
	"Tribe bonus": KeywordRules.TRIBE_BONUS_TEXT,
}
## The link to a card's rulings kept off its face (its `details`), opened on the same slip.
const DETAILS: String = "Details"
const BURNER_GOLDEN: String = "Double printed Attack and Health. Its burn limit and rate are above."

var actions: VBoxContainer
## The unit shown ({} when empty), for tests.
var shown: Dictionary = {}
## The open keyword's reminder, docked under the rules text.
var reminder: ReminderSlip

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
var _last_view: Dictionary = {}


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
	reminder = ReminderSlip.new()
	reminder.docked = true
	reminder.reminder_fn = func(word: String) -> String: return reminder_for(word, shown)
	reminder.watch(_notes)
	reminder.shown_changed.connect(_layout)
	add_child(reminder)
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
	reminder.hide_slip()
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
	# The rules read a size larger on a phone, so the reminder (at the phone minimum) stays smaller.
	var rules_size: int = UiTheme.FONT_BODY if CardView.is_phone() else UiTheme.FONT_SMALL
	for key: String in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		_notes.add_theme_font_size_override(key, rules_size)
	if Data.s(view, "def_id") != Data.s(_last_view, "def_id") or view.is_empty():
		reminder.hide_slip()
	_last_view = view
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
	var text_bottom: float = bottom - 14.0 - 16.0 - hint_h
	var slip_h: float = 0.0
	if reminder.visible:
		# Set apart under the rules, never over them; long rules scroll above it.
		slip_h = minf(reminder.height_for(w - 40.0), (text_bottom - notes_top) * 0.6)
		reminder.place(Rect2(20, text_bottom - slip_h, w - 40.0, slip_h))
		slip_h += 10.0
	_notes.position = Vector2(26, notes_top)
	_notes.size = Vector2(w - 52.0, maxf(text_bottom - notes_top - slip_h, 40.0))
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


## The rules text in full with each keyword a link, then what's true of this card right now. No
## reminder text: a keyword's meaning is on the ReminderSlip, shown on hover or tap.
static func full_text_bbcode(view: Dictionary) -> String:
	var lines: PackedStringArray = []
	var rules: String = Data.s(view, "text")
	var linked: Array[String] = []
	if rules.is_empty() and not CardView.is_spell(view):
		lines.append("[color=#%s]No special rules.[/color]" % UiTheme.hex(UiTheme.MUTE))
	elif not rules.is_empty():
		var words: PackedStringArray = KeywordRules.named_on(view)
		if rules.contains("Tribe bonus"):
			words.append("Tribe bonus")
		lines.append(_keyword_marks(rules, words, linked))
	var also: PackedStringArray = []
	var introduced: Array[String] = []
	for word: String in linked:
		for term: String in KeywordRules.terms_in(KeywordRules.text(word)):
			introduced.append(term)
	for word: String in KeywordRules.named_on(view):
		if word != "*" and not linked.has(word) and not introduced.has(word):
			also.append(ReminderSlip.link(word))
	if not also.is_empty():
		lines.append("[b]%s[/b]" % ", ".join(also))
	if Data.s(view, "def_id") == "charcoal_burner":
		var plan: String = _burner_plan(rules)
		if not plan.is_empty():
			lines.append(plan)
	if Data.s(view, "def_id") == "harvest_supper":
		lines.append("Offered from tier 3.")
	var bonuses: Dictionary = Data.d(view, "tribe_bonuses")
	for value: Variant in bonuses:
		var tribe: String = str(value)
		var bonus: int = Data.i(bonuses, tribe)
		if bonus > 0:
			lines.append(
				(
					"[b]%s %s: +%d/+%d[/b] (in its stats)."
					% [tribe, ReminderSlip.link("Tribe bonus", "tribe bonus"), bonus, bonus]
				)
			)
	if view.has("recruit_bitter"):
		lines.append(
			(
				"[b]Bitter %d[/b] (%d base + %d from beside)."
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
	var state: String = state_bbcode(view)
	if not state.is_empty():
		lines.append(state)
	return "\n".join(lines)


## Bold keyword links in the rules, each keyword's first mention only; Nightshade keeps its colour.
## `linked` collects the words that got a link.
static func _keyword_marks(
	rules: String, words: PackedStringArray, linked: Array[String] = []
) -> String:
	var names: Array[String] = []
	for word: String in words:
		if word != "*":
			names.append(word)
	names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	# Each word's first mention, longest names first so "Fly South" wins over a shorter overlap.
	var starts: Array[int] = []
	var ends: Array[int] = []
	var marks: PackedStringArray = []
	for word: String in names:
		var finder: RegEx = RegEx.create_from_string(KeywordRules.pattern(word))
		for found: RegExMatch in finder.search_all(rules):
			var start: int = found.get_start()
			var end: int = found.get_end()
			var overlaps: bool = false
			for index: int in starts.size():
				if start < ends[index] and end > starts[index]:
					overlaps = true
			if overlaps:
				continue
			linked.append(word)
			var mark: String = "[b]%s[/b]" % ReminderSlip.link(word, found.get_string(0))
			if word == "Nightshade":
				mark = "[color=#%s]%s[/color]" % [UiTheme.hex(UiTheme.NIGHTSHADE), mark]
			var at_index: int = 0
			while at_index < starts.size() and starts[at_index] < start:
				at_index += 1
			starts.insert(at_index, start)
			ends.insert(at_index, end)
			marks.insert(at_index, mark)
			break
	var out: String = ""
	var at: int = 0
	for index: int in starts.size():
		out += rules.substr(at, starts[index] - at) + marks[index]
		at = ends[index]
	out += rules.substr(at)
	if not linked.has("Nightshade"):
		out = out.replace(
			"Nightshade", "[b][color=#%s]Nightshade[/color][/b]" % UiTheme.hex(UiTheme.NIGHTSHADE)
		)
	return out


## What is true of this unit now: statuses, golden, created, unbuilt. Each names its word as a
## link; the meaning is one hover or tap away.
static func state_bbcode(view: Dictionary) -> String:
	var lines: PackedStringArray = []
	var statuses: Array = Data.a(view, "statuses")
	for entry: Variant in statuses:
		var status: Dictionary = entry
		var key: String = str(status.get("status", ""))
		var colour: String = UiTheme.hex(UiTheme.readable(UiTheme.status_colour(key)))
		var keyword: String = UiTheme.status_keyword(key)
		var label: String = UiTheme.status_label(key)
		var marked: String = label
		if not KeywordRules.text(keyword).is_empty():
			marked = ReminderSlip.link(keyword, label)
		lines.append("[color=#%s]On this unit: [b]%s[/b][/color]" % [colour, marked])
	if CardView.is_unbuilt(view):
		var warn: String = "[color=#%s][b]Not built yet[/b]: " % UiTheme.hex(UiTheme.NOTE_WARN)
		lines.append(warn + "stats only.[/color]")
	if Data.b(view, "golden", false):
		lines.append(
			(
				"[color=#%s][b]%s[/b][/color]"
				% [UiTheme.hex(UiTheme.NOTE_GOLDEN), ReminderSlip.link("Golden")]
			)
		)
	if str(view.get("origin", "")) == "created":
		lines.append("[b]%s[/b]" % ReminderSlip.link("Created"))
	if not CardRulings.for_view(view).is_empty():
		var mute: String = UiTheme.hex(UiTheme.MUTE)
		lines.append("[color=#%s][i]%s[/i][/color]" % [mute, ReminderSlip.link(DETAILS)])
	return "\n".join(lines)


## Gives a rules text its reminder slip, added to `parent`; `above` docks it over that panel.
static func watch_rules(rich: RichTextLabel, parent: Node, above: Control = null) -> ReminderSlip:
	var slip: ReminderSlip = ReminderSlip.new()
	slip.reminder_fn = func(word: String) -> String: return reminder_for(word, slip.view)
	slip.above = above
	slip.watch(rich)
	rich.set_meta("reminder", slip)
	parent.add_child(slip)
	return slip


## Shows a card's rules in a watched text; a different card closes the last one's reminder.
static func show_rules(rich: RichTextLabel, view: Dictionary) -> void:
	rich.text = full_text_bbcode(view)
	var slip: ReminderSlip = rich.get_meta("reminder", null)
	if slip == null:
		return
	if Data.i(view, "uid", -1) != Data.i(slip.view, "uid", -2) or view.is_empty():
		slip.hide_slip()
	slip.view = view


## A word's reminder for this card, as the slip shows it; "" for no reminder.
static func reminder_for(word: String, view: Dictionary = {}) -> String:
	if word == DETAILS:
		var rulings: String = CardRulings.for_view(view)
		return "" if rulings.is_empty() else "[b]%s:[/b] %s" % [word, rulings]
	if STATE_WORDS.has(word):
		var text: String = STATE_WORDS[word]
		if word == "Golden" and Data.s(view, "def_id") == "charcoal_burner":
			text = BURNER_GOLDEN
		return "[b]%s:[/b] %s" % [word, text]
	return ReminderSlip.reminder_bbcode(word)


## Every reminder this card can show, one per line, as the slip words them (tests and tools).
static func notes_bbcode(view: Dictionary) -> String:
	var lines: PackedStringArray = []
	var words: PackedStringArray = KeywordRules.named_on(view)
	for entry: Variant in Data.a(view, "statuses"):
		var status: Dictionary = entry
		var keyword: String = UiTheme.status_keyword(str(status.get("status", "")))
		if not words.has(keyword):
			words.append(keyword)
	for word: String in words:
		var words_now: String = reminder_for(word, view)
		if not words_now.is_empty():
			lines.append(words_now.get_slice("\n", 0))
	if Data.b(view, "golden", false):
		lines.append(reminder_for("Golden", view))
	if str(view.get("origin", "")) == "created":
		lines.append(reminder_for("Created", view))
	var rulings: String = reminder_for(DETAILS, view)
	if not rulings.is_empty():
		lines.append(rulings)
	return "\n".join(lines)


## Read the live card's bank, burn cap and payout so the example follows normal and golden text.
static func _burner_plan(rules: String) -> String:
	var bank: RegExMatch = (
		RegEx.create_from_string("up to (\\d+) of your gold above (\\d+)").search(rules)
	)
	var rate: RegExMatch = (
		RegEx.create_from_string("gain \\+(\\d+)/\\+(\\d+) per (\\d+) burned").search(rules)
	)
	if bank == null or rate == null:
		return ""
	var remains: int = bank.get_string(2).to_int()
	var burn: int = bank.get_string(1).to_int()
	var divisor: int = rate.get_string(3).to_int()
	if divisor <= 0:
		return ""
	var steps: int = floori(float(burn) / divisor)
	return (
		"Keep %d gold to burn %d: units behind gain +%d/+%d; %d remains."
		% [
			remains + burn,
			burn,
			rate.get_string(1).to_int() * steps,
			rate.get_string(2).to_int() * steps,
			remains
		]
	)
