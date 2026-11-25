class_name L1ShopArch
extends GlassBox
## A persistent shop slot: the arch's recess, its painted stone and the tier light of the card in
## it (buy-screen-l1.md §9, S1). Recess, then painted arch, then the light on the card, then the
## card. The recess is lit from behind in the tier's colour at the tier's strength, the stone takes
## a soft-light tint, light spills out of the opening over the stone and the wall round it and
## pools on its foot, and a halo hugs the card. An empty arch is dark. The light breathes slowly,
## tier 6 the most.

const STONE_SHADER: Shader = preload("res://src/glass/l1_stone_tint.gdshader")

## The tier of the card in the arch, 0 for none.
var tier: int = 0:
	set(value):
		if tier != value:
			tier = value
			_light_up()
## The arch's place in the row, which staggers its breath against its neighbours'.
var place: int = 0:
	set(value):
		if place != value:
			place = value
			_light_up()

var _recess: L1Light
var _stone: Control
var _spill: L1Light
var _pool: L1Light
var _halo: L1Light


static func make(_bonus: Dictionary, box: Vector2) -> GlassBox:
	var slot: L1ShopArch = L1ShopArch.new()
	slot.box_size = box
	slot.size = box
	return slot


func _ready() -> void:
	var opening: Rect2 = _opening()
	_recess = L1Light.make(L1Light.Shape.ARCH, opening, Color.WHITE, "Recess")
	var radius: float = opening.size.x * L1Layout.number("shop.arch.radius_share")
	var half: float = opening.size.x / 2.0
	_recess.arch(radius, sqrt(radius * radius - pow(radius - half, 2.0)))
	add_child(_recess)
	_stone = Control.new()
	_stone.name = "Stone"
	_stone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stone_mat: ShaderMaterial = ShaderMaterial.new()
	stone_mat.shader = STONE_SHADER
	_stone.material = stone_mat
	_stone.draw.connect(_draw_stone)
	add_child(_stone)
	_spill = L1Light.make(L1Light.Shape.ARCH, opening, Color.WHITE, "Spill")
	_spill.arch(radius, sqrt(radius * radius - pow(radius - half, 2.0))).outside_only(true)
	add_child(_spill)
	var pool: Rect2 = Rect2(
		Vector2(
			(opening.size.x - L1Layout.number("light.shop.pool.w")) / 2.0 + opening.position.x,
			(
				L1Layout.number("light.shop.pool.y")
				- L1Layout.number("shop.arch.y")
				- L1Layout.number("shop.unit.down")
				- L1Layout.number("light.shop.pool.h") / 2.0
			)
		),
		Vector2(L1Layout.number("light.shop.pool.w"), L1Layout.number("light.shop.pool.h"))
	)
	_pool = L1Light.make(L1Light.Shape.ELLIPSE, pool, Color.WHITE, "Pool")
	add_child(_pool)
	_halo = L1Light.make(L1Light.Shape.CARD, Rect2(Vector2.ZERO, box_size), Color.WHITE, "Halo")
	add_child(_halo)
	_light_up()


## The lights and stone are its children; the box itself draws nothing.
func _draw() -> void:
	pass


## The opening in the slot's pixels (the slot's origin is its card's top left).
static func _opening() -> Rect2:
	return Rect2(
		-Vector2(L1Layout.number("shop.unit.inset"), L1Layout.number("shop.unit.down")),
		Vector2(L1Layout.number("shop.arch.w"), L1Layout.number("shop.arch.h"))
	)


func _draw_stone() -> void:
	var painted: Rect2 = L1Layout.rect("shop.arch.piece")
	painted.position -= Vector2(
		L1Layout.number("shop.unit.inset"),
		L1Layout.number("shop.arch.y") + L1Layout.number("shop.unit.down")
	)
	_stone.draw_texture_rect(GlassPieces.texture("l1/l1z-arch.png"), painted, false)


## The tier's colour and strength a (buy-screen-l1.md §9), and each light a share of a.
func _light_up() -> void:
	if _recess == null:
		return
	var lit: bool = tier > 0
	var tint: Color = L1Layout.shop_tint(tier) if lit else Color.BLACK
	var a: float = tint.a if lit else 0.0
	var colour: Color = Color(tint, 1.0)
	var period: float = L1Layout.number("light.shop.breathe.period")
	var depth: float = L1Layout.number(
		(
			"light.shop.breathe.depth_tier6"
			if tier == GlassPieces.TIERS
			else "light.shop.breathe.depth"
		)
	)
	var phase: float = place * L1Layout.number("light.shop.breathe.phase_step")
	var additive: float = L1Layout.number("light.shop.additive")
	for each: L1Light in [_recess, _spill, _pool, _halo]:
		each.colour = colour
		each.visible = lit or each == _recess
		each.blend(additive).breathe(period, depth, phase)
	_spill.blend(L1Layout.number("light.shop.spill.additive"))
	_spill.glow(
		Vector3(
			L1Layout.number("light.shop.spill.grow"),
			L1Layout.number("light.shop.spill.blur"),
			L1Layout.number("light.shop.spill.share") * a
		)
	)
	_recess.glow(Vector3.ZERO).fill_inside(
		L1Layout.colour("shop.arch.recess_colour"),
		L1Layout.number("shop.arch.recess_grow"),
		Rect2(
			L1Layout.number("light.shop.recess.cx"),
			L1Layout.number("light.shop.recess.cy"),
			L1Layout.number("light.shop.recess.rx"),
			L1Layout.number("light.shop.recess.ry")
		),
		Vector4(
			L1Layout.number("light.shop.recess.centre_share") * a,
			L1Layout.number("light.shop.recess.mid_share") * a,
			L1Layout.number("light.shop.recess.rim_share") * a,
			L1Layout.number("light.shop.recess.mid_stop")
		)
	)
	_pool.glow(
		Vector3(
			0.0,
			L1Layout.number("light.shop.pool.blur"),
			L1Layout.number("light.shop.pool.share") * a
		)
	)
	_halo.glow(
		Vector3(
			L1Layout.number("light.shop.halo.grow"),
			L1Layout.number("light.shop.halo.blur"),
			L1Layout.number("light.shop.halo.share") * a
		)
	)
	var stone: ShaderMaterial = _stone.material as ShaderMaterial
	stone.set_shader_parameter("tint", colour)
	stone.set_shader_parameter("amount", L1Layout.number("light.shop.stone.share") * a)
	stone.set_shader_parameter("motion", Vector3(period, depth, phase))


## The lights, for tests and the film: Recess, Spill, Pool and Halo.
func light(light_name: String) -> L1Light:
	return get_node_or_null(light_name) as L1Light
