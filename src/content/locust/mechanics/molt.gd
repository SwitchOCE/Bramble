extends Mechanic
## Molt: the first time this dies each fight, it returns as a plain copy with 1 Health, then
## gains +2/+2 permanently (the copy and the recruit-board unit). Through the core's return
## protocol: counted in charges (printed Molt is one a fight, Skin-shedder adds locust_molt_extra
## for this fight), kept in fight counts so they carry across any return, and shown as uses left.
## A plain return (RETURN_PLAIN): with Root as well, Root comes first when the Compost can pay
## (ruling 17), decided by return priority.

const Locust := preload("res://src/content/locust/lib/locust.gd")
const GROWTH: int = 2


func return_offer(_combat: Combat, unit: CombatUnit, _params: MechanicParams) -> int:
	return 1 if Locust.molt_left(unit) > 0 else 0


func pay_return(
	combat: Combat, gone: CombatUnit, back: CombatUnit, _params: MechanicParams
) -> void:
	back.add_fight_count(Locust.MOLT_USED)
	combat.buff(back, GROWTH, GROWTH, gone, true)
	var left: int = Locust.molt_left(back)
	combat.show_uses(back, Locust.MOLT, left, gone)
	if left <= 0:
		combat.show_status(back, Locust.MOLT, false, gone)


## After any return (this Molt's, or Root's first): a Molt given this fight (Skin-shedder) is not
## on the returned unit (a plain copy, or the recruit-board unit), so it is given again while a
## charge is left.
func on_returned(
	combat: Combat, gone: CombatUnit, back: CombatUnit, _params: MechanicParams
) -> void:
	if Locust.molt_left(back) > 0 and not back.has_mechanic(Locust.MOLT):
		combat.bridge(back.side).give_keyword(back, Locust.MOLT, false, gone)
