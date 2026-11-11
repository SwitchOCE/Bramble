extends RefCounted
## Finds layout faults on a live screen: controls that leave the window, controls that spill out
## of their container, labels whose text doesn't fit (or is cut to fewer lines), cards that overlap,
## text under the phone minimum, and tap targets too small for a finger. Used by the scripted
## playthrough (tests/ui/shots/playthrough.gd) and its gate test.
##
## The phone numbers: a 6.5 inch landscape phone at 1688 x 780 is 844 x 390 points at 2x. The canvas
## is always 1080 tall, so one canvas unit is 780 / 1080 window pixels there.
## 11 pt text = 22 window px = 30.46 canvas units: 31 (UiTheme.MIN_FONT).
## 44 pt tap target = 88 window px = 121.8 canvas units: 122 on a phone-shaped window. On a 16:9
## desktop window, canvas units are window pixels and 88 is plenty for a finger on a touch screen.

const CardView := preload("res://src/ui/widgets/card_view.gd")
const LobbyPlaque := preload("res://src/ui/widgets/lobby_plaque.gd")
const Interactive := preload("res://src/ui/widgets/interactive.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const TokenButton := preload("res://src/ui/widgets/token_button.gd")

## Pixels of slack before something counts as out of bounds.
const SLACK: float = 2.0
## Cards may touch; they overlap when the shared area is bigger than this share of a card.
const OVERLAP_SHARE: float = 0.08
const PHONE_WINDOW_H: float = 780.0
const PHONE_POINT_PX: float = 2.0
const MIN_TEXT_PT: float = 11.0
const MIN_TAP_PT: float = 44.0
const CANVAS_H: float = 1080.0
## Wider than this is treated as a phone.
const PHONE_ASPECT: float = 2.0
const DESKTOP_TAP: float = 88.0
const DESKTOP_RULES_FONT: int = 22

## The smallest text size seen in any check since the last reset, in canvas units. On a desktop
## that includes text marked desktop_text, which may go down to DESKTOP_RULES_FONT.
static var smallest_text: int = 9999
static var _name_library: UnitLibrary = UnitLibrary.load_dir()


## The smallest allowed font size, in canvas units.
static func min_font() -> int:
	return ceili(MIN_TEXT_PT * PHONE_POINT_PX * CANVAS_H / PHONE_WINDOW_H)


## The smallest allowed tap target at this window shape, in canvas units.
static func min_tap(window: Vector2) -> float:
	if window.x / maxf(window.y, 1.0) <= PHONE_ASPECT:
		return DESKTOP_TAP
	return ceilf(MIN_TAP_PT * PHONE_POINT_PX * CANVAS_H / PHONE_WINDOW_H)


## `overlap`: also check that cards don't overlap (off mid-fight, where lunges overlap on purpose).
static func problems(root: Control, where: String, overlap: bool = true) -> PackedStringArray:
	var out: PackedStringArray = []
	var window: Rect2 = root.get_viewport_rect()
	var cards: Array[CardView] = []
	_walk(root, window, where, out, cards)
	if not overlap:
		cards.clear()
	for i: int in cards.size():
		for j: int in range(i + 1, cards.size()):
			if _same_hand_fan(cards[i], cards[j]):
				continue
			var shared: float = _shared_face_area(cards[i], cards[j])
			if shared <= 0.0:
				continue
			if (
				shared
				> (
					OVERLAP_SHARE
					* minf(
						_polygon_area(_face_polygon(cards[i])),
						_polygon_area(_face_polygon(cards[j]))
					)
				)
			):
				out.append(
					(
						"%s: cards overlap: %s and %s"
						% [where, _card_name(cards[i]), _card_name(cards[j])]
					)
				)
	return out


static func _face_polygon(card: CardView) -> PackedVector2Array:
	return card.get_global_transform() * Interactive.HexShape.polygon(card.face_rect())


static func _polygon_area(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i: int in points.size():
		total += points[i].cross(points[(i + 1) % points.size()])
	return absf(total) / 2.0


static func _shared_face_area(a: CardView, b: CardView) -> float:
	if not a.get_global_rect().intersects(b.get_global_rect()):
		return 0.0
	var area: float = 0.0
	for polygon: PackedVector2Array in Geometry2D.intersect_polygons(
		_face_polygon(a), _face_polygon(b)
	):
		area += _polygon_area(polygon)
	return area


## Only sibling hand tiles intentionally overlap. Their bounds/fonts/taps were still checked.
## Cards outside that exact fan continue through the ordinary pairwise overlap check.
static func _same_hand_fan(a: CardView, b: CardView) -> bool:
	if a.zone != "hand" or b.zone != "hand" or a.get_parent() != b.get_parent():
		return false
	var parent: Node = a.get_parent()
	var script: Script = parent.get_script() if parent != null else null
	return script != null and script.resource_path == "res://src/ui/widgets/hand_fan.gd"


static func _walk(
	node: Node, window: Rect2, where: String, out: PackedStringArray, cards: Array[CardView]
) -> void:
	var control: Control = node as Control
	if control != null:
		if not control.is_visible_in_tree() or control.modulate.a < 0.05:
			return
		if control is ScrollContainer:
			_check_bounds(control, window, where, out)
			return
		_check_bounds(control, window, where, out)
		_check_font(control, window, where, out)
		_check_tap(control, window, where, out)
		if control is CardView:
			var card: CardView = control
			if card.mouse_filter != Control.MOUSE_FILTER_IGNORE or card.has_meta("overlap_checked"):
				cards.append(card)
		if control is Label:
			_check_label(control as Label, where, out)
			_check_plaque_text(control as Label, where, out)
		if control is RichTextLabel and control.has_meta("must_fit"):
			_check_rich(control as RichTextLabel, where, out)
	for child: Node in node.get_children():
		_walk(child, window, where, out, cards)


## Every piece of text at or over the phone minimum; rules on a tile may go smaller on a desktop.
static func _check_font(
	control: Control, window: Rect2, where: String, out: PackedStringArray
) -> void:
	var font_size: int = 0
	var label: Label = control as Label
	var button: Button = control as Button
	var rich: RichTextLabel = control as RichTextLabel
	if label != null and not label.text.is_empty():
		font_size = label.get_theme_font_size("font_size")
	elif button != null and not button.text.is_empty() and not button.has_meta("drawn_face"):
		font_size = button.get_theme_font_size("font_size")
	elif rich != null and not rich.text.is_empty():
		font_size = rich.get_theme_font_size("normal_font_size")
	if font_size == 0:
		return
	var phone: bool = window.size.x / maxf(window.size.y, 1.0) > PHONE_ASPECT
	var least: int = min_font()
	if control.has_meta("desktop_text") and not phone:
		least = DESKTOP_RULES_FONT
	smallest_text = mini(smallest_text, font_size)
	if font_size < least:
		out.append(
			"%s: %s text %d under the minimum %d" % [where, _describe(control), font_size, least]
		)


## Everything you can tap at least a finger's size on both sides.
static func _check_tap(
	control: Control, window: Rect2, where: String, out: PackedStringArray
) -> void:
	var tappable: bool = control is BaseButton
	if control is Interactive and control.mouse_filter == Control.MOUSE_FILTER_STOP:
		tappable = true
	if not tappable:
		return
	var smallest: float = minf(control.size.x, control.size.y)
	if smallest < 1.0:
		return
	var needed: float = min_tap(window.size)
	if smallest + SLACK < needed:
		out.append(
			(
				"%s: %s tap target %d under the minimum %d"
				% [where, _describe(control), smallest, needed]
			)
		)


static func _check_bounds(
	control: Control, window: Rect2, where: String, out: PackedStringArray
) -> void:
	var rect: Rect2 = control.get_global_rect()
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	if not window.grow(SLACK).encloses(rect):
		out.append("%s: %s leaves the window %s" % [where, _describe(control), rect])
		return
	var parent: Control = control.get_parent() as Control
	if parent is Container and not parent is ScrollContainer:
		if not parent.get_global_rect().grow(SLACK).encloses(rect):
			out.append("%s: %s spills out of its container" % [where, _describe(control)])


## Every marked slip must fit or provide a usable scroll area that reaches all its text.
static func _check_rich(rich: RichTextLabel, where: String, out: PackedStringArray) -> void:
	if rich.text.is_empty() or rich.get_content_height() <= rich.size.y + SLACK:
		return
	if not rich.scroll_active:
		out.append(
			(
				"%s: slip text cut (%d > %d): %s"
				% [where, rich.get_content_height(), rich.size.y, rich.get_parsed_text().left(40)]
			)
		)
		return
	var bar: VScrollBar = rich.get_v_scroll_bar()
	if rich.size.y < rich.get_theme_font_size("normal_font_size") * 3:
		out.append("%s: slip scroll area is too short to read" % where)
	if (
		not bar.is_visible_in_tree()
		or bar.max_value - bar.page < rich.get_content_height() - rich.size.y - SLACK
	):
		out.append("%s: slip cannot scroll through all its text" % where)


## Text that doesn't fit: "wider than its box" / "cut to N of M lines" for plain labels, and
## "trimmed" for labels that clip or add an ellipsis (the card's own text fitting).
static func _check_label(label: Label, where: String, out: PackedStringArray) -> void:
	var card: CardView = label.get_parent() as CardView
	if card != null and label == card.get("_name_label") and CardView.needs_name(card.unit):
		var definition: Dictionary = _name_library.get_unit(str(card.unit.get("def_id", "")))
		if not definition.is_empty() and not CoreUtil.to_bool(definition.get("pool", true)):
			return
	if label.text.is_empty() or (label.has_meta("ellipsis_ok") and card == null):
		return
	var trims: bool = (
		label.clip_text or label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
	)
	var kind: String = "trimmed" if trims else "text"
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		var font: Font = label.get_theme_font("font")
		var font_size: int = label.get_theme_font_size("font_size")
		var needed: float = 0.0
		for line: String in label.text.split("\n"):
			needed = maxf(
				needed, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			)
		var room: float = label.size.x
		var badge: ShapeBadge = label.get_parent() as ShapeBadge
		if badge != null:
			# A badge number must fit inside the drawn shape, not just the badge's box.
			room = minf(room, badge.inner_width())
		if label.get_parent() is TokenButton:
			# A word on a round token must clear the rim at its own height, not just the box.
			var side: float = minf(label.size.x, label.size.y)
			var half_word: float = font.get_height(font_size) * 0.25
			var radius: float = side / 2.0 - TokenButton.RIM
			room = 2.0 * sqrt(maxf(radius * radius - half_word * half_word, 0.0))
		if needed > room + SLACK:
			out.append(
				(
					"%s: %s wider than its box (%d > %d): %s%s"
					% [where, kind, needed, room, label.text, _owner_card(label)]
				)
			)
	elif label.get_visible_line_count() < label.get_line_count():
		out.append(
			(
				"%s: %s cut to %d of %d lines: %s%s"
				% [
					where,
					kind,
					label.get_visible_line_count(),
					label.get_line_count(),
					label.text,
					_owner_card(label)
				]
			)
		)


## " (on card X, W px wide)" when the label belongs to a card.
static func _owner_card(node: Node) -> String:
	var at: Node = node.get_parent()
	while at != null and not at is CardView:
		at = at.get_parent()
	if at == null:
		return ""
	var card: CardView = at
	return " (on card %s, %d px wide)" % [_card_name(card), card.card_size.x]


static func _card_name(card: CardView) -> String:
	return "%s (%s %d)" % [str(card.unit.get("name", "?")), card.zone, card.index]


static func _describe(control: Control) -> String:
	var label: Label = control as Label
	if label != null:
		return "label '%s'" % label.text.left(40)
	var button: Button = control as Button
	if button != null:
		return "button '%s'" % button.text
	if control is CardView:
		return "card %s" % _card_name(control as CardView)
	var inner: Array[Node] = control.find_children("*", "Label", true, false)
	var text: String = (inner[0] as Label).text if not inner.is_empty() else ""
	return "%s '%s'%s" % [control.get_class(), text, _owner_card(control)]


## A label's box can fit while its ink crosses a rounded plaque's lower corners.
static func _check_plaque_text(label: Label, where: String, out: PackedStringArray) -> void:
	var plaque: LobbyPlaque = label.get_parent() as LobbyPlaque
	if plaque == null or label.name != "LastStand":
		return
	var font: Font = label.get_theme_font("font")
	var font_size: int = label.get_theme_font_size("font_size")
	var ink_size := Vector2(
		font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x,
		font.get_height(font_size)
	)
	var ink := Rect2(label.position + (label.size - ink_size) / 2.0, ink_size)
	var face := Rect2(Vector2.ZERO, plaque.size).grow(-5.0)
	var radius: float = minf(38.0, face.size.y / 2.0)
	if label.has_theme_stylebox_override("normal"):
		if label.position.x < -SLACK or label.get_rect().end.x > plaque.size.x + SLACK:
			out.append("%s: status tag crosses plaque width: %s" % [where, label.text])
		var tag: StyleBoxFlat = label.get_theme_stylebox("normal") as StyleBoxFlat
		var border: float = float(tag.border_width_top)
		face = label.get_rect().grow(-border)
		radius = maxf(0.0, float(tag.corner_radius_top_left) - border)
	var center := Rect2(
		face.position + Vector2.ONE * radius, face.size - Vector2.ONE * radius * 2.0
	)
	for corner: Vector2 in [
		ink.position,
		ink.end,
		Vector2(ink.position.x, ink.end.y),
		Vector2(ink.end.x, ink.position.y)
	]:
		var nearest := Vector2(
			clampf(corner.x, center.position.x, center.end.x),
			clampf(corner.y, center.position.y, center.end.y)
		)
		if corner.distance_to(nearest) > radius + SLACK:
			out.append("%s: text crosses rounded plaque edge: %s" % [where, label.text])
			return
