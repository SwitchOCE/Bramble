class_name FightGainDisc
extends GlassCard
## One card's stat discs drawn swollen, over the card, while a stat gain lands (CB14 c, FightGains):
## the card's own stat setting and number scaled about the disc's centre, the number in the green
## "up" colour. Only the discs that are swelling or counting are drawn; the card itself is never
## scaled. Ported from the fight fixture's buff_disc.gd.

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
		var disc: Vector3 = GlassCard.stat_disc(stat)
		var grown: float = GlassPieces.as_float(shown["scale"])
		_draw_stat(GlassPieces.as_int(shown["value"]), disc, false, grown, true)
