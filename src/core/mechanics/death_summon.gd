extends Mechanic
## Hoglet Mother (library entry 7): when this dies, summon `count` of `unit`, the first into this
## unit's slot (rulebook 8.4.1), the rest nearest (8.4.2). A golden unit summons golden tokens;
## the count stays (7.3.5, SPEC 4.2).


func on_death(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	combat.trigger(unit, "death_summon")
	for _index: int in CoreUtil.to_int(params.get("count", 1)):
		combat.summon(str(params.get("unit", "")), unit.golden, unit.side, unit.slot, unit)
