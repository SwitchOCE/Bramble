extends Mechanic
## Shared neutral dispatcher; body and timing rates remain with the originating entry.


func recruit_hook(ctx: RecruitContext) -> void:
	Pass3Neutrals.recruit_hook(ctx)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	Pass3NeutralCombat.start(combat, unit, params)
