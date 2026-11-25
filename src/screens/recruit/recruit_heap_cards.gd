class_name RecruitHeapCards
extends RefCounted
## A heap's read-only miniature cards, in the order of each group's newest copy.


static func groups(entries: Array) -> Array[Dictionary]:
	var grouped: Array[Dictionary] = []
	var indices: Dictionary = {}
	for i: int in range(entries.size() - 1, -1, -1):
		var card: Dictionary = entries[i]
		var key: Array = [card.get("id", ""), card.get("tier", 1), card.get("golden", false)]
		if not indices.has(key):
			indices[key] = grouped.size()
			grouped.append({"card": card, "count": 0})
		grouped[GlassPieces.as_int(indices[key])]["count"] += 1
	return grouped


static func fill(spread: Control, grouped: Array[Dictionary]) -> void:
	var view: Rect2 = L1Layout.rect("panel.heap.view")
	var card: Rect2 = L1Layout.rect("panel.heap.card")
	var cols: int = int(L1Layout.number("panel.heap.columns"))
	var gap: Vector2 = L1Layout.point("panel.heap.gap")
	var step: Vector2 = card.size + gap
	var rows: int = ceili(float(grouped.size()) / cols)
	var left: float = (view.size.x - (cols * step.x - gap.x)) / 2.0
	left -= L1Layout.number("panel.heap.nudge")
	spread.custom_minimum_size.y = (rows - 1) * step.y + card.end.y + card.position.y
	for i: int in grouped.size():
		var at: Vector2 = Vector2(left + (i % cols) * step.x, card.position.y)
		at.y += floorf(float(i) / cols) * step.y
		var made: Control = _card(grouped[i], card.size)
		made.name = "HeapCard_%d" % i
		made.position = at
		spread.add_child(made)


static func _card(group: Dictionary, box: Vector2) -> Control:
	var card: Dictionary = group["card"]
	var copies: int = group["count"]
	var golden: bool = GlassScreen._b(card.get("golden", false))
	var holder: Control = L1ColumnArt.area(Rect2(Vector2.ZERO, box))
	var step: float = L1Layout.number("panel.heap.stack_step")
	var extra: int = int(L1Layout.number("panel.heap.stack_edges"))
	for edge: int in range(mini(copies - 1, extra), 0, -1):
		var back: L1CardFace = L1CardFace.new()
		back.build(box, null)
		back.position = Vector2(step, -step) * edge
		holder.add_child(back)
	var face: L1CardFace = L1CardFace.new()
	face.build(box, GlassPieces.art(str(card.get("art", ""))))
	if golden:
		face.set_gilt(true, 0.0, false)
	holder.add_child(face)
	_stats(holder, card, golden)
	if copies > 1:
		var badge_rect: Rect2 = L1Layout.rect("panel.heap.badge")
		badge_rect.position.x += box.x / 2.0
		var badge: GlassBox = _badge(
			badge_rect,
			"0e1314",
			"59605f",
			"1a2226",
			L1Layout.number("panel.heap.badge_rim"),
			L1Layout.number("panel.heap.badge_line"),
			L1Layout.number("panel.heap.badge_radius")
		)
		badge.name = "Copies"
		var label: GlassText = L1ColumnArt.text(
			"×%d" % copies, L1Layout.number("panel.heap.badge_font"), RecruitAuraPanel.CREAM
		)
		L1ColumnArt.fit_number(
			label, label.words, label.font_px, badge.size / 2.0, badge_rect.size.x
		)
		badge.add_child(label)
		holder.add_child(badge)
	return holder


static func _stats(holder: Control, card: Dictionary, golden: bool) -> void:
	var key: String = "panel.heap.stat."
	var diameter: float = L1Layout.number(key + "d")
	var inset: float = L1Layout.number(key + "x")
	var y: float = holder.size.y - holder.size.x * tan(L1CardFace.point_angle()) / 2.0
	y -= diameter * L1Layout.number(key + "y_share")
	for stat: String in ["attack", "health"]:
		var x: float = inset if stat == "attack" else holder.size.x - inset - diameter
		var rect: Rect2 = Rect2(Vector2(x, y), Vector2.ONE * diameter)
		var badge: GlassBox = _badge(
			rect,
			"d9a24a" if golden else "1c201f",
			"fff0b8" if golden else "555b58",
			"e6d6b4",
			L1Layout.number(key + "rim"),
			L1Layout.number(key + "line"),
			diameter / 2.0
		)
		var face: GlassBox = badge.get_node("Face")
		var focus: Vector2 = L1Layout.point(key + "focus")
		face.layers = [
			{
				"kind": "radial",
				"at": [focus.x, focus.y],
				"stops": [["fbf4e2", 0], ["e6d6b4", 60], ["c9b48d", 100]]
			}
		]
		face.refresh()
		var words: String = GlassScreen.number_words(card.get(stat, 0))
		var font: float = L1Layout.number(key + "font")
		var label: GlassText = L1ColumnArt.text(words, font, Color("241d14"))
		L1ColumnArt.fit_number(label, words, font, badge.size / 2.0, diameter)
		badge.add_child(label)
		holder.add_child(badge)


static func _badge(
	rect: Rect2,
	rim_colour: String,
	line_colour: String,
	face_colour: String,
	rim: float,
	line: float,
	radius: float
) -> GlassBox:
	var outer: GlassBox = GlassBox.new()
	outer.position = rect.position - Vector2.ONE * (rim + line)
	outer.box_size = rect.grow(rim + line).size
	outer.radii = Vector4.ONE * (radius + rim + line)
	outer.layers = [{"kind": "colour", "colour": rim_colour}]
	outer.border_width = line
	outer.border_colour = Color(line_colour)
	outer.refresh()
	var face: GlassBox = GlassBox.new()
	face.name = "Face"
	face.position = Vector2.ONE * (rim + line)
	face.box_size = rect.size
	face.radii = Vector4.ONE * radius
	face.layers = [{"kind": "colour", "colour": face_colour}]
	face.refresh()
	outer.add_child(face)
	return outer
