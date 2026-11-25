class_name L1ShopArch
extends GlassBox
## A persistent shop slot with a painted arch around its card and a flat tier-colour stand-in.

static var _recess: PackedVector2Array

var tier: int = 0:
	set(value):
		if tier != value:
			tier = value
			queue_redraw()


static func make(_bonus: Dictionary, box: Vector2) -> GlassBox:
	var slot: L1ShopArch = L1ShopArch.new()
	slot.box_size = box
	slot.size = box
	return slot


func _draw() -> void:
	if _recess.is_empty():
		_recess = _opening()
	var colour: Color = L1Layout.colour("shop.arch.recess_colour")
	if tier > 0:
		var tint: Color = L1Layout.shop_tint(tier)
		colour = colour.lerp(Color(tint, 1.0), tint.a)
	draw_colored_polygon(_recess, colour)
	var painted: Rect2 = L1Layout.rect("shop.arch.piece")
	painted.position -= Vector2(
		L1Layout.number("shop.unit.inset"),
		L1Layout.number("shop.arch.y") + L1Layout.number("shop.unit.down")
	)
	draw_texture_rect(GlassPieces.texture("l1/l1z-arch.png"), painted, false)


static func _opening() -> PackedVector2Array:
	var width: float = L1Layout.number("shop.arch.w")
	var height: float = L1Layout.number("shop.arch.h")
	var grown: float = L1Layout.number("shop.arch.recess_grow")
	var origin: Vector2 = -Vector2(
		L1Layout.number("shop.unit.inset") + grown, L1Layout.number("shop.unit.down") + grown
	)
	var stretch: Vector2 = Vector2((width + 2.0 * grown) / width, (height + grown) / height)
	var radius: float = width * L1Layout.number("shop.arch.radius_share")
	var spring: float = sqrt(radius * radius - pow(radius - width / 2.0, 2.0))
	var roof_angle: float = acos((radius - width / 2.0) / radius)
	var left: PackedVector2Array = PackedVector2Array([origin + Vector2(0, height) * stretch])
	var right: PackedVector2Array = PackedVector2Array()
	for step: int in 17:
		var theta: float = roof_angle * step / 16.0
		var at: Vector2 = Vector2(radius * (1.0 - cos(theta)), spring - radius * sin(theta))
		left.append(origin + at * stretch)
		if step < 16:
			right.append(origin + Vector2(width - at.x, at.y) * stretch)
	right.reverse()
	left.append_array(right)
	left.append(origin + Vector2(width, height) * stretch)
	return left
