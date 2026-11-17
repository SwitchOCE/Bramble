extends Control
## Rendered regression: run with Compatibility under Xvfb, not the headless dummy renderer.
## -- --out=/path optionally --old-shader=/path tests the exact original shader without edits.

const PHASES: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]
const NORMAL: Rect2i = Rect2i(50, 145, 240, 360)
const HALO_A: Rect2i = Rect2i(385, 245, 12, 150)
const HALO_B: Rect2i = Rect2i(685, 245, 12, 150)
var _glows: Array[GlassDuplicateGlow] = []


func _ready() -> void:
	var out: String = "/tmp/bramble-dupes-pixels"
	var old_shader: Shader = null
	for arg: String in OS.get_cmdline_user_args():
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
	var report: Dictionary = {
		"phases": PHASES, "a": values_a, "b": values_b, "normal_unchanged": true
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
	var file: FileAccess = FileAccess.open(out.path_join("pixels.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, " "))
	file.close()
	var passed: bool = (
		values_a[0] - values_a[2] > 1.0
		and values_b[0] - values_b[2] > 1.0
		and absf(values_a[0] - values_a[4]) < 0.1
		and absf(values_b[0] - values_b[4]) < 0.1
		and report["normal_unchanged"] == true
	)
	print("dupes_pixels: ", "PASS " if passed else "FAIL ", JSON.stringify(report))
	get_tree().quit(0 if passed else 1)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1920, 1080)), Color("15151a"))


static func _brightness(shot: Image, region: Rect2i) -> float:
	var sum: float = 0.0
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			sum += shot.get_pixel(x, y).get_luminance() * 255.0
	return sum / region.get_area()
