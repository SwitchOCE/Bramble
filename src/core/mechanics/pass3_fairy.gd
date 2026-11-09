extends Mechanic
## Fairy recruit state and combat copies share the same data ability names.


func recruit_hook(ctx: RecruitContext) -> void:
	Pass3Fairies.recruit_hook(ctx)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	Pass3FairyCombat.start(
		combat,
		unit,
		str(params.get("ability", "")),
		CoreUtil.to_int(params.get("factor", unit.golden_factor()))
	)
