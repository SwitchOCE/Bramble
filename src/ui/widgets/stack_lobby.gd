extends "res://src/ui/widgets/lobby_strip.gd"
## Compact standings rail. Presentation order follows standings without changing the lobby state.


func show_standings(standings: Array, next_opponent_id: int, ghost_owner_id: int = -9) -> void:
	var positions: Dictionary = {}
	var health: Dictionary = {}
	for plaque: Control in plaques:
		var entry: Dictionary = plaque.get("_standing")
		var id: int = Data.i(entry, "player_id", -1)
		positions[id] = plaque.position
		health[id] = Data.i(entry, "health")
	super(standings, next_opponent_id, ghost_owner_id)
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
