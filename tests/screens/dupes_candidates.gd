extends Control
## Both motion options at the game's real 250 px card height, on one 60 fps film.

const TITLES: Array[String] = ["A · slow breath (chosen)", "B · quicker pulse"]
var _time: float = 0.0
var _glows: Array[GlassDuplicateGlow] = []


func _ready() -> void:
	var state: Dictionary = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	var source: RecruitScreen = RecruitScreen.new()
	# This off-tree factory only needs the display table for the existing keyword pills.
	source.state = state
	source._g = RecruitShop.geometry()
	for candidate: int in 2:
		var x: float = 100.0 + candidate * 960.0
		_label(TITLES[candidate], Vector2(x, 55), 34)
		_label("Shop · match", Vector2(x, 145), 24)
		_label("Shop · triple", Vector2(x + 250, 145), 24)
		_label("Board · combines", Vector2(x, 565), 24)
		_label("Hand · combines", Vector2(x + 250, 565), 24)
		for i: int in 4:
			var data: Dictionary = state.shop_units[2 if i == 0 else 3]
			var card: GlassCard = source._unit_card(data, 250.0)
			card.position = Vector2(x + (i % 2) * 250.0, 195.0 + floori(i / 2.0) * 420.0)
			add_child(card)
			var glow: GlassDuplicateGlow = GlassDuplicateGlow.apply(card, 1 if i == 0 else 2)
			glow.candidate = candidate
			_glows.append(glow)
		_label("Match stays steady. All three participants pulse together.", Vector2(x, 970), 23)
	source.free()


func _process(delta: float) -> void:
	_time += delta
	for glow: GlassDuplicateGlow in _glows:
		glow.set_phase(_time)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("15151a"))
	draw_line(Vector2(960, 25), Vector2(960, 1055), Color("776e58"), 2.0)


func _label(words: String, at: Vector2, px: float) -> void:
	var text: GlassText = GlassText.new()
	text.words = words
	text.family = "body"
	text.font_px = px
	text.colour = Color("eee4ce")
	text.position = at
	add_child(text.refresh())
