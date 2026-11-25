class_name SlotLayer
extends Control
## Permanent slot backings, described only by their geometry and lasting bonuses. Cards and
## their motion live on the next layer. An unchanged slot keeps its node across screen redraws.

var _counts: Dictionary = {}


func set_row(
	prefix: String,
	places: Array[Vector2],
	box: Vector2,
	bonuses: Array[Dictionary] = [],
	make_slot: Callable = GlassSlot.make
) -> void:
	for i: int in places.size():
		var id: String = "%s%d" % [prefix, i]
		var info: Dictionary = bonuses[i] if i < bonuses.size() else {}
		var slot: GlassBox = get_node_or_null(id) as GlassBox
		if slot != null and (slot.box_size != box or slot.get_meta("bonus") != info):
			remove_child(slot)
			slot.queue_free()
			slot = null
		if slot == null:
			slot = make_slot.call(info, box)
			slot.name = id
			slot.set_meta("bonus", info.duplicate(true))
			add_child(slot)
		slot.position = places[i]
	for i: int in range(places.size(), GlassPieces.as_int(_counts.get(prefix, 0))):
		var extra: Node = get_node("%s%d" % [prefix, i])
		remove_child(extra)
		extra.queue_free()
	_counts[prefix] = places.size()
