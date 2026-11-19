extends Mechanic
## Grenadier Guard, an Active ("{cost}: ..."): make a slot (empty or not) your Guard post,
## clearing the old one; the post is a slot effect giving Guard (taunt) and stays when the
## Grenadier is sold. At the end of your turn, give the slot that is your Guard post then `amount`
## Renown, permanently; when the post moves, Renown already given stays on the old slot.

const GuardPost := preload("res://src/content/pigeon/mechanics/guard_post.gd")
const GUARD: StringName = &"taunt"


func param_kinds() -> Dictionary:
	return {
		"cost": MechanicParams.Kind.THRESHOLD,
		"amount": MechanicParams.Kind.NUMBER,
	}


func has_ability() -> bool:
	return true


func ability_cost(params: MechanicParams) -> int:
	return params.num(&"cost")


func ability_target(_params: MechanicParams) -> Target:
	return Target.SLOT


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	var slot: int = ctx.target_index
	if slot < 0 or not ctx.trigger(unit, &"pigeon_grenadier"):
		return
	var old: int = GuardPost.post_of(ctx.player.slots)
	if old == slot:
		return
	if old >= 0:
		ctx.slot_clear_keyword(old, GuardPost.ID, unit)
		ctx.slot_clear_keyword(old, GUARD, unit)
	ctx.slot_buff(slot, 0, 0, unit, GuardPost.ID)
	ctx.slot_buff(slot, 0, 0, unit, GUARD)


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null:
		return
	var post: int = GuardPost.post_of(ctx.player.slots)
	if post < 0 or not ctx.trigger(unit, &"pigeon_grenadier"):
		return
	ctx.add_renown(post, params.num(&"amount"), unit)
