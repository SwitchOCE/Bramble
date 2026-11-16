class_name GlassCard
extends Control
## One unit card drawn the way the mock-ups' card.js makes it: the art clipped to the art window,
## the tier's frame on top, and Attack and Health centred on that tier's own discs, sized from
## the disc's radius. Every number comes from GlassPieces (assets/glass, pulled from the mock-ups).
## Set the fields, then add it to the tree; the card sizes itself from card_height.

## STAND-IN (polish.html .card .num.up): a raised number's colour and glow.
const UP_COLOUR: Color = Color("0a6e14")
const UP_GLOW: Color = Color(0.784, 1.0, 0.667, 1.0)
const UP_GLOW_EM: float = 0.14
const SHADOW_SHADER: Shader = preload("res://src/glass/card_shadow.gdshader")
## STAND-IN (docs/ideation-track-2/mockups/stand-ins.html ?m=drag, .card.held): a card carried
## by the pointer, lifted: a warm light under it and a deeper, softer shadow.
const HELD_BRIGHTNESS: float = 1.06
const HELD_SHADOWS: Array[Dictionary] = [
	{"x": 0.0, "y": 0.0, "blur": 14.0, "colour": Color(1.0, 0.925, 0.745, 0.5)},
	{"x": 0.0, "y": 22.0, "blur": 18.0, "colour": Color(0.0, 0.0, 0.0, 0.55)},
]

var tier: int = 1
var art: Texture2D
var attack: int = 0
var health: int = 0
## The card's height in pixels; its width follows the frame's 560 x 1000 shape.
var card_height: float = 250.0
## What the card prints and its Health before damage, when known (-1: not): set_numbers colours
## the numbers from them.
var base_attack: int = -1
var base_health: int = -1
var max_health: int = -1
## card.js hurt: Health drawn in red (card.css .card .num.hurt), for a unit damaged in a fight.
var hurt: bool = false
## STAND-IN (polish.html .card .num.up): Attack or Health above what the card prints, in green.
var up_attack: bool = false
var up_health: bool = false
## Attack below what the card prints, in the damaged red.
var down_attack: bool = false
## A golden unit (7.3): STAND-IN gold rim round the frame, as no golden frame is designed yet.
var golden: bool = false
## How big Attack (x) and Health (y) are drawn against their size, for a number that just changed
## to pop (the screens tween it back to 1).
var number_pop: Vector2 = Vector2.ONE:
	set(value):
		number_pop = value
		queue_redraw()

var _hot: bool = false
## The CSS rule whose filter lights the card now ([file, selector]), or none.
var _glow: PackedStringArray = PackedStringArray()
## The rule set_glow gave, which comes back when the hover leaves.
var _lit: PackedStringArray = PackedStringArray()
var _shadows: Array[Control] = []
var _held: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = card_size(card_height)
	size = custom_minimum_size
	_make_shadows()


## stage.css .card.hot: brighter, with a warm glow and a deeper shadow in place of the card's own.
func set_hot(on: bool) -> void:
	if on == _hot:
		return
	_hot = on
	_apply_glow(PackedStringArray(["stage", ".card.hot"]) if on else _lit)


## The numbers shown, and their colours with them: green above what the card prints, red below
## (polish.html .num.up), Health red when below its most (card.js hurt). A dying unit's Health
## shows 0, never below.
func set_numbers(new_attack: int, new_health: int) -> void:
	attack = new_attack
	health = maxi(0, new_health)
	hurt = max_health >= 0 and new_health < max_health
	if base_attack >= 0:
		up_attack = attack > base_attack
		down_attack = attack < base_attack
	if base_health >= 0:
		up_health = health > base_health
		hurt = hurt or health < base_health
	queue_redraw()


## Carried by the pointer (HELD_SHADOWS), or put down: its own look again.
func set_held(on: bool) -> void:
	if on == _held:
		return
	_held = on
	_apply_glow(_glow)


func is_held() -> bool:
	return _held


## A CSS rule's filter on the card: brightness, then drop-shadows in place of the card's own
## (file "fight", ".card.lunge"); selector "" puts the card's own back. Hover lights over it.
func set_glow(file: String, selector: String) -> void:
	_lit = PackedStringArray([file, selector]) if selector != "" else PackedStringArray()
	if not _hot:
		_apply_glow(_lit)


func _apply_glow(rule: PackedStringArray) -> void:
	_glow = rule
	var brightness: float = HELD_BRIGHTNESS if _held else 1.0
	if not _held and not _glow.is_empty():
		for f: Dictionary in GlassPieces.rule(_glow[0], _glow[1], "filter"):
			if f["fn"] == "brightness":
				brightness = f["amount"]
	self_modulate = Color(brightness, brightness, brightness)
	if is_inside_tree():
		_make_shadows()


## The drop-shadows behind the card: card.css's one, or the glow rule's (the first nearest).
func _shadow_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _held:
		out.assign(HELD_SHADOWS)
		return out
	if not _glow.is_empty():
		for f: Dictionary in GlassPieces.rule(_glow[0], _glow[1], "filter"):
			if f["fn"] == "drop-shadow":
				(
					out
					. append(
						{
							"x": _f(f["x"]),
							"y": _f(f["y"]),
							"blur": _f(f["blur"]),
							"colour": Color.html(str(f["colour"])),
						}
					)
				)
		return out
	(
		out
		. append(
			{
				"x": GlassPieces.number("card.shadow.x"),
				"y": GlassPieces.number("card.shadow.y"),
				"blur": GlassPieces.number("card.shadow.blur"),
				"colour": GlassPieces.css_colour(GlassPieces.text("card.shadow.colour")),
			}
		)
	)
	return out


func _make_shadows() -> void:
	for old: Control in _shadows:
		remove_child(old)
		old.queue_free()
	_shadows.clear()
	var list: Array[Dictionary] = _shadow_list()
	# drawn behind the card, the later child over the earlier: add the outermost first
	for i: int in range(list.size() - 1, -1, -1):
		var shadow: Control = Control.new()
		shadow.name = "Shadow%d" % i
		shadow.show_behind_parent = true
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var spec: Dictionary = list[i]
		shadow.draw.connect(func() -> void: _draw_shadow(shadow, spec))
		add_child(shadow)
		_shadows.append(shadow)


## The card's size in pixels at a given height.
static func card_size(height: float) -> Vector2:
	return Vector2(height * GlassPieces.card_units().x / GlassPieces.card_units().y, height)


## Pixels per card unit.
func _k() -> float:
	return card_height / GlassPieces.card_units().y


func _draw() -> void:
	var k: float = _k()
	var points: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in GlassPieces.art_polygon():
		points.append(p * k)
		uvs.append(p / GlassPieces.card_units())
	if art != null:
		draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, art)
	draw_texture_rect(GlassPieces.frame(tier), Rect2(Vector2.ZERO, card_size(card_height)), false)
	if golden:
		var whole: Vector2 = card_size(card_height)
		var rim: PackedVector2Array = GlassBox.hexagon(Rect2(Vector2.ZERO, whole), 0.17)
		rim.append(rim[0])
		draw_polyline(rim, Color(1.0, 0.78, 0.25, 0.95), 0.03 * whole.x, true)
	_draw_number(attack, GlassPieces.disc(tier, "attack"), down_attack, number_pop.x, up_attack)
	_draw_number(
		health, GlassPieces.disc(tier, "health"), hurt, number_pop.y, up_health and not hurt
	)


## card.js num(): one digit at 1.2 x the disc's radius, two at 0.95 x; the box is the disc's
## square, the text centred in it with card.css's padding, letter spacing and glow.
func _draw_number(
	value: int, disc: Vector3, red: bool, pop: float = 1.0, green: bool = false
) -> void:
	var k: float = _k()
	if not is_equal_approx(pop, 1.0):
		var centre: Vector2 = Vector2(disc.x, disc.y) * k
		draw_set_transform(centre * (1.0 - pop), 0.0, Vector2(pop, pop))
	var digits: String = str(value)
	var scale_key: String = (
		"card.num.two_digit_scale" if digits.length() > 1 else "card.num.one_digit_scale"
	)
	var font_size: int = roundi(disc.z * GlassPieces.number(scale_key) * k)
	var font: Font = GlassPieces.display_font(_i(GlassPieces.number("card.num.weight")), true)
	var spacing: float = GlassPieces.number("card.num.letter_spacing_em") * font_size
	var advances: PackedFloat32Array = PackedFloat32Array()
	var width: float = 0.0
	for ch: String in digits:
		var advance: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		advances.append(advance)
		width += advance + spacing
	# The box (content-box, with padding-top) is centred on the disc, so the line's middle sits
	# padding/2 below the disc's centre; with line-height 1 the baseline is (ascent - descent)/2
	# below the line's middle, with the browser's rounded ascent and descent.
	var pad: float = GlassPieces.number("card.num.padding_top_em") * font_size
	var middle: Vector2 = Vector2(disc.x, disc.y) * k + Vector2(0.0, pad / 2.0)
	var line: Vector3 = GlassPieces.css_line("display", font_size)
	var baseline: float = middle.y + (line.x - line.y) / 2.0
	var colour: Color = GlassPieces.colour("card.num.colour")
	var glow: Color = GlassPieces.css_colour(GlassPieces.text("card.num.glow"))
	var glow_px: float = GlassPieces.number("card.num.glow_em") * font_size
	if red:
		colour = GlassPieces.rule_colour("card", ".card .num.hurt", "color")
		var hurt_glow: Array = GlassPieces.rule("card", ".card .num.hurt", "text-shadow")
		var spec: Dictionary = hurt_glow[0]
		glow = Color.html(str(spec["colour"]))
		glow_px = str(spec["blur"]).trim_suffix("em").to_float() * font_size
	elif green:
		colour = UP_COLOUR
		glow = UP_GLOW
		glow_px = UP_GLOW_EM * font_size
	var x: float = middle.x - width / 2.0
	for i: int in digits.length():
		var at: Vector2 = Vector2(x, baseline)
		# STAND-IN for the CSS text-shadow blur: soft outlines of falling strength.
		for pass_i: int in 3:
			var reach: float = glow_px * (1.6 - 0.5 * pass_i)
			var tint: Color = glow * Color(1, 1, 1, 0.16 + 0.08 * pass_i)
			draw_string_outline(
				font,
				at,
				digits[i],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				maxi(1, roundi(reach * 2.0)),
				tint
			)
		draw_string(font, at, digits[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
		x += advances[i] + spacing
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A CSS drop-shadow: the frame's shape, offset, blurred and tinted, behind the card.
func _draw_shadow(on: Control, spec: Dictionary) -> void:
	var tex: Texture2D = GlassPieces.frame(tier)
	var card: Vector2 = card_size(card_height)
	var blur: float = spec["blur"]
	var margin: float = blur * 1.5 + 2.0
	var offset: Vector2 = Vector2(_f(spec["x"]), _f(spec["y"]))
	var rect: Rect2 = Rect2(offset - Vector2(margin, margin), card + Vector2(margin, margin) * 2.0)
	var mat: ShaderMaterial = on.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = SHADOW_SHADER
		on.material = mat
	# rect UV (0..1) to frame UV: uv * scale + offset
	mat.set_shader_parameter("uv_scale", rect.size / card)
	mat.set_shader_parameter("uv_offset", -Vector2(margin, margin) / card)
	# CSS blur radius is twice the Gaussian's standard deviation.
	mat.set_shader_parameter("sigma_uv", Vector2(blur / 2.0, blur / 2.0) / card)
	mat.set_shader_parameter("shadow_colour", spec["colour"])
	on.draw_texture_rect(tex, rect, false)


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)


static func _i(v: Variant) -> int:
	return GlassPieces.as_int(v)
