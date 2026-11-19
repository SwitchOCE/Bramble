extends Mechanic
## Sett Sexton: after a unit in front of this gains Attack from Fury, it gains +amount Attack
## permanently, `limit` times a fight for each unit (a cap: golden doubles the amount, not the
## limit). The gain is made in BadgerRules.sexton_pays, right after the Fury buff that earned it.
## Balance pass 1 (19 Nov 2026) replaced its old effect (Fury for the Badgers after a death).


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER, "limit": MechanicParams.Kind.THRESHOLD}
