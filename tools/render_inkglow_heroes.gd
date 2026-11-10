extends SceneTree
## Review only: real lobby plaques with 70px round portraits, current beside inkglow.
## scripts/godot_slot.sh xvfb-run -a godot --rendering-driver opengl3
## --audio-driver Dummy -s tools/render_inkglow_heroes.gd -- output.png

const Lobby := preload("res://src/ui/widgets/lobby_plaque.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const IDS: Array[String] = ["dame_hoolet", "brother_bracken"]
const NAMES: Array[String] = ["Dame Hoolet", "Brother Bracken"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("usage: -- output.png")
		quit(2)
		return
	DisplayServer.window_set_size(Vector2i(760, 350))
	root.size = Vector2i(760, 350)
	root.content_scale_size = Vector2i(760, 350)
	var ground := ColorRect.new()
	ground.color = Color("45564a")
	ground.size = Vector2(760, 350)
	root.add_child(ground)
	var title := UiTheme.label("Real lobby chips: 70px portraits", 25, UiTheme.CREAM)
	title.position = Vector2(25, 12)
	root.add_child(title)
	for index: int in IDS.size():
		var name_label := UiTheme.label(NAMES[index], 23, UiTheme.CREAM)
		name_label.position = Vector2(25, 80 + index * 130)
		root.add_child(name_label)
		for variant: int in 2:
			var plaque := Lobby.new(
				{"hero": NAMES[index], "name": "Review", "health": 40, "tier": 3}, false
			)
			root.add_child(plaque)
			plaque.position = Vector2(290 + variant * 230, 65 + index * 130)
			plaque.size = Vector2(110, 70)
			if variant == 1:
				var path: String = "res://assets/portraits_inkglow/%s.jpg" % IDS[index]
				var image := Image.load_from_file(ProjectSettings.globalize_path(path))
				if image == null:
					printerr("missing hero review: ", path)
					quit(2)
					return
				plaque._portrait.texture = ImageTexture.create_from_image(image)
			var label := UiTheme.label("Current" if variant == 0 else "Inkglow", 20, UiTheme.CREAM)
			label.position = plaque.position + Vector2(20, 85)
			root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(args[0])
	quit(0 if result == OK else 1)
