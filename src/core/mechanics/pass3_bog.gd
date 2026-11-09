extends Mechanic
## One dispatch point; shared owner rules are resolved once by the death-batch helper.


func recruit_hook(ctx: RecruitContext) -> void:
	Pass3Bog.recruit_hook(ctx)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	Pass3BogStart.invoke(combat, unit, str(params.get("ability", "")))


func on_attacked_complete(
	combat: Combat, unit: CombatUnit, _params: Dictionary, attacker: CombatUnit
) -> void:
	Pass3BogCombat.hit_back(combat, unit, attacker)


func after_attacked(
	combat: Combat,
	unit: CombatUnit,
	_params: Dictionary,
	attacker: CombatUnit,
	defender: CombatUnit
) -> void:
	Pass3BogCombat.after_attack(combat, unit, attacker, defender)


func on_death(combat: Combat, unit: CombatUnit, _params: Dictionary) -> void:
	Pass3BogCombat.died(combat, unit)
