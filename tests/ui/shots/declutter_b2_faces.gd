extends SceneTree
## Every native unit through the real smallest resting board face; no invented art or labels.
const UnitViews := preload("res://src/ui/unit_views.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const COLUMNS: int = 10
var _out: String


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	assert(args.size() == 1, "usage: -- <batch2 output>")
	_out = args[0]
	_run.call_deferred()


func _run() -> void:
	var board: BoardView = BoardView.new()
	board.configure("board", 209, true, false, false)
	var tile_size: Vector2 = (
		CardView.size_for(board.tile_width(), CardView.Mode.BOARD) + Vector2(0, 40)
	)
	board.free()
	var cell: Vector2 = tile_size + Vector2(30, 32)
	var units: Array[Dictionary] = UnitLibrary.load_dir().all_units()
	var rows: int = ceili(float(units.size()) / COLUMNS)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(roundi(cell.x * COLUMNS), roundi(cell.y * rows))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = UiTheme.CREAM
	background.size = Vector2(viewport.size)
	viewport.add_child(background)
	var entries: Array[Dictionary] = []
	for index: int in units.size():
		var view: Dictionary = UnitViews.from_def(units[index], false, index + 1)
		var card: CardView = CardView.new()
		viewport.add_child(card)
		card.show_unit(view, CardView.Mode.BOARD)
		card.set_card_size(tile_size)
		card.position = (
			Vector2(index % COLUMNS, floori(float(index) / COLUMNS)) * cell + Vector2(15, 10)
		)
		var art: Control = card.get("_art")
		entries.append(
			{
				"index": index,
				"row": floori(float(index) / COLUMNS),
				"column": index % COLUMNS,
				"def_id": view["def_id"],
				"name": view["name"],
				"fallback_name_shown": CardView.needs_name(view),
				"art_rect_share": art.size.x * art.size.y / (tile_size.x * tile_size.y)
			}
		)
	for frame: int in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	assert(image.get_size() == viewport.size)
	assert(image.save_jpg(_out.path_join("all-unit-board-faces.jpg"), 0.85) == OK)
	var file := FileAccess.open(_out.path_join("all-unit-board-faces.json"), FileAccess.WRITE)
	file.store_string(
		JSON.stringify(
			{
				"tile_canvas": [tile_size.x, tile_size.y],
				"sheet_pixels": [viewport.size.x, viewport.size.y],
				"columns": COLUMNS,
				"unit_count": units.size(),
				"entries": entries
			},
			"\t",
			true,
			true
		)
	)
	print("declutter-b2 contact sheet: ", units.size(), " units at ", tile_size)
	root.remove_child(viewport)
	viewport.free()
	quit()
