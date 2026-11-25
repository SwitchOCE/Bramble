extends Control
## Three coin candidates side by side, plus the L1 combat settings.


func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("191b20")
	bg.size = Vector2(1920, 1080)
	add_child(bg)
	_label("Gold coin candidates · shown at game size and enlarged", Vector2(80, 38), 38)
	var names: Array[String] = [
		"A · Milled / Sans bold / centred",
		"B · Faceted / Alegreya / centred",
		"C · Sunburst / Alegreya / lowered"
	]
	for candidate: int in 3:
		var x: float = 100 + candidate * 610
		_label(names[candidate], Vector2(x, 112), 28)
		var values: Array[int] = [1, 7, 26, 120]
		for i: int in 4:
			var coin: GoldCoin = GoldCoin.make(values[i], 46)
			coin.candidate = candidate
			coin.position = Vector2(x + i * 105, 176)
			add_child(coin)
		var big: GoldCoin = GoldCoin.make(7, 180)
		big.candidate = candidate
		big.position = Vector2(x, 270)
		add_child(big)
		var dull: GoldCoin = GoldCoin.make(7, 46, true)
		dull.candidate = candidate
		dull.position = Vector2(x + 240, 295)
		add_child(dull)
		_label("Can't afford", Vector2(x + 210, 360), 23)
	_label("Attack and Health", Vector2(80, 510), 36)
	for i: int in 2:
		var x: float = 340 + i * 800
		_label("Lead" if i == 0 else "Gilt", Vector2(x - 30, 575), 30)
		var card: GlassCard = GlassCard.new()
		card.card_height = 350
		card.art = GlassPieces.art("badger-1")
		card.attack = 7
		card.health = 7
		card.golden = i == 1
		card.position = Vector2(x, 630)
		add_child(card)
		var coin: GoldCoin = GoldCoin.make(7, 62)
		coin.position = Vector2(x + 250, 862)
		add_child(coin)


func _label(words: String, at: Vector2, px: float) -> void:
	var text: GlassText = GlassText.new()
	text.words = words
	text.font_px = px
	text.colour = Color("eee4ca")
	text.position = at
	add_child(text.refresh())
