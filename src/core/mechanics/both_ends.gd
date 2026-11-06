extends Mechanic
## Both Ends (library entry 45): while another Both Ends unit is at the other end of this unit's
## row (F1 and F4, or B1 and B3), this has +`attack`/+`health`. Whenever an enemy attacks the
## partner, this first deals `prick` effect damage to the attacker; if that kills it, the attack
## doesn't happen (SPEC 4.2).


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	if _partner(combat, unit) == null:
		return Vector2i.ZERO
	return Vector2i(
		CoreUtil.to_int(params.get("attack", 0)), CoreUtil.to_int(params.get("health", 0))
	)


func on_attack_declared(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit, defender: CombatUnit
) -> void:
	if attacker.side == unit.side or not attacker.on_board or attacker.health <= 0:
		return
	if _partner(combat, unit) != defender:
		return
	combat.trigger(unit, "both_ends")
	combat.deal_effect_damage(unit, attacker, CoreUtil.to_int(params.get("prick", 0)))


static func _partner(combat: Combat, unit: CombatUnit) -> CombatUnit:
	var other_slot: int = BoardGeometry.row_end_partner(unit.slot)
	if other_slot < 0:
		return null
	var other: CombatUnit = combat.unit_at(unit.side, other_slot)
	if other == null or not other.has_mechanic("both_ends"):
		return null
	return other
