extends Control
## The lobby across the top (.wr-lobby): one carved plaque per player with a tier knot, name and
## rosehip health. You are moss, the next opponent walnut with a red rim and a NEXT tag, and anyone
## out is struck through on a dashed, pale plaque. Reads SPEC 6.4 standings and next_opponent_id.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Plaque := preload("res://src/ui/widgets/lobby_plaque.gd")

const HEIGHT: float = 74.0
const GAP: float = 12.0

## Each plaque's rectangle, for tests.
var plaques: Array[Control] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)
	ready.connect(_place)


func show_standings(standings: Array, next_opponent_id: int) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	plaques.clear()
	for entry: Variant in standings:
		var standing: Dictionary = entry
		var is_next: bool = Data.i(standing, "player_id", -1) == next_opponent_id
		var plaque: Plaque = Plaque.new(standing, is_next)
		add_child(plaque)
		plaques.append(plaque)
	_place()


## Plaques size to their names (as the mock's flex row does) and share any slack; a name that can't
## fit is cut with an ellipsis, and when the row can't fit at all every plaque shrinks evenly.
func _place() -> void:
	if plaques.is_empty():
		return
	var total: float = 0.0
	var widths: Array[float] = []
	for plaque: Control in plaques:
		var wanted: float = (plaque as Plaque).wanted_width()
		widths.append(wanted)
		total += wanted
	var room: float = size.x - GAP * (plaques.size() - 1)
	var extra: float = minf((room - total) / plaques.size(), 36.0)
	var x: float = 0.0
	var shrink: float = minf(1.0, room / total) if total > 0.0 else 1.0
	for i: int in plaques.size():
		var width: float = widths[i] + extra if extra > 0.0 else widths[i] * shrink
		plaques[i].position = Vector2(x, 0)
		plaques[i].size = Vector2(width, HEIGHT)
		x += width + GAP
