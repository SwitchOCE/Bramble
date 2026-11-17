extends Control
## Same triple rim and face, side by side: existing glow alone versus the new triple-only foil.

var _elapsed: float = 0.0
var _glows: Array[GlassDuplicateGlow] = []


func _ready() -> void:
	var source: RecruitScreen = RecruitScreen.new()
	source.state = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	source._g = RecruitShop.geometry()
	var triple_data: Dictionary = source.state.shop_units[3]
	var pair_data: Dictionary = source.state.shop_units[0]
	for side: int in 2:
		var left: float = side * 960.0 + 75.0
		_label("Glow only" if side == 0 else "Glow + moving foil", Vector2(left, 90), 38)
		_label("Triple copies: shop / board / hand", Vector2(left, 150), 26)
		for i: int in 3:
			var card: GlassCard = source._unit_card(triple_data, 330.0)
			card.position = Vector2(left + 275.0 * i, 235)
			add_child(card)
			var glow: GlassDuplicateGlow = GlassDuplicateGlow.apply(
				card, RecruitDuplicates.Mark.TRIPLE
			)
			if side == 0:
				glow._foil.hide()
			_glows.append(glow)
		var pair: GlassCard = source._unit_card(pair_data, 250.0)
		pair.position = Vector2(left, 685)
		add_child(pair)
		GlassDuplicateGlow.apply(pair, RecruitDuplicates.Mark.MATCH)
		_label("Pair matches keep the steady glow only", Vector2(left + 180, 760), 25)
	source.free()


func _process(delta: float) -> void:
	_elapsed += delta
	for glow: GlassDuplicateGlow in _glows:
		glow.set_phase(_elapsed)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("15151a"))
	draw_line(Vector2(960, 35), Vector2(960, 1045), Color("776e58"), 2.0)


func _label(words: String, at: Vector2, px: float) -> void:
	var text: GlassText = GlassText.new()
	text.words = words
	text.font_px = px
	text.colour = Color("eee4ce")
	text.position = at
	add_child(text.refresh())


func feel_report() -> Dictionary:
	return {"foil_period": GlassTripleFoil.PERIOD, "glow_only_copies": 3, "foil_copies": 3}
