extends Control
## Native-size inspection sheet, using the game's actual shared card and mark drawing.


func _ready() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("181510")
	backdrop.size = Vector2(1920, 1080)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var builder: GlassScreen = GlassScreen.new()
	builder.state = {"display": GameContent.load_default().display_table()}
	for row: int in 2:
		var height: float = 186.0 if row == 0 else 250.0
		var y: float = 85.0 if row == 0 else 395.0
		for tier: int in range(1, 7):
			var card: GlassCard = (
				builder
				. _unit_card(
					{
						"tier": tier,
						"attack": 2,
						"health": 8,
						"art": "../../units/badger/hedge-knight",
						"text": "Guard. Fury 1. Thorns 4.",
						"keywords": ["taunt"],
						"mechanics": ["badger_fury", "thorn_thorns"],
					},
					height
				)
			)
			card.position = Vector2(260.0 + (tier - 1) * 245.0, y)
			add_child(card)
			var label: GlassText = GlassText.from_rule(
				"stage", ".lbl", "%d px · Tier %d" % [roundi(height), tier]
			)
			label.font_px = 24.0
			label.refresh()
			label.position = Vector2(card.position.x, y - 40.0)
			add_child(label)
	builder.free()
	for item: Array in [["Fury 1", 800.0], ["Thorns 4", 900.0]]:
		var mark: KeywordMark = KeywordMark.make(
			{"words": str(item[0])}, true, KeywordStyle.CARD_MIN_SIDE
		)
		mark.position = Vector2(GlassPieces.as_float(item[1]), 850.0)
		add_child(mark)
	print("keyword_sizes: ready")
