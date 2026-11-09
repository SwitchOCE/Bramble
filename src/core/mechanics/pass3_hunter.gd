extends Mechanic
## Runtime rewards are dispatched once at the shared exchange and death-batch boundaries.


func recruit_hook(ctx: RecruitContext) -> void:
	Pass3Hunters.recruit_hook(ctx)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if str(params.get("ability", "")) == "sable":
		Pass3HunterStart.sable(combat, unit)
