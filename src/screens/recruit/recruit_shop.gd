class_name RecruitShop
extends RefCounted
## The shop's existing buttons, tags and slot art, laid out in the L1 shop wall.
## The coin's drawing lives in GoldCoin.

const BUTTON_SIZE: Vector2 = Vector2(176, 68)
const BUTTON_COIN: float = 46.0
const SHOP_READOUT_TINT: Color = Color("d9cfbb")
const SELL_COIN: float = 58.0
const SELL_CAPTION_WIDTH: float = 250.0
const SELL_CAPTION_INSET: float = 28.0
const SELL_SIDE_MARGIN: float = 20.0
const SELL_CORNER: float = 22.0


## STAND-IN: today's unit slot art in the arch openings. Spell places have no backing.
static func build_slots(screen: RecruitScreen) -> void:
	var units: Array = screen.state.get("shop_units", [])
	var places: Array[Vector2] = []
	for i: int in units.size():
		places.append(screen.shop_xy(i))
	screen._slots.set_row("ShopSlot_", places, screen.card_box())


## The centred row of arch openings, with each card inset in its opening.
static func unit_xy(i: int) -> Vector2:
	var opening: float = L1Layout.number("shop.arch.w")
	var gap: float = L1Layout.number("shop.arch.gap")
	var count: float = L1Layout.number("shop.arch.count")
	var width: float = count * opening + (count - 1.0) * gap
	return Vector2(
		(
			(L1Layout.stage_size().x - width) / 2.0
			+ i * (opening + gap)
			+ L1Layout.number("shop.unit.inset")
		),
		L1Layout.number("shop.arch.y") + L1Layout.number("shop.unit.down")
	)


static func geometry() -> Dictionary:
	var g: Dictionary = GlassPieces.recruit_geom().duplicate()
	g["W"] = L1Layout.number("card.w")
	g["H"] = L1Layout.number("card.h")
	g["g"] = L1Layout.number("card.gap")
	var shop: Vector2 = unit_xy(0)
	g["shopL"] = shop.x
	g["shopTop"] = shop.y
	g["shopW"] = (
		unit_xy(int(L1Layout.number("shop.arch.count")) - 1).x - shop.x + L1Layout.number("card.w")
	)
	var wall: float = L1Layout.number("room.wall.h")
	g["shopBot"] = wall
	g["T0"] = wall
	g["sill"] = wall + L1Layout.number("room.table.h") + L1Layout.number("room.edge.h")
	return g


static func build_buttons(screen: RecruitScreen) -> void:
	var gold: GlassBox = _button(screen, "gold", "right.gold", BUTTON_SIZE)
	var amount: GlassText = _text(str(screen._counts.gold()), 34, true)
	amount.name = "GoldValue"
	_row(gold, [GoldCoin.make(-1, 40.0), amount])

	# STAND-IN: fit the current rectangular buttons inside the tablet.
	var box: Vector2 = Vector2(L1Layout.number("shop.button.stand_in_w"), BUTTON_SIZE.y)
	var tier: int = GlassPieces.as_int(screen.state.get("tier", 1))
	if screen.state.get("upgrade_cost") != null:
		var upgrade: GlassBox = _button(screen, "tier", "shop.tier", box)
		var value: int = GlassPieces.as_int(screen.state["upgrade_cost"])
		var words: Control = Control.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var title: TextureRect = _icon("shop_up", 18, Color("c9bda6"))
		title.name = "ShopUp"
		var tiers: GlassText = _text("%d → %d" % [tier, tier + 1], 27, true)
		tiers.name = "Tiers"
		title.position.x = (tiers.size.x - title.size.x) / 2.0
		tiers.position.y = 15.0
		words.size = Vector2(maxf(title.size.x, tiers.size.x), 43.0)
		words.add_child(title)
		words.add_child(tiers)
		var price: GoldCoin = GoldCoin.make(value, BUTTON_COIN, value > screen._counts.gold())
		price.name = "Cost"
		_row(upgrade, [words, price])
		var drop: int = GlassPieces.as_int(screen.state.get("tier_up_drop", 0))
		if drop > 0:
			_shop_readout(
				screen,
				"TierUpDrop",
				"−%d next turn" % drop,
				18.0,
				upgrade.get_rect().get_center().x,
				upgrade.get_rect().end.y
			)
	elif tier == GlassPieces.TIERS:
		# STAND-IN: at maximum level, show the level without a cost or an upgrade target.
		var upgrade: GlassBox = _button(screen, "tier", "shop.tier", box)
		_row(upgrade, [_icon("shop_up", 18, Color("c9bda6")), _text(str(tier), 27, true)])
	var cost: int = GlassPieces.as_int(screen.state.get("refresh_cost", 0))
	var refresh: GlassBox = _button(screen, "refresh", "shop.refresh", box)
	_row(
		refresh,
		[_icon("refresh", 30), GoldCoin.make(cost, BUTTON_COIN, cost > screen._counts.gold())]
	)
	if screen.state.has("refreshes_left"):
		var left_count: int = GlassPieces.as_int(screen.state["refreshes_left"])
		_shop_readout(
			screen,
			"RefreshCounter",
			"%d left at this price" % left_count,
			17.0,
			refresh.get_rect().get_center().x,
			refresh.get_rect().end.y
		)
	var freeze: GlassBox = _button(screen, "freeze", "shop.freeze", box)
	_row(freeze, [_icon("freeze", 36)])
	if GlassPieces.as_bool(screen.state.get("frozen", false)):
		GlassParts.add_frost(freeze, GlassParts.round_poly(freeze.box_size))


## STAND-IN: keep the discount and refresh readouts in the gaps below their buttons.
static func _shop_readout(
	screen: RecruitScreen, node_name: String, words: String, px: float, x: float, y: float
) -> void:
	var label: GlassText = _text(words, px, false, SHOP_READOUT_TINT)
	label.name = node_name
	label.z_index = 1
	label.position = Vector2(x - label.size.x / 2.0, y)
	screen._back.add_child(label)


static func _button(screen: RecruitScreen, id: String, place: String, size: Vector2) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.name = "Button_" + id
	box.box_size = size
	box.position = L1Layout.centre(place, size)
	var balance: bool = id == "gold"
	box.use_css("stage", ".btn")
	if balance:
		box.use_css("stage", ".btn.gold")
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".btn", "border-radius"), size)
	box.refresh()
	var action: String = "upgrade" if id == "tier" else id
	var max_tier: bool = id == "tier" and screen.state.get("upgrade_cost") == null
	if not balance and not max_tier and screen.is_barred(action):
		box.name += "_short"
		box.self_modulate = RecruitScreen.SHORT_DIM
	screen._back.add_child(box)
	if max_tier:
		return box
	screen._targets.append(
		{"kind": "button", "index": 0, "id": id, "node": box, "poly": GlassParts.rect_poly(size)}
	)
	return box


static func _row(box: Control, items: Array[Control]) -> void:
	var width: float = (items.size() - 1) * 10.0
	for item: Control in items:
		width += item.size.x
	var x: float = (box.size.x - width) / 2.0
	for item: Control in items:
		item.position = Vector2(x, (box.size.y - item.size.y) / 2.0).round()
		box.add_child(item)
		x += item.size.x + 10.0


static func _text(
	words: String, px: float, display: bool = false, tint: Color = Color("e8dfc6")
) -> GlassText:
	var text: GlassText = GlassText.new()
	text.words = words
	text.family = "display" if display else "body"
	text.weight = 900 if display else 700
	text.font_px = px
	text.colour = tint
	text.stroke_colour = Color("120e0b")
	text.stroke_width = 3.0
	return text.refresh()


static func _icon(id: String, px: int, tint: Color = Color("e8dfc6")) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = GlassPieces.icon(id, tint, px, 2.4)
	icon.size = Vector2.ONE * px
	return icon


static func dress_card(node: Control, data: Dictionary, poor: bool) -> void:
	if node is GlassSpell:
		var disc: Control = node.get_node("Cost")
		node.remove_child(disc)
		disc.free()
		var price_coin: GoldCoin = GoldCoin.make(
			GlassPieces.as_int(data.get("cost", 0)), L1Layout.number("shop.spell.price.w"), poor
		)
		price_coin.name = "Cost"
		var inset: Vector2 = (L1Layout.rect("shop.spell").size - node.size) / 2.0
		price_coin.position = L1Layout.point("shop.spell.price") - inset
		node.add_child(price_coin)
		return
	var tag: Control = price_tag(GlassPieces.as_int(data.get("price", 0)), poor)
	tag.position = Vector2(node.size.x / 2.0, node.size.y)
	node.add_child(tag)


## A shop unit's hanging price tag: a pin and a short cord, the price coin hanging from it. Its
## origin is the pin (it swings about it).
static func price_tag(price: int, poor: bool) -> Control:
	var tag: Control = Control.new()
	tag.name = "ShopTag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.draw.connect(
		func() -> void:
			tag.draw_circle(Vector2(0, 0), 3, Color("16120e"))
			tag.draw_line(Vector2(0, -1), Vector2(0, 14), Color("16120e"), 3, true)
	)
	var diameter: float = L1Layout.number("shop.price.d")
	var coin: GoldCoin = GoldCoin.make(price, diameter, poor)
	coin.name = "Price"
	var drop: float = L1Layout.number("shop.price.y") - unit_xy(0).y - L1Layout.number("card.h")
	coin.position = Vector2(-diameter / 2.0, drop)
	tag.add_child(coin)
	return tag


## Mirrors the existing board-sale drop area; no selling or origin rules live in the UI.
static func show_sell(
	screen: RecruitScreen, value: int, on: bool, carried_x: float = 1030.0
) -> void:
	var old: Control = screen._front.get_node_or_null("SellCue")
	if not on:
		if old != null:
			old.hide()
		return
	if old != null:
		old.show()
		_position_sell_caption(old, carried_x)
		return
	var pane: GlassBox = GlassBox.new()
	pane.name = "SellCue"
	pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.position = Vector2(screen.geom("shopL") - 20.0, screen.geom("shopTop") - 14.0)
	pane.box_size = Vector2(screen.geom("shopW") + 40.0, screen.card_box().y + 30.0)
	pane.layers = [{"kind": "colour", "colour": "#0a08068c"}]
	pane.radii = Vector4.ONE * SELL_CORNER
	pane.z_index = 6
	pane.refresh()
	var border: PackedVector2Array = _sell_border(pane.box_size)
	var outline: Control = Control.new()
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_child(outline)
	outline.draw.connect(
		func() -> void:
			for i: int in border.size():
				outline.draw_dashed_line(
					border[i], border[(i + 1) % border.size()], Color("ffd68cbf"), 3, 8
				)
	)
	var row: Control = Control.new()
	row.name = "SellCaption"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size = Vector2(SELL_CAPTION_WIDTH, SELL_COIN)
	row.position.y = (pane.box_size.y - SELL_COIN) / 2.0 - 70.0
	_row(row, [_text("Sell for", 40, true, Color("ffe08a")), GoldCoin.make(value, SELL_COIN)])
	pane.add_child(row)
	screen._front.add_child(pane)
	_position_sell_caption(pane, carried_x)


## The value must remain visible beside the carried card, including a middle-based drop.
static func _position_sell_caption(pane: Control, carried_x: float) -> void:
	var row: Control = pane.get_node("SellCaption")
	var middle: float = pane.position.x + pane.size.x / 2.0
	var left: bool = pane.get_meta("caption_left", carried_x >= middle) == true
	# Keep the side steady while the carried card floats near the middle.
	if carried_x > middle + SELL_SIDE_MARGIN:
		left = true
	elif carried_x < middle - SELL_SIDE_MARGIN:
		left = false
	pane.set_meta("caption_left", left)
	row.position.x = (
		SELL_CAPTION_INSET if left else pane.size.x - SELL_CAPTION_WIDTH - SELL_CAPTION_INSET
	)


static func _sell_border(box: Vector2) -> PackedVector2Array:
	var corners: PackedVector2Array = PackedVector2Array(
		[
			Vector2(SELL_CORNER, SELL_CORNER),
			Vector2(box.x - SELL_CORNER, SELL_CORNER),
			box - Vector2.ONE * SELL_CORNER,
			Vector2(SELL_CORNER, box.y - SELL_CORNER)
		]
	)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 4:
		for step: int in 7:
			var angle: float = PI + i * PI / 2.0 + step * PI / 12.0
			points.append(corners[i] + Vector2.from_angle(angle) * SELL_CORNER)
	return points
