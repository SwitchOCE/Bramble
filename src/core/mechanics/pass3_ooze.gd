extends Mechanic
## Eating is recruit-side; combat answers and release marks share one native dispatcher.


func recruit_hook(ctx: RecruitContext) -> void:
	Pass3Oozes.recruit_hook(ctx)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	Pass3OozeCombat.start(combat, unit, params)


func on_death(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	Pass3OozeCombat.death(combat, unit, params)


func on_friendly_death(
	combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit
) -> void:
	Pass3OozeCombat.friendly_death(combat, unit, params, dead)


func hears_allies(params: Dictionary) -> bool:
	return str(params.get("ability", "")) == "hasty_pudding"
