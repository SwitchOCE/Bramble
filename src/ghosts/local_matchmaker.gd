class_name LocalMatchmaker
extends Matchmaker
## The local matchmaker, a port of Rust's LocalMatchmaker. Select seven run IDs in seat order. band accepts labels and inclusive placement bounds.


func pick(
	store: GhostStore, rules_hash: String, band: Dictionary, exclude: Dictionary, rng: Rng
) -> Dictionary:
	var infos: Array[Dictionary] = (
		store
		. find(
			{
				"rules_hash": rules_hash,
				"labels": band.get("labels", []),
				"placement": band.get("placement"),
				"exclude": exclude,
			}
		)
	)
	if store.error != "":
		return {"ok": false, "message": store.error}
	infos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	var ids: Array[String] = []
	var seen_ids: Dictionary = {}
	var seen_seats: Dictionary = {}
	for info: Dictionary in infos:
		var id: String = info["id"]
		if seen_ids.has(id):
			continue
		seen_ids[id] = true
		if info["ended"] == "unfinished":
			continue
		var record: String = info["record_sha256"]
		var seat_key: String = "%s:%d" % [record, info["seat"]]
		if seen_seats.has(seat_key):
			continue
		if record != "":
			seen_seats[seat_key] = true
		ids.append(id)
	if ids.size() < 7:
		return {"ok": false, "message": "need 7 eligible ghost runs, found %d" % ids.size()}
	# Same first seven forward Fisher-Yates swaps as Rust.
	for i: int in 7:
		var j: int = rng.range_int(i, ids.size() - 1)
		var previous: String = ids[i]
		ids[i] = ids[j]
		ids[j] = previous
	return {"ok": true, "ids": ids.slice(0, 7)}
