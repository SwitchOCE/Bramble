extends Mechanic
## Molt: the first time this dies each fight, it returns as a plain copy with 1 Health, then
## gains +2/+2 permanently (the copy and the recruit-board unit). Counted in charges: printed
## Molt is one a fight and Skin-shedder adds locust_molt_extra for this fight (SHARED-RULES,
## Molt); the counts live in the unit's fight state. A unit with Root as well uses Root first:
## Molt claims a death only when no earlier return did (ruling 17).

const Locust := preload("res://src/content/locust/lib/locust.gd")
const GROWTH: int = 2


func return_health(combat: Combat, unit: CombatUnit, health: int, _params: MechanicParams) -> int:
	if health > 0 or Locust.molt_left(unit) <= 0 or combat.halted():
		return health
	unit.set_state(Locust.MOLT_CLAIM, 1)
	return 1


func on_returned(
	combat: Combat, gone: CombatUnit, back: CombatUnit, _params: MechanicParams
) -> void:
	# The charges are this fight's limit: carried onto the copy whichever return brought it back.
	back.set_state(Locust.MOLT_EXTRA, gone.state_int(Locust.MOLT_EXTRA))
	back.set_state(Locust.MOLT_USED, gone.state_int(Locust.MOLT_USED))
	if gone.state_int(Locust.MOLT_CLAIM) == 0 or not combat.trigger(back, Locust.MOLT):
		return
	var side: FightSide = combat.bridge(back.side)
	back.set_state(Locust.MOLT_USED, back.state_int(Locust.MOLT_USED) + 1)
	combat.buff(back, GROWTH, GROWTH, gone, true)
	if Locust.molt_left(back) <= 0:
		combat.show_status(back, Locust.MOLT, false, gone)
	elif not back.has_mechanic(Locust.MOLT):
		# A Molt given this fight (Skin-shedder) with a charge left: the plain copy keeps it.
		side.give_keyword(back, Locust.MOLT, false, gone)
