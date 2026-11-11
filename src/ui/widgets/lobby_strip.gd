extends Control
## The lobby across the top (.wr-lobby): one carved plaque per player with a tier knot, name and
## rosehip health. You are moss, the next opponent walnut with a red rim and Next prefix, and anyone
## out is struck through on a dashed, pale plaque. Reads SPEC 6.4 standings and next_opponent_id.

## The next opponent's plaque was tapped.
signal next_tapped
signal hero_requested(standing: Dictionary)

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Plaque := preload("res://src/ui/widgets/lobby_plaque.gd")

const HEIGHT: float = 122.0

## Each plaque's rectangle, for tests.
var plaques: Array[Control] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)
	ready.connect(_place)


## `ghost_owner_id`: whose board the ghost would be, marked as next when next_opponent_id is the
## ghost's (-1). There is no plaque of its own: it's that player's plaque, back for one more fight.
func show_standings(standings: Array, next_opponent_id: int, ghost_owner_id: int = -9) -> void:
	var positions: Dictionary = {}
	var health: Dictionary = {}
	for plaque: Control in plaques:
		var entry: Dictionary = plaque.get("_standing")
		var id: int = Data.i(entry, "player_id", -1)
		positions[id] = plaque.position
		health[id] = Data.i(entry, "health")
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
		plaque.next_requested.connect(func() -> void: next_tapped.emit())
		plaque.hero_requested.connect(
			func(details: Dictionary) -> void: hero_requested.emit(details)
		)
	_place()

	if not is_inside_tree() or preload("res://src/ui/settings.gd").reduce_motion:
		return
	for plaque: Control in plaques:
		var entry: Dictionary = plaque.get("_standing")
		var id: int = Data.i(entry, "player_id", -1)
		if positions.has(id) and positions[id] != plaque.position:
			var destination: Vector2 = plaque.position
			plaque.position = positions[id]
			create_tween().tween_property(plaque, "position", destination, 0.3)
		if health.has(id) and Data.as_int(health[id]) != Data.i(entry, "health"):
			var hip: Control = plaque.get("_hip")
			var label: Label = hip.get_child(0) as Label
			create_tween().bind_node(plaque).tween_method(
				func(value: int) -> void: label.text = str(value),
				Data.as_int(health[id]),
				maxi(0, Data.i(entry, "health")),
				0.3
			)


func _place() -> void:
	if plaques.is_empty():
		return
	var ordered: Array[Control] = plaques.duplicate()
	ordered.sort_custom(_ahead)
	var y: float = 0.0
	for plaque: Control in ordered:
		# Eliminated faces shrink inside the same easy-to-tap, non-overlapping seat.
		var height: float = 122.0
		plaque.position = Vector2(0, y)
		plaque.size = Vector2(122, height)
		y += height + 8.0


func _ahead(a: Control, b: Control) -> bool:
	var first: Dictionary = a.get("_standing")
	var second: Dictionary = b.get("_standing")
	var a_alive: bool = Data.b(first, "alive", true)
	var b_alive: bool = Data.b(second, "alive", true)
	if a_alive != b_alive:
		return a_alive
	var a_health: int = Data.i(first, "health")
	var b_health: int = Data.i(second, "health")
	return a_health > b_health
