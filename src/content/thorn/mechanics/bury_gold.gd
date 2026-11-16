extends "res://src/content/thorn/bury_base.gd"
## Bury: Gain N gold (Hedge Layer).


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func mechanic_id() -> StringName:
	return &"thorn_bury_gold"


func bury_effect(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	ctx.gain_gold(params.num(&"amount"), unit)
