class_name Matchmaker
extends RefCounted
## Picks a game's seven opponents. The interface a server version replaces
## (docs/workstreams/third-run/ghost-server-plan.md); LocalMatchmaker is the local one.


## Return {"ok": true, "ids": [7 run ids in seat order]} or {"ok": false, "message": ...}.
## band accepts store filters such as kinds, labels and inclusive placement bounds.
## exclude is a set of run ids.
func pick(
	_store: GhostStore, _rules_hash: String, _band: Dictionary, _exclude: Dictionary, _rng: Rng
) -> Dictionary:
	return {"ok": false, "message": "Matchmaker.pick is not implemented"}
