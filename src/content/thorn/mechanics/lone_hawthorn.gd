extends Mechanic
## Enemies your Thorns kill go into your Compost (Lone Hawthorn). While this is on the board, an
## enemy killed by Thorns damage from any of your units adds an entry for its card, plain and at
## its own tier, if that enemy was Bought. Tokens and other Created units add nothing. With two
## Lone Hawthorns a kill still adds one entry.

const Compost := preload("res://src/content/thorn/compost_rules.gd")
const Thorns := preload("res://src/content/thorn/mechanics/thorns.gd")


func on_any_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null or dead.side == unit.side:
		return
	var side: FightSide = combat.bridge(unit.side)
	var key: StringName = Thorns.kill_key(dead)
	if side.state_int(key) <= 0:
		return
	side.set_state(key, 0)
	if dead.bought and combat.trigger(unit, &"thorn_lone_hawthorn"):
		side.heap_add(Compost.HEAP, dead.def.id, dead.def.tier, unit)
