extends Mechanic
## Air Marshal, Charge `limit` (`golden_limit` for a golden): after a friendly reservist steps
## in, it attacks immediately (Combat.attack_now). A use is refunded if the reservist couldn't.


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.THRESHOLD, "golden_limit": MechanicParams.Kind.THRESHOLD}


func on_fight_enter(
	combat: Combat, unit: CombatUnit, entered: CombatUnit, params: MechanicParams
) -> void:
	const ID: StringName = &"pigeon_air_marshal"
	var limit: int = params.num(&"golden_limit" if params.golden else &"limit")
	if entered.side != unit.side or not entered.reservist or entered.gone or entered.should_die():
		return
	if unit.fight_count(ID) < limit and combat.trigger(unit, ID):
		unit.add_fight_count(ID)
		if not combat.attack_now(entered):
			unit.add_fight_count(ID, -1)
