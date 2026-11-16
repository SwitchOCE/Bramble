extends Control
## Proof scene: the mock-ups' card sheet (cards.html) drawn in Godot from the pulled pieces, at
## the page's own pixel sizes: every tier at 212 and 250 px tall and at 2x 212, one- and
## two-digit numbers. Compare a screenshot of this with cards.html at the same window size.
## The page's sizes, colours and words come from layout.json's sheet.* entries.

const READY_LINE: String = "card_sheet: ready"


func _ready() -> void:
	# The sheet is drawn at the page's pixels, so turn off the project's 1280 x 720 stretch.
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	print(READY_LINE)


func _build() -> void:
	var page: ColorRect = ColorRect.new()
	page.color = GlassPieces.colour("sheet.page")
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	var pad: float = GlassPieces.number("sheet.padding")
	var width: float = get_viewport_rect().size.x - 2.0 * pad
	var y: float = pad
	var h1_font: Font = GlassPieces.display_font(_weight("sheet.h1"))
	y = _label("sheet.h1", h1_font, "display", "sheet.text", y, pad)
	y += GlassPieces.number("sheet.h1.margin_bottom")
	y = _label("sheet.p", GlassPieces.body_font(), "body", "sheet.muted", y, pad)
	var margin: float = GlassPieces.number("sheet.p.margin_bottom")
	var arts: Array = GlassPieces.array("sheet.art")
	var numbers: Array = GlassPieces.array("sheet.numbers")
	var gap: float = GlassPieces.number("sheet.row.gap")
	var row_pad: float = GlassPieces.number("sheet.row.padding")
	for size_entry: Array in GlassPieces.array("sheet.sizes"):
		var height: float = size_entry[0]
		# CSS margins collapse: the gap above a heading is the larger of the two margins.
		y += maxf(margin, GlassPieces.number("sheet.h2.margin_top"))
		y = _heading(str(size_entry[1]), y, pad)
		y += GlassPieces.number("sheet.h2.margin_bottom")
		var row: Panel = Panel.new()
		var box: StyleBoxFlat = StyleBoxFlat.new()
		box.bg_color = GlassPieces.colour("sheet.row.colour")
		box.set_corner_radius_all(int(GlassPieces.number("sheet.row.radius")))
		row.add_theme_stylebox_override("panel", box)
		row.position = Vector2(pad, y)
		row.size = Vector2(width, height + 2.0 * row_pad)
		add_child(row)
		var x: float = pad + row_pad
		for tier: int in range(1, GlassPieces.TIERS + 1):
			var pair: Array = numbers[tier - 1]
			var attack: float = pair[0]
			var health: float = pair[1]
			var card: GlassCard = GlassCard.new()
			card.name = "Card%d_%d" % [int(height), tier]
			card.tier = tier
			card.art = GlassPieces.art(str(arts[tier - 1]))
			card.attack = int(attack)
			card.health = int(health)
			card.card_height = height
			card.position = Vector2(x, y + row_pad)
			add_child(card)
			x += GlassCard.card_size(height).x + gap
		y += row.size.y
		margin = 0.0


func _heading(words: String, y: float, x: float) -> float:
	var font: Font = GlassPieces.display_font(_weight("sheet.h2"))
	var font_size: int = roundi(GlassPieces.number("sheet.h2.size"))
	return _place(words, font, "display", font_size, "sheet.text", Vector2(x, y))


func _label(
	key: String, font: Font, family: String, colour_key: String, y: float, x: float
) -> float:
	var font_size: int = roundi(GlassPieces.number(key + ".size"))
	var words: String = GlassPieces.text(key + ".label")
	return _place(words, font, family, font_size, colour_key, Vector2(x, y))


## One line of text where the page puts it: a CSS line box (line-height: normal) at top_left.
## Returns the y below the line.
func _place(
	words: String, font: Font, family: String, font_size: int, colour_key: String, top_left: Vector2
) -> float:
	var settings: LabelSettings = LabelSettings.new()
	settings.font = font
	settings.font_size = font_size
	settings.font_color = GlassPieces.colour(colour_key)
	var label: Label = Label.new()
	label.text = words
	label.label_settings = settings
	# A Label puts its baseline one Godot ascent below its top; move it to the CSS baseline.
	var line: Vector3 = GlassPieces.css_line(family, font_size)
	var baseline: float = floorf(line.z / 2.0) + line.x
	label.position = top_left + Vector2(0.0, baseline - font.get_ascent(font_size))
	add_child(label)
	return top_left.y + line.x + line.y + line.z


func _weight(key: String) -> int:
	return int(GlassPieces.number(key + ".weight"))
