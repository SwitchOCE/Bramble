extends Control
## Rendered regression: run with Compatibility under Xvfb, not the headless dummy renderer.
## -- --out=/path optionally --old-shader=/path tests the exact original shader without edits.

const PHASES: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]
const NORMAL: Rect2i = Rect2i(50, 145, 240, 360)
const HALO_A: Rect2i = Rect2i(385, 245, 12, 150)
const HALO_B: Rect2i = Rect2i(685, 245, 12, 150)
const FOIL_FACE: Rect2i = Rect2i(435, 250, 70, 90)
const FOIL_STATS: Rect2i = Rect2i(415, 380, 20, 20)
const FOIL_HEALTH: Rect2i = Rect2i(505, 380, 20, 20)
const FOIL_PRICE: Rect2i = Rect2i(450, 457, 40, 40)
const FOIL_CORNER: Rect2i = Rect2i(400, 195, 15, 15)
const MATCH_FACE: Rect2i = Rect2i(1035, 250, 70, 90)
const HALO_MATCH: Rect2i = Rect2i(985, 245, 12, 150)
var _glows: Array[GlassDuplicateGlow] = []


func _ready() -> void:
	var out: String = "/tmp/bramble-dupes-pixels"
	var old_shader: Shader = null
	var freeze_foil: bool = false
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--freeze-foil":
			freeze_foil = true
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg.begins_with("--old-shader="):
			old_shader = Shader.new()
			old_shader.code = FileAccess.get_file_as_string(arg.trim_prefix("--old-shader="))
	DirAccess.make_dir_recursive_absolute(out)
	var source: RecruitScreen = RecruitScreen.new()
	source.state = GlassScreen.load_state("res://tests/screens/fixtures/shop_review.json")
	source._g = RecruitShop.geometry()
	var cards: Array = source.state["shop_units"]
	var data: Dictionary = cards[3]
	for i: int in 4:
		var card: GlassCard = source._unit_card(data, 250.0)
		card.position = Vector2(100.0 + 300.0 * i, 195.0)
		add_child(card)
		var layers: Array[Control] = card._shadows.duplicate()
		if i > 0:
			var mark: int = 1 if i == 3 else 2
			var glow: GlassDuplicateGlow = GlassDuplicateGlow.apply(card, mark)
			glow.candidate = 1 if i == 2 else 0
			_glows.append(glow)
			layers.append_array(glow._layers)
		if old_shader != null:
			for layer: Control in layers:
				var mat: ShaderMaterial = ShaderMaterial.new()
				mat.shader = old_shader
				layer.material = mat
	source.free()
	var values_a: Array[float] = []
	var values_b: Array[float] = []
	var values_match: Array[float] = []
	var report: Dictionary = {
		"phases": PHASES,
		"a": values_a,
		"b": values_b,
		"match": values_match,
		"normal_unchanged": true
	}
	var normal: Image = null
	for i: int in PHASES.size():
		for glow: GlassDuplicateGlow in _glows:
			glow.set_phase(PHASES[i] * GlassDuplicateGlow.PERIODS[glow.candidate])
		# Two drawn frames include first-time shader/material setup and parameter upload.
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot: Image = get_viewport().get_texture().get_image()
		shot.save_png(out.path_join("phase-%d.png" % i))
		var current: Image = shot.get_region(NORMAL)
		if normal == null:
			normal = current
			normal.save_png(out.path_join("normal.png"))
		elif normal.get_data() != current.get_data():
			report["normal_unchanged"] = false
		values_a.append(_brightness(shot, HALO_A))
		values_b.append(_brightness(shot, HALO_B))
		values_match.append(_brightness(shot, HALO_MATCH))
	report["foil"] = await _foil_pixels(out, freeze_foil)
	var file: FileAccess = FileAccess.open(out.path_join("pixels.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, " "))
	file.close()
	var passed: bool = (
		values_a[0] - values_a[2] > 8.0
		and values_b[0] - values_b[2] > 20.0
		and absf(values_a[0] - values_a[4]) < 0.1
		and absf(values_b[0] - values_b[4]) < 0.1
		and values_a.min() > 65.0
		and values_b.min() > 48.0
		and values_match.min() > 60.0
		and values_match.max() - values_match.min() < 0.1
		and report["normal_unchanged"] == true
		and report["foil"]["passed"] == true
	)
	print("dupes_pixels: ", "PASS " if passed else "FAIL ", JSON.stringify(report))
	get_tree().quit(0 if passed else 1)


## Hold the rim still and compare rendered face pixels, so a breathing halo cannot fake motion.
## --freeze-foil is a negative control: it must fail even while the halo regression still passes.
func _foil_pixels(out: String, freeze: bool) -> Dictionary:
	for glow: GlassDuplicateGlow in _glows:
		glow.set_phase(0.0)
	var foil: GlassTripleFoil = _glows[0]._foil
	RecruitShop.dress_card(foil.get_parent() as GlassCard, {"price": 2}, false)
	foil.hide()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var bare: Image = get_viewport().get_texture().get_image()
	foil.show()
	var shots: Array[Image] = []
	var protected: bool = true
	for i: int in PHASES.size():
		foil.set_phase(0.0 if freeze else PHASES[i] * GlassTripleFoil.PERIOD)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var shot: Image = get_viewport().get_texture().get_image()
		shot.save_png(out.path_join("foil-%d.png" % i))
		shots.append(shot)
		for region: Rect2i in [
			FOIL_STATS, FOIL_HEALTH, FOIL_PRICE, FOIL_CORNER, MATCH_FACE, NORMAL
		]:
			protected = protected and _difference(bare, shot, region) == 0.0
	var motion: float = _difference(shots[0], shots[1], FOIL_FACE)
	var strength: float = _difference(bare, shots[0], FOIL_FACE)
	var loop: float = _difference(shots[0], shots[4], FOIL_FACE)
	var reverse: float = _difference(shots[1], shots[3], FOIL_FACE)
	return {
		"motion_delta": motion,
		"face_delta": strength,
		"loop_delta": loop,
		"reverse_delta": reverse,
		"protected_unchanged": protected,
		"passed": motion > 12.0 and strength > 12.0 and loop < 0.1 and reverse < 0.1 and protected
	}


static func _difference(a: Image, b: Image, region: Rect2i) -> float:
	var total: float = 0.0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			var before: Color = a.get_pixel(x, y)
			var after: Color = b.get_pixel(x, y)
			total += absf(before.r - after.r) + absf(before.g - after.g) + absf(before.b - after.b)
	return total * 255.0 / (region.get_area() * 3.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("15151a"))


static func _brightness(shot: Image, region: Rect2i) -> float:
	var sum: float = 0.0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			sum += shot.get_pixel(x, y).get_luminance() * 255.0
	return sum / region.get_area()
