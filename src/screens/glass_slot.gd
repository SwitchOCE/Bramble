class_name GlassSlot
extends RefCounted
## A board slot as drawn on its own (the recruit board's and both fight sides'), from a slot's
## entry as GlassScreen.slot_info reads it ({buff, buff_name, renown}, or {} for nothing on it).


## An empty board slot (stage.css .slot and .slot::after): a dim pane in a lead outline, or the
## Ring slot (.slot.ring::after) with its bonus written on it when the slot carries one.
static func make(info: Dictionary, size: Vector2) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.box_size = size
	var whole: Rect2 = Rect2(Vector2.ZERO, box.box_size)
	var inset: Array = GlassPieces.rule("stage", ".slot::after", "inset")
	var inner: Rect2 = whole.grow_individual(
		-GlassPieces.as_float(inset[1]),
		-GlassPieces.as_float(inset[0]),
		-GlassPieces.as_float(inset[1]),
		-GlassPieces.as_float(inset[0])
	)
	var outer_clip: Array = GlassPieces.rule("stage", ".slot", "clip-path")
	var inner_clip: Array = GlassPieces.rule("stage", ".slot::after", "clip-path")
	box.polygon_outer = GlassBox.css_polygon(outer_clip, whole)
	box.polygon_inner = GlassBox.css_polygon(inner_clip, inner)
	var lead: Array = GlassPieces.rule("stage", ".slot", "background")
	var lead_layer: Dictionary = lead[0]
	box.border_colour = Color.html(str(lead_layer["colour"]))
	box.border_width = GlassPieces.as_float(inset[0])
	box.padding_override = inner
	var ring: bool = info.has("buff")
	box.layers = GlassPieces.rule(
		"stage", ".slot.ring::after" if ring else ".slot::after", "background"
	)
	box.blend_modes = GlassPieces.rule(
		"stage", ".slot.ring::after" if ring else ".slot::after", "background-blend-mode"
	)
	box.refresh()
	if ring:
		_words(box, str(info.get("buff", "")), str(info.get("buff_name", "")))
	if GlassPieces.as_int(info.get("renown", 0)) != 0:
		var banner: GlassBox = renown_banner(GlassPieces.as_int(info["renown"]), box.box_size)
		banner.name = "Renown"
		box.add_child(banner)
	return box


## STAND-IN: a slot's Renown as a small pill at the slot's head ("Renown 3"), placed for a slot
## of `size` at the slot's own origin. The board draws the same pill over a unit standing there.
static func renown_banner(renown: int, size: Vector2) -> GlassBox:
	var pill: GlassBox = GlassParts.make_pill("Renown %d" % renown)
	pill.position = Vector2((size.x - pill.box_size.x) / 2.0, 0.0)
	return pill


## .slot .rt: the bonus over its name, a column centred on the slot, line-height 1.
static func _words(box: GlassBox, buff: String, buff_name: String) -> void:
	var em: float = roundf(box.box_size.y * GlassPieces.number("stage.slot.ring_text_per_h"))
	var big: GlassText = GlassText.from_rule("stage", ".slot .rt", buff)
	big.font_px = em
	big.line_height = GlassPieces.as_float(GlassPieces.rule("stage", ".slot .rt", "line-height"))
	big.refresh()
	var small: GlassText = GlassText.from_rule("stage", ".slot .rt small", buff_name.to_upper())
	small.font_px = (
		em
		* GlassParts.em_px(
			(GlassPieces.rule_font("stage", ".slot .rt small") as Dictionary)["size"], 1.0
		)
	)
	small.line_height = big.line_height
	small.spacing = GlassParts.em_px(
		GlassPieces.rule("stage", ".slot .rt small", "letter-spacing"), small.font_px
	)
	var shadows: Array = GlassPieces.rule("stage", ".slot .rt small", "text-shadow")
	small.shadow = shadows[0]
	small.refresh()
	var gap: float = GlassParts.em_px(
		GlassPieces.rule("stage", ".slot .rt small", "margin-top"), small.font_px
	)
	var total: float = big.size.y + gap + small.size.y
	var top: float = (box.box_size.y - total) / 2.0
	big.position = Vector2((box.box_size.x - big.size.x) / 2.0, top)
	# letter-spacing adds space after the last letter too, so the word sits a little left
	small.position = Vector2((box.box_size.x - small.size.x) / 2.0, top + big.size.y + gap)
	box.add_child(big)
	box.add_child(small)
