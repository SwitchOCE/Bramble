extends "res://tests/ui/shots/look_movie.gd"
## A repeatable recruit turn through real pointer events, with reader evidence at native sizes.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const FeelFixture := preload("res://tests/ui/shots/declutter_cold_fixture.gd")
var _pointer: Vector2


func _run(_screen_name: String, window_size: Vector2i, out_path: String) -> void:
	await process_frame
	var app := App.new()
	root.add_child(app)
	app.setup(FeelFixture.make("ooze"))
	app.show_recruit()
	await _shoot(window_size, out_path)


func _move(at: Vector2, held: bool = false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	event.relative = at - _pointer
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.warp_mouse(at)
	root.push_input(event, true)
	_pointer = at


func _button(down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = _pointer
	event.global_position = _pointer
	root.push_input(event, true)


func _click(control: Control) -> void:
	_move(control.get_global_rect().get_center())
	_button(true)
	_button(false)


func _drag(from: Control, to: Control) -> void:
	var start: Vector2 = from.get_global_rect().get_center()
	var end: Vector2 = to.get_global_rect().get_center()
	_move(start)
	await _movie_frames(2)
	_button(true)
	await _movie_frames(2)
	for step: int in range(1, 25):
		_move(start.lerp(end, step / 24.0), true)
		await _movie_frames(1)
	_button(false)
	await _movie_frames(14)


func _movie_actions(app: App) -> void:
	var screen: RecruitScreen = app.current as RecruitScreen
	var board: BoardView = screen.get("_board")
	await _movie_frames(10)
	_click(screen._card_at("shop", 1))
	await _movie_frames(24)
	var label: String = "phone" if DisplayServer.window_get_size().x == 1688 else "pc"
	root.get_texture().get_image().save_png("res://build/loop1/recruit-feel/reader-%s.png" % label)
	var detail: CardDetail = screen.get("_detail")
	_move(screen._stage.get_global_transform() * Vector2(12, 12))
	_button(true)
	_button(false)
	await _movie_frames(8)
	await _drag(screen._card_at("shop", 0), board.slots[2])
	await _drag(screen._card_at("shop", 0), screen._hand_zone)
	await _drag(screen._card_at("hand", 0), board.slots[1])
	await _drag(screen._card_at("board", 2), board.slots[0])
	await _drag(screen._card_at("board", 0), screen._shop_zone)
	# Keep the tap alternative in the same evidence turn.
	_click(screen._card_at("shop", 0))
	await _movie_frames(8)
	_click(detail.actions.get_child(0) as Control)
	await _movie_frames(16)
	_click(screen._card_at("hand", 0))
	await _movie_frames(8)
	_click(board.slots[4])
	await _movie_frames(20)
	_click(screen._end_button)
	await _movie_frames(20)
	var script: Script = app.current.get_script()
	print("recruit-feel turn completed: ", script.resource_path)
