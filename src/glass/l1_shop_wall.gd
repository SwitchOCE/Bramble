class_name L1ShopWall
extends Control
## The wall fittings behind the offers: the spells' chain and the lanterns, with the lights behind
## them (buy-screen-l1.md §9): each spell's tier light (S2) and each lit lantern's warm light (S3).

var tier: int
var spells: Array


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_add_spell_lights()
	_add_lantern_lights()


func _draw() -> void:
	_draw_hanger()
	_draw_lanterns()


## A spell's tier light, behind its disc: an inner and an outer circle, breathing as the arches do.
func _add_spell_lights() -> void:
	var additive: float = L1Layout.number("light.shop.additive")
	var period: float = L1Layout.number("light.shop.breathe.period")
	for i: int in spells.size():
		if not spells[i] is Dictionary:
			continue
		var offer: Dictionary = spells[i]
		var spell_tier: int = GlassPieces.as_int(offer.get("tier", 1))
		var tint: Color = L1Layout.shop_tint(spell_tier)
		var disc: Rect2 = L1Layout.rect("shop.spell")
		disc.position.y += i * L1Layout.number("shop.spell.step")
		var light: L1Light = L1Light.make(
			L1Light.Shape.CIRCLE, disc, Color(tint, 1.0), "SpellLight_%d" % i
		)
		light.show_behind_parent = true
		light.glow(
			Vector3(
				L1Layout.number("light.spell.near.grow"),
				L1Layout.number("light.spell.near.blur"),
				L1Layout.number("light.spell.near.share") * tint.a
			),
			Vector3(
				L1Layout.number("light.spell.far.grow"),
				L1Layout.number("light.spell.far.blur"),
				L1Layout.number("light.spell.far.share") * tint.a
			)
		)
		var depth: float = L1Layout.shop_breath(spell_tier)
		var phase: float = (i + 0.5) * L1Layout.number("light.shop.breathe.phase_step")
		light.blend(additive).breathe(period, depth, phase)
		add_child(light)


## A small warm light round each lit lantern, flickering a little.
func _add_lantern_lights() -> void:
	var gap: float = L1Layout.number("shop.arch.gap")
	var d: float = L1Layout.number("light.lantern.d")
	for i: int in mini(tier, int(L1Layout.number("shop.arch.count")) + 1):
		var x: float = L1Layout.shop_opening_x(i) - gap / 2.0
		var centre: Vector2 = Vector2(x, L1Layout.number("light.lantern.y"))
		var light: L1Light = L1Light.make(
			L1Light.Shape.CIRCLE,
			Rect2(centre - Vector2.ONE * d / 2.0, Vector2.ONE * d),
			L1Layout.colour("light.lantern.light_colour"),
			"LanternLight_%d" % i
		)
		light.show_behind_parent = true
		light.glow(
			Vector3(
				0.0, L1Layout.number("light.lantern.blur"), L1Layout.number("light.lantern.alpha")
			)
		)
		light.blend(L1Layout.number("light.lantern.additive")).breathe(
			1.0, 0.0, i * 0.37, L1Layout.number("light.lantern.flicker")
		)
		add_child(light)


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
