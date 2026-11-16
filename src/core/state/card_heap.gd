class_name CardHeap
extends RefCounted
## A player's named list of card entries kept for the game (a pile, a graveyard, a heap that
## cards count or spend from). Entries are card ids with their tier, oldest first. Entries hold
## no pool copies: adding never takes from the pool and spending never gives back.

## Each entry: {"id": StringName, "tier": int}.
var entries: Array[Dictionary] = []


func size() -> int:
	return entries.size()


func add(card_id: StringName, tier: int) -> void:
	entries.append({"id": card_id, "tier": tier})


## Removes the `count` lowest-tier entries, oldest first on a tie. With fewer than `count`
## entries nothing is removed and the result is empty. Returns the removed ids.
func spend_lowest(count: int) -> Array[StringName]:
	var out: Array[StringName] = []
	if count <= 0 or count > entries.size():
		return out
	for _i: int in count:
		var best: int = 0
		for i: int in entries.size():
			if _tier(i) < _tier(best):
				best = i
		out.append(StringName(str(entries[best]["id"])))
		entries.remove_at(best)
	return out


## Removes and returns the highest-tier entry, newest first on a tie; &"" when empty.
func take_highest() -> StringName:
	if entries.is_empty():
		return &""
	var best: int = entries.size() - 1
	for i: int in range(entries.size() - 1, -1, -1):
		if _tier(i) > _tier(best):
			best = i
	var card_id := StringName(str(entries[best]["id"]))
	entries.remove_at(best)
	return card_id


func _tier(index: int) -> int:
	return CoreUtil.to_int(entries[index]["tier"])


func duplicate_heap() -> CardHeap:
	var copy := CardHeap.new()
	for entry: Dictionary in entries:
		copy.entries.append(entry.duplicate())
	return copy


## JSON-shaped: entries oldest first.
func view() -> Array:
	return entries.map(
		func(e: Dictionary) -> Dictionary: return {"id": str(e["id"]), "tier": e["tier"]}
	)
