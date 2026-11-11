extends Control
## The full card, one tap or hover away: a pinned note with the art, the name on an oak banner, the
## type line, the whole rules text, any actions (Buy, Sell). Keywords in the text are links: hover
## (PC) or tap (phone) shows what one means on a ReminderSlip docked under the rules.
## Recruit places this over free space away from the inspected row, without reflow.

const StatNumbers := preload("res://src/ui/stat_numbers.gd")
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
	"Shield": "Prevents the first damage this would take each fight.",
	"Golden": "Double stats; numbers in its text double.",
	"Created": "Made by a card, not bought.",
	"Poached": "Bought from your last opponent. Stays through refreshes.",
	"Tribe bonus": KeywordRules.TRIBE_BONUS_TEXT,
}
## The link to a card's rulings kept off its face (its `details`), opened on the same slip.
const DETAILS: String = "Details"
const BURNER_GOLDEN: String = "Double printed Attack and Health. Its burn limit and rate are above."

var actions: VBoxContainer
## The unit shown ({} when empty), for tests.
var shown: Dictionary = {}
var read_zone: String = "":
	set(value):
		read_zone = value
		if _anchor.is_valid():
			_anchor.call()
## The open keyword's reminder, docked under the rules text.
var reminder: ReminderSlip

var _anchor: Callable
var _overlay: bool = false
var _overlay_limit: Vector2
var _panel: WoodPanel
var _art: ArtFrame
var _banner: Panel
var _name_label: Label
var _type: RichTextLabel
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
var _arena_anchor: Array = []
var _source_getter: Callable


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
	_type = RichTextLabel.new()
	_type.bbcode_enabled = true
	_type.scroll_active = false
	_type.mouse_filter = Control.MOUSE_FILTER_PASS
	_type.add_theme_font_size_override("normal_font_size", UiTheme.FONT_SMALL)
	_type.add_theme_font_size_override("bold_font_size", UiTheme.FONT_SMALL)
	_type.add_theme_color_override("default_color", UiTheme.MUTE)
	_type.add_theme_constant_override("line_separation", -8)
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
	reminder.watch(_type)
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
	_art.texture = UiTheme.portrait_for(
		Data.s(view, "portrait_id", Data.s(view, "def_id")), Data.a(view, "tribes")
	)
	# A note about a slot or a ghost is nobody's portrait.
	_art.visible = not Data.s(view, "def_id").is_empty()
	_name_label.text = Data.s(view, "name")
	_fit_name()
	_type.text = "[center]%s[/center]" % type_bbcode(view)
	_tier_label.text = str(Data.i(view, "cost", 1) if spell else Data.i(view, "tier", 1))
	_tier.visible = Data.s(view, "type_word").is_empty()
	_attack.visible = not spell
	_health.visible = not spell
	# Repeated action instructions belong to the tutorial. Keep only the changing wait warning.
	_hint.text = "Its wait restarts." if hint.contains("Its wait restarts.") else ""
	_hint.visible = not _hint.text.is_empty()
	# The rules read a size larger on a phone, so the reminder (at the phone minimum) stays smaller.
	var rules_size: int = UiTheme.FONT_BODY if CardView.is_phone() else UiTheme.FONT_SMALL
	for key: String in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		_notes.add_theme_font_size_override(key, rules_size)
	if Data.s(view, "def_id") != Data.s(_last_view, "def_id") or view.is_empty():
		reminder.hide_slip()
	_last_view = view
	_notes.text = full_text_bbcode(view)
	if _overlay and _anchor.is_valid():
		_anchor.call()
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


## A changing reason replaces Play itself; it is never a second instruction below the rules.
func add_unavailable_action(reason: String) -> Button:
	var button: LeafButton = add_action(reason, func() -> void: pass) as LeafButton
	button.disabled = true
	button.set_label_size(UiTheme.MIN_FONT)
	button.set_meta("unavailable_action", true)
	var label: Label = button.get("_label")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.get_parent().set("size_flags_horizontal", Control.SIZE_EXPAND_FILL)
	_layout()
	return button


## A wide recruit screen can place actions beside the reader, keeping the full page for text.
func set_action_column(rect: Rect2 = Rect2()) -> void:
	_action_column = rect
	_layout()


## Re-anchor only this overlay when its live controls move; never relayout the screen.
func attach_recruit_overlay(
	stage: Control, gold: Control, end_button: Control, rows: Dictionary
) -> void:
	_source_getter = rows.get("source", Callable())
	var row_refs: Dictionary = {}
	for zone: String in rows:
		if zone != "source":
			row_refs[zone] = weakref(rows[zone])
	_anchor = _anchor_recruit.bind(weakref(stage), weakref(gold), weakref(end_button), row_refs)
	visibility_changed.connect(_anchor)
	gold.item_rect_changed.connect(_anchor, CONNECT_DEFERRED)
	end_button.item_rect_changed.connect(_anchor, CONNECT_DEFERRED)
	for zone: String in row_refs:
		var row: Control = rows[zone]
		row.item_rect_changed.connect(_anchor, CONNECT_DEFERRED)


## The deferred callable belongs to this reader; none of its targets keeps a node alive.
func _anchor_recruit(
	stage_ref: WeakRef, gold_ref: WeakRef, end_ref: WeakRef, row_refs: Dictionary
) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not visible:
		return
	var targets: Array[Control] = [stage_ref.get_ref(), gold_ref.get_ref(), end_ref.get_ref()]
	for target: Control in targets:
		if target == null or not target.is_inside_tree() or target.is_queued_for_deletion():
			return
	var rows: Dictionary = {}
	for zone: String in row_refs:
		var ref: WeakRef = row_refs[zone]
		var row: Control = ref.get_ref()
		if row == null or not row.is_inside_tree() or row.is_queued_for_deletion():
			return
		rows[zone] = row
	rows["source"] = _source_getter
	place_recruit_overlay(targets[0], targets[1], targets[2], rows)


## Protect the entire inspected row. Hand inspection also leaves every play destination clear.
func place_recruit_overlay(
	stage: Control, gold: Control, end_button: Control, rows: Dictionary
) -> void:
	if stage.has_meta("arena_layout"):
		_place_arena_overlay(stage, gold, end_button, rows)
		return
	var inverse: Transform2D = stage.get_global_transform().affine_inverse()
	var top: Rect2 = inverse * gold.get_global_rect()
	var end: Rect2 = inverse * end_button.get_global_rect()
	var width: float = maxf(430.0, maxf(top.size.x, end.size.x))
	var start := Vector2(end.end.x - width, minf(top.position.y, stage.size.y * 0.1))
	var bottom: float = minf(end.position.y, stage.size.y * 0.84)
	var rect := Rect2(start, Vector2(width, maxf(0.0, bottom - start.y - 12.0)))
	var protected: Array[Rect2] = [
		Rect2(0, end.position.y, stage.size.x, stage.size.y - end.position.y)
	]
	for zone: String in ["board", "shop", "lobby", "scout", read_zone]:
		var row: Control = rows.get(zone)
		if row != null and row.visible:
			protected.append((inverse * row.get_global_rect()).grow(12.0))
	if not _clear_of(rect, protected):
		var margin: float = stage.size.y * 0.02
		var floor_y: float = end.position.y if end.position.y > stage.size.y * 0.6 else stage.size.y
		var bounds := Rect2(margin, margin, stage.size.x - margin * 2, floor_y - margin * 2)
		var free: Rect2 = _free_band(bounds, protected)
		if free.has_area():
			width = minf(1550.0, free.size.x) if free.size.y < 600.0 else minf(width, free.size.x)
			start = Vector2(
				clampf(end.end.x - width, free.position.x, free.end.x - width), free.position.y
			)
			rect = Rect2(start, Vector2(width, minf(rect.size.y, free.size.y)))
	place_overlay(rect)


## Keep B's content-fitted reader, selecting a side band from the new live arena rectangles.
func _place_arena_overlay(
	stage: Control, gold: Control, end_button: Control, rows: Dictionary
) -> void:
	var inverse: Transform2D = stage.get_global_transform().affine_inverse()
	var protected: Array[Rect2] = [
		(inverse * gold.get_global_rect()).grow(12),
		(inverse * end_button.get_global_rect()).grow(12),
	]
	for zone: String in ["board", "shop", "scout", "lobby", "market_controls"]:
		var row: Control = rows.get(zone)
		if row != null and row.is_visible_in_tree():
			protected.append((inverse * row.get_global_rect()).grow(12))
	var source_fn: Callable = rows.get("source", Callable())
	if source_fn.is_valid():
		var source: Control = source_fn.call()
		if source != null and source.is_visible_in_tree():
			protected.append((inverse * source.get_global_rect()).grow(12))
	var anchor: Array = [stage.size, read_zone, protected]
	if _arena_anchor == anchor:
		return
	_arena_anchor = anchor
	var free: Rect2 = _free_band(
		Rect2(Vector2(12, 12), stage.size - Vector2(24, 24)), protected, 530.0, 300.0
	)
	if not free.has_area():
		return
	free.size.x = minf(free.size.x, 530.0)
	place_overlay(free)


static func _clear_of(rect: Rect2, protected: Array[Rect2]) -> bool:
	for row: Rect2 in protected:
		if rect.intersects(row):
			return false
	return true


## Boundaries come from the live rows. This also finds the space between a shop and a hand
## when a held spell targets the shop: both its source and its tap targets remain exposed.
static func _free_band(
	bounds: Rect2, protected: Array[Rect2], max_width: float = INF, min_height: float = 0.0
) -> Rect2:
	var xs: Array[float] = [bounds.position.x, bounds.end.x]
	var ys: Array[float] = [bounds.position.y, bounds.end.y]
	for row: Rect2 in protected:
		xs.append(clampf(row.position.x, bounds.position.x, bounds.end.x))
		xs.append(clampf(row.end.x, bounds.position.x, bounds.end.x))
		ys.append(clampf(row.position.y, bounds.position.y, bounds.end.y))
		ys.append(clampf(row.end.y, bounds.position.y, bounds.end.y))
	var largest := Rect2()
	for left: float in xs:
		for right: float in xs:
			if right - left < 270.0:
				continue
			for top: float in ys:
				for bottom: float in ys:
					if bottom - top < min_height:
						continue
					var band := Rect2(left, top, minf(right - left, max_width), bottom - top)
					if (
						bottom > top
						and band.get_area() > largest.get_area()
						and _clear_of(band, protected)
					):
						largest = band
	return largest


## Recruit supplies a live anchor; this panel never asks surrounding controls for space.
func place_overlay(rect: Rect2) -> void:
	_overlay = true
	_overlay_limit = rect.size
	position = rect.position
	size = rect.size
	set_action_column()
	_layout()


func _layout() -> void:
	var w: float = size.x
	if w < 10.0:
		return
	# Shallow free bands read across, leaving the inspected row and its neighbours untouched.
	var across: bool = w >= 800.0 and (_overlay or size.y < 500.0)
	if _overlay and across:
		w -= 340.0 + 30.0
		_action_column = Rect2(w + 12.0, 12, 340, size.y - 24.0)
	var compact: bool = _overlay and not across and (_overlay_limit.y < 800.0 or size.x < 430.0)
	if _overlay:
		_art.visible = not compact and not Data.s(shown, "def_id").is_empty()
		_tier.visible = not compact and Data.s(shown, "type_word").is_empty()
		_attack.visible = not compact and not CardView.is_spell(shown)
		_health.visible = _attack.visible
	var side_actions: bool = _action_column.has_area()
	var heading_w: float = 500.0 if across else w
	var gap: int = 0 if side_actions else 6
	var button_h: float = SIDE_ACTION_H if side_actions else ACTION_H
	actions.add_theme_constant_override("separation", gap)
	var action_h: float = 0.0
	for child: Node in actions.get_children():
		var height: float = button_h
		if child.has_meta("unavailable_action"):
			var label: Label = child.get("_label")
			var width: float = (_action_column.size.x if side_actions else w) * 0.73
			height = maxf(height, _wrapped_height(label, width) + 20.0)
		(child as Control).custom_minimum_size.y = height
		action_h += height + gap
	var bottom: float = size.y if side_actions else size.y - action_h
	_panel.position = Vector2.ZERO
	_panel.size = size if _overlay else Vector2(w, bottom - 14.0)
	var art: float = 176.0 if _art.visible else 0.0
	_art.position = Vector2(24, 24)
	_art.size = Vector2(art, art)
	_banner.position = Vector2(art + 36.0 if _art.visible else 24.0, 28)
	_banner.size = Vector2(heading_w - _banner.position.x - 18.0, 104)
	if _overlay and not across:
		_banner.position.y = 130.0
		_banner.size.y = 88.0
	if compact:
		_banner.position = Vector2(16, 12)
		_banner.size = Vector2(w - 32.0, 88)
	_name_label.position = Vector2(4, 0)
	_name_label.size = Vector2(_banner.size.x - 8.0, _banner.size.y)
	_fit_name()
	_type.position = Vector2(_banner.position.x, _banner.position.y + 108.0)
	_type.size = Vector2(_banner.size.x, 92)
	if _overlay and not across:
		_type.position = Vector2(24, 224)
		_type.size = Vector2(w - 48.0, 44.0)
	if compact:
		_type.position = Vector2(16, 104)
		_type.size = Vector2(_banner.size.x, 40.0)
		_type.size.y = maxf(40.0, _type.get_content_height())
	_tier.position = Vector2(4, 4)
	_tier.size = Vector2(58, 58)
	# A familiar whole-million label may need slightly more than the usual 76-unit badge.
	# Preserve each badge's right edge while making room at the shared minimum font.
	var needed: float = maxf(
		StatNumbers.minimum_width(Data.i(shown, "attack"), _attack_label.get_theme_font("font")),
		StatNumbers.minimum_width(
			maxi(Data.i(shown, "health"), 0), _health_label.get_theme_font("font")
		)
	)
	var stat_width: float = clampf(ceilf(needed / 0.8), 76.0, 84.0)
	_attack.size = Vector2(stat_width, 76)
	_health.size = Vector2(stat_width, 76)
	_attack.position = Vector2(84.0 - stat_width, 152.0)
	_health.position = Vector2(228.0 - stat_width, 152.0)
	StatNumbers.fit(_attack_label, _attack.inner_width(), 40, Data.i(shown, "attack"))
	StatNumbers.fit(_health_label, _health.inner_width(), 40, maxi(Data.i(shown, "health"), 0))
	var hint_h: float = 0.0
	if _hint.visible:
		hint_h = maxf(84.0, _wrapped_height(_hint, heading_w - 48.0))
		_hint.size = Vector2(heading_w - 48.0, hint_h)
	var notes_left: float = heading_w + 24.0 if across else 26.0
	var notes_top: float = 24.0 if across else (248.0 if _art.visible else 186.0)
	if _overlay and not across:
		notes_top = (
			_type.position.y + _type.size.y + 8.0
			if compact
			else maxf(notes_top, _type.position.y + _type.size.y + 8.0)
		)
	var notes_w: float = w - notes_left - 26.0
	_notes.size.x = notes_w
	if _overlay:
		var rules_h: float = maxf(40.0, _notes.get_content_height())
		var reminder_h: float = (
			reminder.height_for(notes_w + 12.0) + 10.0 if reminder.visible else 0.0
		)
		var body_h: float = notes_top + rules_h + reminder_h + 30.0 + hint_h
		var heading_h: float = _type.position.y + _type.size.y + 20.0
		var content_h: float = maxf(body_h, heading_h)
		content_h = maxf(content_h, action_h + 24.0) if side_actions else content_h + action_h
		size.y = minf(_overlay_limit.y, content_h)
		bottom = size.y if side_actions else size.y - action_h
		_panel.size = size
	if _hint.visible:
		_hint.position = Vector2(24, bottom - 14.0 - hint_h - 8.0)
	var text_bottom: float = bottom - 30.0 - (0.0 if across else hint_h)
	var slip_h: float = 0.0
	if reminder.visible:
		# Set apart under the rules, never over them; long rules scroll above it.
		slip_h = minf(reminder.height_for(notes_w + 12.0), (text_bottom - notes_top) * 0.6)
		reminder.place(Rect2(notes_left - 6.0, text_bottom - slip_h, notes_w + 12.0, slip_h))
		slip_h += 10.0
	_notes.position = Vector2(notes_left, notes_top)
	_notes.size = Vector2(notes_w, maxf(text_bottom - notes_top - slip_h, 40.0))
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


## Fit complete names to the available banner before they can be clipped by it.
func _fit_name() -> void:
	var font_size: int = UiTheme.FONT_BODY + 4
	var font: Font = UiTheme.head_font()
	while font_size > UiTheme.FONT_SMALL:
		var height: float = (
			font
			. get_multiline_string_size(
				_name_label.text, HORIZONTAL_ALIGNMENT_CENTER, _name_label.size.x, font_size
			)
			. y
		)
		if height <= _name_label.size.y:
			break
		font_size = maxi(UiTheme.FONT_SMALL, font_size - 2)
	_name_label.add_theme_font_size_override("font_size", font_size)


## The rules text in full with each keyword a link, then what's true of this card right now. No
## reminder text: a keyword's meaning is on the ReminderSlip, shown on hover or tap.
static func full_text_bbcode(view: Dictionary, own_card: bool = true) -> String:
	var lines: PackedStringArray = []
	if (
		not CardView.is_spell(view)
		and maxi(Data.i(view, "attack"), Data.i(view, "health")) >= StatNumbers.EXACT_DETAILS_FROM
	):
		lines.append(
			(
				"[b]Attack: %s\nHealth: %s[/b]"
				% [
					StatNumbers.exact(Data.i(view, "attack")),
					StatNumbers.exact(maxi(0, Data.i(view, "health")))
				]
			)
		)
	var rules: String = Data.s(view, "text")
	if own_card and Data.s(view, "def_id") == "nest_egg" and view.has("bird_attack"):
		var left: int = Data.i(view, "turns_left")
		rules = (
			"Egg: %d/%d.\nBird: %d/%d.\nHome in %d %s."
			% [
				Data.i(view, "attack"),
				Data.i(view, "health"),
				Data.i(view, "bird_attack"),
				Data.i(view, "bird_health"),
				left,
				"turn" if left == 1 else "turns",
			]
		)
	var linked: Array[String] = []
	if not rules.is_empty():
		var words: PackedStringArray = KeywordRules.named_on(view)
		if rules.contains("Tribe bonus"):
			words.append("Tribe bonus")
		lines.append(_keyword_marks(rules, words, linked))
	for borrowed: Dictionary in Data.a(view, "borrowed_rules"):
		var borrowed_text: String = _keyword_marks(
			Data.s(borrowed, "text"), KeywordRules.named_on(borrowed), linked
		)
		lines.append("Borrowed from %s: %s" % [Data.s(borrowed, "name"), borrowed_text])
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
	if view.has("bog_kiss_period"):
		var period: int = maxi(1, Data.i(view, "bog_kiss_period"))
		var count: int = Data.i(
			view,
			"kisses",
			Data.i(view, "recruit_kisses", Data.i(Data.d(view, "counters"), "kisses"))
		)
		lines.append("[b]Shared kisses: %d (%d/%d).[/b]" % [count, count % period, period])
	elif view.has("recruit_kisses"):
		lines.append(
			"[b]Kisses: %d/3[/b] toward The Prince Restored." % Data.i(view, "recruit_kisses")
		)
	if view.has("hunter_take_preview"):
		var prey: Dictionary = Data.d(view, "hunter_take_preview")
		var taker_slot: int = Data.i(prey, "owner_slot", -1)
		var names: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
		var first: String = (
			names[taker_slot] if taker_slot >= 0 and taker_slot < names.size() else "none"
		)
		lines.append("[b]Recorded quarry: %s. First Take: %s.[/b]" % [Data.s(prey, "name"), first])
		if Data.i(prey, "attack") > 0:
			lines.append(
				(
					"Take: +%s/+%s, if this makes the Take."
					% [
						StatNumbers.exact(Data.i(prey, "attack")),
						StatNumbers.exact(Data.i(prey, "health"))
					]
				)
			)
	for entry: Variant in Data.a(view, "soak_preview"):
		if entry is Dictionary:
			var preview: Dictionary = entry
			var when: String = "After %s emerges" if Data.b(preview, "waiting") else "Across %s"
			lines.append(
				(
					"[b]%s: +%s/+%s per bite.[/b]"
					% [
						when % Data.s(preview, "name"),
						StatNumbers.exact(Data.i(preview, "drink")),
						StatNumbers.exact(Data.i(preview, "drink"))
					]
				)
			)
	if view.has("hedgerow_preview"):
		var preview: Vector2i = view["hedgerow_preview"]
		var timing: String = (
			"Start of Turn" if Data.s(view, "def_id") == "squire_lollop" else "End of Turn"
		)
		lines.append(
			(
				"[b]Next %s share: +%s/+%s per recipient.[/b]"
				% [timing, StatNumbers.exact(preview.x), StatNumbers.exact(preview.y)]
			)
		)
	if Data.b(view, "hedgerow_runt"):
		lines.append("The Standing Committee's current smallest unit.")
	if Data.b(view, "hedgerow_clock"):
		lines.append(
			(
				"[b]Sleep: %d/%d turns in this slot.[/b] Moving this restarts the wait."
				% [Data.i(view, "turns_in_slot"), Data.i(view, "turns_goal")]
			)
		)
	var state: String = state_bbcode(view)
	var digest: Vector2i = view.get("ooze_digest_preview", Vector2i.ZERO)
	if digest != Vector2i.ZERO:
		lines.append(
			(
				"[b]Digest at Start of Turn: +%s/+%s.[/b]"
				% [StatNumbers.exact(digest.x), StatNumbers.exact(digest.y)]
			)
		)
	var soup: Vector2i = view.get("ooze_soup_bonus", Vector2i.ZERO)
	if soup != Vector2i.ZERO:
		lines.append(
			(
				"[b]Stone Soup: +%s/+%s[/b] (in its stats; kept when bought)."
				% [StatNumbers.exact(soup.x), StatNumbers.exact(soup.y)]
			)
		)
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


## Identity and origin share one readable line; their meanings remain one tap away.
static func type_bbcode(view: Dictionary) -> String:
	var parts: PackedStringArray = []
	if Data.b(view, "golden"):
		parts.append(ReminderSlip.link("Golden", "GOLDEN"))
	if Data.s(view, "origin") == "created":
		parts.append(ReminderSlip.link("Created", "CREATED"))
	parts.append(
		(
			(
				CardView.card_word(view)
				if CardView.is_spell(view)
				else UiTheme.type_line(Data.a(view, "tribes"))
			)
			. to_upper()
		)
	)
	return " · ".join(parts)


## Worked examples and offer exceptions live behind Details, beside card-local rulings.
static func _details_for(view: Dictionary) -> String:
	var parts: PackedStringArray = []
	var rulings: String = CardRulings.for_view(view)
	if not rulings.is_empty():
		parts.append(rulings)
	if Data.s(view, "def_id") == "charcoal_burner":
		var plan: String = _burner_plan(Data.s(view, "text"))
		if not plan.is_empty():
			parts.append(plan)
	if Data.s(view, "def_id") == "harvest_supper":
		parts.append("Offered from tier 3.")
	return "\n".join(parts)


## What is true of this unit now: statuses, pending gains and unbuilt. Each names its word as a
## link; the meaning is one hover or tap away.
static func state_bbcode(view: Dictionary) -> String:
	var lines: PackedStringArray = []
	var hex_parts: PackedStringArray = []
	for field: String in ["hex_amount", "hex_percent_amount"]:
		var amount: int = Data.i(view, field)
		if amount <= 0:
			continue
		var stored_field: String = "hex_stored" if field == "hex_amount" else "hex_percent_stored"
		var suffix: String = "" if field == "hex_amount" else "%"
		var stored: int = Data.i(view, stored_field, amount)
		hex_parts.append("%d%s (%d%s stored)" % [amount, suffix, stored, suffix])
	if not hex_parts.is_empty():
		lines.append("[b]Hex: %s.[/b]" % " + ".join(hex_parts))
	var pending_attack: int = Data.i(view, "pending_attack")
	var pending_health: int = Data.i(view, "pending_health")
	if pending_attack != 0 or pending_health != 0:
		lines.append(
			(
				"[b]Pending gain: +%s/+%s.[/b] Arrives at your next Start of Turn."
				% [StatNumbers.exact(pending_attack), StatNumbers.exact(pending_health)]
			)
		)
	if Data.b(view, "combat_start_overlay"):
		lines.append("[b]Combat-start stats.[/b] Copies %s." % Data.s(view, "copied_name"))
	if Data.b(view, "poached"):
		lines.append("[b]%s[/b]" % ReminderSlip.link("Poached"))
	if Data.b(view, "egged"):
		lines.append("[b]Golden Egg used.[/b] This Bird cannot take another Golden Egg.")
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
	if not _details_for(view).is_empty():
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
static func show_rules(rich: RichTextLabel, view: Dictionary, own_card: bool = true) -> void:
	rich.set_meta("card_detail_view", view)
	rich.text = full_text_bbcode(view, own_card)
	var slip: ReminderSlip = rich.get_meta("reminder", null)
	if slip == null:
		return
	if Data.i(view, "uid", -1) != Data.i(slip.view, "uid", -2) or view.is_empty():
		slip.hide_slip()
	slip.view = view


## A word's reminder for this card, as the slip shows it; "" for no reminder.
static func reminder_for(word: String, view: Dictionary = {}) -> String:
	if word == DETAILS:
		var rulings: String = _details_for(view)
		return "" if rulings.is_empty() else "[b]%s:[/b] %s" % [word, rulings]
	if STATE_WORDS.has(word):
		var text: String = STATE_WORDS[word]
		if word == "Golden" and Data.s(view, "def_id") == "charcoal_burner":
			text = BURNER_GOLDEN
			if Data.s(view, "text").contains("their stats per gold"):
				text = "Double printed Attack and Health and burn limit. The share per gold stays unchanged."
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
	if bank != null and rules.contains("their stats per gold"):
		var native_rate: RegExMatch = (
			RegEx.create_from_string("gain (.+) of their stats per gold").search(rules)
		)
		if native_rate != null:
			var phrase: String = native_rate.get_string(1)
			var share: float = -1.0
			for denominator: int in Pass3Text.FRACTIONS:
				for numerator: int in range(1, denominator * 2 + 1):
					if phrase == Pass3Text._fraction(float(numerator) / denominator):
						share = float(numerator) / denominator
			var percentage: RegExMatch = RegEx.create_from_string("^([0-9.]+)%$").search(phrase)
			if percentage != null:
				share = percentage.get_string(1).to_float() / 100.0
			var native_burn: int = bank.get_string(1).to_int()
			var native_remains: int = bank.get_string(2).to_int()
			var gain: String = (
				Pass3Text._n(share * native_burn * 100.0) + "%"
				if share >= 0.0
				else phrase + " per gold"
			)
			return (
				"Keep %d gold to burn %d: each unit behind gains %s of its own body stats; %d remains."
				% [native_remains + native_burn, native_burn, gain, native_remains]
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
