class_name RecruitShop
extends RefCounted
## Shop offers, their roundels and the existing sell cue.

const GOLD_SIZE: Vector2 = Vector2(176, 68)
const BUTTON_INK: Color = Color("fbf3dc")
const SELL_COIN: float = 58.0
const SELL_CAPTION_WIDTH: float = 250.0
const SELL_CAPTION_INSET: float = 28.0
const SELL_SIDE_MARGIN: float = 20.0
const SELL_CORNER: float = 22.0


static func build_slots(screen: RecruitScreen) -> void:
	var units: Array = screen.state.get("shop_units", [])
	var count: int = maxi(units.size(), int(L1Layout.number("shop.arch.count")))
	var places: Array[Vector2] = []
	for i: int in count:
		places.append(screen.shop_xy(i))
	screen._slots.set_row("ShopSlot_", places, screen.card_box(), [], L1ShopArch.make)
	for i: int in count:
		var slot: L1ShopArch = screen._slots.get_node("ShopSlot_%d" % i)
		var unit: Dictionary = units[i] if i < units.size() and units[i] is Dictionary else {}
		slot.tier = 0 if unit.is_empty() else GlassPieces.as_int(unit.get("tier", 1))
	var wall: L1ShopWall = L1ShopWall.new()
	wall.tier = GlassPieces.as_int(screen.state.get("tier", 1))
	wall.spells = screen.state.get("shop_spells", [])
	screen._back.add_child(wall)


## The centred row of arch openings, with each card inset in its opening.
static func unit_xy(i: int) -> Vector2:
	return Vector2(
		L1Layout.shop_opening_x(i) + L1Layout.number("shop.unit.inset"),
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
	_build_gold(screen)
	var tier: int = GlassPieces.as_int(screen.state.get("tier", 1))
	var upgrade_cost: Variant = screen.state.get("upgrade_cost")
	if upgrade_cost != null or tier == GlassPieces.TIERS:
		var upgrade: Control = _roundel(screen, "tier", upgrade_cost)
		var stall: TextureRect = _icon(
			"shop_up", int(L1Layout.number("shop.tier.icon")), BUTTON_INK
		)
		stall.name = "ShopUp"
		stall.position = (upgrade.size - stall.size) / 2.0
		stall.position.y -= L1Layout.number("shop.tier.icon_rise")
		upgrade.add_child(stall)
		var level: GlassText = GlassText.new()
		level.name = "Tiers"
		level.words = str(tier)
		level.font_px = L1Layout.number("shop.tier.level_px")
		level.weight = 700
		level.colour = BUTTON_INK
		level.refresh()
		level.position = (
			Vector2(upgrade.size.x / 2.0, L1Layout.number("shop.tier.level_y")) - level.size / 2.0
		)
		upgrade.add_child(level)

	var refresh: Control = _roundel(screen, "refresh", screen.state.get("refresh_cost", 0))
	_add_centred_icon(refresh, "refresh", BUTTON_INK)
	if screen.state.has("refreshes_left"):
		var beads: L1RefreshBeads = L1RefreshBeads.new()
		beads.name = "RefreshBeads"
		beads.position = refresh.position + refresh.size / 2.0
		beads.show_step(refresh_step(screen.state))
		screen._back.add_child(beads)

	var freeze: Control = _roundel(screen, "freeze")
	_add_centred_icon(freeze, "freeze", Color("f4fbff"))
	# STAND-IN: keep the existing frost over a frozen shop's freeze button.
	if GlassPieces.as_bool(screen.state.get("frozen", false)):
		GlassParts.add_frost(freeze, GlassParts.round_poly(freeze.size))


static func refresh_step(state: Dictionary) -> Vector2i:
	var left: int = GlassPieces.as_int(state.get("refreshes_left", 0))
	# Older fixtures only carry the remaining count and price. Live state supplies the step
	# length, which stays the same when a discount (including a free refresh) changes the price.
	var total: int
	if state.has("refresh_step_size"):
		total = GlassPieces.as_int(state["refresh_step_size"])
	else:
		var defaults: GameConfig = GameConfig.new()
		var cost: int = GlassPieces.as_int(state.get("refresh_cost", 0))
		total = (
			defaults.refresh_step_length
			if cost > defaults.refresh_base_cost and left <= defaults.refresh_step_length
			else defaults.refresh_first_step_after
		)
	return Vector2i(total, left)


static func _build_gold(screen: RecruitScreen) -> void:
	var box: GlassBox = GlassBox.new()
	box.name = "Button_gold"
	box.box_size = GOLD_SIZE
	box.position = L1Layout.centre("right.gold", GOLD_SIZE)
	box.use_css("stage", ".btn").use_css("stage", ".btn.gold")
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".btn", "border-radius"), GOLD_SIZE)
	box.refresh()
	screen._back.add_child(box)
	_add_target(screen, "gold", box, GOLD_SIZE)
	var amount: GlassText = _text(str(screen._counts.gold()), 34, true)
	amount.name = "GoldValue"
	_row(box, [GoldCoin.make(-1, 40.0), amount])


static func _roundel(screen: RecruitScreen, id: String, cost: Variant = null) -> Control:
	var rect: Rect2 = L1Layout.rect("shop." + id)
	var button: Control = Control.new()
	button.name = "Button_" + id
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.position = rect.position
	button.size = rect.size
	var action: String = "upgrade" if id == "tier" else id
	var max_tier: bool = id == "tier" and cost == null
	var price: int = GlassPieces.as_int(cost) if cost != null else 0
	var poor: bool = cost != null and price > screen._counts.gold()
	# STAND-IN: retain the unavailable look for restrictions besides the price.
	if not max_tier and screen.is_barred(action):
		button.name += "_short"
		if not poor:
			button.self_modulate = RecruitScreen.SHORT_DIM
	button.draw.connect(
		func() -> void:
			var shadow: Vector2 = Vector2(0, L1Layout.number("shop.button.shadow_y"))
			button.draw_circle(
				button.size / 2.0 + shadow,
				button.size.x / 2.0,
				Color(0, 0, 0, 0.65),
				true,
				-1.0,
				true
			)
			button.draw_texture_rect(
				GlassPieces.texture("l1/l1p-roundel-slate.png"),
				Rect2(Vector2.ZERO, button.size),
				false
			)
	)
	screen._back.add_child(button)
	var hit_size: Vector2 = button.size
	if cost != null:
		var coin: GoldCoin = GoldCoin.painted_cost(
			price, L1Layout.number("shop.button.price.d"), poor
		)
		coin.name = "Cost"
		coin.position = L1Layout.point("shop.button.price")
		button.add_child(coin)
		hit_size = hit_size.max(coin.position + coin.size)
	if not max_tier:
		_add_target(screen, id, button, hit_size)
	return button


static func _add_target(screen: RecruitScreen, id: String, node: Control, box: Vector2) -> void:
	screen._targets.append(
		{"kind": "button", "index": 0, "id": id, "node": node, "poly": GlassParts.rect_poly(box)}
	)


static func _add_centred_icon(button: Control, id: String, tint: Color) -> void:
	var icon: TextureRect = _icon(id, int(L1Layout.number("shop.button.icon")), tint)
	icon.position = (button.size - icon.size) / 2.0
	button.add_child(icon)


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
		var price: GoldCoin = GoldCoin.painted_cost(
			GlassPieces.as_int(data.get("cost", 0)), L1Layout.number("shop.spell.price.w"), poor
		)
		price.name = "Cost"
		price.position = L1Layout.point("shop.spell.price")
		node.add_child(price)
		return
	var diameter: float = L1Layout.number("shop.price.d")
	var coin: GoldCoin = GoldCoin.painted_cost(
		GlassPieces.as_int(data.get("price", 0)), diameter, poor
	)
	# STAND-IN: the carried offer keeps today's price visibility and carries its coin.
	coin.name = "ShopTag"
	coin.position = Vector2(
		(node.size.x - diameter) / 2.0, L1Layout.number("shop.price.y") - unit_xy(0).y
	)
	node.add_child(coin)


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
