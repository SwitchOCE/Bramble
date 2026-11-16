extends Mechanic
## Lends its Health to the units in front of it: extra maximum Health (an aura, 12.2.1; borrowed
## stats). When this leaves, the extra goes but never takes a unit below 1 (the core's rule for
## aura Health).
##
## Closest version: the design lends this unit's maximum Health as it stands. AuraContext shows
## an aura only the card defs on the board, so this lends the printed Health (doubled on a
## golden: `times` is 2 there). See lend_attack.gd.


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
	return Vector2i(0, lender.health * params.num(&"times"))
