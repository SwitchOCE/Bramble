extends Mechanic
## The Compost (standing, every player): a Bought unit sold goes in, one entry for each Bought
## copy in it (a golden adds one for each); Created units add nothing. It also gives an Elder
## Mother copy its bonus when it lands, even after the Elder Mother has died.

const Compost := preload("res://src/content/thorn/compost_rules.gd")


func on_any_sold(ctx: RecruitContext, unit: Unit, sold: Unit, _params: MechanicParams) -> void:
	if unit != null or sold.is_spell():
		return
	for _copy: int in sold.bought_copies:
		ctx.heap_add(Compost.HEAP, sold.def.id, null)


func on_fight_enter(
	combat: Combat, unit: CombatUnit, entered: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null and entered.side == combat.listening_side:
		Compost.elder_bonus(combat, entered)
