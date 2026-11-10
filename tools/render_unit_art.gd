extends SceneTree
## Review-only portrait substitution; never changes the game's content or portrait lookup.
## Run with a real renderer through scripts/godot_slot.sh:
## godot -s tools/render_unit_art.gd -- current|v2 output.png

const Card := preload("res://src/ui/widgets/card_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const IDS: Array[String] = [
	"mrs_mallow",
	"lob_lie_by_the_fire",
	"wee_wobbly",
	"grey_agnes",
	"lantern_man",
	"mrs_jay",
	"toll_bard",
	"pill_bug",
]
const TRIBES: Array[String] = [
	"Hedgerow folk",
	"Fairies",
	"Oozes",
	"Hunters",
	"Bog folk",
	"Birds",
	"Hunters",
	"Neutral",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] not in ["current", "v2"]:
		printerr("usage: -- current|v2 output.png")
		quit(2)
		return
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
	var ground := ColorRect.new()
	ground.color = Color("45564a")
	ground.size = Vector2(1920, 1080)
	root.add_child(ground)
	for index: int in IDS.size():
		var card := Card.new()
		root.add_child(card)
		(
			card
			. show_unit(
				{
					"def_id": IDS[index],
					"kind": "unit",
					"name": IDS[index],
					"tribes": [] if TRIBES[index] == "Neutral" else [TRIBES[index]],
					"attack": 7,
					"health": 17,
					"max_health": 17,
				}
			)
		)
		card.set_card_size(Vector2(270, 297))
		card.position = Vector2(210 + index % 4 * 400, 130 + floori(index / 4.0) * 460)
		if args[0] == "v2":
			var path: String = "res://assets/portraits_v2/%s.jpg" % IDS[index]
			var portrait := Image.load_from_file(path)
			if portrait == null:
				printerr("missing sample: ", path)
				quit(2)
				return
			card._art.texture = ImageTexture.create_from_image(portrait)
		var label := UiTheme.label(IDS[index] + "\n" + TRIBES[index], 27, Color("f4e8ca"))
		label.position = card.position + Vector2(-20, 340)
		label.size = Vector2(340, 80)
		root.add_child(label)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png(args[1])
	quit(0 if result == OK else 1)
