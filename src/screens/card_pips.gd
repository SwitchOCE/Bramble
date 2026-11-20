class_name CardPips
extends Control
## STAND-IN (pitch-pigeon 3): a card's Charge and Supply as pips just over its stat discs: round
## pips for Charge, which dim as its uses are spent in a fight and light again for the next, and
## small square crates for Supply, which empty and stay empty. A spent pip is dimmed as a spent
## keyword mark is (KeywordStyle.SPENT_ALPHA), in the count family's glass with the marks' lead.
## Each kind is a row, centred; a long Supply wraps upwards. Pips are named Pip_<kind>_<n>, with
## "_spent" added when spent. Built from CardTerms.pips.

## The side of a pip against the card's height, and the smallest it gets.
const SIDE_PER_H: float = 0.05
const MIN_SIDE: float = 8.0
const GAP: float = 3.0
## Pips in one row before it wraps, and the space between the rows and over the discs.
const PER_ROW: int = 9
const ROW_GAP: float = 4.0
const ABOVE_DISCS: float = 3.0
## A Supply crate's corner, against its side.
const CRATE_ROUND: float = 0.2


## The pips for a card of `height` and `tier`, sized to the whole card. Null for no pips.
static func make(pips: Array[Dictionary], height: float, tier: int) -> CardPips:
	if pips.is_empty():
		return null
	var node: CardPips = CardPips.new()
	node.name = "Pips"
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.size = GlassCard.card_size(height)
	var side: float = maxf(MIN_SIDE, roundf(height * SIDE_PER_H))
	var k: float = height / GlassPieces.card_units().y
	var disc: Vector3 = GlassPieces.disc(tier, "attack")
	var bottom: float = (disc.y - disc.z * 1.12) * k - ABOVE_DISCS
	for group: Dictionary in pips:
		var kind: String = str(group["kind"])
		var total: int = GlassPieces.as_int(group["total"])
		var left: int = GlassPieces.as_int(group["left"])
		var rows: int = ceili(total / float(PER_ROW))
		for n: int in total:
			var row: int = floori(n / float(PER_ROW))
			var in_row: int = mini(PER_ROW, total - row * PER_ROW)
			var width: float = in_row * side + (in_row - 1) * GAP
			var pip: Control = _pip(kind, side, n >= left)
			pip.name = "Pip_%s_%d%s" % [kind, n, "_spent" if n >= left else ""]
			pip.position = Vector2(
				(node.size.x - width) / 2.0 + (n % PER_ROW) * (side + GAP),
				bottom - side - (rows - 1 - row) * (side + ROW_GAP)
			)
			node.add_child(pip)
		bottom -= rows * (side + ROW_GAP)
	return node


## One pip: a round Charge pip or a square Supply crate, lit or spent.
static func _pip(kind: String, side: float, spent: bool) -> Control:
	var pip: Control = Control.new()
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip.size = Vector2.ONE * side
	var family: Dictionary = KeywordStyle.family("Charge" if kind == "charge" else "Supply")
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(str(family["light"]))
	box.border_color = KeywordStyle.INK
	box.set_border_width_all(KeywordStyle.MARK_BORDER)
	var radius: float = side / 2.0 if kind == "charge" else side * CRATE_ROUND
	box.set_corner_radius_all(roundi(radius))
	pip.draw.connect(func() -> void: pip.draw_style_box(box, Rect2(Vector2.ZERO, pip.size)))
	if spent:
		pip.modulate.a = KeywordStyle.SPENT_ALPHA
	return pip
