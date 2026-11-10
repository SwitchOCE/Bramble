extends RefCounted
## Older captures can contain setup events before the authoritative starting snapshot.


static func start(events: Array) -> Dictionary:
	for value: Variant in events:
		if value is Dictionary:
			var event: Dictionary = value
			if event.get("type", "") == "combat_start":
				return event
	return {}


## Unknown identity is not side zero. Callers must handle -1 before displaying a real fight.
static func side(start_event: Dictionary, player_id: int) -> int:
	var value: Variant = start_event.get("player_ids")
	if not value is Array:
		return -1
	var ids: Array = value
	if ids.size() != 2:
		return -1
	for index: int in 2:
		if not (ids[index] is int or ids[index] is float):
			return -1
		if CoreUtil.to_int(ids[index]) == player_id:
			return index
	return -1
