class_name L1ShopWall
extends Control
## The wall fittings behind the offers. Tier colour is a flat stand-in for the later light.

var tier: int
var spells: Array


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	_draw_hanger()
	for i: int in spells.size():
		if not spells[i] is Dictionary:
			continue
		var offer: Dictionary = spells[i]
		var disc: Rect2 = L1Layout.rect("shop.spell")
		disc.position.y += i * L1Layout.number("shop.spell.step")
		var radius: float = (disc.size.x + L1Layout.number("shop.spell.tint_overhang")) / 2.0
		draw_circle(
			disc.get_center(),
			radius,
			L1Layout.shop_tint(GlassPieces.as_int(offer.get("tier", 1))),
			true,
			-1.0,
			true
		)
	_draw_lanterns()


func _draw_hanger() -> void:
	var hanger: Texture2D = GlassPieces.texture("l1/l1z-hanger.png")
	var at: Vector2 = L1Layout.point("shop.hanger")
	var width: float = L1Layout.number("shop.hanger.w")
	var step: float = L1Layout.number("shop.spell.step")
	var scale_to_width: float = width / hanger.get_width()
	var head: Vector2 = Vector2(width, L1Layout.rect("shop.spell").get_center().y - at.y)
	var base: Rect2 = Rect2(at, head)
	var link: Rect2 = Rect2(at + Vector2(0, head.y), Vector2(width, step))
	var head_source: Rect2 = Rect2(Vector2.ZERO, head / scale_to_width)
	var link_source: Rect2 = Rect2(
		Vector2(0, L1Layout.number("shop.hanger.repeat_row")) / scale_to_width,
		link.size / scale_to_width
	)
	var shadow: Vector2 = L1Layout.point("shop.hanger.shadow")
	var shade: Color = Color(0, 0, 0, 0.6)
	draw_texture_rect_region(hanger, Rect2(base.position + shadow, base.size), head_source, shade)
	draw_texture_rect_region(hanger, Rect2(link.position + shadow, link.size), link_source, shade)
	draw_texture_rect_region(hanger, base, head_source)
	draw_texture_rect_region(hanger, link, link_source)


func _draw_lanterns() -> void:
	var lit: Texture2D = GlassPieces.texture("l1/l1s-lantern-lit.png")
	var dark: Texture2D = GlassPieces.texture("l1/l1s-lantern-dark.png")
	var gap: float = L1Layout.number("shop.arch.gap")
	var count: int = int(L1Layout.number("shop.arch.count"))
	var box: Vector2 = Vector2(L1Layout.number("shop.lantern.w"), L1Layout.number("shop.lantern.h"))
	var shadow: Vector2 = Vector2(0, L1Layout.number("shop.lantern.shadow_y"))
	for i: int in count + 1:
		var x: float = L1Layout.shop_opening_x(i) - gap / 2.0
		var rect: Rect2 = Rect2(Vector2(x - box.x / 2.0, 0), box)
		var lantern: Texture2D = lit if i < tier else dark
		draw_texture_rect(lantern, Rect2(rect.position + shadow, box), false, Color(0, 0, 0, 0.75))
		draw_texture_rect(lantern, rect, false)
