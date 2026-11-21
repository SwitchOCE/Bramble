class_name RecruitWaitingPile
extends RefCounted
## The small stack shows the newest gain. The hover lists cards in arrival order.

const TOP: Vector2 = Vector2(1380, 972)
const COUNT_OFFSET: Vector2 = Vector2(104, -8)
const FAN_STEP: Vector2 = Vector2(12, -4)
const VISIBLE_CARDS: int = 3
const CARD_H: float = 170.0
const COLUMN_W: float = 120.0
const PANE_PAD: float = 18.0
const PANE_GAP: float = 8.0
const MAX_COLUMNS: int = 5
const INK: Color = Color("#efe6d2")

var _screen: RecruitScreen
var _count: GlassBox
var _pane: GlassBox
var _scroll: ScrollContainer
var _entries: Array[Dictionary] = []


func _init(screen: RecruitScreen) -> void:
	_screen = screen


func want_cards() -> void:
	var cards: Array = _screen.state.get("waiting_pile", [])
	var last: int = cards.size() - 1
	for i: int in range(maxi(0, cards.size() - VISIBLE_CARDS), cards.size()):
		var card: Dictionary = cards[i]
		var depth: int = i - last
		var at: Vector2 = TOP + depth * FAN_STEP
		if GlassScreen._is_spell(card):
			at.y += 8.0
		_screen._want_card(
			GlassScreen.card_key("waiting_pile", i, card),
			"waiting_pile",
			i,
			card,
			at,
			9.0 + depth * 4.0,
			{"waiting_tint": 0.86 if depth == 0 else 0.62}
		)


func build_count() -> void:
	_count = null
	_pane = null
	_scroll = null
	_entries.clear()
	var cards: Array = _screen.state.get("waiting_pile", [])
	if cards.is_empty():
		return
	_count = count_chip(cards.size())
	_count.name = "WaitingCount"
	_count.position = TOP + COUNT_OFFSET
	_count.z_index = 7
	_screen._front.add_child(_count)


## The stack's count: "+N" on a cream chip.
static func count_chip(count: int) -> GlassBox:
	var label: GlassText = _label("+%d" % count, 26, 900, Color("#16120e"))
	label.family = "display"
	label.refresh()
	var chip: GlassBox = GlassBox.new()
	chip.box_size = Vector2(maxf(52.0, label.size.x + 26.0), 40.0)
	chip.use_css("stage", ".chipv")
	chip.radii = Vector4.ONE * 20.0
	chip.border_width = 3.0
	chip.shadows = [
		{"inset": false, "x": 0, "y": 0, "blur": 10, "spread": 0, "colour": "#ffc86e8c"},
		{"inset": false, "x": 0, "y": 3, "blur": 6, "spread": 0, "colour": "#00000099"}
	]
	chip.refresh()
	label.position = (chip.box_size - label.size) / 2.0
	chip.add_child(label)
	return chip


func hover(here: Vector2, tips: RecruitTips) -> bool:
	if (
		_count == null
		or _screen.is_discovering()
		or _screen.is_aiming()
		or not _screen._hover_allowed()
	):
		close()
		return false
	if not _count.get_rect().has_point(here) and not _over_cards(here) and not _over_pane(here):
		close()
		return false
	if _pane == null:
		_build_pane()
		_count.border_colour = Color("#ffb24a")
		_count.refresh()
	var clip := Rect2(_pane.position + _scroll.position, _scroll.size)
	if clip.has_point(here):
		for entry: Dictionary in _entries:
			var node: Control = entry["node"]
			if Rect2(Vector2.ZERO, node.size).has_point(_screen._to_local_of(node, here)):
				if tips.hot != node or not tips.tip.visible:
					tips.show(entry, here)
				return true
	tips.hide()
	return true


func close() -> void:
	if not is_instance_valid(_pane):
		return
	_pane.hide()
	_pane.queue_free()
	_pane = null
	_entries.clear()
	_count.border_colour = Color("#16120e")
	_count.refresh()


func _over_cards(here: Vector2) -> bool:
	var hit: Dictionary = _screen.card_target_at(here, ["waiting_pile"])
	var node: Control = hit.get("node")
	return node != null and node.visible


func _over_pane(here: Vector2) -> bool:
	if _pane == null:
		return false
	if _pane.get_rect().has_point(here):
		return true
	# Keep the list open along the short path between it and the stack.
	var bridge := Rect2(
		Vector2(TOP.x - 24.0, _pane.position.y + _pane.size.y),
		Vector2(COUNT_OFFSET.x + _count.size.x + 24.0, TOP.y - _pane.position.y - _pane.size.y)
	)
	return bridge.has_point(here)


func _build_pane() -> void:
	var cards: Array = _screen.state["waiting_pile"]
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 0)
	for i: int in cards.size():
		var card: Dictionary = cards[i]
		row.add_child(_column(card, i == 0))
	var width: float = mini(cards.size(), MAX_COLUMNS) * COLUMN_W
	var row_height: float = row.get_combined_minimum_size().y
	_pane = GlassBox.new()
	_pane.name = "WaitingPane"
	var title: GlassText = _label("Waiting", 26, 900, INK)
	title.family = "display"
	title.refresh()
	title.position = Vector2(PANE_PAD, 14.0)
	_pane.add_child(title)
	var note: GlassText = _label(
		"They join your hand as places free up.", 18, 400, Color("#d9cfbb")
	)
	note.position = Vector2(PANE_PAD, title.position.y + title.size.y + 4.0)
	_pane.add_child(note)
	_scroll = ScrollContainer.new()
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.get_h_scroll_bar().mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(row)
	_scroll.position = Vector2(PANE_PAD, note.position.y + note.size.y + 12.0)
	var scrollbar: float = 12.0 if cards.size() > MAX_COLUMNS else 0.0
	_scroll.size = Vector2(width, row_height + scrollbar)
	_pane.add_child(_scroll)
	_pane.box_size = Vector2(
		maxf(width, note.size.x) + 2.0 * PANE_PAD, _scroll.position.y + _scroll.size.y + 16.0
	)
	_pane.use_css("stage", "#tip .txt").refresh()
	_pane.position = TOP + Vector2(30.0 - _pane.box_size.x / 2.0, -40.0 - _pane.box_size.y)
	_pane.z_index = 7
	_screen._front.add_child(_pane)


func _column(card: Dictionary, first: bool) -> Control:
	var column := Control.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var node: Control
	if GlassScreen._is_spell(card):
		node = _screen._spell_card(card, _screen._spell_size() * CARD_H / _screen.card_box().y)
	else:
		node = _screen._unit_card(card, CARD_H)
		node.size = GlassCard.card_size(CARD_H)
	node.position.x = (COLUMN_W - node.size.x) / 2.0
	column.add_child(node)
	_entries.append({"kind": "waiting_preview", "node": node, "card": card})
	var y: float = node.size.y + PANE_GAP
	for line: String in GlassParts.wrap_words(str(card.get("name", "")), COLUMN_W - PANE_GAP, 16):
		var name: GlassText = _label(line, 16, 700, INK)
		name.position = Vector2((COLUMN_W - name.size.x) / 2.0, y)
		column.add_child(name)
		y += name.size.y
	if first:
		var next: GlassText = _label("Next", 13, 700, Color("#ffcf8a"))
		next.position = Vector2((COLUMN_W - next.size.x) / 2.0, y + 4.0)
		column.add_child(next)
		y = next.position.y + next.size.y
	column.custom_minimum_size = Vector2(COLUMN_W, y)
	return column


static func _label(words: String, px: float, weight: int, ink: Color) -> GlassText:
	var label := GlassText.new()
	label.words = words
	label.font_px = px
	label.weight = weight
	label.colour = ink
	return label.refresh()
