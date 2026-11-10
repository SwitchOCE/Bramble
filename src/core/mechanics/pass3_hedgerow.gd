extends Mechanic
## Hedgerow native hooks share resolved rates with the generated faces.


func recruit_hook(ctx: RecruitContext) -> void:
	Pass3Hedgerow.recruit_hook(ctx)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	Pass3HedgeCombat.start(combat, unit, params)


func hears_allies(params: Dictionary) -> bool:
	return str(params.get("ability", "")) == "mrs_clover"


func on_ally_summon(
	combat: Combat, unit: CombatUnit, params: Dictionary, summoned: CombatUnit
) -> void:
	Pass3HedgeCombat.on_ally_summon(combat, unit, params, summoned)
