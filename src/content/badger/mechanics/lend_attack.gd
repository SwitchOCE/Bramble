extends Mechanic
## Lends its Attack to the units in front of it (an aura, 12.2.1; borrowed stats).
##
## Closest version: the design lends this unit's Attack as it stands (buffs, Grudge, its slot's
## buff). AuraContext shows an aura only the card defs on the board, not a unit's current stats,
## so this lends the printed Attack (doubled on a golden: `times` is 2 there). Reported to the
## core pass 4; the failing case is in tests/content/badger/test_badger_plans.gd (Lends).


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Vector2i:
	if source_slot < 0 or not view.geometry.in_front_of(source_slot).has(target_slot):
		return Vector2i.ZERO
	var lender: UnitDef = view.def_at(source_slot)
	if lender == null:
		return Vector2i.ZERO
	return Vector2i(lender.attack * params.num(&"times"), 0)
