extends RefCounted
## Finds layout faults on a live screen: controls that leave the window, controls that spill out
## of their container, labels whose text doesn't fit (or is cut to fewer lines), and cards that
## overlap. Used by the scripted playthrough (tests/ui/shots/playthrough.gd) and its gate test.

const CardView := preload("res://src/ui/widgets/card_view.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")

## Pixels of slack before something counts as out of bounds.
const SLACK: float = 2.0
## Cards may touch; they overlap when the shared area is bigger than this share of a card.
const OVERLAP_SHARE: float = 0.08


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
			var a: Rect2 = cards[i].get_global_rect()
			var b: Rect2 = cards[j].get_global_rect()
			var shared: float = a.intersection(b).get_area()
			if shared > OVERLAP_SHARE * minf(a.get_area(), b.get_area()):
				out.append(
					(
						"%s: cards overlap: %s and %s"
						% [where, _card_name(cards[i]), _card_name(cards[j])]
					)
				)
	return out


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
		if control is CardView:
			var card: CardView = control
			if card.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				cards.append(card)
		if control is Label:
			_check_label(control as Label, where, out)
	for child: Node in node.get_children():
		_walk(child, window, where, out, cards)


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


## Text that doesn't fit: "wider than its box" / "cut to N of M lines" for plain labels, and
## "trimmed" for labels that clip or add an ellipsis (the card's own text fitting).
static func _check_label(label: Label, where: String, out: PackedStringArray) -> void:
	if label.text.is_empty():
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
