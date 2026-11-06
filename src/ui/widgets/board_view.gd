extends Control
## The 4-3 brick (.wc-board): an oak tray cut to the shape, four front pockets and three back ones
## offset by half a pocket (rulebook 8.1), with dotted grooves from each back pocket to the two
## front pockets in front of it. Pockets are fixed and always drawn. Tiles are placed by hand so
## combat playback can move them freely.
##
## `front_toward_top` puts the front row on top (your board) or at the bottom (the enemy's, facing
## you). Slot indices are SPEC's: 0-3 front, 4-6 back. With `with_labels` each pocket has a name
## strip (recruit); without, a slot chip sits on its bottom edge (combat).

const UiTheme := preload("res://src/ui/ui_theme.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const SlotView := preload("res://src/ui/widgets/slot_view.gd")
const Icons := preload("res://src/ui/widgets/icons.gd")
const SlotMarks := preload("res://src/ui/widgets/slot_marks.gd")

const SLOTS: int = 7
const FRONT: int = 4
const BORDER: float = 7.0
const LABEL_H: float = 44.0
const LABEL_GAP: float = 6.0
const EDGE: float = 15.0
const SLOT_NAMES: PackedStringArray = SlotView.SLOT_NAMES

var zone: String = "board"
## Pocket size (recruit 209 x 189, combat 189 x 169).
var pocket: Vector2 = Vector2(209, 189)
var gap: float = 24.0
var pad: float = 27.0
var front_toward_top: bool = true
var with_labels: bool = false
var with_notes: bool = false

var slots: Array[SlotView] = []
## Card in each slot, or null.
var cards: Array[CardView] = []

var _labels: Array[Panel] = []
var _label_names: Array[Label] = []
var _chips: Array[Label] = []
var _marks: SlotMarks


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for i: int in SLOTS:
		var slot: SlotView = SlotView.new()
		slot.set_slot(zone, i)
		add_child(slot)
		slots.append(slot)
		cards.append(null)
	for i: int in SLOTS:
		var strip: Panel = Panel.new()
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_theme_stylebox_override("panel", UiTheme.slip_box(UiTheme.BIRCH, 3, 8))
		strip.visible = false
		add_child(strip)
		var chip: Label = _slot_chip(SLOT_NAMES[i])
		chip.position = Vector2.ZERO
		strip.add_child(chip)
		var words: Label = UiTheme.head("", UiTheme.FONT_SMALL)
		words.clip_text = true
		words.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		words.set_meta("ellipsis_ok", true)
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		strip.add_child(words)
		_labels.append(strip)
		_label_names.append(words)
	for i: int in SLOTS:
		var chip: Label = _slot_chip(SLOT_NAMES[i])
		chip.z_index = 2
		chip.visible = false
		add_child(chip)
		_chips.append(chip)
	_marks = SlotMarks.new(self)
	add_child(_marks)
	resized.connect(_layout)
	ready.connect(_layout)


func _slot_chip(words: String) -> Label:
	var chip: Label = UiTheme.number(words, UiTheme.FONT_SMALL, UiTheme.BIRCH)
	var face: StyleBoxFlat = UiTheme.flat_box(UiTheme.INK, Color.TRANSPARENT, 0, 7)
	face.content_margin_left = 6
	face.content_margin_right = 6
	face.content_margin_top = 0
	face.content_margin_bottom = 0
	chip.add_theme_stylebox_override("normal", face)
	chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return chip


## `labels`: a name strip per pocket (recruit), else a slot chip on its edge (combat).
func configure(
	board_zone: String,
	pocket_width: float,
	front_on_top: bool,
	labels: bool = false,
	notes: bool = false
) -> void:
	zone = board_zone
	pocket = Vector2(pocket_width, roundf(pocket_width * 112.0 / 124.0))
	gap = roundf(pocket_width * 14.0 / 124.0)
	pad = roundf(pocket_width * 16.0 / 124.0)
	front_toward_top = front_on_top
	with_labels = labels
	with_notes = notes
	for i: int in SLOTS:
		slots[i].set_slot(zone, i)
		slots[i].with_note = notes
		_labels[i].visible = false
		_chips[i].visible = false
	custom_minimum_size = tray_size()
	size = custom_minimum_size
	_layout()


## The tile that stands in a pocket.
func tile_width() -> float:
	return roundf(pocket.x * 112.0 / 124.0)


func tray_size() -> Vector2:
	var width: float = FRONT * pocket.x + (FRONT - 1) * gap + pad * 2.0 + BORDER * 2.0
	return Vector2(width, _row_height(true) + _row_height(false) + EDGE)


func _row_height(front: bool) -> float:
	var strip: float = LABEL_H + LABEL_GAP if with_labels else 0.0
	var inner: float = 38.0 if not front else 20.0
	return BORDER + _outer() + strip + pocket.y + inner


## Wood between the tray's outer edge and the pockets (or name strips).
func _outer() -> float:
	return 8.0 if with_labels else 18.0


## Top-left of a slot's pocket in this board's local coordinates.
func slot_position(slot: int) -> Vector2:
	var front: bool = slot < FRONT
	var column: float = float(slot) if front else float(slot - FRONT) + 0.5
	var x: float = BORDER + pad + column * (pocket.x + gap)
	var strip: float = LABEL_H + LABEL_GAP if with_labels else 0.0
	var y: float
	if front_toward_top:
		if front:
			y = BORDER + _outer() + strip
		else:
			y = _row_height(true) + 38.0
	else:
		if front:
			y = _row_height(false) + 20.0
		else:
			y = BORDER + _outer()
	return Vector2(x, y)


func slot_global_center(slot: int) -> Vector2:
	return get_global_transform() * (slot_position(slot) + pocket / 2.0)


## Where a tile sits inside its pocket (raised a little, as in the mock).
func card_position(slot: int) -> Vector2:
	var width: float = tile_width()
	var tile_h: float = CardView.size_for(width, CardView.Mode.BOARD).y
	return slot_position(slot) + Vector2((pocket.x - width) / 2.0, (pocket.y - tile_h) / 2.0 - 6.0)


## The tray's rectangle for one row: [front, back] joined at the shared edge.
func row_rect(front: bool) -> Rect2:
	var full: Vector2 = tray_size()
	var width: float = FRONT * pocket.x + (FRONT - 1) * gap + pad * 2.0 + BORDER * 2.0
	var back_w: float = 3.0 * pocket.x + 2.0 * gap + pad * 2.0 + BORDER * 2.0
	var back_x: float = (width - back_w) / 2.0
	var top_h: float = _row_height(front_toward_top)
	if front == front_toward_top:
		return Rect2(0.0 if front else back_x, 0.0, width if front else back_w, top_h)
	var bottom_h: float = full.y - EDGE - top_h
	return Rect2(0.0 if front else back_x, top_h, width if front else back_w, bottom_h)


func _layout() -> void:
	for i: int in SLOTS:
		slots[i].position = slot_position(i)
		slots[i].size = pocket
		var card: CardView = cards[i]
		if card != null:
			card.position = card_position(i)
		_place_label(i)
	queue_redraw()


func _place_label(i: int) -> void:
	var strip: Panel = _labels[i]
	var card: CardView = cards[i]
	strip.visible = with_labels and card != null
	var chip_on: bool = not with_labels and card != null
	_chips[i].visible = chip_on
	if strip.visible:
		var front: bool = i < FRONT
		var at: Vector2 = slot_position(i)
		var y: float = at.y - LABEL_H - LABEL_GAP if front else at.y + pocket.y + LABEL_GAP
		strip.position = Vector2(at.x - 4.0, y)
		strip.size = Vector2(pocket.x + 8.0, LABEL_H)
		var chip: Label = strip.get_child(0) as Label
		chip.size = Vector2(54, LABEL_H)
		var words: Label = _label_names[i]
		words.position = Vector2(60, -1)
		words.size = Vector2(strip.size.x - 66.0, LABEL_H)
		words.text = fit_name(str(card.unit.get("name", "")), words)
	if chip_on:
		var chip: Label = _chips[i]
		chip.size = Vector2(52, 42)
		chip.position = slot_position(i) + Vector2((pocket.x - 52.0) / 2.0, pocket.y - 26.0)


## The whole name if it fits the strip, else its last word ("Still-Water Heron" -> "Heron"), else
## nothing: the art and a tap name the unit, and a strip never trails off.
static func fit_name(full: String, words: Label) -> String:
	var font: Font = words.get_theme_font("font")
	var last: String = full.get_slice(" ", full.get_slice_count(" ") - 1)
	var part: String = last.get_slice("-", last.get_slice_count("-") - 1)
	for attempt: String in [full, last, part]:
		var wide: float = (
			font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.FONT_SMALL).x
		)
		if wide <= words.size.x:
			return attempt
	return ""


## Rings and Rainbow bands, one entry per slot (RecruitView.slot_marks).
func set_marks(slot_marks: Array) -> void:
	_marks.set_marks(slot_marks)


## The slot a Pass would land on, or -1.
func set_pass_landing(slot: int) -> void:
	_marks.pass_slot = slot


## Oak faces cut to the brick, the carved edge below, then the grooves between the rows.
func _draw() -> void:
	var top: Rect2 = row_rect(front_toward_top)
	var bottom: Rect2 = row_rect(not front_toward_top)
	var under: StyleBoxFlat = _row_box(UiTheme.CARVE, UiTheme.INK, BORDER)
	draw_style_box(under, Rect2(top.position + Vector2(0, EDGE), top.size))
	draw_style_box(under, Rect2(bottom.position + Vector2(0, EDGE), bottom.size))
	for rect: Rect2 in [row_rect(true), row_rect(false)]:
		draw_style_box(_row_box(UiTheme.OAK, UiTheme.INK, BORDER), rect)
	# The narrower row's join: the wood runs through with no line across.
	var narrow: Rect2 = row_rect(false)
	var seam_y: float = top.end.y
	var join: Rect2 = Rect2(
		narrow.position.x + BORDER,
		seam_y - BORDER - 12.0,
		narrow.size.x - BORDER * 2.0,
		24.0 + BORDER * 2.0
	)
	draw_rect(join, UiTheme.OAK)
	for rect: Rect2 in [row_rect(true), row_rect(false)]:
		var inset: float = 12.0
		var grain: Rect2 = rect.grow_individual(-BORDER, -inset, -BORDER, -inset)
		draw_texture_rect(Icons.tile("oak"), grain, true)
	_draw_grooves()


func _row_box(fill: Color, line: Color, width: float) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = line
	box.set_border_width_all(roundi(width))
	box.corner_detail = 6
	var round_corner: int = 30
	box.corner_radius_top_left = round_corner
	box.corner_radius_top_right = round_corner
	box.corner_radius_bottom_left = round_corner
	box.corner_radius_bottom_right = round_corner
	return box


func _draw_grooves() -> void:
	for back: int in range(FRONT, SLOTS):
		var back_at: Vector2 = slot_position(back)
		var from_y: float = back_at.y + (pocket.y if back_at.y < slot_position(0).y else 0.0)
		var from: Vector2 = Vector2(back_at.x + pocket.x / 2.0, from_y)
		for front: int in [back - FRONT, back - FRONT + 1]:
			# Each groove is a link of the zigzag: lit when units stand at both ends.
			var lit: bool = with_labels and cards[back] != null and cards[front] != null
			var dot: Color = UiTheme.ACORN if lit else Color(UiTheme.INK, 0.9)
			var front_at: Vector2 = slot_position(front)
			var to_y: float = front_at.y + (pocket.y if front_at.y < back_at.y else 0.0)
			var to: Vector2 = Vector2(front_at.x + pocket.x / 2.0, to_y)
			var steps: int = maxi(2, roundi(from.distance_to(to) / 22.0))
			for step: int in steps + 1:
				var at: Vector2 = from.lerp(to, float(step) / steps)
				if lit:
					draw_circle(at, 9.0, UiTheme.INK)
				draw_circle(at, 6.0, dot)


## Puts a card into a slot (replacing whatever was there). The board owns it from now on.
func place_card(card: CardView, slot: int) -> void:
	remove_card(slot)
	cards[slot] = card
	if card.get_parent() != self:
		if card.get_parent() != null:
			card.get_parent().remove_child(card)
		add_child(card)
		# Slot chips and name strips stay readable over the tile.
		for strip: Panel in _labels:
			move_child(strip, -1)
		for chip: Label in _chips:
			move_child(chip, -1)
	card.mode = CardView.Mode.BOARD
	card.set_card_width(tile_width())
	card.position = card_position(slot)
	slots[slot].filled = true
	_place_label(slot)
	move_child(_marks, -1)
	queue_redraw()


## Takes the card out of the slot and frees it.
func remove_card(slot: int) -> void:
	var card: CardView = cards[slot]
	cards[slot] = null
	slots[slot].filled = false
	_place_label(slot)
	queue_redraw()
	if card != null:
		remove_child(card)
		card.queue_free()


## Takes the card out of the slot without freeing it (combat animates it elsewhere).
func detach_card(slot: int) -> CardView:
	var card: CardView = cards[slot]
	cards[slot] = null
	slots[slot].filled = false
	_place_label(slot)
	return card


func clear() -> void:
	for i: int in SLOTS:
		remove_card(i)


func slot_of_card(card: CardView) -> int:
	return cards.find(card)


func clear_highlights() -> void:
	for slot: SlotView in slots:
		slot.highlight = Color.TRANSPARENT
	for card: CardView in cards:
		if card != null:
			card.outline = Color.TRANSPARENT
			card.selected = false
