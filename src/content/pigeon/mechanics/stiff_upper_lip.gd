extends Mechanic
## Stiff Upper Lip: the first time damage would kill this each fight, it stays on 1 Health. Any
## kind of damage; not a death and not a return. Destroy effects don't go through damage, so they
## ignore it. Once a fight for each unit, whatever gives it: a fight count, which a return carries
## (SHARED-RULES 21), so a unit that returns as it stands keeps it used. A plain-copy return has
## no Medals, so it is not Decorated and has none.

const USED: StringName = &"pigeon_stiff_upper_lip_used"


func absorb_damage(
	combat: Combat, unit: CombatUnit, amount: int, _from_attack: bool, _params: MechanicParams
) -> int:
	if unit.fight_count(USED) != 0 or amount < unit.health() or unit.health() <= 0:
		return amount
	if not combat.trigger(unit, &"pigeon_stiff_upper_lip"):
		return amount
	unit.add_fight_count(USED)
	combat.show_status(unit, &"pigeon_stiff_upper_lip", false)
	return unit.health() - 1
