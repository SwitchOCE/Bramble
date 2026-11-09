class_name PlantedEngine
extends RefCounted
## Test-only overlay. The default zero-growth call remains a no-op. Explicit null/reference
## modes install identical inert bodies so that the real null has a valid experimental control.


static func install(
	library: UnitLibrary, growth: int, mode: String = "engine", in_pool: bool = false
) -> Dictionary:
	assert(growth >= 0)
	assert(mode in ["engine", "null", "reference"])
	if mode == "engine" and growth == 0:
		return {}
	var is_engine: bool = mode == "engine"
	var card: Dictionary = {
		"id": "bench_engine_%d" % growth if is_engine else "bench_" + mode,
		"name": "Planted test engine",
		"set": "slice",
		"tier": 1,
		"attack": 1,
		"health": 1,
		"tribes": [],
		"text": "Test only: permanent growth each turn." if is_engine else "",
		"golden_text": "Test only." if is_engine else "",
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
		"pool": in_pool,
		"priority": null,
		"skeleton": false,
	}
	if not is_engine:
		card["mechanics"] = []
	assert(library.register_unit(card) == "")
	return card


static func spawn(session: GameSession, card: Dictionary, seat: int = 0) -> void:
	if card.is_empty() or CoreUtil.to_bool(card.get("pool", false)):
		return
	var player: PlayerState = session._players[seat]
	var unit := RecruitUnit.make(
		session._library.get_unit(str(card["id"])), session._rules.new_iid()
	)
	unit.origin = RecruitUnit.ORIGIN_CREATED
	player.hand.append(unit)
	assert(session._rules.play(player, player.hand.size() - 1, player.first_empty_slot()) == "")
