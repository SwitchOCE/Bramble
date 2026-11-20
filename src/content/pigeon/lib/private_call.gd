extends Mechanic
## Remember only deaths this officer witnessed. Resolve after hand reserves and waiting summons.


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, _params: MechanicParams
) -> void:
	if accepts(combat, unit, dead):
		var slots: Array = combat.arrivals.witnessed.get(unit.uid, [])
		slots.append(dead.slot)
		combat.arrivals.witnessed[unit.uid] = slots


func accepts(_combat: Combat, _unit: CombatUnit, _dead: CombatUnit) -> bool:
	return true


func mechanic_id() -> StringName:
	return &"pigeon_bugler"


func after_death_round(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var slots: Array = combat.arrivals.witnessed.get(unit.uid, [])
	combat.arrivals.witnessed.erase(unit.uid)
	var id: StringName = mechanic_id()
	var uses_key: StringName = StringName("%s_uses" % id)
	var limit: int = params.num(&"limit")
	# Proposal: spend scarce Charge on the Guard post first among simultaneous deaths,
	# then follow the order in which the officer witnessed the remaining deaths.
	var post: int = combat.side_query(unit.side, Q_FILL_FIRST, -1)
	if slots.has(post):
		slots.erase(post)
		slots.push_front(post)
	for raw: Variant in slots:
		var slot: int = CoreUtil.to_int(raw)
		if unit.gone or unit.should_die() or combat.halted() or unit.fight_count(id) >= limit:
			return
		if combat.unit_at(unit.side, slot) == null and combat.trigger(unit, id):
			unit.add_fight_count(id)
			combat.show_uses(unit, uses_key, limit - unit.fight_count(id), unit)
			combat.step_in(unit.side, &"private", slot, unit)
