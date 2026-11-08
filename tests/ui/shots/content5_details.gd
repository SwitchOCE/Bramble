extends SceneTree
## Two real CardDetail readers with their Details slips open, for wording inspection.
##   xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy \
##     -s res://tests/ui/shots/content5_details.gd -- <WxH> <out.png>

const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("usage: -- <WxH> <out.png>")
		quit(2)
		return
	var dims: PackedStringArray = args[0].split("x")
	var window_size := Vector2i(int(dims[0]), int(dims[1]))
	DisplayServer.window_set_size(window_size)
	root.size = window_size
	CardView.window_override = Vector2(window_size)
	@warning_ignore("missing_await")
	_render(window_size, args[1])


func _render(window_size: Vector2i, out_path: String) -> void:
	await process_frame
	var stage := Control.new()
	stage.theme = UiTheme.get_theme()
	root.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var canvas: Vector2 = stage.get_viewport_rect().size
	var background := ColorRect.new()
	background.color = UiTheme.BG
	background.size = canvas
	stage.add_child(background)
	var title: Label = UiTheme.head("Content5: card details", UiTheme.FONT_TITLE)
	title.position = Vector2(48, 18)
	title.size = Vector2(canvas.x - 96, 64)
	stage.add_child(title)
	var phone: bool = CardView.is_phone()
	var ids: PackedStringArray = (
		PackedStringArray(["redwing", "market_stall"])
		if phone
		else PackedStringArray(["horseshoe", "barn_owl"])
	)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var width: float = minf(720.0, (canvas.x - 144.0) / 2.0)
	var left: float = (canvas.x - width * 2.0 - 48.0) / 2.0
	for index: int in ids.size():
		var detail: CardDetail = CardDetail.new()
		stage.add_child(detail)
		detail.position = Vector2(left + index * (width + 48.0), 104)
		detail.size = Vector2(width, canvas.y - 128.0)
		var card: Dictionary = library.get_card(ids[index])
		var view: Dictionary
		if str(card.get("kind", "")) == "spell":
			view = HandItem.make(card, index + 1).view()
		else:
			view = UnitViews.from_def(library.get_unit(ids[index]), phone)
		detail.show_unit(view)
		detail.reminder.show_keyword(CardDetail.DETAILS)
		if not detail.reminder.visible:
			printerr("content5_details: no Details for %s" % ids[index])
			quit(1)
			return
	for _frame: int in 20:
		await process_frame
	var problems: PackedStringArray = LayoutCheck.problems(stage, "content5 details")
	if not problems.is_empty():
		for problem: String in problems:
			printerr(problem)
		quit(1)
		return
	var image: Image = root.get_texture().get_image()
	if image.get_size() != window_size:
		printerr("content5_details: got %s, wanted %s" % [image.get_size(), window_size])
		quit(1)
		return
	var result: Error = image.save_png(out_path)
	print("content5_details: %s %s, layout clean" % [out_path, window_size])
	quit(0 if result == OK else 1)
