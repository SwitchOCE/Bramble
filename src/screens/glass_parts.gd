class_name GlassParts
extends RefCounted
## The small glass pieces the screens share, each from stage.css: pips, pills, portraits,
## Health badges, the hover detail's words, and the STAND-IN frost. All static.

## STAND-IN: the frozen shop's ice, over each shop card and the freeze button (no mock-up).
const FROST: Color = Color(0.55, 0.85, 1.0, 0.32)
const FROST_EDGE: Color = Color(0.8, 0.95, 1.0, 0.95)
## STAND-IN: a valid target's light (the end-turn glow's amber, stage.css --go).
const LIT_EDGE: Color = Color("ffb24a")
const LIT_GLOW: Color = Color(1.0, 0.7, 0.29, 0.35)
const LIT_WASH: Color = Color(1.0, 0.7, 0.29, 0.12)
## STAND-IN ability button: its words' size, its height and its side padding.
const ABILITY_PX: float = 18.0
const ABILITY_HEIGHT: float = 32.0
const ABILITY_PAD: float = 12.0


## .btn .pip: a lead pill with the number, its sizes in em of the button's font.
static func make_pip(words: String, button_px: float) -> GlassBox:
	var em: float = button_px * em_px(GlassPieces.rule("stage", ".btn .pip", "font-size"), 1.0)
	var label: GlassText = GlassText.new()
	label.words = words
	label.use_font(GlassPieces.rule_font("stage", ".btn"))
	label.font_px = em
	label.colour = GlassPieces.rule_colour("stage", ".btn .pip", "color")
	label.refresh()
	var pad: Array = GlassPieces.rule("stage", ".btn .pip", "padding")
	var border: Dictionary = GlassPieces.rule("stage", ".btn .pip", "border")
	var height: float = em_px(GlassPieces.rule("stage", ".btn .pip", "height"), em)
	var width: float = maxf(
		em_px(GlassPieces.rule("stage", ".btn .pip", "min-width"), em),
		label.size.x + 2.0 * em_px(pad[1], em) + 2.0 * _f(border["width"])
	)
	var pill: GlassBox = GlassBox.new()
	pill.box_size = Vector2(width, height)
	pill.use_css("stage", ".btn .pip")
	pill.radii = Vector4.ONE * em_px(GlassPieces.rule("stage", ".btn .pip", "border-radius"), em)
	pill.refresh()
	label.position = (pill.box_size - label.size) / 2.0
	pill.add_child(label)
	return pill


## A CSS length in px: a number, "1.4em" of em px, or "50%" of em too (for radii on squares).
static func em_px(value: Variant, em: float) -> float:
	var text: String = str(value)
	if text.ends_with("em"):
		return text.trim_suffix("em").to_float() * em
	return _f(value)


## A pill's outline (radius half the height), for the frost on a button.
static func round_poly(box: Vector2) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var r: float = box.y / 2.0
	for i: int in 13:
		out.append(Vector2(box.x - r, r) + Vector2.from_angle(-PI / 2.0 + PI * i / 12.0) * r)
	for i: int in 13:
		out.append(Vector2(r, r) + Vector2.from_angle(PI / 2.0 + PI * i / 12.0) * r)
	return out


static func rect_poly(box: Vector2) -> PackedVector2Array:
	return PackedVector2Array([Vector2.ZERO, Vector2(box.x, 0), box, Vector2(0, box.y)])


## .chipv: a cream pill with a count.
static func make_pill(words: String) -> GlassBox:
	var label: GlassText = GlassText.from_rule("stage", ".chipv", words)
	label.refresh()
	var pad: Array = GlassPieces.rule("stage", ".chipv", "padding")
	var border: Dictionary = GlassPieces.rule("stage", ".chipv", "border")
	var pill: GlassBox = GlassBox.new()
	pill.box_size = Vector2(
		maxf(
			GlassPieces.rule_number("stage", ".chipv", "min-width"),
			label.size.x + 2.0 * _f(pad[1]) + 2.0 * _f(border["width"])
		),
		GlassPieces.rule_number("stage", ".chipv", "height")
	)
	pill.use_css("stage", ".chipv").refresh()
	label.position = (pill.box_size - label.size) / 2.0
	pill.add_child(label)
	return pill


## .port with the given rules on top (.hero, .endturn, .lb .port ...): a round portrait.
static func make_portrait(portrait: String, side: float, rules: Array) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.box_size = Vector2(side, side)
	for rule: String in rules:
		box.use_css("stage", rule)
	box.radii = Vector4.ONE * side / 2.0
	box.image_texture = GlassPieces.portrait(portrait)
	box.layers = [{"kind": "image", "size": "cover", "position": [50.0, 50.0]}]
	box.refresh()
	return box


## .hp, with later rules overriding (.lb .hp): a ruby badge with the Health centred on it.
static func health_badge(value: int, rules: Array) -> GlassBox:
	var label: GlassText = GlassText.new()
	label.words = str(value)
	var min_w: float = 0.0
	var height: float = 0.0
	var pad: float = 0.0
	var box: GlassBox = GlassBox.new()
	for rule: String in rules:
		var spec: Variant = GlassPieces.rule_or("stage", rule, "font", null)
		if spec is Dictionary:
			var font_spec: Dictionary = spec
			label.use_font(font_spec)
		var colour: Variant = GlassPieces.rule_or("stage", rule, "color", null)
		if colour != null:
			label.colour = Color.html(str(colour))
		var stroke: Variant = GlassPieces.rule_or("stage", rule, "-webkit-text-stroke", null)
		if stroke is Dictionary:
			var stroke_spec: Dictionary = stroke
			label.stroke_width = _f(stroke_spec["width"])
			label.stroke_colour = Color.html(str(stroke_spec["colour"]))
		var px: Variant = GlassPieces.rule_or("stage", rule, "font-size", null)
		if px != null:
			label.font_px = _f(px)
		min_w = _f(GlassPieces.rule_or("stage", rule, "min-width", min_w))
		height = _f(GlassPieces.rule_or("stage", rule, "height", height))
		var padding: Variant = GlassPieces.rule_or("stage", rule, "padding", null)
		if padding is Array:
			var padding_list: Array = padding
			pad = _f(padding_list[1])
		box.use_css("stage", rule)
	label.refresh()
	box.box_size = Vector2(maxf(min_w, label.size.x + 2.0 * pad + 2.0 * box.border_width), height)
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".hp", "border-radius"), box.box_size)
	box.refresh()
	label.position = (box.box_size - label.size) / 2.0
	box.add_child(label)
	return box


## #tip .txt: the name, "Tier n · unit" or "Spell · costs n", the rules text, wrapped, and any
## reminder lines (a keyword's or counter's reminder text) under it.
static func tip_text(
	card: Dictionary, is_spell: bool, reminders: PackedStringArray = PackedStringArray()
) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.name = "Words"
	box.use_css("stage", "#tip .txt")
	var width: float = GlassPieces.rule_number("stage", "#tip .txt", "width")
	var pad: Array = GlassPieces.rule("stage", "#tip .txt", "padding")
	var border: float = box.border_width
	var inner_w: float = width - 2.0 * _f(pad[1]) - 2.0 * border
	var colour: Color = GlassPieces.rule_colour("stage", "#tip .txt", "color")
	var y: float = border + _f(pad[0])
	var x: float = border + _f(pad[1])
	var title: GlassText = GlassText.from_rule("stage", "#tip .n", str(card.get("name", "")))
	title.colour = colour
	title.refresh()
	title.position = Vector2(x, y)
	box.add_child(title)
	y += title.size.y
	var margins: Array = GlassPieces.rule("stage", "#tip .m", "margin")
	var kind_words: String = (
		"Spell · costs %d" % _i(card.get("cost", 0))
		if is_spell
		else "Tier %d · unit" % _i(card.get("tier", 1))
	)
	if card.has("price"):
		kind_words += " · costs %d" % _i(card["price"])
	if card.has("sell_value"):
		kind_words += " · sells for %d" % _i(card["sell_value"])
	var kind: GlassText = GlassText.from_rule("stage", "#tip .m", kind_words.to_upper())
	kind.font_px = GlassPieces.rule_number("stage", "#tip .m", "font-size")
	kind.spacing = em_px(GlassPieces.rule("stage", "#tip .m", "letter-spacing"), kind.font_px)
	kind.refresh()
	y += _f(margins[0])
	kind.position = Vector2(x, y)
	box.add_child(kind)
	y += kind.size.y + _f(margins[2])
	var lines: PackedStringArray = wrap_words(str(card.get("text", "")), inner_w)
	for reminder: String in reminders:
		lines.append_array(wrap_words(reminder, inner_w))
	for line: String in lines:
		var words: GlassText = GlassText.from_rule("stage", "#tip .r", line)
		words.colour = colour
		words.font_px = GlassPieces.rule_number("stage", "#tip .r", "font-size")
		words.line_height = GlassPieces.rule_number("stage", "#tip .r", "line-height")
		words.refresh()
		words.position = Vector2(x, y)
		box.add_child(words)
		y += words.size.y
	box.box_size = Vector2(width, y + _f(pad[0]) + border)
	box.radii = GlassBox.css_radii(
		GlassPieces.rule("stage", "#tip .txt", "border-radius"), box.box_size
	)
	box.refresh()
	return box


## Greedy line breaking at spaces, as a browser wraps normal text.
static func wrap_words(words: String, width: float) -> PackedStringArray:
	var measure: GlassText = GlassText.from_rule("stage", "#tip .r", "")
	measure.font_px = GlassPieces.rule_number("stage", "#tip .r", "font-size")
	var lines: PackedStringArray = PackedStringArray()
	var line: String = ""
	for word: String in words.split(" ", false):
		var trial: String = word if line == "" else line + " " + word
		measure.words = trial
		if line != "" and measure.line_size().x > width:
			lines.append(line)
			line = word
		else:
			line = trial
	if line != "":
		lines.append(line)
	measure.free()
	return lines


## STAND-IN frozen look: a pale ice pane with a bright rim over the outline.
static func add_frost(on: Control, outline: PackedVector2Array) -> void:
	var ice: Control = Control.new()
	ice.name = "Frost"
	ice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ice.size = on.size
	var rim: PackedVector2Array = outline.duplicate()
	rim.append(outline[0])
	ice.draw.connect(
		func() -> void:
			ice.draw_colored_polygon(outline, FROST)
			ice.draw_polyline(rim, FROST_EDGE, 3.0, true)
	)
	on.add_child(ice)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)


## STAND-IN lit target (recruit-play.html .lit): an amber rim and a faint wash over the outline.
static func add_lit(on: Control, outline: PackedVector2Array) -> void:
	var lit: Control = Control.new()
	lit.name = "Lit"
	lit.set_meta(&"lit", true)
	lit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lit.size = on.size
	var rim: PackedVector2Array = outline.duplicate()
	rim.append(outline[0])
	lit.draw.connect(
		func() -> void:
			lit.draw_colored_polygon(outline, LIT_WASH)
			lit.draw_polyline(rim, LIT_GLOW, 12.0, true)
			lit.draw_polyline(rim, LIT_EDGE, 4.0, true)
	)
	on.add_child(lit)


## STAND-IN ability button (recruit-play.html .abil): a small leaded pill with the ability's name.
static func ability_button(words: String) -> GlassBox:
	var label: GlassText = GlassText.new()
	label.words = words
	label.use_font(GlassPieces.rule_font("stage", ".btn"))
	label.font_px = ABILITY_PX
	label.colour = GlassPieces.rule_colour("stage", ".btn", "color")
	label.refresh()
	var box: GlassBox = GlassBox.new()
	box.box_size = Vector2(label.size.x + 2.0 * ABILITY_PAD, ABILITY_HEIGHT)
	box.use_css("stage", ".btn")
	box.border_width = 3.0
	box.radii = Vector4.ONE * ABILITY_HEIGHT / 2.0
	box.refresh()
	label.position = ((box.box_size - label.size) / 2.0).round()
	box.add_child(label)
	return box
