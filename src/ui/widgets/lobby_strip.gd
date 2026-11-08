extends Control
## The lobby across the top (.wr-lobby): one carved plaque per player with a tier knot, name and
## rosehip health. You are moss, the next opponent walnut with a red rim and Next prefix, and anyone
## out is struck through on a dashed, pale plaque. Reads SPEC 6.4 standings and next_opponent_id.

## The next opponent's plaque was tapped.
signal next_tapped

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Plaque := preload("res://src/ui/widgets/lobby_plaque.gd")

const HEIGHT: float = 74.0
const GAP: float = 12.0
## Under this width (a desktop's canvas, never a phone's) names use DESKTOP_NAME.
const DESKTOP_WIDTH: float = 2000.0
const DESKTOP_NAME: int = 26

## Each plaque's rectangle, for tests.
var plaques: Array[Control] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)
	ready.connect(_place)


## `ghost_owner_id`: whose board the ghost would be, marked as next when next_opponent_id is the
## ghost's (-1). There is no plaque of its own: it's that player's plaque, back for one more fight.
func show_standings(standings: Array, next_opponent_id: int, ghost_owner_id: int = -9) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	plaques.clear()
	for entry: Variant in standings:
		var standing: Dictionary = entry
		var player_id: int = Data.i(standing, "player_id", -1)
		var ghost: bool = next_opponent_id == -1 and player_id == ghost_owner_id
		var is_next: bool = player_id == next_opponent_id or ghost
		var plaque: Plaque = Plaque.new(standing, is_next, ghost)
		add_child(plaque)
		plaques.append(plaque)
		if is_next:
			plaque.tap.tapped.connect(func(_zone: String, _index: int) -> void: next_tapped.emit())
	_place()


## Plaques size to both lines of the full name and the separate status tag, sharing any slack.
func _place() -> void:
	if plaques.is_empty():
		return
	var room: float = size.x - GAP * (plaques.size() - 1)
	if size.x > 10.0 and size.x < DESKTOP_WIDTH:
		for plaque: Control in plaques:
			(plaque as Plaque).use_desktop_size(DESKTOP_NAME)
	var total: float = 0.0
	var widths: Array[float] = []
	for plaque: Control in plaques:
		var wanted: float = (plaque as Plaque).wanted_width()
		widths.append(wanted)
		total += wanted
	var extra: float = minf((room - total) / plaques.size(), 36.0)
	var x: float = 0.0
	var most: float = _widest_allowed(widths, room)
	for i: int in plaques.size():
		var width: float = widths[i] + extra if extra > 0.0 else minf(widths[i], most)
		plaques[i].position = Vector2(x, 0)
		plaques[i].size = Vector2(width, HEIGHT)
		x += width + GAP


## The width no plaque may pass for the row to fit in `room`.
func _widest_allowed(widths: Array[float], room: float) -> float:
	var low: float = 0.0
	var high: float = room
	for step: int in 16:
		var cap: float = (low + high) / 2.0
		var total: float = 0.0
		for width: float in widths:
			total += minf(width, cap)
		if total > room:
			high = cap
		else:
			low = cap
	return low
