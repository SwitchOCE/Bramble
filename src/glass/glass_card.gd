class_name GlassCard
extends Control
## One unit card. Lead, art and stats share the same layout at every tier and on every screen.
## Set the fields, then add it to the tree; the card sizes itself from card_height.

## STAND-IN (docs/ideation-track-2/mockups/stand-ins.html ?m=drag, .card.held): a card carried
## by the pointer, lifted: a warm light under it and a deeper, softer shadow.
const HELD_BRIGHTNESS: float = 1.06
const HELD_SHADOWS: Array[Dictionary] = [
	{"x": 0.0, "y": 0.0, "blur": 14.0, "colour": Color(1.0, 0.925, 0.745, 0.5)},
	{"x": 0.0, "y": 22.0, "blur": 18.0, "colour": Color(0.0, 0.0, 0.0, 0.55)},
]
const GLINT_SHADER: Shader = preload("res://src/glass/l1_glint.gdshader")
static var _stat_settings: Dictionary[bool, Texture2D] = {}

var art: Texture2D
var attack: int = 0
var health: int = 0
## The card's height in pixels; its width follows the L1 proportions.
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
## A golden unit uses gilt lead and stat rims, with its light (buy-screen-l1.md §9, G1 to G3): a
## warm halo behind it, light round its Attack and Health rims, and a glint along the gilt.
var golden: bool = false:
	set(value):
		golden = value
		if _face != null:
			_face.set_gilt(golden, _glint_phase())
			_light_golden()
		queue_redraw()
## How big Attack (x) and Health (y) are drawn against their size, for a number that just changed
## to pop (the screens tween it back to 1).
var number_pop: Vector2 = Vector2.ONE:
	set(value):
		number_pop = value
		queue_redraw()

var _face: L1CardFace
var _hot: bool = false
var _raised: bool = false
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
	_face = L1CardFace.new()
	_face.name = "Face"
	_face.show_behind_parent = true
	_face.build(size, art)
	_face.set_gilt(golden, _glint_phase())
	add_child(_face)
	_make_shadows()
	_light_golden()


## STAND-IN (stage.css .card.hot): brightness, warm glow and a deeper shadow.
func set_hot(on: bool) -> void:
	if on == _hot:
		return
	_hot = on
	_apply_glow(PackedStringArray(["stage", ".card.hot"]) if on else _lit)


## A hand card standing up has a deeper slab shadow.
func set_raised(on: bool) -> void:
	if on == _raised:
		return
	_raised = on
	_make_shadows()


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
	if _face != null:
		_face.self_modulate = self_modulate
		_make_shadows()


## STAND-IN: keep existing held, hovered and combat glows on the new silhouette. A raised
## hand card uses the L1 slab shadow in place of the existing hover rule's black shadow.
func _shadow_list() -> Array[Dictionary]:
	if _held:
		return HELD_SHADOWS
	var out: Array[Dictionary] = []
	if not _glow.is_empty():
		for f: Dictionary in GlassPieces.rule(_glow[0], _glow[1], "filter"):
			if f["fn"] != "drop-shadow":
				continue
			var colour: Color = Color.html(str(f["colour"]))
			if _raised and Vector3(colour.r, colour.g, colour.b) == Vector3.ZERO:
				continue
			out.append({"x": _f(f["x"]), "y": _f(f["y"]), "blur": _f(f["blur"]), "colour": colour})
	if _raised or out.is_empty():
		out.append(L1CardFace.slab_shadow(_raised, false, _k()))
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
		move_child(shadow, _shadows.size())
		_shadows.append(shadow)


## Golden cards glint at different moments: a stable share of the period from this card.
func _glint_phase() -> float:
	return float(get_instance_id() % 997) / 997.0


## Adds or removes the golden light: GoldenHalo behind the card, GoldenRims round the Attack and
## Health discs (over the face, under the discs), GoldenGlint (the twinkle) over the card.
func _light_golden() -> void:
	for light_name: String in ["GoldenHalo", "GoldenRim_attack", "GoldenRim_health", "GoldenGlint"]:
		var old: Node = get_node_or_null(light_name)
		if old != null:
			remove_child(old)
			old.queue_free()
	if not golden or _face == null:
		return
	var k: float = _k()
	var box: Vector2 = size
	var additive: float = L1Layout.number("light.golden.additive")
	var halo: L1Light = L1Light.make(
		L1Light.Shape.CARD,
		Rect2(Vector2.ZERO, box),
		L1Layout.colour("light.golden.halo_colour"),
		"GoldenHalo"
	)
	halo.show_behind_parent = true
	halo.glow(
		Vector3(
			L1Layout.number("light.golden.halo.grow") * k,
			L1Layout.number("light.golden.halo.blur") * k,
			L1Layout.number("light.golden.halo.alpha")
		)
	)
	halo.blend(additive).dim_over_backdrop().breathe(
		1.0, 0.0, _glint_phase(), L1Layout.number("light.golden.halo.flicker")
	)
	add_child(halo)
	move_child(halo, _face.get_index())
	for stat: String in ["attack", "health"]:
		var disc: Vector3 = stat_disc(stat)
		var outer: float = (
			disc.z + L1Layout.number("card.stat.rim") + L1Layout.number("card.stat.outline")
		)
		var rim: L1Light = L1Light.make(
			L1Light.Shape.CIRCLE,
			Rect2(
				(Vector2(disc.x, disc.y) - Vector2.ONE * outer) * k, Vector2.ONE * 2.0 * outer * k
			),
			L1Layout.colour("light.golden.rim_colour"),
			"GoldenRim_" + stat
		)
		rim.show_behind_parent = true
		rim.glow(
			Vector3(
				0.0,
				L1Layout.number("light.golden.rim.blur") * k,
				L1Layout.number("light.golden.rim.alpha")
			)
		)
		rim.blend(additive)
		add_child(rim)
		move_child(rim, _face.get_index() + 1)
	add_child(_glint(box, k))


## The twinkle: a four-point star at the upper right shoulder, timed to the glint's passing.
func _glint(box: Vector2, k: float) -> Control:
	var star: Control = Control.new()
	star.name = "GoldenGlint"
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side: float = L1Layout.number("light.golden.star.size") * k * 2.0
	var shoulder: Vector2 = Vector2(box.x, box.x * tan(L1CardFace.point_angle()) / 2.0)
	star.position = shoulder - Vector2.ONE * side / 2.0
	star.size = Vector2.ONE * side
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GLINT_SHADER
	mat.set_shader_parameter("core", L1Layout.colour("light.golden.star_core_colour"))
	mat.set_shader_parameter("glow", L1Layout.colour("light.golden.star_glow_colour"))
	var timing: Vector4 = L1CardFace.glint_timing(_glint_phase())
	mat.set_shader_parameter(
		"timing",
		Vector4(
			timing.x,
			timing.y * L1CardFace.way_round(shoulder, box),
			L1Layout.number("light.golden.star.time"),
			timing.w
		)
	)
	star.material = mat
	star.draw.connect(func() -> void: star.draw_rect(Rect2(Vector2.ZERO, star.size), Color.WHITE))
	return star


## The card's size in pixels at a given height.
static func card_size(height: float) -> Vector2:
	var reference: Vector2 = L1CardFace.draw_size()
	return Vector2(height * (reference.x / reference.y), height)


func _k() -> float:
	return card_height / L1Layout.number("card.h")


## The centre and radius of the cream face in L1 design pixels; the rims sit outside it.
static func stat_disc(stat: String) -> Vector3:
	var r: float = L1Layout.number("card.stat.d") / 2.0
	var centre: Vector2 = L1Layout.point("card.stat." + stat) + Vector2.ONE * r
	return Vector3(centre.x, centre.y, r)


func _draw() -> void:
	_draw_stat(attack, stat_disc("attack"), down_attack, number_pop.x, up_attack)
	_draw_stat(health, stat_disc("health"), hurt, number_pop.y, up_health and not hurt)


func _draw_stat(value: int, disc: Vector3, red: bool, pop: float, green: bool) -> void:
	var k: float = _k()
	var centre: Vector2 = Vector2(disc.x, disc.y) * k
	var outer: float = (
		(disc.z + L1Layout.number("card.stat.rim") + L1Layout.number("card.stat.outline")) * k
	)
	draw_texture_rect(
		_stat_setting(golden), Rect2(centre - Vector2.ONE * outer, Vector2.ONE * 2.0 * outer), false
	)

	var digits: String = str(value)
	var font: Font = GlassPieces.body_font(700, true)
	var font_size: int = maxi(1, roundi(L1Layout.number("card.stat.font_px") * k))
	var width: float = font.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# STAND-IN (§11): keep long values centred and fit them to the face.
	var fit: float = minf(1.0, 2.0 * disc.z * k / maxf(1.0, width))
	var baseline: float = (font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
	baseline += L1Layout.number("card.stat.baseline_em") * font_size
	draw_set_transform(centre, 0.0, Vector2(fit, 1.0) * pop)
	var at: Vector2 = Vector2(-width / 2.0, baseline)
	var colour: Color = Color("2a2118")
	if red or green:
		colour = L1Layout.colour("card.stat.lowered_colour" if red else "card.stat.raised_colour")
		draw_string_outline(
			font, at, digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 1, Color("120e0b")
		)
	draw_string(font, at, digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
	draw_set_transform(Vector2.ZERO)


static func _stat_setting(gilt: bool) -> Texture2D:
	if not _stat_settings.has(gilt):
		var d: float = L1Layout.number("card.stat.d")
		var r: float = d / 2.0
		var rim: float = r + L1Layout.number("card.stat.rim")
		var outer: float = rim + L1Layout.number("card.stat.outline")
		var at: Vector2 = Vector2.ONE * (outer - r) + L1Layout.point("card.stat.focus") * d
		var reach: float = at.distance_to(Vector2.ONE * (outer + r))
		var diameter: float = outer * 2.0
		var svg: String = (
			'<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s">' % [diameter, diameter]
			+ (
				'<defs><radialGradient id="face" gradientUnits="userSpaceOnUse" cx="%s" cy="%s" r="%s">'
				% [at.x, at.y, reach]
			)
			+ (
				'<stop offset="0" stop-color="#fbf3df"/><stop offset="%s" stop-color="#e6d6b4"/>'
				% L1Layout.number("card.stat.face_stop")
			)
			+ '<stop offset="1" stop-color="#c9b48d"/></radialGradient></defs>'
			+ _circle(outer, outer, "#fff0b8" if gilt else "#555b58")
			+ _circle(outer, rim, "#d9a24a" if gilt else "#1c201f")
			+ _circle(outer, r, "url(#face)")
			+ "</svg>"
		)
		var img: Image = Image.new()
		img.load_svg_from_string(svg, 4.0)
		img.generate_mipmaps()
		_stat_settings[gilt] = ImageTexture.create_from_image(img)
	return _stat_settings[gilt]


static func _circle(centre: float, radius: float, fill: String) -> String:
	return '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % [centre, centre, radius, fill]


func _draw_shadow(on: Control, spec: Dictionary) -> void:
	L1CardFace.draw_shadow(on, spec, card_size(card_height))


static func _f(v: Variant) -> float:
	return GlassPieces.as_float(v)
