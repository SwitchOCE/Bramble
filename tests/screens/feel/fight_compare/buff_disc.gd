extends GlassCard
## One card's stat discs drawn swollen, over the card (buff_screen.gd), for CB14: the card's own
## stat setting and number (GlassCard._draw_stat_setting, _draw_number) scaled about the disc's
## centre, the number in the green "up" colour. Only the discs that are swelling or counting are
## drawn; the card itself is never scaled. GlassCard.number_pop scales the digits alone, so the
## setting scaled with them is drawn here, in the fixture, not in src/. Exploratory: nothing here
## is the game.

## stat ("attack", "health") -> {scale, value}; a stat not listed is not drawn.
var discs: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = GlassCard.card_size(card_height)


func _draw() -> void:
	for stat: String in ["attack", "health"]:
		if not discs.has(stat):
			continue
		var shown: Dictionary = discs[stat]
		var disc: Vector3 = GlassPieces.disc(tier, stat)
		var grown: float = GlassPieces.as_float(shown["scale"])
		var centre: Vector2 = Vector2(disc.x, disc.y) * _k()
		draw_set_transform(centre * (1.0 - grown), 0.0, Vector2(grown, grown))
		_draw_stat_setting(disc, stat == "health")
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_number(GlassPieces.as_int(shown["value"]), disc, false, grown, true)


## A disc's centre on the card, in the card's own pixels.
func disc_centre(stat: String) -> Vector2:
	var disc: Vector3 = GlassPieces.disc(tier, stat)
	return Vector2(disc.x, disc.y) * _k()


## A disc's radius at rest, in the card's own pixels.
func disc_radius(stat: String) -> float:
	return GlassPieces.disc(tier, stat).z * _k()
