class_name PlantedEngine
extends RefCounted
## Test-only library overlay. Zero is a literal no-op; no default pool or content file changes.


static func install(library: UnitLibrary, growth: int) -> Dictionary:
	assert(growth >= 0)
	if growth == 0:
		return {}
	var card: Dictionary = {
		"id": "bench_engine_%d" % growth,
		"name": "Planted test engine",
		"set": "slice",
		"tier": 1,
		"attack": 1,
		"health": 1,
		"tribes": [],
		"text": "Test only: permanent growth each turn.",
		"golden_text": "Test only.",
		"mechanics":
		[
			{
				"id": "effect",
				"trigger": "end_of_turn",
				"name": "bench_growth",
				"do":
				{
					"effect": "buff",
					"attack": growth,
					"health": growth,
					"permanent": true,
					"target": {"select": "self"}
				}
			}
		],
		"keywords": [],
		"row_hint": null,
		"pool": false,
		"priority": null,
		"skeleton": false,
	}
	assert(library.register_unit(card) == "")
	return card


static func spawn(session: GameSession, card: Dictionary, seat: int = 0) -> void:
	if card.is_empty():
		return
	var player: PlayerState = session._players[seat]
	var unit := RecruitUnit.make(
		session._library.get_unit(str(card["id"])), session._rules.new_iid()
	)
	unit.origin = RecruitUnit.ORIGIN_CREATED
	player.hand.append(unit)
	assert(session._rules.play(player, player.hand.size() - 1, player.first_empty_slot()) == "")
