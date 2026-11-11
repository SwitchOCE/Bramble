extends RefCounted
## One formation anchor in every phase. Canvas height is 1080; wide phones gain side space.

const UNIT := Vector2(176, 226)
const BOARD := Vector2(820, 510)
const MARKET := Vector2(1400, 414)
const TOP: float = 16.0
const LOW: float = 554.0


static func board_rect(canvas: Vector2, opponent: bool = false) -> Rect2:
	return Rect2(Vector2((canvas.x - BOARD.x) / 2.0, TOP if opponent else LOW), BOARD)


static func market_rect(canvas: Vector2) -> Rect2:
	return Rect2(
		Vector2((canvas.x - MARKET.x) / 2.0, TOP), Vector2(MARKET.x, 326.0 + control_height(canvas))
	)


static func control_height(canvas: Vector2) -> float:
	return 122.0 if canvas.x / maxf(canvas.y, 1.0) > 2.0 else 88.0


static func hand_rect(canvas: Vector2) -> Rect2:
	return Rect2(Vector2(board_rect(canvas).position.x - 420.0, LOW), Vector2(392, 510))


static func hero_rect(canvas: Vector2, opponent: bool = false) -> Rect2:
	return Rect2(
		Vector2(board_rect(canvas).end.x + 36.0, 150 if opponent else 650), Vector2(270, 140)
	)


static func lobby_rect(canvas: Vector2) -> Rect2:
	return Rect2(canvas.x - 134.0, 24, 122, 1032)


## Supply sizes through the board's existing public geometry, without changing its row packing.
static func size_board(board: Control, zone: String, front_on_top: bool) -> void:
	board.set("compact", true)
	board.set("surface_visible", false)
	board.call("configure", zone, 195.0, front_on_top, false, false, BOARD.y)
	board.update_minimum_size()
	board.size = board.call("tray_size")


## Preserve the board's slot centres when a face is sized independently of its legacy ratio.
static func fit_cards(board: Control) -> void:
	for card: Control in board.get("cards"):
		if card == null:
			continue
		card.call("set_card_size", UNIT)


static func place_board(board: Control, canvas: Vector2, opponent: bool = false) -> void:
	var frame: Rect2 = board_rect(canvas, opponent)
	board.update_minimum_size()
	board.size = board.call("tray_size")
	board.position = frame.position + (frame.size - board.size) / 2.0
