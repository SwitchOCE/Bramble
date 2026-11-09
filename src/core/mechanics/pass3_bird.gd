extends Mechanic
## Bird card timing stays in the usual mechanic hooks; the tribe helper owns its rules.


func recruit_hook(ctx: RecruitContext) -> void:
	Pass3Birds.recruit_hook(ctx)


func recruit_aura(player: PlayerState, unit: RecruitUnit, params: Dictionary) -> Vector2i:
	return Pass3Birds.recruit_aura(player, unit, params)


func first_of_all(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if str(params.get("ability", "")) == "mag_pye":
		Pass3BirdCombat.steal_text(
			combat, unit, CoreUtil.to_int(params.get("factor", unit.golden_factor()))
		)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	Pass3BirdCombat.start(
		combat,
		unit,
		str(params.get("ability", "")),
		CoreUtil.to_int(params.get("factor", unit.golden_factor()))
	)


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	if str(params.get("ability", "")) == "lump":
		return Pass3BirdCombat.lump(
			combat, unit, CoreUtil.to_int(params.get("factor", unit.golden_factor()))
		)
	return Vector2i.ZERO


func hears_allies(params: Dictionary) -> bool:
	return str(params.get("ability", "")) == "ratchet"


func on_friendly_death(
	combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit
) -> void:
	if str(params.get("ability", "")) == "ratchet":
		Pass3BirdCombat.drop_in(
			combat, unit, dead, CoreUtil.to_int(params.get("factor", unit.golden_factor()))
		)
