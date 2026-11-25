extends Control
## Rendered regression: a light must fade and darken with its card (buy-screen-l1.md §9). Run with
## Compatibility under Xvfb, not the headless dummy renderer (scripts/check.sh, feel step).
## Compare a golden card with and without each light at full strength, half and quarter RGB,
## half alpha and zero alpha. The differences should follow the card's modulate.
## -- --out=/path saves the shot and the values.

const MODULATES: Array[Color] = [
	Color.WHITE,
	Color(0.5, 0.5, 0.5, 1),
	Color(0.25, 0.25, 0.25, 1),
	Color(1, 1, 1, 0.5),
	Color(1, 1, 1, 0),
]
const LIGHTS: Array[String] = ["halo", "rim", "glint", "twinkle", "tier"]
const HEIGHT: float = 200.0
const CELL: Vector2 = Vector2(160, 210)
const ORIGIN: Vector2 = Vector2(40, 20)


func _ready() -> void:
	var out: String = "/tmp/bramble-light-fade-pixels"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	var back: ColorRect = ColorRect.new()
	back.color = Color(0.15, 0.15, 0.15)
	back.size = Vector2(1920, 1080)
	add_child(back)
	var cards: Dictionary = {}
	for row: int in MODULATES.size():
		for column: int in LIGHTS.size() + 1:
			var card: GlassCard = GlassCard.new()
			card.art = GlassPieces.art("mouse-1")
			card.card_height = HEIGHT
			card.golden = true
			card.set_numbers(3, 4)
			card.position = ORIGIN + Vector2(column, row) * CELL
			card.modulate = MODULATES[row]
			add_child(card)
			_show_only(card, "" if column == 0 else LIGHTS[column - 1])
			cards[Vector2i(column, row)] = card
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var shot: Image = get_viewport().get_texture().get_image()
	shot.save_png(out.path_join("light-fade.png"))
	var first: GlassCard = cards[Vector2i(0, 0)]
	var report: Dictionary = {}
	var passed: bool = true
	for i: int in LIGHTS.size():
		var light: String = LIGHTS[i]
		var region: Rect2i = _region(light, first)
		var adds: Array[float] = []
		for row: int in MODULATES.size():
			var offset: Vector2i = Vector2i(Vector2(i + 1, 0) * CELL)
			var lit: Rect2i = Rect2i(
				region.position + Vector2i(Vector2(0, row) * CELL), region.size
			)
			adds.append(_difference(shot, Rect2i(lit.position + offset, lit.size), lit))
		var full: float = adds[0]
		var ok: bool = (
			full > 6.0
			and absf(adds[1] / full - 0.5) <= 0.06
			and absf(adds[2] / full - 0.25) <= 0.04
			and absf(adds[3] / full - 0.5) <= 0.06
			and adds[4] <= 0.01
		)
		passed = passed and ok
		report[light] = {
			"full": full,
			"half_rgb": adds[1],
			"quarter_rgb": adds[2],
			"half_alpha": adds[3],
			"zero_alpha": adds[4],
			"ok": ok,
		}
	var file: FileAccess = FileAccess.open(out.path_join("pixels.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, " "))
	file.close()
	print("light_fade_pixels: ", "PASS " if passed else "FAIL ", JSON.stringify(report))
	get_tree().quit(0 if passed else 1)


## Hides every golden light but one, and holds the timed ones still and fully shown.
func _show_only(card: GlassCard, light: String) -> void:
	var halo: L1Light = card.get_node("GoldenHalo")
	halo.breathe(1.0, 0.0)
	halo.visible = light == "halo"
	for stat: String in ["attack", "health"]:
		(card.get_node("GoldenRim_" + stat) as Control).visible = light == "rim"
	var face: Control = card.get_node("Face")
	var face_mat: ShaderMaterial = face.material
	# a glint band as wide as the whole outline, standing still
	face_mat.set_shader_parameter("glint", Vector4(1.0e6, 1.0e6, 10.0, 0.5))
	if light != "glint":
		face_mat.set_shader_parameter("glint_colour", Color(1, 1, 1, 0))
	var star: Control = card.get_node("GoldenGlint")
	var star_mat: ShaderMaterial = star.material
	# A tiny period keeps both the star's brightness and rotation near their peak pose.
	star_mat.set_shader_parameter("timing", Vector4(0.001, 0.0, 1.0, 0.0))
	star.visible = light == "twinkle"
	if light == "tier":
		var hug: L1Light = RecruitTips.tier_hug(card, 4)
		card.add_child(hug)
		card.move_child(hug, face.get_index())


## Where each light is read, in stage pixels for the card at the first cell.
func _region(light: String, card: GlassCard) -> Rect2i:
	var at: Vector2 = card.position
	var k: float = HEIGHT / L1Layout.number("card.h")
	match light:
		"halo", "tier":
			return Rect2i(Vector2i(at + Vector2(-6, 90)), Vector2i(3, 30))
		"rim":
			var disc: Vector3 = GlassCard.stat_disc("attack")
			var outer: float = (
				disc.z + L1Layout.number("card.stat.rim") + L1Layout.number("card.stat.outline")
			)
			var top: Vector2 = at + Vector2(disc.x, disc.y - outer) * k
			return Rect2i(Vector2i(top + Vector2(-3, -3)), Vector2i(6, 2))
		"glint":
			return Rect2i(Vector2i(at + Vector2(1, 90)), Vector2i(2, 30))
	# the twinkle's centre, at the upper right shoulder
	var shoulder: Vector2 = Vector2(card.size.x, card.size.x * tan(L1CardFace.point_angle()) / 2.0)
	return Rect2i(Vector2i(at + shoulder + Vector2(1, -2)), Vector2i(3, 3))


## The mean difference, 0 to 255 over the three channels, between two regions of the shot.
static func _difference(shot: Image, a: Rect2i, b: Rect2i) -> float:
	var total: float = 0.0
	for y: int in a.size.y:
		for x: int in a.size.x:
			var p: Color = shot.get_pixel(a.position.x + x, a.position.y + y)
			var q: Color = shot.get_pixel(b.position.x + x, b.position.y + y)
			total += absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)
	return total / (3.0 * a.size.x * a.size.y) * 255.0
