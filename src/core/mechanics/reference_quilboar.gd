extends Mechanic
## Available only in the test reference library.


func recruit_hook(ctx: RecruitContext) -> void:
	ReferenceQuilboar.on_recruit(ctx, ctx.params)


func on_before_attack(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	QuilboarCombat.fire(combat, unit, params, "on_attack")


func on_death(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	QuilboarCombat.fire(combat, unit, params, "on_death")
