extends Mechanic
## Quartermaster, Recruit: give `amount` units in your hand Reserve (one; two for a golden), never
## itself or a unit that has Reserve already; the leftmost when no target is picked. While alive in
## a fight, the side can call `amount` more reservists (Q_RESERVE_LIMIT); on the recruit board it
## answers the same query through modify_int, for the screen's count.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func recruit_target(_params: MechanicParams) -> Target:
	return Target.HAND_UNIT


## Never itself: "a unit in your hand" means another one.
func accepts_recruit_target(card: Unit, source: Unit) -> bool:
	return card != source and not card.has_mechanic(&"pigeon_reserve")


func on_recruited(ctx: RecruitContext, unit: Unit, target: Unit, params: MechanicParams) -> void:
	# Proposal: with an explicit first target, a golden still picks the leftmost eligible second.
	var candidates: Array[Unit] = ctx.player.hand.duplicate()
	if target != null and candidates.has(target):
		candidates.erase(target)
		candidates.push_front(target)
	var given: int = 0
	for card: Unit in candidates:
		if card.is_spell() or not accepts_recruit_target(card, unit):
			continue
		if given == 0 and not ctx.trigger(unit, &"pigeon_quartermaster"):
			return
		ctx.give_keyword(card, &"pigeon_reserve", unit)
		given += 1
		if given == params.num(&"amount"):
			return


func side_query(
	_combat: Combat, unit: CombatUnit, query: StringName, value: int, params: MechanicParams
) -> int:
	return value + params.num(&"amount") if unit != null and query == Q_RESERVE_LIMIT else value


func modify_int(
	query: StringName, value: int, _player: PlayerState, _unit: Unit, params: MechanicParams
) -> int:
	return value + params.num(&"amount") if query == Q_RESERVE_LIMIT else value
