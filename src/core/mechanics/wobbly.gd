extends HitReactor
## Wee Wobbly: after this survives a hit, the unit inside comes out in the nearest gap; with nobody
## inside it summons a Drip. `limit` times a fight.


func hit_counter() -> String:
	return "wobbly_hit"


func after_hit(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var used: int = CoreUtil.to_int(unit.counters.get("wobbly", 0))
	var slot: int = BoardGeometry.summon_slot(combat._occupied(unit.side), unit.slot, false)
	if (
		not CoreUtil.to_bool(params.get("pass3", false))
		and used >= CoreUtil.to_int(params.get("limit", 2))
	):
		return
	if slot < 0:
		var held: bool = not unit.held_specs.is_empty()
		(
			combat
			. emit_event(
				"no_room",
				{
					"uid": unit.uid,
					"side": unit.side,
					"def_id":
					str(unit.held_specs.back()["def_id"]) if held else str(params.get("unit", "")),
					"outcome": "stays_inside" if held else "",
				}
			)
		)
		return
	unit.counters["wobbly"] = used + 1
	combat.trigger(unit, "wobbly")
	if unit.held_specs.is_empty():
		var spec: Dictionary = {"def_id": str(params.get("unit", "")), "golden": unit.golden}
		if CoreUtil.to_bool(params.get("pass3", false)):
			spec["attack"] = CoreUtil.to_int(params.get("drip", 1))
			spec["health"] = CoreUtil.to_int(params.get("drip", 1))
		combat.enter_from_spec(spec, unit.side, slot, unit, {"wobbly_drip": true})
	elif CoreUtil.to_bool(params.get("pass3", false)):
		var releasing: int = unit.held_specs.size()
		for _time: int in releasing:
			if not unit.on_board or unit.is_dead() or unit.held_specs.is_empty():
				break
			if BoardGeometry.summon_slot(combat._occupied(unit.side), unit.slot, false) < 0:
				combat.emit_event(
					"no_room",
					{
						"uid": unit.uid,
						"side": unit.side,
						"def_id": str(unit.held_specs.back()["def_id"]),
						"outcome": "stays_inside"
					}
				)
				break
			CombatHeld.pop_one(combat, unit, false)
	else:
		CombatHeld.pop_one(combat, unit, false)
	combat._resolve_deaths(unit.side)
