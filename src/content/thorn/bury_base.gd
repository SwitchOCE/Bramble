extends Mechanic
## Bury (SHARED-RULES, Briars): once a turn for each Bury unit on the board, a shop unit (not a
## spell) leaves the shop, its pool copy goes back (5.3.7), an entry for it goes into the
## Compost, then the unit's effect resolves, as many times as "Your Bury effects happen" says
## (Old Mother Midden). The thorn_bury_* mechanics extend this and write bury_effect.

const Compost := preload("res://src/content/thorn/compost_rules.gd")
## Rules.ask query: how many times a Bury's effect resolves (base 1).
const Q_BURY_TIMES: StringName = &"thorn_bury_times"


func has_ability() -> bool:
	return true


func ability_target(_params: MechanicParams) -> Target:
	return Target.SHOP_UNIT


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, params: MechanicParams) -> void:
	if not ctx.trigger(unit, mechanic_id()):
		return
	var card_id: StringName = ctx.take_from_shop(ctx.target_index, unit)
	if card_id == &"":
		return
	ctx.heap_add(Compost.HEAP, card_id, unit)
	var times: int = maxi(1, ctx.session.rules.ask(Q_BURY_TIMES, 1, ctx.player, null))
	for _time: int in times:
		bury_effect(ctx, unit, params)


## The mechanic's id, for its trigger.
func mechanic_id() -> StringName:
	return &"thorn_bury"


## What follows the Bury.
func bury_effect(_ctx: RecruitContext, _unit: Unit, _params: MechanicParams) -> void:
	pass
