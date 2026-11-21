class_name KeywordMark
extends Control
## The same coloured glass mark in a card's border and inline in its tooltip. A cost mark
## (`coin` in the term, an Active's "1:") is the gold coin holding the number, with no words.
var term: Dictionary = {}
var compact: bool = false
var coin: bool = false
var diameter: float = 24.0
var words: String = ""
var number: String = ""
var _icon: Texture2D
var _word_px: int


static func make(
	mark: Dictionary,
	small: bool = false,
	side: float = KeywordStyle.TOOLTIP_MARK_H,
	word_px: int = int(KeywordStyle.MARK_PX)
) -> KeywordMark:
	var node: KeywordMark = KeywordMark.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.term = mark
	node.compact = small
	node.diameter = side
	node.words = str(mark.get("words", mark.get("name", "")))
	node._word_px = word_px
	if GlassPieces.as_bool(mark.get("coin", false)):
		node.coin = true
		node.number = node.words
		node.size = Vector2.ONE * side
		node.add_child(GoldCoin.make(node.words.to_int(), side, false, true))
		return node
	var found: RegExMatch = RegEx.create_from_string("\\(?([+]?\\d+)\\)?$").search(node.words)
	if found != null:
		node.number = found.get_string(1)
	node._icon = KeywordStyle.icon(str(mark.get("name", node.words)))
	var width: float = side
	if not small:
		width += (
			(
				GlassPieces
				. display_font(800)
				. get_string_size(node.words, HORIZONTAL_ALIGNMENT_LEFT, -1, word_px)
				. x
			)
			+ KeywordStyle.WORD_PAD
		)
	node.size = Vector2(width, side)
	if GlassPieces.as_bool(mark.get("spent", false)):
		node.modulate.a = KeywordStyle.SPENT_ALPHA
	return node


## Extra aim room without changing the border drawing or its placement.
func hit_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size).grow(4.0 if compact else 0.0)


func _draw() -> void:
	if coin:
		return
	var colour: Color = Color(str(KeywordStyle.family(str(term.get("name", words)))["colour"]))
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = colour
	box.border_color = KeywordStyle.INK
	box.set_border_width_all(KeywordStyle.MARK_BORDER)
	box.set_corner_radius_all(roundi(diameter / 2.0))
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	if compact and GlassPieces.as_bool(term.get("more", false)):
		var overflow_font: Font = GlassPieces.display_font(KeywordStyle.NUMBER_WEIGHT, true)
		var overflow_px: int = KeywordStyle.NUMBER_MIN_PX
		var overflow_width: float = (
			overflow_font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, overflow_px).x
		)
		var overflow_at: Vector2 = Vector2(
			(diameter - overflow_width) / 2.0,
			(
				(diameter - overflow_font.get_height(overflow_px)) / 2.0
				+ overflow_font.get_ascent(overflow_px)
			)
		)
		overflow_font.draw_string_outline(
			get_canvas_item(),
			overflow_at,
			words,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			overflow_px,
			KeywordStyle.WORD_OUTLINE,
			KeywordStyle.INK
		)
		overflow_font.draw_string(
			get_canvas_item(),
			overflow_at,
			words,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			overflow_px,
			KeywordStyle.WORD
		)
		return
	var middle: Vector2 = Vector2.ONE * diameter / 2.0
	draw_circle(middle, diameter * KeywordStyle.ICON_DISC, KeywordStyle.INK)
	var icon_side: float = diameter * KeywordStyle.ICON_SIDE
	draw_texture_rect(
		_icon, Rect2(middle - Vector2.ONE * icon_side / 2.0, Vector2.ONE * icon_side), false
	)
	var font: Font = (
		GlassPieces.display_font(KeywordStyle.NUMBER_WEIGHT, true)
		if compact
		else GlassPieces.display_font(800, true)
	)
	if compact:
		if number != "":
			# A light outlined number at the mark's lower right, as on the approved border.
			var px: int = maxi(
				KeywordStyle.NUMBER_MIN_PX, roundi(diameter * KeywordStyle.NUMBER_PER_SIDE)
			)
			var at: Vector2 = Vector2(diameter * KeywordStyle.NUMBER_X, diameter)
			font.draw_string_outline(
				get_canvas_item(),
				at,
				number,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				px,
				5,
				KeywordStyle.INK
			)
			font.draw_string(
				get_canvas_item(),
				at,
				number,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				px,
				KeywordStyle.NUMBER
			)
	else:
		var px: int = _word_px
		var at: Vector2 = Vector2(
			diameter + KeywordStyle.WORD_GAP,
			(diameter - font.get_height(px)) / 2.0 + font.get_ascent(px)
		)
		font.draw_string_outline(
			get_canvas_item(),
			at,
			words,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			px,
			KeywordStyle.WORD_OUTLINE,
			KeywordStyle.INK
		)
		font.draw_string(
			get_canvas_item(), at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, px, KeywordStyle.WORD
		)
