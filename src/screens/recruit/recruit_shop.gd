class_name RecruitShop
extends RefCounted
## Briefs 1 and 3: Tags layout from docs/design/mockups/kit/screen.js.
## Taste constants live here; the coin's own drawing lives in GoldCoin.

const PRICE_ROOM: float = 54.0
const BUTTON_SIZE: Vector2 = Vector2(176, 68)
const BUTTON_GAP: float = 20.0
const BUTTON_UP: float = 78.0
const BUTTON_STEP: float = 84.0
const BUTTON_COIN: float = 46.0
const TAG_COIN: float = 44.0
const TAG_DROP: float = 10.0
const COUNTER_SIZE: float = 19.0
const SELL_COIN: float = 58.0
const SELL_CAPTION_WIDTH: float = 250.0
const SELL_CAPTION_INSET: float = 28.0
const SELL_SIDE_MARGIN: float = 20.0
const SELL_CORNER: float = 22.0


## The view arrays retain bought positions as null until refill. Every position gets a backing,
## including spells, regardless of its contents; the rules already supply the shop's size.
static func build_slots(screen: RecruitScreen) -> void:
	var units: Array = screen.state.get("shop_units", [])
	var spells: Array = screen.state.get("shop_spells", [])
	var places: Array[Vector2] = []
	for i: int in units.size():
		places.append(screen.shop_xy(i))
	screen._slots.set_row("ShopSlot_", places, screen.card_box())
	places = []
	for i: int in spells.size():
		places.append(screen.spell_xy(i))
	screen._slots.set_row("SpellSlot_", places, screen._spell_size())


static func geometry() -> Dictionary:
	var g: Dictionary = GlassPieces.recruit_geom().duplicate()
	# geom(54): the 40% minimum hand reveal is reached with hanging tags.
	var hand_top: float = minf(
		1080.0 - GlassPieces.as_float(g["H"]) * 0.4, GlassPieces.as_float(g["handTop"]) + PRICE_ROOM
	)
	var down: float = hand_top - GlassPieces.as_float(g["handTop"])
	for key: String in ["handTop", "sill", "boardTop", "boardBot", "T0", "T1"]:
		g[key] = GlassPieces.as_float(g[key]) + down
	for key: String in ["shopTop", "shopBot"]:
		g[key] = GlassPieces.as_float(g[key]) + down - PRICE_ROOM
	g["ys"] = maxf(GlassPieces.as_float(g["shopTop"]) + 30.0, 90.0)
	return g


static func build_buttons(screen: RecruitScreen) -> void:
	var left: float = screen.geom("shopL") - BUTTON_GAP - BUTTON_SIZE.x
	var right: float = screen.geom("shopL") + screen.geom("shopW") + BUTTON_GAP
	var top: float = screen.geom("shopTop") + screen.card_box().y / 2.0 - BUTTON_UP
	var gold: GlassBox = _button(screen, "gold", Vector2(left, top), true)
	var amount: GlassText = _text(str(screen._counts.gold()), 34, true)
	amount.name = "GoldValue"
	_row(gold, [GoldCoin.make(-1, 40.0), amount])
	if screen.state.get("upgrade_cost") != null:
		var tier: int = GlassPieces.as_int(screen.state.get("tier", 1))
		var value: int = GlassPieces.as_int(screen.state["upgrade_cost"])
		var upgrade: GlassBox = _button(screen, "tier", Vector2(left, top + BUTTON_STEP))
		var words: Control = Control.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var title: TextureRect = _icon("shop_up", 18, Color("c9bda6"))
		title.name = "ShopUp"
		var tiers: GlassText = _text("%d → %d" % [tier, tier + 1], 27, true)
		title.position.x = (tiers.size.x - title.size.x) / 2.0
		tiers.position.y = 15.0
		words.size = Vector2(maxf(title.size.x, tiers.size.x), 43.0)
		words.add_child(title)
		words.add_child(tiers)
		_row(upgrade, [words, GoldCoin.make(value, BUTTON_COIN, value > screen._counts.gold())])
	var cost: int = GlassPieces.as_int(screen.state.get("refresh_cost", 0))
	var refresh: GlassBox = _button(screen, "refresh", Vector2(right, top))
	_row(
		refresh,
		[_icon("refresh", 30), GoldCoin.make(cost, BUTTON_COIN, cost > screen._counts.gold())]
	)
	if screen.state.has("refreshes_left"):
		var left_count: int = GlassPieces.as_int(screen.state["refreshes_left"])
		var counter: GlassText = _text("%d left at this price" % left_count, COUNTER_SIZE)
		counter.name = "RefreshCounter"
		counter.position = Vector2(right + (BUTTON_SIZE.x - counter.size.x) / 2.0, top - 30.0)
		screen._back.add_child(counter)
	var freeze: GlassBox = _button(screen, "freeze", Vector2(right, top + BUTTON_STEP))
	_row(freeze, [_icon("freeze", 36)])
	if GlassPieces.as_bool(screen.state.get("frozen", false)):
		GlassParts.add_frost(freeze, GlassParts.round_poly(freeze.box_size))


static func _button(
	screen: RecruitScreen, id: String, at: Vector2, balance: bool = false
) -> GlassBox:
	var box: GlassBox = GlassBox.new()
	box.name = "Button_" + id
	box.box_size = BUTTON_SIZE
	box.position = at
	box.use_css("stage", ".btn")
	if balance:
		box.use_css("stage", ".btn.gold")
	box.radii = GlassBox.css_radii(GlassPieces.rule("stage", ".btn", "border-radius"), BUTTON_SIZE)
	box.refresh()
	var action: String = "upgrade" if id == "tier" else id
	if not balance and screen.is_barred(action):
		box.name += "_short"
		box.self_modulate = RecruitScreen.SHORT_DIM
	screen._back.add_child(box)
	screen._targets.append(
		{
			"kind": "button",
			"index": 0,
			"id": id,
			"node": box,
			"poly": GlassParts.rect_poly(BUTTON_SIZE)
		}
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
			GlassPieces.as_int(data.get("cost", 0)), TAG_COIN, poor
		)
		price_coin.name = "Cost"
		price_coin.position = Vector2(-16.0, node.size.y * 0.16)
		node.add_child(price_coin)
		return
	var price: int = GlassPieces.as_int(data.get("price", 0))
	var tag: Control = Control.new()
	tag.name = "ShopTag"
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.position = Vector2(node.size.x / 2.0, node.size.y)
	tag.draw.connect(
		func() -> void:
			tag.draw_circle(Vector2(0, 0), 3, Color("16120e"))
			tag.draw_line(Vector2(0, -1), Vector2(0, 14), Color("16120e"), 3, true)
	)
	var coin: GoldCoin = GoldCoin.make(price, TAG_COIN, poor)
	coin.position = Vector2(-TAG_COIN / 2.0, TAG_DROP)
	tag.add_child(coin)
	node.add_child(tag)


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
