extends "res://src/content/thorn/lib/bury_base.gd"
## Bury: Give your Briars +N/+N permanently (Leafmould Carter, Old Mother Midden): every Briar on
## the board, this one included.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func mechanic_id() -> StringName:
	return &"thorn_bury_feed"


func bury_effect(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	var amount: int = params.num(&"amount")
	for briar: Unit in Compost.briars(ctx.player):
		ctx.buff(briar, amount, amount, true, unit)
