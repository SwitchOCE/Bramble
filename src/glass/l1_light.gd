class_name L1Light
extends Control
## A light drawn by the engine (l1_light.gdshader) round a shape, tinted and timed at run time:
## the shop's tier light, the lanterns, the beads, the golden halo, the tier on hover and End turn.
## Never a glow painted into a texture (buy-screen-l1.md §9). Its numbers live in the L1 layout
## file under "light.".

enum Shape { CARD, CIRCLE, ARCH, ELLIPSE }

const SHADER: Shader = preload("res://src/glass/l1_light.gdshader")

var shape: Shape = Shape.CARD
## The shape's box in this node's pixels.
var shape_rect: Rect2
var colour: Color = Color.WHITE
## The glows: Vector3(grow, blur, opacity), in pixels as CSS draws a grown, blurred outline.
var near: Vector3 = Vector3.ZERO
var far: Vector3 = Vector3.ZERO
var _mat: ShaderMaterial


static func make(kind: Shape, rect: Rect2, tint: Color, light_name: String) -> L1Light:
	var light: L1Light = L1Light.new()
	light.name = light_name
	light.shape = kind
	light.shape_rect = rect
	light.colour = tint
	return light


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat


## Sets the glows and draws again.
func glow(near_glow: Vector3, far_glow: Vector3 = Vector3.ZERO) -> L1Light:
	near = near_glow
	far = far_glow
	_apply()
	return self


## A slow breath (depth: share of the light) and a little flicker, phase a share of a period.
func breathe(period: float, depth: float, phase: float = 0.0, flicker: float = 0.0) -> L1Light:
	_mat.set_shader_parameter("motion", Vector4(maxf(period, 0.01), depth, phase, flicker))
	return self


## How much the light adds to what is under it (1) rather than covering it (0).
func blend(additive: float) -> L1Light:
	_mat.set_shader_parameter("additive", clampf(additive, 0.0, 1.0))
	return self


## The inside of the shape: a solid base, grown by grow px, lit by a radial ellipse
## (centre and radii as shares of the shape's box) at opacities centre, mid (at mid_stop) and rim.
func fill_inside(base: Color, grow: float, ellipse: Rect2, opacities: Vector4) -> L1Light:
	_mat.set_shader_parameter("base", base)
	_mat.set_shader_parameter("fill_grow", grow)
	_mat.set_shader_parameter(
		"fill_ellipse",
		Vector4(ellipse.position.x, ellipse.position.y, ellipse.size.x, ellipse.size.y)
	)
	_mat.set_shader_parameter("fill", opacities)
	_apply()
	return self


## The arch's side radius and springing depth (Shape.ARCH).
func arch(radius: float, spring: float) -> L1Light:
	_mat.set_shader_parameter("arch", Vector2(radius, spring))
	return self


## Extra opacity over the whole light, for a flash.
func set_boost(value: float) -> void:
	_mat.set_shader_parameter("boost", value)


func boost() -> float:
	return GlassPieces.as_float(_mat.get_shader_parameter("boost"))


## The glow's opacity at the shape's edge before any breath: what a test can read.
func strength() -> float:
	return near.z + far.z


func _apply() -> void:
	_mat.set_shader_parameter("shape", int(shape))
	_mat.set_shader_parameter(
		"shape_rect",
		Vector4(shape_rect.position.x, shape_rect.position.y, shape_rect.size.x, shape_rect.size.y)
	)
	var angle: float = L1CardFace.point_angle()
	_mat.set_shader_parameter("slopes", Vector2(sin(angle), cos(angle)))
	_mat.set_shader_parameter("colour", colour)
	_mat.set_shader_parameter("near", near)
	_mat.set_shader_parameter("far", far)
	queue_redraw()


## The drawn quad: the shape grown by the farthest glow and room for its blur.
func reach() -> Rect2:
	var margin: float = 2.0
	for g: Vector3 in [near, far]:
		if g.z > 0.0:
			margin = maxf(margin, g.x + 2.4 * g.y + 2.0)
	return shape_rect.grow(margin)


func _draw() -> void:
	draw_rect(reach(), Color.WHITE)
