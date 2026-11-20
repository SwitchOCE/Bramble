extends Mechanic

const USES: StringName = &"core_weasel_uses"


func param_kinds() -> Dictionary:
	return {"limit": MechanicParams.Kind.NUMBER}


func on_fight_enter(
	combat: Combat, unit: CombatUnit, entered: CombatUnit, params: MechanicParams
) -> void:
	if entered.side == unit.side or entered.reservist or entered.gone or entered.should_die():
		return
	var limit: int = params.num(&"limit")
	if unit.should_die() or unit.fight_count(USES) >= limit:
		return
	if combat.trigger(unit, &"hit_enemy_summon"):
		unit.add_fight_count(USES)
		combat.show_uses(unit, USES, limit - unit.fight_count(USES), unit)
		combat.hit(unit, entered)
