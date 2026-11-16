class_name GlassSpell
extends Control
## STAND-IN: a shop spell as the mock-ups draw one with no spell frame yet (card.js make() with
## spell "hex", card.css .card.hexsp): the spell picture in a hexagon the units' width, a plain lead
## outline round it, and a cost disc on its left shoulder. Set the fields, then call build().

var art: Texture2D
var cost: int = 0
## The hexagon's size, and its shoulders as a share of its height (geom()'s SW, SH and SS).
var spell_size: Vector2 = Vector2(140, 167)
var shoulder: float = 0.25


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func build() -> void:
	size = spell_size
	var whole: Rect2 = Rect2(Vector2.ZERO, spell_size)
	var lead: GlassBox = GlassBox.new()
	lead.name = "Lead"
	lead.box_size = spell_size
	lead.polygon_outer = GlassBox.hexagon(whole, shoulder)
	lead.use_css("card", ".card .spell-lead")
	lead.shadows = [GlassSpell.card_shadow()]
	lead.refresh()
	add_child(lead)
	# .card.hexsp .art: inset from the card's edges, the picture covering it, centred at 45% down
	var inset: Array = GlassPieces.rule("card", ".card.hexsp .art", "inset")
	var inset_y: float = str(inset[0]).to_float() / 100.0 * spell_size.y
	var inset_x: float = str(inset[1]).to_float() / 100.0 * spell_size.x
	var art_rect: Rect2 = whole.grow_individual(-inset_x, -inset_y, -inset_x, -inset_y)
	var picture: GlassBox = GlassBox.new()
	picture.name = "Art"
	picture.box_size = spell_size
	picture.polygon_outer = GlassBox.hexagon(art_rect, shoulder)
	picture.padding_override = art_rect
	picture.image_texture = art
	var position_y: String = str(
		GlassPieces.rule("card", ".card.hexsp .art", "background-position")
	)
	picture.layers = [
		{
			"kind": "image",
			"size": GlassPieces.rule("card", ".card.hexsp .art", "background-size"),
			"position": [50.0, position_y.split(" ")[1].to_float()],
		}
	]
	picture.refresh()
	add_child(picture)
	add_child(_cost_disc())


## card.css .card .cost, moved by .card.hexsp .cost: a round disc, its size and place shares of
## the card, raised by half its height (translateY(-50%)), with the cost centred on it.
func _cost_disc() -> GlassBox:
	var left: float = _share(".card.hexsp .cost", "left") * spell_size.x
	var top: float = _share(".card.hexsp .cost", "top") * spell_size.y
	var width: float = _share(".card.hexsp .cost", "width") * spell_size.x
	var disc: GlassBox = GlassBox.new()
	disc.name = "Cost"
	disc.box_size = Vector2(width, width)
	disc.position = Vector2(left, top - width / 2.0)
	disc.use_css("card", ".card .cost")
	disc.radii = Vector4.ONE * width / 2.0
	disc.refresh()
	var words: GlassText = GlassText.new()
	words.words = str(cost)
	words.family = "display"
	words.weight = _i(GlassPieces.rule("card", ".card .cost", "font-weight"))
	words.colour = Color.html(str(GlassPieces.rule("card", ".card .cost", "color")))
	words.font_px = spell_size.y * GlassPieces.number("stage.spell.cost_per_h")
	words.refresh()
	words.position = (disc.box_size - words.size) / 2.0
	disc.add_child(words)
	return disc


func _share(selector: String, property: String) -> float:
	return str(GlassPieces.rule("card", selector, property)).to_float() / 100.0


## card.css .card's drop-shadow as a box-shadow entry for GlassBox.
static func card_shadow() -> Dictionary:
	return {
		"inset": false,
		"x": GlassPieces.number("card.shadow.x"),
		"y": GlassPieces.number("card.shadow.y"),
		"blur": GlassPieces.number("card.shadow.blur"),
		"spread": 0.0,
		"colour": "#" + GlassPieces.css_colour(GlassPieces.text("card.shadow.colour")).to_html(),
	}


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)
