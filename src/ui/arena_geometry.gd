extends RefCounted
## One height-fitted hex formation in every phase; wide phones gain side-column space.

const UNIT := Vector2(201, 201.0 / 0.78)
const BOARD := Vector2(1035, 522)
const MARKET := Vector2(7 * UNIT.x + 6 * 16 + 64, 80 + UNIT.y + 8 + 88 + 12)
const TOP: float = 16.0
const LOW: float = TOP + BOARD.y + 12.0


static func board_rect(canvas: Vector2, opponent: bool = false) -> Rect2:
	return Rect2(Vector2((canvas.x - BOARD.x) / 2.0, TOP if opponent else LOW), BOARD)


static func market_rect(canvas: Vector2) -> Rect2:
	var height: float = 80 + UNIT.y + 8 + control_height(canvas) + 12
	return Rect2(Vector2((canvas.x - MARKET.x) / 2.0, LOW - 12 - height), Vector2(MARKET.x, height))


static func control_height(canvas: Vector2) -> float:
	return 122.0 if canvas.x / maxf(canvas.y, 1.0) > 2.0 else 88.0


static func hand_rect(canvas: Vector2) -> Rect2:
	var width: float = 2 * UNIT.x + 12 + 8
	var left: float = board_rect(canvas).position.x - width - 12
	if canvas.x / maxf(canvas.y, 1.0) > 2.0:
		left = 64.0
		width = board_rect(canvas).position.x - left - 12
	return Rect2(Vector2(left, LOW - 12), Vector2(width, 2 * UNIT.y + 12 + 8))


static func side_width(canvas: Vector2) -> float:
	return clampf(lobby_rect(canvas).position.x - board_rect(canvas).end.x - 36, 270, 400)


static func hero_rect(canvas: Vector2, opponent: bool = false) -> Rect2:
	return Rect2(
		Vector2(board_rect(canvas).end.x + 24.0, 150.0 if opponent else LOW + 96.0),
		Vector2(side_width(canvas), 140)
	)


static func lobby_rect(canvas: Vector2) -> Rect2:
	return Rect2(canvas.x - 134.0, 24, 122, 1032)


## Native hex packing owns the pocket, row stride, input contour and unit face size.
static func size_board(board: Control, zone: String, front_on_top: bool) -> void:
	board.set("compact", true)
	board.set("surface_visible", false)
	board.call("configure", zone, 222.0, front_on_top, false, false, BOARD.y)
	board.update_minimum_size()
	board.size = board.call("tray_size")


static func place_board(board: Control, canvas: Vector2, opponent: bool = false) -> void:
	var frame: Rect2 = board_rect(canvas, opponent)
	board.update_minimum_size()
	board.size = board.call("tray_size")
	board.position = frame.position + (frame.size - board.size) / 2.0
